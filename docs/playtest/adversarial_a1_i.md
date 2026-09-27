# Adversarial playtest: Act I, sub-chapter I.i (puzzles 1-3)

Reviewed on 2026-09-27 against HEAD `463a3dd` plus the uncommitted working tree. That tree includes the new Tally "Read as E/T/A/O" row, the "shapes agree" readout and the rewritten P03 hints.

Numbers come from `content/thirst_config.tres`: wrong seal +8, hints +5/+12/+25, Sanctified <= 10, Stained <= 35, frenzy at 100 resets Thirst to 70.

I measured behaviour with a throwaway GUT probe (now deleted) that drove the real `main.tscn` and `PuzzleHost`. Seeded keys:

| Puzzle | v0 (normal) | v1 | v2 | v3 |
|---|---|---|---|---|
| P01 | shift 19 | 16 | 20 | 6 |
| P02 | shift **12** | 11 | 22 | 9 |
| P03 | atbash, atbash, rot13 | atbash, rot13, atbash | atbash, atbash, rot13 | atbash, rot13, atbash |

P02 costs 1 per trial at v0 and 2 per trial at v1 and later. Its letter has 260 letters. The E peak is unambiguous: 48 against 29 for the next letter.

---

## P01 "The First Letter" (Caesar, free wheel)

1. **Cheese.** Not applicable, because the free live preview is the lesson. The only cost is a premature seal (+8, still Sanctified).
2. **Stuck?** No. Dragging the ring is taught by a coach mark, and the status line says to seal. Hints are correct, none depends on the key, and tier 3 ("one notch at a time... seal it") does not give the number.
3. **Walkthrough.** The player drags the ring and sees words appear at 19 (7 notches clockwise), then seals. Expected spend is 0 (8 if they seal early to see what happens). Grade: Sanctified.
4. **Bugs.** None specific to P01.

## P02 "The Rusted Wheel" (Caesar by frequency, costed brute force)

1. **Cheese.**
   - Blind brute force from 0 costs 12 notches going up or 14 going down, so it ends Stained. The rust works for v0.
   - Undo is free but only returns to shifts already paid for, so there is no gain.
   - Reload does not refund, because `charge()` saves immediately.
   - **Real cheeses:**
     - (a) *Grade laundering.* Solve Damned, close the app on the folio, then Continue. The puzzle restarts with `thirst_spent = 0`, and a replay costs 1 ("Read Q as E"), which overwrites the record with Sanctified. Measured: record `damned, 40` became `sanctified, 1`. The same trick works on every puzzle.
     - (b) *Frenzy dodge.* Kill the app during the frenzy scene. On reload Thirst is 100 with no pending frenzy, the same variant, and nothing logged. This works on any puzzle that can be finished with no further cost (P01, P03). Measured: P03 was solved at Thirst 100 with `frenzy_count = 0`.
   - After a frenzy the "new, harder" letter has the same plaintext under a new key. Anyone who read it before can pin the key from one known letter.
2. **Stuck?** Unlikely: the Tally coach mark says "English shouts E", and the peak is huge. The hints have two problems:
   - Tier 2 ("its distance to what it should be") never names E or frequency analysis. It reads more like a nudge than a concept hint.
   - **Tier 3 is misleading:** "turn the wheel that many stops" sends the player to the manual path, which costs 12 at v0 (the key is 12 notches from 0). "Read as E" does the same thing for 1.
   - No hint depends on a specific key.
3. **Walkthrough.** The player tries 2-3 notches (the rust bites), opens Tally, taps Q, and presses "E" (+1). Typical spend is 3-5: Sanctified.
   - A player who does the analysis correctly in their head but turns the wheel by hand (as tier 3 says) pays 12-16: **Stained**. That is the same as blind brute force.
   - Hints 1 and 2 bring the total to about 18-20: Stained. All three hints (42 or more): Damned.
