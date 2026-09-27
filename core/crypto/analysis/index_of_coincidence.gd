class_name IndexOfCoincidence
extends RefCounted
## Index of coincidence (Friedman, 1922): IC = sum n_i(n_i - 1) / (N(N - 1)).
## English is about 0.066; uniformly random letters about 1/26 = 0.0385.

const ENGLISH_IC: float = 0.0667
const RANDOM_IC: float = 1.0 / 26.0


static func from_counts(letter_counts: PackedInt32Array) -> float:
	var n: int = 0
	var s: int = 0
	for c: int in letter_counts:
		n += c
		s += c * (c - 1)
	if n < 2:
		return 0.0
	return float(s) / float(n * (n - 1))


static func ic(text: String) -> float:
	return from_counts(Frequency.counts(text))


## IC x 26: about 1.73 for English, 1.0 for random letters.
static func normalized(value: float) -> float:
	return value * 26.0


## Mean IC of the `period` columns of the text's letters.
static func average_column_ic(text: String, period: int) -> float:
	if period < 1:
		return 0.0
	var cols: PackedStringArray = Vigenere.columns(text, period)
	var sum: float = 0.0
	for c: String in cols:
		sum += ic(c)
	return sum / float(period)


## Index p (1..max_period) -> average column IC. Index 0 is unused (0.0).
static func by_period(text: String, max_period: int) -> PackedFloat64Array:
	var out: PackedFloat64Array = PackedFloat64Array()
	out.resize(max_period + 1)
	for p: int in range(1, max_period + 1):
		out[p] = average_column_ic(text, p)
	return out


## Smallest period whose average column IC reaches `threshold` (multiples of the true
## period also score high, so the smallest is preferred). Falls back to the maximum.
static func likely_period(text: String, max_period: int, threshold: float = 0.058) -> int:
	var values: PackedFloat64Array = by_period(text, max_period)
	for p: int in range(1, max_period + 1):
		if values[p] >= threshold:
			return p
	var best: int = 1
	for p: int in range(1, max_period + 1):
		if values[p] > values[best]:
			best = p
	return best
