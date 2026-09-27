extends GutTest
## TextUtil, Caesar, Substitution, Vigenere: vectors and round-trip properties.

const SAMPLE: String = "Your servant in eternity, the Steward. Count the heads!"


func test_text_util_predicates() -> void:
	assert_true(TextUtil.is_upper(65))
	assert_false(TextUtil.is_upper(97))
	assert_true(TextUtil.is_lower(122))
	assert_false(TextUtil.is_lower(90))
	assert_true(TextUtil.is_letter(109))
	assert_false(TextUtil.is_letter(32))


func test_text_util_normalize() -> void:
	assert_eq(TextUtil.normalize("Hi, you.", TextUtil.UPPER_KEEP), "HI, YOU.")
	assert_eq(TextUtil.normalize("Hi, you.", TextUtil.LETTERS_ONLY), "HIYOU")
	assert_eq(TextUtil.normalize("Hi, you.", TextUtil.ASCII), "Hi, you.")
	assert_eq(TextUtil.normalize("Hi, you.", TextUtil.UPPER_ASCII), "HI, YOU.")
	assert_eq(TextUtil.letters_only("a-B c!"), "ABC")


func test_text_util_group_and_indices() -> void:
	assert_eq(TextUtil.group("ABCDEFGHIJKL"), "ABCDE FGHIJ KL")
	assert_eq(TextUtil.group("ABCD", 2), "AB CD")
	assert_eq(TextUtil.letter_indices("aZ b"), PackedInt32Array([0, 25, 1]))
	assert_eq(TextUtil.indices_to_string(PackedInt32Array([7, 8])), "HI")
	assert_eq(TextUtil.letter_count("a b, c."), 3)


func test_caesar_textbook_vectors() -> void:
	# Suetonius: Caesar shifted by three.
	assert_eq(Caesar.encrypt("VENI VIDI VICI", 3), "YHQL YLGL YLFL")
	assert_eq(Caesar.encrypt("xyz", 3), "abc")
	assert_eq(Caesar.decrypt("YHQL YLGL YLFL", 3), "VENI VIDI VICI")
	assert_eq(Caesar.encrypt("Abc", -1), "Zab")
	assert_eq(Caesar.shift_code(65, 27), 66)
	assert_eq(Caesar.shift_code(97, -27), 122)
	assert_eq(Caesar.shift_code(33, 5), 33)


func test_rot13_and_atbash_are_self_inverse() -> void:
	assert_eq(Caesar.rot13("Hello"), "Uryyb")
	assert_eq(Caesar.rot13(Caesar.rot13(SAMPLE)), SAMPLE)
	assert_eq(Caesar.atbash("ABC xyz"), "ZYX cba")
	assert_eq(Caesar.atbash("WIZARD"), "DRAZIW")
	assert_eq(Caesar.atbash(Caesar.atbash(SAMPLE)), SAMPLE)


func test_caesar_shift_between_and_brute_force() -> void:
	assert_eq(Caesar.shift_between(4, 7), 3) # E -> H is a shift of 3
	assert_eq(Caesar.shift_between(25, 0), 1)
	var all: PackedStringArray = Caesar.all_decryptions(Caesar.encrypt("TITHE", 11))
	assert_eq(all.size(), Caesar.KEYSPACE)
	assert_eq(all[11], "TITHE")


func test_caesar_round_trip_property() -> void:
	var rng: Pcg32 = Pcg32.new(101)
	for _i: int in range(200):
		var m: String = _random_text(rng, 40)
		var k: int = rng.range_int(-60, 60)
		assert_eq(Caesar.decrypt(Caesar.encrypt(m, k), k), m)


func test_substitution_key_validation() -> void:
	assert_true(Substitution.is_valid_key("QWERTYUIOPASDFGHJKLZXCVBNM"))
	assert_false(Substitution.is_valid_key("QWERTYUIOPASDFGHJKLZXCVBNQ"))
	assert_false(Substitution.is_valid_key("ABC"))
	assert_false(Substitution.is_valid_key("qwertyuiopasdfghjklzxcvbnm"))


func test_substitution_vectors() -> void:
	var key: String = "QWERTYUIOPASDFGHJKLZXCVBNM"
	assert_eq(Substitution.encrypt("Hello World", key), "Itssg Vgksr")
	assert_eq(Substitution.decrypt("Itssg Vgksr", key), "Hello World")
	assert_eq(Substitution.invert_key(key), "KXVMCNOPHQRSZYIJADLEGWBUFT")
	assert_eq(Substitution.invert_key(Substitution.invert_key(key)), key)


