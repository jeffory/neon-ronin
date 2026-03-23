extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_hud.gd

func _initialize() -> void:
	print("Generating: HUD")

	var root := CanvasLayer.new()
	root.name = "HUD"
	root.layer = 1
	root.set_script(load("res://scripts/hud_controller.gd"))

	# Full-rect Control container
	var container := Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container)

	# ── Health Area (top-left, no panel border) ──
	# Health bar row: bar + percentage
	var bar_row := HBoxContainer.new()
	bar_row.name = "BarRow"
	bar_row.anchor_left = 0.0
	bar_row.anchor_top = 0.0
	bar_row.offset_left = 24
	bar_row.offset_top = 24
	bar_row.offset_right = 280
	bar_row.offset_bottom = 36
	bar_row.add_theme_constant_override("separation", 8)
	container.add_child(bar_row)

	var health_bar := ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(180, 8)
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# White-cyan gradient fill
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.7, 0.95, 1.0, 0.95)
	fill_style.corner_radius_top_left = 1
	fill_style.corner_radius_top_right = 1
	fill_style.corner_radius_bottom_left = 1
	fill_style.corner_radius_bottom_right = 1
	health_bar.add_theme_stylebox_override("fill", fill_style)
	# Subtle dark background
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.12, 0.18, 0.6)
	bar_bg.corner_radius_top_left = 1
	bar_bg.corner_radius_top_right = 1
	bar_bg.corner_radius_bottom_left = 1
	bar_bg.corner_radius_bottom_right = 1
	health_bar.add_theme_stylebox_override("background", bar_bg)
	bar_row.add_child(health_bar)

	# Health percentage next to bar
	var health_percent := Label.new()
	health_percent.name = "HealthPercent"
	health_percent.text = "100%"
	health_percent.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	health_percent.add_theme_font_size_override("font_size", 14)
	health_percent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(health_percent)

	# Info row below bar: player name + HP value
	var info_row := HBoxContainer.new()
	info_row.name = "InfoRow"
	info_row.anchor_left = 0.0
	info_row.anchor_top = 0.0
	info_row.offset_left = 24
	info_row.offset_top = 40
	info_row.offset_right = 280
	info_row.offset_bottom = 56
	info_row.add_theme_constant_override("separation", 10)
	container.add_child(info_row)

	var player_name := Label.new()
	player_name.name = "PlayerName"
	player_name.text = "NEON_RONIN"
	player_name.add_theme_color_override("font_color", Color(0, 0.9, 1, 0.8))
	player_name.add_theme_font_size_override("font_size", 11)
	info_row.add_child(player_name)

	var health_value := Label.new()
	health_value.name = "HealthValue"
	health_value.text = "100/100"
	health_value.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7, 0.7))
	health_value.add_theme_font_size_override("font_size", 11)
	info_row.add_child(health_value)

	# ── Weapon Area (bottom-LEFT, no panel border) ──
	var weapon_area := HBoxContainer.new()
	weapon_area.name = "WeaponArea"
	weapon_area.anchor_left = 0.0
	weapon_area.anchor_top = 1.0
	weapon_area.anchor_right = 0.0
	weapon_area.anchor_bottom = 1.0
	weapon_area.offset_left = 24
	weapon_area.offset_top = -76
	weapon_area.offset_right = 280
	weapon_area.offset_bottom = -20
	weapon_area.add_theme_constant_override("separation", 10)
	container.add_child(weapon_area)

	# Weapon icon (left)
	var weapon_icon := TextureRect.new()
	weapon_icon.name = "WeaponIcon"
	weapon_icon.custom_minimum_size = Vector2(56, 40)
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	weapon_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_tex: Texture2D = load("res://assets/img/icon_handgun.png")
	if icon_tex:
		weapon_icon.texture = icon_tex
	weapon_area.add_child(weapon_icon)

	# Weapon text info (right of icon)
	var weapon_vbox := VBoxContainer.new()
	weapon_vbox.name = "WeaponVBox"
	weapon_vbox.add_theme_constant_override("separation", 2)
	weapon_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	weapon_area.add_child(weapon_vbox)

	var ammo_label := Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "12 / 36"
	ammo_label.add_theme_color_override("font_color", Color(1, 1, 1))
	ammo_label.add_theme_font_size_override("font_size", 28)
	weapon_vbox.add_child(ammo_label)

	var weapon_label := Label.new()
	weapon_label.name = "WeaponLabel"
	weapon_label.text = "HANDGUN"
	weapon_label.add_theme_color_override("font_color", Color(0, 0.9, 1, 0.7))
	weapon_label.add_theme_font_size_override("font_size", 12)
	weapon_vbox.add_child(weapon_label)

	# ── Crosshair (center, small dot) ──
	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "·"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -8
	crosshair.offset_top = -10
	crosshair.offset_right = 8
	crosshair.offset_bottom = 10
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_color_override("font_color", Color(0, 1, 1, 0.8))
	crosshair.add_theme_font_size_override("font_size", 14)
	container.add_child(crosshair)

	# ── Damage Overlay (full screen) ──
	var damage_overlay := Control.new()
	damage_overlay.name = "DamageOverlay"
	damage_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.set_script(load("res://scripts/damage_overlay.gd"))
	container.add_child(damage_overlay)

	# ── Kill Feed (top-right) ──
	var kill_feed := VBoxContainer.new()
	kill_feed.name = "KillFeed"
	kill_feed.anchor_left = 1.0
	kill_feed.anchor_top = 0.0
	kill_feed.anchor_right = 1.0
	kill_feed.anchor_bottom = 0.0
	kill_feed.offset_left = -400
	kill_feed.offset_top = 20
	kill_feed.offset_right = -20
	kill_feed.offset_bottom = 200
	container.add_child(kill_feed)

	# ── Scoreboard (center, hidden) ──
	var scoreboard := PanelContainer.new()
	scoreboard.name = "Scoreboard"
	scoreboard.anchor_left = 0.5
	scoreboard.anchor_top = 0.5
	scoreboard.anchor_right = 0.5
	scoreboard.anchor_bottom = 0.5
	scoreboard.offset_left = -300
	scoreboard.offset_top = -200
	scoreboard.offset_right = 300
	scoreboard.offset_bottom = 200
	scoreboard.visible = false
	var sb_style := _make_panel()
	sb_style.corner_radius_top_left = 8
	sb_style.corner_radius_top_right = 8
	sb_style.corner_radius_bottom_left = 8
	sb_style.corner_radius_bottom_right = 8
	sb_style.border_width_left = 2
	sb_style.border_width_top = 2
	sb_style.border_width_right = 2
	sb_style.border_width_bottom = 2
	scoreboard.add_theme_stylebox_override("panel", sb_style)
	container.add_child(scoreboard)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/hud.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/hud.tscn")
	quit(0)

func _make_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.03, 0.08, 0.8)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0, 0.8, 1, 0.4)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
