extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_level.gd

func _initialize() -> void:
	var root := Node3D.new()
	root.name = "Level"

	# Navigation region placeholder
	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	root.add_child(nav_region)

	# Spawn points container
	var spawn_points := Node3D.new()
	spawn_points.name = "SpawnPoints"
	root.add_child(spawn_points)

	# Pickup spots container
	var pickup_spots := Node3D.new()
	pickup_spots.name = "PickupSpots"
	root.add_child(pickup_spots)

	# WorldEnvironment placeholder
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	root.add_child(world_env)

	# Moonlight
	var dir_light := DirectionalLight3D.new()
	dir_light.name = "Moonlight"
	root.add_child(dir_light)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/level.tscn")
	print("Saved: res://scenes/level.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
