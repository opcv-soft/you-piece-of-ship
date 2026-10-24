# Playtest Log

One entry per hypothesis. Newest first.

## 2026-10-22 — Adaptive music
Hypothesis: If the same shanty sounds more and more like a band having a breakdown as the ship falls apart, then players feel the danger before reading it and laugh at the band, increasing Comedy and Thrill of danger.
Variable: stability thresholds 20/40/60/80, hysteresis 5
Sessions: 0 — not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main

## 2026-10-22 — Second solo session feedback (Olivier)
Observed: "Great!". AIs sometimes stand around doing nothing. Wants the engineer to have real work (coal pile, shovel, spills, wet coal), a sail for minimum speed, personal bests, adaptive music, HD cartoon UI and main menu, a French version, and online play with his dad abroad.
Decision: gameplay changes built first (coal, sail, AI, bests). Simulated crews (1 idle human + 3 AIs): Maiden Voyage 4:46, Reef Run 5:24 (deadline 5:30), Fog Bank 5:43; The Narrows still beats them.

## 2026-10-22 — AI crewmates
Hypothesis: If empty slots can be AI crewmates with a job and a backup job, then a solo player can finish voyages and still feel part of a crew (the navigator shouts callouts), increasing Social interaction even with fewer humans.
Variable: AI on/off per slot
Sessions: 0 humans yet. Simulated: one idle human + 3 AIs delivered Maiden Voyage, Reef Run and Fog Bank without hitting a rock; The Narrows still beats them.
Observed: pending
Biggest weakness: pending
Decision: merged to main

## 2026-10-22 — First solo playtest of the full game (Olivier)
Sessions: 1 (self: 1, others: 0), Maiden Voyage, alone
Observed: "extremely fun concept". Ran out of coal in the first round and couldn't finish the Maiden Voyage alone (one person can't steer and shovel). Leak patching "feels good" (two players faster). Shop prices: not the time to balance.
Biggest weakness: a single player can't run the ship.
Decision: make coal obvious and plentiful; add AI crewmates with primary and secondary jobs; keep leak patching as is; defer price balancing.

## 2026-10-22 — Online multiplayer  (#14)
Hypothesis: If remote friends can join a crew with an address and their own keyboard, then groups that can't share a couch still get the callout chaos, increasing Social interaction.
Variable: snapshot rate 20 per second
Sessions: 0 players; technical check on one Mac over localhost passed (tests/net/)
Observed: pending
Biggest weakness: pending (latency between real computers untested)
Decision: merged to main; couch play unchanged

## 2026-10-22 — Dock and upgrade shop  (#13)
Hypothesis: If every upgrade has a visible catch, then crews will argue at the dock about what to buy and the next voyage will feel different, increasing Social interaction without reducing Comedy.
Variable: prices 300-500 coins
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main

## 2026-10-22 — Contracts, tutorial, fog and telescope  (#11, #12)
Hypothesis: If the first contract teaches each system by doing and the last one blinds the chart, then new crews learn without a manual and the fog run forces a new split of roles, increasing Social interaction.
Variable: fog chart range 30 m; telescope range 90 m
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main

## 2026-10-22 — Results and recap  (#10)
Hypothesis: If the results screen replays the chain of accidents with timestamps, then players will laugh about who caused what and immediately press R, increasing Comedy and replay desire.
Variable: recap length 12 lines
Sessions: 0 — built overnight, not yet player-tested. A simulated crew (autopilot navigator, venting engineer, pumper) completed the Reef Run in 4:53 with no rock hits.
Observed: pending
Biggest weakness: pending
Decision: merged to main

## 2026-10-22 — Hazard director  (#8)
Hypothesis: If a big wave never lands while two systems are already failing or right after a recovery, then players will blame their own choices rather than the game, increasing Thrill of danger (fair near-saves).
Variable: calm window 20 s; max failing systems 1
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; survey question 'did you understand why things went wrong?' checks it

