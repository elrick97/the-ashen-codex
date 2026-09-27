class_name Hamming
extends RefCounted
## Hamming distance (differing bits) and repeating-key XOR key-size estimation.


static func popcount(b: int) -> int:
	var v: int = b & 0xFF
	var n: int = 0
	while v != 0:
		n += v & 1
		v >>= 1
	return n


## Number of differing bits over the shorter length (inputs should be equal length).
static func distance(a: PackedByteArray, b: PackedByteArray) -> int:
	var d: int = 0
	for i: int in range(mini(a.size(), b.size())):
		d += popcount(a[i] ^ b[i])
	return d


static func distance_str(a: String, b: String) -> int:
	return distance(a.to_ascii_buffer(), b.to_ascii_buffer())


## Average of distance/keysize over adjacent block pairs (0-1, 1-2, ...), using up to
## `max_pairs` pairs. Returns INF if the data holds fewer than two blocks.
static func normalized_distance(data: PackedByteArray, keysize: int, max_pairs: int = 30) -> float:
	if keysize < 1:
		return INF
	@warning_ignore("integer_division")
	var blocks: int = data.size() / keysize
	var pairs: int = mini(blocks - 1, max_pairs)
	if pairs < 1:
		return INF
	var sum: float = 0.0
	for p: int in range(pairs):
		var a: PackedByteArray = data.slice(p * keysize, (p + 1) * keysize)
		var b: PackedByteArray = data.slice((p + 1) * keysize, (p + 2) * keysize)
		sum += float(distance(a, b)) / float(keysize)
	return sum / float(pairs)


## Index k (0..max_size) -> normalized distance; indices below min_size are INF.
static func keysize_scores(data: PackedByteArray, min_size: int = 2, max_size: int = 40) -> PackedFloat64Array:
	var out: PackedFloat64Array = PackedFloat64Array()
	out.resize(max_size + 1)
	for k: int in range(max_size + 1):
		out[k] = normalized_distance(data, k) if k >= min_size else INF
	return out


## The key size with the lowest normalized distance.
static func likely_keysize(data: PackedByteArray, min_size: int = 2, max_size: int = 40) -> int:
	var scores: PackedFloat64Array = keysize_scores(data, min_size, max_size)
	var best: int = min_size
	for k: int in range(min_size, max_size + 1):
		if scores[k] < scores[best]:
			best = k
	return best
