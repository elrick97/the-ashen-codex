extends GutTest
## ModMath (Act IV), BlockCipher / CipherModes (Act II), HashToy (Act III), BigInt interface.


func test_gcd_egcd_modinv() -> void:
	assert_eq(ModMath.gcd(240, 46), 2)
	assert_eq(ModMath.gcd(-12, 18), 6)
	assert_eq(ModMath.gcd(0, 5), 5)
	var r: Array[int] = ModMath.egcd(240, 46)
	assert_eq(r[0], 2)
	assert_eq(240 * r[1] + 46 * r[2], 2)
	assert_eq(ModMath.modinv(3, 11), 4)
	assert_eq(ModMath.modinv(-3, 11), 7)
	assert_eq(ModMath.modinv(6, 9), -1)
	var rng: Pcg32 = Pcg32.new(55)
	for _i: int in range(100):
		var m: int = rng.range_int(2, 1000000)
		var a: int = rng.range_int(1, m - 1)
		var inv: int = ModMath.modinv(a, m)
		if ModMath.gcd(a, m) == 1:
			assert_eq((a * inv) % m, 1)
		else:
			assert_eq(inv, -1)


func test_mulmod_large_operands() -> void:
	var m: int = (1 << 61) - 1 # Mersenne prime 2^61 - 1
	assert_eq(ModMath.mulmod(m - 1, m - 1, m), 1) # (-1)^2
	assert_eq(ModMath.mulmod(1 << 40, 1 << 40, m), 1 << 19) # 2^80 = 2^19 * 2^61
	assert_eq(ModMath.mulmod(-2, 3, 7), 1)
	assert_eq(ModMath.mulmod(123456789, 987654321, 1000000007), 259106859)


func test_modpow() -> void:
	assert_eq(ModMath.modpow(4, 13, 497), 445)
	assert_eq(ModMath.modpow(2, 0, 7), 1)
	assert_eq(ModMath.modpow(5, 3, 1), 0)
	var p: int = (1 << 61) - 1
	assert_eq(ModMath.modpow(3, p - 1, p), 1) # Fermat
	# Textbook RSA: p=61, q=53, n=3233, e=17, d=2753
	var c: int = ModMath.modpow(65, 17, 3233)
	assert_eq(c, 2790)
	assert_eq(ModMath.modpow(c, 2753, 3233), 65)
	assert_eq(ModMath.modinv(17, 3120), 2753)


func test_crt() -> void:
	var r: Dictionary = ModMath.crt([2, 3, 2], [3, 5, 7])
	assert_eq(int(r["x"]), 23)
	assert_eq(int(r["m"]), 105)
	assert_eq(ModMath.crt([1, 2], [4, 6]), {})
	assert_eq(ModMath.crt([1, 2], [(1 << 40) + 1, (1 << 31) - 1]), {}) # product > 2^62
	assert_eq(ModMath.crt([1], [1 << 40, 1 << 30]), {}) # size mismatch
	assert_eq(ModMath.crt([], []), {})


func test_spn_vectors_and_round_trip() -> void:
	# Vectors from tests/reference/crypto_ref.py
	assert_eq(BlockCipher.encrypt_block(0x1234, 0xDEADBEEF), 0x5db5)
	assert_eq(BlockCipher.encrypt_block(0x0000, 0x00000000), 0xe0bb)
	var ks: Array[int] = BlockCipher.round_keys(0x12345678)
	assert_eq(ks.size(), 5)
	assert_eq(ks[0], 0x1234)
	assert_eq(ks[1], 0x2345)
	assert_eq(ks[4], 0x5678)
	var rng: Pcg32 = Pcg32.new(66)
	for _i: int in range(200):
		var key: int = rng.next_u32()
		var b: int = rng.next_int(65536)
		assert_eq(BlockCipher.decrypt_block(BlockCipher.encrypt_block(b, key), key), b)


func test_pkcs7() -> void:
	assert_eq(CipherModes.pkcs7_pad(PackedByteArray([1])), PackedByteArray([1, 1]))
	assert_eq(CipherModes.pkcs7_pad(PackedByteArray([1, 2])), PackedByteArray([1, 2, 2, 2]))
	var ok: Dictionary = CipherModes.pkcs7_unpad(PackedByteArray([1, 2, 2, 2]))
	assert_true(ok["ok"])
	assert_eq(ok["data"], PackedByteArray([1, 2]))
	assert_false(CipherModes.pkcs7_unpad(PackedByteArray([1, 3]))["ok"])
	assert_false(CipherModes.pkcs7_unpad(PackedByteArray([5, 1, 2]))["ok"])
	assert_false(CipherModes.pkcs7_unpad(PackedByteArray([2, 0]))["ok"])


func test_ecb_leaks_repeats_cbc_does_not() -> void:
	var msg: PackedByteArray = "ABABABAB".to_ascii_buffer()
	var ecb: PackedByteArray = CipherModes.ecb_encrypt(msg, 0xC0FFEE11)
	assert_eq(ecb.slice(0, 2), ecb.slice(2, 4))
	assert_false(CipherModes.ecb_decrypt(ecb.slice(0, ecb.size() - 1), 0xC0FFEE11)["ok"], "odd length rejected")
	var cbc: PackedByteArray = CipherModes.cbc_encrypt(msg, 0xC0FFEE11, 0x5151)
	assert_false(CipherModes.cbc_decrypt(cbc.slice(0, cbc.size() - 1), 0xC0FFEE11, 0x5151)["ok"], "odd length rejected")
	assert_ne(cbc.slice(0, 2), cbc.slice(2, 4))
	var rng: Pcg32 = Pcg32.new(67)
	for _i: int in range(50):
		var m: PackedByteArray = XorOps.random_pad(rng, rng.range_int(0, 30))
		var key: int = rng.next_u32()
		var iv: int = rng.next_int(65536)
		var d1: Dictionary = CipherModes.ecb_decrypt(CipherModes.ecb_encrypt(m, key), key)
		assert_true(d1["ok"])
		assert_eq(d1["data"], m)
		var d2: Dictionary = CipherModes.cbc_decrypt(CipherModes.cbc_encrypt(m, key, iv), key, iv)
		assert_true(d2["ok"])
		assert_eq(d2["data"], m)


func test_toy_hash() -> void:
	assert_eq(HashToy.digest(PackedByteArray()), 0x2e79)
	assert_eq(HashToy.digest("TITHE".to_ascii_buffer()), 0xb05e)
	assert_eq(HashToy.md_pad(PackedByteArray([0x41])), PackedByteArray([0x41, 0x80, 0x00, 0x08]))
	assert_eq(HashToy.md_pad(PackedByteArray()).size() % 2, 0)
	assert_eq(HashToy.compress(HashToy.IV, HashToy.md_pad(PackedByteArray())), 0x2e79)
	# 16-bit output: a birthday search finds a collision quickly.
	var seen: Dictionary = {}
	var found: bool = false
	for i: int in range(5000):
		var h: int = HashToy.digest(("VEIL%d" % i).to_ascii_buffer())
		if seen.has(h):
			found = true
			break
		seen[h] = i
	assert_true(found)


func test_bigint_interface_only() -> void:
	assert_false(BigInt.is_available())
	assert_eq(BigInt.LIMB_BITS, 24)