## 2026-10-22 — The Reef Run route  (#9)
Hypothesis: If one voyage paces calm, complication, calm, overlap and a peak in the last third, then the crew will feel a rising arc and cheer at port, increasing Thrill of danger.
Variable: route length 1300 m, deadline 5:30
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune deadline and rock density after the first couch playtest

## 2026-10-22 — Load and balance  (#7)
Hypothesis: If loose cargo tilts the deck and can be thrown overboard to save the ship, then the crew will argue about sacrificing cargo, increasing Social interaction and Comedy.
Variable: heel per crate-metre 1.2 degrees
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Rudder damage  (#6)
Hypothesis: If a hard hit makes the wheel pull to one side until someone hauls the heavy pin to the helm, then the captain will call for help and the slow pin-carrier will be the centre of attention, increasing Comedy and Thrill of danger.
Variable: pull strength 0.35 of full wheel
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Engine heat caps speed  (#4)
Hypothesis: If full throttle overheats the engine and only the engineer can see the gauge, then the engineer will shout "slow down!" while the navigator wants speed, increasing Social interaction.
Variable: heat rise (full throttle reaches 80% in about 18 s, 100% in about 22 s)
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Hull breach changes handling  (#3)
Hypothesis: If a rock hit cracks the hull and water visibly slows and tilts the ship, then the crew will split up (someone pumps, two patch, the captain slows down) and argue about priorities, increasing Social interaction and Thrill of danger.
Variable: flow rate (1 open leak fills the ship in 70 s)
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main; tune after the first couch playtest

## 2026-10-22 — Carry and drop  (#5)
Hypothesis: If carried items drop when a wave knocks you over and then slide to the low side, then crew will chase runaway planks and yell "grab a station!" before waves, increasing Comedy.
Variable: knockdown on big waves (on/off); wave roll 14 degrees
Sessions: 0 — built overnight, not yet player-tested
Observed: pending
Biggest weakness: pending
Decision: merged to main so later systems can build on it; keep or change after the first couch playtest

## 2026-10-22 — Background music (requested by Olivier)
Hypothesis: If a lively shanty loops in the background, ducks on crashes and speeds up near port, then the crew will feel the mood (frantic, goofy) and the run's tension, increasing Comedy and Thrill of danger. Risk: music makes any build feel better, so it can hide whether the mechanics are fun; mute (M) during fun-gate tests.
Variable: music on/off (M key or Music node "music_enabled")
Sessions: 1 (self: 1, others: 0)
Observed: Olivier: "everything is excellent."
Biggest weakness: none reported.
Decision: KEPT.

## 2026-10-22 — Juice pass on existing moments (requested by Olivier)
Hypotheses (one per effect; each has its own switch on the GameFeel node, so each is kept or removed on its own):
- Crash (shake + 80 ms freeze + debris/spray + "CRASH!" pop): if a crash is felt, then the crew will groan and blame each other, increasing Comedy.
- Wake foam at bow and stern: if speed shows on the water, then the captain will feel the speed without reading the HUD, increasing Thrill of danger.
- Squash and stretch on jump/land: if jumps have weight, then players will hop around more, increasing Comedy.
- Port confetti: if arriving is celebrated, then the crew will cheer, increasing Thrill of danger (the release).
Variable: each effect on/off
Sessions: 1 (self: 1, others: 0)
Observed: Olivier: "everything is excellent." No readability problems reported.
Biggest weakness: none reported.
Decision: KEPT, all four effects.

## 2026-10-22 — Station-bound information  (#2)
Hypothesis: If submerged rocks are shown only on a map table at the bow while the wheel is at the stern, then the navigator will shout directions and the captain will steer by their calls, increasing Social interaction.
Variable: chart visible only while someone stands at the map table (on/off)
Sessions: 1 (self: 1, others: 0)
Observed: The navigator could warn the captain in time; steering by the ship's own left/right was "fine"; difficulty (12 rocks, ~1 min run) "fine".
Biggest weakness: none reported for the mechanic; Olivier asked for a higher resolution and more game feel (juice), handled as the next step.
Decision: KEPT. Not yet tested with a second person, which is the real test of the callout loop.

## 2026-10-22 — Walk on a rocking ship, together  (#1)
Hypothesis: If four players share one deck that rolls ±8° on a slow swell, then they will stumble into each other and laugh while still feeling in control of where they go, increasing Comedy and Social interaction.
Variable: wave roll amplitude (starting value 8°)
Sessions: 1 (self: 1, others: 0)
Observed: Rocking strength "ok"; each player always knows which capsule is theirs and where it faces; bumping into each other and the mast is "fine" (neutral, not yet funny).
Biggest weakness: there is nothing to do on deck yet. Expected at this step: posts and tasks arrive with #2 (map table), #3 (hull breach), #4 (engine heat), #5 (carry and drop).
Decision: KEPT, roll stays at 8°. The deck works as a foundation; nothing to tune until there is a job to do on it.

<!--
## YYYY-MM-DD — <hypothesis name>  (#issue)
Hypothesis: If ..., then ..., increasing <form of fun>.
Variable: <name> <old> → <new>
Sessions: <n> (self: x, others: y)
Observed:
Biggest weakness:
Decision: KEPT / REVERTED — why
-->

## 2026-10-22 evening — Olivier's feedback batch
- Music: "the music thing could be as simple as going up an octave" → band layers and captions removed; the tune now climbs in pitch with trouble.
- "The dialogue does not really make sense (the accordionist?)" → replaced by thought bubbles above the crew that say what they are doing and what they see.
- Wants: dev mode on Esc, AI by default, visible engine heat, painted kawaii ship that reads as a ship, rich sea, varied obstacles, chests, a real pump, 3 stars, fishing, sea battles, Overcooked-style progression.

## 2026-10-24 — Olivier's playtest notes (core gameplay focus)
- Cargo should waltz around and chests burst on big hits; SUNK! screen ugly and off-screen; dock too busy (remove jobs/hats/upgrades for now).
- Acceleration not obvious (wants a wake); obstacles should appear when in view, not only after hitting them; sail blocks the deck; labels too small.
- Fishing: Use to cast, Jump to strike, reel the fish onto the deck where it stays. Sea looks "Nintendo 64": try an FFT ocean.
- Port: a beach with a ramshackle pirate village, the ship softly beaches itself. Speed in knots for the helm; callouts in nautical units.
- Lookout up the mast with a spyglass instead of the map table. Siren should pull the ship; everything should be shootable or rammable for loot.
- Test Drive mode; camera min distance 30, reserve right 0.1; impacts should scale with speed; collision should match the visuals.
- Dropped cannonballs roll and knock crew over; a big shovel whose coal spills into smears that crew track around; 1700s only (no lamps).

## 2026-10-24 night — Olivier's tweak batch
- Backing opacity 0.3; pins and planks on the foredeck; pirate voice "AT YOURRRR STATIONS!" for the countdown.
- "The mast is in the way, it hides what is behind" → rigging see-through; cannons moved forward of the mast.
- Smashed things should break into pieces that float, then get swooshed into the right pile on the boat.
- "The waves do not appear AT ALL. You can remove the whole wave mechanic for now" → big waves off behind a flag.
- Fishing succeeds too often → rarer, more random, dev sliders.

## 2026-10-24 late — Olivier
- "i only get the loot when i hit the floating barrels, i want to get the loot when i hit everything" → every hit chips salvage aboard.
- "i want a aim thing that shows me where the cannon trajectory is" → aim guide.
- "It's hard to read, hard to understand what the other AI are doing" → Claude playtested Maiden Voyage and Reef Run; review sent, top-5 readability changes awaiting Olivier's pick.
