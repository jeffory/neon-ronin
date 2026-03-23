extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_main.gd

func _initialize() -> void:
	print("Generating: Main (dynamic level loading)")

	var root := Node3D.new()
	root.name = "Main"

	# Attach main_controller.gd to root — handles level loading, bot/pickup spawning
	var main_script = load("res://scripts/main_controller.gd")
	if main_script:
		root.set_script(main_script)

	# Instance Player (repositioned at runtime by main_controller)
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.name = "Player"
	player.position = Vector3(0, 1, 0)
	root.add_child(player)

	# Attach player_controller.gd script override
	var player_script = load("res://scripts/player_controller.gd")
	if player_script:
		player.set_script(player_script)

	# Instance HUD
	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud = hud_scene.instantiate()
	hud.name = "HUD"
	root.add_child(hud)

	# Attach hud_controller.gd script override
	var hud_script = load("res://scripts/hud_controller.gd")
	if hud_script:
		hud.set_script(hud_script)

	# Instance Pause Menu
	var pause_scene: PackedScene = load("res://scenes/pause_menu.tscn")
	if pause_scene:
		var pause_menu = pause_scene.instantiate()
		pause_menu.name = "PauseMenu"
		root.add_child(pause_menu)
		# Attach pause_menu.gd script override
		var pause_script = load("res://scripts/pause_menu.gd")
		if pause_script:
			pause_menu.set_script(pause_script)

	# Instance DevConsole
	var dev_scene: PackedScene = load("res://scenes/dev_console.tscn")
	if dev_scene:
		var dev_console = dev_scene.instantiate()
		dev_console.name = "DevConsole"
		root.add_child(dev_console)

	# No Level, bots, or pickups — these are spawned at runtime by main_controller.gd

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/main.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/main.tscn")
	quit(0)

func _set_owners(root_node: Node, owner: Node) -> void:
	for c in root_node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
