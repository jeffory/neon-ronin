extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_main.gd

func _initialize() -> void:
	var root := Node3D.new()
	root.name = "Main"

	# Instance Level
	var level = load("res://scenes/level.tscn").instantiate()
	level.name = "Level"
	root.add_child(level)

	# Instance Player
	var player = load("res://scenes/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector3(0, 1, 0)
	root.add_child(player)

	# Instance HUD
	var hud = load("res://scenes/hud.tscn").instantiate()
	hud.name = "HUD"
	root.add_child(hud)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/main.tscn")
	print("Saved: res://scenes/main.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
