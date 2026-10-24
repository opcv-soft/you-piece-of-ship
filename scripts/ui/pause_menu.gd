extends CanvasLayer
## Esc during a voyage: the pause menu (resume, restart, dock, main menu) and the Developer panel
## (Olivier, 2026-10-22): live sliders for every tunable number on the ship, buttons that force
## events (crash, flood, reach port...), time scale and presets saved to user://dev_presets.json.
## The game keeps running while the Developer panel is open, so changes show straight away.
## Online, the game never pauses (the others are still playing).

var presets_path := "user://dev_presets.json"
const DOCK_SCENE := "res://scenes/levels/dock.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## Event buttons: [event id, label].
const EVENTS := [
	["crash", "Crash into a rock"], ["leak", "Open a leak"], ["flood", "Flood +30%"],
	["overheat", "Overheat engine"], ["stall", "Stall engine"], ["out_of_coal", "Empty the coal"],
	["rudder", "Break the rudder"], ["wave_port", "Big wave (port)"], ["wave_starboard", "Big wave (starboard)"],
	["loose_cargo", "Loose cargo"], ["reach_port", "Reach port"], ["sink", "Sink (fail)"],
	["add_coins", "+500 coins"], ["unlock_all", "Unlock everything"], ["god_mode", "God mode on/off"],
]

var voyage: Node ## the voyage this menu controls
var defaults := {} ## group -> property -> value when the panel first opened (for Reset)

var _pause: PanelContainer
var _dev: PanelContainer
var _tune_box: VBoxContainer
var _status: Label
var _filter: LineEdit
var _sliders := {} ## "group/property" -> Range or CheckBox


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_pause()
	_build_dev()
	_pause.visible = false
	_dev.visible = false


func _unhandled_input(event: InputEvent) -> void:
	var pause_button: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_ESCAPE):
		toggle()
		get_viewport().set_input_as_handled()
	elif pause_button and _pause.visible:
		close()


func is_open() -> bool:
	return _pause.visible or _dev.visible


## Esc: open the pause menu; Esc again (or from the Developer panel) closes everything.
func toggle() -> void:
	if is_open():
		close()
	else:
		open_pause()


func open_pause() -> void:
	_dev.visible = false
	_pause.visible = true
	UI.pop_in(_pause)
	get_tree().paused = Net.role == "offline"
	(_pause.find_child("Resume", true, false) as Button).grab_focus()


func open_dev() -> void:
	_pause.visible = false
	_dev.visible = true
	get_tree().paused = false # keep playing: see the changes live
	if defaults.is_empty():
		defaults = snapshot()
	_rebuild_tunables()


func close() -> void:
	_pause.visible = false
	_dev.visible = false
	get_tree().paused = false


# --- Tunables -------------------------------------------------------------------------------

## The groups of tunable nodes: name -> nodes (changes apply to every node in the group).
func groups() -> Dictionary:
	if voyage == null:
		return {}
	var ship: Node = voyage.get_node("Ship")
	var found := {
		"Ship handling": [ship.get_node("ShipHandling")],
		"Engine and coal": [ship.get_node("EngineSystem")],
		"Hull and leaks": [ship.get_node("HullSystem")],
		"Waves": [ship.get_node("WaveMotion")],
		"Rudder": [ship.get_node("RudderSystem")],
		"Cargo": [ship.get_node("LoadSystem")],
		"Hazards": [voyage.get_node("HazardDirector")],
		"Music": [voyage.get_node("Music")],
		"Camera": [voyage.get_node("SharedCamera")],
		"Game feel": [voyage.get_node("GameFeel")],
		"Crew": voyage.get_tree().get_nodes_in_group("crew"),
		"AI crew": voyage.get_tree().get_nodes_in_group("ai_crew"),
		"Fishing": voyage.get_tree().get_nodes_in_group("fishing_spots"),
	}
	for extra in voyage.get_tree().get_nodes_in_group("dev_tunable"):
		found[extra.get_meta("dev_group", extra.name)] = [extra]
	for key in found.keys():
		if found[key].is_empty():
			found.erase(key)
	return found


## The numbers and switches a node exposes in the editor (its @export variables).
static func tunable_properties(node: Object) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for property in node.get_property_list():
		var usage: int = property.usage
		if not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) or not (usage & PROPERTY_USAGE_EDITOR):
			continue
		if property.type in [TYPE_FLOAT, TYPE_INT, TYPE_BOOL]:
			result.append(property)
	return result


