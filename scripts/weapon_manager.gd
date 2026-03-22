extends Node3D
## res://scripts/weapon_manager.gd — Manages 3 weapons, firing, reload, ammo

signal weapon_switched(weapon_name: String)
signal ammo_changed(mag: int, reserve: int)

# Weapon data
var weapons: Array[Dictionary] = []
var current_weapon: int = 0
var _fire_timer: float = 0.0
var _is_reloading: bool = false
var _reload_timer: float = 0.0
var _spread_buildup: float = 0.0
var _weapon_models: Array[Node3D] = []

# Muzzle flash
var _flash_light: OmniLight3D = null
var _flash_timer: float = 0.0

func _ready() -> void:
	# Define weapons: handgun, rifle, shotgun
	weapons = [
		{
			"name": "HANDGUN",
			"damage": 25,
			"fire_rate": 0.3,       # seconds between shots
			"mag_size": 12,
			"mag_current": 12,
			"reserve": 36,
			"reload_time": 1.2,
			"auto_fire": false,
			"spread": 0.01,
			"spread_increase": 0.0,
			"ray_count": 1,
			"cone_angle": 0.0,
			"model_path": "res://assets/glb/handgun.glb",
			"target_scale": 0.3,
		},
		{
			"name": "RIFLE",
			"damage": 18,
			"fire_rate": 0.1,
			"mag_size": 30,
			"mag_current": 30,
			"reserve": 90,
			"reload_time": 2.0,
			"auto_fire": true,
			"spread": 0.015,
			"spread_increase": 0.003,   # spread increases over sustained fire
			"ray_count": 1,
			"cone_angle": 0.0,
			"model_path": "res://assets/glb/rifle.glb",
			"target_scale": 0.7,
		},
		{
			"name": "SHOTGUN",
			"damage": 15,            # per pellet
			"fire_rate": 0.8,
			"mag_size": 6,
			"mag_current": 6,
			"reserve": 24,
			"reload_time": 2.5,
			"auto_fire": false,
			"spread": 0.0,
			"spread_increase": 0.0,
			"ray_count": 8,
			"cone_angle": 0.08,      # spread cone for shotgun pellets
			"model_path": "res://assets/glb/shotgun.glb",
			"target_scale": 0.8,
		},
	]

	# Load weapon models
	for i in range(weapons.size()):
		var w: Dictionary = weapons[i]
		var model_scene: PackedScene = load(w["model_path"])
		if model_scene:
			var model = model_scene.instantiate()
			model.name = "WeaponModel_%d" % i
			# Scale to target size
			var mesh_inst = _find_mesh_instance(model)
			if mesh_inst:
				var aabb: AABB = mesh_inst.get_aabb()
				var longest: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
				if longest > 0.001:
					var sf: float = w["target_scale"] / longest
					model.scale = Vector3(sf, sf, sf)
			model.visible = (i == 0)
			add_child(model)
			_weapon_models.append(model)
		else:
			_weapon_models.append(null)

	# Create muzzle flash light
	_flash_light = OmniLight3D.new()
	_flash_light.name = "MuzzleFlash"
	_flash_light.light_color = Color(1.0, 0.8, 0.3)
	_flash_light.light_energy = 3.0
	_flash_light.omni_range = 4.0
	_flash_light.visible = false
	_flash_light.position = Vector3(0, 0, -0.5)
	add_child(_flash_light)

	# Emit initial state
	weapon_switched.emit(weapons[0]["name"])
	ammo_changed.emit(weapons[0]["mag_current"], weapons[0]["reserve"])

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_mesh_instance(child)
		if found:
			return found
	return null

func _process(delta: float) -> void:
	# Fire cooldown
	if _fire_timer > 0.0:
		_fire_timer -= delta

	# Reload timer
	if _is_reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()

	# Flash timer
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_light.visible = false

	# Spread decay
	if _spread_buildup > 0.0:
		_spread_buildup = move_toward(_spread_buildup, 0.0, 0.02 * delta * 60.0)

	# Input — weapon switching
	if Input.is_action_just_pressed("weapon_1"):
		switch_weapon(0)
	elif Input.is_action_just_pressed("weapon_2"):
		switch_weapon(1)
	elif Input.is_action_just_pressed("weapon_3"):
		switch_weapon(2)

	# Scroll wheel weapon switching
	if Input.is_action_just_released("reload"):
		reload()

	# Firing
	var w: Dictionary = weapons[current_weapon]
	if w["auto_fire"]:
		if Input.is_action_pressed("shoot"):
			fire()
	else:
		if Input.is_action_just_pressed("shoot"):
			fire()

