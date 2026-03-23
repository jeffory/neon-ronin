extends Control
## res://scripts/loading_screen.gd — Loading screen with threaded resource loading

@onready var level_name_label: Label = $CenterBox/LevelName
@onready var progress_bar: ProgressBar = $CenterBox/LoadProgress

var _target_scene_path: String = "res://scenes/main.tscn"
var _load_requested: bool = false
var _elapsed: float = 0.0
var _min_display_time: float = 0.5
var _load_finished: bool = false
var _loaded_resource: Resource = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Get level name from GameManager autoload
	var gm: Node = _find_autoload("GameManager")
	if gm and gm.has_method("get_current_level_name"):
		var lname: String = gm.get_current_level_name()
		level_name_label.text = lname
	else:
		level_name_label.text = "Loading level..."
	# Start threaded loading
	var err: int = ResourceLoader.load_threaded_request(_target_scene_path)
	if err == OK:
		_load_requested = true
	else:
		push_error("LoadingScreen: Failed to start threaded load for %s (error %d)" % [_target_scene_path, err])
		# Fallback: go back to title screen
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _process(delta: float) -> void:
	_elapsed += delta
	if not _load_requested:
		return
	# Poll loading status
	var progress_arr: Array = []
	var status: int = ResourceLoader.load_threaded_get_status(_target_scene_path, progress_arr)
	# Update progress bar
	if progress_arr.size() > 0:
		var pct: float = progress_arr[0] * 100.0
		progress_bar.value = pct
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass  # Keep polling
		ResourceLoader.THREAD_LOAD_LOADED:
			progress_bar.value = 100.0
			if not _load_finished:
				_load_finished = true
				_loaded_resource = ResourceLoader.load_threaded_get(_target_scene_path)
			# Wait for minimum display time so the screen doesn't flash
			if _elapsed >= _min_display_time and _loaded_resource:
				var packed: PackedScene = _loaded_resource as PackedScene
				if packed:
					get_tree().change_scene_to_packed(packed)
				else:
					push_error("LoadingScreen: Loaded resource is not a PackedScene")
					get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("LoadingScreen: Threaded load FAILED for %s" % _target_scene_path)
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("LoadingScreen: Invalid resource %s" % _target_scene_path)
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _find_autoload(autoload_name: String) -> Node:
	for child in get_tree().root.get_children():
		if child.name == autoload_name:
			return child
	return null
