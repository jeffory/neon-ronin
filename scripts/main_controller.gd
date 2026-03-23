extends Node3D
## res://scripts/main_controller.gd — Dynamic level loading and entity spawning

var _gm: Node = null
var _level_instance: Node3D = null

func _ready() -> void:
	_gm = _get_game_manager()
	if not _gm:
		push_error("main_controller: GameManager autoload not found")
		return

	# Load and instance the current level
	var level_path: String = _gm.get_current_level_path()
	var level_scene: PackedScene = load(level_path)
	if not level_scene:
		push_error("main_controller: Failed to load level scene: " + level_path)
		return

	_level_instance = level_scene.instantiate()
	_level_instance.name = "Level"
	add_child(_level_instance)

	# Defer level data loading so global positions are valid
	call_deferred("_on_level_added")

func _on_level_added() -> void:
	if not _gm or not _level_instance:
		return

	# Load spawn/pickup data from level Marker3D nodes
	_gm.load_level_data(_level_instance)

	# Wait one more frame for load_level_data to finish processing
	call_deferred("_spawn_entities")

func _spawn_entities() -> void:
	if not _gm:
		return

	# Reposition player to first spawn point
	var player: Node3D = get_node_or_null("Player")
	if player and _gm.spawn_points.size() > 0:
		player.global_position = _gm.spawn_points[0]

	# Spawn bots
	_spawn_bots()

	# Spawn pickups
	_spawn_pickups()

	# Bake navmesh (GameManager also does this, but ensure it happens)
	_gm._bake_navmesh()

	# Connect match_ended signal
	if _gm.has_signal("match_ended"):
		if not _gm.match_ended.is_connected(_on_match_ended):
			_gm.match_ended.connect(_on_match_ended)

func _spawn_bots() -> void:
	var bot_scene: PackedScene = load("res://scenes/bot.tscn")
	if not bot_scene:
		push_error("main_controller: Failed to load bot.tscn")
		return

	var bot_script: GDScript = load("res://scripts/bot_controller.gd")
	var bot_names: Array[String] = ["Bot_Alpha", "Bot_Bravo", "Bot_Charlie", "Bot_Delta"]

	for i in range(4):
		var bot = bot_scene.instantiate()
		bot.name = bot_names[i]
		# Attach bot controller script
		if bot_script:
			bot.set_script(bot_script)
		# Set collision layers: layer=2 (enemies), mask=1|2|4 (player+enemies+environment)
		bot.collision_layer = 2
		bot.collision_mask = 1 | 2 | 4
		add_child(bot)
		# Position at spawn point after adding to tree (so global_position works)
		if _gm.spawn_points.size() > 0:
			var spawn_idx: int = (i + 1) % _gm.spawn_points.size()
			bot.global_position = _gm.spawn_points[spawn_idx]

func _spawn_pickups() -> void:
	var health_scene: PackedScene = load("res://scenes/pickup_health.tscn")
	var ammo_scene: PackedScene = load("res://scenes/pickup_ammo.tscn")
	var pickup_script: GDScript = load("res://scripts/pickup.gd")

	if not health_scene or not ammo_scene:
		push_error("main_controller: Failed to load pickup scenes")
		return

	for i in range(_gm.pickup_spots.size()):
		var pickup: Node
		var is_health: bool = (i % 2 == 0)
		if is_health:
			pickup = health_scene.instantiate()
			pickup.name = "PickupHealth_%d" % i
		else:
			pickup = ammo_scene.instantiate()
			pickup.name = "PickupAmmo_%d" % i

		# Attach pickup script
		if pickup_script:
			pickup.set_script(pickup_script)

		# Set pickup type export
		if is_health:
			pickup.set("pickup_type", "health")
		else:
			pickup.set("pickup_type", "ammo")

		# Set collision: layer=0, mask=1|2 (player+enemies)
		if pickup is CollisionObject3D:
			pickup.collision_layer = 0
			pickup.collision_mask = 1 | 2

		add_child(pickup)
		# Position after adding to tree
		pickup.global_position = _gm.pickup_spots[i]

var _countdown_label: Label = null
var _countdown_seconds: int = 5
var _countdown_active: bool = false

func _on_match_ended(winner_name: String) -> void:
	print("Match ended! Winner: " + winner_name)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var next_map_name: String = _gm.get_next_level_name() if _gm else "Unknown"

	# Create match end overlay
	var overlay := CanvasLayer.new()
	overlay.name = "MatchEndOverlay"
	overlay.layer = 100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "MATCH OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	vbox.add_child(title)

	var winner := Label.new()
	winner.text = winner_name + " WINS!"
	winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner.add_theme_font_size_override("font_size", 32)
	winner.add_theme_color_override("font_color", Color(1, 0.8, 0))
	vbox.add_child(winner)

	# Show scores
	if _gm:
		var scores: Dictionary = _gm.get_scores()
		var spacer := Control.new()
		spacer.custom_minimum_size.y = 20
		vbox.add_child(spacer)

		var score_header := Label.new()
		score_header.text = "FINAL SCORES"
		score_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_header.add_theme_font_size_override("font_size", 22)
		score_header.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		vbox.add_child(score_header)

		var entries: Array = []
		for entity_name in scores:
			entries.append({"name": entity_name, "kills": scores[entity_name]["kills"], "deaths": scores[entity_name]["deaths"]})
		entries.sort_custom(func(a, b): return a["kills"] > b["kills"])

		for entry in entries:
			var row := Label.new()
			row.text = "%-18s %3d kills  %3d deaths" % [entry["name"], entry["kills"], entry["deaths"]]
			row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_theme_font_size_override("font_size", 18)
			if entry["name"] == "Player":
				row.add_theme_color_override("font_color", Color(0, 1, 1))
			else:
				row.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
			vbox.add_child(row)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size.y = 20
	vbox.add_child(spacer2)

	var next_map := Label.new()
	next_map.text = "Next map: " + next_map_name
	next_map.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_map.add_theme_font_size_override("font_size", 20)
	next_map.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	vbox.add_child(next_map)

	_countdown_label = Label.new()
	_countdown_label.text = "Continuing in %d..." % _countdown_seconds
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.add_theme_font_size_override("font_size", 16)
	_countdown_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(_countdown_label)

	add_child(overlay)

	# Start countdown timer
	_countdown_active = true
	_run_countdown()

func _run_countdown() -> void:
	if _countdown_seconds <= 0:
		_transition_to_next_map()
		return
	if _countdown_label:
		_countdown_label.text = "Continuing in %d..." % _countdown_seconds
	# Create a timer that works while paused
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.process_callback = Timer.TIMER_PROCESS_IDLE
	timer.autostart = false
	add_child(timer)
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(func():
		timer.queue_free()
		_countdown_seconds -= 1
		_run_countdown()
	)
	timer.start()

func _transition_to_next_map() -> void:
	_countdown_active = false
	if _gm:
		_gm.advance_to_next_level()
		_gm.reset_match()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
