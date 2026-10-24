extends Node3D
## A pirate ship that hunts you (Olivier, 2026-10-22). It comes alongside on one side and fires a
## broadside whenever it is level with you; it only ever attacks from the side, where your cannons
## are. Outrun it (it's a little slower than your full speed) or sink it with three hits for loot.

signal sunk(enemy: Node3D)
signal broadside

const Projectile = preload("res://scripts/components/cannon_projectile.gd")
const Toon = preload("res://scripts/systems/toon.gd")
const LootScene = preload("res://scripts/components/loot.gd")
## The pirate's paint: plum hull stripes, dark sails, a black flag.
const TINTS := {"paint_teal": Color(0.45, 0.3, 0.55), "paint_red": Color(0.3, 0.2, 0.32), "trim_cream": Color(0.75, 0.7, 0.8),
		"flag": Color(0.12, 0.1, 0.14), "sail": Color(0.55, 0.5, 0.62), "wood_hull": Color(0.38, 0.26, 0.24)}

@export var side := -1.0 ## which side of the player it attacks from: -1 port, +1 starboard
@export var health := 3
@export var speed_share := 0.8 ## of the player's top speed: full throttle outruns it
@export var stand_off := 19.0 ## metres between the hulls' centre lines when alongside
@export var reload_seconds := 9.0
@export var accuracy := 0.5 ## chance a broadside ball lands on the deck
@export var give_up_metres := 45.0 ## left this far behind, it gives up
@export var model_scale := 0.75
@export var balls_per_broadside := 1
@export var chase_seconds := 75.0 ## after this long they give up and sail off anyway

var target: Node3D ## the player's ship
var alive := true
var reload_left := 3.0
var _speed := 0.0
var _sink := 0.0
var _rng := RandomNumberGenerator.new()


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


## Whether it's a danger right now (for the music, the AI gunners and the navigator).
func is_threat() -> bool:
	if not alive or target == null:
		return false
	return global_position.distance_to(target.global_position) < 55.0


## Whether a point (where a ball lands) is on this ship's deck.
func contains(point: Vector3) -> bool:
	var local := to_local(point)
	return absf(local.x - 1.2) < 9.5 * model_scale + 1.0 and absf(local.z) < 3.8 * model_scale + 1.0


func take_hit(_point: Vector3) -> void:
	if not alive:
		return
	health -= 1
	_flash()
	if health <= 0:
		_sink_now()


func _flash() -> void:
	var tween := create_tween()
	tween.tween_property(self, "rotation:x", 0.12 * side, 0.08)
	tween.tween_property(self, "rotation:x", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.2)
	UI.play("stamp")


func _sink_now() -> void:
	alive = false
	remove_from_group("enemy_ships")
	sunk.emit(self)
	UI.play("coin")
	for i in 3:
		var loot := LootScene.new()
		loot.value = 60
		get_parent().add_child(loot)
		loot.global_position = global_position + Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-4, 4))


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
		remove_from_group("enemy_ships")
		return
	var top: float = handling.max_speed * speed_share
	_speed = move_toward(_speed, clampf(offset.length() * 0.6, 0.0, top), 4.0 * delta)
	if offset.length() > 0.3:
		global_position += offset.normalized() * minf(_speed * delta, offset.length())
	rotation.y = lerp_angle(rotation.y, target.rotation.y, minf(1.0, delta * 1.5)) # sail parallel
	chase_seconds -= delta
	if chase_seconds <= 0.0:
		alive = false
		remove_from_group("enemy_ships")
		return
	reload_left -= delta
	var along := (global_position - target.global_position).dot(fwd)
	var across := absf((global_position - target.global_position).dot(right))
	if reload_left <= 0.0 and absf(along) < 9.0 and across < stand_off + 8.0:
		_fire_broadside(right)


## Two balls at the player's side; each lands on the deck or in the sea next to it.
func _fire_broadside(right: Vector3) -> void:
	reload_left = reload_seconds
	broadside.emit()
	for i in balls_per_broadside:
		var aim_at: Vector3 = target.global_position + target.global_basis.x * _rng.randf_range(-6.0, 7.0)
		if _rng.randf() > accuracy:
			aim_at -= right * side * _rng.randf_range(6.0, 9.0) # falls short, in the water between the ships
		aim_at.y = 1.2
		var ball := Projectile.new()
		ball.shooter = self
		get_parent().add_child(ball)
		var muzzle := global_position + Vector3(0, 1.4, 0) - right * side * 3.0 + target.global_basis.x * (i * 3.0 - 1.5)
		ball.launch(muzzle, aim_at, 1.2 + i * 0.15)
