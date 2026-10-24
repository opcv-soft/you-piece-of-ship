extends Node
## Treasure chests that won't sit still (Olivier, 2026-10-24: "cargo waltzing around as we're
## moving and getting hit; a big hit opens a chest; some is lost and swept away on another hit or
## when we flood"). Lashed chests sway in their ropes with the ship; hard lurches snap the ropes
## and burst chests open; spilled gold slides about and washes overboard from the edges on the next
## big lurch or while the deck is flooded. Gold carried back to a chest (Use) goes back in.
## A child of the ship; ship.lurch() calls on_lurch().

signal chest_burst(chest: Node3D)
signal gold_lost(value: int)

const ItemScene = preload("res://scenes/greybox/item.tscn")

@export var snap_push := 3.5 ## lurch (m/s) that can snap a lashing rope
@export var burst_push := 5.0 ## lurch that can burst a loose chest open
@export var spill_share := 0.5 ## share of a chest's treasure that spills when it bursts
@export var gold_pieces := 3
@export var flood_sweep_water := 0.35 ## deck flooded past this: gold near the edges washes away

var _ship: Node3D
var _sweep_clock := 0.0


func _ready() -> void:
	name = "CargoChaos"
	_ship = get_parent()


## A lurch (crash, wave, cannonball): ropes snap, loose chests burst, gold at the edges goes over.
func on_lurch(push: Vector2) -> void:
	var strength := push.length()
	var bay := get_tree().get_first_node_in_group("cargo_bay")
	for chest in get_tree().get_nodes_in_group("cargo"):
		if not _ship.is_ancestor_of(chest) or chest.carrier:
			continue
		if chest.lashed and strength >= snap_push and randf() < 0.35 and bay:
			bay.unlash(chest)
			chest.jolt(push)
		elif not chest.lashed and strength >= burst_push and not chest.get_meta("burst", false) and randf() < 0.6:
			burst(chest)
	if strength >= 2.5:
		_sweep_edges(0.6)


## A chest bursts open: half its treasure spills across the deck as loose gold.
func burst(chest: Node3D) -> void:
	chest.set_meta("burst", true)
	var spilled := int(chest.value * spill_share)
	chest.value -= spilled
	var lid := chest.find_child("ChestLid", true, false) as Node3D
	if lid:
		lid.position += Vector3(0, 0.25, -0.2)
		lid.rotation.x = -1.0
	var items := _ship.get_node_or_null("Items")
	for i in gold_pieces:
		var gold: Node3D = ItemScene.instantiate()
		gold.kind = "gold"
		gold.value = spilled / gold_pieces
		items.add_child(gold)
		gold.position = chest.position + Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))
		gold.velocity = Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5))
	chest_burst.emit(chest)


func _physics_process(delta: float) -> void:
	_sweep_clock -= delta
	var hull := _ship.get_node_or_null("HullSystem")
	if hull and hull.water >= flood_sweep_water and _sweep_clock <= 0.0:
		_sweep_clock = 1.5
		_sweep_edges(0.35)


## Gold lying near the rails can wash overboard (lost for good).
func _sweep_edges(chance: float) -> void:
	var half_length: float = _ship.deck_length * 0.5 - 0.9
	var half_width: float = _ship.deck_width * 0.5 - 0.9
	for gold in get_tree().get_nodes_in_group("gold"):
		if gold.carrier or not _ship.is_ancestor_of(gold):
			continue
		var near_edge: bool = absf(gold.position.x) > half_length or absf(gold.position.z) > half_width
		if near_edge and randf() < chance:
			gold_lost.emit(gold.value)
			gold.consume()
