class_name BytesUtil
extends RefCounted
## Conversions between bytes, hex, base64, bits and ASCII.

const HEX_DIGITS: String = "0123456789abcdef"
const B64: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


static func byte_to_hex(b: int) -> String:
	return HEX_DIGITS[(b >> 4) & 0xF] + HEX_DIGITS[b & 0xF]


static func to_hex(data: PackedByteArray) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for b: int in data:
		parts.append(byte_to_hex(b))
	return "".join(parts)


## Parses hex (either case, whitespace ignored). Returns empty on malformed input.
static func from_hex(hex: String) -> PackedByteArray:
	var clean: String = hex.strip_edges().replace(" ", "").replace("\n", "").to_lower()
	var out: PackedByteArray = PackedByteArray()
	if clean.length() % 2 != 0:
		return out
	for i: int in range(0, clean.length(), 2):
		var hi: int = HEX_DIGITS.find(clean[i])
		var lo: int = HEX_DIGITS.find(clean[i + 1])
		if hi < 0 or lo < 0:
			return PackedByteArray()
		out.append((hi << 4) | lo)
	return out


static func to_base64(data: PackedByteArray) -> String:
	var out: String = ""
	var i: int = 0
	while i < data.size():
		var n: int = mini(3, data.size() - i)
		var chunk: int = data[i] << 16
		if n > 1:
			chunk |= data[i + 1] << 8
		if n > 2:
			chunk |= data[i + 2]
		out += B64[(chunk >> 18) & 63] + B64[(chunk >> 12) & 63]
		out += B64[(chunk >> 6) & 63] if n > 1 else "="
		out += B64[chunk & 63] if n > 2 else "="
		i += 3
	return out


static func from_base64(text: String) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	var acc: int = 0
	var bits: int = 0
	for ch: String in text.strip_edges():
		if ch == "=":
			break
		var v: int = B64.find(ch)
		if v < 0:
			continue
		acc = ((acc << 6) | v) & 0xFFFFFF
		bits += 6
		if bits >= 8:
			bits -= 8
			out.append((acc >> bits) & 0xFF)
	return out


## "01000001" for 65. Most significant bit first.
static func byte_to_bits(b: int) -> String:
	var s: String = ""
	for i: int in range(7, -1, -1):
		s += "1" if (b >> i) & 1 == 1 else "0"
	return s


## Inverse of byte_to_bits(); returns -1 if the string is not 8 binary digits.
static func bits_to_byte(bits: String) -> int:
	if bits.length() != 8:
		return -1
	var v: int = 0
	for ch: String in bits:
		if ch != "0" and ch != "1":
			return -1
		v = (v << 1) | (1 if ch == "1" else 0)
	return v


static func ascii_to_bytes(text: String) -> PackedByteArray:
	return text.to_ascii_buffer()


## ASCII view: printable bytes (32..126) as characters, everything else as `replacement`.
static func to_printable(data: PackedByteArray, replacement: String = ".") -> String:
	var out: PackedByteArray = PackedByteArray()
	var rep: int = replacement.unicode_at(0)
	for b: int in data:
		out.append(b if b >= 32 and b <= 126 else rep)
	return out.get_string_from_ascii()


static func is_printable(b: int) -> bool:
	return (b >= 32 and b <= 126) or b == 10
