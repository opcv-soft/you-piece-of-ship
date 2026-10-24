extends GutTest
## features/speed_streaks.feature — water streaks show speed, follow real velocity, never slide under a still ship.

const LevelScene = preload("res://scenes/levels/voyage.tscn")

var _level: Node3D
var _streaks: Node
var _handling: Node


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	_streaks = _level.get_node("WaterStreaks")
	_handling = _level.get_node("Ship/ShipHandling")
	for player in get_tree().get_nodes_in_group("crew"):
		player.get_node("PlayerInput").enabled = false
	await wait_physics_frames(2)


func test_still_ship_shows_nothing_and_speed_brings_them_in() -> void:
	_handling.sail_speed = 0.0
	_handling.speed = 0.0
	await wait_seconds(1.5)
	assert_lt(_streaks.strength, 0.05, "a still ship: no streaks")
	_handling.speed = _handling.max_speed
	_handling.sail_speed = _handling.max_speed
	_handling.throttle = 1.0
	await wait_seconds(2.0)
	assert_gt(_streaks.strength, 0.5, "full speed: clearly visible")


func test_streaks_follow_the_real_velocity_and_are_recycled_not_created() -> void:
	_handling.speed = _handling.max_speed
	_handling.throttle = 1.0
	await wait_seconds(1.0)
	var fwd: Vector3 = _handling.forward()
	assert_gt(_streaks.velocity.normalized().dot(fwd), 0.9, "measured from the ship's actual motion")
	var count: int = _streaks.multimesh.instance_count
	await wait_seconds(3.0)
	assert_eq(_streaks.multimesh.instance_count, count, "a fixed pool, recycled")
	for i in count:
		assert_lt(_streaks.multimesh.get_instance_transform(i).origin.distance_to(_level.get_node("Ship").global_position), _streaks.view_radius + 1.0)
