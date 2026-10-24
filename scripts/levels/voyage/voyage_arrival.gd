extends RefCounted
## Arriving in port (Olivier, 2026-10-24): no finish line. The beach of the pirate village rises
## out of the sea; the ship glides in, slows, rides up the sand bow-first and settles with a little
## lurch, then the results show. Also lays out the village. Owned by voyage.gd.

const VILLAGE_OFFSET := 12.0 ## metres past finish_x where the sand meets the sea (the bow is 14.6 m ahead of the ship)
const SAND_START := 15.0 ## in the village model, the sand breaks the surface this far in
const HATS := ["tricorn", "bandana", "captain", "beanie", "straw"]

var beaching_seconds := 3.0 ## how long the ship takes to slide up the sand and settle

var voyage: Node3D
var beaching := false
var delivering := false ## the haul is flying to the village
var _deliver_left := 0.0
var _piles := {} ## resource -> the village stockpile node
## Where each stockpile stands, from the waterline (x up the beach, z along it).
const PILE_SPOTS := {"gold": Vector3(16, 1.7, -9), "coal": Vector3(16, 1.7, -3), "planks": Vector3(16, 1.7, 3),
		"grease": Vector3(17, 1.7, 9), "siren": Vector3(18, 1.7, -15)}
var _left := 0.0
var _start_speed := 0.0


func _init(owner_voyage: Node3D) -> void:
	voyage = owner_voyage


## The pirate village and its people on the beach (painted look), plus chart markers.
func build_village() -> void:
	var finish_x: float = voyage.finish_x
	var village: Node3D = voyage._ship.prop("village", "Village")
	village.position = Vector3(finish_x + VILLAGE_OFFSET - SAND_START, 0.0, 0.0)
	voyage.add_child(village)
	for side in [-1.0, 1.0]: # where the chart draws the port
		var mark := Marker3D.new()
		mark.position = Vector3(finish_x + VILLAGE_OFFSET, 0.0, side * 12.0)
		mark.add_to_group("finish")
		voyage.add_child(mark)
	_build_piles(finish_x)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 7:
		var villager: Node3D = voyage._ship.prop("crew", "Villager%d" % i)
		var tint := Color.from_hsv(rng.randf(), 0.55, 0.85)
		load("res://scripts/systems/toon.gd").paint(villager, {"player": tint})
		for hat in HATS:
			var node := villager.find_child("Hat_" + hat, true, false)
			if node:
				node.visible = hat == HATS[i % HATS.size()]
		var crown := villager.find_child("Hat_crown", true, false)
		if crown:
			crown.visible = false
		villager.position = Vector3(finish_x + VILLAGE_OFFSET + rng.randf_range(8.0, 18.0), 1.6, rng.randf_range(-24.0, 24.0))
		villager.rotation.y = -PI / 2.0 + rng.randf_range(-0.5, 0.5) # facing the sea
		voyage.add_child(villager)
		var bob := villager.create_tween().set_loops()
		bob.tween_property(villager, "position:y", 1.85, 0.4 + rng.randf() * 0.3) # hopping and cheering
		bob.tween_property(villager, "position:y", 1.6, 0.4 + rng.randf() * 0.3)


## The bow has reached the beach: start sliding up the sand.
func start() -> void:
	if beaching:
		return
	beaching = true
	_left = beaching_seconds
	var handling: Node = voyage._handling
	_start_speed = maxf(absf(handling.speed), 2.0)
	handling.throttle = 0.0
	handling.sail_speed = 0.0 # sails furled: she stays on the sand
	voyage.get_node("Ship/WaveMotion").intensity = 0.3


