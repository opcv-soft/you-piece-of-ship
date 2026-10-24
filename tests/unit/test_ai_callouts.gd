extends GutTest
## features/ai_crew.feature — the navigator's clock bearings

const AICrew = preload("res://scripts/ai/ai_crew.gd")


func test_clock_hours() -> void:
	assert_eq(AICrew.clock_hour(40.0, 0.0), 12, "dead ahead")
	assert_eq(AICrew.clock_hour(0.0, 30.0), 3, "starboard beam")
	assert_eq(AICrew.clock_hour(0.0, -30.0), 9, "port beam")
	assert_eq(AICrew.clock_hour(35.0, 20.0), 1, "a little to starboard")
	assert_eq(AICrew.clock_hour(20.0, 35.0), 2)



func test_nautical_bearings_and_distances() -> void:
	assert_eq(AICrew.nautical_bearing(40.0, 1.0), "dead ahead")
	assert_eq(AICrew.nautical_bearing(30.0, 20.0), "off the starboard bow")
	assert_eq(AICrew.nautical_bearing(0.0, -30.0), "on the port beam")
	assert_eq(AICrew.nautical_bearing(-20.0, 10.0), "off the starboard quarter")
	assert_eq(AICrew.nautical_bearing(-40.0, 0.0), "dead astern")
	assert_eq(AICrew.nautical_distance(11.0), "half a length")
	assert_eq(AICrew.nautical_distance(30.0), "1 length")
	assert_eq(AICrew.nautical_distance(80.0), "3 lengths")
	assert_eq(AICrew.nautical_distance(370.4), "2.0 cables")
