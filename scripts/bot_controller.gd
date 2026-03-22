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
	if dist < 8.0:
		_current_weapon = 2  # Shotgun
	elif dist < 25.0:
		_current_weapon = 1  # Rifle
	else:
		_current_weapon = 0  # Handgun

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
		random_point.x += randf_range(-5.0, 5.0)
		random_point.z += randf_range(-5.0, 5.0)
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

func take_damage(amount: int, attacker_name: String) -> void:
	if is_dead:
		return
	_last_attacker = attacker_name
	current_health -= amount
	if current_health < 0:
		current_health = 0
	health_changed.emit(current_health)

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
	visible = false
	col_shape.set_deferred("disabled", true)
	# Register kill
	var gm = _get_game_manager()
	if gm:
		gm.register_kill(_last_attacker, bot_name)
	died.emit(bot_name)
	# Respawn after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(_respawn)

func _respawn() -> void:
	var gm = _get_game_manager()
	var spawn_pos: Vector3 = Vector3(0, 1, 0)
	if gm:
		spawn_pos = gm.get_random_spawn_point()
	global_position = spawn_pos
	current_health = max_health
	is_dead = false
	visible = true
	col_shape.set_deferred("disabled", false)
	health_changed.emit(current_health)
	_change_state(State.PATROL)
	_pick_patrol_target()

func respawn(pos: Vector3) -> void:
	global_position = pos
	current_health = max_health
	is_dead = false
	visible = true
	col_shape.set_deferred("disabled", false)
	health_changed.emit(current_health)
	_change_state(State.PATROL)
	_pick_patrol_target()
