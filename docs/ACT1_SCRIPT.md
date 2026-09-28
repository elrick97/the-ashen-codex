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

Generated by `python3 tools_dev/build_strings.py --script` from `content/i18n/strings.csv`.

### LTR_P01 (57 words, 295 letters)
*From Steward Veneric Soll to Reeve Harl Bassett, by raven*

```
Reeve Bassett,\nThe new moon falls in nine nights. See the tithe-house at Reedmouth aired and swept, the rushes changed, and the rotten planking by the door replaced before the carts arrive. Count every head in the village yourself, cellar and loft besides. Last season's tally was short, and the Lord forgives nothing twice.\nYour servant in eternity,\nVeneric Soll
```

### LTR_P02 (55 words, 263 letters)
*From Reeve Harl Bassett to Steward Veneric Soll, by raven*

```
Steward Soll,\nThree families slipped into the reeds before dawn, the Marles and Pikes among them, gone the moment the tithe bell rang. Send hounds and men enough to beat the marsh; we cannot spare the watch we keep. The cart axle is rotten besides and threatens to break under the next load.\nYour obedient reeve,\nHarl Bassett
```

### LTR_P03_A (47 words, 232 letters)
*From Lady Ysolde Crane to Dame Petra Ashcombe, by hand*

```
Petra,\nHave you seen the steward's ledgers this quarter? Column after column, counted twice and initialed thrice, as if one missing hen might undo the whole house. Dour little man. I hear he weighs the tithe grain himself, and trusts no clerk to carry the scale.\nYours in idleness,\nYsolde
```

### LTR_P03_B (47 words, 226 letters)
*From Dame Petra Ashcombe to Lord Aldric Penrose, by hand*

```
Aldric,\nStrange news from the steward's tower: he no longer writes his tallies plain. His maid says he has taken to an alphabet of his own devising, crossed out and begun again by candlelight. Even the lord seems amused by it, which frightens me more than the ledgers.\nYours,\nPetra
```

### LTR_P03_C (47 words, 198 letters)
*From Lord Aldric Penrose to Lady Ysolde Crane, by hand*

```
Ysolde,\nYou will laugh: I have dressed this letter in one of our little court tricks, and not one soul at court will trouble to unpick it. I confess I am pleased with my own cleverness, and mean to gloat of it at the feast.\nYour admirer in wit,\nAldric
```

### LTR_P04 (216 words, 917 letters)
*From Steward Veneric Soll to Reeve Harl Bassett, by hand*

```
To Reeve Harl Bassett, at Hollowmere, by the Steward's own hand.\nThe tithe roll for the new moon stands thus. The Marsh Row households owe four measures each, save the Coopers, who owe six for their two grown sons and their mother besides. The millers on the Long Causeway owe five measures and a jar of the old vintage the Lord prefers. The Reed cottages by the water owe three measures each, and Widow Anwen owes but two, her holding being the smallest on the row.\nMark this well, Reeve. Of the last tithe, three jars had turned before they reached the tithe-house, gone black and sour in the heat of the cart. The Lord does not accept spoilage as an excuse, and neither will I. See that the jars are packed in wet moss this time, and see that your carters do not dawdle at the ford to drink what is not theirs to drink.\nOne name is added to this roll at the Lady's request, and not for the common roll: the girl called Lise, of the eel-trap cottages. She is not to be counted among the household quotas, and no receipt is to be written for her. You will understand me, Reeve, or in time you will.\nYour servant in eternity, Veneric Soll, Steward of House Morrow-Veil
```

### LTR_P05 (94 words, 377 letters)
*From Steward Veneric Soll to Lord Casimir Morrow-Veil, by raven*

```
My lord Casimir, forgive the haste of this hand.\nOur letters are read. Too many carts turned back at the ford, too many hounds waiting where none should wait, and no road to such knowledge but the raven road. I do not know if the reader is monk or renegade, but I know a fool's habit kept too long. From the next new moon I write in a new hand of my own devising, and the old wheel goes into the marsh mud. Say nothing of this to the household.\nYour servant in eternity, Veneric Soll
```

### LTR_P06 (42 words, 176 letters)
*From the Steward's clerk, Wat Coln, to Warden Mave Tallow, by hand*

```
Warden Tallow,\nThe carts turn south at the ford and climb north to the barn's back door, not the front. The hound naps past the midnight bell; a man stands watch on the stair till the dawn. Burn this fast.\nThe clerk, Wat Coln
```

### LTR_P07 (41 words, 204 letters)
*From Steward Veneric Soll to Warden Mave Tallow, by raven*

```
Warden Tallow,\n\nThe Lord sends a new cipher from his own library, five teeth to its wheel. Use it from this day.\n\nThe carts cross at Blackwater ford after moonrise. Count them twice and say nothing to the reeve.\n\nYour servant in eternity,\nVeneric Soll
```

### LTR_P08 (97 words, 470 letters)
*From Lord Casimir Morrow-Veil to Steward Veneric Soll, by raven*

```
Steward,\n\nYou try my patience. The tithe is not a suggestion, and Hollowmere is not exempt from it. Twice the tithe came short, and twice you blamed the reeve, the weather, the carts.\n\nCollect the tithe at Hollowmere before the new moon, or find yourself replaced before the new moon after that.\n\nBlood is owed, blood is paid, world without end.\n\nHollowmere remembers its tithe even when its steward forgets his sums, and the new moon does not wait on excuses. Recite it until you believe it. Blood is owed, blood is paid, world without end.\n\nSee the tithe is whole.\n\nCasimir Morrow-Veil
```

### LTR_P09 (44 words, 199 letters)
*From Steward Veneric Soll to Warden Mave Tallow, by hand*

```
Tallow,\n\nWord from the manor: the night has moved. Bring the carts before dusk falls, not after moonrise as before. The old crossing floods whenever it rains, so use the north path this time and go quietly. Burn this note once you have read it.\n\nSoll
```

### LTR_P10 (23 words, 84 letters)
*From an unnamed thrall of Hollowmere, passed hand to hand*

```
They watch the north gate after dark now. Do not use the old path again, and burn this once you have read it.
```

### LTR_P11 (116 words, 524 letters)
*From Steward Veneric Soll to Lord Casimir Morrow-Veil, by raven*

```
Casimir Morrow-Veil,\n\nOur friend in the Quill is worth ten spies. He sits among the cipher-monks and copies their manifests before the ink is dry, and for a purse of silver and a promise of turned blood he tells us which routes the Order walks and which raven-roosts they watch.\n\nHe calls himself devout. He is merely for sale, which is a kind of devotion I understand far better than prayer.\n\nThrough him we know the Order reads more of our mail than either of us would like, and that they have not yet broken the new cipher. Use that ignorance while it lasts. Do not write his name where a courier might read it.\n\nYour servant in eternity,\nVeneric Soll
```

### LTR_P12_A (36 words, 166 letters)
*From Steward Veneric Soll to Warden Mave Tallow, by raven*

```
Warden Tallow,\n\nBe ready. The tithe falls on the night of the black moon, at the salt barn. Bring the ledger; count twice. The reeve is not to be trusted with the tally.\n\nYour servant in eternity,\nVeneric Soll
```

### LTR_P12_B (32 words, 169 letters)
*From Steward Veneric Soll to Lord Casimir Morrow-Veil, by raven*

```
Casimir Morrow-Veil,\n\nOur friend in the Quill is no friend. Brother Ansgar sells them our routes, and has done since the salt barn burned. Silence him before new moon.\n\nYour servant in eternity,\nVeneric Soll
```

