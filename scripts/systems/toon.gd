extends RefCounted
## The painted-kawaii palette (Olivier, 2026-10-22). Models from Blender only carry material
## *names*; this paints them: warm woods, pastel paints, gold trim, a soft outline on solid things.
## One shared material per name (cheap: the renderer batches them).

const TOON = preload("res://assets/shaders/toon.gdshader")
const TOON_SEE_THROUGH = preload("res://assets/shaders/toon_see_through.gdshader")
const OUTLINE = preload("res://assets/shaders/outline.gdshader")

## name -> [colour, emission, outline?, glossy]
const PALETTE := {
	"wood_hull": [Color(0.62, 0.36, 0.22), 0.0, true, 0.15],
	"wood_light": [Color(0.93, 0.72, 0.47), 0.0, true, 0.15],
	"wood_dark": [Color(0.4, 0.23, 0.14), 0.0, true, 0.15],
	"deck": [Color("B8895B"), 0.0, false, 0.05], # darker deck (Olivier, 2026-10-24)
	"paint_red": [Color(0.94, 0.38, 0.36), 0.0, true, 0.4],
	"paint_teal": [Color(0.28, 0.72, 0.74), 0.0, true, 0.4],
	"trim_cream": [Color(1.0, 0.95, 0.82), 0.0, true, 0.3],
	"gold": [Color(1.0, 0.8, 0.3), 0.15, true, 0.9],
	"iron": [Color(0.3, 0.3, 0.38), 0.0, true, 0.6],
	"sail": [Color(1.0, 0.97, 0.9), 0.08, false, 0.0],
	"sail_stripe": [Color(0.94, 0.38, 0.36), 0.05, false, 0.0],
	"rope": [Color(0.85, 0.72, 0.5), 0.0, false, 0.0],
	"glow": [Color(1.0, 0.86, 0.45), 1.6, false, 0.0],
	"glass": [Color(0.25, 0.35, 0.55), 0.0, true, 1.0],
	"rock": [Color(0.62, 0.62, 0.7), 0.0, true, 0.1],
	"rock_dark": [Color(0.44, 0.44, 0.54), 0.0, true, 0.1],
	"moss": [Color(0.5, 0.76, 0.42), 0.0, true, 0.1],
	"sand": [Color(1.0, 0.9, 0.66), 0.0, true, 0.05],
	"leaf": [Color(0.4, 0.8, 0.38), 0.0, true, 0.2],
	"whale": [Color(0.38, 0.52, 0.82), 0.0, true, 0.5],
	"belly": [Color(0.94, 0.95, 1.0), 0.0, true, 0.3],
	"skin": [Color(1.0, 0.84, 0.72), 0.0, true, 0.3],
	"eye": [Color(0.1, 0.07, 0.12), 0.0, false, 1.0],
	"white": [Color(1.0, 1.0, 1.0), 0.5, false, 0.0],
	"blush": [Color(1.0, 0.58, 0.64), 0.1, false, 0.0],
	"tail": [Color(0.35, 0.8, 0.74), 0.0, true, 0.7],
	"hair": [Color(1.0, 0.5, 0.62), 0.0, true, 0.4],
	"flag": [Color(0.94, 0.32, 0.32), 0.0, false, 0.0],
	"coal": [Color(0.16, 0.15, 0.18), 0.0, false, 0.6],
	"water": [Color(0.45, 0.8, 1.0), 0.3, false, 1.0],
	"player": [Color(1.0, 1.0, 1.0), 0.0, true, 0.4],
}

static var _cache := {}
static var painted := true ## the voyage's look: false when the ship uses the pixel or grey-box style


## The toon material for a palette name (unknown names get a friendly grey).
static func material(name: String, tint := Color(-1, 0, 0)) -> ShaderMaterial:
	var key := name + (str(tint) if tint.r >= 0.0 else "")
	if _cache.has(key):
		return _cache[key]
	var entry: Array = PALETTE.get(name, [Color(0.8, 0.8, 0.82), 0.0, true, 0.2])
	var mat := ShaderMaterial.new()
	mat.shader = TOON
	mat.set_shader_parameter("albedo", tint if tint.r >= 0.0 else entry[0])
	mat.set_shader_parameter("emission_strength", entry[1])
	mat.set_shader_parameter("glossy", entry[3])
	if name.begins_with("sail"):
		mat.shader = TOON_SEE_THROUGH
		mat.set_shader_parameter("alpha", 0.38) # see the crew working under the sails
		mat.render_priority = 1
	if entry[2]:
		var outline := ShaderMaterial.new()
		outline.shader = OUTLINE
		mat.next_pass = outline
	_cache[key] = mat
	return mat


## A see-through copy of a painted material (a sailor working a station fades so you can see
## what they're working on).
static func see_through(source: Material, alpha := 0.35) -> Material:
	if not source is ShaderMaterial:
		return source
	var key := "see_through_%d_%.2f" % [source.get_instance_id(), alpha]
	if _cache.has(key):
		return _cache[key]
	var faded := (source as ShaderMaterial).duplicate() as ShaderMaterial
	faded.shader = TOON_SEE_THROUGH
	faded.set_shader_parameter("alpha", alpha)
	faded.next_pass = null
	faded.render_priority = 3
	_cache[key] = faded
	return faded


## Paints every mesh under a node by its surface material names. A name prefix up to the first
## "." is used, so Blender's "gold.001" still means gold. tints: name -> Color overrides.
static func paint(root: Node, tints := {}) -> void:
	for node in _meshes(root):
		var mesh: Mesh = node.mesh
		for surface in mesh.get_surface_count():
			var source := mesh.surface_get_material(surface)
			var name := source.resource_name.get_slice(".", 0) if source else ""
			node.set_surface_override_material(surface, material(name, tints.get(name, Color(-1, 0, 0))))


static func _meshes(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		found.append(root)
	for child in root.get_children():
		found.append_array(_meshes(child))
	return found
