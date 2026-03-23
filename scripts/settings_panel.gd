extends PanelContainer
## res://scripts/settings_panel.gd — Reusable settings panel with mouse sensitivity slider

signal back_pressed

func _ready() -> void:
	var slider: HSlider = $VBox/SensitivityRow/Slider
	var value_label: Label = $VBox/SensitivityRow/ValueLabel
	var reset_btn: Button = $VBox/ResetButton
	var back_btn: Button = $VBox/BackButton

	# Load current value
	var sm: Node = Engine.get_singleton("SettingsManager") if Engine.has_singleton("SettingsManager") else get_node_or_null("/root/SettingsManager")
	if sm:
		slider.value = sm.mouse_sensitivity
		_update_value_label(value_label, sm.mouse_sensitivity)

	slider.value_changed.connect(func(val: float) -> void:
		_update_value_label(value_label, val)
		if sm:
			sm.mouse_sensitivity = val
			sm.save_settings()
	)

	reset_btn.pressed.connect(func() -> void:
		if sm:
			slider.value = sm.DEFAULT_SENSITIVITY
	)

	back_btn.pressed.connect(func() -> void:
		back_pressed.emit()
	)

func _update_value_label(label: Label, val: float) -> void:
	# Display as a readable 1-10 scale
	var display_val: float = remap(val, 0.0005, 0.006, 1.0, 10.0)
	label.text = str(snapped(display_val, 0.1))
