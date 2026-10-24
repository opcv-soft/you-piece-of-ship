extends Node3D
## Floating loot: sail through it to scoop it up. Each piece is a resource for the ship's stores
## (ship_stores.gd): gold, charcoal, planks or whale grease, each with its own look.

signal collected(value: int)

const Toon = preload("res://scripts/systems/toon.gd")

@export var value := 60 ## how many units (gold, charcoal...) it holds
@export_enum("gold", "coal", "planks", "grease") var resource := "gold"
@export var pickup_radius := 9.0

var _time := 0.0


func _ready() -> void:
	add_to_group("loot")
	var model := _look()
	model.name = "Model"
	add_child(model)
	_time = randf() * TAU


func _physics_process(delta: float) -> void:
	_time += delta
	position.y = sin(_time * 1.8) * 0.18
	rotation.y += delta * 0.4
	var ship := get_tree().get_first_node_in_group("player_ship") as Node3D
	if ship == null:
		return
	var offset := ship.global_position - global_position
	offset.y = 0.0
	if offset.length() < pickup_radius:
		collect()


## What it looks like afloat: a barrel of gold, a raft of black charcoal, a bundle of planks,
## or a grease barrel.
func _look() -> Node3D:
	if resource == "gold" or resource == "grease":
		var barrel: Node3D = (load("res://assets/art/export/models/loot.glb") as PackedScene).instantiate()
		Toon.paint(barrel, {"gold": Color(0.95, 0.9, 0.7)} if resource == "grease" else {})
		return barrel
	var bundle := Node3D.new()
	for i in 4:
		var piece := MeshInstance3D.new()
		if resource == "coal":
			var lump := SphereMesh.new()
			lump.radius = 0.35
			lump.height = 0.6
			piece.mesh = lump
			piece.material_override = Toon.material("coal")
			piece.position = Vector3((i % 2) * 0.5 - 0.25, 0.1, (i / 2) * 0.5 - 0.25)
		else:
			var plank := BoxMesh.new()
			plank.size = Vector3(2.0, 0.15, 0.4)
			piece.mesh = plank
			piece.material_override = Toon.material("wood_light")
			piece.position = Vector3(0, i * 0.16, (i - 1.5) * 0.3)
			piece.rotation.y = (i - 1.5) * 0.25
		bundle.add_child(piece)
	return bundle


func collect() -> void:
	var voyage := get_tree().get_first_node_in_group("voyage")
	var ship := get_tree().get_first_node_in_group("player_ship")
	var points := 0
	if ship and ship.has_node("ShipStores"):
		points = ship.get_node("ShipStores").add(resource, value)
	if voyage and "bonus_points" in voyage:
		voyage.bonus_points += points
	collected.emit(value)
	UI.play("coin")
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", 4.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(queue_free)
