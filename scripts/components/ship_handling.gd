extends Node
## Arcade sailing: the throttle sets speed, the wheel turns the bow. Moves its parent ship
## along the sea (yaw and travel only; WaveMotion owns roll, pitch and heave).
## Only the crew member at the helm can drive it: the captain's job (Social, Thrill of danger).

signal impact(rock: Node3D) ## emitted first, so the voyage log tells cause before effect
signal rock_hit(rock: Node3D)

@export var helm: Node3D ## the station the captain uses
@export var max_speed := 6.0 ## metres per second at full throttle
@export var acceleration := 1.2 ## metres per second gained each second
@export var turn_rate_degrees := 14.0 ## degrees per second at full wheel and full speed
@export var min_turn_factor := 0.35 ## a slow ship still turns a little, so you can steer off a rock
@export var throttle_rate := 0.5 ## throttle change per second while holding up or down
@export_range(0.0, 1.0) var max_reverse := 0.3 ## pull the throttle below zero to back off a rock
@export var sail_speed := 0.0 ## the sail always pushes this fast (m/s), engine or not; set when the voyage starts
@export var hull_half_length := 9.0
@export var hull_half_width := 3.5
@export var hull_centre_x := 0.0 ## the hull's middle along the ship (the painted bow reaches further forward)
@export var impact_pushback := 2.5 ## metres the ship bounces back off a rock
@export var impact_cooldown := 1.5 ## seconds before the next rock can hit
@export var impact_sidestep := 1.5 ## metres the ship is shoved sideways, away from the rock
@export var deflect_degrees := 10.0 ## the bow glances away from the rock, so a straight course doesn't stick

var speed_limits := {} ## system name -> top speed factor (water, heat...), multiplied together
var turn_limits := {} ## system name -> turning factor
var rudder_offset := 0.0 ## a broken rudder pulls the wheel this way (-1..1)
var impact_speed := 0.0 ## speed just before the last rock hit
var throttle := 0.0 ## -max_reverse..1 (negative = astern)
var rudder := 0.0 ## -1 = full starboard (right), +1 = full port (left)
var lures := {} ## sirens pulling the wheel: id -> pull (-1..1), added to the rudder
var drifts := {} ## sirens dragging the ship: id -> world velocity (m/s), added to its motion
var speed := 0.0

var _ship: Node3D
var _cooldown := 0.0


func _ready() -> void:
	_ship = get_parent() as Node3D


func _physics_process(delta: float) -> void:
	_read_helm(delta)
	step(delta)
	_update_helm_label()


func _read_helm(delta: float) -> void:
	var captain: Node3D = helm.occupant if helm else null
	if captain == null:
		rudder = 0.0 # nobody at the wheel: it springs back, but the engine keeps going
		return
	rudder = -captain.move_input.x
	throttle = clampf(throttle - captain.move_input.y * throttle_rate * delta, -max_reverse, 1.0)


func _update_helm_label() -> void:
	if helm and not _ship.has_node("RudderSystem"):
		helm.status_text = throttle_text()


## Direction the bow points, flat on the sea.
func forward() -> Vector3:
	var yaw := _ship.rotation.y
	return Vector3(cos(yaw), 0.0, -sin(yaw))


## Speed in knots (1 m/s = 1.944 knots).
func knots() -> float:
	return absf(speed) * 1.944


## The helm's readout: speed in knots and the throttle (Olivier, 2026-10-24).
func throttle_text() -> String:
	var knots_text := tr("%.1f knots") % knots()
	if throttle < -0.01:
		return knots_text + "\n" + tr("ASTERN %d%%") % roundi(-throttle * 100.0)
	return knots_text + "\n" + tr("throttle %d%%") % roundi(throttle * 100.0)


## Top speed right now, after damage (water, heat...).
func top_speed() -> float:
	var factor := 1.0
	for limit in speed_limits.values():
		factor *= limit
	return max_speed * factor


func turn_factor() -> float:
	var factor := 1.0
	for limit in turn_limits.values():
		factor *= limit
	return factor


