extends Camera3D
## One shared couch camera. It stays level with the horizon (so you see the deck rock)
## and pulls back just enough to keep the whole ship and every crew member on screen
## (Social: one screen, one crew, nobody hunting for themselves).

@export var target_group := "camera_focus" ## crew members and the ship's corner markers
@export_range(20.0, 85.0) var view_pitch_degrees := 40.0 ## how steeply we look down (40: the sea looks good, the deck stays readable)
@export var margin := 2.5 ## metres of room around the outermost point
@export var look_ahead := 14.0 ## metres of sea kept in view beyond the bow, to see what's coming
@export_range(0.0, 0.5) var reserve_right := 0.0 ## share of the screen kept free on the right for the HUD (map chart)
@export var min_distance := 30.0
@export var max_distance := 45.0
@export var follow_speed := 4.0
@export var shake_max_offset := 0.8 ## metres the view jolts at full trauma
@export var shake_decay := 1.5 ## trauma lost per second

var trauma := 0.0 ## 0..1, raised by add_trauma(); the shake is trauma squared, so small hits stay subtle

var _anchor := Vector3.ZERO


func _ready() -> void:
	snap()


func _physics_process(delta: float) -> void:
	trauma = maxf(0.0, trauma - shake_decay * delta)
	_frame(1.0 - exp(-follow_speed * delta))


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Jump straight to the framing (used at start).
func snap() -> void:
	_frame(1.0)


func _frame(weight: float) -> void:
	var targets := get_tree().get_nodes_in_group(target_group)
	if targets.is_empty():
		return
	var lowest := Vector3.INF
	var highest := -Vector3.INF
	var points: Array[Vector3] = []
	for target in targets:
		points.append(target.global_position)
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	if ship and look_ahead > 0.0:
		var bow := ship.global_position + ship.global_basis.x * (14.5 + look_ahead)
		points.append(Vector3(bow.x, 0.0, bow.z))
	for point in points:
		lowest = lowest.min(point)
		highest = highest.max(point)
	var center := (lowest + highest) * 0.5
	var half_width := (highest.x - lowest.x) * 0.5 + margin
	var pitch := deg_to_rad(view_pitch_degrees)
	# Looking down at an angle, depth on the deck appears shorter on screen by sin(pitch).
	var half_height := (highest.z - lowest.z) * 0.5 * sin(pitch) + (highest.y - lowest.y) * 0.5 + margin
	var screen := get_viewport().get_visible_rect().size
	var aspect := screen.x / screen.y if screen.y > 0.0 else 16.0 / 9.0
	var tan_half_v := tan(deg_to_rad(fov) * 0.5) # fov is vertical
	var usable_aspect := aspect * (1.0 - reserve_right)
	var distance := maxf(half_height / tan_half_v, half_width / (tan_half_v * usable_aspect))
	distance = clampf(distance, min_distance, max_distance)
	var goal := center + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	_anchor = _anchor.lerp(goal, weight)
	global_position = _anchor + _shake_offset()
	rotation = Vector3(-pitch, 0.0, 0.0)
	# Slide the view right so the ship sits in the free part of the screen.
	h_offset = reserve_right * distance * tan_half_v * aspect


func _shake_offset() -> Vector3:
	if trauma <= 0.0:
		return Vector3.ZERO
	var jolt := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	return jolt * trauma * trauma * shake_max_offset
