extends Node
## res://scripts/settings_manager.gd — Autoload singleton for persistent game settings

signal sensitivity_changed(value: float)

const SAVE_PATH := "user://settings.cfg"
const DEFAULT_SENSITIVITY := 0.002
const WEB_SENSITIVITY_MULTIPLIER := 2.5

var mouse_sensitivity: float = DEFAULT_SENSITIVITY:
	set(value):
		mouse_sensitivity = value
		sensitivity_changed.emit(value)

func _ready() -> void:
	load_settings()

func get_effective_sensitivity() -> float:
	if OS.has_feature("web"):
		return mouse_sensitivity * WEB_SENSITIVITY_MULTIPLIER
	return mouse_sensitivity

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.save(SAVE_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", DEFAULT_SENSITIVITY)
