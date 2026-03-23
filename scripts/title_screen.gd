extends Control
## res://scripts/title_screen.gd — Title screen with level selection, settings, quit

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Main menu buttons
	var select_map_btn: Button = $VBoxContainer/SelectMapButton
	var settings_btn: Button = $VBoxContainer/SettingsButton
	var quit_btn: Button = $VBoxContainer/QuitButton
	if select_map_btn:
		select_map_btn.pressed.connect(_on_select_map)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)
	# Settings panel back button
	var panel: PanelContainer = get_node_or_null("SettingsPanel")
	if panel:
		panel.back_pressed.connect(_on_settings_back)
	# Level select buttons
	var streets_btn: Button = get_node_or_null("LevelSelect/LevelVBox/StreetsButton")
	var sky_btn: Button = get_node_or_null("LevelSelect/LevelVBox/SkyscraperButton")
	var level_back_btn: Button = get_node_or_null("LevelSelect/LevelVBox/LevelBackButton")
	if streets_btn:
		streets_btn.pressed.connect(_on_streets)
	if sky_btn:
		sky_btn.pressed.connect(_on_skyscraper)
	if level_back_btn:
		level_back_btn.pressed.connect(_on_level_back)

func _on_select_map() -> void:
	$VBoxContainer.visible = false
	var level_select: PanelContainer = get_node_or_null("LevelSelect")
	if level_select:
		level_select.visible = true

func _on_streets() -> void:
	var gm: Node = _get_game_manager()
	if gm:
		gm.current_level = 0  # Streets
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_skyscraper() -> void:
	var gm: Node = _get_game_manager()
	if gm:
		gm.current_level = 1  # Skyscraper
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")

func _on_level_back() -> void:
	$VBoxContainer.visible = true
	var level_select: PanelContainer = get_node_or_null("LevelSelect")
	if level_select:
		level_select.visible = false

func _on_settings() -> void:
	$VBoxContainer.visible = false
	var panel: PanelContainer = get_node_or_null("SettingsPanel")
	if panel:
		panel.visible = true

func _on_settings_back() -> void:
	$VBoxContainer.visible = true
	var panel: PanelContainer = get_node_or_null("SettingsPanel")
	if panel:
		panel.visible = false

func _on_quit() -> void:
	get_tree().quit()

func _get_game_manager() -> Node:
	for child in get_tree().root.get_children():
		if child.name == "GameManager":
			return child
	return null
