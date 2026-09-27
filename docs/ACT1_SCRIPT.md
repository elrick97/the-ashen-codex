# Act I Script: The Tithe Letters

Beat sheet first, then every letter in plaintext (section "Letters"), which is generated from `content/i18n/strings.csv` by `tools_dev/build_strings.py --script` so the doc and the game never drift.

## Cast
| Key | Name | Role |
|---|---|---|
| isaak | Isaak Varr | pale-blood narrator; young novice in memories, chained prisoner in the Vault |
| kett | Brother Kett | one-eyed cipher-monk, Isaak's mentor; voices every hint |
| marquise | Marquise Ottilie Dray | Court archivist and cryptanalyst; the listener |
| steward | Steward Veneric Soll | House Morrow-Veil's steward; writes most letters; signs "Your servant in eternity" |
| lord | Lord Casimir Morrow-Veil | the House's master; bored, cruel, fond of liturgy |
| wenna | Wenna Grobb | thrall informant in Hollowmere; aunt of the child on the list |
| courier | Odo Lusk | thrall-courier caught in I.i |
| (letters only) | Reeve Harl Bassett | Hollowmere's thrall reeve |
| (letters only) | Warden Mave Tallow | keeper of the tithe-house |
| (letters only) | Brother Ansgar | the Order's key-warden, the traitor revealed in #12 |

Places: Hollowmere (marsh village), the Reedmouth salt-barn (the tithe-house), Blackwater ford, the Order's chapter-house at Saint Ebbe's Cut, the Vault under the Court's library.

## Frame (Vault)
- **a1_vault_open**: Isaak wakes in chains. The Marquise at her lectern: she has read the Order's reports and wants the method, not the myth. Isaak bargains for water; she offers ink instead. He begins: Hollowmere, the autumn he was nineteen.
- **a1_vault_i** (after I.i): she critiques her house's shift ciphers; notes whether he fed on the courier. Asks about "the Steward's alphabet".
- **a1_vault_ii** (after I.ii): she admires the crib; admits the Steward's signature was vanity; asks how the many-toothed key fell.
- **a1_vault_end** (after #12 and the big choice): she reveals she already knew about Ansgar; her final line turns the theme on Isaak: the Order repeated too (it reused its trust).
- **Remarks** after puzzles 2, 5, 8, 11: one to three lines each, the Marquise critiquing her own house's cipher discipline.

## I.i The Raven's Wheel
- **a1_i_intro** (memory): Kett and Isaak in the reeds at dusk. Kett downs a raven with a sling. Introduces himself, the wheel, the idea of a key.
- **#1 The First Letter** (Caesar, tutorial). Letter: Steward to Reeve Bassett: prepare the tithe-house, the new moon falls in nine nights, count the heads. 25 to 60 words.
- **a1_p01_after**: Kett: "Now you know what a key is. It's the only thing they're hiding."
- **#2 The Rusted Wheel** (Caesar by frequency; costed notches). Letter: Reeve to Steward: three families fled into the reeds; he asks for hounds and complains the cart axle is rotten. 40 to 60 words, E clearly the most frequent letter.
- **a1_p02_after** + Marquise remark on key space.
- **#3 Thirteen Turns** (ROT13 / Atbash; three court notes). Notes: courtiers' gossip. One mocks the Steward's ledgers; one says the Steward now uses "an alphabet of his own devising"; one is vain nonsense. 25 to 50 words each.
- **a1_i_end**: they catch the thrall-courier Odo Lusk. **Choice:** drain him (-35, `courier_drained`; he dies, and Wenna later fears Isaak) or let him go with a doctored letter and drink Kett's pig's blood (-12, `courier_spared`; Odo later helps).
- Frenzy scene **a1_i_frenzy**: Isaak loses himself on a raven-keeper; the letter is soaked; Kett drags him off; a new letter must be caught.

## I.ii The Steward's Alphabet
- **a1_ii_intro**: Hollowmere by night. Wenna Grobb meets them at the eel-traps; she carries the Steward's roll to the tithe-house and copies it for the Order.
- **#4 The Tithe Roll** (substitution, 150 to 250 words, spaces kept). The roll: quotas by household, spoilage complaints, and one small name added "at the Lady's request, not for the common roll" (the child; implied only).
- **a1_p04_after**: Wenna recognises the name. It is her niece, Lise.
- **#5 The Signature** (substitution with crib, 60 to 100 words, spaces kept). Steward to Lord Casimir: someone reads the ravens; he will change ciphers; signed "Your servant in eternity".
- **a1_p05_after** + Marquise remark on formulaic sign-offs.
- **#6 Bigrams in the Marsh** (letters only, flattened single-letter counts). The Steward's clerk, ordered to write sparingly of the commonest letter, sends the warden the carts' route and the barn's watch. 150 to 250 letters.
- **a1_ii_end**: Wenna, shaking, offers her wrist. **Choice:** drink (-30, `drank_wenna`) or refuse (-5, `refused_wenna`). Isaak promises nothing aloud; Kett does it for him.
- Frenzy scene **a1_ii_frenzy**: Isaak turns on a tithe-house hound and its handler; Wenna sees; a copy is lost.

## I.iii The Many-Toothed Key
- **a1_iii_intro**: the letters change. Kett has stolen a page from the Steward's writing box: "the key has five teeth".
- **#7 The Steward Grows Clever** (Vigenere, period given). Steward to Warden Tallow: a new cipher from the Lord's library; carts cross at Blackwater ford.
- **#8 Kasiski's Lens** (Vigenere, unknown period; 250+ letters with repeated words). Lord Casimir to the Steward: berates him, repeats "the tithe", "Hollowmere", "the new moon" and a liturgical formula.
- **a1_p08_after** + Marquise remark: repetition, her cousin's key.
- **#9 The Loom of Columns** (Vigenere, short, 120 to 200 letters). Hurried note: the tithe night is moved.
- **#10 Bit Rosary** (bytes, XOR, single-byte XOR). The Court's alchemists give the House a counting-bead cipher (numbers as bead strings). Stage 1 and 2 are Kett's lesson; stage 3 is a short thrall note.
- **#11 The Litany Key** (repeating-key XOR, key = a line of the House liturgy). Steward to Lord: "our friend in the Quill" supplies the Order's routes.
- **a1_p11_after** + Marquise remark on liturgy as key.
- **#12 BOSS: The Twice-Used Pad**. Two letters under the same pad. A: Steward to Warden with the tithe night and place. B: Steward to Lord naming Brother Ansgar as the source of the Order's keys. Win when the tithe-night phrase and Ansgar's name are recovered.
- **a1_iii_end**: Kett goes grey. **Big choice:** warn Hollowmere tonight (`act1_warned`: the village scatters into the reeds, the House learns its mail is read, Ansgar vanishes) or stay silent and hunt Ansgar (`act1_silent`: the tithe is taken; Lise's fate stays unspoken; they follow Ansgar's raven). Consequence scene branches on the earlier flags.
- Frenzy scene **a1_iii_frenzy**: Isaak bites Kett's arm. Kett says nothing about it, ever. A crib is lost.
- **a1_vault_end**, act folio, card: "To be continued: Act II, *The Stained Glass*".

## Letters
(Generated section; see the tool note above.)
