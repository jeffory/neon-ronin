extends CharacterBody3D
## res://scripts/player_controller.gd

signal died(entity_name: String)
signal health_changed(hp: int)

@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.0
@export var mouse_sensitivity: float = 0.002
@export var max_health: int = 100

var current_health: int = 100
var is_sprinting: bool = false
var is_sliding: bool = false

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func take_damage(amount: int, attacker_name: String) -> void:
	pass

func heal(amount: int) -> void:
	pass

func respawn(position: Vector3) -> void:
	pass
