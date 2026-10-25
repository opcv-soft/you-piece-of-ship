extends Node3D
## A pirate broadside you see coming (Olivier, 2026-10-25: "Broadsides you see coming"). While the
## pirates take aim: gun ports on the side facing us swing open and the muzzles run out, fuses spark,
## and a red ring marks each spot where a ball will come down, shrinking and pulsing faster until they
## fire. The rings stay put on the sea, so the helm can sail the deck out of them. A child of enemy_ship.

const RED := Color(1.0, 0.22, 0.15, 0.9)
const PORT_DARK := Color(0.08, 0.06, 0.07)

var ship: Node3D ## the pirate ship this belongs to

var _ports: Array[Node3D] = []
var _rings: Array[MeshInstance3D] = []
var _material: StandardMaterial3D
var _fuses: Array[CPUParticles3D] = []
var _left := 0.0
var _total := 1.0


func _ready() -> void:
	name = "BroadsideWarning"
	ship = get_parent()
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.no_depth_test = true # seen through the deck, the rigging and the crew
	_material.render_priority = 5
	_material.albedo_color = RED


## Gun ports along the side facing our ship (side -1 attacks from our port, so its guns face +z).
func build_ports(count: int, side: float, model_scale: float) -> void:
	for port in _ports:
		port.queue_free()
	_ports.clear()
	_fuses.clear()
	var dark := StandardMaterial3D.new()
	dark.albedo_color = PORT_DARK
	var iron := load("res://scripts/systems/toon.gd").material("iron") as Material
	for i in count:
		var port := Node3D.new()
		port.name = "GunPort%d" % i
		port.position = Vector3((float(i) - (count - 1) / 2.0) * 3.0 * model_scale + 1.2, 1.4, -side * 2.6 * model_scale)
		add_child(port)
		var hole := MeshInstance3D.new() # the open port: a dark square in the hull
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 0.7, 0.1)
		hole.mesh = box
		hole.material_override = dark
		port.add_child(hole)
		var muzzle := MeshInstance3D.new() # runs out through the port while they aim
		muzzle.name = "Muzzle"
		var barrel := CylinderMesh.new()
		barrel.top_radius = 0.2
		barrel.bottom_radius = 0.26
		barrel.height = 1.2
		muzzle.mesh = barrel
		muzzle.material_override = iron
		muzzle.rotation.x = PI / 2.0
		port.add_child(muzzle)
		var fuse := CPUParticles3D.new() # sparks at the touch-hole
		fuse.amount = 12
		fuse.lifetime = 0.35
		fuse.emitting = false
		var spark := SphereMesh.new()
		spark.radius = 0.06
		spark.height = 0.12
		var hot := StandardMaterial3D.new()
		hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hot.albedo_color = Color(1.0, 0.75, 0.2)
		spark.material = hot
		fuse.mesh = spark
		fuse.direction = Vector3.UP
		fuse.spread = 60.0
		fuse.initial_velocity_min = 1.0
		fuse.initial_velocity_max = 2.5
		fuse.gravity = Vector3(0, -4, 0)
		fuse.position = Vector3(0, 0.4, side * 0.4)
		port.add_child(fuse)
		_fuses.append(fuse)
		port.set_meta("side", side)
		port.visible = false
		_ports.append(port)


## They take aim: open the ports and ring each landing spot (world positions) for `seconds`.
func show_warning(points: Array, seconds: float) -> void:
	clear()
	_total = maxf(seconds, 0.01)
	_left = _total
	for point in points:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.5
		torus.outer_radius = 2.1
		torus.material = _material
		ring.mesh = torus
		ring.top_level = true
		add_child(ring)
		ring.global_position = Vector3(point.x, 1.3, point.z)
		_rings.append(ring)
	for port in _ports:
		port.visible = true
		var muzzle := port.get_node("Muzzle") as Node3D
		muzzle.position.z = 0.0
		port.create_tween().tween_property(muzzle, "position:z", -float(port.get_meta("side")) * 0.6, 0.4) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for fuse in _fuses:
		fuse.emitting = true


## They fired, sank, gave up or were knocked off their aim: everything goes away.
func clear() -> void:
	for ring in _rings:
		ring.queue_free()
	_rings.clear()
	_left = 0.0
	for port in _ports:
		port.visible = false
	for fuse in _fuses:
		fuse.emitting = false


func showing() -> bool:
	return not _rings.is_empty()


func rings() -> Array[MeshInstance3D]:
	return _rings


func _process(delta: float) -> void:
	if _rings.is_empty():
		return
	_left = maxf(_left - delta, 0.0)
	var t := 1.0 - _left / _total # 0 when they start aiming, 1 as they fire
	var pulse := 1.0 + sin(Time.get_ticks_msec() * (0.008 + t * 0.03)) * 0.12 # faster as the fuse burns down
	for ring in _rings:
		ring.scale = Vector3.ONE * lerpf(1.8, 1.0, t) * pulse
	_material.albedo_color = RED.lerp(Color(1.0, 0.95, 0.3, 1.0), t * t) # red to hot yellow just before the shot
