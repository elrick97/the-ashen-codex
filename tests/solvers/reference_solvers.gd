class_name ReferenceSolvers
extends RefCounted
## One reference solver per Act I puzzle, each using the intended technique through the
## core analysis code. They see only what the player sees (ciphertext, the puzzle's
## given clues such as the period or the crib) and never the key or plaintext.

const WORDS_PATH: String = "res://tests/solvers/data/english_words.json"

static var _vocab: Dictionary = {}
static var _prefixes: Dictionary = {}


## 1. The First Letter: brute force the 26 shifts, keep the most English (key-space lesson).
static func solve_p01(inst: PuzzleInstance) -> Dictionary:
	var c: String = inst.ciphertexts[0]
	var best: int = 0
	var best_f: float = -INF
	for s: int in range(26):
		var f: float = EnglishScore.fitness(TextUtil.letter_indices(Caesar.decrypt(c, s)))
		if f > best_f:
			best_f = f
			best = s
	return {"shift": best}


## 2. The Rusted Wheel: frequency analysis, the peak cipher letter is E.
static func solve_p02(inst: PuzzleInstance) -> Dictionary:
	return {"shift": Frequency.shift_from_peak(inst.ciphertexts[0])}


## 3. Thirteen Turns: keyless schemes; try the two known methods and keep the English one.
static func solve_p03(inst: PuzzleInstance) -> Dictionary:
	var schemes: Array = []
	for c: String in inst.ciphertexts:
		var r: float = EnglishScore.fitness(TextUtil.letter_indices(Caesar.rot13(c)))
		var a: float = EnglishScore.fitness(TextUtil.letter_indices(Caesar.atbash(c)))
		schemes.append("rot13" if r >= a else "atbash")
	return {"schemes": schemes}


## 4. The Tithe Roll: frequency start + n-gram hill climb.
static func solve_p04(inst: PuzzleInstance) -> Dictionary:
	return {"key": SolverLib.to_key(SolverLib.solve_substitution(inst.ciphertexts[0]))}


## 5. The Signature: slide the crib to the offset where its letter pattern is consistent,
## pin those letters, then finish the rest statistically.
static func solve_p05(inst: PuzzleInstance) -> Dictionary:
	var c: String = inst.ciphertexts[0]
	var crib: String = TranslationServer.translate(str(inst.param("crib_key", ""))).to_upper()
	var pos: PackedInt32Array = Crib.substitution_positions(c, crib)
	var fixed: Dictionary = {}
	if pos.size() >= 1:
		var m: Dictionary = Crib.substitution_mapping(c, crib, pos[pos.size() - 1])
		for k: Variant in m.keys():
			fixed[int(k) - 65] = int(m[k]) - 65
	return {"key": SolverLib.to_key(SolverLib.solve_substitution(c, fixed)), "crib_positions": pos}


## 6. Bigrams in the Marsh: trigram statistics (single letters are flattened).
static func solve_p06(inst: PuzzleInstance) -> Dictionary:
	return {"key": SolverLib.to_key(SolverLib.solve_substitution(inst.ciphertexts[0], {}, true, 6))}


## 7. The Steward Grows Clever: the period is given; each column is a Caesar by frequency.
static func solve_p07(inst: PuzzleInstance) -> Dictionary:
	var period: int = int(inst.param("period_given", 5))
	return {"shifts": SolverLib.vigenere_shifts(inst.ciphertexts[0], period), "period": period}


## 8. Kasiski's Lens: the period from repeated-sequence spacings.
static func solve_p08(inst: PuzzleInstance) -> Dictionary:
	var period: int = Kasiski.likely_period(inst.ciphertexts[0], 2, int(inst.param("period_max", 12)))
	return {"shifts": SolverLib.vigenere_shifts(inst.ciphertexts[0], maxi(period, 1)), "period": period}


## 9. The Loom of Columns: the period from the index of coincidence.
static func solve_p09(inst: PuzzleInstance) -> Dictionary:
	var period: int = IndexOfCoincidence.likely_period(inst.ciphertexts[0], int(inst.param("period_max", 12)))
	return {"shifts": SolverLib.vigenere_shifts(inst.ciphertexts[0], period), "period": period}


