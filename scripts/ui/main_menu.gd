extends Control
## The main menu (Olivier's mockup, 2026-10-22): the title on a wooden sign, big cartoon buttons,
## a painted deck scene behind, couch-party style. Quick Play jumps straight into a voyage with
## AI crewmates filling the empty posts.

const MenuItem = preload("res://scripts/ui/menu_item.gd")
const LogoSign = preload("res://scripts/ui/logo_sign.gd")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const VERSION := "v0.4.0"
const DOCK := "res://scenes/levels/dock.tscn"
const WORLD_MAP := "res://scenes/ui/world_map.tscn"
const VOYAGE := "res://scenes/levels/voyage.tscn"

var buttons := {}
var _background: TextureRect
var _time := 0.0
var _settings: PanelContainer
var _join: PanelContainer
var _join_address: LineEdit
var _join_status: Label
var _tagline: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	refresh_texts()
	Net.connected.connect(func(_index): _go(DOCK))
	Net.connection_failed.connect(_on_join_failed)
	await get_tree().process_frame
	var delay := 0.15
	for key in ["quick", "map", "host", "join", "ship", "settings", "quit"]:
		UI.pop_in(buttons[key], delay)
		delay += 0.07
	buttons.quick.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	# The painted deck sways gently, like the ship rocking (scale and turn only: it stays full-screen).
	_background.pivot_offset = _background.size * 0.5
	_background.scale = Vector2.ONE * (1.05 + sin(_time * 0.25) * 0.015)
	_background.rotation = sin(_time * 0.35) * 0.008


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_panels()


## Changes screen (only when the menu really is the current screen, not inside tests).
func _go(scene_path: String) -> void:
	if is_inside_tree() and get_tree().current_scene == self:
		UI.go(scene_path)


# --- Actions ----------------------------------------------------------------------------------

## Quick Play: a random open contract now, with AI crewmates in every empty post.
func quick_play() -> void:
	if Session.joined_players.is_empty():
		Session.joined_players = [1] as Array[int]
	Session.fill_crew_with_ai()
	var open: Array = Session.open_contracts()
	Session.contract_index = open[randi() % open.size()] if not open.is_empty() else 0
	_go(VOYAGE)


func host_game() -> void:
	if Net.host() != OK:
		UI.play("error")
		return
	_go(DOCK)


func open_join() -> void:
	_close_panels()
	_join.visible = true
	UI.pop_in(_join)
	_join_address.text = Session.last_join_address
	_join_address.grab_focus()


func join_game() -> void:
	var address := _join_address.text.strip_edges()
	if address == "":
		_join_status.text = tr("Type your friend's address first.")
		UI.play("error")
		return
	Session.last_join_address = address
	Session.save_game()
	if Net.join(address) != OK:
		_join_status.text = tr("That address doesn't look right.")
		UI.play("error")
	else:
		_join_status.text = tr("Joining %s...") % address


func _on_join_failed() -> void:
	_join_status.text = tr("Couldn't reach that address. Check it with your friend.")
	UI.play("error")


func open_settings() -> void:
	_close_panels()
	_settings.visible = true
	UI.pop_in(_settings)
	_settings.find_child("Language", true, false).grab_focus()


func _close_panels() -> void:
	_settings.visible = false
	_join.visible = false
	if buttons.has("quick"):
		buttons.quick.grab_focus()


# --- Settings ---------------------------------------------------------------------------------

func toggle_language() -> void:
	var now := TranslationServer.get_locale().substr(0, 2)
	Session.language = "en" if now == "fr" else "fr"
	Session.apply_settings()
	Session.save_game()
	refresh_texts()


func set_volume(value: float) -> void:
	Session.music_volume_db = value
	Session.apply_settings()
	Session.save_game()


func set_fullscreen(on: bool) -> void:
	Session.fullscreen = on
	Session.apply_settings()
	Session.save_game()


## Every visible text, in the current language (the title stays in English).
func refresh_texts() -> void:
	_tagline.text = tr("Same ship.\nDifferent view.\nTotal chaos.")
	for button in buttons.values():
		button.queue_redraw()
	var language: Button = _settings.find_child("Language", true, false)
	language.text = "Language: English" if TranslationServer.get_locale().begins_with("en") else "Langue : français"
	for label in _settings.find_children("*", "Label", true, false) + _join.find_children("*", "Label", true, false):
		if label.has_meta("key"):
			label.text = tr(label.get_meta("key"))
	for button in _settings.find_children("*", "BaseButton", true, false) + _join.find_children("*", "BaseButton", true, false):
		if button.has_meta("key"):
			button.text = tr(button.get_meta("key"))


# --- Building ---------------------------------------------------------------------------------

