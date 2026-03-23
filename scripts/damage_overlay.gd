extends Control
## res://scripts/damage_overlay.gd — Draws red chevrons pointing toward damage sources

var _indicators: Array = []  # Array of {angle: float, alpha: float}

func add_indicator(angle: float) -> void:
	_indicators.append({"angle": angle, "alpha": 0.9})

func _process(delta: float) -> void:
	var changed: bool = false
	var i: int = _indicators.size() - 1
	while i >= 0:
		_indicators[i]["alpha"] -= delta * 0.9  # Fade over ~1 second
		if _indicators[i]["alpha"] <= 0.0:
			_indicators.remove_at(i)
		changed = true
		i -= 1
	if changed:
		queue_redraw()

func _draw() -> void:
	if _indicators.is_empty():
		return

	var center: Vector2 = size * 0.5
	var radius: float = minf(center.x, center.y) * 0.35  # Distance from center

	for ind in _indicators:
		var angle: float = ind["angle"]
		var alpha: float = ind["alpha"]

		# Chevron pointing outward from center at the given angle
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		var perp: Vector2 = Vector2(-dir.y, dir.x)

		var tip: Vector2 = center + dir * (radius + 40.0)
		var inner: Vector2 = center + dir * radius
		var left: Vector2 = inner + perp * 18.0
		var right: Vector2 = inner - perp * 18.0

		# Inner cutout for chevron shape
		var inner_tip: Vector2 = center + dir * (radius + 20.0)

		var color := Color(1.0, 0.1, 0.1, alpha)
		var points: PackedVector2Array = PackedVector2Array([tip, left, inner_tip, right])
		var colors: PackedColorArray = PackedColorArray([color, color, color, color])
		draw_polygon(points, colors)