## Each frame while beaching. Returns true once the ship has settled.
func step(delta: float) -> bool:
	_left -= delta
	var t := 1.0 - clampf(_left / beaching_seconds, 0.0, 1.0)
	var handling: Node = voyage._handling
	handling.throttle = 0.0
	handling.speed = _start_speed * pow(1.0 - t, 2.0) # glides to a stop
	var waves: Node = voyage.get_node("Ship/WaveMotion")
	waves.intensity = lerpf(0.3, 0.0, t)
	waves.list_pitch = deg_to_rad(5.0) * ease(t, 0.6) # bow rides up the sand
	waves.sink = -0.55 * ease(t, 0.6) # and the hull lifts out of the water
	if _left <= 0.0 and not delivering:
		voyage._ship.lurch(Vector2(2.0, 0.0), false) # a last little jolt as she settles
		_start_delivery()
	if delivering:
		_deliver_left -= delta
		return _deliver_left <= 0.0
	return false


# --- The haul goes to the village ---------------------------------------------------------------

## Village stockpiles, sized by everything hauled home so far (Session.village).
func _build_piles(finish_x: float) -> void:
	var toon = load("res://scripts/systems/toon.gd")
	var looks := {"gold": "gold", "coal": "coal", "planks": "wood_light", "grease": "wood_hull", "siren": "hair"}
	for resource in PILE_SPOTS:
		var pile := MeshInstance3D.new()
		pile.name = "Pile_" + resource
		var mesh: Mesh
		if resource == "planks":
			var stack := BoxMesh.new()
			stack.size = Vector3(3.0, 1.0, 1.4)
			mesh = stack
		elif resource == "grease":
			var drum := CylinderMesh.new()
			drum.top_radius = 0.7
			drum.bottom_radius = 0.7
			drum.height = 1.2
			mesh = drum
		elif resource == "siren":
			var pole := CylinderMesh.new()
			pole.top_radius = 0.12
			pole.bottom_radius = 0.15
			pole.height = 4.0
			mesh = pole
		else:
			var heap := SphereMesh.new()
			heap.radius = 1.4
			heap.height = 1.6
			mesh = heap
		pile.mesh = mesh
		pile.material_override = toon.material(looks[resource])
		pile.position = Vector3(finish_x + VILLAGE_OFFSET, 0.0, 0.0) + PILE_SPOTS[resource]
		voyage.add_child(pile)
		_piles[resource] = pile
		_size_pile(resource)


func _size_pile(resource: String) -> void:
	var pile: MeshInstance3D = _piles.get(resource)
	if pile == null:
		return
	var total: int = Session.village.get(resource, 0)
	pile.visible = total > 0 or resource == "siren"
	var grow := clampf(0.5 + total / 12.0, 0.5, 2.5)
	pile.scale = Vector3(grow, grow, grow) if resource != "siren" else Vector3.ONE


## Each unit of the haul flies in an arc from the ship to its stockpile.
func _start_delivery() -> void:
	delivering = true
	_deliver_left = 0.6
	var stores: Node = voyage._ship.get_node_or_null("ShipStores")
	if stores == null:
		return
	var delay := 0.0
	for resource in stores.counts:
		var amount: int = stores.counts[resource]
		for i in mini(amount, 8): # a handful each, however big the haul
			_fly(resource, delay)
			delay += 0.12
		Session.village[resource] = Session.village.get(resource, 0) + amount
	_deliver_left = delay + 1.2
	Session.save_game()


func _fly(resource: String, delay: float) -> void:
	var toon = load("res://scripts/systems/toon.gd")
	var token := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.3
	ball.height = 0.6
	token.mesh = ball
	token.material_override = toon.material({"gold": "gold", "coal": "coal", "planks": "wood_light", "grease": "wood_hull",
			"siren": "hair"}[resource])
	voyage.add_child(token)
	var from: Vector3 = voyage._ship.global_position + Vector3(0, 2.0, 0)
	var to: Vector3 = _piles[resource].global_position + Vector3(0, 1.5, 0)
	token.global_position = from
	token.visible = false
	var flight := token.create_tween()
	flight.tween_interval(delay)
	flight.tween_callback(func(): token.visible = true)
	flight.tween_method(func(t: float): token.global_position = from.lerp(to, t) + Vector3(0, sin(t * PI) * 8.0, 0), 0.0, 1.0, 0.9)
	flight.tween_callback(func():
		UI.play("coin")
		_size_pile(resource)
		token.queue_free())
