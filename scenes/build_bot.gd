extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_bot.gd

func _initialize() -> void:
	var root := CharacterBody3D.new()
	root.name = "Bot"
	root.set_script(load("res://scripts/bot_controller.gd"))

	# Collision shape — capsule 1.8m
	var col_shape := CollisionShape3D.new()
	col_shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	col_shape.shape = capsule
	col_shape.position = Vector3(0, 0.9, 0)
	root.add_child(col_shape)

	# Navigation agent
	var nav_agent := NavigationAgent3D.new()
	nav_agent.name = "NavigationAgent3D"
	root.add_child(nav_agent)

	# Line of sight raycast
	var raycast := RayCast3D.new()
	raycast.name = "SightRaycast"
	raycast.target_position = Vector3(0, 0, -50)
	raycast.enabled = true
	raycast.position = Vector3(0, 1.6, 0)
	root.add_child(raycast)

	# Placeholder mesh
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "BotMesh"
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.3
	capsule_mesh.height = 1.8
	mesh_inst.mesh = capsule_mesh
	mesh_inst.position = Vector3(0, 0.9, 0)
	root.add_child(mesh_inst)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/bot.tscn")
	print("Saved: res://scenes/bot.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
