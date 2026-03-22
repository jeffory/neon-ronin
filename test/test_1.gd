extends SceneTree
## Test harness for Task 1: Cyberpunk City Arena
## Verifies: dark city environment with colorful neon signs, navigable streets, cover objects

var _frame := 0
var _cam: Camera3D
var _root: Node

func _initialize() -> void:
	_root = get_root()

	# Load the level scene
	var level_scene: PackedScene = load("res://scenes/level.tscn")
	var level = level_scene.instantiate()
	_root.add_child(level)

	# Create a camera for first-person view
	_cam = Camera3D.new()
	_cam.name = "TestCamera"
	_cam.fov = 75.0
	_cam.current = true
	_root.add_child(_cam)

	# Start in center of arena, first-person height
	_cam.position = Vector3(0, 1.7, 0)
	_cam.rotation_degrees = Vector3(0, 0, 0)

	# Verify node structure
	var nav_region = level.get_node_or_null("NavigationRegion3D")
	if nav_region:
		print("ASSERT PASS: NavigationRegion3D exists")
		if nav_region.navigation_mesh:
			print("ASSERT PASS: NavigationMesh assigned")
		else:
			print("ASSERT FAIL: NavigationMesh not assigned")
	else:
		print("ASSERT FAIL: NavigationRegion3D missing")

	var spawn_points = level.get_node_or_null("SpawnPoints")
	if spawn_points and spawn_points.get_child_count() >= 6:
		print("ASSERT PASS: SpawnPoints has %d markers (>= 6)" % spawn_points.get_child_count())
	else:
		var count: int = spawn_points.get_child_count() if spawn_points else 0
		print("ASSERT FAIL: SpawnPoints has %d markers (need >= 6)" % count)

	var pickup_spots = level.get_node_or_null("PickupSpots")
	if pickup_spots and pickup_spots.get_child_count() >= 4:
		print("ASSERT PASS: PickupSpots has %d markers (>= 4)" % pickup_spots.get_child_count())
	else:
		var count: int = pickup_spots.get_child_count() if pickup_spots else 0
		print("ASSERT FAIL: PickupSpots has %d markers (need >= 4)" % count)

	var world_env = level.get_node_or_null("WorldEnvironment")
	if world_env:
		print("ASSERT PASS: WorldEnvironment exists")
	else:
		print("ASSERT FAIL: WorldEnvironment missing")

	var moonlight = level.get_node_or_null("Moonlight")
	if moonlight:
		print("ASSERT PASS: Moonlight exists")
	else:
		print("ASSERT FAIL: Moonlight missing")

	var buildings = level.get_node_or_null("NavigationRegion3D/Buildings")
	if buildings:
		var building_count := 0
		var sign_count := 0
		var light_count := 0
		for child in buildings.get_children():
			if child.name.begins_with("Building_"):
				building_count += 1
			elif child.name.begins_with("NeonSign_") or child.name.begins_with("LargeSign_"):
				sign_count += 1
			elif child.name.begins_with("NeonLight_") or child.name.begins_with("LargeSignLight_"):
				light_count += 1
		print("ASSERT PASS: Buildings=%d Signs=%d Lights=%d" % [building_count, sign_count, light_count])
	else:
		print("ASSERT FAIL: Buildings node missing")

	var cover = level.get_node_or_null("NavigationRegion3D/Cover")
	if cover and cover.get_child_count() > 10:
		print("ASSERT PASS: Cover objects=%d" % cover.get_child_count())
	else:
		var count: int = cover.get_child_count() if cover else 0
		print("ASSERT FAIL: Cover objects=%d (need > 10)" % count)


func _process(_delta: float) -> bool:
	_frame += 1

	# Camera positions — all in street corridors between buildings
	match _frame:
		1:
			# Frame 1: Main street looking north — narrow corridor, neon overhead
			_cam.position = Vector3(0, 1.7, 5)
			_cam.rotation_degrees = Vector3(-5, 0, 0)
		5:
			# Frame 5: Main street looking south — buildings on both sides
			_cam.position = Vector3(0, 1.7, -5)
			_cam.rotation_degrees = Vector3(-5, 180, 0)
		10:
			# Frame 10: Looking up at neon signs on east building wall
			_cam.position = Vector3(0, 1.7, 0)
			_cam.rotation_degrees = Vector3(15, 70, 0)
		15:
			# Frame 15: Looking up at neon on west building wall
			_cam.position = Vector3(0, 1.7, -3)
			_cam.rotation_degrees = Vector3(15, -70, 0)
		20:
			# Frame 20: Elevated street view — looking down the corridor
			_cam.position = Vector3(0, 8, 15)
			_cam.rotation_degrees = Vector3(-25, 0, 0)
		25:
			# Frame 25: Cover objects with neon atmosphere
			_cam.position = Vector3(1, 1.2, -1)
			_cam.rotation_degrees = Vector3(-5, 30, 0)
		30:
			# Frame 30: Low angle — neon canyon effect
			_cam.position = Vector3(0, 0.8, 2)
			_cam.rotation_degrees = Vector3(30, 0, 0)
		35:
			# Frame 35: Bird's eye — entire arena
			_cam.position = Vector3(0, 35, 0)
			_cam.rotation_degrees = Vector3(-80, 0, 0)

	_cam.current = true
	return false
