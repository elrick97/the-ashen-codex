extends GutTest
## Every Act I puzzle, generated from its PuzzleDef on several seeds plus its post-frenzy
## variant, is solved by its reference solver using the intended technique.

const VARIANTS: Array[int] = [0, 1, 2, 3, 4]

var db: ContentDB = null


func before_all() -> void:
	db = ContentDB.new()
	db.load_all()


func _instances(id: String) -> Array[PuzzleInstance]:
	var def: PuzzleDef = db.puzzle(id)
	var out: Array[PuzzleInstance] = []
	assert_not_null(def, id + " exists")
	if def == null:
		return out
	for v: int in VARIANTS:
		out.append(PuzzleFactory.build(def, v, false))
	out.append(PuzzleFactory.build(def, 1, true))
	return out


func _tag(inst: PuzzleInstance) -> String:
	return "%s v%d%s" % [inst.def.id, inst.variant, " frenzied" if inst.frenzied else ""]


func test_all_twelve_puzzles_exist_and_generate() -> void:
	for n: int in range(1, 13):
		var id: String = "a1_p%02d" % n
		var def: PuzzleDef = db.puzzle(id)
		assert_not_null(def, id)
		if def == null:
			continue
		var inst: PuzzleInstance = PuzzleFactory.build(def)
		for p: String in inst.plaintexts:
			assert_gt(p.length(), 20, id + " has a real letter")
			assert_false(p.begins_with("LTR_"), id + " letter text is translated")
		assert_eq(def.hint_keys.size(), 3, id + " has three hints")
		assert_ne(def.anti_cheese, "", id + " documents its anti-cheese reasoning")


func test_generation_is_deterministic() -> void:
	for id: String in ["a1_p02", "a1_p06", "a1_p11", "a1_p12"]:
		var def: PuzzleDef = db.puzzle(id)
		var a: PuzzleInstance = PuzzleFactory.build(def, 2)
		var b: PuzzleInstance = PuzzleFactory.build(def, 2)
		assert_eq(a.ciphertexts, b.ciphertexts, id)
		assert_eq(a.cipher_bytes, b.cipher_bytes, id)
		var c: PuzzleInstance = PuzzleFactory.build(def, 3)
		assert_true(a.ciphertexts != c.ciphertexts or a.cipher_bytes != c.cipher_bytes, id + " variants differ")


func test_p01_brute_force() -> void:
	for inst: PuzzleInstance in _instances("a1_p01"):
		var r: Dictionary = ReferenceSolvers.solve_p01(inst)
		assert_eq(Caesar.decrypt(inst.ciphertexts[0], int(r["shift"])), inst.plaintexts[0], _tag(inst))


func test_p02_frequency_peak_is_e() -> void:
	for inst: PuzzleInstance in _instances("a1_p02"):
		var r: Dictionary = ReferenceSolvers.solve_p02(inst)
		assert_eq(int(r["shift"]), int(inst.key), _tag(inst))
		assert_eq(Caesar.decrypt(inst.ciphertexts[0], int(r["shift"])), inst.plaintexts[0], _tag(inst))


func test_p03_keyless_schemes() -> void:
	for inst: PuzzleInstance in _instances("a1_p03"):
		var r: Dictionary = ReferenceSolvers.solve_p03(inst)
		assert_eq(r["schemes"], inst.key, _tag(inst))
		var kinds: Dictionary = {}
		for s: Variant in inst.key:
			kinds[s] = true
		assert_eq(kinds.size(), 2, _tag(inst) + " mixes both schemes")


func test_p04_substitution_by_statistics() -> void:
	for inst: PuzzleInstance in _instances("a1_p04"):
		var r: Dictionary = ReferenceSolvers.solve_p04(inst)
		assert_eq(Substitution.decrypt(inst.ciphertexts[0], str(r["key"])), inst.plaintexts[0], _tag(inst))


func test_p05_crib_fits_once_and_solves() -> void:
	for inst: PuzzleInstance in _instances("a1_p05"):
		var r: Dictionary = ReferenceSolvers.solve_p05(inst)
		var pos: PackedInt32Array = r["crib_positions"]
		if inst.frenzied:
			assert_gt(pos.size(), 0, _tag(inst) + " short crib still fits")
		else:
			assert_eq(pos.size(), 1, _tag(inst) + " crib fits at exactly one offset")
		assert_eq(Substitution.decrypt(inst.ciphertexts[0], str(r["key"])), inst.plaintexts[0], _tag(inst))


func test_p05_frequency_alone_is_ambiguous() -> void:
	var inst: PuzzleInstance = PuzzleFactory.build(db.puzzle("a1_p05"))
	assert_lt(_rank_mapping_accuracy(inst), 0.6, "plain frequency ranking reads under 60% of the letter")


