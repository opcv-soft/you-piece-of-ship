extends Node
## The voyage's story: every accident, fix and near-save with its time, for the results recap
## ("did you understand why things went wrong?", DESIGN.md section 9 survey).

signal logged(entry: Dictionary)

@export var ship: Node3D

var entries: Array[Dictionary] = [] ## {time, text, key, args, kind: "bad" | "good" | "info"}
var elapsed := 0.0

var _water_marks := [0.5, 0.8]
var _fallen: Array[String] = []
var _fallen_at := -1.0
var _last_rock := ""
var _last_rock_at := -INF


func _ready() -> void:
	var handling := ship.get_node("ShipHandling")
	var hull := ship.get_node("HullSystem")
	var engine := ship.get_node("EngineSystem")
	var rudder := ship.get_node("RudderSystem")
	var cargo := ship.get_node("LoadSystem")
	var waves := ship.get_node("WaveMotion")
	handling.impact.connect(_on_impact.bind(handling))
	hull.breach_cracked.connect(func(_b): add("The hull cracked", "bad"))
	hull.breach_opened.connect(func(_b): add("Leak open: water pouring in", "bad"))
	hull.breach_sealed.connect(func(_b): add("Leak patched", "good"))
	hull.breach_plugged.connect(func(_b): add("Leak plugged with a crate (cargo lost)", "info"))
	engine.overheat_warning.connect(func(): add("Engine overheating!", "bad"))
	engine.stalled.connect(func(): add("Engine stalled and the cooling pipe burst", "bad"))
	engine.vented.connect(func(player): add("%s vented steam", "info", [_who(player)]))
	engine.pipe_fixed.connect(func(): add("Cooling pipe fixed", "good"))
	engine.out_of_fuel.connect(func(): add("Out of coal!", "bad"))
	rudder.warning_started.connect(func(): add("Hard hit: the wheel is shuddering", "bad"))
	rudder.damaged.connect(func(): add("Rudder broken: pulling to %s", "bad", [
			"starboard" if rudder.pull_side < 0.0 else "port"]))
	rudder.repaired.connect(func(): add("Rudder pin swapped", "good"))
	cargo.rope_fraying.connect(func(_c): add("A cargo rope is fraying", "info"))
	cargo.crate_loose.connect(func(_c): add("A crate broke loose", "bad"))
	cargo.thrown_overboard.connect(func(crate): add("%s threw a crate overboard", "info", [_who(crate.carrier)]))
	var chaos := ship.get_node_or_null("CargoChaos")
	if chaos:
		chaos.chest_burst.connect(func(_c): add("A chest burst open: gold all over the deck!", "bad"))
		chaos.gold_lost.connect(func(value): add("%d gold washed overboard", "bad", [value]))
	waves.wave_warning.connect(func(side): add("Big wave coming from %s!", "info", ["starboard" if side > 0.0 else "port"]))
	for player in get_tree().get_nodes_in_group("crew"):
		player.knocked_down.connect(_on_knocked.bind(player))


func _on_impact(rock: Node3D, handling: Node) -> void:
	# Bouncing off the same rock again right away is the same accident.
	var obstacle := str(rock.get_instance_id()) if rock.hidden else "coast"
	if obstacle == _last_rock and elapsed - _last_rock_at < 8.0:
		return
	_last_rock = obstacle
	_last_rock_at = elapsed
	var what := "the coast" if not rock.hidden else "a rock"
	add("Hit %s at %d%% speed", "bad", [what, roundi(absf(handling.impact_speed) / handling.max_speed * 100.0)])


func _who(player: Node) -> String:
	return "P%d" % player.player_index if player else "Someone"


## Records an event. key is the English sentence (with %s/%d slots), args fill the slots; text is
## the English version, translate_entry() gives it in the current language.
func add(key: String, kind := "info", args: Array = []) -> void:
	var entry := {"time": elapsed, "key": key, "args": args, "text": key % args if not args.is_empty() else key, "kind": kind}
	entries.append(entry)
	logged.emit(entry)


func _on_knocked(player: Node3D) -> void:
	# Several crew falling at once is one line: "P2, P3 knocked over".
	if elapsed - _fallen_at > 0.6:
		_fallen.clear()
	_fallen_at = elapsed
	_fallen.append(_who(player))
	var names := ", ".join(_fallen)
	if _fallen.size() > 1 and not entries.is_empty() and entries[-1].key == "%s knocked over":
		entries[-1].args = [names]
		entries[-1].text = "%s knocked over" % names
	else:
		add("%s knocked over", "bad", [names])


func _physics_process(delta: float) -> void:
	var voyage := get_parent()
	if "started" in voyage and (not voyage.started or voyage.finished):
		return
	elapsed += delta
	var water: float = ship.get_node("HullSystem").water
	if not _water_marks.is_empty() and water >= _water_marks[0]:
		add("Water %d%% up the hold!", "bad", [roundi(_water_marks[0] * 100.0)])
		_water_marks.pop_front()


## An entry in the current language (words in its arguments are translated too).
func translate_entry(entry: Dictionary) -> String:
	var args := []
	for arg in entry.get("args", []):
		args.append(tr(arg) if arg is String else arg)
	return tr(entry.get("key", entry.text)) % args if not args.is_empty() else tr(entry.get("key", entry.text))


## The lines worth showing on the results screen: the bad and good ones, most recent last.
func recap(limit := 12) -> Array[Dictionary]:
	var picked: Array[Dictionary] = []
	for entry in entries:
		if entry.kind != "info" or entry.text.contains("overboard") or entry.text.contains("vented"):
			picked.append(entry)
	return picked.slice(maxi(0, picked.size() - limit))
