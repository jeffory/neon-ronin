extends CharacterBody3D
## res://scripts/player_controller.gd — FPS controller with sprint, crouch-slide, mantle

signal died(entity_name: String)
signal health_changed(hp: int)

@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var max_health: int = 100

# Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var weapon_holder: Node3D = $Head/Camera3D/WeaponHolder

# State
var current_health: int = 100
var is_sprinting: bool = false
var is_sliding: bool = false
var is_dead: bool = false
var _slide_speed: float = 0.0
var _slide_direction: Vector3 = Vector3.ZERO
var _head_default_y: float = 1.6
var _head_slide_y: float = 0.8
var _last_attacker: String = ""
var _gravity: float = 0.0

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	current_health = max_health
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Register with game manager
	var gm = _get_game_manager()
	if gm:
		gm.register_entity("Player", self)
	health_changed.emit(current_health)

func _get_game_manager() -> Node:
	# Autoloads are children of root
	var root_node = get_tree().root
	for child in root_node.get_children():
		if child.name == "GameManager":
			return child
	return null

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion:
		# Horizontal rotation on body
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical rotation on head
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		var head_rot: float = clampf(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		head.rotation.x = head_rot

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0:
		velocity.y = 0

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Sprint
	is_sprinting = Input.is_action_pressed("sprint") and not is_sliding

	# Crouch-slide initiation
	if Input.is_action_just_pressed("crouch") and is_sprinting and is_on_floor():
		_start_slide()

	# Slide logic
	if is_sliding:
		_process_slide(delta)
	else:
		_process_movement(delta)

	# Mantle check
	_check_mantle()

	# Head height interpolation
	var target_y: float = _head_slide_y if is_sliding else _head_default_y
	head.position.y = lerpf(head.position.y, target_y, 10.0 * delta)

	move_and_slide()

func _process_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed: float = sprint_speed if is_sprinting else speed

	if direction != Vector3.ZERO:
		velocity.x = lerpf(velocity.x, direction.x * current_speed, 10.0 * delta)
		velocity.z = lerpf(velocity.z, direction.z * current_speed, 10.0 * delta)
	else:
		velocity.x = lerpf(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerpf(velocity.z, 0.0, 10.0 * delta)

func _start_slide() -> void:
	is_sliding = true
	_slide_speed = 12.0  # Momentum burst
	_slide_direction = -transform.basis.z  # Forward direction

func _process_slide(delta: float) -> void:
	# Decelerate
	_slide_speed = move_toward(_slide_speed, 0.0, 8.0 * delta)
	velocity.x = _slide_direction.x * _slide_speed
	velocity.z = _slide_direction.z * _slide_speed

	# End slide when slow enough or crouch released
	if _slide_speed < 1.0 or not Input.is_action_pressed("crouch"):
		is_sliding = false

func _check_mantle() -> void:
	if not Input.is_action_pressed("move_forward"):
		return
	if not is_on_wall() or not is_on_floor():
		return
	# Check if obstacle is mantleable height (0.5-1.2m)
	var wall_normal: Vector3 = get_wall_normal()
	var ray_origin: Vector3 = global_position + Vector3(0, 1.4, 0)
	var ray_end: Vector3 = ray_origin - wall_normal * 0.8
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		# No obstacle at head height — can mantle
		velocity.y = 5.0
		velocity.x = -wall_normal.x * 3.0
		velocity.z = -wall_normal.z * 3.0

func take_damage(amount: int, attacker_name: String) -> void:
	if is_dead:
		return
	_last_attacker = attacker_name
	current_health -= amount
	if current_health < 0:
		current_health = 0
	health_changed.emit(current_health)
	if current_health <= 0:
		_die()

func heal(amount: int) -> void:
	if is_dead:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health)

func _die() -> void:
	is_dead = true
	visible = false
	# Disable collision
	$CollisionShape3D.set_deferred("disabled", true)
	# Register kill
	var gm = _get_game_manager()
	if gm:
		gm.register_kill(_last_attacker, "Player")
	died.emit("Player")
	# Respawn after 2 seconds
	get_tree().create_timer(2.0).timeout.connect(_respawn)

func _respawn() -> void:
	var gm = _get_game_manager()
	var spawn_pos: Vector3 = Vector3(0, 1, 0)
	if gm:
		spawn_pos = gm.get_random_spawn_point()
	global_position = spawn_pos
	current_health = max_health
	is_dead = false
	visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	health_changed.emit(current_health)

func respawn(pos: Vector3) -> void:
	global_position = pos
	current_health = max_health
	is_dead = false
	visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	health_changed.emit(current_health)

func add_ammo_to_current_weapon() -> void:
	var wm = weapon_holder as Node3D
	if wm and wm.has_method("refill_current_ammo"):
		wm.refill_current_ammo()
