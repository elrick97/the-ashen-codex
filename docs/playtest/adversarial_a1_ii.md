# Adversarial playtest: I.ii "The Steward's Alphabet" (puzzles 4-6)

Method: I read the code and content, measured the plaintexts' statistics (they don't depend on the key, because a substitution keeps every letter's count and every repeat pattern), and ran headless probes of the real `PuzzleHost` and modes. I did not change any game files. Costs come from `content/thirst_config.tres`: a wrong seal costs 8, hints cost 5, 12 and 25. Grades: Sanctified <= 10, Stained <= 35, Damned > 35.

Content was checked as of commit `c66a4e4`, which rewrote several I.ii hints and changed the P05 frenzy crib to `IN ETERNITY`.

## P04 The Tithe Roll

Numbers: 913 letters, 25 distinct (no Z). E is the tallest bar (139, 15.2%), with T at 97. THE appears 25 times as a word, and word breaks are kept.

1. **Cheese.** None found that bypasses the concept. The preview decrypts only the tiles the player has placed. The Seal button stays disabled until every tile is placed (`substitution_board.gd:134`), and a wrong seal costs 8, which gives a poor 1-bit oracle. Placing tiles by trial is free, but each trial only pays off if the player reads word shapes, and that is the lesson. A long text with word breaks makes this the easiest puzzle of the three, as intended.
2. **Stuck?** Unlikely. Hints are correct and don't depend on the key. H1 points to the tally scroll, H2 says E/T and to check against short words, and H3 says to put the tallest bar on E and then find a repeating three-letter word. None of them gives the answer. H3 is right for P04, where E really is tallest, but it teaches a habit that walks players straight into the P05 soft-lock (issue B1).
3. **Walkthrough.** Tallest bar goes to E, the repeated 3-letter word gives THE, then word shapes (AND, OF, TO) do the rest. The rare tiles Q, X and J (2 to 3 occurrences each) are the only likely slip. Expect 0 Thirst (Sanctified), 8 after one slip (Sanctified), or 17 with H1+H2 (Stained).
4. **Bugs.** The shared board bugs B1, M2, m1 and m2 all apply here.

## P05 The Signature

Numbers: 375 letters. The counts O 43, E 41, T 35 and N 34 make single-letter frequency ambiguous, as designed. The crib `YOUR SERVANT IN ETERNITY` fits only at offset 445. Pinning it sets 11 letters, which cover 267 of the 375 letters (71%).

1. **Cheese: yes, the crib concept is automated or bypassable.**
   - The crib strip is compared against the raw text with spaces. A space in the crib must sit on a space in the cipher, so the word-shape 4-7-2-8 alone picks offset 445. Checking only spaces gives exactly the same single offset as the full check, so the letter-repeat reasoning (the lesson, and the Codex example) never decides anything.
   - "It fits" and the enabling of the Pin button act as a free oracle (`substitution_board.gd:125`, `:490`). The player can drag the strip across all 460 offsets until Pin lights up.
   - The letter can also be solved with no crib at all: THE appears 8 times as a separate word, so P04's word-shape method works.
   - The frenzy crib `IN ETERNITY` is actually a better lesson: its shape fits 5 offsets (176, 245, 351, 431, 458), and only the repeats pick 458.
2. **Stuck?** No. The brief and status line already say "slide the crib to where it fits". H3 says "hard against the letter's very end", but the crib ends 14 characters before the end (", VENERIC SOLL"), so "just before his name" would be more accurate. After pinning, THE with T and E known gives H, and the rest follows. None of the hints depend on the key.
3. **Walkthrough.** Open Crib, drag, Pin, then fill about 12 letters from word shapes. Expect 0 Thirst (Sanctified). **Trap:** a player who follows P04-H3 and the coach mark ("hold a slot to lock a sure one") puts the tallest tile on E and locks it. That tile is really O. Pinning then soft-locks the puzzle (B1).
4. **Bugs.** B1 (confirmed by probe), M2 (confirmed), m2.

## P06 Bigrams in the Marsh

Numbers: 174 letters, no word breaks, 20 distinct letters. The Letters tab ranks T 27 (15.5%), A 17, N 16, H 15, and E 12 (5th). The Triples tab shows THE 9, far ahead of the next entry, TTH 5; all others are 2. The Pairs tab shows TH 12, HE 9, then ST, TT and NT at 4 to 5 each. The English list shown beside it (IN, ER, AN, RE) doesn't match the letter's pairs.

1. **Cheese.** The n-gram tab hands over T, H and E in one tap, but that is the lesson. It is not trivial after that: the remaining 17 letters (69% of the text) must be read out of unspaced fragments. The free preview makes this "try a tile and read", which is still honest cryptanalysis. No undo, save or frenzy exploit found. A frenzy resets Thirst to 70 but also throws away the board and rolls a new key, and the grade still counts every point spent.
2. **Stuck? Yes, right after THE, and the hints don't reach that point.**
   - H1 (tallest bar is not E) and H2 (count pairs and triples) repeat the free brief, status line and Tally help text ("English leans on TH, HE and THE").
   - H3 (the commonest trigram is a common word) repeats the free Codex example, which even says "THE (9 times)".
   - Buying all three costs 42, which is Damned on its own, and the player is still no further than THE.
   - Low-count letters are likely to be misplaced in unspaced text, each costing a wrong seal: G appears once, P and K twice each, M and F three times each.
