extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_loading_screen.gd

func _initialize() -> void:
	print("Generating: LoadingScreen")

	var root := Control.new()
	root.name = "LoadingScreen"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://scripts/loading_screen.gd"))

	# ── Dark background ──
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.01, 0.01, 0.02, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)

	# ── Center VBoxContainer ──
	var vbox := VBoxContainer.new()
	vbox.name = "CenterBox"
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -200
	vbox.offset_top = -80
	vbox.offset_right = 200
	vbox.offset_bottom = 80
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(vbox)

	# ── "LOADING..." label ──
	var loading_label := Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "LOADING..."
	loading_label.add_theme_color_override("font_color", Color(0, 1, 1))
	loading_label.add_theme_font_size_override("font_size", 36)
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(loading_label)

	# ── Level name label ──
	var level_name := Label.new()
	level_name.name = "LevelName"
	level_name.text = "Loading level..."
	level_name.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	level_name.add_theme_font_size_override("font_size", 20)
	level_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(level_name)

	# ── ProgressBar ──
	var progress := ProgressBar.new()
	progress.name = "LoadProgress"
	progress.custom_minimum_size = Vector2(400, 20)
	progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress.min_value = 0.0
	progress.max_value = 100.0
	progress.value = 0.0
	progress.show_percentage = false

	# Custom styling — dark background with cyan fill
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.05, 0.05, 0.1, 0.9)
	bg_style.corner_radius_top_left = 3
	bg_style.corner_radius_top_right = 3
	bg_style.corner_radius_bottom_left = 3
	bg_style.corner_radius_bottom_right = 3
	bg_style.border_color = Color(0, 0.6, 0.8, 0.5)
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	progress.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0, 0.9, 1.0, 0.9)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	progress.add_theme_stylebox_override("fill", fill_style)

	vbox.add_child(progress)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("Pack failed: " + str(err))
		quit(1)
		return
	err = ResourceSaver.save(packed, "res://scenes/loading_screen.tscn")
	if err != OK:
		push_error("Save failed: " + str(err))
		quit(1)
		return
	print("Saved: res://scenes/loading_screen.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
