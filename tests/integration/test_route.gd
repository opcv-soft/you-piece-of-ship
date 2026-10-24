extends GutTest
## features/route.feature

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D


func before_each() -> void:
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func test_given_reef_run_then_rocks_hidden_cliffs_visible_port_at_end() -> void:
	var contract: Resource = ContractLibrary.reef_run()
	var expected := 0
	for row in contract.rock_rows:
		expected += row[1].size()
	var hidden := 0
	var cliffs := 0
	var others := 0
	for rock in _level.get_tree().get_nodes_in_group("rocks"):
		if rock.hidden:
			hidden += 1
			assert_false(_seen(rock), "%s can't be seen" % rock.name)
		elif rock.kind == "cliff":
			cliffs += 1
			assert_true(_seen(rock))
			assert_gt(absf(rock.position.z), contract.coast_half_width, "cliffs line the channel")
		elif rock.kind != "barrel": # floating barrels are cannon targets, not route obstacles
			others += 1
			assert_true(_seen(rock), "%s (%s) is in plain sight" % [rock.name, rock.kind])
	assert_eq(others, contract.obstacles.size(), "the wreck, whale and atoll are on the route")
	assert_eq(hidden, expected)
	assert_gt(cliffs, 100)
	for mark in _level.get_tree().get_nodes_in_group("finish"):
		assert_almost_eq(mark.position.x, contract.length + _level._arrival.VILLAGE_OFFSET, 0.01, "the beach's waterline")


func _seen(rock: Node3D) -> bool:
	var model := rock.get_node_or_null("Model") as Node3D
	return model.visible if model else rock.get_node("Mesh").visible


func test_given_reef_run_then_calm_start_and_waves_later() -> void:
	var contract: Resource = ContractLibrary.reef_run()
	for row in contract.rock_rows:
		assert_gt(row[0], 200.0, "no rocks in the calm departure")
	assert_gte(contract.waves.size(), 2)
	for wave in contract.waves:
		assert_gt(wave[0], 300.0)


func test_given_port_out_of_range_then_chart_has_port_distance() -> void:
	var chart: Control = _level.get_node("HUD/MapChart")
	var mark: Vector2 = chart.chart_point(Vector3(chart.port_x, 0, 0))
	assert_gt(mark.length(), chart.size.x * 0.5, "port is beyond the chart rim, so the arrow shows")
	assert_almost_eq(chart.port_x, 1300.0, 0.01)


func test_given_voyage_running_then_deadline_shown_and_turns_red_when_late() -> void:
	var status: Label = _level.get_node("HUD/Status")
	assert_string_contains(status.text, "/ 6:15")
	_level.elapsed = 400.0
	await wait_physics_frames(2)
	var colour: Color = status.get_theme_color("font_color")
	assert_gt(colour.r, 0.9)
	assert_lt(colour.g, 0.6, "red when late")


func test_given_ship_sails_into_coast_then_crashes() -> void:
	var ship: Node3D = _level.get_node("Ship")
	var handling: Node = ship.get_node("ShipHandling")
	watch_signals(handling)
	ship.position = Vector3(100, ship.position.y, -40)
	ship.rotation.y = PI / 2.0 # bow toward port (-Z)
	handling.throttle = 1.0
	handling.speed = 4.0
	await wait_seconds(3.0)
	assert_signal_emitted(handling, "rock_hit")


func test_arriving_the_ship_slides_up_the_beach_then_the_results_show() -> void:
	assert_not_null(_level.get_node_or_null("Village"), "a pirate village instead of a harbour")
	var ship: Node3D = _level.get_node("Ship")
	ship.position.x = _level.finish_x + 0.5
	_level.get_node("Ship/ShipHandling").speed = 5.0
	await wait_physics_frames(3)
	assert_true(_level._arrival.beaching, "beaching")
	assert_false(_level.finished, "not over yet: still sliding up the sand")
	await wait_seconds(_level._arrival.beaching_seconds + 0.3)
	assert_true(_level.finished)
	assert_almost_eq(_level.get_node("Ship/ShipHandling").speed, 0.0, 0.2, "settled on the sand")
