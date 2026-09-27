class_name Vigenere
extends RefCounted
## Vigenere (Bellaso, 1553): several Caesar shifts used in turn.
## The key advances only on letters, so spaces and punctuation don't consume key.


## Key word -> shift per position (A=0 ... Z=25). Non-letters in the key are ignored.
static func key_to_shifts(key: String) -> PackedInt32Array:
	return TextUtil.letter_indices(key)


static func shifts_to_key(shifts: PackedInt32Array) -> String:
	var norm: PackedInt32Array = PackedInt32Array()
	for s: int in shifts:
		norm.append(posmod(s, 26))
	return TextUtil.indices_to_string(norm)


static func encrypt(text: String, key: String) -> String:
	return encrypt_with_shifts(text, key_to_shifts(key))


static func decrypt(text: String, key: String) -> String:
	return decrypt_with_shifts(text, key_to_shifts(key))


static func encrypt_with_shifts(text: String, shifts: PackedInt32Array) -> String:
	return _apply(text, shifts, 1)


static func decrypt_with_shifts(text: String, shifts: PackedInt32Array) -> String:
	return _apply(text, shifts, -1)


## Splits letters into `period` columns: column j holds letters j, j+period, j+2*period...
static func columns(text: String, period: int) -> PackedStringArray:
	var letters: String = TextUtil.letters_only(text)
	var bufs: Array[PackedByteArray] = []
	for _j: int in range(period):
		bufs.append(PackedByteArray())
	var src: PackedByteArray = letters.to_ascii_buffer()
	for i: int in range(src.size()):
		bufs[i % period].append(src[i])
	var out: PackedStringArray = PackedStringArray()
	for b: PackedByteArray in bufs:
		out.append(b.get_string_from_ascii())
	return out


## Inverse of columns().
static func interleave(cols: PackedStringArray) -> String:
	var out: PackedByteArray = PackedByteArray()
	var bufs: Array[PackedByteArray] = []
	var longest: int = 0
	for c: String in cols:
		bufs.append(c.to_ascii_buffer())
		longest = maxi(longest, c.length())
	for i: int in range(longest):
		for b: PackedByteArray in bufs:
			if i < b.size():
				out.append(b[i])
	return out.get_string_from_ascii()


static func _apply(text: String, shifts: PackedInt32Array, direction: int) -> String:
	if shifts.is_empty():
		return text
	var buf: PackedByteArray = text.to_ascii_buffer()
	var k: int = 0
	for i: int in range(buf.size()):
		var c: int = buf[i]
		if TextUtil.is_letter(c):
			buf[i] = Caesar.shift_code(c, direction * shifts[k % shifts.size()])
			k += 1
	return buf.get_string_from_ascii()
