extends RefCounted
## All hand-made contracts, in the order they unlock (DESIGN.md section 7: four contracts of
## rising intensity; the last one in fog).

const Contract = preload("res://scripts/contracts/contract.gd")


## The index is how saves remember each contract: new ones go at the end (the world map groups
## them into oceans, see scripts/systems/progress.gd).
static func all_contracts() -> Array:
	return [maiden_voyage(), reef_run(), the_narrows(), fog_bank(), coral_hop(), siren_strait(), whale_road(),
			smugglers_run(), krakens_gate()]


static func by_index(index: int) -> Resource:
	var all := all_contracts()
	return all[clampi(index, 0, all.size() - 1)]


## Contract 1 (DESIGN.md section 8): teaches by doing and cannot be lost.
static func maiden_voyage() -> Resource:
	var contract := Contract.new()
	contract.title = "Maiden Voyage"
	contract.blurb = "A short hop with spare sails. Learn the ropes; nobody sinks today."
	contract.length = 1100.0
	contract.deadline = 420.0
	contract.tutorial = true
	contract.difficulty = 1
	contract.pay_per_crate = 60
	# Buoy lane at 0:45: small hidden markers only the map table shows.
	contract.rock_rows = [
		[190, [-9, 9], 1.5], [215, [-9, 9], 1.5], [240, [-6, 12], 1.5], [265, [-3, 15], 1.5],
		[290, [0, 18], 1.5], [315, [-3, 15], 1.5],
		[930, [6], 2.5],
	]
	contract.waves = [[700, 1]]
	contract.obstacles = [[600, 22, "wreck"], [790, -24, "atoll", 9.0]]
	contract.events = [
		[0, "hint", "Welcome aboard! Walk to a station and press Use. Captain: HELM, hold UP for throttle."],
		[50, "hint", "Engineer: fill a shovel at the COAL pile (back corner), carry it to the ENGINE and press Use. The pile never runs out."],
		[120, "hint", "Buoys ahead! Navigator: climb to the CROW'S NEST and call where they are."],
		[360, "leak", "A wave cracked the hull! Fetch a PLANK, put it on the LEAK, hammer it. Someone: PUMP!"],
		[520, "heat", "Headwind! The engine runs hot. Engineer: at the ENGINE, Jump vents steam (stand clear!)."],
		[880, "rudder", "Rudder trouble! Bring the PIN to the HELM. Two problems at once: split up!"],
		[880, "leak", ""],
		[1040, "hint", "Port ahead! Steer between the yellow buoys."],
	]
	return contract


static func reef_run() -> Resource:
	var contract := Contract.new()
	contract.title = "Reef Run"
	contract.blurb = "Six crates of tinned sardines through the Gull Reef. Five minutes, if nothing breaks."
	contract.length = 1300.0
	contract.deadline = 375.0 # 2026-10-24: the real hull shape and the climb to the nest cost the AI crew ~30 s
	contract.difficulty = 2
	# Pacing (DESIGN.md section 7): calm departure, first complication, calm, overlap, peak, port.
	contract.rock_rows = [
		[220, [0]],
		[280, [-14, 12]],
		[340, [-6, 20, -30]],
		[400, [8, -22]],
		[520, [-35]],
		[620, [0, 25, -25]],
		[680, [-12, 14]],
		[730, [3, -30, 32]],
		[780, [-18, 20]],
		[830, [8, -40]],
		[1000, [-8, 10, 30]],
		[1040, [18, -20]],
		[1080, [0, -30, 34]],
		[1120, [-14, 12]],
		[1160, [24, -4, -36]],
		[1200, [10, -18]],
		[1240, [-6, 30]],
	]
	contract.waves = [[380, 1], [760, -1], [1100, 1]]
	contract.obstacles = [[470, 22, "wreck"], [570, 0, "whale"], [920, -26, "atoll", 10.0]]
	contract.enemies = [[430, -1]] # in the calm stretch: pirates, not rocks
	return contract


static func the_narrows() -> Resource:
	var contract := Contract.new()
	contract.title = "The Narrows"
	contract.blurb = "Fragile glassware through a channel barely wider than the ship. Mind the walls."
	contract.length = 1400.0
	contract.deadline = 345.0
	contract.coast_half_width = 28.0 # the painted ship is longer than the grey box was
	contract.difficulty = 3
	contract.pay_per_crate = 130
	# Rocks near the walls sit against the cliffs, so there are no ship-sized pockets to wedge in.
	contract.rock_rows = [
		[200, [-8]], [250, [8]], [300, [-19, 6]], [350, [19, -4]], [400, [0]],
		[470, [-19, 10]], [560, [6]], [610, [-8, 19]], [660, [2, -19]], [710, [-6, 19]],
		[760, [19, -10]], [810, [0]], [900, [-19, 8]], [960, [19, -6]], [1010, [-2, 19]],
		[1060, [-19, 6]], [1110, [13, -11]], [1160, [0, 19]], [1210, [-19, 8]], [1260, [19, -4]],
		[1320, [-6, 10]],
	]
	contract.waves = [[330, -1], [640, 1], [980, -1], [1240, 1]]
	contract.obstacles = [[530, -14, "siren"], [860, 13, "wreck", 3.5]]
	return contract


