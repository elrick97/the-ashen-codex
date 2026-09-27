# Crypto Accuracy Audit: The Ashen Codex, Act I

Independent audit following `.claude/skills/crypto-accuracy-check/SKILL.md`. Report only; nothing was fixed.

## Summary

The crypto core is sound. Every primitive I re-implemented independently in Python matched the game's code and the reference values: PCG32 (the published `pcg32_srandom(42, 54)` stream), Caesar, ROT13, Atbash, Vigenere, IoC, the Hamming distance of 37, English byte scoring, crib consistency, modmath, the Heys-style toy SPN (0x5db5 and 0xe0bb), CBC/ECB/PKCS#7 and the Davies-Meyer toy hash (0x2e79 and 0xb05e). The unit suite passes (58 tests, 9589 asserts). The mode controllers judge commits correctly. No reference solver reads the key or the plaintext.

The problems are in what the game **teaches** and **promises**, compared with what the letters and tools actually do:

1. **The "read each column's tallest bar as E" lesson fails.**
   - P07: it fails on 3 of 5 columns for every key in the pool. The plaintext columns peak on T, O and N, not E.
   - P09: it fails on about half the columns.
   - P08: it fails on 1 to 4 columns, depending on the key.

   The brief, the hints and the anti-cheese note all promise that it works. The reference solvers use chi-squared over the whole letter profile instead, so the solver tests never exercise the technique the player is taught.
2. **P07 hint 3 is false.** It says the Tally Scroll "will tell you the moment a column reads true". The scroll shows ciphertext column counts, and those never change when a drum turns.
3. **P09's premise is false.** Its brief, UI line, hint 1 and anti-cheese note say the letter is too short for Kasiski and that "nothing repeats". The ciphertext has genuine repeats. Kasiski gives the right period for VEIL (4), and a usable multiple for ASHES and GRIEF (10).
4. **Several hints and Codex lines overstate a heuristic:**
   - "a repeat is never an accident"
   - "the smallest Hamming score is the key size" (it is a multiple for 2 of the 4 P11 keys)
   - "wrong column counts look random" (multiples of the key length look like English too)
   - a Kasiski example that picks 4 from a single gap of 8
   - "a Caesar key space measures a cipher's true strength"
5. **Smaller issues:**
   - P03 hint 3 all but quotes the correct answer to the concept question.
   - The XOR Codex page calls a 1-bit "lit", but its own bead widget draws a 1 as a dark bead.
   - P05 is called a "short letter". At 375 letters with word breaks it is not short; it is skewed so that O beats E.
   - A Marquise line calls a liturgy "a fine key".
   - A handful of arithmetic and docstring slips.

Counts are at the end of the report.

## Method and environment notes

- **Reference checks:** independent Python re-implementations in `.tools/audit_core.py`, `.tools/audit_a.py` and `.tools/audit_b.py` (gitignored scratch). I wrote them from the reference descriptions without reading the project's `tests/reference/crypto_ref.py`.
- **Keys:** puzzle keys were derived with my own PCG32 port. For Vigenere and XOR I tested every word or phrase in each pool, not only the seeds the solver tests use.
- **Commands run:**
  - `./tools_dev/run_tests.sh unit`: 58/58 pass. The script also runs `tools_dev/build_strings.py`, which regenerates the derived `content/i18n/strings.csv`.
  - `python3 tools_dev/check_letters.py`: 0 failing.
- **Concurrent edits:** another process was editing the repo during the audit.
  - `content/i18n/src/modes.csv`, `core/puzzle_modes/puzzle_mode.gd` and `core/puzzle_modes/xor_rosary_mode.gd` changed at 18:37. I re-read them: new `UI_ROSARY_EQ1/EQ2` strings and layout changes, with no effect on judging.
  - `tools.csv` changed `UI_CRIB_PIN`, which makes no claim.
  - This audit reflects the tree as of about 18:40 on 2026-09-27.
- **Plaintext length guidelines are heuristics** (skill file). The solver tests remain the final word on solvability. Where a guideline and a claim in the text disagree, I report the claim.

---

## core/crypto/

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| text_util.gd | `normalize`, `letters_only`, `group`, `letter_indices`, `indices_to_string`, `letter_count` | OK | Match the TECH_DESIGN normalization table; unit tests pass. | |
| caesar.gd | `shift_code` / `encrypt` / `decrypt` / `all_decryptions` (26 keys) | OK | posmod wrap, case kept, non-letters pass through. Python port agrees: VENI VIDI VICI +3 = YHQL YLGL YLFL. | |
| caesar.gd | `rot13`, `atbash` (self-inverse, keyless) | OK | Port matches: THE ORDER READS gives GUR BEQRE ERNQF and GSV LIWVI IVZWH. | |
| caesar.gd | `shift_between(plain, cipher)` = encryption shift | OK | Consistent with `Frequency.shift_from_peak` and the Caesar mode's commit. | |
| substitution.gd | `is_valid_key`, `invert_key`, `encrypt`, `decrypt`, `decrypt_partial`, `mapping_for_text` | OK | Lower case handled with +32 on the table. Round trips pass in the unit tests. | |
| substitution.gd | `random_key(derangement=true)` | OK | Rejection sampling over Fisher-Yates gives a uniform derangement. | |
| substitution.gd | `keyspace_bits` about 88.38; `keyspace_exact` = 26! | OK | log2(26!) = 88.382; 26! = 403291461126605635584000000 (about 4.03e26). | |
| vigenere.gd | "Vigenere (Bellaso, 1553)"; key advances on letters only; `columns` / `interleave` | OK | ATTACKATDAWN + LEMON = LXFOPVEFRNHR (port). | |
| xor_ops.gd | `xor_bytes`, `xor_single`, `xor_repeating`, `transpose`, `untranspose` | OK | Correct indexing; cryptopals S1C5 vector passes in the unit tests. | |
| xor_ops.gd | `random_pad` docstring: "Random pad bytes (a one-time pad, if it is used once and kept secret)" | MISLEADING | Bytes come from PCG32, a deterministic 64-bit-seeded non-cryptographic PRNG. Shannon's perfect secrecy needs a truly random pad. | "Pseudo-random pad bytes from PCG32 (stands in for a one-time pad in the game; a real OTP needs truly random bytes)." |
| bytes_util.gd | `to_hex`, `byte_to_hex`, `to_base64`, `from_base64`, `byte_to_bits`, `bits_to_byte`, `to_printable` | OK | Standard alphabet and padding; MSB-first bits. | |
| bytes_util.gd | `from_hex` docstring "whitespace ignored" | WRONG | Only leading/trailing whitespace, spaces and `\n` are removed. An internal tab or `\r` makes it return empty. Low impact. | Strip all whitespace, or document "spaces and newlines ignored". |
| rng.gd | `Pcg32` `next_u32`, `reseed` | OK | Port reproduces a15c02b7 7b47f409 ba1d3330 83d2f293 bfa4784b cbed606e. Multiplier limbs = 0x5851F42D4C957F2D. `_mul` partial sums stay below 2^35. | |
| rng.gd | `next_int` (unbiased), `range_int`, `next_float`, `shuffle`, `pick` | OK | Threshold (2^32 - b) mod b matches the reference `-bound % bound`. Fisher-Yates is correct. | |
| modmath.gd | `gcd`, `mulmod` (double-and-add, m <= 2^62), `modpow`, `egcd`, `modinv`, `crt` | OK | Intermediates stay below 2^63 (result + x < 2*2^62). Python pow agrees: 4^13 mod 497 = 445; RSA 3233 round trip; 17^-1 mod 3120 = 2753. CRT product bound checked before multiplying. | |
| bigint.gd | Interface only; 24-bit limbs | OK | Consistent with CURRICULUM Act IV (the "open decision"). | |
| block_cipher.gd | "Structure follows Heys' SPN tutorial": 16-bit block, 4 rounds, Heys S-box, bit transposition, final whitening | OK | S-box = Heys (E 4 D 1 2 F B 8 3 A 6 C 5 9 0 7). The transposition is its own inverse. My port gives enc(0x1234, 0xDEADBEEF) = 0x5db5 and enc(0, 0) = 0xe0bb, same as the unit test. Decrypt is the exact inverse. Note: Heys uses independent subkeys; the 4-bit-offset schedule here is the project's own and is documented as such. | |
| modes.gd | `pkcs7_pad` / `pkcs7_unpad` (the yes/no oracle); `ecb_encrypt`; `cbc_encrypt` | OK | Correct PKCS#7 for block = 2; ECB leaks repeats, CBC chains. | |
| modes.gd | `ecb_decrypt`, `cbc_decrypt` | WRONG | `range(0, data.size() - 1, 2)` silently drops a trailing odd byte. `pkcs7_unpad` then checks the truncated plaintext, so an odd-length (malformed) ciphertext can return `ok: true`. A padding oracle must reject non-block-multiple input. Low impact today (Act II stub). | Return `{ok: false}` when `data.size() % BLOCK_BYTES != 0`. |
| hash_toy.gd | Merkle-Damgard + Davies-Meyer `h_i = E_{m_i}(h_{i-1}) xor h_{i-1}`; `md_pad`; `digest` | OK | Port gives digest("") = 0x2e79 and digest("TITHE") = 0xb05e, as the tests expect. | |
| hash_toy.gd | "a birthday search finds a collision after roughly 2^8 = 256 tries" | OK | Expected first collision is about sqrt(pi/2 * 2^16), roughly 321. "Roughly 2^8" is fair. | |

