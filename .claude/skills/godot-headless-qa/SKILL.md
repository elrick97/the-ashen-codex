---
name: godot-headless-qa
description: Exact commands and pitfalls for building, testing, linting and screenshotting The Ashen Codex with Godot 4 from the command line. Use whenever running Godot, tests, the screenshot tour, or writing GDScript.
---

# Godot 4 Headless QA

`$GODOT` is `godot` if it's on PATH, otherwise `./tools_dev/godot.sh`. Wrap long runs in `timeout`.

## Commands
- Import or reimport assets (run after adding files): `timeout 300 $GODOT --headless --path . --import`
  - If `--import` isn't supported, use `$GODOT --headless --path . --editor --quit`.
- Parse-check one script: `$GODOT --headless --path . --check-only --script res://path/file.gd`
- Run all tests (GUT): `timeout 600 $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
- Fallback runner if GUT isn't vendored: `timeout 600 $GODOT --headless --path . --script res://tests/run_all.gd`. It extends `SceneTree`, runs every `test_*` method, prints a summary, and calls `quit(failures)`. The exit code is the failure count.
- Headless boot smoke test: `timeout 60 $GODOT --headless --path . --quit-after 600 2>&1 | tee qa/boot.log`
- Screenshot tour (needs a display: WSLg `$DISPLAY`, or `xvfb-run -a` in front): `timeout 900 $GODOT --path . --rendering-driver opengl3 --resolution 1080x1920 res://tools_dev/screenshot_tour.tscn`. Run it again at `720x1280`.
  - Capture code: `await RenderingServer.frame_post_draw` then `get_viewport().get_texture().get_image().save_png(path)`.
  - Headless mode doesn't render. Never trust screenshots taken with `--headless`.
- Error scan (keep the context small; never dump full logs): `grep -nE "SCRIPT ERROR|ERROR:|WARNING:|Parse Error|Invalid call" qa/*.log | head -50`
- To save context, filter test output to failures and the summary, or delegate long runs to a subagent that reports back only the summary.

## Godot 3 → 4 pitfalls (don't write Godot 3 code)
- `yield` → `await`. `connect("sig", self, "m")` → `sig.connect(m)`. `emit_signal("s")` → `s.emit()`.
- `export var` / `onready var` / `tool` → `@export` / `@onready` / `@tool`. `setget` → property `get:`/`set:` blocks.
- `instance()` → `instantiate()`. `change_scene()` → `change_scene_to_file()`. `update()` → `queue_redraw()`.
- `File` / `Directory` → `FileAccess` / `DirAccess`. `to_json` / `parse_json` → `JSON.stringify` / `JSON.parse_string`.
- `PoolByteArray` etc. → `PackedByteArray` etc. `rand_range` → `randf_range` / `randi_range`. `OS.get_ticks_msec` → `Time.get_ticks_msec`.
- `rect_size` / `rect_position` → `size` / `position`. `.tscn` uses `format=3` with `uid://` references.

## GDScript correctness traps for this project
- **`%` on negative ints keeps the dividend's sign.** Always use `posmod(a, 26)` for cipher shifts.
- `int` is 64-bit signed. For later-act modular math, don't multiply two values ≥ 2^31 directly. Use a mulmod (double-and-add) helper.
- Bytes: `PackedByteArray`. `String.to_utf8_buffer()` / `to_ascii_buffer()`, `PackedByteArray.get_string_from_ascii()`, `hex_encode()`. Bitwise: `^ & | << >>`.
- `String.unicode_at(i)` and `String.chr(code)` convert between characters and codes.
- Type everything: `var x: int`, `Array[int]`, `Dictionary` with documented shape, `-> void`. Keep the untyped-declaration warning on and at zero.
- Keep crypto logic in `RefCounted` classes with `static func`s so it's testable without scenes.
- Resources (`.tres`) for PuzzleDef and ChapterDef: `class_name` + `extends Resource` + `@export` fields.

## Definition of green
The test runner's exit code is 0. The boot log has zero `ERROR`/`SCRIPT ERROR` lines. The screenshot tour produced every expected PNG and nothing is clipped or blank.
