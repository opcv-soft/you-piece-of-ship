extends Sprite3D
## A comic-strip bubble ("phylactère") above a crew member's head: short, readable, always on top.
## Two styles: "think" (white cloud with little trailing circles: what I'm about to do) and "shout"
## (yellow with a pointy tail: callouts like "Rock, 2 o'clock, 11 m!"). Drawn once into a small
## SubViewport whenever the text changes, then shown as a billboard sprite (cheap: no redraw per frame).

@export var height := 3.3 ## metres above the feet
@export var font_size := 30

## Opacity of the dark backing behind prompts and HUD text (Developer → Tune → Legibility).
static var backing_opacity := 0.3

var text := ""
var style := "think"
var _left := 0.0
var _viewport: SubViewport
var _panel: PanelContainer
var _label: Label
var _tail: Control


func _ready() -> void:
	name = "ThoughtBubble"
	position = Vector3(0.0, height, 0.0)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	render_priority = 10
	pixel_size = 0.014
	offset = Vector2(0, 75) # the tail sits at the bottom: grow upward from the head
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visible = false
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.size = Vector2i(700, 190)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)
	_panel = PanelContainer.new()
	_viewport.add_child(_panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", Color(0.16, 0.11, 0.09))
	if has_node("/root/UI"):
		_label.add_theme_font_override("font", get_node("/root/UI").display_font())
	_panel.add_child(_label)
	_tail = Control.new()
	_tail.draw.connect(_draw_tail)
	_viewport.add_child(_tail)
	texture = _viewport.get_texture()


## Shows a bubble for a few seconds. Saying the same thing again just keeps it up.
func show_text(new_text: String, seconds := 2.5, new_style := "think") -> void:
	if new_text == "":
		return
	var changed := new_text != text or new_style != style or not visible
	text = new_text
	style = new_style
	_left = seconds
	if not changed:
		return
	_label.text = text
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1.0, 0.86, 0.3) if style == "shout" else Color(1, 1, 1)
	box.border_color = Color(0.16, 0.11, 0.09)
	box.set_border_width_all(4)
	box.set_corner_radius_all(30 if style == "think" else 16)
	# "prompt": what Use does here, light text on a dark see-through backing.
	_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.86) if style == "prompt" else Color(0.16, 0.11, 0.09))
	if style == "prompt":
		box.bg_color = Color(0.04, 0.06, 0.1, backing_opacity)
		box.set_border_width_all(0)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 8
	box.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", box)
	# Fit the bubble to the text, centred, with room for the tail below.
	var text_size := _label.get_theme_font("font").get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var panel_size := Vector2(minf(text_size.x + 52.0, 690.0), text_size.y + 22.0)
	_panel.size = panel_size
	_panel.position = Vector2((700.0 - panel_size.x) * 0.5, 6.0)
	_tail.size = Vector2(700, 190)
	_tail.queue_redraw()
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	visible = true
	scale = Vector3.ONE * 0.4
	var pop := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(self, "scale", Vector3.ONE, 0.22)


func hide_now() -> void:
	visible = false
	_left = 0.0


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	if _left <= 0.0:
		visible = false
		text = ""


func _draw_tail() -> void:
	if style == "prompt":
		return
	var ink := Color(0.16, 0.11, 0.09)
	var fill := Color(1.0, 0.86, 0.3) if style == "shout" else Color(1, 1, 1)
	var bottom := _panel.position.y + _panel.size.y
	var centre := 350.0
	if style == "think":
		for dot in [[Vector2(centre - 6, bottom + 16), 11.0], [Vector2(centre - 16, bottom + 40), 7.0]]:
			_tail.draw_circle(dot[0], dot[1] + 3.0, ink)
			_tail.draw_circle(dot[0], dot[1], fill)
	else:
		var points := PackedVector2Array([Vector2(centre - 18, bottom - 4), Vector2(centre + 14, bottom - 4),
				Vector2(centre - 10, bottom + 34)])
		_tail.draw_colored_polygon(points, fill)
		_tail.draw_line(points[0] + Vector2(0, 4), points[2], ink, 4.0, true)
		_tail.draw_line(points[1] + Vector2(0, 4), points[2], ink, 4.0, true)
