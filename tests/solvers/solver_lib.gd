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
static func solve_substitution(ciphertext: String, fixed: Dictionary = {}, use_trigrams: bool = false, restarts: int = 10) -> PackedInt32Array:
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
	var best: PackedInt32Array = _climb(c, start.duplicate(), fixed, use_trigrams)
	var best_score: float = _score(c, best, use_trigrams)
	var rng: Pcg32 = Pcg32.new(777)
	for r: int in range(1, restarts):
		# Restart from a shaken copy of the best key (half the time) or a fresh shuffle.
		var key: PackedInt32Array = best.duplicate()
		var free: Array = []
		for i: int in range(26):
			if not fixed.has(i):
				free.append(i)
		if r % 2 == 0:
			var vals: Array = []
			for i2: int in free:
				vals.append(key[i2])
			rng.shuffle(vals)
			for j: int in range(free.size()):
				key[free[j]] = vals[j]
		else:
			for _k: int in range(4):
				var a0: int = free[rng.next_int(free.size())]
				var b0: int = free[rng.next_int(free.size())]
				var t0: int = key[a0]
				key[a0] = key[b0]
				key[b0] = t0
		key = _climb(c, key, fixed, use_trigrams)
		var sc: float = _score(c, key, use_trigrams)
		if sc > best_score:
			best_score = sc
			best = key
	return best


## Hill-climb: keep swapping pairs of plaintext assignments while the score improves.
static func _climb(c: PackedInt32Array, key: PackedInt32Array, fixed: Dictionary, tri: bool) -> PackedInt32Array:
	var score: float = _score(c, key, tri)
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
				var s: float = _score(c, key, tri)
				if s > score:
					score = s
					improved = true
				else:
					key[b] = key[a]
					key[a] = t
	return key


## Word patterns: with word breaks kept, keep swapping letters while more of the reading
## is made of real English words (the second half of the Tithe Roll technique).
static func polish_with_words(ciphertext: String, cipher_to_plain: PackedInt32Array, words: Dictionary, fixed: Dictionary = {}) -> PackedInt32Array:
	var key: PackedInt32Array = cipher_to_plain.duplicate()
	var present: Array[int] = []
	var movable: Array[int] = []
	var counts: PackedInt32Array = Frequency.counts(ciphertext)
	for i: int in range(26):
		if not fixed.has(i):
			movable.append(i)
			if counts[i] > 0:
				present.append(i)
	var spaced: bool = ciphertext.strip_edges().contains(" ")
	var best: int = _word_score(ciphertext, key, words) if spaced else _segment_score(ciphertext, key, words)
	var improved: bool = true
	while improved:
		improved = false
		for a: int in present:
			for b: int in movable:
				if b <= a and counts[b] > 0:
					continue
				if b == a:
					continue
				var t: int = key[a]
				key[a] = key[b]
				key[b] = t
				var s: int = _word_score(ciphertext, key, words) if spaced else _segment_score(ciphertext, key, words)
				if s > best:
					best = s
					improved = true
				else:
					key[b] = key[a]
					key[a] = t
	return key


## Letters without word breaks: the most letters that can be covered by real words
## (dynamic-programming segmentation, words up to 12 letters).
static func _segment_score(ciphertext: String, key: PackedInt32Array, words: Dictionary) -> int:
	var c: PackedInt32Array = TextUtil.letter_indices(ciphertext)
	var plain: PackedByteArray = PackedByteArray()
	plain.resize(c.size())
	for i: int in range(c.size()):
		plain[i] = 65 + key[c[i]]
	var text: String = plain.get_string_from_ascii()
	var n: int = text.length()
	var best: PackedInt32Array = PackedInt32Array()
	best.resize(n + 1)
	for i2: int in range(1, n + 1):
		best[i2] = best[i2 - 1]
		for l: int in range(2, mini(12, i2) + 1):
			if words.has(text.substr(i2 - l, l)):
				best[i2] = maxi(best[i2], best[i2 - l] + l)
	return best[n]


static func _word_score(ciphertext: String, key: PackedInt32Array, words: Dictionary) -> int:
	var total: int = 0
	var cur: String = ""
	for ch: int in (ciphertext.to_upper() + " ").to_ascii_buffer():
		if TextUtil.is_upper(ch):
			cur += String.chr(65 + key[ch - 65])
		else:
			if cur != "" and words.has(cur):
				total += cur.length()
			cur = ""
	return total


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
