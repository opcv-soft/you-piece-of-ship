extends Node3D
## A pirate ship that hunts you (Olivier, 2026-10-22). It comes alongside on one side and fires a
## broadside whenever it is level with you; it only ever attacks from the side, where your cannons
## are. Outrun it (it's a little slower than your full speed) or sink it with three hits for its planks.
## Broadsides are telegraphed (2026-10-25): it takes aim for `warning_seconds` first (gun ports open,
## red rings where the balls will land, see broadside_warning.gd), so the crew can sail out of the
## rings, step off them, or hit the pirates first to spoil the shot.

signal sunk(enemy: Node3D)
signal broadside ## the balls are away
signal took_aim ## it has started taking aim: the warning is up
signal spoiled ## one of our hits knocked it off its aim before it fired

const Projectile = preload("res://scripts/components/cannon_projectile.gd")
const Toon = preload("res://scripts/systems/toon.gd")
const Salvage = preload("res://scripts/components/salvage.gd")
const BroadsideWarning = preload("res://scripts/components/broadside_warning.gd")
const BALL_FLIGHT := 1.2 ## seconds a broadside ball is in the air
## The pirate's paint: plum hull stripes, dark sails, a black flag.
const TINTS := {"paint_teal": Color(0.45, 0.3, 0.55), "paint_red": Color(0.3, 0.2, 0.32), "trim_cream": Color(0.75, 0.7, 0.8),
		"flag": Color(0.12, 0.1, 0.14), "sail": Color(0.55, 0.5, 0.62), "wood_hull": Color(0.38, 0.26, 0.24)}

@export var side := -1.0 ## which side of the player it attacks from: -1 port, +1 starboard
@export var health := 3
@export var speed_share := 0.95 ## its top speed, as a share of yours: only flat-out sailing outruns it
@export var crew_count := 4
@export var stand_off := 19.0 ## metres between the hulls' centre lines when alongside
@export var reload_seconds := 9.0
@export var accuracy := 0.5 ## chance a broadside ball lands on the deck
@export var give_up_metres := 45.0 ## left this far behind, it gives up
@export var model_scale := 0.75
@export var balls_per_broadside := 1
@export var chase_seconds := 75.0 ## after this long they give up and sail off anyway
@export var warning_seconds := 2.0 ## how long they visibly take aim before the broadside
@export var spoiled_reload := 0.5 ## a hit while aiming: they reload this share of reload_seconds

var target: Node3D ## the player's ship
var alive := true
var reload_left := 3.0
var aiming := false
var _aim_left := 0.0
var _aim_points: Array[Vector3] = [] ## where this broadside's balls will come down (world)
var _warning: Node3D
var _speed := 0.0
var _sink := 0.0
var _rng := RandomNumberGenerator.new()
var _crew: Array[Node3D] = []
var _ram_cooldown := 0.0


