extends GutTest
## features/battle.feature — pirates attack from the side; cannons, loot, outrunning them.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D
var _ship: Node3D
var _crew := {}


func before_each() -> void:
	Session.ai_crew = {}
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.maiden_voyage()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_crew.clear()
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
		_crew[player.player_index] = player
	await wait_physics_frames(2)


func _cannons(side: float) -> Array:
	return get_tree().get_nodes_in_group("cannons").filter(func(c): return c.side == side)


func test_two_cannons_a_side_and_a_ball_rack() -> void:
	assert_eq(_cannons(-1.0).size(), 2)
	assert_eq(_cannons(1.0).size(), 2)
	assert_not_null(_ship.get_node_or_null("BallRack"))


func test_load_aim_fire_and_hit_a_pirate() -> void:
	var enemy: Node3D = _level.spawn_enemy(1.0)
	var cannon: Node3D = _cannons(1.0)[0]
	enemy.set_physics_process(false)
	enemy.global_position = cannon.landing_point()
	enemy.global_position.y = 0.0
	var gunner: Node3D = _crew[1]
	gunner.position = cannon.position
	await wait_physics_frames(2)
	var ball: Node3D = _ship.get_node("BallRack").take()
	ball.pick_up(gunner)
	assert_true(gunner.interact_with(cannon), "load it")
	assert_true(cannon.loaded)
	assert_true(cannon.occupy(gunner))
	watch_signals(cannon)
	gunner.jump_requested = true
	await wait_physics_frames(2)
	assert_signal_emitted(cannon, "fired")
	assert_false(cannon.loaded)
	await wait_seconds(1.4)
	assert_eq(enemy.health, 2, "a hit")


func test_three_hits_sink_it_and_its_planks_swoosh_aboard() -> void:
	var enemy: Node3D = _level.spawn_enemy(-1.0)
	watch_signals(enemy)
	for i in 3:
		enemy.take_hit(enemy.global_position)
	assert_signal_emitted(enemy, "sunk")
	assert_false(enemy.is_threat())
	await wait_physics_frames(2)
	var salvage := get_tree().get_nodes_in_group("salvage")
	assert_eq(salvage.size(), 3, "a plank off each of the first two hits, the rest when it sinks")
	for piece in salvage:
		piece.land_all()
	assert_eq(_level.bonus_points, 160, "planks: 1 + 1 + 6, at 20 points each")


func test_an_enemy_ball_on_deck_cracks_the_hull() -> void:
	_level.cannon_hit(_ship.to_global(Vector3(2, 0, 3)))
	var cracked := 0
	for breach in _ship.get_node("HullSystem").breaches():
		if breach.state != 0:
			cracked += 1
	assert_eq(cracked, 1)


func test_pirates_only_fire_when_alongside() -> void:
	var enemy: Node3D = _level.spawn_enemy(-1.0)
	enemy.reload_left = 0.0
	watch_signals(enemy)
	await wait_physics_frames(2)
	assert_signal_not_emitted(enemy, "broadside", "still behind: no shot")
	var right: Vector3 = _ship.global_basis.z
	enemy.global_position = _ship.global_position - right * enemy.stand_off
	enemy.global_position.y = 0.0
	await wait_physics_frames(2)
	assert_signal_emitted(enemy, "took_aim", "level with us: they take aim")
	assert_signal_not_emitted(enemy, "broadside", "but give us a moment to see it coming")
	await wait_seconds(enemy.warning_seconds + 0.1)
	assert_signal_emitted(enemy, "broadside", "then the broadside")


func test_outrunning_them_makes_them_give_up() -> void:
	var enemy: Node3D = _level.spawn_enemy(1.0)
	enemy.global_position = _ship.global_position - _ship.global_basis.x * 90.0
	await wait_physics_frames(2)
	assert_false(enemy.is_threat())
	assert_lt(enemy.speed_share, 1.0, "they're slower than us at full throttle")


