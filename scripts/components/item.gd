extends Node3D
## Something a crew member can carry: a plank, a rudder pin or a cargo crate.
## Carried above the head; dropped on Use or when knocked down. Loose items slide to the
## low side of the deck (deck comedy rule, DESIGN.md section 13). Lashed crates stay put.
## Lives under the ship's Items node, so its position is in ship space.

const PixelArt = preload("res://scripts/systems/pixel_art.gd")

signal picked_up(player: Node3D)
signal dropped(player: Node3D)

const KINDS := {
	"plank": {"size": Vector3(1.2, 0.12, 0.35), "color": Color(0.82, 0.62, 0.38), "carry_speed": 0.85, "name": "plank"},
	"pin": {"size": Vector3(0.9, 0.22, 0.22), "color": Color(0.6, 0.62, 0.66), "carry_speed": 0.5, "name": "rudder pin"},
	"crate": {"size": Vector3(0.8, 0.8, 0.8), "color": Color(0.78, 0.45, 0.2), "carry_speed": 0.6, "name": "cargo crate"},
	"coal": {"size": Vector3(0.9, 0.15, 0.35), "color": Color(0.12, 0.12, 0.13), "carry_speed": 0.9, "name": "shovel of coal"},
	"ball": {"size": Vector3(0.4, 0.4, 0.4), "color": Color(0.2, 0.2, 0.24), "carry_speed": 0.7, "name": "cannonball"},
	"fish": {"size": Vector3(0.7, 0.3, 0.3), "color": Color(0.6, 0.65, 0.7), "carry_speed": 0.9, "name": "fish"},
}
## How each kind moves loose on the deck: [static friction, damping]. Cannonballs roll and roll;
## fish flop about; crates (treasure chests) are heavy.
const MOTION := {"ball": [0.01, 0.35], "fish": [0.05, 1.6], "crate": [0.09, 1.2]}
## Things heavy and fast enough to knock a sailor over when they slide into them.
const KNOCKERS := ["crate", "ball"]

@export_enum("plank", "pin", "crate", "coal", "ball", "fish") var kind := "plank"
@export var species := "fish_sardine" ## fish only: which model
@export var value := 0 ## score value delivered to port (cargo crates)
@export var static_friction := 0.09 ## deck tilt (as gravity fraction) needed before it starts sliding
@export var slide_damping := 1.2
@export var knock_speed := 1.6 ## a crate sliding faster than this knocks crew over

static var _next_net_id := 1

var net_id := 0 ## identity for online play (the host numbers every item it creates)
var carrier: Node3D = null
var lashed := false
var amount := 1.0 ## coal: how full the shovel is (a hit spills some)
var wetness := 0.0 ## coal: soaked coal burns worse
var velocity := Vector2.ZERO ## ship-local x/z metres per second while sliding
var ship: Node3D

var carry_speed: float:
	get:
		return KINDS[kind].carry_speed
var display_name: String:
	get:
		return KINDS[kind].name


func _ready() -> void:
	if net_id == 0:
		net_id = _next_net_id
		_next_net_id += 1
	add_to_group("items")
	add_to_group("interactables")
	if kind == "crate":
		add_to_group("cargo")
	if MOTION.has(kind):
		static_friction = MOTION[kind][0]
		slide_damping = MOTION[kind][1]
	ship = _find_ship()
	if ship and "art_style" in ship and ship.art_style == "painted":
		# Painted props: a treasure chest, a plank, the rudder pin, a shovel of coal.
		var model: Node3D = ship.prop({"crate": "chest", "plank": "plank", "pin": "pin", "coal": "shovel",
				"ball": "cannonball", "fish": species}[kind], "Mesh")
		if kind == "fish":
			model.scale = Vector3.ONE * 1.4
		add_child(model)
		return
	if ship and "pixel_art" in ship and ship.pixel_art and not kind in ["ball", "fish"]:
		# Pixel-art sprite: a crate, a plank or the iron pin (sizes match the grey boxes).
		var sizes := {"crate": 0.06, "plank": 0.06, "pin": 0.045, "coal": 0.05}
		var sprite := PixelArt.make_sprite(PixelArt.texture("shovel_coal" if kind == "coal" else kind), sizes[kind])
		sprite.name = "Mesh"
		add_child(sprite)
		return
	var mesh := BoxMesh.new()
	mesh.size = KINDS[kind].size
	var material := StandardMaterial3D.new()
	material.albedo_color = KINDS[kind].color
	mesh.material = material
	var body := MeshInstance3D.new()
	body.name = "Mesh"
	body.mesh = mesh
	body.position.y = mesh.size.y * 0.5
	add_child(body)


func _find_ship() -> Node3D:
	var node := get_parent()
	while node and not node.has_method("local_gravity"):
		node = node.get_parent()
	return node as Node3D


func half_extent() -> float:
	var size: Vector3 = KINDS[kind].size
	return maxf(size.x, size.z) * 0.5


# --- Interaction ---------------------------------------------------------------

func distance_to_player(player: Node3D) -> float:
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length()


