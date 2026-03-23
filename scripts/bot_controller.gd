extends CharacterBody3D
## res://scripts/bot_controller.gd — AI bot with state machine, navigation, combat

signal died(entity_name: String)
signal health_changed(hp: int)

@export var speed: float = 5.0
@export var sprint_speed: float = 7.0
@export var max_health: int = 100

enum State { PATROL, CHASE, ENGAGE, RETREAT }

# Node references
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sight_ray: RayCast3D = $SightRaycast
@onready var col_shape: CollisionShape3D = $CollisionShape3D

# State
var current_state: State = State.PATROL
var current_health: int = 100
var target: Node3D = null
var bot_name: String = ""
var is_dead: bool = false
var _last_attacker: String = ""
var _gravity: float = 0.0

# Timers
var _target_eval_timer: float = 0.0
var _fire_timer: float = 0.0
var _patrol_timer: float = 0.0
var _state_timer: float = 0.0

# Weapon selection: 0=handgun, 1=rifle, 2=shotgun
var _current_weapon: int = 0
# Weapon data: {damage, fire_rate, range, spread}
var _weapons: Array[Dictionary] = []

# Combat
var _aim_spread: float = 0.04  # Bot inaccuracy

# Animation
var _model_node: Node3D = null
var _model_base_y: float = 0.0
const _MODEL_Y_ROTATION: float = PI  # Mixamo FBX faces +Z; rotate to align with Godot -Z forward
var _anim_player: AnimationPlayer = null
var _current_anim: String = ""
var _death_anims: Array[String] = ["death_1", "death_2", "death_3", "death_4"]
var _hit_react_active: bool = false
var _skel: Skeleton3D = null
var _weapon_holder: BoneAttachment3D = null
var _weapon_models: Array[Node3D] = []

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	current_health = max_health

	# Use node name as bot identity
	bot_name = name

	# Set collision: layer 2 (enemies), mask 1|2|4 (player, enemies, environment)
	collision_layer = 2
	collision_mask = 1 | 2 | 4

	# Configure nav agent
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 1.5
	nav_agent.max_speed = sprint_speed

	# Weapon definitions — ranges are engagement ranges, not max bullet range
	_weapons = [
		{"name": "HANDGUN", "damage": 25, "fire_rate": 0.4, "range": 20.0, "spread": 0.05},
		{"name": "RIFLE", "damage": 18, "fire_rate": 0.15, "range": 25.0, "spread": 0.03},
		{"name": "SHOTGUN", "damage": 15, "fire_rate": 0.9, "range": 8.0, "spread": 0.08, "ray_count": 8, "cone": 0.08},
	]

	# Find the model node (first Node3D child that isn't nav/raycast/collision)
	for child in get_children():
		if child is Node3D and not (child is NavigationAgent3D) and not (child is RayCast3D) and not (child is CollisionShape3D):
			_model_node = child
			_model_base_y = child.position.y
			break

	# Rotate model to align Mixamo +Z facing with Godot -Z forward
	if _model_node:
		_model_node.rotation.y = _MODEL_Y_ROTATION

	# Find AnimationPlayer and Skeleton in the model tree and load animations
	if _model_node:
		_anim_player = _find_node_of_type(_model_node, "AnimationPlayer") as AnimationPlayer
		_skel = _find_node_of_type(_model_node, "Skeleton3D") as Skeleton3D
		if _anim_player:
			_load_animations()
			_anim_player.animation_finished.connect(_on_animation_finished)
		# Attach weapon models to right hand bone
		_setup_weapon_models()


	# Register with game manager
	var gm = _get_game_manager()
	if gm:
		gm.register_entity(bot_name, self)

	# Start patrol
	_pick_patrol_target()

