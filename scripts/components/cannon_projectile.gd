extends Node3D
## A cannonball in flight: a high arc from the muzzle to where it lands. On landing it hits the enemy
## ship (or the player's ship, for enemy shots) if it's there, otherwise it splashes.

signal landed(at: Vector3, hit: Node3D)

const Toon = preload("res://scripts/systems/toon.gd")

var shooter: Node3D ## who fired: never hits itself
var start := Vector3.ZERO
var target := Vector3.ZERO
var seconds := 1.0
var _age := 0.0


func launch(from: Vector3, to: Vector3, flight: float) -> void:
	start = from
	target = to
	seconds = flight
	global_position = from
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	ball.mesh = sphere
	ball.material_override = Toon.material("iron")
	add_child(ball)


func _physics_process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / seconds, 0.0, 1.0)
	var flat := start.lerp(target, t)
	global_position = flat + Vector3(0, sin(t * PI) * 5.0 * (1.0 - t * 0.3), 0)
	if t >= 1.0:
		_land()


func _land() -> void:
	var hit: Node3D = null
	for obstacle in get_tree().get_nodes_in_group("rocks"):
		if obstacle.has_method("take_hit") and obstacle.has_node("Breakable"):
			var gap := Vector2(obstacle.global_position.x - target.x, obstacle.global_position.z - target.z).length()
			if gap < obstacle.radius + 1.0:
				obstacle.take_hit(target)
				landed.emit(target, obstacle)
				queue_free()
				return
	for enemy in get_tree().get_nodes_in_group("enemy_ships"):
		if enemy != shooter and enemy.has_method("contains") and enemy.contains(target):
			hit = enemy
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	if hit == null and ship and ship != shooter and _on_ship(ship, target):
		hit = ship
	if hit and hit.has_method("take_hit"):
		hit.take_hit(target)
	elif hit == ship and ship:
		var voyage := get_tree().get_first_node_in_group("voyage")
		if voyage and voyage.has_method("cannon_hit"):
			voyage.cannon_hit(target)
	else:
		_splash()
	landed.emit(target, hit)
	queue_free()


static func _on_ship(ship: Node3D, point: Vector3) -> bool:
	var local := ship.to_local(point)
	return absf(local.x - 1.6) < 11.0 and absf(local.z) < 4.2


func _splash() -> void:
	var splash := CPUParticles3D.new()
	splash.one_shot = true
	splash.amount = 24
	splash.lifetime = 0.9
	splash.explosiveness = 0.95
	var drop := SphereMesh.new()
	drop.radius = 0.18
	drop.height = 0.36
	drop.radial_segments = 6
	drop.rings = 3
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.85, 0.95, 1.0, 0.9)
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = white
	splash.mesh = drop
	splash.direction = Vector3.UP
	splash.spread = 25.0
	splash.initial_velocity_min = 4.0
	splash.initial_velocity_max = 7.0
	splash.gravity = Vector3(0, -12, 0)
	var parent := get_parent()
	parent.add_child(splash)
	splash.global_position = Vector3(target.x, 0.1, target.z)
	splash.emitting = true
	parent.get_tree().create_timer(1.2).timeout.connect(splash.queue_free)
