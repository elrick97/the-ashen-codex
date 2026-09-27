# Playtest Report: Act I, "The Tithe Letters"

Sources: three adversarial playtest passes by independent subagents (`docs/playtest/adversarial_a1_i.md`, `_a1_ii.md`, `_a1_iii.md`), two independent crypto audits (`docs/CRYPTO_AUDIT.md`), four screenshot tours, the automated tests, and the reference solvers. Thirst numbers use `content/thirst_config.tres`: wrong seal +8, hint tiers +5/+12/+25, grades Sanctified <= 10, Stained <= 35, Damned > 35.

## Simulated first-time player, per puzzle

Values are after all fixes. "Expected" is a careful first-timer who reads the Codex page (free) and doesn't brute force.

| # | Puzzle | What they'd try | Where they'd stick | Do hints resolve it? | Expected Thirst / grade |
|---|---|---|---|---|---|
| 1 | The First Letter (Caesar, free wheel) | Drag the ring until the card reads | Nowhere; the coach mark shows the ring | Yes (tier 3: turn one notch at a time) | 0 / Sanctified |
| 2 | The Rusted Wheel (costed notches) | Spin the rusted wheel; the rising cost pushes them to the Tally | Not knowing the tallest bar is E | Tier 2 names frequency and E; tier 3 points at the Read-as button | 1-5 / Sanctified (hand-turning: 12-16 / Stained) |
| 3 | Thirteen Turns (ROT13 / Atbash) | Try Shift 13 and Mirror on each note | The concept question (answers in a seeded order) | Yes; the Kerckhoffs Codex page is free reading | 0-8 / Sanctified |
| 4 | The Tithe Roll (substitution) | Tally, place E/T, find THE and short words | Rare letters (J in "jar") late in the solve | Tiers point from tally to short-word patterns | 0-8 / Sanctified; 17 with two hints |
| 5 | The Signature (crib) | Frequency first (misleads: O and T outnumber E), then the crib strip | Finding where the crib's letter pattern agrees (letters only, spaces ignored) | Tier 3: the sign-off just before his name | 0-5 / Sanctified |
| 6 | Bigrams in the Marsh (flattened E, no word breaks) | Letters tab (T tops it), then Triples: THE | Reading the other 17 letters out of an unbroken stream | Tiers now target that stage: letters before each THE, then half-words | 10-35 / Stained (the hardest early solve) |
| 7 | The Steward Grows Clever (Vigenere, 5 given) | Per-column Tally; Read-as E; watch "shapes agree" | Columns whose peak is T or O, not E | Tier 2/3: try T, A, O, N and keep the best agreement | 14-22 / Stained |
| 8 | Kasiski's Lens | Hold repeats; factor tray glows the largest well-supported factor | Choosing 6 over its factors 2 and 3 | Tier 3: largest factor nearly all spacings share | 12-20 / Stained |
| 9 | The Loom of Columns (IoC) | Slide N; vial thickens at the key length | Columns that need I or N; the 0.79 column | Read-as covers E/T/A/O/I/N/S/H; tier 3 teaches the A-E-I-O vowel comb for stubborn strands | 20-30 / Stained |
| 10 | Bit Rosary (bits, XOR, single-byte) | Flip beads to match; pour twice; dial the gauge | None serious | Stage-by-stage hints | 0 / Sanctified |
| 11 | The Litany Key (repeating XOR) | Comb: shortest tooth (smallest near-best size marked); per-strand dials | A multiple of the key size (accepted anyway) | Tier 2 mentions multiples | 0 / Sanctified |
| 12 | BOSS: The Twice-Used Pad | Drag tray cribs; readable gold text only where it truly reads | Deciding which letter a crib belongs to (now filed correctly for free) and bridging Ansgar | Tier 3: earlier letters' words; P11's "Our friend in the Quill" is the key callback | 8-20 / Stained |

Fair path to the boss targets (verified by the crib-drag reference solver and by hand): "OUR FRIEND IN THE QUILL" (letter B) reveals "...THE TITHE FALLS ON" (A); "THE NIGHT OF" in A; tray "BROTHER" (B) reveals "E BLACK"; Ansgar is named twice before the boss, so "ANSGAR" in B reveals "MOON, ".

**Length:** 195 dialogue lines (2,775 words), 994 words of letters, 3,473 words of Codex (optional). About 15 minutes of reading plus 12 puzzles at 3-7 minutes each: roughly 60-90 minutes for a first-time player.

## Adversarial findings and what was done

All blockers and majors are fixed; every item below was re-tested (automated test or the probe that found it).

