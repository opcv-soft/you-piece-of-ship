extends GutTest
## features/sfx.feature — things make noise when they break; the engine hums with speed.

const LevelScene = preload("res://scenes/levels/voyage.tscn")

var _level: Node3D


func before_each() -> void:
	_level = LevelScene.instantiate()
	add_child_autofree(_level)
	await wait_physics_frames(2)


func test_breaking_a_barrel_plays_a_sound_on_the_sfx_bus() -> void:
	var barrel: Node3D = _level._spawn_ahead("barrel")
	barrel.take_hit()
	await wait_physics_frames(1)
	var players := get_tree().root.find_children("*", "AudioStreamPlayer3D", true, false).filter(
			func(p): return p.bus == &"SFX" and p.stream and p.stream.resource_path.ends_with("barrel_burst.wav"))
	assert_gt(players.size(), 0, "a barrel burst sound")


func test_the_engine_hums_higher_at_speed() -> void:
	var sound := _level.get_node("Ship/EngineSound")
	var handling := _level.get_node("Ship/ShipHandling")
	handling.throttle = 1.0
	handling.speed = handling.max_speed * 0.2
	await wait_seconds(1.0)
	var slow: float = sound._hum.pitch_scale
	assert_true(sound._hum.playing, "humming")
	handling.speed = handling.max_speed
	await wait_seconds(1.5)
	assert_gt(sound._hum.pitch_scale, slow + 0.2, "higher pitch at speed")
