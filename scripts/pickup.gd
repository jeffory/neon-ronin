extends Area3D
## res://scripts/pickup.gd — Health and ammo pickups with respawn timer

@export var pickup_type: String = "health"
@export var heal_amount: int = 50
@export var respawn_time: float = 15.0

var is_active: bool = true
var _time: float = 0.0
var _base_y: float = 0.0

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)
	# Set collision to detect player and bots (layers 1 and 2)
	collision_layer = 0  # Pickup doesn't need its own physics layer
	collision_mask = 1 | 2  # Detect player (1) and enemies (2)

func _process(delta: float) -> void:
	if not is_active:
		return
	_time += delta
	rotate_y(delta * 1.5)
	position.y = _base_y + sin(_time * 2.0) * 0.1

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if pickup_type == "health":
		if body.has_method("heal"):
			body.heal(heal_amount)
			_collect()
	elif pickup_type == "ammo":
		if body.has_method("add_ammo_to_current_weapon"):
			body.add_ammo_to_current_weapon()
			_collect()

func _collect() -> void:
	is_active = false
	visible = false
	# Disable collision detection while collected
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	# Respawn timer
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	is_active = true
	visible = true
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", false)
