extends SceneTree
## Scene builder — run: timeout 120 godot --headless --script scenes/build_level_skyscraper.gd

func _initialize() -> void:
	print("Generating: Level (Skyscraper Rooftops)")
	seed(42)

	var root := Node3D.new()
	root.name = "Level"
	root.set_script(load("res://scripts/level_skyscraper_materials.gd"))

	# ── WorldEnvironment ──
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/img/sunset_sky.png")
	sky_mat.energy_multiplier = 0.8
	sky.sky_material = sky_mat
	env.sky = sky

	# Tonemap — ACES cinematic
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0

	# Ambient — warm sunset
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.25, 0.15)
	env.ambient_light_energy = 0.7

	# Color adjustment (toggled at runtime for death effect)
	env.adjustment_enabled = false
	env.adjustment_saturation = 1.0

	# Glow / Bloom
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.3
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE

	# Fog — warm haze (sky_affect low so skybox remains visible)
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.6, 0.3)
	env.fog_density = 0.003
	env.fog_sky_affect = 0.15

	# SSAO
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	env.ssao_radius = 1.5

	world_env.environment = env
	root.add_child(world_env)

	# ── Sunlight (warm sunset directional) ──
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.light_color = Color(1.0, 0.7, 0.3)
	sunlight.light_energy = 1.5
	sunlight.shadow_enabled = true
	sunlight.shadow_bias = 0.05
	sunlight.shadow_blur = 5.0
	sunlight.rotation_degrees = Vector3(-20, -30, 0)
	root.add_child(sunlight)

	# ── NavigationRegion3D ──
	var nav_region := NavigationRegion3D.new()
	nav_region.name = "NavigationRegion3D"
	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_max_climb = 0.3
	nav_mesh.agent_max_slope = 45.0
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_region.navigation_mesh = nav_mesh
	root.add_child(nav_region)

	# ── Materials ──
	var concrete_mat := StandardMaterial3D.new()
	concrete_mat.albedo_texture = load("res://assets/img/concrete_rooftop.png")
	concrete_mat.uv1_scale = Vector3(4, 4, 1)
	concrete_mat.roughness = 0.85

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_texture = load("res://assets/img/glass_window.png")
	glass_mat.uv1_scale = Vector3(4, 5, 1)
	glass_mat.roughness = 0.1
	glass_mat.metallic = 0.8

	var facade_mat := StandardMaterial3D.new()
	facade_mat.albedo_texture = load("res://assets/img/building_facade.png")
	facade_mat.uv1_scale = Vector3(1, 1, 1)

	var office_floor_mat := StandardMaterial3D.new()
	office_floor_mat.albedo_texture = load("res://assets/img/office_floor.png")
	office_floor_mat.uv1_scale = Vector3(4, 3, 1)
	office_floor_mat.roughness = 0.6

	var office_wall_mat := StandardMaterial3D.new()
	office_wall_mat.albedo_texture = load("res://assets/img/office_wall.png")
	office_wall_mat.uv1_scale = Vector3(2, 1, 1)
	office_wall_mat.roughness = 0.7

	var helipad_mat := StandardMaterial3D.new()
	helipad_mat.albedo_texture = load("res://assets/img/helipad_marking.png")
	helipad_mat.roughness = 0.9

	var railing_mat := StandardMaterial3D.new()
	railing_mat.albedo_texture = load("res://assets/img/metal_railing.png")
	railing_mat.roughness = 0.4
	railing_mat.metallic = 0.7

	var parapet_mat := StandardMaterial3D.new()
	parapet_mat.albedo_color = Color(0.35, 0.33, 0.3)
	parapet_mat.roughness = 0.9

	# ══════════════════════════════════════════════
	# ROOFTOP A (West Building) — centered at X=-20, Z=0
	# ══════════════════════════════════════════════
	var rooftop_a := Node3D.new()
	rooftop_a.name = "RooftopA"
	nav_region.add_child(rooftop_a)

	# Platform A — split into segments with stairwell gap
	# Hole at world (-12, 39.5, 7): X[-13.5, -10.5], Z[4.5, 9.5]
	# Platform spans X[-35, -5], Z[-15, 15]

	# North strip: full width, Z[-15, 4.5]
	var platform_a_n := CSGBox3D.new()
	platform_a_n.name = "PlatformA_N"
	platform_a_n.size = Vector3(30, 1, 19.5)
	platform_a_n.position = Vector3(-20, 39.5, -5.25)
	platform_a_n.use_collision = true
	platform_a_n.collision_layer = 4
	platform_a_n.collision_mask = 0
	platform_a_n.material = concrete_mat
	rooftop_a.add_child(platform_a_n)

	# South strip: full width, Z[9.5, 15]
	var platform_a_s := CSGBox3D.new()
	platform_a_s.name = "PlatformA_S"
	platform_a_s.size = Vector3(30, 1, 5.5)
	platform_a_s.position = Vector3(-20, 39.5, 12.25)
	platform_a_s.use_collision = true
	platform_a_s.collision_layer = 4
	platform_a_s.collision_mask = 0
	platform_a_s.material = concrete_mat
	rooftop_a.add_child(platform_a_s)

	# West strip: X[-35, -13.5], Z[4.5, 9.5]
	var platform_a_w := CSGBox3D.new()
	platform_a_w.name = "PlatformA_W"
	platform_a_w.size = Vector3(21.5, 1, 5)
	platform_a_w.position = Vector3(-24.25, 39.5, 7)
	platform_a_w.use_collision = true
	platform_a_w.collision_layer = 4
	platform_a_w.collision_mask = 0
	platform_a_w.material = concrete_mat
	rooftop_a.add_child(platform_a_w)

	# East strip: X[-10.5, -5], Z[4.5, 9.5]
	var platform_a_e := CSGBox3D.new()
	platform_a_e.name = "PlatformA_E"
	platform_a_e.size = Vector3(5.5, 1, 5)
	platform_a_e.position = Vector3(-7.75, 39.5, 7)
	platform_a_e.use_collision = true
	platform_a_e.collision_layer = 4
	platform_a_e.collision_mask = 0
	platform_a_e.material = concrete_mat
	rooftop_a.add_child(platform_a_e)

	# Parapet walls — North, South, West (full), East (with gap for bridge)
	var parapet_a_north := CSGBox3D.new()
	parapet_a_north.name = "ParapetA_North"
	parapet_a_north.size = Vector3(30, 1, 0.3)
	parapet_a_north.position = Vector3(-20, 40.5, -15)
	parapet_a_north.use_collision = true
	parapet_a_north.collision_layer = 4
	parapet_a_north.collision_mask = 0
	parapet_a_north.material = parapet_mat
	rooftop_a.add_child(parapet_a_north)

	var parapet_a_south := CSGBox3D.new()
	parapet_a_south.name = "ParapetA_South"
	parapet_a_south.size = Vector3(30, 1, 0.3)
	parapet_a_south.position = Vector3(-20, 40.5, 15)
	parapet_a_south.use_collision = true
	parapet_a_south.collision_layer = 4
	parapet_a_south.collision_mask = 0
	parapet_a_south.material = parapet_mat
	rooftop_a.add_child(parapet_a_south)

	var parapet_a_west := CSGBox3D.new()
	parapet_a_west.name = "ParapetA_West"
	parapet_a_west.size = Vector3(0.3, 1, 30)
	parapet_a_west.position = Vector3(-35, 40.5, 0)
	parapet_a_west.use_collision = true
	parapet_a_west.collision_layer = 4
	parapet_a_west.collision_mask = 0
	parapet_a_west.material = parapet_mat
	rooftop_a.add_child(parapet_a_west)

	# East parapet with gap — two segments leaving 4m gap in center
	var parapet_a_east_n := CSGBox3D.new()
	parapet_a_east_n.name = "ParapetA_East_N"
	parapet_a_east_n.size = Vector3(0.3, 1, 13)
	parapet_a_east_n.position = Vector3(-5, 40.5, -8.5)
	parapet_a_east_n.use_collision = true
	parapet_a_east_n.collision_layer = 4
	parapet_a_east_n.collision_mask = 0
	parapet_a_east_n.material = parapet_mat
	rooftop_a.add_child(parapet_a_east_n)

	var parapet_a_east_s := CSGBox3D.new()
	parapet_a_east_s.name = "ParapetA_East_S"
	parapet_a_east_s.size = Vector3(0.3, 1, 13)
	parapet_a_east_s.position = Vector3(-5, 40.5, 8.5)
	parapet_a_east_s.use_collision = true
	parapet_a_east_s.collision_layer = 4
	parapet_a_east_s.collision_mask = 0
	parapet_a_east_s.material = parapet_mat
	rooftop_a.add_child(parapet_a_east_s)

	# AC Units (5 units for cover)
	var ac_positions: Array = [
		Vector3(-25, 40, -8),
		Vector3(-28, 40, 5),
		Vector3(-15, 40, -12),
		Vector3(-18, 40, 10),
		Vector3(-30, 40, 0),
	]
	var ac_rotations: Array = [0.0, 15.0, -10.0, 25.0, -5.0]
	for i in range(ac_positions.size()):
		var ac_scene: PackedScene = load("res://assets/glb/ac_unit.glb")
		var ac = ac_scene.instantiate()
		ac.name = "ACUnit_%d" % i
		var apos: Vector3 = ac_positions[i]
		ac.position = apos
		ac.rotation_degrees.y = ac_rotations[i]
		rooftop_a.add_child(ac)

	# Roof Door Structure A
	var door_struct_a := Node3D.new()
	door_struct_a.name = "DoorStructA"
	door_struct_a.position = Vector3(-12, 40, 8)
	rooftop_a.add_child(door_struct_a)

	# Back wall (north) — REMOVED: was blocking stairwell path

	# Left wall (west)
	var ds_a_left := CSGBox3D.new()
	ds_a_left.name = "DoorStructA_Left"
	ds_a_left.size = Vector3(0.2, 3, 3)
	ds_a_left.position = Vector3(-1.4, 1.5, 0)
	ds_a_left.use_collision = true
	ds_a_left.collision_layer = 4
	ds_a_left.collision_mask = 0
	ds_a_left.material = facade_mat
	door_struct_a.add_child(ds_a_left)

	# Right wall (east)
	var ds_a_right := CSGBox3D.new()
	ds_a_right.name = "DoorStructA_Right"
	ds_a_right.size = Vector3(0.2, 3, 3)
	ds_a_right.position = Vector3(1.4, 1.5, 0)
	ds_a_right.use_collision = true
	ds_a_right.collision_layer = 4
	ds_a_right.collision_mask = 0
	ds_a_right.material = facade_mat
	door_struct_a.add_child(ds_a_right)

	# Roof of door structure
	var ds_a_roof := CSGBox3D.new()
	ds_a_roof.name = "DoorStructA_Roof"
	ds_a_roof.size = Vector3(3, 0.2, 3)
	ds_a_roof.position = Vector3(0, 3.1, 0)
	ds_a_roof.use_collision = true
	ds_a_roof.collision_layer = 4
	ds_a_roof.collision_mask = 0
	ds_a_roof.material = facade_mat
	door_struct_a.add_child(ds_a_roof)

	# Stairwell A — 16 steps descending from Y=40 to Y=36 (0.25m rise each)
	var stairs_a := Node3D.new()
	stairs_a.name = "StairsA"
	nav_region.add_child(stairs_a)
	for step_i in range(16):
		var step := CSGBox3D.new()
		step.name = "StairA_%d" % step_i
		step.size = Vector3(2, 0.25, 0.5)
		# Steps go north (-Z) from door structure at (-12, 40, 8), descending (first step below platform)
		step.position = Vector3(-12, 39.75 - step_i * 0.25 - 0.125, 8.0 - step_i * 0.5)
		step.use_collision = true
		step.collision_layer = 4
		step.collision_mask = 0
		step.material = concrete_mat
		stairs_a.add_child(step)

	# Stairwell A enclosure walls
	var stairwell_a_west := CSGBox3D.new()
	stairwell_a_west.name = "StairwellA_West"
	stairwell_a_west.size = Vector3(0.2, 4, 8)
	stairwell_a_west.position = Vector3(-13, 38, 4)
	stairwell_a_west.use_collision = true
	stairwell_a_west.collision_layer = 4
	stairwell_a_west.collision_mask = 0
	stairwell_a_west.material = office_wall_mat
	nav_region.add_child(stairwell_a_west)

	var stairwell_a_east := CSGBox3D.new()
	stairwell_a_east.name = "StairwellA_East"
	stairwell_a_east.size = Vector3(0.2, 4, 8)
	stairwell_a_east.position = Vector3(-11, 38, 4)
	stairwell_a_east.use_collision = true
	stairwell_a_east.collision_layer = 4
	stairwell_a_east.collision_mask = 0
	stairwell_a_east.material = office_wall_mat
	nav_region.add_child(stairwell_a_east)

	# ── Office Floor A at Y=36 ──
	var office_a := Node3D.new()
	office_a.name = "OfficeA"
	nav_region.add_child(office_a)

	# Floor plate
	var floor_a := CSGBox3D.new()
	floor_a.name = "FloorA"
	floor_a.size = Vector3(20, 0.5, 15)
	floor_a.position = Vector3(-20, 35.75, 0)
	floor_a.use_collision = true
	floor_a.collision_layer = 4
	floor_a.collision_mask = 0
	floor_a.material = office_floor_mat
	office_a.add_child(floor_a)

	# Ceiling A — split segments with physical gap for stairwell
	# (Replaces CSGCombiner3D boolean subtraction which left collision intact)
	var ceiling_a_north := CSGBox3D.new()
	ceiling_a_north.name = "CeilingA_North"
	ceiling_a_north.size = Vector3(20, 0.3, 13)
	ceiling_a_north.position = Vector3(-20, 39.7, -1)
	ceiling_a_north.use_collision = true
	ceiling_a_north.collision_layer = 4
	ceiling_a_north.collision_mask = 0
	ceiling_a_north.material = office_wall_mat
	office_a.add_child(ceiling_a_north)

	var ceiling_a_sw := CSGBox3D.new()
	ceiling_a_sw.name = "CeilingA_SW"
	ceiling_a_sw.size = Vector3(16.5, 0.3, 2)
	ceiling_a_sw.position = Vector3(-21.75, 39.7, 6.5)
	ceiling_a_sw.use_collision = true
	ceiling_a_sw.collision_layer = 4
	ceiling_a_sw.collision_mask = 0
	ceiling_a_sw.material = office_wall_mat
	office_a.add_child(ceiling_a_sw)

	var ceiling_a_se := CSGBox3D.new()
	ceiling_a_se.name = "CeilingA_SE"
	ceiling_a_se.size = Vector3(0.5, 0.3, 2)
	ceiling_a_se.position = Vector3(-10.25, 39.7, 6.5)
	ceiling_a_se.use_collision = true
	ceiling_a_se.collision_layer = 4
	ceiling_a_se.collision_mask = 0
	ceiling_a_se.material = office_wall_mat
	office_a.add_child(ceiling_a_se)

	# Outer walls for office A
	var ow_a_north := CSGBox3D.new()
	ow_a_north.name = "OfficeA_WallN"
	ow_a_north.size = Vector3(20, 3.7, 0.2)
	ow_a_north.position = Vector3(-20, 37.85, -7.4)
	ow_a_north.use_collision = true
	ow_a_north.collision_layer = 4
	ow_a_north.collision_mask = 0
	ow_a_north.material = office_wall_mat
	office_a.add_child(ow_a_north)

	var ow_a_south := CSGBox3D.new()
	ow_a_south.name = "OfficeA_WallS"
	ow_a_south.size = Vector3(20, 3.7, 0.2)
	ow_a_south.position = Vector3(-20, 37.85, 7.4)
	ow_a_south.use_collision = true
	ow_a_south.collision_layer = 4
	ow_a_south.collision_mask = 0
	ow_a_south.material = office_wall_mat
	office_a.add_child(ow_a_south)

	var ow_a_west := CSGBox3D.new()
	ow_a_west.name = "OfficeA_WallW"
	ow_a_west.size = Vector3(0.2, 3.7, 15)
	ow_a_west.position = Vector3(-30, 37.85, 0)
	ow_a_west.use_collision = true
	ow_a_west.collision_layer = 4
	ow_a_west.collision_mask = 0
	ow_a_west.material = office_wall_mat
	office_a.add_child(ow_a_west)

	var ow_a_east := CSGBox3D.new()
	ow_a_east.name = "OfficeA_WallE"
	ow_a_east.size = Vector3(0.2, 3.7, 15)
	ow_a_east.position = Vector3(-10, 37.85, 0)
	ow_a_east.use_collision = true
	ow_a_east.collision_layer = 4
	ow_a_east.collision_mask = 0
	ow_a_east.material = office_wall_mat
	office_a.add_child(ow_a_east)

	# Interior partitions for 3 rooms — 2 walls with doorway openings
	# Partition 1: divides at Z=-2.5 (north room from center room)
	_add_partition_wall(office_a, "OfficeA_Part1", Vector3(-20, 37.85, -2.5), Vector3(20, 3.7, 0.15), office_wall_mat)
	# Partition 2: divides at Z=2.5 (center room from south room)
	_add_partition_wall(office_a, "OfficeA_Part2", Vector3(-20, 37.85, 2.5), Vector3(20, 3.7, 0.15), office_wall_mat)

	# Office furniture per room (3 rooms in A)
	_add_office_furniture(office_a, "OfficeA_Room0", Vector3(-24, 36, -5), Vector3(-17, 36, -5))
	_add_office_furniture(office_a, "OfficeA_Room1", Vector3(-24, 36, 0), Vector3(-17, 36, 0))
	_add_office_furniture(office_a, "OfficeA_Room2", Vector3(-24, 36, 5), Vector3(-17, 36, 5))

	# Interior lighting — 2 SpotLight3D per room
	_add_office_lights(office_a, "OfficeA", [
		Vector3(-22, 39.5, -5), Vector3(-16, 39.5, -5),
		Vector3(-22, 39.5, 0), Vector3(-16, 39.5, 0),
		Vector3(-22, 39.5, 5), Vector3(-16, 39.5, 5),
	])

	# ══════════════════════════════════════════════
	# ROOFTOP B (East Building) — centered at X=25, Z=0
	# ══════════════════════════════════════════════
	var rooftop_b := Node3D.new()
	rooftop_b.name = "RooftopB"
	nav_region.add_child(rooftop_b)

	# Platform B — split into segments with stairwell gap
	# Hole at world (20, 39.5, 4): X[18.5, 21.5], Z[1.5, 6.5]
	# Platform spans X[12.5, 37.5], Z[-12.5, 12.5]

	# North strip: full width, Z[-12.5, 1.5]
	var platform_b_n := CSGBox3D.new()
	platform_b_n.name = "PlatformB_N"
	platform_b_n.size = Vector3(25, 1, 14)
	platform_b_n.position = Vector3(25, 39.5, -5.5)
	platform_b_n.use_collision = true
	platform_b_n.collision_layer = 4
	platform_b_n.collision_mask = 0
	platform_b_n.material = concrete_mat
	rooftop_b.add_child(platform_b_n)

	# South strip: full width, Z[6.5, 12.5]
	var platform_b_s := CSGBox3D.new()
	platform_b_s.name = "PlatformB_S"
	platform_b_s.size = Vector3(25, 1, 6)
	platform_b_s.position = Vector3(25, 39.5, 9.5)
	platform_b_s.use_collision = true
	platform_b_s.collision_layer = 4
	platform_b_s.collision_mask = 0
	platform_b_s.material = concrete_mat
	rooftop_b.add_child(platform_b_s)

	# West strip: X[12.5, 18.5], Z[1.5, 6.5]
	var platform_b_w := CSGBox3D.new()
	platform_b_w.name = "PlatformB_W"
	platform_b_w.size = Vector3(6, 1, 5)
	platform_b_w.position = Vector3(15.5, 39.5, 4)
	platform_b_w.use_collision = true
	platform_b_w.collision_layer = 4
	platform_b_w.collision_mask = 0
	platform_b_w.material = concrete_mat
	rooftop_b.add_child(platform_b_w)

	# East strip: X[21.5, 37.5], Z[1.5, 6.5]
	var platform_b_e := CSGBox3D.new()
	platform_b_e.name = "PlatformB_E"
	platform_b_e.size = Vector3(16, 1, 5)
	platform_b_e.position = Vector3(29.5, 39.5, 4)
	platform_b_e.use_collision = true
	platform_b_e.collision_layer = 4
	platform_b_e.collision_mask = 0
	platform_b_e.material = concrete_mat
	rooftop_b.add_child(platform_b_e)

	# Parapet walls B — gap on WEST side
	var parapet_b_north := CSGBox3D.new()
	parapet_b_north.name = "ParapetB_North"
	parapet_b_north.size = Vector3(25, 1, 0.3)
	parapet_b_north.position = Vector3(25, 40.5, -12.5)
	parapet_b_north.use_collision = true
	parapet_b_north.collision_layer = 4
	parapet_b_north.collision_mask = 0
	parapet_b_north.material = parapet_mat
	rooftop_b.add_child(parapet_b_north)

	var parapet_b_south := CSGBox3D.new()
	parapet_b_south.name = "ParapetB_South"
	parapet_b_south.size = Vector3(25, 1, 0.3)
	parapet_b_south.position = Vector3(25, 40.5, 12.5)
	parapet_b_south.use_collision = true
	parapet_b_south.collision_layer = 4
	parapet_b_south.collision_mask = 0
	parapet_b_south.material = parapet_mat
	rooftop_b.add_child(parapet_b_south)

	var parapet_b_east := CSGBox3D.new()
	parapet_b_east.name = "ParapetB_East"
	parapet_b_east.size = Vector3(0.3, 1, 25)
	parapet_b_east.position = Vector3(37.5, 40.5, 0)
	parapet_b_east.use_collision = true
	parapet_b_east.collision_layer = 4
	parapet_b_east.collision_mask = 0
	parapet_b_east.material = parapet_mat
	rooftop_b.add_child(parapet_b_east)

	# West parapet with gap — two segments leaving 4m gap
	var parapet_b_west_n := CSGBox3D.new()
	parapet_b_west_n.name = "ParapetB_West_N"
	parapet_b_west_n.size = Vector3(0.3, 1, 10.5)
	parapet_b_west_n.position = Vector3(12.5, 40.5, -7.25)
	parapet_b_west_n.use_collision = true
	parapet_b_west_n.collision_layer = 4
	parapet_b_west_n.collision_mask = 0
	parapet_b_west_n.material = parapet_mat
	rooftop_b.add_child(parapet_b_west_n)

	var parapet_b_west_s := CSGBox3D.new()
	parapet_b_west_s.name = "ParapetB_West_S"
	parapet_b_west_s.size = Vector3(0.3, 1, 10.5)
	parapet_b_west_s.position = Vector3(12.5, 40.5, 7.25)
	parapet_b_west_s.use_collision = true
	parapet_b_west_s.collision_layer = 4
	parapet_b_west_s.collision_mask = 0
	parapet_b_west_s.material = parapet_mat
	rooftop_b.add_child(parapet_b_west_s)

	# Helipad
	var helipad := CSGCylinder3D.new()
	helipad.name = "Helipad"
	helipad.radius = 4.0
	helipad.height = 0.1
	helipad.position = Vector3(30, 40.05, -5)
	helipad.use_collision = true
	helipad.collision_layer = 4
	helipad.collision_mask = 0
	helipad.material = helipad_mat
	rooftop_b.add_child(helipad)

	# Walkways along north and east edges (2m wide strips)
	var walkway_north := CSGBox3D.new()
	walkway_north.name = "WalkwayNorth"
	walkway_north.size = Vector3(25, 0.15, 2)
	walkway_north.position = Vector3(25, 40.05, -11.5)
	walkway_north.use_collision = true
	walkway_north.collision_layer = 4
	walkway_north.collision_mask = 0
	walkway_north.material = railing_mat
	rooftop_b.add_child(walkway_north)

	var walkway_east := CSGBox3D.new()
	walkway_east.name = "WalkwayEast"
	walkway_east.size = Vector3(2, 0.15, 25)
	walkway_east.position = Vector3(36.5, 40.05, 0)
	walkway_east.use_collision = true
	walkway_east.collision_layer = 4
	walkway_east.collision_mask = 0
	walkway_east.material = railing_mat
	rooftop_b.add_child(walkway_east)

	# Railings (thin CSGBox3D, 1m tall, 0.05m thick at walkway edges)
	var railing_data: Array = [
		# North walkway outer railing
		{"pos": Vector3(25, 40.55, -12.45), "size": Vector3(25, 1, 0.05)},
		# North walkway inner railing
		{"pos": Vector3(25, 40.55, -10.55), "size": Vector3(25, 1, 0.05)},
		# East walkway outer railing
		{"pos": Vector3(37.45, 40.55, 0), "size": Vector3(0.05, 1, 25)},
		# East walkway inner railing
		{"pos": Vector3(35.55, 40.55, 0), "size": Vector3(0.05, 1, 25)},
	]
	for ri in range(railing_data.size()):
		var rd = railing_data[ri]
		var rail := CSGBox3D.new()
		rail.name = "Railing_%d" % ri
		var rpos: Vector3 = rd["pos"]
		var rsize: Vector3 = rd["size"]
		rail.position = rpos
		rail.size = rsize
		rail.use_collision = true
		rail.collision_layer = 4
		rail.collision_mask = 0
		rail.material = railing_mat
		rooftop_b.add_child(rail)

	# Roof Door Structure B
	var door_struct_b := Node3D.new()
	door_struct_b.name = "DoorStructB"
	door_struct_b.position = Vector3(20, 40, 5)
	rooftop_b.add_child(door_struct_b)

	# Back wall (north) — REMOVED: was blocking stairwell path

	var ds_b_left := CSGBox3D.new()
	ds_b_left.name = "DoorStructB_Left"
	ds_b_left.size = Vector3(0.2, 3, 3)
	ds_b_left.position = Vector3(-1.4, 1.5, 0)
	ds_b_left.use_collision = true
	ds_b_left.collision_layer = 4
	ds_b_left.collision_mask = 0
	ds_b_left.material = facade_mat
	door_struct_b.add_child(ds_b_left)

	var ds_b_right := CSGBox3D.new()
	ds_b_right.name = "DoorStructB_Right"
	ds_b_right.size = Vector3(0.2, 3, 3)
	ds_b_right.position = Vector3(1.4, 1.5, 0)
	ds_b_right.use_collision = true
	ds_b_right.collision_layer = 4
	ds_b_right.collision_mask = 0
	ds_b_right.material = facade_mat
	door_struct_b.add_child(ds_b_right)

	var ds_b_roof := CSGBox3D.new()
	ds_b_roof.name = "DoorStructB_Roof"
	ds_b_roof.size = Vector3(3, 0.2, 3)
	ds_b_roof.position = Vector3(0, 3.1, 0)
	ds_b_roof.use_collision = true
	ds_b_roof.collision_layer = 4
	ds_b_roof.collision_mask = 0
	ds_b_roof.material = facade_mat
	door_struct_b.add_child(ds_b_roof)

	# Stairwell B — 16 steps descending from Y=40 to Y=36 (0.25m rise each)
	var stairs_b := Node3D.new()
	stairs_b.name = "StairsB"
	nav_region.add_child(stairs_b)
	for step_i in range(16):
		var step := CSGBox3D.new()
		step.name = "StairB_%d" % step_i
		step.size = Vector3(2, 0.25, 0.5)
		# Steps go north (-Z) from door structure at (20, 40, 5), descending (first step below platform)
		step.position = Vector3(20, 39.75 - step_i * 0.25 - 0.125, 5.0 - step_i * 0.5)
		step.use_collision = true
		step.collision_layer = 4
		step.collision_mask = 0
		step.material = concrete_mat
		stairs_b.add_child(step)

	# Stairwell B enclosure walls
	var stairwell_b_west := CSGBox3D.new()
	stairwell_b_west.name = "StairwellB_West"
	stairwell_b_west.size = Vector3(0.2, 4, 8)
	stairwell_b_west.position = Vector3(19, 38, 1)
	stairwell_b_west.use_collision = true
	stairwell_b_west.collision_layer = 4
	stairwell_b_west.collision_mask = 0
	stairwell_b_west.material = office_wall_mat
	nav_region.add_child(stairwell_b_west)

	var stairwell_b_east := CSGBox3D.new()
	stairwell_b_east.name = "StairwellB_East"
	stairwell_b_east.size = Vector3(0.2, 4, 8)
	stairwell_b_east.position = Vector3(21, 38, 1)
	stairwell_b_east.use_collision = true
	stairwell_b_east.collision_layer = 4
	stairwell_b_east.collision_mask = 0
	stairwell_b_east.material = office_wall_mat
	nav_region.add_child(stairwell_b_east)

	# ── Office Floor B at Y=36 ──
	var office_b := Node3D.new()
	office_b.name = "OfficeB"
	nav_region.add_child(office_b)

	# Floor plate (smaller)
	var floor_b := CSGBox3D.new()
	floor_b.name = "FloorB"
	floor_b.size = Vector3(15, 0.5, 12)
	floor_b.position = Vector3(25, 35.75, 0)
	floor_b.use_collision = true
	floor_b.collision_layer = 4
	floor_b.collision_mask = 0
	floor_b.material = office_floor_mat
	office_b.add_child(floor_b)

	# Ceiling B — split segments with physical gap for stairwell
	var ceiling_b_north := CSGBox3D.new()
	ceiling_b_north.name = "CeilingB_North"
	ceiling_b_north.size = Vector3(15, 0.3, 7.5)
	ceiling_b_north.position = Vector3(25, 39.7, -2.25)
	ceiling_b_north.use_collision = true
	ceiling_b_north.collision_layer = 4
	ceiling_b_north.collision_mask = 0
	ceiling_b_north.material = office_wall_mat
	office_b.add_child(ceiling_b_north)

	var ceiling_b_sw := CSGBox3D.new()
	ceiling_b_sw.name = "CeilingB_SW"
	ceiling_b_sw.size = Vector3(1, 0.3, 4.5)
	ceiling_b_sw.position = Vector3(18, 39.7, 3.75)
	ceiling_b_sw.use_collision = true
	ceiling_b_sw.collision_layer = 4
	ceiling_b_sw.collision_mask = 0
	ceiling_b_sw.material = office_wall_mat
	office_b.add_child(ceiling_b_sw)

	var ceiling_b_se := CSGBox3D.new()
	ceiling_b_se.name = "CeilingB_SE"
	ceiling_b_se.size = Vector3(11, 0.3, 4.5)
	ceiling_b_se.position = Vector3(27, 39.7, 3.75)
	ceiling_b_se.use_collision = true
	ceiling_b_se.collision_layer = 4
	ceiling_b_se.collision_mask = 0
	ceiling_b_se.material = office_wall_mat
	office_b.add_child(ceiling_b_se)

	# Outer walls for office B
	var ow_b_north := CSGBox3D.new()
	ow_b_north.name = "OfficeB_WallN"
	ow_b_north.size = Vector3(15, 3.7, 0.2)
	ow_b_north.position = Vector3(25, 37.85, -5.9)
	ow_b_north.use_collision = true
	ow_b_north.collision_layer = 4
	ow_b_north.collision_mask = 0
	ow_b_north.material = office_wall_mat
	office_b.add_child(ow_b_north)

	var ow_b_south := CSGBox3D.new()
	ow_b_south.name = "OfficeB_WallS"
	ow_b_south.size = Vector3(15, 3.7, 0.2)
	ow_b_south.position = Vector3(25, 37.85, 5.9)
	ow_b_south.use_collision = true
	ow_b_south.collision_layer = 4
	ow_b_south.collision_mask = 0
	ow_b_south.material = office_wall_mat
	office_b.add_child(ow_b_south)

	var ow_b_west := CSGBox3D.new()
	ow_b_west.name = "OfficeB_WallW"
	ow_b_west.size = Vector3(0.2, 3.7, 12)
	ow_b_west.position = Vector3(17.5, 37.85, 0)
	ow_b_west.use_collision = true
	ow_b_west.collision_layer = 4
	ow_b_west.collision_mask = 0
	ow_b_west.material = office_wall_mat
	office_b.add_child(ow_b_west)

	var ow_b_east := CSGBox3D.new()
	ow_b_east.name = "OfficeB_WallE"
	ow_b_east.size = Vector3(0.2, 3.7, 12)
	ow_b_east.position = Vector3(32.5, 37.85, 0)
	ow_b_east.use_collision = true
	ow_b_east.collision_layer = 4
	ow_b_east.collision_mask = 0
	ow_b_east.material = office_wall_mat
	office_b.add_child(ow_b_east)

	# Interior partition for 2 rooms
	_add_partition_wall(office_b, "OfficeB_Part1", Vector3(25, 37.85, 0), Vector3(15, 3.7, 0.15), office_wall_mat)

	# Office furniture (2 rooms in B)
	_add_office_furniture(office_b, "OfficeB_Room0", Vector3(21, 36, -3), Vector3(28, 36, -3))
	_add_office_furniture(office_b, "OfficeB_Room1", Vector3(21, 36, 3), Vector3(28, 36, 3))

	# Interior lighting B
	_add_office_lights(office_b, "OfficeB", [
		Vector3(22, 39.5, -3), Vector3(28, 39.5, -3),
		Vector3(22, 39.5, 3), Vector3(28, 39.5, 3),
	])

	# ══════════════════════════════════════════════
	# SKY BRIDGE — connecting the two rooftops
	# ══════════════════════════════════════════════
	var bridge := Node3D.new()
	bridge.name = "SkyBridge"
	nav_region.add_child(bridge)

	# Bridge floor: spans from X=-5 to X=12.5 = 17.5m long
	var bridge_floor := CSGBox3D.new()
	bridge_floor.name = "BridgeFloor"
	bridge_floor.size = Vector3(17.5, 0.5, 4)
	bridge_floor.position = Vector3(3.75, 39.75, 0)
	bridge_floor.use_collision = true
	bridge_floor.collision_layer = 4
	bridge_floor.collision_mask = 0
	bridge_floor.material = concrete_mat
	bridge.add_child(bridge_floor)

	# Glass side walls — semi-transparent blue
	var glass_wall_mat := StandardMaterial3D.new()
	glass_wall_mat.albedo_color = Color(0.3, 0.5, 0.8, 0.4)
	glass_wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_wall_mat.roughness = 0.05
	glass_wall_mat.metallic = 0.3

	var glass_north := CSGBox3D.new()
	glass_north.name = "BridgeGlass_North"
	glass_north.size = Vector3(17.5, 1.5, 0.1)
	glass_north.position = Vector3(3.75, 40.75, -1.95)
	glass_north.use_collision = true
	glass_north.collision_layer = 4
	glass_north.collision_mask = 0
	glass_north.material = glass_wall_mat
	bridge.add_child(glass_north)

	var glass_south := CSGBox3D.new()
	glass_south.name = "BridgeGlass_South"
	glass_south.size = Vector3(17.5, 1.5, 0.1)
	glass_south.position = Vector3(3.75, 40.75, 1.95)
	glass_south.use_collision = true
	glass_south.collision_layer = 4
	glass_south.collision_mask = 0
	glass_south.material = glass_wall_mat
	bridge.add_child(glass_south)

	# Cover pillars — 3 columns along the bridge
	var pillar_positions: Array = [Vector3(-1.0, 40.0, 0), Vector3(3.75, 40.0, 0), Vector3(8.5, 40.0, 0)]
	for pi in range(pillar_positions.size()):
		var pillar := CSGBox3D.new()
		pillar.name = "BridgePillar_%d" % pi
		pillar.size = Vector3(0.5, 2, 0.5)
		var ppos: Vector3 = pillar_positions[pi]
		pillar.position = ppos
		pillar.use_collision = true
		pillar.collision_layer = 4
		pillar.collision_mask = 0
		pillar.material = parapet_mat
		bridge.add_child(pillar)

	# ══════════════════════════════════════════════
	# ROOFTOP CRATES — random large/small, some stacked
	# ══════════════════════════════════════════════
	var crate_mat := StandardMaterial3D.new()
	crate_mat.albedo_color = Color(0.45, 0.35, 0.2)
	crate_mat.roughness = 0.9

	# Rooftop A crates
	var crates_a_data: Array = [
		# [position, size] — large crates ~1.5m, small crates ~0.6-0.8m
		[Vector3(-28, 40.75, -12), Vector3(1.5, 1.5, 1.5)],   # large, NW corner
		[Vector3(-28, 42.15, -12), Vector3(0.6, 0.6, 0.6)],   # small stacked on top
		[Vector3(-16, 40.4, -13), Vector3(0.8, 0.8, 0.8)],    # small, N edge
		[Vector3(-32, 40.6, 5), Vector3(1.2, 1.2, 1.2)],      # medium, SW area
		[Vector3(-32, 41.7, 5), Vector3(0.7, 0.7, 0.7)],      # small stacked on top
		[Vector3(-33, 40.4, -5), Vector3(0.8, 0.8, 1.2)],     # small, W edge
	]
	for ci in range(crates_a_data.size()):
		var cd: Array = crates_a_data[ci]
		var crate := CSGBox3D.new()
		crate.name = "CrateA_%d" % ci
		var cpos: Vector3 = cd[0]
		var csize: Vector3 = cd[1]
		crate.position = cpos
		crate.size = csize
		crate.rotation_degrees.y = randf_range(-15.0, 15.0)
		crate.use_collision = true
		crate.collision_layer = 4
		crate.collision_mask = 0
		crate.material = crate_mat
		rooftop_a.add_child(crate)

	# Rooftop B crates
	var crates_b_data: Array = [
		[Vector3(35, 40.75, 8), Vector3(1.5, 1.5, 1.5)],      # large, SE area
		[Vector3(35, 42.15, 8), Vector3(0.8, 0.6, 0.8)],      # small stacked
		[Vector3(18, 40.5, -11), Vector3(1.0, 1.0, 1.0)],     # medium, N edge
		[Vector3(33, 40.4, -10), Vector3(0.7, 0.8, 0.7)],     # small, NE
		[Vector3(15, 40.6, 10), Vector3(1.2, 1.2, 1.0)],      # medium, S edge
		[Vector3(15, 41.7, 10), Vector3(0.6, 0.6, 0.6)],      # small stacked
	]
	for ci in range(crates_b_data.size()):
		var cd: Array = crates_b_data[ci]
		var crate := CSGBox3D.new()
		crate.name = "CrateB_%d" % ci
		var cpos: Vector3 = cd[0]
		var csize: Vector3 = cd[1]
		crate.position = cpos
		crate.size = csize
		crate.rotation_degrees.y = randf_range(-15.0, 15.0)
		crate.use_collision = true
		crate.collision_layer = 4
		crate.collision_mask = 0
		crate.material = crate_mat
		rooftop_b.add_child(crate)

	# ══════════════════════════════════════════════
	# OFFICE PROPS — water coolers and plants in corners
	# ══════════════════════════════════════════════

	# Water cooler: tall cylinder (body) + small cylinder (jug) on top
	# Plant: cylinder pot + small sphere/cylinder for foliage

	# Office A corners — 4 corners, alternate water cooler / plant
	# Office A bounds: X[-30..-10], Z[-7.4..7.4], floor Y=36
	_add_water_cooler(office_a, "OfficeA_WaterCooler0", Vector3(-29, 36, -6.5), concrete_mat)
	_add_plant(office_a, "OfficeA_Plant0", Vector3(-11, 36, -6.5))
	_add_water_cooler(office_a, "OfficeA_WaterCooler1", Vector3(-29, 36, 6.5), concrete_mat)
	_add_plant(office_a, "OfficeA_Plant1", Vector3(-11, 36, 6.5))

	# Office B corners — 4 corners
	# Office B bounds: X[17.5..32.5], Z[-5.9..5.9], floor Y=36
	_add_water_cooler(office_b, "OfficeB_WaterCooler0", Vector3(18.5, 36, -5), concrete_mat)
	_add_plant(office_b, "OfficeB_Plant0", Vector3(31.5, 36, -5))
	_add_water_cooler(office_b, "OfficeB_WaterCooler1", Vector3(18.5, 36, 5), concrete_mat)
	_add_plant(office_b, "OfficeB_Plant1", Vector3(31.5, 36, 5))

	# ══════════════════════════════════════════════
	# BUILDING FACADES (tall columns below rooftops)
	# ══════════════════════════════════════════════
	var facades := Node3D.new()
	facades.name = "Facades"
	root.add_child(facades)

	# Building A facade
	var facade_a := CSGBox3D.new()
	facade_a.name = "FacadeA"
	facade_a.size = Vector3(30, 36, 30)
	facade_a.position = Vector3(-20, 17.5, 0)
	facade_a.use_collision = true
	facade_a.collision_layer = 4
	facade_a.collision_mask = 0
	facade_a.material = glass_mat
	facades.add_child(facade_a)

	# Building B facade
	var facade_b := CSGBox3D.new()
	facade_b.name = "FacadeB"
	facade_b.size = Vector3(25, 36, 25)
	facade_b.position = Vector3(25, 17.5, 0)
	facade_b.use_collision = true
	facade_b.collision_layer = 4
	facade_b.collision_mask = 0
	facade_b.material = glass_mat
	facades.add_child(facade_b)

	# ══════════════════════════════════════════════
	# KILL ZONE — Area3D at Y=10
	# ══════════════════════════════════════════════
	var kill_zone := Area3D.new()
	kill_zone.name = "KillZone"
	kill_zone.position = Vector3(0, -10, 0)
	kill_zone.collision_layer = 0
	kill_zone.collision_mask = 3  # player (1) + bots (2)
	kill_zone.set_script(load("res://scripts/kill_zone.gd"))
	root.add_child(kill_zone)

	var kz_col := CollisionShape3D.new()
	kz_col.name = "KillZoneShape"
	var kz_shape := BoxShape3D.new()
	kz_shape.size = Vector3(200, 40, 200)
	kz_col.shape = kz_shape
	kill_zone.add_child(kz_col)

	# ══════════════════════════════════════════════
	# SPAWN POINTS (8 Marker3D nodes)
	# ══════════════════════════════════════════════
	var spawn_points := Node3D.new()
	spawn_points.name = "SpawnPoints"
	root.add_child(spawn_points)

	var spawn_positions: Array = [
		Vector3(-25, 41, -10),   # Rooftop A, NW corner near AC
		Vector3(-15, 41, 8),     # Rooftop A, near roof door
		Vector3(-28, 41, 12),    # Rooftop A, SW area
		Vector3(30, 41, -5),     # Rooftop B, near helipad
		Vector3(20, 41, 5),      # Rooftop B, near roof door
		Vector3(18, 41, -10),    # Rooftop B, NE area
		Vector3(3.75, 41, 0),    # Sky bridge center
		Vector3(-18, 37, 5),     # Inside office A
	]

	for si in range(spawn_positions.size()):
		var marker := Marker3D.new()
		marker.name = "Spawn_%d" % si
		var mpos: Vector3 = spawn_positions[si]
		marker.position = mpos
		spawn_points.add_child(marker)

	# ══════════════════════════════════════════════
	# PICKUP SPOTS (6 Marker3D nodes)
	# ══════════════════════════════════════════════
	var pickup_spots := Node3D.new()
	pickup_spots.name = "PickupSpots"
	root.add_child(pickup_spots)

	var pickup_positions: Array = [
		Vector3(-25, 40.5, 0),   # Rooftop A, between AC units
		Vector3(-30, 40.5, -10), # Rooftop A, corner
		Vector3(30, 40.5, 5),    # Rooftop B, near helipad
		Vector3(15, 40.5, -8),   # Rooftop B, walkway area
		Vector3(3.75, 40.5, 0),  # Sky bridge center
		Vector3(22, 37, 3),      # Inside office B
		Vector3(-2, 40.5, 0),    # Sky bridge west end
		Vector3(9, 40.5, 0),     # Sky bridge east end
	]

	for pi in range(pickup_positions.size()):
		var pmarker := Marker3D.new()
		pmarker.name = "Pickup_%d" % pi
		var pppos: Vector3 = pickup_positions[pi]
		pmarker.position = pppos
		pickup_spots.add_child(pmarker)

	# ── Set ownership chain ──
	set_owner_on_new_nodes(root, root)

	# ── Save ──
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return

	err = ResourceSaver.save(packed, "res://scenes/level_skyscraper.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/level_skyscraper.tscn")
	quit(0)


