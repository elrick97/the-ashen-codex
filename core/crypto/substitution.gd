class_name Substitution
extends RefCounted
## Monoalphabetic substitution.
##
## A key is a 26-letter uppercase String: key[i] is the cipher letter for plain letter i.
## Partial mappings (what the player has on the board) are Dictionaries of
## cipher code (int, 65..90) -> plain code (int, 65..90).

const ALPHABET: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


static func is_valid_key(key: String) -> bool:
	if key.length() != 26:
		return false
	var seen: Dictionary = {}
	for c: int in key.to_ascii_buffer():
		if not TextUtil.is_upper(c) or seen.has(c):
			return false
		seen[c] = true
	return true


## Random key. With `derangement`, no letter maps to itself (so no letter reads as itself).
static func random_key(rng: Pcg32, derangement: bool = true) -> String:
	var letters: Array = []
	for c: int in ALPHABET.to_ascii_buffer():
		letters.append(c)
	while true:
		rng.shuffle(letters)
		var ok: bool = true
		if derangement:
			for i: int in range(26):
				if letters[i] == TextUtil.CODE_A + i:
					ok = false
					break
		if ok:
			break
	var buf: PackedByteArray = PackedByteArray()
	for c: int in letters:
		buf.append(c)
	return buf.get_string_from_ascii()


static func invert_key(key: String) -> String:
	var buf: PackedByteArray = PackedByteArray()
	buf.resize(26)
	var src: PackedByteArray = key.to_ascii_buffer()
	for i: int in range(26):
		buf[src[i] - TextUtil.CODE_A] = TextUtil.CODE_A + i
	return buf.get_string_from_ascii()


static func encrypt(text: String, key: String) -> String:
	return _apply(text, key.to_ascii_buffer())


static func decrypt(text: String, key: String) -> String:
	return _apply(text, invert_key(key).to_ascii_buffer())


## Decrypts with a partial cipher->plain mapping. Unmapped cipher letters become `placeholder`.
static func decrypt_partial(text: String, mapping: Dictionary, placeholder: int = 95) -> String:
	var buf: PackedByteArray = text.to_upper().to_ascii_buffer()
	for i: int in range(buf.size()):
		var c: int = buf[i]
		if TextUtil.is_upper(c):
			buf[i] = int(mapping.get(c, placeholder))
	return buf.get_string_from_ascii()


## The true cipher->plain mapping restricted to letters that occur in `ciphertext`.
static func mapping_for_text(ciphertext: String, key: String) -> Dictionary:
	var inv: PackedByteArray = invert_key(key).to_ascii_buffer()
	var out: Dictionary = {}
	for c: int in ciphertext.to_upper().to_ascii_buffer():
		if TextUtil.is_upper(c):
			out[c] = inv[c - TextUtil.CODE_A]
	return out


## log2(26!), about 88.38 bits.
static func keyspace_bits() -> float:
	var bits: float = 0.0
	for k: int in range(2, 27):
		bits += log(float(k)) / log(2.0)
	return bits


## 26! as an exact decimal string (it does not fit a 64-bit int).
static func keyspace_exact() -> String:
	var digits: PackedInt32Array = PackedInt32Array([1]) # little-endian base 10
	for k: int in range(2, 27):
		var carry: int = 0
		for i: int in range(digits.size()):
			var t: int = digits[i] * k + carry
			digits[i] = t % 10
			carry = _div10(t)
		while carry > 0:
			digits.append(carry % 10)
			carry = _div10(carry)
	var s: String = ""
	for i: int in range(digits.size() - 1, -1, -1):
		s += str(digits[i])
	return s


static func _div10(v: int) -> int:
	@warning_ignore("integer_division")
	var q: int = v / 10
	return q


static func _apply(text: String, table: PackedByteArray) -> String:
	var buf: PackedByteArray = text.to_ascii_buffer()
	for i: int in range(buf.size()):
		var c: int = buf[i]
		if TextUtil.is_upper(c):
			buf[i] = table[c - TextUtil.CODE_A]
		elif TextUtil.is_lower(c):
			buf[i] = table[c - TextUtil.CODE_LOWER_A] + 32
	return buf.get_string_from_ascii()
