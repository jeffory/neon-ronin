extends CanvasLayer
## res://scripts/hud_controller.gd — HUD display for health, ammo, crosshair, kill feed

@onready var health_bar: ProgressBar = $Container/HealthBar
@onready var ammo_label: Label = $Container/AmmoLabel
@onready var weapon_label: Label = $Container/WeaponLabel
@onready var crosshair: Label = $Container/Crosshair
@onready var kill_feed: VBoxContainer = $Container/KillFeed
@onready var scoreboard: PanelContainer = $Container/Scoreboard

var _player: Node = null
var _weapon_manager: Node = null

func _ready() -> void:
	# Find player and connect signals (deferred to let scene tree settle)
	call_deferred("_connect_signals")

func _connect_signals() -> void:
	# Find player in the scene
	_player = get_parent().get_node_or_null("Player")
	if _player:
		if _player.has_signal("health_changed"):
			_player.health_changed.connect(_on_health_changed)
		# Find weapon manager
		_weapon_manager = _player.get_node_or_null("Head/Camera3D/WeaponHolder")
		if _weapon_manager:
			if _weapon_manager.has_signal("weapon_switched"):
				_weapon_manager.weapon_switched.connect(_on_weapon_switched)
			if _weapon_manager.has_signal("ammo_changed"):
				_weapon_manager.ammo_changed.connect(_on_ammo_changed)

	# Connect to GameManager kill feed
	var gm = _get_game_manager()
	if gm and gm.has_signal("kill_registered"):
		gm.kill_registered.connect(_on_kill_registered)

func _get_game_manager() -> Node:
	var root_node = get_tree().root
	for child in root_node.get_children():
		if child.name == "GameManager":
			return child
	return null

func _process(_delta: float) -> void:
	# Scoreboard toggle
	if scoreboard:
		scoreboard.visible = Input.is_action_pressed("scoreboard")
		if scoreboard.visible:
			_update_scoreboard()

func _on_health_changed(hp: int) -> void:
	if health_bar:
		health_bar.value = hp

func _on_ammo_changed(mag: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = "%d / %d" % [mag, reserve]

func _on_weapon_switched(weapon_name: String) -> void:
	if weapon_label:
		weapon_label.text = weapon_name

func _on_kill_registered(killer_name: String, victim_name: String) -> void:
	if not kill_feed:
		return
	var entry := Label.new()
	entry.text = "%s killed %s" % [killer_name, victim_name]
	entry.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	entry.add_theme_font_size_override("font_size", 14)
	kill_feed.add_child(entry)

	# Limit to 4 entries
	while kill_feed.get_child_count() > 4:
		var old: Node = kill_feed.get_child(0)
		kill_feed.remove_child(old)
		old.queue_free()

	# Fade out after 3s
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(entry) and entry.get_parent():
			entry.get_parent().remove_child(entry)
			entry.queue_free()
	)

func _update_scoreboard() -> void:
	# Clear existing children in scoreboard
	for child in scoreboard.get_children():
		child.queue_free()

	var vbox := VBoxContainer.new()
	vbox.name = "ScoreList"

	var title := Label.new()
	title.text = "SCOREBOARD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	vbox.add_child(title)

	var header := Label.new()
	header.text = "  Name            Kills   Deaths"
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(header)

	var gm = _get_game_manager()
	if gm:
		var scores: Dictionary = gm.get_scores()
		# Sort by kills descending
		var entries: Array = []
		for entity_name in scores:
			entries.append({"name": entity_name, "kills": scores[entity_name]["kills"], "deaths": scores[entity_name]["deaths"]})
		entries.sort_custom(func(a, b): return a["kills"] > b["kills"])

		for entry_data in entries:
			var row := Label.new()
			row.text = "  %-16s %3d     %3d" % [entry_data["name"], entry_data["kills"], entry_data["deaths"]]
			row.add_theme_font_size_override("font_size", 16)
			if entry_data["name"] == "Player":
				row.add_theme_color_override("font_color", Color(0, 1, 0.5))
			else:
				row.add_theme_color_override("font_color", Color(1, 1, 1))
			vbox.add_child(row)

	scoreboard.add_child(vbox)
