extends RefCounted
## The AI gunner: when pirates come alongside, loads a cannon on their side, aims and fires, then
## fetches another ball. Owned by ai_crew.gd.

var ai: Node


func _init(owner_ai: Node) -> void:
	ai = owner_ai


## Fight the pirates: load a cannon on their side, aim at them, fire; fetch another ball.
func gunner(delta: float) -> void:
	var player: CharacterBody3D = ai._player
	var ship: Node3D = ai._ship
	var enemy: Node3D = ai._brain.threat()
	if enemy == null:
		if player.station:
			ai._press_use()
		return
	var right: Vector3 = ship.global_basis.z
	var side := signf((enemy.global_position - ship.global_position).dot(right))
	var cannon: Node3D = player.station if player.station and player.station.is_in_group("cannons") else null
	if cannon:
		if not cannon.loaded:
			ai._press_use() # fired: go and fetch another ball
			return
		var wanted := aim_for(cannon, enemy)
		if absf(wanted - cannon.aim) > 0.06:
			player.move_input = Vector2(signf(wanted - cannon.aim) * cannon.side, 0.0)
		else:
			ai.intend(ai.tr("Fire!"), true)
			player.jump_requested = true
		return
	var loaded := cannon_on(side, true)
	if loaded and (player.carried == null or player.carried.kind != "ball"):
		ai._drop_carried()
		ai.intend(ai.tr("To the cannon!"))
		if ai._walk_to(loaded.global_position, delta, 0.8):
			ai._use_on(loaded)
		return
	var empty := cannon_on(side, false)
	if empty == null:
		return
	ai.intend(ai.tr("Load the cannon!"))
	ai._carpenter.fetch_and_bring("ball", ship.get_node("BallRack"), empty, delta)


## A free cannon on that side, loaded or not.
func cannon_on(side: float, loaded: bool) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for cannon in ai.get_tree().get_nodes_in_group("cannons"):
		if not ai._ship.is_ancestor_of(cannon) or cannon.side != side or cannon.loaded != loaded:
			continue
		if cannon.occupant != null and cannon.occupant != ai._player:
			continue
		var distance: float = ai._player.global_position.distance_to(cannon.global_position)
		if distance < best_distance:
			best = cannon
			best_distance = distance
	return best


## The aim (-1..1) that points this cannon at the enemy.
static func aim_for(cannon: Node3D, enemy: Node3D) -> float:
	var to := enemy.global_position - cannon.global_position
	var out: Vector3 = cannon.global_basis.z * cannon.side
	var along: Vector3 = cannon.global_basis.x
	var angle := atan2(to.dot(along), to.dot(out))
	return clampf(angle / deg_to_rad(cannon.aim_limit_degrees), -1.0, 1.0)
