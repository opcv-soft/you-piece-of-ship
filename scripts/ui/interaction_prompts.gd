extends Node
## Contextual prompts (Olivier, 2026-10-24: "use contextual interaction prompts instead of
## permanent labels"). Each human crew member gets one prompt above the thing they're at or next
## to: what it is, its state, and what Use does there. Nothing is shown for things nobody's near.
## Also owns the legibility settings (backing opacity) as the Developer group "Legibility".

const ThoughtBubble = preload("res://scripts/components/thought_bubble.gd")

@export_range(0.0, 1.0) var backing_opacity := 0.3 ## dark backing behind prompts and HUD text

var _bubbles := {} ## player -> bubble
var _hud_boxes: Array[StyleBoxFlat] = []


func _ready() -> void:
	name = "InteractionPrompts"
	add_to_group("dev_tunable")
	set_meta("dev_group", "Legibility")
	var voyage := get_parent()
	for path in ["HUD/Hint", "HUD/Controls", "HUD/Banner"]:
		var label := voyage.get_node_or_null(path) as Label
		if label:
			var box := StyleBoxFlat.new()
			box.set_corner_radius_all(14)
			box.content_margin_left = 16
			box.content_margin_right = 16
			box.content_margin_top = 6
			box.content_margin_bottom = 8
			label.add_theme_stylebox_override("normal", box)
			_hud_boxes.append(box)


func _process(_delta: float) -> void:
	ThoughtBubble.backing_opacity = backing_opacity
	for box in _hud_boxes:
		box.bg_color = Color(0.04, 0.06, 0.1, backing_opacity)
	for player in get_tree().get_nodes_in_group("crew"):
		if player.has_node("AICrew") or not player.is_inside_tree():
			continue
		var target := target_of(player)
		var bubble: Sprite3D = _bubbles.get(player)
		if target == null:
			if bubble:
				bubble.hide_now()
			continue
		if bubble == null:
			bubble = ThoughtBubble.new()
			bubble.height = 0.0
			bubble.font_size = 26
			get_parent().add_child(bubble)
			_bubbles[player] = bubble
		bubble.global_position = target.global_position + Vector3(0, 2.3, 0)
		bubble.show_text(text_for(target, player), 0.3, "prompt")


## What a player is at or would use: their station, else the nearest thing Use would act on.
static func target_of(player: Node3D) -> Node3D:
	if player.station:
		return player.station
	var best: Node3D = null
	var best_distance := INF
	for node in player.get_tree().get_nodes_in_group("interactables"):
		if node == player.carried or not node.can_interact(player):
			continue
		var distance: float = node.distance_to_player(player)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best


static func text_for(target: Node3D, player: Node3D) -> String:
	if target.has_method("prompt_text"):
		return target.prompt_text(player)
	if "title" in target and "stock" in target: # a spares box
		return "%s %d\n%s" % [TranslationServer.translate(target.title), target.stock, TranslationServer.translate("Use: take one")]
	if "display_name" in target:
		var carrying: Node3D = player.carried
		if carrying and carrying.kind == "gold" and target.kind == "crate":
			return TranslationServer.translate("Use: put the gold back in")
		return TranslationServer.translate("Use: pick up %s") % TranslationServer.translate(target.display_name)
	return TranslationServer.translate("Use")
