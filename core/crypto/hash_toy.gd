class_name HashToy
extends RefCounted
## A deliberately weak 16-bit hash for Act III (stub level: working, tested, unused).
## Merkle-Damgard with a Davies-Meyer compression function over BlockCipher:
##   h_i = E_{m_i}(h_{i-1}) xor h_{i-1}
## Only 16 bits, so a birthday search finds a collision after roughly 2^8 = 256 tries,
## and hash(secret || msg) is open to length extension. Both are the Act III lessons.

const IV: int = 0x3A5C


## Merkle-Damgard strengthening: 0x80, zeros, then the bit length as 2 bytes.
static func md_pad(data: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray = data.duplicate()
	out.append(0x80)
	while (out.size() + 2) % BlockCipher.BLOCK_BYTES != 0:
		out.append(0)
	var bits: int = (data.size() * 8) & 0xFFFF
	out.append((bits >> 8) & 0xFF)
	out.append(bits & 0xFF)
	return out


## Runs the compression function from `state` over already-padded blocks.
static func compress(state: int, padded: PackedByteArray) -> int:
	var h: int = state & 0xFFFF
	for i: int in range(0, padded.size() - 1, 2):
		var m: int = (padded[i] << 8) | padded[i + 1]
		h = BlockCipher.encrypt_block(h, (m << 16) | m) ^ h
	return h


static func digest(data: PackedByteArray) -> int:
	return compress(IV, md_pad(data))
