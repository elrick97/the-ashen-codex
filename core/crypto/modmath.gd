class_name ModMath
extends RefCounted
## Modular arithmetic for Act IV, safe for 64-bit signed ints.
##
## GDScript ints are 64-bit signed, so a*b overflows once both factors pass 2^31.
## mulmod() uses double-and-add so every intermediate stays below 2^63 for moduli
## up to 2^62. Larger numbers need BigInt (see bigint.gd).

const MAX_MODULUS: int = 1 << 62


static func gcd(a: int, b: int) -> int:
	var x: int = absi(a)
	var y: int = absi(b)
	while y != 0:
		var t: int = x % y
		x = y
		y = t
	return x


## (a * b) mod m without overflow, for 1 <= m <= 2^62. Result in [0, m).
static func mulmod(a: int, b: int, m: int) -> int:
	assert(m >= 1 and m <= MAX_MODULUS)
	var x: int = posmod(a, m)
	var y: int = posmod(b, m)
	var result: int = 0
	while y > 0:
		if y & 1 == 1:
			result = (result + x) % m
		x = (x * 2) % m
		y >>= 1
	return result


## base^exponent mod m for exponent >= 0 (square-and-multiply).
static func modpow(base: int, exponent: int, m: int) -> int:
	assert(exponent >= 0)
	if m == 1:
		return 0
	var result: int = 1
	var b: int = posmod(base, m)
	var e: int = exponent
	while e > 0:
		if e & 1 == 1:
			result = mulmod(result, b, m)
		b = mulmod(b, b, m)
		e >>= 1
	return result


## Extended Euclid: returns [g, x, y] with a*x + b*y = g = gcd(a, b).
static func egcd(a: int, b: int) -> Array[int]:
	var old_r: int = a
	var r: int = b
	var old_s: int = 1
	var s: int = 0
	var old_t: int = 0
	var t: int = 1
	while r != 0:
		@warning_ignore("integer_division")
		var q: int = old_r / r
		var tmp: int = r
		r = old_r - q * r
		old_r = tmp
		tmp = s
		s = old_s - q * s
		old_s = tmp
		tmp = t
		t = old_t - q * t
		old_t = tmp
	if old_r < 0:
		return [-old_r, -old_s, -old_t]
	return [old_r, old_s, old_t]


## Inverse of a mod m, or -1 if gcd(a, m) != 1.
static func modinv(a: int, m: int) -> int:
	var r: Array[int] = egcd(posmod(a, m), m)
	if r[0] != 1:
		return -1
	return posmod(r[1], m)


## Chinese remainder theorem for pairwise-coprime moduli.
## Returns {"x": int, "m": int} with x = r_i mod m_i for all i, or {} if the moduli
## share a factor or their product exceeds 2^62.
static func crt(residues: Array[int], moduli: Array[int]) -> Dictionary:
	if residues.size() != moduli.size() or moduli.is_empty():
		return {}
	var x: int = 0
	var m: int = 1
	for i: int in range(moduli.size()):
		var mi: int = moduli[i]
		if mi < 1 or gcd(m, mi) != 1:
			return {}
		@warning_ignore("integer_division")
		var limit: int = MAX_MODULUS / mi
		if m > limit:
			return {}
		# x' = x + m * ((r_i - x) * inv(m, m_i) mod m_i)
		var inv: int = modinv(m % mi, mi) if mi > 1 else 0
		var k: int = mulmod(posmod(residues[i] - x, mi), inv, mi) if mi > 1 else 0
		var new_m: int = m * mi
		x = (x + mulmod(m, k, new_m)) % new_m
		m = new_m
	return {"x": x, "m": m}