func test_p06_ngrams_needed_and_sufficient() -> void:
	for inst: PuzzleInstance in _instances("a1_p06"):
		var r: Dictionary = ReferenceSolvers.solve_p06(inst)
		assert_eq(Substitution.decrypt(inst.ciphertexts[0], str(r["key"])), inst.plaintexts[0], _tag(inst))
	var one: PuzzleInstance = PuzzleFactory.build(db.puzzle("a1_p06"))
	assert_lt(_rank_mapping_accuracy(one), 0.5, "single-letter ranking alone fails on the flattened letter")


func test_p07_given_period() -> void:
	for inst: PuzzleInstance in _instances("a1_p07"):
		var r: Dictionary = ReferenceSolvers.solve_p07(inst)
		assert_eq(Vigenere.decrypt_with_shifts(inst.ciphertexts[0], r["shifts"]), inst.plaintexts[0], _tag(inst))


func test_p08_kasiski_period() -> void:
	for inst: PuzzleInstance in _instances("a1_p08"):
		var r: Dictionary = ReferenceSolvers.solve_p08(inst)
		var klen: int = str(inst.key).length()
		assert_eq(int(r["period"]) % klen, 0, _tag(inst) + " period %d vs key %d" % [int(r["period"]), klen])
		assert_eq(Vigenere.decrypt_with_shifts(inst.ciphertexts[0], r["shifts"]), inst.plaintexts[0], _tag(inst))


func test_p09_ioc_period() -> void:
	for inst: PuzzleInstance in _instances("a1_p09"):
		var r: Dictionary = ReferenceSolvers.solve_p09(inst)
		assert_eq(int(r["period"]), str(inst.key).length(), _tag(inst))
		assert_eq(Vigenere.decrypt_with_shifts(inst.ciphertexts[0], r["shifts"]), inst.plaintexts[0], _tag(inst))
		var per_col: float = float(inst.ciphertexts[0].length()) / float(str(inst.key).length())
		assert_gt(per_col, 25.0, _tag(inst) + " >= 25 letters per column (IoC heuristic)")


func test_p10_xor() -> void:
	for inst: PuzzleInstance in _instances("a1_p10"):
		var r: Dictionary = ReferenceSolvers.solve_p10(inst)
		assert_eq(int(inst.extras["stage1_a"]) ^ int(r["stage1_key"]), int(inst.extras["stage1_b"]), _tag(inst))
		assert_eq(int(r["key"]), int(inst.key), _tag(inst))
		assert_eq(XorOps.xor_single(inst.cipher_bytes[0], int(r["key"])), inst.plain_bytes[0], _tag(inst))


func test_p11_hamming_keysize() -> void:
	for inst: PuzzleInstance in _instances("a1_p11"):
		var r: Dictionary = ReferenceSolvers.solve_p11(inst)
		var key: PackedByteArray = inst.key
		assert_eq(int(r["size"]) % key.size(), 0, _tag(inst) + " size %d vs %d" % [int(r["size"]), key.size()])
		assert_eq(XorOps.xor_repeating(inst.cipher_bytes[0], r["key"]), inst.plain_bytes[0], _tag(inst))
		assert_gt(float(inst.cipher_bytes[0].size()) / 40.0, 4.0 - 0.001, _tag(inst) + " >= ~4 blocks at the largest key size")


func test_p12_crib_dragging_recovers_targets() -> void:
	for inst: PuzzleInstance in _instances("a1_p12"):
		var r: Dictionary = ReferenceSolvers.solve_p12(inst)
		var known: Array = r["known"]
		var ok_same: bool = true
		var ok_swap: bool = true
		for t: Dictionary in inst.extras["targets"]:
			var m: int = int(t["msg"])
			for i: int in range(int(t["start"]), int(t["start"]) + int(t["length"])):
				if (known[m] as PackedByteArray)[i] != inst.plain_bytes[m][i]:
					ok_same = false
				if (known[1 - m] as PackedByteArray)[i] != inst.plain_bytes[m][i]:
					ok_swap = false
		assert_true(ok_same or ok_swap, _tag(inst) + " recovered the tithe night and the traitor (pins: %d)" % int(r["pins"]))


## Share of letters read correctly by mapping cipher letters to English by frequency rank only.
func _rank_mapping_accuracy(inst: PuzzleInstance) -> float:
	var c: String = inst.ciphertexts[0]
	var ranked: PackedInt32Array = Frequency.ranked(c)
	var order: PackedInt32Array = TextUtil.letter_indices(SolverLib.ENGLISH_ORDER)
	var map: PackedInt32Array = PackedInt32Array()
	map.resize(26)
	for i: int in range(26):
		map[ranked[i]] = order[i]
	var ci: PackedInt32Array = TextUtil.letter_indices(c)
	var pi: PackedInt32Array = TextUtil.letter_indices(inst.plaintexts[0])
	var right: int = 0
	for i: int in range(ci.size()):
		if map[ci[i]] == pi[i]:
			right += 1
	return float(right) / float(maxi(ci.size(), 1))
