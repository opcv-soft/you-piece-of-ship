extends Node
## The steam engine's voice: a chug-chug start when it gets going, then a steady hum that climbs
## in pitch as the ship speeds up (and with the throttle, so pushing it forward sounds like
## accelerating). Silent when the engine is stalled. A child of the ship. Also owns the SFX volume
## (Developer → Tune → Sound).

@export_range(-40.0, 6.0) var sfx_volume_db := -3.0
@export var hum_volume_db := -10.0

var _hum: AudioStreamPlayer
var _was_running := false
var _idle := 10.0 ## seconds the engine has been idle (a start sound needs a real rest first)


func _ready() -> void:
	name = "EngineSound"
	add_to_group("dev_tunable")
	set_meta("dev_group", "Sound")
	_hum = AudioStreamPlayer.new()
	_hum.stream = load("res://assets/audio/sfx/engine_hum.wav")
	_hum.bus = &"SFX"
	_hum.volume_db = -60.0
	add_child(_hum)
	var engine := get_parent().get_node_or_null("EngineSystem")
	if engine:
		engine.restarted.connect(func(): load("res://scripts/systems/sfx.gd").play("engine_start", self))


func _process(delta: float) -> void:
	var bus := AudioServer.get_bus_index(&"SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, sfx_volume_db)
	var handling := get_parent().get_node("ShipHandling")
	var engine := get_parent().get_node_or_null("EngineSystem")
	var throttle: float = absf(handling.throttle)
	var running: bool = throttle > 0.05 and not (engine and engine.is_stalled())
	if running and not _was_running and _idle > 2.0:
		load("res://scripts/systems/sfx.gd").play("engine_start", self)
	_idle = 0.0 if running else _idle + delta
	_was_running = running
	if not _hum.playing and running:
		_hum.play()
	var ratio: float = clampf(absf(handling.speed) / handling.max_speed, 0.0, 1.0)
	_hum.pitch_scale = lerpf(_hum.pitch_scale, 0.65 + ratio * 0.8 + throttle * 0.15, minf(1.0, delta * 2.0))
	var target := hum_volume_db + throttle * 6.0 if running else -60.0
	_hum.volume_db = move_toward(_hum.volume_db, target, delta * 30.0)
