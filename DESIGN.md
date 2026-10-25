# You Piece of Ship — Design Document

> **Current phase:** 4 — Art & content (version 0.4.0, 2026-10-22 evening: painted-kawaii look, AI crew by default, developer mode, battles, fishing, three stars, world map). Before that: 3 — Ugly Prototype. Olivier has played solo with AI crew; the fun gate (a real 4-player couch playtest) is still to come.
> **Last updated:** 2026-10-22 (0.4.0)
> This file is the Committee's memory. Read it before every Godot or Blender action. Update it after every approved decision.

## 1. Pitch
**You Piece of Ship is a 4-player co-op party game where you steer, read charts, stoke the engine and patch the hull of one rickety cargo ship to reach port, but every breakdown changes how the ship handles, so one bad call snowballs into a disaster you can almost save.**

Short form: *Four terrible sailors. One ship. Every mistake makes it worse.*

<details><summary>Pitch iterations</summary>

| Round | Pitch | What changed |
|---|---|---|
| 1 | A co-op party game where you crew a ship to deliver cargo, but the ship keeps falling apart. | v0.1 high concept. "Falling apart" is a theme, not a mechanic. |
| 2 | A co-op party game where four friends each run one post on a cargo ship to beat a deadline, but every mistake physically breaks the ship. | Names the micro verb and macro goal. |
| 3 | (current pitch) | The hook becomes a mechanic: damage changes handling, which creates the cascade and the near-save. |

</details>

## 2. MDA
### Aesthetics (target forms of fun, ranked — confirmed by Olivier)
1. **Comedy** — a player sprints across the deck with the only replacement pipe, a wave tilts the ship, the pipe slides overboard, and all four players scream at once.
2. **Social interaction** — the navigator shouts "reef, 3 o'clock, hard left NOW" and the captain, who cannot see it, trusts them and swings the wheel.
3. **Thrill of danger** — the ship limps into port at 4% hull with water at the cabin door, and the crew cheers like they won a final.

Advancement (upgrades) supports these but is not a pillar: if an upgrade makes the game less funny, it is cut.

### MDA chain
| Aesthetic (feel) | ← Dynamic (emergent behavior) | ← Mechanic (rule) |
|---|---|---|
| Comedy | Slapstick accidents: dropped parts, collisions, players knocked over | Carried items drop on knockdown; deck tilts with waves and load; loose objects slide downhill; players collide |
| Comedy | Bad decisions with visible, ridiculous consequences | Damage is shown on the ship itself (water level, smoke, missing plank), never only as a number |
| Social interaction | Constant callouts, requests and arguments | Information is bound to stations; only the player at a station can read it |
| Social interaction | The crew negotiates which problem to solve first | Systems compete: speed raises heat, repairs need low speed, the route needs speed |
| Social interaction | Pairs form for big jobs | A few tasks (large patch, cooling pipe) need two players for 3–5 s |
| Thrill of danger | Cascades: one mistake spawns two more problems | Coupled systems (hull ↔ load ↔ handling ↔ engine) |
| Thrill of danger | Near-saves | Warnings before every failure; emergency measures that buy time at a cost; nothing fails twice from one cause |

## 3. Core Loops
- **Micro (every 1–5 s): read, shout, act.** Read your station, call out what matters, act on a call (turn the wheel, open a valve, slap a patch, run to a problem). Must be fun in a grey box with four players and no art.
- **Mid (every 30–90 s): routine → complication → crisis → recover.** A hazard director guarantees at least 20 s of routine after every recovery.
- **Macro (one voyage, 5–8 min): contract → sail → deliver → upgrade.** Paid on cargo, time, hull, fish and loot; spend on one upgrade; take a harder contract.
- **Meta (a session, 30–90 min): world map → route → stars → new ocean.** Stars (1–3 per route, from the score) open routes and oceans; each ocean brings one new kind of trouble; stars also unlock hats (section 14).
- **How macro feeds back into micro:** every upgrade changes a post's job rather than removing it (overclocked engine = more for the engineer to watch; reinforced hull = captain plans turns earlier). Contract modifiers (fog, night, fragile cargo) change which station is busiest.

## 4. Genre, Mood & Audience
- **Genre / comparables:** chaotic co-op party game, 3D, third person, 2–4 players (designed for 4), playable on one couch (one shared screen, a controller each) and online. Comparables: Overcooked, Lovers in a Dangerous Spacetime, Sea of Thieves, Keep Talking and Nobody Explodes.
- **Mood (3 adjectives):** frantic, goofy, triumphant.
- **For:** groups of friends who already play Overcooked or Moving Out together, on the same couch or on voice chat, in 30–90 minute sessions; mixed skill levels.
- **Not for:** solo players, competitive players who want PvP, players who want a deep sailing simulation, players who want long-term character progression.

## 5. Uniqueness
The damage itself is the level design: a broken ship handles differently, so each mistake rewrites everyone's job for the next two minutes. Mechanic: coupled ship systems where damage changes handling (section 13).

