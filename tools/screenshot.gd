extends SceneTree
## Takes screenshots of a voyage for checking the look (not part of the game).
## godot --path . -s tools/screenshot.gd -- out=/path/shot.png wait=4 events=overheat,leak dev=1 contract=1
## Several shots: shots=3 every=2 (out gets _1, _2... before the extension). haul=siren:3 fills the stores.

func _initialize() -> void:
	create_timer(50.0).timeout.connect(quit) # never hang
	_run.call_deferred()


func _run() -> void:
	await create_timer(0.3).timeout # autoloads are ready from here
	var args := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else "1"
	var session := root.get_node("Session")
	session.persist = false
	session.contract_index = int(args.get("contract", "0"))
	session.joined_players = [] as Array[int]
	session.ai_crew = {}
	for index in range(1, 5):
		session.enable_ai(index)
	if args.has("stars"): # pretend progress: e.g. stars=0:3,4:2
		session.stars = {}
		for pair in String(args.stars).split(",", false):
			session.stars[pair.get_slice(":", 0)] = int(pair.get_slice(":", 1))
	var scene: PackedScene = load(args.get("scene", "res://scenes/levels/voyage.tscn"))
	var level := scene.instantiate()
	root.add_child(level)
	current_scene = level
	if level.has_method("_apply_crew"):
		level._apply_crew([] as Array[int])
	if args.has("pitch") and level.has_node("SharedCamera"):
		level.get_node("SharedCamera").view_pitch_degrees = float(args.pitch)
	await create_timer(float(args.get("wait", "3"))).timeout
	for event in String(args.get("events", "")).split(",", false) if level.has_method("dev_event") else []:
		level.dev_event(event)
	for pair in String(args.get("haul", "")).split(",", false): # e.g. haul=siren:3,gold:5
		level.get_node("Ship/ShipStores").add(pair.get_slice(":", 0), int(pair.get_slice(":", 1)))
	if args.has("dev"):
		level.get_node("PauseMenu").open_dev()
	if args.has("pause"):
		level.get_node("PauseMenu").open_pause()
	var shots := int(args.get("shots", "1"))
	var out: String = args.get("out", "/tmp/shot.png")
	for i in shots:
		await create_timer(float(args.get("every", "1.5"))).timeout
		await process_frame
		var image := root.get_texture().get_image()
		var path := out if shots == 1 else out.get_basename() + "_%d.%s" % [i + 1, out.get_extension()]
		image.save_png(path)
		print("saved ", path)
	quit()
