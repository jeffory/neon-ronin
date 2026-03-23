extends CanvasLayer
## res://scripts/hud_controller.gd — Cyberpunk HUD for health, ammo, crosshair, kill feed, scoreboard

@onready var health_bar: ProgressBar = $Container/BarRow/HealthBar
@onready var health_percent: Label = $Container/BarRow/HealthPercent
@onready var health_value: Label = $Container/InfoRow/HealthValue
@onready var weapon_icon: TextureRect = $Container/WeaponArea/WeaponIcon
@onready var ammo_label: Label = $Container/WeaponArea/WeaponVBox/AmmoLabel
@onready var weapon_label: Label = $Container/WeaponArea/WeaponVBox/WeaponLabel
@onready var crosshair: Label = $Container/Crosshair
@onready var kill_feed: VBoxContainer = $Container/KillFeed
@onready var scoreboard: PanelContainer = $Container/Scoreboard

var _player: Node = null
var _weapon_manager: Node = null
var _damage_overlay: Control = null
var _scoreboard_vbox: VBoxContainer = null
var _scoreboard_dirty: bool = true
var _respawn_prompt: Label = null
var _respawn_pulse_tween: Tween = null
var _weapon_icons: Dictionary = {}  # weapon_name -> Texture2D

func _ready() -> void:
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	_player = get_parent().get_node_or_null("Player")
	if _player:
		if _player.has_signal("health_changed"):
			_player.health_changed.connect(_on_health_changed)
		if _player.has_signal("damage_taken"):
			_player.damage_taken.connect(_on_damage_taken)
		if _player.has_signal("respawn_ready"):
			_player.respawn_ready.connect(_on_respawn_ready)
		if _player.has_signal("respawned"):
			_player.respawned.connect(_on_respawned)
		_weapon_manager = _player.get_node_or_null("Head/Camera3D/WeaponHolder")
		if _weapon_manager:
			if _weapon_manager.has_signal("weapon_switched"):
				_weapon_manager.weapon_switched.connect(_on_weapon_switched)
			if _weapon_manager.has_signal("ammo_changed"):
				_weapon_manager.ammo_changed.connect(_on_ammo_changed)

	# Load weapon icon textures
	_weapon_icons["Handgun"] = load("res://assets/img/icon_handgun.png")
	_weapon_icons["Rifle"] = load("res://assets/img/icon_rifle.png")
	_weapon_icons["Shotgun"] = load("res://assets/img/icon_shotgun.png")

	_damage_overlay = get_node_or_null("Container/DamageOverlay")

	var gm = _get_game_manager()
	if gm:
		if gm.has_signal("kill_registered"):
			gm.kill_registered.connect(_on_kill_registered)
		if gm.has_signal("score_updated"):
			gm.score_updated.connect(_on_score_updated)

	if scoreboard:
		_scoreboard_vbox = VBoxContainer.new()
		_scoreboard_vbox.name = "ScoreList"
		scoreboard.add_child(_scoreboard_vbox)

	# Respawn prompt (hidden by default)
	var container: Control = get_node_or_null("Container")
	if container:
		_respawn_prompt = Label.new()
		_respawn_prompt.name = "RespawnPrompt"
		_respawn_prompt.text = "CLICK TO RESPAWN"
		_respawn_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_respawn_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_respawn_prompt.add_theme_font_size_override("font_size", 32)
		_respawn_prompt.add_theme_color_override("font_color", Color(0, 1, 1))
		_respawn_prompt.set_anchors_preset(Control.PRESET_FULL_RECT)
		_respawn_prompt.offset_top = 60
		_respawn_prompt.visible = false
		container.add_child(_respawn_prompt)

func _get_game_manager() -> Node:
	var root_node = get_tree().root
	for child in root_node.get_children():
		if child.name == "GameManager":
			return child
	return null

func _process(_delta: float) -> void:
	if scoreboard:
		var show_board: bool = Input.is_action_pressed("scoreboard")
		scoreboard.visible = show_board
		if show_board and _scoreboard_dirty:
			_update_scoreboard()
			_scoreboard_dirty = false

