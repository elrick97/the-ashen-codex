extends GutTest
## BytesUtil, XorOps, Pcg32.

const CRYPTOPALS_S1C5_PLAIN: String = "Burning 'em, if you ain't quick and nimble\nI go crazy when I hear a cymbal"
const CRYPTOPALS_S1C5_HEX: String = "0b3637272a2b2e63622c2e69692a23693a2a3c6324202d623d63343c2a26226324272765272a282b2f20430a652e2c652a3124333a653e2b2027630c692b20283165286326302e27282f"


func test_hex() -> void:
	assert_eq(BytesUtil.byte_to_hex(0), "00")
	assert_eq(BytesUtil.byte_to_hex(0xAF), "af")
	assert_eq(BytesUtil.to_hex(PackedByteArray([1, 255, 16])), "01ff10")
	assert_eq(BytesUtil.from_hex("01FF10"), PackedByteArray([1, 255, 16]))
	assert_eq(BytesUtil.from_hex("0 1f f1 0"), PackedByteArray([1, 255, 16]))
	assert_eq(BytesUtil.from_hex("01\tff\r\n10"), PackedByteArray([1, 255, 16]))
	assert_eq(BytesUtil.from_hex("abc"), PackedByteArray())
	assert_eq(BytesUtil.from_hex("zz"), PackedByteArray())


func test_base64_rfc4648_vectors() -> void:
	var cases: Dictionary = {"": "", "f": "Zg==", "fo": "Zm8=", "foo": "Zm9v", "foob": "Zm9vYg==", "fooba": "Zm9vYmE=", "foobar": "Zm9vYmFy"}
	for plain: String in cases.keys():
		assert_eq(BytesUtil.to_base64(plain.to_ascii_buffer()), cases[plain])
		assert_eq(BytesUtil.from_base64(cases[plain]), plain.to_ascii_buffer())
	var rng: Pcg32 = Pcg32.new(5)
	for _i: int in range(50):
		var data: PackedByteArray = XorOps.random_pad(rng, rng.range_int(0, 40))
		assert_eq(BytesUtil.from_base64(BytesUtil.to_base64(data)), data)
		if not data.is_empty():
			assert_eq(BytesUtil.to_base64(data), Marshalls.raw_to_base64(data))


func test_bits() -> void:
	assert_eq(BytesUtil.byte_to_bits(65), "01000001")
	assert_eq(BytesUtil.byte_to_bits(255), "11111111")
	assert_eq(BytesUtil.bits_to_byte("01000001"), 65)
	assert_eq(BytesUtil.bits_to_byte("0100"), -1)
	assert_eq(BytesUtil.bits_to_byte("0100000x"), -1)
	for b: int in range(256):
		assert_eq(BytesUtil.bits_to_byte(BytesUtil.byte_to_bits(b)), b)


func test_ascii_views() -> void:
	assert_eq(BytesUtil.ascii_to_bytes("Hi"), PackedByteArray([72, 105]))
	assert_eq(BytesUtil.to_printable(PackedByteArray([72, 0, 200, 105])), "H..i")
	assert_eq(BytesUtil.to_printable(PackedByteArray([1]), "#"), "#")
	assert_true(BytesUtil.is_printable(32))
	assert_true(BytesUtil.is_printable(10))
	assert_false(BytesUtil.is_printable(127))


func test_xor_laws() -> void:
	var rng: Pcg32 = Pcg32.new(9)
	for _i: int in range(100):
		var a: int = rng.next_int(256)
		var b: int = rng.next_int(256)
		var c: int = rng.next_int(256)
		assert_eq(a ^ a, 0)
		assert_eq(a ^ 0, a)
		assert_eq(a ^ b, b ^ a)
		assert_eq((a ^ b) ^ c, a ^ (b ^ c))
		assert_eq((a ^ b) ^ b, a)


