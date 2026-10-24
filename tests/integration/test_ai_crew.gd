extends GutTest
## features/ai_crew.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")

var _level: Node3D
var _ship: Node3D
var _crew := {}


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_crew.clear()
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
		_crew[player.player_index] = player
	await wait_physics_frames(2)


## A human (P1) takes the helm, so the AIs under test aren't pulled away to steer.
func _human_at_helm() -> void:
	await _place(_crew[1], _ship.get_node("Helm").position)
	_crew[1].use_requested = true
	await wait_physics_frames(3)


func _ai(index: int, primary: String, secondary := "") -> Node:
	return _level.add_ai(index, primary, secondary)


func _place(player: Node3D, local: Vector3) -> void:
	player.global_position = _ship.to_global(local + Vector3(0, 0.05, 0))
	await wait_physics_frames(3)


func test_given_human_at_helm_then_ai_with_helm_primary_does_its_secondary() -> void:
	await _place(_crew[1], _ship.get_node("Helm").position)
	_crew[1].use_requested = true
	await wait_physics_frames(3)
	_ai(2, "helm", "pump")
	_ship.get_node("HullSystem").water = 0.4
	await wait_seconds(1.0)
	assert_eq(_level.get_node("CrewBrain").job_of(_crew[2]), "pump")
	assert_eq(_ship.get_node("Helm").occupant, _crew[1], "the human keeps the helm")


func test_given_ai_at_helm_when_human_takes_it_then_ai_steps_aside() -> void:
	_ai(2, "helm")
	await wait_seconds(6.0)
	assert_eq(_ship.get_node("Helm").occupant, _crew[2], "AI went to the helm")
	await _place(_crew[1], _ship.get_node("Helm").position + Vector3(0.3, 0, 0.9))
	_crew[1].use_requested = true
	await wait_physics_frames(3)
	assert_eq(_ship.get_node("Helm").occupant, _crew[1], "the human takes over")
	assert_null(_crew[2].station, "the AI let go")


func test_given_ai_engineer_then_carries_coal_and_vents_hot_engine() -> void:
	await _human_at_helm()
	_ai(4, "engine")
	var engine := _ship.get_node("EngineSystem")
	engine.fuel = 0.3
	await wait_seconds(12.0)
	assert_gt(engine.fuel, 0.4, "shovelled coal from the pile into the furnace")
	engine.heat = 0.95
	await wait_seconds(6.0)
	assert_lt(engine.heat, 0.8, "vented")


func test_given_three_ais_and_work_to_do_then_nobody_stands_around_more_than_3_s() -> void:
	await _human_at_helm()
	var ais := [_ai(2, "navigator", "carpenter"), _ai(3, "engine", "carpenter"), _ai(4, "carpenter", "pump")]
	_ship.get_node("ShipHandling").throttle = 0.6
	var breach: Node3D = _ship.get_node("HullSystem").add_breach(Vector3(3, 0, 3))
	breach._warning_left = 0.0
	_ship.get_node("EngineSystem").fuel = 0.4
	var idle := {}
	var worst := {}
	for i in 60 * 40:
		await wait_physics_frames(1)
		if i % 6 != 0:
			continue
		for ai in ais:
			idle[ai] = 0.0 if ai.is_working() else idle.get(ai, 0.0) + 0.1
			worst[ai] = maxf(worst.get(ai, 0.0), idle[ai])
			if idle[ai] > 1.0 and OS.get_environment("AI_DEBUG") != "":
				var p: Node3D = ai.get_parent()
				print("IDLE P%d job=%s target=%s pos=%s carried=%s station=%s rudder=%d pins=%d loose=%s" % [p.player_index, ai.job, ai.target, _ship.to_local(p.global_position).snapped(Vector3.ONE * 0.1), p.carried, p.station, _ship.get_node("RudderSystem").state, _ship.get_node("PinBox").stock, _pin_info(p)])
	for ai in ais:
		assert_lt(worst[ai], 3.0, "P%d (%s) stood around too long" % [ai.get_parent().player_index, ai.primary])


func test_given_leak_then_ai_carpenter_patches_it() -> void:
	await _human_at_helm()
	_ai(3, "carpenter")
	var hull := _ship.get_node("HullSystem")
	var breach: Node3D = hull.add_breach(Vector3(3, 0, 3))
	breach._warning_left = 0.0
	await wait_seconds(20.0)
	assert_eq(breach.state, 0, "patched")


func test_given_navigator_and_rock_ahead_then_calls_it_out() -> void:
	await _human_at_helm()
	var ai: Node = _ai(3, "navigator")
	var rock: Node3D = RockScene.instantiate()
	_level.add_child(rock)
	rock.global_position = _ship.to_global(Vector3(45, 0, 12))
	rock.global_position.y = 0.0
	await wait_seconds(6.0)
	assert_string_contains(_crew[3].bubble.text, "fathoms", "a shout bubble above the navigator, in sailor's units")
	assert_eq(_crew[3].bubble.style, "shout")
	assert_true(_ship.get_node("Lookout").is_up(), "up in the crow's nest")


func test_given_navigator_with_carpenter_secondary_when_clear_sea_and_leak_then_patches() -> void:
	await _human_at_helm()
	_ai(3, "navigator", "carpenter")
	var breach: Node3D = _ship.get_node("HullSystem").add_breach(Vector3(3, 0, 3))
	breach._warning_left = 0.0
	await wait_seconds(1.0)
	assert_eq(_level.get_node("CrewBrain").job_of(_crew[3]), "carpenter", "no rocks near: fix the leak")


func test_given_ai_helm_then_ship_gets_under_way() -> void:
	_ai(2, "helm")
	await wait_seconds(8.0)
	assert_eq(_ship.get_node("Helm").occupant, _crew[2])
	assert_gt(_ship.get_node("ShipHandling").speed, 1.0)


func test_given_nobody_steering_then_any_ai_takes_the_helm() -> void:
	_ai(4, "engine")
	await wait_seconds(1.0)
	assert_eq(_level.get_node("CrewBrain").job_of(_crew[4]), "helm", "someone must always steer")


func test_given_ai_navigator_then_chart_stays_off_screen_and_rocks_are_called_out() -> void:
	await _human_at_helm()
	_ai(3, "navigator")
	await wait_seconds(5.0)
	assert_true(_ship.get_node("Lookout").is_active(), "the AI watches from the crow's nest")
	assert_false(_level.get_node("HUD/MapChart").visible, "but only a human reader puts it on screen")


func _pin_info(p: Node3D) -> String:
	var pin: Node3D = _level.get_node("CrewBrain").loose_item("pin")
	if pin == null:
		return "none"
	return "%s d=%.2f can=%s carrier=%s lashed=%s parent=%s" % [_ship.to_local(pin.global_position).snapped(Vector3.ONE * 0.1),
			pin.distance_to_player(p), pin.can_interact(p), pin.carrier, pin.lashed, pin.get_parent().name]
