extends RefCounted
## The AI carpenter: hammers leaks, fixes the pipe, patches breaches with planks (or a crate when
## the planks run out), brings rudder pins. Also fetches and delivers items for other jobs.
## Owned by ai_crew.gd.

var ai: Node


func _init(owner_ai: Node) -> void:
	ai = owner_ai


func carpentry(delta: float) -> void:
	var task: Array = ai._pick_task()
	if task.is_empty():
		ai.target = null
		ai._idle.idle_work(delta)
		return
	ai.target = task[1]
	var target: Node3D = ai.target
	ai.intend({"hammer": ai.tr("Hammering the leak!"), "pipe": ai.tr("Fixing the pipe!"), "patch": ai.tr("Going to fix leak!"),
			"rudder": ai.tr("Fetching a rudder pin!")}.get(task[0], ""))
	match task[0]:
		"hammer", "pipe":
			ai._drop_carried()
			if ai._player.station == target:
				return # working on it
			if ai._walk_to(target.global_position, delta, 0.9):
				ai._use_on(target)
		"patch":
			_patch(target, delta)
		"rudder":
			fetch_and_bring("pin", ai._ship.get_node("PinBox"), target, delta)


func _patch(breach: Node3D, delta: float) -> void:
	var carried: Node3D = ai._player.carried
	if carried and (carried.kind == "plank" or (carried.kind == "crate" and not breach.is_plugged)):
		if ai._walk_to(breach.global_position, delta, 0.9):
			ai._use_on(breach)
		return
	var box: Node3D = ai._ship.get_node("PlankBox")
	if box.stock > 0 or ai._brain.loose_item("plank") != null:
		fetch_and_bring("plank", box, breach, delta)
		return
	# Out of planks: stuff a cargo crate in the hole (the cargo is lost).
	if breach.is_plugged:
		return
	var crate := _nearest_crate()
	if crate == null:
		return
	if carried and carried != crate:
		ai._drop_carried()
	if ai._walk_to(crate.global_position, delta, 0.9):
		ai._use_on(crate)


## Gets an item (a loose one on the deck, or one from its box) and brings it to a target.
func fetch_and_bring(kind: String, box: Node3D, destination: Node3D, delta: float) -> void:
	var carried: Node3D = ai._player.carried
	if carried and carried.kind == kind:
		if ai._walk_to(approach_point(destination), delta, 0.6):
			ai._use_on(destination)
		return
	ai._drop_carried()
	var loose: Node3D = ai._brain.loose_item(kind)
	var source: Node3D = loose if loose else box
	# Items can be reached from 1.3 m; the spare boxes up on the forecastle from the step below it.
	var reach := 1.2 if source.is_in_group("items") else minf(1.7, source.radius - 0.2)
	if ai._walk_to(source.global_position, delta, reach):
		ai._use_on(source)


## Where to stand to reach a station. The helm's stand point is behind the wheel post (and maybe
## taken by the captain), so deliveries come alongside it instead.
func approach_point(station: Node3D) -> Vector3:
	var player: CharacterBody3D = ai._player
	if String(station.name) == "Helm":
		var side := 1.0 if player.global_position.distance_to(station.to_global(Vector3(0.3, 0, 0.95))) \
				< player.global_position.distance_to(station.to_global(Vector3(0.3, 0, -0.95))) else -1.0
		return station.to_global(Vector3(0.3, 0.0, 0.95 * side))
	return station.global_position


func _nearest_crate() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for crate in ai.get_tree().get_nodes_in_group("cargo"):
		var distance: float = ai._player.global_position.distance_to(crate.global_position)
		if crate.carrier == null and distance < best_distance:
			best = crate
			best_distance = distance
	return best
