extends Control
## Results: did we make it, how long, how much cargo, how dry, the score, personal bests, and the
## story of what went wrong. HD cartoon panel; the numbers roll up, coins burst, records get stamped.
## R / Start sails again with the same crew; Enter / A goes back to the dock; J changes the crew.

signal sail_again_pressed
signal map_pressed
signal change_crew_pressed

## Ink on parchment (Olivier, 2026-10-24: the old dark panel didn't match the painted look).
const GOOD := Color(0.18, 0.5, 0.22)
const BAD := Color(0.78, 0.2, 0.15)
const INK := Color(0.27, 0.16, 0.1)
const PAPER := Color(1.0, 0.95, 0.84)
const WOOD := Color(0.45, 0.26, 0.13)

var outcome := {}
var recap: Array[Dictionary] = []

var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _rows: GridContainer
var _score: Label
var _coins: Label
var _breakdown: Label
var _stamp: Label
var _story: VBoxContainer
var _footer: Label
var _stars: Array[Label] = []
var _next_star: Label


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


## Scores a finished voyage. Delivered: cargo value + up to 200 for a dry hull + 2 per second
## early. Sunk: nothing delivered, score 0.
## bonus: extra points earned on the way (fish caught, loot scooped up).
static func score(delivered: bool, cargo_value: int, water: float, elapsed: float, deadline: float, bonus := 0) -> Dictionary:
	if not delivered:
		return {"cargo": 0, "hull": 0, "time": 0, "bonus": 0, "total": 0}
	var hull := roundi((1.0 - water) * 200.0)
	var time := maxi(0, roundi((deadline - elapsed) * 2.0))
	return {"cargo": cargo_value, "hull": hull, "time": time, "bonus": bonus, "total": cargo_value + hull + time + bonus}


func show_results(data: Dictionary, story: Array[Dictionary]) -> void:
	outcome = data
	recap = story
	visible = true
	_fill()
	_animate()


func _fill() -> void:
	_title.text = tr("DELIVERED!") if outcome.delivered else tr("SUNK!")
	_title.add_theme_color_override("font_color", UI.YELLOW if outcome.delivered else Color(1.0, 0.42, 0.32))
	_subtitle.text = tr(outcome.contract)
	for child in _rows.get_children():
		child.queue_free()
	var lines := [
		[tr("Time"), tr("%s (deadline %s)") % [outcome.time_text, outcome.deadline_text], outcome.on_time],
		[tr("Cargo"), tr("%d of %d crates") % [outcome.crates, outcome.crates_loaded], outcome.crates == outcome.crates_loaded],
		[tr("Hull"), tr("%d%% dry") % roundi((1.0 - outcome.water) * 100.0), outcome.water < 0.3],
	]
	if not outcome.delivered:
		lines.append([tr("Distance"), tr("%d%% of the way") % roundi(outcome.progress * 100.0), false])
	var haul: Dictionary = outcome.get("haul", {})
	var parts := PackedStringArray()
	for resource in ["gold", "coal", "planks", "grease", "siren"]:
		if haul.get(resource, 0) > 0:
			parts.append("%d %s" % [haul[resource], tr({"gold": "gold", "coal": "charcoal", "planks": "planks",
					"grease": "whale grease", "siren": "siren"}[resource])])
	if not parts.is_empty():
		lines.append([tr("Haul"), " · ".join(parts), true])
	if outcome.has("best_score"):
		lines.append([tr("Best"), tr("%d points, %s") % [outcome.best_score, outcome.best_time_text], true])
	for line in lines:
		var key := Label.new()
		key.text = line[0]
		key.add_theme_color_override("font_color", Color(INK, 0.7))
		key.add_theme_constant_override("outline_size", 0)
		_rows.add_child(key)
		var value := Label.new()
		value.text = line[1]
		value.add_theme_color_override("font_color", GOOD if line[2] else BAD)
		value.add_theme_constant_override("outline_size", 0)
		_rows.add_child(value)
	var s: Dictionary = outcome.score
	_breakdown.text = tr("cargo %d + dry hull %d + early %d") % [s.cargo, s.hull, s.time]
	if s.get("bonus", 0) > 0:
		_breakdown.text += tr(" + fish & loot %d") % s.bonus
	var earned: int = outcome.get("stars", 0)
	var limits: Array = outcome.get("star_limits", [])
	for i in _stars.size():
		_stars[i].add_theme_color_override("font_color", Color(INK, 0.18))
	_next_star.text = ""
	if earned < 3 and limits.size() == 3 and outcome.delivered:
		_next_star.text = tr("Next star at %d points") % int(limits[earned])
	_coins.visible = outcome.has("earned")
	var records: Dictionary = outcome.get("records", {})
	_stamp.visible = records.get("score", false) or records.get("time", false)
	if _stamp.visible:
		_stamp.text = tr("NEW BEST SCORE & TIME!") if records.score and records.time else (
				tr("NEW BEST SCORE!") if records.score else tr("NEW BEST TIME!"))
	for child in _story.get_children():
		child.queue_free()
	if recap.is_empty():
		_story.add_child(_line("", tr("Nothing went wrong. Suspicious."), INK))
	for entry in recap:
		var stamp := "%d:%02d" % [int(entry.time) / 60, int(entry.time) % 60]
		var color := BAD if entry.kind == "bad" else (GOOD if entry.kind == "good" else INK)
		_story.add_child(_line(stamp, _translate(entry), color))
	_footer.text = ""


