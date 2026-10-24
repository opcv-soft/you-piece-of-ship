extends "res://scripts/components/station.gd"
## The crow's nest (Olivier, 2026-10-24: "put the guy up the mast with a little pirate spyglass").
## Use at the rope ladder by the mast: the sailor climbs up in 1.5 s, then reads the sea from the
## nest with a spyglass (the chart shows to a human lookout; an AI lookout calls things out).
## Use again to let go: they drop back down to the deck. Replaces the old map table.

signal reached_top(player: Node3D)

@export var climb_seconds := 1.5
@export var nest := Vector3(0.0, 7.15, 0.9) ## where the lookout stands, from this station (at the mast's foot)
@export var spyglass_bonus := 1.25 ## the spyglass sees this much further than the old chart

var climbed := 0.0 ## 0 on the deck .. 1 in the nest

var _spyglass: Node3D
var _ladder_built := false


func _ready() -> void:
	super._ready()
	add_to_group("lookouts")
	station_name = "CROW'S NEST"
	prompt = "Use: climb up"
	needs_use = true
	radius = 1.2
	_build_ladder()


## The lookout is useful only once up in the nest.
func is_up() -> bool:
	return occupant != null and climbed >= 1.0


func readers() -> Array[Node3D]:
	var up: Array[Node3D] = []
	if is_up():
		up.append(occupant)
	return up


func occupy(player: Node3D) -> bool:
	if not super.occupy(player):
		return false
	climbed = 0.0
	_give_spyglass(player)
	return true


func release(player: Node3D) -> void:
	var was_up := climbed > 0.5
	super.release(player)
	climbed = 0.0
	if _spyglass and is_instance_valid(_spyglass):
		_spyglass.queue_free()
	if was_up and player is CharacterBody3D:
		# Hop off beside the ladder and drop to the deck.
		player.global_position = global_position + global_basis * Vector3(0, 6.5, -0.2)
		player.velocity = Vector3(0, 2.0, 0)


## Where the lookout is: up the ladder as they climb, then in the nest.
func stand_point(player: Node3D) -> Vector3:
	var t := ease(clampf(climbed, 0.0, 1.0), -1.6)
	return global_position + global_basis * (Vector3(0, 0, 0).lerp(nest, t))


func _physics_process(delta: float) -> void:
	if occupant and climbed < 1.0:
		climbed = minf(1.0, climbed + delta / climb_seconds)
		if climbed >= 1.0:
			reached_top.emit(occupant)


func _give_spyglass(player: Node3D) -> void:
	_spyglass = Node3D.new()
	_spyglass.name = "Spyglass"
	var tube := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.1
	mesh.height = 0.7
	tube.mesh = mesh
	tube.material_override = load("res://scripts/systems/toon.gd").material("gold")
	tube.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	_spyglass.add_child(tube)
	_spyglass.position = Vector3(0.25, 1.45, 0.55)
	player.add_child(_spyglass)


## A rope ladder up the mast to the nest.
func _build_ladder() -> void:
	if _ladder_built:
		return
	_ladder_built = true
	var toon = load("res://scripts/systems/toon.gd")
	for side in [-0.35, 0.35]:
		var rope := MeshInstance3D.new()
		var line := CylinderMesh.new()
		line.top_radius = 0.035
		line.bottom_radius = 0.035
		line.height = nest.y
		rope.mesh = line
		rope.material_override = toon.material("rope")
		rope.position = Vector3(side, nest.y * 0.5, 0.7)
		add_child(rope)
	var rung_mesh := CylinderMesh.new()
	rung_mesh.top_radius = 0.03
	rung_mesh.bottom_radius = 0.03
	rung_mesh.height = 0.7
	var y := 0.5
	while y < nest.y:
		var rung := MeshInstance3D.new()
		rung.mesh = rung_mesh
		rung.material_override = toon.material("wood_light")
		rung.rotation = Vector3(0, 0, PI / 2.0)
		rung.position = Vector3(0, y, 0.7)
		add_child(rung)
		y += 0.45
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 2.4, 0.4)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	add_child(label)
