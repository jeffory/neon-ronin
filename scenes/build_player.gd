extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_player.gd

func _initialize() -> void:
	var root := CharacterBody3D.new()
	root.name = "Player"
	root.set_script(load("res://scripts/player_controller.gd"))

	# Collision shape — capsule 1.8m
	var col_shape := CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	col_shape.shape = capsule
	col_shape.position = Vector3(0, 0.9, 0)
	root.add_child(col_shape)

	# Head pivot
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.6, 0)
	root.add_child(head)

	# Camera
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 75.0
	head.add_child(camera)

	# Weapon holder
	var weapon_holder := Node3D.new()
	weapon_holder.name = "WeaponHolder"
	weapon_holder.set_script(load("res://scripts/weapon_manager.gd"))
	weapon_holder.position = Vector3(0.3, -0.2, -0.5)
	camera.add_child(weapon_holder)

	# Weapon raycast
	var raycast := RayCast3D.new()
	raycast.name = "WeaponRaycast"
	raycast.target_position = Vector3(0, 0, -100)
	raycast.enabled = true
	camera.add_child(raycast)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/player.tscn")
	print("Saved: res://scenes/player.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