func test_substitution_partial_and_mapping() -> void:
	var key: String = "QWERTYUIOPASDFGHJKLZXCVBNM"
	var c: String = Substitution.encrypt("THE TITHE", key)
	var m: Dictionary = Substitution.mapping_for_text(c, key)
	assert_eq(m.size(), 4) # T, H, E, I
	assert_eq(Substitution.decrypt_partial(c, m), "THE TITHE")
	var partial: Dictionary = {90: 84} # Z -> T
	assert_eq(Substitution.decrypt_partial(c, partial), "T__ T_T__")
	assert_eq(Substitution.decrypt_partial(c, partial, 42), "T** T*T**")


func test_substitution_random_key_is_derangement() -> void:
	var rng: Pcg32 = Pcg32.new(7)
	for _i: int in range(50):
		var key: String = Substitution.random_key(rng)
		assert_true(Substitution.is_valid_key(key))
		for i: int in range(26):
			assert_ne(key.unicode_at(i), 65 + i)
	var plain_key: String = Substitution.random_key(Pcg32.new(8), false)
	assert_true(Substitution.is_valid_key(plain_key))


func test_substitution_keyspace() -> void:
	assert_eq(Substitution.keyspace_exact(), "403291461126605635584000000")
	assert_almost_eq(Substitution.keyspace_bits(), 88.38, 0.01)


func test_substitution_round_trip_property() -> void:
	var rng: Pcg32 = Pcg32.new(202)
	for _i: int in range(100):
		var key: String = Substitution.random_key(rng)
		var m: String = _random_text(rng, 60)
		assert_eq(Substitution.decrypt(Substitution.encrypt(m, key), key), m)


func test_vigenere_textbook_vectors() -> void:
	assert_eq(Vigenere.encrypt("ATTACKATDAWN", "LEMON"), "LXFOPVEFRNHR")
	assert_eq(Vigenere.decrypt("LXFOPVEFRNHR", "LEMON"), "ATTACKATDAWN")
	# Spaces and punctuation don't consume key letters.
	assert_eq(Vigenere.encrypt("ATTACK AT DAWN!", "LEMON"), "LXFOPV EF RNHR!")
	assert_eq(Vigenere.encrypt("abc", ""), "abc")


func test_vigenere_shift_helpers() -> void:
	assert_eq(Vigenere.key_to_shifts("LEMON"), PackedInt32Array([11, 4, 12, 14, 13]))
	assert_eq(Vigenere.shifts_to_key(PackedInt32Array([11, 4, -14, 40, 13])), "LEMON")
	var shifts: PackedInt32Array = PackedInt32Array([1, 2])
	assert_eq(Vigenere.encrypt_with_shifts("AAAA", shifts), "BCBC")
	assert_eq(Vigenere.decrypt_with_shifts("BCBC", shifts), "AAAA")


func test_vigenere_columns_interleave() -> void:
	var cols: PackedStringArray = Vigenere.columns("ABCDEFG", 3)
	assert_eq(cols, PackedStringArray(["ADG", "BE", "CF"]))
	assert_eq(Vigenere.interleave(cols), "ABCDEFG")
	# Each column of a Vigenere ciphertext is a plain Caesar shift.
	var c: String = Vigenere.encrypt("THETITHEISTAKENATNEWMOON", "ASH")
	var plain_cols: PackedStringArray = Vigenere.columns("THETITHEISTAKENATNEWMOON", 3)
	var cipher_cols: PackedStringArray = Vigenere.columns(c, 3)
	for j: int in range(3):
		assert_eq(Caesar.decrypt(cipher_cols[j], Vigenere.key_to_shifts("ASH")[j]), plain_cols[j])


func test_vigenere_round_trip_property() -> void:
	var rng: Pcg32 = Pcg32.new(303)
	for _i: int in range(100):
		var klen: int = rng.range_int(1, 12)
		var shifts: PackedInt32Array = PackedInt32Array()
		for _j: int in range(klen):
			shifts.append(rng.next_int(26))
		var key: String = Vigenere.shifts_to_key(shifts)
		var m: String = _random_text(rng, 80)
		assert_eq(Vigenere.decrypt(Vigenere.encrypt(m, key), key), m)


static func _random_text(rng: Pcg32, n: int) -> String:
	var pool: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz .,!'"
	var out: String = ""
	for _i: int in range(n):
		out += pool[rng.next_int(pool.length())]
	return out
