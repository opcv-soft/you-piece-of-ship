extends CharacterBody3D
## One crew member: walk, run and jump, Overcooked-style; Use picks up, puts down, applies
## items and takes over stations. Crew live inside the ship node, so the rocking deck carries
## them; they only fight the waves to walk where they want (Comedy without frustration).
## Knockdowns (big waves, steam vents, sliding crates) drop whatever you carry.

const CrewSprite = preload("res://scripts/components/crew_sprite.gd")
const CrewModel = preload("res://scripts/components/crew_model.gd")
const DEFAULT_HATS := ["tricorn", "bandana", "beanie", "straw"]
const ThoughtBubble = preload("res://scripts/components/thought_bubble.gd")
const CrewBadge = preload("res://scripts/components/crew_badge.gd")

signal jumped
signal landed
signal knocked_down

const COLORS := [
	Color(0.9, 0.25, 0.2), # player 1: red
	Color(0.2, 0.45, 0.95), # player 2: blue
	Color(0.95, 0.8, 0.15), # player 3: yellow
	Color(0.25, 0.75, 0.3), # player 4: green
]

@export_range(1, 4) var player_index := 1
@export var walk_speed := 5.0 ## metres per second
@export var acceleration := 40.0
@export var jump_velocity := 6.0
@export var gravity := 20.0
@export var knockdown_seconds := 1.4
@export var knockdown_push := 3.0 ## metres per second you are shoved when knocked over
@export var pixel_art := true ## draw as an animated pixel pirate (false: the grey-box capsule)
@export var hat := "" ## hat style for the painted look (empty: the player's default)

var move_input := Vector2.ZERO ## x = right, y = towards the camera
var jump_requested := false
var use_requested := false
var station: Node3D = null ## the station this player is operating, if any
var carried: Node3D = null ## the item above this player's head, if any
var knocked := 0.0 ## seconds left lying on the deck
var facing := Vector3(0, 0, 1) ## world direction the player last moved or worked in (for the sprite)

var _air_time := 0.0
var bubble: Sprite3D ## comic bubble above the head (what I'm doing, what I see)

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("crew")
	add_to_group("camera_focus")
	# The ship already carries us (we are its child), so don't also add the deck's motion.
	platform_floor_layers = 0
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = COLORS[player_index - 1]
	$Visual/Body.material_override = body_material
	$Label.text = "P%d" % player_index
	$Label.modulate = COLORS[player_index - 1].lightened(0.3)
	var ship := get_parent().get_parent() if get_parent() else null
	if ship and "art_style" in ship and ship.art_style == "painted":
		_use_painted()
		$Label.position.y = 2.6 # above the hat
	elif pixel_art:
		_use_pixel_art()
		$Label.position.y = 3.05 # above the taller pixel pirate
	bubble = ThoughtBubble.new()
	bubble.height = $Label.position.y + 1.0 # clear of the job icon and P-tag
	add_child(bubble)
	add_child(CrewBadge.new()) # colour ring, job icon, big P-tag


## Shows a thought ("think") or a callout ("shout") bubble above this crew member.
func think(text: String, seconds := 2.5, style := "think") -> void:
	if bubble:
		bubble.show_text(text, seconds, style)


func _physics_process(delta: float) -> void:
	if knocked > 0.0:
		_lie_down(delta)
		return
	if use_requested:
		_interact()
	use_requested = false
	if station:
		# Operating a station: stand at it, face the bow; the stick drives the station instead.
		velocity = Vector3.ZERO
		if jump_requested:
			station.secondary_action(self)
		jump_requested = false
		if station: # the secondary action may have released us
			global_position = station.stand_point(self)
			_visual.rotation.y = PI / 2.0
			facing = _station_facing()
		return
	var speed: float = walk_speed * (carried.carry_speed if carried else 1.0)
	var direction := Vector3(move_input.x, 0.0, move_input.y).limit_length(1.0)
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	_fall_and_jump(delta, true)
	if direction.length() > 0.1:
		# Face where we walk; the ship may have turned, so convert to our own frame.
		facing = direction
		var local_facing := global_basis.inverse() * direction
		_visual.rotation.y = atan2(local_facing.x, local_facing.z)


