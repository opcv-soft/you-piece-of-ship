extends GutTest
## features/engine_heat.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D
var _ship: Node3D
var _engine: Node
var _handling: Node
var _crew: Array[Node] = []


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_engine = _ship.get_node("EngineSystem")
	_handling = _ship.get_node("ShipHandling")
	_crew = _level.get_tree().get_nodes_in_group("crew")
	for player in _crew:
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(3)
	_engine.set_physics_process(false)


func _run(seconds: float) -> void:
	for i in int(seconds * 60.0):
		_engine.step(1.0 / 60.0)


func _place(player: Node3D, local: Vector3) -> void:
	player.global_position = _ship.to_global(local + Vector3(0, 0.05, 0))
	await wait_physics_frames(3)


func _use(player: Node3D) -> void:
	player.use_requested = true
	await wait_physics_frames(2)


func test_given_full_throttle_when_heat_passes_80_then_top_speed_capped() -> void:
	_handling.throttle = 1.0
	_run(10.0)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed, 0.01, "not capped while cool")
	_run(10.0)
	assert_gt(_engine.heat, 0.8)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed * _engine.heat_cap_speed, 0.01, "capped")


func test_given_heat_100_when_warning_ends_then_stalls_20_s_and_pipe_bursts() -> void:
	_handling.throttle = 1.0
	_engine.heat = 1.0
	_run(0.1)
	assert_true(_engine.is_warning(), "warning first")
	assert_false(_engine.is_stalled())
	_run(5.1)
	assert_true(_engine.is_stalled(), "stalled after the warning")
	assert_eq(_handling.top_speed(), 0.0)
	assert_true(_engine.is_pipe_burst(), "pipe burst")
	_run(20.5)
	assert_false(_engine.is_stalled(), "running again after 20 s")


func test_given_heat_100_when_engineer_vents_then_cools_and_bystander_knocked() -> void:
	await _place(_crew[3], _ship.get_node("Engine").position)
	await _use(_crew[3])
	assert_eq(_ship.get_node("Engine").occupant, _crew[3])
	await _place(_crew[1], _ship.get_node("Engine").position + Vector3(1.5, 0, -0.5))
	watch_signals(_crew[1])
	_handling.throttle = 1.0
	_engine.heat = 1.0
	_run(0.1)
	assert_true(_engine.is_warning())
	_crew[3].jump_requested = true # Jump at the engine = vent
	await wait_physics_frames(2)
	assert_lt(_engine.heat, 0.6, "vented")
	_run(6.0)
	assert_false(_engine.is_stalled(), "stall avoided")
	assert_signal_emitted(_crew[1], "knocked_down")
	assert_eq(_crew[3].knocked, 0.0, "the engineer holds on")


func test_given_no_coal_then_limps_and_a_shovel_from_the_pile_refills() -> void:
	_engine.fuel = 0.0
	_handling.throttle = 1.0
	_run(0.2)
	assert_almost_eq(_handling.top_speed(), _handling.max_speed * _engine.no_fuel_speed, 0.01)
	var player: Node3D = _crew[3]
	await _place(player, _ship.get_node("CoalPile").position)
	await _use(player)
	assert_eq(player.carried.kind, "coal", "filled a shovel")
	await _place(player, _ship.get_node("Engine").position)
	await _use(player)
	assert_null(player.carried, "fed to the furnace")
	assert_almost_eq(_engine.fuel, _engine.shovel_load, 0.01, "one shovel's worth")


func test_given_hit_while_carrying_coal_then_half_spills_and_leaves_a_mark() -> void:
	var player: Node3D = _crew[3]
	await _place(player, _ship.get_node("CoalPile").position)
	await _use(player)
	var shovel: Node3D = player.carried
	var rock: Node3D = preload("res://scenes/greybox/rock.tscn").instantiate()
	_level.add_child(rock)
	_handling.impact.emit(rock)
	assert_almost_eq(shovel.amount, 0.5, 0.01, "half the coal spilled")
	assert_eq(_level.get_tree().get_nodes_in_group("coal_marks").size(), 1, "a black mark on the deck")


