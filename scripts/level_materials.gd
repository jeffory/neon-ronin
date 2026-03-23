extends Node3D
## res://scripts/level_materials.gd — Applies textures at runtime (headless build can't load images)

func _ready() -> void:
	print("LevelMaterials: _ready() starting")

	# Load textures (works at runtime, not in headless build)
	var street_tex: Texture2D = load("res://assets/img/street.png")
	var facade_tex: Texture2D = load("res://assets/img/building_facade.png")
	var neon_textures: Array = [
		load("res://assets/img/neon_sign_1.png"),
		load("res://assets/img/neon_sign_2.png"),
		load("res://assets/img/neon_sign_3.png"),
	]
	var night_sky_tex: Texture2D = load("res://assets/img/night_sky.png")

	print("LevelMaterials: street_tex=%s facade_tex=%s sky=%s" % [street_tex, facade_tex, night_sky_tex])

	# ── Skybox ──
	var world_env: Node = null
	for child in get_children():
		if child is WorldEnvironment:
			world_env = child
			break
	if world_env and world_env.environment and world_env.environment.sky:
		var sky_mat = world_env.environment.sky.sky_material
		if sky_mat is PanoramaSkyMaterial:
			sky_mat.panorama = night_sky_tex
			print("LevelMaterials: skybox textured")

	# ── Ground + Walls + Buildings ──
	var nav_region: Node = get_node_or_null("NavigationRegion3D")
	if not nav_region:
		print("LevelMaterials: ERROR — NavigationRegion3D not found!")
		return

	# Ground
	var ground = nav_region.get_node_or_null("Ground")
	if ground:
		print("LevelMaterials: Ground found, class=%s, material=%s" % [ground.get_class(), ground.material])
		if ground.material:
			ground.material.albedo_texture = street_tex
			print("LevelMaterials: Ground textured")
		else:
			# Create new material if none exists
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = street_tex
			mat.albedo_color = Color(0.25, 0.25, 0.28)
			mat.uv1_scale = Vector3(15, 15, 1)
			mat.roughness = 0.2
			mat.metallic = 0.4
			mat.metallic_specular = 0.9
			ground.material = mat
			print("LevelMaterials: Ground — created new material with texture")

	# Boundary walls
	for i in range(4):
		var wall = nav_region.get_node_or_null("BoundaryWall_%d" % i)
		if wall:
			if wall.material:
				wall.material.albedo_texture = facade_tex
			else:
				var mat := StandardMaterial3D.new()
				mat.albedo_texture = facade_tex
				wall.material = mat

	# Buildings and neon signs
	var buildings: Node = nav_region.get_node_or_null("Buildings")
	if not buildings:
		print("LevelMaterials: ERROR — Buildings node not found!")
		return

	var building_count: int = 0
	var sign_counter: int = 0
	var large_sign_count: int = 0

	for child in buildings.get_children():
		var cname: String = child.name

		if cname.begins_with("Building_"):
			building_count += 1
			if child.material:
				child.material.albedo_texture = facade_tex
			else:
				# No material survived serialization — create a fresh one
				var mat := StandardMaterial3D.new()
				mat.albedo_texture = facade_tex
				child.material = mat
				print("LevelMaterials: %s had no material, created new one" % cname)

		elif cname.begins_with("NeonSign_"):
			var tex_idx: int = sign_counter % 3
			var mat = child.get_surface_override_material(0) if child is MeshInstance3D else null
			if mat:
				mat.albedo_texture = neon_textures[tex_idx]
				mat.emission_texture = neon_textures[tex_idx]
			sign_counter += 1

		elif cname.begins_with("LargeSign_"):
			var parts: PackedStringArray = cname.split("_")
			var j: int = int(parts[1]) if parts.size() > 1 else 0
			var tex_idx: int = j % 3
			var mat = child.get_surface_override_material(0) if child is MeshInstance3D else null
			if mat:
				mat.albedo_texture = neon_textures[tex_idx]
				mat.emission_texture = neon_textures[tex_idx]
			large_sign_count += 1

	print("LevelMaterials: textured %d buildings, %d neon signs, %d large signs" % [building_count, sign_counter, large_sign_count])
