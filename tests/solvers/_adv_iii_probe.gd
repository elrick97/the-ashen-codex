extends SceneTree
## Throwaway adversarial probe for I.iii (delete after use).


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var db: ContentDB = ContentDB.new()
	db.load_all()
	for id: String in ["a1_p07", "a1_p08", "a1_p09"]:
		for v: int in range(4):
			_vig(db.puzzle(id), v)
	for v: int in range(3):
		_p10(db.puzzle("a1_p10"), v)
	for v: int in range(4):
		_p11(db.puzzle("a1_p11"), v)
	_p12(db.puzzle("a1_p12"), 0, false)
	quit(0)


func _vig(def: PuzzleDef, v: int) -> void:
	var inst: PuzzleInstance = PuzzleFactory.build(def, v, v > 0)
	var c: String = inst.ciphertexts[0]
	var key: String = str(inst.key)
	var p: int = key.length()
	var letters: int = c.length()
	print("%s v%d key=%s period=%d letters=%d cost=%d" % [def.id, v, key, p, letters, inst.trial_cost])
	# Per column: rank of plaintext E in cipher counts (tallest bar = E?)
	var cols: PackedStringArray = Vigenere.columns(c, p)
	var ranks: String = ""
	var shifts: PackedInt32Array = Vigenere.key_to_shifts(key)
	for j: int in range(p):
		var cnt: PackedInt32Array = Frequency.counts(cols[j])
		var e_c: int = posmod(4 + shifts[j], 26)
		var rank: int = 1
		var ties: int = 0
		for k: int in range(26):
			if cnt[k] > cnt[e_c]:
				rank += 1
			elif cnt[k] == cnt[e_c] and k != e_c:
				ties += 1
		var order: Array = range(26)
		order.sort_custom(func(a: int, b: int) -> bool: return cnt[a] > cnt[b])
		var top: String = ""
		for k: int in range(3):
			top += "%s=%d(%s) " % [String.chr(65 + order[k]), cnt[order[k]], String.chr(65 + posmod(order[k] - shifts[j], 26))]
		ranks += "\n   col%d n=%d E-rank=%d ties=%d top: %s" % [j + 1, cols[j].length(), rank, ties, top]
	print(ranks)
	var reps: Array[Dictionary] = Kasiski.find_repeats(c, 3, 8)
	var good: int = 0
	var s: String = ""
	for r: Dictionary in reps:
		var sp: PackedInt32Array = r["spacings"]
		var ok: bool = true
		for d: int in sp:
			if d % p != 0:
				ok = false
		if ok:
			good += 1
		s += "%s%s%s " % [r["seq"], str(Array(sp)), "" if ok else "*"]
	print("   repeats=%d genuine=%d : %s" % [reps.size(), good, s])
	var t: PackedInt32Array = Kasiski.factor_tally(Kasiski.all_spacings(c), 2, 12)
	var ts: String = ""
	for f: int in range(2, 13):
		ts += "%d:%d " % [f, t[f]]
	print("   factor tally: %s likely=%d" % [ts, Kasiski.likely_period(c, 2, 12)])
	var ic: PackedFloat64Array = IndexOfCoincidence.by_period(c, 12)
	var ics: String = ""
	for q: int in range(1, 13):
		ics += "%d:%.3f " % [q, ic[q]]
	print("   IoC: %s likely=%d" % [ics, IndexOfCoincidence.likely_period(c, 12)])


func _p10(def: PuzzleDef, v: int) -> void:
	var inst: PuzzleInstance = PuzzleFactory.build(def, v, v > 0)
	var cb: PackedByteArray = inst.cipher_bytes[0]
	var key: int = int(inst.key)
	var scores: Array = []
	for k: int in range(256):
		scores.append([EnglishScore.gauge(XorOps.xor_single(cb, k)), k])
	scores.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var top: String = ""
	for i: int in range(4):
		top += "%d(0x%02x)=%.2f[%s] " % [scores[i][1], scores[i][1], scores[i][0], XorOps.xor_single(cb, scores[i][1]).slice(0, 18).get_string_from_ascii().c_escape()]
	print("a1_p10 v%d key=%d a=%s b=%s  top: %s" % [v, key, String.chr(inst.extras["stage1_a"]), String.chr(inst.extras["stage1_b"]), top])


