extends Node3D
## One voyage from the dock to port, built from a contract (rocks, cliffs, waves, deadline).
## The route's pacing is hand-made (DESIGN.md section 7); this script only lays it out and
## runs the clock.

signal port_reached
signal hint_shown(text: String)
signal voyage_over(delivered: bool)

const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")
const VoyageDev = preload("res://scripts/levels/voyage/voyage_dev.gd")
const VoyageSky = preload("res://scripts/levels/voyage/voyage_sky.gd")
const VoyageRoute = preload("res://scripts/levels/voyage/voyage_route.gd")
const VoyagePirates = preload("res://scripts/levels/voyage/voyage_pirates.gd")
const VoyageArrival = preload("res://scripts/levels/voyage/voyage_arrival.gd")
const InteractionPrompts = preload("res://scripts/ui/interaction_prompts.gd")
const VoyageCountdown = preload("res://scripts/levels/voyage/voyage_countdown.gd")
const WaterStreaks = preload("res://scripts/components/water_streaks.gd")
const Upgrades = preload("res://scripts/systems/upgrades.gd")
const AICrew = preload("res://scripts/ai/ai_crew.gd")
const PlayerControls = preload("res://scripts/systems/player_controls.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")
const Stars = preload("res://scripts/systems/stars.gd")
const StarRules = preload("res://scripts/systems/star_rules.gd")
const DOCK_SCENE := "res://scenes/levels/dock.tscn"
const WORLD_MAP_SCENE := "res://scenes/ui/world_map.tscn"

@export var contract: Resource ## leave empty to use the session's chosen contract

var finish_x := 1300.0
var hits := 0
var started := false ## the clock runs once the crew has set sail
var finished := false
var delivered := false
var elapsed := 0.0
var _crash_flash := 0.0
var _show_help := false
var net_puppet := false ## online client: the host runs the game, this copy only shows it
var _next_event := 0
var _next_enemy := 0
var _hint_left := 0.0
var god_mode := false
var test_drive := false ## developer mode: no obstacles, no port, just open sea
var bonus_points := 0 ## fish caught and loot scooped up on the way (added to the score) ## developer mode: no flooding, no overheating, no running dry

var _dev := VoyageDev.new(self) ## Developer mode
var _sky := VoyageSky.new(self) ## sky, fog, storm
var _route := VoyageRoute.new(self) ## rocks, cliffs, port
var _pirates := VoyagePirates.new(self)
var _arrival := VoyageArrival.new(self) ## the pirate village and beaching the ship
var _countdown := VoyageCountdown.new(self) ## 5 s to get to your posts

@onready var _ship: Node3D = $Ship
@onready var _handling: Node = $Ship/ShipHandling
@onready var _water: Node3D = $Water
@onready var _status: Label = $HUD/Status
@onready var _banner: Label = $HUD/Banner


func _ready() -> void:
	add_to_group("voyage")
	if Session.realistic_sea and $Water.use_fft():
		$Ship/WaveMotion.sea = $Water
	if contract == null:
		contract = ContractLibrary.by_index(Session.contract_index)
	finish_x = contract.length
	_route.build_route()
	$HUD/MapChart.port_x = finish_x
	$Music.finish_x = finish_x
	$HazardDirector.setup(contract.waves)
	$HUD/MapChart.range_metres = contract.chart_range
	_sky.apply_fog(contract.fog)
	for crate in get_tree().get_nodes_in_group("cargo"):
		crate.value = contract.pay_per_crate # each contract pays its own rate
	Upgrades.apply(_ship, Session.upgrades)
	if contract.equipment.has("no_sail"):
		var model := _ship.get_node_or_null("Model")
		for part in ["Sail", "SailStripe", "Jib"]:
			var piece: Node = model.find_child(part, true, false) if model else null
			if piece:
				piece.visible = false # a smuggler's ship: engine only
	if contract.tutorial:
		$Ship/HullSystem.sink_grace_seconds = INF # the Maiden voyage can't be lost
		$Ship/EngineSystem.min_fuel = 0.3 # ...and never runs dry
	var engine := $Ship/EngineSystem
	engine.fuel_low.connect(func(): show_hint(tr("Coal low! Fill a shovel at the COAL pile (back corner) and press Use at the ENGINE.")))
	engine.out_of_fuel.connect(func(): show_hint(tr("Out of coal: only the sail is pushing. Shovel coal from the pile into the ENGINE!")))
	_handling.rock_hit.connect(_on_rock_hit)
	$Ship/WaveMotion.wave_warning.connect(_on_wave_warning)
	$Ship/HullSystem.ship_sunk.connect(_on_sunk)
	_banner.visible = false
	var rules := StarRules.new()
	rules.name = "StarRules"
	var limits := Stars.thresholds(contract, get_tree().get_nodes_in_group("cargo").size())
	rules.star_1 = limits[0]
	rules.star_2 = limits[1]
	rules.star_3 = limits[2]
	add_child(rules)
	var results := $HUD/Results
	results.sail_again_pressed.connect(_sail_again)
	results.map_pressed.connect(_back_to_map)
	results.change_crew_pressed.connect(_change_crew)
	add_child(InteractionPrompts.new())
	var streaks := WaterStreaks.new()
	streaks.ship = _ship
	add_child(streaks)
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	pause.voyage = self
	add_child(pause)
	_sky.setup_sky()
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.09, 0.15, 0.27, 0.85)
	pill.set_corner_radius_all(18)
	pill.content_margin_left = 18
	pill.content_margin_right = 18
	_status.add_theme_stylebox_override("normal", pill)
	$HUD/CrewJoin.crew_ready.connect(_on_crew_ready)
	if Net.role != "offline":
		$NetSync.setup(Net.role, Net.my_index, Net.peers)
	if not Session.joined_players.is_empty():
		_apply_crew(Session.joined_players) # restart: same crew, straight back to sea
	elif get_tree().current_scene == self:
		$HUD/CrewJoin.visible = true # first launch: choose the crew
	else:
		_start() # running inside tests: everyone aboard


