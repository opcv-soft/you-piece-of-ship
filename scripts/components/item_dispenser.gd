extends Node3D
## A spare-parts box: Use takes one item (plank or rudder pin) while stock lasts.
## Limited stock makes every patch a decision (Thrill of danger).

const ItemScene = preload("res://scenes/greybox/item.tscn")

@export_enum("plank", "pin", "crate", "ball") var kind := "plank"
@export var stock := 4
@export var radius := 1.2
@export var title := "PLANKS"

var _items_root: Node3D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("dispensers")
	_items_root = get_parent().get_node_or_null("Items")


func _process(_delta: float) -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		var near := false
		for player in get_tree().get_nodes_in_group("crew"):
			near = near or distance_to_player(player) <= radius
		var count := " %d" % stock if stock < 100 else "" # the cannonball rack never runs out: no count
		label.text = tr(title) + count + ("\n" + tr("Use: take one") if near and stock > 0 else "")
		label.visible = false # contextual prompts instead (interaction_prompts.gd)


func distance_to_player(player: Node3D) -> float:
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length()


func can_interact(player: Node3D) -> bool:
	return stock > 0 and player.carried == null and distance_to_player(player) <= radius


func interact(player: Node3D) -> void:
	var item := take()
	if item:
		item.pick_up(player)


## Spawns one item on the ship (or returns null when empty).
func take() -> Node3D:
	if stock <= 0 or _items_root == null:
		return null
	stock -= 1
	var item: Node3D = ItemScene.instantiate()
	item.kind = kind
	_items_root.add_child(item)
	item.position = _items_root.to_local(global_position)
	return item