func _get_game_manager() -> Node:
	var root_node = get_tree().root
	for child in root_node.get_children():
		if child.name == "GameManager":
			return child
	return null

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Update timers
	_target_eval_timer -= delta
	_fire_timer -= delta
	_patrol_timer -= delta
	_state_timer += delta

	# Target evaluation every 0.5s
	if _target_eval_timer <= 0.0:
		_target_eval_timer = 0.5
		_evaluate_target()

	# State machine
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.ENGAGE:
			_process_engage(delta)
		State.RETREAT:
			_process_retreat(delta)

	move_and_slide()

	# Update animation based on state and velocity
	_update_animation()

func _evaluate_target() -> void:
	var best_target: Node3D = null
	var best_dist: float = 999.0
	var my_pos: Vector3 = global_position

	# Find all potential targets (player + other bots)
	var main_node = get_parent()
	if not main_node:
		return

	for child in main_node.get_children():
		if child == self:
			continue
		if not (child is CharacterBody3D):
			continue
		# Check if it's a valid target (player or bot that's alive)
		if child.has_method("take_damage"):
			var is_target_dead: bool = false
			if "is_dead" in child:
				is_target_dead = child.is_dead
			if is_target_dead:
				continue
			var dist: float = my_pos.distance_to(child.global_position)
			if dist < best_dist and _has_line_of_sight(child):
				best_dist = dist
				best_target = child

	target = best_target

	# State transitions based on target and health
	if target == null:
		if current_state != State.PATROL:
			_change_state(State.PATROL)
			_pick_patrol_target()
		return

	var dist_to_target: float = my_pos.distance_to(target.global_position)

	# Retreat if low health
	if current_health < 30:
		if current_state != State.RETREAT:
			_change_state(State.RETREAT)
			_pick_retreat_position()
		return

	# Select weapon by range
	_select_weapon_by_range(dist_to_target)

	# Engage if in weapon range and have LOS
	var weapon_range: float = _weapons[_current_weapon]["range"]
	if dist_to_target < weapon_range:
		if current_state != State.ENGAGE:
			_change_state(State.ENGAGE)
	else:
		if current_state != State.CHASE:
			_change_state(State.CHASE)

func _has_line_of_sight(other: Node3D) -> bool:
	var eye_pos: Vector3 = global_position + Vector3(0, 1.6, 0)
	var target_pos: Vector3 = other.global_position + Vector3(0, 1.0, 0)
	# Don't bother with LOS beyond 40m
	if eye_pos.distance_to(target_pos) > 40.0:
		return false
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(eye_pos, target_pos)
	# Exclude self and target — if ray hits anything else, LOS is blocked
	var excludes: Array[RID] = [get_rid()]
	if other is CollisionObject3D:
		excludes.append(other.get_rid())
	query.exclude = excludes
	query.collision_mask = 0xFFFFFFFF  # Check all layers for obstacles
	var result: Dictionary = space_state.intersect_ray(query)
	# If nothing between us, we have LOS
	return result.is_empty()

func _select_weapon_by_range(dist: float) -> void:
	var prev_weapon: int = _current_weapon
	if dist < 8.0:
		_current_weapon = 2  # Shotgun
	elif dist < 25.0:
		_current_weapon = 1  # Rifle
	else:
		_current_weapon = 0  # Handgun
	if _current_weapon != prev_weapon:
		_show_current_weapon()

func _change_state(new_state: State) -> void:
	current_state = new_state
	_state_timer = 0.0

func _process_patrol(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_patrol_timer -= delta
		if _patrol_timer <= 0.0:
			_pick_patrol_target()
		return

	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position).normalized()
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Face movement direction
		_face_direction(direction)

func _process_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_change_state(State.PATROL)
		_pick_patrol_target()
		return

	nav_agent.target_position = target.global_position
	if nav_agent.is_navigation_finished():
		return

	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position).normalized()
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * sprint_speed
		velocity.z = direction.z * sprint_speed
		_face_direction(direction)

