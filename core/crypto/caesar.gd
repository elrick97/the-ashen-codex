class_name Caesar
extends RefCounted
## Shift ciphers: Caesar, ROT13 and Atbash. Case is preserved; non-letters pass through.

const KEYSPACE: int = 26


## Shifts one character code by `shift` places (any integer; wraps with posmod).
static func shift_code(code: int, shift: int) -> int:
	if TextUtil.is_upper(code):
		return TextUtil.CODE_A + posmod(code - TextUtil.CODE_A + shift, 26)
	if TextUtil.is_lower(code):
		return TextUtil.CODE_LOWER_A + posmod(code - TextUtil.CODE_LOWER_A + shift, 26)
	return code


static func encrypt(text: String, shift: int) -> String:
	var buf: PackedByteArray = text.to_ascii_buffer()
	for i: int in range(buf.size()):
		buf[i] = shift_code(buf[i], shift)
	return buf.get_string_from_ascii()


static func decrypt(text: String, shift: int) -> String:
	return encrypt(text, -shift)


## ROT13: a shift of 13, so applying it twice returns the original.
static func rot13(text: String) -> String:
	return encrypt(text, 13)


## Atbash: A<->Z, B<->Y, ... Self-inverse and keyless.
static func atbash(text: String) -> String:
	var buf: PackedByteArray = text.to_ascii_buffer()
	for i: int in range(buf.size()):
		var c: int = buf[i]
		if TextUtil.is_upper(c):
			buf[i] = TextUtil.CODE_Z - (c - TextUtil.CODE_A)
		elif TextUtil.is_lower(c):
			buf[i] = TextUtil.CODE_LOWER_Z - (c - TextUtil.CODE_LOWER_A)
	return buf.get_string_from_ascii()


## The encryption shift that maps plain letter index `plain` to cipher letter index `cipher`.
static func shift_between(plain: int, cipher: int) -> int:
	return posmod(cipher - plain, 26)


## Every candidate decryption, index = shift tried (the brute-force attack, 26 keys).
static func all_decryptions(text: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for s: int in range(KEYSPACE):
		out.append(decrypt(text, s))
	return out
