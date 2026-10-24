extends AnimatableBody3D
## The grey ship. Its WaveMotion child rocks it; everything on board is a child of it.
## The ship is itself the moving physics body (AnimatableBody3D): moving a parent node does not
## move a physics body in Godot. sync_to_physics is off in ship.tscn: with it on, Godot 4.7
## applied the heave but dropped the roll.
## Crew and items live in ship space, so "downhill" on the deck comes from local_gravity().

const PixelArt = preload("res://scripts/systems/pixel_art.gd")
const EngineHeatVisual = preload("res://scripts/components/engine_heat_visual.gd")
const FishingSpot = preload("res://scripts/components/fishing_spot.gd")
const ShipWake = preload("res://scripts/components/ship_wake.gd")
const CoalSmears = preload("res://scripts/components/coal_smears.gd")
const CargoChaos = preload("res://scripts/components/cargo_chaos.gd")
## Fishing spots along the starboard rail, clear of the leak spots and stations.
const FISHING_SPOTS := [Vector3(5.6, 0.0, 2.75), Vector3(8.3, 0.0, 2.6)]
const Cannon = preload("res://scripts/components/cannon.gd")
const ItemDispenser = preload("res://scripts/components/item_dispenser.gd")
## Two cannons a side, at the gunports, clear of the leak spots and stations.
## Same spots on both sides, facing each other (Olivier, 2026-10-24: they were misaligned).
const CANNONS := [Vector3(-0.8, 0.0, -2.8), Vector3(2.6, 0.0, -2.8), Vector3(-0.8, 0.0, 2.8), Vector3(2.6, 0.0, 2.8)]
const BALL_RACK := Vector3(-1.4, 0.0, 0.3)
const Toon = preload("res://scripts/systems/toon.gd")
const SHIP_MODEL := "res://assets/art/export/models/ship.glb"
const MODELS := "res://assets/art/export/models/"
## Station -> painted prop (modelled in the station's own frame, see tools/blender/build_props.py).
const STATION_PROPS := {"Helm": "helm", "PlankBox": "plank_box", "PinBox": "pin_box",
		"Pump": "pump", "Engine": "engine", "CoolingPipe": "cooling_pipe", "Telescope": "telescope"}
const PUMP_HINGE := Vector3(0.0, 1.45, -0.85)
const PUMP_SPOUT := Vector3(0.0, 0.85, -1.8)
const GREYBOX_MESHES := ["Hull", "Bowsprit", "DeckMesh", "RailPortMesh", "RailStarboardMesh", "RailBowMesh",
		"RailSternMesh", "MastMesh"]

## "painted": the kawaii painted ship (2026-10-22); "pixel": the earlier pixel-art tiles; "greybox".
@export_enum("painted", "pixel", "greybox") var art_style := "painted"
var pixel_art: bool: ## items and crew ask this to pick their own look
	get:
		return art_style == "pixel"

@onready var waves: Node = $WaveMotion

var _wheel: Node3D
var _lever: Node3D
var _gush: CPUParticles3D
var _pump_time := 0.0

## Deck size comes from the floor's collision box, so there is one source of truth.
var deck_length: float:
	get:
		return ($Floor.shape as BoxShape3D).size.x
var deck_width: float:
	get:
		return ($Floor.shape as BoxShape3D).size.z


func _ready() -> void:
	add_to_group("player_ship")
	Toon.painted = art_style == "painted"
	waves.wave_struck.connect(_on_wave_struck)
	if art_style == "pixel":
		_dress()
	elif art_style == "painted":
		_paint()
	$Engine.add_child(EngineHeatVisual.new())
	add_child(ShipWake.new())
	add_child(CoalSmears.new())
	add_child(CargoChaos.new())
	$ShipHandling.impact.connect(func(_rock): lurch(Vector2($ShipHandling.impact_speed, 0.0), false)) # the engine spills coal on impact
	for i in CANNONS.size():
		var cannon := Cannon.new()
		cannon.name = "Cannon%d" % (i + 1)
		cannon.side = signf(CANNONS[i].z)
		cannon.position = CANNONS[i]
		add_child(cannon)
	_add_ball_rack()
	for i in FISHING_SPOTS.size():
		var spot := FishingSpot.new()
		spot.name = "FishingSpot%d" % (i + 1)
		spot.position = FISHING_SPOTS[i]
		add_child(spot)


## The painted ship model (tools/blender/build_ship.py) replaces the grey boxes; collision and
## every station stay exactly where they were.
func _paint() -> void:
	for mesh_name in GREYBOX_MESHES:
		get_node(mesh_name).visible = false
	var model: Node3D = (load(SHIP_MODEL) as PackedScene).instantiate()
	model.name = "Model"
	Toon.paint(model)
	add_child(model)
	for station_name in STATION_PROPS:
		var station := get_node(station_name)
		for child in station.get_children():
			if child is MeshInstance3D:
				child.visible = false
		station.add_child(prop(STATION_PROPS[station_name], "Painted"))
	# Animated parts: the wheel turns with the steering, the pump's handle rocks while pumping.
	_wheel = prop("wheel", "PaintedWheel")
	_wheel.position = Vector3(0.55, 1.1, 0.0)
	$Helm.add_child(_wheel)
	_lever = Node3D.new()
	_lever.name = "LeverPivot"
	_lever.position = PUMP_HINGE
	var arm := prop("pump_lever", "Lever")
	arm.position = -PUMP_HINGE
	_lever.add_child(arm)
	$Pump.add_child(_lever)
	_gush = _water_gush()
	$Pump.add_child(_gush)