## 10. Bit Rosary: stage 1 by the XOR law (K = A xor B); stage 3 by English scoring.
static func solve_p10(inst: PuzzleInstance) -> Dictionary:
	var a: int = int(inst.extras["stage1_a"])
	var b: int = int(inst.extras["stage1_b"])
	return {"stage1_key": a ^ b, "key": int(EnglishScore.best_single_byte_key(inst.cipher_bytes[0])["key"])}


## 11. The Litany Key: key size by normalized Hamming distance, then columns.
static func solve_p11(inst: PuzzleInstance) -> Dictionary:
	var data: PackedByteArray = inst.cipher_bytes[0]
	var size: int = Hamming.likely_keysize(data, int(inst.param("keysize_min", 2)), int(inst.param("keysize_max", 40)))
	return {"key": SolverLib.xor_columns(data, size), "size": size}


## 12. The Twice-Used Pad: crib-dragging. Seed with the best tray crib, then extend word by
## word at the edges of what is known, keeping guesses whose other-letter fragment reads
## as English. Returns the two recovered texts (0 = unknown byte). Which letter is "A" is
## only fixed up to a swap (the game shows the senders), so the caller checks both ways.
static func solve_p12(inst: PuzzleInstance, max_steps: int = 200) -> Dictionary:
	_ensure_vocab()
	var overlap: int = int(inst.extras["overlap"])
	var x: PackedByteArray = XorOps.xor_bytes(inst.cipher_bytes[0], inst.cipher_bytes[1]).slice(0, overlap)
	var known: Array[PackedByteArray] = [PackedByteArray(), PackedByteArray()]
	for r: int in range(2):
		known[r].resize(overlap)
		known[r].fill(0)
	var tray: PackedStringArray = inst.extras["crib_tray"]
	var pins: int = 0
	# Seed: every tray crib at every offset; keep the best-reading placement.
	var seed_best: Dictionary = {}
	for w: String in tray:
		var wb: PackedByteArray = w.to_ascii_buffer()
		for o: int in range(overlap - wb.size() + 1):
			var frag: PackedByteArray = Crib.drag(x, wb, o)
			if not Crib.is_plausible_upper(frag):
				continue
			var s: float = _fragment_score(frag) + wb.size() * 0.2
			if seed_best.is_empty() or s > float(seed_best["score"]):
				seed_best = {"score": s, "o": o, "w": wb}
	if seed_best.is_empty():
		return {"known": known, "pins": 0}
	_apply(known, x, 0, int(seed_best["o"]), seed_best["w"])
	pins += 1
	for _step: int in range(max_steps):
		var cand: Dictionary = _best_extension(known, x, tray)
		if cand.is_empty():
			break
		_apply(known, x, int(cand["row"]), int(cand["o"]), cand["w"])
		pins += 1
	return {"known": known, "pins": pins}


static func _apply(known: Array[PackedByteArray], x: PackedByteArray, row: int, o: int, w: PackedByteArray) -> void:
	var other: PackedByteArray = Crib.drag(x, w, o)
	for i: int in range(w.size()):
		known[row][o + i] = w[i]
		known[1 - row][o + i] = other[i]


