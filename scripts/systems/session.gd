extends Node
## What survives between voyages (autoload "Session"): the crew, the chosen contract, money,
## upgrades, unlocked contracts and best scores. Money and progress are saved to disk
## (user://save.json); the crew is not, it's chosen fresh at the dock each time.

const SAVE_PATH := "user://save.json"
const Upgrades = preload("res://scripts/systems/upgrades.gd")
const Progress = preload("res://scripts/systems/progress.gd")
const ContractLibrary = preload("res://scripts/contracts/contract_library.gd")

var joined_players: Array[int] = [] ## human player indexes 1..4; empty = not chosen yet
var ai_crew := {} ## player index -> {"primary": job, "secondary": job} for AI crewmates
var contract_index := 0
var money := 0
var upgrades: Array = [] ## owned upgrade ids
var unlocked := 1 ## how many contracts are open
var best_scores := {} ## contract index (as text) -> best score
var best_times := {} ## contract index (as text) -> fastest delivery in seconds
var stars := {} ## contract index (as text) -> most stars earned (0..3)
var village := {"gold": 0, "coal": 0, "planks": 0, "grease": 0, "siren": 0} ## everything ever hauled home
var hats := {} ## player index (as text) -> hat style
var seen_oceans: Array = [0] ## oceans whose "new ocean" card has been shown
var unlock_everything := false ## developer mode: every route open
var last_records := {"score": false, "time": false} ## did the last voyage set a personal best?
var language := "" ## "en" or "fr"; empty = follow the computer's language
var music_volume_db := -8.0
var fullscreen := false
var realistic_sea := true ## the FFT ocean (falls back to the painted sea where it can't run)
var last_join_address := "" ## the friend's address last used with Join
var persist := true ## false while running automated tests: never touch the player's save


func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg.ends_with("gut_cmdln.gd"):
			persist = false
	load_game()
	if persist:
		fill_crew_with_ai()
	apply_settings()


## Language, music volume and fullscreen from the saved settings.
func apply_settings() -> void:
	var locale := language if language != "" else OS.get_locale_language()
	if not persist and language == "":
		locale = "en" # automated tests always run in English
	TranslationServer.set_locale("fr" if locale == "fr" else "en")
	var bus := AudioServer.get_bus_index(&"Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, music_volume_db + 8.0) # layers are mixed for -8 dB
	if persist and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED)


## Records a finished voyage: earnings, best score, and the next contract unlocks on delivery.
## Returns the money earned.
func record_voyage(index: int, delivered: bool, score: int, seconds := -1.0, earned_stars := 0) -> int:
	var earned := score if delivered else 0
	money += earned
	var key := str(index)
	last_records = {"score": false, "time": false}
	if delivered and score > int(best_scores.get(key, 0)):
		last_records.score = true
	best_scores[key] = maxi(int(best_scores.get(key, 0)), score)
	if delivered and seconds >= 0.0 and (not best_times.has(key) or seconds < float(best_times[key])):
		last_records.time = true
		best_times[key] = seconds
	stars[key] = maxi(int(stars.get(key, 0)), earned_stars)
	if delivered:
		unlocked = maxi(unlocked, index + 2)
	save_game()
	return earned


func total_stars() -> int:
	var total := 0
	for value in stars.values():
		total += int(value)
	return total


## Whether a contract is open: enough stars (the world map), or developer "unlock everything".
func is_open(index: int) -> bool:
	return unlock_everything or total_stars() >= Progress.stars_needed(index)


func open_contracts() -> Array:
	var open := []
	for i in ContractLibrary.all_contracts().size():
		if is_open(i):
			open.append(i)
	return open


## The hat a player wears (their choice if it's unlocked, else their default).
func outfit_for(index: int) -> String:
	var choice: String = hats.get(str(index), "")
	if choice != "" and Progress.hats_unlocked(total_stars()).has(choice):
		return choice
	return ["tricorn", "bandana", "beanie", "straw"][clampi(index - 1, 0, 3)]


## Next unlocked hat for a player (the dock's Hat button).
func cycle_hat(index: int) -> String:
	var open := Progress.hats_unlocked(total_stars())
	var next: String = open[(open.find(outfit_for(index)) + 1) % open.size()]
	hats[str(index)] = next
	save_game()
	return next


func can_buy(id: String) -> bool:
	return not upgrades.has(id) and money >= int(Upgrades.DATA[id].price)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	money -= int(Upgrades.DATA[id].price)
	upgrades.append(id)
	save_game()
	return true


## Turns an AI crewmate on for an empty slot, with sensible default jobs.
func enable_ai(index: int) -> void:
	var used := []
	for other in ai_crew.values():
		used.append(other.primary)
	var primary := "carpenter"
	# Four crew: one at the map, one at the furnace, one fixing things; the helm for whoever is left.
	for job in ["navigator", "engine", "carpenter", "helm", "pump", "cargo"]:
		if not used.has(job):
			primary = job
			break
	var backups := {"navigator": "carpenter", "engine": "carpenter", "helm": "pump", "carpenter": "pump",
			"pump": "carpenter", "cargo": "carpenter"}
	ai_crew[index] = {"primary": primary, "secondary": backups[primary]}
	joined_players.erase(index)
	save_game()


## Every slot without a human gets an AI crewmate (Olivier, 2026-10-22: the four crew are AI by
## default; players who come aboard take an AI's place).
func fill_crew_with_ai() -> void:
	for index in range(1, 5):
		if not joined_players.has(index) and not ai_crew.has(index):
			enable_ai(index)


func disable_ai(index: int) -> void:
	ai_crew.erase(index)
	save_game()


func reset_progress() -> void:
	money = 0
	upgrades = []
	unlocked = 1
	best_scores = {}
	best_times = {}
	stars = {}
	hats = {}
	seen_oceans = [0]
	save_game()


func save_game() -> void:
	if not persist:
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"money": money, "upgrades": upgrades, "unlocked": unlocked,
				"best_scores": best_scores, "best_times": best_times, "stars": stars, "village": village, "hats": hats, "seen_oceans": seen_oceans, "ai_crew": ai_crew, "language": language,
				"music_volume_db": music_volume_db, "fullscreen": fullscreen, "realistic_sea": realistic_sea,
				"last_join_address": last_join_address}))


func load_game() -> void:
	if not persist or not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if data is Dictionary:
		money = int(data.get("money", 0))
		upgrades = data.get("upgrades", [])
		unlocked = int(data.get("unlocked", 1))
		best_scores = data.get("best_scores", {})
		best_times = data.get("best_times", {})
		stars = data.get("stars", {})
		var saved_village = data.get("village", {})
		if saved_village is Dictionary:
			for key in saved_village:
				village[key] = int(saved_village[key])
		hats = data.get("hats", {})
		seen_oceans = data.get("seen_oceans", [0])
		# Saves from before stars: every contract already delivered counts one star.
		for key in best_scores:
			if int(best_scores[key]) > 0 and not stars.has(key):
				stars[key] = 1
		language = data.get("language", "")
		music_volume_db = float(data.get("music_volume_db", -8.0))
		fullscreen = bool(data.get("fullscreen", false))
		realistic_sea = bool(data.get("realistic_sea", true))
		last_join_address = data.get("last_join_address", "")
		ai_crew = {}
		var saved_ai = data.get("ai_crew", {})
		if saved_ai is Dictionary:
			for key in saved_ai:
				ai_crew[int(key)] = saved_ai[key] # JSON keys come back as text