func test_given_knocked_down_with_coal_then_all_spills() -> void:
	var player: Node3D = _crew[3]
	await _place(player, _ship.get_node("CoalPile").position)
	await _use(player)
	player.knock_down(Vector2(0, 1))
	await wait_physics_frames(2)
	assert_null(player.carried)
	assert_eq(_level.get_tree().get_nodes_in_group("items").filter(func(i): return i.kind == "coal").size(), 0)
	assert_gte(_level.get_tree().get_nodes_in_group("coal_marks").size(), 1)


func test_given_water_in_hold_then_coal_gets_wet_and_top_speed_drops() -> void:
	_ship.get_node("HullSystem").water = 0.5
	var pile := _ship.get_node("CoalPile")
	await wait_seconds(8.0)
	assert_gt(pile.wetness, 0.5, "the bottom of the pile is soaked")
	var dry_speed: float = _handling.top_speed()
	var player: Node3D = _crew[3]
	await _place(player, pile.position)
	await _use(player)
	_engine.fuel = 0.05
	await _place(player, _ship.get_node("Engine").position)
	await _use(player)
	_engine.fuel = 0.6 # plenty of (wet) coal now
	_run(0.1)
	assert_gt(_engine.coal_wetness, 0.2)
	assert_lt(_handling.top_speed(), dry_speed, "wet coal: slower")
	assert_string_contains(_ship.get_node("Engine").status_text, "WET")


func test_given_engine_dead_then_sail_keeps_ship_moving() -> void:
	_engine.fuel = 0.0
	_engine.stall_left = 20.0
	_handling.throttle = 0.0
	_handling.set_physics_process(true)
	await wait_seconds(3.0)
	assert_almost_eq(_handling.speed, _handling.sail_speed, 0.05, "the sail pushes")
	assert_gt(_handling.sail_speed, 0.5)


func test_given_water_in_hull_then_engine_heats_faster() -> void:
	_handling.throttle = 1.0
	_run(5.0)
	var dry: float = _engine.heat
	_engine.heat = 0.0
	_ship.get_node("HullSystem").water = 0.8
	_run(5.0)
	assert_gt(_engine.heat, dry * 1.4)


func test_given_burst_pipe_when_two_crew_fix_4_s_then_fixed() -> void:
	var pipe := _ship.get_node("CoolingPipe")
	pipe.break_it()
	await _place(_crew[0], pipe.position)
	await _use(_crew[0])
	await _place(_crew[1], pipe.position)
	await _use(_crew[1])
	assert_eq(pipe.occupants.size(), 2)
	await wait_seconds(4.3)
	assert_false(pipe.broken)


func test_given_nobody_at_engine_then_gauge_hidden_and_engineer_sees_it() -> void:
	var gauge: Control = _level.get_node("HUD/EngineGauge")
	await wait_physics_frames(2)
	assert_false(gauge.visible)
	await _place(_crew[3], _ship.get_node("Engine").position)
	await _use(_crew[3])
	await wait_physics_frames(2)
	assert_true(gauge.visible)


func test_given_low_coal_then_everyone_sees_warning() -> void:
	_engine.fuel = 0.3
	_handling.throttle = 1.0
	watch_signals(_engine)
	_run(10.0)
	assert_signal_emitted(_engine, "fuel_low")
	assert_string_contains(_ship.get_node("Engine").status_text, "COAL LOW")


func test_full_firebox_lasts_about_150_seconds_at_full_throttle() -> void:
	_handling.throttle = 1.0
	_engine.heat_rise = 0.0 # only the coal matters here
	_run(140.0)
	assert_gt(_engine.fuel, 0.0)
	_run(15.0)
	assert_eq(_engine.fuel, 0.0)


func test_crew_track_coal_smears_around_the_deck() -> void:
	var ship: Node3D = _level.get_node("Ship")
	var smears: Node = ship.get_node("CoalSmears")
	smears.add_smear(Vector3(0, 0, 0), 1.0, Vector2(1, 0))
	var walker: Node3D = _level.get_tree().get_nodes_in_group("crew")[0]
	walker.position = Vector3(0, 0.05, 0)
	await wait_physics_frames(3)
	assert_gt(smears.soot_of(walker), 0.5, "stepped in it: sooty boots")
	walker.position = Vector3(-4, 0.05, 1.0)
	await wait_physics_frames(2)
	walker.position = Vector3(-5, 0.05, 1.0)
	await wait_physics_frames(2)
	assert_gt(_level.get_tree().get_nodes_in_group("coal_prints").size(), 0, "black footprints across the deck")
