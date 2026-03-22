extends SceneTree
## Scene builder — run: timeout 60 godot --headless --script scenes/build_hud.gd

func _initialize() -> void:
	var root := CanvasLayer.new()
	root.name = "HUD"
	root.layer = 1
	root.set_script(load("res://scripts/hud_controller.gd"))

	# Full-rect Control container
	var container := Control.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(container)

	# Health bar — bottom left
	var health_bar := ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.position = Vector2(20, 660)
	health_bar.size = Vector2(200, 25)
	container.add_child(health_bar)

	# Ammo label — bottom right
	var ammo_label := Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.text = "12 / 36"
	ammo_label.position = Vector2(1060, 665)
	ammo_label.size = Vector2(200, 30)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	container.add_child(ammo_label)

	# Weapon label
	var weapon_label := Label.new()
	weapon_label.name = "WeaponLabel"
	weapon_label.text = "HANDGUN"
	weapon_label.position = Vector2(1060, 640)
	weapon_label.size = Vector2(200, 25)
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	container.add_child(weapon_label)

	# Crosshair — center
	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.position = Vector2(632, 352)
	crosshair.size = Vector2(16, 16)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(crosshair)

	# Kill feed — top right
	var kill_feed := VBoxContainer.new()
	kill_feed.name = "KillFeed"
	kill_feed.position = Vector2(880, 20)
	kill_feed.size = Vector2(380, 200)
	container.add_child(kill_feed)

	# Scoreboard — center, hidden
	var scoreboard := PanelContainer.new()
	scoreboard.name = "Scoreboard"
	scoreboard.position = Vector2(340, 160)
	scoreboard.size = Vector2(600, 400)
	scoreboard.visible = false
	container.add_child(scoreboard)

	# Save
	_set_owners(root, root)
	var packed := PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/hud.tscn")
	print("Saved: res://scenes/hud.tscn")
	quit(0)

func _set_owners(node: Node, owner: Node) -> void:
	for c in node.get_children():
		c.owner = owner
		if c.scene_file_path.is_empty():
			_set_owners(c, owner)