func test_xor_bytes_and_single() -> void:
	assert_eq(XorOps.xor_bytes(PackedByteArray([1, 2, 3]), PackedByteArray([3, 2])), PackedByteArray([2, 0]))
	assert_eq(XorOps.xor_single(PackedByteArray([0x41, 0x42]), 0x20), PackedByteArray([0x61, 0x62]))
	assert_eq(XorOps.xor_single(PackedByteArray([1]), 0x1FF), PackedByteArray([0xFE]))
	# Cryptopals set 1 challenge 2
	var a: PackedByteArray = BytesUtil.from_hex("1c0111001f010100061a024b53535009181c")
	var b: PackedByteArray = BytesUtil.from_hex("686974207468652062756c6c277320657965")
	assert_eq(BytesUtil.to_hex(XorOps.xor_bytes(a, b)), "746865206b696420646f6e277420706c6179")


func test_repeating_xor_cryptopals_s1c5() -> void:
	var c: PackedByteArray = XorOps.xor_repeating(CRYPTOPALS_S1C5_PLAIN.to_ascii_buffer(), "ICE".to_ascii_buffer())
	assert_eq(BytesUtil.to_hex(c), CRYPTOPALS_S1C5_HEX)
	assert_eq(XorOps.xor_repeating(c, "ICE".to_ascii_buffer()).get_string_from_ascii(), CRYPTOPALS_S1C5_PLAIN)
	assert_eq(XorOps.xor_repeating(PackedByteArray([7]), PackedByteArray()), PackedByteArray([7]))


func test_xor_round_trip_property() -> void:
	var rng: Pcg32 = Pcg32.new(404)
	for _i: int in range(100):
		var m: PackedByteArray = XorOps.random_pad(rng, rng.range_int(1, 64))
		var k: int = rng.next_int(256)
		assert_eq(XorOps.xor_single(XorOps.xor_single(m, k), k), m)
		var key: PackedByteArray = XorOps.random_pad(rng, rng.range_int(1, 12))
		assert_eq(XorOps.xor_repeating(XorOps.xor_repeating(m, key), key), m)


func test_transpose_untranspose() -> void:
	var data: PackedByteArray = PackedByteArray([0, 1, 2, 3, 4, 5, 6])
	var cols: Array[PackedByteArray] = XorOps.transpose(data, 3)
	assert_eq(cols[0], PackedByteArray([0, 3, 6]))
	assert_eq(cols[1], PackedByteArray([1, 4]))
	assert_eq(XorOps.untranspose(cols, 7), data)


func test_random_pad() -> void:
	var p1: PackedByteArray = XorOps.random_pad(Pcg32.new(1), 32)
	var p2: PackedByteArray = XorOps.random_pad(Pcg32.new(1), 32)
	assert_eq(p1.size(), 32)
	assert_eq(p1, p2)
	assert_ne(p1, XorOps.random_pad(Pcg32.new(2), 32))


func test_pcg32_reference_vectors() -> void:
	# pcg32-demo: pcg32_srandom(42, 54)
	var r: Pcg32 = Pcg32.new(42, 54)
	var expected: Array[int] = [0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e]
	for e: int in expected:
		assert_eq(r.next_u32(), e)
	# tests/reference/crypto_ref.py
	var r2: Pcg32 = Pcg32.new(20260927, 7)
	for e: int in [570746491, 715528183, 792798616, 908144169]:
		assert_eq(r2.next_u32(), e)
	r2.reseed(42, 54)
	assert_eq(r2.next_u32(), 0xa15c02b7)


func test_pcg32_bounded() -> void:
	var r: Pcg32 = Pcg32.new(3)
	var seen: Dictionary = {}
	for _i: int in range(2000):
		var v: int = r.next_int(6)
		assert_between(v, 0, 5)
		seen[v] = true
		var w: int = r.range_int(-3, 3)
		assert_between(w, -3, 3)
		var f: float = r.next_float()
		assert_true(f >= 0.0 and f < 1.0)
	assert_eq(seen.size(), 6)


func test_pcg32_shuffle_and_pick() -> void:
	var arr: Array = [1, 2, 3, 4, 5, 6, 7, 8]
	Pcg32.new(11).shuffle(arr)
	var arr2: Array = [1, 2, 3, 4, 5, 6, 7, 8]
	Pcg32.new(11).shuffle(arr2)
	assert_eq(arr, arr2)
	var sorted_copy: Array = arr.duplicate()
	sorted_copy.sort()
	assert_eq(sorted_copy, [1, 2, 3, 4, 5, 6, 7, 8])
	var p: Variant = Pcg32.new(12).pick(["a", "b", "c"])
	assert_true(p in ["a", "b", "c"])
