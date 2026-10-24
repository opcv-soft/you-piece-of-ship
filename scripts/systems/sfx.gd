extends RefCounted
## Sound effects (Olivier, 2026-10-24: "add sound effects for when shit breaks bro"). Plays a
## sound from assets/audio/sfx/ (made by tools/make_sfx.py) on the SFX bus, at a spot in the
## world (positional) or flat, with a little random pitch so repeats don't sound robotic.

const DIR := "res://assets/audio/sfx/"


static func play(sound: String, world: Node, at: Variant = null, volume_db := 0.0, pitch_spread := 0.08) -> void:
	if world == null or not world.is_inside_tree() or not ResourceLoader.exists(DIR + sound + ".wav"):
		return
	var player: Node
	if at is Vector3:
		var spot := AudioStreamPlayer3D.new()
		spot.unit_size = 30.0
		spot.max_db = 6.0
		spot.volume_db = volume_db
		spot.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
		spot.stream = load(DIR + sound + ".wav")
		spot.bus = &"SFX"
		world.add_child(spot)
		spot.global_position = at
		spot.play()
		spot.finished.connect(spot.queue_free)
		player = spot
	else:
		var flat := AudioStreamPlayer.new()
		flat.volume_db = volume_db
		flat.pitch_scale = 1.0 + randf_range(-pitch_spread, pitch_spread)
		flat.stream = load(DIR + sound + ".wav")
		flat.bus = &"SFX"
		world.add_child(flat)
		flat.play()
		flat.finished.connect(flat.queue_free)
		player = flat
