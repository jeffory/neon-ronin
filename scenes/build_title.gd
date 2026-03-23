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

	# ── Select Map button (replaces New Game) ──
	var select_map := Button.new()
	select_map.name = "SelectMapButton"
	select_map.text = "SELECT MAP"
	select_map.custom_minimum_size = Vector2(280, 56)
	select_map.add_theme_font_size_override("font_size", 22)
	select_map.add_theme_color_override("font_color", Color(0, 1, 1))
	select_map.add_theme_color_override("font_hover_color", Color(0.5, 1, 1))
	select_map.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var ng_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0, 0.8, 1, 0.5))
	var ng_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var ng_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	select_map.add_theme_stylebox_override("normal", ng_normal)
	select_map.add_theme_stylebox_override("hover", ng_hover)
	select_map.add_theme_stylebox_override("pressed", ng_pressed)
	select_map.add_theme_stylebox_override("focus", ng_hover)
	vbox.add_child(select_map)

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

	# ── Level Select Panel (hidden by default) ──
	var level_panel := PanelContainer.new()
	level_panel.name = "LevelSelect"
	level_panel.visible = false
	level_panel.anchor_left = 0.5
	level_panel.anchor_top = 0.4
	level_panel.anchor_right = 0.5
	level_panel.anchor_bottom = 0.4
	level_panel.offset_left = -200
	level_panel.offset_top = 0
	level_panel.offset_right = 200
	level_panel.offset_bottom = 320
	var lp_style := _make_button_style(Color(0.02, 0.02, 0.06, 0.9), Color(0, 0.6, 0.8, 0.5))
	lp_style.content_margin_left = 24
	lp_style.content_margin_right = 24
	lp_style.content_margin_top = 24
	lp_style.content_margin_bottom = 24
	level_panel.add_theme_stylebox_override("panel", lp_style)
	root.add_child(level_panel)

	var lp_vbox := VBoxContainer.new()
	lp_vbox.name = "LevelVBox"
	lp_vbox.add_theme_constant_override("separation", 16)
	level_panel.add_child(lp_vbox)

	var lp_title := Label.new()
	lp_title.text = "SELECT MAP"
	lp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lp_title.add_theme_font_size_override("font_size", 24)
	lp_title.add_theme_color_override("font_color", Color(0, 1, 1))
	lp_vbox.add_child(lp_title)

	# Streets button
	var streets_btn := Button.new()
	streets_btn.name = "StreetsButton"
	streets_btn.text = "STREETS\nCyberpunk City Alleyways"
	streets_btn.custom_minimum_size = Vector2(340, 64)
	streets_btn.add_theme_font_size_override("font_size", 18)
	streets_btn.add_theme_color_override("font_color", Color(0, 1, 1))
	streets_btn.add_theme_color_override("font_hover_color", Color(0.5, 1, 1))
	streets_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	streets_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0, 0.8, 1, 0.5)))
	streets_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8)))
	streets_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0)))
	streets_btn.add_theme_stylebox_override("focus", _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8)))
	lp_vbox.add_child(streets_btn)

	# Skyscraper button
	var sky_btn := Button.new()
	sky_btn.name = "SkyscraperButton"
	sky_btn.text = "SKYSCRAPER\nRooftop Sunset Showdown"
	sky_btn.custom_minimum_size = Vector2(340, 64)
	sky_btn.add_theme_font_size_override("font_size", 18)
	sky_btn.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	sky_btn.add_theme_color_override("font_hover_color", Color(1, 0.85, 0.5))
	sky_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	sky_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.04, 0.02, 0.85), Color(1, 0.6, 0.2, 0.5)))
	sky_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.12, 0.06, 0.03, 0.9), Color(1, 0.8, 0.3, 0.8)))
	sky_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.15, 0.08, 0.02, 0.9), Color(1, 0.9, 0.4, 1.0)))
	sky_btn.add_theme_stylebox_override("focus", _make_button_style(Color(0.12, 0.06, 0.03, 0.9), Color(1, 0.8, 0.3, 0.8)))
	lp_vbox.add_child(sky_btn)

	# Back button
	var back_btn := Button.new()
	back_btn.name = "LevelBackButton"
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(340, 48)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	back_btn.add_theme_color_override("font_hover_color", Color(0, 1, 1))
	back_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	back_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.3, 0.4, 0.5, 0.4)))
	back_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8)))
	back_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0)))
	back_btn.add_theme_stylebox_override("focus", _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8)))
	lp_vbox.add_child(back_btn)

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