func _fall_and_jump(delta: float, can_jump: bool) -> void:
	if is_on_floor():
		if jump_requested and can_jump:
			velocity.y = jump_velocity
			jumped.emit()
	else:
		velocity.y -= gravity * delta
	jump_requested = false
	move_and_slide()
	if is_on_floor():
		if _air_time > 0.15: # ignore tiny hops from the deck heaving
			landed.emit()
		_air_time = 0.0
	else:
		_air_time += delta


func _lie_down(delta: float) -> void:
	knocked -= delta
	use_requested = false
	velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)
	_fall_and_jump(delta, false)
	if knocked <= 0.0:
		knocked = 0.0
		_visual.rotation.x = 0.0
		_visual.position.y = 0.0


## Uses the nearest thing in reach: leave a station, apply or drop the carried item,
## pick something up, or take over a station.
func _interact() -> void:
	if station:
		station.release(self)
		return
	var best: Node = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactables"):
		if node == carried or not node.can_interact(self):
			continue
		var distance: float = node.distance_to_player(self)
		if distance < best_distance:
			best = node
			best_distance = distance
	if best:
		best.interact(self)
	elif carried:
		carried.drop()


## Uses one particular thing (an AI crewmate knows what it wants; humans use whatever is nearest).
## Returns false if that thing can't be used from here right now.
func interact_with(target: Node) -> bool:
	if knocked > 0.0 or target == null or not is_instance_valid(target) or not target.can_interact(self):
		return false
	target.interact(self)
	return true


## Knocks this player over, dropping what they carry. push is a ship-local x/z direction.
## Players operating a station are holding on (braced) and stay up. Returns true if knocked.
func knock_down(push := Vector2.ZERO) -> bool:
	if station or knocked > 0.0:
		return false
	knocked = knockdown_seconds
	if carried:
		carried.drop(push * knockdown_push * 1.3)
	var ship_basis := get_parent_node_3d().global_basis if get_parent_node_3d() else Basis.IDENTITY
	var shove := ship_basis * Vector3(push.x, 0.0, push.y) * knockdown_push
	velocity.x = shove.x
	velocity.z = shove.z
	_visual.rotation.x = -PI / 2.0
	_visual.position.y = 0.35
	think(tr("Whoa!"), 1.2, "shout")
	knocked_down.emit()
	return true


## Swaps the grey-box capsule for a chubby painted sailor in the player's colour and hat.
func _use_painted() -> void:
	$Visual/Body.visible = false
	$Visual/Nose.visible = false
	var model := CrewModel.new()
	model.name = "Sailor"
	var style := hat
	if style == "":
		style = Session.outfit_for(player_index) if Session.has_method("outfit_for") else DEFAULT_HATS[player_index - 1]
	model.setup(self, COLORS[player_index - 1], style)
	_visual.add_child(model)


## Swaps the grey-box capsule for an animated pixel pirate in the player's colour, plus a soft
## shadow under the feet so the sprite sits on the deck.
func _use_pixel_art() -> void:
	$Visual/Body.visible = false
	$Visual/Nose.visible = false
	var sprite := CrewSprite.new()
	sprite.name = "Sprite"
	# Player 2's blue is the sheet's own colour; the others are recoloured.
	sprite.setup(self, null if player_index == 2 else COLORS[player_index - 1])
	_visual.add_child(sprite)
	var shadow := MeshInstance3D.new()
	shadow.name = "Shadow"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.45
	disc.bottom_radius = 0.45
	disc.height = 0.01
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0, 0, 0, 0.35)
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material = dark
	shadow.mesh = disc
	shadow.position.y = 0.02
	add_child(shadow)


## Working a station: face the station's gear (the bow for the helm, the rail for side stations).
func _station_facing() -> Vector3:
	var toward: Vector3 = station.global_position - global_position
	for child in station.get_children():
		if child is MeshInstance3D:
			toward = child.global_position - global_position
			break
	toward.y = 0.0
	if toward.length() < 0.05:
		return Vector3(0, 0, 1)
	return toward.normalized()
