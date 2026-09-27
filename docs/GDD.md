# The Ashen Codex: Game Design Document

**Genre:** grimdark narrative codebreaking, M-rated. **Platform:** mobile portrait (1080x1920 base), playable with a mouse. **Slice:** Act I, "The Tithe Letters" (12 puzzles, about 60 to 90 minutes).

**Tagline:** *Everything eternal repeats.*

## Premise
Isaak Varr, a pale-blood and former cipher-hunter of the Order of the Silent Quill, is chained in a vault under the Undying Court's library. Marquise Ottilie Dray, the Court's archivist and a vampire cryptanalyst, wants to know how the Order broke her kind's ciphers. Every chapter Isaak tells is a memory; every memory is a run of puzzles built on real ciphers and real attacks.

## Pillars
1. **The crypto is real.** Correct ciphers, correct attacks, generated from plaintext and key at load time, and each puzzle has a reference solver that uses the intended technique.
2. **Hands on the math.** Wheels, tiles, beads, dials, combs and crib strips. The player never types math.
3. **Insight is cheaper than force.** Brute force is possible but costs Thirst; analysis tools are free.
4. **Grimdark and crude.** Written violence, profanity and gallows humour; restrained visuals.
5. **Balanced learning.** After Act I a player can do every Act I attack on paper.

## Core loop
1. **Vault** (frame): short exchange with the Marquise; she prompts the next memory.
2. **Memory scene**: Isaak and Kett intercept a letter (dialogue, past tense).
3. **Puzzle**: the letter arrives as ciphertext on a parchment card; the player uses the tactile tools, reads free analysis, optionally buys hints, and commits (seals) an answer.
4. **Folio**: the decrypted letter as story, the grade, the Codex entries unlocked, sometimes a remark from the Marquise.
5. Repeat; at each sub-chapter's end a feeding choice restores some Thirst at a narrative price.

## The Thirst
- 0 to 100, carried across puzzles within the act, partly restored by story choices at sub-chapter ends.
- **Free:** every analysis view (Tally Scroll, lenses, gauges, comb, dragging cribs), reading the Codex, rereading bought hints.
- **Costs** (tunable in `content/thirst_config.tres`): wrong commit +8; brute-force trial +1 to +3 on `brute_force_costed` puzzles; hint tiers +5 / +12 / +25.
- **Thresholds:** 40 heartbeat layer and faint red vignette; 65 ink bleed, wobble on non-critical UI, whispers in the Marquise's margins; 90 pulse and desaturation; 100 **Frenzy**.
- **Frenzy:** a written scene with a consequence, logged in the save; Thirst drops to 70 and the puzzle restarts on a harder seeded variant. Later dialogue checks the frenzy flag.
- Effects never cover the ciphertext, the tools' readouts or the commit button. **Clear Mind** (Reduce Motion) disables every distortion shader and wobble.

## Grades
Thirst spent within one puzzle: **Sanctified** <= 10, **Stained** <= 35, **Damned** > 35. Shown on the folio; the chapter summary lists all twelve.

## Hints
Three tiers, voiced as memories of Brother Kett: Nudge (what to look at), Concept (which technique and why), Near-answer (the exact next step, never the answer). Tiers unlock in order; a bought tier stays readable for free. Optional confirmation before paying.

## The Codex
Isaak's grimoire. One entry per concept: plain explanation (<= 120 words), worked example, "How the Court got it wrong", Scribe's Aside (the real-world note, modern terms allowed), and Kett's margin notes. Reached from every puzzle through a bookmark tab; reading is free. Each sub-chapter has at least one live mini-widget (shift wheel, frequency histogram, IoC gauge, XOR beads).

## Structure of Act I
| # | Sub-chapter | Puzzle | Technique | Tool(s) |
|---|---|---|---|---|
| 1 | I.i The Raven's Wheel | The First Letter | Caesar, idea of a key | Cipher Wheel |
| 2 | | The Rusted Wheel | Caesar by frequency (costed brute force) | Cipher Wheel, Tally Scroll |
| 3 | | Thirteen Turns | ROT13 vs Atbash, Kerckhoffs | Cipher Wheel (modes) |
| 4 | I.ii The Steward's Alphabet | The Tithe Roll | Monoalphabetic substitution by frequency | Substitution Board, Tally Scroll |
| 5 | | The Signature | Cribs / known plaintext | Substitution Board, Crib strip |
| 6 | | Bigrams in the Marsh | Bigrams and trigrams | Substitution Board, Tally Scroll (n-grams) |
| 7 | I.iii The Many-Toothed Key | The Steward Grows Clever | Vigenere, known period | Multi-Wheel, Tally Scroll |
| 8 | | Kasiski's Lens | Kasiski examination | Kasiski Lens, Multi-Wheel |
| 9 | | The Loom of Columns | Index of coincidence | Column Loom, Multi-Wheel |
| 10 | | Bit Rosary | Bytes, XOR, single-byte XOR scoring | Bit Rosary, Key Dial |
| 11 | | The Litany Key | Repeating-key XOR, Hamming distance | Hamming Comb, Key Dial |
| 12 | | BOSS: The Twice-Used Pad | Two-time pad, crib-dragging | Crib Dragger |

After #12: the act's big choice, its consequence, the Marquise's last word, the chapter folio, and the "To be continued: Act II, *The Stained Glass*" card.

## Choices and flags
- End of I.i: drain the captured courier (-35 Thirst, `courier_drained`) or let him go with a doctored letter and drink Kett's pig's blood (-12, `courier_spared`).
- End of I.ii: drink from the informant Wenna's offered wrist (-30, `drank_wenna`) or refuse (-5, `refused_wenna`).
- End of I.iii: warn Hollowmere and burn the Order's trust (`act1_warned`) or stay silent to hunt the traitor (`act1_silent`).
- Frenzies set `frenzy_count` and `frenzied_<subchapter>`. Later lines branch on these flags.

## Feel
Touch-first: drag the outer ring of a wheel with inertia and detents, drop tiles into magnetic slots, flip beads, slide crib strips. Haptic ticks (toggleable). Undo on every tool that changes state (50 steps).

## Tone
Candlelit vellum, iron-gall ink, blood-red rubrication, tarnished gold. Grim and funny. See `.claude/skills/grimdark-voice/SKILL.md`.
