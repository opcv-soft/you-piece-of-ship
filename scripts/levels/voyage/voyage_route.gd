extends RefCounted
## Lays out a voyage's route from its contract: hidden rocks, obstacles, the cliffs along the
## channel, the port, and obstacles spawned ahead in Developer mode. Owned by voyage.gd.

const RockScene = preload("res://scenes/greybox/rock.tscn")
const Toon = preload("res://scripts/systems/toon.gd")
const OBSTACLE_RADIUS := {"wreck": 4.0, "whale": 3.5, "siren": 2.5, "atoll": 12.0, "rock": 3.5, "barrel": 1.0}
const BARREL_SPACING := 130.0 ## metres between floating barrels (cannon targets full of loot)

var voyage: Node3D


func _init(owner_voyage: Node3D) -> void:
	voyage = owner_voyage


func build_route() -> void:
	var contract: Resource = voyage.contract
	var reef: Node = voyage.get_node("Reef")
	var count := 0
	for row in contract.rock_rows:
		var radius: float = row[2] if row.size() > 2 else 3.5
		for z in row[1]:
			count += 1
			add_rock(reef, "Rock%d" % count, Vector3(row[0], 0.0, z), radius, true)
	for entry in contract.obstacles:
		count += 1
		var kind: String = entry[2]
		var size: float = entry[3] if entry.size() > 3 else OBSTACLE_RADIUS.get(kind, 3.5)
		add_rock(reef, "%s%d" % [kind.capitalize(), count], Vector3(entry[0], 0.0, entry[1]), size, kind == "rock", kind)
	_add_barrels(reef)
	# Visible cliffs along both sides keep the ship in the channel.
	var x := -40.0
	var i := 0
	while x < voyage.finish_x + 80.0:
		for side in [-1.0, 1.0]:
			i += 1
			var wobble := sin(x * 0.07 + side) * 3.0
			add_rock(reef, "Cliff%d" % i, Vector3(x, 0.0, side * (contract.coast_half_width + 6.0 + wobble)), 6.0, false)
		x += 11.0
	_build_port()


## Floating barrels along the route, off to the sides: shoot them (or ram them) for loot.
func _add_barrels(reef: Node) -> void:
	var contract: Resource = voyage.contract
	if contract.tutorial:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(contract.title)
	var x := 150.0
	var n := 0
	while x < voyage.finish_x - 100.0:
		n += 1
		var side := 1.0 if rng.randf() < 0.5 else -1.0
		var z := side * rng.randf_range(10.0, maxf(12.0, contract.coast_half_width - 12.0))
		add_rock(reef, "Barrel%d" % n, Vector3(x + rng.randf_range(-30.0, 30.0), 0.0, z), 1.0, false, "barrel")
		x += BARREL_SPACING


func add_rock(parent: Node, rock_name: String, where: Vector3, radius: float, hidden: bool, kind := "") -> Node3D:
	var rock: Node3D = RockScene.instantiate()
	rock.name = rock_name
	rock.radius = radius
	rock.hidden = hidden
	rock.kind = kind if kind != "" else ("rock" if hidden else "cliff")
	rock.position = where
	parent.add_child(rock)
	return rock


func _build_port() -> void:
	var finish_x: float = voyage.finish_x
	var buoy_mesh := CylinderMesh.new()
	buoy_mesh.top_radius = 0.6
	buoy_mesh.bottom_radius = 0.8
	buoy_mesh.height = 3.0
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(1, 0.85, 0.2)
	buoy_mesh.material = yellow
	if Toon.painted:
		for side in [-1.0, 1.0]:
			var buoy: Node3D = voyage._ship.prop("buoy", "Buoy%s" % ("Port" if side < 0.0 else "Starboard"))
			buoy.position = Vector3(finish_x, 0.0, side * 12.0)
			buoy.add_to_group("finish")
			voyage.add_child(buoy)
		var harbour: Node3D = voyage._ship.prop("port", "Dock")
		harbour.position = Vector3(finish_x + 30.0, 0.0, 0.0)
		voyage.add_child(harbour)
		return
	for side in [-1.0, 1.0]:
		var buoy := MeshInstance3D.new()
		buoy.name = "Buoy%s" % ("Port" if side < 0.0 else "Starboard")
		buoy.mesh = buoy_mesh
		buoy.position = Vector3(finish_x, 1.0, side * 12.0)
		buoy.add_to_group("finish")
		voyage.add_child(buoy)
	var dock_mesh := BoxMesh.new()
	dock_mesh.size = Vector3(30, 3, 70)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.55, 0.53, 0.5)
	dock_mesh.material = stone
	var dock := MeshInstance3D.new()
	dock.name = "Dock"
	dock.mesh = dock_mesh
	dock.position = Vector3(finish_x + 45.0, 1.0, 0.0)
	voyage.add_child(dock)


## Developer: puts an obstacle of that kind just ahead of the ship.
func spawn_ahead(kind: String) -> Node3D:
	var reef: Node = voyage.get_node("Reef")
	var ahead: Vector3 = voyage._ship.global_position + voyage._handling.forward() * (45.0 + OBSTACLE_RADIUS[kind])
	ahead.y = 0.0
	if kind == "siren":
		ahead += Vector3(0, 0, 16.0) # beside the lane: she lures rather than blocks
	var rock := add_rock(reef, "Dev%s%d" % [kind.capitalize(), reef.get_child_count()], ahead, OBSTACLE_RADIUS[kind],
			kind == "rock", kind)
	rock.home = ahead
	return rock


func spawn_foam() -> void:
	var contract: Resource = voyage.contract
	var flecks := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.04, 0.35)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.93, 1.0)
	mesh.material = material
	multimesh.mesh = mesh
	var area: float = (voyage.finish_x + 120.0) * contract.coast_half_width * 2.0
	multimesh.instance_count = int(area / 25.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in multimesh.instance_count:
		var spot := Vector3(rng.randf_range(-60.0, voyage.finish_x + 60.0), 0.03,
				rng.randf_range(-contract.coast_half_width, contract.coast_half_width))
		multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), spot))
	flecks.multimesh = multimesh
	voyage.add_child(flecks)
