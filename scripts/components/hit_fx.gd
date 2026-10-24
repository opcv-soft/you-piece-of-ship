extends RefCounted
## A cannonball hit, made to feel great (Olivier, 2026-10-24: "beautifully, with confetti and
## animation"): a bright flash, wood and stone debris, a burst of confetti, a squash and shake on
## the target, a camera jolt and a tiny hit-stop. One static call; everything cleans itself up.

const CONFETTI := [Color(1.0, 0.85, 0.25), Color(0.95, 0.35, 0.4), Color(0.3, 0.75, 0.95), Color(0.45, 0.85, 0.4),
		Color(1.0, 1.0, 1.0)]


static func play(at: Vector3, world: Node, target: Node3D = null) -> void:
	if world == null or not world.is_inside_tree():
		return
	_flash(at, world)
	_burst(at, world, _debris_mesh(), 18, 6.0, 11.0, -16.0, 1.2, false)
	_burst(at, world, _confetti_mesh(), 60, 5.0, 12.0, -5.0, 2.2, true)
	if target:
		_squash(target)
	var camera := world.get_viewport().get_camera_3d()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.3)
	Engine.time_scale = 0.15
	world.get_tree().create_timer(0.06, true, false, true).timeout.connect(Engine.set.bind("time_scale", 1.0))


static func _flash(at: Vector3, world: Node) -> void:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(1.0, 0.95, 0.7, 0.9)
	white.emission_enabled = true
	white.emission = Color(1.0, 0.85, 0.4)
	white.emission_energy_multiplier = 3.0
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.material = white
	ball.mesh = sphere
	world.add_child(ball)
	ball.global_position = at + Vector3(0, 1.0, 0)
	ball.scale = Vector3.ONE * 0.3
	var tween := ball.create_tween().set_parallel()
	tween.tween_property(ball, "scale", Vector3.ONE * 3.2, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(white, "albedo_color:a", 0.0, 0.3)
	tween.chain().tween_callback(ball.queue_free)


static func _burst(at: Vector3, world: Node, mesh: Mesh, amount: int, v_min: float, v_max: float, gravity: float,
		life: float, coloured: bool) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.mesh = mesh
	p.direction = Vector3.UP
	p.spread = 75.0
	p.initial_velocity_min = v_min
	p.initial_velocity_max = v_max
	p.gravity = Vector3(0, gravity, 0)
	p.damping_min = 1.0
	p.damping_max = 3.0
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	if coloured:
		var colours := Gradient.new()
		colours.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
		colours.colors = PackedColorArray(CONFETTI)
		p.color_initial_ramp = colours
	world.add_child(p)
	p.global_position = at + Vector3(0, 1.2, 0)
	p.emitting = true
	world.get_tree().create_timer(life + 0.5).timeout.connect(p.queue_free)


static func _debris_mesh() -> Mesh:
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.35, 0.18, 0.2)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.5, 0.33, 0.2)
	chunk.material = wood
	return chunk


static func _confetti_mesh() -> Mesh:
	var bit := QuadMesh.new()
	bit.size = Vector2(0.22, 0.14)
	var paper := StandardMaterial3D.new()
	paper.vertex_color_use_as_albedo = true
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	bit.material = paper
	return bit


static func _squash(target: Node3D) -> void:
	var model := target.get_node_or_null("Model") as Node3D
	var node: Node3D = model if model else target
	var rest := node.scale
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3(rest.x * 1.25, rest.y * 0.75, rest.z * 1.25), 0.07)
	tween.tween_property(node, "scale", rest, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