## Candidate words at the edges of known regions, in either letter.
static func _best_extension(known: Array[PackedByteArray], x: PackedByteArray, tray: PackedStringArray) -> Dictionary:
	var n: int = x.size()
	var best: Dictionary = {}
	for row: int in range(2):
		var kb: PackedByteArray = known[row]
		for e: int in range(1, n):
			# Right edge: known up to e-1, unknown at e.
			if kb[e - 1] != 0 and kb[e] == 0:
				var start: int = e
				while start > 0 and kb[start - 1] != 0 and kb[start - 1] != 32:
					start -= 1
				var partial: String = kb.slice(start, e).get_string_from_ascii()
				for w: String in _completions(partial, tray):
					var wb: PackedByteArray = (w + " ").to_ascii_buffer()
					var cand: Dictionary = _evaluate(known, x, row, start, wb)
					if not cand.is_empty() and (best.is_empty() or float(cand["score"]) > float(best["score"])):
						best = cand
			# Left edge: unknown at e-1, known from e: complete the word that ends here.
			if kb[e - 1] == 0 and kb[e] != 0 and e >= 2:
				var stop: int = e
				while stop < n and kb[stop] != 0 and kb[stop] != 32:
					stop += 1
				var suffix: String = kb.slice(e, stop).get_string_from_ascii()
				for w2: String in _endings(suffix, tray):
					var wb2: PackedByteArray = (" " + w2).to_ascii_buffer()
					var o2: int = stop - wb2.size()
					if o2 < 0:
						continue
					var cand2: Dictionary = _evaluate(known, x, row, o2, wb2)
					if not cand2.is_empty() and (best.is_empty() or float(cand2["score"]) > float(best["score"])):
						best = cand2
	return best


static func _evaluate(known: Array[PackedByteArray], x: PackedByteArray, row: int, o: int, wb: PackedByteArray) -> Dictionary:
	if o < 0 or o + wb.size() > x.size():
		return {}
	var fresh: int = 0
	for i: int in range(wb.size()):
		var k: int = known[row][o + i]
		if k != 0 and k != wb[i]:
			return {}
		if k == 0:
			fresh += 1
	if fresh == 0:
		return {}
	var frag: PackedByteArray = Crib.drag(x, wb, o)
	for i: int in range(frag.size()):
		var k2: int = known[1 - row][o + i]
		if k2 != 0 and k2 != frag[i]:
			return {}
	if not Crib.is_plausible_upper(frag):
		return {}
	# Read the other letter's words through the new fragment, with known neighbours.
	var s: int = o
	while s > 0 and known[1 - row][s - 1] != 0:
		s -= 1
	var t: int = o + wb.size()
	while t < x.size() and known[1 - row][t] != 0:
		t += 1
	var ctx: PackedByteArray = known[1 - row].slice(s, t)
	for i: int in range(frag.size()):
		ctx[o - s + i] = frag[i]
	var score: float = _fragment_score(ctx) + 0.15 * fresh
	return {"score": score, "row": row, "o": o, "w": wb}


## Higher when the fragment's complete words are English (or story) words.
static func _fragment_score(frag: PackedByteArray) -> float:
	var text: String = frag.get_string_from_ascii()
	var parts: PackedStringArray = text.split(" ")
	var score: float = 0.0
	for i: int in range(parts.size()):
		var w: String = parts[i].strip_edges().trim_suffix(".").trim_suffix(",").trim_suffix(";").trim_suffix(":")
		if w == "":
			continue
		var complete: bool = i > 0 and i < parts.size() - 1
		if complete:
			score += float(w.length()) if _vocab.has(w) else -2.0
		elif _prefixes.has(w) or _vocab.has(w):
			score += 0.5 * w.length()
	return score + EnglishScore.score_bytes(frag)


static func _completions(partial: String, tray: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for w: String in _vocab.keys():
		if w.begins_with(partial) and w.length() > partial.length():
			out.append(w)
	for t: String in tray:
		var tw: String = t.strip_edges()
		if tw.begins_with(partial) and tw.length() > partial.length():
			out.append(tw)
	if partial == "":
		out.append_array(PackedStringArray(["THE", "AND", "OF", "TO", "IN", "AT", "IS", "A"]))
	return out


static func _endings(suffix: String, tray: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for w: String in _vocab.keys():
		if w.ends_with(suffix) and w.length() > suffix.length():
			out.append(w)
	for t: String in tray:
		var tw: String = t.strip_edges()
		if tw.ends_with(suffix) and tw.length() > suffix.length():
			out.append(tw)
	return out


static func _ensure_vocab() -> void:
	if not _vocab.is_empty():
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS_PATH))
	for w: Variant in (d as Dictionary)["words"]:
		var s: String = str(w)
		_vocab[s] = true
		for i: int in range(1, s.length()):
			_prefixes[s.substr(0, i)] = true