func _translate(entry: Dictionary) -> String:
	var args := []
	for arg in entry.get("args", []):
		args.append(tr(arg) if arg is String else arg)
	return tr(entry.get("key", entry.text)) % args if not args.is_empty() else tr(entry.get("key", entry.text))


func _animate() -> void:
	UI.pop_in(_panel)
	UI.play("stamp")
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2(2.2, 2.2)
	_title.create_tween().tween_property(_title, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	UI.roll_up(_score, outcome.score.total, 1.0, tr("SCORE %d"))
	if outcome.has("earned"):
		UI.roll_up(_coins, outcome.earned, 1.0, tr("+%d coins"))
		if outcome.earned > 0:
			get_tree().create_timer(0.9).timeout.connect(func():
				if is_inside_tree():
					UI.coin_burst(_coins.get_global_rect().get_center(), 22))
	for i in int(outcome.get("stars", 0)):
		get_tree().create_timer(1.0 + i * 0.4).timeout.connect(_star_in.bind(i))
	if _stamp.visible:
		_stamp.modulate.a = 0.0
		get_tree().create_timer(1.1 + outcome.get("stars", 0) * 0.4).timeout.connect(_stamp_in)
	var delay := 0.4
	for line in _story.get_children():
		line.modulate.a = 0.0
		line.create_tween().tween_property(line, "modulate:a", 1.0, 0.2).set_delay(delay)
		delay += 0.08


## One earned star lights up: gold, a big pop and a rising chime.
func _star_in(index: int) -> void:
	if not is_inside_tree():
		return
	var star := _stars[index]
	star.add_theme_color_override("font_color", UI.YELLOW)
	star.pivot_offset = star.size * 0.5
	star.scale = Vector2(2.4, 2.4)
	star.rotation = deg_to_rad(-25)
	var tween := star.create_tween().set_parallel()
	tween.tween_property(star, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "rotation", 0.0, 0.3)
	UI.play("coin")
	UI.coin_burst(star.get_global_rect().get_center(), 10)


func _stamp_in() -> void:
	if not is_inside_tree():
		return
	UI.play("stamp")
	_stamp.modulate.a = 1.0
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.scale = Vector2(3, 3)
	_stamp.rotation = deg_to_rad(-14)
	var tween := _stamp.create_tween().set_parallel()
	tween.tween_property(_stamp, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_stamp, "rotation", deg_to_rad(-6), 0.25)


func _line(stamp: String, text: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	var time := Label.new()
	time.text = stamp
	time.custom_minimum_size = Vector2(56, 0)
	time.add_theme_font_size_override("font_size", 14)
	time.add_theme_color_override("font_color", Color(INK, 0.5))
	time.add_theme_constant_override("outline_size", 0)
	row.add_child(time)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.12, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	# A parchment card in a wooden frame; two columns so it stays short enough for any window.
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(880, 0)
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = WOOD
	paper.set_border_width_all(10)
	paper.set_corner_radius_all(26)
	paper.content_margin_left = 30
	paper.content_margin_right = 30
	paper.content_margin_top = 16
	paper.content_margin_bottom = 18
	paper.shadow_color = Color(0, 0, 0, 0.4)
	paper.shadow_size = 16
	paper.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", paper)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	_stamp = Label.new()
	_stamp.add_theme_font_size_override("font_size", 22)
	_stamp.add_theme_color_override("font_color", BAD)
	_stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(_stamp)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 56)
	_title.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.06))
	_title.add_theme_constant_override("outline_size", 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", INK)
	_subtitle.add_theme_constant_override("outline_size", 0)
	box.add_child(_subtitle)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	box.add_child(columns)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(390, 0)
	columns.add_child(left)
	var star_row := HBoxContainer.new()
	star_row.alignment = BoxContainer.ALIGNMENT_CENTER
	star_row.add_theme_constant_override("separation", 14)
	left.add_child(star_row)
	for i in 3:
		var star := Label.new()
		star.text = "★"
		star.add_theme_font_size_override("font_size", 64 if i == 1 else 52)
		star.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.06))
		star.add_theme_constant_override("outline_size", 10)
		star_row.add_child(star)
		_stars.append(star)
	_next_star = Label.new()
	_next_star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_next_star.add_theme_font_size_override("font_size", 14)
	_next_star.add_theme_color_override("font_color", Color(INK, 0.7))
	_next_star.add_theme_constant_override("outline_size", 0)
	left.add_child(_next_star)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override("h_separation", 20)
	left.add_child(_rows)
	var score_row := HBoxContainer.new()
	left.add_child(score_row)
	_score = Label.new()
	_score.add_theme_font_size_override("font_size", 32)
	_score.add_theme_color_override("font_color", WOOD)
	_score.add_theme_constant_override("outline_size", 0)
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(_score)
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 24)
	_coins.add_theme_color_override("font_color", Color(0.75, 0.5, 0.05))
	_coins.add_theme_constant_override("outline_size", 0)
	score_row.add_child(_coins)
	_breakdown = Label.new()
	_breakdown.add_theme_font_size_override("font_size", 13)
	_breakdown.add_theme_color_override("font_color", Color(INK, 0.6))
	_breakdown.add_theme_constant_override("outline_size", 0)
	_breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_breakdown)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	var heading := Label.new()
	heading.text = tr("WHAT HAPPENED")
	heading.add_theme_color_override("font_color", WOOD)
	heading.add_theme_constant_override("outline_size", 0)
	right.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 250)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_story = VBoxContainer.new()
	_story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_story.add_theme_constant_override("separation", 0)
	scroll.add_child(_story)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)
	for spec in [["Sail again  (R)", sail_again_pressed], ["World map  (Enter)", map_pressed], ["Change crew  (J)", change_crew_pressed]]:
		var button := Button.new()
		button.text = tr(spec[0])
		button.custom_minimum_size = Vector2(220, 46)
		for state in ["normal", "hover", "pressed", "focus"]:
			var plank := StyleBoxFlat.new()
			plank.bg_color = WOOD.lightened(0.15) if state == "hover" else (WOOD.darkened(0.2) if state == "pressed" else WOOD)
			if state == "focus":
				plank.bg_color = Color(0, 0, 0, 0)
				plank.border_color = UI.YELLOW
				plank.set_border_width_all(4)
			plank.set_corner_radius_all(14)
			plank.set_content_margin_all(8)
			button.add_theme_stylebox_override(state, plank)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_focus_color", Color.WHITE)
		var on_press: Signal = spec[1]
		button.pressed.connect(func(): on_press.emit())
		buttons.add_child(button)
	_footer = Label.new()
	_footer.visible = false
	box.add_child(_footer)
