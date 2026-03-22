extends Node
## res://scripts/game_manager.gd — Autoload singleton

signal kill_registered(killer_name: String, victim_name: String)
signal score_updated

var scores: Dictionary = {}
var spawn_points: Array[Vector3] = []
var pickup_spots: Array[Vector3] = []
var _entities: Dictionary = {}  # name -> node reference

func _ready() -> void:
	# Spawn points from MEMORY.md
	spawn_points = [
		Vector3(0, 1, 0), Vector3(14, 1, -10), Vector3(-14, 1, 10),
		Vector3(0, 1, -20), Vector3(0, 1, 20), Vector3(14, 1, 10),
		Vector3(-14, 1, -10), Vector3(0, 1, -10)
	]
	# Pickup spots from MEMORY.md
	pickup_spots = [
		Vector3(0, 0.5, -5), Vector3(14, 0.5, 0), Vector3(-14, 0.5, 0),
		Vector3(0, 0.5, 15), Vector3(2, 0.5, -15), Vector3(-2, 0.5, 10)
	]

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

func get_random_spawn_point() -> Vector3:
	if spawn_points.is_empty():
		return Vector3(0, 1, 0)
	return spawn_points[randi() % spawn_points.size()]

func get_scores() -> Dictionary:
	return scores

func get_entity(entity_name: String) -> Node:
	if _entities.has(entity_name):
		return _entities[entity_name]
	return null
