extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_settings_panel.gd

func _initialize() -> void:
	print("Generating: SettingsPanel")

	var root := PanelContainer.new()
	root.name = "SettingsPanel"
	root.custom_minimum_size = Vector2(400, 200)
	root.set_script(load("res://scripts/settings_panel.gd"))
	var panel_style := _make_panel()
	root.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 20)
	root.add_child(vbox)

	# ── Title ──
	var title := Label.new()
	title.name = "Title"
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0, 1, 1))
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# ── Sensitivity row ──
	var row := HBoxContainer.new()
	row.name = "SensitivityRow"
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var label := Label.new()
	label.name = "Label"
	label.text = "MOUSE SENSITIVITY"
	label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	label.add_theme_font_size_override("font_size", 14)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0.0005
	slider.max_value = 0.006
	slider.step = 0.0001
	slider.value = 0.002
	slider.custom_minimum_size = Vector2(180, 20)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Style the slider grabber area
	var grabber_style := StyleBoxFlat.new()
	grabber_style.bg_color = Color(0, 0.8, 1, 0.6)
	grabber_style.corner_radius_top_left = 2
	grabber_style.corner_radius_top_right = 2
	grabber_style.corner_radius_bottom_left = 2
	grabber_style.corner_radius_bottom_right = 2
	slider.add_theme_stylebox_override("slider", grabber_style)
	var grabber_area := StyleBoxFlat.new()
	grabber_area.bg_color = Color(0.1, 0.12, 0.18, 0.8)
	grabber_area.corner_radius_top_left = 2
	grabber_area.corner_radius_top_right = 2
	grabber_area.corner_radius_bottom_left = 2
	grabber_area.corner_radius_bottom_right = 2
	slider.add_theme_stylebox_override("grabber_area", grabber_area)
	slider.add_theme_stylebox_override("grabber_area_highlight", grabber_style)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "3.5"
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color(0, 1, 1, 0.9))
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(value_label)

	# ── Reset Defaults button ──
	var reset_btn := Button.new()
	reset_btn.name = "ResetButton"
	reset_btn.text = "RESET DEFAULTS"
	reset_btn.custom_minimum_size = Vector2(280, 42)
	reset_btn.add_theme_font_size_override("font_size", 16)
	reset_btn.add_theme_color_override("font_color", Color(0.6, 0.5, 0.2))
	reset_btn.add_theme_color_override("font_hover_color", Color(1, 0.85, 0.3))
	reset_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var rst_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.5, 0.4, 0.15, 0.4))
	var rst_hover := _make_button_style(Color(0.06, 0.05, 0.02, 0.9), Color(1, 0.85, 0.3, 0.8))
	var rst_pressed := _make_button_style(Color(0.1, 0.08, 0.0, 0.9), Color(1, 0.85, 0.3, 1.0))
	reset_btn.add_theme_stylebox_override("normal", rst_normal)
	reset_btn.add_theme_stylebox_override("hover", rst_hover)
	reset_btn.add_theme_stylebox_override("pressed", rst_pressed)
	reset_btn.add_theme_stylebox_override("focus", rst_hover)
	reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(reset_btn)

	# ── Back button ──
	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(280, 48)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	back_btn.add_theme_color_override("font_hover_color", Color(0, 1, 1))
	back_btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	var b_normal := _make_button_style(Color(0.03, 0.03, 0.08, 0.85), Color(0.4, 0.5, 0.6, 0.4))
	var b_hover := _make_button_style(Color(0.05, 0.05, 0.12, 0.9), Color(0, 1, 1, 0.8))
	var b_pressed := _make_button_style(Color(0, 0.15, 0.2, 0.9), Color(0, 1, 1, 1.0))
	back_btn.add_theme_stylebox_override("normal", b_normal)
	back_btn.add_theme_stylebox_override("hover", b_hover)
	back_btn.add_theme_stylebox_override("pressed", b_pressed)
	back_btn.add_theme_stylebox_override("focus", b_hover)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(back_btn)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/settings_panel.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/settings_panel.tscn")
	quit(0)

func _make_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.03, 0.08, 0.9)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0, 0.8, 1, 0.4)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 20
	s.content_margin_bottom = 20
	return s

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
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
