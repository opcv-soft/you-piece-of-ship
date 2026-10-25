extends Node3D
## The bowsprit kebab (Olivier, 2026-10-25, circled the bowsprit: "I want the siren here"; then
## "sirens like shrimps, whales as whale blubbers"): trophies threaded on the pole like a kebab stick.
## A siren is curled into a C hanging under the pole, the pole through her head and her tail fin; a
## whale is a block of scored pink blubber on black skin, the pole through it. Each new trophy goes
## further in along the pole; when the outboard end is full the next row sits on top. Drawn over the
## see-through jib so it never washes them out. A child of ShipStores (ship_stores.gd).

const Toon = preload("res://scripts/systems/toon.gd")
## The pole rises POLE_ANGLE toward the bow (tools/blender/build_ship.py).
const POLE_ANGLE := 0.272
const TIP := Vector3(17.4, 2.72, 0.0) ## the first trophy, near the bowsprit's end (ship frame)
const STEP := Vector3(-1.15, -0.32, 0.0) ## the next one, further in along the pole
const ROOM := 3 ## trophies that fit hanging under the outboard pole; more sit on top of it
const SIZE := 0.85
const BLUBBER_PINK := Color(1.0, 0.62, 0.45) ## salmon fat, like Olivier's photo
const CURL := 0.75 ## a skewered siren's curl: a C this radius, both ends on the pole

static var _over_sail_cache := {}
var trophies: Array[Node3D] = []


func _ready() -> void:
	name = "BowspritSkewer"


func add_siren() -> Node3D:
	return _thread(_siren(), "Siren")


func add_blubber() -> Node3D:
	return _thread(_blubber(), "Blubber")


## Puts a trophy (built in the pole's frame: x along it toward the bow, y up, z sideways) in the
## next slot, with a pop.
func _thread(trophy: Node3D, kind: String) -> Node3D:
	var n := trophies.size()
	trophy.name = "%s%d" % [kind, get_children().filter(func(c): return String(c.name).begins_with(kind)).size() + 1]
	trophy.position = TIP + STEP * (n % ROOM)
	var on_top := (n / ROOM) % 2 == 1 # a full row: the next one sits on top of the pole
	var along := Basis(Vector3.BACK, POLE_ANGLE)
	if on_top and kind == "Blubber":
		trophy.position += along.y * 0.5 * SIZE # skin side still down, resting on the pole
	elif on_top:
		along = along * Basis(Vector3.RIGHT, PI) # a siren's curl turned up over the pole
	trophy.basis = along
	for mesh in trophy.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _over_sail(mesh.material_override)
	add_child(trophy)
	trophies.append(trophy)
	trophy.scale = Vector3.ONE * 0.01 # (not zero: that would lose its turn onto the pole)
	trophy.create_tween().tween_property(trophy, "scale", Vector3.ONE * SIZE, 0.4) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return trophy


## A siren like a shrimp: curled into a C, her tail banded like a shrimp's shell, eyes crossed out.
## Built with the pole along her local y, then turned so the C hangs under it.
func _siren() -> Node3D:
	var holder := Node3D.new()
	var siren := Node3D.new()
	siren.rotation.z = PI / 2.0
	holder.add_child(siren)
	# Head, then torso, then a tail getting thinner, round the C. [material, degrees on the arc, size]
	var segments := [["skin", 112.0, 0.4], ["skin", 88.0, 0.3], ["skin", 68.0, 0.36], ["skin", 48.0, 0.34],
			["tail", 26.0, 0.32], ["tail_band", 6.0, 0.3], ["tail", -14.0, 0.28], ["tail_band", -34.0, 0.26],
			["tail", -54.0, 0.24], ["tail_band", -74.0, 0.21], ["tail", -94.0, 0.18]]
	for segment in segments:
		var material: String = segment[0]
		var mat := Toon.material("tail", Color(0.2, 0.62, 0.58)) if material == "tail_band" else Toon.material(material)
		siren.add_child(_blob(mat, _on_curl(segment[1]), Vector3.ONE * float(segment[2])))
	var head := _on_curl(112.0)
	siren.add_child(_blob(Toon.material("hair"), head + Vector3(-0.22, 0.12, 0.0), Vector3(0.36, 0.42, 0.44))) # hair
	siren.add_child(_blob(Toon.material("hair"), head + Vector3(-0.45, -0.3, 0.0), Vector3(0.16, 0.42, 0.3))) # hanging locks
	for z in [-1.0, 1.0]: # face on both sides: crossed-out eyes and a blush
		for eye_x in [0.12, -0.08]:
			for tilt in [0.8, -0.8]:
				var stroke := _blob(Toon.material("eye"), head + Vector3(eye_x, 0.06, z * 0.37), Vector3(0.025, 0.1, 0.025))
				stroke.rotation.z = tilt
				siren.add_child(stroke)
		siren.add_child(_blob(Toon.material("blush"), head + Vector3(0.02, -0.12, z * 0.34), Vector3(0.08, 0.05, 0.04)))
		siren.add_child(_blob(Toon.material("skin"), _on_curl(70.0) + Vector3(-0.15, -0.05, z * 0.36), Vector3(0.1, 0.24, 0.1))) # arms
	var fin := _on_curl(-112.0)
	for spread in [-0.5, 0.5]: # the tail fin, fanned out on the pole like a shrimp's tail
		var lobe := _blob(Toon.material("tail"), fin + Vector3(0.0, -0.12, spread * 0.4), Vector3(0.1, 0.3, 0.28))
		lobe.rotation.x = spread
		siren.add_child(lobe)
	return holder


## A whale as a block of blubber (Olivier's photo, 2026-10-25): black skin underneath, pale pink fat
## on top scored into thick slices, the pole through it.
func _blubber() -> Node3D:
	var block := Node3D.new()
	block.add_child(_box(Toon.material("coal"), Vector3(0.0, -0.32, 0.0), Vector3(1.0, 0.42, 0.7))) # the skin
	var fat := Toon.material("skin", BLUBBER_PINK)
	for i in 7: # the slices, a little gap between each
		block.add_child(_box(fat, Vector3(-0.43 + i * 0.143, 0.1, 0.0), Vector3(0.13, 0.44, 0.68)))
	return block


## The see-through sails (the jib over the bowsprit) would wash the trophies out: draw them after
## the sails and the rigging.
static func _over_sail(source: Material) -> Material:
	var key := source.get_instance_id()
	if not _over_sail_cache.has(key):
		var mat := Toon.see_through(source, 1.0).duplicate() as Material
		mat.render_priority = 5
		_over_sail_cache[key] = mat
	return _over_sail_cache[key]


## A point on a skewered siren's curl, `degrees` round it (90 = the top end, on the pole).
static func _on_curl(degrees: float) -> Vector3:
	var a := deg_to_rad(degrees)
	return Vector3(CURL * (cos(deg_to_rad(112.0)) - cos(a)), CURL * sin(a), 0.0)


static func _blob(material: Material, at: Vector3, size: Vector3) -> MeshInstance3D:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	ball.mesh = sphere
	ball.material_override = material
	ball.position = at
	ball.scale = size
	return ball


static func _box(material: Material, at: Vector3, size: Vector3) -> MeshInstance3D:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	box.mesh = mesh
	box.material_override = material
	box.position = at
	return box
