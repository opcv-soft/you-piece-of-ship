extends "res://scripts/components/station.gd"
## A fishing spot at the rail (Olivier, 2026-10-22: "if players are idle they can fish; fishing
## adds points"). Use takes the rod and casts; wait for the float to dip ("!"), then press Jump
## quickly to strike. Too early or too late and it gets away. Each catch adds to the voyage score.

signal caught(catch: Dictionary, player: Node3D)
signal got_away(player: Node3D)

const Toon = preload("res://scripts/systems/toon.gd")
const MODELS := "res://assets/art/export/models/"
## [name, model, points, chance weight] (weights are the defaults; the Fishing dev sliders override them)
const CATCHES := [
	["Sardine", "fish_sardine", 20, 70.0],
	["Goldfish", "fish_goldfish", 50, 12.0],
	["Squid", "fish_squid", 40, 9.0],
	["Pufferfish", "fish_pufferfish", 35, 8.0],
	["Treasure!", "chest", 150, 1.0],
]

enum Phase { IDLE, WAITING, BITE, REELING }

const ItemScene = preload("res://scenes/greybox/item.tscn")

# Olivier, 2026-10-24: "Reduce the frequency of fish success, increase randomness, add dev controls".
@export_range(1.0, 30.0, 0.5) var bite_min := 6.0 ## seconds before something tugs, at least
@export_range(1.0, 60.0, 0.5) var bite_max := 18.0
## A tug is just a nibble (strike = too early). 0.25: three tugs in four are real bites (Olivier,
## 2026-10-25: "increase fishing success by 1.5x", it was one in two).
@export_range(0.0, 0.9, 0.05) var nibble_chance := 0.25
## Seconds to strike on a real bite: 3x the old 0.45-0.8 s (Olivier, 2026-10-25).
@export_range(0.2, 6.0, 0.05) var bite_window_min := 1.35
@export_range(0.2, 6.0, 0.05) var bite_window_max := 2.4
@export_range(0.0, 100.0, 1.0) var sardine_weight := 70.0
@export_range(0.0, 100.0, 1.0) var goldfish_weight := 12.0
@export_range(0.0, 100.0, 1.0) var squid_weight := 9.0
@export_range(0.0, 100.0, 1.0) var pufferfish_weight := 8.0
@export_range(0.0, 100.0, 0.5) var treasure_weight := 1.0
@export var cast_distance := 3.2 ## metres out from the rail
@export var reel_seconds := 1.3 ## reeling the catch in, over the rail and onto the deck

var phase := Phase.IDLE
var wait_left := 0.0
var bite_left := 0.0
var bite_window := 0.6 ## this bite's strike window (rolled between bite_window_min and _max)
var nibble_left := 0.0
var catches := 0

var _rng := RandomNumberGenerator.new()
var _rod: Node3D
var _bobber: Node3D
var _line: MeshInstance3D
var _time := 0.0
var _reel_left := 0.0
var _reeled: Node3D ## the catch on the end of the line while it's reeled in
var _reel_catch := {}


func _ready() -> void:
	super._ready()
	add_to_group("fishing_spots")
	station_name = "FISHING"
	prompt = "Use: fish"
	radius = 1.1
	_rng.randomize()
	_build()


func _build() -> void:
	var side := signf(position.z) if position.z != 0.0 else 1.0
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 2.3, side * 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	add_child(label)
	_rod = Node3D.new()
	_rod.name = "Rod"
	add_child(_rod)
	var pole := MeshInstance3D.new()
	var stick := CylinderMesh.new()
	stick.top_radius = 0.025
	stick.bottom_radius = 0.045
	stick.height = 2.4
	pole.mesh = stick
	pole.material_override = Toon.material("wood_light")
	pole.position = Vector3(0, 1.6, side * 0.75)
	pole.rotation.x = side * deg_to_rad(55)
	_rod.add_child(pole)
	_bobber = Node3D.new()
	_bobber.name = "Bobber"
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	ball.mesh = sphere
	ball.material_override = Toon.material("paint_red")
	_bobber.add_child(ball)
	var cap := MeshInstance3D.new()
	var top := SphereMesh.new()
	top.radius = 0.1
	top.height = 0.12
	cap.mesh = top
	cap.material_override = Toon.material("trim_cream")
	cap.position.y = 0.12
	_bobber.add_child(cap)
	_bobber.position = Vector3(0, -1.0, side * cast_distance)
	add_child(_bobber)
	_line = MeshInstance3D.new()
	_line.name = "Line"
	var thread := CylinderMesh.new()
	thread.top_radius = 0.008
	thread.bottom_radius = 0.008
	thread.height = 1.0
	_line.mesh = thread
	_line.material_override = Toon.material("trim_cream")
	add_child(_line)
	_show_tackle(false)


func _show_tackle(on: bool) -> void:
	_bobber.visible = on
	_line.visible = on


## The rod tip, in this spot's own space.
func _tip() -> Vector3:
	var side := signf(position.z) if position.z != 0.0 else 1.0
	return Vector3(0, 1.6 + cos(deg_to_rad(55)) * 1.2, side * (0.75 + sin(deg_to_rad(55)) * 1.2))


func occupy(player: Node3D) -> bool:
	if not super.occupy(player):
		return false
	_cast()
	return true


func release(player: Node3D) -> void:
	if _reeled:
		_land_catch() # let go mid-reel: the fish still lands on deck
	super.release(player)
	if occupants.is_empty():
		phase = Phase.IDLE
		_show_tackle(false)


func _cast() -> void:
	phase = Phase.WAITING
	nibble_left = 0.0
	wait_left = _rng.randf_range(bite_min, maxf(bite_min, bite_max))
	_show_tackle(true)