4. **Bugs.**
   - **Overcharge race after "Read as"** (measured). A single tiny nudge made while the 0.45 s turn animation plays charged **+16**, and the next touch charged **+38**: 58 Thirst in total, from an action the game prices at 1.
     - Cause: `turn_to()` sets `_last_notch = target`, while the tween keeps writing `_angle` from its old, unnormalised value (for example -3 after a backward turn).
     - Any `_check_notch()` call during the tween (a drag, or settling in `_process`) then walks and charges every notch between the two, and again when the tween callback snaps `_angle` back to the target.
     - `show_tab(0)` switches straight to the wheel, which invites exactly that touch. This does not happen with Clear Mind on, because there is no tween.
   - Repeating "Read as" at the current shift charges again (+1). This is harmless.

## P03 "Thirteen Turns" (ROT13 vs Atbash, Kerckhoffs)

1. **Cheese.**
   - The wheel is free, so every note can be read by eye. `anti_cheese` accepts that.
   - The "assessment" is a 3-option question with the answer fixed at option 3. Guessing costs 0/8/16 (expected 8), so **one wrong guess is still Sanctified**.
   - The free Codex bookmark opens `a1_kerckhoffs`, which is unlocked at puzzle start. It states both schemes exactly (ROT13 = 13, Atbash = reversed) and the answer ("not ciphers at all... neither hides anything once you know its name").
   - All three paid hints are therefore dominated by free text. Reading is meant to be free, but then the question tests nothing.
2. **Stuck?** No. Shift covers the ROT13 note and Mirror covers the Atbash notes; both are visible buttons. The working-tree hints are correct:
   - The old tier 1 ("three little tricks", "never changes a letter's shape") contradicted the status line and has been fixed.
   - The new tier 3 no longer echoes answer A3's wording.
   - Remaining gaps:
     - The brief and tier 3 say "Name each note's trick", but there is no naming control. Naming means setting the wheel.
     - The hub labels 13 as "the key" in a puzzle whose lesson is "ROT13 has no key".
3. **Walkthrough.** Note 1 is Atbash: the player tries shifts, then Mirror, and it reads. Note 3 is ROT13: turn to 13. Then seal and pick option 3. Expected spend is 0-8: Sanctified.
   - If the player seals before all three notes read, they pay +8 with a generic "Wrong" toast that doesn't say which note, or that the question comes after. Worst plausible case: 8 + 16 = 24, Stained.
4. **Bugs.**
   - **Undo desyncs the wheel from the reading** (measured). The failing sequence is: the note is at shift 0, the player toggles Mirror, then presses Undo.
     - Result: the wheel shows Shift/0 but the stored setting stays Mirror, so the card shows the Atbash reading.
     - The reverse sequence (Mirror, Shift, Undo) is worse. The wheel shows **Mirror** while the card shows raw ciphertext. The player concludes that "Mirror doesn't work" and a seal is judged wrong (+8).
     - The desynced setting is what gets autosaved.
     - Cause: `CipherWheel.set_state()` changes `mode` without emitting `wheel_mode_changed`, and emits `shift_changed` only if the shift changed. `KeylessMode._store()` therefore never runs.
   - `can_commit()` is always true, so the Seal button invites a costed seal while notes are unread.

---

## Ranked issues

