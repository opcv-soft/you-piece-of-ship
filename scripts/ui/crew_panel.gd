extends PanelContainer
## The crew panel (Claude's playtest, 2026-10-24: you couldn't tell what each AI was doing). Top-left
## corner: one row per crew member with their colour, P-tag, job icon and one word ("Steering",
## "Repairs"...). Same jobs as the icons over their heads (crew_badge.gd). Added by voyage.gd.

const CrewBadge = preload("res://scripts/components/crew_badge.gd")

var _rows := {} ## player -> [disc, glyph, word, row, tag]
var _list: VBoxContainer
var _refresh := 0.0


func _ready() -> void:
	name = "CrewPanel"
	position = Vector2(12, 12)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.06, 0.1, 0.8)
	box.set_corner_radius_all(14)
	box.content_margin_left = 12
	box.content_margin_right = 16
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	add_theme_stylebox_override("panel", box)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	add_child(_list)


func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh > 0.0:
		return
	_refresh = 0.25
	var crew := get_tree().get_nodes_in_group("crew")
	crew.sort_custom(func(a, b): return a.player_index < b.player_index)
	for player in _rows.keys():
		if not is_instance_valid(player) or not crew.has(player):
			_rows[player][3].queue_free()
			_rows.erase(player)
	for player in crew:
		if not _rows.has(player):
			_rows[player] = _row(player)
		var job := CrewBadge.job_of(player)
		var row: Array = _rows[player]
		row[1].texture = CrewBadge.icon(job) if job != "" else null
		row[0].modulate.a = 1.0 if job != "" else 0.35
		row[2].text = tr(CrewBadge.WORDS.get(job, "Free"))
		row[4].text = (tr("P%d AI") if player.has_node("AICrew") else "P%d") % player.player_index
	visible = not crew.is_empty()


func _row(player: Node) -> Array:
	var colour: Color = player.COLORS[player.player_index - 1]
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var tag := Label.new()
	tag.custom_minimum_size.x = 64
	tag.add_theme_font_size_override("font_size", 20)
	tag.add_theme_color_override("font_color", colour.lightened(0.35))
	tag.add_theme_constant_override("outline_size", 8)
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	line.add_child(tag)
	var holder := Control.new() # the disc in their colour, the white glyph on top
	holder.custom_minimum_size = Vector2(28, 28)
	line.add_child(holder)
	var disc := _picture(CrewBadge.icon("disc"), 0)
	disc.modulate = colour
	holder.add_child(disc)
	var glyph := _picture(null, 4)
	holder.add_child(glyph)
	var word := Label.new()
	word.add_theme_font_size_override("font_size", 20)
	word.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86))
	line.add_child(word)
	_list.add_child(line)
	return [disc, glyph, word, line, tag]


func _picture(texture: Texture2D, inset: float) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = texture
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = inset
	picture.offset_top = inset
	picture.offset_right = -inset
	picture.offset_bottom = -inset
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return picture
