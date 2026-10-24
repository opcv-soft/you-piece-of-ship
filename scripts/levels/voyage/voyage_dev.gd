extends RefCounted
## Developer mode for one voyage (Esc → Developer): forced events, Test Drive, collision view.
## Owned by voyage.gd, which forwards dev_event, dev_extra_events and set_test_drive here.

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const RockScene = preload("res://scenes/greybox/rock.tscn")

const DEV_EVENTS := ["crash", "leak", "flood", "overheat", "stall", "out_of_coal", "rudder", "wave_port",
		"wave_starboard", "loose_cargo", "reach_port", "sink", "add_coins", "unlock_all", "god_mode"]

var voyage: Node3D


func _init(owner_voyage: Node3D) -> void:
	voyage = owner_voyage


## Forces an event right now, for testing and tuning. Returns false for an unknown event.
func dev_event(event: String) -> bool:
	var ship: Node3D = voyage._ship
	var handling: Node = voyage._handling
	match event:
		"crash":
			var rock: Node3D = RockScene.instantiate()
			rock.radius = 1.0
			rock.position = ship.global_position + handling.forward() * 8.0
			voyage.get_node("Reef").add_child(rock)
			handling.speed = maxf(handling.speed, handling.max_speed * 0.8)
			handling._hit(rock)
		"leak":
			voyage.get_node("Ship/HullSystem").add_breach(Vector3(randf_range(-6.0, 6.0), 0.0, 3.0 * (1.0 if randf() < 0.5 else -1.0)))
		"flood":
			var hull: Node = voyage.get_node("Ship/HullSystem")
			hull.water = minf(1.0, hull.water + 0.3)
		"overheat":
			voyage.get_node("Ship/EngineSystem").heat = 1.0
		"stall":
			var engine: Node = voyage.get_node("Ship/EngineSystem")
			engine.heat = 1.0
			engine.warning_left = 0.01
		"out_of_coal":
			voyage.get_node("Ship/EngineSystem").fuel = 0.0
		"rudder":
			voyage.get_node("Ship/RudderSystem").try_damage(1.0)
		"wave_port", "wave_starboard":
			voyage.get_node("Ship/WaveMotion").big_wave(-1.0 if event == "wave_port" else 1.0)
		"loose_cargo":
			var cargo: Node = voyage.get_node("Ship/LoadSystem")
			for crate in cargo.crates():
				if crate.lashed:
					voyage.get_tree().get_first_node_in_group("cargo_bay").unlash(crate)
					crate.velocity = Vector2(0.0, 3.0)
					cargo.crate_loose.emit(crate)
					break
		"reach_port":
			if voyage.test_drive:
				return false # an endless sea has no port
			ship.position.x = voyage.finish_x + 1.0
		"sink":
			var hull: Node = voyage.get_node("Ship/HullSystem")
			hull.sink_grace_seconds = 0.0
			hull.water = 1.0
		"add_coins":
			Session.money += 500
			Session.save_game()
		"unlock_all":
			Session.unlocked = ContractLibrary.all_contracts().size()
			Session.unlock_everything = true
			Session.save_game()
		"god_mode":
			voyage.god_mode = not voyage.god_mode
		"show_collisions":
			toggle_collision_view()
		"spawn_enemy_port", "spawn_enemy_starboard":
			voyage.spawn_enemy(-1.0 if event == "spawn_enemy_port" else 1.0)
		"spawn_rock", "spawn_wreck", "spawn_whale", "spawn_siren", "spawn_atoll", "spawn_barrel":
			voyage._spawn_ahead(event.trim_prefix("spawn_"))
		_:
			return false
	return true


## Developer events added by the obstacles: spawn each kind just ahead of the ship.
func dev_extra_events() -> Array:
	return [["show_collisions", "Show collision shapes"], ["spawn_enemy_port", "Spawn: pirates (port)"], ["spawn_enemy_starboard", "Spawn: pirates (starboard)"],
			["spawn_rock", "Spawn: reef rock"], ["spawn_wreck", "Spawn: shipwreck"], ["spawn_whale", "Spawn: whale"],
			["spawn_siren", "Spawn: siren"], ["spawn_atoll", "Spawn: atoll"], ["spawn_barrel", "Spawn: barrel"]]


## Developer "Test Drive": clears every obstacle, pirate, scripted event and wave, removes the port
## and the cliffs, and makes the sea endless, to try the ship's handling in peace.
func set_test_drive(on: bool) -> void:
	if not on:
		if voyage.test_drive and voyage.is_inside_tree() and voyage.get_tree().current_scene == voyage:
			voyage.get_tree().reload_current_scene() # back to the real route
		return
	voyage.test_drive = true
	for child in voyage.get_node("Reef").get_children():
		child.queue_free()
	for loot in voyage.get_tree().get_nodes_in_group("loot"):
		loot.queue_free()
	for node in voyage.get_tree().get_nodes_in_group("finish"):
		node.queue_free()
	if voyage.has_node("Dock"):
		voyage.get_node("Dock").queue_free()
	voyage.contract = voyage.contract.duplicate()
	voyage.contract.events = []
	voyage.contract.enemies = []
	voyage.contract.obstacles = []
	voyage.contract.coast_half_width = INF
	voyage._next_event = 0
	voyage._next_enemy = 0
	voyage.get_node("HazardDirector").setup([])
	voyage.finish_x = INF
	voyage.get_node("HUD/MapChart").port_x = INF
	voyage.get_node("Music").finish_x = INF


## Draws the hull's collision outline and every obstacle's collision circle on the sea, to check
## they match what you see.
func toggle_collision_view() -> void:
	if voyage.has_node("CollisionView"):
		voyage.get_node("CollisionView").queue_free()
		return
	var view := MeshInstance3D.new()
	view.name = "CollisionView"
	view.mesh = ImmediateMesh.new()
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.15, 0.4)
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	red.no_depth_test = true
	view.material_override = red
	voyage.add_child(view)


func draw_collision_view() -> void:
	var ship: Node3D = voyage._ship
	var handling: Node = voyage._handling
	var mesh: ImmediateMesh = voyage.get_node("CollisionView").mesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var fwd: Vector3 = handling.forward()
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var outline: PackedVector2Array = handling.hull_outline()
	var origin := Vector3(ship.global_position.x, 0.3, ship.global_position.z)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		mesh.surface_add_vertex(origin + fwd * a.x + right * a.y)
		mesh.surface_add_vertex(origin + fwd * b.x + right * b.y)
	for rock in voyage.get_tree().get_nodes_in_group("rocks"):
		if rock.global_position.distance_to(ship.global_position) > 140.0:
			continue
		var c := Vector3(rock.global_position.x, 0.3, rock.global_position.z)
		for k in 24:
			mesh.surface_add_vertex(c + Vector3.FORWARD.rotated(Vector3.UP, k * TAU / 24.0) * rock.radius)
			mesh.surface_add_vertex(c + Vector3.FORWARD.rotated(Vector3.UP, (k + 1) * TAU / 24.0) * rock.radius)
	mesh.surface_end()
