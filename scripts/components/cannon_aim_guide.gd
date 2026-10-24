extends Node3D
## The cannon's aim guide (Olivier, 2026-10-24: "i want a aim thing that shows me where the cannon
## trajectory is"). While a human player is at the cannon: a dotted line on the water from the
## muzzle to where the ball will land, and a ring at the landing spot. It turns gold when the shot
## would hit something (a pirate ship, or anything breakable it passes over, since balls hit whatever
## they fly over). A child of the cannon; drawn in world space so it stays flat on the sea.

const DOTS := 16
const WHITE := Color(1.0, 1.0, 1.0, 0.85)
const ON_TARGET := Color(1.0, 0.78, 0.15, 0.95)

var cannon: Node3D
var on_target: Node3D = null ## what the current aim would hit, if anything

var _dots: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	name = "AimGuide"
	top_level = true
	cannon = get_parent()
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.no_depth_test = true
	_material.render_priority = 4 # above the sea, the wake and the streaks
	_material.albedo_color = WHITE
	var dot := SphereMesh.new()
	dot.radius = 0.32
	dot.height = 0.2
	dot.radial_segments = 10
	dot.rings = 3
	dot.material = _material
	for i in DOTS:
		var mesh := MeshInstance3D.new()
		mesh.mesh = dot
		add_child(mesh)
		_dots.append(mesh)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.4
	torus.outer_radius = 1.9
	torus.material = _material
	_ring.mesh = torus
	add_child(_ring)
	visible = false


func _process(_delta: float) -> void:
	visible = wanted()
	if not visible:
		on_target = null
		return
	var start: Vector3 = cannon.global_position + cannon._shot_direction() * 1.2
	var land: Vector3 = cannon.landing_point()
	start.y = 0.35
	land.y = 0.35
	on_target = target_along(start, land)
	_material.albedo_color = ON_TARGET if on_target else WHITE
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.15
	for i in DOTS:
		var t := float(i + 1) / float(DOTS + 1)
		_dots[i].global_position = start.lerp(land, t)
		_dots[i].scale = Vector3.ONE * (0.7 + t * 0.6)
	_ring.global_position = land
	_ring.scale = Vector3.ONE * pulse


## Only for a human at this cannon (AI gunners aim by themselves; their guides would just clutter).
func wanted() -> bool:
	var gunner: Node = cannon.occupant
	return gunner != null and not gunner.has_node("AICrew")


## The first thing a ball fired from start to land would hit, or null (same rules as cannon_projectile.gd).
func target_along(start: Vector3, land: Vector3) -> Node3D:
	var tree := get_tree()
	for i in 21:
		var point := start.lerp(land, i / 20.0)
		for enemy in tree.get_nodes_in_group("enemy_ships"):
			if enemy.has_method("contains") and enemy.contains(point):
				return enemy
		for obstacle in tree.get_nodes_in_group("rocks"):
			if obstacle.has_node("Breakable"):
				var gap := Vector2(obstacle.global_position.x - point.x, obstacle.global_position.z - point.z).length()
				if gap < obstacle.radius + (1.0 if i == 20 else 0.6):
					return obstacle
	return null
