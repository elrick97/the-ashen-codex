#!/usr/bin/env python3
"""Merges content/i18n/src/*.csv into content/i18n/strings.csv (the one translation table).

Checks: header is `keys,en`; no duplicate keys; values are plain ASCII (no curly quotes,
em dashes or diacritics); every key referenced by content (.tres, dialogue .json, scripts'
tr("...") calls) exists; the banned-terms list does not appear.

Usage:
  python3 tools_dev/build_strings.py            merge + check (exit 1 on problems)
  python3 tools_dev/build_strings.py --script   also regenerate the Letters section of docs/ACT1_SCRIPT.md
  python3 tools_dev/build_strings.py --report   print word/letter counts for every LTR_ key
"""
import csv
import glob
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "content", "i18n", "src")
OUT = os.path.join(ROOT, "content", "i18n", "strings.csv")
SCRIPT_DOC = os.path.join(ROOT, "docs", "ACT1_SCRIPT.md")
BANNED = ["Gabriel", "de Leon", "de León", "Jean-Francois", "Jean-François", "Silver Saints",
          "San Michon", "daysdeath", "sanguimancy", "Chastain", "Ilon", "Voss", "Dyvok",
          "Esani", "Celene", "Astrid", "Lachance"]
KEY_RE = re.compile(r"^[A-Z][A-Z0-9_]*$")


def read_fragments():
    rows = []
    for path in sorted(glob.glob(os.path.join(SRC, "*.csv"))):
        with open(path, newline="", encoding="utf-8") as fh:
            reader = csv.reader(fh)
            header = next(reader, None)
            if header != ["keys", "en"]:
                raise SystemExit("%s: header must be keys,en (got %r)" % (path, header))
            for line in reader:
                if not line or not line[0].strip() or line[0].startswith("#"):
                    continue
                if len(line) != 2:
                    raise SystemExit("%s: row %r must have 2 columns" % (path, line[:1]))
                rows.append((line[0].strip(), line[1], os.path.basename(path)))
    return rows


def referenced_keys():
    keys = set()
    for path in glob.glob(os.path.join(ROOT, "content", "**", "*.tres"), recursive=True):
        text = open(path, encoding="utf-8").read()
        for m in re.finditer(r'"((?:UI|SPK|CH|PZ|LTR|DLG|CDX|CARD)_[A-Z0-9_]+)"', text):
            keys.add((m.group(1), os.path.relpath(path, ROOT)))
    for path in glob.glob(os.path.join(ROOT, "content", "dialogue", "*.json")):
        data = json.load(open(path, encoding="utf-8"))
        for node in data.get("nodes", []):
            for field in ("text",):
                if field in node:
                    keys.add((node[field], os.path.relpath(path, ROOT)))
            for c in node.get("choices", []):
                keys.add((c["text"], os.path.relpath(path, ROOT)))
    for path in glob.glob(os.path.join(ROOT, "**", "*.gd"), recursive=True):
        if "/addons/" in path or "/.godot/" in path or "/tests/" in path:
            continue
        text = open(path, encoding="utf-8").read()
        for m in re.finditer(r'\btr\("([A-Z][A-Z0-9_]+)"\)', text):
            keys.add((m.group(1), os.path.relpath(path, ROOT)))
    return keys


SPEAKERS = {"isaak", "kett", "marquise", "steward", "wenna", "courier", "lord", "narrator"}


def budget_problems(values):
    """Length budgets from the grimdark-voice skill."""
    out = []
    choice_keys = set()
    for path in glob.glob(os.path.join(ROOT, "content", "dialogue", "*.json")):
        try:
            data = json.load(open(path, encoding="utf-8"))
        except ValueError:
            continue
        for node in data.get("nodes", []):
            for c in node.get("choices", []):
                choice_keys.add(c.get("text", ""))
    for k, v in values.items():
        n_words = len(v.split())
        if k.startswith("DLG_") and k not in choice_keys and len(v) > 140:
            out.append("%s: dialogue line is %d chars (max 140)" % (k, len(v)))
        if k in choice_keys and len(v) > 60:
            out.append("%s: choice is %d chars (max 60)" % (k, len(v)))
        if re.match(r"^PZ_P\d\d_HINT[123]$", k):
            sentences = len([s for s in re.split(r"[.!?]+(?:\s|$)", v.strip()) if s.strip()])
            if sentences > 2:
                out.append("%s: hint has %d sentences (max 2)" % (k, sentences))
        if re.match(r"^CDX_.*_BODY$", k) and n_words > 120:
            out.append("%s: codex body %d words (max 120)" % (k, n_words))
        if re.match(r"^CDX_.*_(WRONG|ASIDE)$", k) and n_words > 50:
            out.append("%s: %d words (max 50)" % (k, n_words))
        if re.match(r"^CDX_.*_M\d$", k) and n_words > 25:
            out.append("%s: margin note %d words (max 25)" % (k, n_words))
    return out


