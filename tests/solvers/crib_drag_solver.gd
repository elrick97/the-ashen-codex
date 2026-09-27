class_name CribDragSolver
extends RefCounted
## Reference solver for the two-time pad, by crib-dragging only.
##
## It works like a patient player: drag a guessed word along C1 xor C2 and read what the
## other letter becomes beneath it; believe the guess only if BOTH letters then read as
## English (punctuation, real short words, quadgram statistics); then guess the next word
## at the edge of what is known. A small beam keeps the few most convincing readings
## alive so one plausible-but-wrong early guess can be abandoned.
## It never sees the pad or the plaintexts.

const BASELINE: float = -6.0 # quadgram log10: English ~ -4.1, noise ~ -8
const TERMINATORS: Array[String] = [" ", ", ", ".\n", ". ", ",\n", "\n", "; "]
const COMMON_WORDS: int = 450
const WORD_BONUS: float = 2.5
const UNKNOWN_PENALTY: float = 6.0
const QUAD_WEIGHT: float = 0.3
const CONTRACTIONS: Array[String] = ["S", "T", "D", "M", "LL", "RE", "VE"]

var x: PackedByteArray = PackedByteArray()
var tray: PackedStringArray = PackedStringArray()
var vocab: Dictionary = {}
var vocab_list: PackedStringArray = PackedStringArray()


func _init(stream: PackedByteArray, tray_words: PackedStringArray, words: PackedStringArray) -> void:
	x = stream
	tray = tray_words
	vocab_list = words
	for w: String in words:
		vocab[w] = true
	for t: String in tray_words:
		for part: String in t.strip_edges().split(" ", false):
			vocab[part] = true


## Returns {"known": [PackedByteArray, PackedByteArray], "pins": int, "score": float}.
## Each seed placement gets its own small beam, like a player trying one crib and
## following it as far as it reads. The readings are then combined the way a player
## keeps every pin: the most convincing first, later ones only where nothing is known yet.
func solve(beam: int = 8, branch: int = 5, max_steps: int = 90, seeds: int = 10) -> Dictionary:
	var results: Array[Dictionary] = []
	for p: Dictionary in _seed_placements(seeds):
		results.append(_beam_from(p, beam, branch, max_steps))
	results.sort_custom(func(r1: Dictionary, r2: Dictionary) -> bool: return float(r1["score"]) > float(r2["score"]))
	if results.is_empty():
		return {"known": _blank(x.size()), "pins": 0, "score": 0.0}
	var merged: Array[PackedByteArray] = [(results[0]["known"] as Array)[0].duplicate(), (results[0]["known"] as Array)[1].duplicate()]
	var pins: int = int(results[0]["pins"])
	for i: int in range(1, results.size()):
		var k: Array = results[i]["known"]
		var added: bool = false
		for j: int in range(x.size()):
			if merged[0][j] == 0 and (k[0] as PackedByteArray)[j] != 0:
				merged[0][j] = (k[0] as PackedByteArray)[j]
				merged[1][j] = (k[1] as PackedByteArray)[j]
				added = true
		if added:
			pins += int(results[i]["pins"])
	return {"known": merged, "pins": pins, "score": float(results[0]["score"])}


func _beam_from(p: Dictionary, beam: int, branch: int, max_steps: int) -> Dictionary:
	var k0: Array[PackedByteArray] = _blank(x.size())
	_apply(k0, 0, int(p["o"]), p["w"])
	var states: Array[Dictionary] = [{"known": k0, "score": _total(k0), "pins": 1}]
	var finished: Array[Dictionary] = []
	for _step: int in range(max_steps):
		var next: Array[Dictionary] = []
		var seen: Dictionary = {}
		for st: Dictionary in states:
			var cands: Array[Dictionary] = _candidates(st["known"])
			cands.sort_custom(func(a2: Dictionary, b2: Dictionary) -> bool: return float(a2["delta"]) > float(b2["delta"]))
			var grew: bool = false
			for c: Dictionary in cands.slice(0, branch):
				if float(c["delta"]) <= 0.0:
					continue
				var k2: Array[PackedByteArray] = [(st["known"] as Array)[0].duplicate(), (st["known"] as Array)[1].duplicate()]
				_apply(k2, int(c["row"]), int(c["o"]), c["w"])
				var key: String = k2[0].hex_encode()
				if seen.has(key):
					continue
				seen[key] = true
				grew = true
				next.append({"known": k2, "score": float(st["score"]) + float(c["delta"]), "pins": int(st["pins"]) + 1})
			if not grew:
				finished.append(st)
		if next.is_empty():
			break
		next.sort_custom(func(a3: Dictionary, b3: Dictionary) -> bool: return float(a3["score"]) > float(b3["score"]))
		states = next.slice(0, beam)
	finished.append_array(states)
	var best: Dictionary = {}
	for st2: Dictionary in finished:
		if best.is_empty() or float(st2["score"]) > float(best["score"]):
			best = st2
	return best