func can_interact(player: Node3D) -> bool:
	return carrier == null and player.carried == null and distance_to_player(player) <= 1.3


func interact(player: Node3D) -> void:
	pick_up(player)


func pick_up(player: Node3D) -> void:
	if lashed:
		var bay := get_tree().get_first_node_in_group("cargo_bay")
		if bay:
			bay.unlash(self)
	lashed = false
	carrier = player
	player.carried = self
	velocity = Vector2.ZERO
	picked_up.emit(player)


## Puts the item down at the carrier's feet, optionally flung (ship-local metres per second).
## A shovel of coal can't be put down: dropping it spills the coal on the deck.
func drop(fling := Vector2.ZERO) -> void:
	if carrier == null:
		return
	if kind == "coal":
		spill(1.0)
		return
	var player := carrier
	carrier = null
	player.carried = null
	var feet := ship.to_local(player.global_position) if ship else player.position
	position = Vector3(feet.x, 0.0, feet.z)
	rotation = Vector3.ZERO
	velocity = fling
	dropped.emit(player)


## Spills part of a shovel of coal (a hit while carrying it), leaving a black mark on the deck.
## Spilling it all uses the shovel up.
func spill(share: float) -> void:
	if kind != "coal":
		return
	var where := carrier.global_position if carrier else global_position
	amount *= 1.0 - share
	if ship and ship.has_method("add_coal_mark"):
		ship.add_coal_mark(ship.to_local(where), share)
	if amount < 0.05:
		consume()


## Takes the item out of the game (used up as a patch, thrown overboard...).
func consume() -> void:
	if carrier:
		carrier.carried = null
		carrier = null
	remove_from_group("interactables")
	remove_from_group("cargo")
	queue_free()


# --- Motion --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if carrier:
		global_position = carrier.global_position + carrier.global_basis.y.normalized() * _carry_height()
		global_rotation = Vector3(carrier.global_rotation.x, carrier.global_rotation.y, carrier.global_rotation.z)
		return
	if lashed or ship == null:
		return
	slide(delta)


## Held overhead: above the grey-box capsule, or above the (taller) pixel pirate's head.
func _carry_height() -> float:
	if get_node_or_null("Mesh") is Sprite3D:
		return 2.75
	return 2.15 if ship and "art_style" in ship and ship.art_style == "painted" else 1.75


func _process(_delta: float) -> void:
	var sprite := get_node_or_null("Mesh") as Sprite3D
	if sprite:
		# While carried, draw over the carrier's sprite so everyone sees what they hold.
		sprite.no_depth_test = carrier != null
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED if carrier else SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.render_priority = 0


func slide(delta: float) -> void:
	var gravity: Vector3 = ship.local_gravity()
	var downhill := Vector2(gravity.x, gravity.z)
	# Static friction: a small tilt doesn't move a resting item.
	if velocity.length() > 0.05 or downhill.length() > static_friction * 9.8:
		velocity += downhill * delta
	velocity -= velocity * minf(slide_damping * delta, 1.0)
	var next := Vector2(position.x, position.z) + velocity * delta
	var limit_x: float = ship.deck_length * 0.5 - 0.2 - half_extent()
	var limit_z: float = ship.deck_width * 0.5 - 0.2 - half_extent()
	if absf(next.x) > limit_x:
		next.x = clampf(next.x, -limit_x, limit_x)
		velocity.x = 0.0
	if absf(next.y) > limit_z:
		next.y = clampf(next.y, -limit_z, limit_z)
		velocity.y = 0.0
	position = Vector3(next.x, 0.0, next.y)
	if KNOCKERS.has(kind) and velocity.length() > knock_speed:
		for player in get_tree().get_nodes_in_group("crew"):
			if distance_to_player(player) < 0.75:
				player.knock_down(velocity.normalized())
	_animate_loose(delta)


## A sudden lurch of the ship (a crash, a wave, a cannonball): loose things keep going.
## push is in ship-local x/z metres per second.
func jolt(push: Vector2) -> void:
	if carrier or lashed:
		return
	velocity += push * (1.4 if kind == "ball" else 1.0)


var _flop := 0.0


## Cannonballs roll as they slide; fish flop about now and then.
func _animate_loose(delta: float) -> void:
	var mesh := get_node_or_null("Mesh") as Node3D
	if mesh == null:
		return
	if kind == "ball":
		mesh.rotation.z -= velocity.x * delta / 0.2
		mesh.rotation.x += velocity.y * delta / 0.2
	elif kind == "fish":
		_flop -= delta
		if _flop <= 0.0:
			_flop = randf_range(0.6, 1.8)
			velocity += Vector2(randf_range(-1.2, 1.2), randf_range(-1.2, 1.2))
			var hop := create_tween()
			hop.tween_property(mesh, "position:y", 0.35, 0.12)
			hop.parallel().tween_property(mesh, "rotation:z", randf_range(-0.8, 0.8), 0.12)
			hop.tween_property(mesh, "position:y", 0.0, 0.15)