func _build() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.35, 0.62, 0.86)
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	_background = TextureRect.new()
	_background.texture = load("res://assets/art/export/ui/menu_background.png")
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.offset_left = 300
	add_child(_background)
	var shade := TextureRect.new() # a soft fade so the menu column reads over the painting
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.05, 0.12, 0.25, 0.95))
	gradient.set_color(1, Color(0.05, 0.12, 0.25, 0.0))
	var fade := GradientTexture2D.new()
	fade.gradient = gradient
	fade.fill_to = Vector2(1, 0)
	shade.texture = fade
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 620
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var logo := LogoSign.new()
	logo.position = Vector2(20, 6)
	logo.size = Vector2(430, 250)
	add_child(logo)

	var column := VBoxContainer.new()
	column.position = Vector2(40, 250)
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	for spec in [
		["quick", "Quick Play", "Jump into a random voyage", "wheel", true, quick_play],
		["map", "World Map", "Oceans, ports and routes", "map", false, func(): _go(WORLD_MAP)],
		["host", "Host Game", "Start a game with friends", "people", false, host_game],
		["join", "Join Game", "Enter your friend's address", "link", false, open_join],
		["ship", "Ship & Upgrades", "Crew, contracts and the shop", "crate", false, func(): _go(DOCK)],
		["settings", "Settings", "", "gear", false, open_settings],
		["quit", "Quit", "", "door", false, func(): get_tree().quit()],
	]:
		var item := MenuItem.new()
		item.name = spec[0]
		item.title = spec[1]
		item.subtitle = spec[2]
		item.glyph = spec[3]
		item.highlight = spec[4]
		item.pressed.connect(spec[5])
		if spec[0] in ["settings", "quit"]:
			# Settings and Quit share the last row, so seven entries fit on any screen.
			var last := column.get_node_or_null("LastRow") as HBoxContainer
			if last == null:
				last = HBoxContainer.new()
				last.name = "LastRow"
				last.add_theme_constant_override("separation", 6)
				column.add_child(last)
			item.compact = true
			last.add_child(item)
		else:
			column.add_child(item)
		buttons[spec[0]] = item

	_tagline = Label.new()
	_tagline.add_theme_font_size_override("font_size", 22)
	_tagline.add_theme_color_override("font_color", Color.WHITE)
	_tagline.add_theme_constant_override("outline_size", 8)
	_tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tagline.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_tagline.offset_left = -300
	_tagline.offset_top = 20
	_tagline.offset_right = -28
	_tagline.rotation = deg_to_rad(-6)
	add_child(_tagline)

	var badge := PanelContainer.new()
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.offset_left = -190
	badge.offset_top = -66
	badge.offset_right = -20
	badge.offset_bottom = -18
	var badge_text := Label.new()
	badge_text.set_meta("key", "4 PLAYERS CO-OP")
	badge_text.text = tr("4 PLAYERS CO-OP")
	badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_text.add_theme_font_size_override("font_size", 16)
	badge.add_child(badge_text)
	add_child(badge)

	var version := Label.new()
	version.text = VERSION
	version.add_theme_font_size_override("font_size", 12)
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.offset_left = 10
	version.offset_top = -22
	add_child(version)

	_settings = _panel("Settings")
	var language := Button.new()
	language.name = "Language"
	language.pressed.connect(toggle_language)
	_settings.get_child(0).add_child(language)
	var volume_label := _keyed_label("Music volume")
	_settings.get_child(0).add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = -40
	volume.max_value = 4
	volume.value = Session.music_volume_db
	volume.value_changed.connect(set_volume)
	_settings.get_child(0).add_child(volume)
	var full := CheckButton.new()
	full.set_meta("key", "Full screen")
	full.button_pressed = Session.fullscreen
	full.toggled.connect(set_fullscreen)
	_settings.get_child(0).add_child(full)
	var sea := CheckButton.new()
	sea.set_meta("key", "Realistic sea")
	sea.button_pressed = Session.realistic_sea
	sea.toggled.connect(func(on): Session.realistic_sea = on; Session.save_game())
	_settings.get_child(0).add_child(sea)
	_settings.get_child(0).add_child(_back_button())

	_join = _panel("Join Game")
	_join.get_child(0).add_child(_keyed_label("Your friend's address (they read it out from their screen):"))
	_join_address = LineEdit.new()
	_join_address.placeholder_text = "203.0.113.7"
	_join_address.text_submitted.connect(func(_t): join_game())
	_join.get_child(0).add_child(_join_address)
	var join_button := Button.new()
	join_button.set_meta("key", "Join")
	join_button.pressed.connect(join_game)
	_join.get_child(0).add_child(join_button)
	_join_status = Label.new()
	_join_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_join.get_child(0).add_child(_join_status)
	_join.get_child(0).add_child(_back_button())


func _panel(title_key: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(450, 170)
	panel.custom_minimum_size = Vector2(440, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := _keyed_label(title_key)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UI.YELLOW)
	box.add_child(title)
	add_child(panel)
	return panel


func _keyed_label(key: String) -> Label:
	var label := Label.new()
	label.set_meta("key", key)
	label.text = tr(key)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _back_button() -> Button:
	var back := Button.new()
	back.set_meta("key", "Back")
	back.pressed.connect(_close_panels)
	return back
