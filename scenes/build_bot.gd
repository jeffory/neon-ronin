extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_bot.gd

func _initialize() -> void:
	print("Generating: Bot")

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
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 1.5
	root.add_child(nav_agent)

	# Line of sight raycast (at eye level)
	var raycast := RayCast3D.new()
	raycast.name = "SightRaycast"
	raycast.target_position = Vector3(0, 0, -50)
	raycast.enabled = true
	raycast.position = Vector3(0, 1.6, 0)
	root.add_child(raycast)

	# Load bot FBX model (rigged Mixamo character)
	var bot_scene: PackedScene = load("res://assets/glb/bot/bot.fbx")
	if bot_scene:
		var bot_model = bot_scene.instantiate()
		bot_model.name = "BotModel"
		# Scale to 1.8m tall
		var mesh_inst = _find_mesh_instance(bot_model)
		if mesh_inst:
			var aabb: AABB = mesh_inst.get_aabb()
			var model_height: float = aabb.size.y
			if model_height > 0.001:
				var sf: float = 1.8 / model_height
				bot_model.scale = Vector3(sf, sf, sf)
				# Align feet to ground
				bot_model.position.y = -aabb.position.y * sf
		root.add_child(bot_model)
	else:
		# Fallback: placeholder capsule mesh
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "BotModel"
		var capsule_mesh := CapsuleMesh.new()
		capsule_mesh.radius = 0.3
		capsule_mesh.height = 1.8
		mesh_inst.mesh = capsule_mesh
		mesh_inst.position = Vector3(0, 0.9, 0)
		# Red-ish material to distinguish from player
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.2, 0.2)
		mesh_inst.set_surface_override_material(0, mat)
		root.add_child(mesh_inst)

	# Set collision layers: layer 2 (enemies), mask 1|2|4 (player, enemies, environment)
	root.collision_layer = 2
	root.collision_mask = 1 | 2 | 4

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/bot.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/bot.tscn")
	quit(0)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
