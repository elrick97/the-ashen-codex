# Changelog

## 0.1.0 (2026-09-27): Act I vertical slice

### Added
- **Act I, "The Tithe Letters":** 12 puzzles in three sub-chapters (shift ciphers, monoalphabetic substitution, polyalphabetic and XOR), a confession frame in the Vault, three feeding choices and the act's big choice with persistent flags, frenzy scenes, sub-chapter summaries, the act folio and the "To be continued" card.
- **Crypto core** (`core/crypto/`): Caesar/ROT13/Atbash, substitution, Vigenere, XOR, bytes/hex/base64, seeded PCG32; analysis: frequency and n-grams, profile matching, Kasiski, index of coincidence, Hamming key size, English scoring, cribs; later-act groundwork: modular arithmetic, toy SPN, ECB/CBC/PKCS#7, toy Merkle-Damgard hash, BigInt interface.
- **Ten tactile tools:** Cipher Wheel, Tally Scroll, Substitution Board (with crib strip), Multi-Wheel, Kasiski Lens, Column Loom, Bit Rosary, Key Dial, Hamming Comb, Crib Dragger; all with undo and save/resume.
- **Systems:** Thirst (costs, thresholds, frenzy with a harder variant), grades, tiered hints voiced by Brother Kett, the Codex (18 entries, 4 live widgets), versioned atomic saves with migration and backup fallback, settings (text size, Clear Mind, haptics, volumes, hint confirmation, reset).
- **Presentation:** procedural parchment, ink-bleed transitions, Thirst overlay (vignette, ink, desaturation, pulse, drips; all off under Clear Mind), procedural portraits and backdrops, illuminated drop caps, OFL fonts, procedurally synthesized SFX and ambience.
- **Quality tooling:** GUT suite (unit, integration, reference solvers incl. a crib-dragging solver), LSP-based GDScript lint, string/budget/dialogue checker, letter-constraint checker, automated screenshot tour, export presets for Android, iOS, Linux, Windows and Web.

### Fixed during review
- Independent crypto audit (`docs/CRYPTO_AUDIT.md`): teaching text corrected; Vigenere columns now taught by matching the whole letter profile (shapes-agree score, read-as E/T/A/O) instead of "the peak is E".
- Adversarial playtests (`docs/playtest/`): wheel overcharging after programmatic turns, grade laundering by replaying solved puzzles, frenzy dodging by killing the app, P05 lock/pin softlock, crib strip giving itself away through spaces, undo desyncs.
- Layout at the largest text size, modal placement recursion, leaked audio streams at exit, drips over the letter card.
