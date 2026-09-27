class_name Frequency
extends RefCounted
## Letter and n-gram frequency analysis (al-Kindi, 9th century).

## Expected English letter frequencies A..Z (Lewand, "Cryptological Mathematics", 2000).
const ENGLISH: Array[float] = [
	0.08167, 0.01492, 0.02782, 0.04253, 0.12702, 0.02228, 0.02015, 0.06094, 0.06966,
	0.00153, 0.00772, 0.04025, 0.02406, 0.06749, 0.07507, 0.01929, 0.00095, 0.05987,
	0.06327, 0.09056, 0.02758, 0.00978, 0.02360, 0.00150, 0.01974, 0.00074,
]
const COMMON_BIGRAMS: PackedStringArray = ["TH", "HE", "IN", "ER", "AN", "RE", "ND", "ON", "EN", "AT"]
const COMMON_TRIGRAMS: PackedStringArray = ["THE", "AND", "ING", "HER", "THA", "ENT", "ION", "TIO"]
const INDEX_E: int = 4


## Letter counts A..Z (case-insensitive; non-letters ignored).
static func counts(text: String) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	out.resize(26)
	for i: int in TextUtil.letter_indices(text):
		out[i] += 1
	return out


static func total(letter_counts: PackedInt32Array) -> int:
	var t: int = 0
	for c: int in letter_counts:
		t += c
	return t


## Proportions A..Z summing to 1 (all zero for text without letters).
static func proportions(text: String) -> PackedFloat64Array:
	var c: PackedInt32Array = counts(text)
	var t: int = total(c)
	var out: PackedFloat64Array = PackedFloat64Array()
	out.resize(26)
	if t == 0:
		return out
	for i: int in range(26):
		out[i] = float(c[i]) / float(t)
	return out


## Letter indices sorted by count, most frequent first (ties: alphabetical).
static func ranked(text: String) -> PackedInt32Array:
	var c: PackedInt32Array = counts(text)
	var idx: Array[int] = []
	for i: int in range(26):
		idx.append(i)
	idx.sort_custom(func(a: int, b: int) -> bool: return c[a] > c[b] or (c[a] == c[b] and a < b))
	return PackedInt32Array(idx)


## Letter index of the most frequent letter (the "peak").
static func peak(text: String) -> int:
	return ranked(text)[0]


## Chi-squared statistic of observed counts against English. Lower is more English-like.
static func chi_squared(letter_counts: PackedInt32Array) -> float:
	var t: int = total(letter_counts)
	if t == 0:
		return INF
	var chi: float = 0.0
	for i: int in range(26):
		var expected: float = ENGLISH[i] * t
		var d: float = letter_counts[i] - expected
		chi += d * d / expected
	return chi


## Caesar shift under the assumption that the peak cipher letter stands for E.
static func shift_from_peak(ciphertext: String) -> int:
	return Caesar.shift_between(INDEX_E, peak(ciphertext))


## Caesar shift whose decryption has the lowest chi-squared against English.
static func shift_by_chi_squared(ciphertext: String) -> int:
	var c: PackedInt32Array = counts(ciphertext)
	var best: int = 0
	var best_chi: float = INF
	for s: int in range(26):
		var shifted: PackedInt32Array = PackedInt32Array()
		shifted.resize(26)
		for i: int in range(26):
			shifted[i] = c[posmod(i + s, 26)]
		var chi: float = chi_squared(shifted)
		if chi < best_chi:
			best_chi = chi
			best = s
	return best


## n-gram counts. With within_words, n-grams never cross a non-letter; otherwise the
## text is reduced to letters first (right for text written without word breaks).
static func ngram_counts(text: String, n: int, within_words: bool = false) -> Dictionary:
	var out: Dictionary = {}
	var chunks: PackedStringArray = PackedStringArray()
	if within_words:
		var word: String = ""
		for c: int in text.to_upper().to_ascii_buffer():
			if TextUtil.is_upper(c):
				word += String.chr(c)
			else:
				if word != "":
					chunks.append(word)
				word = ""
		if word != "":
			chunks.append(word)
	else:
		chunks.append(TextUtil.letters_only(text))
	for w: String in chunks:
		for i: int in range(w.length() - n + 1):
			var g: String = w.substr(i, n)
			out[g] = int(out.get(g, 0)) + 1
	return out


## The k most common n-grams as [{"gram": String, "count": int}], ties alphabetical.
static func top_ngrams(text: String, n: int, k: int, within_words: bool = false) -> Array[Dictionary]:
	var c: Dictionary = ngram_counts(text, n, within_words)
	var grams: Array = c.keys()
	grams.sort_custom(func(a: String, b: String) -> bool:
		return int(c[a]) > int(c[b]) or (int(c[a]) == int(c[b]) and a < b))
	var out: Array[Dictionary] = []
	for i: int in range(mini(k, grams.size())):
		out.append({"gram": grams[i], "count": int(c[grams[i]])})
	return out
