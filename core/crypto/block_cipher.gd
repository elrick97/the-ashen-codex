class_name BlockCipher
extends RefCounted
## Toy substitution-permutation network for Act II (stub level: working, tested, not yet
## used by any puzzle). Structure follows Heys' SPN tutorial: 16-bit block, four rounds
## of key mixing, 4-bit S-boxes and a bit transposition, final key whitening.
## It is a teaching toy with a 32-bit key; it is NOT secure.

const BLOCK_BYTES: int = 2
const ROUNDS: int = 4
const SBOX: Array[int] = [0xE, 0x4, 0xD, 0x1, 0x2, 0xF, 0xB, 0x8, 0x3, 0xA, 0x6, 0xC, 0x5, 0x9, 0x0, 0x7]


## Five 16-bit round keys from a 32-bit key: round key r = bits of the key rotated by 4r.
static func round_keys(key32: int) -> Array[int]:
	var k: int = key32 & 0xFFFFFFFF
	var out: Array[int] = []
	for r: int in range(ROUNDS + 1):
		var rot: int = ((k << (4 * r)) | (k >> (32 - 4 * r))) & 0xFFFFFFFF if r > 0 else k
		out.append((rot >> 16) & 0xFFFF)
	return out


static func encrypt_block(block: int, key32: int) -> int:
	var ks: Array[int] = round_keys(key32)
	var x: int = block & 0xFFFF
	for r: int in range(ROUNDS - 1):
		x = _permute(_substitute(x ^ ks[r], SBOX))
	x = _substitute(x ^ ks[ROUNDS - 1], SBOX)
	return x ^ ks[ROUNDS]


static func decrypt_block(block: int, key32: int) -> int:
	var ks: Array[int] = round_keys(key32)
	var inv: Array[int] = _inverse_sbox()
	var x: int = (block & 0xFFFF) ^ ks[ROUNDS]
	x = _substitute(x, inv) ^ ks[ROUNDS - 1]
	for r: int in range(ROUNDS - 2, -1, -1):
		x = _substitute(_permute(x), inv) ^ ks[r]
	return x


static func _substitute(x: int, box: Array[int]) -> int:
	var out: int = 0
	for n: int in range(4):
		out |= box[(x >> (4 * n)) & 0xF] << (4 * n)
	return out


## Bit transposition: bit (4*i + j) moves to bit (4*j + i). Its own inverse.
static func _permute(x: int) -> int:
	var out: int = 0
	for i: int in range(4):
		for j: int in range(4):
			if (x >> (4 * i + j)) & 1 == 1:
				out |= 1 << (4 * j + i)
	return out


static func _inverse_sbox() -> Array[int]:
	var inv: Array[int] = []
	inv.resize(16)
	for i: int in range(16):
		inv[SBOX[i]] = i
	return inv
