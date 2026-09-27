# Technical Design

Godot 4.7.2, GDScript with static typing, Compatibility renderer, portrait 1080x1920 (`canvas_items`, `expand`).

## 1. Layout
```
res://
  core/crypto/            pure logic, RefCounted + static funcs, no Nodes
    text_util.gd caesar.gd substitution.gd vigenere.gd xor_ops.gd bytes_util.gd rng.gd
    analysis/ frequency.gd kasiski.gd index_of_coincidence.gd hamming.gd english_score.gd crib.gd
    modmath.gd (implemented)  block_cipher.gd modes.gd hash_toy.gd bigint.gd (stubs/interfaces)
  core/game/
    event_bus.gd thirst.gd save_service.gd settings_service.gd audio_service.gd   (autoloads)
    game_context.gd progression.gd codex_service.gd hint_service.gd content_db.gd
    puzzle_def.gd chapter_def.gd codex_entry_def.gd thirst_config.gd  (Resource classes)
    puzzle_factory.gd  (PuzzleDef + seed -> PuzzleInstance: plaintexts, key, ciphertext)
    dialogue_runner.gd (pure state machine over dialogue JSON)
  core/puzzle_modes/      one controller per mode (wires tools to the crypto core, judges commits)
  content/ chapters/ puzzles/ codex/ dialogue/ i18n/strings.csv  i18n/src/*.csv (.gdignore)
           data/english_ngrams.json  thirst_config.tres
  tools/<tool>/<tool>.tscn + .gd   ten tactile tools
  ui/theme/ ui/shaders/ ui/components/
  scenes/ main.tscn boot/ title/ vault/ memory/ puzzle_host/ folio/ codex/ settings/ credits/ summary/ ending/ dev/
  audio/generated/*.wav
  tests/unit/ tests/integration/ tests/solvers/
  tools_dev/ godot.sh run_tests.sh build_strings.py synth_sfx.py screenshot_tour.tscn lint.sh
```

## 2. Autoloads (only these)
| Name | Script | Role |
|---|---|---|
| EventBus | core/game/event_bus.gd | global signals (thirst_changed, threshold_crossed, frenzy, settings_changed, codex_unlocked, toast) |
| Thirst | core/game/thirst.gd | value 0..100, `spend(amount, reason) -> void`, `restore(amount)`, thresholds, frenzy detection; reads `content/thirst_config.tres` |
| Save | core/game/save_service.gd | versioned JSON save, migration, atomic write, backup fallback |
| Settings | core/game/settings_service.gd | settings JSON, applies text size, volumes, clear-mind, haptics |
| Audio | core/game/audio_service.gd | buses, SFX pool, ambience loops, heartbeat layers, ducking |

Everything else (Progression, CodexService, HintService, ContentDB) lives in `GameContext`, created by `scenes/main.gd` and passed to every screen via `setup(ctx: GameContext)`.

## 3. Screens and flow
`scenes/main.tscn` holds `ScreenRoot` (current screen), `ThirstOverlay` (CanvasLayer: vignette, ink-bleed, desaturation, blood drips; all off in Clear Mind), `TransitionLayer` (ink-bleed wipe shader). `Main.goto(screen_id, args)` swaps screens behind the wipe.