func set_owner_on_new_nodes(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		if child.scene_file_path.is_empty():
			set_owner_on_new_nodes(child, scene_owner)


# ── Helper: Partition wall with doorway opening ──
func _add_partition_wall(parent: Node, wall_name: String, center: Vector3, full_size: Vector3, mat: StandardMaterial3D) -> void:
	# Create two wall segments with a 2m doorway gap in the center
	# Wall runs along X axis (full_size.x wide), gap centered at X center
	var half_width: float = (full_size.x - 2.0) / 2.0
	var segment_size := Vector3(half_width, full_size.y, full_size.z)

	var left_seg := CSGBox3D.new()
	left_seg.name = wall_name + "_L"
	left_seg.size = segment_size
	left_seg.position = Vector3(center.x - 1.0 - half_width / 2.0, center.y, center.z)
	left_seg.use_collision = true
	left_seg.collision_layer = 4
	left_seg.collision_mask = 0
	left_seg.material = mat
	parent.add_child(left_seg)

	var right_seg := CSGBox3D.new()
	right_seg.name = wall_name + "_R"
	right_seg.size = segment_size
	right_seg.position = Vector3(center.x + 1.0 + half_width / 2.0, center.y, center.z)
	right_seg.use_collision = true
	right_seg.collision_layer = 4
	right_seg.collision_mask = 0
	right_seg.material = mat
	parent.add_child(right_seg)


# ── Helper: Add office furniture (2 desks, 2 chairs, 2 monitors) ──
func _add_office_furniture(parent: Node, prefix: String, pos1: Vector3, pos2: Vector3) -> void:
	var positions: Array = [pos1, pos2]
	for i in range(2):
		var fpos: Vector3 = positions[i]

		var desk_scene: PackedScene = load("res://assets/glb/office_desk.glb")
		var desk = desk_scene.instantiate()
		desk.name = prefix + "_Desk_%d" % i
		desk.position = fpos
		parent.add_child(desk)

		var chair_scene: PackedScene = load("res://assets/glb/office_chair.glb")
		var chair = chair_scene.instantiate()
		chair.name = prefix + "_Chair_%d" % i
		chair.position = Vector3(fpos.x, fpos.y, fpos.z + 0.8)
		parent.add_child(chair)

		var monitor_scene: PackedScene = load("res://assets/glb/computer_monitor.glb")
		var monitor = monitor_scene.instantiate()
		monitor.name = prefix + "_Monitor_%d" % i
		monitor.position = Vector3(fpos.x, fpos.y + 0.8, fpos.z)
		parent.add_child(monitor)


# ── Helper: Add office SpotLight3D fixtures ──
func _add_office_lights(parent: Node, prefix: String, light_positions: Array) -> void:
	for i in range(light_positions.size()):
		var lpos: Vector3 = light_positions[i]
		var spot := SpotLight3D.new()
		spot.name = prefix + "_Light_%d" % i
		spot.position = lpos
		spot.light_color = Color(1, 0.95, 0.9)
		spot.light_energy = 2.0
		spot.spot_range = 6.0
		spot.spot_angle = 60.0
		spot.rotation_degrees = Vector3(-90, 0, 0)  # pointing down
		spot.shadow_enabled = true
		parent.add_child(spot)


# ── Helper: Water cooler (CSG body + jug) ──
func _add_water_cooler(parent: Node, wc_name: String, pos: Vector3, body_mat: StandardMaterial3D) -> void:
	var wc := Node3D.new()
	wc.name = wc_name
	wc.position = pos
	parent.add_child(wc)

	# Body — tall box
	var body := CSGBox3D.new()
	body.name = wc_name + "_Body"
	body.size = Vector3(0.35, 1.0, 0.35)
	body.position = Vector3(0, 0.5, 0)
	body.use_collision = true
	body.collision_layer = 4
	body.collision_mask = 0
	body.material = body_mat
	wc.add_child(body)

	# Water jug — cylinder on top (blue tint)
	var jug_mat := StandardMaterial3D.new()
	jug_mat.albedo_color = Color(0.5, 0.7, 0.9, 0.6)
	jug_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var jug := CSGCylinder3D.new()
	jug.name = wc_name + "_Jug"
	jug.radius = 0.12
	jug.height = 0.35
	jug.position = Vector3(0, 1.18, 0)
	jug.use_collision = false
	jug.material = jug_mat
	wc.add_child(jug)


# ── Helper: Potted plant (CSG pot + foliage) ──
func _add_plant(parent: Node, plant_name: String, pos: Vector3) -> void:
	var plant := Node3D.new()
	plant.name = plant_name
	plant.position = pos
	parent.add_child(plant)

	# Pot — small brown cylinder
	var pot_mat := StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.5, 0.3, 0.15)
	pot_mat.roughness = 0.9
	var pot := CSGCylinder3D.new()
	pot.name = plant_name + "_Pot"
	pot.radius = 0.2
	pot.height = 0.35
	pot.position = Vector3(0, 0.175, 0)
	pot.use_collision = true
	pot.collision_layer = 4
	pot.collision_mask = 0
	pot.material = pot_mat
	plant.add_child(pot)

	# Foliage — green sphere on top
	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.15, 0.5, 0.15)
	foliage_mat.roughness = 0.8
	var foliage := CSGCylinder3D.new()
	foliage.name = plant_name + "_Foliage"
	foliage.radius = 0.3
	foliage.height = 0.5
	foliage.position = Vector3(0, 0.6, 0)
	foliage.use_collision = false
	foliage.material = foliage_mat
	plant.add_child(foliage)
