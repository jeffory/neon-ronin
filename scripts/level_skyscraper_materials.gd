extends Node3D
## res://scripts/level_skyscraper_materials.gd — Applies textures at runtime (headless build can't load images)

func _ready() -> void:
	print("LevelSkyscraperMaterials: _ready() starting")

	var concrete_tex: Texture2D = load("res://assets/img/concrete_rooftop.png")
	var glass_tex: Texture2D = load("res://assets/img/glass_window.png")
	var office_floor_tex: Texture2D = load("res://assets/img/office_floor.png")
	var office_wall_tex: Texture2D = load("res://assets/img/office_wall.png")
	var helipad_tex: Texture2D = load("res://assets/img/helipad_marking.png")
	var railing_tex: Texture2D = load("res://assets/img/metal_railing.png")
	var sunset_tex: Texture2D = load("res://assets/img/sunset_sky.png")

	print("LevelSkyscraperMaterials: concrete=%s glass=%s sunset=%s" % [concrete_tex, glass_tex, sunset_tex])

	# ── Skybox ──
	var world_env: Node = null
	for child in get_children():
		if child is WorldEnvironment:
			world_env = child
			break
	if world_env and world_env.environment and world_env.environment.sky:
		var sky_mat = world_env.environment.sky.sky_material
		if sky_mat is PanoramaSkyMaterial:
			sky_mat.panorama = sunset_tex
			print("LevelSkyscraperMaterials: skybox textured")

	# ── Walk tree and apply textures based on node names ──
	_apply_textures_recursive(self, concrete_tex, glass_tex, office_floor_tex, office_wall_tex, helipad_tex, railing_tex)

	print("LevelSkyscraperMaterials: texturing complete")


func _apply_textures_recursive(node: Node, concrete_tex: Texture2D, glass_tex: Texture2D,
		office_floor_tex: Texture2D, office_wall_tex: Texture2D,
		helipad_tex: Texture2D, railing_tex: Texture2D) -> void:
	var nname: String = node.name

	if node is CSGBox3D or node is CSGCylinder3D:
		var csg_node = node
		# Determine texture by node name
		if nname.begins_with("Platform") or nname.begins_with("Ramp") or nname.begins_with("BridgeFloor"):
			_ensure_texture(csg_node, concrete_tex)
		elif nname.begins_with("Facade"):
			_ensure_texture(csg_node, glass_tex)
		elif nname.begins_with("Floor"):
			_ensure_texture(csg_node, office_floor_tex)
		elif nname.begins_with("Ceiling") or nname.begins_with("Office") and nname.contains("Wall"):
			_ensure_texture(csg_node, office_wall_tex)
		elif nname == "Helipad":
			_ensure_texture(csg_node, helipad_tex)
		elif nname.begins_with("Walkway") or nname.begins_with("Railing"):
			_ensure_texture(csg_node, railing_tex)

	for child in node.get_children():
		_apply_textures_recursive(child, concrete_tex, glass_tex, office_floor_tex, office_wall_tex, helipad_tex, railing_tex)


func _ensure_texture(csg_node: Node, tex: Texture2D) -> void:
	if csg_node.material:
		csg_node.material.albedo_texture = tex
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		csg_node.material = mat