Flow: `boot` (M-rated warning) -> `title` -> New Game/Continue -> `Progression` walks the current ChapterDef's `steps`:
- `{"type":"dialogue","id":"..."}` -> `vault` or `memory` screen (chosen by the dialogue's `location`)
- `{"type":"puzzle","id":"a1_p01"}` -> `puzzle_host`, then `folio` automatically
- `{"type":"summary"}` -> sub-chapter summary (grades so far)
- `{"type":"act_folio"}` -> act folio with all grades, then `{"type":"card","text":"CARD_A1_END"}` -> ending card -> title
When a chapter's steps run out, Progression moves to `next_chapter`.

## 4. Data schemas

### PuzzleDef (`content/puzzles/a1_pNN.tres`, class `PuzzleDef extends Resource`)
| Field | Type | Meaning |
|---|---|---|
| id | String | `a1_p01` ... |
| chapter_id | String | `a1_i`, `a1_ii`, `a1_iii` |
| number | int | 1..12 |
| title_key, brief_key | String | CSV keys: puzzle title, one-line task shown on the card |
| mode | String | `caesar`, `keyless`, `substitution`, `vigenere`, `xor_rosary`, `xor_repeating`, `two_time_pad` |
| tools | PackedStringArray | tool ids shown in the host (see section 6) |
| plaintext_keys | PackedStringArray | CSV keys of the letter(s) |
| sender_keys | PackedStringArray | CSV keys of the "From X to Y" line per letter |
| normalization | String | `upper_keep` (uppercase; spaces, punctuation, newlines kept; only A-Z enciphered), `letters_only` (A-Z only, shown in groups of five), `ascii` (bytes as written), `upper_ascii` (uppercased ASCII bytes) |
| key_rule | Dictionary | see below |
| base_seed | int | variant 0 seed; variant v uses `base_seed + 7919 * v` |
| params | Dictionary | mode-specific, see section 5 |
| brute_force_costed | bool | trials cost Thirst |
| trial_cost | int | Thirst per trial when costed (1..3; mode may define what a trial is) |
| hint_keys | PackedStringArray | exactly 3 keys: nudge, concept, near-answer |
| codex_unlocks | PackedStringArray | codex entry ids unlocked on solve |
| frenzy_dialogue | String | dialogue id played at Frenzy |
| frenzy_overrides | Dictionary | merged over `params` (and `trial_cost`) for variants after a frenzy |
| anti_cheese | String | dev note: why the free preview does not solve it (not player-facing, not translated) |

`key_rule` types: `{"type":"shift","min":3,"max":23}`, `{"type":"scheme_mix","schemes":["rot13","atbash"]}`, `{"type":"perm"}` (random derangement), `{"type":"word","pool":["ASHEN",...]}`, `{"type":"byte","min":65,"max":250,"exclude":[96]}`, `{"type":"phrase","pool":["..."]}`, `{"type":"pad"}`.

### ChapterDef (`content/chapters/a1_i.tres`)
`id`, `act` (int), `title_key`, `subtitle_key`, `steps: Array[Dictionary]`, `next_chapter: String`, `puzzle_ids: PackedStringArray`.

### CodexEntryDef (`content/codex/<id>.tres`)
`id`, `act`, `chapter_id`, `order`, `title_key`, `body_key` (<= 120 words), `example_key`, `wrong_key` (<= 50 words), `aside_key` (<= 50 words), `margin_keys: PackedStringArray` (1..3, <= 25 words each), `widget: String` (`""`, `shift_wheel`, `frequency`, `ioc`, `xor_beads`), `placeholder: bool` (Acts II-V stubs).

### ThirstConfig (`content/thirst_config.tres`)
`wrong_commit=8`, `hint_costs=[5,12,25]`, `thresholds=[40,65,90]`, `frenzy_at=100`, `frenzy_reset_to=70`, `grade_sanctified_max=10`, `grade_stained_max=35`.

### Dialogue JSON (`content/dialogue/<id>.json`)
```json
{
  "id": "a1_i_end",
  "location": "memory",            // "vault" or "memory"
  "ambience": "marsh",             // "vault" or "marsh"
  "nodes": [
    {"speaker": "kett", "text": "DLG_A1_I_END_01"},
    {"speaker": "isaak", "text": "DLG_A1_I_END_02", "if": {"flag": "frenzied_a1_i"}},
    {"speaker": "isaak", "text": "DLG_A1_I_END_03", "choices": [
      {"text": "DLG_A1_I_END_C1", "set": {"courier_drained": true}, "thirst": -35, "goto": "drained"},
      {"text": "DLG_A1_I_END_C2", "set": {"courier_spared": true}, "thirst": -12, "goto": "spared"}
    ]},
    {"label": "drained", "speaker": "narrator", "text": "DLG_A1_I_END_04", "goto": "after"},
    {"label": "spared", "speaker": "kett", "text": "DLG_A1_I_END_05"},
    {"label": "after", "speaker": "isaak", "text": "DLG_A1_I_END_06", "end": true}
  ]
}
```
Rules: nodes run in order. A node whose `if` is false is skipped. `set` and `thirst` apply when the node (or choice) is taken. `goto` jumps to a `label`. `end` stops. Conditions: `{"flag":"x"}` (truthy), `{"flag":"x","eq":v}`, `{"not":{...}}`, `{"all":[...]}`, `{"any":[...]}`. Speakers: `isaak`, `kett`, `marquise`, `steward`, `wenna`, `courier`, `lord`, `narrator` (narrator has no portrait). Speaker display names: `SPK_<SPEAKER>`.

### Strings (`content/i18n/strings.csv`, header `keys,en`)
Prefixes: `UI_` interface, `SPK_` speakers, `CH_` chapters, `PZ_Pnn_` puzzle titles, briefs, hints (`_HINT1..3`), cribs and questions, `LTR_Pnn` letters (`LTR_Pnn_A`.. when several), `LTR_Pnn_FROM` sender lines, `DLG_<SCENE>_nn` dialogue, `CDX_<ID>_TITLE|BODY|EXAMPLE|WRONG|ASIDE|M1..M3` codex, `CARD_` cards. Newlines inside a value are written as `\n`. Values are plain ASCII.

## 5. Mode contracts
| Mode | Commit is correct when | Trials (costed) | Params |
|---|---|---|---|
| caesar | wheel shift == key | each notch turned; each "read peak as E" | `show_tally` |
| keyless | every note's scheme identified and the concept question answered | none; wrong commit +8 | `question_key`, `answer_keys` (3), `correct_answer` |
| substitution | decrypt(ciphertext, player mapping) == normalized plaintext | none; wrong full commit +8 | `crib_key` (optional), `ngrams` (bool), `group5` (bool) |
| vigenere | decrypt(ciphertext, wheel settings) == normalized plaintext | each notch; each "read as E" | `period_given` (int, 0 = unknown), `period_max` |
| xor_rosary | stage 1 key byte found, stage 2 double pour done, stage 3 dial == key | none (dial free) | `stage1_pool` (letters for A and B) |
| xor_repeating | decrypt(ciphertext, dial keys) == plaintext | none | `keysize_min`, `keysize_max` |
| two_time_pad | all bytes of every target phrase revealed by correct pins | each wrong pin costs `trial_cost` | `crib_tray_keys`, `targets` [{`msg`, `phrase_key`}] |

A multiple of the true period that decrypts correctly is accepted (it is a correct key).

## 6. Tool interface
Each tool is `tools/<id>/<id>.tscn` with a root `Control` script (`class_name`), drawn in `_draw()`:
- `signal state_changed` (player changed something), plus tool-specific signals (`trial_made`, `request_codex`).
- `func get_state() -> Dictionary` / `func set_state(d: Dictionary) -> void` (for save/resume and the screenshot tour).
- `func undo() -> bool` (UndoStack of 50 snapshots, shared helper `ui/components/undo_stack.gd`).
- Tools never import crypto math. Mode controllers push derived data in (histograms, IoC values, Hamming scores, previews) via setters.

| id | Tool | Used by |
|---|---|---|
| cipher_wheel | two concentric rings, drag outer ring with inertia/detents; modes Shift / Mirror | 1, 2, 3 |
| tally_scroll | histogram vs English baseline; tabs letters / bigrams / trigrams; per-column selector | 2, 4, 6, 7 |
| substitution_board | glyph tiles dragged onto plaintext slots, locks, crib strip | 4, 5, 6 |
| multi_wheel | N stacked thin wheels, one per key column | 7, 8, 9 |
| kasiski_lens | long-press shows repeated trigrams, ruler of spacings, factor tray | 8 |
| column_loom | slider N splits text into coloured strands, IoC "blood purity" vial | 9 |
| bit_rosary | 8 beads per byte, tap to flip, hex/bin/ASCII toggle, XOR chalice | 10 |
| key_dial | 0..255 dial with English-ness gauge; one dial per column | 10, 11 |
| hamming_comb | bar chart of normalized Hamming distance for key sizes 2..40 | 11 |
| crib_dragger | C1 xor C2 stream, draggable crib strips, pin to message A/B, glyph keyboard | 12 |

## 7. Save schema (version 1)
```json
{
  "version": 1,
  "updated_unix": 0,
  "chapter_id": "a1_i", "step_index": 0,
  "thirst": 0.0,
  "flags": {"courier_drained": true},
  "puzzles": {"a1_p01": {"solved": true, "variant": 0, "thirst_spent": 4, "grade": "sanctified", "hints_bought": 1}},
  "active_puzzle": {"id": "a1_p02", "variant": 0, "thirst_spent": 3, "hints_bought": 0, "trials": 3, "tool_states": {}, "mode_state": {}},
  "codex_unlocked": ["a1_key"],
  "frenzies": [{"puzzle": "a1_p02", "unix": 0}],
  "coach_seen": {"cipher_wheel": true}
}
```
**v0 (legacy, used by the migration test):** `{"thirst": 30, "current_puzzle": "a1_p03", "solved": ["a1_p01","a1_p02"], "flags": {}}` with no `version`. `migrate()` upgrades step by step (`_migrate_0_to_1`, ...).
**Atomic write:** write `save.json.tmp`, copy current `save.json` to `save.json.bak`, rename tmp over `save.json`. **Load:** main, else backup, else fresh; a file that fails to parse or validate is treated as missing.
**Autosave:** every step transition, every commit/hint/trial, tool changes debounced to 1 s, and `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST`.

## 8. Settings (`user://settings.json`)
`text_size` (0..2), `clear_mind` (bool), `haptics` (bool), `vol_master`, `vol_music`, `vol_sfx` (0..1), `hint_confirm` (bool). Reset progress is a double-confirm button in the settings screen.

## 9. Testing
- `tools_dev/run_tests.sh`: import, then GUT over `res://tests` (unit, integration, solvers). Exit code 0 means green.
- Solvers (`tests/solvers/solver_pNN.gd`) use only core analysis functions and the intended technique; the integration test runs each on seeds `variant 0..N` and on the frenzy variant.