func _process_engage(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_change_state(State.PATROL)
		_pick_patrol_target()
		return

	# Face target
	var dir_to_target: Vector3 = (target.global_position - global_position)
	dir_to_target.y = 0.0
	if dir_to_target.length() > 0.01:
		_face_direction(dir_to_target.normalized())

	# Stop moving while engaging
	velocity.x = 0.0
	velocity.z = 0.0

	# Fire weapon
	if _fire_timer <= 0.0:
		_fire_at_target()

	# Check if target moved out of range
	var dist: float = global_position.distance_to(target.global_position)
	var weapon_range: float = _weapons[_current_weapon]["range"]
	if dist > weapon_range * 1.2:
		_change_state(State.CHASE)

func _process_retreat(delta: float) -> void:
	if nav_agent.is_navigation_finished() or _state_timer > 5.0:
		# Done retreating or timeout, try to fight or patrol
		if current_health >= 30:
			if target != null and is_instance_valid(target):
				_change_state(State.CHASE)
			else:
				_change_state(State.PATROL)
				_pick_patrol_target()
		else:
			_pick_retreat_position()
		return

	var next_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position).normalized()
	direction.y = 0.0
	if direction.length() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * sprint_speed
		velocity.z = direction.z * sprint_speed
		_face_direction(direction)

func _pick_patrol_target() -> void:
	var gm = _get_game_manager()
	if gm and gm.spawn_points.size() > 0:
		var random_point: Vector3 = gm.spawn_points[randi() % gm.spawn_points.size()]
		# Add some randomness to avoid all bots converging
		random_point.x += randf_range(-3.0, 3.0)
		random_point.z += randf_range(-3.0, 3.0)
		nav_agent.target_position = random_point
	_patrol_timer = randf_range(2.0, 5.0)

func _pick_retreat_position() -> void:
	# Move away from attacker/target
	var away_dir: Vector3 = Vector3.ZERO
	if target != null and is_instance_valid(target):
		away_dir = (global_position - target.global_position).normalized()
	else:
		away_dir = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()

	var retreat_pos: Vector3 = global_position + away_dir * 15.0
	# Clamp to arena bounds
	retreat_pos.x = clampf(retreat_pos.x, -28.0, 28.0)
	retreat_pos.z = clampf(retreat_pos.z, -28.0, 28.0)
	retreat_pos.y = 1.0
	nav_agent.target_position = retreat_pos

func _face_direction(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		var look_target: Vector3 = global_position + dir
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)

func _fire_at_target() -> void:
	if target == null or not is_instance_valid(target):
		return

	var w: Dictionary = _weapons[_current_weapon]
	_fire_timer = w["fire_rate"]

	var eye_pos: Vector3 = global_position + Vector3(0, 1.6, 0)
	var target_center: Vector3 = target.global_position + Vector3(0, 1.0, 0)

	# Muzzle flash
	var muzzle_dir: Vector3 = (target_center - eye_pos).normalized()
	var muzzle_pos: Vector3 = eye_pos + muzzle_dir * 0.5
	_spawn_muzzle_flash(muzzle_pos)

	var space_state = get_world_3d().direct_space_state

	var ray_count: int = 1
	if w.has("ray_count"):
		ray_count = w["ray_count"]

	for i in range(ray_count):
		var aim_dir: Vector3 = (target_center - eye_pos).normalized()
		# Add bot inaccuracy
		var spread: float = _aim_spread + w["spread"]
		if w.has("cone"):
			spread = w["cone"]
		aim_dir.x += randf_range(-spread, spread)
		aim_dir.y += randf_range(-spread, spread)
		aim_dir = aim_dir.normalized()

		var ray_end: Vector3 = eye_pos + aim_dir * 200.0
		var query = PhysicsRayQueryParameters3D.create(eye_pos, ray_end)
		query.exclude = [get_rid()]
		query.collision_mask = 1 | 2 | 4  # Hit player, enemies, environment
		var result: Dictionary = space_state.intersect_ray(query)

		if not result.is_empty():
			var collider = result["collider"]
			if collider.has_method("take_damage"):
				collider.take_damage(w["damage"], bot_name)
			# Spawn impact sparks
			_spawn_impact(result["position"], result["normal"])