func _start() -> void:
	$HUD/CrewJoin.visible = false
	# A real run (not a test) begins with 5 s to get to your posts, the ship held still.
	if is_inside_tree() and get_tree().current_scene == self and Net.role != "client" and not _countdown.running():
		_countdown.start()
		return
	_set_sail()


func _set_sail() -> void:
	started = true
	# The sail keeps the ship moving even if the engine dies (not on a smuggler's sail-less ship).
	_handling.sail_speed = 0.0 if contract.equipment.has("no_sail") else 1.2
	$HUD/CrewJoin.visible = false


func _on_crew_ready(players: Array[int]) -> void:
	Session.joined_players = players
	_apply_crew(players)


## Takes anyone who didn't join (as a human or an AI) off the ship; small crews get a slow
## automatic pump.
func _apply_crew(players: Array[int]) -> void:
	var ai_indexes: Array = Net.remote_ai if Net.role == "client" else Session.ai_crew.keys()
	var aboard := 0
	for player in get_tree().get_nodes_in_group("crew"):
		var index: int = player.player_index
		if players.has(index):
			aboard += 1
		elif ai_indexes.has(index):
			aboard += 1
			if Net.role != "client": # online clients only show the host's AI
				var jobs: Dictionary = Session.ai_crew[index]
				add_ai(index, jobs.primary, jobs.get("secondary", ""))
		else:
			player.remove_from_group("crew")
			player.remove_from_group("camera_focus")
			player.queue_free()
	var hull := $Ship/HullSystem
	hull.auto_pump_rate = hull.pump_rate * 0.3 if aboard <= 3 else 0.0
	_start()


## Hands a crew member over to an AI with a primary and a secondary job.
func add_ai(index: int, primary: String, secondary := "") -> Node:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.player_index == index and not player.has_node("AICrew"):
			var ai := AICrew.new()
			ai.name = "AICrew"
			ai.primary = primary
			ai.secondary = secondary
			player.add_child(ai)
			return ai
	return null