## Jump while fishing: strike. Right after a bite it's a catch; any other time the fish is scared.
func secondary_action(player: Node3D) -> void:
	strike(player)


func strike(player: Node3D) -> void:
	if phase == Phase.BITE:
		var catch := roll_catch()
		catches += 1
		var voyage := get_tree().get_first_node_in_group("voyage")
		if voyage and "bonus_points" in voyage:
			voyage.bonus_points += int(catch.points)
		player.think(tr("%s +%d") % [tr(catch.name), catch.points], 2.0, "shout")
		caught.emit(catch, player)
		_start_reel(catch)
		return
	elif phase == Phase.WAITING:
		player.think(tr("Too early!") if nibble_left > 0.0 else tr("Nothing yet..."), 1.2)
		got_away.emit(player)
	elif phase == Phase.REELING:
		return # busy bringing one in
	_cast()


## The catch comes up on the line: reeled toward the rod, swung over the rail, dropped on deck.
func _start_reel(catch: Dictionary) -> void:
	phase = Phase.REELING
	_reel_left = reel_seconds
	_reel_catch = catch
	var path := MODELS + String(catch.model) + ".glb"
	_reeled = (load(path) as PackedScene).instantiate()
	Toon.paint(_reeled)
	_reeled.scale = Vector3.ONE * (1.6 if catch.model != "chest" else 0.9)
	_reeled.position = _bobber.position
	add_child(_reeled)


func _reel(delta: float) -> void:
	_reel_left -= delta
	var t := 1.0 - clampf(_reel_left / reel_seconds, 0.0, 1.0)
	var side := signf(position.z) if position.z != 0.0 else 1.0
	var water := Vector3(0.0, _bobber.position.y, side * cast_distance)
	var over_rail := _tip() + Vector3(0, -0.4, 0)
	var deck := Vector3(0.3, 0.6, -side * 0.9)
	if t < 0.65:
		_reeled.position = water.lerp(over_rail, ease(t / 0.65, 0.6)) # up the line, wriggling
		_reeled.rotation.z = sin(_time * 25.0) * 0.5
	else:
		var u := (t - 0.65) / 0.35
		_reeled.position = over_rail.lerp(deck, u) + Vector3(0, sin(u * PI) * 0.8, 0) # swung onto the deck
		_reeled.rotation.z = lerpf(_reeled.rotation.z, PI / 2.0, u)
	_bobber.position = _reeled.position
	if _reel_left <= 0.0:
		_land_catch()


## The fish stays on deck, flopping about (treasure just bursts into coins).
func _land_catch() -> void:
	var where := _reeled.global_position
	_reeled.queue_free()
	_reeled = null
	var ship := get_parent()
	var items := ship.get_node_or_null("Items")
	if _reel_catch.model != "chest" and items:
		var fish: Node3D = ItemScene.instantiate()
		fish.kind = "fish"
		fish.species = _reel_catch.model
		items.add_child(fish)
		var local: Vector3 = ship.to_local(where)
		fish.position = Vector3(local.x, 0.0, local.z)
	elif is_inside_tree():
		UI.play("coin")
	_cast()


## Picks what bites, by weight.
func roll_catch() -> Dictionary:
	var weights := [sardine_weight, goldfish_weight, squid_weight, pufferfish_weight, treasure_weight]
	var total := 0.0
	for weight in weights:
		total += weight
	var pick := _rng.randf() * total
	for i in CATCHES.size():
		var entry: Array = CATCHES[i]
		pick -= weights[i]
		if pick <= 0.0 and weights[i] > 0.0:
			return {"name": entry[0], "model": entry[1], "points": entry[2]}
	return {"name": CATCHES[0][0], "model": CATCHES[0][1], "points": CATCHES[0][2]}


func _physics_process(delta: float) -> void:
	_time += delta
	match phase:
		Phase.WAITING:
			wait_left -= delta
			nibble_left -= delta
			if wait_left <= 0.0:
				if _rng.randf() < nibble_chance:
					# Just a nibble: the float twitches, then nothing. Strike now and it's scared off.
					nibble_left = 0.6
					wait_left = _rng.randf_range(bite_min * 0.3, bite_max * 0.5)
					if occupant:
						occupant.think("?", 0.6)
				else:
					phase = Phase.BITE
					bite_window = _rng.randf_range(bite_window_min, maxf(bite_window_min, bite_window_max))
					bite_left = bite_window
					if occupant:
						occupant.think("!", bite_window, "shout")
		Phase.REELING:
			_reel(delta)
			_update_line()
			return
		Phase.BITE:
			bite_left -= delta
			if bite_left <= 0.0:
				if occupant:
					occupant.think(tr("It got away..."), 1.2)
					got_away.emit(occupant)
				_cast()
	if _bobber.visible:
		_float_bobber()
		_update_line()


func _float_bobber() -> void:
	var side := signf(position.z) if position.z != 0.0 else 1.0
	var dip := -0.35 if phase == Phase.BITE and fmod(_time, 0.3) < 0.15 else 0.0
	if nibble_left > 0.0 and phase == Phase.WAITING:
		dip = -0.12 if fmod(_time, 0.2) < 0.1 else 0.0
	# The float sits on the sea surface (the ship's deck is 1.2 m above it).
	var sea_y := to_local(Vector3(0, 0.05, 0) + global_position * Vector3(1, 0, 1)).y
	_bobber.position = Vector3(0.0, sea_y + sin(_time * 2.0) * 0.06 + dip, side * cast_distance)


func _update_line() -> void:
	var tip := _tip()
	var span := _bobber.position - tip
	if span.length() < 0.05:
		return
	_line.position = tip + span * 0.5
	(_line.mesh as CylinderMesh).height = span.length()
	_line.basis = Basis(Quaternion(Vector3.UP, span.normalized()))
