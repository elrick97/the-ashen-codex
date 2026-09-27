class_name TextUtil
extends RefCounted
## Text normalization and letter helpers shared by the letter ciphers.
## All game text is plain ASCII (see the grimdark-voice skill).

const UPPER_KEEP: String = "upper_keep"
const LETTERS_ONLY: String = "letters_only"
const ASCII: String = "ascii"
const UPPER_ASCII: String = "upper_ascii"

const CODE_A: int = 65
const CODE_Z: int = 90
const CODE_LOWER_A: int = 97
const CODE_LOWER_Z: int = 122


static func is_upper(code: int) -> bool:
	return code >= CODE_A and code <= CODE_Z


static func is_lower(code: int) -> bool:
	return code >= CODE_LOWER_A and code <= CODE_LOWER_Z


static func is_letter(code: int) -> bool:
	return is_upper(code) or is_lower(code)


## Applies a PuzzleDef normalization mode.
static func normalize(text: String, mode: String) -> String:
	match mode:
		UPPER_KEEP, UPPER_ASCII:
			return text.to_upper()
		LETTERS_ONLY:
			return letters_only(text)
		ASCII:
			return text
	push_error("TextUtil.normalize: unknown mode " + mode)
	return text


## Uppercase A-Z only; everything else dropped.
static func letters_only(text: String) -> String:
	var src: PackedByteArray = text.to_upper().to_ascii_buffer()
	var out: PackedByteArray = PackedByteArray()
	for c: int in src:
		if is_upper(c):
			out.append(c)
	return out.get_string_from_ascii()


## Splits a letters-only string into space-separated groups.
static func group(letters: String, size: int = 5) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var i: int = 0
	while i < letters.length():
		parts.append(letters.substr(i, size))
		i += size
	return " ".join(parts)


## Letter indices 0..25 for each letter of the text (case-insensitive), skipping non-letters.
static func letter_indices(text: String) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for c: int in text.to_upper().to_ascii_buffer():
		if is_upper(c):
			out.append(c - CODE_A)
	return out


static func indices_to_string(indices: PackedInt32Array) -> String:
	var out: PackedByteArray = PackedByteArray()
	out.resize(indices.size())
	for i: int in range(indices.size()):
		out[i] = CODE_A + indices[i]
	return out.get_string_from_ascii()


static func letter_count(text: String) -> int:
	return letter_indices(text).size()
