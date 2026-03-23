extends CanvasLayer
## res://scripts/dev_console.gd — Quake-style dev console for QA testing

# State
var _is_open: bool = false
var _god_mode: bool = false
var _noclip: bool = false
var _freeze: bool = false
var _fps_visible: bool = false
var _noclip_speed: float = 10.0
var _command_history: Array[String] = []
var _history_index: int = -1
var _original_max_health: int = 100

# Node refs
var _panel: PanelContainer
var _output: RichTextLabel
var _input_line: LineEdit
var _fps_label: Label
var _slide_tween: Tween

# Actions to suppress while console is open
var _game_actions: Array[String] = [
	"move_forward", "move_back", "move_left", "move_right",
	"jump", "sprint", "crouch", "shoot", "reload",
	"weapon_1", "weapon_2", "weapon_3", "scoreboard"
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_panel.visible = false

func _build_ui() -> void:
	# --- Main panel (top 40% of screen) ---
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.4
	_panel.offset_left = 0.0
	_panel.offset_right = 0.0
	_panel.offset_top = 0.0
	_panel.offset_bottom = 0.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.02, 0.05, 0.92)
	panel_style.border_color = Color(0, 1, 1, 0.4)
	panel_style.border_width_bottom = 2
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_top = 8.0
	panel_style.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(vbox)

	# --- Output area ---
	var scroll := ScrollContainer.new()
	scroll.name = "OutputScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	vbox.add_child(scroll)

	_output = RichTextLabel.new()
	_output.name = "Output"
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_output.add_theme_color_override("default_color", Color(0, 1, 1, 0.8))
	_output.add_theme_font_size_override("normal_font_size", 14)
	scroll.add_child(_output)

	# --- Input line ---
	_input_line = LineEdit.new()
	_input_line.name = "InputLine"
	_input_line.placeholder_text = "Type a command..."
	_input_line.add_theme_color_override("font_color", Color(0, 1, 1, 1.0))
	_input_line.add_theme_color_override("font_placeholder_color", Color(0, 1, 1, 0.3))
	_input_line.add_theme_color_override("caret_color", Color(0, 1, 1, 1.0))
	_input_line.add_theme_font_size_override("font_size", 14)
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.03, 0.03, 0.06, 1.0)
	input_style.border_color = Color(0, 1, 1, 0.2)
	input_style.border_width_top = 1
	input_style.content_margin_left = 8.0
	input_style.content_margin_right = 8.0
	input_style.content_margin_top = 4.0
	input_style.content_margin_bottom = 4.0
	_input_line.add_theme_stylebox_override("normal", input_style)
	_input_line.add_theme_stylebox_override("focus", input_style)
	vbox.add_child(_input_line)

	_input_line.text_submitted.connect(_on_text_submitted)

	# --- FPS counter (top-right, independent of panel) ---
	_fps_label = Label.new()
	_fps_label.name = "FPSLabel"
	_fps_label.anchor_left = 1.0
	_fps_label.anchor_right = 1.0
	_fps_label.anchor_top = 0.0
	_fps_label.offset_left = -120.0
	_fps_label.offset_right = -10.0
	_fps_label.offset_top = 10.0
	_fps_label.offset_bottom = 30.0
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.add_theme_color_override("font_color", Color(0, 1, 1, 0.9))
	_fps_label.add_theme_font_size_override("font_size", 16)
	_fps_label.visible = false
	add_child(_fps_label)

	# Welcome message
	_print_line("[color=cyan]Dev Console[/color] — type [color=yellow]help[/color] for commands")

# ── Input ──

func _input(event: InputEvent) -> void:
	# Tilde toggle — always intercept
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT or event.physical_keycode == KEY_QUOTELEFT:
			_toggle()
			get_viewport().set_input_as_handled()
			return

	if not _is_open:
		return

	# When open, intercept special keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_close()
				get_viewport().set_input_as_handled()
			KEY_UP:
				_history_prev()
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_history_next()
				get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# Suppress all game actions while console is open
	if _is_open:
		for action in _game_actions:
			Input.action_release(action)

	if _fps_visible:
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _physics_process(delta: float) -> void:
	# God mode: keep health maxed
	if _god_mode:
		var player = _get_player()
		if player and is_instance_valid(player):
			player.current_health = 999999
			player.max_health = 999999

	# Noclip movement (only when console is closed)
	if _noclip and not _is_open:
		_process_noclip(delta)

# ── Toggle ──

func _toggle() -> void:
	if _is_open:
		_close()
	else:
		_open()

func _open() -> void:
	_is_open = true
	_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Release all held game actions
	for action in _game_actions:
		Input.action_release(action)
	_input_line.grab_focus()
	_input_line.text = ""
	_animate_slide(true)