func step(delta: float) -> void:
	var wanted := throttle * top_speed()
	if throttle >= 0.0:
		wanted = maxf(wanted, sail_speed) # the sail: never dead in the water
	speed = move_toward(speed, wanted, acceleration * delta)
	if absf(speed) > 0.05:
		# Turning needs water flowing past the rudder; going astern turns the other way.
		var turn_factor_now := signf(speed) * maxf(absf(speed) / max_speed, min_turn_factor) * turn_factor()
		var pull := 0.0
		for amount in lures.values():
			pull += amount
		var wheel := clampf(rudder + rudder_offset + pull, -1.0, 1.0)
		_ship.rotation.y += deg_to_rad(turn_rate_degrees) * wheel * turn_factor_now * delta
	_ship.position += forward() * speed * delta
	for drift in drifts.values():
		_ship.position += drift * delta
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown == 0.0:
		_check_rocks()


func _check_rocks() -> void:
	var fwd := forward()
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	for rock in get_tree().get_nodes_in_group("rocks"):
		if rock.has_method("is_solid") and not rock.is_solid():
			continue # a diving whale passes under the keel
		var offset: Vector3 = rock.global_position - _ship.global_position
		if offset.length() > rock.radius + 16.0:
			continue
		if touches_hull(Vector2(offset.dot(fwd), offset.dot(right)), rock.radius):
			if rock.has_method("is_soft") and rock.is_soft():
				rock.take_hit(rock.global_position, 99) # a floating barrel just bursts
				continue
			_hit(rock)
			return


## The hull's outline at the waterline, in the ship's flat frame (x = toward the bow, y = starboard):
## the same shape as the painted model (tools/blender/build_ship.py), pointed bow and all.
static func hull_outline() -> PackedVector2Array:
	if not _outline.is_empty():
		return _outline
	var side: Array[Vector2] = []
	var x := -10.9
	while x <= 14.6:
		var half := 3.7
		if x > 8.2:
			half = maxf(0.06, 3.7 * pow(cos((x - 8.2) / (14.6 - 8.2) * PI / 2.0), 0.9))
		elif x < -9.4:
			var t := (x + 9.4) / (-10.9 + 9.4)
			half = 3.7 - 0.5 * t * t
		side.append(Vector2(x, half))
		x += 0.5
	for point in side:
		_outline.append(point)
	for i in range(side.size() - 1, -1, -1):
		_outline.append(Vector2(side[i].x, -side[i].y))
	return _outline


static var _outline := PackedVector2Array()


## Whether a circle (centre in the ship's flat frame) touches or overlaps the hull outline.
static func touches_hull(centre: Vector2, radius: float) -> bool:
	var outline := hull_outline()
	if Geometry2D.is_point_in_polygon(centre, outline):
		return true
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		if Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre) < radius:
			return true
	return false


## How hard the last hit was: 0 (a nudge) to 1 (full speed).
func impact_strength() -> float:
	return clampf(absf(impact_speed) / max_speed, 0.0, 1.0)


func _hit(rock: Node3D) -> void:
	impact_speed = speed
	speed = 0.0
	# Glance off: back away, step sideways away from the rock and turn the bow away from it.
	var fwd := forward()
	var right := Vector3(-fwd.z, 0.0, fwd.x) # starboard
	var across := (rock.global_position - _ship.global_position).dot(right)
	var away := -1.0 if across >= 0.0 else 1.0 # +1 = toward starboard
	var backwards := -1.0 if impact_speed >= 0.0 else 1.0 # bounce opposite to the way we were going
	# Gentle at low speed, violent at full speed (Olivier, 2026-10-24).
	var force := 0.3 + 0.7 * impact_strength()
	_ship.position += fwd * backwards * impact_pushback * force + right * away * impact_sidestep * force
	_ship.rotation.y -= deg_to_rad(deflect_degrees) * away * force # positive yaw turns the bow to port
	_cooldown = impact_cooldown
	rock.reveal()
	impact.emit(rock)
	rock_hit.emit(rock)
	# A hard ram (40% of top speed or more) damages breakable things; any bump knocks a bit of salvage off.
	if rock.has_method("take_hit"):
		rock.take_hit(rock.global_position, 1 + int(impact_strength() * 1.5) if impact_strength() >= 0.4 else 0)