func _spawn_impact(pos: Vector3, normal: Vector3) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "BotImpact"
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.25
	particles.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(normal.x, normal.y, normal.z)
	mat.spread = 25.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 5.0
	mat.gravity = Vector3(0, -9.8, 0)
	mat.color = Color(1.0, 0.6, 0.2)
	particles.process_material = mat

	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.015
	draw_pass.height = 0.03
	particles.draw_pass_1 = draw_pass

	get_tree().root.add_child(particles)
	particles.global_position = pos
	get_tree().create_timer(0.5).timeout.connect(particles.queue_free)

func _spawn_muzzle_flash(pos: Vector3) -> void:
	# Bright flash light
	var flash := OmniLight3D.new()
	flash.name = "MuzzleFlash"
	flash.light_color = Color(1.0, 0.7, 0.2)
	flash.light_energy = 4.0
	flash.omni_range = 6.0
	flash.omni_attenuation = 2.0
	get_tree().root.add_child(flash)
	flash.global_position = pos
	# Fade out quickly
	var tween: Tween = flash.create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.08)
	tween.tween_callback(flash.queue_free)

	# Spark particles at muzzle
	var particles := GPUParticles3D.new()
	particles.name = "MuzzleSparks"
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.15
	particles.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, -1)
	mat.spread = 35.0
	mat.initial_velocity_min = 3.0
	mat.initial_velocity_max = 8.0
	mat.gravity = Vector3.ZERO
	mat.color = Color(1.0, 0.8, 0.3)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.05
	particles.process_material = mat

	var draw_pass := SphereMesh.new()
	draw_pass.radius = 0.02
	draw_pass.height = 0.04
	particles.draw_pass_1 = draw_pass

	get_tree().root.add_child(particles)
	particles.global_position = pos
	get_tree().create_timer(0.4).timeout.connect(particles.queue_free)

func take_damage(amount: int, attacker_name: String) -> void:
	if is_dead:
		return
	_last_attacker = attacker_name
	current_health -= amount
	if current_health < 0:
		current_health = 0
	health_changed.emit(current_health)

	# Hit reaction animation
	_play_hit_react()

	# React to being attacked — switch target to attacker if possible
	if target == null or not is_instance_valid(target):
		var main_node = get_parent()
		if main_node:
			for child in main_node.get_children():
				if child is CharacterBody3D and child.name == attacker_name:
					target = child
					break
		if current_health < 30:
			_change_state(State.RETREAT)
			_pick_retreat_position()
		else:
			_change_state(State.CHASE)

	if current_health <= 0:
		_die()

func _play_hit_react() -> void:
	if not _anim_player or is_dead:
		# Fallback: visibility flash
		if _model_node:
			_model_node.visible = false
			get_tree().create_timer(0.05).timeout.connect(func():
				if is_instance_valid(_model_node) and not is_dead:
					_model_node.visible = true
			)
		return
	if _anim_player.has_animation("hit_react"):
		_hit_react_active = true
		_anim_player.play("hit_react")

func heal(amount: int) -> void:
	if is_dead:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health)

func add_ammo_to_current_weapon() -> void:
	# Bots have infinite ammo conceptually, but accept the pickup call
	pass

func _die() -> void:
	is_dead = true
	col_shape.set_deferred("disabled", true)
	# Register kill
	var gm = _get_game_manager()
	if gm:
		gm.register_kill(_last_attacker, bot_name)
	died.emit(bot_name)
	# Play death animation
	if _anim_player:
		var death_anim: String = _death_anims[randi() % _death_anims.size()]
		if _anim_player.has_animation(death_anim):
			_anim_player.play(death_anim)
			_current_anim = death_anim
			# Hide after animation finishes + small delay
			var anim: Animation = _anim_player.get_animation(death_anim)
			get_tree().create_timer(anim.length + 0.5).timeout.connect(func():
				if is_instance_valid(self) and is_dead:
					visible = false
			)
		else:
			visible = false
	else:
		visible = false
	# Respawn after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(_respawn)

