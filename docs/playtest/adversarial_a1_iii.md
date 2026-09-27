# Adversarial playtest: Act I.iii "The Many-Toothed Key" (puzzles 7-12)

Tested against HEAD `f9ab878`, which already includes the E/T/A/O read-as buttons, the shapes-agree score and the reworded hints. The numbers come from headless probes that build the real `PuzzleInstance`s with `PuzzleFactory` (variants 0-3) and from driving the real `PuzzleHost` scene. The probe scripts were deleted afterwards.

Thirst costs used: wrong seal +8, hints +5/+12/+25, notch or read-as +1 (+2 after a frenzy on 7-9), wrong pin +4. Grades: Sanctified <= 10, Stained <= 35, Damned > 35.

---

## 7. The Steward Grows Clever (Vigenere, period 5 given)

**Cheese.** None found. The drums are rusted, so every notch costs. Reading a drum's shapes-agree score means paying for a setting first. Undo only reverts to a position you already paid for. The period stepper is hidden. The drum window shows the key letters, so a player with two or three letters can guess the key word (GRAVE, EMBER). That is a legitimate cryptanalytic shortcut, and it still costs 1 read per drum.

**Stuck?** The letter has 197 letters, about 40 per column. Only 2 of the 5 columns have E as the tallest bar. Columns 1, 2 and 4 peak on plaintext T, O and N. The shapes-agree score does separate them well: the true shift scores 0.82-0.94 and the best wrong shift at most 0.69. Following hint 3's "under about 80, try T, A or O" rule lands every column. The hints are true, don't depend on the key, and tier 3 never gives the answer.

**Walkthrough.** A player who reads the tallest bar as E, checks the score, then tries T/A/O and then the next bar needs **13 reads (v0 GRAVE) or 14 (v1 EMBER)**. That is 13 Thirst, so **Stained**, or 28 after a frenzy. Reaching Sanctified requires reading the aligned English row before paying, which cuts it to about 5-8. The anti_cheese note's "about 5-10" is optimistic for a first-timer.

**Bugs.** Selecting a drum sets `tally.column` directly (`vigenere_mode.gd:47-49`). The column buttons are not rebuilt, so the tally shows column 3 while the "All" button still looks pressed. Read-as then acts on the column that is not highlighted.

## 8. Kasiski's Lens (unknown period)

**Cheese.** The period stepper and the tallies are free. Stepping widths and eyeballing each column's peakiness is a slow form of IoC that skips Kasiski entirely. The anti_cheese note now admits this. It is acceptable: it is still analysis, and the drums still cost.

**Stuck? Yes, on the key length.** With every repeat collected, the factor tray reads as follows:

| Key | Variants | Tray (factor:count) | Glowing "best" |
|---|---|---|---|
| CANDLE | v0, v1 | 2:28, **3:30**, 6:26, 12:13 | 3 |
| SHROUD | v2 | 2:27, 3:27, 6:26 | 2 and 3 |
| VESPERS | v3 | **7:56**, 2:51 | 7 (fine) |

Any spacing that is a multiple of 6 is also divisible by 2 and by 3. So a 6-letter key (3 of the 5 pool words) can never be the strongest button in the tray. Hint 3, "Take the factor most spacings share", points at 3. The Codex example says "the largest shared". The tray and hint 3 contradict it.

At the right width, E/T/A/O reads land in 9 tries (6-letter keys) or 13 (VESPERS). At width 3, no column reaches 80, so every read there is wasted.

**Walkthrough.**
- About 2 minutes of long-pressing collects around 10 of the 21 repeats.
- The player taps the glowing 3 and burns 3-6 reads.
- They then try 6 and spend 9 reads.
- Total is about **12-20, Stained**. Buying hint 3 (+42 cumulative) makes it worse: **Damned**.

## 9. The Loom of Columns (IoC)

**Cheese.** The same free stepper and tally applies, and the loom gives the IoC for free by design. No shortcut past the drums.

**Stuck? Yes, on columns 1 and 4.** The letter has 195 letters, 39 per column. The loom works: N=5 reads 0.065 and N=10 reads 0.079, and the reworded hint 3 ("smallest width") handles the multiple. Frequency then fails on two columns:
- Tallest bar = E in only 1-2 of the 5 columns.
- **Column 1's true shift scores 0.79**, under the 80 rule taught by puzzle 7's hint 3. In v0 (ASHES), column 1's correct setting is A, which is where the drum starts. It shows "79", and the rule tells the player to move it away.
- **Column 4** is nearly flat (true 0.82, best wrong 0.76).
- For both columns, E/T/A/O on the four tallest bars never reaches the true shift (16 tries each, no hit).

The remaining routes are reading the 60%-correct preview and deducing a letter, or rusted notches. A clever player can read a deduced E/T/A/O letter off the tally for 1 Thirst, but nothing teaches that.

**Walkthrough.**
- 3 good columns cost about 9.
- Columns 1 and 4 cost 5-13 each (notches or guesses), plus a probable wrong seal (+8).
- Total is about **20-35, Stained to Damned**. A frenzy variant costs double, so **Damned**.
- This is the hardest puzzle in the sub-chapter, and it is not the boss.