## core/crypto/analysis/

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| frequency.gd | `ENGLISH` table (Lewand 2000); E 12.702, T 9.056, A 8.167... | OK | Sums to 0.99999; order ETAOINSHRDLCUMWFGYPBVKJXQZ. Matches the reference facts. | |
| frequency.gd | `COMMON_BIGRAMS` (TH HE IN ER AN...), `COMMON_TRIGRAMS` (THE AND ING...) | OK | Match the reference facts. | |
| frequency.gd | `counts`, `proportions`, `ranked` (ties alphabetical), `peak`, `chi_squared` | OK | Standard definitions. | |
| frequency.gd | `shift_from_peak` (peak = E), `shift_by_chi_squared` | OK | Both return the encryption shift, consistent with `Caesar.shift_between`. Note: chi-squared is much more robust than peak-as-E on short columns; see the P07/P09 findings. | |
| frequency.gd | `ngram_counts` (within words or letters-only), `top_ngrams` | OK | | |
| english_score.gd | `score_bytes`, `gauge`, `best_single_byte_key` | OK | Port recovers every allowed P10 key (65..250 except 96) on the P10 letter, and every column of every P11 key. | |
| english_score.gd | Docstring: "mean log-probability per byte under a simple English character model" | MISLEADING | The table is not a probability distribution: upper and lower case each get 0.76 x freq, and the whole table sums to about 1.74. It works as a score. | "Mean log-weight per byte (an unnormalized English character score)." |
| english_score.gd | `fitness` (quadgrams), `trigram_logp`, `quadgram_table`, `_ensure_ngrams` | OK | log10 tables from 6 Gutenberg texts (`tools_dev/build_ngrams.py`); a floor is applied to unseen quadgrams. | |
| index_of_coincidence.gd | IC = sum n_i(n_i-1)/(N(N-1)); English about 0.066; random 1/26; normalized x26 | OK | Matches the reference; ATTACKATDAWN gives 0.1364. | |
| index_of_coincidence.gd | `average_column_ic`, `by_period`, `likely_period` (smallest period >= 0.058) | OK | Port picks the true period for all 4 P09 keys (VEIL 4, ASHES 5, GRIEF 5, EMBERS 6). | |
| hamming.gd | `popcount`, `distance`, `distance_str` | OK | hamming("this is a test", "wokka wokka!!!") = 37. | |
| hamming.gd | `normalized_distance` (adjacent block pairs / k, averaged), `keysize_scores`, `likely_keysize` | OK | Matches the reference procedure. Returns a multiple of the key size for 2 of 4 P11 keys (33 for an 11-byte key, 28 for 14). The mode accepts multiples, so solvability holds; the text claims are addressed below. | |
| kasiski.gd | "published 1863"; `find_repeats` (drops repeats wholly inside a longer repeat), `spacings`, `factors`, `factor_tally` | OK | Port reproduces the logic. | |
| kasiski.gd | `likely_period` (largest factor with tally >= 0.8 of the best) | OK | Heuristic. Correct for all 5 P08 keys (6, 6, 6, 7, 7). | |
| crib.gd | `substitution_fits` / `_mapping` / `_letter_status` / `_positions` (one-to-one consistency, non-letters must match) | OK | Fit depends only on the plaintext's letter pattern, not the key. The P05 crib fits at exactly one offset (445), for both the full and the short crib. | |
| crib.gd | `drag` (stream xor crib), `is_plausible_upper` | OK | C1 xor C2 = P1 xor P2; a correct crib yields the other letter. | |

## core/game/puzzle_factory.gd

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| puzzle_factory.gd | `build`: seeded PCG32(seed_for_variant, def.number); frenzy overrides merged | OK | Deterministic; unit and solver tests check this. | |
| puzzle_factory.gd | `make_key` shift 3..23 | OK | Excludes 0 and near-trivial shifts. | |
| puzzle_factory.gd | `make_key` scheme_mix (forces both schemes when there are 2 or more letters) | OK | P03 always mixes ROT13 and Atbash. | |
| puzzle_factory.gd | `make_key` perm (derangement), word, phrase | OK | | |
| puzzle_factory.gd | `make_key` byte (min/max/exclude) | OK | Code is correct. The rationale for excluding 96 is questioned under a1_p10.tres. | |
| puzzle_factory.gd | `_build_rosary`: stage-1 letters a != b, stage-2 key a xor b | OK | The key is never 0. | |
| puzzle_factory.gd | `_build_two_time_pad`: one PCG32 pad, uniform bytes via `next_int(256)`, XORed into both letters; targets must lie inside the overlap | OK | The same pad is reused by construction (the lesson). Note: C1 xor C2 does not depend on the pad, so every variant of P12 is the same puzzle; the solver test says so. | |

## content/puzzles/*.tres (anti_cheese notes and parameters)

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| a1_p01.tres | Free wheel preview is the lesson; 25 non-trivial shifts | OK | 292 letters. Brute force by eye is the intended attack. | |
| a1_p02.tres | Notches and "read as E" cost 1 (2 after a frenzy); one "read as E" usually lands the key; eyeballing averages about 6-13 trials, "up to 25" | OK | The peak is E in the plaintext (48 E vs 29 T), so peak-as-E is right for every variant (checked v0-v9). `turn_to` does not charge notches. Nit: the key is at most 23, so at most 23 notches in one direction. | "up to 23" |
| a1_p03.tres | Free preview deliberate; the seal needs every note read and the concept answer; wrong seals cost 8 | OK | `keyless_mode.commit` checks every reading, then the question (index 2 = "Nothing, once the trick itself is known"). | |
| a1_p04.tres | 26! keys; the preview shows only placed letters; wrong full seal costs 8 | OK | 913 letters, E is the top letter, THE appears 25 times. | |
| a1_p05.tres | "Short letter: single-letter counts are ambiguous... After a frenzy only 'YOUR SERVANT' survives the blood, so fewer letters are pinned" | MISLEADING | 375 letters with word breaks, above the 150-250 guideline for frequency plus word patterns. What makes counts ambiguous is the engineered skew (O 43 > E 41), not length. The short crib pins 10 letters against 11, only one fewer. `test_p05_frequency_alone_is_ambiguous` compares against pure rank mapping, which fails even on long texts, so it does not show the letter is too short. | "Skewed letter: O outnumbers E, so the tallest bar misleads." Consider a shorter letter (<150 letters) if "short" is the intent. |
| a1_p06.tres | "single-letter counts are flattened by the E-sparing clerk, so the Letters tab misleads. Only pairs/triples anchor the alphabet" | MISLEADING | Counts are not flat. T is a strong peak (27/174 = 15.5%) and E is suppressed (12, 6.9%). "Misleads" is right, "flattened" is not. The claim that only pairs and triples suffice is not demonstrated: the reference solver uses quadgram hill-climbing plus dictionary segmentation (see tests/solvers). | "E is suppressed, so the tallest bar (T) misleads; the pairs TH/HE and triple THE still anchor..." |
| a1_p07.tres | "the preview never reads as English until all five are right... The per-column Tally Scroll plus 'read as E' sets each drum for 1 Thirst" | WRONG | Plaintext columns peak on T (col 0), O (col 1), E, N (col 3), E. Peak-as-E is right for only 2 of 5 columns, for every key in the pool (ASHEN, RAVEN, THORN, GRAVE, EMBER), because the column text does not depend on the key. A player following the note spends Thirst on 3 wrong "read as E". Also, with 4 of 5 drums right, 80% of the letters read correctly. | Rewrite the letter so each column (about 40 letters) peaks on E, or teach "match the whole profile" (the Tally overlay) instead of peak-as-E. Drop "never reads as English". |
| a1_p08.tres | "Unknown period: without it the column tallies are mush... Kasiski spacings on the free lens give the period" | MISLEADING | Kasiski works (period correct for all 5 keys; 22-52 genuine repeats). But the period stepper and per-column tallies are free (`multi_wheel._set_period_player`, `vigenere_mode._update_tally`). A player can step N and eyeball which N gives peaked column tallies, an informal IoC, without the lens. | Acknowledge that the free stepper allows eyeballing, or charge for period changes. |
| a1_p09.tres | "Too short and too varied for Kasiski. The free Column Loom's IoC vial finds N; notches still cost, so guessing periods on the drums is expensive" | MISLEADING | IoC finds N for all 4 keys. But the ciphertext has genuine repeats: VEIL has BSZ at 14, 22, 90, 130 (all spacings multiples of 4) and BSDW at 142, 166, and Kasiski gives 4. ASHES and GRIEF give 10, a multiple the mode accepts. EMBERS gives 3. Period changes are free, as for P08. | "Kasiski is unreliable here (few repeats); the loom is faster." Or shorten or rewrite the letter until no trigram repeats for any pool key. |
| a1_p10.tres | "Keys that merely flip letter case (0x20) are excluded so no key reads as English by accident" (`exclude: [96]`) | MISLEADING | Key 0x20 (32) is already outside 65..250. It is the key under which the ciphertext itself reads as case-flipped English. The excluded 96 (0x60) has no such property: its ciphertext is 25% printable and scores -12.2. For any key K, dialing K xor 0x20 flips case and turns spaces into NUL, which scores badly, so the true key always wins (checked all 186 keys). | State the real reason for 96, or remove it; note that min 65 already rules out 0x20. |
| a1_p11.tres | "a strand... never reads as text on its own; only the per-strand English gauge finds each byte... with the wrong size no dial setting scores well" | MISLEADING | Multiples of the key size score as well as the true size and are accepted by the commit. The comb's minimum is 33 for NOX AETERNA and 28 for SALT AND ASHES. The byte grid shows the full interleaved decryption live, so once most dials are set, the rest can be read from context. | "With a size that is not a multiple of the key length..." and acknowledge the context preview. |
| a1_p12.tres | No preview of either letter; readable text appears only under a correct crib; wrong pin costs 4; needs chained guesses | OK | Only C1 xor C2 is shown; pins are judged against the true plaintext; both targets lie inside the 207-byte overlap. | |

## core/puzzle_modes/

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| puzzle_mode.gd | `spend_trial` charges only when `brute_force_costed` | OK | | |
| caesar_mode.gd | Commit: `wheel.shift == key`; "read as E" charges one trial and turns without notch charges | OK | Key range 3..23, so no alternative correct shift. | |
| keyless_mode.gd | Commit: each note's reading == plaintext, then the question (correct index 2) | OK | Shift 13 or Mirror are the only settings that read a note correctly. | |
| substitution_mode.gd | Commit: decrypt_partial(cipher, mapping) == normalized plaintext; the preview shows only placed letters; the crib pins only at consistent offsets (free) | OK | Pinning at a wrong offset is impossible, because `substitution_mapping` returns {} there. | |
| substitution_mode.gd | Tally n-gram tabs give only the top 8 bigrams/trigrams (P06) | OK | Relevant to the P06 solver finding. | |
| vigenere_mode.gd | Commit: decrypt(cipher, drums) == plaintext (multiples of the period accepted) | OK | Matches TECH_DESIGN section 5. | |
| vigenere_mode.gd | Per-column tally = ciphertext column counts; unaffected by drum settings | OK | The behaviour is fine; it contradicts PZ_P07_HINT3. | |
| xor_rosary_mode.gd | Stage 1 (a xor k == b), stage 2 (two pours), stage 3 dial == key | OK | Re-read after the concurrent edit; the new EQ1/EQ2 lesson lines do not reveal the key. | |
| xor_repeating_mode.gd | Commit: xor_repeating(cipher, dials) == plaintext; per-strand gauge | OK | Multiples accepted. | |
| two_time_pad_mode.gd | Pins judged against the true letter bytes; wrong pin charged; commit needs every target byte known | OK | Plaintext bytes are never 0, so 0 is a safe "unknown" marker. | |

