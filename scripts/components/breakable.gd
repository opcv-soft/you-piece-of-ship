extends Node
## Makes an obstacle breakable (Olivier, 2026-10-24: "everything should be shootable with the
## cannon or destroyable with the hull... using the cannon to get loot"). Cannonballs and hard rams
## chip at its health; at zero it bursts apart and sinks, and its salvage swooshes onto the ship
## (salvage.gd).
## A child of the obstacle (rock.gd adds it for the kinds that can break; whales and cliffs can't).

signal destroyed(obstacle: Node3D)

const Salvage = preload("res://scripts/components/salvage.gd")
const Sfx = preload("res://scripts/systems/sfx.gd")
## What breaking each kind sounds like.
const SOUNDS := {"rock": "rock_crack", "wreck": "wood_splinter", "barrel": "barrel_burst", "siren": "siren_shriek",
		"whale": "whale_moan"}
## kind -> [health, loot pieces, resource, units each]. Rocks are black charcoal rocks; the siren
## goes straight onto the bowsprit; whales give grease (Olivier, 2026-10-24).
const KINDS := {"rock": [3, 1, "coal", 2], "wreck": [4, 2, "planks", 2], "siren": [3, 0, "siren", 1],
		"barrel": [1, 1, "gold", 3], "whale": [5, 1, "grease", 1]}

var health := 1
var _obstacle: Node3D


static func can_break(kind: String) -> bool:
	return KINDS.has(kind)


func _ready() -> void:
	name = "Breakable"
	_obstacle = get_parent()
	health = KINDS[_obstacle.kind][0]


## One hit (a cannonball or a ram). Returns true if that destroyed it. Damage 0 (a gentle bump)
## still chips some salvage off.
func hit(damage := 1) -> bool:
	if health <= 0:
		return false
	health -= damage
	_shudder()
	if health > 0:
		Sfx.play(SOUNDS.get(_obstacle.kind, "rock_crack"), _obstacle, _obstacle.global_position, -8.0, 0.2) # a crack, not yet a break
		chip()
	if health <= 0:
		_burst()
		return true
	return false


## Every hit that doesn't break it still knocks a little off, which flies aboard (Olivier,
## 2026-10-24: "i want to get the loot when i hit everything"). A siren's chips are gold.
func chip() -> void:
	var resource: String = KINDS[_obstacle.kind][2]
	var salvage := Salvage.new()
	salvage.resource = "gold" if resource == "siren" else resource
	salvage.units = 1
	salvage.pieces = 2
	_obstacle.get_parent().add_child(salvage)
	salvage.global_position = _obstacle.global_position * Vector3(1, 0, 1)


func _shudder() -> void:
	var model := _obstacle.get_node_or_null("Model") as Node3D
	if model == null:
		return
	var rest := model.position
	var shake := model.create_tween()
	for i in 4:
		shake.tween_property(model, "position", rest + Vector3(randf_range(-0.3, 0.3), 0.0, randf_range(-0.3, 0.3)), 0.04)
	shake.tween_property(model, "position", rest, 0.05)
	if is_inside_tree():
		UI.play("stamp")


## Bursts apart: debris, salvage for the ship, the remains sink, and it stops being an obstacle.
func _burst() -> void:
	_obstacle.remove_from_group("rocks")
	_obstacle.remove_from_group("obstacles")
	destroyed.emit(_obstacle)
	Sfx.play(SOUNDS.get(_obstacle.kind, "rock_crack"), _obstacle.get_parent(), _obstacle.global_position, 2.0)
	var settings: Array = KINDS[_obstacle.kind]
	var world := _obstacle.get_parent()
	var salvage := Salvage.new()
	salvage.resource = settings[2]
	salvage.units = maxi(1, settings[1]) * settings[3]
	world.add_child(salvage)
	salvage.global_position = _obstacle.global_position * Vector3(1, 0, 1)
	_debris()
	var sink := _obstacle.create_tween()
	sink.tween_property(_obstacle, "position:y", -6.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sink.tween_callback(_obstacle.queue_free)


func _debris() -> void:
	var chunks := CPUParticles3D.new()
	chunks.one_shot = true
	chunks.amount = 30
	chunks.lifetime = 1.4
	chunks.explosiveness = 0.95
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.4, 0.3, 0.3)
	var colour := StandardMaterial3D.new()
	colour.albedo_color = Color(0.12, 0.11, 0.12) if _obstacle.kind == "rock" else Color(0.55, 0.36, 0.22)
	chunk.material = colour
	chunks.mesh = chunk
	chunks.direction = Vector3.UP
	chunks.spread = 70.0
	chunks.initial_velocity_min = 5.0
	chunks.initial_velocity_max = 10.0
	chunks.gravity = Vector3(0, -14, 0)
	chunks.angular_velocity_min = -400.0
	chunks.angular_velocity_max = 400.0
	chunks.position = _obstacle.global_position + Vector3(0, 1.0, 0)
	_obstacle.get_parent().add_child(chunks)
	chunks.emitting = true
	chunks.get_tree().create_timer(2.0).timeout.connect(chunks.queue_free)
