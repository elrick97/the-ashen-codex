class_name PuzzleFactory
extends RefCounted
## Turns a PuzzleDef + variant into a PuzzleInstance: reads the letters through tr(),
## normalizes them, derives the key from key_rule with a seeded PCG32, and encrypts
## with the crypto core. Same def + variant + locale = same puzzle, always.


static func build(def: PuzzleDef, variant: int = 0, frenzied: bool = false) -> PuzzleInstance:
	var inst: PuzzleInstance = PuzzleInstance.new()
	inst.def = def
	inst.variant = variant
	inst.frenzied = frenzied
	inst.seed_value = def.seed_for_variant(variant)
	inst.params = def.params.duplicate(true)
	inst.trial_cost = def.trial_cost
	if frenzied:
		for k: Variant in def.frenzy_overrides.keys():
			if str(k) == "trial_cost":
				inst.trial_cost = int(def.frenzy_overrides[k])
			else:
				inst.params[k] = def.frenzy_overrides[k]
	var rng: Pcg32 = Pcg32.new(inst.seed_value, def.number)
	for k: String in def.plaintext_keys:
		inst.plaintexts.append(TextUtil.normalize(letter_text(k), def.normalization))
	inst.key = make_key(def.key_rule, rng, inst.plaintexts.size())
	match def.mode:
		"caesar":
			for p: String in inst.plaintexts:
				inst.ciphertexts.append(Caesar.encrypt(p, int(inst.key)))
		"keyless":
			var schemes: Array = inst.key
			for i: int in range(inst.plaintexts.size()):
				var p: String = inst.plaintexts[i]
				inst.ciphertexts.append(Caesar.rot13(p) if schemes[i] == "rot13" else Caesar.atbash(p))
		"substitution":
			for p: String in inst.plaintexts:
				inst.ciphertexts.append(Substitution.encrypt(p, str(inst.key)))
		"vigenere":
			for p: String in inst.plaintexts:
				inst.ciphertexts.append(Vigenere.encrypt(p, str(inst.key)))
		"xor_rosary":
			_build_rosary(inst, rng)
		"xor_repeating":
			for p: String in inst.plaintexts:
				var pb: PackedByteArray = p.to_ascii_buffer()
				inst.plain_bytes.append(pb)
				inst.cipher_bytes.append(XorOps.xor_repeating(pb, inst.key))
		"two_time_pad":
			_build_two_time_pad(inst)
		_:
			push_error("PuzzleFactory: unknown mode " + def.mode)
	return inst


## A letter's text from the translation table (CSV values are ASCII with real newlines).
static func letter_text(key: String) -> String:
	return TranslationServer.translate(key)


static func make_key(rule: Dictionary, rng: Pcg32, letters: int) -> Variant:
	var kind: String = str(rule.get("type", ""))
	match kind:
		"shift":
			return rng.range_int(int(rule.get("min", 1)), int(rule.get("max", 25)))
		"scheme_mix":
			var pool: Array = rule.get("schemes", ["rot13", "atbash"])
			var out: Array = []
			for _i: int in range(letters):
				out.append(rng.pick(pool))
			if letters >= 2 and pool.size() >= 2:
				var all_same: bool = true
				for s: Variant in out:
					if s != out[0]:
						all_same = false
				if all_same:
					out[letters - 1] = pool[(pool.find(out[0]) + 1) % pool.size()]
			return out
		"perm":
			return Substitution.random_key(rng, bool(rule.get("derangement", true)))
		"word":
			return str(rng.pick(rule.get("pool", ["KEY"]))).to_upper()
		"byte":
			var excluded: Array = rule.get("exclude", [])
			while true:
				var b: int = rng.range_int(int(rule.get("min", 1)), int(rule.get("max", 255)))
				if not excluded.has(b) and not excluded.has(float(b)):
					return b
		"phrase":
			return str(rng.pick(rule.get("pool", ["KEY"]))).to_ascii_buffer()
		"pad":
			return null # sized by the letters, see _build_two_time_pad
	push_error("PuzzleFactory: unknown key rule " + kind)
	return null


static func _build_rosary(inst: PuzzleInstance, rng: Pcg32) -> void:
	var k: int = int(inst.key)
	for p: String in inst.plaintexts:
		var pb: PackedByteArray = p.to_ascii_buffer()
		inst.plain_bytes.append(pb)
		inst.cipher_bytes.append(XorOps.xor_single(pb, k))
	var pool: PackedByteArray = str(inst.param("stage1_pool", "ABCDEFGHIJKLMNOPQRSTUVWXYZ")).to_ascii_buffer()
	var a: int = pool[rng.next_int(pool.size())]
	var b: int = a
	while b == a:
		b = pool[rng.next_int(pool.size())]
	inst.extras["stage1_a"] = a
	inst.extras["stage1_b"] = b
	var word_key: String = str(inst.param("stage2_word_key", ""))
	var word: String = letter_text(word_key) if word_key != "" else "BLOOD"
	inst.extras["stage2_word"] = word.to_upper().to_ascii_buffer()
	inst.extras["stage2_key"] = a ^ b


static func _build_two_time_pad(inst: PuzzleInstance) -> void:
	var longest: int = 0
	for p: String in inst.plaintexts:
		inst.plain_bytes.append(p.to_ascii_buffer())
		longest = maxi(longest, p.length())
	var rng: Pcg32 = Pcg32.new(inst.seed_value, 1000 + inst.def.number)
	var pad: PackedByteArray = XorOps.random_pad(rng, longest)
	inst.key = pad
	for pb: PackedByteArray in inst.plain_bytes:
		inst.cipher_bytes.append(XorOps.xor_bytes(pb, pad))
	var overlap: int = mini(inst.plain_bytes[0].size(), inst.plain_bytes[1].size()) if inst.plain_bytes.size() >= 2 else 0
	inst.extras["overlap"] = overlap
	var targets: Array[Dictionary] = []
	for t: Variant in inst.param("targets", []):
		var td: Dictionary = t
		var msg: int = int(td.get("msg", 0))
		var phrase: String = TextUtil.normalize(letter_text(str(td.get("phrase_key", ""))), inst.def.normalization)
		var start: int = inst.plaintexts[msg].find(phrase)
		if start < 0 or start + phrase.length() > overlap:
			push_error("PuzzleFactory: target phrase not inside the overlap: " + phrase)
			continue
		targets.append({"msg": msg, "start": start, "length": phrase.length(), "label_key": str(td.get("label_key", ""))})
	inst.extras["targets"] = targets
	var tray: PackedStringArray = PackedStringArray()
	for ck: Variant in inst.param("crib_tray_keys", []):
		tray.append(TextUtil.normalize(letter_text(str(ck)), inst.def.normalization))
	inst.extras["crib_tray"] = tray