## The cannonball rack in the middle of the deck (it never runs out).
func _add_ball_rack() -> void:
	var rack := ItemDispenser.new()
	rack.name = "BallRack"
	rack.kind = "ball"
	rack.stock = 999
	rack.title = "CANNONBALLS"
	rack.radius = 1.1
	rack.position = BALL_RACK
	var label := Label3D.new()
	label.name = "Label"
	label.position = Vector3(0, 1.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 56
	label.outline_size = 12
	rack.add_child(label)
	if art_style == "painted":
		rack.add_child(prop("ball_rack", "Painted"))
	add_child(rack)


## A painted model from assets/art/export/models/ (toon-painted, ready to add).
static func prop(model_name: String, node_name := "") -> Node3D:
	var model: Node3D = (load(MODELS + model_name + ".glb") as PackedScene).instantiate()
	model.name = node_name if node_name != "" else model_name
	Toon.paint(model)
	return model


func _process(delta: float) -> void:
	if _wheel == null:
		return
	_pump_time += delta
	var steering: float = $ShipHandling.rudder
	_wheel.rotation.x = lerp_angle(_wheel.rotation.x, steering * 2.4 + $Helm/Wheel.rotation.x, minf(1.0, delta * 8.0))
	var pumping: bool = $Pump.is_active()
	_lever.rotation.z = sin(_pump_time * 9.0) * 0.45 if pumping else lerpf(_lever.rotation.z, 0.0, delta * 4.0)
	_gush.emitting = pumping and $HullSystem.water > 0.005


## Water gushing out of the pump's spout over the side, while someone pumps.
func _water_gush() -> CPUParticles3D:
	var gush := CPUParticles3D.new()
	gush.name = "Gush"
	gush.position = PUMP_SPOUT
	gush.emitting = false
	gush.amount = 40
	gush.lifetime = 0.8
	var drop := SphereMesh.new()
	drop.radius = 0.09
	drop.height = 0.18
	drop.radial_segments = 6
	drop.rings = 3
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color(0.55, 0.85, 1.0, 0.85)
	blue.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blue.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = blue
	gush.mesh = drop
	gush.direction = Vector3(0, -0.3, -1)
	gush.spread = 12.0
	gush.initial_velocity_min = 2.0
	gush.initial_velocity_max = 3.0
	gush.gravity = Vector3(0, -9.8, 0)
	gush.scale_amount_min = 0.7
	gush.scale_amount_max = 1.3
	return gush


## Pixel-art dressing: plank textures on deck, hull and rails, crate-built spare boxes, a coal pile
## and a see-through sail. Collision and every station stay exactly as in the grey box.
func _dress() -> void:
	$DeckMesh.material_override = PixelArt.tiled_material("deck", Vector2(4.8, 4.8))
	$Hull.material_override = PixelArt.tiled_material("hull", Vector2(2.4, 0.6))
	$MastMesh.material_override = PixelArt.tiled_material("hull", Vector2(2.4, 0.6), Color(1.3, 1.2, 1.1))
	for rail in ["RailPortMesh", "RailStarboardMesh", "RailBowMesh", "RailSternMesh", "Bowsprit"]:
		get_node(rail).material_override = PixelArt.tiled_material("trim", Vector2(4.8, 0.6))
	$Pump/PumpMesh.material_override = PixelArt.tiled_material("hull", Vector2(1.2, 0.3))
	for box in ["PlankBox/BoxMesh", "PinBox/BoxMesh"]:
		get_node(box).material_override = PixelArt.tiled_material("crate", Vector2(1.0, 0.7))
	var sail := PixelArt.make_sprite(PixelArt.texture("sail"), 0.02, false)
	sail.name = "Sail"
	sail.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sail.modulate = Color(1, 1, 1, 0.6) # partly see-through: never fully hides the deck
	sail.offset = Vector2.ZERO
	sail.position = $MastMesh.position + Vector3(0.96, 0.7, 0.0)
	add_child(sail)


## Gravity as seen from the deck (ship-local, metres per second squared). Its x/z part points
## downhill: that is where loose things slide.
func local_gravity() -> Vector3:
	return global_basis.inverse() * Vector3(0.0, -9.8, 0.0)


## Knocks every crew member not holding a station over toward push (ship-local x/z).
func knock_down_crew(push: Vector2) -> Array[Node3D]:
	var fallen: Array[Node3D] = []
	for player in get_tree().get_nodes_in_group("crew"):
		if player.knock_down(push):
			fallen.append(player)
	return fallen


func _on_wave_struck(side: float) -> void:
	# The wave lifts its side, so everyone loose falls toward the other side.
	knock_down_crew(Vector2(0.0, -side))
	lurch(Vector2(0.0, -side * 3.0))


## A sudden lurch (crash, cannonball, big wave): anyone carrying a cannonball loses it, and every
## loose thing on deck keeps moving (push: ship-local x/z metres per second).
func lurch(push: Vector2, spill_coal := true) -> void:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.carried and player.carried.kind == "ball":
			player.carried.drop(push * 0.8)
		elif spill_coal and player.carried and player.carried.kind == "coal":
			player.carried.spill(clampf(push.length() / 8.0, 0.15, 0.6), push)
	for item in get_tree().get_nodes_in_group("items"):
		if is_ancestor_of(item):
			item.jolt(push)
	$CargoChaos.on_lurch(push)


## Spilled coal: a streaky smear on the deck that crew track around (scripts/components/coal_smears.gd).
func add_coal_mark(local: Vector3, size := 1.0, dir := Vector2.ZERO) -> void:
	$CoalSmears.add_smear(local, size, dir)
