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
	if _left <= 0.0:
		voyage._ship.lurch(Vector2(2.0, 0.0), false) # a last little jolt as she settles
		return true
	return false
