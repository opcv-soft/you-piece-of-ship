# You Piece of Ship — Backlog

> Agile, not a roadmap. Only "Now" is committed. Re-prioritize after every development cycle.
> Tags: `[innovation]` 40% hooks · `[standard]` genre conventions · `[tech]` infrastructure
> Milestones: **Ugly Prototype** (Milestone A, DESIGN.md §9) then **Vertical Slice** (Milestone B)

## Now (committed, top = highest priority) — Milestone A

## Next (likely, not committed)

## Later (deliberately vague)
- Generated HD art for the menu background, logo and icons (replace the mockup crop); ship sound effects; more pixel-art dressing
- Enemy AI ships to sink, with cannons (Olivier, 2026-10-22: "eventually there shall be enemy AI ships to sink and we'd have cannons")

## Parked (good ideas that are out of scope until the core loop is proven)
- Fire, crew overboard, floating cargo recovery
- 2-player mode, split screen, mixed couch-plus-online groups
- Secret objectives, many classes, crafting, campaign, permadeath, cosmetics

## Done
- 2026-10-24 (evening) Speed streaks (water_streaks.gd, Olivier's spec): a pool of 48 soft streaks in one MultiMesh, fixed on the water so they flow past opposite to the ship's measured velocity; fade in and stretch with speed (smoothed), align with travel (turns and astern correct), recycled ahead when out of view, nothing under a still ship. Profiled: 0.02 ms per frame, no FPS change. Developer → Tune → Speed streaks.
- 2026-10-24 (evening) Cannons and pirates: cannonballs hit anything they pass over (no height); hits play hit_fx.gd (flash, debris, confetti, squash, camera jolt, tiny hit-stop); pirate ships carry 4 little bad-guy sailors (black tricorns, red bandanas, eyepatches) who hop and fall over when hit; pirates keep pace with you (95% of your top speed: only flat-out sailing escapes); ramming works both ways and pirates hurt themselves on rocks.
- 2026-10-24 (evening) Readability: deck #B8895B; permanent station labels replaced by per-player contextual prompts (interaction_prompts.gd: name, state, what Use does, on a dark backing; alerts like "OVERHEAT!" still show); dark translucent backing behind HUD text, 75% by default (Developer → Tune → Legibility); sailors fade while working a station; cannons aligned (x -0.8 and 2.6 on both sides); plank and pin boxes moved to the foredeck; camera locked at 40° (Developer → Tune → Camera), no pull-back for battles; 5-second countdown with ticks before each run (voyage_countdown.gd).
- 2026-10-24 Block G: port = a sandy beach with a ramshackle pirate village (huts on stilts with patched roofs, palms, rowboats, crates, campfire, Jolly Roger, cheering villagers); no finish line: when the bow meets the sand the ship glides to a stop over 3 s, rides up bow-first and settles with a jolt, then the results show (voyage_arrival.gd). Developer "Sail to the beach" to watch it.
- 2026-10-24 Blocks D+E (deck chaos): coal spills leave streaky skid-mark smears; crew who walk through get sooty boots and leave fading footprints (coal_smears.gd); the coal shovel is carried big in both arms with a heap that shrinks as it spills; waves and cannonball hits spill coal too. Lashed chests sway in their ropes; hard lurches snap ropes (chests slide with momentum) and burst loose chests open, spilling half their gold as loose piles; gold still counts while aboard, washes overboard from the edges on the next big lurch or while the deck is flooded, and can be carried back into a chest (cargo_chaos.gd). Siren drag fades near her rock and lets go after a bump (ships no longer get pinned).
- 2026-10-24 Block F: breakable obstacles (scripts/components/breakable.gd): rocks (3 hits), wrecks (4), the siren (3) and new floating barrels (1) break under cannonballs or hard rams (40%+ of top speed) and burst into floating loot; whales, cliffs and atolls never break; barrels sit along every route as cannon targets and just burst if rammed (no bounce, no damage); the siren now drags the whole ship toward her (up to 2.4 m/s) as well as pulling the wheel; wider speech bubbles.
- 2026-10-24 Block H: realistic FFT ocean (tessarakkt/godot4-oceanfft, MIT; 128x128 FFT, 512 m patch, small LOD tree; ~65 fps on Olivier's MacBook at 5K), tuned brighter for the high camera with whitecaps and glints; the ship rides its real wave heights; storms raise the wind; Settings → "Realistic sea" switches back to the painted sea (automatic where compute shaders aren't available).
- 2026-10-24 Block C: map table replaced by the crow's nest (rope ladder at the mast; Use climbs in 1.5 s, spyglass in hand; chart and callouts only once up; Use again drops back down); fishing reels the catch up the line and over the rail, and fish stay flopping on deck as items; a crash, big wave or cannonball hit lurches the ship: carried cannonballs are dropped, loose things keep moving, rolling cannonballs bowl sailors over. Reef Run deadline 5:30 → 6:15 (AI crew now delivers).
- 2026-10-24 Block B: impacts scale with speed (shake, debris, hit-stop, bounce; under 25% of top speed no damage); collision uses the painted hull's real outline (pointed bow) and obstacle models match their collision circles; Developer "Show collision shapes"; reef rocks appear as soon as they're on screen; speed-scaled wake (stern V, propeller wash, bow spray, three steps); helm shows knots; callouts in sailor's terms ("Rock, 6 fathoms, off the starboard bow!"); sail higher, shorter and more see-through.
- 2026-10-24 Block A: results card restyled (parchment in a wood frame, two columns, real buttons, fits any window); dock simplified (jobs, hats, shop and contract list hidden behind SHOW_ADVANCED in dock.gd); in-world labels 1.7x bigger; no lamps or glowing windows; camera min distance 30, reserve right 0.1; Developer → Tune → "Test Drive" (open ocean, no obstacles, no port).
- Block 6 (2026-10-22 evening): Overcooked-style progression — World Map (main menu + dock + after every voyage) with 3 oceans x 3 routes (Calm Cove: Maiden Voyage, Coral Hop, Reef Run; Whale Waters: Siren Strait, The Narrows, Whale Road; Pirate Sea: Fog Bank, Smugglers' Run, Kraken's Gate); stars open routes (0/1/3, 5/7/9, 12/14/17); a "NEW OCEAN" card says what's new; new trouble: shifting cargo, engine failure, flooding bow, storm (rain, lightning, slate sea), a sail-less smuggler's ship; hats unlock with stars (captain 6, crown 15) and are picked per player at the dock; old saves get one star per delivered contract. Version 0.4.0.
- Block 5 (2026-10-22 evening): sea battles — pirate ships come alongside on one side and fire a broadside when level with you (1 ball, half land on deck and crack the hull); two cannons a side plus a cannonball rack mid-deck; load (Use with a ball), aim (stick), fire (Jump); 3 hits sink them and leave 3 floating loot barrels (60 points each) to sail through; they're slower than full throttle and give up when left 45 m behind or after 75 s; AI "gunner" job (and the AI helm goes full speed to escape); camera pulls back to show the fight; Developer spawn buttons. Reef Run has pirates at 430 m.
- Block 4 (2026-10-22 evening): fishing — two spots on the starboard rail; Use casts, Jump strikes when the float dips (sardine 20, goldfish 50, squid 40, pufferfish 35, rare treasure 150); points go into the score ("Fish & loot" in the timer pill, bonus line on the results); AI carpenters fish only when nothing needs doing and reel in for any trouble. The Narrows widened to 28 m (the painted ship is longer).
- Block 3 (2026-10-22 evening): three stars per voyage from the score (1 = delivered, 2 and 3 = good and great scores; thresholds per contract or worked out from the pay; tunable live in Developer → Tune → Stars); stars pop in one by one on the results; best stars saved and shown on the dock.
- Block 2 (2026-10-22 evening): painted-kawaii look — a real ship (curved hull, pointed bow, raised bow and stern decks with a cabin, mast with sail and crow's nest, bowsprit and jib, fish figurehead, gunports), chubby 3D crew with faces and per-player hats, treasure chests, a hand pump whose lever rocks and gushes water over the side, painted props for every station, Gerstner-wave sea with foam around everything, sun glints and swells for big waves, pastel sky; new obstacles (wreck, whale that swims and dives, siren whose song pulls the wheel, atoll) with chart icons and navigator call-outs; camera looks 14 m ahead of the bow; HUD timer pill. Pixel art kept as a switch (Ship art_style).
- Block 1 (2026-10-22 evening): Esc pause menu + Developer panel (live sliders for every tunable, forced events, time scale, presets in user://dev_presets.json); music simplified to the same tune climbing in pitch (0/+2/+4/+7/+12 semitones) as stability drops, band captions removed; comic thought/shout bubbles above crew (AI plans, navigator callouts, "Whoa!"); all 4 crew AI by default, humans take an AI's place at the dock, online, or mid-voyage by pressing Jump/Use; engine heat visible to all (glowing firebox, flickering light, dial, smoke, shimmer, rattle)
- Windows build (zip with EN/FR "How to play with Dad" guide) via export_presets.cfg; Mac build waits for the Mac export template (2026-10-22)
- Internet host check (UPnP, public address, CGNAT detection) with plain EN/FR messages and Copy button (2026-10-22)
- French version with a language switch (2026-10-22)
- HD cartoon main menu, interface theme and juice pass, maximized window (2026-10-22)
- Adaptive music with band captions (2026-10-22, built, not yet player-tested; generated by tools/make_adaptive_music.py)
- Coal pile and shovel, spills and coal marks, wet coal, sail minimum speed, smarter AI with no idling, personal bests (2026-10-22, built, not yet player-tested)
- Pixel-art pass with Olivier's sprite sheet and ship tile set (2026-10-22; asset source and licence to confirm)
- AI crewmates with jobs and backup jobs, set at the dock; navigator callouts; humans take priority (2026-10-22, built, not yet player-tested)
- #14 Online multiplayer, host-authoritative, lobby on the dock (2026-10-22, built and checked on one Mac over localhost; not yet tested between two computers)
- #13 Dock: contract choice, upgrade shop with four trade-off upgrades, saved progress, voyage-to-voyage loop (2026-10-22, built, not yet player-tested)
- #12 Fog and the bow telescope (2026-10-22, built, not yet player-tested)
- #11 Four hand-made contracts with the Maiden voyage tutorial (2026-10-22, built, not yet player-tested)
- #10 Results screen with event recap, quick restart, crew join, 3-player auto pump (2026-10-22, built, not yet player-tested)
- #8 Hazard director and fairness rules: wave timing with calm windows, two-failure cap, all failures warn 5 s, sinking grace (2026-10-22, built, not yet player-tested)
- #9 One 5-minute route (Reef Run): contract-built rocks, cliffs, port and dock, deadline clock, chart port arrow (2026-10-22, built, not yet player-tested)
- #7 Load and balance: cargo heel and trim, fraying ropes before waves, loose crates, cargo overboard (2026-10-22, built, not yet player-tested)
- Two-player tasks: plank patch and cooling pipe (fast with 2 crew, slow alone) — built with #3 and #4
- #6 Rudder damage and the rudder pin swap (2026-10-22, built, not yet player-tested)
- #4 Engine heat caps speed: engine room with coal and heat gauge, speed cap, warning then stall, vent knockdown, burst cooling pipe two-player fix, flooded ship heats faster (2026-10-22, built, not yet player-tested)
- #3 Hull breach changes handling: leaks with warning, crate plug, plank patch (1-2 crew), pump, water slows/sinks/lists the ship, sinking grace (2026-10-22, built, not yet player-tested)
- #5 Carry and drop: planks, rudder pins, cargo crates; knockdowns drop items; items slide to the low side; big waves (2026-10-22, built, not yet player-tested)
- Background music (placeholder sea shanty loop, M to mute): requested twice by Olivier, added early on 2026-10-22; final music still Phase 4
- #2 Station-bound information: helm, heading-up map table chart, hidden reef run to port (2026-10-22)
- #1 Walk on a rocking ship, together: grey ship on scripted waves, four couch players, shared camera (2026-10-22)
- Phase 1: Committee Summary approved (2026-10-22)

## Questions for Olivier
- Fog Bank is now marginal for the AI test crew (the deck chaos costs it time); tune its deadline after you've played it?
- After the Block B collision change the AI crew finishes Reef Run ~20 s late (348 s vs 330 s deadline) and still sometimes loses The Narrows. Tune the deadline, or the AI's steering margins?
- Star thresholds for routes and hats are first guesses: too stingy or too generous after a few evenings of play?
- The Narrows still sometimes beats a crew of 3 AIs plus an idle human (the navigator is needed all the time, so nobody repairs). Fine as the hard one, or ease it?
- Loot from sunk pirates currently just adds points (so coins). What should loot be for? Ideas: buy cosmetics, rare ship parts, a "treasure" star, crew outfits.
- Lashing the wheel (design's emergency measure for the rudder) is not built: the throttle already changes the turn rate, and the pull continues with nobody at the wheel. Is that enough, or do you want an explicit 'lash the wheel' action?
- The Reef Run deadline (5:30) was calibrated with a simulated crew. After the first real playtest: too tight, too loose?
- Simulated crews (perfect navigator, venting engineer, pumper, but nobody repairing) finished the Maiden Voyage in 4:05, the Reef Run in 4:53 and the Fog Bank in 5:42, and sank in The Narrows near the end. Is The Narrows the right kind of hard once real crews repair things?
- Online play has only been checked on one Mac (localhost). The first test between two computers on your Wi-Fi may need macOS to allow incoming connections for Godot. Do you want to try it with a friend?
- Online clients don't earn coins in their own save; the host's save holds the crew's progress. OK?
- Where do the two pixel-art sheets come from (website or artist), and under what licence? Needed for credits before any public release.
