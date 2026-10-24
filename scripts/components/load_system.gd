extends Node
## Load and balance (DESIGN.md section 13). Where the cargo sits sets the ship's heel and trim.
## Top speed is for a fully loaded ship; every crate thrown away makes it a little faster. Before a big wave one lashed crate's rope frays
## (warning); if the wave hits before someone re-lashes it, the crate breaks loose and slides.
## Emergency measure: throw cargo overboard at the rail (lighter and level again, but that
## cargo's value is lost).

signal rope_fraying(crate: Node3D)
signal crate_loose(crate: Node3D)
signal thrown_overboard(crate: Node3D)

@export var list_per_crate_metre := 1.2 ## degrees of heel per crate per metre off the centre line
@export var trim_per_crate_metre := 0.25 ## degrees of trim per crate per metre fore or aft
@export var max_list_degrees := 12.0
@export_range(0.0, 0.1) var speed_gain_per_crate := 0.02 ## top speed gained per crate lost
@export var fray_on_waves := true

var _ship: Node3D
var _handling: Node
var _waves: Node
var _bay: Node3D
var _fraying: Node3D
var _rng := RandomNumberGenerator.new()
var _loaded_crates := -1


func _ready() -> void:
	_ship = get_parent()
	_handling = _ship.get_node("ShipHandling")
	_waves = _ship.get_node("WaveMotion")
	_bay = _ship.get_node("CargoBay")
	_waves.wave_warning.connect(_on_wave_warning)
	_waves.wave_struck.connect(_on_wave_struck)
	_rng.seed = 5


func crates() -> Array[Node]:
	return get_tree().get_nodes_in_group("cargo")


func cargo_value() -> int:
	var total := 0
	for crate in crates():
		total += crate.value
	for gold in get_tree().get_nodes_in_group("gold"):
		total += gold.value # spilled treasure still aboard still counts
	return total


func _physics_process(_delta: float) -> void:
	var heel := 0.0
	var trim := 0.0
	for crate in crates():
		var local: Vector3 = _ship.to_local(crate.global_position)
		heel += local.z
		trim += local.x
	var max_list := deg_to_rad(max_list_degrees)
	# Positive roll lowers starboard (+Z); positive pitch lifts the bow, so weight forward is negative.
	_waves.list_sources["load"] = clampf(deg_to_rad(list_per_crate_metre) * heel, -max_list, max_list)
	_waves.list_pitch = -deg_to_rad(trim_per_crate_metre) * trim / 6.0
	if _loaded_crates < 0:
		_loaded_crates = crates().size()
	_handling.speed_limits["cargo"] = 1.0 + speed_gain_per_crate * (_loaded_crates - crates().size())
	_update_fray_label()


func _on_wave_warning(_side: float) -> void:
	if not fray_on_waves:
		return
	var lashed: Array[Node] = []
	for crate in crates():
		if crate.lashed:
			lashed.append(crate)
	if lashed.is_empty():
		return
	_fraying = lashed[_rng.randi() % lashed.size()]
	rope_fraying.emit(_fraying)


func _on_wave_struck(side: float) -> void:
	if _fraying and is_instance_valid(_fraying) and _fraying.lashed and _fraying.carrier == null:
		_bay.unlash(_fraying)
		_fraying.velocity = Vector2(0.0, -side * 3.0) # thrown toward the low side
		crate_loose.emit(_fraying)
	_clear_fray()


## Re-lashing a fraying crate (picking it up and putting it back) saves it.
func _clear_fray() -> void:
	if _fraying and is_instance_valid(_fraying):
		var label := _fraying.get_node_or_null("FrayLabel")
		if label:
			label.queue_free()
	_fraying = null


func _update_fray_label() -> void:
	if _fraying == null or not is_instance_valid(_fraying):
		return
	if not _fraying.lashed and _fraying.carrier != null:
		_clear_fray() # someone took it in hand
		return
	if _fraying.get_node_or_null("FrayLabel") == null:
		var label := Label3D.new()
		label.name = "FrayLabel"
		label.text = tr("ROPE FRAYING!")
		label.font_size = 48
		label.outline_size = 10
		label.modulate = Color(1.0, 0.8, 0.4)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = Vector3(0, 1.6, 0)
		_fraying.add_child(label)


## Throws a carried crate over the rail.
func throw_overboard(crate: Node3D) -> void:
	thrown_overboard.emit(crate)
	crate.consume()
