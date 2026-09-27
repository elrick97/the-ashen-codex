# THE ASHEN CODEX: AUTONOMOUS BUILD PROMPT

You are working in an **empty directory**. This message is the complete brief. It covers bootstrapping the repo and its Claude Code configuration, the full game spec, the execution plan, and the definition of done. Read it all before acting.

---

# 0. BOOTSTRAP (do this first, in order)

1. **Save this brief.** Write this entire message **verbatim** to `PROMPT.md` in the repo root. It is your source of truth. Whenever your context is compacted or you resume, re-read `PROMPT.md` and `docs/DECISIONS.md` before doing anything else.
2. **Git.** Run `git init`. Create a `.gitignore` for Godot 4 (ignore `.godot/`, `/build/`, `/.tools/`, `*.tmp`, `qa/screenshots/*.png` except a `latest/` folder, and export outputs; commit `*.import` files). Never push anywhere.
3. **Toolchain recon.** Record the findings in `docs/ENVIRONMENT.md`:
   - **Godot:** if `godot --version` works, use it. Otherwise download the **latest stable Godot 4.x Linux x86_64** build from the official `godotengine/godot` GitHub releases (use the releases API to find the asset). Unzip it into `./.tools/godot/`, and use it through a wrapper script `./tools_dev/godot.sh` that execs the binary with any arguments. Don't use `sudo`. From here on, `$GODOT` means whichever works.
   - **Display for rendered screenshots:** check `$DISPLAY` / `$WAYLAND_DISPLAY` (WSLg provides these on Windows 11). If neither is set, check for `xvfb-run`. If neither is available, headless screenshots can't render. Document that in `docs/BLOCKERS.md` and fall back to reviewing scene layouts structurally.
   - **Also check:** `python3`, network access (GitHub, Google Fonts), CPU count.
4. **Claude Code project config.** Create the files below exactly. Writes to `.claude/` are protected, so they may need approval. That's expected.
5. **Project skills.** Create the three skills in §0.2. They're how your subagents get the voice bible, the QA commands, and the crypto audit checklist. When you delegate, always tell the subagent to **Read the relevant `.claude/skills/<name>/SKILL.md` first**. Don't assume skills auto-load mid-session.
6. **CLAUDE.md.** Create the file in §0.3.
7. Commit: `chore: bootstrap repo, Claude config, project skills`.

## 0.1 `.claude/settings.json`

