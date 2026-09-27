# Next Steps: Act II, "The Stained Glass"

Priority order. Each item names what exists already.

1. **Playtest Act I on real phones** (see PLAYTEST_REPORT, "Top five to test"). Tune Thirst numbers in `content/thirst_config.tres` and the per-puzzle `trial_cost`; confirm touch feel of the wheels and drums, and legibility of the crib grid at 360 dp.
2. **Block cipher lesson set.** `core/crypto/block_cipher.gd` (Heys-style 16-bit SPN) and `modes.gd` (PKCS#7, ECB, CBC) are implemented and tested. Build:
   - a **Block Press** tool (a 2-byte block through S-box and permutation layers, bead-by-bead);
   - an **ECB Stained Glass** puzzle: an image whose pixels are blocks, encrypted in ECB so the outline survives (repeats again);
   - a **CBC bit-flip** puzzle: flip a ciphertext bit to change a known plaintext field in the next block;
   - a **padding oracle** boss ("the confessor who only says yes or no"): the oracle is `CipherModes.pkcs7_unpad(...)["ok"]`.
3. **Modes to add** (`core/puzzle_modes/`): `ecb_picture`, `cbc_flip`, `padding_oracle`; each with a reference solver in `tests/solvers/` that uses only the oracle/technique.
4. **Codex:** replace the `a2_stained_glass` placeholder with entries for SPN, ECB, CBC, PKCS#7, padding oracles; one live widget (flip a CBC bit, watch two blocks change).
5. **Story:** the Order's chapter-house after Ansgar's flight; the Marquise's own house's glass-window ciphers; act-level choice branching on `act1_warned` / `act1_silent`.
6. **Art pass** using the swap paths in ASSET_MANIFEST: painted portraits (`ui/portraits/<speaker>.png`), backgrounds, illuminated capitals.
7. **Act IV prerequisite:** BigInt (`core/crypto/bigint.gd` is interface-only). Decide limb size (24-bit planned) and whether a GDExtension is needed, by profiling modpow on 512-bit numbers on a mid-range phone.
8. **Localization:** strings are all keyed in `content/i18n/strings.csv`. A second language needs its own letters, and the solver tests must pass on them (letters drive the ciphertext).
