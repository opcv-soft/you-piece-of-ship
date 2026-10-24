# You Piece of Ship

**You Piece of Ship is a 4-player co-op party game where you steer, read charts, stoke the engine and patch the hull of one rickety cargo ship to reach port, but every breakdown changes how the ship handles, so one bad call snowballs into a disaster you can almost save.**

Built with Godot 4.7.2. Design: [DESIGN.md](DESIGN.md) · Backlog: [BACKLOG.md](BACKLOG.md) · Playtests: [docs/PLAYTEST_LOG.md](docs/PLAYTEST_LOG.md)

## How to play
Start the game (in Godot press ▶ or F5). You arrive at **the dock**.

1. **Crew:** each player presses **Use** to come aboard (P1: E, P2: Right Shift, controllers: X).
2. **Contract:** pick one with the arrow keys / D-pad and Enter / A. Start with the **Maiden Voyage**: it teaches everything and can't be lost.
3. **Sail** to the yellow buoys at port before the deadline. **Results** show your score and what went wrong; Enter goes back to the dock, R sails again.
4. **Shop:** spend coins on upgrades. Every upgrade has a catch.

| | P1 | P2 | Controller (1-4) |
|---|---|---|---|
| Move | W A S D (Z Q S D on a French keyboard) | Arrow keys | Left stick |
| Jump | Space | Enter | A |
| Use (pick up, put down, apply, take a station) | E | Right Shift | X |

**Stations** (walk up and press Use; press Use again to leave):

| Station | Where | What you do there |
|---|---|---|
| Helm | stern (back) | left/right steer, up/down throttle (pull below zero to go astern) |
| Map table | bow (front), port side | just stand there: only you see the hidden rocks on the chart |
| Telescope | bow, fog only | marks rocks ahead for everyone |
| Engine | stern, starboard | only you see heat and coal; hold up = shovel coal, Jump = vent steam (knocks bystanders over) |
| Pump | stern, port side | pumps water out |
| Leaks | along the rails | bring a plank (Use), hammer it (2 crew = fast), or stuff a cargo crate in it |
| Cooling pipe | stern, starboard | when it bursts: fix it (2 crew = fast) |
| Spare parts | port side | planks and the rudder pin (bring the pin to the helm when the rudder breaks) |

Big waves warn for 5 seconds: hold on to a station or you fall over and drop what you carry.
Carry a cargo crate to the rail and press Use to throw it overboard (lighter ship, less pay).
M mutes the music. **Online:** one player clicks *Host online game* at the dock; friends type the host's address and click *Join*.

## How to test online
Online play has one **host** and up to three friends. Each computer needs a copy of the game (for now: this project opened in Godot 4.7.2).

**On one Mac (quick check):** in Godot, *Debug → Customize Run Instances…*, tick *Enable Multiple Instances*, set 2, OK, then ▶. In window 1 click **Host online game**; in window 2 click **Join** (the address `127.0.0.1` means "this computer"). The host picks a contract. Click a window to play in it (W A S D, E, Space).

**Two computers on the same Wi-Fi:**
1. Both computers are on the same Wi-Fi network.
2. Host: open the game; the dock shows *This computer: 192.168.x.x* in the online row. Read that address out to your friend. Click **Host online game**.
3. The first time, macOS may ask whether Godot may *accept incoming network connections*: click **Allow**.
4. Friend: type the host's address in the box next to **Join** and click **Join**. They become P2 (then P3, P4) and play with their own keyboard (W A S D, E, Space) or controller.
5. Host: pick a contract. Everyone sails together; the host decides when to restart or go back to the dock.

The game uses port **7777** (UDP). Playing over the internet (not the same Wi-Fi) needs port forwarding on the host's router and is out of scope for now.

## Getting started
1. Install [Godot 4.7.2](https://godotengine.org/download) and [Git LFS](https://git-lfs.com) (`git lfs install`).
2. Clone the repo and open `project.godot` in Godot.

## Running tests
Tests use [GUT](https://github.com/bitwes/Gut). BDD specs live in `features/`, tests in `tests/`.
```bash
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```
CI runs the same suite on every push and pull request. Online play is checked separately with two game processes: see [tests/net/README.md](tests/net/README.md).

## Workflow
Hypothesis → spec → test → greybox → playtest → keep or revert → update docs. See [CLAUDE.md](CLAUDE.md).

## Languages
English and French. The game follows the computer's language; switch it any time in **Settings**. Translations live in `translations/strings.csv`, generated from `tools/translations_fr.py` (the English text is the key; the title is never translated).

## Credits
- Realistic ocean: [godot4-oceanfft](https://github.com/tessarakkt/godot4-oceanfft) by Tessa Avery (MIT), in `addons/tessarakkt.oceanfft/`. Switch it off in Settings → "Realistic sea" to get the painted sea back.
- Sound effects: original, synthesised by `tools/make_sfx.py` (no third-party samples).
