extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_level.gd

func _initialize() -> void:
	print("Generating: Level (Cyberpunk City Arena)")
	seed(42)

	var root := Node3D.new()
	root.name = "Level"
	root.set_script(load("res://scripts/level_materials.gd"))

	# ── WorldEnvironment ──
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/img/night_sky.png")
	sky_mat.energy_multiplier = 0.3
	sky.sky_material = sky_mat
	env.sky = sky

	# Tonemap — ACES for cinematic neon look
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.8

	# Ambient — dark but visible
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.06, 0.06, 0.1)
	env.ambient_light_energy = 1.5

	# Color adjustment (toggled at runtime for death effect)
	env.adjustment_enabled = false
	env.adjustment_saturation = 1.0

	# Glow / Bloom — essential for neon
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 1.2
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 0.8
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 1.0)
	env.set_glow_level(2, 0.6)
	env.set_glow_level(3, 0.3)
	env.set_glow_level(4, 0.1)

	# Volumetric fog for atmosphere
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.01
	env.volumetric_fog_albedo = Color(0.05, 0.05, 0.1)
	env.volumetric_fog_emission = Color(0.01, 0.005, 0.02)
	env.volumetric_fog_emission_energy = 0.5
	env.volumetric_fog_length = 80.0
	env.volumetric_fog_anisotropy = 0.6

	# SSR for wet street reflections
	env.ssr_enabled = true
	env.ssr_max_steps = 64
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.5

	# SSAO for depth
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	env.ssao_radius = 1.5

	world_env.environment = env
	root.add_child(world_env)

	# ── Moonlight (dim directional) ──
	var moonlight := DirectionalLight3D.new()
	moonlight.name = "Moonlight"
	moonlight.light_color = Color(0.4, 0.45, 0.6)
	moonlight.light_energy = 1.15
	moonlight.shadow_enabled = true
	moonlight.shadow_bias = 0.05
	moonlight.shadow_blur = 2.0
	moonlight.rotation_degrees = Vector3(-55, -30, 0)
	moonlight.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	root.add_child(moonlight)

	# ── Materials ──
	var street_mat := StandardMaterial3D.new()
	street_mat.albedo_texture = load("res://assets/img/street.png")
	street_mat.albedo_color = Color(0.25, 0.25, 0.28)  # darken the street
	street_mat.uv1_scale = Vector3(15, 15, 1)
	street_mat.roughness = 0.2  # wet look
	street_mat.metallic = 0.4
	street_mat.metallic_specular = 0.9

	var facade_mat := StandardMaterial3D.new()
	facade_mat.albedo_texture = load("res://assets/img/building_facade.png")
	facade_mat.uv1_scale = Vector3(1, 1, 1)  # will set per-building based on size

	# Additional facade textures for variety
	var facade_textures: Array = [
		load("res://assets/img/building_facade.png"),
		load("res://assets/img/building_facade_2.png"),
		load("res://assets/img/building_facade_3.png"),
	]

	# Shopfront textures
	var shopfront_textures: Array = [
		load("res://assets/img/shopfront_1.png"),
		load("res://assets/img/shopfront_2.png"),
		load("res://assets/img/shopfront_3.png"),
	]

	var door_tex: Texture2D = load("res://assets/img/door_metal.png")

	var cover_mat := StandardMaterial3D.new()
	cover_mat.albedo_color = Color(0.12, 0.12, 0.15)
	cover_mat.roughness = 0.7
	cover_mat.metallic = 0.4

	# Neon sign textures
	var neon_textures: Array = [
		load("res://assets/img/neon_sign_1.png"),
		load("res://assets/img/neon_sign_2.png"),
		load("res://assets/img/neon_sign_3.png"),
	]

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

	# ── Ground ──
	var ground := CSGBox3D.new()
	ground.name = "Ground"
	ground.size = Vector3(64, 0.3, 64)
	ground.position = Vector3(0, -0.15, 0)
	ground.use_collision = true
	ground.collision_layer = 4  # environment layer (layer 3)
	ground.collision_mask = 0
	ground.material = street_mat
	nav_region.add_child(ground)

	# ── Arena boundary walls (invisible but collidable) ──
	var wall_positions: Array = [
		{"pos": Vector3(0, 5, -32), "size": Vector3(64, 10, 0.5)},
		{"pos": Vector3(0, 5, 32), "size": Vector3(64, 10, 0.5)},
		{"pos": Vector3(-32, 5, 0), "size": Vector3(0.5, 10, 64)},
		{"pos": Vector3(32, 5, 0), "size": Vector3(0.5, 10, 64)},
	]
	for i in range(wall_positions.size()):
		var wd = wall_positions[i]
		var wall := CSGBox3D.new()
		wall.name = "BoundaryWall_%d" % i
		var wpos: Vector3 = wd["pos"]
		var wsize: Vector3 = wd["size"]
		wall.position = wpos
		wall.size = wsize
		wall.use_collision = true
		wall.collision_layer = 4  # environment layer
		wall.collision_mask = 0
		# Dark building facade material for boundary walls
		var bw_mat := StandardMaterial3D.new()
		bw_mat.albedo_texture = load("res://assets/img/building_facade.png")
		var tile_x: float = wsize.x / 4.0 if wsize.x > 1.0 else wsize.z / 4.0
		var tile_y: float = wsize.y / 4.0
		bw_mat.uv1_scale = Vector3(tile_x, tile_y, 1)
		wall.material = bw_mat
		nav_region.add_child(wall)

	# ── Building layout ──
	# Create a cyberpunk city with streets, alleys, and plazas
	# Buildings are placed on a rough grid with variation

	var building_data: Array = []

	# Main street buildings (east side) — narrower street ~6m wide
	building_data.append({"pos": Vector3(8, 0, -22), "size": Vector3(8, 20, 8), "floors": 5})
	building_data.append({"pos": Vector3(9, 0, -12), "size": Vector3(10, 26, 7), "floors": 7})
	building_data.append({"pos": Vector3(8, 0, -2), "size": Vector3(8, 16, 8), "floors": 4})
	building_data.append({"pos": Vector3(9, 0, 8), "size": Vector3(10, 22, 7), "floors": 6})
	building_data.append({"pos": Vector3(8, 0, 18), "size": Vector3(8, 18, 8), "floors": 5})
	building_data.append({"pos": Vector3(9, 0, 26), "size": Vector3(10, 14, 6), "floors": 4})

	# Main street buildings (west side) — offset for organic feel
	building_data.append({"pos": Vector3(-8, 0, -24), "size": Vector3(8, 24, 8), "floors": 6})
	building_data.append({"pos": Vector3(-9, 0, -14), "size": Vector3(10, 18, 7), "floors": 5})
	building_data.append({"pos": Vector3(-8, 0, -4), "size": Vector3(8, 28, 8), "floors": 7})
	building_data.append({"pos": Vector3(-9, 0, 6), "size": Vector3(10, 20, 7), "floors": 5})
	building_data.append({"pos": Vector3(-8, 0, 16), "size": Vector3(8, 16, 8), "floors": 4})
	building_data.append({"pos": Vector3(-9, 0, 24), "size": Vector3(10, 22, 7), "floors": 6})

	# Back alley buildings (far east) — second row creates back alley
	building_data.append({"pos": Vector3(20, 0, -18), "size": Vector3(8, 22, 14), "floors": 6})
	building_data.append({"pos": Vector3(20, 0, -2), "size": Vector3(8, 30, 12), "floors": 8})
	building_data.append({"pos": Vector3(20, 0, 14), "size": Vector3(8, 18, 14), "floors": 5})

	# Back alley buildings (far west)
	building_data.append({"pos": Vector3(-20, 0, -16), "size": Vector3(8, 26, 14), "floors": 7})
	building_data.append({"pos": Vector3(-20, 0, 2), "size": Vector3(8, 20, 12), "floors": 5})
	building_data.append({"pos": Vector3(-20, 0, 18), "size": Vector3(8, 24, 14), "floors": 6})

	# Cross-street buildings (north) — create T-junction feel
	building_data.append({"pos": Vector3(-1, 0, -28), "size": Vector3(5, 22, 4), "floors": 6})
	building_data.append({"pos": Vector3(5, 0, -28), "size": Vector3(4, 18, 4), "floors": 5})

	# Cross-street buildings (south)
	building_data.append({"pos": Vector3(-2, 0, 28), "size": Vector3(6, 20, 4), "floors": 5})
	building_data.append({"pos": Vector3(4, 0, 28), "size": Vector3(4, 24, 4), "floors": 6})

	# Central area — smaller buildings creating alley junctions
	building_data.append({"pos": Vector3(0, 0, -16), "size": Vector3(3, 14, 4), "floors": 4})
	building_data.append({"pos": Vector3(-3, 0, 10), "size": Vector3(3, 12, 3), "floors": 3})
	building_data.append({"pos": Vector3(3, 0, -7), "size": Vector3(2.5, 10, 3), "floors": 3})

	var buildings_node := Node3D.new()
	buildings_node.name = "Buildings"
	nav_region.add_child(buildings_node)

	var sign_index := 0
	for i in range(building_data.size()):
		var bd = building_data[i]
		var bpos: Vector3 = bd["pos"]
		var bsize: Vector3 = bd["size"]

		var building := CSGBox3D.new()
		building.name = "Building_%d" % i
		building.size = bsize
		building.position = Vector3(bpos.x, bsize.y * 0.5, bpos.z)
		building.use_collision = true
		building.collision_layer = 4  # environment layer
		building.collision_mask = 0

		var bmat := StandardMaterial3D.new()
		var ftex: Texture2D = facade_textures[i % 3]
		bmat.albedo_texture = ftex
		bmat.uv1_scale = Vector3(bsize.x / 4.0, bsize.y / 4.0, 1)
		building.material = bmat

		buildings_node.add_child(building)

		# Add neon signs to buildings facing the streets
		var num_signs: int = randi_range(1, 3)
		for s in range(num_signs):
			var sign_mesh := MeshInstance3D.new()
			sign_mesh.name = "NeonSign_%d_%d" % [i, s]
			var quad := QuadMesh.new()
			quad.size = Vector2(1.0, 0.5) if randf() > 0.3 else Vector2(1.5, 0.75)
			sign_mesh.mesh = quad

			var sign_mat := StandardMaterial3D.new()
			sign_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sign_mat.albedo_texture = neon_textures[sign_index % 3]
			sign_mat.emission_enabled = true
			sign_mat.emission_texture = neon_textures[sign_index % 3]
			var emission_colors: Array = [
				Color(1.0, 0.2, 0.6),  # pink
				Color(0.2, 0.8, 1.0),  # cyan
				Color(0.7, 0.3, 1.0),  # purple
				Color(1.0, 0.5, 0.1),  # orange
			]
			sign_mat.emission = emission_colors[sign_index % 4]
			sign_mat.emission_energy_multiplier = 2.5  # lower so albedo texture detail shows
			sign_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sign_mesh.set_surface_override_material(0, sign_mat)
			# Make signs larger so text is visible
			quad.size = Vector2(2.0, 1.0) if randf() > 0.3 else Vector2(2.5, 1.25)

			# Position sign on building facade
			var sign_height: float = randf_range(3.0, bsize.y * 0.7)
			var sign_side: float = 1.0 if randf() > 0.5 else -1.0
			var face_x: bool = randf() > 0.5

			if face_x:
				sign_mesh.position = Vector3(
					bpos.x + sign_side * (bsize.x * 0.5 + 0.05),
					sign_height,
					bpos.z + randf_range(-bsize.z * 0.3, bsize.z * 0.3)
				)
				sign_mesh.rotation_degrees = Vector3(0, 90 if sign_side > 0 else -90, 0)
			else:
				sign_mesh.position = Vector3(
					bpos.x + randf_range(-bsize.x * 0.3, bsize.x * 0.3),
					sign_height,
					bpos.z + sign_side * (bsize.z * 0.5 + 0.05)
				)
				sign_mesh.rotation_degrees = Vector3(0, 0 if sign_side > 0 else 180, 0)

			buildings_node.add_child(sign_mesh)

			# Neon light for each sign — casts colored light on surroundings
			var neon_light := OmniLight3D.new()
			neon_light.name = "NeonLight_%d_%d" % [i, s]
			neon_light.light_color = emission_colors[sign_index % 4]
			neon_light.light_energy = 1.5
			neon_light.omni_range = 6.0
			neon_light.omni_attenuation = 1.5
			neon_light.shadow_enabled = false  # too many for shadows
			neon_light.position = sign_mesh.position + Vector3(0, 0, 0)
			if face_x:
				neon_light.position.x += sign_side * 0.5
			else:
				neon_light.position.z += sign_side * 0.5
			buildings_node.add_child(neon_light)

			sign_index += 1

		# Add emissive window strips to building facades for architectural detail
		var window_colors: Array = [
			Color(0.8, 0.7, 0.4, 1.0),   # warm yellow interior
			Color(0.3, 0.5, 0.8, 1.0),   # cool blue screen glow
			Color(0.6, 0.3, 0.6, 1.0),   # purple ambient
		]
		var num_window_rows: int = int(bsize.y / 3.5)
		for wr in range(num_window_rows):
			var wy: float = 2.5 + wr * 3.5
			if wy >= bsize.y - 1.0:
				continue
			# Place windows on two faces of the building facing the streets
			for face in range(2):
				if randf() < 0.3:
					continue  # skip some for variety
				var win_mesh := MeshInstance3D.new()
				win_mesh.name = "Window_%d_%d_%d" % [i, wr, face]
				var win_quad := QuadMesh.new()
				win_quad.size = Vector2(randf_range(1.5, 3.0), 0.8)
				win_mesh.mesh = win_quad
				var win_mat := StandardMaterial3D.new()
				win_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				var wcolor: Color = window_colors[randi_range(0, 2)]
				win_mat.albedo_color = wcolor
				win_mat.emission_enabled = true
				win_mat.emission = wcolor
				win_mat.emission_energy_multiplier = 1.5
				win_mesh.set_surface_override_material(0, win_mat)

				if face == 0:
					# X-facing side
					var side: float = 1.0 if randf() > 0.5 else -1.0
					win_mesh.position = Vector3(
						bpos.x + side * (bsize.x * 0.5 + 0.03),
						wy,
						bpos.z + randf_range(-bsize.z * 0.3, bsize.z * 0.3)
					)
					win_mesh.rotation_degrees = Vector3(0, 90 if side > 0 else -90, 0)
				else:
					# Z-facing side
					var side: float = 1.0 if randf() > 0.5 else -1.0
					win_mesh.position = Vector3(
						bpos.x + randf_range(-bsize.x * 0.3, bsize.x * 0.3),
						wy,
						bpos.z + side * (bsize.z * 0.5 + 0.03)
					)
					win_mesh.rotation_degrees = Vector3(0, 0 if side > 0 else 180, 0)

				buildings_node.add_child(win_mesh)

	# ── Additional emissive panels on buildings (larger signage) ──
	var large_sign_data: Array = [
		{"pos": Vector3(4.0, 6.0, -22.0), "rot": Vector3(0, -90, 0), "size": Vector2(3.5, 1.8), "color": Color(1.0, 0.1, 0.5), "tex": 0},
		{"pos": Vector3(-4.0, 8.0, -14.0), "rot": Vector3(0, 90, 0), "size": Vector2(3.0, 1.5), "color": Color(0.1, 0.9, 1.0), "tex": 1},
		{"pos": Vector3(4.0, 5.0, -2.0), "rot": Vector3(0, -90, 0), "size": Vector2(3.0, 1.5), "color": Color(0.8, 0.2, 1.0), "tex": 2},
		{"pos": Vector3(-4.0, 10.0, -4.0), "rot": Vector3(0, 90, 0), "size": Vector2(4.0, 2.0), "color": Color(1.0, 0.4, 0.1), "tex": 0},
		{"pos": Vector3(4.0, 7.0, 8.0), "rot": Vector3(0, -90, 0), "size": Vector2(3.0, 1.5), "color": Color(0.2, 1.0, 0.5), "tex": 1},
		{"pos": Vector3(-4.0, 6.0, 6.0), "rot": Vector3(0, 90, 0), "size": Vector2(3.5, 1.8), "color": Color(1.0, 0.2, 0.8), "tex": 2},
		{"pos": Vector3(0.0, 5.0, -26.0), "rot": Vector3(0, 0, 0), "size": Vector2(3.0, 1.5), "color": Color(0.3, 0.7, 1.0), "tex": 0},
		{"pos": Vector3(-2.0, 7.0, 26.0), "rot": Vector3(0, 180, 0), "size": Vector2(3.5, 1.8), "color": Color(1.0, 0.6, 0.1), "tex": 1},
		{"pos": Vector3(4.0, 4.0, 18.0), "rot": Vector3(0, -90, 0), "size": Vector2(3.0, 1.5), "color": Color(0.9, 0.1, 0.9), "tex": 2},
		{"pos": Vector3(-4.0, 9.0, 16.0), "rot": Vector3(0, 90, 0), "size": Vector2(3.5, 1.8), "color": Color(0.1, 0.8, 0.9), "tex": 0},
	]

	for j in range(large_sign_data.size()):
		var sd = large_sign_data[j]
		var lsm := MeshInstance3D.new()
		lsm.name = "LargeSign_%d" % j
		var lquad := QuadMesh.new()
		var ssize: Vector2 = sd["size"]
		lquad.size = ssize
		lsm.mesh = lquad
		var lsmat := StandardMaterial3D.new()
		lsmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var tex_idx: int = sd["tex"]
		lsmat.albedo_texture = neon_textures[tex_idx]
		lsmat.emission_enabled = true
		lsmat.emission_texture = neon_textures[tex_idx]
		var scolor: Color = sd["color"]
		lsmat.emission = scolor
		lsmat.emission_energy_multiplier = 3.0  # visible text detail
		lsmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lsm.set_surface_override_material(0, lsmat)
		var spos: Vector3 = sd["pos"]
		var srot: Vector3 = sd["rot"]
		lsm.position = spos
		lsm.rotation_degrees = srot
		buildings_node.add_child(lsm)

		var ls_light := OmniLight3D.new()
		ls_light.name = "LargeSignLight_%d" % j
		ls_light.light_color = scolor
		ls_light.light_energy = 2.5
		ls_light.omni_range = 10.0
		ls_light.omni_attenuation = 1.2
		ls_light.shadow_enabled = false
		ls_light.position = spos
		buildings_node.add_child(ls_light)

	# ── Street-level spot lights (colored, angled down onto streets) ──
	var spot_data: Array = [
		{"pos": Vector3(0, 5, -5), "color": Color(1, 0.2, 0.6), "rot": Vector3(-70, 0, 0)},
		{"pos": Vector3(0, 5, 5), "color": Color(0.2, 0.8, 1.0), "rot": Vector3(-70, 0, 0)},
		{"pos": Vector3(3, 5, 0), "color": Color(0.7, 0.3, 1.0), "rot": Vector3(-70, 90, 0)},
		{"pos": Vector3(-3, 5, 0), "color": Color(1.0, 0.5, 0.1), "rot": Vector3(-70, -90, 0)},
		{"pos": Vector3(0, 5, -18), "color": Color(0.2, 1, 0.4), "rot": Vector3(-75, 0, 0)},
		{"pos": Vector3(0, 5, 18), "color": Color(1, 0.1, 0.8), "rot": Vector3(-75, 0, 0)},
		{"pos": Vector3(14, 5, 0), "color": Color(0.1, 0.6, 1), "rot": Vector3(-75, 90, 0)},
		{"pos": Vector3(-14, 5, 0), "color": Color(1, 0.3, 0.2), "rot": Vector3(-75, -90, 0)},
		{"pos": Vector3(0, 4, -12), "color": Color(1, 0.5, 0.2), "rot": Vector3(-65, 0, 0)},
		{"pos": Vector3(0, 4, 12), "color": Color(0.5, 0.2, 1), "rot": Vector3(-65, 0, 0)},
	]

	var lights_node := Node3D.new()
	lights_node.name = "Lights"
	root.add_child(lights_node)

	for k in range(spot_data.size()):
		var spd = spot_data[k]
		var spot := SpotLight3D.new()
		spot.name = "StreetSpot_%d" % k
		var sppos: Vector3 = spd["pos"]
		var spcol: Color = spd["color"]
		var sprot: Vector3 = spd["rot"]
		spot.position = sppos
		spot.rotation_degrees = sprot
		spot.light_color = spcol
		spot.light_energy = 3.0
		spot.spot_range = 15.0
		spot.spot_angle = 35.0
		spot.spot_attenuation = 0.8
		spot.shadow_enabled = false
		lights_node.add_child(spot)

	# ── Cover Objects ──
	var cover_node := Node3D.new()
	cover_node.name = "Cover"
	nav_region.add_child(cover_node)

	# Vending machines (tall narrow boxes, ~1.8m tall)
	var vending_positions: Array = [
		Vector3(3.5, 0, -3),
		Vector3(-3.5, 0, 5),
		Vector3(3.5, 0, 15),
		Vector3(-3.5, 0, -15),
	]
	var vend_tex: Texture2D = load("res://assets/img/vending_machine.png")
	for vi in range(vending_positions.size()):
		var vpos: Vector3 = vending_positions[vi]
		# Face toward arena center: right-wall machines face -X, left-wall face +X
		var face_angle: float = -PI / 2.0 if vpos.x > 0 else PI / 2.0

		# Body — dark metallic box with collision
		var vending := CSGBox3D.new()
		vending.name = "Vending_%d" % vi
		vending.size = Vector3(0.8, 1.8, 0.6)
		vending.position = Vector3(vpos.x, 0.9, vpos.z)
		vending.rotation.y = face_angle
		vending.use_collision = true
		vending.collision_layer = 4
		vending.collision_mask = 0
		var vend_mat := StandardMaterial3D.new()
		vend_mat.albedo_color = Color(0.08, 0.08, 0.12)
		vend_mat.metallic = 0.6
		vend_mat.roughness = 0.3
		vending.material = vend_mat
		cover_node.add_child(vending)

		# Front face — textured quad, offset in the facing direction
		if vend_tex:
			var front := MeshInstance3D.new()
			front.name = "VendingFront_%d" % vi
			var quad := QuadMesh.new()
			quad.size = Vector2(0.78, 1.78)  # Slightly inset from box edges
			front.mesh = quad
			var front_mat := StandardMaterial3D.new()
			front_mat.albedo_texture = vend_tex
			front_mat.emission_enabled = true
			front_mat.emission_texture = vend_tex
			front_mat.emission_energy_multiplier = 0.5
			front_mat.metallic = 0.2
			front_mat.roughness = 0.4
			front.set_surface_override_material(0, front_mat)
			var front_offset: float = 0.301
			if vpos.x > 0:
				front.position = Vector3(vpos.x - front_offset, 0.9, vpos.z)
			else:
				front.position = Vector3(vpos.x + front_offset, 0.9, vpos.z)
			front.rotation.y = face_angle
			cover_node.add_child(front)

		# Vending machine glow light — in front of the textured face
		var vend_light := OmniLight3D.new()
		vend_light.name = "VendingLight_%d" % vi
		var light_offset: float = 0.4
		if vpos.x > 0:
			vend_light.position = Vector3(vpos.x - light_offset, 1.0, vpos.z)
		else:
			vend_light.position = Vector3(vpos.x + light_offset, 1.0, vpos.z)
		var vend_colors: Array = [Color(0.2, 1.0, 0.4), Color(1.0, 0.4, 0.1), Color(0.2, 0.6, 1.0), Color(1.0, 0.2, 0.8)]
		vend_light.light_color = vend_colors[vi % 4]
		vend_light.light_energy = 0.8
		vend_light.omni_range = 2.5
		vend_light.omni_attenuation = 1.5
		vend_light.shadow_enabled = false
		cover_node.add_child(vend_light)

	# Dumpsters (~1m tall, good cover)
	var dumpster_positions: Array = [
		Vector3(3, 0, -12),
		Vector3(-3, 0, 10),
		Vector3(14, 0, -8),
		Vector3(-14, 0, 8),
	]
	for di in range(dumpster_positions.size()):
		var dpos: Vector3 = dumpster_positions[di]
		var dumpster := CSGBox3D.new()
		dumpster.name = "Dumpster_%d" % di
		dumpster.size = Vector3(1.5, 1.0, 0.8)
		dumpster.position = Vector3(dpos.x, 0.5, dpos.z)
		dumpster.use_collision = true
		dumpster.collision_layer = 4
		dumpster.collision_mask = 0
		var dump_mat := StandardMaterial3D.new()
		dump_mat.albedo_color = Color(0.15, 0.18, 0.12)
		dump_mat.roughness = 0.9
		dump_mat.metallic = 0.2
		dumpster.material = dump_mat
		cover_node.add_child(dumpster)

	# Crates (~0.6m, stackable cover)
	var crate_positions: Array = [
		Vector3(2, 0, 0), Vector3(2.6, 0, 0), Vector3(2.3, 0.6, 0),
		Vector3(-2, 0, -8), Vector3(-1.4, 0, -8),
		Vector3(13, 0, 5), Vector3(13.6, 0, 5), Vector3(13.3, 0.6, 5),
		Vector3(-13, 0, -5), Vector3(-13.6, 0, -5),
	]
	for ci in range(crate_positions.size()):
		var cpos: Vector3 = crate_positions[ci]
		var crate := CSGBox3D.new()
		crate.name = "Crate_%d" % ci
		crate.size = Vector3(0.6, 0.6, 0.6)
		crate.position = Vector3(cpos.x, cpos.y + 0.3, cpos.z)
		crate.use_collision = true
		crate.collision_layer = 4
		crate.collision_mask = 0
		crate.material = cover_mat
		cover_node.add_child(crate)

	# Concrete barriers (~1m tall, good mantling height)
	var barrier_positions: Array = [
		{"pos": Vector3(0, 0.5, -10), "rot": 0.0},
		{"pos": Vector3(2, 0.5, -10), "rot": 0.0},
		{"pos": Vector3(0, 0.5, 10), "rot": 45.0},
		{"pos": Vector3(-2, 0.5, 10), "rot": 45.0},
		{"pos": Vector3(3, 0.5, 5), "rot": 90.0},
		{"pos": Vector3(-3, 0.5, -5), "rot": 90.0},
		{"pos": Vector3(14, 0.5, 12), "rot": 30.0},
		{"pos": Vector3(-14, 0.5, -12), "rot": -30.0},
	]
	for bi in range(barrier_positions.size()):
		var brd = barrier_positions[bi]
		var barrier := CSGBox3D.new()
		barrier.name = "Barrier_%d" % bi
		barrier.size = Vector3(1.5, 1.0, 0.4)
		var brpos: Vector3 = brd["pos"]
		barrier.position = brpos
		var brrot: float = brd["rot"]
		barrier.rotation_degrees = Vector3(0, brrot, 0)
		barrier.use_collision = true
		barrier.collision_layer = 4
		barrier.collision_mask = 0
		var barrier_mat := StandardMaterial3D.new()
		barrier_mat.albedo_color = Color(0.2, 0.2, 0.22)
		barrier_mat.roughness = 0.85
		barrier.material = barrier_mat
		cover_node.add_child(barrier)

	# ── Trash Cans ──
	var trash_scene: PackedScene = load("res://assets/glb/trash_can.glb")
	var trash_positions: Array = [
		Vector3(5, 0, -8),
		Vector3(-5, 0, 3),
		Vector3(12, 0, -5),
		Vector3(-12, 0, 15),
		Vector3(1, 0, -22),
		Vector3(-1, 0, 22),
		Vector3(16, 0, 5),
		Vector3(-16, 0, -5),
	]
	if trash_scene:
		for ti in range(trash_positions.size()):
			var tpos: Vector3 = trash_positions[ti]
			var trash = trash_scene.instantiate()
			trash.name = "TrashCan_%d" % ti
			# Scale to ~0.8m tall
			var tmesh = _find_mesh_instance(trash)
			if tmesh:
				var taabb: AABB = tmesh.get_aabb()
				var tlongest: float = maxf(maxf(taabb.size.x, taabb.size.y), taabb.size.z)
				if tlongest > 0.001:
					var tsf: float = 0.8 / tlongest
					trash.scale = Vector3(tsf, tsf, tsf)
			trash.position = Vector3(tpos.x, 0, tpos.z)
			trash.rotation.y = randf() * TAU
			cover_node.add_child(trash)

	# ── Power Boxes (wall-mounted) ──
	var pbox_scene: PackedScene = load("res://assets/glb/power_box.glb")
	var power_box_placements: Array = [
		{"pos": Vector3(4.0, 1.4, -18), "rot": -PI / 2.0},  # east wall, face -X
		{"pos": Vector3(4.0, 1.4, 4), "rot": -PI / 2.0},
		{"pos": Vector3(-4.0, 1.4, -10), "rot": PI / 2.0},  # west wall, face +X
		{"pos": Vector3(-4.0, 1.4, 20), "rot": PI / 2.0},
		{"pos": Vector3(16.0, 1.4, -14), "rot": -PI / 2.0},  # back alley east
		{"pos": Vector3(-16.0, 1.4, 6), "rot": PI / 2.0},  # back alley west
	]
	if pbox_scene:
		for pbi in range(power_box_placements.size()):
			var pbd = power_box_placements[pbi]
			var pbox = pbox_scene.instantiate()
			pbox.name = "PowerBox_%d" % pbi
			var pmesh = _find_mesh_instance(pbox)
			if pmesh:
				var paabb: AABB = pmesh.get_aabb()
				var plongest: float = maxf(maxf(paabb.size.x, paabb.size.y), paabb.size.z)
				if plongest > 0.001:
					var psf: float = 0.5 / plongest
					pbox.scale = Vector3(psf, psf, psf)
			var pbpos: Vector3 = pbd["pos"]
			var pbrot: float = pbd["rot"]
			pbox.position = pbpos
			pbox.rotation.y = pbrot
			cover_node.add_child(pbox)

			# Warning light
			var warn_light := OmniLight3D.new()
			warn_light.name = "PowerLight_%d" % pbi
			warn_light.position = Vector3(pbpos.x, pbpos.y + 0.3, pbpos.z)
			warn_light.light_color = Color(1.0, 0.3, 0.1)
			warn_light.light_energy = 0.4
			warn_light.omni_range = 1.5
			warn_light.omni_attenuation = 2.0
			warn_light.shadow_enabled = false
			cover_node.add_child(warn_light)

	# ── Metal Doors (on building facades) ──
	var door_placements: Array = [
		{"pos": Vector3(3.99, 1.1, -22), "rot": -PI / 2.0},   # east building
		{"pos": Vector3(-3.99, 1.1, -14), "rot": PI / 2.0},    # west building
		{"pos": Vector3(3.99, 1.1, 8), "rot": -PI / 2.0},      # east building
		{"pos": Vector3(-3.99, 1.1, 6), "rot": PI / 2.0},      # west building
		{"pos": Vector3(16.0, 1.1, -2), "rot": -PI / 2.0},     # back alley east
		{"pos": Vector3(-16.0, 1.1, 2), "rot": PI / 2.0},      # back alley west
	]
	if door_tex:
		for di in range(door_placements.size()):
			var dd = door_placements[di]
			var door_mesh := MeshInstance3D.new()
			door_mesh.name = "Door_%d" % di
			var dquad := QuadMesh.new()
			dquad.size = Vector2(1.0, 2.2)
			door_mesh.mesh = dquad
			var dmat := StandardMaterial3D.new()
			dmat.albedo_texture = door_tex
			dmat.roughness = 0.6
			dmat.metallic = 0.5
			door_mesh.set_surface_override_material(0, dmat)
			var dpos: Vector3 = dd["pos"]
			var drot: float = dd["rot"]
			door_mesh.position = dpos
			door_mesh.rotation.y = drot
			cover_node.add_child(door_mesh)

	# ── Shopfronts (ground-floor building facades) ──
	var shopfront_placements: Array = [
		{"pos": Vector3(3.99, 1.5, -2), "rot": -PI / 2.0, "tex": 0},   # ramen shop, east main street
		{"pos": Vector3(-3.99, 1.5, -4), "rot": PI / 2.0, "tex": 1},   # tech shop, west main street
		{"pos": Vector3(3.99, 1.5, 18), "rot": -PI / 2.0, "tex": 2},   # bar, east south
		{"pos": Vector3(-3.99, 1.5, 16), "rot": PI / 2.0, "tex": 0},   # ramen, west south
	]
	for si in range(shopfront_placements.size()):
		var sd = shopfront_placements[si]
		var stex_idx: int = sd["tex"]
		var stex: Texture2D = shopfront_textures[stex_idx]
		if not stex:
			continue

		var shop_mesh := MeshInstance3D.new()
		shop_mesh.name = "Shopfront_%d" % si
		var squad := QuadMesh.new()
		squad.size = Vector2(3.5, 2.8)
		shop_mesh.mesh = squad
		var smat := StandardMaterial3D.new()
		smat.albedo_texture = stex
		smat.emission_enabled = true
		smat.emission_texture = stex
		smat.emission_energy_multiplier = 0.6
		smat.roughness = 0.3
		smat.metallic = 0.2
		shop_mesh.set_surface_override_material(0, smat)
		var spos: Vector3 = sd["pos"]
		var srot: float = sd["rot"]
		shop_mesh.position = spos
		shop_mesh.rotation.y = srot
		cover_node.add_child(shop_mesh)

		# Shopfront glow light
		var shop_light := OmniLight3D.new()
		shop_light.name = "ShopLight_%d" % si
		var light_colors: Array = [
			Color(1.0, 0.6, 0.2),   # warm orange (ramen)
			Color(0.2, 0.7, 1.0),   # cool blue (tech)
			Color(0.8, 0.2, 0.6),   # magenta (bar)
		]
		shop_light.light_color = light_colors[stex_idx]
		shop_light.light_energy = 1.0
		shop_light.omni_range = 3.0
		shop_light.omni_attenuation = 1.5
		shop_light.shadow_enabled = false
		# Position light in front of shopfront
		var light_dir: float = -1.0 if spos.x > 0 else 1.0
		shop_light.position = Vector3(spos.x + light_dir * 0.8, 1.5, spos.z)
		cover_node.add_child(shop_light)

	# ── Spawn Points ──
	var spawn_points := Node3D.new()
	spawn_points.name = "SpawnPoints"
	root.add_child(spawn_points)

	var spawn_positions: Array = [
		Vector3(0, 1, 0),       # center street
		Vector3(14, 1, -10),    # east alley north
		Vector3(-14, 1, 10),    # west alley south
		Vector3(0, 1, -20),     # north street
		Vector3(0, 1, 20),      # south street
		Vector3(14, 1, 10),     # east alley south
		Vector3(-14, 1, -10),   # west alley north
		Vector3(0, 1, -10),     # mid street north
	]

	for si in range(spawn_positions.size()):
		var marker := Marker3D.new()
		marker.name = "Spawn_%d" % si
		var mpos: Vector3 = spawn_positions[si]
		marker.position = mpos
		spawn_points.add_child(marker)

	# ── Pickup Spots ──
	var pickup_spots := Node3D.new()
	pickup_spots.name = "PickupSpots"
	root.add_child(pickup_spots)

	var pickup_positions: Array = [
		Vector3(0, 0.5, -5),    # center street
		Vector3(14, 0.5, 0),    # east alley
		Vector3(-14, 0.5, 0),   # west alley
		Vector3(0, 0.5, 15),    # south street
		Vector3(2, 0.5, -15),   # north street
		Vector3(-2, 0.5, 10),   # south-center
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

	err = ResourceSaver.save(packed, "res://scenes/level.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return

	print("Saved: res://scenes/level.tscn")
	quit(0)


func set_owner_on_new_nodes(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		if child.scene_file_path.is_empty():
			set_owner_on_new_nodes(child, scene_owner)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null
