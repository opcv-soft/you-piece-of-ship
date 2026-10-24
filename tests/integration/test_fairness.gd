extends GutTest
## features/fairness.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D
var _ship: Node3D
var _director: Node


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_director = _level.get_node("HazardDirector")
	_director.big_waves_enabled = true # off in the game for now (Olivier, 2026-10-24); the rules still hold
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)
	_director.set_physics_process(false)


func _sail_to(x: float) -> void:
	_ship.position.x = x


func test_given_systems_fine_when_ship_reaches_wave_then_wave_starts() -> void:
	watch_signals(_director)
	var first: Array = _director.waves[0]
	_sail_to(first[0] - 1.0)
	_director.step(0.1)
	assert_signal_not_emitted(_director, "wave_sent")
	_sail_to(first[0] + 1.0)
	_director.step(0.1)
	assert_signal_emitted(_director, "wave_sent")
	assert_true(_ship.get_node("WaveMotion").is_wave_active(), "warning running")


func test_given_two_systems_failing_when_wave_position_reached_then_wave_waits() -> void:
	watch_signals(_director)
	_ship.get_node("HullSystem").add_breach(Vector3(3, 0, 3))
	_ship.get_node("RudderSystem").try_damage(1.0)
	_director.step(0.1)
	assert_eq(_director.failing_systems().size(), 2)
	_sail_to(_director.waves[0][0] + 5.0)
	_director.step(0.1)
	assert_signal_not_emitted(_director, "wave_sent")
	assert_eq(_director.next_wave, 0, "still pending")


func test_given_recent_recovery_then_no_wave_for_20_seconds() -> void:
	watch_signals(_director)
	var rudder := _ship.get_node("RudderSystem")
	rudder.try_damage(1.0)
	_director.step(0.1)
	rudder.repair()
	_director.step(0.1)
	assert_signal_emitted(_director, "recovered")
	_sail_to(_director.waves[0][0] + 5.0)
	_director.step(10.0)
	assert_signal_not_emitted(_director, "wave_sent", "inside the calm window")
	_director.step(11.0)
	assert_signal_emitted(_director, "wave_sent", "after the calm window")


func test_given_waiting_wave_when_200_m_past_then_skipped() -> void:
	watch_signals(_director)
	_ship.get_node("HullSystem").add_breach(Vector3(3, 0, 3))
	_ship.get_node("RudderSystem").try_damage(1.0)
	_director.step(0.1)
	_sail_to(_director.waves[0][0] + 201.0)
	_director.step(0.1)
	assert_signal_emitted(_director, "wave_skipped")
	assert_eq(_director.next_wave, 1)


func test_every_failure_warns_at_least_5_seconds() -> void:
	assert_gte(_ship.get_node("Leak1").warning_seconds, 5.0, "leak")
	assert_gte(_ship.get_node("RudderSystem").warning_seconds, 5.0, "rudder")
	assert_gte(_ship.get_node("EngineSystem").warning_seconds, 5.0, "engine")
	assert_gte(_ship.get_node("WaveMotion").wave_warning_seconds, 5.0, "big wave and fraying rope")


func test_no_sinking_within_60_seconds_of_first_failure() -> void:
	assert_gte(_ship.get_node("HullSystem").sink_grace_seconds, 60.0)
