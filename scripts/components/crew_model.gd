extends Node3D
## A crew member as a chubby kawaii sailor (tools/blender/build_crew.py), animated without a
## skeleton: feet waddle, hands swing, the body bobs and squashes, the eyes blink. Arms go up to
## carry, forward to work a station, and pump up and down at the pump. Hat and colour per player.

const MODEL := "res://assets/art/export/models/crew.glb"
const Toon = preload("res://scripts/systems/toon.gd")
const HATS := ["tricorn", "bandana", "captain", "beanie", "straw", "crown"]

var hat := "tricorn"
var _player: CharacterBody3D
var _model: Node3D
var _parts := {} ## part name -> [node, rest position]
var _eyes: Array[Node3D] = []
var _phase := 0.0
var _time := 0.0
var _blink_in := 2.0
var _squash := 0.0
var _faded := false
var _originals := {} ## mesh -> [surface materials] (to undo the fade)


func setup(player: CharacterBody3D, tint: Color, hat_style: String) -> void:
	_player = player
	hat = hat_style if HATS.has(hat_style) else "tricorn"
	_model = (load(MODEL) as PackedScene).instantiate()
	_model.name = "Model"
	Toon.paint(_model, {"player": tint})
	add_child(_model)
	for part in ["Body", "Head", "HandL", "HandR", "FootL", "FootR"]:
		var node := _model.find_child(part, true, false) as Node3D
		if node:
			_parts[part] = [node, node.position]
	for style in HATS:
		var node := _model.find_child("Hat_" + style, true, false) as Node3D
		if node:
			node.visible = style == hat
			if style == hat:
				_parts["Hat"] = [node, node.position]
	for eye_name in ["Eye-1", "Eye1"]:
		var eye := _model.find_child(eye_name, true, false) as Node3D
		if eye:
			_eyes.append(eye)
	player.jumped.connect(func(): _squash = -0.25)
	player.landed.connect(func(): _squash = 0.3)


func _process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	_fade(_player.station != null)
	var speed := Vector2(_player.velocity.x, _player.velocity.z).length()
	var moving: bool = speed > 0.4 and _player.knocked <= 0.0
	_phase += delta * (4.0 + speed * 1.6) if moving else 0.0
	var swing := sin(_phase) if moving else 0.0
	var bob := absf(sin(_phase)) * 0.08 if moving else sin(_time * 2.2) * 0.012
	_squash = move_toward(_squash, 0.0, delta * 2.5)
	var stretch := 1.0 - _squash * 0.5
	scale = Vector3(1.0 + _squash * 0.35, stretch, 1.0 + _squash * 0.35)
	_pose("Body", Vector3(0, bob, 0))
	_pose("Head", Vector3(0, bob * 1.3, 0), Vector3(0, 0, swing * 0.04))
	_pose("Hat", Vector3(0, bob * 1.3, 0))
	_pose("FootL", Vector3(0, maxf(0.0, swing) * 0.12, swing * 0.2))
	_pose("FootR", Vector3(0, maxf(0.0, -swing) * 0.12, -swing * 0.2))
	var hands := _hand_pose(swing)
	_pose("HandL", hands[0])
	_pose("HandR", hands[1])
	# Blink every few seconds.
	_blink_in -= delta
	var closed := _blink_in < 0.12
	if _blink_in <= 0.0:
		_blink_in = randf_range(2.0, 4.5)
	for eye in _eyes:
		eye.scale.y = 0.15 if closed else 1.0


## Working a station: the sailor fades so what they work on (the cannon's aim, the dial) shows
## through them (Olivier, 2026-10-24).
func _fade(on: bool) -> void:
	if on == _faded:
		return
	_faded = on
	for mesh in _model.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if not _originals.has(instance):
			var list := []
			for i in instance.mesh.get_surface_count():
				list.append(instance.get_surface_override_material(i))
			_originals[instance] = list
		for i in instance.mesh.get_surface_count():
			var original: Material = _originals[instance][i]
			instance.set_surface_override_material(i, Toon.see_through(original) if on else original)


## Hand offsets (left, right) from their rest spots for what the sailor is doing.
func _hand_pose(swing: float) -> Array:
	if _player.carried and _player.carried.kind == "coal":
		return [Vector3(0.12, 0.3, 0.45), Vector3(-0.2, 0.25, 0.35)] # both arms forward on the shovel
	if _player.carried:
		return [Vector3(0.18, 1.05, -0.05), Vector3(-0.18, 1.05, -0.05)] # arms up, holding it overhead
	if _player.station:
		var work := sin(_time * 9.0) * 0.18 if String(_player.station.name) == "Pump" else sin(_time * 3.0) * 0.03
		return [Vector3(0.15, 0.25 + work, 0.3), Vector3(-0.15, 0.25 - work * 0.6, 0.3)]
	if _player.knocked > 0.0:
		return [Vector3(-0.2, 0.3, 0), Vector3(0.2, 0.3, 0)] # flailing
	return [Vector3(0, absf(swing) * 0.05, -swing * 0.22), Vector3(0, absf(swing) * 0.05, swing * 0.22)]


func _pose(part: String, offset: Vector3, rotation_offset := Vector3.ZERO) -> void:
	if not _parts.has(part):
		return
	var node: Node3D = _parts[part][0]
	node.position = _parts[part][1] + offset
	node.rotation = rotation_offset
