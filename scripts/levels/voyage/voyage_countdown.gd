extends RefCounted
## The countdown before each run (Olivier, 2026-10-24): 5 seconds for everyone to get to their
## posts, the ship held still; each second pops on screen with a tick, then "SET SAIL!".
## Owned by voyage.gd.

var voyage: Node3D
var left := 0.0 ## seconds left; 0 = not counting
var _shown := -1


func _init(owner_voyage: Node3D) -> void:
	voyage = owner_voyage


func start(seconds := 5.0) -> void:
	left = seconds
	_shown = -1


func running() -> bool:
	return left > 0.0


## Each frame while counting. Returns true the moment it reaches zero.
func step(delta: float) -> bool:
	left -= delta
	var banner: Label = voyage._banner
	var number := ceili(left)
	if left <= 0.0:
		left = 0.0
		banner.text = voyage.tr("SET SAIL!")
		banner.visible = true
		voyage._crash_flash = 1.2 # the banner hides itself after a moment
		_pop(banner)
		UI.play("stamp")
		return true
	if number != _shown:
		_shown = number
		banner.text = str(number)
		banner.visible = true
		_pop(banner)
		UI.play("click")
	return false


func _pop(control: Control) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 2.0
	control.create_tween().tween_property(control, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
