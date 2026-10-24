extends RefCounted
## AI jobs at the helm, the pump and the engine: walk to the station, steer around the known rocks
## (autopilot), feed and vent the furnace. Owned by ai_crew.gd.

const STATION_FOR := {"helm": "Helm", "navigator": "Lookout", "engine": "Engine", "pump": "Pump"}

var ai: Node


func _init(owner_ai: Node) -> void:
	ai = owner_ai


func run_station(station_job: String, delta: float) -> void:
	var station: Node3D = ai._ship.get_node(STATION_FOR[station_job])
	if ai._player.station == station:
		if station_job == "helm":
			_steer()
		return
	ai._drop_carried()
	ai.intend(ai.tr("To the helm!") if station_job == "helm" else ai.tr("Pumping!"))
	if ai._walk_to(station.global_position, delta, 0.9):
		ai._use_on(station)


## The engineer's loop: fill a shovel at the coal pile, carry it to the furnace, feed it. When the
## engine runs hot, take the controls (empty-handed) and vent. With the firebox full, wait by the
## furnace with a loaded shovel, ready.
func engineer(delta: float) -> void:
	var player: CharacterBody3D = ai._player
	var engine: Node = ai._ship.get_node("EngineSystem")
	var furnace: Node3D = ai._ship.get_node("Engine")
	var carrying_coal: bool = player.carried != null and player.carried.kind == "coal"
	var vent_at: float = engine.heat_cap_threshold # above this, top speed is capped: vent
	if player.station == furnace:
		if engine.heat > vent_at and engine.vent_ready_in <= 0.0:
			ai.intend(ai.tr("Too hot! Venting!"), true)
			player.jump_requested = true # vent steam
		elif engine.heat < 0.6 or engine.vent_ready_in > 0.0 and engine.fuel < 0.7:
			ai._press_use() # cool enough (or coal needed): let go of the controls
		return
	if engine.heat > vent_at and engine.vent_ready_in <= 0.0 and not carrying_coal:
		if ai._walk_to(furnace.global_position, delta, 0.9):
			ai._use_on(furnace)
		return
	if player.carried and not carrying_coal:
		ai._drop_carried()
	if carrying_coal:
		ai.intend(ai.tr("Coal for the furnace!"))
		if ai._walk_to(furnace.global_position, delta, 1.0) and engine.fuel < 0.9:
			ai._use_on(furnace) # feed the fire
		return
	var pile: Node3D = ai._ship.get_node("CoalPile")
	if engine.fuel < 0.9:
		ai.intend(ai.tr("Need coal!"))
	if ai._walk_to(pile.global_position, delta, 1.0):
		ai._use_on(pile)


func _steer() -> void:
	var ship: Node3D = ai._ship
	var handling: Node = ship.get_node("ShipHandling")
	var engine: Node = ship.get_node("EngineSystem")
	var wanted := 0.8
	if engine.heat > 0.93 or engine.is_warning():
		wanted = 0.45 # about to overheat: ease off until the engineer vents
	if ai._brain and ai._brain.threat() != null and engine.heat < 0.9 and not engine.is_warning():
		wanted = 1.0 # pirates: full speed to outrun them
	if ai._reverse_left > 0.0:
		wanted = -0.3 # just hit something: back off
	var voyage := ship.get_parent()
	if "finished" in voyage and voyage.finished:
		wanted = 0.0
	var stick_y := 0.0
	if handling.throttle < wanted - 0.03:
		stick_y = -1.0
	elif handling.throttle > wanted + 0.03:
		stick_y = 1.0
	ai._player.move_input = Vector2(autopilot(), stick_y)


## Steers away from the known rocks ahead and back toward the middle of the channel, with a strong
## push away from the cliffs near its edges. Hidden rocks are only known while someone reads the map
## table (or the telescope marked them). The route runs along +X, so the channel is world Z.
func autopilot() -> float:
	return steer_for(ai._ship.global_position, ai._ship.rotation.y, known_rocks(), channel_half_width())


## Stick x for a ship at here/yaw among known rocks: positive = steer to starboard.
static func steer_for(here: Vector3, yaw: float, rocks: Array, half_width: float) -> float:
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var go_starboard := clampf(-here.z / half_width, -1.0, 1.0) * 0.8 # pull to the middle, harder near the edges
	if absf(here.z) > half_width - 6.0:
		go_starboard -= signf(here.z) * 1.2 # too close to the cliffs: come back
	var toward_middle := -signf(here.z) if absf(here.z) > 1.0 else 1.0
	# Room to spare around rocks: half the hull (3.5 m) plus 3.5 m, or plus 2 m in a narrow channel.
	var margin := 5.5 if half_width < 20.0 else 7.0
	for rock in rocks:
		var centre: Vector3 = rock.avoid_centre() if rock.has_method("avoid_centre") else rock.global_position
		var size: float = rock.avoid_radius() if rock.has_method("avoid_radius") else rock.radius
		var offset: Vector3 = centre - here
		var along := offset.dot(fwd)
		if along < -5.0 - size or along > 80.0 + size:
			continue
		var across := offset.dot(right)
		if absf(across) < size + margin:
			# Pass on the side away from the rock; nearly dead ahead, pass on the channel's middle side.
			var away := -signf(across) if absf(across) > 1.5 else toward_middle
			go_starboard += away * 1.5 * (1.0 - maxf(along, 0.0) / 80.0)
	var target_yaw := -clampf(go_starboard, -1.0, 1.0) * 0.6 # positive yaw = bow to port
	return clampf((yaw - target_yaw) * 4.0, -1.0, 1.0) # stick right turns to starboard


func known_rocks() -> Array:
	var ship: Node3D = ai._ship
	var chart_on: bool = ship.get_node("Lookout").is_active()
	var sight := chart_range()
	var known := []
	for rock in ai.get_tree().get_nodes_in_group("rocks"):
		if is_cliff(rock) or (rock.has_method("is_soft") and rock.is_soft()):
			continue # cliffs: the lane stays inside the channel instead
		if not rock.hidden:
			known.append(rock) # wrecks, whales, sirens, atolls: everyone can see them
			continue
		var distance: float = rock.global_position.distance_to(ship.global_position)
		if rock.revealed or (chart_on and distance <= sight) or _marked(rock):
			known.append(rock)
	return known


static func is_cliff(rock: Node3D) -> bool:
	return ("kind" in rock and rock.kind == "cliff") or (not ("kind" in rock) and not rock.hidden)


func channel_half_width() -> float:
	var voyage: Node = ai._ship.get_parent()
	if "contract" in voyage and voyage.contract:
		return voyage.contract.coast_half_width - 9.0
	return 30.0


func chart_range() -> float:
	var voyage: Node = ai._ship.get_parent()
	if "contract" in voyage and voyage.contract:
		return voyage.contract.chart_range
	return 70.0


func _marked(rock: Node3D) -> bool:
	for child in rock.get_children():
		if child.is_in_group("spot_markers") and child.visible:
			return true
	return false
