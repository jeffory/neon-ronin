extends Node
## res://scripts/web_performance.gd — Autoload that reduces rendering/physics cost on web

func _ready() -> void:
	if not OS.has_feature("web"):
		return

	# Reduce physics tick rate from 120 to 60 on web
	Engine.physics_ticks_per_second = 60

	# Disable MSAA on web
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED

	# Reduce shadow quality
	RenderingServer.directional_soft_shadow_filter_set_quality(
		RenderingServer.SHADOW_QUALITY_SOFT_LOW
	)

	# Connect to scene changes to apply environment overrides on each level
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is WorldEnvironment:
		# Defer so the environment is fully initialized
		_apply_web_env_overrides.call_deferred(node)

func _apply_web_env_overrides(world_env: WorldEnvironment) -> void:
	if not is_instance_valid(world_env):
		return
	var env: Environment = world_env.environment
	if not env:
		return

	# Disable expensive post-processing effects
	env.ssr_enabled = false
	env.ssao_enabled = false
	env.volumetric_fog_enabled = false

	# Keep glow but reduce it (important for neon aesthetic)
	env.glow_intensity *= 0.5
	env.glow_bloom = 0.0

	# Reduce standard fog density if present
	if env.fog_enabled:
		env.fog_density *= 0.5
