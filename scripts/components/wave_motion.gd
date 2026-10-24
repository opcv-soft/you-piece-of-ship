extends Node
## Rocks its parent like a ship on a swell: roll (side to side), pitch (bow up and down)
## and heave (the whole ship rising and falling).
## The pose is pure maths from time, so it is predictable for players and, later,
## identical on every networked screen. Serves Comedy (stumbles) without being a physics sim.
## On top of the swell: a steady list (heel) from load and water, sinking lower when flooded,
## and scripted big waves that arrive after a warning (fairness: at least 5 s).

signal wave_warning(side: float) ## a big wave is coming; side +1 = starboard, -1 = port
signal wave_struck(side: float) ## the big wave hits now

@export_range(0.0, 3.0, 0.05) var intensity := 1.0 ## 0 = flat calm, 1 = normal swell
@export_range(0.0, 30.0, 0.5) var roll_degrees := 8.0
@export var roll_period := 6.0 ## seconds for one full side-to-side rock
@export_range(0.0, 15.0, 0.5) var pitch_degrees := 3.0
@export var pitch_period := 4.3
@export var heave_metres := 0.3
@export var heave_period := 5.1
@export_group("Big waves")
@export var wave_warning_seconds := 5.0
@export var wave_roll_degrees := 14.0
@export var wave_duration := 2.5

var list_roll := 0.0 ## radians of steady heel (positive lowers starboard, +Z), set by load and water
var list_sources := {} ## system name -> extra heel in radians (water, load), added to list_roll
var list_pitch := 0.0 ## radians of steady trim (positive lifts the bow)
var sink := 0.0 ## metres lower in the water
var sea: Node ## the realistic sea, if any: the ship then rides its real wave heights
var _sea_heave := 0.0
var _sea_pitch := 0.0
var _sea_roll := 0.0

var _time := 0.0
var _rest_height := 0.0
var _parent: Node3D
var _wave_side := 1.0
var _warning_left := 0.0
var _wave_elapsed := -1.0
var _struck := false


func _ready() -> void:
	_parent = get_parent() as Node3D
	if _parent:
		_rest_height = _parent.position.y


func _physics_process(delta: float) -> void:
	if _parent == null:
		return
	_time += delta
	_advance_wave(delta)
	var pose := sample(_time)
	_ride_sea(delta)
	# The bow points along +X, so roll turns around X and pitch around Z.
	_parent.rotation = Vector3(pose.roll * 0.6 + _sea_roll + total_list() + wave_roll(), _parent.rotation.y,
			pose.pitch * 0.6 + _sea_pitch + list_pitch) if sea and sea.fft else \
			Vector3(pose.roll + total_list() + wave_roll(), _parent.rotation.y, pose.pitch + list_pitch)
	var heave: float = _sea_heave if sea and sea.fft else pose.heave
	_parent.position.y = _rest_height + heave - sink # x and z belong to ShipHandling


## With the realistic sea, sample its height under the bow, stern and both sides: the ship rises,
## pitches and rolls with the real waves (smoothed, so it rides rather than jitters).
func _ride_sea(delta: float) -> void:
	if sea == null or sea.fft == null or not sea.fft.is_inside_tree():
		return
	var basis := _parent.global_basis
	var at := _parent.global_position
	var bow: float = sea.height_at(at + basis.x * 9.0)
	var stern: float = sea.height_at(at - basis.x * 9.0)
	var port: float = sea.height_at(at - basis.z * 3.5)
	var starboard: float = sea.height_at(at + basis.z * 3.5)
	var blend := minf(1.0, delta * 3.0)
	_sea_heave = lerpf(_sea_heave, (bow + stern + port + starboard) * 0.25 * intensity, blend)
	_sea_pitch = lerpf(_sea_pitch, atan2(bow - stern, 18.0) * intensity, blend)
	_sea_roll = lerpf(_sea_roll, atan2(port - starboard, 7.0) * intensity, blend)


## Steady heel from everything: list_roll plus every system's list source.
func total_list() -> float:
	var total := list_roll
	for angle in list_sources.values():
		total += angle
	return total


## Returns {roll, pitch} in radians and {heave} in metres at time t (seconds).
func sample(t: float) -> Dictionary:
	return {
		"roll": deg_to_rad(roll_degrees) * intensity * sin(TAU * t / roll_period),
		"pitch": deg_to_rad(pitch_degrees) * intensity * sin(TAU * t / pitch_period + 1.0),
		"heave": heave_metres * intensity * sin(TAU * t / heave_period + 2.0),
	}


## Starts a big wave from one side. It warns first, then rolls the ship hard.
## Returns false if a wave is already on its way.
func big_wave(side: float) -> bool:
	if is_wave_active():
		return false
	_wave_side = 1.0 if side >= 0.0 else -1.0
	_warning_left = wave_warning_seconds
	_wave_elapsed = -1.0
	_struck = false
	wave_warning.emit(_wave_side)
	if wave_warning_seconds <= 0.0:
		_warning_left = 0.0
		_wave_elapsed = 0.0
	return true


func is_wave_active() -> bool:
	return _warning_left > 0.0 or _wave_elapsed >= 0.0


## Extra roll from the current big wave (lifts the side it hits).
func wave_roll() -> float:
	if _wave_elapsed < 0.0:
		return 0.0
	# Positive roll lowers starboard, so lifting the wave's side is a negative roll for starboard.
	return -_wave_side * deg_to_rad(wave_roll_degrees) * sin(PI * clampf(_wave_elapsed / wave_duration, 0.0, 1.0))


func _advance_wave(delta: float) -> void:
	if _warning_left > 0.0:
		_warning_left -= delta
		if _warning_left <= 0.0:
			_wave_elapsed = 0.0
		return
	if _wave_elapsed < 0.0:
		return
	_wave_elapsed += delta
	if not _struck and _wave_elapsed >= wave_duration * 0.25:
		_struck = true
		wave_struck.emit(_wave_side)
	if _wave_elapsed >= wave_duration:
		_wave_elapsed = -1.0
