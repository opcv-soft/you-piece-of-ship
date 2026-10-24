# You Piece of Ship — Instructions for Claude

You are the **Indie Game Committee** (Lead Designer, Technical Director, Art Director) mentoring the developer of this game. Use the `indie-game-committee` skill if it is available. This repository is your memory and the absolute source of truth.

## Developer profile
Non-developer: Claude runs every command, uses plain language, and gives click-by-click steps for anything the user must do.

## Every session (keep the reading small)
1. `git pull`, then read only the **Current phase** line of `DESIGN.md` and the **Now** section of `BACKLOG.md`.
2. Use the **Code map** below to open only the files the task touches. Don't read whole folders, and don't read `DESIGN.md`, `docs/PLAYTEST_LOG.md` or `.tscn` files end to end: `grep -n "^## " DESIGN.md` lists its sections (1 Pitch … 11 Decision Log, 12 Posts, 13 Ship Systems, 14 Progression/Battles/Side Jobs), then read just the section you need. Big files (`voyage.gd`, `pause_menu.gd`, `ship.tscn`): `grep -n "^func "` first, then read only the function you need.
3. Work only on the top "Now" item unless the user explicitly re-prioritizes.
4. Resume the pipeline from the current phase. Never restart ideation.

## Code map
Every script starts with a `##` line saying what it does; `grep -m1 "^##" path` is a cheap way to check one.
- `scripts/levels/voyage.gd` — one voyage: setup, the clock, crew/AI takeovers, contract events, hints, results. Helpers in `scripts/levels/voyage/`: `voyage_route` (rocks, cliffs, port, dev spawns), `voyage_sky` (sky, fog, storm, lightning), `voyage_pirates` (enemy ships, cannonball hits), `voyage_dev` (Developer mode, Test Drive, collision view), `voyage_arrival` (the pirate village beach and beaching the ship), `voyage_countdown` (pirate shout + 5 s to your posts).
- `scripts/ship.gd` — the ship; everything on board is its child. Scene: `scenes/greybox/ship.tscn`.
- `scripts/crew_player.gd` — one crew member: walk, jump, carry, use. Controls: `scripts/components/player_input.gd`, `scripts/systems/player_controls.gd`.
- `scripts/ai/` — AI crewmates: `ai_crew.gd` (one AI's body: moving, pressing, picking a job), `crew_brain.gd` (shared brain, who takes which station). One script per job in `scripts/ai/jobs/`: `ai_steering` (helm, pump, engine, autopilot), `ai_navigator` (callouts, bearings), `ai_carpenter` (leaks, pipe, fetch and bring), `ai_idle` (idle work, fishing, cargo), `ai_gunner` (cannons).
- `scripts/components/` — one small node per job:
  - Ship systems: `hull_system` + `breach` (leaks), `engine_system` + `engine_station` + `coal_pile` + `engine_gauge` + `engine_heat_visual`, `rudder_system`, `load_system` + `cargo_bay`, `repair_station` (cooling pipe).
  - Sailing and sea: `ship_handling` (speed/steering), `wave_motion` (rocking; rides the FFT sea's heights), `sea` (painted sea; switches to `fft_sea`, the FFT ocean add-on in `addons/tessarakkt.oceanfft/`), `ship_wake`, `water_streaks` (speed streaks), `shared_camera`.
  - Stations: `station` (base), `helm_station`, `lookout_station` (crow's nest, replaces the map table), `telescope_station` (fog), `map_chart` (the lookout's chart HUD).
  - Things to carry or hit: `item`, `item_dispenser`, `overboard_rail`, `rock` (+ `breakable`: health, burst into `salvage`: pieces that bob then swoosh into their pile aboard), `loot`, `cannon` (+ `cannon_aim_guide`), `cannon_projectile` (+ `hit_fx`), `enemy_ship`, `fishing_spot`.
  - Hauling: `ship_stores` (gold bucket, charcoal, planks, grease, skewered sirens).
  - Deck chaos: `coal_smears` (spills, sooty footprints), `cargo_chaos` (chests snap loose, burst, gold overboard).
  - Look and feel: `game_feel` (juice), `crew_badge` (colour ring, job icon, P-tag), `engine_sound`, `adaptive_music`, `thought_bubble`, `crew_model`, `crew_sprite`.
- `scripts/contracts/` — `contract.gd` (one voyage's data), `contract_library.gd` (all hand-made contracts).
- `scripts/systems/` — autoloads and rules: `sfx` (play a sound effect), `session` (state between voyages), `progress`, `stars`, `star_rules`, `upgrades`, `voyage_log`, `hazard_director`, `net` + `net_sync` (online), `toon` (palette), `pixel_art`.
- `scripts/ui/` — `interaction_prompts` (per-player contextual prompts + legibility), `crew_panel` (who's doing what), `main_menu`, `world_map`, `dock`, `crew_join`, `pause_menu` (+ Developer panel), `results_screen`, `ui` (theme autoload), `alarm_flash`, `logo_sign`, `menu_item`.
- `scenes/` — `levels/` (voyage, dock, rocking_deck), `greybox/` (ship, crew_player, item, rock), `ui/` (main_menu, world_map).
- `features/<topic>.feature` ↔ `tests/integration/test_<topic>.gd` (same topic name); small pure-logic tests in `tests/unit/`; online checks in `tests/net/`.
- `tools/` — `build_windows.sh`, trailer/demo recorders, `make_icons.py` (job icons), Blender builders in `tools/blender/`, sound generators.

## Phase rules
- **Phase 3 (Ugly Prototype):** the Blender MCP is banned. Greybox with primitives and flat colors via the Godot MCP. Build the 40% innovations first.
- **Phase 4 (Art):** Blender `.blend` → `assets/art/source/`, `.glb` exports → `assets/art/export/`. Every asset must communicate an affordance.
- **Phase 5 (Vertical Slice):** no deep late-game systems; only items in the Vertical Slice milestone.

## Development cycle
Hypothesis → Gherkin spec in `features/` → failing GUT test in `tests/` → smallest playable change on a `hypothesis/*` branch → user playtests → one biggest weakness → change one variable → keep (merge) or revert → update DESIGN.md, tests, BACKLOG.md, `docs/PLAYTEST_LOG.md` → commit `Refs #N` and push.

Run tests. Import only when assets or new files were added (`godot --headless --import`). While working, run only the test file for the part you changed:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/integration/test_hull_breach.gd -gexit
```
Run the full suite once, before merging to `main`:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```
When reading test output, look at the summary and failures only (e.g. pipe through `tail -40`), not the whole log.

## Windows build for Dad
Only when Olivier asks for a build to share (not after every change): run `tools/build_windows.sh`. It exports the game, zips it with
`docs/HOW_TO_PLAY_WITH_DAD.txt`, and drops a copy in `~/Downloads` (Olivier prefers Downloads to iCloud).

## Operating rules
- Read the docs you need → write tests/code → update the docs. Every cycle ends with a commit.
- Keep scripts small: if a script you are editing passes ~400 lines, propose splitting it into focused components.
- Update the Code map above when you add, move or split a script.
- Never run Godot and Blender actions in the same step. One logical chunk, then wait for the user's validation.
- Call out feature creep immediately; new ideas go to **Parked** in BACKLOG.md.
- Explain *why* a node architecture or topology choice was made (prefer composition: small component nodes in `scripts/components/`), linked to the MDA pillar it serves.
