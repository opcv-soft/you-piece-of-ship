extends GutTest
## features/resources.feature — what you break becomes gold, charcoal, planks, grease or a skewered siren.

const LevelScene = preload("res://scenes/levels/voyage.tscn")
const Projectile = preload("res://scripts/components/cannon_projectile.gd")

var _level: Node3D
var _ship: Node3D
var _stores: Node
var _village_before := {}


func before_each() -> void:
	_village_before = Session.village.duplicate()
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_ship = _level.get_node("Ship")
	_stores = _ship.get_node("ShipStores")
	await wait_physics_frames(2)


func after_each() -> void:
	Session.village = _village_before


func _collect_all() -> void:
	await wait_physics_frames(2)
	for salvage in get_tree().get_nodes_in_group("salvage"):
		salvage.land_all()


func test_barrels_give_gold_in_the_bucket() -> void:
	_level._spawn_ahead("barrel").take_hit()
	await _collect_all()
	assert_gt(_stores.counts.gold, 0)
	assert_true(_stores.get_node("GoldHeap").visible, "gold in the bucket at the bow")


func test_charcoal_rocks_feed_the_furnace_and_planks_fill_the_box() -> void:
	var engine := _ship.get_node("EngineSystem")
	engine.fuel = 0.2
	var rock: Node3D = _level._spawn_ahead("rock")
	for i in 3:
		rock.take_hit()
	await _collect_all()
	assert_gt(engine.fuel, 0.3, "charcoal went into the firebox")
	var planks: int = _ship.get_node("PlankBox").stock
	var wreck: Node3D = _level._spawn_ahead("wreck")
	for i in 4:
		wreck.take_hit()
	await _collect_all()
	assert_gt(_ship.get_node("PlankBox").stock, planks, "planks for repairs")


func test_the_siren_ends_up_on_the_bowsprit_and_whales_give_grease() -> void:
	var siren: Node3D = _level._spawn_ahead("siren")
	for i in 3:
		siren.take_hit()
	await _collect_all()
	assert_eq(_stores.counts.siren, 1)
	assert_not_null(_stores.get_node_or_null("Siren1"), "skewered on the bowsprit")
	var whale: Node3D = _level._spawn_ahead("whale")
	for i in 5:
		whale.take_hit()
	await _collect_all()
	assert_eq(_stores.counts.grease, 5, "a keg knocked off with every hit, and one when it breaks")


func test_debris_floats_then_swooshes_into_its_pile_by_itself() -> void:
	_level._spawn_ahead("barrel").take_hit()
	await wait_physics_frames(2)
	assert_eq(_stores.counts.gold, 0, "the pieces bob on the water first")
	await wait_seconds(3.0)
	assert_gt(_stores.counts.gold, 0, "then they fly into the bucket")
	assert_eq(get_tree().get_nodes_in_group("salvage").size(), 0)


func test_every_cannonball_hit_knocks_charcoal_aboard() -> void:
	var rock: Node3D = _level._spawn_ahead("rock")
	await wait_physics_frames(1)
	var ball := Projectile.new()
	_level.add_child(ball)
	ball.shooter = _ship
	ball.launch(_ship.global_position + Vector3(0, 1, 0), rock.global_position, 0.5)
	await wait_seconds(0.8)
	assert_true(rock.is_in_group("rocks"), "one hit doesn't break it")
	await _collect_all()
	assert_gt(_stores.counts.coal, 0, "but a lump of charcoal still comes aboard")


func test_even_a_gentle_bump_knocks_charcoal_aboard() -> void:
	var rock: Node3D = _level._spawn_ahead("rock")
	var handling: Node = _ship.get_node("ShipHandling")
	handling.speed = handling.max_speed * 0.15
	handling._hit(rock)
	assert_true(rock.is_in_group("rocks"))
	await _collect_all()
	assert_gt(_stores.counts.coal, 0)


func test_at_the_beach_the_haul_goes_to_the_village() -> void:
	_stores.add("gold", 3)
	_stores.add("coal", 2)
	var gold_before: int = Session.village.gold
	_ship.position.x = _level.finish_x + 0.5
	_level.get_node("Ship/ShipHandling").speed = 4.0
	await wait_seconds(_level._arrival.beaching_seconds + 3.0)
	assert_true(_level.finished)
	assert_eq(Session.village.gold, gold_before + 3, "the gold is in the village stockpile")
	assert_eq(_level.get_node("HUD/Results").outcome.haul.gold, 3)
