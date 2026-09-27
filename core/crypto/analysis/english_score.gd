class_name EnglishScore
extends RefCounted
## How English-like a byte string or letter sequence is.
##
## score_bytes(): mean log-weight per byte under a simple English character model
## (letters by Frequency.ENGLISH, space, punctuation, digits; the weights are not
## normalized to sum to 1, so it is a score, not a true log-probability). The Key Dial's
## "English-ness" gauge shows gauge() of the same function, so the tool and the solvers
## rank candidates identically.
##
## fitness(): quadgram log-probability of letters-only text, from
## core/crypto/data/english_ngrams.json (built by tools_dev/build_ngrams.py).

const NGRAM_PATH: String = "res://core/crypto/data/english_ngrams.json"
const SPACE_P: float = 0.17
const LETTER_SHARE: float = 0.76
const PUNCT: String = ".,;:'!?-\""
const PUNCT_P: float = 0.03
const DIGIT_P: float = 0.004
const NEWLINE_P: float = 0.01
const OTHER_PRINTABLE_P: float = 0.0004
const NON_PRINTABLE_P: float = 0.000001
## Gauge calibration: typical scores for English prose and for random bytes.
const GAUGE_ENGLISH: float = -2.9
const GAUGE_RANDOM: float = -9.5

static var _byte_logp: PackedFloat64Array = PackedFloat64Array()
static var _quad: PackedFloat32Array = PackedFloat32Array()
static var _tri: PackedFloat32Array = PackedFloat32Array()
static var _loaded: bool = false


## Mean log-weight per byte. Higher is more English-like.
static func score_bytes(data: PackedByteArray) -> float:
	if data.is_empty():
		return GAUGE_RANDOM
	var table: PackedFloat64Array = _byte_table()
	var s: float = 0.0
	for b: int in data:
		s += table[b]
	return s / float(data.size())


static func score_text(text: String) -> float:
	return score_bytes(text.to_ascii_buffer())


## score_bytes() mapped to 0..1 for the gauge.
static func gauge(data: PackedByteArray) -> float:
	return clampf((score_bytes(data) - GAUGE_RANDOM) / (GAUGE_ENGLISH - GAUGE_RANDOM), 0.0, 1.0)


## Single-byte XOR key whose decryption scores best. Returns {"key", "score"}.
## Used by solvers and tests; the game never auto-solves for the player.
static func best_single_byte_key(data: PackedByteArray) -> Dictionary:
	var best_key: int = 0
	var best: float = -INF
	for k: int in range(256):
		var s: float = score_bytes(XorOps.xor_single(data, k))
		if s > best:
			best = s
			best_key = k
	return {"key": best_key, "score": best}


## Quadgram fitness of letter indices (0..25). Higher is more English-like.
static func fitness(indices: PackedInt32Array) -> float:
	_ensure_ngrams()
	var s: float = 0.0
	for i: int in range(indices.size() - 3):
		s += _quad[((indices[i] * 26 + indices[i + 1]) * 26 + indices[i + 2]) * 26 + indices[i + 3]]
	return s


## Trigram log-probability of one trigram (letter indices).
static func trigram_logp(a: int, b: int, c: int) -> float:
	_ensure_ngrams()
	return _tri[(a * 26 + b) * 26 + c]


## Flat quadgram table (index ((a*26+b)*26+c)*26+d), for solvers that score incrementally.
static func quadgram_table() -> PackedFloat32Array:
	_ensure_ngrams()
	return _quad


static func _byte_table() -> PackedFloat64Array:
	if _byte_logp.size() == 256:
		return _byte_logp
	var t: PackedFloat64Array = PackedFloat64Array()
	t.resize(256)
	for b: int in range(256):
		var p: float = NON_PRINTABLE_P
		if TextUtil.is_upper(b):
			p = LETTER_SHARE * Frequency.ENGLISH[b - TextUtil.CODE_A]
		elif TextUtil.is_lower(b):
			p = LETTER_SHARE * Frequency.ENGLISH[b - TextUtil.CODE_LOWER_A]
		elif b == 32:
			p = SPACE_P
		elif b == 10:
			p = NEWLINE_P
		elif b > 0 and PUNCT.find(String.chr(b)) >= 0:
			p = PUNCT_P / float(PUNCT.length())
		elif b >= 48 and b <= 57:
			p = DIGIT_P / 10.0
		elif b >= 32 and b <= 126:
			p = OTHER_PRINTABLE_P
		t[b] = log(p)
	_byte_logp = t
	return _byte_logp


static func _ensure_ngrams() -> void:
	if _loaded:
		return
	_loaded = true
	var f: FileAccess = FileAccess.open(NGRAM_PATH, FileAccess.READ)
	if f == null:
		push_error("EnglishScore: cannot open " + NGRAM_PATH)
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not data is Dictionary:
		push_error("EnglishScore: bad n-gram file")
		return
	var d: Dictionary = data
	var tri: Array = d["tri"]
	_tri = PackedFloat32Array(tri)
	_quad = PackedFloat32Array()
	_quad.resize(456976)
	_quad.fill(float(d["quad_floor"]))
	var quad: Dictionary = d["quad"]
	for g: String in quad.keys():
		var b: PackedByteArray = g.to_ascii_buffer()
		var idx: int = (((b[0] - 65) * 26 + (b[1] - 65)) * 26 + (b[2] - 65)) * 26 + (b[3] - 65)
		_quad[idx] = float(quad[g])