func _seed_placements(count: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n: int = x.size()
	for w: String in tray:
		var wb: PackedByteArray = w.to_ascii_buffer()
		for o: int in range(n - wb.size() + 1):
			var frag: PackedByteArray = Crib.drag(x, wb, o)
			if not Crib.is_plausible_upper(frag) or not _reads_true(frag):
				continue
			out.append({"o": o, "w": wb, "s": _gain(frag) + _gain(wb)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["s"]) > float(b["s"]))
	# Keep the best two placements of each crib so one repeated phrase can't fill the beam.
	var per_word: Dictionary = {}
	var picked: Array[Dictionary] = []
	for p: Dictionary in out:
		var key: String = (p["w"] as PackedByteArray).get_string_from_ascii()
		if int(per_word.get(key, 0)) >= 2:
			continue
		per_word[key] = int(per_word.get(key, 0)) + 1
		picked.append(p)
	return picked.slice(0, count)


static func _blank(n: int) -> Array[PackedByteArray]:
	var k: Array[PackedByteArray] = [PackedByteArray(), PackedByteArray()]
	for r: int in range(2):
		k[r].resize(n)
		k[r].fill(0)
	return k


func _apply(k: Array[PackedByteArray], row: int, o: int, w: PackedByteArray) -> void:
	var other: PackedByteArray = Crib.drag(x, w, o)
	for i: int in range(w.size()):
		k[row][o + i] = w[i]
		k[1 - row][o + i] = other[i]


func _total(k: Array[PackedByteArray]) -> float:
	var s: float = 0.0
	for r: int in range(2):
		for seg: PackedByteArray in _segments(k[r], 0, k[r].size()):
			s += _gain(seg)
	return s


static func _segments(kb: PackedByteArray, a: int, b: int) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	var i: int = a
	while i < b:
		if kb[i] == 0:
			i += 1
			continue
		var j: int = i
		while j < b and kb[j] != 0:
			j += 1
		out.append(kb.slice(i, j))
		i = j
	return out


## Readability gain of a known run: every complete real word earns its length, every
## complete unknown word (a name, or noise) costs a fixed amount, and the letters add a
## small quadgram term above the noise baseline.
func _gain(seg: PackedByteArray) -> float:
	var g: float = 0.0
	var letters: PackedInt32Array = TextUtil.letter_indices(seg.get_string_from_ascii())
	if letters.size() >= 4:
		g += QUAD_WEIGHT * (EnglishScore.fitness(letters) - BASELINE * float(letters.size() - 3))
	var words: PackedStringArray = _words(seg)
	for i: int in range(1, words.size() - 1):
		var w: String = words[i]
		if w == "":
			continue
		g += WORD_BONUS * w.length() if vocab.has(w.trim_suffix("'S")) else -UNKNOWN_PENALTY
	return g


static func _words(seg: PackedByteArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var cur: String = ""
	for b: int in seg:
		if TextUtil.is_upper(b) or b == 39:
			cur += String.chr(b)
		else:
			out.append(cur)
			cur = ""
	out.append(cur)
	return out


static func _trigram_per(w: String) -> float:
	var idx: PackedInt32Array = TextUtil.letter_indices(w)
	if idx.size() < 3:
		return 0.0
	var t: float = 0.0
	for i: int in range(idx.size() - 2):
		t += EnglishScore.trigram_logp(idx[i], idx[i + 1], idx[i + 2])
	return t / float(idx.size() - 2)


static func _is_break(b: int) -> bool:
	return b == 32 or b == 10 or (b != 0 and not TextUtil.is_upper(b) and b != 39)


func _candidates(k: Array[PackedByteArray]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n: int = x.size()
	for row: int in range(2):
		var kb: PackedByteArray = k[row]
		for e: int in range(1, n):
			if kb[e - 1] != 0 and kb[e] == 0:
				var start: int = e
				while start > 0 and kb[start - 1] != 0 and not _is_break(kb[start - 1]):
					start -= 1
				var partial: String = kb.slice(start, e).get_string_from_ascii()
				var words: PackedStringArray = _completions(partial)
				if partial != "":
					words.append(partial)
				for w: String in words:
					for term: String in TERMINATORS:
						var c: Dictionary = _evaluate(k, row, start, (w + term).to_ascii_buffer())
						if not c.is_empty():
							out.append(c)
			if kb[e - 1] == 0 and kb[e] != 0 and e >= 2:
				var stop: int = e
				while stop < n and kb[stop] != 0 and not _is_break(kb[stop]):
					stop += 1
				var suffix: String = kb.slice(e, stop).get_string_from_ascii()
				for w2: String in _endings(suffix):
					for lead: String in [" ", "\n"]:
						var wb2: PackedByteArray = (lead + w2).to_ascii_buffer()
						var c2: Dictionary = _evaluate(k, row, stop - wb2.size(), wb2)
						if not c2.is_empty():
							out.append(c2)
	return out


func _evaluate(k: Array[PackedByteArray], row: int, o: int, wb: PackedByteArray) -> Dictionary:
	if o < 0 or o + wb.size() > x.size():
		return {}
	var fresh: int = 0
	for i: int in range(wb.size()):
		var kv: int = k[row][o + i]
		if kv != 0 and kv != wb[i]:
			return {}
		if kv == 0:
			fresh += 1
	if fresh == 0:
		return {}
	var frag: PackedByteArray = Crib.drag(x, wb, o)
	if not Crib.is_plausible_upper(frag):
		return {}
	for i: int in range(frag.size()):
		var k2: int = k[1 - row][o + i]
		if k2 != 0 and k2 != frag[i]:
			return {}
	var own: Dictionary = _context(k[row], o, wb)
	var other: Dictionary = _context(k[1 - row], o, frag)
	if not _reads_true(own["after"]) or not _reads_true(other["after"]):
		return {}
	var delta: float = _gain(own["after"]) + _gain(other["after"]) - float(own["before"]) - float(other["before"])
	return {"row": row, "o": o, "w": wb, "delta": delta}


## The run of known text around a placement, before (as a gain) and after writing it in.
func _context(kb: PackedByteArray, o: int, wb: PackedByteArray) -> Dictionary:
	var s: int = o
	while s > 0 and kb[s - 1] != 0:
		s -= 1
	var t: int = o + wb.size()
	while t < kb.size() and kb[t] != 0:
		t += 1
	var before: float = 0.0
	for seg: PackedByteArray in _segments(kb, s, t):
		before += _gain(seg)
	var after: PackedByteArray = kb.slice(s, t)
	for i: int in range(wb.size()):
		after[o - s + i] = wb[i]
	return {"after": after, "before": before}


## What a reader checks before believing a fragment.
func _reads_true(ctx: PackedByteArray) -> bool:
	var n: int = ctx.size()
	for i: int in range(n):
		var b: int = ctx[i]
		var nxt: int = ctx[i + 1] if i + 1 < n else -1
		var prv: int = ctx[i - 1] if i > 0 else -1
		if b in [46, 44, 59, 58, 33, 63] and nxt != -1 and nxt != 32 and nxt != 10:
			return false
		if b in [46, 44, 59, 58, 33, 63] and prv != -1 and not TextUtil.is_upper(prv):
			return false
		if b == 10 and prv != -1 and prv != 44 and prv != 46 and prv != 10:
			return false
		if b == 39 and ((prv != -1 and not TextUtil.is_upper(prv)) or (nxt != -1 and not TextUtil.is_upper(nxt))):
			return false
		if b == 32 and nxt == 32:
			return false
		# Letters use . , ; and the apostrophe; colons, bangs, queries and dashes read as noise.
		if b in [45, 58, 33, 63]:
			return false
	var words: PackedStringArray = _words(ctx)
	for i2: int in range(1, words.size() - 1):
		var w: String = words[i2]
		if w == "":
			continue
		var q: int = w.find("'")
		if q >= 0 and (q == 0 or not CONTRACTIONS.has(w.substr(q + 1))):
			return false
		if vocab.has(w) or vocab.has(w.substr(0, q) if q > 0 else w):
			continue
		# An unknown complete word must look like a name: long enough and English-shaped.
		if w.length() < 5 or _trigram_per(w) < -4.3:
			return false
	var letters: PackedInt32Array = TextUtil.letter_indices(ctx.get_string_from_ascii())
	if letters.size() >= 8:
		if EnglishScore.fitness(letters) / float(letters.size() - 3) < -5.2:
			return false
	return true


func _completions(partial: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if partial == "":
		out = vocab_list.slice(0, COMMON_WORDS)
	else:
		for w: String in vocab_list:
			if w.begins_with(partial) and w.length() > partial.length():
				out.append(w)
	for t: String in tray:
		var tw: String = t.strip_edges()
		if tw.begins_with(partial) and tw.length() > partial.length():
			out.append(tw)
	return out


func _endings(suffix: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if suffix == "":
		return vocab_list.slice(0, COMMON_WORDS)
	for w: String in vocab_list:
		if w.ends_with(suffix) and w.length() > suffix.length():
			out.append(w)
	for t: String in tray:
		var tw: String = t.strip_edges()
		if tw.ends_with(suffix) and tw.length() > suffix.length():
			out.append(tw)
	return out
