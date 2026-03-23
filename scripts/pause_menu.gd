extends CanvasLayer
## res://scripts/pause_menu.gd — In-game pause menu with settings

var _is_open: bool = false
var _showing_settings: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# Wire button signals
	var resume_btn: Button = $Background/CenterContainer/VBox/ButtonsVBox/ResumeButton
	var settings_btn: Button = $Background/CenterContainer/VBox/ButtonsVBox/SettingsButton
	var quit_btn: Button = $Background/CenterContainer/VBox/ButtonsVBox/QuitButton
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_to_menu)
	# Wire settings panel back button
	var panel: PanelContainer = $Background/CenterContainer/VBox/SettingsPanel
	if panel:
		panel.back_pressed.connect(_hide_settings)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _showing_settings:
			_hide_settings()
		elif _is_open:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	_is_open = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close() -> void:
	_is_open = false
	_showing_settings = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _show_settings() -> void:
	_showing_settings = true
	var buttons: VBoxContainer = $Background/CenterContainer/VBox/ButtonsVBox
	var panel: PanelContainer = $Background/CenterContainer/VBox/SettingsPanel
	buttons.visible = false
	panel.visible = true

func _hide_settings() -> void:
	_showing_settings = false
	var buttons: VBoxContainer = $Background/CenterContainer/VBox/ButtonsVBox
	var panel: PanelContainer = $Background/CenterContainer/VBox/SettingsPanel
	buttons.visible = true
	panel.visible = false

func _on_resume() -> void:
	_close()

func _on_settings() -> void:
	_show_settings()

func _on_quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
