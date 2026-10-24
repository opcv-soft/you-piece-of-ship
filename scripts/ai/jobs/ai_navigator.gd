extends RefCounted
## The AI navigator: climbs to the crow's nest and watches with the spyglass (or the telescope in fog) and shouts the nearest danger
## the way sailors say it. Owned by ai_crew.gd; the static helpers are tested on their own.

const AISteering = preload("res://scripts/ai/jobs/ai_steering.gd")

var ai: Node


func _init(owner_ai: Node) -> void:
	ai = owner_ai


func navigate(delta: float) -> void:
	var player: CharacterBody3D = ai._player
	ai._drop_carried()
	ai.intend(ai.tr("Up the mast!"))
	# In fog the chart sees little: the navigator takes the telescope instead.
	var telescope: Node3D = ai._ship.get_node("Telescope")
	if telescope.enabled:
		if player.station != telescope:
			if ai._walk_to(telescope.global_position, delta, 0.9):
				ai._use_on(telescope)
			return
	else:
		var nest: Node3D = ai._ship.get_node("Lookout")
		if player.station != nest:
			if ai._walk_to(nest.global_position, delta, 0.9):
				ai._use_on(nest)
			return
		if not nest.is_up():
			return # still climbing
	ai._callout_left -= delta
	if ai._callout_left <= 0.0:
		ai._callout_left = ai.callout_interval
		var line := callout()
		if line != "":
			ai.say(line)


## What the navigator shouts: the nearest dangerous rock as a clock bearing, or the port.
func callout() -> String:
	var ship: Node3D = ai._ship
	var yaw := ship.rotation.y
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var best: Node3D = null
	var best_distance := INF
	for rock in ai.get_tree().get_nodes_in_group("rocks"):
		if AISteering.is_cliff(rock):
			continue
		var offset: Vector3 = rock.global_position - ship.global_position
		offset.y = 0.0
		var along := offset.dot(fwd)
		var sight: float = ai._steering.chart_range()
		var telescope: Node3D = ship.get_node("Telescope")
		if telescope.enabled and ai._player.station == telescope:
			sight = telescope.spot_range
		if along <= 0.0 or offset.length() > sight or absf(offset.dot(right)) > rock.radius + 14.0:
			continue
		if offset.length() < best_distance:
			best = rock
			best_distance = offset.length()
	if best:
		var offset: Vector3 = best.global_position - ship.global_position
		var bearing := nautical_bearing(offset.dot(fwd), offset.dot(right))
		var what: String = best.call_name() if best.has_method("call_name") else "Rock"
		if what == "Siren":
			return ai.tr("Siren, %s! Don't listen!") % ai.tr(bearing)
		return ai.tr("%s, %s, %s!") % [ai.tr(what), nautical_distance(best_distance), ai.tr(bearing)]
	var voyage: Node = ship.get_parent()
	if "finish_x" in voyage and voyage.finish_x - ship.global_position.x < 150.0:
		return ai.tr("Land ho! %s dead ahead!") % nautical_distance(voyage.finish_x - ship.global_position.x)
	return ai.tr("Clear ahead!") if ai._rng.randf() < 0.3 else ""


## Where something is, the way sailors say it: dead ahead, off the starboard bow, on the port beam,
## off the starboard quarter, dead astern.
static func nautical_bearing(along: float, across: float) -> String:
	var degrees := rad_to_deg(atan2(across, along)) # 0 = ahead, +90 = starboard
	var side := "starboard" if degrees > 0.0 else "port"
	var angle := absf(degrees)
	if angle < 12.0:
		return "dead ahead"
	if angle < 67.5:
		return "off the %s bow" % side
	if angle < 112.5:
		return "on the %s beam" % side
	if angle < 168.0:
		return "off the %s quarter" % side
	return "dead astern"


## Distance in ship-lengths up close (our ship is about 25 m), cables (185 m) further out. Fathoms
## measure depth, which confused players (Claude's playtest, 2026-10-24).
const SHIP_LENGTH := 25.0


static func nautical_distance(metres: float) -> String:
	if metres < 185.0:
		var lengths := roundi(metres / SHIP_LENGTH)
		if lengths < 1:
			return TranslationServer.translate("half a length")
		if lengths == 1:
			return TranslationServer.translate("1 length")
		return TranslationServer.translate("%d lengths") % lengths
	return TranslationServer.translate("%.1f cables") % (metres / 185.2)


## Clock bearing from the bow: 12 = dead ahead, 3 = starboard, 9 = port.
static func clock_hour(along: float, across: float) -> int:
	var degrees := rad_to_deg(atan2(across, along))
	var hour := roundi(degrees / 30.0)
	if hour <= 0:
		hour += 12
	return hour
