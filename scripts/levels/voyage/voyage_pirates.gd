extends RefCounted
## Pirates on a voyage: spawns the contract's enemy ships as the ship sails past their mark, and
## turns an enemy cannonball landing on deck into a breach. Owned by voyage.gd.

const EnemyShip = preload("res://scripts/components/enemy_ship.gd")

var voyage: Node3D


func _init(owner_voyage: Node3D) -> void:
	voyage = owner_voyage


func run_enemies() -> void:
	var enemies: Array = voyage.contract.enemies
	while voyage._next_enemy < enemies.size() and voyage._ship.global_position.x >= enemies[voyage._next_enemy][0]:
		spawn_enemy(float(enemies[voyage._next_enemy][1]))
		voyage._next_enemy += 1


## Pirates appear behind the ship on one side and come alongside.
func spawn_enemy(side: float) -> Node3D:
	var ship: Node3D = voyage._ship
	var voyage_log: Node = voyage.get_node("VoyageLog")
	var enemy := EnemyShip.new()
	enemy.name = "Pirates%d" % voyage.get_tree().get_nodes_in_group("enemy_ships").size()
	enemy.side = side
	enemy.target = ship
	voyage.get_node("Reef").add_child(enemy)
	var right: Vector3 = ship.global_basis.z
	enemy.global_position = ship.global_position - voyage._handling.forward() * 35.0 + right * side * 22.0
	enemy.global_position.y = 0.0
	enemy.rotation.y = ship.rotation.y
	enemy.sunk.connect(func(_e): voyage_log.add("Pirates sunk! Scoop up the loot", "good"); voyage.show_hint(voyage.tr("Pirates sunk! Sail through the floating loot to scoop it up.")))
	enemy.broadside.connect(func(): voyage_log.add("Pirates fired a broadside", "info"))
	voyage_log.add("Pirates on the %s side!", "bad", ["starboard" if side > 0.0 else "port"])
	voyage.show_hint(voyage.tr("PIRATES! Outrun them at full speed, or load the cannons on that side (cannonballs in the middle of the deck)."))
	return enemy


## An enemy cannonball landed on the deck: it cracks the hull there, like a rock would.
func cannon_hit(point: Vector3) -> void:
	var ship: Node3D = voyage._ship
	voyage.hits += 1
	voyage.get_node("Ship/HullSystem").add_breach(ship.to_local(point))
	var hit_side := signf(ship.to_local(point).z)
	ship.lurch(Vector2(0.0, -hit_side * 2.5)) # the blow shoves everything loose across the deck
	voyage.get_node("VoyageLog").add("Cannonball hit!", "bad")
	voyage.get_node("Music").sting("sting_crash")
	voyage._banner.text = voyage.tr("BOOM!")
	voyage._banner.visible = true
	voyage._crash_flash = 0.8
	voyage.get_node("SharedCamera").add_trauma(0.5)
	var local := ship.to_local(point)
	for player in voyage.get_tree().get_nodes_in_group("crew"):
		if player.position.distance_to(local) < 2.5:
			player.knock_down(Vector2(player.position.x - local.x, player.position.z - local.z).normalized())
