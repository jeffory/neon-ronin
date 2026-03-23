extends Node
## res://scripts/game_manager.gd — Autoload singleton

signal kill_registered(killer_name: String, victim_name: String)
signal score_updated
signal match_ended(winner_name: String)

var scores: Dictionary = {}
var spawn_points: Array[Vector3] = []
var pickup_spots: Array[Vector3] = []
var _entities: Dictionary = {}  # name -> node reference
var _nav_baked: bool = false

# Multi-level state
var current_level: int = 0
var level_order: Array[String] = [
	"res://scenes/level.tscn",
	"res://scenes/level_skyscraper.tscn"
]
var score_limit: int = 20
var match_active: bool = true
var level_names: Dictionary = {
	"res://scenes/level.tscn": "Streets",
	"res://scenes/level_skyscraper.tscn": "Skyscraper"
}

func get_current_level_path() -> String:
	return level_order[current_level]

func get_current_level_name() -> String:
	var path: String = get_current_level_path()
	if level_names.has(path):
		return level_names[path]
	return "Unknown"

func get_next_level_name() -> String:
	var next_idx: int = (current_level + 1) % level_order.size()
	var path: String = level_order[next_idx]
	if level_names.has(path):
		return level_names[path]
	return "Unknown"

var _level_loaded: bool = false

func _ready() -> void:
	# Spawn points and pickup spots are now loaded dynamically
	# from the scene tree via load_level_data().
	# _process polls each frame until level is found, then stops checking.
	pass

func _process(_delta: float) -> void:
	if not _level_loaded:
		_try_auto_load_level()

func _try_auto_load_level() -> void:
	if _level_loaded:
		return
	var level_node: Node = _find_child_by_name(get_tree().root, "Level")
	if level_node:
		load_level_data(level_node)
		_level_loaded = true
		# Also bake navmesh now that level is ready
		_bake_navmesh()

func _bake_navmesh() -> void:
	if _nav_baked:
		return
	var nav_region = _find_navigation_region(get_tree().root)
	if nav_region and nav_region is NavigationRegion3D:
		nav_region.bake_navigation_mesh()
		_nav_baked = true
		print("GameManager: NavMesh baked")

func _find_navigation_region(node: Node) -> Node:
	if node is NavigationRegion3D:
		return node
	for child in node.get_children():
		var found = _find_navigation_region(child)
		if found:
			return found
	return null

func load_level_data(level_root: Node) -> void:
	spawn_points.clear()
	pickup_spots.clear()
	_nav_baked = false
	# Walk scene tree for SpawnPoints Marker3D children
	var sp_parent: Node = _find_child_by_name(level_root, "SpawnPoints")
	if sp_parent:
		for child in sp_parent.get_children():
			if child is Marker3D:
				spawn_points.append(child.global_position)
	# Walk scene tree for PickupSpots Marker3D children
	var pp_parent: Node = _find_child_by_name(level_root, "PickupSpots")
	if pp_parent:
		for child in pp_parent.get_children():
			if child is Marker3D:
				pickup_spots.append(child.global_position)
	print("GameManager: Loaded %d spawn points, %d pickup spots from level" % [spawn_points.size(), pickup_spots.size()])

func _find_child_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var found: Node = _find_child_by_name(child, target_name)
		if found:
			return found
	return null

func register_entity(entity_name: String, node: Node) -> void:
	_entities[entity_name] = node
	if not scores.has(entity_name):
		scores[entity_name] = {"kills": 0, "deaths": 0}

func register_kill(killer_name: String, victim_name: String) -> void:
	if not scores.has(killer_name):
		scores[killer_name] = {"kills": 0, "deaths": 0}
	if not scores.has(victim_name):
		scores[victim_name] = {"kills": 0, "deaths": 0}
	scores[killer_name]["kills"] += 1
	scores[victim_name]["deaths"] += 1
	kill_registered.emit(killer_name, victim_name)
	score_updated.emit()
	# Check for match end condition
	if match_active and scores[killer_name]["kills"] >= score_limit:
		match_active = false
		match_ended.emit(killer_name)

func get_random_spawn_point() -> Vector3:
	if spawn_points.is_empty():
		return Vector3(0, 1, 0)
	return spawn_points[randi() % spawn_points.size()]

func get_safest_spawn_point() -> Vector3:
	if spawn_points.is_empty():
		return Vector3(0, 1, 0)
	# Collect positions of all living entities
	var living_positions: Array[Vector3] = []
	for entity_name in _entities:
		var entity: Node = _entities[entity_name]
		if is_instance_valid(entity) and entity is CharacterBody3D:
			var entity_dead: bool = false
			if "is_dead" in entity:
				entity_dead = entity.is_dead
			if not entity_dead:
				living_positions.append(entity.global_position)
	# If no living entities, pick random
	if living_positions.is_empty():
		return spawn_points[randi() % spawn_points.size()]
	# For each spawn point, find the minimum distance to any living entity
	# Pick the spawn point with the largest minimum distance
	var best_point: Vector3 = spawn_points[0]
	var best_min_dist: float = -1.0
	for sp in spawn_points:
		var min_dist: float = 999999.0
		for pos in living_positions:
			var dist: float = sp.distance_to(pos)
			if dist < min_dist:
				min_dist = dist
		if min_dist > best_min_dist:
			best_min_dist = min_dist
			best_point = sp
	return best_point

func get_scores() -> Dictionary:
	return scores

func get_entity(entity_name: String) -> Node:
	if _entities.has(entity_name):
		return _entities[entity_name]
	return null

func advance_to_next_level() -> void:
	current_level += 1
	if current_level >= level_order.size():
		current_level = 0  # Wrap around
	_level_loaded = false  # Allow auto-detection of new level
	print("GameManager: Advancing to level %d (%s)" % [current_level, level_order[current_level]])

func reset_match() -> void:
	match_active = true
	for entity_name in scores:
		scores[entity_name]["kills"] = 0
		scores[entity_name]["deaths"] = 0
	score_updated.emit()
	print("GameManager: Match reset")
