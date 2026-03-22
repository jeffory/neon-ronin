extends Area3D
## res://scripts/pickup.gd — Health and ammo pickups with respawn timer

@export var pickup_type: String = "health"
@export var heal_amount: int = 50
@export var respawn_time: float = 15.0

var is_active: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Set collision to detect player and bots (layers 1 and 2)
	collision_layer = 0  # Pickup doesn't need its own physics layer
	collision_mask = 1 | 2  # Detect player (1) and enemies (2)

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
