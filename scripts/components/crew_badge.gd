extends Node3D
## Who's who and who's doing what (Olivier, 2026-10-24: "hard to understand what the other AI are
## doing"). A ring in the player's colour under their feet, and above their head a big job icon
## (wheel, shovel, water drop, hammer, spyglass, cannon, crate, fish) on a disc of their colour,
## next to a bigger P-tag. AIs always show their current job; humans show it while at a station.
## The icon follows what they're actually doing, not the job they were hired for. A child of
## each crew member (crew_player.gd adds it); the crew panel (crew_panel.gd) uses the same jobs.

const ICONS := "res://assets/art/export/ui/icons/"
const ICON_PIXEL := 0.011 ## the disc: 128 px = 1.4 m, readable from the 40-degree camera
const TAG_FONT := 88
const TAG_PIXEL := 0.009 ## P-tag letters about 0.8 m tall
## Job -> one word for the crew panel.
const WORDS := {"helm": "Steering", "engine": "Stoking", "pump": "Pumping", "navigator": "Lookout",
		"carpenter": "Repairs", "cargo": "Cargo", "gunner": "Cannons", "fishing": "Fishing"}

var job := "" ## what the icon shows now ("" = nothing)

var _player: Node3D
var _disc: Sprite3D
var _glyph: Sprite3D
var _label: Label3D


## What a crew member is doing right now, as a job name ("" = nothing in particular).
static func job_of(player: Node) -> String:
	var station: Node = player.get("station")
	if station and station.is_in_group("fishing_spots"):
		return "fishing"
	var ai := player.get_node_or_null("AICrew")
	var ai_job: Variant = ai.get("job") if ai else null
	if ai_job:
		return ai_job
	return station_job(station) if station else ""


static func station_job(station: Node) -> String:
	if station.is_in_group("cannons"):
		return "gunner"
	match String(station.name):
		"Helm":
			return "helm"
		"Engine":
			return "engine"
		"Pump":
			return "pump"
		"Lookout", "Telescope":
			return "navigator"
	if station.is_in_group("breaches") or String(station.name).begins_with("Leak") or String(station.name) == "CoolingPipe":
		return "carpenter"
	return ""


static func icon(name: String) -> Texture2D:
	var path := ICONS + name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


func _ready() -> void:
	name = "CrewBadge"
	_player = get_parent()
	var colour: Color = _player.COLORS[_player.player_index - 1]
	_label = _player.get_node("Label")
	_label.font_size = TAG_FONT
	_label.pixel_size = TAG_PIXEL
	_label.outline_size = 22
	# The ring on the deck.
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.85
	torus.rings = 32
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = colour
	torus.material = paint
	ring.mesh = torus
	ring.scale = Vector3(1.0, 0.15, 1.0)
	ring.position.y = 0.06
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	# The job icon, left of the P-tag.
	_disc = _sprite(icon("disc"), ICON_PIXEL, 11)
	_disc.modulate = colour
	_disc.position.y = _label.position.y
	_disc.offset = Vector2(-75, 0)
	add_child(_disc)
	_glyph = _sprite(null, ICON_PIXEL * 0.72, 12)
	_glyph.offset = _disc.offset / 0.72
	_disc.add_child(_glyph)
	_disc.visible = false


func _sprite(texture: Texture2D, pixel: float, priority: int) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = pixel
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.no_depth_test = true
	sprite.render_priority = priority
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return sprite


func _process(_delta: float) -> void:
	var now := job_of(_player)
	if now == job:
		return
	job = now
	_disc.visible = job != ""
	_glyph.texture = icon(job) if job != "" else null
	_label.offset = Vector2(95, 0) if _disc.visible else Vector2.ZERO
