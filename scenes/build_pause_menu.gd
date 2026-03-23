extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_pause_menu.gd
## Requires: settings_panel.tscn (run build_settings_panel.gd first)

func _initialize() -> void:
	print("Generating: PauseMenu")

	var root := CanvasLayer.new()
	root.name = "PauseMenu"
	root.layer = 10
	root.set_script(load("res://scripts/pause_menu.gd"))

	# ── Dark overlay background ──
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	root.add_child(bg)

	# ── Center container ──
	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(center)

	# ── Main VBox ──
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	# ── Title ──
	var title := Label.new()
	title.name = "Title"
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	# ── Buttons container ──
	var buttons_vbox := VBoxContainer.new()
	buttons_vbox.name = "ButtonsVBox"
	buttons_vbox.add_theme_constant_override("separation", 16)
	vbox.add_child(buttons_vbox)

	# Resume button (cyan-neon, like NewGameButton)
	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "RESUME"
	resume.custom_minimum_size = Vector2(280, 56)
	resume.add_theme_font_size_override("font_size", 22)
	resume.add_theme_color_override("font_color", Color(0, 1, 1))
	resume.add_theme_color_override("font_hover_color", Color(0.5, 1, 1))
	resume.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var r_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0, 0.8, 1, 0.5))
	var r_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var r_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	resume.add_theme_stylebox_override("normal", r_normal)
	resume.add_theme_stylebox_override("hover", r_hover)
	resume.add_theme_stylebox_override("pressed", r_pressed)
	resume.add_theme_stylebox_override("focus", r_hover)
	buttons_vbox.add_child(resume)

	# Settings button (gray-neon)
	var settings := Button.new()
	settings.name = "SettingsButton"
	settings.text = "SETTINGS"
	settings.custom_minimum_size = Vector2(280, 56)
	settings.add_theme_font_size_override("font_size", 22)
	settings.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	settings.add_theme_color_override("font_hover_color", Color(0, 1, 1))
	settings.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var s_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.4, 0.5, 0.6, 0.4))
	var s_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var s_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	settings.add_theme_stylebox_override("normal", s_normal)
	settings.add_theme_stylebox_override("hover", s_hover)
	settings.add_theme_stylebox_override("pressed", s_pressed)
	settings.add_theme_stylebox_override("focus", s_hover)
	buttons_vbox.add_child(settings)

	# Quit to Menu button (gray-neon)
	var quit_btn := Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "QUIT TO MENU"
	quit_btn.custom_minimum_size = Vector2(280, 56)
	quit_btn.add_theme_font_size_override("font_size", 22)
	quit_btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	quit_btn.add_theme_color_override("font_hover_color", Color(1, 0.4, 0.5))
	quit_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var q_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.4, 0.5, 0.6, 0.4))
	var q_hover := _make_button_style(Color(0.08, 0.03, 0.05, 0.9), Color(1, 0.3, 0.5, 0.8))
	var q_pressed := _make_button_style(Color(0.15, 0, 0.05, 0.9), Color(1, 0.3, 0.5, 1.0))
	quit_btn.add_theme_stylebox_override("normal", q_normal)
	quit_btn.add_theme_stylebox_override("hover", q_hover)
	quit_btn.add_theme_stylebox_override("pressed", q_pressed)
	quit_btn.add_theme_stylebox_override("focus", q_hover)
	buttons_vbox.add_child(quit_btn)

	# ── Settings panel (instance, hidden by default) ──
	var settings_panel_scene: PackedScene = load("res://scenes/settings_panel.tscn")
	if settings_panel_scene:
		var panel := settings_panel_scene.instantiate()
		panel.name = "SettingsPanel"
		panel.visible = false
		vbox.add_child(panel)
	else:
		push_warning("settings_panel.tscn not found — build it first")

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/pause_menu.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/pause_menu.tscn")
	quit(0)

func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = border_color
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