func _reset_model() -> void:
	if _model_node:
		_model_node.rotation = Vector3(0.0, _MODEL_Y_ROTATION, 0.0)
		_model_node.position.y = _model_base_y
		_model_node.scale = Vector3.ONE
	_current_anim = ""
	_hit_react_active = false

func _play_spawn_anim() -> void:
	if not _model_node:
		return
	_model_node.scale = Vector3(0.01, 0.01, 0.01)
	var spawn_tween: Tween = create_tween()
	spawn_tween.tween_property(_model_node, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _respawn() -> void:
	var gm = _get_game_manager()
	var spawn_pos: Vector3 = Vector3(0, 1, 0)
	if gm:
		spawn_pos = gm.get_safest_spawn_point()
	global_position = spawn_pos
	current_health = max_health
	is_dead = false
	_reset_model()
	visible = true
	col_shape.set_deferred("disabled", false)
	health_changed.emit(current_health)
	_change_state(State.PATROL)
	_pick_patrol_target()
	_play_spawn_anim()
	if _anim_player and _anim_player.has_animation("rifle_idle"):
		_play_anim("rifle_idle")

func respawn(pos: Vector3) -> void:
	global_position = pos
	current_health = max_health
	is_dead = false
	_reset_model()
	visible = true
	col_shape.set_deferred("disabled", false)
	health_changed.emit(current_health)
	_change_state(State.PATROL)
	_pick_patrol_target()
	_play_spawn_anim()
	if _anim_player and _anim_player.has_animation("rifle_idle"):
		_play_anim("rifle_idle")

# ── Weapon Models ──

func _setup_weapon_models() -> void:
	if not _skel:
		return
	var hand_idx: int = _skel.find_bone("mixamorig_RightHand")
	if hand_idx < 0:
		return

	_weapon_holder = BoneAttachment3D.new()
	_weapon_holder.name = "WeaponHolder"
	_weapon_holder.bone_idx = hand_idx
	_skel.add_child(_weapon_holder)

	var weapon_paths: Array[String] = [
		"res://assets/glb/handgun.glb",
		"res://assets/glb/rifle.glb",
		"res://assets/glb/shotgun.glb",
	]
	var target_scales: Array[float] = [0.3, 0.7, 0.8]

	for i in range(weapon_paths.size()):
		var weapon_scene: PackedScene = load(weapon_paths[i])
		if not weapon_scene:
			_weapon_models.append(Node3D.new())  # placeholder
			_weapon_holder.add_child(_weapon_models[i])
			continue
		var weapon_inst: Node3D = weapon_scene.instantiate()
		# Auto-scale based on AABB
		var mesh_inst: MeshInstance3D = _find_mesh_instance(weapon_inst)
		if mesh_inst and mesh_inst.mesh:
			var aabb: AABB = mesh_inst.get_aabb()
			var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
			if longest > 0.001:
				var sf: float = target_scales[i] / longest
				weapon_inst.scale = Vector3(sf, sf, sf)
		# Z=90 aligns barrel with bone axis, Y=180 flips to point forward
		weapon_inst.rotation_degrees = Vector3(0, 180, 90)
		# Offset forward along bone Y axis and up along bone X axis
		weapon_inst.position.y = 0.15
		weapon_inst.position.x = 0.05
		_weapon_holder.add_child(weapon_inst)
		_weapon_models.append(weapon_inst)

	# Show only the default weapon (handgun)
	_show_current_weapon()

func _show_current_weapon() -> void:
	for i in range(_weapon_models.size()):
		_weapon_models[i].visible = (i == _current_weapon)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found: MeshInstance3D = _find_mesh_instance(child)
		if found:
			return found
	return null

# ── Animation System ──

func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found = _find_node_of_type(child, type_name)
		if found:
			return found
	return null

func _load_animations() -> void:
	if not _anim_player:
		return
	var anim_files: Dictionary = {
		"rifle_idle": "res://assets/glb/bot/Rifle Aiming Idle.fbx",
		"jog": "res://assets/glb/bot/Jogging.fbx",
		"run": "res://assets/glb/bot/Pistol Run.fbx",
		"shoot": "res://assets/glb/bot/Firing Rifle.fbx",
		"hit_react": "res://assets/glb/bot/Hit Reaction.fbx",
		"death_1": "res://assets/glb/bot/Death.fbx",
		"death_2": "res://assets/glb/bot/Death From Right.fbx",
		"death_3": "res://assets/glb/bot/Death From The Back.fbx",
		"death_4": "res://assets/glb/bot/Death From The Front.fbx",
	}
	var lib: AnimationLibrary = _anim_player.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		_anim_player.add_animation_library("", lib)

	for anim_name in anim_files:
		var path: String = anim_files[anim_name]
		var scene: PackedScene = load(path)
		if not scene:
			print("Bot %s: Failed to load animation %s" % [bot_name, path])
			continue
		var inst: Node = scene.instantiate()
		var src_ap: AnimationPlayer = _find_node_of_type(inst, "AnimationPlayer") as AnimationPlayer
		if src_ap:
			var src_lib: AnimationLibrary = src_ap.get_animation_library("")
			if src_lib:
				var src_anims: PackedStringArray = src_lib.get_animation_list()
				# Prefer "mixamo_com" — some FBX files have "Take 001" (T-pose) as first entry
				var pick: String = ""
				for sn in src_anims:
					if sn == "mixamo_com":
						pick = sn
						break
				if pick.is_empty() and src_anims.size() > 0:
					pick = src_anims[0]
				if not pick.is_empty():
					var anim: Animation = src_lib.get_animation(pick)
					# Set loop mode for locomotion animations
					if anim_name in ["rifle_idle", "jog", "run", "shoot"]:
						anim.loop_mode = Animation.LOOP_LINEAR
					# Strip root motion — zero out Hips X/Z position to keep model in place
					_strip_root_motion(anim)
					lib.add_animation(anim_name, anim)
		inst.free()

func _strip_root_motion(anim: Animation) -> void:
	# Strip Hips position (X/Z drift) and rotation (Y turning) to keep model in place
	for t in range(anim.get_track_count()):
		var path: String = str(anim.track_get_path(t))
		if "mixamorig_Hips" not in path:
			continue
		if anim.track_get_type(t) == Animation.TYPE_POSITION_3D:
			var key_count: int = anim.track_get_key_count(t)
			for k in range(key_count):
				var pos: Vector3 = anim.position_track_interpolate(t, anim.track_get_key_time(t, k))
				anim.track_set_key_value(t, k, Vector3(0.0, pos.y, 0.0))
		elif anim.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			var key_count: int = anim.track_get_key_count(t)
			for k in range(key_count):
				var rot: Quaternion = anim.rotation_track_interpolate(t, anim.track_get_key_time(t, k))
				var euler: Vector3 = rot.get_euler()
				euler.y = 0.0  # Strip Y rotation (turning)
				anim.track_set_key_value(t, k, Quaternion.from_euler(euler))

func _play_anim(anim_name: String) -> void:
	if not _anim_player or _current_anim == anim_name:
		return
	if not _anim_player.has_animation(anim_name):
		return
	_anim_player.play(anim_name)
	_current_anim = anim_name

func _update_animation() -> void:
	if is_dead or not _anim_player or _hit_react_active:
		return
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()

	match current_state:
		State.ENGAGE:
			_play_anim("shoot")
		State.CHASE, State.RETREAT:
			if horiz_speed > 0.5:
				_play_anim("run")
			else:
				_play_anim("rifle_idle")
		State.PATROL:
			if horiz_speed > 0.5:
				_play_anim("jog")
			else:
				_play_anim("rifle_idle")

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "hit_react":
		_hit_react_active = false
		# Resume appropriate animation
		_current_anim = ""
		_update_animation()
