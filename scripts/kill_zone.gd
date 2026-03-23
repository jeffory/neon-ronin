extends Area3D
## res://scripts/kill_zone.gd — Kills any entity that falls below the rooftops

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(9999, global_position)
	elif "health" in body:
		body.health = 0
