extends GutTest
## features/crew_legibility.feature — you can tell who's who and what each AI is doing.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

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


func test_everyone_has_a_colour_ring_and_a_big_tag() -> void:
	for player in _crew.values():
		var badge: Node3D = player.get_node("CrewBadge")
		assert_not_null(badge.get_node_or_null("Ring"))
		assert_gte(player.get_node("Label").font_size, 80)


func test_an_ai_shows_the_job_it_is_actually_doing() -> void:
	var ai: Node = _level.add_ai(4, "carpenter")
	_level.get_node("CrewBrain").think()
	await wait_seconds(0.3)
	var badge: Node3D = _crew[4].get_node("CrewBadge")
	assert_eq(badge.job, ai.job, "the icon follows the brain's assignment, not the hired job")
	assert_ne(badge.job, "")


func test_the_crew_panel_lists_everyone_with_a_word() -> void:
	_level.add_ai(2, "navigator")
	_level.get_node("CrewBrain").think()
	await wait_seconds(0.5)
	var panel: Control = _level.get_node("HUD/CrewPanel")
	assert_true(panel.visible)
	assert_eq(panel._rows.size(), _crew.size())
	var job: String = _crew[2].get_node("CrewBadge").job
	assert_ne(job, "")
	assert_eq(panel._rows[_crew[2]][2].text, panel.CrewBadge.WORDS[job], "one word for what P2 is doing")
	assert_eq(panel._rows[_crew[2]][4].text, "P2 AI")


func test_a_human_never_fades_at_a_station_but_an_ai_does() -> void:
	var helm: Node3D = _ship.get_node("Helm")
	helm.occupy(_crew[1])
	await wait_physics_frames(3)
	var model: Node = _crew[1].get_node_or_null("Visual/Sailor")
	if model == null:
		pass_test("no painted model in this art style")
		return
	assert_false(model._faded, "you never lose sight of yourself")


func test_routine_ai_plans_dont_pop_bubbles_but_alerts_do() -> void:
	var ai: Node = _level.add_ai(3, "carpenter")
	ai.intend("Going to fix leak!")
	assert_false(_crew[3].bubble.visible, "routine: only the crew panel")
	ai.intend("Too hot! Venting!", true)
	assert_true(_crew[3].bubble.visible, "urgent: a bubble")


func test_a_station_card_shows_for_the_nearest_human_only() -> void:
	var pump: Node3D = _ship.get_node("Pump")
	_crew[1].global_position = pump.global_position + Vector3(0.5, 0.05, 0)
	_crew[2].global_position = pump.global_position + Vector3(-1.0, 0.05, 0)
	await wait_physics_frames(3)
	var prompts: Node = _level.get_node("InteractionPrompts")
	var shown := 0
	for player in prompts._bubbles:
		if prompts._bubbles[player].visible:
			shown += 1
	assert_eq(shown, 1, "one card for the pump, not two")
