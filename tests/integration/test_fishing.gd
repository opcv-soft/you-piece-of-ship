extends GutTest
## features/fishing.feature — idle crew fish at the rail; catches add to the score.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var _level: Node3D
var _ship: Node3D
var _crew: Dictionary = {}


func before_each() -> void:
	Session.ai_crew = {}
	_level = LevelScene.instantiate()
	_level.contract = ContractLibrary.reef_run()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_crew.clear()
	for player in _level.get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
		_crew[player.player_index] = player
	await wait_physics_frames(2)


func test_two_fishing_spots_on_the_rail() -> void:
	var spots := _level.get_tree().get_nodes_in_group("fishing_spots")
	assert_eq(spots.size(), 2)


func test_strike_on_a_bite_catches_a_fish_and_scores() -> void:
	var spot: Node3D = _ship.get_node("FishingSpot1")
	var fisher: Node3D = _crew[1]
	fisher.position = spot.position
	await wait_physics_frames(2)
	assert_true(spot.occupy(fisher))
	assert_eq(spot.phase, spot.Phase.WAITING, "the line is cast")
	watch_signals(spot)
	spot.strike(fisher)
	assert_signal_emitted(spot, "got_away", "too early scares the fish")
	assert_eq(_level.bonus_points, 0)
	spot.nibble_chance = 0.0
	spot.wait_left = 0.0
	await wait_physics_frames(2)
	assert_eq(spot.phase, spot.Phase.BITE)
	fisher.jump_requested = true
	await wait_physics_frames(2)
	assert_signal_emitted(spot, "caught")
	assert_gt(_level.bonus_points, 0, "the catch adds points")


func test_catches_add_to_the_final_score() -> void:
	_level.bonus_points = 120
	_level.dev_event("reach_port")
	await wait_physics_frames(3)
	var score: Dictionary = _level.get_node("HUD/Results").outcome.score
	assert_eq(score.bonus, 120)
	assert_eq(score.total, score.cargo + score.hull + score.time + 120)


func test_an_idle_ai_goes_fishing_when_all_is_calm_and_stops_for_a_leak() -> void:
	# A full crew: humans at the helm and the engine, an AI navigator, and an AI carpenter with nothing to fix.
	_ship.get_node("Helm").occupy(_crew[1])
	_ship.get_node("Engine").occupy(_crew[2])
	_level.add_ai(4, "navigator", "")
	_level.add_ai(3, "carpenter", "")
	await wait_seconds(6.0)
	assert_true(_crew[3].station != null and _crew[3].station.is_in_group("fishing_spots"), "gone fishing")
	_ship.get_node("HullSystem").add_breach(Vector3(-1.8, 0, 2.3))
	await wait_seconds(1.0)
	assert_false(_crew[3].station != null and _crew[3].station.is_in_group("fishing_spots"), "reels in for the leak")


func test_the_catch_is_reeled_onto_the_deck_and_stays_there() -> void:
	var spot: Node3D = _ship.get_node("FishingSpot1")
	var fisher: Node3D = _crew[1]
	fisher.position = spot.position
	await wait_physics_frames(2)
	spot.occupy(fisher)
	spot.roll_catch() # warm the dice
	spot.phase = spot.Phase.BITE
	spot.bite_left = 1.0
	spot._rng.seed = 1 # a sardine, not the rare treasure
	spot.strike(fisher)
	assert_eq(spot.phase, spot.Phase.REELING, "reeling it in")
	await wait_seconds(spot.reel_seconds + 0.3)
	var fish := get_tree().get_nodes_in_group("items").filter(func(i): return i.kind == "fish")
	assert_eq(fish.size(), 1, "the fish is on the deck")
	assert_true(_ship.is_ancestor_of(fish[0]))
	assert_eq(spot.phase, spot.Phase.WAITING, "and the line is cast again")
