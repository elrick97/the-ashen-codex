class_name Kasiski
extends RefCounted
## Kasiski examination (published 1863): repeated ciphertext sequences tend to sit a
## multiple of the key length apart. Spacings are factored and the factors tallied.


## Repeated sequences of length min_len..max_len in the letters of `text`.
## Returns [{"seq": String, "positions": PackedInt32Array, "spacings": PackedInt32Array}],
## longest first. A shorter repeat is dropped when every occurrence lies inside a
## reported longer repeat (so "THET" doesn't also report "THE" and "HET").
static func find_repeats(text: String, min_len: int = 3, max_len: int = 8) -> Array[Dictionary]:
	var letters: String = TextUtil.letters_only(text)
	var out: Array[Dictionary] = []
	var covered: Array[Vector2i] = [] # (start, length) of reported occurrences
	for n: int in range(max_len, min_len - 1, -1):
		var seen: Dictionary = {}
		for i: int in range(letters.length() - n + 1):
			var s: String = letters.substr(i, n)
			if not seen.has(s):
				seen[s] = PackedInt32Array()
			var arr: PackedInt32Array = seen[s]
			arr.append(i)
			seen[s] = arr
		var keys: Array = seen.keys()
		keys.sort()
		for s: String in keys:
			var pos: PackedInt32Array = seen[s]
			if pos.size() < 2:
				continue
			var inside: bool = true
			for p: int in pos:
				if not _is_covered(covered, p, n):
					inside = false
					break
			if inside:
				continue
			for p: int in pos:
				covered.append(Vector2i(p, n))
			out.append({"seq": s, "positions": pos, "spacings": spacings(pos)})
	return out


## Distances between every pair of occurrences.
static func spacings(positions: PackedInt32Array) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for i: int in range(positions.size()):
		for j: int in range(i + 1, positions.size()):
			out.append(positions[j] - positions[i])
	return out


## Divisors of n in [lo, hi].
static func factors(n: int, lo: int = 2, hi: int = 20) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for f: int in range(lo, mini(hi, n) + 1):
		if n % f == 0:
			out.append(f)
	return out


## How many spacings each factor in [lo, hi] divides. Index = factor.
static func factor_tally(spacing_list: PackedInt32Array, lo: int = 2, hi: int = 20) -> PackedInt32Array:
	var tally: PackedInt32Array = PackedInt32Array()
	tally.resize(hi + 1)
	for d: int in spacing_list:
		for f: int in factors(d, lo, hi):
			tally[f] += 1
	return tally


## Every spacing from every repeat in the text.
static func all_spacings(text: String, min_len: int = 3) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for r: Dictionary in find_repeats(text, min_len):
		out.append_array(r["spacings"])
	return out


## Heuristic key length: the largest factor whose tally is at least `share` of the best
## tally. Small factors divide everything, so the largest well-supported one wins.
static func likely_period(text: String, lo: int = 2, hi: int = 20, share: float = 0.8) -> int:
	var tally: PackedInt32Array = factor_tally(all_spacings(text), lo, hi)
	var best: int = 0
	for f: int in range(lo, hi + 1):
		best = maxi(best, tally[f])
	if best == 0:
		return 0
	var pick: int = 0
	for f: int in range(lo, hi + 1):
		if float(tally[f]) >= share * float(best):
			pick = f
	return pick


static func _is_covered(covered: Array[Vector2i], start: int, n: int) -> bool:
	for c: Vector2i in covered:
		if start >= c.x and start + n <= c.x + c.y:
			return true
	return false