def dialogue_problems():
    out = []
    for path in sorted(glob.glob(os.path.join(ROOT, "content", "dialogue", "*.json"))):
        name = os.path.relpath(path, ROOT)
        try:
            data = json.load(open(path, encoding="utf-8"))
        except ValueError as e:
            out.append("%s: invalid JSON (%s)" % (name, e))
            continue
        if data.get("id") != os.path.basename(path)[:-5]:
            out.append("%s: id must equal the file name" % name)
        if data.get("location") not in ("vault", "memory"):
            out.append("%s: location must be vault or memory" % name)
        nodes = data.get("nodes", [])
        labels = {n["label"] for n in nodes if "label" in n}
        for i, n in enumerate(nodes):
            if n.get("speaker", "narrator") not in SPEAKERS:
                out.append("%s node %d: unknown speaker %r" % (name, i, n.get("speaker")))
            gotos = [n.get("goto")] + [c.get("goto") for c in n.get("choices", [])]
            for g_ in gotos:
                if g_ is not None and g_ not in labels:
                    out.append("%s node %d: goto %r has no label" % (name, i, g_))
            if "text" not in n:
                out.append("%s node %d: missing text" % (name, i))
    return out


def letters_section(values):
    out = ["## Letters", "",
           "Generated by `python3 tools_dev/build_strings.py --script` from `content/i18n/strings.csv`.", ""]
    for key in sorted(k for k in values if re.match(r"^LTR_P\d\d(_[A-Z])?$", k)):
        text = values[key]
        words = len(text.split())
        letters = sum(1 for ch in text if ch.isalpha())
        sender = values.get(key + "_FROM", "")
        out.append("### %s (%d words, %d letters)" % (key, words, letters))
        if sender:
            out.append("*%s*" % sender)
        out.append("")
        out.append("```")
        out.append(text)
        out.append("```")
        out.append("")
    return "\n".join(out) + "\n"


def main():
    rows = read_fragments()
    problems = []
    values = {}
    for key, val, src in rows:
        if not KEY_RE.match(key):
            problems.append("%s: bad key %r" % (src, key))
        if key in values:
            problems.append("%s: duplicate key %s" % (src, key))
        values[key] = val
        try:
            val.encode("ascii")
        except UnicodeEncodeError:
            bad = sorted({ch for ch in val if ord(ch) > 127})
            problems.append("%s: %s has non-ASCII characters %r" % (src, key, bad))
        for term in BANNED:
            if re.search(r"\b%s\b" % re.escape(term), val, re.IGNORECASE):
                problems.append("%s: %s contains banned term %r" % (src, key, term))
    for key, where in sorted(referenced_keys()):
        if key not in values:
            problems.append("missing key %s (used in %s)" % (key, where))
    problems.extend(budget_problems(values))
    problems.extend(dialogue_problems())
    buf = io.StringIO()
    w = csv.writer(buf, lineterminator="\n")
    w.writerow(["keys", "en"])
    for key, val, _src in rows:
        w.writerow([key, val])
    new_text = buf.getvalue()
    old_text = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
    if new_text != old_text:
        with open(OUT, "w", encoding="utf-8", newline="") as fh:
            fh.write(new_text)
    print("strings: %d keys from %d fragments" % (len(values), len(glob.glob(os.path.join(SRC, "*.csv")))))
    if "--report" in sys.argv:
        for key in sorted(k for k in values if k.startswith("LTR_") and not k.endswith("_FROM")):
            t = values[key]
            print("%-12s words=%4d letters=%4d" % (key, len(t.split()), sum(ch.isalpha() for ch in t)))
    if "--script" in sys.argv:
        doc = open(SCRIPT_DOC, encoding="utf-8").read()
        head = doc.split("## Letters")[0]
        with open(SCRIPT_DOC, "w", encoding="utf-8") as fh:
            fh.write(head + letters_section(values))
        print("updated", os.path.relpath(SCRIPT_DOC, ROOT))
    for p in problems:
        print("PROBLEM:", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
