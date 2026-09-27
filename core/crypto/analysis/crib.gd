class_name Crib
extends RefCounted
## Known-plaintext helpers: crib placement for substitution, crib-dragging for XOR.


## True if `crib` can sit at `offset` of a substitution ciphertext: non-letters must match
## exactly, and letters must be consistent with a one-to-one cipher<->plain mapping.
static func substitution_fits(ciphertext: String, crib: String, offset: int) -> bool:
	return not substitution_mapping(ciphertext, crib, offset).is_empty()


## The cipher->plain mapping implied by the crib at `offset` (codes 65..90), or {} if it
## doesn't fit.
static func substitution_mapping(ciphertext: String, crib: String, offset: int) -> Dictionary:
	var c: PackedByteArray = ciphertext.to_upper().to_ascii_buffer()
	var p: PackedByteArray = crib.to_upper().to_ascii_buffer()
	if offset < 0 or offset + p.size() > c.size() or p.is_empty():
		return {}
	var fwd: Dictionary = {}
	var back: Dictionary = {}
	for i: int in range(p.size()):
		var cc: int = c[offset + i]
		var pc: int = p[i]
		var c_letter: bool = TextUtil.is_upper(cc)
		if c_letter != TextUtil.is_upper(pc):
			return {}
		if not c_letter:
			if cc != pc:
				return {}
			continue
		if fwd.has(cc) and int(fwd[cc]) != pc:
			return {}
		if back.has(pc) and int(back[pc]) != cc:
			return {}
		fwd[cc] = pc
		back[pc] = cc
	return fwd


## Per-character verdict for the crib at `offset`, read left to right: 1 = consistent so
## far, 0 = contradicts an earlier letter of the crib (or a space/punctuation mismatch),
## -1 = past the end of the ciphertext.
static func substitution_letter_status(ciphertext: String, crib: String, offset: int) -> PackedInt32Array:
	var c: PackedByteArray = ciphertext.to_upper().to_ascii_buffer()
	var p: PackedByteArray = crib.to_upper().to_ascii_buffer()
	var out: PackedInt32Array = PackedInt32Array()
	var fwd: Dictionary = {}
	var back: Dictionary = {}
	for i: int in range(p.size()):
		var j: int = offset + i
		if j < 0 or j >= c.size():
			out.append(-1)
			continue
		var cc: int = c[j]
		var pc: int = p[i]
		var c_letter: bool = TextUtil.is_upper(cc)
		if c_letter != TextUtil.is_upper(pc):
			out.append(0)
			continue
		if not c_letter:
			out.append(1 if cc == pc else 0)
			continue
		if (fwd.has(cc) and int(fwd[cc]) != pc) or (back.has(pc) and int(back[pc]) != cc):
			out.append(0)
			continue
		fwd[cc] = pc
		back[pc] = cc
		out.append(1)
	return out


## Every offset where the crib fits.
static func substitution_positions(ciphertext: String, crib: String) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for o: int in range(ciphertext.length() - crib.length() + 1):
		if substitution_fits(ciphertext, crib, o):
			out.append(o)
	return out


## Crib-dragging: XOR the crib into the stream (C1 xor C2 = P1 xor P2) at `offset`.
## If the crib really is in one message there, the result is the other message's text.
static func drag(stream: PackedByteArray, crib: PackedByteArray, offset: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	for i: int in range(crib.size()):
		var j: int = offset + i
		if j < 0 or j >= stream.size():
			break
		out.append(stream[j] ^ crib[i])
	return out


## True if every byte is in the uppercase-letter-space-punctuation set used by the
## two-time-pad letters (a quick readability filter for dragged fragments).
static func is_plausible_upper(fragment: PackedByteArray) -> bool:
	for b: int in fragment:
		if not (TextUtil.is_upper(b) or UPPER_MARKS.has(b)):
			return false
	return true


## A stricter reading test for a dragged fragment: plausible characters, punctuation
## followed by a space or line break, no doubled spaces, and English-like letters
## (quadgram fitness per gram above -5.2 when there are enough letters to judge).
static func reads_like_english(fragment: PackedByteArray) -> bool:
	if not is_plausible_upper(fragment):
		return false
	var n: int = fragment.size()
	for i: int in range(n):
		var b: int = fragment[i]
		var nxt: int = fragment[i + 1] if i + 1 < n else -1
		if b in [46, 44, 59, 58, 33, 63] and nxt != -1 and nxt != 32 and nxt != 10:
			return false
		if b == 32 and nxt == 32:
			return false
	var letters: PackedInt32Array = TextUtil.letter_indices(fragment.get_string_from_ascii())
	if letters.size() >= 4:
		return EnglishScore.fitness(letters) / float(letters.size() - 3) > -5.2
	return letters.size() > 0


## Space, newline and . , ; : ' ! ? - as byte values.
const UPPER_MARKS: Array[int] = [32, 10, 46, 44, 59, 58, 39, 33, 63, 45]
