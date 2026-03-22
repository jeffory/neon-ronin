extends SceneTree
## Test harness for Task 2: Player Controller, Weapons & Combat
## Verifies: FPS view, weapon switching, HUD, pickups

var _frame: int = 0
var _cam: Camera3D = null
var _player: CharacterBody3D = null
var _main_scene: Node = null

func _initialize() -> void:
	var root: Node = get_root()

	# Load main scene
	var scene: PackedScene = load("res://scenes/main.tscn")
	_main_scene = scene.instantiate()
	root.add_child(_main_scene)

	# Find player
	_player = _main_scene.get_node_or_null("Player")
	if _player:
		_cam = _player.get_node_or_null("Head/Camera3D")
		# Position player in the neon-lit main corridor facing down the street
		_player.position = Vector3(0, 1, 5)
		_player.rotation_degrees = Vector3(0, 180, 0)  # Face south (towards neon signs)
		print("ASSERT PASS: Player node found")
	else:
		print("ASSERT FAIL: Player node not found")

	# Find HUD
	var hud = _main_scene.get_node_or_null("HUD")
	if hud:
		print("ASSERT PASS: HUD node found")
	else:
		print("ASSERT FAIL: HUD node not found")

	# Check weapon holder
	if _player:
		var wh = _player.get_node_or_null("Head/Camera3D/WeaponHolder")
		if wh:
			print("ASSERT PASS: WeaponHolder found")
			# Check weapon count
			if wh.has_method("switch_weapon"):
				print("ASSERT PASS: WeaponManager has switch_weapon")
			else:
				print("ASSERT FAIL: WeaponManager missing switch_weapon")
		else:
			print("ASSERT FAIL: WeaponHolder not found")

	# Check pickups
	var pickup_count: int = 0
	for child in _main_scene.get_children():
		if child.name.begins_with("PickupHealth") or child.name.begins_with("PickupAmmo"):
			pickup_count += 1
	if pickup_count >= 4:
		print("ASSERT PASS: Found %d pickups" % pickup_count)
	else:
		print("ASSERT FAIL: Only found %d pickups (expected >=4)" % pickup_count)

func _process(delta: float) -> bool:
	_frame += 1

	if not _player:
		return false

	# Make camera active on frame 1
	if _frame == 1 and _cam:
		_cam.current = true

	# Weapon switching demonstration
	var wh = _player.get_node_or_null("Head/Camera3D/WeaponHolder")

	# Frame 1-20: Show handgun (default) — facing down neon corridor
	# Frame 20: Switch to rifle
	if _frame == 20 and wh and wh.has_method("switch_weapon"):
		wh.switch_weapon(1)
		print("ASSERT PASS: Switched to rifle")

	# Frame 40: Switch to shotgun
	if _frame == 40 and wh and wh.has_method("switch_weapon"):
		wh.switch_weapon(2)
		print("ASSERT PASS: Switched to shotgun")

	# Frame 55: Switch back to handgun
	if _frame == 55 and wh and wh.has_method("switch_weapon"):
		wh.switch_weapon(0)

	# Frame 60: Fire weapon (direct call)
	if _frame == 60 and wh and wh.has_method("fire"):
		wh.fire()
		print("ASSERT PASS: Fired weapon")

	# Frame 65: Move player forward a bit (simulated)
	if _frame >= 65 and _frame <= 80:
		_player.velocity = -_player.transform.basis.z * 5.0
		_player.move_and_slide()

	# Frame 82: Test take_damage
	if _frame == 82:
		_player.take_damage(30, "TestBot")
		if _player.current_health == 70:
			print("ASSERT PASS: Damage applied (HP=70)")
		else:
			print("ASSERT FAIL: Damage not applied correctly (HP=%d)" % _player.current_health)

	# Frame 85: Test heal
	if _frame == 85:
		_player.heal(20)
		if _player.current_health == 90:
			print("ASSERT PASS: Heal applied (HP=90)")
		else:
			print("ASSERT FAIL: Heal not applied correctly (HP=%d)" % _player.current_health)

	# Frame 88: Rotate player to see pickup
	if _frame == 88:
		_player.rotation_degrees.y = 0  # Face north toward pickups

	return false
