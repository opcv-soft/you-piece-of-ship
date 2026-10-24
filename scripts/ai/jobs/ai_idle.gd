extends RefCounted
## What an AI does when nothing needs repairing: pump, tie down cargo, help with the coal, go
## fishing, or hold a plank ready. Also the cargo job (re-lashing loose crates). Owned by ai_crew.gd.

var ai: Node


func _init(owner_ai: Node) -> void:
	ai = owner_ai


## Nothing to repair: still be useful. Pump any water, help keep the furnace fed, re-tie loose
## cargo, or hold a plank ready near the middle of the deck for the next leak.
func idle_work(delta: float) -> void:
	var ship: Node3D = ai._ship
	var player: CharacterBody3D = ai._player
	var hull: Node = ship.get_node("HullSystem")
	var pump: Node3D = ship.get_node("Pump")
	if hull.water > 0.01 and (pump.occupant == null or pump.occupant == player):
		ai._drop_carried()
		if player.station != pump and ai._walk_to(pump.global_position, delta, 0.9):
			ai._use_on(pump)
		return
	if not ai._brain.loose_crates().is_empty() or ai._brain.fraying_crate() != null:
		cargo(delta)
		return
	var engine: Node = ship.get_node("EngineSystem")
	var carrying: Node3D = player.carried
	if engine.fuel < 0.7 or (carrying and carrying.kind == "coal"):
		ai._steering.engineer(delta) # lend a hand with the coal
		return
	if fishing_ok():
		var spot := _free_fishing_spot()
		if spot:
			ai._drop_carried()
			ai.intend(ai.tr("Gone fishing!"))
			if ai._walk_to(spot.global_position, delta, 0.8):
				ai._use_on(spot)
			return
	if carrying == null and ship.get_node("PlankBox").stock > 1:
		var box: Node3D = ship.get_node("PlankBox")
		if ai._walk_to(box.global_position, delta, 1.6): # up on the forecastle: reach from the step
			ai._use_on(box)
		return
	if carrying and carrying.kind != "plank":
		ai._drop_carried()
	ai._walk_to(ship.to_global(Vector3(-1.0, 0.0, 1.6 if player.player_index % 2 == 0 else -1.6)), delta, 0.8)


## All's well aboard: no water, no leaks, nothing to repair, no loose cargo, coal and heat fine.
func fishing_ok() -> bool:
	var brain: Node = ai._brain
	var hull: Node = ai._ship.get_node("HullSystem")
	var engine: Node = ai._ship.get_node("EngineSystem")
	if hull.water > 0.01 or not brain.carpenter_tasks().is_empty() or not brain.loose_crates().is_empty():
		return false
	for breach in hull.breaches():
		if breach.state != 0:
			return false
	return engine.fuel >= 0.6 and engine.heat < engine.heat_cap_threshold and brain.fraying_crate() == null \
			and brain.threat() == null


func _free_fishing_spot() -> Node3D:
	for spot in ai.get_tree().get_nodes_in_group("fishing_spots"):
		if ai._ship.is_ancestor_of(spot) and (spot.occupant == null or spot.occupant == ai._player):
			return spot
	return null


## Fishing: strike when the float dips (most of the time: nobody's perfect).
func fish() -> void:
	var spot: Node3D = ai._player.station
	if spot.phase == spot.Phase.BITE and spot.bite_left < spot.bite_window - 0.2:
		if ai._rng.randf() < 0.6:
			ai._player.jump_requested = true
		else:
			spot.bite_left = 0.0 # missed it


func cargo(delta: float) -> void:
	var player: CharacterBody3D = ai._player
	var carried: Node3D = player.carried
	if carried and carried.kind == "crate":
		var spot: Marker3D = ai._ship.get_node("CargoBay").nearest_free_spot(player.global_position)
		if spot and ai._walk_to(spot.global_position, delta, 0.5):
			ai._use_on(ai._ship.get_node("CargoBay"))
		return
	ai._drop_carried()
	var crate: Node3D = ai._brain.fraying_crate()
	if crate == null:
		var loose: Array = ai._brain.loose_crates()
		crate = loose[0] if not loose.is_empty() else null
	ai.target = crate
	if crate:
		ai.intend(ai.tr("Tying down cargo!"))
	if crate and ai._walk_to(crate.global_position, delta, 0.9):
		ai._use_on(crate)