| Comparable | What we do differently |
|---|---|
| Overcooked | Problems are caused by the crew's own earlier choices and chain into each other |
| Lovers in a Dangerous Spacetime | Damage changes handling and creates new physical work; information is split across stations |
| Sea of Thieves | Short authored voyages with a deadline and party-game readability, not a sandbox |
| Keep Talking and Nobody Explodes | The information split is spatial and swappable, and everyone also has hands-on work |

## 6. Feature Split (60 / 40)
| Feature | Type | Serves | Notes |
|---|---|---|---|
| Station-bound information (map, gauges, telescope) | Innovation | Social | Prototype first |
| Coupled ship systems (hull, heat, rudder, load) | Innovation | Danger, Comedy | Signature mechanic |
| Damage changes handling | Innovation | Danger | Part of coupled systems |
| Conflicting urgency (speed vs heat vs repair vs route) | Innovation | Social | Emerges from systems; tune, don't script |
| Two-player tasks (big patch, cooling pipe) | Innovation | Social, Comedy | Max 2 in the slice |
| Voyage recap (chain of events) | Innovation | Comedy | Event log shown as a timeline on results |
| Walk, run, jump, carry, interact | Standard | All | Overcooked-style controls |
| Exaggerated deck physics (tilt, slide, knockdown) | Standard | Comedy | Simple and predictable, not a sim |
| Helm, throttle, wind | Standard | Danger | Arcade handling |
| Deadline timer and route with port | Standard | Danger | |
| Results screen with score | Standard | Advancement | Cargo + time + hull |
| Quick restart | Standard | All | Under 10 s |
| Upgrade shop with trade-offs | Standard | Advancement | 4 upgrades in the slice |
| Couch play on one shared screen | Standard | Social | Milestone A |
| Online lobby, drop-in and reassign | Standard | Social | Milestone B, host-authoritative |
| Contract modifiers | Standard | Danger | Fog, storm, shifting cargo, engine failure, flooded bow, sail-less ship |
| AI crewmates fill every empty post; humans take one over | Standard | Social | All 4 AI by default (Olivier 2026-10-22) |
| Thought bubbles above crew (plans, callouts, shouts) | Standard | Comedy, Social | Replaced the band captions |
| Sea battles: pirates alongside, side cannons, fight or outrun, loot | Standard | Danger, Comedy | Added by Olivier 2026-10-22 (was Parked) |
| Fishing at the rail for idle crew | Standard | Comedy | Points into the score; nobody idles |
| Three stars per route, world map with 3 oceans x 3 routes, hats | Standard | Advancement | Overcooked-style progression, Olivier 2026-10-22 |
| Developer mode on Esc (sliders, forced events) | Tool | — | For tuning and testing only |
| Fire | Next | Danger | Fourth system once the first three are fun |
| Crew overboard and rescue | Next | Comedy | Costly to network |
| Floating cargo recovery, extra upgrades | Later | Advancement | |
| Secret objectives, many classes, crafting, permadeath | Parked | — | |

## 7. Pacing
- **One voyage (5–8 min):** calm departure (45 s) → first complication (one system) → recovery + calm (≥ 20 s) → rising section, two systems overlap → peak crisis in the last third → port in sight, release. Hazards are hand-placed; the director only enforces fairness rules and calm windows.
- **The slice (~30 min):** four contracts of rising intensity; the shop between them is the rest stop. Contract 4 adds fog.
- **The world map (since 0.4.0):** nine routes in three oceans of rising intensity (Calm Cove, Whale Waters, Pirate Sea), ending with Kraken's Gate in a storm. Stars gate progress, so a crew replays a route to get better rather than grinding.

## 8. Onboarding
Contract 1, "Maiden voyage", teaches by doing and cannot be lost:
1. **0:00 Dock.** Stations glow; walking to one shows a one-line prompt ("Hold to steer"). No tutorial screens.
2. **0:45 Open water.** A buoy lane teaches steering and callouts: buoys appear on the map table before the captain can see them.
3. **1:30 First leak.** A scripted wave cracks one plank; teaches patching and pumping. Cannot sink the ship.
4. **2:30 Heat.** A headwind forces full throttle; the whistle teaches venting.
5. **3:30 Small cascade.** A gentle rock hit cracks the hull and nudges the rudder at once: feel the coupling safely.
6. **4:30 Port.** Results and recap. Failure means a later dock and lower score.

## 9. Vertical Slice Boundary
**Milestone A — Ugly Prototype (Phase 3 fun gate):** one grey ship, four stations, one 5-minute route with rocks and waves, hull + heat + rudder coupled, carry and knockdown, local couch play on one shared screen (no networking yet), results screen, restart. Passes when a group of four (not only Olivier) asks for another run unprompted and can explain why they sank.