## 10. Bit Rosary

**Cheese.**
- Stage 1: making the "Poured" row match the "Wanted" row bead by bead *is* the XOR relation, so that is fine.
- Stage 2: two presses, and no decision.
- Stage 3: the dial is free by design. The gauge reads 1.00 at the key and at most 0.80 elsewhere, and the byte grid previews the plaintext live.
- Expected Thirst is 0, so **Sanctified** unless the player seals stage 1 early (+8). Working as intended.

**Stuck?** Unlikely. The hints are stage-agnostic, though. A player stuck on stage 3 who buys tier 1 gets bead advice. Hint 3's "Once you have one letter..." is confusing phrasing.

**Bugs.** Undo after a bead flip does nothing (confirmed: k=1 stays 1). `bit_rosary.gd:77` snapshots only `view`, and k lives in the mode (`xor_rosary_mode.gd:56-60`).

## 11. The Litany Key (repeating-key XOR)

**Cheese.** Dials are free. Each dial controls every 13th/14th byte, and the per-strand gauges separate cleanly (true 0.95-1.00, runner-up at most 0.85). No shortcut, but it is a grind: 13-14 dials, each with up to 256 values.

**Stuck?** Mostly no. The comb results by variant:
- v0/v2 (WE DO NOT END): the best tooth is 13, then 26 and 39. Correct.
- v1/v3 (SALT AND ASHES, the post-frenzy variant): **the comb outlines 28** (2.696) over 14 (2.762). The tap text and hint 2 now mention multiples, and 28 is accepted, so it only costs extra dial work.

**Walkthrough.** Comb, then transpose, then 13 dials. **0 Thirst, Sanctified**, about 5-10 minutes.

**Bug (confirmed).** Choosing a size does not snapshot the dial (`xor_repeating_mode.gd:31-37`). Repro: turn the dial before choosing (or choose 13 and later choose 26), then press Undo.
- The dial restores its old 1-column (or 13-column) state while `keysize` stays 13 (or 26).
- `sync_views` then throws `Out of bounds get index` at line 56 on every change.
- The chips and gauges die.
- Seal judges a 1-byte key and charges +8.
- Re-choosing a size on the comb recovers.

## 12. BOSS: The Twice-Used Pad

**Cheese.**
- No preview, and pins are checked against the truth, so guess-pinning costs 4 each.
- Single-character cribs are no cheaper: a space next to a letter means a 50% row guess at 4 Thirst.
- **The frenzy consequence is void**:
  - The letters are fixed, so every variant shows the same C1 xor C2.
  - Re-pinning an already-correct crib is free (verified).
  - The "lost" SALT BARN crib can be typed back on the glyph keyboard.
  - The only penalty is the Thirst reset.

**Stuck? On the letter row.** A correct crib pinned in the wrong letter costs 4 and gives the same "wrong" feedback as a bad offset. Verified: BROTHER at offset 60 pinned in A cost +4, and pinned in B was free.
- The dragged fragment is identical whichever row is selected, so XOR cannot tell the player which row is right.
- The row defaults to A, while the key tray crib BROTHER lives in B.
- YOUR SERVANT IN ETERNITY reads perfectly at both 169 and 171, but each offset is valid for only one letter.
- " THE " and SALT BARN occur in both letters.
- A player told "wrong" will abandon a correct placement.

The gold "readable" tint (`Crib.is_plausible_upper`) is mostly false. A letter xor letter byte, xor a crib letter, usually lands on A-Z:

| Crib | Gold offsets | True |
|---|---|---|
| TITHE | 37 | 1 |
| " THE " | 24 | 9 |
| BROTHER | 13 | 1 |
| LEDGER | 14 | 1 |
| ANSGAR | 15 | 1 |

The fragments themselves (for example 'S; DF' or ' EWVX' against the true 'ND IN') are readable enough to judge, but the colour invites 4-point pins.

**Fair path to "the night of the black moon" and "Brother Ansgar": yes.** Targets are A[45..72) and B[60..74) of a 207-byte overlap.
1. "OUR FRIEND IN THE QUILL" is the opening of the steward's report in puzzle 11. It has a unique gold hit at B@22, which shows A = "DY. THE TITHE FALLS ON ".
2. Guessing "THE NIGHT OF" in A reveals B " IS NO FRIEND. B...".
3. The tray's BROTHER at B@60 gives A "E BLACK".
4. ANSGAR is introduced in the I.iii intro as the Order's key-keeper, and the "Who:" line shows 14 blanks, which is "BROTHER ______". ANSGAR at B@68 gives A "MOON, ".
5. A custom crib "BROTHER ANSGAR" plus "BLACK MOON" (B side "OTHER ANSG", 1 of only 3 gold hits) closes both targets.

That is about 6-8 pins. The hints never point at the puzzle 11 callback or the row choice, and tier 3 is generic.

**Walkthrough.** 1-3 row mistakes plus 0-2 misreads comes to about **8-20, Stained**. This is roughly as hot as the design intends. With no Thirst restore inside I.iii, carrying over 70 into the boss is likely after the costs of 7-9 (see issue 12), so a frenzy here is common. It is harmless because of the void consequence.

