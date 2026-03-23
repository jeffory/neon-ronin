extends Control
## res://scripts/title_screen.gd — Title screen with New Game / Quit menu

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var new_game_btn: Button = $VBoxContainer/NewGameButton
	var quit_btn: Button = $VBoxContainer/QuitButton
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)

func _on_new_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit() -> void:
	get_tree().quit()
