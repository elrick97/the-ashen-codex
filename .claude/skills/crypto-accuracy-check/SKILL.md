---
name: crypto-accuracy-check
description: Audit checklist and reference facts for verifying The Ashen Codex's cryptography code, puzzles, hints and Codex text. Use when auditing crypto correctness, writing teaching text, or reviewing a puzzle's solvability.
---

# Crypto Accuracy Audit

You are an auditor. **Report, don't fix.** For every file you review, output a table with columns: file, claim or function, verdict (OK / WRONG / MISLEADING / UNVERIFIED), evidence, suggested correction.

## Procedure
1. **Code:** for each function in `core/crypto/`, check it against the reference facts and vectors below. Where possible, write and run a quick independent check (for example, a Python one-off) and compare outputs.
2. **Text:** extract every factual claim from Codex entries, hints and Marquise remarks. Verify each claim against this list, or derive it. Flag unsupported historical claims.
3. **Puzzles:** confirm each puzzle's solver really uses the intended technique, and that the plaintext is long enough for that technique (guidelines below). Confirm no free live preview trivializes the concept.
4. **Hints:** tier 3 must never reveal the final answer. Every hint must be true.

## Reference facts and values
- **Caesar:** 26 shifts (25 non-trivial). Suetonius records Julius Caesar using a shift of 3.
- **ROT13:** a shift of 13, self-inverse. Popularized on Usenet in the 1980s. **Atbash:** reversed alphabet, of Hebrew origin, self-inverse. Neither has a secret key.
- **Kerckhoffs's principle (1883):** a system should stay secure even if everything except the key is public.
- **Monoalphabetic substitution:** 26! ≈ 4.03 × 10^26 keys (about 88 bits), yet frequency analysis breaks it. The first known description of frequency analysis is by **al-Kindi (9th century)**.
- **English letter frequencies:** E ≈ 12.7%, T ≈ 9.1%, A ≈ 8.2%, O ≈ 7.5%, I ≈ 7.0%, N ≈ 6.7% (order "ETAOIN SHRDLU" is approximate). Common bigrams: TH, HE, IN, ER, AN. Common trigrams: THE, AND, ING.
- **Vigenère:** first described by **Giovan Battista Bellaso (1553)** and later misattributed to Blaise de Vigenère. Called "le chiffre indéchiffrable" for about three centuries. **Kasiski published a general attack in 1863.** Babbage broke it earlier (about the 1850s) but didn't publish.
- **Kasiski examination:** distances between repeated ciphertext sequences tend to be multiples of the key length. Take common factors, and beware coincidental repeats (prefer trigrams or longer).
- **Index of coincidence (Friedman, 1922):** IC = Σ n_i(n_i−1) / (N(N−1)). English ≈ 0.066–0.067; uniformly random letters ≈ 1/26 ≈ 0.0385. Normalized (×26): about 1.73 vs 1.0. Splitting Vigenère ciphertext into columns at the correct key length brings each column's IC near the English value.
- **XOR:** a⊕a = 0, a⊕0 = a, commutative, associative, self-inverse. Single-byte XOR has 256 keys. Score candidates by English-likeness (letter frequency or chi-squared).
- **Hamming distance:** the number of differing bits. hamming("this is a test", "wokka wokka!!!") = **37**.
- **Repeating-key XOR key length:** for each candidate size k, average the normalized Hamming distance (divided by k) across several pairs of adjacent k-byte blocks. The smallest value is likely the key size. Then transpose and solve each column as single-byte XOR.
- **One-time pad (Shannon, 1949):** perfect secrecy only if the key is truly random, at least as long as the message, kept secret, and **never reused**.
- **Two-time pad:** C1⊕C2 = P1⊕P2, so the key cancels. Crib-dragging: XOR a guessed word at each offset. Readable output in the other message confirms the guess.
- **Historical key-reuse examples:**
  - **VENONA:** US codebreakers exploited Soviet one-time pad reuse (1940s).
  - **Bletchley Park:** broke Enigma helped by cribs from formulaic messages (weather reports, "nothing to report").
  - **WEP:** IV reuse broke it.
  - **Modern equivalent:** nonce reuse in stream ciphers and CTR/GCM exposes the keystream (and, for GCM, enables forgeries).
- **Language:** never call a cipher "unbreakable" without stating the conditions.

## Plaintext length guidelines (heuristics; label them as such)
- Caesar by frequency: ≥ 25 letters.
- Substitution by frequency plus word patterns: ≥ 150–250 letters. Shorter texts need cribs.
- Vigenère via Kasiski: ≥ ~20× the key length, with genuine repeats.
- Vigenère via IoC: ≥ ~25 letters per column.
- Repeating-key XOR via Hamming: ≥ ~4 blocks per candidate key size.
- Solver tests are the final word. If the reference solver fails on a seed, the text is too short.