~~~~json
{
  "permissions": {
    "allow": [
      "Bash(godot *)",
      "Bash(./tools_dev/godot.sh *)",
      "Bash(./.tools/godot/*)",
      "Bash(xvfb-run *)",
      "Bash(timeout *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(python3 *)",
      "Bash(mkdir *)",
      "Bash(ls *)",
      "Bash(unzip *)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:api.github.com)",
      "WebFetch(domain:fonts.google.com)",
      "WebFetch(domain:docs.godotengine.org)"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(sudo *)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(~/.config/gcloud/**)",
      "Read(~/.gnupg/**)"
    ]
  }
}
~~~~

## 0.2 Project skills

### `.claude/skills/grimdark-voice/SKILL.md`

~~~~markdown
---
name: grimdark-voice
description: Writing bible for The Ashen Codex. Use whenever writing or editing ANY player-facing text — dialogue, intercepted letters, Codex entries, hints, UI copy, names, item or chapter titles.
---

# The Ashen Codex: Writing Bible

## World in brief
- The Undying Court: vampire nobility who rule openly. Great houses govern human villages through a **blood tithe** taken at every new moon.
- House Morrow-Veil (Act I antagonists) rules the marsh-village of Hollowmere through a steward and thrall-couriers. Orders go out by raven and by hand, always enciphered.
- The Order of the Silent Quill: cipher-monks who hunt vampires by reading their mail. Poor, stubborn, half-heretical.
- Frame: Isaak Varr, a pale-blood (half-vampire), is chained in a vault beneath the Court's library. He tells his story to Marquise Ottilie Dray, archivist and cryptanalyst of the Court.
- **Theme: "Everything eternal repeats."** Immortals get lazy. They reuse keys, pads, phrasings and signatures, and repetition is how they get broken. Weave it in everywhere, but never state it more than once per scene.

## Voices (with calibration lines; don't reuse these verbatim more than once)
- **Isaak Varr** (narrator, past tense in memories, present tense in the Vault): weary, sardonic, clever, ashamed of his hunger. Short sentences. Physical detail.
  - "The letter smelled of marsh water and somebody else's fear. I read it the way Kett taught me: slowly, and assuming it was lying."
- **Brother Kett** (mentor; voices all hints and Codex margin notes): one-eyed, foul-mouthed, funny, secretly tender. Swears creatively and never cruelly at Isaak.
  - "Twenty-six keys, boy. You could try them all, or you could use the brain God wasted on you."
- **Marquise Ottilie Dray** (the Vault): precise, elegant, amused, terrifying. A real cryptanalyst who respects good work even from a prisoner. Occasionally she critiques her own house's cipher discipline, which makes her a second teaching voice from the enemy's side.
  - "My cousin used the same key for ninety years. He considered it tradition. I consider it evidence."
- **The Steward of Morrow-Veil** (letters): bureaucratic cruelty. Ledgers, quotas, complaints about spoilage. Always signs off "Your servant in eternity." That signature is a deliberate crib in puzzle 5.

## Tone rules (M-rated)
- Allowed and expected: strong profanity, blood, written violence, bleak choices, gallows humor.
- Violence is described in text, never gratuitously. Implication beats inventory.
- **Never:** sexual content. No depicted harm to children (the missing child on the tithe list stays implied, as stakes only). No slurs. No torture porn.
- No modern slang or anachronistic tech words **in-world**. The one exception is the Codex's clearly marked **"Scribe's Aside"** real-world notes, which may use modern terms (AES, nonce, TLS) because they speak to the player directly.

## Formats and length budgets (mobile portrait)
- Dialogue line: ≤ 140 characters. Split longer thoughts across beats.
- Choice text: ≤ 60 characters, verb-first.
- Hint: 1–2 sentences, in Kett's voice. Tier 1 = what to look at. Tier 2 = which technique and why. Tier 3 = the exact next step, **never the final answer**.
- Codex entry: title, then ≤ 120-word plain explanation, worked example, "How the Court got it wrong" (≤ 50 words), Scribe's Aside (≤ 50 words), and 1–3 Kett margin notes (≤ 25 words each). Mark simplifications honestly in a margin note.
- Intercepted letters: salutation, body, signature. Length follows the puzzle's technique:
  - Caesar, ROT13, Atbash: 25–60 words.
  - Substitution by frequency: 120–250 words.
  - Crib puzzle: 60–100 words.
  - Vigenère with Kasiski: 250+ letters and deliberate repeated words.
  - Vigenère with IoC: 120–200 letters.
  - XOR puzzles: whatever the solver needs.
- Plaintexts are plain ASCII: no diacritics, curly quotes or em dashes. Follow the PuzzleDef's normalization field (for example, letters-only uppercase vs. spaces preserved).

## Naming
- New names are original, with a Central European / Latin / marsh-folk flavor (Varr, Dray, Kett, Morrow-Veil, Hollowmere). Check that they don't collide with famous fiction.
- **Banned (Empire of the Vampire IP):** Gabriel, de León, Jean-François, Silver Saints, San Michon, daysdeath, sanguimancy, Chastain, Ilon, Voss, Dyvok, Esani, Celene, Astrid, Lachance, and any quoted or paraphrased text from that series. Grep your output for them.

## Checklist before handing text back
- Voice matches the speaker. Length budgets met. No banned terms.
- Every technical statement is correct. If unsure, flag it for the crypto-accuracy-check audit.
- All strings go into content files or the translation CSV, never hard-coded.
~~~~

### `.claude/skills/godot-headless-qa/SKILL.md`

~~~~markdown
---
name: godot-headless-qa
description: Exact commands and pitfalls for building, testing, linting and screenshotting The Ashen Codex with Godot 4 from the command line. Use whenever running Godot, tests, the screenshot tour, or writing GDScript.
---

# Godot 4 Headless QA

`$GODOT` is `godot` if it's on PATH, otherwise `./tools_dev/godot.sh`. Wrap long runs in `timeout`.

## Commands
- Import or reimport assets (run after adding files): `timeout 300 $GODOT --headless --path . --import`
  - If `--import` isn't supported, use `$GODOT --headless --path . --editor --quit`.
- Parse-check one script: `$GODOT --headless --path . --check-only --script res://path/file.gd`
- Run all tests (GUT): `timeout 600 $GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
- Fallback runner if GUT isn't vendored: `timeout 600 $GODOT --headless --path . --script res://tests/run_all.gd`. It extends `SceneTree`, runs every `test_*` method, prints a summary, and calls `quit(failures)`. The exit code is the failure count.
- Headless boot smoke test: `timeout 60 $GODOT --headless --path . --quit-after 600 2>&1 | tee qa/boot.log`
- Screenshot tour (needs a display: WSLg `$DISPLAY`, or `xvfb-run -a` in front): `timeout 900 $GODOT --path . --rendering-driver opengl3 --resolution 1080x1920 res://tools_dev/screenshot_tour.tscn`. Run it again at `720x1280`.
  - Capture code: `await RenderingServer.frame_post_draw` then `get_viewport().get_texture().get_image().save_png(path)`.
  - Headless mode doesn't render. Never trust screenshots taken with `--headless`.
- Error scan (keep the context small; never dump full logs): `grep -nE "SCRIPT ERROR|ERROR:|WARNING:|Parse Error|Invalid call" qa/*.log | head -50`
- To save context, filter test output to failures and the summary, or delegate long runs to a subagent that reports back only the summary.

## Godot 3 → 4 pitfalls (don't write Godot 3 code)
- `yield` → `await`. `connect("sig", self, "m")` → `sig.connect(m)`. `emit_signal("s")` → `s.emit()`.
- `export var` / `onready var` / `tool` → `@export` / `@onready` / `@tool`. `setget` → property `get:`/`set:` blocks.
- `instance()` → `instantiate()`. `change_scene()` → `change_scene_to_file()`. `update()` → `queue_redraw()`.
- `File` / `Directory` → `FileAccess` / `DirAccess`. `to_json` / `parse_json` → `JSON.stringify` / `JSON.parse_string`.
- `PoolByteArray` etc. → `PackedByteArray` etc. `rand_range` → `randf_range` / `randi_range`. `OS.get_ticks_msec` → `Time.get_ticks_msec`.
- `rect_size` / `rect_position` → `size` / `position`. `.tscn` uses `format=3` with `uid://` references.

## GDScript correctness traps for this project
- **`%` on negative ints keeps the dividend's sign.** Always use `posmod(a, 26)` for cipher shifts.
- `int` is 64-bit signed. For later-act modular math, don't multiply two values ≥ 2^31 directly. Use a mulmod (double-and-add) helper.
- Bytes: `PackedByteArray`. `String.to_utf8_buffer()` / `to_ascii_buffer()`, `PackedByteArray.get_string_from_ascii()`, `hex_encode()`. Bitwise: `^ & | << >>`.
- `String.unicode_at(i)` and `String.chr(code)` convert between characters and codes.
- Type everything: `var x: int`, `Array[int]`, `Dictionary` with documented shape, `-> void`. Keep the untyped-declaration warning on and at zero.
- Keep crypto logic in `RefCounted` classes with `static func`s so it's testable without scenes.
- Resources (`.tres`) for PuzzleDef and ChapterDef: `class_name` + `extends Resource` + `@export` fields.

## Definition of green
The test runner's exit code is 0. The boot log has zero `ERROR`/`SCRIPT ERROR` lines. The screenshot tour produced every expected PNG and nothing is clipped or blank.
~~~~

### `.claude/skills/crypto-accuracy-check/SKILL.md`

~~~~markdown
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
~~~~

## 0.3 `CLAUDE.md`

~~~~markdown
# The Ashen Codex: working notes for Claude

- Source of truth: `PROMPT.md`. Decisions: `docs/DECISIONS.md`. Blockers: `docs/BLOCKERS.md`. Re-read all three after any context compaction.
- Engine: Godot 4.x via `$GODOT` (`godot` or `./tools_dev/godot.sh`). GDScript, statically typed.
- Skills: `.claude/skills/grimdark-voice` (all writing), `godot-headless-qa` (all Godot commands and GDScript), `crypto-accuracy-check` (audits). Subagents must Read the relevant SKILL.md first.
- Never hard-code ciphertext or player-facing strings. Crypto logic lives only in `core/crypto/`.
- Commit at the end of every phase. Never push.

# Compact instructions
When compacting, preserve: the current phase and next step, failing tests, open DoD items, and file paths recently changed.
~~~~

---

# ROLE AND MISSION

You are a senior game developer, technical designer, and applied cryptographer working **alone and autonomously**. Build a **production-quality vertical slice** of an original mobile game called **THE ASHEN CODEX** in **Godot 4** (GDScript, statically typed). The slice is **Act I: complete, polished, and shippable**. The architecture must also carry Acts II–V without a rewrite.

**Work continuously.** Don't stop to ask questions or to check in. When something is ambiguous, pick the option that best fits the design pillars, log it in `docs/DECISIONS.md` (one line: decision, reason), and keep going. Stop only when every item in **§11 Definition of Done** passes with evidence, or when a blocker you cannot resolve is written up in `docs/BLOCKERS.md` together with the workaround you tried. Then continue with everything the blocker doesn't affect.

---

# 1. THE GAME IN ONE PARAGRAPH

This is a grimdark, M-rated **narrative codebreaking game** for **mobile portrait**. You play **Isaak Varr**, a *pale-blood* (a half-vampire) and a former cipher-hunter of the **Order of the Silent Quill**, monks who hunt vampires by reading their mail. Isaak is chained in a vault beneath the **Undying Court's** library. There he tells his story to **Marquise Ottilie Dray**, the Court's archivist and a vampire cryptanalyst, who wants one thing: *how did the Order break our ciphers?* Every chapter he tells is a memory, and each memory is a set of puzzles. The player breaks real ciphers using **tactile, touch-first tools**: rotating cipher wheels, dragging letter tiles, flipping bit-beads, dragging cribs. Behind all of it is **the Thirst**: Isaak's vampire hunger rises every time he brute-forces, guesses wrong, or asks for help. Cleverness keeps him human. Laziness feeds the monster.

**Theme and tagline: *"Everything eternal repeats."*** Vampires are immortal, so they are arrogant about secrecy. They reuse keys, reuse pads, and never rotate anything. Repetition is how you break them. Every attack in the game is, at some level, an exploit of something that repeats. The theme should show up in the writing, the puzzle order, and the final twist of Act I.

## Design pillars (break ties with these)
1. **The crypto is real.** Every cipher and attack is mathematically correct, and the player uses the actual technique (frequency analysis, Kasiski, index of coincidence, Hamming distance, crib-dragging). Mechanics are never faked with lookup tables.
2. **Hands on the math.** No typing of math. The player manipulates the concept physically with thumbs.
3. **Insight is cheaper than force.** The Thirst makes brute force possible but costly, so the elegant path always feels better.
4. **Grimdark and crude.** Profanity, blood, bleak choices, gallows humor. Violence is written, never gratuitous in the visuals.
5. **Balanced learning.** Roughly 50/50 game and education. A player who finishes Act I can explain and carry out every Act I attack on paper.

## Original IP: hard rule
The tone is *in the vein of* grimdark vampire fantasy such as Jay Kristoff's *Empire of the Vampire*, but **every name, place, faction, term, and plot beat must be original**. The banned-terms list lives in the `grimdark-voice` skill. Before finishing, grep the repo for every banned term and include the grep output in the final report.

---

# 2. PLATFORM AND TECH CONSTRAINTS

- **Engine:** Godot 4.x, latest stable. Record the exact version in the README. GDScript with **static typing everywhere** (`var x: int`, typed arrays, typed returns). Turn on the project setting that warns on untyped declarations and keep the warning count at zero.
- **Target:** mobile portrait. Base resolution 1080×1920, stretch mode `canvas_items`, aspect `expand`. Respect safe areas (notch and home bar) via `DisplayServer.get_display_safe_area()`. Touch targets ≥ 48 dp. Single-thumb reachability: primary actions go in the bottom 60% of the screen.
- **Input:** touch first (drag, rotate gesture on the wheels, long-press, tap). Mouse emulation must work so it plays on desktop for testing. Use haptics (`Input.vibrate_handheld`) on key moments, with a toggle.
- **Exports:** configure export presets for Android, iOS, Linux/Windows desktop, and Web. You don't need to produce signed mobile builds, but the presets must be valid.
- **Performance:** 60 fps on a mid-range phone. No per-frame allocations in hot paths. Shaders must be mobile-safe and work on the Compatibility renderer (`--rendering-driver opengl3`).
- **Renderer:** use **Mobile** or **Compatibility**. Record the choice and the reason in DECISIONS.md.
- **Dependencies:** minimal. Vendor **GUT** into `addons/gut` for tests if you can download it. Otherwise write the fallback runner described in the `godot-headless-qa` skill. No other third-party runtime addons.
- **Language:** English only, but every player-facing string goes through `tr()` with keys in a CSV translation table so localization can come later.

---

# 3. ARCHITECTURE (must support Acts II–V)

Design for data-driven content. Suggested layout (adapt it, but justify changes in DECISIONS.md):

```
res://
  core/crypto/           # PURE logic, no Node dependencies, fully unit-tested
    caesar.gd, substitution.gd, vigenere.gd, xor_ops.gd,
    analysis/ frequency.gd, kasiski.gd, index_of_coincidence.gd,
              hamming.gd, english_score.gd
    bytes_util.gd        # hex/base64/ascii/bits conversions
    rng.gd               # seeded PCG for deterministic puzzle variants
    # stubs + interfaces for later acts: block_cipher.gd (toy SPN/AES-lite),
    # modes.gd, hash_toy.gd, modmath.gd (safe mulmod, modpow, egcd, modinv, CRT),
    # bigint.gd (interface only; document the 64-bit int limit and the Act IV plan)
  core/game/
    thirst.gd            # Thirst model (autoload service)
    progression.gd       # chapters, puzzle unlocks, grades
    save_service.gd      # versioned JSON in user://, migrations, atomic write
    codex_service.gd     # unlocked Codex entries
    hint_service.gd      # tiered hints, Thirst costs
    settings_service.gd
    event_bus.gd
  content/
    chapters/*.tres      # ChapterDef resources
    puzzles/*.tres       # PuzzleDef: tool, plaintext source, normalization, key rules,
                         # seed policy, thirst costs, hints[3], codex unlocks, narrative hooks
    dialogue/*.json      # confession frame + in-memory scenes (simple custom format)
    codex/*.tres
    i18n/strings.csv
  tools/                 # one scene per tactile tool, reusable across puzzles
    cipher_wheel/, substitution_board/, tally_scroll/, multi_wheel/,
    kasiski_lens/, column_loom/, bit_rosary/, key_dial/, hamming_comb/, crib_dragger/
  ui/ theme/, shaders/, components/
  scenes/ boot, title, confession_vault, memory_scene, puzzle_host, codex, settings, credits
  audio/ generated/
  tests/ unit/, integration/, solvers/
  tools_dev/             # godot.sh, SFX synth, texture gen, screenshot_tour.tscn, lint
docs/
qa/
licenses/
```

Architectural rules:
- **Ciphertext is never hard-coded.** Each puzzle defines plaintext, key or key rules, and a seed. The crypto core generates the ciphertext at load time. That makes correctness provable and variants trivial to add.
- **PuzzleDef is declarative.** Adding a puzzle needs zero new code if it uses an existing tool.
- **Tools are dumb views over the crypto core.** No crypto math inside UI scripts.
- **Every puzzle ships with a reference solver** (in `tests/solvers/`) that solves it *using the intended technique* (for example, the frequency-analysis solver really uses frequencies). That proves it can be solved.
- **Deterministic:** same seed, same puzzle. Store seeds in the save file.
- **Autoloads:** keep them few (EventBus, Thirst, Save, Settings, Audio). Everything else is injected or uses signals.

---

# 4. CORE SYSTEMS

## 4.1 The Thirst (pressure system)
- Range 0–100, carried *within* a chapter and partly restored between chapters through story beats (grimdark: what Isaak feeds on is a story choice and has consequences).
- **Free:** using analysis tools that reveal information (histograms, lenses, gauges). *Players must never be punished for learning.*
- **Costs** (tunable in a single `thirst_config.tres`): wrong answer commit (+8), each brute-force "trial" in puzzles flagged `brute_force_costed` (+1 to +3), hint tier 1 (+5), tier 2 (+12), tier 3 (+25).
- **Thresholds with escalating feedback:**
  - 40+: heartbeat audio layer, faint red vignette.
  - 65+: ink bleeds, text in *non-critical* UI wobbles, whispers in the Marquise's margin notes.
  - 90+: pulse and screen desaturation.
  - 100: **Frenzy**. A short written scene with a real narrative consequence (for example, Isaak kills the courier and loses a clue, and the puzzle resets with a harder seeded variant). Log the frenzy in the save file. Later dialogue references it.
- Thirst effects must **never** obscure the information needed to solve the puzzle. A **Reduce Motion / Clear Mind** accessibility toggle turns off all distortion shaders.
- **Grade per puzzle** from Thirst spent: *Sanctified* (≤ 10), *Stained* (≤ 35), *Damned* (> 35). Show it on the results page (the "folio"). Chapter summary shows the grades.

## 4.2 The Codex (in-world grimoire)
- Isaak's cipher-grimoire, illuminated-manuscript style. Each concept unlocks an entry following the format in the `grimdark-voice` skill: explanation, worked example with a live mini-widget, "How the Court got it wrong", a Scribe's Aside (the real-world note), and Kett's margin notes.
- It's reachable from any puzzle via a bookmark tab. Reading it is free.
- The entries are the **learning ledger**. Write them accurately and concisely. Verify them with the `crypto-accuracy-check` skill.

## 4.3 Tiered hints
Three tiers per puzzle: **Nudge** (what to look at), **Concept** (which technique and why), **Near-answer** (the specific next step, never the final answer). Hints are voiced as memories of **Brother Kett**. Each tier costs Thirst.

## 4.4 Confession frame and dialogue
- Between memories: the **Vault**. Candlelit cell, chains, the Marquise writing at a lectern. Short exchanges. After some puzzles she makes a technical remark about her own house's mistakes.
- In memories: scenes told in the past tense, with intercepted letters as the main in-mission storytelling. **Decrypted plaintexts are story content.** Write them as real letters between vampire nobles, stewards, and thralls: petty, cruel, bureaucratic, horrifying.
- Build a small dialogue runner: speaker, portrait key (procedural silhouette), text, optional choices, flags, Thirst deltas. Typewriter reveal, tap to skip, fast-forward, and a history log.
- One meaningful choice per chapter, at minimum. The flags persist and show up in later text.

## 4.5 Save, settings, meta
- Autosave at every puzzle transition and on app pause (`NOTIFICATION_APPLICATION_PAUSED`). Versioned schema with a migration function. Atomic write (temp file, then rename). Survives a corrupted file by falling back to a backup.
- Settings: text size (3 steps), Reduce Motion / Clear Mind, haptics, master/music/SFX volume, hint confirmation, reset progress (double confirm).
- Boot: an M-rated content warning (blood, violence, strong language), then the title.

---

# 5. ACT I CONTENT: "THE TITHE LETTERS"

**Story setup.** Years ago, House **Morrow-Veil** ruled the marsh-village of **Hollowmere** through a blood tithe collected every new moon. Its steward sent orders by raven and thrall-courier. The Order of the Silent Quill sent young Isaak and Brother Kett to intercept the letters, find out when and where the next tithe would be taken, and stop it. As the ciphers get stronger, the story escalates: a thrall informant inside the village, a missing child on the tithe list, and at the end, **proof that someone inside the Order is feeding the House its keys**. That's the cliffhanger that sends the story into Act II. In the Vault, the Marquise reacts to each break. Her final line of the act should turn the theme against Isaak (the Order repeats too).

**Puzzle sequence (12 puzzles, three sub-chapters).** For each puzzle: learning objective, tool, design note, and anti-cheese rule. Write the plaintext letters yourself, following the `grimdark-voice` length budgets. The solvers verify they can be solved.

### I.i: "The Raven's Wheel" (shift ciphers)
1. **The First Letter.** Caesar shift, **Cipher Wheel** tool (drag the outer ring). A short note. Rotation is free and the preview is live. *Tutorial:* learn the controls and the idea of a key. Kett introduces himself.
2. **The Rusted Wheel.** Caesar again, but the wheel is "rusted": each notch turned costs +1 Thirst (`brute_force_costed`). The free **Tally Scroll** (frequency histogram against the English baseline) lets the player spot that cipher-letter X is almost certainly E and jump straight to the key. *Lesson:* a small key space can be brute-forced, but statistics is cheaper. Codex: key space.
3. **Thirteen Turns.** ROT13 and Atbash as a pair of "court vanity ciphers". The player has to identify *which* scheme (both wheel modes available). *Lesson:* a scheme with no secret key is not encryption. Codex: Kerckhoffs's principle, with Kett swearing about it.

### I.ii: "The Steward's Alphabet" (monoalphabetic substitution)
4. **The Tithe Roll.** Full substitution cipher. **Substitution Board**: drag glyph tiles onto plaintext slots, the message updates live, letters can be locked. Plus the Tally Scroll. A long letter. *Lesson:* 26! keys, broken anyway. Anti-cheese: committing a wrong full mapping costs Thirst. Partial reveals are free.
5. **The Signature.** A shorter substitution letter where plain frequency analysis alone is ambiguous. A **crib** is available: the steward always signs "Your servant in eternity" (the theme). The player drags the crib to find where it fits, which pins down many letters. *Lesson:* known plaintext (cribs). Codex: cribs, and how the Bletchley Park codebreakers exploited formulaic messages (brief and accurate).
6. **Bigrams in the Marsh.** Substitution with deliberately flattened single-letter frequencies. The Tally Scroll adds a bigram/trigram tab (TH, HE, THE, ING). *Lesson:* structure leaks beyond single letters.

### I.iii: "The Many-Toothed Key" (polyalphabetic → XOR)
7. **The Steward Grows Clever.** Vigenère. **Multi-Wheel** tool: N stacked wheels. The key length is given in the story (Kett stole it), so the player sets each wheel by frequency per column. *Lesson:* Vigenère is several Caesars interleaved.
8. **Kasiski's Lens.** Vigenère with an unknown key length. **Kasiski Lens**: long-press shows repeated trigrams with their spacings on a ruler, and a factor tray highlights common divisors. The player picks the key length, then solves as in #7. *Lesson:* repetition in ciphertext leaks the key length (the theme, made explicit).
9. **The Loom of Columns.** Vigenère on a short text where Kasiski is weak. **Column Loom**: a slider for key length N splits the ciphertext into N colored strands, with an **Index of Coincidence** gauge (styled as a "blood purity" vial) that jumps near 0.066 at the right N. Then each strand gets its own wheel. *Lesson:* index of coincidence.
10. **Bit Rosary.** Introduces bytes and XOR. **Bit Rosary**: 8 beads per byte, tap to flip, a toggle for hex/binary/ASCII views, and an XOR "chalice" where two strands are poured together. Puzzles inside: find the byte that turns A into B, and show that XORing twice undoes it. Then **single-byte XOR** with the **Key Dial** (0–255) and an "English-ness" gauge that uses the same scoring function as `english_score.gd`. *Lesson:* XOR is its own inverse, and single-byte XOR is just Caesar on bytes. Dial turns are free here, since the lesson is the scoring function.
11. **The Litany Key.** Repeating-key XOR (the vampire's key is a line of their own liturgy). **Hamming Comb**: for key sizes 2–40, shows a bar chart of normalized average Hamming distance, and the lowest bar is the likely key size. Then the text is transposed into blocks, each solved with the Key Dial. *Lesson:* this is Vigenère again, in bytes. Everything eternal repeats.
12. **BOSS: The Twice-Used Pad.** The steward, lazy in his immortality, encrypted **two** letters with the **same** one-time pad. **Crib Dragger**: show C1 ⊕ C2. The player drags guessed words (a crib tray seeded with story-plausible words, plus custom crib entry via an in-game glyph keyboard) along the XOR stream, and correct placements reveal readable fragments of the *other* message. The letters reveal the tithe night **and** the Order's traitor. The Thirst runs hot on purpose. *Lesson:* a one-time pad is perfect only if it's used once, and key reuse is fatal. The Codex entry ties this forward to modern nonce reuse (stream ciphers, CTR, GCM), setting up later acts.

**After #12:** the chapter's big choice (for example, warn Hollowmere and burn the Order's trust, or stay silent to hunt the traitor), a written consequence, the Marquise's final reaction, a chapter folio with grades, and a "To be continued: Act II, *The Stained Glass*" card.

**Acts II–V** are stubbed only as data plus Codex placeholders, so the architecture is exercised. Write this curriculum map into `docs/CURRICULUM.md`:
- **II, The Stained Glass:** toy block cipher, ECB patterns (the "stained glass" image), CBC bit-flipping, padding oracle ("the confessor who only says yes or no").
- **III, Blood Sigils:** hashes, birthday attacks, length extension, HMAC.
- **IV, The Court of Primes:** modular arithmetic, RSA (small e, common modulus, Wiener), Diffie–Hellman, discrete log, ECC intuition. This needs arbitrary-precision integers, so document the chosen bigint approach as an open decision.
- **V, The Ward and the Whisper:** replay and MITM, timing side channels, ECDSA nonce reuse (the theme's final form), a zero-knowledge proof as the redemption mechanic.

---

# 6. TACTILE TOOL QUALITY BAR

Each tool is a reusable scene with:
- Physically satisfying feel: inertia and detents on the wheels, snap on drops, magnetic slots, subtle squash on tiles, haptic ticks.
- Instant visual feedback. Every manipulation updates derived views within the same frame.
- Clear affordances without tutorials after the first use. First-use coach marks drawn as ink annotations.
- Works one-handed in portrait at 360×640 dp (test that size too).
- Undo (at least 20 steps) wherever a tool changes state.
- **Anti-cheese review:** for every puzzle, write in the PuzzleDef comment why it can't be solved by eyeballing a free live preview without using the target concept. If it can, redesign it (cost the trials, shorten the visible preview, or require a committed answer).

---

# 7. ART DIRECTION: ILLUMINATED MANUSCRIPT, GRIMDARK

- **Look:** aged vellum and parchment, iron-gall black ink, **blood-red rubrication**, tarnished gold leaf, woodcut-style engravings, candle glow, soot. Gothic blackletter for titles, a readable old-style serif for body text, a monospace for bytes.
- **Everything procedural or code-generated, but it must look finished:**
  - Parchment: a shader with layered noise (fibers, stains, foxing, edge burn). A per-page seed gives variety.
  - Ink: text with slight per-glyph jitter and ink-pooling (a shader on labels, turned off by Reduce Motion).
  - Illuminated drop-caps: procedurally framed with vine or knot borders drawn from line primitives.
  - Portraits: procedural silhouettes with red rim-light (the Marquise, Kett, Isaak, the steward), built from `Polygon2D` and shaders. Moody, not cartoonish.
  - Blood: shader drips and splatters on the Thirst threshold events and at the frenzy.
  - Candle-flicker lighting on the Vault scene (a `PointLight2D` or shader).
- **Fonts:** use SIL OFL fonts if you can download them (for example UnifrakturMaguntia or Pirata One for titles, IM Fell English or EB Garamond for body, JetBrains Mono for bytes). Put the licenses in `/licenses`. If there's no network, fall back to `SystemFont` and log it.
- **Contrast and accessibility:** body text ≥ 4.5:1 contrast. Red is never the only signal; pair it with shape or icon. Scalable text.
- **Asset manifest:** alongside the procedural versions, write `docs/ASSET_MANIFEST.md` listing every visual and audio asset: ID, where it's used, current procedural implementation, target spec for an artist or AI-art pass (dimensions, style prompt, palette hex codes), and how to swap it in (path conventions, so replacing a file needs no code changes).

---

# 8. AUDIO: PROCEDURAL AND SHIPPABLE

- Write `tools_dev/synth_sfx` (a GDScript tool or Python script) that **generates WAV files** in the sfxr style: quill scratch, page turn, wheel detent tick, tile snap, bead click, chalice pour, wrong-commit (a sick low thud), heartbeat (layered by Thirst), frenzy sting, chapter-complete toll.
- Ambience: a procedurally synthesized low organ/choir drone and room tone for the Vault, and marsh wind for the memories. Loop seamlessly.
- An audio bus layout (Master, Music, SFX, Ambience, UI) with ducking during dialogue.
- List every sound in the ASSET_MANIFEST with an upgrade spec.

---

# 9. WRITING

All writing follows the **`grimdark-voice` skill** (voices, tone limits, length budgets, letter format, banned terms). Also:
- Hint and Codex text must be **technically correct**, checked against the `crypto-accuracy-check` skill.
- Length target for Act I: roughly 60–90 minutes of play for a first-time player.
- Put all text in content files and the translation CSV, never hard-coded in scripts.

---

# 10. EXECUTION PLAN (follow in order; commit after each phase)

0. **Bootstrap and recon** (§0).
1. **Design docs** (tight, no filler): `docs/GDD.md` (pillars, loop, Thirst, grading, structure), `docs/CURRICULUM.md` (all acts, objectives, attack prerequisites), `docs/ACT1_SCRIPT.md` (beat sheet plus all letters in plaintext), `docs/TECH_DESIGN.md` (architecture, data schemas, save schema). Also create `docs/DECISIONS.md` and `docs/BLOCKERS.md`.
2. **Crypto core plus tests.** Implement every Act I primitive and analysis function as pure code. Unit-test them against known vectors (the Cryptopals Set 1 Challenge 5 repeating-key XOR vector with key "ICE"; Caesar and Vigenère textbook vectors; IoC of English ≈ 0.066; Hamming("this is a test","wokka wokka!!!") = 37). Property tests: decrypt(encrypt(m,k),k) == m over seeded random inputs.
3. **Framework:** project settings, autoloads, save/load plus migration, settings, event bus, scene transitions (ink-bleed wipe), the Thirst service, the hint service, the Codex service, the dialogue runner, PuzzleDef/ChapterDef resources, puzzle host.
4. **Tools:** build the ten tactile tools as reusable scenes. Get each one playable in a sandbox scene (`scenes/dev/tool_sandbox.tscn`) before content goes in.
5. **Content:** all 12 puzzles, the letters, dialogue, Codex entries, hints, the choice, the frenzy variants, the chapter folio.
6. **Solvers plus integration tests:** one reference solver per puzzle, using the intended technique. An integration test loads each PuzzleDef, generates ciphertext, runs the solver, and asserts success. Test the Thirst math, the grade thresholds, a save/load round trip mid-chapter, save migration from a fake v0 file, and a corrupted-save fallback. Then run the **crypto audit** (§12).
7. **Art and audio pass:** shaders, procedural textures, fonts, SFX generation, ambience, and juice (tweens, particles, haptics).
8. **Automated screenshot tour:** `tools_dev/screenshot_tour.tscn` boots the game, walks every screen and every puzzle's start and solved states, and saves PNGs to `qa/screenshots/<resolution>/`. Run it at 1080×1920 and 720×1280 with a real renderer (see the `godot-headless-qa` skill), then **look at the screenshots**. Critique them against §7 and fix what looks amateur: alignment, contrast, empty space, clipped text, safe areas.
9. **Self-review and fix loop:** run the full test suite, fix everything, then go through §11 line by line. Write `docs/PLAYTEST_REPORT.md`: a simulated first-time-player walkthrough per puzzle (what they'd try, where they'd get stuck, whether the hints resolve it, expected Thirst spend and grade), plus the adversarial-player findings (§12). Act on the findings. Do at least **two** full review-and-fix loops.
10. **Finalize:** README (how to run, test, export, controls, project map, exact Godot version), CHANGELOG, `docs/NEXT_STEPS.md` (a prioritized plan for Act II), the banned-terms grep, zero untyped-code warnings, zero errors in the boot and tour logs.

---

# 11. DEFINITION OF DONE (every item must be true, with evidence in PLAYTEST_REPORT.md)

**Functional**
- [ ] New game → content warning → title → Vault → all 12 Act I puzzles → choice → ending card, playable start to finish with touch and with mouse.
- [ ] Every puzzle can be solved by its intended technique (a solver test proves it) and can't be cheesed via a free preview (documented per puzzle).
- [ ] Thirst costs, thresholds, frenzy, and grades all work. Frenzy triggers its narrative consequence and the harder variant.
- [ ] Hints: 3 tiers per puzzle, correct and escalating, Thirst charged.
- [ ] Codex: an entry for every concept, reachable from any puzzle, with at least one live mini-widget per sub-chapter.
- [ ] Save/resume at any point, including mid-puzzle tool state. Migration and corruption fallback are tested.
- [ ] Settings all work, including Reduce Motion removing every distortion effect.

**Quality**
- [ ] 100% of crypto core functions unit-tested. All tests pass headless with a single command documented in the README.
- [ ] Zero script errors or warnings in a headless boot plus the automated tour.
- [ ] Static typing throughout. Untyped-declaration warnings enabled and at zero.
- [ ] Portrait layout correct at 1080×1920, 720×1280, and 360×640 dp. Safe areas respected. No clipped text at the largest text size.
- [ ] Screenshots reviewed (or the blocker documented if no display was available). The game reads as an intentional, cohesive, illuminated-manuscript grimdark product, not a prototype.
- [ ] Crypto audit run by an independent subagent. Every WRONG or MISLEADING finding is fixed and re-verified.
- [ ] All strings in the translation CSV.
- [ ] Export presets present for Android, iOS, desktop, and Web.

**Content and IP**
- [ ] Act I script complete, M-rated voice consistent, technically accurate teaching text.
- [ ] Banned-terms grep is clean (output included in the final report).
- [ ] Font and asset licenses in `/licenses`. ASSET_MANIFEST complete.

**Docs**
- [ ] GDD, CURRICULUM, ACT1_SCRIPT, TECH_DESIGN, DECISIONS, BLOCKERS, ASSET_MANIFEST, PLAYTEST_REPORT, NEXT_STEPS, ENVIRONMENT, README, CHANGELOG, CLAUDE.md.

---

# 12. ORCHESTRATION

You are the **lead**. You own the plan, the architecture, and every merge. Delegate to subagents only where it saves context or adds independence. **Every subagent prompt must tell it to Read the relevant skill file(s) first**, plus the specific docs it needs (subagents don't see this brief unless you tell them to read `PROMPT.md`).

- **Parallel content authoring (Phase 5):** one subagent per sub-chapter (I.i, I.ii, I.iii), using the Sonnet model. Each reads `grimdark-voice` and `docs/TECH_DESIGN.md`, then writes its PuzzleDefs, letters, hints, and Codex entries against the schemas. You review, fix voice drift, and integrate.
- **Independent crypto auditor (end of Phase 6, and again after Phase 9 fixes):** a fresh subagent on the Opus model that did not write the crypto core. It reads `crypto-accuracy-check` and audits `core/crypto/`, the solvers, and all Codex, hint and Marquise text. It reports; you fix.
- **Adversarial players (Phase 9):** one subagent per sub-chapter tries to break each puzzle. Can it be cheesed? Is it unsolvable without hints? Is a hint wrong or too revealing? Findings go into PLAYTEST_REPORT.md.
- **Screenshot critic (Phase 8):** a subagent that reads `godot-headless-qa` and §7 of PROMPT.md, views the PNGs, and returns a ranked list of visual fixes.
- **QA runner:** send long test runs and log reading to a subagent that reads `godot-headless-qa` and returns only failures and a summary.
- Don't spawn agent teams or dynamic workflows. Keep at most 3–4 subagents running at once. Commit before and after every fan-out.

---

# 13. FINAL REPORT

When done, print a concise summary: what was built, test results (counts), screenshot tour location, crypto-audit results, the banned-terms grep output, known issues ranked by severity, and the top five things a human should playtest first on a real phone.