func _close() -> void:
	_is_open = false
	_input_line.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_animate_slide(false)

func _animate_slide(opening: bool) -> void:
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	if opening:
		var panel_h: float = _panel.size.y
		if panel_h < 10.0:
			panel_h = 300.0  # fallback before layout
		_panel.position.y = -panel_h
		_slide_tween.tween_property(_panel, "position:y", 0.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	else:
		_slide_tween.tween_property(_panel, "position:y", -_panel.size.y, 0.15).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		_slide_tween.tween_callback(func(): _panel.visible = false)

# ── Command Execution ──

func _on_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	_print_line("> " + text)
	_command_history.append(text)
	_history_index = _command_history.size()
	_input_line.text = ""
	_execute_command(text.strip_edges())

func _execute_command(text: String) -> void:
	var parts: PackedStringArray = text.split(" ", false)
	if parts.is_empty():
		return
	var cmd: String = parts[0].to_lower()
	var args: PackedStringArray = parts.slice(1)

	match cmd:
		"god":
			_cmd_god()
		"noclip":
			_cmd_noclip()
		"freeze":
			_cmd_freeze()
		"brightness":
			_cmd_brightness(args)
		"kill":
			_cmd_kill()
		"heal":
			_cmd_heal()
		"give_ammo", "ammo":
			_cmd_give_ammo()
		"tp", "teleport":
			_cmd_teleport(args)
		"fps":
			_cmd_fps()
		"pos":
			_cmd_pos()
		"help":
			_cmd_help()
		"clear":
			_output.clear()
		_:
			_print_line("[color=red]Unknown command:[/color] " + cmd)

# ── Commands ──

func _cmd_god() -> void:
	var player = _get_player()
	if not player:
		_print_line("[color=red]Player not found[/color]")
		return
	_god_mode = not _god_mode
	if _god_mode:
		_original_max_health = player.max_health
		player.max_health = 999999
		player.current_health = 999999
		player.health_changed.emit(999999)
		if not _noclip:
			_enable_noclip(player)
		_print_line("[color=yellow]GOD MODE ON[/color] — invincible + noclip")
	else:
		player.max_health = _original_max_health
		player.current_health = _original_max_health
		player.health_changed.emit(_original_max_health)
		if _noclip:
			_disable_noclip(player)
		_print_line("[color=yellow]GOD MODE OFF[/color]")

func _cmd_noclip() -> void:
	var player = _get_player()
	if not player:
		_print_line("[color=red]Player not found[/color]")
		return
	if _noclip:
		_disable_noclip(player)
		_print_line("[color=yellow]NOCLIP OFF[/color]")
	else:
		_enable_noclip(player)
		_print_line("[color=yellow]NOCLIP ON[/color] — WASD/Space/Crouch to fly, Sprint for speed")

func _enable_noclip(player: Node) -> void:
	_noclip = true
	var col: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", true)
	player.set_physics_process(false)

func _disable_noclip(player: Node) -> void:
	_noclip = false
	var col: CollisionShape3D = player.get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", false)
	player.set_physics_process(true)

func _process_noclip(delta: float) -> void:
	var player = _get_player()
	if not player or not is_instance_valid(player):
		return
	var camera: Camera3D = player.get_node_or_null("Head/Camera3D")
	if not camera:
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (camera.global_basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if Input.is_action_pressed("jump"):
		direction.y += 1.0
	if Input.is_action_pressed("crouch"):
		direction.y -= 1.0

	var fly_speed: float = _noclip_speed
	if Input.is_action_pressed("sprint"):
		fly_speed *= 3.0

	if direction.length() > 0.01:
		player.global_position += direction.normalized() * fly_speed * delta

func _cmd_freeze() -> void:
	_freeze = not _freeze
	var gm = _get_game_manager()
	if not gm:
		_print_line("[color=red]GameManager not found[/color]")
		return
	var count: int = 0
	for entity_name in gm._entities:
		if entity_name == "Player":
			continue
		var entity: Node = gm._entities[entity_name]
		if is_instance_valid(entity):
			entity.set_physics_process(not _freeze)
			count += 1
	if _freeze:
		_print_line("[color=yellow]BOTS FROZEN[/color] (%d bots)" % count)
	else:
		_print_line("[color=yellow]BOTS UNFROZEN[/color] (%d bots)" % count)

func _cmd_brightness(args: PackedStringArray) -> void:
	if args.is_empty():
		_print_line("[color=red]Usage:[/color] brightness <0-5>")
		return
	var value: float = clampf(float(args[0]), 0.0, 5.0)
	var world_env: WorldEnvironment = _find_world_environment()
	if not world_env or not world_env.environment:
		_print_line("[color=red]WorldEnvironment not found[/color]")
		return
	var env: Environment = world_env.environment
	env.ambient_light_energy = lerpf(0.3, 3.0, value / 5.0)
	env.tonemap_exposure = lerpf(0.5, 4.0, value / 5.0)
	_print_line("Brightness set to %.1f (ambient=%.1f, exposure=%.1f)" % [value, env.ambient_light_energy, env.tonemap_exposure])

func _cmd_kill() -> void:
	var gm = _get_game_manager()
	if not gm:
		_print_line("[color=red]GameManager not found[/color]")
		return
	var count: int = 0
	for entity_name in gm._entities:
		if entity_name == "Player":
			continue
		var entity: Node = gm._entities[entity_name]
		if is_instance_valid(entity) and entity.has_method("take_damage"):
			if "is_dead" in entity and entity.is_dead:
				continue
			entity.take_damage(99999, "Console")
			count += 1
	_print_line("Killed %d bots" % count)

func _cmd_heal() -> void:
	var player = _get_player()
	if not player:
		_print_line("[color=red]Player not found[/color]")
		return
	player.current_health = player.max_health
	player.health_changed.emit(player.current_health)
	_print_line("Health restored to %d" % player.current_health)

func _cmd_give_ammo() -> void:
	var player = _get_player()
	if not player:
		_print_line("[color=red]Player not found[/color]")
		return
	var wm: Node = player.get_node_or_null("Head/Camera3D/WeaponHolder")
	if not wm or not ("weapons" in wm):
		_print_line("[color=red]WeaponManager not found[/color]")
		return
	for w: Dictionary in wm.weapons:
		w["mag_current"] = w["mag_size"]
		w["reserve"] = w["mag_size"] * 10
	# Update HUD for current weapon
	var cw: Dictionary = wm.weapons[wm.current_weapon]
	wm.ammo_changed.emit(cw["mag_current"], cw["reserve"])
	_print_line("All weapons fully loaded")

func _cmd_teleport(args: PackedStringArray) -> void:
	if args.size() < 3:
		_print_line("[color=red]Usage:[/color] tp <x> <y> <z>")
		return
	var x: float = float(args[0])
	var y: float = float(args[1])
	var z: float = float(args[2])
	var player = _get_player()
	if not player:
		_print_line("[color=red]Player not found[/color]")
		return
	player.global_position = Vector3(x, y, z)
	_print_line("Teleported to (%.1f, %.1f, %.1f)" % [x, y, z])

func _cmd_fps() -> void:
	_fps_visible = not _fps_visible
	_fps_label.visible = _fps_visible
	_print_line("FPS counter %s" % ("ON" if _fps_visible else "OFF"))

func _cmd_pos() -> void:
	var player = _get_player()
	if not player:
		_print_line("[color=red]Player not found[/color]")
		return
	var p: Vector3 = player.global_position
	_print_line("Position: (%.2f, %.2f, %.2f)" % [p.x, p.y, p.z])

func _cmd_help() -> void:
	_print_line("[color=yellow]Commands:[/color]")
	_print_line("  god          — toggle invincibility + noclip")
	_print_line("  noclip       — toggle flying/no-collision")
	_print_line("  freeze       — toggle bot AI")
	_print_line("  brightness N — set brightness (0-5)")
	_print_line("  kill         — kill all bots")
	_print_line("  heal         — restore player health")
	_print_line("  give_ammo    — refill all weapons")
	_print_line("  tp X Y Z     — teleport to position")
	_print_line("  fps          — toggle FPS counter")
	_print_line("  pos          — print player position")
	_print_line("  clear        — clear console output")

# ── History ──

func _history_prev() -> void:
	if _command_history.is_empty():
		return
	_history_index = clampi(_history_index - 1, 0, _command_history.size() - 1)
	_input_line.text = _command_history[_history_index]
	_input_line.caret_column = _input_line.text.length()

func _history_next() -> void:
	if _command_history.is_empty():
		return
	_history_index += 1
	if _history_index >= _command_history.size():
		_history_index = _command_history.size()
		_input_line.text = ""
	else:
		_input_line.text = _command_history[_history_index]
	_input_line.caret_column = _input_line.text.length()

# ── Helpers ──

func _print_line(text: String) -> void:
	_output.append_text(text + "\n")

func _get_player() -> Node:
	var gm = _get_game_manager()
	if gm:
		return gm.get_entity("Player")
	return null

func _get_game_manager() -> Node:
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "GameManager":
			return child
	return null

func _find_world_environment() -> WorldEnvironment:
	return _find_node_type(get_tree().root, "WorldEnvironment") as WorldEnvironment

func _find_node_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var found: Node = _find_node_type(child, type_name)
		if found:
			return found
	return null