## Calm Cove, route 2: a short, friendly run with a wreck and an atoll to steer around.
static func coral_hop() -> Resource:
	var contract := Contract.new()
	contract.title = "Coral Hop"
	contract.blurb = "Pineapples for the atoll market. Short and sweet: steer round the old wreck."
	contract.length = 1000.0
	contract.deadline = 300.0
	contract.difficulty = 1
	contract.pay_per_crate = 80
	contract.rock_rows = [[260, [-12, 14]], [380, [0]], [520, [-20, 8]], [700, [12, -10]], [820, [-4]]]
	contract.obstacles = [[450, 18, "wreck"], [620, -22, "atoll", 9.0]]
	contract.waves = [[600, -1]]
	return contract


## Whale Waters, route 1: two sirens on either side of a strait.
static func siren_strait() -> Resource:
	var contract := Contract.new()
	contract.title = "Siren Strait"
	contract.blurb = "Love letters for the lighthouse. Two sirens sing in the strait. Don't listen!"
	contract.length = 1250.0
	contract.deadline = 330.0
	contract.coast_half_width = 38.0
	contract.difficulty = 2
	contract.pay_per_crate = 110
	contract.rock_rows = [[250, [-6, 14]], [330, [10]], [480, [-14, 4]], [640, [0, 18]], [800, [-12]], [900, [6, -20]],
			[1050, [12, -6]], [1150, [0]]]
	contract.obstacles = [[420, -26, "siren"], [740, 26, "siren"], [980, -24, "wreck"]]
	contract.waves = [[560, 1], [960, -1]]
	return contract


## Whale Waters, route 3: whales everywhere, and a wave that shifts the cargo.
static func whale_road() -> Resource:
	var contract := Contract.new()
	contract.title = "Whale Road"
	contract.blurb = "Delicate porcelain along the whales' road. When the big swell comes, the cargo shifts."
	contract.length = 1350.0
	contract.deadline = 360.0
	contract.difficulty = 3
	contract.pay_per_crate = 140
	contract.rock_rows = [[240, [-10, 12]], [520, [20, -24]], [780, [-6, 26]], [1080, [10, -18]], [1220, [0]]]
	contract.obstacles = [[360, 0, "whale"], [650, 10, "whale"], [930, -8, "whale"], [1150, 28, "atoll", 9.0]]
	contract.waves = [[470, 1], [870, -1]]
	contract.events = [[700, "cargo_shift", "The swell shifted the cargo! Tie the chests back down."]]
	return contract


## Pirate Sea, route 2: a smuggler's ship (no sail: engine only), two pirate attacks, an engine failure.
static func smugglers_run() -> Resource:
	var contract := Contract.new()
	contract.title = "Smugglers' Run"
	contract.blurb = "Hush-hush cargo on a sail-less smuggler's ship. If the engine stops, so do you. Pirates know you're coming."
	contract.length = 1300.0
	contract.deadline = 360.0
	contract.difficulty = 3
	contract.pay_per_crate = 170
	contract.equipment = ["no_sail"]
	contract.rock_rows = [[250, [0, -18]], [380, [14]], [700, [-10, 16]], [820, [4]], [1100, [-14, 10]], [1200, [20]]]
	contract.obstacles = [[960, -22, "wreck"]]
	contract.enemies = [[450, 1], [900, -1]]
	contract.waves = [[640, 1]]
	contract.events = [[580, "stall", "The engine coughed and died! Fix the cooling pipe and get it going again."]]
	return contract


## Pirate Sea finale: a storm, pirates, a siren, a whale and a flooding deck.
static func krakens_gate() -> Resource:
	var contract := Contract.new()
	contract.title = "Kraken's Gate"
	contract.blurb = "The crown jewels, through the worst storm in years. Everything that can go wrong will."
	contract.length = 1500.0
	contract.deadline = 420.0
	contract.difficulty = 4
	contract.pay_per_crate = 220
	contract.storm = true
	contract.rock_rows = [[240, [-8, 14]], [340, [18, -14]], [460, [0]], [620, [-20, 10]], [760, [4, -24]],
			[1000, [-14, 18]], [1120, [2]], [1260, [-10, 14]], [1380, [20, -4]]]
	contract.obstacles = [[540, -26, "siren"], [880, 0, "whale"], [1320, -24, "wreck"]]
	contract.enemies = [[700, 1]]
	contract.waves = [[300, -1], [580, 1], [840, -1], [1100, 1], [1300, -1]]
	contract.events = [[950, "flood", "A wave broke over the bow: the deck is flooding! Pump! Patch!"]]
	return contract


static func fog_bank() -> Resource:
	var contract := Contract.new()
	contract.title = "Fog Bank"
	contract.blurb = "Medicine for the lighthouse keeper. The fog is so thick the chart can't help much: use the telescope."
	contract.length = 1400.0
	contract.deadline = 390.0
	contract.coast_half_width = 40.0
	contract.fog = true
	contract.chart_range = 30.0
	contract.difficulty = 4
	contract.pay_per_crate = 160
	contract.rock_rows = [
		[220, [0, -20]], [290, [14, -10]], [360, [-4, 22]], [430, [10, -24]],
		[520, [-14, 4]], [590, [18, -6]], [660, [-20, 8]], [720, [0, 26]],
		[800, [-10, 14]], [870, [6, -18]], [940, [-24, 2, 22]], [1010, [12, -8]],
		[1080, [-4, 20]], [1150, [16, -14]], [1220, [-8, 6]], [1290, [2, -22, 20]],
	]
	contract.waves = [[480, 1], [900, -1], [1200, 1]]
	contract.obstacles = [[380, -26, "siren"], [750, 0, "whale"], [1120, 28, "wreck"]]
	contract.events = [
		[0, "hint", "Thick fog: the chart only sees 30 m. Navigator: the TELESCOPE at the bow spots rocks further ahead."],
	]
	return contract
