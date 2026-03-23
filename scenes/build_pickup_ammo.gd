extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_pickup_ammo.gd

func _initialize() -> void:
	print("Generating: PickupAmmo")

	var root := Area3D.new()
	root.name = "PickupAmmo"
	root.set_script(load("res://scripts/pickup.gd"))
	# Pickup layer 4 (bitmask 8)
	root.collision_layer = 8
	root.collision_mask = 1 | 2  # Detect player and enemies

	# Collision
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	col.shape = sphere
	root.add_child(col)

	# Load ammo crate GLB model
	var model_scene: PackedScene = load("res://assets/glb/ammo_crate.glb")
	if model_scene:
		var model = model_scene.instantiate()
		model.name = "Model"
		# Scale to 0.3m
		var mesh_inst = _find_mesh_instance(model)
		if mesh_inst:
			var aabb: AABB = mesh_inst.get_aabb()
			var longest: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
			if longest > 0.001:
				var sf: float = 0.3 / longest
				model.scale = Vector3(sf, sf, sf)
		model.position = Vector3(0, 0.3, 0)
		root.add_child(model)
	else:
		# Fallback: orange cube
		var mesh_inst := MeshInstance3D.new()
		mesh_inst.name = "Model"
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 0.3, 0.3)
		mesh_inst.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.6, 0.1)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.6, 0.1)
		mat.emission_energy_multiplier = 2.0
		mesh_inst.set_surface_override_material(0, mat)
		mesh_inst.position = Vector3(0, 0.3, 0)
		root.add_child(mesh_inst)

	# Orange glow light
	var glow := OmniLight3D.new()
	glow.name = "GlowLight"
	glow.light_color = Color(1.0, 0.6, 0.1)
	glow.light_energy = 0.6
	glow.omni_range = 1.5
	glow.omni_attenuation = 2.0
	glow.position = Vector3(0, 0.3, 0)
	root.add_child(glow)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/pickup_ammo.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/pickup_ammo.tscn")
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
