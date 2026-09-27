# Asset Manifest

Everything in the slice is procedural or code-drawn. This list gives each asset's ID, where it is used, how it is made now, the target spec for an artist or AI-art pass, and how to swap it in without code changes.

Palette (hex): vellum `#e9dcc0`, vellum mid `#d8c6a0`, vellum shadow `#b89f74`, iron-gall ink `#1e1a16`, faded ink `#4a3f33`, rubric red `#8e1b1b`, bright blood `#b3261e`, tarnished gold `#b08d3c`, gold light `#d4b25e`, soot `#14100d`, stone `#2a231e`, candle `#f2b455`.

## Visual

| ID | Used in | Current implementation | Target spec | Swap-in |
|---|---|---|---|---|
| parchment | every card, folio, Codex, dialogue box | `ui/shaders/parchment.gdshader` (fbm tone, fibres, stains, foxing, burnt edge) on `ParchmentPanel` | Tileable vellum, 1024x1024, 9-slice-able burnt border, palette above; prompt: "aged calfskin vellum, iron-gall stains, foxing, candle-scorched edges, flat top light" | Add a `texture` sampler to the shader or replace `ParchmentPanel._draw` with a `StyleBoxTexture` from `res://ui/art/parchment.png` |
| ink_wipe | screen transitions | `ui/shaders/ink_wipe.gdshader` | 8-frame ink-bleed flipbook, 1080x1920, black ink on transparent | `res://ui/art/ink_wipe_XX.png`, read by the wipe shader as `uniform sampler2D` |
| thirst_overlay | Thirst 40/65/90, frenzy drips | `ui/shaders/thirst_overlay.gdshader` | Edge vignette + ink-corner masks 1080x1920; 6 blood drip strips 128x512 | `res://ui/art/thirst_*.png` as shader samplers |
| portrait_isaak, portrait_kett, portrait_marquise, portrait_steward, portrait_lord, portrait_wenna, portrait_courier | dialogue screen | `ui/components/portrait.gd` polygons + red rim light | 900x1100 PNG, woodcut/engraving silhouette, black on transparent, single red rim light from the right; Kett one-eyed, hooded; Marquise high collar, piled hair; Isaak gaunt, chained | Drop `res://ui/portraits/<speaker>.png`; `Portrait` loads it automatically |
| vault_backdrop | title, Vault dialogues | `ui/components/vault_backdrop.gd` (stone courses, arch, chains, lectern, flickering candles) | 1080x1920 painted scene, candle-lit cell, lectern right, chains left, keep the lower 45% dark for UI | `res://ui/art/bg_vault.png`; add a `TextureRect` in `VaultBackdrop._draw` path when present |
| marsh_backdrop | memory dialogues, puzzle host | `vault_backdrop.gd` kind `marsh` (sky gradient, moon, reeds, fog) | 1080x1920, moonlit marsh, reeds, low fog, cold palette `#0b0d14`-`#1c2324` | `res://ui/art/bg_marsh.png` |
| drop_cap | folio letters, Codex entries | `ui/components/drop_cap.gd` (fraktur capital, gold frame, procedural vine and knots) | 26 illuminated capitals A-Z, 256x256, gold leaf, vine border, rubric letter | `res://ui/art/caps/<L>.png` (add a texture branch in `DropCap._draw`) |
| grade_seal | folio, summaries | `ui/components/grade_seal.gd` (three distinct shapes) | 3 wax seals 256x256: haloed cross (Sanctified), blot (Stained), cracked skull seal (Damned) | `res://ui/art/seal_<grade>.png` |
| cipher_wheel, multi_wheel, key_dial, bit_rosary, hamming_comb, tally_scroll, substitution_board, kasiski_lens, column_loom, crib_dragger | tools | `_draw()` in `tools/<id>/<id>.gd` | Brass and vellum instrument art per tool (wheel rings 1024x1024 with transparent centre; bead sprite 128x128 on/off; comb spine 1024x128) | Tools keep geometry in code; replace fills with `draw_texture_rect` from `res://tools/<id>/art/` |
| thirst_vial | puzzle header | `ui/components/thirst_vial.gd` | Glass vial 512x128 with separate blood fill mask | `res://ui/art/vial.png`, `vial_fill.png` |
| icon | app icon | `icon.svg` | 1024x1024 blood drop on vellum with gold ring | replace `icon.svg` |
| fonts | all text | UnifrakturMaguntia (drop caps), Pirata One (titles), EB Garamond (body), IM FELL English (letters), JetBrains Mono (ciphertext, bytes) | keep; all SIL OFL 1.1 | `ui/theme/fonts/`, referenced in `ui/theme/theme_builder.gd` |

## Audio (all `audio/generated/<id>.wav`, 22.05 kHz mono, built by `tools_dev/synth_sfx.py`)

Replace a file with a same-named WAV (any rate, mono or stereo) to upgrade it; `Audio` loads by name. Loops (`amb_*`, `drone_*`, `heartbeat`) are set to loop at runtime.

| ID | Used when | Current synthesis | Upgrade spec |
|---|---|---|---|
| quill | transitions, commits, pins | high-passed noise strokes | real quill on vellum, 0.3 s, dry |
| page_turn | dialogue advance, Codex, tabs | swept filtered noise | heavy vellum page turn, 0.5 s |
| detent | wheel/dial notches | click + 1.8 kHz ping | brass ratchet click, 60 ms, 3 variations |
| tick | selections, sliders | 2.6 kHz triangle blip | soft wooden tick, 40 ms |
| tile_snap | tiles placed, modes | swept 420 Hz knock | bone tile set on wood, 120 ms |
| snap | stage complete | 660 Hz knock | latch closing, 100 ms |
| bead | rosary beads | glassy two-partial ping | glass/bone bead click, 150 ms |
| pour | XOR chalice | wobbling low-passed noise | wine poured into metal chalice, 0.9 s |
| wrong / wrong_soft | wrong commit / locked wheel | low sweep + detuned groan / short thud | sick low thud with organic squelch, 0.7 s / 0.25 s |
| ui_tap | buttons | 900 Hz triangle blip | muted parchment tap |
| toll | chapter/act complete, Sanctified | inharmonic bell partials | distant cathedral bell, 3 s |
| solve | puzzle solved | rising bell fifth | small hand-bell, 1.2 s |
| frenzy | frenzy sting | dissonant cluster + tearing noise + slam | orchestral stab + snarl, 1.6 s |
| heartbeat | Thirst 40+ (pitch and volume rise per level) | lub-dub low sines, 1 s loop | close-mic heartbeat loop, 60 bpm |
| amb_vault | Vault | low-passed room noise, 8 s loop | stone room tone with distant drips, 30 s loop |
| amb_marsh | memories, puzzles | modulated filtered wind, 8 s loop | marsh wind, reeds, frogs, 30 s loop |
| drone_vault | Vault music bed | organ-like triangle stack (55 Hz family) | low organ + wordless choir drone, 60 s loop |
| drone_marsh | memory music bed | low triangle stack (49 Hz family) | cello/viol drone, 60 s loop |

Buses: Master > Music (drones), Ambience, SFX, UI. Music and Ambience duck by 9 dB while dialogue is on screen.
