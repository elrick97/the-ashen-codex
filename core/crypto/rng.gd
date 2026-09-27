class_name Pcg32
extends RefCounted
## PCG32 (O'Neill's pcg32_random_r / pcg32_srandom_r) in pure GDScript.
##
## The 64-bit state is kept as four 16-bit limbs so no arithmetic ever
## overflows a signed 64-bit int. Output matches the reference C code
## bit for bit, so a stored seed rebuilds the same puzzle on any engine build.

const _MULT: Array[int] = [0x7F2D, 0x4C95, 0xF42D, 0x5851] # 6364136223846793005, low limb first
const MASK32: int = 0xFFFFFFFF

var _state: Array[int] = [0, 0, 0, 0]
var _inc: Array[int] = [0, 0, 0, 0]


## seed and stream must be non-negative. stream selects one of 2^63 sequences.
func _init(seed_value: int = 0, stream: int = 54) -> void:
	reseed(seed_value, stream)


func reseed(seed_value: int, stream: int = 54) -> void:
	_state = [0, 0, 0, 0]
	_inc = _shl1_or1(_limbs(stream))
	next_u32()
	_state = _add(_state, _limbs(seed_value))
	next_u32()


## Next uniformly distributed 32-bit value in [0, 2^32).
func next_u32() -> int:
	var old: Array[int] = _state.duplicate()
	_state = _add(_mul(old, _MULT), _inc)
	var hi: int = (old[3] << 16) | old[2]
	var lo: int = (old[1] << 16) | old[0]
	# xorshifted = ((old >> 18) ^ old) >> 27, truncated to 32 bits
	var s_hi: int = hi >> 18
	var s_lo: int = ((lo >> 18) | (hi << 14)) & MASK32
	var x_hi: int = hi ^ s_hi
	var x_lo: int = lo ^ s_lo
	var xorshifted: int = ((x_lo >> 27) | (x_hi << 5)) & MASK32
	var rot: int = hi >> 27
	return ((xorshifted >> rot) | (xorshifted << ((32 - rot) & 31))) & MASK32


## Unbiased integer in [0, bound). bound must be in [1, 2^32).
func next_int(bound: int) -> int:
	assert(bound > 0 and bound <= MASK32)
	var threshold: int = (0x100000000 - bound) % bound
	while true:
		var r: int = next_u32()
		if r >= threshold:
			return r % bound
	return 0


## Integer in [lo, hi], inclusive.
func range_int(lo: int, hi: int) -> int:
	return lo + next_int(hi - lo + 1)


## Float in [0, 1).
func next_float() -> float:
	return float(next_u32()) / 4294967296.0


## Fisher-Yates shuffle in place.
func shuffle(arr: Array) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = next_int(i + 1)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func pick(arr: Array) -> Variant:
	return arr[next_int(arr.size())]


static func _limbs(v: int) -> Array[int]:
	return [v & 0xFFFF, (v >> 16) & 0xFFFF, (v >> 32) & 0xFFFF, (v >> 48) & 0xFFFF]


static func _add(a: Array[int], b: Array[int]) -> Array[int]:
	var out: Array[int] = [0, 0, 0, 0]
	var carry: int = 0
	for i: int in range(4):
		var t: int = a[i] + b[i] + carry
		out[i] = t & 0xFFFF
		carry = t >> 16
	return out


## (a * b) mod 2^64 on 16-bit limbs; every partial sum stays below 2^35.
static func _mul(a: Array[int], b: Array[int]) -> Array[int]:
	var out: Array[int] = [0, 0, 0, 0]
	var carry: int = 0
	for k: int in range(4):
		var t: int = carry
		for i: int in range(k + 1):
			t += a[i] * b[k - i]
		out[k] = t & 0xFFFF
		carry = t >> 16
	return out


static func _shl1_or1(a: Array[int]) -> Array[int]:
	var out: Array[int] = [0, 0, 0, 0]
	var carry: int = 1
	for i: int in range(4):
		var t: int = (a[i] << 1) | carry
		out[i] = t & 0xFFFF
		carry = (a[i] >> 15) & 1
	return out
