extends Node3D
## Salvage from something smashed (Olivier, 2026-10-24: "When I hit a rock or whatever, it needs to
## disassemble, break into pieces. the debris should float and then get swooshed in the correct
## stock pile on the boat"). The pieces pop out, bob on the water a moment, then fly in arcs onto
## the ship, each into its own pile: charcoal to the coal pile, planks to the plank box, gold to the
## bucket, grease to the grease barrels, a siren onto the bowsprit. When the last piece lands the
## haul goes into ShipStores and the score. Spawned by breakable.gd and enemy_ship.gd.

const Toon = preload("res://scripts/systems/toon.gd")
const ShipStores = preload("res://scripts/components/ship_stores.gd")
const FLOAT_SECONDS := 1.2 ## bobbing on the water before the swoosh
const FLIGHT_SECONDS := 0.75
const STAGGER := 0.09 ## each piece leaves a little after the one before
## Where each resource lands, in the ship's frame (x = bow, z = starboard).
const TARGETS := {
	"coal": Vector3(-8.1, 0.8, 2.6), # the coal pile by the furnace
	"planks": Vector3(10.0, 1.4, -0.4), # the plank box on the foredeck
	"gold": ShipStores.BUCKET + Vector3(0, 1.0, 0),
	"grease": ShipStores.GREASE + Vector3(0, 1.0, 0),
	"siren": ShipStores.SKEWER_TIP,
}
## How many pieces each resource breaks into.
const PIECES := {"coal": 6, "planks": 5, "gold": 8, "grease": 3, "siren": 1}

var resource := "gold"
var units := 1 ## what it adds to the stores when it all lands
var pieces := -1 ## how many bits fly; -1 = the usual for its resource (PIECES)

var _chunks: Array[Dictionary] = []
var _time := 0.0
var _delivered := false


func _ready() -> void:
	add_to_group("salvage")
	for i in (pieces if pieces > 0 else PIECES.get(resource, 4)):
		var piece := _piece()
		add_child(piece)
		piece.position = Vector3(randf_range(-1.0, 1.0), 1.0, randf_range(-1.0, 1.0))
		piece.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		var out := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		_chunks.append({"node": piece, "velocity": out * randf_range(3.0, 6.0) + Vector3(0, randf_range(5.0, 8.0), 0),
				"spin": Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6)), "from": Vector3.ZERO,
				"leaves": FLOAT_SECONDS + i * STAGGER, "landed": false})


func _physics_process(delta: float) -> void:
	_time += delta
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	var landed := 0
	for chunk in _chunks:
		var node: Node3D = chunk.node
		if chunk.landed:
			landed += 1
			continue
		if _time < chunk.leaves or ship == null:
			_bob(chunk, delta)
			chunk.from = node.global_position
			continue
		var t := clampf((_time - chunk.leaves) / FLIGHT_SECONDS, 0.0, 1.0)
		var target := ship.to_global(TARGETS.get(resource, Vector3.ZERO)) # follows the moving ship
		var from: Vector3 = chunk.from
		var lift := 3.0 + from.distance_to(target) * 0.25
		var u := ease(t, 1.8) # slow lift-off, then the swoosh
		node.global_position = from.lerp(target, u) + Vector3(0, sin(u * PI) * lift, 0)
		node.rotation += chunk.spin * delta * 2.0
		node.scale = Vector3.ONE * lerpf(1.0, 0.6, u)
		if t >= 1.0:
			chunk.landed = true
			node.visible = false
			UI.play("coin")
	if landed == _chunks.size():
		land_all()


## Popped out of the wreckage, then bobbing where it fell.
func _bob(chunk: Dictionary, delta: float) -> void:
	var node: Node3D = chunk.node
	var velocity: Vector3 = chunk.velocity
	if node.position.y > 0.25 or velocity.y > 0.0:
		velocity.y -= 16.0 * delta
		node.position += velocity * delta
		node.rotation += chunk.spin * delta
	else:
		velocity = Vector3.ZERO
		node.position.y = 0.2 + sin(_time * 4.0 + node.position.x) * 0.12
		node.rotation.y += delta
	chunk.velocity = velocity


## Everything lands in the stores now (also used by tests, rather than waiting for the swoosh).
func land_all() -> void:
	if _delivered:
		return
	_delivered = true
	var ship := get_tree().get_first_node_in_group("player_ship")
	if ship and ship.has_node("ShipStores"):
		var points: int = ship.get_node("ShipStores").add(resource, units)
		var voyage := get_tree().get_first_node_in_group("voyage")
		if voyage and "bonus_points" in voyage:
			voyage.bonus_points += points
	queue_free()


## One piece of debris: a charcoal lump, a plank, a gold coin, a grease keg or the siren herself.
func _piece() -> Node3D:
	var piece := MeshInstance3D.new()
	match resource:
		"coal":
			var lump := SphereMesh.new()
			lump.radius = 0.45
			lump.height = 0.7
			piece.mesh = lump
			piece.material_override = Toon.material("coal")
		"planks":
			var plank := BoxMesh.new()
			plank.size = Vector3(1.8, 0.16, 0.4)
			piece.mesh = plank
			piece.material_override = Toon.material("wood_light")
		"gold":
			var coin := CylinderMesh.new()
			coin.top_radius = 0.35
			coin.bottom_radius = 0.35
			coin.height = 0.08
			piece.mesh = coin
			piece.material_override = Toon.material("gold")
		"grease":
			var keg := CylinderMesh.new()
			keg.top_radius = 0.32
			keg.bottom_radius = 0.32
			keg.height = 0.7
			piece.mesh = keg
			piece.material_override = Toon.material("wood_light")
		_:
			var body := SphereMesh.new()
			body.radius = 0.5
			body.height = 1.4
			piece.mesh = body
			piece.material_override = Toon.material("skin")
			var tail := MeshInstance3D.new()
			var fin := SphereMesh.new()
			fin.radius = 0.35
			fin.height = 0.9
			tail.mesh = fin
			tail.material_override = Toon.material("tail")
			tail.position = Vector3(0, -0.8, 0)
			piece.add_child(tail)
	return piece
