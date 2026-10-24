extends Node3D
## Coal on the deck (Olivier, 2026-10-24): spilled coal leaves streaky skid-mark smears, and crew
## who walk through one get sooty boots and track black footprints around the deck until the soot
## wears off. Lightweight: flat decals on the deck, a few dozen at most, the oldest fading away.
## A child of the ship; ship.add_coal_mark() adds smears.

const MAX_SMEARS := 40
const MAX_PRINTS := 140

@export var print_spacing := 0.5 ## metres walked between two footprints
@export var soot_per_print := 0.12 ## boots get cleaner with each print
@export var print_seconds := 25.0 ## footprints fade over this long

var smears: Array = [] ## [mesh, radius, soot left]
var _prints: Array = [] ## [mesh, age]
var _soot := {} ## crew member -> soot on their boots (0..1)
var _last_print := {} ## crew member -> where they last left a print
static var _smear_material: StandardMaterial3D
static var _print_material: StandardMaterial3D


func _ready() -> void:
	name = "CoalSmears"


## A smear of spilled coal at a ship-local point, stretched along dir (the way it skidded).
func add_smear(local: Vector3, size := 1.0, dir := Vector2.ZERO) -> MeshInstance3D:
	var smear := MeshInstance3D.new()
	smear.add_to_group("coal_marks")
	var quad := PlaneMesh.new()
	var length := 1.2 + clampf(size, 0.1, 1.5) * 1.6
	var width := 0.6 + clampf(size, 0.1, 1.5) * 0.5
	quad.size = Vector2(length, width)
	quad.material = smear_material()
	smear.mesh = quad
	smear.position = Vector3(local.x, 0.012, local.z)
	smear.rotation.y = atan2(-dir.y, dir.x) if dir.length() > 0.05 else randf() * TAU
	smear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smear)
	smears.append([smear, length * 0.5, clampf(size, 0.3, 1.5)])
	if smears.size() > MAX_SMEARS:
		var oldest: Array = smears.pop_front()
		oldest[0].queue_free()
	return smear


## How much soot a crew member carries on their boots.
func soot_of(player: Node3D) -> float:
	return _soot.get(player, 0.0)


func _physics_process(delta: float) -> void:
	_age_prints(delta)
	var ship := get_parent() as Node3D
	for player in get_tree().get_nodes_in_group("crew"):
		if player.get_parent() == null or not ship.is_ancestor_of(player):
			continue
		var feet: Vector3 = ship.to_local(player.global_position)
		var flat := Vector2(feet.x, feet.z)
		# Stepping in a smear: sooty boots (and the smear gets a little thinner).
		for entry in smears:
			var mesh: MeshInstance3D = entry[0]
			if entry[2] > 0.05 and flat.distance_to(Vector2(mesh.position.x, mesh.position.z)) < entry[1]:
				_soot[player] = 1.0
				entry[2] -= delta * 0.4
				mesh.transparency = clampf(1.0 - entry[2], 0.0, 0.85)
		var soot: float = _soot.get(player, 0.0)
		if soot <= 0.05 or feet.y > 0.6: # clean, or up the mast
			_last_print[player] = flat
			continue
		var last: Vector2 = _last_print.get(player, flat)
		if flat.distance_to(last) >= print_spacing:
			_footprint(flat, (flat - last).normalized(), soot)
			_last_print[player] = flat
			_soot[player] = soot - soot_per_print


func _footprint(at: Vector2, dir: Vector2, soot: float) -> void:
	var foot := MeshInstance3D.new()
	foot.add_to_group("coal_prints")
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.32, 0.18)
	quad.material = print_material()
	foot.mesh = quad
	var side := Vector2(-dir.y, dir.x) * (0.12 if _prints.size() % 2 == 0 else -0.12) # left, right, left...
	foot.position = Vector3(at.x + side.x, 0.013, at.y + side.y)
	foot.rotation.y = atan2(-dir.y, dir.x)
	foot.transparency = 1.0 - clampf(soot, 0.15, 0.9)
	foot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(foot)
	_prints.append([foot, 0.0])
	if _prints.size() > MAX_PRINTS:
		var oldest: Array = _prints.pop_front()
		oldest[0].queue_free()


func _age_prints(delta: float) -> void:
	for i in range(_prints.size() - 1, -1, -1):
		var entry: Array = _prints[i]
		entry[1] += delta
		if entry[1] > print_seconds:
			entry[0].queue_free()
			_prints.remove_at(i)
		elif entry[1] > print_seconds * 0.6:
			entry[0].transparency = minf(0.97, entry[0].transparency + delta / (print_seconds * 0.4))


## Streaky black skid marks, drawn once.
static func smear_material() -> StandardMaterial3D:
	if _smear_material:
		return _smear_material
	var image := Image.create(160, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for streak in 14:
		var y := rng.randi_range(6, 57)
		var start := rng.randi_range(0, 40)
		var length := rng.randi_range(60, 155 - start)
		var thick := rng.randi_range(2, 6)
		var dark := rng.randf_range(0.5, 0.95)
		for x in range(start, start + length):
			var fade := sin(PI * float(x - start) / length) # tapered ends
			for dy in range(-thick, thick + 1):
				var py := clampi(y + dy + int(sin(x * 0.08 + streak) * 2.0), 0, 63)
				var alpha := dark * fade * (1.0 - absf(dy) / (thick + 1.0)) * rng.randf_range(0.7, 1.0)
				var old := image.get_pixel(x, py)
				image.set_pixel(x, py, Color(0.05, 0.045, 0.05, maxf(old.a, alpha)))
	_smear_material = _decal_material(ImageTexture.create_from_image(image))
	return _smear_material


## A little sooty boot print.
static func print_material() -> StandardMaterial3D:
	if _print_material:
		return _print_material
	var image := Image.create(32, 18, false, Image.FORMAT_RGBA8)
	for x in 32:
		for y in 18:
			var dx := (x - 16.0) / 15.0
			var dy := (y - 9.0) / 8.0
			if dx * dx + dy * dy < 1.0 and not (x > 12 and x < 15): # sole and heel
				image.set_pixel(x, y, Color(0.05, 0.045, 0.05, 0.85))
	_print_material = _decal_material(ImageTexture.create_from_image(image))
	return _print_material


static func _decal_material(texture: Texture2D) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.render_priority = 2
	return material
