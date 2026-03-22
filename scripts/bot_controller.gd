extends CharacterBody3D
## res://scripts/bot_controller.gd

signal died(entity_name: String)
signal health_changed(hp: int)

@export var speed: float = 5.0
@export var sprint_speed: float = 7.0
@export var max_health: int = 100

enum State { PATROL, CHASE, ENGAGE, RETREAT }

var current_state: State = State.PATROL
var current_health: int = 100
var target: Node3D = null
var bot_name: String = ""

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func take_damage(amount: int, attacker_name: String) -> void:
	pass

func respawn(position: Vector3) -> void:
	pass
