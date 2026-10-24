extends Node3D
## The coal pile, a few steps from the furnace. Use here fills a shovel; carry it to the ENGINE and
## press Use to feed the fire. The pile never runs out, but water in the hold soaks its bottom:
## wet coal burns worse, so the ship's top speed drops (DESIGN.md section 13, Olivier 2026-10-22).

const ItemScene = preload("res://scenes/greybox/item.tscn")
const PixelArt = preload("res://scripts/systems/pixel_art.gd")

@export var radius := 1.3
@export var soak_rate := 0.08 ## wetness gained per second, toward the water level in the hold
@export var dry_rate := 0.01 ## wetness lost per second once the water is gone

var wetness := 0.0 ## 0 = dry, 1 = soaked

var _hull: Node
var _items_root: Node3D


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("coal_piles")
	var ship := get_parent()
	_hull = ship.get_node_or_null("HullSystem")
	_items_root = ship.get_node_or_null("Items")
	_build_visual(ship)


func _build_visual(ship: Node) -> void:
	if "art_style" in ship and ship.art_style == "painted":
		add_child(ship.prop("coal_pile", "Lumps"))
	elif "pixel_art" in ship and ship.pixel_art:
		var lumps := PixelArt.make_sprite(PixelArt.texture("coal"), 0.09)
		lumps.name = "Lumps"
		add_child(lumps)
	else:
		var mesh := SphereMesh.new()
		mesh.radius = 0.6
		mesh.height = 0.7
		var black := StandardMaterial3D.new()
		black.albedo_color = Color(0.1, 0.1, 0.11)
		mesh.material = black
		var pile := MeshInstance3D.new()
		pile.name = "Lumps"
		pile.mesh = mesh
		pile.position.y = 0.2
		add_child(pile)
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 1.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	add_child(label)


func _process(delta: float) -> void:
	var water: float = _hull.water if _hull else 0.0
	var target := clampf(water * 1.5, 0.0, 1.0) # the bottom of the pile gets wet first
	if target > wetness:
		wetness = move_toward(wetness, target, soak_rate * delta)
	else:
		wetness = move_toward(wetness, target, dry_rate * delta)
	var lumps := get_node_or_null("Lumps") as GeometryInstance3D
	if lumps is Sprite3D:
		(lumps as Sprite3D).modulate = Color(1, 1, 1).lerp(Color(0.55, 0.65, 0.9), wetness) # bluish when soaked
	var label := get_node("Label") as Label3D
	var near := false
	for player in get_tree().get_nodes_in_group("crew"):
		near = near or distance_to_player(player) <= radius
	var lines := PackedStringArray([tr("COAL")])
	if wetness > 0.2:
		lines.append(tr("WET!"))
	if near:
		lines.append(tr("Use: fill a shovel"))
	label.text = "\n".join(lines)
	label.visible = wetness > 0.2 # only the alert; prompts tell players the rest (interaction_prompts.gd)


func prompt_text(_player: Node3D) -> String:
	return tr("COAL") + ("  " + tr("WET!") if wetness > 0.2 else "") + "\n" + tr("Use: fill a shovel")


func distance_to_player(player: Node3D) -> float:
	var offset := player.global_position - global_position
	offset.y = 0.0
	return offset.length()


func can_interact(player: Node3D) -> bool:
	return player.carried == null and distance_to_player(player) <= radius


func interact(player: Node3D) -> void:
	var filled := shovel()
	if filled:
		filled.pick_up(player)


## A fresh shovel of coal (carrying this pile's wetness).
func shovel() -> Node3D:
	if _items_root == null:
		return null
	var coal: Node3D = ItemScene.instantiate()
	coal.kind = "coal"
	coal.wetness = wetness
	_items_root.add_child(coal)
	coal.position = _items_root.to_local(global_position)
	return coal
