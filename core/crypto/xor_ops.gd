class_name XorOps
extends RefCounted
## XOR on bytes. a^a = 0, a^0 = a; XOR is commutative, associative and self-inverse.


## Bytewise XOR over the shorter length.
static func xor_bytes(a: PackedByteArray, b: PackedByteArray) -> PackedByteArray:
	var n: int = mini(a.size(), b.size())
	var out: PackedByteArray = PackedByteArray()
	out.resize(n)
	for i: int in range(n):
		out[i] = a[i] ^ b[i]
	return out


static func xor_single(data: PackedByteArray, key: int) -> PackedByteArray:
	var out: PackedByteArray = data.duplicate()
	var k: int = key & 0xFF
	for i: int in range(out.size()):
		out[i] = out[i] ^ k
	return out


## Repeating-key XOR (the key cycles over the data).
static func xor_repeating(data: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray = data.duplicate()
	if key.is_empty():
		return out
	for i: int in range(out.size()):
		out[i] = out[i] ^ key[i % key.size()]
	return out


## Column j holds bytes j, j+size, j+2*size...
static func transpose(data: PackedByteArray, size: int) -> Array[PackedByteArray]:
	var cols: Array[PackedByteArray] = []
	for _j: int in range(size):
		cols.append(PackedByteArray())
	for i: int in range(data.size()):
		cols[i % size].append(data[i])
	return cols


## Inverse of transpose().
static func untranspose(cols: Array[PackedByteArray], total: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(total)
	var size: int = cols.size()
	if size == 0:
		return out
	for i: int in range(total):
		@warning_ignore("integer_division")
		var row: int = i / size
		out[i] = cols[i % size][row]
	return out


## Pseudo-random pad bytes from the seeded PCG32. Good enough for a game letter; a real
## one-time pad needs truly random bytes (and must be used once and kept secret).
static func random_pad(rng: Pcg32, length: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(length)
	for i: int in range(length):
		out[i] = rng.next_int(256)
	return out
