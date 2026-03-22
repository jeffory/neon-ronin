extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_main.gd

func _initialize() -> void:
	print("Generating: Main")

	var root := Node3D.new()
	root.name = "Main"

	# Instance Level
	var level_scene: PackedScene = load("res://scenes/level.tscn")
	var level = level_scene.instantiate()
	level.name = "Level"
	root.add_child(level)

	# Instance Player at spawn point 0
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.name = "Player"
	player.position = Vector3(0, 1, 0)
	root.add_child(player)

	# Instance HUD
	var hud_scene: PackedScene = load("res://scenes/hud.tscn")
	var hud = hud_scene.instantiate()
	hud.name = "HUD"
	root.add_child(hud)

	# Instance pickups at pickup spots from MEMORY.md
	var pickup_positions: Array = [
		{"pos": Vector3(0, 0.5, -5), "type": "health"},
		{"pos": Vector3(14, 0.5, 0), "type": "ammo"},
		{"pos": Vector3(-14, 0.5, 0), "type": "health"},
		{"pos": Vector3(0, 0.5, 15), "type": "ammo"},
		{"pos": Vector3(2, 0.5, -15), "type": "health"},
		{"pos": Vector3(-2, 0.5, 10), "type": "ammo"},
	]

	var health_scene: PackedScene = load("res://scenes/pickup_health.tscn")
	var ammo_scene: PackedScene = load("res://scenes/pickup_ammo.tscn")

	for i in range(pickup_positions.size()):
		var pdata: Dictionary = pickup_positions[i]
		var pickup: Node
		if pdata["type"] == "health":
			pickup = health_scene.instantiate()
			pickup.name = "PickupHealth_%d" % i
		else:
			pickup = ammo_scene.instantiate()
			pickup.name = "PickupAmmo_%d" % i
		pickup.position = pdata["pos"]
		root.add_child(pickup)

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
