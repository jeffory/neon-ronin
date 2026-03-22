extends SceneTree
## test/test_3.gd — Test Bot AI & Deathmatch
## Verify: Bots navigating arena, engaging targets, kill feed, scoreboard

var _frame: int = 0
var _cam: Camera3D = null
var _main: Node = null
var _player_cam: Camera3D = null
var _checked_bots: bool = false
var _bot_nodes: Array = []

func _initialize() -> void:
	var root = get_root()

	# Load main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	main.name = "Main"
	root.add_child(main)
	_main = main

	# Create observer camera
	_cam = Camera3D.new()
	_cam.name = "TestCamera"
	_cam.fov = 75
	_cam.current = true
	# Start overhead
	_cam.position = Vector3(0, 25, 25)
	_cam.rotation_degrees = Vector3(-45, 0, 0)
	main.add_child(_cam)

	# Disable player camera
	var player = main.get_node_or_null("Player")
	if player:
		_player_cam = player.get_node_or_null("Head/Camera3D")
		if _player_cam:
			_player_cam.current = false

	# Collect bot refs
	for child in main.get_children():
		if child is CharacterBody3D and child.name.begins_with("Bot_"):
			_bot_nodes.append(child)

func _process(delta: float) -> bool:
	_frame += 1

	# Keep test camera active every frame (per quirks.md)
	if _cam:
		_cam.current = true
	if _player_cam:
		_player_cam.current = false

	# --- Camera choreography ---

	# Frame 1-30: High overhead showing full arena and all bots
	if _frame <= 30:
		_cam.position = Vector3(0, 30, 30)
		_cam.rotation_degrees = Vector3(-45, 0, 0)

	# Frame 31-60: Orbit around arena at medium height
	elif _frame <= 60:
		var t: float = float(_frame - 30) / 30.0
		var angle: float = t * 180.0
		var rad: float = deg_to_rad(angle)
		_cam.position = Vector3(sin(rad) * 20.0, 12.0, cos(rad) * 20.0)
		# Look at center
		var look_target: Vector3 = Vector3(0, 2, 0)
		var dir: Vector3 = (look_target - _cam.position).normalized()
		_cam.rotation_degrees.x = rad_to_deg(asin(-dir.y))
		_cam.rotation_degrees.y = rad_to_deg(atan2(dir.x, dir.z))

	# Frame 61-90: Follow first alive bot from behind
	elif _frame <= 90:
		var bot = _get_alive_bot(0)
		if bot:
			var bot_pos: Vector3 = bot.global_position
			# Position camera behind and above the bot
			var behind: Vector3 = -bot.global_basis.z * -5.0
			behind.y = 0.0
			if behind.length() < 0.1:
				behind = Vector3(5, 0, 5)
			_cam.position = bot_pos + behind.normalized() * 6.0 + Vector3(0, 4, 0)
			var look_pos: Vector3 = bot_pos + Vector3(0, 1.5, 0)
			var dir: Vector3 = (look_pos - _cam.position).normalized()
			_cam.rotation_degrees.x = rad_to_deg(asin(-dir.y))
			_cam.rotation_degrees.y = rad_to_deg(atan2(dir.x, dir.z))

	# Frame 91-120: Follow second alive bot
	elif _frame <= 120:
		var bot = _get_alive_bot(1)
		if bot:
			var bot_pos: Vector3 = bot.global_position
			_cam.position = bot_pos + Vector3(-4, 3, 4)
			var look_pos: Vector3 = bot_pos + Vector3(0, 1.2, 0)
			var dir: Vector3 = (look_pos - _cam.position).normalized()
			_cam.rotation_degrees.x = rad_to_deg(asin(-dir.y))
			_cam.rotation_degrees.y = rad_to_deg(atan2(dir.x, dir.z))

	# Frame 121-150: Wide shot showing combat activity
	elif _frame <= 150:
		_cam.position = Vector3(-5, 6, 15)
		_cam.rotation_degrees = Vector3(-15, -20, 0)

	# Assertions at frame 40
	if _frame == 40 and not _checked_bots:
		_checked_bots = true
		_run_assertions()

	# Print bot positions at frame 50 and 100 to verify movement
	if _frame == 50 or _frame == 100:
		for bot in _bot_nodes:
			if is_instance_valid(bot):
				var state_name: String = "unknown"
				if "current_state" in bot:
					match bot.current_state:
						0: state_name = "PATROL"
						1: state_name = "CHASE"
						2: state_name = "ENGAGE"
						3: state_name = "RETREAT"
				print("Frame %d: %s at %s state=%s hp=%s" % [
					_frame, bot.name,
					str(bot.global_position).substr(0, 30),
					state_name,
					str(bot.current_health) if "current_health" in bot else "?"
				])

	return false

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

func _run_assertions() -> void:
	if not _main:
		print("ASSERT FAIL: Main scene not loaded")
		return

	# Check 4 bots exist
	var bot_count: int = 0
	var bot_names: Array[String] = []
	for child in _main.get_children():
		if child is CharacterBody3D and child.name.begins_with("Bot_"):
			bot_count += 1
			bot_names.append(child.name)

	if bot_count == 4:
		print("ASSERT PASS: Found 4 bots: " + str(bot_names))
	else:
		print("ASSERT FAIL: Expected 4 bots, found " + str(bot_count))

	# Check bots have navigation agents
	for child in _main.get_children():
		if child is CharacterBody3D and child.name.begins_with("Bot_"):
			var nav = child.get_node_or_null("NavigationAgent3D")
			if nav:
				print("ASSERT PASS: " + child.name + " has NavigationAgent3D")
			else:
				print("ASSERT FAIL: " + child.name + " missing NavigationAgent3D")

	# Check bots have bot_controller script with state machine
	for child in _main.get_children():
		if child is CharacterBody3D and child.name.begins_with("Bot_"):
			if "current_state" in child:
				print("ASSERT PASS: " + child.name + " has state machine")
			else:
				print("ASSERT FAIL: " + child.name + " missing state machine")

	# Check GameManager
	var gm: Node = null
	var root_node = get_root()
	for child in root_node.get_children():
		if child.name == "GameManager":
			gm = child
			break
	if gm:
		var scores: Dictionary = gm.get_scores()
		var registered: int = scores.size()
		print("ASSERT PASS: GameManager has " + str(registered) + " registered entities")
		if registered >= 5:
			print("ASSERT PASS: All 5 combatants registered (player + 4 bots)")
		else:
			print("ASSERT FAIL: Expected >= 5 registered entities, got " + str(registered))
	else:
		print("ASSERT FAIL: GameManager not found")

	# Check Player
	var player = _main.get_node_or_null("Player")
	if player:
		print("ASSERT PASS: Player exists")
	else:
		print("ASSERT FAIL: Player not found")

	# Check HUD components
	var hud = _main.get_node_or_null("HUD")
	if hud:
		print("ASSERT PASS: HUD exists")
		var kill_feed = hud.get_node_or_null("Container/KillFeed")
		if kill_feed:
			print("ASSERT PASS: Kill feed exists")
		else:
			print("ASSERT FAIL: Kill feed not found")
		var scoreboard = hud.get_node_or_null("Container/Scoreboard")
		if scoreboard:
			print("ASSERT PASS: Scoreboard exists")
		else:
			print("ASSERT FAIL: Scoreboard not found")
	else:
		print("ASSERT FAIL: HUD not found")