func _physics_process(delta: float) -> void:
	if _countdown.running():
		_handling.throttle = 0.0
		if _countdown.step(delta):
			_set_sail()
	if _crash_flash > 0.0:
		_crash_flash -= delta
		_banner.visible = _crash_flash > 0.0
	if _hint_left > 0.0:
		_hint_left -= delta
		$HUD/Hint.visible = _hint_left > 0.0
	# The controls help fades after the first half minute (H brings it back).
	var help: Label = $HUD/Controls
	help.modulate.a = move_toward(help.modulate.a, 1.0 if _show_help or elapsed < 30.0 else 0.0, delta * 2.0)
	_status.text = tr("%s    Time %s / %s") % [tr(contract.title), _clock(elapsed), _clock(contract.deadline)]
	if bonus_points > 0:
		_status.text += tr("    Fish & loot +%d") % bonus_points
	_status.add_theme_color_override("font_color", Color(1, 0.5, 0.45) if elapsed > contract.deadline else Color(1, 0.96, 0.86))
	if net_puppet:
		return # online client: the host's snapshots move everything
	$HazardDirector.set_physics_process(started and not finished)
	if not started:
		_handling.throttle = 0.0 # moored until the crew sets sail
	if has_node("CollisionView"):
		_dev.draw_collision_view()
	if god_mode:
		$Ship/HullSystem.water = 0.0
		$Ship/EngineSystem.heat = minf($Ship/EngineSystem.heat, 0.6)
		$Ship/EngineSystem.fuel = maxf($Ship/EngineSystem.fuel, 0.5)
	if started and not finished and Net.role != "client":
		_check_takeovers()
	if started and not finished:
		_run_events()
		_pirates.run_enemies()
		elapsed += delta
		if _arrival.beaching:
			if _arrival.step(delta):
				_finish()
		elif _ship.global_position.x >= finish_x:
			_arrival.start() # the bow meets the beach: slide up the sand, then the results


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]


func _unhandled_input(event: InputEvent) -> void:
	var restart: bool = (event is InputEventKey and event.pressed and event.physical_keycode == KEY_R) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H:
		_show_help = not _show_help
	if Net.role == "client":
		return # online: the host decides when to sail again or go back to the dock
	if restart:
		_sail_again()
	if finished and event.is_action_pressed("ui_accept"):
		_back_to_map()
	var change_crew: bool = finished and event is InputEventKey and event.pressed and event.physical_keycode == KEY_J
	if change_crew:
		_change_crew()


func _sail_again() -> void:
	if Net.role == "client":
		return
	if Net.role == "host":
		Net.start_voyage(Session.contract_index)
	elif is_inside_tree() and get_tree().current_scene == self:
		get_tree().reload_current_scene()


func _back_to_map() -> void:
	if Net.role == "host":
		Net.back_to_dock()
	elif Net.role == "offline" and is_inside_tree() and get_tree().current_scene == self:
		UI.go(WORLD_MAP_SCENE) # back to the map: see the stars, pick the next route


func _change_crew() -> void:
	if Net.role != "offline" or not (is_inside_tree() and get_tree().current_scene == self):
		return
	Session.joined_players.clear()
	UI.go(DOCK_SCENE)


## A player presses Jump or Use on their controller mid-voyage: they take over their AI crewmate.
func _check_takeovers() -> void:
	for player in get_tree().get_nodes_in_group("crew"):
		var index: int = player.player_index
		if not player.has_node("AICrew") or (Net.role == "host" and index != 1):
			continue # online, only the host's own controls are on this computer
		if Input.is_action_just_pressed(PlayerControls.action(index, "jump")) \
				or Input.is_action_just_pressed(PlayerControls.action(index, "use")):
			take_over(index)


## A human takes an AI crewmate's place, right where it stands.
func take_over(index: int) -> void:
	for player in get_tree().get_nodes_in_group("crew"):
		if player.player_index != index or not player.has_node("AICrew"):
			continue
		var ai := player.get_node("AICrew")
		player.remove_child(ai)
		ai.queue_free()
		player.get_node("PlayerInput").enabled = true
		player.get_node("Label").text = "P%d" % index
		player.think(tr("I'm in!"), 1.5, "shout")
		if not Session.joined_players.has(index):
			Session.joined_players.append(index)
			Session.joined_players.sort()
		Session.ai_crew.erase(index)
		$CrewBrain.assignments.erase(player)


# --- Contract events and hints ------------------------------------------------------

func _run_events() -> void:
	while _next_event < contract.events.size() and _ship.global_position.x >= contract.events[_next_event][0]:
		var event: Array = contract.events[_next_event]
		_next_event += 1
		match event[1]:
			"leak":
				$Ship/HullSystem.add_breach(Vector3(randf_range(-4.0, 6.0), 0.0, 3.0 * (1.0 if randf() < 0.5 else -1.0)))
			"rudder":
				$Ship/RudderSystem.try_damage(1.0)
			"heat":
				var engine := $Ship/EngineSystem
				engine.heat = maxf(engine.heat, 0.85)
			"stall":
				dev_event("stall")
			"cargo_shift":
				_shift_cargo()
			"flood":
				# A wave over the bow: two leaks on the same side and water sloshing in.
				var side := 1.0 if randf() < 0.5 else -1.0
				$Ship/HullSystem.add_breach(Vector3(4.0, 0.0, side * 3.0))
				$Ship/HullSystem.add_breach(Vector3(7.0, 0.0, side * 3.0))
				$Ship/HullSystem.water = minf(0.9, $Ship/HullSystem.water + 0.15)
		if event.size() > 2 and event[2] != "":
			show_hint(tr(event[2]))


