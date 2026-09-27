# The Ashen Codex

A grimdark, M-rated narrative codebreaking game for mobile portrait, built in **Godot 4.7.2-stable** (`4.7.2.stable.official.ed1daf0bf`), GDScript with static typing, Compatibility renderer.

You are Isaak Varr, a pale-blood cipher-hunter chained beneath the Undying Court's library, confessing to the Marquise Ottilie Dray how the Order of the Silent Quill broke her kind's letters. **Act I, "The Tithe Letters"** is complete: 12 puzzles from Caesar to a two-time-pad boss, all with real ciphers generated at load time, real attacks, and a reference solver per puzzle.

*Everything eternal repeats.*

## Run

```bash
./tools_dev/godot.sh --path .
```
`tools_dev/godot.sh` wraps the vendored binary in `.tools/godot/` (download it as described in `docs/ENVIRONMENT.md`, or point `GODOT` at any Godot 4.7 binary). First run on a fresh clone: import once so translations are generated:
```bash
./tools_dev/godot.sh --headless --path . --import
```

## Test (one command)

```bash
./tools_dev/run_tests.sh
```
Imports, then runs every GUT test headless (unit, integration, solvers). Exit code 0 means green. `./tools_dev/run_tests.sh unit` runs one folder.

Other checks:
- `python3 tools_dev/lint.py`: Godot's own GDScript analyzer through its language server; must report 0 diagnostics (untyped declarations are warnings).
- `python3 tools_dev/build_strings.py`: merges `content/i18n/src/*.csv` into `content/i18n/strings.csv`; checks missing keys, ASCII, banned names, line budgets and dialogue structure.
- `python3 tools_dev/check_letters.py`: technique constraints for every letter.
- Screenshot tour (needs a display): `./tools_dev/godot.sh --path . --rendering-driver opengl3 --resolution 1080x1920 res://tools_dev/screenshot_tour.tscn` (also `720x1280`, and `-- notch` to simulate a notch). PNGs land in `qa/screenshots/<W>x<H>/`.

## Export

Presets for Android, iOS, Linux, Windows Desktop and Web are in `export_presets.cfg`. With the 4.7.2 export templates installed:
```bash
./tools_dev/godot.sh --headless --path . --export-release "Linux" build/linux/ashen_codex.x86_64
./tools_dev/godot.sh --headless --path . --export-release "Web" build/web/index.html
./build/linux/ashen_codex.x86_64 --headless -- --selftest
```
Android needs Java + Android SDK paths in Editor Settings; iOS needs an Apple Team ID and macOS (see `docs/BLOCKERS.md`).

## Controls

Touch first; the mouse works the same way (a click is a tap).
- **Cipher Wheel / Key Dial:** drag around the ring to turn it (inertia, detents). Tap Shift/Mirror for scheme modes.
- **Multi-Wheel:** drag each drum up or down.
- **Substitution Board:** drag a red cipher tile onto a plaintext slot, or tap a tile then a slot. Hold a filled slot to lock it (hold again to unlock). Drag a tile back to the tray to clear it.
- **Tally Scroll:** tap a bar to pick a cipher letter; on costed puzzles, "Read as E/T/A/O" jumps the wheel for one trial.
- **Kasiski Lens:** hold a letter on the page to measure repeats.
- **Column Loom:** slide N; watch the blood-purity (IoC) vial.
- **Bit Rosary:** tap beads to flip bits; pour the chalice.
- **Hamming Comb:** tap the shortest tooth.
- **Crib Dragger:** tap a crib (or write one), drag it along the stream, pin it to letter A or B.
- **Undo** (50 steps), **Ask Kett** (hints cost Thirst), **Seal the reading** (commit). Codex bookmark on every puzzle; reading it is free.
- Settings: text size (3 steps), Clear Mind (removes every distortion effect), haptics, volumes, hint confirmation, reset progress (double confirm).

## Project map

```
core/crypto/          pure cipher and analysis code (RefCounted, static funcs), fully unit-tested
core/crypto/analysis/ frequency, Kasiski, IoC, Hamming, English scoring, cribs
core/game/            autoloads (EventBus, Thirst, Save, Settings, Audio), progression, hints,
                      codex, content DB, puzzle factory, dialogue runner, resource classes
core/puzzle_modes/    one controller per puzzle mode (wires tools to the crypto core)
content/              puzzles/*.tres, chapters/*.tres, codex/*.tres, dialogue/*.json,
                      i18n/src/*.csv -> i18n/strings.csv, thirst_config.tres
tools/<tool>/         the ten tactile tools (dumb views)
ui/                   theme, shaders (parchment, ink wipe, Thirst overlay), components, codex widgets
scenes/               main (screen stack, overlays), boot, title, dialogue, puzzle_host, folio,
                      summary, codex, settings, credits, card, dev/tool_sandbox
audio/generated/      WAVs from tools_dev/synth_sfx.py
tests/                unit/, integration/, solvers/ (reference solvers + crib-drag solver)
tools_dev/            godot.sh, run_tests.sh, lint.py, build_strings.py, check_letters.py,
                      gen_content_defs.py, build_ngrams.py, synth_sfx.py, screenshot_tour, snap, contact_sheet
docs/                 GDD, CURRICULUM, ACT1_SCRIPT, TECH_DESIGN, DECISIONS, BLOCKERS, ENVIRONMENT,
                      ASSET_MANIFEST, CRYPTO_AUDIT, PLAYTEST_REPORT, NEXT_STEPS, playtest/
```

## Licences
Code: this project. Fonts: SIL OFL 1.1 (`licenses/OFL-*.txt`). GUT: MIT (`licenses/GUT_LICENSE.md`). Godot: MIT. N-gram and word statistics derived from public-domain Project Gutenberg texts.
