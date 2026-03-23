extends Node
## res://scripts/effect_pool.gd — Object pool for impact particles and muzzle flash lights

const PARTICLE_POOL_SIZE := 16
const LIGHT_POOL_SIZE := 8

var _particle_pool: Array[GPUParticles3D] = []
var _light_pool: Array[OmniLight3D] = []

# Shared materials (created once, reused by all particles)
var _impact_material: ParticleProcessMaterial
var _impact_mesh: SphereMesh
var _bot_impact_material: ParticleProcessMaterial
var _bot_impact_mesh: SphereMesh

func _ready() -> void:
	# Pre-create shared materials
	_impact_material = ParticleProcessMaterial.new()
	_impact_material.spread = 30.0
	_impact_material.initial_velocity_min = 3.0
	_impact_material.initial_velocity_max = 6.0
	_impact_material.gravity = Vector3(0, -9.8, 0)
	_impact_material.color = Color(1.0, 0.8, 0.3)

	_impact_mesh = SphereMesh.new()
	_impact_mesh.radius = 0.02
	_impact_mesh.height = 0.04

	_bot_impact_material = ParticleProcessMaterial.new()
	_bot_impact_material.spread = 25.0
	_bot_impact_material.initial_velocity_min = 2.0
	_bot_impact_material.initial_velocity_max = 5.0
	_bot_impact_material.gravity = Vector3(0, -9.8, 0)
	_bot_impact_material.color = Color(1.0, 0.6, 0.2)

	_bot_impact_mesh = SphereMesh.new()
	_bot_impact_mesh.radius = 0.015
	_bot_impact_mesh.height = 0.03

	# Pre-allocate particle nodes
	for i in PARTICLE_POOL_SIZE:
		var p := GPUParticles3D.new()
		p.one_shot = true
		p.emitting = false
		p.visible = false
		add_child(p)
		_particle_pool.append(p)

	# Pre-allocate light nodes
	for i in LIGHT_POOL_SIZE:
		var l := OmniLight3D.new()
		l.visible = false
		l.light_color = Color(1.0, 0.7, 0.2)
		l.omni_range = 6.0
		l.omni_attenuation = 2.0
		add_child(l)
		_light_pool.append(l)

func spawn_impact(pos: Vector3, normal: Vector3, is_bot: bool = false) -> void:
	var p: GPUParticles3D = _get_free_particle()
	if not p:
		return  # Pool exhausted, skip effect

	if is_bot:
		p.process_material = _bot_impact_material
		p.draw_pass_1 = _bot_impact_mesh
		p.amount = 6
		p.lifetime = 0.25
	else:
		p.process_material = _impact_material
		p.draw_pass_1 = _impact_mesh
		p.amount = 8
		p.lifetime = 0.3

	# Set direction on a per-instance copy would require a new material,
	# but we can just set the direction on the shared material briefly.
	# Since particles are one-shot and emitted instantly with explosiveness=1.0,
	# all particles spawn on the same frame, so sharing is safe.
	var mat: ParticleProcessMaterial = p.process_material
	mat.direction = normal
	p.explosiveness = 1.0
	p.global_position = pos
	p.visible = true
	p.emitting = true

	# Return to pool after lifetime
	get_tree().create_timer(0.5).timeout.connect(_return_particle.bind(p))

func spawn_muzzle_flash(pos: Vector3) -> void:
	var l: OmniLight3D = _get_free_light()
	if not l:
		return

	l.global_position = pos
	l.light_energy = 4.0
	l.visible = true

	var tween: Tween = l.create_tween()
	tween.tween_property(l, "light_energy", 0.0, 0.08)
	tween.tween_callback(_return_light.bind(l))

func _get_free_particle() -> GPUParticles3D:
	for p in _particle_pool:
		if not p.emitting and not p.visible:
			return p
	return null

func _get_free_light() -> OmniLight3D:
	for l in _light_pool:
		if not l.visible:
			return l
	return null

func _return_particle(p: GPUParticles3D) -> void:
	if is_instance_valid(p):
		p.emitting = false
		p.visible = false

func _return_light(l: OmniLight3D) -> void:
	if is_instance_valid(l):
		l.visible = false