**Milestone B — Vertical Slice. Target length:** ~30 minutes.
- **IN:** one ship; four stations; four hand-made contracts (last in fog); four systems (hull, heat, rudder, load); two two-player tasks; the three deck comedy rules; upgrade shop with 4 trade-off upgrades (overclocked engine, reinforced hull, bigger pumps, second spare-parts crate); results with event recap; couch play on one shared screen; online lobby for 3–4 players with drop-in reassignment; final art, sound and juice for all of the above.
- **OUT (explicitly not building):** fire, crew overboard, floating cargo, second ship, procedural routes, campaign map, more than 4 upgrades, 2-player mode, split screen, mixed couch-plus-online groups, cosmetics, secret objectives, combat, crafting, persistent progression.

**Scope change (Olivier, 2026-10-22 evening):** Olivier explicitly brought into scope a campaign-style world map, star ratings, cosmetics (hats), combat (pirate ships) and fishing. The OUT list above is kept as the original plan; those five items are now IN. Still out: fire, crew overboard, second ship, procedural routes, 2-player mode, split screen, mixed couch-plus-online, secret objectives, crafting.

**Playtest survey (every Milestone A session):** Did you have something useful to do most of the time? Did you understand why things went wrong? Did your actions help the team? Did the crew recover from something that seemed hopeless? Did you immediately want another attempt? Who did you talk to most, and about what?

## 10. Risks
| Risk | Why it matters | How we test it early |
|---|---|---|
| Networked physics on a moving ship feels laggy or desyncs | Comedy dies if a knockdown looks different on each screen | Milestone A is couch-only. First Milestone B task: two Godot instances on LAN, host-authoritative, players in ship-local space, scripted buoyancy instead of a rigid-body sim |
| One player bosses the others | Social interaction becomes one person playing through three | Survey "who did you talk to most"; if lopsided, move a key reading off the captain's path |
| Deckhand overloaded, captain bored | Breaks the "nobody idles" rule | Log idle time per post; target under 15% |
| Cascades feel unfair, not funny | Players blame the game | Survey "did you understand why things went wrong"; lengthen that failure's warning |
| Upgrades remove the chaos | Advancement fights Comedy | Every upgrade adds a decision; playtest contract 4 fully upgraded |
| Shared couch screen softens the information split | Everyone can glance at the map | Navigator's edge = hands and attention on the chart; watch whether players still call out |
| Not enough testers for 4-player sessions | Fun gate needs four people | Book a weekly group of four early |

