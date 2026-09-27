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
		if not (TextUtil.is_upper(b) or b == 32 or ".,;:'!?-\n".find(String.chr(b)) >= 0):
			return false
	return true