func test_an_ai_gunner_loads_and_fires() -> void:
	_ship.get_node("Helm").occupy(_crew[1])
	var enemy: Node3D = _level.spawn_enemy(1.0)
	enemy.set_physics_process(false)
	var right: Vector3 = _ship.global_basis.z
	enemy.global_position = _ship.global_position + right * 20.0
	enemy.global_position.y = 0.0
	_level.add_ai(3, "gunner", "")
	var fired := [false]
	for cannon in _cannons(1.0):
		cannon.fired.connect(func(_b): fired[0] = true)
	await wait_seconds(12.0)
	assert_true(fired[0], "the AI gunner fired at the pirates")


func test_a_hit_knocks_a_carried_cannonball_loose_and_it_rolls_into_crew() -> void:
	var carrier: Node3D = _crew[1]
	var victim: Node3D = _crew[2]
	carrier.position = Vector3(-4.0, 0.05, 0.0)
	victim.position = Vector3(-1.5, 0.05, 0.0)
	await wait_physics_frames(2)
	var ball: Node3D = _ship.get_node("BallRack").take()
	ball.pick_up(carrier)
	_ship.lurch(Vector2(6.0, 0.0)) # a crash: everything loose keeps going toward the bow
	assert_null(carrier.carried, "the ball is dropped")
	assert_gt(ball.velocity.x, 3.0, "and rolls forward")
	await wait_seconds(1.0)
	assert_gt(victim.knocked, 0.0, "it bowls a sailor over")


func test_pirates_have_a_crew_and_keep_pace() -> void:
	var enemy: Node3D = _level.spawn_enemy(1.0)
	await wait_physics_frames(2)
	assert_eq(enemy._crew.size(), enemy.crew_count, "little pirates aboard")
	var handling := _ship.get_node("ShipHandling")
	handling.speed = handling.max_speed * 0.7
	enemy.global_position = _ship.global_position + _ship.global_basis.z * enemy.stand_off
	enemy.global_position.y = 0.0
	enemy._speed = handling.speed
	await wait_seconds(2.0)
	var along: float = (enemy.global_position - _ship.global_position).dot(_ship.global_basis.x)
	assert_lt(absf(along), 8.0, "still level with us after 2 s")


func test_ramming_a_pirate_hurts_both() -> void:
	var enemy: Node3D = _level.spawn_enemy(1.0)
	enemy.set_physics_process(true)
	enemy.global_position = _ship.global_position + _ship.global_basis.z * 4.5
	enemy.global_position.y = 0.0
	var health: int = enemy.health
	await wait_physics_frames(3)
	assert_lt(enemy.health, health, "the pirate ship is damaged")
	var cracked := 0
	for breach in _ship.get_node("HullSystem").breaches():
		if breach.state != 0:
			cracked += 1
	assert_gt(cracked, 0, "and so are we")


func test_a_player_at_a_cannon_sees_the_aim_guide_and_it_turns_gold_on_target() -> void:
	var cannon: Node3D = _cannons(1.0)[0]
	var guide: Node3D = cannon.get_node("AimGuide")
	await wait_physics_frames(2)
	assert_false(guide.visible, "hidden when nobody's at the cannon")
	cannon.occupy(_crew[0])
	await wait_physics_frames(2)
	assert_true(guide.visible, "dotted line to where the ball lands")
	assert_null(guide.on_target, "open sea")
	var enemy: Node3D = _level.spawn_enemy(1.0)
	enemy.set_physics_process(false)
	enemy.global_position = cannon.landing_point()
	enemy.global_position.y = 0.0
	await wait_physics_frames(2)
	assert_eq(guide.on_target, enemy, "gold when the shot would hit them")


func test_every_hit_on_a_pirate_knocks_a_plank_aboard() -> void:
	var enemy: Node3D = _level.spawn_enemy(-1.0)
	enemy.take_hit(enemy.global_position)
	await wait_physics_frames(2)
	assert_eq(get_tree().get_nodes_in_group("salvage").size(), 1, "a plank flies off on the first hit")


