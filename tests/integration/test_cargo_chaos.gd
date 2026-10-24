extends GutTest
## features/cargo_chaos.feature — chests strain, snap loose, burst open; gold washes overboard.

const LevelScene = preload("res://scenes/levels/voyage.tscn")

var _level: Node3D
var _ship: Node3D
var _chaos: Node


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_ship.get_node("WaveMotion").intensity = 0.0
	_chaos = _ship.get_node("CargoChaos")
	for player in get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func _chests() -> Array:
	return get_tree().get_nodes_in_group("cargo").filter(func(c): return _ship.is_ancestor_of(c))


func test_hard_lurches_snap_ropes_and_chests_slide() -> void:
	seed(3)
	for i in 6:
		_ship.lurch(Vector2(6.0, 0.0))
	var loose := _chests().filter(func(c): return not c.lashed)
	assert_gt(loose.size(), 0, "some chests broke loose")
	assert_gt(loose[0].velocity.length(), 1.0, "and keep sliding")


func test_a_burst_chest_spills_gold_that_still_counts_until_lost() -> void:
	var chest: Node3D = _chests()[0]
	get_tree().get_first_node_in_group("cargo_bay").unlash(chest)
	var before: int = _ship.get_node("LoadSystem").cargo_value()
	watch_signals(_chaos)
	_chaos.burst(chest)
	assert_signal_emitted(_chaos, "chest_burst")
	await wait_physics_frames(2)
	var gold := get_tree().get_nodes_in_group("gold")
	assert_eq(gold.size(), _chaos.gold_pieces, "gold on the deck")
	assert_almost_eq(_ship.get_node("LoadSystem").cargo_value(), before, _chaos.gold_pieces, "still aboard: still counts")
	for piece in gold:
		piece.position = Vector3(0.0, 0.0, _ship.deck_width * 0.5 - 0.4) # against the rail
	seed(1)
	for i in 8:
		_chaos._sweep_edges(1.0)
	await wait_physics_frames(2)
	assert_eq(get_tree().get_nodes_in_group("gold").size(), 0, "washed overboard")
	assert_lt(_ship.get_node("LoadSystem").cargo_value(), before, "value lost")


func test_carrying_gold_back_to_a_chest_puts_it_back() -> void:
	var chest: Node3D = _chests()[0]
	_chaos.burst(chest)
	var value_after_burst: int = chest.value
	var gold: Node3D = get_tree().get_nodes_in_group("gold")[0]
	var sailor: Node3D = get_tree().get_nodes_in_group("crew")[0]
	sailor.position = chest.position + Vector3(0.8, 0.05, 0)
	await wait_physics_frames(2)
	gold.pick_up(sailor)
	assert_true(sailor.interact_with(chest))
	assert_eq(chest.value, value_after_burst + gold.value)