## Slider range for a property: its declared range, or a generous one around the current value.
static func range_for(property: Dictionary, value: float) -> Vector3:
	if property.hint == PROPERTY_HINT_RANGE:
		var parts: PackedStringArray = String(property.hint_string).split(",")
		if parts.size() >= 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
			var step := float(parts[2]) if parts.size() > 2 and parts[2].is_valid_float() else 0.0
			return Vector3(float(parts[0]), float(parts[1]), step)
	var top := maxf(absf(value) * 3.0, 1.0 if property.type == TYPE_FLOAT else 10.0)
	var bottom := -top if value < 0.0 else 0.0
	return Vector3(bottom, top, 1.0 if property.type == TYPE_INT else 0.0)


## Every tunable value right now: group -> property -> value (from the group's first node).
func snapshot() -> Dictionary:
	var values := {}
	var all := groups()
	for group in all:
		var node: Object = all[group][0]
		values[group] = {}
		for property in tunable_properties(node):
			var value = node.get(property.name)
			if value is float and is_inf(value):
				continue # JSON can't store infinity
			values[group][property.name] = value
	return values


## Sets a value on every node of a group.
func apply(group: String, property: String, value: Variant) -> void:
	var all := groups()
	for node in all.get(group, []):
		if property in node:
			node.set(property, value)


func apply_values(values: Dictionary) -> void:
	for group in values:
		for property in values[group]:
			apply(group, property, values[group][property])
	if _dev.visible:
		_rebuild_tunables()


func save_preset(slot: int) -> void:
	var presets := _load_presets()
	presets[str(slot)] = snapshot()
	var file := FileAccess.open(presets_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(presets, "  "))
	_status.text = tr("Saved preset %d.") % slot


func load_preset(slot: int) -> bool:
	var presets := _load_presets()
	if not presets.has(str(slot)):
		_status.text = tr("Preset %d is empty.") % slot
		return false
	apply_values(presets[str(slot)])
	_status.text = tr("Loaded preset %d.") % slot
	return true


func _load_presets() -> Dictionary:
	if not FileAccess.file_exists(presets_path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(presets_path))
	return data if data is Dictionary else {}


# --- Building the panels ---------------------------------------------------------------------

