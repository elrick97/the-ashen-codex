#!/usr/bin/env python3
"""Checks every Act I letter against its puzzle's technique constraints (heuristics from
the crypto-accuracy-check skill). Reads content/i18n/src/*.csv directly.

Usage: python3 tools_dev/check_letters.py [P04 P06 ...]   (default: all)
Exit code 1 if any hard constraint fails. The GDScript solver tests remain the final word.
"""
import csv
import glob
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load():
    vals = {}
    for p in glob.glob(os.path.join(ROOT, "content", "i18n", "src", "*.csv")):
        with open(p, newline="", encoding="utf-8") as fh:
            r = csv.reader(fh)
            next(r, None)
            for row in r:
                if len(row) == 2 and row[0] and not row[0].startswith("#"):
                    vals[row[0]] = row[1].replace("\\n", "\n")
    return vals


def letters(t):
    return re.sub(r"[^A-Z]", "", t.upper())


def words(t):
    return len(t.split())


def ic(s):
    c = Counter(s)
    n = len(s)
    return sum(v * (v - 1) for v in c.values()) / (n * (n - 1)) if n > 1 else 0


def check(v):
    out = []  # (key, ok, message)

    def need(key, cond, msg):
        out.append((key, bool(cond), msg))

    def txt(k):
        return v.get(k, "")

    for k, t in v.items():
        if k.startswith("LTR_P") and not k.endswith("_FROM"):
            try:
                t.encode("ascii")
                need(k, True, "ascii")
            except UnicodeEncodeError:
                need(k, False, "non-ASCII characters")
            for bad in ["—", "’", "“", "”"]:
                need(k, bad not in t, "no curly quotes / em dashes")
    t = txt("LTR_P01")
    need("LTR_P01", 25 <= words(t) <= 60, "25-60 words (has %d)" % words(t))
    t = txt("LTR_P02")
    L = letters(t)
    c = Counter(L).most_common(2)
    need("LTR_P02", 40 <= words(t) <= 60, "40-60 words (has %d)" % words(t))
    need("LTR_P02", len(c) == 2 and c[0][0] == "E" and c[0][1] - c[1][1] >= 2,
         "E must be the commonest letter by >= 2 (top two: %s)" % c)
    for s in "ABC":
        t = txt("LTR_P03_" + s)
        need("LTR_P03_" + s, 25 <= words(t) <= 50, "25-50 words (has %d)" % words(t))
    for k in ["PZ_P03_Q", "PZ_P03_A1", "PZ_P03_A2", "PZ_P03_A3"]:
        need(k, k in v, "exists")
    t = txt("LTR_P04")
    need("LTR_P04", 150 <= words(t) <= 250, "150-250 words (has %d)" % words(t))
    need("LTR_P04", len(letters(t)) >= 600, ">= 600 letters (has %d)" % len(letters(t)))
    t = txt("LTR_P05")
    crib = txt("PZ_P05_CRIB").upper()
    need("LTR_P05", 60 <= words(t) <= 100, "60-100 words (has %d)" % words(t))
    need("LTR_P05", crib == "YOUR SERVANT IN ETERNITY", "PZ_P05_CRIB is YOUR SERVANT IN ETERNITY")
    need("LTR_P05", t.upper().count(crib) == 1, "contains the crib exactly once")
    need("PZ_P05_CRIB_SHORT", txt("PZ_P05_CRIB_SHORT").upper() == "YOUR SERVANT", "PZ_P05_CRIB_SHORT is YOUR SERVANT")
    t = txt("LTR_P06")
    L = letters(t)
    c = Counter(L).most_common(3)
    need("LTR_P06", 150 <= len(L) <= 250, "150-250 letters (has %d)" % len(L))
    need("LTR_P06", len(c) >= 2 and Counter(L)["E"] <= c[1][1] + 1 if c and c[0][0] == "E" else True,
         "E flattened: not more than 1 above the runner-up (top: %s)" % c)
    tri = Counter(L[i:i + 3] for i in range(len(L) - 2)).most_common(3)
    need("LTR_P06", tri and tri[0][0] == "THE", "THE is the commonest trigram (top: %s)" % tri)
    t = txt("LTR_P07")
    L = letters(t)
    need("LTR_P07", 150 <= len(L) <= 240, "150-240 letters (has %d)" % len(L))
    t = txt("LTR_P08")
    L = letters(t)
    need("LTR_P08", 300 <= len(L) <= 460, "300-460 letters (has %d)" % len(L))
    for rep in ["TITHE", "HOLLOWMERE", "NEWMOON"]:
        need("LTR_P08", L.count(rep) >= 3, "repeats %s at least 3 times (has %d)" % (rep, L.count(rep)))
    t = txt("LTR_P09")
    L = letters(t)
    need("LTR_P09", 150 <= len(L) <= 200, "150-200 letters (has %d)" % len(L))
    need("LTR_P09", ic(L) >= 0.060, "English-like IoC >= 0.060 (has %.4f)" % ic(L))
    t = txt("LTR_P10")
    need("LTR_P10", 60 <= len(t) <= 140, "60-140 characters (has %d)" % len(t))
    need("PZ_P10_WORD", re.fullmatch(r"[A-Z]{4,6}", txt("PZ_P10_WORD")) is not None, "4-6 capital letters")
    t = txt("LTR_P11")
    need("LTR_P11", 420 <= len(t) <= 700, "420-700 characters (has %d)" % len(t))
    a = txt("LTR_P12_A").upper()
    b = txt("LTR_P12_B").upper()
    ov = min(len(a), len(b))
    need("LTR_P12_A", 130 <= len(a) <= 210, "130-210 characters (has %d)" % len(a))
    need("LTR_P12_B", 130 <= len(b) <= 210, "130-210 characters (has %d)" % len(b))
    night = txt("PZ_P12_TARGET_NIGHT").upper()
    name = txt("PZ_P12_TARGET_NAME").upper()
    need("PZ_P12_TARGET_NIGHT", night and 0 <= a.find(night) and a.find(night) + len(night) <= ov, "in letter A, inside the overlap")
    need("PZ_P12_TARGET_NAME", name and 0 <= b.find(name) and b.find(name) + len(name) <= ov, "in letter B, inside the overlap")
    need("PZ_P12_TARGET_NAME", "ANSGAR" in name, "names Ansgar")
    for i in range(1, 7):
        k = "PZ_P12_CRIB_%d" % i
        need(k, k in v, "exists")
        need(k, "ANSGAR" not in txt(k).upper(), "tray does not give away the name")
    for k in ["LTR_P12_A", "LTR_P12_B"]:
        need(k, re.fullmatch(r"[A-Za-z .,;:'!?\-\n]+", txt(k)) is not None, "only letters, spaces and . , ; : ' ! ? -")
    return out


def main():
    v = load()
    only = [a.upper() for a in sys.argv[1:]]
    bad = 0
    for key, ok, msg in check(v):
        if only and not any(key.startswith("LTR_" + o) or key.startswith("PZ_" + o) for o in only):
            continue
        if not ok:
            bad += 1
        print("%s %-22s %s" % ("ok  " if ok else "FAIL", key, msg))
    print("letters check: %d failing" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
