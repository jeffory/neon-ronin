extends Control
## res://scripts/title_screen.gd — Title screen with New Game / Settings / Quit menu

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var new_game_btn: Button = $VBoxContainer/NewGameButton
	var settings_btn: Button = $VBoxContainer/SettingsButton
	var quit_btn: Button = $VBoxContainer/QuitButton
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)
	# Wire settings panel back button
	var panel: PanelContainer = get_node_or_null("SettingsPanel")
	if panel:
		panel.back_pressed.connect(_on_settings_back)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

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
