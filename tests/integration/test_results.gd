extends GutTest
## features/results.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")

var _level: Node3D


func _load_level() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)


func before_each() -> void:
	Session.ai_crew = {} # these tests are about human crews only


func after_each() -> void:
	Session.joined_players.clear()


func test_given_rock_hit_and_knockdown_then_logged_with_times() -> void:
	await _load_level()
	var ship: Node3D = _level.get_node("Ship")
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = ship.to_global(Vector3(12, 0, 0))
	ship.get_node("ShipHandling").speed = ship.get_node("ShipHandling").max_speed * 0.4 # cracks the hull, spares the rudder
	ship.get_node("ShipHandling")._hit(rock)
	_level.get_tree().get_nodes_in_group("crew")[1].knock_down(Vector2(0, 1))
	var log := _level.get_node("VoyageLog")
	var texts := []
	for entry in log.entries:
		texts.append(entry.text)
	assert_true(texts.any(func(t): return t.begins_with("Hit a rock")), str(texts))
	assert_true(texts.any(func(t): return t.contains("P2 knocked over")), str(texts))
	assert_true(texts.find("The hull cracked") > texts.find(texts.filter(func(t): return t.begins_with("Hit a rock"))[0]),
			"cause before effect")


func test_given_port_reached_then_results_show_delivery() -> void:
	await _load_level()
	_level.elapsed = 300.0
	_level._finish()
	var results: Control = _level.get_node("HUD/Results")
	assert_true(results.visible)
	assert_true(results.outcome.delivered)
	assert_eq(results.outcome.crates, 6)
	assert_eq(results.outcome.score.total, 600 + 200 + (375 - 300) * 2, "cargo + dry hull + 2 points a second early")
	assert_true(results.outcome.has("records"), "personal bests checked")
	assert_true(results.outcome.has("best_time_text"))


func test_given_sunk_then_results_say_sunk_score_zero() -> void:
	await _load_level()
	var ship: Node3D = _level.get_node("Ship")
	ship.position.x = 650.0
	ship.get_node("HullSystem").ship_sunk.emit()
	var results: Control = _level.get_node("HUD/Results")
	assert_true(results.visible)
	assert_false(results.outcome.delivered)
	assert_eq(results.outcome.score.total, 0)
	assert_almost_eq(results.outcome.progress, 0.5, 0.01)


func test_score_formula() -> void:
	var s: Dictionary = ResultsScreen.score(true, 500, 0.25, 310.0, 330.0)
	assert_eq(s.cargo, 500)
	assert_eq(s.hull, 150)
	assert_eq(s.time, 40)
	assert_eq(s.total, 690)
	assert_eq(ResultsScreen.score(true, 600, 0.0, 400.0, 330.0).time, 0, "late: no time bonus")


func test_given_crew_1_and_3_when_restarted_then_only_they_are_aboard_and_auto_pump() -> void:
	Session.joined_players = [1, 3]
	await _load_level()
	var indexes := []
	for player in _level.get_tree().get_nodes_in_group("crew"):
		indexes.append(player.player_index)
	indexes.sort()
	assert_eq(indexes, [1, 3])
	assert_true(_level.started, "straight back to sea")
	assert_gt(_level.get_node("Ship/HullSystem").auto_pump_rate, 0.0)


func test_given_four_crew_then_no_auto_pump() -> void:
	Session.joined_players = [1, 2, 3, 4]
	await _load_level()
	assert_eq(_level.get_node("Ship/HullSystem").auto_pump_rate, 0.0)


func test_given_crew_screen_when_players_join_and_use_then_voyage_starts_with_them() -> void:
	await _load_level()
	var join: Control = _level.get_node("HUD/CrewJoin")
	join.visible = true
	join.toggle(2)
	join.toggle(4)
	assert_true(join.start())
	await wait_physics_frames(2)
	assert_eq(Session.joined_players, [2, 4] as Array[int])
	assert_eq(_level.get_tree().get_nodes_in_group("crew").size(), 2)


func test_stars_from_the_score() -> void:
	var Stars = load("res://scripts/systems/stars.gd")
	var limits := [1, 500, 800]
	assert_eq(Stars.count(900, true, limits), 3)
	assert_eq(Stars.count(600, true, limits), 2)
	assert_eq(Stars.count(100, true, limits), 1, "delivering is worth a star")
	assert_eq(Stars.count(2000, false, limits), 0, "sunk: no stars")
	var reef: Resource = load("res://scripts/contracts/contract_library.gd").reef_run()
	var auto: Array = Stars.thresholds(reef, 6)
	assert_eq(auto.size(), 3)
	assert_lt(auto[1], auto[2])
	reef.star_scores = [1, 300, 600]
	assert_eq(Stars.thresholds(reef, 6), [1, 300, 600] as Array[int], "a contract can set its own")


func test_results_show_stars_and_save_the_best() -> void:
	await _load_level()
	Session.stars.erase(str(Session.contract_index))
	_level.get_node("StarRules").star_2 = 2
	_level.get_node("StarRules").star_3 = 999999
	_level.dev_event("reach_port")
	await wait_physics_frames(3)
	var results := _level.get_node("HUD/Results")
	assert_eq(results.outcome.stars, 2)
	assert_eq(int(Session.stars[str(Session.contract_index)]), 2)
	assert_string_contains(results._next_star.text, "999999")
