#!/usr/bin/env python3
"""Writes content/puzzles/*.tres and content/chapters/*.tres from the tables below.

The .tres files are the source of truth at runtime; this generator keeps them consistent
(key naming, seeds, anti-cheese notes). Re-run after editing: python3 tools_dev/gen_content_defs.py
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def hints(n):
    return ["PZ_P%02d_HINT%d" % (n, t) for t in (1, 2, 3)]


PUZZLES = [
    dict(n=1, ch="a1_i", mode="caesar", tools=["cipher_wheel"], letters=["LTR_P01"],
         norm="upper_keep", key={"type": "shift", "min": 3, "max": 23}, params={"show_tally": False},
         costed=False, cost=1, codex=["a1_key"], frenzy="a1_i_frenzy", fo={"costed": True},
         anti="Tutorial. The live preview is the lesson: the player learns that the whole secret is one number on the wheel. "
              "25 non-trivial shifts is small enough that turning the wheel IS the attack; puzzle 2 then prices that attack."),
    dict(n=2, ch="a1_i", mode="caesar", tools=["cipher_wheel", "tally_scroll"], letters=["LTR_P02"],
         norm="upper_keep", key={"type": "shift", "min": 3, "max": 23}, params={"show_tally": True},
         costed=True, cost=1, codex=["a1_keyspace", "a1_frequency"], frenzy="a1_i_frenzy", fo={"trial_cost": 2},
         anti="Rusted wheel: every notch turned and every 'read as E' costs 1 Thirst (2 after a frenzy). Eyeballing the preview "
              "means turning notch by notch (average ~6-13 trials, up to 25), which pushes the grade to Stained or worse. "
              "The free Tally Scroll shows the peak; one 'read as E' costs 1 and usually lands the key: Sanctified."),
    dict(n=3, ch="a1_i", mode="keyless", tools=["cipher_wheel"], letters=["LTR_P03_A", "LTR_P03_B", "LTR_P03_C"],
         norm="upper_keep", key={"type": "scheme_mix", "schemes": ["rot13", "atbash"]},
         params={"question_key": "PZ_P03_Q", "answer_keys": ["PZ_P03_A1", "PZ_P03_A2", "PZ_P03_A3"], "correct_answer": 2},
         costed=False, cost=1, codex=["a1_kerckhoffs"], frenzy="a1_i_frenzy", fo={"costed": True},
         anti="The free preview is deliberate: the lesson is that a keyless scheme falls the moment its method is known "
              "(Kerckhoffs). The assessment cannot be eyeballed: the seal requires naming the scheme of each note and then "
              "answering what actually protects these letters (nothing but the secrecy of the method). Wrong seals cost 8."),
    dict(n=4, ch="a1_ii", mode="substitution", tools=["substitution_board", "tally_scroll"], letters=["LTR_P04"],
         norm="upper_keep", key={"type": "perm"}, params={"ngrams": False},
         costed=False, cost=1, codex=["a1_substitution"], frenzy="a1_ii_frenzy", fo={"wrong_cost": 16},
         anti="26! keys; there is no dial to spin. The preview only shows letters the player has placed, so every letter must be argued from frequency and word patterns. Partial placements are free; sealing a wrong full alphabet costs 8 (16 after a frenzy)."),
    dict(n=5, ch="a1_ii", mode="substitution", tools=["substitution_board", "tally_scroll"], letters=["LTR_P05"],
         norm="upper_keep", key={"type": "perm"}, params={"crib_key": "PZ_P05_CRIB", "ngrams": False},
         costed=False, cost=1, codex=["a1_cribs"], frenzy="a1_ii_frenzy", fo={"crib_key": "PZ_P05_CRIB_SHORT"},
         anti="Frequency alone is ambiguous here: O and T outnumber E in this letter, so a rank-order guess misreads it. The crib strip compares letters only (no spaces), so the player must slide it to where its letter-repeat pattern is self-consistent; 'agrees' means consistent, not proven. Pinning applies about eleven letters at once. The preview never places letters by itself. After a frenzy only IN ETERNITY survives the blood: six letters, and it agrees in more than one place."),
    dict(n=6, ch="a1_ii", mode="substitution", tools=["substitution_board", "tally_scroll"], letters=["LTR_P06"],
         norm="letters_only", key={"type": "perm"}, params={"ngrams": True, "group5": True},
         costed=False, cost=1, codex=["a1_ngrams"], frenzy="a1_ii_frenzy", fo={"wrong_cost": 16},
         anti="Word breaks are stripped and the clerk starved E, so single-letter counts mislead (T tops the tally, E sits mid-table). Pairs and triples (TH, HE, THE) anchor the alphabet; the rest is read off the words that appear. There is no dial to spin, and sealing a wrong complete alphabet costs 8 (16 after a frenzy)."),
    dict(n=7, ch="a1_iii", mode="vigenere", tools=["multi_wheel", "tally_scroll"], letters=["LTR_P07"],
         norm="letters_only", key={"type": "word", "pool": ["ASHEN", "RAVEN", "THORN", "GRAVE", "EMBER"]},
         params={"period_given": 5, "period_max": 12}, costed=True, cost=1, codex=["a1_vigenere"],
         frenzy="a1_iii_frenzy", fo={"trial_cost": 2},
         anti="Each drum changes only every fifth letter, so the preview reads as English only when every column is right, and turning drums blind costs a notch each. The per-column Tally shows a shapes-agree score for the drum's current setting; read-as E/T/A/O jumps cost 1 per try, so matching shapes costs about 10-15 Thirst while spinning drums costs far more."),
    dict(n=8, ch="a1_iii", mode="vigenere", tools=["kasiski_lens", "multi_wheel", "tally_scroll"], letters=["LTR_P08"],
         norm="letters_only", key={"type": "word", "pool": ["MORROW", "SHROUD", "CANDLE", "REQUIEM", "VESPERS"]},
         params={"period_given": 0, "period_max": 12}, costed=True, cost=1, codex=["a1_kasiski"],
         frenzy="a1_iii_frenzy", fo={"trial_cost": 2},
         anti="Unknown period. The period stepper and tallies are free, and at the right period each column's shape lines up with English (at a wrong one nothing does), so testing widths on the tally is a slow cousin of the index of coincidence. The Kasiski lens is faster: the factor most spacings share. Either way every drum notch still costs Thirst."),
    dict(n=9, ch="a1_iii", mode="vigenere", tools=["column_loom", "multi_wheel", "tally_scroll"], letters=["LTR_P09"],
         norm="letters_only", key={"type": "word", "pool": ["VEIL", "ASHES", "GRIEF", "EMBERS"]},
         params={"period_given": 0, "period_max": 12}, costed=True, cost=1, codex=["a1_ioc"],
         frenzy="a1_iii_frenzy", fo={"trial_cost": 2},
         anti="Only a few short repeats occur, at chance level, so Kasiski misleads here. The free Column Loom's IoC vial finds N (prefer the smallest N whose vial runs thick; multiples of the key length also score high). As on puzzle 8 the stepper and tallies are free, and every drum notch costs Thirst."),
    dict(n=10, ch="a1_iii", mode="xor_rosary", tools=["bit_rosary", "key_dial"], letters=["LTR_P10"],
         norm="ascii", key={"type": "byte", "min": 65, "max": 250},
         params={"stage2_word_key": "PZ_P10_WORD", "stage1_pool": "ABCDEFGHIJKLMNOPQRSTUVWXYZ"},
         costed=False, cost=1, codex=["a1_xor", "a1_single_xor"], frenzy="a1_iii_frenzy", fo={},
         anti="Stage 1 needs the XOR relation: flip exactly the beads where the letter and the wanted letter differ; the key is never shown. Stage 3: dial turns are free on purpose because the lesson is the scoring function: the gauge is the same English score the solvers use, and 256 keys is exactly where brute force plus a scorer is the right tool. Keys 65-250 always set bit 6 or 7, so no key merely flips letter case (0x20) and no wrong key reads as English by accident."),
    dict(n=11, ch="a1_iii", mode="xor_repeating", tools=["hamming_comb", "key_dial"], letters=["LTR_P11"],
         norm="ascii", key={"type": "phrase", "pool": ["NOX AETERNA", "WE DO NOT END", "BLOOD IS OWED", "SALT AND ASHES"]},
         params={"keysize_min": 2, "keysize_max": 40},
         costed=False, cost=1, codex=["a1_repeating_xor"], frenzy="a1_iii_frenzy", fo={},
         anti="The key size comes from the Hamming comb: the true size or a multiple scores lowest (a multiple also decrypts correctly and is accepted). Each dial sets every k-th byte, so the live preview reads as English only when all dials are right; the per-strand gauges (frequency scoring) find each byte. At a wrong size no setting makes every strand gauge high."),
    dict(n=12, ch="a1_iii", mode="two_time_pad", tools=["crib_dragger"], letters=["LTR_P12_A", "LTR_P12_B"],
         norm="upper_ascii", key={"type": "pad"},
         params={"crib_tray_keys": ["PZ_P12_CRIB_1", "PZ_P12_CRIB_2", "PZ_P12_CRIB_3", "PZ_P12_CRIB_4", "PZ_P12_CRIB_5", "PZ_P12_CRIB_6"],
                 "targets": [{"msg": 0, "phrase_key": "PZ_P12_TARGET_NIGHT", "label_key": "PZ_P12_LABEL_NIGHT"},
                             {"msg": 1, "phrase_key": "PZ_P12_TARGET_NAME", "label_key": "PZ_P12_LABEL_NAME"}]},
         costed=True, cost=4, codex=["a1_otp"], frenzy="a1_iii_frenzy",
         fo={"trial_cost": 6, "crib_tray_keys": ["PZ_P12_CRIB_1", "PZ_P12_CRIB_2", "PZ_P12_CRIB_4", "PZ_P12_CRIB_5", "PZ_P12_CRIB_6"]},
         anti="There is no preview of either letter: only XOR(C1, C2) is visible. Readable text appears only under a correct "
              "crib, which is the technique itself. Pinning commits the guess; a wrong pin costs 4, so spraying cribs is "
              "expensive. Winning needs the tithe-night phrase and the traitor's name recovered, which takes several "
              "chained guesses. After a frenzy one tray crib is lost and a wrong pin costs 6."),
]

CHAPTERS = [
    dict(id="a1_i", order=1, title="CH_A1_I_TITLE", sub="CH_A1_I_SUB", next="a1_ii", puzzles=["a1_p01", "a1_p02", "a1_p03"], steps=[
        ("dialogue", "a1_vault_open"), ("dialogue", "a1_i_intro"), ("puzzle", "a1_p01"), ("dialogue", "a1_p01_after"),
        ("puzzle", "a1_p02"), ("dialogue", "a1_p02_after"), ("dialogue", "a1_p02_remark"), ("puzzle", "a1_p03"),
        ("dialogue", "a1_p03_after"), ("dialogue", "a1_i_end"), ("summary", ""), ("dialogue", "a1_vault_i")]),
    dict(id="a1_ii", order=2, title="CH_A1_II_TITLE", sub="CH_A1_II_SUB", next="a1_iii", puzzles=["a1_p04", "a1_p05", "a1_p06"], steps=[
        ("dialogue", "a1_ii_intro"), ("puzzle", "a1_p04"), ("dialogue", "a1_p04_after"), ("puzzle", "a1_p05"),
        ("dialogue", "a1_p05_after"), ("dialogue", "a1_p05_remark"), ("puzzle", "a1_p06"), ("dialogue", "a1_p06_after"),
        ("dialogue", "a1_ii_end"), ("summary", ""), ("dialogue", "a1_vault_ii")]),
    dict(id="a1_iii", order=3, title="CH_A1_III_TITLE", sub="CH_A1_III_SUB", next="",
         puzzles=["a1_p07", "a1_p08", "a1_p09", "a1_p10", "a1_p11", "a1_p12"], steps=[
        ("dialogue", "a1_iii_intro"), ("puzzle", "a1_p07"), ("dialogue", "a1_p07_after"), ("puzzle", "a1_p08"),
        ("dialogue", "a1_p08_after"), ("dialogue", "a1_p08_remark"), ("puzzle", "a1_p09"), ("dialogue", "a1_p09_after"),
        ("puzzle", "a1_p10"), ("dialogue", "a1_p10_after"), ("puzzle", "a1_p11"), ("dialogue", "a1_p11_after"),
        ("dialogue", "a1_p11_remark"), ("puzzle", "a1_p12"), ("dialogue", "a1_iii_end"), ("dialogue", "a1_vault_end"),
        ("summary", ""), ("act_folio", ""), ("card", "CARD_A1_END")]),
]


# (id, act, chapter, order, widget, margins, placeholder)
CODEX = [
    ("a1_key", 1, "a1_i", 1, "shift_wheel", 2, False),
    ("a1_keyspace", 1, "a1_i", 2, "", 2, False),
    ("a1_frequency", 1, "a1_i", 3, "frequency", 2, False),
    ("a1_kerckhoffs", 1, "a1_i", 4, "", 3, False),
    ("a1_substitution", 1, "a1_ii", 5, "frequency", 2, False),
    ("a1_cribs", 1, "a1_ii", 6, "", 2, False),
    ("a1_ngrams", 1, "a1_ii", 7, "", 2, False),
    ("a1_vigenere", 1, "a1_iii", 8, "", 2, False),
    ("a1_kasiski", 1, "a1_iii", 9, "", 2, False),
    ("a1_ioc", 1, "a1_iii", 10, "ioc", 2, False),
    ("a1_xor", 1, "a1_iii", 11, "xor_beads", 2, False),
    ("a1_single_xor", 1, "a1_iii", 12, "", 2, False),
    ("a1_repeating_xor", 1, "a1_iii", 13, "", 2, False),
    ("a1_otp", 1, "a1_iii", 14, "", 3, False),
    ("a2_stained_glass", 2, "a2", 1, "", 1, True),
    ("a3_blood_sigils", 3, "a3", 1, "", 1, True),
    ("a4_court_of_primes", 4, "a4", 1, "", 1, True),
    ("a5_ward_whisper", 5, "a5", 1, "", 1, True),
]


def write_codex():
    os.makedirs(os.path.join(ROOT, "content", "codex"), exist_ok=True)
    for cid, act, ch, order, widget, margins, ph in CODEX:
        k = "CDX_" + cid.upper()
        lines = [
            '[gd_resource type="Resource" script_class="CodexEntryDef" format=3]', "",
            '[ext_resource type="Script" path="res://core/game/codex_entry_def.gd" id="1"]', "",
            "[resource]", 'script = ExtResource("1")',
            "id = %s" % g(cid), "act = %d" % act, "chapter_id = %s" % g(ch), "order = %d" % order,
            'title_key = "%s_TITLE"' % k, 'body_key = "%s_BODY"' % k, 'example_key = "%s_EXAMPLE"' % k,
            'wrong_key = "%s_WRONG"' % k, 'aside_key = "%s_ASIDE"' % k,
            "margin_keys = %s" % packed(["%s_M%d" % (k, i) for i in range(1, margins + 1)]),
            "widget = %s" % g(widget), "placeholder = %s" % ("true" if ph else "false"), "",
        ]
        with open(os.path.join(ROOT, "content", "codex", cid + ".tres"), "w") as fh:
            fh.write("\n".join(lines))


def g(v):
    """Godot text-resource literal."""
    return json.dumps(v)


def packed(lst):
    return "PackedStringArray(%s)" % ", ".join(json.dumps(x) for x in lst)


def main():
    os.makedirs(os.path.join(ROOT, "content", "puzzles"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "content", "chapters"), exist_ok=True)
    for p in PUZZLES:
        n = p["n"]
        senders = [k + "_FROM" for k in p["letters"]]
        lines = [
            '[gd_resource type="Resource" script_class="PuzzleDef" format=3]', "",
            '[ext_resource type="Script" path="res://core/game/puzzle_def.gd" id="1"]', "",
            "[resource]", 'script = ExtResource("1")',
            'id = "a1_p%02d"' % n, "chapter_id = %s" % g(p["ch"]), "number = %d" % n,
            'title_key = "PZ_P%02d_TITLE"' % n, 'brief_key = "PZ_P%02d_BRIEF"' % n,
            "mode = %s" % g(p["mode"]), "tools = %s" % packed(p["tools"]),
            "plaintext_keys = %s" % packed(p["letters"]), "sender_keys = %s" % packed(senders),
            "normalization = %s" % g(p["norm"]), "key_rule = %s" % g(p["key"]),
            "base_seed = %d" % (1000 + 101 * n), "params = %s" % g(p["params"]),
            "brute_force_costed = %s" % ("true" if p["costed"] else "false"), "trial_cost = %d" % p["cost"],
            "hint_keys = %s" % packed(hints(n)), "codex_unlocks = %s" % packed(p["codex"]),
            "frenzy_dialogue = %s" % g(p["frenzy"]), "frenzy_overrides = %s" % g(p["fo"]),
            "anti_cheese = %s" % g(p["anti"]), "",
        ]
        with open(os.path.join(ROOT, "content", "puzzles", "a1_p%02d.tres" % n), "w") as fh:
            fh.write("\n".join(lines))
    for c in CHAPTERS:
        steps = []
        for kind, ref in c["steps"]:
            if kind in ("dialogue", "puzzle"):
                steps.append({"type": kind, "id": ref})
            elif kind == "card":
                steps.append({"type": "card", "text": ref})
            else:
                steps.append({"type": kind})
        lines = [
            '[gd_resource type="Resource" script_class="ChapterDef" format=3]', "",
            '[ext_resource type="Script" path="res://core/game/chapter_def.gd" id="1"]', "",
            "[resource]", 'script = ExtResource("1")',
            "id = %s" % g(c["id"]), "act = 1", "order = %d" % c["order"],
            "title_key = %s" % g(c["title"]), "subtitle_key = %s" % g(c["sub"]),
            "steps = Array[Dictionary](%s)" % g(steps), "next_chapter = %s" % g(c["next"]),
            "puzzle_ids = %s" % packed(c["puzzles"]), "",
        ]
        with open(os.path.join(ROOT, "content", "chapters", c["id"] + ".tres"), "w") as fh:
            fh.write("\n".join(lines))
    write_codex()
    print("wrote %d puzzles, %d chapters, %d codex entries" % (len(PUZZLES), len(CHAPTERS), len(CODEX)))


if __name__ == "__main__":
    main()