| Finding (severity) | Fix |
|---|---|
| P05: locking a tile then pinning the crib leaves an empty locked slot: unsolvable after a restart (blocker) | Pins skip locked tiles; empty slots drop their lock; holding an empty slot unlocks |
| Wheel charged phantom notches if touched during the Read-as animation (major) | Real angle jumps at once; only a visual offset animates (Cipher Wheel and Multi-Wheel) |
| Replaying a solved puzzle overwrote its grade (major) | Solved puzzles resume on their folio; the first record stands |
| P02 punished hand-turning after correct analysis (major) | Tier 3 points to the one-drop Read-as button; notch cost kept by design (rust) |
| P03 undo desynced wheel and text (major) | Restoring state re-signals mode and shift |
| P06 hints stopped before the real sticking point (major) | Hints rewritten for the post-THE stage |
| Crib-slide undo undid the previous placement (major) | One undo step per drag/nudge |
| Crib strip gave its place away through spaces (major) | Crib strip matches letters only; "agrees" is worded as a candidate, not proof |
| Boss: right crib in the wrong letter cost a wrong pin (major) | Filed into the letter it belongs to, with a note |
| P08 tray never glowed 6 (major) | Glows the largest factor with >= 80% of the best count |
| P09 columns unreachable with E/T/A/O reads (major) | Read-as E/T/A/O/I/N/S/H; "best agreement" wording; vowel-comb hint |
| P11 undo after choosing a size broke the dials (major) | Size follows the dials' column count; snapshot before resizing |
| Boss "readable" gold lit at wrong offsets (major) | `Crib.reads_like_english`: punctuation rules + quadgram fitness, and fragments under six letters are never called readable (neutral colour, the player judges) |
| Frenzy dodge by killing the app (minor) | `frenzy_pending` saved and replayed on load |
| Frenzy variants not harder (minor) | P01/P03 rusted; P04/P06 double wrong-seal cost; P05 keeps only IN ETERNITY; P07-P09 double notch cost; P12 wrong pins cost 6; new variants never reuse the first key word |
| No Thirst restored inside I.iii (minor) | Kett's flask after the Bit Rosary (-20) |
| Others: P03 answer always third, seal before reading every note, phantom tiles from the tally, P10 bead undo, tally column not following the drum, tray hiding spaces, keyboard missing ; - ', frenzy/after text continuity | All fixed (see CHANGELOG) |

## Review-and-fix loops

1. **Loop 1 (tests + first screenshot tour):** solvers tuned until all 12 puzzles solve on every seed and the frenzy variant; tour 1 at 1080x1920 found overflow at the largest text size, unreadable settings toggles, drips over the letter card, broken Codex drop caps, the crib strip's invisible letters, toasts over the tools, leaks at exit. All fixed; tour re-run.
2. **Loop 2 (independent crypto audit + three adversarial playtests):** 12 WRONG / 35 MISLEADING audit items and 1 blocker / 12 major / 20+ minor playtest items fixed (tables above and in the audit). Tours re-run at 1080x1920, 720x1280, 360x640 and 1080x1920 with a simulated notch; screenshots re-reviewed; last polish (rosary lesson card, clean audio shutdown).
3. **Loop 3 (re-audit):** a fresh auditor re-verified every earlier finding and audited everything new; see "Re-audit (second pass)" in `docs/CRYPTO_AUDIT.md`.

## Definition of Done (PROMPT.md section 11)

