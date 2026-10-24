extends MultiMeshInstance3D
## Speed you can see (Olivier, 2026-10-24, from his spec): a small pool of soft, irregular,
## translucent streaks lying on the water. They stay where they are on the sea, so as the ship
## moves they flow past it, opposite to its real velocity (the camera follows the ship). They fade
## in and stretch as the ship speeds up, line up with the direction of travel (correct when turning
## or going astern), and vanish when the ship stops: water never slides under a still ship.
## Streaks that fall out of view are moved back ahead of the ship: no new objects, one draw call.

@export var count := 48
@export var view_radius := 55.0 ## metres around the ship where streaks live
@export var max_alpha := 0.38 ## at full speed: subtle, never hiding the water's colour
@export var height := 0.25 ## just above the wave surface
@export var speed_for_full := 6.0 ## m/s at which the effect is at its strongest

var ship: Node3D
var velocity := Vector3.ZERO ## the ship's real, smoothed velocity
var strength := 0.0 ## 0 (still) .. 1 (fast)

var _spots: PackedVector3Array = PackedVector3Array()
var _sizes: PackedVector2Array = PackedVector2Array() ## per streak: base length, width
var _last := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "WaterStreaks"
	add_to_group("dev_tunable")
	set_meta("dev_group", "Speed streaks")
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rng.seed = 2026
	var quad := PlaneMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.material = _streak_material()
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = count
	_spots.resize(count)
	_sizes.resize(count)
	if ship:
		_last = ship.global_position
	for i in count:
		_spots[i] = _random_spot(Vector3.ZERO, true)
		_sizes[i] = Vector2(_rng.randf_range(2.5, 6.0), _rng.randf_range(0.3, 0.6))


func _physics_process(delta: float) -> void:
	if ship == null or delta <= 0.0:
		return
	var here := ship.global_position
	var moved := (here - _last) / delta
	_last = here
	moved.y = 0.0
	velocity = velocity.lerp(moved, minf(1.0, delta * 4.0)) # smooth: no sudden jumps
	var speed := velocity.length()
	strength = move_toward(strength, smoothstep(0.4, speed_for_full, speed), delta * 1.5)
	var direction := velocity.normalized() if speed > 0.05 else Vector3.RIGHT
	var yaw := atan2(-direction.z, direction.x)
	var stretch := 1.0 + strength * 1.6
	for i in count:
		var spot := _spots[i]
		var offset := spot - here
		offset.y = 0.0
		# Out of view (usually left behind): recycle it somewhere ahead.
		if offset.length() > view_radius:
			spot = _random_spot(direction, false)
			_spots[i] = spot
		var size := _sizes[i]
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3(size.x * stretch, 1.0, size.y))
		multimesh.set_instance_transform(i, Transform3D(basis, Vector3(spot.x, height, spot.z)))
		# Each streak twinkles a little on its own (no synchronised blinking).
		var flicker := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.0013 + i * 1.7)
		multimesh.set_instance_color(i, Color(1, 1, 1, max_alpha * strength * flicker))


## A spot on the water: anywhere around the ship at the start, else ahead in the direction of
## travel, never under the hull.
func _random_spot(direction: Vector3, anywhere: bool) -> Vector3:
	var centre := ship.global_position if ship else Vector3.ZERO
	for attempt in 6:
		var spot: Vector3
		if anywhere or direction == Vector3.ZERO:
			spot = centre + Vector3(_rng.randf_range(-view_radius, view_radius), 0.0, _rng.randf_range(-view_radius, view_radius)) * 0.7
		else:
			var side := Vector3(-direction.z, 0.0, direction.x)
			spot = centre + direction * _rng.randf_range(view_radius * 0.5, view_radius * 0.95) + side * _rng.randf_range(-view_radius * 0.8, view_radius * 0.8)
		if spot.distance_to(centre) > 12.0: # clear of the ship itself
			return spot
	return centre + Vector3(view_radius * 0.8, 0.0, 0.0)


## A soft, uneven streak: bright in the middle, fading to nothing at both ends and edges.
static func _streak_material() -> StandardMaterial3D:
	var image := Image.create(96, 24, false, Image.FORMAT_RGBA8)
	for x in 96:
		for y in 24:
			var along := sin(PI * x / 95.0)
			var across := 1.0 - absf(y - 11.5) / 12.0
			var wobble := 0.75 + 0.25 * sin(x * 0.35) * sin(x * 0.11 + 1.3)
			image.set_pixel(x, y, Color(1, 1, 1, clampf(along * across * across * wobble, 0.0, 1.0)))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.render_priority = 4 # drawn after the (see-through) sea
	return material
