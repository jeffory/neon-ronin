extends SceneTree
## test/presentation.gd — Cinematic presentation video (~30s at 30 FPS = 900 frames)
## Showcases Neon Ronin: cyberpunk city, FPS combat, bot AI, weapons, kill feed

var _frame: int = 0
var _cam: Camera3D = null
var _main: Node = null
var _player: Node = null
var _player_cam: Camera3D = null
var _bot_nodes: Array = []
var _gm: Node = null

# Camera state for smooth interpolation
var _cam_pos: Vector3 = Vector3.ZERO
var _cam_target: Vector3 = Vector3.ZERO
var _initialized_cam: bool = false

func _initialize() -> void:
	var root = get_root()

	# Load main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	main.name = "Main"
	root.add_child(main)
	_main = main

	# Find player
	_player = main.get_node_or_null("Player")
	if _player:
		_player_cam = _player.get_node_or_null("Head/Camera3D")
		# Move player out of the way initially — we control the camera
		_player.position = Vector3(0, 1, 5)

	# Collect bot refs
	for child in main.get_children():
		if child is CharacterBody3D and child.name.begins_with("Bot_"):
			_bot_nodes.append(child)

	# Find GameManager autoload
	for child in root.get_children():
		if child.name == "GameManager":
			_gm = child
			break

	# Create cinematic camera
	_cam = Camera3D.new()
	_cam.name = "CinematicCamera"
	_cam.fov = 70
	_cam.current = true
	# Pre-position for frame 0 (--write-movie renders before _process)
	_cam.position = Vector3(0, 35, 35)
	_cam.rotation_degrees = Vector3(-45, 0, 0)
	main.add_child(_cam)

	_cam_pos = _cam.position
	_cam_target = Vector3(0, 2, 0)

