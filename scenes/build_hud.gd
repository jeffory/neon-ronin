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

	# Health bar — bottom left
	var health_bar := ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	# Anchor bottom-left
	health_bar.anchor_left = 0.0
	health_bar.anchor_top = 1.0
	health_bar.anchor_right = 0.0
	health_bar.anchor_bottom = 1.0
	health_bar.offset_left = 20
	health_bar.offset_top = -50
	health_bar.offset_right = 250
	health_bar.offset_bottom = -20
	# Style
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.1, 0.9, 0.3, 0.9)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("background", bg_style)
	container.add_child(health_bar)

	# Health label
	var health_label := Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP"
	health_label.anchor_left = 0.0
	health_label.anchor_top = 1.0
	health_label.anchor_right = 0.0
	health_label.anchor_bottom = 1.0
	health_label.offset_left = 20
	health_label.offset_top = -70
	health_label.offset_right = 100
	health_label.offset_bottom = -50
	health_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	health_label.add_theme_font_size_override("font_size", 14)
	container.add_child(health_label)

	# Ammo label — bottom right
	var ammo_label := Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "12 / 36"
	ammo_label.anchor_left = 1.0
	ammo_label.anchor_top = 1.0
	ammo_label.anchor_right = 1.0
	ammo_label.anchor_bottom = 1.0
	ammo_label.offset_left = -230
	ammo_label.offset_top = -45
	ammo_label.offset_right = -20
	ammo_label.offset_bottom = -20
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_color_override("font_color", Color(1, 1, 1))
	ammo_label.add_theme_font_size_override("font_size", 22)
	container.add_child(ammo_label)

	# Weapon label — bottom right, above ammo
	var weapon_label := Label.new()
	weapon_label.name = "WeaponLabel"
	weapon_label.text = "HANDGUN"
	weapon_label.anchor_left = 1.0
	weapon_label.anchor_top = 1.0
	weapon_label.anchor_right = 1.0
	weapon_label.anchor_bottom = 1.0
	weapon_label.offset_left = -230
	weapon_label.offset_top = -70
	weapon_label.offset_right = -20
	weapon_label.offset_bottom = -48
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.add_theme_color_override("font_color", Color(0, 0.9, 1))
	weapon_label.add_theme_font_size_override("font_size", 14)
	container.add_child(weapon_label)

	# Crosshair — center
	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -10
	crosshair.offset_top = -15
	crosshair.offset_right = 10
	crosshair.offset_bottom = 15
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	crosshair.add_theme_font_size_override("font_size", 24)
	container.add_child(crosshair)

	# Kill feed — top right
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

	# Scoreboard — center, hidden
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
	# Dark semi-transparent background
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0, 0.8, 1, 0.5)
	scoreboard.add_theme_stylebox_override("panel", panel_style)
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

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