## 11. Decision Log
| Date | Decision | Why | Evidence (playtest / issue) |
|---|---|---|---|
| 2026-10-22 | Committee Summary approved; project scaffolded | Phase 1 complete | Olivier: "yes" |
| 2026-10-22 | Godot 4 engine | Free; matches the Committee tooling | Olivier confirmed |
| 2026-10-22 | Two milestones: 5-min prototype, 30-min slice | Prove the loop before progression | Olivier confirmed |
| 2026-10-22 | Couch first, online second | Couch needs no networking; riskiest tech waits until fun is proven | Olivier: online and couch |
| 2026-10-22 | Non-developer mode | Olivier has not coded before | Olivier: technical comfort (a) |
| 2026-10-22 | Roles become station-bound posts | Fixes role swapping, disconnects and couch play; gives the Crisis beat a cost | Design review of v0.1 |
| 2026-10-22 | Four coupled systems; fire and overboard to Next | Fewer, deeper systems make cascades readable | Design review of v0.1 |
| 2026-10-22 | Fog hides hazards from the helm | Gives the navigator unique, necessary information | Design review of v0.1 |
| 2026-10-22 | Ship is one moving body rocked by scripted waves (roll 8°, pitch 3°, heave 0.3 m); crew are children of the ship | Players stay on board without a physics sim; the motion is predictable and ship-local, ready for networking (Risk 1) | #1, tests/integration/test_rocking_deck.gd |
| 2026-10-22 | One shared camera, level with the horizon, always framing the whole ship and all crew | Couch play on one screen; nobody hunts for themselves; the deck visibly rocks against a steady view | #1 |
| 2026-10-22 | Stations are spots on the deck: the helm (stern) needs Use and takes over the stick; the map table (bow) works by standing at it | Information and controls belong to the station, not the player (section 12); captain and navigator are 10 m apart so they must shout | #2 |
| 2026-10-22 | Map table chart is heading-up, 70 m range, shown in a screen corner only while someone stands at the table; the camera leaves that corner free | "Rock at 2 o'clock" means the same to captain and navigator; the shared couch screen is a known risk (section 10) | #2 |
| 2026-10-22 | Rock hits stop the ship, bounce it back and reveal the rock; no hull damage yet | Damage arrives with #3; this keeps #2 about callouts only | #2 |
| 2026-10-22 | Small juice pass (crash, wake, squash, confetti) on the GameFeel node, each effect switchable | Requested by Olivier before Phase 4; kept small and reversible so each effect can be kept or cut | Olivier request |
| 2026-10-22 | Placeholder music: synthesised "Drunken Sailor" loop (public-domain tune) on a Music bus; M / Select mutes; ducks on crash, speeds up near port | Requested twice by Olivier; mute it for fun-gate playtests so music doesn't mask the mechanics | Olivier request |
| 2026-10-22 | Ship enlarged to 18 x 7 m with a fixed layout: helm (stern), map table (bow, port), spare-parts boxes (port, amidships), cargo bay of 6 lashed crates (forward of the mast) | Room for four stations, repairs and running around; side lanes stay clear so crew can cross the ship | #5 |
| 2026-10-22 | Use is one context button: leave a station, apply or drop the carried item, pick up, take over a station (nearest in reach wins) | One button keeps couch controls learnable for mixed-skill groups (section 4) | #5 |
| 2026-10-22 | Big waves warn for 5 s (sign + side), then roll the ship 14 degrees; anyone not holding a station is knocked down and drops what they carry; loose items slide downhill; fast crates bowl people over | Deck comedy rules and fairness rule (warning of at least 5 s), section 13 | #5 |
| 2026-10-22 | Six fixed leak spots along the rails; a rock cracks the nearest free one (5 s cracking warning, then water); the same rock can't crack more hull for 8 s | Readable, predictable damage on the ship itself; fairness: warnings and one failure per impact | #3 |
| 2026-10-22 | Fixes: crate plug (flow to 30%, cargo lost) or plank patch (place plank, hammer: 4 s with 2 crew, 12 s alone); pump at the stern removes water | Emergency measure at a cost vs proper fix (section 13); one-person patching stays possible for small crews | #3 |
| 2026-10-22 | Water effects: top speed up to -45%, turning -30%, sits 0.7 m lower, lists up to 6 degrees toward the leaks; full = sunk, never within 60 s of the first failure | Damage changes handling (the signature mechanic); fairness rule | #3 |
| 2026-10-22 | Engine room (stern starboard): hold up to shovel coal, Jump to vent steam; heat and coal gauge only shows to the engineer, in the top-right HUD corner | Station-bound information; the engineer has hands-on work all the time (no idling) | #4 |
| 2026-10-22 | Heat rises above 55% throttle and faster with water aboard; >80% caps top speed at 70%; 100% gives a 5 s warning then a 20 s stall that bursts the cooling pipe; venting cools 50% but knocks over crew within 3 m (8 s cooldown); burst pipe heats 1.6x faster until fixed (4 s with 2 crew, 12 s alone) | Conflicting urgency (speed vs heat) and coupling rule 3; emergency measure at a cost | #4 |
| 2026-10-22 | Impacts above half speed damage an intact rudder instead of the hull (otherwise the hull cracks): one impact, one failure | Coupling rule 1 combined with fairness rule 'one impact starts at most one new failure' | #6 |
| 2026-10-22 | Broken rudder: 5 s wheel shudder warning, then half steering response and a pull to one side even with nobody steering; fix by carrying the single spare rudder pin (half walking speed) to the helm | Rudder row of section 13; one spare makes a second rudder break a real crisis | #6 |
| 2026-10-22 | Cargo position sets heel (1.2 degrees per crate-metre off centre, max 12) and trim; top speed is for a full load, +2% per crate lost | Load and balance row of section 13; throwing cargo is an emergency measure with a reward cost | #7 |
| 2026-10-22 | Before each big wave one lashed crate's rope frays (label on the crate); if nobody takes it in hand before the wave hits, it breaks loose toward the low side | Crates rattle, ropes fray warning (section 13); the wave becomes a decision, not just a knockdown | #7 |
| 2026-10-22 | Carry a crate to any rail and press Use to throw it overboard | Emergency measure: lower reward; a crate stuffed in a leak is also lost cargo | #7 |
| 2026-10-22 | Voyages are built from hand-made contracts (rocks, waves, deadline, pay); the Reef Run is the Milestone A route: 1300 m, deadline 5:30, calm first 200 m, peak rocks in the last third | Pacing of section 7; the same data drives Milestone B's four contracts | #9 |
| 2026-10-22 | Visible cliffs line the channel 45 m either side; hitting them is a crash; the chart shows a PORT arrow with the distance when the port is beyond its range | Keeps the navigator's job about the reef, not about finding the way | #9 |
| 2026-10-22 | Main scene is now scenes/levels/voyage.tscn; a Session autoload remembers the crew and chosen contract across restarts | Quick restart (< 10 s) and contract choice later | #9 |
| 2026-10-22 | Hazard director: big waves start at their contract position only while at most one system (hull, engine, rudder, load) is failing and 20 s after the last recovery; a wave still waiting 200 m later is dropped | Fairness rules of section 13 and calm windows of section 7; hand-placed hazards, director only enforces fairness | #8 |
| 2026-10-22 | Results: DELIVERED/SUNK, time vs deadline, cargo, hull, score = cargo value + up to 200 for a dry hull + 2 per second early (sunk = 0), and a 'what happened' timeline from the voyage log | Survey: 'did you understand why things went wrong?'; the recap is the comedy replay (section 6) | #10 |
| 2026-10-22 | Crew screen on first launch: press Jump to join, Use to set sail; R restarts with the same crew in seconds; J changes crew; 3 or fewer players get a slow automatic pump (30% of the pump) | Quick restart under 10 s; 3-player rule of section 12 | #10 |
| 2026-10-22 | Rocks deflect the ship (back off, sidestep, bow turns 10 degrees away); scraping along the coast or re-bumping a rock within 8 s is one accident | A simulated full voyage showed straight-ahead crashes trapping the ship against a rock until it sank | #10 |
| 2026-10-22 | Reef Run deadline stays 5:30: a simulated crew at 80% throttle venting at 90% heat arrives in about 4:53; full throttle stalls repeatedly | Simulation calibration; real crews will be slower, check in the first playtest | #10 |
| 2026-10-22 | Four contracts unlock in order: Maiden Voyage (tutorial, can't sink, scripted lessons with on-screen hints), Reef Run, The Narrows (26 m channel, 4 waves), Fog Bank (fog, 30 m chart, telescope); pay per crate 60/100/130/160 | Section 7 (four contracts of rising intensity, last in fog) and section 8 (Maiden voyage teaches by doing) | #11 |
| 2026-10-22 | Fog: light haze over the sea, chart shrinks to 30 m; a bow telescope (only in fog) marks rocks up to 90 m ahead in a 35-degree cone with red markers everyone sees for 5 s; it is a separate station from the map table | Fog hides hazards from the helm; the navigator must choose between map and telescope (section 12) | #12 |
| 2026-10-22 | The game now starts at the dock: crew joins with Use, picks an unlocked contract, buys upgrades; results return to the dock with the score added as coins; delivering unlocks the next contract | Macro loop of section 3 (contract, sail, deliver, upgrade) for the ~30-minute slice | #13 |
| 2026-10-22 | Upgrades: overclocked engine 450 (+20% speed, heats 45% faster), reinforced hull 500 (leaks 40% slower and +3 s warning, but -8% speed and -10% turning), bigger pumps 350 (+80% pumping, pump burns coal), second spares crate 300 (+3 planks +1 pin, one fewer cargo crate) | Every upgrade changes a post's job rather than removing it (section 3); Advancement must not kill the chaos (section 2) | #13 |
| 2026-10-22 | Coins, upgrades, unlocked contracts and best scores are saved to user://save.json; the crew is chosen fresh each session; automated tests never read or write the save | Progress survives closing the game; tests stay independent of what the player bought | #13 |
| 2026-10-22 | The throttle goes to -30% (ASTERN) so a crew can back off a rock; going astern turns the other way and still works the engine; collisions bounce opposite to the direction of travel | Simulated voyages showed ships wedged between a rock and the coast with no way out | #11 |
| 2026-10-22 | The Narrows: rocks near the walls sit against the cliffs, so every gap is either clearly passable (13 m or more) or closed | No ship-sized pockets to wedge in | #11 |
| 2026-10-22 | Online play is host-authoritative: the host's machine simulates everything; clients send their stick every frame and button presses reliably; the host sends a 20 Hz snapshot (ship, ship-local crew and item positions, leak/engine/rudder/pump state, station texts) plus reliable events (crash, waves, hints, telescope spots, results) | Risk 1 of section 10: one simulation, ship-local positions, so knockdowns look the same on every screen | #14 |
| 2026-10-22 | Online lobby on the dock: the host is P1, friends join with the host's address and become P2-P4 using their own keyboard (W A S D) or first controller; only the host picks contracts, restarts or returns to the dock; mixed couch-plus-online stays out of scope | Section 9 boundary; keeps couch play untouched | #14 |
| 2026-10-22 | Online is checked by a two-process script (tests/net/), not GUT: one process can't hold two separate games because systems share scene-tree groups | Verified on this Mac over localhost: client joins as P2, sees the same ship, crew and items, its stick moves its sailor on both screens, and it gets the results screen | #14 |
| 2026-10-22 | Coal: the pile beside the engine never runs out; a full firebox lasts 2.5 min at full throttle (was 1.5) and refills empty-to-full in 5 s of shovelling; 'COAL LOW!' shows over the engine below 25% with a hint; the Maiden Voyage never drops below 30% | Olivier ran out of coal in the first round playing alone and didn't know how to get more | Olivier playtest 2026-10-22 |
| 2026-10-22 | AI crewmates fill empty slots (set at the dock: on/off, a job and a backup job; jobs: helm, navigator, engine, pump, carpenter, cargo). Humans choose first: a station a human uses is theirs, and a human can take over a station from an AI. Each AI picks between job and backup by need (routine, urgent, critical); anything critical nobody covers (steering, a flooding hold, a stalling engine) pulls in a free AI | Olivier couldn't finish the Maiden Voyage alone; AIs make solo and small-crew play possible without removing human roles | Olivier 2026-10-22 |
| 2026-10-22 | AI navigator shouts clock-bearing callouts in a speech bubble ('Rock, 2 o'clock, 40 m!'); in fog it mans the telescope; the AI helmsman only knows hidden rocks while someone reads the chart or the telescope marked them; the chart and engine gauge only show on screen for human readers | Keeps station-bound information and the callout loop (Social interaction) even with AI teammates | Olivier 2026-10-22 |
| 2026-10-22 | One idle human + 3 AIs (helm/pump, navigator/carpenter, engine/carpenter) deliver the Maiden Voyage (5:20, 0 hits), the Reef Run (5:27, 0 hits) and the Fog Bank (5:52, 0 hits); they fail The Narrows. Checked by tests/ai/full_voyage_check.gd, run by CI for the first two contracts | Coordinator brief: one human + 3 AIs must finish Maiden Voyage and Reef Run | tests/ai |
| 2026-10-22 | Visual pass with Olivier's pixel art: crew are animated NES pirates (run, walk, idle, push/pull at stations, arms-up carry, hit when knocked) recoloured per player, camera-facing and drawn over furniture so nobody is ever hidden; name tags and speech bubbles follow the camera's up so they sit on the head | Readability first (couch screen); keeps P1-P4 colours | Olivier 2026-10-22 |
| 2026-10-22 | Ship dressed with tile-set textures (deck, hull, rails, mast), crate-built spare boxes, crate/plank/pin item sprites, coal pile, rocky cliffs and a 60% see-through canvas sail; collisions, stations and the grey-box option (pixel_art = false on the ship and crew) unchanged. Textures are cut reproducibly by tools/cut_pixel_art.gd | Visual enhancement without touching gameplay; cannons and barrels left out until ship combat exists | Olivier 2026-10-22 |
| 2026-10-22 | Ship combat moves from Parked/OUT to Later: enemy AI ships to sink, with cannons; not built yet | Olivier's direction after playing; it changes the Comedy/Social pillars' balance, so it needs its own design pass before Milestone B is closed | Olivier 2026-10-22 |
| 2026-10-22 | Online test instructions in README; the dock always shows this computer's address; port 7777; same-Wi-Fi only for now (internet needs port forwarding) | Olivier asked how to test with multiple players online | Olivier 2026-10-22 |
| 2026-10-22 | Coal pile in the stern corner (3 m from the furnace): Use fills a shovel (15% of the firebox), Use at the engine feeds it; a hit while carrying spills half (black mark on the deck), falling over spills all; water soaks the pile, wet coal gives 40% less and costs up to 35% top speed ('WET COAL'); holding up at the engine no longer shovels | Olivier: the engineer needs something to do; spills and wet coal tie the engine to hits and flooding (coupled systems) | Olivier 2026-10-22 |
| 2026-10-22 | The sail always pushes at least 1.2 m/s once under way (not when going astern) | Olivier: always a minimum speed | Olivier 2026-10-22 |
| 2026-10-22 | AI jobs are filled by need (most needed first, best-suited AI first); AIs use the exact thing they intend (not the nearest); a carried part keeps its repair on the list; spare AIs do useful idle work (pump, coal, re-lash, hold a plank ready); default AI jobs: navigator, engine, carpenter, then helm; the engineer vents as soon as heat passes the 80% cap | Olivier: AIs stood around; a test now fails if an AI is idle more than 3 s while there is work | Olivier 2026-10-22 |
| 2026-10-22 | Personal bests per contract: best score and fastest delivery, saved; NEW BEST on the results; shown on the dock | Olivier asked for personal bests for time and score | Olivier 2026-10-22 |
| 2026-10-22 | Adaptive soundtrack: 12 synced layers of the same Drunken Sailor arrangement at 100 BPM (vertical layering), tense and cluster harmony variants under the same melody (adaptive harmony), stings for crash, honk, fanfare, cadence and sad trombone (horizontal events), bass and drums drop out when the engine stalls; driven by a hidden stability score with fast-fall, slow-rise smoothing and a 5-point hysteresis | Olivier's brief (ChatGPT music-theory notes): keep the tune recognisable while the band gets increasingly nervous | Olivier 2026-10-22 |
| 2026-10-22 | Fourth wall: a band corner (bottom left) with the sheet's pirate portrait comments on state changes and events; captions can be switched off; a hard limiter on the Music bus prevents clipping | Tongue-in-cheek tone Olivier asked for; readability (short, corner, fades) | Olivier 2026-10-22 |
| 2026-10-22 | New main menu after Olivier's mockup: title on a drawn wooden sign (wheel, anchor, wave; title stays English), Quick Play (random open contract, AI crewmates fill empty posts), Host, Join (remembers the last address), Ship & Upgrades (the dock), Settings (language, music volume, band comments, full screen), Quit; tagline, 4 PLAYERS CO-OP badge, version; background = the painted deck from the mockup, gently swaying | Olivier's reference image; HD cartoon UI built in Godot (no art-generation tool: godogen not installed for safety, Aseprite not installed) | Olivier 2026-10-22 |
| 2026-10-22 | Interface juice: one cartoon theme (rounded chunky panels, Arial Rounded / Segoe UI Black), every button grows on hover/focus and squashes on press with sounds, menus cascade in, curtain transitions between screens, results stamp + roll-up numbers + coin bursts, coin bursts on purchases, screen-edge alarm flashes, controls help fades after 30 s (H toggles) | Olivier asked for a heavy juice pass on the interface; readability first | Olivier 2026-10-22 |
| 2026-10-22 | The game window opens maximized (full screen optional in Settings) and the interface scales with it at full screen resolution, so text and panels stay crisp on Retina and big displays | Olivier asked to double the resolution again; the design layout stays 1152x648 and stretches | Olivier 2026-10-22 |
| 2026-10-22 | French version: every interface text, prompt, hint, callout, band comment, voyage-log line and result is translated (translations/strings.csv, built from tools/translations_fr.py; English text is the key); the title 'You Piece of Ship' and the P1-P4 tags stay as they are; language follows the computer and can be switched in Settings | Olivier asked for a French version leaving the title intact | Olivier 2026-10-22 |
| 2026-10-22 | Internet hosting without any service: Host asks the router (UPnP) to open UDP 7777, compares the router's outside address with the public address from an HTTPS what's-my-IP check (api.ipify.org), and tells the host in plain words: friends can join at X (with Copy), or the connection can't host (CGNAT: let the friend host), or the router didn't open the door (UPnP off); the mapping is removed on leave/quit | Olivier and his dad are in different countries; Parsec and Tailscale don't work for them; his dad hosts first, a relay only if that fails | Olivier 2026-10-22 |
| 2026-10-22 | Olivier's home connection: router without UPnP and a provider-shared address (CGNAT, 100.72.x after the router); on his phone hotspot also no UPnP. He can't host for his dad; his dad hosts | Measured on Olivier's Mac 2026-10-22 | network check |
| 2026-10-22 | Superseded: the layered adaptive soundtrack and the band captions are replaced by one Drunken Sailor loop that climbs in pitch (0, +2, +4, +7, +12 semitones) as stability drops | Olivier: same theme, simply higher as things get worse; captions didn't read | Olivier 2026-10-22 |
| 2026-10-22 | Esc opens a pause menu with a Developer panel: live sliders for every tunable, buttons to force events (crash, flood, reach port, pirates, storm...), time scale, saved presets | Fast tuning without code; Olivier tests alone | Olivier 2026-10-22 |
| 2026-10-22 | All four crew are AI by default; a human replaces an AI at the dock, online, or mid-voyage by pressing Jump or Use; comic thought bubbles show AI plans and navigator callouts | Olivier can play alone or with any number of friends; Social and Comedy stay readable | Olivier 2026-10-22 |
| 2026-10-22 | Painted kawaii art: real ship silhouette (curved hull, raised bow and stern decks, mast and sail, gunports), chubby 3D crew with hats, treasure chests, a hand pump that rocks and gushes, visibly heating engine, Gerstner-wave sea; new obstacles: wreck, whale, siren, atoll | Every asset shows its affordance; Olivier's title-screen style | Olivier 2026-10-22 |
| 2026-10-22 | Three stars per voyage from the score (1 = delivered, 2 and 3 = good and great), thresholds per route and tunable in Developer | Clear goal to replay a route; Overcooked model | Olivier 2026-10-22 |
| 2026-10-22 | Fishing: two spots on the rail, cast with Use, strike with Jump; fish add points; AI fishes only when nothing needs doing | Nobody idles; small comic side job | Olivier 2026-10-22 |
| 2026-10-22 | Sea battles: pirates come alongside and fire broadsides (they only attack from the sides, where the cannons are); 2 cannons a side and a cannonball rack; 3 hits sink them and leave 3 loot barrels (60 points each); they give up when left 45 m behind or after 75 s; AI gunner job | Fight or outrun is a crew decision (Social); loot is points for now, purpose open | Olivier 2026-10-22 |
| 2026-10-22 | World map: 3 oceans x 3 routes (Calm Cove: Maiden Voyage, Coral Hop, Reef Run; Whale Waters: Siren Strait, The Narrows, Whale Road; Pirate Sea: Fog Bank, Smugglers' Run, Kraken's Gate); star gates 0/1/3, 5/7/9, 12/14/17; one new trouble per ocean; hats unlock at 6 (captain) and 15 (crown) stars; old saves get one star per delivered contract. Version 0.4.0 | Overcooked-style progression Olivier asked for | Olivier 2026-10-22 |
| 2026-10-25 | Telegraphed broadsides: pirates take aim for 2 s (gun ports, fuse hiss, red rings on our deck that lead a moving ship) before firing; balls land in the rings and hit our deck only where they land; a hit while they aim spoils the shot (half reload) | Counterplay for every post: the helm dodges, the crew steps off, the gunners race to shoot first (Social, Danger); readable chaos instead of random damage | Olivier 2026-10-25 |
| 2026-10-25 | Shot sirens are skewered on the bowsprit like shrimp on a kebab stick (curled into a C under the pole, banded tail, crossed-out eyes, drawn over the sails; three hang under it, more curl on top); one cannonball breaks any breakable (rock, wreck, whale, siren, barrel) for all the loot the old hits gave together; rams still need the old number of bumps so rocks stay obstacles, no longer on the bowsprit; fishing easier: 3 tugs in 4 are real bites (was 1 in 2) and the strike window is 1.35-2.4 s (3x) | Trophies where everyone sees them (Comedy); fishing was too fiddly to be fun | Olivier 2026-10-25 |

## 12. Posts (roles)
Information and controls belong to the station, not the player. Anyone can use any station.

| Post | Station and what only it shows | Routine job | Calm-time task | Signature failure |
|---|---|---|---|---|
| Captain | Helm on the raised stern: throttle, wheel, wind vane. Sees the surface near the ship, not submerged rocks or anything in fog | Hold course, set speed, call "brace" | Trim the sail for a small speed bonus | Overcorrects, turns broadside to a wave |
| Navigator | Map table below deck: hidden reefs, route, deadline. Telescope on the bow spots hazards in fog but leaves the map unread | Call headings and distances; pick shortcut or safe route | Re-plot a quicker route; recover a blown chart page | Right call, two seconds too late |
| Engineer | Engine room: heat gauge, fuel, pressure valves, power split | Keep heat green, shovel fuel, divert power | Pre-cool before a sprint; prepare spare parts | Overheats at the worst moment |
| Deckhand | No fixed station; hull leak and fire alarms show where to go | Patch, pump, secure cargo | Pre-cut patches; lash cargo; restock toolbox | Patches one leak while another floods behind |

Rules: nobody idles while their system is fine; posts are swappable any time; no permanent classes. With three players there is no dedicated deckhand: the ship gets a slow automatic pump and the other three share repairs. Two-player play is Parked.

## 13. Ship Systems and Cascades
| System | Effect when damaged | Warning (5–10 s) | Emergency measure (at a cost) | Proper fix |
|---|---|---|---|---|
| Hull and water | Water adds weight: slower, lower, deck tilts toward the flood | Planks creak, spray from a seam | Stuff a crate in the hole (stops 70% of flow, crate cargo lost) | Plank patch (two players, 4 s), then pump |
| Engine heat | Above 80% heat top speed is capped; at 100% stall for 20 s | Gauge red, steam, whistle | Vent steam (instant cool, knocks nearby players down) | Fix cooling pipe (two players) |
| Rudder | Steering response halves, then the wheel pulls to one side | Wheel shudders after impact | Lash the wheel and steer with throttle bursts | Swap rudder pin from the spares crate (heavy, walking speed) |
| Load and balance | Shifted cargo or water tilts the deck; loose crates slide and knock players over | Crates rattle, ropes fray | Throw cargo overboard (lower reward) | Re-lash and rebalance cargo |

**Coupling rules:** (1) impacts damage the hull and, above half speed, the rudder; (2) water and shifted load make the ship heavier and tilted, which slows it and worsens steering; (3) a slow, badly steering ship needs more power, raising heat; (4) a stall leaves the ship drifting, making the next impact likely.

**Deck comedy rules:** carried items drop on knockdown; the deck tilts with waves and load and loose things slide to the low side; player bumps are exaggerated. All visible and predictable.

**Fairness rules:** every failure has a warning of at least 5 s; one impact starts at most one new failure directly; no new hazard spawns while two systems are failing; the ship cannot sink within 60 s of its first failure.

## 14. Progression, Battles and Side Jobs (0.4.0)
| Ocean | Routes (star gate) | New trouble |
|---|---|---|
| Calm Cove | Maiden Voyage (0), Coral Hop (1), Reef Run (3) | Rocks, waves, first pirates on Reef Run |
| Whale Waters | Siren Strait (5), The Narrows (7), Whale Road (9) | Sirens pull the wheel, whales dive, cargo shifts |
| Pirate Sea | Fog Bank (12), Smugglers' Run (14), Kraken's Gate (17) | Fog, a ship with no sail, engine failure, storm with flooded deck |

- **Stars:** 1 for delivering, 2 and 3 for good and great scores. Score = cargo + dry hull + time bonus + fish + loot.
- **Unlocks:** routes and oceans by stars; hats per player (captain's hat 6 stars, crown 15). A card announces each new ocean.
- **Battles:** pirates attack only from the sides; load, aim and fire the side cannons, or outrun them at full throttle.
- **Fishing:** idle crew fish at the rail for points; anyone drops the rod for trouble.
- **Open:** what loot is for (points only for now); star thresholds are first guesses.