| # | Sev | Issue | Where | Suggested fix |
|---|---|---|---|---|
| 1 | **major** | Touching the rusted wheel during the "Read as" turn animation charges dozens of notches (measured +54 on top of the 1 charged). This can push a careful player to Damned, or into a frenzy. | `tools/cipher_wheel/cipher_wheel.gd:83-103` (`turn_to`), `:150-164`, `:208-215`; `core/puzzle_modes/caesar_mode.gd:42-44` | Keep the tween in a member and `kill()` it on press, and before any `_check_notch`. Set `_angle = float(target)` first, normalise `from` with `fposmod(_angle, 26)`, and animate only a separate visual offset that `_check_notch` never reads. |
| 2 | **major** | Grade laundering: closing the app on the folio, then Continue, replays the puzzle with a fresh `thirst_spent` and overwrites the record. | `core/game/progression.gd:106-116`, `:155-166`; `scenes/main.gd:179-183` | In `start_puzzle`/`run_story`, if `is_solved(id)`, skip straight to the folio or advance. Never overwrite an existing solved record; keep the first grade. |
| 3 | **major** | P02 prices the concept by distance. A player who reads the Tally and turns to the computed key by hand pays 12-16 (Stained), the same as blind brute force. Only the "Read as" button is cheap, and hint 3 tells the player to turn by hand. | `core/puzzle_modes/caesar_mode.gd:18`; `content/i18n/src/a1_i.csv` `PZ_P02_HINT3` | Charge per trial (each time the wheel comes to rest on a new shift) instead of per notch crossed, and blank the preview while dragging. Alternatively, start the wheel 13 from the key. Rewrite hint 3 to point at "tap the tallest bar, then Read it as E". |
| 4 | **major** | P03 Undo desync: after Mirror/Shift and Undo, the wheel face and the stored reading disagree. This can cause a wrong seal (+8) and a misleading lesson, and it is autosaved. | `tools/cipher_wheel/cipher_wheel.gd:73-79`; `core/puzzle_modes/keyless_mode.gd:34-35`, `:54-58` | Have `set_state` emit `wheel_mode_changed` when the mode changes, or have `KeylessMode` re-read `wheel.get_state()` on `state_changed` and in `sync_views()`. |
| 5 | minor | Frenzy dodge: killing the app during the frenzy scene reloads at Thirst 100 with no frenzy, the same variant and no log. Free puzzles can then be finished without any consequence. | `core/game/thirst.gd:20-25`; `scenes/puzzle_host/puzzle_host.gd:301-316` | Write `frenzy_pending` into the active record before opening the scene. On load, if it is set (or Thirst >= `frenzy_at`), replay the frenzy immediately. |
| 6 | minor | The P03 question can be brute-forced cheaply (the fixed third option; one miss is still Sanctified), and the free Codex page opened by the bookmark states both schemes and the answer. | `content/puzzles/a1_p03.tres`; `scenes/puzzle_host/puzzle_host.gd:144`, `:292-294` | Shuffle the options (seeded), and make a wrong answer cost enough to leave Sanctified. Alternatively, unlock `a1_kerckhoffs` on solve rather than at start, or open the bookmark on `a1_key`. |
| 7 | minor | The P03 seal is always enabled, and a wrong seal doesn't say which note is unread, or that a question follows. | `core/puzzle_modes/keyless_mode.gd:79-82`; `puzzle_mode.gd:42` | Override `can_commit()` so it requires every note to have been touched, and toast "Note N still reads as noise". |
| 8 | minor | P02 hint 2 never names E or frequency analysis, so tier 2 reads like a nudge. | `a1_i.csv` `PZ_P02_HINT2` | For example: "English leans on E above all. The tallest bar is probably E; the gap between them is the shift." |
| 9 | minor | Frenzy "harder variant" is not harder for P01 or P03 (`frenzy_overrides = {}`). P02's new letter has the same plaintext under a new key, which contradicts "we'll not get that letter now". | `content/puzzles/a1_p01.tres`, `a1_p03.tres`, `a1_p02.tres` | Add alternate letters (`plaintext_keys` per variant) or real overrides. For example, P01 v1+ could use a rusted wheel, and P03 v1+ could hide the Mirror button's label. |
| 10 | minor | P03 wording: the brief and hint 3 say "Name each note's trick", but naming happens by setting the wheel. The hub shows "13 / the key" in the no-key lesson. | `a1_i.csv` `PZ_P03_BRIEF`; `cipher_wheel.gd:287-290` | Say "Set the wheel to each note's trick". In keyless mode, label the hub "ROT13" at shift 13, not "the key". |
| 11 | minor | Tool state is saved only by a 1 s debounce, while Thirst is saved on every charge. A pause or kill right after a paid drag loses the wheel position but keeps the cost. | `scenes/puzzle_host/puzzle_host.gd:198-217` | Call `save_now()` (or write `tool_states`) inside `charge()`. |
