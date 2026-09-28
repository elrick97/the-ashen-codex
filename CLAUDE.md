# The Ashen Codex: working notes for Claude

- Source of truth: `PROMPT.md`. Decisions: `docs/DECISIONS.md`. Blockers: `docs/BLOCKERS.md`. Re-read all three after any context compaction.
- Engine: Godot 4.x via `$GODOT` (`godot` or `./tools_dev/godot.sh`). GDScript, statically typed.
- Skills: `.claude/skills/grimdark-voice` (all writing), `godot-headless-qa` (all Godot commands and GDScript), `crypto-accuracy-check` (audits). Subagents must Read the relevant SKILL.md first.
- Never hard-code ciphertext or player-facing strings. Crypto logic lives only in `core/crypto/`.
- Commit at the end of every phase. Push only to the owner's GitHub remote (`origin`), and only when asked; `tools_dev/publish_web.sh` publishes the playable web build to GitHub Pages.

# Compact instructions
When compacting, preserve: the current phase and next step, failing tests, open DoD items, and file paths recently changed.
