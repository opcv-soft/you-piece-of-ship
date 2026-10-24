extends "res://scripts/components/station.gd"
## A cannon at the rail (Olivier, 2026-10-22: battles broadside to broadside). Bring a cannonball
## from the rack and press Use to load it; press Use empty-handed to take the cannon; steer the stick
## left/right to aim (along the ship); Jump fires. One ball per shot.

signal fired(ball: Node3D)

const Projectile = preload("res://scripts/components/cannon_projectile.gd")
const AimGuide = preload("res://scripts/components/cannon_aim_guide.gd")

@export var side := 1.0 ## +1 starboard, -1 port
@export var aim_limit_degrees := 35.0
@export var aim_speed := 1.4 ## aim units per second (aim goes -1..1)
@export var shot_range := 34.0 ## metres to where the ball lands
@export var flight_seconds := 1.1

var loaded := false
var aim := 0.0 ## -1 = toward the stern, +1 = toward the bow

var _barrel: Node3D
var _base: Node3D


func _ready() -> void:
	super._ready()
	add_to_group("cannons")
	station_name = "CANNON"
	prompt = "Use: aim   Jump: fire"
	radius = 1.1
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 2.1, side * 0.3)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	add_child(label)
	var ship := get_parent()
	if "art_style" in ship and ship.art_style == "painted":
		_base = ship.prop("cannon", "Carriage")
		_barrel = ship.prop("cannon_barrel", "Barrel")
		var pivot := Node3D.new()
		pivot.name = "BarrelPivot"
		pivot.position = Vector3(0, 0.65, 0.2)
		_barrel.position = -pivot.position
		pivot.add_child(_barrel)
		_base.add_child(pivot)
		_barrel = pivot
	else:
		_base = Node3D.new()
		_barrel = MeshInstance3D.new()
		var tube := CylinderMesh.new()
		tube.top_radius = 0.18
		tube.bottom_radius = 0.24
		tube.height = 1.4
		(_barrel as MeshInstance3D).mesh = tube
		_barrel.rotation.x = PI / 2.0
		_barrel.position = Vector3(0, 0.65, 0.3)
		_base.add_child(_barrel)
	_base.rotation.y = 0.0 if side > 0.0 else PI # model points +z (starboard)
	_base.position.z = side * 0.25
	add_child(_base)
	add_child(AimGuide.new())


func accepts_item(item: Node3D, _player: Node3D) -> bool:
	return item.kind == "ball" and not loaded


func receive_item(item: Node3D, player: Node3D) -> void:
	item.consume()
	loaded = true
	player.think(tr("Loaded!"), 1.0)
	UI.play("click")


func secondary_action(player: Node3D) -> void:
	fire(player)


## Where the ball lands for the current aim, in world space.
func landing_point() -> Vector3:
	return global_position + _shot_direction() * shot_range


func _shot_direction() -> Vector3:
	var out := global_basis.z * side
	var along := global_basis.x
	var angle := deg_to_rad(aim_limit_degrees) * aim
	var direction := (out * cos(angle) + along * sin(angle))
	direction.y = 0.0
	return direction.normalized()


func fire(player: Node3D = null) -> bool:
	if not loaded:
		if player:
			player.think(tr("Not loaded!"), 1.0)
		return false
	loaded = false
	var start := global_position + Vector3(0, 0.9, 0) + _shot_direction() * 1.2
	var ball := Projectile.new()
	ball.shooter = get_parent()
	var world: Node = get_tree().get_first_node_in_group("voyage")
	if world == null:
		world = get_tree().root
	world.add_child(ball)
	ball.launch(start, landing_point(), flight_seconds)
	_kick()
	load("res://scripts/systems/sfx.gd").play("cannon_fire", self, global_position)
	fired.emit(ball)
	return true


## Recoil, smoke and a camera jolt.
func _kick() -> void:
	var tween := _base.create_tween()
	var rest := _base.position
	tween.tween_property(_base, "position", rest - Vector3(0, 0, side * 0.35), 0.06)
	tween.tween_property(_base, "position", rest, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var puff := CPUParticles3D.new()
	puff.one_shot = true
	puff.amount = 18
	puff.lifetime = 1.0
	puff.explosiveness = 0.9
	var cloud := SphereMesh.new()
	cloud.radius = 0.3
	cloud.height = 0.6
	cloud.radial_segments = 6
	cloud.rings = 3
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.92, 0.92, 0.95, 0.8)
	grey.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grey.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cloud.material = grey
	puff.mesh = cloud
	puff.direction = _shot_direction()
	puff.spread = 25.0
	puff.initial_velocity_min = 2.0
	puff.initial_velocity_max = 4.0
	puff.gravity = Vector3(0, 0.6, 0)
	puff.position = to_local(global_position + Vector3(0, 0.9, 0) + _shot_direction() * 1.3)
	add_child(puff)
	puff.emitting = true
	get_tree().create_timer(1.5).timeout.connect(puff.queue_free)
	var camera := get_viewport().get_camera_3d()
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(0.25)
	UI.play("stamp")


func _physics_process(delta: float) -> void:
	var gunner: Node3D = occupant
	if gunner:
		aim = clampf(aim + gunner.move_input.x * side * aim_speed * delta, -1.0, 1.0)
	if _barrel:
		if _barrel.name == "BarrelPivot":
			_barrel.rotation.y = aim * deg_to_rad(aim_limit_degrees) * side
	status_text = tr("loaded") if loaded else ""


## Cannon labels only show in a fight, when loaded, or for someone standing at one.
func _label_wanted() -> bool:
	return loaded or not crew_nearby().is_empty() or not get_tree().get_nodes_in_group("enemy_ships").is_empty()