## tests/solvers/

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| reference_solvers.gd | Header: "see only what the player sees... never the key or plaintext" | OK | No solver reads `inst.key`, `plaintexts` or `plain_bytes`; the tests compare afterwards. | |
| reference_solvers.gd | `solve_p01` brute force by quadgram fitness; `solve_p02` peak = E; `solve_p03` try both schemes | OK | Intended techniques. | |
| reference_solvers.gd / solver_lib.gd | `solve_p04`: frequency start, quadgram hill-climb, word-list polish | OK | Statistical substitution attack; stronger than the player's board but the same family (frequency plus word patterns). | |
| reference_solvers.gd | `solve_p05`: crib positions, pin mapping (last position), then statistics | OK | The crib fits at exactly one offset (checked independently), so choosing the last is harmless. | |
| reference_solvers.gd / solver_lib.gd | `solve_p06` "n-gram statistics... only multi-letter structure such as TH, HE, THE" | MISLEADING | It calls `solve_substitution(c, {}, false, 40)`: quadgrams, not trigrams (the `use_trigrams` flag the SolverLib docstring calls "the Bigrams-in-the-Marsh lesson" is off). It also starts from a single-letter frequency ranking and finishes with dictionary segmentation. Passing does not show that the player's top-8 bigram/trigram tabs suffice. | Add a solver restricted to bigram/trigram evidence (for example, anchor TH/HE/THE from `top_ngrams` then hill-climb on trigrams), or document that the solver is stronger than the lesson. |
| reference_solvers.gd / solver_lib.gd | `solve_p07`/`p08`/`p09` column step: `vigenere_shifts` = chi-squared per column | MISLEADING | The game teaches peak-as-E per column (costed "read as E", P07 brief and HINT2, P09 HINT3, P08 HINT3). Peak-as-E fails on 3/5 columns in P07 (all keys), 2/4 to 3/6 columns in P09 and 1/6 to 4/7 in P08. Chi-squared succeeds on all. The tests therefore never catch that the taught technique fails. | Add a peak-as-E solver test for P07 (and P08/P09 if peak-as-E stays in the hints), or change the teaching to profile matching. |
| reference_solvers.gd | `solve_p08` Kasiski; `solve_p09` IoC; `solve_p10` XOR law plus English scoring; `solve_p11` Hamming then columns | OK | Independent ports agree on every pool key. | |
| crib_drag_solver.gd / reference_solvers.gd | `solve_p12`: crib-dragging only; vocabulary = story words read before P12 plus an English list | MISLEADING | It never touches the pad or plaintext. But `_reads_true` rejects `- : ! ?` as noise, a prior matching the letters' punctuation exactly. LTR_P12_B writes "Casimir Morrow Veil" without the hyphen used everywhere else (including its own sender line), which suggests the plaintext was edited to suit the filter. A player has no such guarantee. ANSGAR in the vocabulary is fair: it is in DLG_A1_I_INTRO_14 and DLG_A1_III_INTRO_09. | Document the punctuation prior as a known assumption, or allow `-` and restore "Morrow-Veil" in LTR_P12_B and confirm the solver still passes. |
| test_solvers.gd | Variants 0-4 plus frenzy per puzzle; P08 accepts multiples; P09 asserts >= 25 letters per column; P11 >= 4 blocks at size 40 | OK | Heuristics correctly encoded. (See the P05 row above on the weak rank-mapping evidence.) | |