---

## Ranked issues

No blockers found: every puzzle is solvable, and no tier-3 hint gives the answer.

### Major
1. **Boss: a correct crib in the wrong letter is charged as a wrong pin** (`core/puzzle_modes/two_time_pad_mode.gd:68-79`). The math cannot tell the rows apart, and the tray's key crib BROTHER sits in B while the default row is A.
   - *Fix:* accept a pin if the crib matches either letter at that offset and file it in the right row. Charge only when it matches neither. Say "right words, other letter" on a row miss if the row is kept as a choice.
2. **P8 factor tray always glows 3 or 2 for 6-letter keys, and hint 3 sends the player there** (`tools/kasiski_lens/kasiski_lens.gd:128-143`; `content/i18n/src/a1_iii.csv:13`). CANDLE: 3:30 > 6:26. SHROUD: 2 = 3 = 27 > 6:26. This affects 3 of the 5 pool keys and variants v0-v2.
   - *Fix:* glow the largest factor whose count is at least 0.8 of the best (`Kasiski.likely_period`'s rule), or add a "largest shared" marker.
   - *Hint 3:* "Take the largest number that nearly every spacing shares...".
3. **P9 columns 1 and 4 cannot be found by E/T/A/O reads, and column 1's true setting scores 79, under the "about 80" rule** (`LTR_P09`, `a1_iii.csv:21`; the rule is at `a1_iii.csv:6`). This is the costliest puzzle of I.iii, and Damned after a frenzy.
   - *Fix:* rewrite LTR_P09 and add a check in `tools_dev/check_letters.py`: for every pool key, each column's true-shift profile_match is at least 0.85 and is reachable by E/T/A/O on the two tallest bars.
   - *Alternatively:* allow "read as any letter" (tap a letter on the English row), which makes preview deduction cheap and principled.
4. **P11 Undo after choosing a key size desyncs the dial from `keysize`** (`core/puzzle_modes/xor_repeating_mode.gd:31-37, 56`). It throws out-of-bounds script errors on every refresh, and Seal judges a short key (+8). Reproduced.
   - *Fix:* call `dial.snapshot()` before `set_columns` in `_choose`, and derive `keysize` from `dial.columns` in `sync_views`/`set_state`. Alternatively, keep `keysize` in the dial's state.
5. **Boss: the gold "readable" tint is a false positive most of the time** (`two_time_pad_mode.gd:61`, `core/crypto/analysis/crib.gd:95`). TITHE lights at 37 offsets with 1 true.
   - *Fix:* require letters that form word-like text, for example `EnglishScore.gauge(frag)` at least about 0.8 plus at least one vowel per 4 letters, or drop the colour and let the reading speak.

### Minor
6. **P10 Undo is a no-op for bead flips** (`xor_rosary_mode.gd:56-60`, `tools/bit_rosary/bit_rosary.gd:77`). *Fix:* snapshot k in the mode, or put k in the rosary state.
7. **P10 hints ignore the stage.** Tier 1 is bead advice even at stage 3, and HINT3's "Once you have one letter" is unclear (`a1_iii.csv:25-27`). *Fix:* use per-stage hint keys, or order the hints by stage.
8. **The tally's column buttons don't follow drum selection** (`vigenere_mode.gd:47-49`). *Fix:* add a `TallyScroll.set_column(d)` that updates the button group.
9. **Frenzy "harder variant" is not harder:**
   - P8 v1 reuses v0's key CANDLE.
   - P12 variants share one C1 xor C2.
   - P12 re-pins are free, and the lost SALT BARN crib can be retyped.

   *Fix:* exclude the previous variant's key when picking. For P12, clear custom cribs and charge re-pins after a frenzy, or swap in a different letter pair.
10. **The shared `a1_iii_frenzy` dialogue talks about losing "the page with the salt barn" and "that letter" for frenzies in P7-P11 too**, yet the same letter comes back (`a1_iii.csv:165-166`). *Fix:* use a generic I.iii frenzy line, and keep the salt-barn line for P12 only.
11. **P11 comb outlines 28 (a multiple) as best for SALT AND ASHES.** Mitigated by the tap text and hint 2. *Fix:* outline the smallest size within about 5% of the minimum.
12. **No Thirst restore inside I.iii, and P7-P9 are all costed.** First-timers are likely at 60+ by P12, and a P9 frenzy doubles its cost. *Fix:* consider a small story restore after P10/P11, or a lower trial cost on P9.
13. **Boss UI details:**
    - The tray button shows " THE " as "THE", hiding the spaces that matter (`tools/crib_dragger/crib_dragger.gd:174`).
    - The glyph keyboard has no `;`, `-` or newline, so "LEDGER; COUNT" and "MORROW-VEIL" can't be written.
    - Screenshot `43_p12_crib_readable.png` shows the "Who:" line under the bottom bar. It predates the goal-on-card change, so re-shoot to confirm.
14. **The P7 anti_cheese note claims "about 5-10 Thirst"; following the hints costs 13-14** (Stained). Either accept Stained as the norm or make the first read per column free.
