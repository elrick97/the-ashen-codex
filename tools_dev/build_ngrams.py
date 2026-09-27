#!/usr/bin/env python3
"""Builds core/crypto/data/english_ngrams.json from public-domain English books.

Corpus (Project Gutenberg, public domain in the US): Dracula (#345), Pride and
Prejudice (#1342), A Tale of Two Cities (#98), Moby-Dick (#2701), The Adventures
of Sherlock Holmes (#1661), Frankenstein (#84). Download them with
  for n in 345 1342 98 2701 1661 84; do curl -sL -o $n.txt https://www.gutenberg.org/cache/epub/$n/pg$n.txt; done
then run: python3 tools_dev/build_ngrams.py <corpus_dir>

Output: log10 probabilities over letters-only text (word breaks removed).
  "bi":   676 values, index a*26+b
  "tri":  17576 values, index a*676+b*26+c
  "quad": {gram: log10p} for the 30000 most common quadgrams; "quad_floor" for the rest
Values are rounded to 3 decimals.
"""
import json
import math
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "core", "crypto", "data", "english_ngrams.json")


def body(text):
    start = re.search(r"\*\*\* ?START OF (THE|THIS) PROJECT GUTENBERG.*?\*\*\*", text)
    end = re.search(r"\*\*\* ?END OF (THE|THIS) PROJECT GUTENBERG", text)
    a = start.end() if start else 0
    b = end.start() if end else len(text)
    return text[a:b]


def main():
    corpus_dir = sys.argv[1]
    letters = []
    for name in sorted(os.listdir(corpus_dir)):
        if name.endswith(".txt"):
            with open(os.path.join(corpus_dir, name), encoding="utf-8", errors="ignore") as fh:
                letters.append(re.sub(r"[^A-Z]", "", body(fh.read()).upper()))
    total_letters = sum(len(s) for s in letters)
    counts = {n: Counter() for n in (2, 3, 4)}
    for s in letters:
        for n in (2, 3, 4):
            c = counts[n]
            for i in range(len(s) - n + 1):
                c[s[i:i + n]] += 1

    def table(n):
        c = counts[n]
        tot = sum(c.values())
        floor = math.log10(0.01 / tot)
        return c, tot, floor

    out = {"source": "Gutenberg #345 #1342 #98 #2701 #1661 #84", "letters": total_letters}
    for n, key in ((2, "bi"), (3, "tri")):
        c, tot, floor = table(n)
        arr = []
        A = ord("A")
        rng = range(26)
        if n == 2:
            grams = [chr(A + a) + chr(A + b) for a in rng for b in rng]
        else:
            grams = [chr(A + a) + chr(A + b) + chr(A + d) for a in rng for b in rng for d in rng]
        for g in grams:
            arr.append(round(math.log10(c[g] / tot), 3) if c[g] else round(floor, 3))
        out[key] = arr
    c, tot, floor = table(4)
    out["quad"] = {g: round(math.log10(k / tot), 3) for g, k in c.most_common(30000)}
    out["quad_floor"] = round(floor, 3)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        json.dump(out, fh, separators=(",", ":"))
    print("letters:", total_letters, "wrote", OUT, os.path.getsize(OUT), "bytes")
    top = counts[3].most_common(8)
    print("top trigrams:", top)


if __name__ == "__main__":
    main()
