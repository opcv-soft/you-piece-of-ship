extends Node3D
## A place on the ship that owns some information or controls (DESIGN.md section 12).
## Information belongs to the station, not the player: whoever stands here gets it,
## which is what makes crew call things out to each other (Social interaction).
## Each station shows a one-line prompt to crew standing nearby (onboarding, DESIGN.md section 8).

@export var station_name := "Station"
@export var radius := 1.3 ## metres: how close a crew member must stand
@export var needs_use := true ## true: press Use to take it over (helm). false: standing here is enough (map table)
@export var max_occupants := 1 ## 2 for two-player jobs
@export var prompt := "" ## one line shown to nearby crew, e.g. "Use: steer"

var occupants: Array[Node3D] = []
var status_text := "" ## live state for the label, set by the system that owns this station
var enabled := true ## a disabled station can't be used and hides its label
static var show_labels := false ## true: the old permanent labels on every station

## The first player operating this station, or null.
var occupant: Node3D:
	get:
		return occupants[0] if not occupants.is_empty() else null


func _ready() -> void:
	add_to_group("stations")
	add_to_group("interactables")


func _process(_delta: float) -> void:
	_update_label()


func _update_label() -> void:
	var label := get_node_or_null("Label") as Label3D
	if label == null:
		return
	# Contextual prompts (Olivier, 2026-10-24): the label only shows for an alert ("OVERHEAT!",
	# "Cracking! 5"); otherwise each player sees a prompt for what they're next to (interaction_prompts.gd).
	label.visible = enabled and _label_wanted() and (show_labels or status_text.contains("!"))
	var lines := PackedStringArray([tr(station_name)])
	if status_text != "":
		lines.append(status_text)
	if prompt != "" and _show_prompt():
		lines.append(tr(prompt))
	label.text = "\n".join(lines)


## Override: hide the label when it would only be clutter.
func _label_wanted() -> bool:
	return true


## One prompt for a player standing here: name, state, and what Use does.
func prompt_text(player: Node3D) -> String:
	var lines := PackedStringArray([tr(station_name)])
	if status_text != "":
		lines.append(status_text)
	if occupants.has(player):
		lines.append(tr("Use: let go"))
	elif prompt != "":
		lines.append(tr(prompt))
	return "\n".join(lines)


func _show_prompt() -> bool:
	if not needs_use:
		return not is_active()
	return occupants.size() < max_occupants and not crew_nearby().is_empty()


## Crew members standing within reach (distance measured along the deck, ignoring height).
func crew_nearby() -> Array[Node3D]:
	var nearby: Array[Node3D] = []
	for player in get_tree().get_nodes_in_group("crew"):
		if distance_to_player(player) <= radius:
			nearby.append(player)
	return nearby


func distance_to_player(player: Node3D) -> float:
	var offset: Vector3 = player.global_position - global_position
	offset.y = 0.0
	return offset.length()


## The players currently getting this station's information.
func readers() -> Array[Node3D]:
	if needs_use:
		return occupants.duplicate()
	return crew_nearby()


func is_active() -> bool:
	return not readers().is_empty()


## Whether a human is getting this station's information (screens only show it to humans;
## an AI crewmate reads it for itself and calls out what matters).
func has_human_reader() -> bool:
	for player in readers():
		if not player.has_node("AICrew"):
			return true
	return false


# --- Interaction (used by crew_player.gd) ------------------------------------

func can_interact(player: Node3D) -> bool:
	if not enabled or distance_to_player(player) > radius:
		return false
	if player.carried:
		return accepts_item(player.carried, player)
	if not needs_use or occupants.has(player):
		return false
	# Humans come first: a human can take over a station an AI is holding.
	return occupants.size() < max_occupants or (_is_human(player) and _ai_occupant() != null)


func interact(player: Node3D) -> void:
	if player.carried:
		receive_item(player.carried, player)
	else:
		occupy(player)


func _is_human(player: Node3D) -> bool:
	return not player.has_node("AICrew")


func _ai_occupant() -> Node3D:
	for player in occupants:
		if not _is_human(player):
			return player
	return null


func occupy(player: Node3D) -> bool:
	if not enabled or not needs_use or occupants.has(player):
		return false
	if occupants.size() >= max_occupants and _is_human(player) and _ai_occupant() != null:
		release(_ai_occupant()) # the AI steps aside for the human
	if occupants.size() >= max_occupants:
		return false
	occupants.append(player)
	player.station = self
	return true


func release(player: Node3D) -> void:
	occupants.erase(player)
	if player.station == self:
		player.station = null


func release_all() -> void:
	for player in occupants.duplicate():
		release(player)


## Where an occupant stands: side by side for two-player jobs.
func stand_point(player: Node3D) -> Vector3:
	var slot := maxi(occupants.find(player), 0)
	return global_position + global_basis.x.normalized() * (0.8 * slot)


## Override: can this station take the item the player carries (e.g. a plank for a breach)?
func accepts_item(_item: Node3D, _player: Node3D) -> bool:
	return false


func receive_item(_item: Node3D, _player: Node3D) -> void:
	pass


## Override: the Jump button while operating this station (e.g. vent steam at the engine).
func secondary_action(_player: Node3D) -> void:
	pass