## Pirates level with us, guns loaded, nothing in the way: they take aim on the next frame.
func _pirates_alongside(side := -1.0) -> Node3D:
	var enemy: Node3D = _level.spawn_enemy(side)
	enemy.accuracy = 1.0 # every ball aimed at the deck, so the rings are on it
	enemy.reload_left = 0.0
	enemy.global_position = _ship.global_position + _ship.global_basis.z * side * enemy.stand_off
	enemy.global_position.y = 0.0
	return enemy


func _cracked() -> int:
	var cracked := 0
	for breach in _ship.get_node("HullSystem").breaches():
		if breach.state != 0:
			cracked += 1
	return cracked


func test_taking_aim_opens_gun_ports_and_rings_mark_the_landing_spots() -> void:
	var enemy := _pirates_alongside()
	var warning: Node3D = enemy.get_node("BroadsideWarning")
	assert_false(warning.showing(), "nothing to see while they reload")
	await wait_physics_frames(2)
	assert_true(enemy.aiming)
	assert_true(warning.showing(), "gun ports open, rings on our deck")
	assert_eq(warning.rings().size(), enemy.balls_per_broadside, "one ring per ball")
	for ring in warning.rings():
		assert_true(ring.visible)


func test_the_balls_land_in_the_rings() -> void:
	var enemy := _pirates_alongside()
	await wait_physics_frames(2)
	var spots: Array = enemy.warning_points()
	var landed := []
	enemy.broadside.connect(func():
		for ball in get_tree().get_nodes_in_group("enemy_cannonballs"):
			landed.append(ball.target))
	await wait_seconds(enemy.warning_seconds + 0.1)
	assert_eq(landed.size(), spots.size(), "a ball for every ring")
	for i in spots.size():
		assert_almost_eq(Vector2(landed[i].x, landed[i].z), Vector2(spots[i].x, spots[i].z), Vector2(0.01, 0.01))
	assert_false(enemy.get_node("BroadsideWarning").showing(), "rings gone once they've fired")


func test_standing_still_in_the_rings_gets_us_hit() -> void:
	var enemy := _pirates_alongside()
	await wait_physics_frames(2)
	assert_true(enemy.aiming)
	await wait_seconds(enemy.warning_seconds + 1.6)
	assert_gt(_cracked(), 0, "the deck was in the rings: the hull cracks")


func test_sailing_out_of_the_rings_dodges_the_broadside() -> void:
	var enemy := _pirates_alongside()
	await wait_physics_frames(2)
	assert_true(enemy.aiming)
	_ship.global_position += _ship.global_basis.x * 30.0 # full ahead: the deck leaves the rings
	await wait_seconds(enemy.warning_seconds + 1.6)
	assert_eq(_cracked(), 0, "the balls splash into the sea behind us")


func test_they_aim_where_we_will_be_not_where_we_are() -> void:
	var handling := _ship.get_node("ShipHandling")
	handling.speed = handling.max_speed * 0.6
	var enemy := _pirates_alongside()
	enemy.balls_per_broadside = 3
	await wait_physics_frames(2)
	var ahead := 0.0
	for spot in enemy.warning_points():
		ahead += (spot - _ship.global_position).dot(handling.forward())
	assert_gt(ahead / 3.0, 5.0, "they lead a moving ship, so holding course still gets us hit")


func test_hitting_them_while_they_aim_spoils_the_broadside() -> void:
	var enemy := _pirates_alongside()
	await wait_physics_frames(2)
	assert_true(enemy.aiming)
	watch_signals(enemy)
	enemy.take_hit(enemy.global_position)
	assert_false(enemy.aiming, "knocked off their aim")
	assert_signal_emitted(enemy, "spoiled")
	assert_false(enemy.get_node("BroadsideWarning").showing(), "the rings vanish")
	assert_gt(enemy.reload_left, 0.0, "they have to reload")
	await wait_seconds(enemy.warning_seconds + 0.2)
	assert_signal_not_emitted(enemy, "broadside", "no shot this time")


func test_a_sinking_ship_takes_its_rings_with_it() -> void:
	var enemy := _pirates_alongside()
	await wait_physics_frames(2)
	for i in enemy.health:
		enemy.take_hit(enemy.global_position)
	assert_false(enemy.get_node("BroadsideWarning").showing())
