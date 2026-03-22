extends Area3D
## res://scripts/pickup.gd

@export var pickup_type: String = "health"
@export var heal_amount: int = 50
@export var respawn_time: float = 15.0

var is_active: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	pass

func _start_respawn_timer() -> void:
	pass