func _build_pause() -> void:
	_pause = PanelContainer.new()
	_pause.name = "Pause"
	_pause.set_anchors_preset(Control.PRESET_CENTER)
	_pause.custom_minimum_size = Vector2(340, 0)
	_pause.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pause.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_pause)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_pause.add_child(box)
	var title := Label.new()
	title.text = tr("Paused")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UI.YELLOW)
	box.add_child(title)
	for entry in [["Resume", "Resume", close], ["Restart", "Restart voyage", _restart],
			["Dock", "Back to the dock", _to_dock], ["Menu", "Main menu", _to_menu],
			["Developer", "Developer", open_dev]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = tr(entry[1])
		button.custom_minimum_size = Vector2(0, 48)
		button.pressed.connect(entry[2])
		box.add_child(button)


func _build_dev() -> void:
	_dev = PanelContainer.new()
	_dev.name = "Developer"
	_dev.anchor_left = 1.0
	_dev.anchor_right = 1.0
	_dev.anchor_bottom = 1.0
	_dev.offset_left = -440
	_dev.offset_top = 12
	_dev.offset_right = -12
	_dev.offset_bottom = -12
	add_child(_dev)
	var outer := VBoxContainer.new()
	_dev.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	var title := Label.new()
	title.text = tr("Developer")
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UI.YELLOW)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_button := Button.new()
	close_button.text = "✕"
	close_button.pressed.connect(close)
	head.add_child(close_button)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(tabs)
	# Events tab: force things to happen.
	var events_scroll := ScrollContainer.new()
	events_scroll.name = tr("Events")
	tabs.add_child(events_scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	events_scroll.add_child(grid)
	for entry in EVENTS:
		var button := Button.new()
		button.text = tr(entry[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_force.bind(entry[0]))
		grid.add_child(button)
	for extra in _extra_events():
		var button := Button.new()
		button.text = tr(extra[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(_force.bind(extra[0]))
		grid.add_child(button)
	var speed_label := Label.new()
	speed_label.text = tr("Time scale")
	grid.add_child(speed_label)
	var speed := HSlider.new()
	speed.name = "TimeScale"
	speed.min_value = 0.1
	speed.max_value = 4.0
	speed.step = 0.1
	speed.value = Engine.time_scale
	speed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speed.value_changed.connect(func(v): Engine.time_scale = v; _status.text = tr("Time scale: %.1fx") % v)
	grid.add_child(speed)
	# Tune tab: sliders for every tunable.
	var tune := VBoxContainer.new()
	tune.name = tr("Tune")
	tabs.add_child(tune)
	_filter = LineEdit.new()
	_filter.placeholder_text = tr("Search (e.g. heat, speed, leak)")
	_filter.text_changed.connect(func(_t): _rebuild_tunables())
	tune.add_child(_filter)
	var drive := CheckBox.new()
	drive.name = "TestDrive"
	drive.text = tr("Test Drive: open ocean, no obstacles")
	drive.toggled.connect(func(on): if voyage: voyage.set_test_drive(on))
	tune.add_child(drive)
	var presets := HBoxContainer.new()
	tune.add_child(presets)
	for slot in [1, 2, 3]:
		var save := Button.new()
		save.text = tr("Save %d") % slot
		save.add_theme_font_size_override("font_size", 13)
		save.pressed.connect(save_preset.bind(slot))
		presets.add_child(save)
		var load_button := Button.new()
		load_button.text = tr("Load %d") % slot
		load_button.add_theme_font_size_override("font_size", 13)
		load_button.pressed.connect(load_preset.bind(slot))
		presets.add_child(load_button)
	var reset := Button.new()
	reset.text = tr("Reset all")
	reset.add_theme_font_size_override("font_size", 13)
	reset.pressed.connect(func(): apply_values(defaults); _status.text = tr("Back to the defaults."))
	tune.add_child(reset)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tune.add_child(scroll)
	_tune_box = VBoxContainer.new()
	_tune_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_tune_box)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 14)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_status)


## Events other systems add (spawn an enemy ship, spawn each obstacle...): [id, label] pairs.
func _extra_events() -> Array:
	if voyage and voyage.has_method("dev_extra_events"):
		return voyage.dev_extra_events()
	return []


func _rebuild_tunables() -> void:
	for child in _tune_box.get_children():
		child.queue_free()
	_sliders.clear()
	var search := _filter.text.strip_edges().to_lower()
	var all := groups()
	for group in all:
		var node: Object = all[group][0]
		var rows := []
		for property in tunable_properties(node):
			var label := String(property.name).replace("_", " ")
			if search == "" or label.contains(search) or group.to_lower().contains(search):
				rows.append(property)
		if rows.is_empty():
			continue
		var header := Label.new()
		header.text = tr(group)
		header.add_theme_color_override("font_color", UI.YELLOW)
		header.add_theme_font_size_override("font_size", 17)
		_tune_box.add_child(header)
		for property in rows:
			_tune_box.add_child(_row(group, node, property))


func _row(group: String, node: Object, property: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = String(property.name).replace("_", " ")
	name_label.custom_minimum_size = Vector2(150, 0)
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.clip_text = true
	row.add_child(name_label)
	var value = node.get(property.name)
	var key: String = group + "/" + property.name
	if property.type == TYPE_BOOL:
		var check := CheckBox.new()
		check.button_pressed = value
		check.toggled.connect(func(on): apply(group, property.name, on))
		row.add_child(check)
		_sliders[key] = check
		return row
	if value is float and is_inf(value):
		value = 9999.0
	var limits := range_for(property, float(value))
	var slider := HSlider.new()
	slider.min_value = limits.x
	slider.max_value = limits.y
	slider.step = limits.z if limits.z > 0.0 else (limits.y - limits.x) / 500.0
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(140, 0)
	row.add_child(slider)
	var readout := Label.new()
	readout.custom_minimum_size = Vector2(64, 0)
	readout.add_theme_font_size_override("font_size", 13)
	readout.text = _format(value)
	row.add_child(readout)
	slider.value_changed.connect(func(v):
		var typed: Variant = int(v) if property.type == TYPE_INT else v
		apply(group, property.name, typed)
		readout.text = _format(typed))
	_sliders[key] = slider
	return row


static func _format(value: Variant) -> String:
	if value is int:
		return str(value)
	return "%.3f" % value if absf(value) < 10.0 else "%.1f" % value


func _force(event: String) -> void:
	if voyage and voyage.dev_event(event):
		_status.text = tr("Forced: %s") % event
		if event == "god_mode":
			_status.text = tr("God mode: %s") % (tr("on") if voyage.god_mode else tr("off"))


func _restart() -> void:
	close()
	Engine.time_scale = 1.0
	if Net.role == "host":
		Net.start_voyage(Session.contract_index)
	elif Net.role == "offline":
		get_tree().reload_current_scene()


func _to_dock() -> void:
	close()
	Engine.time_scale = 1.0
	if Net.role == "host":
		Net.back_to_dock()
	elif Net.role == "offline":
		UI.go(DOCK_SCENE)


func _to_menu() -> void:
	close()
	Engine.time_scale = 1.0
	if Net.role != "offline":
		Net.leave()
	UI.go(MENU_SCENE)
