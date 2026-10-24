extends Node
## An AI crewmate (a child of a crew member). It drives the same stick and buttons a human would,
## so it follows the same rules: walk there, press Use, hold up to shovel, Jump to vent.
## Its job comes from the CrewBrain: primary job, secondary job, or wherever help is needed.

const AISteering = preload("res://scripts/ai/jobs/ai_steering.gd")
const AINavigator = preload("res://scripts/ai/jobs/ai_navigator.gd")
const AICarpenter = preload("res://scripts/ai/jobs/ai_carpenter.gd")
const AIIdle = preload("res://scripts/ai/jobs/ai_idle.gd")
const AIGunner = preload("res://scripts/ai/jobs/ai_gunner.gd")
const STATION_FOR := AISteering.STATION_FOR

@export var primary := "engine"
@export var secondary := "pump"
@export var arrive_distance := 0.6
@export var callout_interval := 2.5

var job := "" ## what it is doing right now (for tests and the label)
var target: Node3D = null ## the thing it is working on (carpenter, cargo)

var _player: CharacterBody3D
var _ship: Node3D
var _brain: Node
var _intent := "" ## what it's doing right now, in words (shown in the crew panel)
var _intent_quiet := 0.0
var _use_cooldown := 0.0
var _callout_left := 0.0
var _reverse_left := 0.0
var _progress_check := 0.6
var _last_position := Vector3.ZERO
var _sidestep_left := 0.0
var _sidestep := Vector2.ZERO
var _rng := RandomNumberGenerator.new()

var _steering := AISteering.new(self) ## helm, pump, engine
var _navigator := AINavigator.new(self)
var _carpenter := AICarpenter.new(self)
var _idle := AIIdle.new(self) ## idle work, fishing, cargo
var _gunner := AIGunner.new(self)


func _ready() -> void:
	add_to_group("ai_crew")
	_player = get_parent()
	_player.get_node("PlayerInput").enabled = false
	_ship = _player.get_parent().get_parent() as Node3D
	# This voyage's own brain (never another voyage's that is being cleared away).
	var voyage := _ship.get_parent()
	_brain = voyage.get_node_or_null("CrewBrain") if voyage else null
	if _brain == null:
		_brain = get_tree().get_first_node_in_group("crew_brain")
	_ship.get_node("ShipHandling").impact.connect(func(_rock): _reverse_left = 2.0)
	_rng.seed = _player.player_index * 31
	_player.get_node("Label").text = tr("P%d AI") % _player.player_index


## A callout everyone should hear (the navigator's rocks): a yellow shout bubble.
func say(text: String, seconds := 2.2) -> void:
	_player.think(text, seconds, "shout")
	_intent_quiet = seconds


## What I'm doing now. Routine plans only go to the crew panel; urgent ones ("Too hot! Venting!",
## "Fire!") also pop a bubble, so the screen isn't full of chatter (Claude's playtest, 2026-10-24).
func intend(text: String, urgent := false) -> void:
	if text == _intent:
		return
	_intent = text
	if urgent and _intent_quiet <= 0.0:
		_player.think(text, 2.0, "think")


func activity() -> String:
	return _intent


func _physics_process(delta: float) -> void:
	_use_cooldown -= delta
	_reverse_left -= delta
	_intent_quiet -= delta
	_player.move_input = Vector2.ZERO
	if _player.knocked > 0.0:
		return
	job = _brain.job_of(_player) if _brain else primary
	if _player.station and _player.station.is_in_group("fishing_spots"):
		if _idle.fishing_ok() and job != "navigator" and job != "engine" and job != "helm" and job != "pump":
			_idle.fish()
			return
		_press_use() # something needs doing: reel in
		return
	if _player.station and _station_job(_player.station) != job:
		_press_use() # not my job any more: let go
		return
	match job:
		"engine":
			_steering.engineer(delta)
		"helm", "pump":
			_steering.run_station(job, delta)
		"navigator":
			_navigator.navigate(delta)
		"carpenter":
			_carpenter.carpentry(delta)
		"cargo":
			_idle.cargo(delta)
		"gunner":
			_gunner.gunner(delta)


func _station_job(station: Node3D) -> String:
	if station.is_in_group("cannons"):
		return "gunner"
	match String(station.name):
		"Helm":
			return "helm"
		"Engine":
			return "engine"
		"Pump":
			return "pump"
		"Lookout", "Telescope":
			return "navigator"
	return "carpenter" # leaks and the cooling pipe


# --- Moving and pressing ------------------------------------------------------------