3. **Walkthrough.** A P04 habit puts D (really T) on E, and the preview shows garbage (free, so no harm). The player finds Triples, places THE, and gets fragments like `...TTHE...`. Then they flounder: the Pairs tab offers only ST, TT and NT at 4 to 5 each. Typical first-timer: H1+H2 (17), perhaps H3 (42), plus 1 to 2 wrong seals (8 to 16), for 17 to 58 Thirst (Stained or Damned). Thirst carries over from earlier puzzles, so a player entering at 45 or more can hit Frenzy here and lose the board.
4. **Bugs.** m3 (help text clipped), m4 (frenzy variant is not harder), plus the shared board bugs.

## Ranked issues

### Blocker
**B1. Lock + Pin soft-locks P05 permanently (confirmed by probe).**
- **Where:** `core/puzzle_modes/substitution_mode.gd:120-131`. `_pin_crib` checks locks only on the target slot, not on the cipher tile's current slot.
- **How to reproduce:** lock the tallest tile (really O) on E, then Pin.
  1. The pin moves that tile to O, leaving slot E empty but still locked.
  2. The real E tile is rejected from slot E (`substitution_board.gd:349`).
  3. The lock can't be removed, because a long-press needs a tile in the slot (`substitution_board.gd:291`).
- **Result:** the puzzle can't be solved. Undo recovers it only within the session, since the undo stack isn't saved. The lock is saved (`tool_states.board.locks`), so after a restart the only way out is sealing wrong until Frenzy.
- **Fix:**
  - In `_pin_crib`, skip any `cs` whose current plain letter is locked.
  - Drop locks on empty slots in `set_mapping`/`set_state`.
  - Let a long-press unlock an empty slot.

### Major
**M1. P06 hints don't unblock the real stuck point, and tier 3 duplicates free text.**
- **Where:** `content/i18n/src/a1_ii.csv:20-22`.
- **Fix:**
  - Make H2 the concept: THE gives three letters, and TH and HE confirm them.
  - Make H3 a key-independent next step that isn't the answer, e.g. "With THE placed, look at the letter just before each THE (`?THE`, `TTHE` five times): AT THE, TO THE. Words ending in TH (NORTH, SOUTH) and the doubled L in TALLOW, TILL and BELL give the rest."
  - Consider showing more than 6 grams, or marking doubled letters.

**M2. Undo after sliding the crib silently reverts the previous placement or pin (confirmed).**
- **Where:** `tools/substitution_board/substitution_board.gd:439-448`. `_move_crib` emits `state_changed` without calling `snapshot()`, so the mode's undo order points at the board, and `board.undo()` pops the last tile or pin snapshot.
- **Probe:** place J->E, slide 3 steps, press Undo. The mapping is now empty and the crib jumps back to offset 0.
- **Fix:** call `snapshot()` in `_move_crib`, merging consecutive slides into one step, or don't emit `state_changed` for slides at all.

**M3. The P05 crib lesson is done by the UI or can be skipped.**
- **Where:** `substitution_board.gd:125`, `:490`, and `crib.gd:25-30`.
- **Problem:** the space pattern alone picks the offset, "It fits" plus the Pin button form a free oracle, and THE ×8 lets players ignore the crib entirely.
- **Fix:** show the crib window without spaces or punctuation so letter repeats have to do the work (the frenzy crib already shows this works), and remove the "It fits" banner or charge for a wrong pin, as P12 does. Optionally strip word breaks from P05 as well, or cut the THE count, so the crib is actually needed.

### Minor
- **m1. Tapping a zero-count tally bar and then a slot places a "phantom" tile** for a letter that isn't in the cipher, and it knocks out the real tile in that slot. Probe: P04 phantom E placed on slot E removed the real J->E. `substitution_mode.gd:46,70-71`, `substitution_board.gd:315-316`. Fix: ignore `letter_selected` when the count is 0, or have `_place` reject ciphers not in `tiles`.
- **m2. Tapping a tally bar adds an undo step** (`tools/tally_scroll/tally_scroll.gd:349`), so Undo appears to do nothing while it pops invisible bar selections. Also, selecting a tile clears the crib's gold band on the letter (`substitution_mode.gd:73-74`). Fix: don't snapshot selections, and re-run `_update_crib()` after a selection.
- **m3. The P06 Pairs/Triples help text is clipped behind the bottom bar** ("...glish leans on TH, HE and THE." overlaps Seal in `qa/screenshots/1080x1920/26_p06_trigrams.png`; `tally_scroll.gd:242`). Fix: cap the gram grid height or put the label above the grid.
- **m4. After a frenzy, P04 and P06 just roll a new key; they are not harder** (`frenzy_overrides = {}` in `a1_p04.tres` and `a1_p06.tres`), contrary to PROMPT 4.1. Fix: for example, P04 drops word breaks and P06 shortens the text or hides the Pairs tab.
- **m5. Text nits:**
  - The shared frenzy scene says Wenna's copy was ruined, but P05 came by raven and P06 is the clerk's letter (`a1_ii.csv:100`).
  - `DLG_A1_P06_AFTER_01` names "Blackwater ford", which the letter never mentions (`a1_ii.csv:73`).
  - P05-H3 says "very end", but the crib sits just before the name (`a1_ii.csv:13`).