func switch_weapon(index: int) -> void:
	if index == current_weapon or index < 0 or index >= weapons.size():
		return
	if _is_reloading:
		_is_reloading = false

	# Hide current model
	if current_weapon < _weapon_models.size() and _weapon_models[current_weapon]:
		_weapon_models[current_weapon].visible = false

	current_weapon = index

	# Show new model
	if current_weapon < _weapon_models.size() and _weapon_models[current_weapon]:
		_weapon_models[current_weapon].visible = true

	var w: Dictionary = weapons[current_weapon]
	weapon_switched.emit(w["name"])
	ammo_changed.emit(w["mag_current"], w["reserve"])
	_fire_timer = 0.15  # Small swap delay
	_spread_buildup = 0.0

func fire() -> void:
	if _is_reloading or _fire_timer > 0.0:
		return

	var w: Dictionary = weapons[current_weapon]
	if w["mag_current"] <= 0:
		reload()
		return

	w["mag_current"] -= 1
	_fire_timer = w["fire_rate"]

	# Get camera for raycasting
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		ammo_changed.emit(w["mag_current"], w["reserve"])
		return

	var space_state = get_world_3d().direct_space_state
	var ray_origin: Vector3 = camera.global_position
	var ray_forward: Vector3 = -camera.global_basis.z

	# Fire rays
	var ray_count: int = w["ray_count"]
	var total_spread: float = w["spread"] + _spread_buildup

	for i in range(ray_count):
		var spread_x: float = randf_range(-total_spread, total_spread)
		var spread_y: float = randf_range(-total_spread, total_spread)
		if ray_count > 1:
			# Shotgun cone spread
			spread_x = randf_range(-w["cone_angle"], w["cone_angle"])
			spread_y = randf_range(-w["cone_angle"], w["cone_angle"])

		var direction: Vector3 = (ray_forward + camera.global_basis.x * spread_x + camera.global_basis.y * spread_y).normalized()
		var ray_end: Vector3 = ray_origin + direction * 200.0

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		# Exclude self (the player)
		var parent_body = _get_parent_body()
		if parent_body:
			query.exclude = [parent_body.get_rid()]
		var result: Dictionary = space_state.intersect_ray(query)

		if not result.is_empty():
			_spawn_impact(result["position"], result["normal"])
			# Damage if hit entity
			var collider = result["collider"]
			if collider.has_method("take_damage"):
				collider.take_damage(w["damage"], "Player")

	# Spread buildup (rifle)
	_spread_buildup += w["spread_increase"]

	# Muzzle flash
	_flash_light.visible = true
	_flash_timer = 0.05

	ammo_changed.emit(w["mag_current"], w["reserve"])

func _get_parent_body() -> CharacterBody3D:
	var node: Node = get_parent()
	while node:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null

func reload() -> void:
	if _is_reloading:
		return
	var w: Dictionary = weapons[current_weapon]
	if w["mag_current"] >= w["mag_size"] or w["reserve"] <= 0:
		return
	_is_reloading = true
	_reload_timer = w["reload_time"]

func _finish_reload() -> void:
	_is_reloading = false
	var w: Dictionary = weapons[current_weapon]
	var needed: int = w["mag_size"] - w["mag_current"]
	var available: int = mini(needed, w["reserve"])
	w["mag_current"] += available
	w["reserve"] -= available
	ammo_changed.emit(w["mag_current"], w["reserve"])

func refill_current_ammo() -> void:
	var w: Dictionary = weapons[current_weapon]
	w["reserve"] += w["mag_size"] * 2
	ammo_changed.emit(w["mag_current"], w["reserve"])

func add_ammo(weapon_index: int, amount: int) -> void:
	if weapon_index >= 0 and weapon_index < weapons.size():
		weapons[weapon_index]["reserve"] += amount
		if weapon_index == current_weapon:
			var w: Dictionary = weapons[current_weapon]
			ammo_changed.emit(w["mag_current"], w["reserve"])

func _spawn_impact(pos: Vector3, normal: Vector3) -> void:
	# Create a brief spark particle at impact point
	var particles := GPUParticles3D.new()
	particles.name = "Impact"
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(normal.x, normal.y, normal.z)
	mat.spread = 30.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 6.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.color = Color(1.0, 0.8, 0.3)
	particles.process_material = mat

	# Small sphere mesh for particles
	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.02
	draw_pass.height = 0.04
	particles.draw_pass_1 = draw_pass

	particles.global_position = pos
	get_tree().root.add_child(particles)
	# Auto cleanup
	get_tree().create_timer(0.5).timeout.connect(particles.queue_free)
