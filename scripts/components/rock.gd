extends Node3D
## Something in the water the ship must not hit (Olivier, 2026-10-22: "a sunken ship here, a rock
## there, a whale there, a siren here, an atoll there").
##  rock   - a submerged reef rock: invisible from the deck, only the map table shows it; revealed
##           once the ship hits it (a visible scar of the mistake: Comedy)
##  cliff  - the channel's walls
##  wreck  - a sunken ship, masts poking out
##  whale  - swims across the channel and dives now and then (only solid while surfaced)
##  siren  - sings on her rock and pulls the wheel toward her while the ship is close
##  atoll  - a ring island with palm trees
## All of them are in the "rocks" group: the ship's collision, the chart and the AI treat them alike.

const Toon = preload("res://scripts/systems/toon.gd")
const PixelArt = preload("res://scripts/systems/pixel_art.gd")
const Breakable = preload("res://scripts/components/breakable.gd")
const MODELS := "res://assets/art/export/models/"
## kind -> [model, model size at scale 1 (its radius)]
## The size is the model's real footprint at the waterline, so what you see is what you hit.
const LOOKS := {"rock": ["rock", 1.45], "cliff": ["cliff", 1.4], "wreck": ["wreck", 4.4], "whale": ["whale", 4.4],
		"siren": ["siren", 3.2], "atoll": ["atoll", 12.0], "barrel": ["barrel", 0.65]}
## What the navigator calls each one.
const CALL_NAMES := {"rock": "Rock", "wreck": "Wreck", "whale": "Whale", "siren": "Siren", "atoll": "Atoll", "barrel": "Barrel",
		"cliff": "Coast"}

@export_enum("rock", "cliff", "wreck", "whale", "siren", "atoll", "barrel") var kind := "rock"
@export var radius := 3.5 ## metres
@export var hidden := true ## submerged (reef rocks only): just the chart shows it
@export_group("Whale")
@export var swim_amplitude := 14.0 ## metres it swims to each side of its spot
@export var swim_speed := 0.12 ## radians per second of its back-and-forth
@export var surfaced_seconds := 9.0
@export var dived_seconds := 4.0
@export_group("Siren")
@export var lure_radius := 38.0 ## metres: inside this, her song pulls the wheel
@export var lure_strength := 0.45 ## wheel pull at the closest point (-1..1 scale)
@export var drag_speed := 2.4 ## metres per second she drags the ship toward her, at her closest

var revealed := false
var home := Vector3.ZERO
var surfaced := true

var _model: Node3D
var _tail: Node3D
var _time := 0.0
var _dive_clock := 0.0
var _song: AudioStreamPlayer3D
var _notes: CPUParticles3D


func _ready() -> void:
	add_to_group("rocks")
	add_to_group("obstacles")
	home = position
	if kind != "rock":
		hidden = false
	revealed = not hidden
	_rng_offset()
	if Toon.painted:
		_paint()
	else:
		_greybox()
	if kind == "siren":
		_start_song()
	if Breakable.can_break(kind):
		add_child(Breakable.new())


func _rng_offset() -> void:
	_time = fmod(absf(home.x * 0.37 + home.z * 0.11), 10.0)
	_dive_clock = fmod(absf(home.x * 0.13), surfaced_seconds)


func _paint() -> void:
	$Mesh.visible = false
	var look: Array = LOOKS[kind]
	_model = (load(MODELS + look[0] + ".glb") as PackedScene).instantiate()
	_model.name = "Model"
	Toon.paint(_model)
	var s: float = radius / look[1]
	_model.scale = Vector3(s, s * (1.1 if kind == "cliff" else 1.0), s)
	_model.rotation.y = fmod(home.x * 1.7 + home.z, TAU)
	add_child(_model)
	if kind == "rock":
		_model.position.y = -0.55 # just under the surface: the foam ring gives it away only up close
		_model.visible = revealed
	elif kind == "whale":
		_model.rotation.y = 0.0
		_tail = (load(MODELS + "whale_tail.glb") as PackedScene).instantiate()
		Toon.paint(_tail)
		_tail.position = Vector3(-3.6, 0.15, 0.0)
		_model.add_child(_tail)
	elif kind == "siren":
		_model.rotation.y = 0.0 if home.z < 0.0 else PI # she faces the lane


func _greybox() -> void:
	$Mesh.scale = Vector3(radius, radius * 0.4, radius) if hidden else Vector3(radius, radius * 1.6, radius)
	$Mesh.visible = not hidden
	if not hidden and kind == "cliff" and PixelArt:
		$Mesh.material_override = PixelArt.tiled_material("coal", Vector2(2.4, 2.4), Color(1.3, 1.3, 1.3))


func reveal() -> void:
	revealed = true
	if _model:
		_model.visible = true
		var rise := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rise.tween_property(_model, "position:y", -0.15, 0.4)
	else:
		$Mesh.visible = true


## Whether the ship can hit it right now (a diving whale is too deep).
func is_solid() -> bool:
	return kind != "whale" or surfaced


## Where the AI should steer clear of, and how widely: a whale's whole swimming lane.
func avoid_centre() -> Vector3:
	return home if kind == "whale" else global_position


func avoid_radius() -> float:
	return radius + swim_amplitude * 0.75 if kind == "whale" else radius


## A cannonball or a ram. Returns true if it broke (whales, cliffs and atolls never do).
func take_hit(_point := Vector3.ZERO, damage := 1) -> bool:
	var breakable := get_node_or_null("Breakable")
	return breakable.hit(damage) if breakable else false