## Walks toward a point on the deck. Returns true once there.
func _walk_to(point: Vector3, delta: float, arrive := arrive_distance) -> bool:
	var to := point - _player.global_position
	to.y = 0.0
	if to.length() <= arrive:
		_progress_check = 0.6
		return true
	var direction := Vector2(to.x, to.z).normalized()
	var around := _around_mast(point)
	if around != Vector3.INF:
		var detour := around - _player.global_position
		direction = Vector2(detour.x, detour.z).normalized()
	if _sidestep_left > 0.0:
		_sidestep_left -= delta
		direction = (direction * 0.4 + _sidestep).normalized()
	_player.move_input = direction
	# Stuck behind the mast or a crate? Step sideways for a moment.
	_progress_check -= delta
	if _progress_check <= 0.0:
		_progress_check = 0.6
		if _player.global_position.distance_to(_last_position) < 0.25 and _sidestep_left <= 0.0:
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			_sidestep = Vector2(-direction.y, direction.x) * side
			_sidestep_left = 0.7
		_last_position = _player.global_position
	return false


## Walking across the mast's line (e.g. to the boxes on the forecastle)? Go round it: a waypoint
## beside the mast, on whichever side is shorter. INF if the way is clear.
func _around_mast(point: Vector3) -> Vector3:
	if _ship == null:
		return Vector3.INF
	const MAST := Vector2(1.0, 0.0) # ship frame, x = bow, y = starboard
	var from3 := _ship.to_local(_player.global_position)
	var to3 := _ship.to_local(point)
	var from := Vector2(from3.x, from3.z)
	var to := Vector2(to3.x, to3.z)
	if signf(from.x - MAST.x) == signf(to.x - MAST.x) or absf(from.x - MAST.x) < 0.3:
		return Vector3.INF
	var closest := Geometry2D.get_closest_point_to_segment(MAST, from, to)
	if closest.distance_to(MAST) > 0.9:
		return Vector3.INF
	var side := signf(from.y + to.y) if absf(from.y + to.y) > 0.05 else 1.0
	return _ship.to_global(Vector3(MAST.x, 0.0, MAST.y + side * 1.3))


func _press_use() -> void:
	if _use_cooldown <= 0.0:
		_player.use_requested = true
		_use_cooldown = 0.5


## Uses a specific thing (a station, a box, an item, the pile...), never just "whatever is nearest".
func _use_on(thing: Node) -> void:
	if _use_cooldown <= 0.0:
		_player.interact_with(thing)
		_use_cooldown = 0.5


func _drop_carried() -> void:
	if _player.carried:
		_player.carried.drop()


## Whether this crewmate is busy right now: moving, working a station, carrying something, or
## reading the chart (tests check that nobody stands around).
func is_working() -> bool:
	if _player.station or _player.carried or _player.knocked > 0.0:
		return true
	if Vector2(_player.velocity.x, _player.velocity.z).length() > 0.4:
		return true
	return job == "navigator" and _ship.get_node("Lookout").occupant == _player


## The most urgent carpenter task nobody else is already on (two may hammer the same plank).
func _pick_task() -> Array:
	var tasks: Array = _brain.carpenter_tasks()
	# Already holding the right part? Finish that repair first (no dropping it halfway).
	var carried: Node3D = _player.carried
	if carried:
		for task in tasks:
			if (carried.kind == "pin" and task[0] == "rudder") or (carried.kind == "plank" and task[0] == "patch"):
				return task
	for task in tasks:
		var others := 0
		for ai in get_tree().get_nodes_in_group("ai_crew"):
			if ai != self and ai.target == task[1] and ai.job == "carpenter":
				others += 1
		var limit := 2 if task[0] in ["hammer", "pipe"] else 1
		if others < limit:
			return task
	return tasks[0] if not tasks.is_empty() else []


# --- Forwarders (tests and other scripts call these on the AI) ------------------------------

## What the navigator shouts: the nearest dangerous rock as a clock bearing, or the port.
func callout() -> String:
	return _navigator.callout()


static func steer_for(here: Vector3, yaw: float, rocks: Array, half_width: float) -> float:
	return AISteering.steer_for(here, yaw, rocks, half_width)


static func nautical_bearing(along: float, across: float) -> String:
	return AINavigator.nautical_bearing(along, across)


static func nautical_distance(metres: float) -> String:
	return AINavigator.nautical_distance(metres)


static func clock_hour(along: float, across: float) -> int:
	return AINavigator.clock_hour(along, across)
