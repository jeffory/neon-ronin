extends Node
## res://scripts/game_manager.gd — Autoload singleton

signal kill_registered(killer_name: String, victim_name: String)
signal score_updated

var scores: Dictionary = {}
var spawn_points: Array[Marker3D] = []
var pickup_spots: Array[Marker3D] = []

func _ready() -> void:
	pass

func register_kill(killer_name: String, victim_name: String) -> void:
	pass

func get_random_spawn_point() -> Vector3:
	return Vector3.ZERO

func get_scores() -> Dictionary:
	return scores