## Floating barrels just burst when the ship rams them: no bounce, no damage to the hull.
func is_soft() -> bool:
	return kind == "barrel"


func call_name() -> String:
	return CALL_NAMES.get(kind, "Rock")


func _physics_process(delta: float) -> void:
	_time += delta
	# A reef rock shows itself as soon as it comes into view (Olivier, 2026-10-24); the chart and
	# the lookout still see it earlier.
	if not revealed:
		var camera := get_viewport().get_camera_3d()
		if camera and camera.is_position_in_frustum(global_position):
			reveal()
	match kind:
		"whale":
			_swim(delta)
		"siren":
			_lure()


# --- Whale ---------------------------------------------------------------------------------

func _swim(delta: float) -> void:
	var z := sin(_time * swim_speed) * swim_amplitude
	var heading := cos(_time * swim_speed) # +1 swimming to starboard (+z)
	position = Vector3(home.x, 0.0, home.z + z)
	_dive_clock += delta
	var cycle := surfaced_seconds + dived_seconds
	var phase := fmod(_dive_clock, cycle)
	var was_surfaced := surfaced
	surfaced = phase < surfaced_seconds
	if _model:
		_model.rotation.y = -PI / 2.0 * signf(heading) # face where it swims (model faces +x)
		var depth := 0.0 if surfaced else -3.2
		_model.position.y = lerpf(_model.position.y, depth + sin(_time * 1.3) * 0.15, minf(1.0, delta * 1.5))
		if _tail:
			_tail.rotation.z = sin(_time * 2.4) * 0.35
		if surfaced and not was_surfaced:
			_spout()


func _spout() -> void:
	var spray := CPUParticles3D.new()
	spray.one_shot = true
	spray.amount = 30
	spray.lifetime = 1.2
	spray.explosiveness = 0.8
	var drop := SphereMesh.new()
	drop.radius = 0.25
	drop.height = 0.5
	drop.radial_segments = 6
	drop.rings = 3
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.85, 0.95, 1.0, 0.9)
	white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = white
	spray.mesh = drop
	spray.direction = Vector3.UP
	spray.spread = 18.0
	spray.initial_velocity_min = 6.0
	spray.initial_velocity_max = 9.0
	spray.gravity = Vector3(0, -9.8, 0)
	spray.position = Vector3(1.6 * radius / 3.5, 2.0, 0)
	add_child(spray)
	spray.emitting = true
	get_tree().create_timer(2.0).timeout.connect(spray.queue_free)


# --- Siren ---------------------------------------------------------------------------------

## Pulls the ship's wheel toward her rock while the ship is near and hasn't passed her yet.
func _lure() -> void:
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	if ship == null:
		return
	var handling := ship.get_node("ShipHandling")
	var offset := global_position - ship.global_position
	offset.y = 0.0
	var distance := offset.length()
	var pull := 0.0
	var fwd: Vector3 = handling.forward()
	if distance < lure_radius and offset.dot(fwd) > -radius:
		var right := Vector3(-fwd.z, 0.0, fwd.x)
		var side := signf(offset.dot(right)) # +1: she is to starboard
		pull = -side * lure_strength * (1.0 - distance / lure_radius) # wheel: +1 turns to port
	handling.lures[get_instance_id()] = pull
	# Her song drags the whole ship toward her, harder the closer it gets (Olivier, 2026-10-24).
	# It fades out close to her rock and lets go for a moment after the ship bumps into something,
	# so a ship can't get pinned against her.
	var drag := Vector3.ZERO
	var close := radius + 9.0
	if distance < lure_radius and distance > close and handling._cooldown <= 0.0:
		drag = offset.normalized() * drag_speed * (1.0 - distance / lure_radius) * clampf((distance - close) / 6.0, 0.0, 1.0)
	handling.drifts[get_instance_id()] = drag
	if _song:
		_song.volume_db = lerpf(-30.0, -6.0, clampf(1.0 - distance / (lure_radius * 2.0), 0.0, 1.0))
	if _notes:
		_notes.emitting = distance < lure_radius * 1.6


func _start_song() -> void:
	_song = AudioStreamPlayer3D.new()
	_song.name = "Song"
	var stream: AudioStream = load("res://assets/audio/sfx/siren_song.wav")
	_song.stream = stream
	_song.autoplay = true
	_song.unit_size = 25.0
	_song.position = Vector3(0, 3, 0)
	add_child(_song)
	_notes = CPUParticles3D.new()
	_notes.name = "Notes"
	_notes.position = Vector3(-1.1 * radius / 2.5, 3.6 * radius / 2.5, 0.6)
	_notes.amount = 6
	_notes.lifetime = 2.5
	var note := TextMesh.new()
	note.text = "♪"
	note.font_size = 64
	note.depth = 0.02
	var pink := StandardMaterial3D.new()
	pink.albedo_color = Color(1.0, 0.55, 0.75)
	pink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pink.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	note.material = pink
	_notes.mesh = note
	_notes.direction = Vector3.UP
	_notes.spread = 35.0
	_notes.gravity = Vector3(0, 0.5, 0)
	_notes.initial_velocity_min = 0.8
	_notes.initial_velocity_max = 1.4
	_notes.scale_amount_min = 3.0
	_notes.scale_amount_max = 4.5
	add_child(_notes)