func _ready() -> void:
	add_to_group("enemy_ships")
	add_to_group("obstacles")
	_rng.randomize()
	if target == null:
		target = get_tree().get_first_node_in_group("player_ship")
	var model: Node3D = (load("res://assets/art/export/models/ship.glb") as PackedScene).instantiate()
	model.name = "Model"
	Toon.paint(model, TINTS)
	model.scale = Vector3.ONE * model_scale
	add_child(model)
	var label := Label3D.new()
	label.name = "Label"
	label.text = tr("PIRATES!")
	label.position = Vector3(0, 9.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 96
	label.outline_size = 18
	label.modulate = Color(1.0, 0.45, 0.4)
	add_child(label)
	_add_crew()
	_warning = BroadsideWarning.new()
	add_child(_warning)
	_warning.build_ports(maxi(balls_per_broadside, 1), side, model_scale)


## Little pirate dolls in our crew style, clearly the bad guys: black tricorns or red bandanas,
## eyepatches, mean grey-purple coats. They hop and cheer, and fall over when the ship is hit.
func _add_crew() -> void:
	for i in crew_count:
		var pirate: Node3D = (load("res://assets/art/export/models/crew.glb") as PackedScene).instantiate()
		Toon.paint(pirate, {"player": Color(0.15, 0.13, 0.16) if i % 2 == 0 else Color(0.85, 0.15, 0.12)})
		for hat in ["tricorn", "bandana", "captain", "beanie", "straw", "crown"]:
			var node := pirate.find_child("Hat_" + hat, true, false)
			if node:
				node.visible = hat == ("tricorn" if i % 2 == 0 else "bandana")
		var head := pirate.find_child("Head", true, false) as Node3D
		if head:
			var patch := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 0.14
			disc.bottom_radius = 0.14
			disc.height = 0.04
			patch.mesh = disc
			patch.material_override = Toon.material("eye")
			patch.rotation.x = PI / 2.0
			patch.position = Vector3(0.21, 1.44, 0.53)
			head.add_child(patch)
		pirate.scale = Vector3.ONE * model_scale
		pirate.position = Vector3(-5.0 + i * 3.2, 0.0, (i % 2) * 1.6 - 0.8) * model_scale
		pirate.rotation.y = side * PI / 2.0 # facing the player's ship
		add_child(pirate)
		_crew.append(pirate)
		var cheer := pirate.create_tween().set_loops()
		cheer.tween_property(pirate, "position:y", 0.35 * model_scale, 0.25 + i * 0.05)
		cheer.tween_property(pirate, "position:y", 0.0, 0.25 + i * 0.05)
		cheer.tween_interval(0.4 + i * 0.2)


## Whether it's a danger right now (for the music, the AI gunners and the navigator).
func is_threat() -> bool:
	if not alive or target == null:
		return false
	return global_position.distance_to(target.global_position) < 55.0


## Whether a point (where a ball lands) is on this ship's deck.
func contains(point: Vector3) -> bool:
	var local := to_local(point)
	return absf(local.x - 1.2) < 9.5 * model_scale + 1.0 and absf(local.z) < 3.8 * model_scale + 1.0


## Where the balls of the broadside they're aiming will land (empty when not aiming).
func warning_points() -> Array[Vector3]:
	return _aim_points.duplicate()


func take_hit(point: Vector3) -> void:
	if not alive:
		return
	health -= 1
	if aiming:
		_stop_aiming()
		reload_left = reload_seconds * spoiled_reload # knocked off their aim: reload and try again
		spoiled.emit()
	_flash()
	load("res://scripts/systems/sfx.gd").play("wood_splinter", get_parent(), global_position)
	_crew_fall()
	if health <= 0:
		_sink_now()
	else:
		var chip := Salvage.new() # every hit knocks a plank loose, and it flies aboard
		chip.resource = "planks"
		chip.units = 1
		chip.pieces = 2
		get_parent().add_child(chip)
		chip.global_position = point * Vector3(1, 0, 1) if point != Vector3.ZERO else global_position * Vector3(1, 0, 1)


## The pirates fall over, then scramble back up.
func _crew_fall() -> void:
	for pirate in _crew:
		if not is_instance_valid(pirate):
			continue
		var fall := pirate.create_tween()
		fall.tween_property(pirate, "rotation:x", -PI / 2.0, 0.15)
		fall.tween_interval(_rng.randf_range(0.6, 1.2))
		fall.tween_property(pirate, "rotation:x", 0.0, 0.25)


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation:x", 0.12 * side, 0.08)
	tween.tween_property(self, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.2)
	UI.play("stamp")


func _stop_aiming() -> void:
	aiming = false
	_aim_points.clear()
	if _warning:
		_warning.clear()


func _sink_now() -> void:
	alive = false
	_stop_aiming()
	remove_from_group("enemy_ships")
	sunk.emit(self)
	UI.play("coin")
	var salvage := Salvage.new()
	salvage.resource = "planks" # a sunk pirate ship: its planks swoosh into our plank box
	salvage.units = 6
	get_parent().add_child(salvage)
	salvage.global_position = global_position * Vector3(1, 0, 1)


func _physics_process(delta: float) -> void:
	if not alive:
		_sink += delta
		position.y -= delta * 1.2
		rotation.z = minf(rotation.z + delta * 0.25, 0.5) * side
		if _sink > 6.0:
			queue_free()
		return
	if target == null:
		return
	var handling := target.get_node("ShipHandling")
	var fwd: Vector3 = handling.forward()
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var goal: Vector3 = target.global_position + right * side * stand_off
	goal.y = 0.0
	var offset := goal - global_position
	offset.y = 0.0
	var behind := (target.global_position - global_position).dot(fwd)
	if behind > give_up_metres:
		alive = false # gave up: sails away (sinks out of sight)
		_stop_aiming()
		remove_from_group("enemy_ships")
		return
	# Keep pace with the player (so a fight is possible), catching up a bit faster when behind;
	# only flat-out sailing leaves them behind (Olivier, 2026-10-24).
	var top: float = handling.max_speed * speed_share
	var pace: float = absf(handling.speed) + offset.length() * 0.6
	_speed = move_toward(_speed, clampf(pace, 0.0, top), 6.0 * delta)
	_collide(handling, fwd, right, delta)
	if offset.length() > 0.3:
		global_position += offset.normalized() * minf(_speed * delta, offset.length())
	rotation.y = lerp_angle(rotation.y, target.rotation.y, minf(1.0, delta * 1.5)) # sail parallel
	chase_seconds -= delta
	if chase_seconds <= 0.0:
		alive = false
		_stop_aiming()
		remove_from_group("enemy_ships")
		return
	if aiming:
		_aim_left -= delta
		if _aim_left <= 0.0:
			_fire_broadside(right)
		return
	reload_left -= delta
	var along := (global_position - target.global_position).dot(fwd)
	var across := absf((global_position - target.global_position).dot(right))
	if reload_left <= 0.0 and absf(along) < 9.0 and across < stand_off + 8.0:
		_take_aim(handling, fwd, right)


## Ships collide: ramming the player (both get hurt) and running onto rocks.
func _collide(handling: Node, fwd: Vector3, right: Vector3, delta: float) -> void:
	_ram_cooldown -= delta
	var offset := global_position - target.global_position
	var local := Vector2(offset.dot(fwd), offset.dot(right))
	if handling.touches_hull(local, 3.2 * model_scale + 0.5):
		var away := Vector3(offset.x, 0.0, offset.z).normalized()
		global_position += away * 4.0 * delta * 4.0 # shoved apart
		if _ram_cooldown <= 0.0:
			_ram_cooldown = 2.0
			take_hit(global_position)
			var voyage := get_tree().get_first_node_in_group("voyage")
			if voyage and voyage.has_method("cannon_hit"):
				voyage.cannon_hit(target.global_position - away * 3.0) # the player's hull cracks where they met
	for rock in get_tree().get_nodes_in_group("rocks"):
		var gap := Vector2(rock.global_position.x - global_position.x, rock.global_position.z - global_position.z)
		if gap.length() < rock.radius + 3.0 * model_scale:
			var push := -Vector3(gap.x, 0.0, gap.y).normalized()
			global_position += push * 6.0 * delta
			if _ram_cooldown <= 0.0:
				_ram_cooldown = 1.5
				take_hit(global_position)
				if rock.has_method("take_hit"):
					rock.take_hit(rock.global_position)


## They take aim: pick where each ball will land, leading our ship by where it will be when the
## balls come down (if it holds speed and course), and put up the warning. The spots are fixed on
## the sea from now on, so changing speed or course is how the helm dodges.
func _take_aim(handling: Node, fwd: Vector3, right: Vector3) -> void:
	aiming = true
	_aim_left = warning_seconds
	var lead: Vector3 = fwd * handling.speed * (warning_seconds + BALL_FLIGHT)
	_aim_points.clear()
	for i in balls_per_broadside:
		var aim_at: Vector3 = target.global_position + lead + fwd * _rng.randf_range(-6.0, 7.0)
		if _rng.randf() > accuracy:
			aim_at -= right * side * _rng.randf_range(6.0, 9.0) # falls short, in the water between the ships
		aim_at.y = 1.2
		_aim_points.append(aim_at)
	_warning.show_warning(_aim_points, warning_seconds)
	load("res://scripts/systems/sfx.gd").play("fuse_hiss", get_parent(), global_position, -4.0)
	took_aim.emit()


## The broadside: one ball into each ring.
func _fire_broadside(right: Vector3) -> void:
	reload_left = reload_seconds
	var points := _aim_points.duplicate()
	_stop_aiming()
	load("res://scripts/systems/sfx.gd").play("cannon_fire", get_parent(), global_position, -2.0)
	var fwd := Vector3(right.z, 0.0, -right.x)
	for i in points.size():
		var ball := Projectile.new()
		ball.shooter = self
		ball.add_to_group("enemy_cannonballs")
		get_parent().add_child(ball)
		var muzzle := global_position + Vector3(0, 1.4, 0) - right * side * 3.0 + fwd * (i * 3.0 - 1.5)
		ball.launch(muzzle, points[i], BALL_FLIGHT + i * 0.15)
	broadside.emit()