## A swell shifts the cargo: every lashed chest breaks loose and slides.
func _shift_cargo() -> void:
	var bay := get_tree().get_first_node_in_group("cargo_bay")
	var cargo := $Ship/LoadSystem
	var push := 1.0 if randf() < 0.5 else -1.0
	for crate in cargo.crates():
		if crate.lashed and bay:
			bay.unlash(crate)
			crate.velocity = Vector2(randf_range(-1.0, 1.0), push * 3.5)
			cargo.crate_loose.emit(crate)


func show_hint(text: String, seconds := 7.0) -> void:
	hint_shown.emit(text)
	$HUD/Hint.text = text
	$HUD/Hint.visible = true
	_hint_left = seconds


# --- Events --------------------------------------------------------------------

## A big wave: the sea shows the swell rolling in from that side.
func _on_wave_warning(side: float) -> void:
	if _water.has_method("swell"):
		var starboard: Vector3 = _ship.global_basis * Vector3(0, 0, 1)
		_water.swell(_ship.global_position, -starboard * side)



func _on_rock_hit(_rock: Node3D) -> void:
	hits += 1
	if not finished and _handling.impact_strength() > 0.3:
		_banner.text = tr("CRASH!")
		_banner.visible = true
		_crash_flash = 1.0


func _on_sunk() -> void:
	if finished:
		return
	finished = true
	_crash_flash = 0.0
	_handling.throttle = 0.0
	_banner.visible = false
	_show_results()
	voyage_over.emit(false)


func _finish() -> void:
	finished = true
	delivered = true
	_crash_flash = 0.0
	_handling.throttle = 0.0
	_banner.visible = false
	_show_results()
	port_reached.emit()
	voyage_over.emit(true)


func _show_results() -> void:
	$HUD/Hint.visible = false
	$HUD/Controls.visible = false
	_hint_left = 0.0
	var cargo := $Ship/LoadSystem
	var water: float = $Ship/HullSystem.water
	var results := $HUD/Results
	var outcome := {
		"delivered": delivered,
		"contract": contract.title,
		"time_text": _clock(elapsed),
		"deadline_text": _clock(contract.deadline),
		"on_time": elapsed <= contract.deadline,
		"crates": cargo.crates().size(),
		"crates_loaded": maxi(cargo._loaded_crates, cargo.crates().size()),
		"water": water,
		"progress": clampf(_ship.global_position.x / finish_x, 0.0, 1.0),
		"score": results.score(delivered, cargo.cargo_value(), water, elapsed, contract.deadline, bonus_points),
	}
	var stores := _ship.get_node_or_null("ShipStores")
	outcome.haul = stores.counts.duplicate() if stores else {}
	outcome.star_limits = $StarRules.limits()
	outcome.stars = Stars.count(outcome.score.total, delivered, outcome.star_limits)
	outcome.earned = Session.record_voyage(Session.contract_index, delivered, outcome.score.total, elapsed, outcome.stars)
	outcome.records = Session.last_records.duplicate()
	var key := str(Session.contract_index)
	outcome.best_score = int(Session.best_scores.get(key, 0))
	outcome.best_time_text = _clock(float(Session.best_times[key])) if Session.best_times.has(key) else "-"
	results.show_results(outcome, $VoyageLog.recap())


# --- Forwarders (callers outside this script use these names) -----------------------------

## Pirates appear behind the ship on one side and come alongside.
func spawn_enemy(side: float) -> Node3D:
	return _pirates.spawn_enemy(side)


## An enemy cannonball landed on the deck: it cracks the hull there, like a rock would.
func cannon_hit(point: Vector3) -> void:
	_pirates.cannon_hit(point)


## Developer: forces an event right now. Returns false for an unknown event.
func dev_event(event: String) -> bool:
	return _dev.dev_event(event)


func dev_extra_events() -> Array:
	return _dev.dev_extra_events()


func set_test_drive(on: bool) -> void:
	_dev.set_test_drive(on)


func _spawn_ahead(kind: String) -> Node3D:
	return _route.spawn_ahead(kind)


func _lightning() -> void:
	_sky.lightning()
