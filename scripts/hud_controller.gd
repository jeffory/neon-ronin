extends CanvasLayer
## res://scripts/hud_controller.gd

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_health_changed(hp: int) -> void:
	pass

func _on_ammo_changed(mag: int, reserve: int) -> void:
	pass

func _on_weapon_switched(weapon_name: String) -> void:
	pass

func _on_kill_registered(killer_name: String, victim_name: String) -> void:
	pass
