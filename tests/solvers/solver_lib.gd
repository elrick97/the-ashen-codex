class_name SolverLib
extends RefCounted
## Shared pieces for the reference solvers. Each solver uses ONLY the technique its
## puzzle teaches, through the core analysis functions; none of them reads the plaintext
## or the key (the tests compare the result afterwards).

## English letters by frequency (for the frequency-analysis starting key).
const ENGLISH_ORDER: String = "ETAOINSHRDLCUMWFGYPBVKJXQZ"


## Substitution by statistics: start from frequency ranks, then hill-climb by swapping
## pairs of plaintext assignments while the n-gram fitness improves.
## `fixed`: cipher index -> plain index pinned by a crib (never moved).
## `use_trigrams`: score with trigrams (the Bigrams-in-the-Marsh lesson) instead of quadgrams.
## Returns a 26-entry PackedInt32Array: cipher letter index -> plain letter index.
static func solve_substitution(ciphertext: String, fixed: Dictionary = {}, use_trigrams: bool = false, restarts: int = 4) -> PackedInt32Array:
	var c: PackedInt32Array = TextUtil.letter_indices(ciphertext)
	var ranked: PackedInt32Array = Frequency.ranked(ciphertext)
	var start: PackedInt32Array = PackedInt32Array()
	start.resize(26)
	start.fill(-1)
	var used: Dictionary = {}
	for ci: Variant in fixed.keys():
		start[int(ci)] = int(fixed[ci])
		used[int(fixed[ci])] = true
	var order: PackedInt32Array = TextUtil.letter_indices(ENGLISH_ORDER)
	var oi: int = 0
	for ci2: int in ranked:
		if start[ci2] >= 0:
			continue
		while used.has(order[oi]):
			oi += 1
		start[ci2] = order[oi]
		used[order[oi]] = true
		oi += 1
	var best: PackedInt32Array = start.duplicate()
	var best_score: float = _score(c, best, use_trigrams)
	var rng: Pcg32 = Pcg32.new(777)
	var key: PackedInt32Array = best.duplicate()
	for r: int in range(restarts):
		if r > 0:
			key = best.duplicate()
			for _k: int in range(3):
				var a0: int = rng.next_int(26)
				var b0: int = rng.next_int(26)
				if not fixed.has(a0) and not fixed.has(b0):
					var t0: int = key[a0]
					key[a0] = key[b0]
					key[b0] = t0
		var score: float = _score(c, key, use_trigrams)
		var improved: bool = true
		while improved:
			improved = false
			for a: int in range(26):
				if fixed.has(a):
					continue
				for b: int in range(a + 1, 26):
					if fixed.has(b):
						continue
					var t: int = key[a]
					key[a] = key[b]
					key[b] = t
					var s: float = _score(c, key, use_trigrams)
					if s > score:
						score = s
						improved = true
					else:
						key[b] = key[a]
						key[a] = t
		if score > best_score:
			best_score = score
			best = key.duplicate()
	return best


## Turns a cipher->plain index array into a Substitution key string (plain -> cipher).
static func to_key(cipher_to_plain: PackedInt32Array) -> String:
	var buf: PackedByteArray = PackedByteArray()
	buf.resize(26)
	for ci: int in range(26):
		buf[cipher_to_plain[ci]] = 65 + ci
	return buf.get_string_from_ascii()


static func _score(c: PackedInt32Array, key: PackedInt32Array, tri: bool) -> float:
	var p: PackedInt32Array = PackedInt32Array()
	p.resize(c.size())
	for i: int in range(c.size()):
		p[i] = key[c[i]]
	if not tri:
		return EnglishScore.fitness(p)
	var s: float = 0.0
	for i: int in range(p.size() - 2):
		s += EnglishScore.trigram_logp(p[i], p[i + 1], p[i + 2])
	return s


## Vigenere columns by frequency: chi-squared best Caesar shift for each column.
static func vigenere_shifts(ciphertext: String, period: int) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for col: String in Vigenere.columns(ciphertext, period):
		out.append(Frequency.shift_by_chi_squared(col))
	return out


## Repeating-key XOR columns: best single-byte key per transposed column.
static func xor_columns(data: PackedByteArray, size: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	for col: PackedByteArray in XorOps.transpose(data, size):
		out.append(int(EnglishScore.best_single_byte_key(col)["key"]))
	return out
