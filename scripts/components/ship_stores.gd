extends Node3D
## What the crew hauls home (Olivier, 2026-10-24): gold from barrels and treasure piles up in a
## bucket at the bow; charcoal from black rocks goes into the furnace; planks from wrecks and sunk
## pirates go into the plank box; whale grease in barrels; and every siren ends up skewered on the
## bowsprit. A child of the ship. At the beach the haul flies to the village (voyage_arrival.gd).

signal stored(resource: String, amount: int)

const Toon = preload("res://scripts/systems/toon.gd")
const KINDS := ["gold", "coal", "planks", "grease", "siren"]
## Score points each unit is worth (the haul still counts in the score).
const POINTS := {"gold": 40, "coal": 15, "planks": 20, "grease": 60, "siren": 150}
const BUCKET := Vector3(8.4, 0.0, -0.9) ## the gold bucket, on the foredeck
const GREASE := Vector3(-8.0, 0.0, -2.6) ## grease barrels, in the stern corner
const SKEWER_TIP := Vector3(17.6, 2.75, 0.0) ## the bowsprit's end
const SKEWER_STEP := Vector3(-1.0, -0.18, 0.0) ## each new siren goes a little further up the pole

var counts := {"gold": 0, "coal": 0, "planks": 0, "grease": 0, "siren": 0}
var _gold_heap: MeshInstance3D
var _grease_barrels: Array[Node3D] = []


func _ready() -> void:
	name = "ShipStores"
	_build_bucket()


## Adds to the haul and shows it aboard. Returns the score points it's worth.
func add(resource: String, amount := 1) -> int:
	if not counts.has(resource) or amount <= 0:
		return 0
	counts[resource] += amount
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


## A little siren, skewered on the bowsprit like a trophy.
func _skewer_siren() -> void:
	var siren := Node3D.new()
	siren.name = "Siren%d" % counts.siren
	siren.position = SKEWER_TIP + SKEWER_STEP * (counts.siren - 1)
	siren.rotation.z = -0.4
	var parts := [["skin", Vector3(0, 0.0, 0), Vector3(0.28, 0.4, 0.24)], ["skin", Vector3(0, 0.55, 0), Vector3(0.3, 0.3, 0.3)],
			["hair", Vector3(-0.08, 0.62, 0), Vector3(0.34, 0.34, 0.34)], ["tail", Vector3(0, -0.5, 0), Vector3(0.22, 0.45, 0.2)],
			["tail", Vector3(0.1, -0.95, 0), Vector3(0.35, 0.12, 0.3)]]
	for part in parts:
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		ball.mesh = sphere
		ball.material_override = Toon.material(part[0])
		ball.position = part[1]
		ball.scale = part[2]
		siren.add_child(ball)
	add_child(siren)
	siren.scale = Vector3.ZERO
	siren.create_tween().tween_property(siren, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
