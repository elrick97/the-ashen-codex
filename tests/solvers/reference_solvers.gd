class_name ReferenceSolvers
extends RefCounted
## One reference solver per Act I puzzle, each using the intended technique through the
## core analysis code. They see only what the player sees (ciphertext, the puzzle's
## given clues such as the period or the crib) and never the key or plaintext.

const WORDS_PATH: String = "res://tests/solvers/data/english_words.json"

static var _vocab_list: PackedStringArray = PackedStringArray()


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
	var c: String = inst.ciphertexts[0]
	var k: PackedInt32Array = SolverLib.solve_substitution(c)
	return {"key": SolverLib.to_key(SolverLib.polish_with_words(c, k, _word_set()))}


## 5. The Signature: slide the crib to the offset where its letter pattern is consistent,
## pin those letters, then finish the rest statistically.
static func solve_p05(inst: PuzzleInstance) -> Dictionary:
	var c: String = inst.ciphertexts[0]
	# As on the crib strip: letters only, so only letter-repeat patterns place the crib.
	var letters: String = TextUtil.letters_only(c)
	var crib: String = TextUtil.letters_only(TranslationServer.translate(str(inst.param("crib_key", ""))))
	var pos: PackedInt32Array = Crib.substitution_positions(letters, crib)
	var fixed: Dictionary = {}
	if pos.size() >= 1:
		# Several consistent places are possible for a short crib; a sign-off sits last.
		var m: Dictionary = Crib.substitution_mapping(letters, crib, pos[pos.size() - 1])
		for k: Variant in m.keys():
			fixed[int(k) - 65] = int(m[k]) - 65
	var k: PackedInt32Array = SolverLib.solve_substitution(c, fixed)
	return {"key": SolverLib.to_key(SolverLib.polish_with_words(c, k, _word_set(), fixed)), "crib_positions": pos}


## 6. Bigrams in the Marsh: n-gram statistics across word boundaries (single letters
## are flattened, so only multi-letter structure such as TH, HE, THE can anchor the key).
static func solve_p06(inst: PuzzleInstance) -> Dictionary:
	var c: String = inst.ciphertexts[0]
	var k: PackedInt32Array = SolverLib.solve_substitution(c, {}, true, 40)
	return {"key": SolverLib.to_key(SolverLib.polish_with_words(c, k, _word_set()))}


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


## 12. The Twice-Used Pad: crib-dragging (see CribDragSolver). Returns the two recovered
## texts (0 = unknown byte). Which letter is "A" is only fixed up to a swap (the game
## shows the senders), so the caller checks both ways.
static func solve_p12(inst: PuzzleInstance) -> Dictionary:
	_ensure_vocab()
	var overlap: int = int(inst.extras["overlap"])
	var x: PackedByteArray = XorOps.xor_bytes(inst.cipher_bytes[0], inst.cipher_bytes[1]).slice(0, overlap)
	var solver: CribDragSolver = CribDragSolver.new(x, inst.extras["crib_tray"], _story_words() + _vocab_list.slice(0, 6000))
	return solver.solve()


## Words from everything the player has read before the boss: the letters of puzzles
## 1-11 and every dialogue scene up to puzzle 12, commonest first. A player at the boss
## knows the House's vocabulary (tithe, moon, barn) and the names in the story.
static func _story_words() -> PackedStringArray:
	var keys: PackedStringArray = PackedStringArray()
	for n: int in range(1, 12):
		for suffix: String in ["", "_A", "_B", "_C"]:
			keys.append("LTR_P%02d%s" % [n, suffix])
	var db: ContentDB = ContentDB.new()
	db.load_all()
	for cid: String in ["a1_i", "a1_ii", "a1_iii"]:
		var ch: ChapterDef = db.chapter(cid)
		if ch == null:
			continue
		for st: Dictionary in ch.steps:
			if str(st.get("id", "")) == "a1_p12":
				break
			if str(st.get("type", "")) != "dialogue":
				continue
			for node: Variant in db.dialogue(str(st["id"])).get("nodes", []):
				var nd: Dictionary = node
				keys.append(str(nd.get("text", "")))
				for c: Variant in nd.get("choices", []):
					keys.append(str((c as Dictionary).get("text", "")))
	var counts: Dictionary = {}
	for key: String in keys:
		var t: String = TranslationServer.translate(key)
		if t == key:
			continue
		var cur: String = ""
		for ch2: String in (t.to_upper() + " "):
			if ch2 >= "A" and ch2 <= "Z":
				cur += ch2
			else:
				if cur.length() >= 2:
					counts[cur] = int(counts.get(cur, 0)) + 1
				cur = ""
	var words: Array = counts.keys()
	words.sort_custom(func(a2: String, b2: String) -> bool: return int(counts[a2]) > int(counts[b2]))
	return PackedStringArray(words)


static func _word_set() -> Dictionary:
	_ensure_vocab()
	var d: Dictionary = {}
	for w: String in _vocab_list:
		d[w] = true
	return d


static func _ensure_vocab() -> void:
	if not _vocab_list.is_empty():
		return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS_PATH))
	for w: Variant in (d as Dictionary)["words"]:
		_vocab_list.append(str(w))
