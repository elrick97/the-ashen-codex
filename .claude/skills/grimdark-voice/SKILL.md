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
