extends Node3D
## res://scripts/weapon_manager.gd

signal weapon_switched(weapon_name: String)
signal ammo_changed(mag: int, reserve: int)

@export var fire_raycast_path: NodePath

var current_weapon: int = 0
var weapons: Array[Dictionary] = []

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func switch_weapon(index: int) -> void:
	pass

func fire() -> void:
	pass

func reload() -> void:
	pass

func add_ammo(weapon_index: int, amount: int) -> void:
	pass