### Functional
- [x] **New game -> content warning -> title -> Vault -> 12 puzzles -> choice -> ending card, with touch and mouse.** `tests/integration/test_playthrough.gd::test_full_act_one_playthrough` drives the real Main scene through every step (28 dialogues incl. all three choices, 12 puzzles, folios, summaries, act folio, card, back to title). `test_mouse_and_touch_turn_the_wheel` turns the wheel with mouse events and with screen-touch events (touch is converted by `emulate_mouse_from_touch`).
- [x] **Every puzzle solvable by its intended technique; not cheesable via a free preview.** `tests/solvers/test_solvers.gd` (variants 0-4 + frenzy variant for each). Anti-cheese reasoning in each `content/puzzles/a1_pNN.tres` (`anti_cheese`), reviewed by the adversarial passes and the re-audit.
- [x] **Thirst costs, thresholds, frenzy, grades.** `tests/integration/test_framework.gd` (costs, levels, clamp, frenzy fires once and resets to 70, grade thresholds 10/35); `test_puzzle_flow.gd::test_frenzy_plays_scene_and_switches_to_harder_variant` (scene plays, variant 1, doubled rust, Thirst 70, frenzy logged); screenshots 47-53 (40/65/90 effects, frenzy scene, Clear Mind).
- [x] **Hints: 3 tiers, escalating, Thirst charged.** `test_framework.gd::test_hint_service_costs_escalate` (5/12/25), `test_puzzle_flow.gd::test_hints_charge_and_codex_unlocks_on_start`; text verified by both audits (tier 3 never gives the answer).
- [x] **Codex: every concept, reachable from any puzzle, >= 1 live widget per sub-chapter.** 14 Act I entries + 4 later-act placeholders; the Codex tab on every puzzle opens the current concept (`puzzle_host.gd::_open_codex`); widgets: I.i `shift_wheel` + `frequency`, I.ii `frequency`, I.iii `ioc` + `xor_beads`; screenshots 54-60.
- [x] **Save/resume anywhere incl. mid-puzzle tool state; migration and corruption tested.** `test_puzzle_flow.gd::test_mid_puzzle_state_survives_save_and_resume` (all 12, reloaded from disk); `test_framework.gd` (round trip, backup fallback on a torn write, both files corrupt -> fresh, invalid shape rejected, v0 -> v1 migration).
- [x] **Settings all work; Clear Mind removes every distortion.** `test_playthrough.gd::test_clear_mind_removes_every_distortion` (ink, desaturation, pulse, drips all 0; returns when off) and `test_text_size_rebuilds_theme`; `test_framework.gd::test_settings_round_trip`; reset progress uses a double ConfirmDialog. Clear Mind also stops wobble, candle flicker, reed sway, shake and turns wipes into fades (code paths check `Settings.clear_mind`).

### Quality
- [x] **100% of crypto core functions unit-tested; one command.** `tests/unit/test_coverage.gd` scans `core/crypto` and fails on any untested public function; `./tools_dev/run_tests.sh` (README).
- [x] **Zero script errors/warnings in headless boot + tour.** `qa/boot.log` empty of ERROR/WARNING; tour logs contain only the exempt WSLg V-Sync warning (BLOCKERS B1); the exported Linux build boots clean and passes `-- --selftest`.
- [x] **Static typing; untyped-declaration warnings on and at zero.** `project.godot` `gdscript/warnings/untyped_declaration=1`; `python3 tools_dev/lint.py` -> 0 diagnostics (Godot's own analyzer via its language server).
- [x] **Portrait layout at 1080x1920, 720x1280, 360x640; safe areas; no clipped text at the largest size.** `qa/screenshots/{1080x1920,720x1280,360x640,1080x1920_notch}/` (67 shots each); largest-text shots 64-67; safe areas via `SafeArea` (notch tour).
- [x] **Screenshots reviewed.** Two review passes (loops 1 and 2); fixes listed above.
- [x] **Independent crypto audit; every WRONG/MISLEADING fixed and re-verified.** `docs/CRYPTO_AUDIT.md` (first pass + re-audit).
- [x] **All strings in the translation CSV.** `content/i18n/strings.csv` (653 keys) built from `content/i18n/src/`; `tests/integration/test_strings.gd` (no literal `.text` in scripts, every `tr()` key and every content key exists).
- [x] **Export presets for Android, iOS, desktop, Web.** `export_presets.cfg`; Linux, Windows and Web exported; Android/iOS need SDK/Team ID (BLOCKERS B2).

### Content and IP
- [x] **Act I script complete, M-rated voice, accurate teaching text.** `docs/ACT1_SCRIPT.md` (beats + generated letters section); voice budgets enforced by `build_strings.py`; teaching text audited twice.
- [x] **Banned-terms grep clean** (output in the final report; only the rule lists themselves and statistical corpus tables match).
- [x] **Licences and ASSET_MANIFEST.** `licenses/` (5 OFL fonts, GUT MIT, Godot MIT); `docs/ASSET_MANIFEST.md`.

### Docs
- [x] GDD, CURRICULUM, ACT1_SCRIPT, TECH_DESIGN, DECISIONS, BLOCKERS, ASSET_MANIFEST, PLAYTEST_REPORT, NEXT_STEPS, ENVIRONMENT, README, CHANGELOG, CLAUDE.md.

## Top five to test first on a real phone
1. The Cipher Wheel and Multi-Wheel drag feel (inertia, detents, rust) and haptic ticks.
2. Crib Dragger legibility and drag precision at 360 dp (12 cells per row).
3. Substitution Board drag vs. tray scrolling on touch.
4. Frame rate of the parchment and Thirst overlay shaders on a mid-range GPU at 90+ Thirst.
5. Safe areas on a notched device and the largest text size on the boss puzzle.
