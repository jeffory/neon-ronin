extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_pickup_ammo.gd

func _initialize() -> void:
	var root := Area3D.new()
	root.name = "PickupAmmo"
	root.set_script(load("res://scripts/pickup.gd"))

	# Collision
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	col.shape = sphere
	root.add_child(col)

	# Visual placeholder — orange cube
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "MeshInstance3D"
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	mesh_inst.mesh = box
	mesh_inst.position = Vector3(0, 0.3, 0)
	root.add_child(mesh_inst)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/pickup_ammo.tscn")
	print("Saved: res://scenes/pickup_ammo.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
