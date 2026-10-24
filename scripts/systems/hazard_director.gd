extends Node
## The hazard director (DESIGN.md sections 7 and 13). Hazards are hand-placed in the contract;
## the director only enforces fairness: no new scripted hazard (big wave) while two systems are
## failing or within the calm window after a recovery. A postponed wave is dropped if the ship
## gets too far past it.

signal wave_sent(side: float)
signal wave_skipped
signal recovered(system: String)

@export var ship: Node3D
@export var calm_window := 20.0 ## seconds of calm guaranteed after any recovery
@export var max_failing := 1 ## hazards only start while at most this many systems fail
@export var skip_after_metres := 200.0
## The big-wave hazard (warning, roll, knockdown). Off since 2026-10-24: Olivier couldn't see the
## waves at all. The ocean's ordinary swell and the ship riding it stay. Set true to bring it back.
@export var big_waves_enabled := false

var waves: Array = [] ## [x, side] in order, from the contract
var next_wave := 0
var elapsed := 0.0
var last_recovery_at := -INF

var _failing: Array[String] = []


## Called by the voyage once its contract is known.
func setup(contract_waves: Array) -> void:
	waves = contract_waves.duplicate()
	waves.sort_custom(func(a, b): return a[0] < b[0])
	next_wave = 0


## Which ship systems are failing right now: hull, engine, rudder, load.
func failing_systems() -> Array[String]:
	var failing: Array[String] = []
	if ship.get_node("HullSystem").open_breach_count() > 0:
		failing.append("hull")
	var engine := ship.get_node("EngineSystem")
	if engine.heat > engine.heat_cap_threshold or engine.is_stalled() or engine.is_pipe_burst() or engine.fuel <= 0.0:
		failing.append("engine")
	if ship.get_node("RudderSystem").is_damaged():
		failing.append("rudder")
	for crate in get_tree().get_nodes_in_group("cargo"):
		if not crate.lashed and crate.carrier == null:
			failing.append("load")
			break
	return failing


func can_start_hazard() -> bool:
	return _failing.size() <= max_failing and elapsed - last_recovery_at >= calm_window


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	elapsed += delta
	var now := failing_systems()
	for system in _failing:
		if not now.has(system):
			last_recovery_at = elapsed
			recovered.emit(system)
	_failing = now
	if next_wave >= waves.size():
		return
	var x: float = ship.global_position.x
	var wave: Array = waves[next_wave]
	if x < wave[0]:
		return
	if x > wave[0] + skip_after_metres:
		next_wave += 1
		wave_skipped.emit()
		return
	if not big_waves_enabled:
		return
	if can_start_hazard() and ship.get_node("WaveMotion").big_wave(wave[1]):
		next_wave += 1
		wave_sent.emit(wave[1])
