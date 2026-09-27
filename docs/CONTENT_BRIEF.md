# Content Brief (Act I writers)

Read first, in this order: `.claude/skills/grimdark-voice/SKILL.md` (voice, tone, length budgets, banned names), `.claude/skills/crypto-accuracy-check/SKILL.md` (every technical claim must match it), `docs/ACT1_SCRIPT.md` (cast, places, beats), `docs/GDD.md`, `docs/TECH_DESIGN.md` section 4 (dialogue JSON format and string key prefixes).

## Environment
- The repo lives in WSL at `/home/ricardo/dev/ashen-codex`. Edit files through `\\wsl.localhost\Ubuntu\home\ricardo\dev\ashen-codex\...` with Read/Write/Edit.
- Run commands with the Bash tool as `~/w_ashen '<command>'` (it runs inside WSL at the repo root). Quote carefully: the command is wrapped in single quotes, so don't put apostrophes inside it; write Python helpers to a file first if you need them.
- Checks you must run and make pass for your keys: `~/w_ashen 'python3 tools_dev/build_strings.py'` (missing keys, ASCII, banned terms, line budgets, dialogue structure) and `~/w_ashen 'python3 tools_dev/check_letters.py P04 P05'` (letter constraints for your puzzles). Missing keys that belong to other writers are fine.
- Touch ONLY your own files (listed in your assignment). Do not edit `.tres` files, scripts, or other writers' files. Do not commit; the lead commits.

## String files
- Your strings go in ONE file: `content/i18n/src/<your file>.csv`, header `keys,en`, two columns. Quote any value containing a comma or quote; double inner quotes (`""`). Newlines inside a value are written as the two characters `\n` (backslash n), never a real line break.
- All text is plain ASCII: straight quotes only, no em dashes (use a comma, colon or " - "), no diacritics.

## Letters (the ciphertext plaintexts)
- Key `LTR_Pnn` (or `LTR_Pnn_A`...), plus `LTR_Pnn_FROM` (or `LTR_Pnn_A_FROM`) = one short line like `From Steward Veneric Soll to Reeve Harl Bassett, by raven`.
- Format: salutation line, `\n`, body (one or more paragraphs separated by `\n`), `\n`, signature as the final line. Written in normal sentence case; the game uppercases where needed.
- Letters are story: petty, cruel, bureaucratic, horrifying. They must not reference keys, ciphers or the game's mechanics unless the story calls for it.
- Obey the per-puzzle constraints in your assignment and in `tools_dev/check_letters.py`.

## Hints (`PZ_Pnn_HINT1..3`)
- Brother Kett's voice, 1-2 sentences each. Tier 1 = what to look at. Tier 2 = which technique and why. Tier 3 = the exact next step, never the final answer.
- Keys are random per player and per variant: never mention a specific key value, shift, cipher letter or key word. Talk about "the tallest bar", "the peak", "each column", not "Q is E".

## Puzzle title and brief
- `PZ_Pnn_TITLE`: the puzzle's name (given in your assignment). `PZ_Pnn_BRIEF`: one line (<= 90 chars) telling the player what to do, in plain words.

## Dialogue (`content/dialogue/<id>.json`)
- Format in TECH_DESIGN section 4. `"id"` equals the file name. `"location"`: `"vault"` (present tense, Isaak chained, the Marquise) or `"memory"` (past tense, Hollowmere). Optional `"ambience"`: `"vault"` or `"marsh"`.
- Every `text` is a CSV key: `DLG_<ID IN CAPS>_01`, `_02`...; choices `DLG_<ID>_C1`, `_C2`. Lines <= 140 characters; choice text <= 60 characters, verb first.
- Speakers: `isaak`, `kett`, `marquise`, `steward`, `lord`, `wenna`, `courier`, `narrator`.
- Scenes are short: 6-16 lines. Vault remarks 2-5 lines.
- Flags you may read (conditions): `courier_drained`, `courier_spared`, `drank_wenna`, `refused_wenna`, `act1_warned`, `act1_silent`, `frenzied_a1_i`, `frenzied_a1_ii`, `frenzied_a1_iii`, `frenzy_count` (number). Use `{"flag": "x"}` or `{"flag": "frenzy_count", "gte": 1}`.
- A choice may carry `"set": {"flag": true}` and `"thirst": -N` (negative restores Thirst).
- The theme "Everything eternal repeats" is woven in, stated outright at most once per scene.

## Codex entries (`CDX_<ID>_*`)
- `_TITLE`; `_BODY` (<= 120 words, plain explanation); `_EXAMPLE` (a worked example; monospace; keep lines <= 40 characters and use `\n`; compute every example with Python before writing it); `_WRONG` "How the Court got it wrong" (<= 50 words, in-world); `_ASIDE` Scribe's Aside (<= 50 words, the real world, modern terms allowed); `_M1`.. Kett's margin notes (<= 25 words each, his voice; mark any simplification honestly in one of them).
- Every factual claim must match the crypto-accuracy-check reference list. Never call a cipher unbreakable without its conditions.

## Final check
Grep your files for the banned names in the grimdark-voice skill. Report back: the files you wrote, the output of both checkers for your keys, and anything you were unsure about.
