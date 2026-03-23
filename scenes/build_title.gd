extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_title.gd

func _initialize() -> void:
	print("Generating: TitleScreen")

	var root := Control.new()
	root.name = "TitleScreen"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://scripts/title_screen.gd"))

	# ── Background image ──
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_tex: Texture2D = load("res://assets/img/title_bg.png")
	if bg_tex:
		bg.texture = bg_tex
	root.add_child(bg)

	# ── Dark overlay for readability ──
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)

	# ── Logo ──
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.anchor_left = 0.5
	logo.anchor_top = 0.15
	logo.anchor_right = 0.5
	logo.anchor_bottom = 0.15
	logo.offset_left = -300
	logo.offset_top = 0
	logo.offset_right = 300
	logo.offset_bottom = 150
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo_tex: Texture2D = load("res://assets/img/title_logo.png")
	if logo_tex:
		logo.texture = logo_tex
	root.add_child(logo)

	# ── Menu container (centered, below logo) ──
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.55
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.55
	vbox.offset_left = -140
	vbox.offset_top = 0
	vbox.offset_right = 140
	vbox.offset_bottom = 220
	vbox.add_theme_constant_override("separation", 20)
	root.add_child(vbox)

	# ── New Game button ──
	var new_game := Button.new()
	new_game.name = "NewGameButton"
	new_game.text = "NEW GAME"
	new_game.custom_minimum_size = Vector2(280, 56)
	new_game.add_theme_font_size_override("font_size", 22)
	new_game.add_theme_color_override("font_color", Color(0, 1, 1))
	new_game.add_theme_color_override("font_hover_color", Color(0.5, 1, 1))
	new_game.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var ng_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0, 0.8, 1, 0.5))
	var ng_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var ng_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	new_game.add_theme_stylebox_override("normal", ng_normal)
	new_game.add_theme_stylebox_override("hover", ng_hover)
	new_game.add_theme_stylebox_override("pressed", ng_pressed)
	new_game.add_theme_stylebox_override("focus", ng_hover)
	vbox.add_child(new_game)

	# ── Settings button ──
	var settings_btn := Button.new()
	settings_btn.name = "SettingsButton"
	settings_btn.text = "SETTINGS"
	settings_btn.custom_minimum_size = Vector2(280, 56)
	settings_btn.add_theme_font_size_override("font_size", 22)
	settings_btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	settings_btn.add_theme_color_override("font_hover_color", Color(0, 1, 1))
	settings_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var s_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.4, 0.5, 0.6, 0.4))
	var s_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var s_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	settings_btn.add_theme_stylebox_override("normal", s_normal)
	settings_btn.add_theme_stylebox_override("hover", s_hover)
	settings_btn.add_theme_stylebox_override("pressed", s_pressed)
	settings_btn.add_theme_stylebox_override("focus", s_hover)
	vbox.add_child(settings_btn)

	# ── Quit button ──
	var quit_btn := Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "QUIT"
	quit_btn.custom_minimum_size = Vector2(280, 56)
	quit_btn.add_theme_font_size_override("font_size", 22)
	quit_btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	quit_btn.add_theme_color_override("font_hover_color", Color(0, 1, 1))
	quit_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var q_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.4, 0.5, 0.6, 0.4))
	var q_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var q_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	quit_btn.add_theme_stylebox_override("normal", q_normal)
	quit_btn.add_theme_stylebox_override("hover", q_hover)
	quit_btn.add_theme_stylebox_override("pressed", q_pressed)
	quit_btn.add_theme_stylebox_override("focus", q_hover)
	vbox.add_child(quit_btn)

	# ── Settings panel (hidden by default) ──
	var settings_panel_scene: PackedScene = load("res://scenes/settings_panel.tscn")
	if settings_panel_scene:
		var settings_panel := settings_panel_scene.instantiate()
		settings_panel.name = "SettingsPanel"
		settings_panel.visible = false
		settings_panel.anchor_left = 0.5
		settings_panel.anchor_top = 0.45
		settings_panel.anchor_right = 0.5
		settings_panel.anchor_bottom = 0.45
		settings_panel.offset_left = -220
		settings_panel.offset_top = 0
		settings_panel.offset_right = 220
		settings_panel.offset_bottom = 240
		root.add_child(settings_panel)
	else:
		push_warning("settings_panel.tscn not found — build it first")

	# ── Subtitle ──
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "CYBERPUNK DEATHMATCH"
	subtitle.anchor_left = 0.5
	subtitle.anchor_top = 0.85
	subtitle.anchor_right = 0.5
	subtitle.anchor_bottom = 0.85
	subtitle.offset_left = -200
	subtitle.offset_top = 0
	subtitle.offset_right = 200
	subtitle.offset_bottom = 30
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0, 0.8, 1, 0.5))
	subtitle.add_theme_font_size_override("font_size", 14)
	root.add_child(subtitle)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/title_screen.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/title_screen.tscn")
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