func _on_health_changed(hp: int) -> void:
	var max_hp: int = 100
	if _player and "max_health" in _player:
		max_hp = _player.max_health
	if health_bar:
		health_bar.value = hp
	if health_percent:
		var pct: int = int(float(hp) / float(max_hp) * 100.0) if max_hp > 0 else 0
		health_percent.text = "%d%%" % pct
	if health_value:
		health_value.text = "%d/%d" % [hp, max_hp]

func _on_ammo_changed(mag: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [mag, reserve]

func _on_weapon_switched(weapon_name: String) -> void:
	if weapon_label:
		weapon_label.text = weapon_name
	if weapon_icon and _weapon_icons.has(weapon_name):
		weapon_icon.texture = _weapon_icons[weapon_name]

func _on_score_updated() -> void:
	_scoreboard_dirty = true

func _on_kill_registered(killer_name: String, victim_name: String) -> void:
	_scoreboard_dirty = true
	if not kill_feed:
		return
	var entry := Label.new()
	entry.text = "%s killed %s" % [killer_name, victim_name]
	entry.add_theme_color_override("font_color", Color(0, 1, 1))
	entry.add_theme_font_size_override("font_size", 14)
	entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kill_feed.add_child(entry)

	while kill_feed.get_child_count() > 4:
		var old: Node = kill_feed.get_child(0)
		kill_feed.remove_child(old)
		old.queue_free()

	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(entry) and entry.get_parent():
			entry.get_parent().remove_child(entry)
			entry.queue_free()
	)

func _on_damage_taken(attacker_pos: Vector3) -> void:
	if not _damage_overlay or not _player:
		return
	var player_pos: Vector3 = _player.global_position
	var to_attacker: Vector3 = attacker_pos - player_pos
	to_attacker.y = 0.0
	if to_attacker.length_squared() < 0.01:
		return
	var cam: Camera3D = _player.get_node_or_null("Head/Camera3D")
	if not cam:
		return
	var forward: Vector3 = -cam.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = cam.global_basis.x
	right.y = 0.0
	right = right.normalized()
	to_attacker = to_attacker.normalized()
	var angle: float = atan2(to_attacker.dot(right), to_attacker.dot(forward))
	angle = angle - PI / 2.0
	_damage_overlay.add_indicator(angle)

func _update_scoreboard() -> void:
	if not _scoreboard_vbox:
		return

	for child in _scoreboard_vbox.get_children():
		_scoreboard_vbox.remove_child(child)
		child.free()

	var title := Label.new()
	title.text = "SCOREBOARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	_scoreboard_vbox.add_child(title)

	var header := Label.new()
	header.text = "  Name              Kills   Deaths"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_scoreboard_vbox.add_child(header)

	var gm = _get_game_manager()
	if gm:
		var scores: Dictionary = gm.get_scores()
		var entries: Array = []
		for entity_name in scores:
			entries.append({"name": entity_name, "kills": scores[entity_name]["kills"], "deaths": scores[entity_name]["deaths"]})
		entries.sort_custom(func(a, b): return a["kills"] > b["kills"])

		for entry_data in entries:
			var row := Label.new()
			row.text = "  %-18s %3d     %3d" % [entry_data["name"], entry_data["kills"], entry_data["deaths"]]
			row.add_theme_font_size_override("font_size", 16)
			if entry_data["name"] == "Player":
				row.add_theme_color_override("font_color", Color(0, 1, 1))
			else:
				row.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
			_scoreboard_vbox.add_child(row)

func _on_respawn_ready() -> void:
	if not _respawn_prompt:
		return
	_respawn_prompt.visible = true
	_respawn_pulse_tween = create_tween().set_loops()
	_respawn_pulse_tween.tween_property(_respawn_prompt, "modulate:a", 0.3, 0.6)
	_respawn_pulse_tween.tween_property(_respawn_prompt, "modulate:a", 1.0, 0.6)

func _on_respawned() -> void:
	if _respawn_prompt:
		_respawn_prompt.visible = false
	if _respawn_pulse_tween:
		_respawn_pulse_tween.kill()
		_respawn_pulse_tween = null
