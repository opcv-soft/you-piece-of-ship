extends Control
## The chart on the map table. Heading-up: the top of the chart is wherever the bow points,
## so "rock at 2 o'clock" means the same thing to the navigator and the captain.
## Only shown while a crew member stands at the map table (Social: the navigator must call it out).

@export var station: Node3D ## the map table
@export var ship: Node3D
@export var range_metres := 70.0 ## about 12 s of warning at full speed
@export var port_x := 1300.0 ## where the port buoys are (set by the voyage)

const SEA := Color(0.07, 0.16, 0.3, 0.92)
const RING := Color(1, 1, 1, 0.15)
const ROCK := Color(0.75, 0.72, 0.68)
const SHIP := Color(1, 1, 1)
const FINISH := Color(1, 0.85, 0.2)


func _process(_delta: float) -> void:
	visible = station != null and station.has_human_reader()
	if visible:
		queue_redraw()


## Pixels per metre.
func chart_scale() -> float:
	return (minf(size.x, size.y) * 0.5 - 8.0) / range_metres


## Where a world position appears on the chart, relative to the chart centre (the ship).
func chart_point(world: Vector3) -> Vector2:
	var yaw := ship.rotation.y
	var fwd := Vector3(cos(yaw), 0.0, -sin(yaw))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var offset := world - ship.global_position
	return Vector2(offset.dot(right), -offset.dot(fwd)) * chart_scale()


## Chart positions of every rock within range.
func rock_marks() -> Array[Vector2]:
	var marks: Array[Vector2] = []
	var limit := minf(size.x, size.y) * 0.5 - 4.0
	for rock in get_tree().get_nodes_in_group("rocks"):
		var mark := chart_point(rock.global_position)
		if mark.length() < limit:
			marks.append(mark)
	return marks


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	var px := chart_scale()
	draw_circle(center, radius, SEA)
	for ring_metres in [20.0, 40.0, 60.0]:
		draw_arc(center, ring_metres * px, 0.0, TAU, 64, RING, 1.5)
	for buoy in get_tree().get_nodes_in_group("finish"):
		var mark := chart_point(buoy.global_position)
		if mark.length() < radius - 4.0:
			draw_circle(center + mark, 5.0, FINISH)
	for rock in get_tree().get_nodes_in_group("rocks"):
		var mark := chart_point(rock.global_position)
		if mark.length() < radius - 4.0:
			draw_obstacle(rock, center + mark, maxf(4.0, rock.radius * px))
	# The ship: a triangle pointing up (the bow), drawn to scale.
	var handling := ship.get_node("ShipHandling")
	var bow: float = handling.hull_half_length * px
	var beam: float = handling.hull_half_width * px
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -bow), center + Vector2(beam, bow),
			center + Vector2(-beam, bow)]), SHIP)
	_draw_port_arrow(center, radius)
	var names := PackedStringArray()
	for reader in station.readers():
		names.append("P%d" % reader.player_index)
	draw_string(ThemeDB.fallback_font, Vector2(0, -8), tr("CHART  read by ") + ", ".join(names),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(1, 1, 1))


## Each kind of obstacle has its own little icon, so the navigator can say what it is.
func draw_obstacle(rock: Node3D, at: Vector2, r: float) -> void:
	var kind: String = rock.kind if "kind" in rock else "rock"
	var ink := Color(0.05, 0.08, 0.15)
	match kind:
		"wreck":
			draw_circle(at, r, Color(0.62, 0.42, 0.26))
			draw_line(at + Vector2(-r * 0.3, r * 0.4), at + Vector2(r * 0.3, -r * 0.8), ink, 2.5)
			draw_line(at + Vector2(-r * 0.6, -r * 0.2), at + Vector2(r * 0.5, -r * 0.4), ink, 2.0)
		"whale":
			var tint := Color(0.45, 0.62, 0.95) if rock.is_solid() else Color(0.45, 0.62, 0.95, 0.35)
			draw_set_transform(at, 0.0, Vector2(1.6, 1.0))
			draw_circle(Vector2.ZERO, r * 0.7, tint)
			draw_set_transform(Vector2.ZERO)
			draw_colored_polygon(PackedVector2Array([at + Vector2(r * 1.1, 0), at + Vector2(r * 1.6, -r * 0.5),
					at + Vector2(r * 1.6, r * 0.5)]), tint)
			draw_circle(at + Vector2(-r * 0.6, -r * 0.15), maxf(1.5, r * 0.12), ink)
		"siren":
			draw_circle(at, r, Color(1.0, 0.55, 0.72))
			draw_string(ThemeDB.fallback_font, at + Vector2(-r, r * 0.45), "♪", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0,
					int(maxf(12.0, r * 1.5)), Color.WHITE)
		"atoll":
			draw_circle(at, r, Color(0.98, 0.86, 0.58))
			draw_circle(at, r * 0.65, Color(0.35, 0.8, 0.85))
			for i in 4:
				draw_circle(at + Vector2.from_angle(i * TAU / 4.0 + 0.4) * r * 0.82, maxf(2.0, r * 0.14), Color(0.3, 0.7, 0.3))
		_:
			draw_circle(at, r, ROCK)


## When the port is beyond the chart's range, an arrow on the rim points to it with the distance.
func _draw_port_arrow(center: Vector2, radius: float) -> void:
	if is_inf(port_x):
		return # Test Drive: no port anywhere
	var port := Vector3(port_x, 0.0, 0.0)
	var mark := chart_point(port)
	var distance := maxf(0.0, port_x - ship.global_position.x)
	if mark.length() < radius - 4.0 or distance <= 0.0:
		return
	var direction := mark.normalized()
	var tip := center + direction * (radius - 6.0)
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 22.0 + side * 11.0,
			tip - direction * 22.0 - side * 11.0]), FINISH)
	draw_string(ThemeDB.fallback_font, tip - direction * 50.0 - Vector2(40, -6), tr("PORT %d m") % roundi(distance),
			HORIZONTAL_ALIGNMENT_CENTER, 80, 15, FINISH)
