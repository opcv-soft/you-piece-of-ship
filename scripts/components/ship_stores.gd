extends Node3D
## What the crew hauls home (Olivier, 2026-10-24): gold from barrels and treasure piles up in a
## bucket at the bow; charcoal from black rocks goes into the furnace; planks from wrecks and sunk
## pirates go into the plank box; whale grease in barrels; and every siren ends up skewered on the
## mast, curled up like a shrimp (2026-10-25). A child of the ship. At the beach the haul flies to the village (voyage_arrival.gd).

signal stored(resource: String, amount: int)

const Toon = preload("res://scripts/systems/toon.gd")
const KINDS := ["gold", "coal", "planks", "grease", "siren"]
## Score points each unit is worth (the haul still counts in the score).
const POINTS := {"gold": 40, "coal": 15, "planks": 20, "grease": 60, "siren": 150}
const BUCKET := Vector3(8.4, 0.0, -0.9) ## the gold bucket, on the foredeck
const GREASE := Vector3(-8.0, 0.0, -2.6) ## grease barrels, in the stern corner
const SKEWER_TIP := Vector3(1.0, 2.9, 0.0) ## the first siren's middle on the mast, her tail above the crew's heads
const SKEWER_STEP := Vector3(0.0, 1.4, 0.0) ## each new siren goes further up the mast
const SKEWER_ROOM := 3 ## sirens that fit below the crow's nest; more go round the mast at the same heights
const CURL := 0.75 ## a skewered siren's curl: a C this radius, bulging toward the stern, head and tail fin on the mast

var counts := {"gold": 0, "coal": 0, "planks": 0, "grease": 0, "siren": 0}
static var _over_sail_cache := {}
var _gold_heap: MeshInstance3D
var _grease_barrels: Array[Node3D] = []


func _ready() -> void:
	name = "ShipStores"
	_build_bucket()


## Adds to the haul and shows it aboard. Returns the score points it's worth.
func add(resource: String, amount := 1) -> int:
	if not counts.has(resource) or amount <= 0:
		return 0
	counts[resource] += amount if resource != "siren" else 0
	var ship := get_parent()
	match resource:
		"gold":
			_update_bucket()
		"coal":
			var engine := ship.get_node_or_null("EngineSystem")
			if engine:
				engine.fuel = minf(1.0, engine.fuel + 0.12 * amount) # charcoal straight into the firebox
		"planks":
			var box := ship.get_node_or_null("PlankBox")
			if box:
				box.stock += amount
		"grease":
			for i in amount:
				_add_grease_barrel()
		"siren":
			for i in amount:
				counts.siren += 1
				_skewer_siren()
	stored.emit(resource, amount)
	return POINTS.get(resource, 0) * amount


func _build_bucket() -> void:
	var bucket := MeshInstance3D.new()
	bucket.name = "GoldBucket"
	var tub := CylinderMesh.new()
	tub.top_radius = 0.55
	tub.bottom_radius = 0.45
	tub.height = 0.7
	bucket.mesh = tub
	bucket.material_override = Toon.material("wood_hull")
	bucket.position = BUCKET + Vector3(0, 0.35, 0)
	add_child(bucket)
	var band := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.5
	ring.outer_radius = 0.58
	band.mesh = ring
	band.material_override = Toon.material("iron")
	band.position = BUCKET + Vector3(0, 0.55, 0)
	add_child(band)
	_gold_heap = MeshInstance3D.new()
	_gold_heap.name = "GoldHeap"
	var heap := SphereMesh.new()
	heap.radius = 0.5
	heap.height = 0.6
	_gold_heap.mesh = heap
	_gold_heap.material_override = Toon.material("gold")
	_gold_heap.position = BUCKET + Vector3(0, 0.62, 0)
	_gold_heap.visible = false
	add_child(_gold_heap)


## The heap of gold rises in the bucket (and spills over the top when it's really full).
func _update_bucket() -> void:
	_gold_heap.visible = counts.gold > 0
	var fill := clampf(counts.gold / 8.0, 0.15, 1.6)
	_gold_heap.scale = Vector3(1.0, fill, 1.0)
	_gold_heap.position.y = BUCKET.y + 0.45 + fill * 0.25


func _add_grease_barrel() -> void:
	var barrel := MeshInstance3D.new()
	var cask := CylinderMesh.new()
	cask.top_radius = 0.32
	cask.bottom_radius = 0.32
	cask.height = 0.8
	barrel.mesh = cask
	barrel.material_override = Toon.material("wood_light")
	var n := _grease_barrels.size()
	barrel.position = GREASE + Vector3((n % 3) * 0.7, 0.4 + (n / 3) * 0.8, 0.0)
	add_child(barrel)
	_grease_barrels.append(barrel)


## A siren skewered on the mast like a shrimp (Olivier, 2026-10-25: "skewered like a SHRIMP"): big,
## curled into a C bulging toward the stern (clear of the sail), the mast through her head and her
## tail fin, her tail banded like a shrimp's shell, eyes crossed out. They stack up the mast.
func _skewer_siren() -> void:
	var n: int = counts.siren - 1
	var siren := Node3D.new()
	siren.name = "Siren%d" % counts.siren
	siren.position = SKEWER_TIP + SKEWER_STEP * (n % SKEWER_ROOM)
	siren.rotation.y = [0.0, PI / 2.0, -PI / 2.0, PI][(n / SKEWER_ROOM) % 4] # a full mast: round the other sides
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
	for spread in [-0.5, 0.5]: # the tail fin, fanned out on the mast like a shrimp's tail
		var lobe := _blob(Toon.material("tail"), fin + Vector3(0.0, -0.12, spread * 0.4), Vector3(0.1, 0.3, 0.28))
		lobe.rotation.x = spread
		siren.add_child(lobe)
	for blob in siren.get_children():
		blob.material_override = _over_sail(blob.material_override)
	add_child(siren)
	siren.scale = Vector3.ZERO
	var pop := siren.create_tween()
	pop.tween_property(siren, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(siren, "rotation:z", 0.12, 0.15) # a last wiggle on the skewer
	pop.tween_property(siren, "rotation:z", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## The sail hangs in front of the mast from the camera and washed the sirens out (Olivier,
## 2026-10-25: "still does not work"): draw them after the sail and the see-through rigging.
static func _over_sail(source: Material) -> Material:
	var key := source.get_instance_id()
	if not _over_sail_cache.has(key):
		var mat := Toon.see_through(source, 1.0).duplicate() as Material
		mat.render_priority = 5
		_over_sail_cache[key] = mat
	return _over_sail_cache[key]


## A point on a skewered siren's curl, `degrees` round it (90 = the top end, on the mast).
static func _on_curl(degrees: float) -> Vector3:
	var a := deg_to_rad(degrees)
	return Vector3(CURL * (cos(deg_to_rad(112.0)) - cos(a)), CURL * sin(a), 0.0)


func _blob(material: Material, at: Vector3, size: Vector3) -> MeshInstance3D:
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	ball.mesh = sphere
	ball.material_override = material
	ball.position = at
	ball.scale = size
	return ball