## content/i18n/src/a1_i.csv (Codex, hints, briefs, Marquise)

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| a1_i.csv | PZ_P01_BRIEF, PZ_P01_HINT1..3 | OK | True; HINT3 names no shift. | |
| a1_i.csv | PZ_P02_BRIEF, PZ_P02_HINT1..3 | OK | The tallest bar is E in every variant; HINT3 names no shift. | |
| a1_i.csv | PZ_P03_BRIEF, PZ_P03_HINT2, PZ_P03_Q, PZ_P03_A1..A3 | OK | ROT13 adds 13 and is self-inverse; Atbash reverses the alphabet; A3 is correct. | |
| a1_i.csv | PZ_P03_HINT1 "Three notes, three little tricks. Look for one that never changes a letter's shape, only its place in the alphabet." | WRONG | The key rule uses only two schemes; UI_MODE_KEYLESS correctly says "two vanity schemes". The second sentence fits neither scheme meaningfully. | "Three notes, only two tricks between them. One walks every letter thirteen places; the other mirrors the alphabet." |
| a1_i.csv | PZ_P03_HINT3 "...ask yourself plainly what is left to hide once the trick itself is known. Answer that, and seal." | WRONG | Tier 3 must not reveal the final answer. It paraphrases the correct choice PZ_P03_A3 ("Nothing, once the trick itself is known") almost word for word. | "Read each note with the scheme that fits, then ask which of the three answers would still hold if the Order knew every trick the Court uses." |
| a1_i.csv | CDX_A1_KEY_BODY | OK | Algorithm/key separation stated correctly. | |
| a1_i.csv | CDX_A1_KEY_EXAMPLE "key = shift 3 (Suetonius)... VENI VIDI VICI / YHQL YLGL YLFL" | OK | Verified. | |
| a1_i.csv | CDX_A1_KEY_WRONG, CDX_A1_KEY_M2 | OK | | |
| a1_i.csv | CDX_A1_KEY_ASIDE "the same idea underlies AES and password hashing, where the method stays public and only the key stays secret" | MISLEADING | Password hashing has no key: the algorithm and the salt are public and the secret is the password. | "...AES and HMAC, where the method is public and only the key is secret." |
| a1_i.csv | CDX_A1_KEY_M1 "Twenty-six letters, one number. Lose the number and you've lost nothing worth losing; lose the key and you've lost everything." | MISLEADING | In a Caesar cipher the number is the key; the line contradicts itself and the entry's own lesson. | "Lose the wheel and you've lost nothing worth losing; lose the number and you've lost everything." |
| a1_i.csv | CDX_A1_KEYSPACE_BODY "...twenty-five worth trying... Any cipher's true strength is measured by how large and how searchable its key space is, not by how clever its rule looks." | MISLEADING | The 25 figure is right, but the conclusion overclaims. The very next lesson (26! keys, broken by frequency) shows a large key space is necessary, not sufficient. CDX_A1_KEYSPACE_M2 even says so. | "A small key space is fatal; a large one is only the first requirement." |
| a1_i.csv | CDX_A1_KEYSPACE_EXAMPLE (FRGH shift 3 = CODE; shift 1 = EQFG) | OK | Verified. | |
| a1_i.csv | CDX_A1_KEYSPACE_WRONG, _M1, _M2 | OK | | |
| a1_i.csv | CDX_A1_KEYSPACE_ASIDE "128-bit AES key... about 3.4 x 10^38... under 5 bits, smaller than one password character" | OK | 2^128 = 3.40e38; log2 26 = 4.70 bits vs 6.57 for one printable-ASCII character. (A single random lowercase letter is exactly 4.70, so "no bigger than" would be safer.) | |
| a1_i.csv | CDX_A1_FREQUENCY_BODY (E 12.7, T 9.1, A 8.2; al-Kindi, 9th century) | OK | Matches the reference. Consider "the earliest known description" (the skill's wording) over "first described". | |
| a1_i.csv | CDX_A1_FREQUENCY_EXAMPLE (J tallest, J = E + 5, so shift 5) | OK | Verified. | |
| a1_i.csv | CDX_A1_FREQUENCY_WRONG, _ASIDE | OK | | |
| a1_i.csv | CDX_A1_FREQUENCY_M1 "The tallest bar in the tally never lies to you, boy." | MISLEADING | The next puzzles are built on the tallest bar not being E: P05 (O > E), P06 (T), P07 columns (T, O, N). | "The tally never lies, boy. Your reading of it might." |
| a1_i.csv | CDX_A1_FREQUENCY_M2 "This trick only breaks shifts and swaps. Anything cleverer scrambles the tally too" | MISLEADING | The same tally attack breaks each Vigenere column (P07-P09) and single-byte XOR (P10). | "Alone it breaks shifts and swaps; cleverer ciphers make you split the text first." |
| a1_i.csv | CDX_A1_KERCKHOFFS_BODY (1883; ROT13 13 + 13 = 26; Atbash self-inverse; no key) | OK | Matches the reference. | |
| a1_i.csv | CDX_A1_KERCKHOFFS_EXAMPLE | OK | Verified: GUR BEQRE ERNQF / GSV LIWVI IVZWH. | |
| a1_i.csv | CDX_A1_KERCKHOFFS_WRONG, _M1, _M2, _M3 | OK | | |
| a1_i.csv | CDX_A1_KERCKHOFFS_ASIDE (ROT13 on Usenet in the 1980s to hide spoilers) | OK | Matches the reference. | |
| a1_i.csv | Marquise: DLG_A1_VAULT_OPEN_02/04/06/08; DLG_A1_VAULT_I_01..06, _08 | OK | No cryptographic claims beyond narrative (VAULT_I_02 "same key for ninety years" is characterization). | |
| a1_i.csv | Marquise: DLG_A1_P02_REMARK_01 "Twenty-five shifts", _02 | OK | | |

## content/i18n/src/a1_ii.csv

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| a1_ii.csv | PZ_P04_BRIEF, PZ_P04_HINT1..3 | OK | E is the top letter (139/913); "a short three-letter word that keeps repeating" = THE (25). No key named. | |
| a1_ii.csv | PZ_P05_BRIEF, PZ_P05_HINT2, PZ_P05_HINT3 | OK | HINT3 points to the letter's end (the only fit) but does not reveal the key. | |
| a1_ii.csv | PZ_P05_HINT1 "This letter is too short for the tally scroll to save you." | MISLEADING | 375 letters with word breaks is above the guideline; the tally misleads because O (43) outnumbers E (41), not because the letter is short. | "The tally lies on this letter: its tallest bar is not E. Look instead at what a bureaucrat always writes." |
| a1_ii.csv | PZ_P06_BRIEF "this flattened cipher", PZ_P06_HINT1 "lies flat", CDX_A1_NGRAMS_BODY "flattens single-letter counts" | MISLEADING | Counts are not flat: T = 15.5% dominates, E = 6.9%. The letter suppresses E; it does not flatten the profile. | "E-starved" or "skewed" instead of "flattened". |
| a1_ii.csv | PZ_P06_HINT2, PZ_P06_HINT3 | OK | THE is the top trigram (9 vs 5); TH, HE are the top bigrams. | |
| a1_ii.csv | CDX_A1_SUBSTITUTION_BODY (26! about 4.03 x 10^26, 88 bits; frequency plus word shapes) | OK | Verified. | |
| a1_ii.csv | CDX_A1_SUBSTITUTION_EXAMPLE (THE STEWARD KEEPS THE ROLL / ZIT LZTVQKR ATTHL ZIT KGSS; E about 1 in 8) | OK | The mapping is consistent and one-to-one; 12.7% is about 1/8. | |
| a1_ii.csv | CDX_A1_SUBSTITUTION_WRONG, _M1, _M2 | OK | | |
| a1_ii.csv | CDX_A1_SUBSTITUTION_ASIDE (al-Kindi, 9th-century scholar in Baghdad; "first known account") | OK | Matches the reference (Baghdad is his documented base). | |
| a1_ii.csv | CDX_A1_CRIBS_BODY, _WRONG, _M1, _M2 | OK | | |
| a1_ii.csv | CDX_A1_CRIBS_EXAMPLE (YOURSERVANT / NGXKLTKCQFZ, 4th and 7th letters repeat) | OK | Letter patterns are identical (R at positions 4 and 7, K at 4 and 7; all others distinct). | |
| a1_ii.csv | CDX_A1_CRIBS_ASIDE (Bletchley cribs: weather reports, "nothing to report") | OK | Matches the reference. | |
| a1_ii.csv | CDX_A1_NGRAMS_EXAMPLE (THE 9 times / ZIT 9 times), _WRONG, _ASIDE, _M1, _M2 | OK | LTR_P06 has 9 "the"; THE is the top trigram. | |
| a1_ii.csv | Marquise: DLG_A1_P05_REMARK_02 "the same six words every time" and DLG_A1_VAULT_II_01 "the last six words of every letter he ever wrote" | MISLEADING | The crib the player is given is four words (YOUR SERVANT IN ETERNITY); with the name it is six. But LTR_P09 (Soll's) is signed only "Soll", and LTR_P04 continues past the name. Low severity, but it is the crib lesson itself. | "...the same four words, and his name after them, on nearly every letter." |
| a1_ii.csv | Marquise: DLG_A1_P05_REMARK_01, _04; DLG_A1_VAULT_II_03..06, _08 | OK | No false claims. | |

## content/i18n/src/a1_iii.csv

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| a1_iii.csv | PZ_P07_BRIEF "Find each column's peak and set the drums." | WRONG | For every pool key, only columns 3 and 5 of 5 peak on E (the plaintext columns peak on T, O, E, N, E; 39 letters each). | "Match each column's bars to English and set the drums." |
| a1_iii.csv | PZ_P07_HINT1 | OK | | |
| a1_iii.csv | PZ_P07_HINT2 "Read its tallest bar as E and the drum falls into place." | WRONG | Fails for 3 of 5 columns, for every key. | "Read its tallest bar as E; if the reading is nonsense, try the next-tallest as E, or match the whole shape of the bars." |
| a1_iii.csv | PZ_P07_HINT3 "Set one drum at a time and watch the scroll; it will tell you the moment a column reads true." | WRONG | The Tally Scroll shows ciphertext column counts (`vigenere_mode._update_tally`); it does not change when a drum turns and has no "reads true" signal. | "Set one drum at a time; each right drum makes every fifth letter of the preview fall into place." |
| a1_iii.csv | PZ_P08_BRIEF, PZ_P08_HINT2 | OK | | |
| a1_iii.csv | PZ_P08_HINT1 "Look for the same three letters showing up twice in a message this long. That is never an accident." | WRONG | Coincidental repeats occur: for MORROW, 5 of 31 spacings are not multiples of 6; for CANDLE, 9 of 35. The Codex itself says short repeats "can happen by pure chance". | "That is rarely an accident." |
| a1_iii.csv | PZ_P08_HINT3 "Take the common factor of your spacings, split the text into that many columns, then read each peak." | MISLEADING | Peak-as-E fails on 1 of 6 columns (MORROW/SHROUD/CANDLE) and 3-4 of 7 (VESPERS/REQUIEM). | "...then match each column's bars to English." |
| a1_iii.csv | PZ_P09_BRIEF "Too short for repeats to help." | MISLEADING | Repeats do help: Kasiski gives 4 for VEIL and 10 (a multiple, accepted) for ASHES and GRIEF. | "Too few repeats to trust. Slide the loom..." |
| a1_iii.csv | PZ_P09_HINT1 "Nothing repeats twice in a note this short." | WRONG | VEIL: BSZ x4, SZR x3, BSDW, BSZR, IBSZ, WVZO, GZV, IGZ repeat. ASHES: HWTE, WTZL, ZLR. EMBERS: ZPVKZ, KZIZ, KZME, KFI. | "The repeats in a note this short are too few to trust." |
| a1_iii.csv | PZ_P09_HINT2 | OK | Wrong widths give low column IC; multiples of the period also clump (see the IoC body). | |
| a1_iii.csv | PZ_P09_HINT3 "...then read each strand's tallest bar as E." | WRONG | Peak-as-E fails on 2/4 (VEIL), 3/5 (ASHES, GRIEF) and 3/6 (EMBERS) columns of 32-49 letters. | "...then match each strand's bars to English (or try the top few bars as E)." |
| a1_iii.csv | PZ_P10_BRIEF "Flip the beads that differ, then pour the byte twice to find the key." | MISLEADING | Pouring twice restores the word (stage 2); the stage-3 key is found by the dial and gauge, not by pouring. | "Flip the beads that differ, pour twice to see XOR undo itself, then dial the key." |
| a1_iii.csv | PZ_P10_HINT1..3 | OK | HINT3 describes the brute force plus scoring correctly; no key named. | |
| a1_iii.csv | PZ_P11_BRIEF, PZ_P11_HINT1, PZ_P11_HINT3 | OK | | |
| a1_iii.csv | PZ_P11_HINT2 "The size where they agree most is the key's length." | MISLEADING | For NOX AETERNA the best size is 33, and for SALT AND ASHES 28: multiples (still solvable, but more dials). | "...is the key's length or a multiple of it; try the smallest good tooth." |
| a1_iii.csv | PZ_P12_BRIEF, PZ_P12_HINT1..3; PZ_P12_CRIB_1..6 | OK | True. HINT3 reveals neither target; the tray does not contain ANSGAR. | |
| a1_iii.csv | CDX_A1_VIGENERE_BODY (Bellaso 1553, misattributed to Vigenere, "nearly three centuries") | OK | Matches the reference; qualifies "unbreakable". | |
| a1_iii.csv | CDX_A1_VIGENERE_EXAMPLE ATTACKATDAWN / LEMON / LXFOPVEFRNHR | OK | Verified. | |
| a1_iii.csv | CDX_A1_VIGENERE_WRONG, _ASIDE, _M1 | OK | ASIDE: a reused keystream is attacked column-wise, like Vigenere; fair. | |
| a1_iii.csv | CDX_A1_VIGENERE_M2 "the real fight was who wrote it first, some Italian or some Frenchman" | MISLEADING | There was no contest: Bellaso published in 1553, and the credit went to Vigenere through later misattribution. | "The real muddle was the name: an Italian wrote it, a Frenchman got the credit." |
| a1_iii.csv | CDX_A1_KASISKI_BODY (Kasiski 1863; Babbage about a decade earlier, unpublished) | OK | Matches the reference; "trust trigrams and longer" is right. | |
| a1_iii.csv | CDX_A1_KASISKI_BODY "so his name waited a century for credit" | UNVERIFIED | Not in the reference list. Babbage's work was brought to light in the 20th century (commonly credited to Ole Franksen's research, published 1985), which is plausible but not verified here. | Keep, or soften to "waited long for credit". |
| a1_iii.csv | CDX_A1_KASISKI_EXAMPLE "BPU repeats at 22 and 30 / gap = 8 = 2 x 4 / try a key length of 4" | MISLEADING | The 33-letter CT has exactly one trigram repeat (checked), and a single gap of 8 supports 2, 4 and 8 equally. It contradicts the body's "trust a pattern that shows up more than once". | Add a second repeat with a gap of, for example, 12 so 4 is the common factor, or say "try 2, 4 or 8". |
| a1_iii.csv | CDX_A1_KASISKI_WRONG, _ASIDE, _M1, _M2 | OK | | |
| a1_iii.csv | CDX_A1_IOC_BODY (formula, 0.066-0.067 vs 0.038, Friedman 1922) | OK | Matches the reference. | |
| a1_iii.csv | CDX_A1_IOC_BODY "Split... into the wrong number of columns and each column still looks random. Split it into the right number, matching the key's length..." | MISLEADING | Multiples of the key length also look English: P09 VEIL at 8 = 0.070 and 12 = 0.068; ASHES at 10 = 0.079 (higher than at 5). | "...wrong number... looks random, unless that number is a multiple of the key's length; take the smallest width that looks like English." |
| a1_iii.csv | CDX_A1_IOC_EXAMPLE (ATTACKATDAWN: (12+6)/(12x11) = 0.136), _WRONG, _ASIDE, _M1, _M2 | OK | Verified. | |
| a1_iii.csv | CDX_A1_XOR_BODY "XOR... lights the result only when exactly one of them was lit; two dark or two lit beads both go dark" | MISLEADING | Truth table correct, but it makes lit = 1. The page's own widget (`xor_beads` uses BitRosary: "a dark bead is a 1") and UI_COACH_BIT_ROSARY ("Dark is one, pale is nought") make dark = 1. | Align on one convention, for example "a dark bead is a 1... darkens the result only when exactly one of them was dark". |
| a1_iii.csv | CDX_A1_XOR_EXAMPLE, _WRONG, _ASIDE, _M1, _M2 | OK | A = 01000001; A xor A = 0; A xor 0 = A. | |
| a1_iii.csv | CDX_A1_SINGLE_XOR_BODY (256 keys; score by English-likeness; "a Caesar cipher wearing bytes") | OK | Correct; the Caesar analogy is structural (one fixed key over the whole message). | |
| a1_iii.csv | CDX_A1_SINGLE_XOR_EXAMPLE MEET AT DUSK xor 0x2B = 666E6E7F0B6A7F0B6F7E7860 | OK | Verified. | |
| a1_iii.csv | CDX_A1_SINGLE_XOR_WRONG, _M2 | OK | | |
| a1_iii.csv | CDX_A1_SINGLE_XOR_ASIDE "a standard first exercise in modern cryptography training" | UNVERIFIED | Plausible (for example, cryptopals set 1), but not in the reference list. | |
| a1_iii.csv | CDX_A1_SINGLE_XOR_M1 "Two hundred fifty six keys. Count them on your fingers forty times" | WRONG | 256 / 10 fingers = 25.6 passes, not forty. | "...twenty-six times..." |
| a1_iii.csv | CDX_A1_REPEATING_XOR_BODY (Hamming, normalize by size, average pairs, transpose) | OK | Matches the reference procedure. | |
| a1_iii.csv | CDX_A1_REPEATING_XOR_BODY "The key size giving the smallest normalized distance is usually the true one" | MISLEADING | In this game it is a multiple for 2 of 4 pool keys (33 for 11, 28 for 14). | "...is usually the true one or a multiple of it." |
| a1_iii.csv | CDX_A1_REPEATING_XOR_EXAMPLE (37 bits), _WRONG, _ASIDE, _M1, _M2 | OK | 37 verified. | |
| a1_iii.csv | CDX_A1_OTP_BODY (four conditions; key cancels; crib-dragging; Shannon 1949; Soviet reuse) | OK | Matches the reference; "unbreakable" is qualified. | |
| a1_iii.csv | CDX_A1_OTP_EXAMPLE, _WRONG, _M1, _M2 | OK | | |
| a1_iii.csv | CDX_A1_OTP_ASIDE (VENONA 1940s; nonce reuse in stream ciphers and AES-GCM, forgeries) | OK | Matches the reference. | |
| a1_iii.csv | CDX_A1_OTP_M3 "it only worked because the Soviets got lazy first" | MISLEADING | The reuse came from duplicated pad pages produced under wartime pressure (early 1940s), not simple laziness. The "only worked because of reuse" part is right. | "...because Soviet pad-makers, pressed by the war, printed some pages twice." |
| a1_iii.csv | Marquise: DLG_A1_P08_REMARK_01, _02, _04 | OK | "a man who repeats himself can be timed" is a fair Kasiski metaphor. | |
| a1_iii.csv | Marquise: DLG_A1_P11_REMARK_01 "A liturgy makes a poor secret and a fine key." | MISLEADING | A well-known liturgical phrase is a guessable, low-entropy key: it is a poor key. The game's own lesson (the Litany Key falls) says the opposite of "fine key". | "A liturgy makes a poor key: every priest knows it, and it repeats by design." |
| a1_iii.csv | Marquise: DLG_A1_P11_REMARK_02; DLG_A1_VAULT_END_01, _03, _05, _07, _08, _09 | OK | Narrative; the "reuse" theme is stated correctly. | |

## content/i18n/src/tools.csv and modes.csv (tool and mode UI claims)

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| tools.csv | UI_TALLY_SELECTED, _TAP ("Counting is free"), _READ_E, _READ_E_COST, _GRAM_HELP, _IN_LETTER/_IN_ENGLISH/_THIS_LETTER/_ENGLISH | OK | Counting is uncosted in every mode; "English leans on TH, HE and THE" is right. | |
| tools.csv | UI_LOOM_N, _WEAVE, _RANDOM, _ENGLISH, _VIAL ("blood purity (IoC)") | OK | The vial is fed the average column IC. | |
| tools.csv | UI_COMB_SELECTED "%.2f differing bits per byte" | OK | The value is normalized by k: bits per byte. | |
| tools.csv | UI_COMB_TITLE "Average bits that differ between neighbouring blocks (shorter is better)" | MISLEADING | The bars are normalized per byte (see UI_COMB_SELECTED). Raw bits per block grow with k. | "Average differing bits per byte between neighbouring blocks (shorter is better)" |
| tools.csv | UI_COMB_TAP "The shortest tooth is the likeliest key size." | MISLEADING | For 2 of 4 P11 keys the shortest tooth is a multiple (33, 28). | "...the likeliest key size, or a multiple of it." |
| tools.csv | UI_COMB_GO, UI_COMB_GO_NONE | OK | | |
| tools.csv | UI_CRIB_HELP, UI_CRIB_FITS, UI_KASISKI_TRAY, UI_KASISKI_HOLD ("repeat of three or more letters") | OK | Matches `find_repeats(3, 8)`. | |
| tools.csv | UI_COACH_BIT_ROSARY "Dark is one, pale is nought" | OK | Matches the tool; conflicts with CDX_A1_XOR_BODY (reported there). | |
| tools.csv | UI_COACH_KASISKI_LENS "Repeats sit a key-length apart" | MISLEADING | Repeats sit a multiple of the key length apart. | "Repeats sit whole key-lengths apart." |
| tools.csv | UI_COACH_COLUMN_LOOM, UI_COACH_TALLY_SCROLL, UI_COACH_CRIB_DRAGGER, UI_COACH_HAMMING_COMB | OK | | |
| modes.csv | UI_MODE_CAESAR, UI_MODE_CAESAR_RUSTED, UI_MODE_KEYLESS ("two vanity schemes") | OK | | |
| modes.csv | UI_MODE_SUB, UI_MODE_SUB_CRIB, UI_MODE_SUB_NGRAMS ("E is hiding") | OK | P06 E is suppressed (6.9%). | |
| modes.csv | UI_MODE_VIG_PERIOD, UI_MODE_VIG_GIVEN, UI_MODE_VIG_KASISKI | OK | | |
| modes.csv | UI_MODE_VIG_IOC "Unknown key length and too short for Kasiski." | MISLEADING | See PZ_P09_HINT1: Kasiski yields 4 (VEIL) and 10 (ASHES, GRIEF). | "...and too few repeats to trust." |
| modes.csv | UI_MODE_ROSARY_1..3, UI_ROSARY_STAGE1/2, UI_MODE_REPXOR_SIZE/1/2, UI_MODE_OTP | OK | | |
| modes.csv | UI_WIDGET_SHIFT_HELP ("one setting, and only one") | OK | WKH EORRG LV RZHG -3 = THE BLOOD IS OWED; unique. | |
| modes.csv | UI_WIDGET_FREQ_HELP | OK | The widget sample peaks on E (25 vs T 15), so the demonstration holds. | |
| modes.csv | UI_WIDGET_IOC_HELP "at 4 (and 8) each strand is one Caesar of English and the vial thickens" | MISLEADING | Also 12 (0.080), within the slider's range. On this sample N = 2 also reads 0.065, English-like and above the solver's 0.058 threshold, so "smallest thick N" would pick 2. Minor: VEIL is also a live P09 pool key (the widget unlocks only after P09, so no leak). | Change the sample or key so N = 2 stays low, and mention "4, 8 and 12". |
| modes.csv | UI_WIDGET_XOR_HELP, UI_WIDGET_XOR_TWICE, UI_ROSARY_EQ1/EQ2 (new) | OK | | |

## content/i18n/src/common.csv (Act II-V placeholders)

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| common.csv | CDX_A2..A5 bodies, asides, margins (ECB repeats, small-hash collisions, public keys, nonce reuse, ZK) | OK | Correct at the stated level of detail. | |

## Letters: length heuristics (tools_dev/check_letters.py plus independent judgement)

`check_letters.py`: 0 failing. Independent counts below.

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| LTR_P01 | Caesar, >= 25 letters | OK | 292 letters. | |
| LTR_P02 | Caesar by frequency (peak = E) | OK | 260 letters; E 48 vs T 29. | |
| LTR_P03_A/B/C | Keyless; readable once the scheme is named | OK | 229/223/195 letters. | |
| LTR_P04 | Substitution by frequency plus word patterns, >= 150-250 | OK | 913 letters, word breaks kept. | |
| LTR_P05 | Crib puzzle; described as "short" | OK | 375 letters; the length itself is fine, but it contradicts the "short" claims (reported above). The crib fits exactly once. | |
| LTR_P06 | Substitution by n-grams, letters-only | UNVERIFIED | 174 letters, no word breaks, E suppressed. Inside the 150-250 band, but that band assumes word patterns. The solver passes only with quadgrams plus a dictionary; human solvability with top-8 bigram/trigram tabs is not demonstrated. | Playtest, or lengthen to about 250 letters. |
| LTR_P07 | Vigenere, period 5 given | OK | 197 letters, 39.4 per column (>= 25). Length OK; the peak-as-E failure is a content-design issue (reported above). | |
| LTR_P08 | Kasiski: >= about 20x key length with genuine repeats | OK | 458 letters (>= 140). Repeated litany; Kasiski is right for all 5 keys. | |
| LTR_P09 | IoC: >= about 25 per column | OK | 195 letters: 48.8/39/39/32.5 per column. The IoC period is right for all keys. (Has Kasiski-usable repeats, reported above.) | |
| LTR_P10 | Single-byte XOR | OK | 109 bytes; all 186 keys recovered by scoring. | |
| LTR_P11 | Repeating XOR: >= about 4 blocks per candidate size | OK | 654 bytes: 16 blocks at size 40. | |
| LTR_P12_A/B | Two-time pad; targets inside the overlap | OK | 209/207 characters, overlap 207; NIGHT at 45 (A), NAME at 60 (B). | |
| tools_dev/check_letters.py | Encodes the letter heuristics | OK | Correct as far as it goes. Gaps: it does not check per-column peak = E for P07 (the hints rely on it), trigram repeats in P09 (the text claims none), or per-column counts for P09. | Add those three checks. |

---

## All WRONG and MISLEADING findings, most severe first

1. **WRONG.** P07 peak-as-E fails on 3 of 5 columns for every key. Affects PZ_P07_BRIEF, PZ_P07_HINT2 and the a1_p07.tres anti_cheese note, which also claims "never reads as English until all five are right". Players following the lesson pay Thirst for wrong "read as E" presses.
2. **WRONG.** PZ_P07_HINT3 says the Tally Scroll will tell you when a column reads true. The tally shows ciphertext counts and never reacts to the drums.
3. **MISLEADING.** The Vigenere reference solvers (`SolverLib.vigenere_shifts`, used by P07-P09) use chi-squared, not the peak-as-E technique the game teaches. The solver tests therefore cannot catch items 1, 4 and 18.
4. **WRONG.** PZ_P09_HINT1 says "Nothing repeats twice in a note this short". The ciphertext has genuine multi-letter repeats; Kasiski yields 4 for VEIL and 10 for ASHES and GRIEF.
5. **MISLEADING.** P09 "too short for Kasiski". Affects PZ_P09_BRIEF, UI_MODE_VIG_IOC and the a1_p09.tres anti_cheese note, which also says guessing periods is expensive when the period stepper and per-column tallies are free.
6. **WRONG.** PZ_P09_HINT3 says "read each strand's tallest bar as E". It fails on 2/4 to 3/6 columns.
7. **WRONG.** PZ_P08_HINT1 says a repeated trigram "is never an accident". Coincidental spacings occur (5/31 for MORROW, 9/35 for CANDLE), and the Codex itself says so.
8. **WRONG.** PZ_P03_HINT3 (tier 3) paraphrases the correct concept-question answer (PZ_P03_A3), which breaks the rule that tier 3 never reveals the final answer.
9. **MISLEADING.** P05 is called "short". Affects PZ_P05_HINT1 and the a1_p05.tres anti_cheese note. At 375 letters with word breaks the tally fails because O > E, not because the letter is short. The frenzy crib pins only 1 letter fewer. The rank-mapping test is weak evidence.
10. **MISLEADING.** CDX_A1_KEYSPACE_BODY says a cipher's "true strength is measured by" key-space size. A large key space is necessary, not sufficient, as the next lesson (26!) shows.
11. **MISLEADING.** CDX_A1_IOC_BODY says a wrong column count "still looks random". Multiples of the key length look English too (0.070-0.079 in P09).
12. **MISLEADING.** CDX_A1_REPEATING_XOR_BODY says the smallest normalized distance is "usually the true one". Here it is a multiple for 2 of 4 keys (33, 28).
13. **MISLEADING.** The a1_p11.tres anti_cheese note says a wrong size never scores well and a strand never reads alone. Multiples score well, and the full interleaved preview gives context.
14. **MISLEADING.** PZ_P11_HINT2 says "the size where they agree most is the key's length". It can be a multiple.
15. **MISLEADING.** UI_COMB_TAP says "shortest tooth is the likeliest key size". It can be a multiple.
16. **MISLEADING.** CDX_A1_KASISKI_EXAMPLE picks key length 4 from a single gap of 8. That gap supports 2, 4 and 8 equally, and relying on one repeat contradicts the body's advice.
17. **MISLEADING.** DLG_A1_P11_REMARK_01 (Marquise) says "a fine key" of a liturgy. A predictable phrase is a poor key.
18. **MISLEADING.** PZ_P08_HINT3 says "read each peak". Peak-as-E fails on 1/6 to 4/7 columns.
19. **MISLEADING.** CDX_A1_XOR_BODY says lit = 1. The page's own bead widget, the BitRosary tool and UI_COACH_BIT_ROSARY use dark = 1.
20. **MISLEADING.** The `solve_p06` solver uses quadgrams, a single-letter frequency start and dictionary segmentation, not the bigram/trigram evidence the puzzle teaches. The SolverLib docstring says trigrams are the P06 lesson, but the flag is off.
21. **MISLEADING.** The P12 crib-drag solver's readability filter hard-codes the letters' punctuation style (rejects - : ! ?). LTR_P12_B drops the hyphen from "Morrow-Veil", apparently to suit it.
22. **WRONG.** PZ_P03_HINT1 says "three little tricks". Only two schemes exist (UI_MODE_KEYLESS says two).
23. **MISLEADING.** P06 "flattened". Affects PZ_P06_BRIEF, PZ_P06_HINT1 and CDX_A1_NGRAMS_BODY. The profile is skewed (T 15.5%, E 6.9%), not flat.
24. **MISLEADING.** The a1_p06.tres anti_cheese note says "flattened" and "only pairs/triples anchor the alphabet". Not demonstrated by the solver (see item 20).
25. **MISLEADING.** The a1_p08.tres anti_cheese note says "without it the column tallies are mush". The free period stepper plus free per-column tallies allow eyeballing the period without the lens.
26. **MISLEADING.** The a1_p10.tres anti_cheese note explains the exclusion of 96 as removing the case-flip key 0x20. 0x20 is already outside 65..250, and 96 has no such property.
27. **MISLEADING.** PZ_P10_BRIEF says "pour the byte twice to find the key". Pouring twice restores the word; the key comes from the dial.
28. **MISLEADING.** UI_WIDGET_IOC_HELP omits 12, and on its own sample N = 2 also reads English-like (0.065).
29. **MISLEADING.** UI_COMB_TITLE says "Average bits... between neighbouring blocks". The bars are bits per byte (normalized).
30. **MISLEADING.** CDX_A1_FREQUENCY_M1 says the tallest bar "never lies". P05, P06 and P07 are built on it not being E.
31. **MISLEADING.** CDX_A1_FREQUENCY_M2 says the tally "only breaks shifts and swaps". It also breaks Vigenere columns and single-byte XOR.
32. **MISLEADING.** CDX_A1_KEY_M1 contrasts "the number" with "the key". In Caesar they are the same thing.
33. **MISLEADING.** CDX_A1_KEY_ASIDE says "password hashing... only the key stays secret". Password hashing has no key.
34. **MISLEADING.** CDX_A1_VIGENERE_M2 calls authorship "the real fight". It was a later misattribution, not a contest.
35. **MISLEADING.** CDX_A1_OTP_M3 says VENONA worked "because the Soviets got lazy". The duplicated pages came from wartime production pressure.
36. **MISLEADING.** DLG_A1_P05_REMARK_02 and DLG_A1_VAULT_II_01 (Marquise) say "six words... every letter he ever wrote". The crib is four words, and P09 is signed only "Soll".
37. **MISLEADING.** UI_COACH_KASISKI_LENS says "Repeats sit a key-length apart". They sit a multiple of it apart.
38. **WRONG.** CDX_A1_SINGLE_XOR_M1 says "count them on your fingers forty times". 256/10 is about 26.
39. **WRONG.** `core/crypto/modes.gd` `ecb_decrypt` / `cbc_decrypt` silently drop a trailing odd byte, so malformed ciphertext can unpad as ok. Act II stub, currently unused.
40. **MISLEADING.** The `core/crypto/xor_ops.gd` `random_pad` docstring calls PCG32 output a one-time pad. A real OTP needs truly random bytes.
41. **WRONG.** The `core/crypto/bytes_util.gd` `from_hex` docstring says "whitespace ignored". Internal tabs and CR are rejected.
42. **MISLEADING.** The `core/crypto/analysis/english_score.gd` docstring says "mean log-probability". The model is unnormalized (it sums to about 1.74); it is a score.

## Verdict counts (table rows)

| verdict | rows |
|---|---|
| OK | 142 |
| WRONG | 12 |
| MISLEADING | 35 |
| UNVERIFIED | 3 |
| **total** | **192** |

Some table rows group several strings or functions that share a verdict. The numbered list and the table rows do not map one to one: item 1 covers three WRONG rows, item 5 three MISLEADING rows and item 9 two. The 42 list items therefore cover all 47 WRONG and MISLEADING rows.

---

## Re-audit (second pass)

Independent second pass against HEAD `c219f22` (fixes in `c66a4e4`, `f9ab878`, `1ea3465`), following `.claude/skills/crypto-accuracy-check/SKILL.md`. Report only; nothing outside this section was changed.

**Method.**
- I diffed `463a3dd..HEAD` for `content/`, `core/`, `tools/`, `tests/solvers/` and `tools_dev/gen_content_defs.py`, and re-read the current CSV strings, `.tres` anti_cheese notes, solvers and new analysis functions.
- I wrote fresh Python ports in `.tools/ra_lib.py`, `ra_vig.py`, `ra_vig2.py`, `ra_xor.py`, `ra_sub.py` and `ra_otp.py` (scratch). They cover `profile_match` (cosine), Kasiski (`find_repeats` plus the 0.8 rule), IoC, normalized Hamming, the comb's new "smallest within 5%" mark, the byte gauge, letters-only crib fitting and `reads_like_english`. The quadgram table is the game's own (`core/crypto/data/english_ngrams.json`).
- Vigenere and XOR checks ran on **every** key in each pool. They did not depend on PCG32 seeds.
- Letters LTR_P01..P11 are unchanged since the first audit. The only letter edit is LTR_P12_B ("Morrow-Veil" restored).
- `./tools_dev/run_tests.sh solvers`: 15/15 tests, 221 asserts, pass (160 s). `./tools_dev/run_tests.sh unit`: 59/59 pass (9604 asserts); the regenerated `strings.csv` is unchanged.

### Status of the 42 earlier findings

| # | short name | status | evidence |
|---|---|---|---|
| 1 | P07 peak-as-E (brief, HINT2, anti_cheese) | PARTLY FIXED | **Fixed:**<br>- BRIEF now reads "Line up each column's shape with English".<br>- The Tally gained a "Shapes agree" score (`Frequency.profile_match`) and Read-as E/T/A/O/I/N.<br>- HINT3's procedure (read the tallest bar as each letter, keep the best score) is correct on P07: for every pool key the true shift is among the tallest bar x E/T/A/O/I/N, and the best of those 6 is the true shift in all 5 columns.<br>**Remaining:**<br>- HINT2 says "T, A or O can win; try them", but column 4 peaks on plaintext **N** (N 6, E 4) for every key.<br>- The anti_cheese still says "the preview reads as English only when every column is right". With 4 of 5 right, 80% of letters read.<br>- The cost estimate "about 10-15 Thirst" is optimistic. Reads in E,T,A,O,I,N order cost **14** only if the player knows when to stop (7+... = 2+4+1+6+1). A player who cannot tell and tries all six pays about 22-35. It also names only E/T/A/O. |
| 2 | P07 HINT3 "scroll will tell you" | FIXED | HINT3 now points at the shapes-agree score. `vigenere_mode.sync_views` calls `tally.set_alignment(shifts[col], profile_match(...))` on every drum change, so the score does react to the drum. |
| 3 | Vigenere solvers use chi-squared, not the taught method | FIXED | `SolverLib.vigenere_shifts` now takes the argmax of `Frequency.profile_match` over 26 shifts, the same score the Tally shows. My port: the argmax is the true shift in **every** column of every pool key for P07, P08 and P09 (0 failures). Note: the solver searches all 26 shifts for free (see new item N6). |
| 4 | PZ_P09_HINT1 "nothing repeats" | FIXED | "A few letters do repeat here, but too few to vote on a key length." It is a fair hedge. |
| 5 | P09 "too short for Kasiski" (brief, UI_MODE_VIG_IOC, anti_cheese) | PARTLY FIXED | **Fixed:** BRIEF ("Too few repeats to trust") and UI_MODE_VIG_IOC.<br>**Remaining:** the new anti_cheese says "Only a few short repeats occur, **at chance level**, so Kasiski misleads here". This is false:<br>- VEIL has 8 repeated sequences (BSZ x4, SZR x3, BSZR, IBSZ, BSDW, WVZO, GZV, IGZ) against about 1 expected by chance, and 14/15 spacings are multiples of 4. Kasiski gives **4**.<br>- ASHES and GRIEF give 10, a multiple the commit accepts.<br>- Only EMBERS misleads (3). |
| 6 | PZ_P09_HINT3 "tallest bar as E" | FIXED | It now says "Take the smallest width where the vial runs thick, then give each strand the reading where the shapes agree best." IoC gives the right width for all 4 keys, and the shapes-agree argmax is right in every strand. (See N6 for the cost of finding that reading.) |
| 7 | PZ_P08_HINT1 "never an accident" | FIXED | "Short repeats can be chance; longer ones rarely are." |
| 8 | PZ_P03_HINT3 leaks the answer | FIXED | "...ask what a stranger would still lack after reading them." It is a strong nudge toward A3 but no longer paraphrases it, and it names no scheme per note. |
| 9 | P05 "short" (HINT1, anti_cheese) | PARTLY FIXED | **Fixed:** HINT1 now blames the order ("the commonest letters here don't fall in their usual order"). True: O 43 > E 41.<br>**Remaining:** the new anti_cheese adds two false statements:<br>- "**O and T** outnumber E". T is 35, below E at 41.<br>- The frenzy crib IN ETERNITY "agrees in **more than one place**". Letters-only, INETERNITY fits at exactly **one** offset (354 of 375); the full crib fits once (343).<br>`test_p05_frequency_alone_is_ambiguous` is unchanged (weak evidence, as before). |
| 10 | CDX_A1_KEYSPACE_BODY "true strength" | FIXED | "A large key space is necessary for strength but not enough on its own." |
| 11 | CDX_A1_IOC_BODY wrong columns "look random" | FIXED | "...Split it into the key's length, or a multiple of it, and every column looks like English again." |
| 12 | CDX_A1_REPEATING_XOR_BODY "usually the true one" | FIXED | "The true size, or a multiple of it, scores lowest... Prefer the smallest size that scores nearly as well as the best." |
| 13 | a1_p11 anti_cheese | FIXED | It now says multiples score lowest and are accepted. "At a wrong size no setting makes every strand gauge high" is right. Nit: "the live preview reads as English only when all dials are right" overstates, but dials are free in P11, so there is no cost impact. |
| 14 | PZ_P11_HINT2 | FIXED | "...is the key's length, or a multiple of it." |
| 15 | UI_COMB_TAP | FIXED | It now says "key size or a multiple... Prefer the smallest size that is nearly as short". The comb's new mark (smallest size within 5% of the best) picks **11, 13, 13, 14**: the true size for all four keys (best raw 33 and 28 for two of them). Residual coach line: see N9. |
| 16 | CDX_A1_KASISKI_EXAMPLE single gap | PARTLY FIXED | **Improved:** the new example (key VEIL) has three repeats and says "try 4 (the largest shared), then 2". The shown text really is VEIL over "THE TITHE IS OWED AT THE NEW MOON AND THE TI..." OLM (gap 16) and XPP (gap 24) check.<br>**Remaining:**<br>- The shown ciphertext is only **34 letters** (positions 0-33). "BSZ at 34 and 46" lies outside it and cannot be checked; BSZ does not occur in the shown text.<br>- From the two visible gaps (16, 24) the largest shared factor is **8**, not 4. |
| 17 | DLG_A1_P11_REMARK_01 "fine key" | FIXED | "A liturgy makes a fine prayer and a poor key." |
| 18 | PZ_P08_HINT3 "read each peak" | FIXED | It now says "largest factor that nearly all your spacings share... match each column's shape to English":<br>- The Kasiski 0.8 rule gives 6/6/6/7/7, correct for every key.<br>- The lens glow now uses the same rule.<br>- The profile argmax is right in every column. |
| 19 | CDX_A1_XOR_BODY lit = 1 | FIXED | "each dark (one) or pale (nought)... darkens the result only when exactly one of them was dark". It matches `bit_rosary.gd`, UI_COACH_BIT_ROSARY and PZ_P10_HINT1. |
| 20 | `solve_p06` not the bigram/trigram lesson | PARTLY FIXED | **Fixed:** it now calls `solve_substitution(c, {}, true, 40)`, so hill-climbing scores trigrams.<br>**Remaining:**<br>- It still starts from a single-letter frequency ranking and finishes with `polish_with_words` dictionary segmentation. The anti_cheese now says so honestly ("the rest is read off the words that appear").<br>- The `solve_p06` docstring still claims single letters are "flattened, so only multi-letter structure such as TH, HE, THE can anchor the key".<br>- The test message says "flattened letter".<br>- It is still not shown that the top-8 Pairs/Triples tabs alone suffice. |
| 21 | P12 crib-drag solver punctuation prior | FIXED | `_reads_true` now allows a hyphen between two letters, LTR_P12_B has "Morrow-Veil" again, and the prior (`: ! ?` read as noise; a line break only after `, .` or another break) is documented in the code comment. It is still a style prior, but a stated one. |
| 22 | PZ_P03_HINT1 "three tricks" | FIXED | "Three notes, two little tricks." |
| 23 | P06 "flattened" strings | FIXED | BRIEF ("E is hiding"), HINT1 ("starved the commonest letter") and CDX_A1_NGRAMS_BODY ("skews") are fixed. Residual, not in the original list: CDX_A1_NGRAMS_M1 "Flatten the letters all you like" is hypothetical and acceptable. |
| 24 | a1_p06 anti_cheese | FIXED | "T tops the tally, E sits mid-table" is true (T 27, E 12, tied 5th). The word-reading step is now acknowledged. |
| 25 | a1_p08 anti_cheese "mush" | PARTLY FIXED | **Fixed:** it now admits the free stepper and tallies.<br>**Remaining:** "(at a wrong one nothing does)" overstates. Mean best shapes-agree per column (my port):<br>- MORROW: 0.90 at 6, but 0.88 at 3 and 0.84 at 12.<br>- VESPERS: 0.89 at 7, but 0.85 at 2 and 0.84 at 4.<br>Cosine similarity has a high floor: a perfectly flat column scores 0.77 against English. |
| 26 | a1_p10 anti_cheese exclude 96 | PARTLY FIXED | **Fixed:** the bogus `exclude: [96]` is gone.<br>**Remaining:** the new rationale "Keys 65-250 always set bit 6 or 7, so no key merely flips letter case (0x20) and no wrong key reads as English by accident" is a non sequitur:<br>- The dial covers 0-255, and dialing K xor 0x20 (in range for every K) still gives case-flipped letters.<br>- What keeps it from reading is that spaces become NUL and punctuation becomes control codes: gauge at most 0.60 versus at least 0.998 for the true key.<br>- The true key tops the gauge for all 186 keys, and the runner-up peaks at 0.80. |
| 27 | PZ_P10_BRIEF | FIXED | "...pour twice to undo it, then dial the key." |
| 28 | UI_WIDGET_IOC_HELP | PARTLY FIXED | It now mentions multiples and factor 2. Remaining:<br>- `ui/codex_widgets/ioc.gd` calls `_loom.configure(10)`, so **N = 12 is not reachable** on this widget (the first audit's "within the slider's range" was itself wrong).<br>- On the sample, N = 2 reads **0.065**, fully English-level and above the 0.058 threshold, not "a little". N = 6 reads 0.061. |
| 29 | UI_COMB_TITLE | FIXED | "Average differing bits per byte..." |
| 30 | CDX_A1_FREQUENCY_M1 | FIXED | "The tallest bar is only a strong bet, boy." |
| 31 | CDX_A1_FREQUENCY_M2 | FIXED | "...and later every column of a many-toothed key." |
| 32 | CDX_A1_KEY_M1 | FIXED | "In a Caesar the number IS the key." |
| 33 | CDX_A1_KEY_ASIDE password hashing | FIXED | Now AES only. |
| 34 | CDX_A1_VIGENERE_M2 "the real fight" | FIXED | "Bellaso wrote it; Vigenere got the credit centuries later by mistake." |
| 35 | CDX_A1_OTP_M3 "lazy" | FIXED | "...wartime pad makers duplicated pages under pressure." |
| 36 | Marquise "six words... every letter" | PARTLY FIXED | "four words" is fixed. DLG_A1_P05_REMARK_02 still says "every time" and DLG_A1_VAULT_II_01 still says "on every letter". LTR_P09 is signed only "Soll". Low severity. |
| 37 | UI_COACH_KASISKI_LENS | FIXED | "Repeats sit a multiple of the key's length apart." |
| 38 | CDX_A1_SINGLE_XOR_M1 "forty times" | FIXED | "about twenty-six times over" (256/10 = 25.6). |
| 39 | `modes.gd` odd-length decrypt | FIXED | `ecb_decrypt` and `cbc_decrypt` return `{ok: false}` when the data is empty or `size % BLOCK_BYTES != 0`. |
| 40 | `random_pad` docstring | FIXED | "Pseudo-random pad bytes from the seeded PCG32... a real one-time pad needs truly random bytes." |
| 41 | `from_hex` "whitespace ignored" | FIXED | The loop drops space, tab, LF and CR anywhere, and the docstring now lists exactly those. |
| 42 | `english_score` "log-probability" | FIXED | "mean log-weight... the weights are not normalized to sum to 1, so it is a score". |

**Counts:** FIXED 33, PARTLY FIXED 9 (1, 5, 9, 16, 20, 25, 26, 28, 36), NOT FIXED 0.

### New or re-checked items since the first audit

| file | claim or function | verdict | evidence | suggested correction |
|---|---|---|---|---|
| core/crypto/analysis/frequency.gd | `profile_match(counts, shift)`: cosine between counts read back through the shift and `ENGLISH` | OK | Convention matches `Caesar.shift_between` and `Vigenere.decrypt_with_shifts` (cipher = plain + shift). The argmax is the true shift in every column of every P07/P08/P09 pool key (15 key/letter pairs, 32-77 letters per column). | |
| core/crypto/analysis/frequency.gd | Docstring: "About 0.9 or more when the shapes line up; roughly 0.3-0.6 when they don't" | MISLEADING | True shifts measured 0.76-0.96 (for example, P09 VEIL strand 4 at 0.76 and ASHES strand 1 at 0.79). The best wrong shift is 0.57-0.76. A perfectly flat profile scores 0.77 (1/sqrt(26 x sum E^2)). The readout (UI_TALLY_MATCH) is only meaningful comparatively. | "Highest at the right shift, typically 0.8-0.95 on 40+ letters; wrong shifts usually 0.3-0.75, and a flat profile scores about 0.77. Compare settings; don't read it as an absolute." |
| core/crypto/analysis/crib.gd | `substitution_letter_status` (letters-only strip): 1 consistent so far, 0 contradicts an earlier letter, -1 past the end | OK | Same checks as `substitution_mapping`. All 1s exactly when the crib fits. The mode now feeds letters-only cipher and crib (`TextUtil.letters_only`), so word breaks cannot give the place away, and the gold highlight maps letter offsets back correctly. | |
| core/crypto/analysis/crib.gd | `reads_like_english` "English-like letters (quadgram fitness per gram above -5.2 when there are enough letters to judge)" | MISLEADING | Four letters is not enough to judge, and fragments with 3 letters or fewer pass on character set alone. Against the real P12 stream (overlap 207):<br>- **False "reads true":** " THE " at 1, 31 and 139 (" UEM'", "- IN ", "SIK ,"); TITHE at 5, 114, 116 and 139 ("S; DF", "C, KD", " JUN ", "'TW-I").<br>- **False "doesn't read":** a true " THE " at 122 gives "ALT B" (fitness below -5.2).<br>- The long tray cribs (SALT BARN, BROTHER, LEDGER, the sign-off) have no false positives.<br>The colour is the boss's readability cue and a wrong pin costs 4-6. | Require at least 6-8 letters for the quadgram test. Below that, require complete words from a small vocabulary. Also apply the solver's apostrophe and hyphen rules. |
| tests/solvers/solver_lib.gd | `vigenere_shifts`: profile_match argmax "exactly as the game teaches" | OK | Uses the taught score and never reads the key. Caveat in N6: it scores all 26 shifts for free, where a player pays 1 per Read-as. | |
| tests/solvers/reference_solvers.gd | `solve_p05`: letters-only crib, last consistent offset | OK | Mirrors the strip. The crib fits once in both variants, so "a sign-off sits last" is harmless. The comment "Several consistent places are possible for a short crib" does not happen for IN ETERNITY. | |
| tests/solvers/reference_solvers.gd | `solve_p06` docstring "single letters are flattened, so only multi-letter structure... can anchor the key" | MISLEADING | See #20: the solver starts from single-letter ranks and ends with dictionary segmentation; P06 counts are skewed, not flat. | "Trigram-scored hill climb from a frequency start, finished by reading words." |
| tests/solvers/crib_drag_solver.gd | Crib-dragging only; "never sees the pad or the plaintexts" | OK | Inputs are only C1 xor C2 over the overlap, the tray, story words from LTR_P01-P11 plus dialogue before P12, and a word list. Both targets are inside the overlap (NIGHT at 45 in A, ANSGAR at 60 in B). Its `_reads_true` is stricter than the game's `reads_like_english`. The punctuation prior is documented. | |
| tools/kasiski_lens/kasiski_lens.gd | Glow = largest factor with tally >= 0.8 x best | OK | Same rule as `Kasiski.likely_period`: 6, 6, 6, 7, 7 on P08. | |
| tools/hamming_comb/hamming_comb.gd | Mark = smallest size within 5% of the best | OK | 11, 13, 13, 14: the true size for all P11 keys. | |
| a1_iii.csv | PZ_P07_HINT2 "Its tallest bar is often E, but in forty letters T, A or O can win; try them." | MISLEADING | Plaintext column peaks are T, O, E, **N**, E for every key. For column 4, trying E/T/A/O never lands; N (6th button) does. | "...T, A, O or even N can win; try them." |
| a1_p07.tres | "the preview reads as English only when every column is right"; "read-as E/T/A/O jumps... about 10-15 Thirst" | MISLEADING | With 4/5 drums right, 80% of letters read. The minimum is 14 reads, and only with perfect stopping. Without a stopping rule it is about 22 (6 reads per column where the true score is 0.82-0.86, because a player cannot tell it is the best). There are 6 buttons (E/T/A/O/I/N), and the cost doubles after a frenzy. | "...reads fully only when every column is right... about 14-25 Thirst." |
| a1_iii.csv / a1_p09 | P09 strands under the taught Read-as search (N6) | MISLEADING | The true shift is not reachable from the tallest bar x E/T/A/O/I/N in 1-2 strands per key:<br>- VEIL strand 4 has no plaintext E; its peaks are H/O.<br>- ASHES and GRIEF strand 1 peaks on S (true shift at the 2nd bar, read 8); strand 4 peaks on R (**5th bar, 30 reads**).<br>- EMBERS strand 6 peaks on H/S (3rd bar, 18 reads).<br>Hint 3's target ("the reading where the shapes agree best") is true, but the procedure taught on P07 does not reach it cheaply. Only the free-argmax solver passes, so the solver tests cannot see this. The adversarial playtest (docs/playtest/adversarial_a1_iii.md, section 9) found the same. | Add a line to P09 HINT3 ("if no reading of the tall bars scores well, read a word you can guess off the preview and set that letter"), or rebalance the P09 letter so each strand's true shift sits within the two tallest bars x E/T/A/O/I/N. Add a solver test limited to that search. |
| a1_p05.tres | "O and T outnumber E"; frenzy crib "agrees in more than one place" | WRONG | Counts O 43, E 41, T 35. INETERNITY fits at exactly one letter offset (354). See #9. | "O outnumbers E... IN ETERNITY: ten letters, six of them distinct, and it still fits only at the sign-off." |
| a1_p09.tres | "Only a few short repeats occur, at chance level, so Kasiski misleads here" | WRONG | See #5. VEIL: 8 repeats, 14/15 spacings are multiples of 4, and Kasiski gives 4. ASHES/GRIEF give 10 (accepted). Only EMBERS gives 3. | "Repeats are few; Kasiski is right for some keys and wrong for others (EMBERS gives 3), so the loom is the reliable tool." |
| a1_p08.tres | "(at a wrong one nothing does)" | MISLEADING | See #25. | "...at a wrong one the match is weaker (though multiples and shared factors also look decent)." |
| a1_p10.tres | "Keys 65-250 always set bit 6 or 7, so no key merely flips letter case (0x20) and no wrong key reads as English by accident" | MISLEADING | See #26. | "The dial setting K xor 0x20 flips case but turns spaces into NUL, so the gauge rejects it; the true key always tops the gauge (checked for all 186 keys)." |
| a1_iii.csv | CDX_A1_KASISKI_EXAMPLE third repeat | MISLEADING | See #16: "BSZ at 34 and 46" is off the 34-letter text shown, and the visible gaps 16 and 24 share 8. | Show at least 49 letters of the ciphertext (so BSZ is visible), or pick a third repeat inside the shown text. |
| modes.csv | UI_WIDGET_IOC_HELP "(8, 12)... Factors such as 2 rise a little too" | MISLEADING | See #28: the slider stops at 10; N = 2 gives 0.065. | "...at 4 and 8 the vial thickens; at 2 it thickens nearly as much, so prefer the largest of the near-ties that divides the others, or check the strands." (Or change the sample or key.) |
| tools.csv | UI_COACH_HAMMING_COMB "Short tooth, likely key size. Tap it." | MISLEADING | For NOX AETERNA and SALT AND ASHES the shortest tooth is 33 or 28, a multiple. The comb's mark and UI_COMB_TAP are right. Low. | "Short tooth: the key size or a multiple. Tap the marked one." |
| a1_i.csv / a1_ii.csv / a1_iii.csv | Hints PZ_P01..P12 HINT1-3 (all rewritten ones re-read) | OK (except PZ_P07_HINT2 above) | All are true against the letters:<br>- P02: E 48 vs T 29, and "One press costs a drop; ... one per notch" matches `caesar_mode`.<br>- P04: E 139, T 97, THE x25.<br>- P06: THE is the top trigram (9); the words before THE are AT, TO, NOT, PAST, ON, TILL.<br>- P10: dark = 1; K = A xor B.<br>- P12: the auto-refile of a right crib pinned in the wrong letter does not make HINT3 false.<br>Tier 3 never names a shift, key, scheme per note, width, byte or target phrase, and none makes key-specific claims. P03 HINT3 is a strong nudge, not the answer. | |
| a1_*.csv | Rewritten Codex bodies, examples, margins (KEY, KEYSPACE, FREQUENCY, NGRAMS, VIGENERE, KASISKI body, IOC, XOR, SINGLE_XOR, REPEATING_XOR, OTP) | OK (except the Kasiski example) | Checked against the reference facts:<br>- The Babbage "a century" claim was removed (resolving the old UNVERIFIED).<br>- SINGLE_XOR_ASIDE is now hedged.<br>- 256/10 is about 26.<br>- The XOR convention is consistent. | |
| a1_*.csv | Marquise lines rewritten (P05_REMARK_02, VAULT_II_01, P11_REMARK_01) and new narrative (P10_AFTER_05/06, III_FRENZY_04/05) | OK (except #36 residual) | No new cryptographic claims. | |
| tools.csv | UI_TALLY_READ_AS(_COST), UI_TALLY_MATCH, UI_TALLY_ENGLISH_ALIGNED, UI_CRIB_HELP ("spaces ignored"), UI_CRIB_FITS ("a candidate, not proof"), UI_CRIBDRAG_OTHER_LETTER | OK | They match the code paths (`tally_scroll.gd`, `substitution_mode._update_crib`, `two_time_pad_mode._on_pin`). | |
| a1_p01/p03/p04/p06/p12.tres | Frenzy variants (P01/P03 costed, P04/P06 wrong seal 16, P12 wrong pin 6) | OK | `puzzle_factory` applies `costed`, `trial_cost` and params as the notes say. P01's and P03's notes don't mention that the frenzy variant rusts the wheel; this is an omission, not an error. Word/phrase-key variants > 0 never reuse variant 0's key word (checked in code). | |

### Remaining WRONG or MISLEADING items (most severe first)

1. **WRONG.** a1_p09.tres anti_cheese: "at chance level, so Kasiski misleads here".
   - VEIL has 8 repeated sequences with 14/15 spacings multiples of 4, and Kasiski gives 4.
   - ASHES and GRIEF give 10 (accepted).
   - Only EMBERS misleads (3).
2. **WRONG.** a1_p05.tres anti_cheese.
   - "O and T outnumber E" is false: T 35 < E 41.
   - The frenzy crib IN ETERNITY "agrees in more than one place" is false: it fits at exactly one letters-only offset (354).
3. **MISLEADING.** P09 strands cannot be set by the taught tallest-bar x E/T/A/O/I/N search in 1-2 strands per key.
   - The worst case is ASHES/GRIEF strand 4: 5th bar, 30 reads.
   - The reference solver's free 26-shift argmax hides this.
   - HINT3's target is true, but no hint says how to reach it cheaply.
4. **MISLEADING.** PZ_P07_HINT2 lists "T, A or O". Column 4 peaks on N in every variant.
5. **MISLEADING.** a1_p07.tres anti_cheese.
   - "reads as English only when every column is right": 4/5 right reads 80%.
   - "about 10-15 Thirst" is optimistic: 14 is the minimum with perfect stopping; about 22 is realistic.
   - It names E/T/A/O, but there are six buttons.
6. **MISLEADING.** `Crib.reads_like_english` (the boss's readability colour) judges fragments of 3 or fewer letters by character set only, and quadgrams from 4 letters.
   - False "reads" for " THE " and TITHE at 7 wrong offsets.
   - A false "doesn't read" for the true " THE " at 122 ("ALT B").
7. **MISLEADING.** CDX_A1_KASISKI_EXAMPLE: the third repeat (BSZ at 34 and 46) lies outside the 34 letters shown. The visible gaps 16 and 24 share 8, not 4.
8. **MISLEADING.** a1_p08.tres anti_cheese "(at a wrong one nothing does)". Best column matches at wrong widths reach 0.84-0.88 against 0.89-0.90 at the true width.
9. **MISLEADING.** a1_p10.tres anti_cheese. The key range is not why wrong keys fail to read. Dial K xor 0x20 flips case; spaces turning into NUL is what sinks its gauge (at most 0.60).
10. **MISLEADING.** UI_WIDGET_IOC_HELP.
    - It cites N = 12, but the widget's slider stops at 10.
    - "Factors such as 2 rise a little" understates: N = 2 reads 0.065, English level.
11. **MISLEADING.** `Frequency.profile_match` docstring ranges ("0.9 or more" / "0.3-0.6"). Measured true 0.76-0.96, best wrong up to 0.76, and a flat profile scores 0.77.
12. **MISLEADING.** `solve_p06` docstring and test message still say "flattened". The solver still starts from single-letter ranks and finishes with dictionary segmentation, so it does not show that the Pairs/Triples tabs suffice.
13. **MISLEADING.** UI_COACH_HAMMING_COMB "Short tooth, likely key size". For 2 of 4 keys the shortest tooth is a multiple (33, 28). Low.
14. **MISLEADING.** DLG_A1_P05_REMARK_02 ("every time") and DLG_A1_VAULT_II_01 ("on every letter"). LTR_P09 is signed only "Soll". Low.
