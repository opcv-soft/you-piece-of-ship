extends Node3D
## What the crew hauls home (Olivier, 2026-10-24): gold from barrels and treasure piles up in a
## bucket at the bow; charcoal from black rocks goes into the furnace; planks from wrecks and sunk
## pirates go into the plank box; and sirens and whales end up on the bowsprit kebab (2026-10-25:
## sirens like shrimp, whales as blocks of blubber; bowsprit_skewer.gd). A child of the ship. At the
## beach the haul flies to the village (voyage_arrival.gd).

signal stored(resource: String, amount: int)

const Toon = preload("res://scripts/systems/toon.gd")
const KINDS := ["gold", "coal", "planks", "grease", "siren"]
## Score points each unit is worth (the haul still counts in the score).
const POINTS := {"gold": 40, "coal": 15, "planks": 20, "grease": 60, "siren": 150}
const BUCKET := Vector3(8.4, 0.0, -0.9) ## the gold bucket, on the foredeck
const BowspritSkewer = preload("res://scripts/components/bowsprit_skewer.gd")
const GREASE_PER_BLUBBER := 5 ## a whale's worth of grease is one block of blubber on the skewer

var counts := {"gold": 0, "coal": 0, "planks": 0, "grease": 0, "siren": 0}
var skewer: Node3D ## the bowsprit kebab
var _gold_heap: MeshInstance3D


func _ready() -> void:
	name = "ShipStores"
	_build_bucket()
	skewer = BowspritSkewer.new()
	add_child(skewer)


## Adds to the haul and shows it aboard. Returns the score points it's worth.
func add(resource: String, amount := 1) -> int:
	if not counts.has(resource) or amount <= 0:
		return 0
	var blubber_before: int = counts.grease / GREASE_PER_BLUBBER
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
			for i in counts.grease / GREASE_PER_BLUBBER - blubber_before:
				skewer.add_blubber()
		"siren":
			for i in amount:
				skewer.add_siren()
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