func _p11(def: PuzzleDef, v: int) -> void:
	var inst: PuzzleInstance = PuzzleFactory.build(def, v, v > 0)
	var cb: PackedByteArray = inst.cipher_bytes[0]
	var key: PackedByteArray = inst.key
	var sc: PackedFloat64Array = Hamming.keysize_scores(cb, 2, 40)
	var order: Array = range(2, 41)
	order.sort_custom(func(a: int, b: int) -> bool: return sc[a] < sc[b])
	var top: String = ""
	for i: int in range(6):
		top += "%d:%.3f " % [order[i], sc[order[i]]]
	print("a1_p11 v%d key='%s' len=%d bytes=%d comb-best: %s" % [v, key.get_string_from_ascii(), key.size(), cb.size(), top])
	# Per-column: is argmax gauge == key byte? and runner-up gap
	var cols: Array[PackedByteArray] = XorOps.transpose(cb, key.size())
	var miss: String = ""
	for j: int in range(key.size()):
		var best: Dictionary = EnglishScore.best_single_byte_key(cols[j])
		var g_true: float = EnglishScore.gauge(XorOps.xor_single(cols[j], key[j]))
		var second: float = 0.0
		for k: int in range(256):
			if k != key[j]:
				second = maxf(second, EnglishScore.gauge(XorOps.xor_single(cols[j], k)))
		miss += "%d:%s%.2f/%.2f " % [j, "" if int(best["key"]) == key[j] else "MISS", g_true, second]
	print("   col n=%d  true/2nd: %s" % [cols[0].size(), miss])


func _p12(def: PuzzleDef, v: int, frenzied: bool) -> void:
	var inst: PuzzleInstance = PuzzleFactory.build(def, v, frenzied)
	var ov: int = int(inst.extras["overlap"])
	var x: PackedByteArray = XorOps.xor_bytes(inst.cipher_bytes[0], inst.cipher_bytes[1]).slice(0, ov)
	print("a1_p12 lenA=%d lenB=%d overlap=%d targets=%s" % [inst.plain_bytes[0].size(), inst.plain_bytes[1].size(), ov, str(inst.extras["targets"])])
	var a: String = inst.plaintexts[0]
	var b: String = inst.plaintexts[1]
	print("A: " + a.substr(0, ov).c_escape())
	print("B: " + b.substr(0, ov).c_escape())
	for t: Dictionary in inst.extras["targets"]:
		var st: int = int(t["start"])
		var ln: int = int(t["length"])
		print("   target msg%d [%d..%d) A='%s' B='%s'" % [t["msg"], st, st + ln, a.substr(st, ln).c_escape(), b.substr(st, ln).c_escape()])
	for crib: String in inst.extras["crib_tray"]:
		var cb: PackedByteArray = crib.to_ascii_buffer()
		var plaus: PackedInt32Array = PackedInt32Array()
		for o: int in range(ov - cb.size() + 1):
			if Crib.is_plausible_upper(Crib.drag(x, cb, o)):
				plaus.append(o)
		var inA: PackedInt32Array = _find_all(a.substr(0, ov), crib)
		var inB: PackedInt32Array = _find_all(b.substr(0, ov), crib)
		print("   crib '%s': plausible offsets=%d %s | true A=%s B=%s" % [crib, plaus.size(), str(Array(plaus)) if plaus.size() < 25 else "", str(Array(inA)), str(Array(inB))])
		for o2: int in inA:
			print("      A@%d -> B reads '%s'" % [o2, Crib.drag(x, cb, o2).get_string_from_ascii().c_escape()])
		for o3: int in inB:
			print("      B@%d -> A reads '%s'" % [o3, Crib.drag(x, cb, o3).get_string_from_ascii().c_escape()])


func _find_all(h: String, n: String) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	var i: int = h.find(n)
	while i >= 0:
		out.append(i)
		i = h.find(n, i + 1)
	return out