func _process(delta: float) -> bool:
	_frame += 1

	# EVERY frame: keep cinematic camera active, disable player camera
	if _cam:
		_cam.current = true
	if _player_cam:
		_player_cam.current = false

	# Smoothing factor for camera lerp
	var lerp_speed: float = 3.0 * delta

	# ========================================
	# ACT 1: ESTABLISHING SHOTS (frames 1-270, ~9 seconds)
	# ========================================

	# Shot 1 (frames 1-120): High crane shot descending into the city
	if _frame <= 120:
		var t: float = float(_frame) / 120.0
		# Descend from high overview to street level
		var start_pos: Vector3 = Vector3(0, 35, 35)
		var end_pos: Vector3 = Vector3(0, 8, 20)
		_cam_pos = start_pos.lerp(end_pos, _ease_in_out(t))
		_cam_target = Vector3(0, 2, 0)

	# Shot 2 (frames 121-210): Slow orbit showing neon lights and city architecture
	elif _frame <= 210:
		var t: float = float(_frame - 120) / 90.0
		var angle: float = t * 180.0
		var rad: float = deg_to_rad(angle)
		_cam_pos = Vector3(sin(rad) * 22.0, 10.0, cos(rad) * 22.0)
		_cam_target = Vector3(0, 3, 0)

	# Shot 3 (frames 211-270): Low street-level dolly through neon alley
	elif _frame <= 270:
		var t: float = float(_frame - 210) / 60.0
		# Dolly along the main street
		var start_z: float = 25.0
		var end_z: float = -15.0
		_cam_pos = Vector3(3, 3, lerpf(start_z, end_z, _ease_in_out(t)))
		_cam_target = Vector3(-2, 3, _cam_pos.z - 10.0)

	# ========================================
	# ACT 2: COMBAT SHOWCASE (frames 271-630, ~12 seconds)
	# ========================================

	# Shot 4 (frames 271-370): Track a bot patrolling/fighting
	elif _frame <= 370:
		var bot = _get_alive_bot(0)
		if bot:
			var bot_pos: Vector3 = bot.global_position
			# Smooth third-person follow
			var offset: Vector3 = Vector3(4, 4, 6)
			var desired_pos: Vector3 = bot_pos + offset
			if not _initialized_cam:
				_cam_pos = desired_pos
				_initialized_cam = true
			else:
				_cam_pos = _cam_pos.lerp(desired_pos, lerp_speed * 2.0)
			_cam_target = bot_pos + Vector3(0, 1.2, 0)
		else:
			_cam_pos = Vector3(5, 8, 10)
			_cam_target = Vector3(0, 2, 0)

	# Shot 5 (frames 371-460): Action shot tracking combat between bots
	elif _frame <= 460:
		var bot_a = _get_alive_bot(0)
		var bot_b = _get_alive_bot(1)
		if bot_a and bot_b:
			# Position camera between two combatants, offset to side
			var midpoint: Vector3 = (bot_a.global_position + bot_b.global_position) * 0.5
			var separation: Vector3 = bot_b.global_position - bot_a.global_position
			var perp: Vector3 = Vector3(-separation.z, 0, separation.x).normalized()
			var desired_pos: Vector3 = midpoint + perp * 8.0 + Vector3(0, 5, 0)
			_cam_pos = _cam_pos.lerp(desired_pos, lerp_speed * 2.0)
			_cam_target = midpoint + Vector3(0, 1.5, 0)
		else:
			_cam_pos = _cam_pos.lerp(Vector3(-8, 6, 8), lerp_speed)
			_cam_target = Vector3(0, 2, 0)

	# Shot 6 (frames 461-540): Close-up tracking shot on bot engaging target
	elif _frame <= 540:
		var bot = _get_alive_bot(2)
		if not bot:
			bot = _get_alive_bot(0)
		if bot:
			var bot_pos: Vector3 = bot.global_position
			# Close behind-the-shoulder view
			var forward: Vector3 = -bot.global_basis.z
			if forward.length() < 0.1:
				forward = Vector3(0, 0, -1)
			var desired_pos: Vector3 = bot_pos - forward.normalized() * 3.0 + Vector3(1.5, 2.5, 0)
			_cam_pos = _cam_pos.lerp(desired_pos, lerp_speed * 2.0)
			_cam_target = bot_pos + forward * 5.0 + Vector3(0, 1.2, 0)
		else:
			_cam_pos = _cam_pos.lerp(Vector3(0, 5, 10), lerp_speed)
			_cam_target = Vector3(0, 1, 0)

	# Shot 7 (frames 541-630): Sweeping overhead showing full battlefield
	elif _frame <= 630:
		var t: float = float(_frame - 540) / 90.0
		var angle: float = 180.0 + t * 180.0
		var rad: float = deg_to_rad(angle)
		_cam_pos = Vector3(sin(rad) * 25.0, 15.0, cos(rad) * 25.0)
		_cam_target = Vector3(0, 2, 0)

	# ========================================
	# ACT 3: FINALE (frames 631-900, ~9 seconds)
	# ========================================

	# Shot 8 (frames 631-750): Dynamic chase cam on most active bot
	elif _frame <= 750:
		var bot = _get_most_active_bot()
		if bot:
			var bot_pos: Vector3 = bot.global_position
			var forward: Vector3 = -bot.global_basis.z
			if forward.length() < 0.1:
				forward = Vector3(0, 0, -1)
			# Orbit around the bot over time
			var t: float = float(_frame - 630) / 120.0
			var orbit_angle: float = t * 360.0
			var orbit_rad: float = deg_to_rad(orbit_angle)
			var orbit_offset: Vector3 = Vector3(sin(orbit_rad) * 6.0, 4.0, cos(orbit_rad) * 6.0)
			var desired_pos: Vector3 = bot_pos + orbit_offset
			_cam_pos = _cam_pos.lerp(desired_pos, lerp_speed * 3.0)
			_cam_target = bot_pos + Vector3(0, 1.5, 0)
		else:
			_cam_pos = _cam_pos.lerp(Vector3(10, 8, -10), lerp_speed)
			_cam_target = Vector3(0, 2, 0)

	# Shot 9 (frames 751-840): Final dramatic ground-level shot
	elif _frame <= 840:
		var t: float = float(_frame - 750) / 90.0
		# Slow dolly backward revealing the full arena
		var start_pos: Vector3 = Vector3(0, 2.5, -5)
		var end_pos: Vector3 = Vector3(0, 4, 15)
		_cam_pos = start_pos.lerp(end_pos, _ease_in_out(t))
		_cam_target = Vector3(0, 4, -20)

	# Shot 10 (frames 841-900): Final wide establishing shot (full circle)
	else:
		var t: float = float(_frame - 840) / 60.0
		# Pull up and away for final dramatic reveal
		var start_pos: Vector3 = Vector3(0, 8, 20)
		var end_pos: Vector3 = Vector3(0, 30, 30)
		_cam_pos = start_pos.lerp(end_pos, _ease_in_out(t))
		_cam_target = Vector3(0, 2, 0)

	# Apply camera position and look-at
	_cam.position = _cam_pos
	_look_at_smooth(_cam_target)

	# Quit at exactly 900 frames
	if _frame >= 900:
		quit()

	return false

func _ease_in_out(t: float) -> float:
	# Smoothstep easing for camera moves
	var ct: float = clampf(t, 0.0, 1.0)
	return ct * ct * (3.0 - 2.0 * ct)

func _look_at_smooth(target_pos: Vector3) -> void:
	# Manual look_at to avoid issues with look_at() during initialization
	var dir: Vector3 = (target_pos - _cam.position)
	if dir.length() < 0.001:
		return
	dir = dir.normalized()
	_cam.rotation_degrees.x = rad_to_deg(asin(-dir.y))
	_cam.rotation_degrees.y = rad_to_deg(atan2(dir.x, dir.z))

func _get_alive_bot(index: int) -> Node3D:
	var alive_count: int = 0
	for bot in _bot_nodes:
		if is_instance_valid(bot) and "is_dead" in bot and not bot.is_dead:
			if alive_count == index:
				return bot
			alive_count += 1
	# Fallback: return any bot
	if _bot_nodes.size() > index and is_instance_valid(_bot_nodes[index]):
		return _bot_nodes[index]
	return null

func _get_most_active_bot() -> Node3D:
	# Find bot with most kills, or fallback to first alive
	var best_bot: Node3D = null
	var best_kills: int = -1

	for bot in _bot_nodes:
		if not is_instance_valid(bot):
			continue
		if "is_dead" in bot and bot.is_dead:
			continue
		if _gm and "bot_name" in bot:
			var scores: Dictionary = _gm.get_scores()
			var bname: String = bot.bot_name
			if scores.has(bname):
				var kills: int = scores[bname]["kills"]
				if kills > best_kills:
					best_kills = kills
					best_bot = bot

	if best_bot == null:
		best_bot = _get_alive_bot(0)

	return best_bot
