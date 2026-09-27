extends GutTest
## Frequency, Kasiski, IndexOfCoincidence, Hamming, EnglishScore, Crib.


func test_frequency_counts_and_total() -> void:
	var c: PackedInt32Array = Frequency.counts("Aab, z!")
	assert_eq(c[0], 2)
	assert_eq(c[1], 1)
	assert_eq(c[25], 1)
	assert_eq(Frequency.total(c), 4)


func test_frequency_proportions() -> void:
	var p: PackedFloat64Array = Frequency.proportions("AAB")
	assert_almost_eq(p[0], 2.0 / 3.0, 1e-9)
	assert_almost_eq(p[1], 1.0 / 3.0, 1e-9)
	assert_eq(Frequency.proportions("123")[0], 0.0)
	var sum: float = 0.0
	for v: float in Frequency.ENGLISH:
		sum += v
	assert_almost_eq(sum, 1.0, 0.002)


func test_frequency_ranked_and_peak() -> void:
	var r: PackedInt32Array = Frequency.ranked("BBBAAC")
	assert_eq(r[0], 1)
	assert_eq(r[1], 0)
	assert_eq(r[2], 2)
	assert_eq(r[3], 3) # ties alphabetical
	assert_eq(Frequency.peak(EnglishSample.TEXT), Frequency.INDEX_E)


func test_frequency_chi_squared() -> void:
	var english: float = Frequency.chi_squared(Frequency.counts(EnglishSample.TEXT))
	var shifted: float = Frequency.chi_squared(Frequency.counts(Caesar.encrypt(EnglishSample.TEXT, 7)))
	assert_lt(english, shifted)
	assert_eq(Frequency.chi_squared(PackedInt32Array([0, 0])), INF)


func test_frequency_caesar_attacks() -> void:
	for s: int in [1, 5, 13, 22]:
		var c: String = Caesar.encrypt(EnglishSample.TEXT, s)
		assert_eq(Frequency.shift_from_peak(c), s)
		assert_eq(Frequency.shift_by_chi_squared(c), s)


func test_profile_match() -> void:
	var c: PackedInt32Array = Frequency.counts(Caesar.encrypt(EnglishSample.TEXT, 11))
	var right: float = Frequency.profile_match(c, 11)
	assert_gt(right, 0.9, "shapes agree at the true shift")
	for s: int in [0, 3, 10, 12, 20]:
		assert_lt(Frequency.profile_match(c, s), right - 0.2, "wrong shift %d scores clearly lower" % s)
	assert_eq(Frequency.profile_match(PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), 0), 0.0)


func test_ngrams() -> void:
	var bi: Dictionary = Frequency.ngram_counts("THE THEN", 2, true)
	assert_eq(int(bi["TH"]), 2)
	assert_eq(int(bi["HE"]), 2)
	assert_false(bi.has("ET")) # does not cross the space
	var bi2: Dictionary = Frequency.ngram_counts("THE THEN", 2, false)
	assert_eq(int(bi2["ET"]), 1)
	var top: Array[Dictionary] = Frequency.top_ngrams(EnglishSample.TEXT, 3, 3, true)
	assert_eq(top[0]["gram"], "THE")
	assert_eq(top.size(), 3)
	var top_bi: Array[Dictionary] = Frequency.top_ngrams(EnglishSample.TEXT, 2, 5)
	var grams: Array = []
	for t: Dictionary in top_bi:
		grams.append(t["gram"])
	assert_true("TH" in grams and "HE" in grams)


func test_kasiski_repeats_and_spacings() -> void:
	var reps: Array[Dictionary] = Kasiski.find_repeats("ABCXYZABCQQABC", 3, 5)
	assert_eq(reps.size(), 1)
	assert_eq(reps[0]["seq"], "ABC")
	assert_eq(reps[0]["positions"], PackedInt32Array([0, 6, 11]))
	assert_eq(Kasiski.spacings(PackedInt32Array([0, 6, 11])), PackedInt32Array([6, 11, 5]))
	# A longer repeat hides its own sub-repeats.
	var r2: Array[Dictionary] = Kasiski.find_repeats("ABCDQQABCD", 3, 5)
	assert_eq(r2.size(), 1)
	assert_eq(r2[0]["seq"], "ABCD")


func test_kasiski_factors() -> void:
	assert_eq(Kasiski.factors(12), PackedInt32Array([2, 3, 4, 6, 12]))
	assert_eq(Kasiski.factors(12, 2, 5), PackedInt32Array([2, 3, 4]))
	var tally: PackedInt32Array = Kasiski.factor_tally(PackedInt32Array([10, 15, 20]), 2, 10)
	assert_eq(tally[5], 3)
	assert_eq(tally[2], 2)
	assert_eq(tally[10], 2)


func test_kasiski_finds_vigenere_period() -> void:
	var c: String = Vigenere.encrypt(EnglishSample.TEXT, "MORROW")
	var sp: PackedInt32Array = Kasiski.all_spacings(c)
	assert_gt(sp.size(), 5)
	var p: int = Kasiski.likely_period(c, 2, 20)
	assert_eq(p % 6, 0, "period %d should be a multiple of 6" % p)
	assert_eq(Kasiski.likely_period("ABCDEFG"), 0)


func test_ioc_values() -> void:
	var e: float = IndexOfCoincidence.ic(EnglishSample.TEXT)
	assert_between(e, 0.058, 0.075)
	assert_almost_eq(IndexOfCoincidence.from_counts(PackedInt32Array([2, 0])), 1.0, 1e-9)
	assert_eq(IndexOfCoincidence.from_counts(PackedInt32Array([1])), 0.0)
	assert_almost_eq(IndexOfCoincidence.normalized(IndexOfCoincidence.RANDOM_IC), 1.0, 1e-9)
	assert_almost_eq(IndexOfCoincidence.normalized(0.0667), 1.734, 0.001)
	# A Caesar shift doesn't change IC; Vigenere flattens it.
	assert_almost_eq(IndexOfCoincidence.ic(Caesar.encrypt(EnglishSample.TEXT, 9)), e, 1e-9)
	assert_lt(IndexOfCoincidence.ic(Vigenere.encrypt(EnglishSample.TEXT, "LANTERN")), 0.05)


func test_ioc_period_detection() -> void:
	var c: String = Vigenere.encrypt(EnglishSample.TEXT, "ASHEN")
	var by: PackedFloat64Array = IndexOfCoincidence.by_period(c, 12)
	assert_eq(by.size(), 13)
	assert_gt(by[5], 0.058)
	assert_lt(by[3], 0.05)
	assert_almost_eq(IndexOfCoincidence.average_column_ic(c, 5), by[5], 1e-9)
	assert_eq(IndexOfCoincidence.average_column_ic(c, 0), 0.0)
	assert_eq(IndexOfCoincidence.likely_period(c, 12), 5)


func test_hamming_reference() -> void:
	assert_eq(Hamming.distance_str("this is a test", "wokka wokka!!!"), 37)
	assert_eq(Hamming.distance(PackedByteArray([0xFF]), PackedByteArray([0x00])), 8)
	assert_eq(Hamming.popcount(0b1011), 3)
	assert_eq(Hamming.popcount(0x1FF), 8) # only the low byte counts


func test_hamming_keysize() -> void:
	var data: PackedByteArray = XorOps.xor_repeating(EnglishSample.TEXT.to_ascii_buffer(), "NOX AETERNA".to_ascii_buffer())
	var k: int = Hamming.likely_keysize(data, 2, 40)
	assert_eq(k % 11, 0, "keysize %d should be a multiple of 11" % k)
	var scores: PackedFloat64Array = Hamming.keysize_scores(data, 2, 40)
	assert_eq(scores.size(), 41)
	assert_eq(scores[1], INF)
	assert_lt(scores[11], scores[7])
	assert_eq(Hamming.normalized_distance(PackedByteArray([1, 2, 3]), 2), INF)
	assert_almost_eq(Hamming.normalized_distance(PackedByteArray([0, 255]), 1), 8.0, 1e-9)


func test_english_score() -> void:
	var english: float = EnglishScore.score_text(EnglishSample.TEXT)
	var noise: float = EnglishScore.score_bytes(XorOps.random_pad(Pcg32.new(1), 300))
	assert_gt(english, noise)
	assert_gt(EnglishScore.gauge(EnglishSample.TEXT.to_ascii_buffer()), 0.9)
	assert_lt(EnglishScore.gauge(XorOps.random_pad(Pcg32.new(1), 300)), 0.2)
	assert_eq(EnglishScore.score_bytes(PackedByteArray()), EnglishScore.GAUGE_RANDOM)


func test_english_score_breaks_single_byte_xor() -> void:
	# Cryptopals set 1 challenge 3
	var c: PackedByteArray = BytesUtil.from_hex("1b37373331363f78151b7f2b783431333d78397828372d363c78373e783a393b3736")
	var best: Dictionary = EnglishScore.best_single_byte_key(c)
	assert_eq(int(best["key"]), 88)
	assert_eq(XorOps.xor_single(c, 88).get_string_from_ascii(), "Cooking MC's like a pound of bacon")
	for k: int in [7, 0x5A, 200]:
		var ck: PackedByteArray = XorOps.xor_single(EnglishSample.TEXT.to_ascii_buffer(), k)
		assert_eq(int(EnglishScore.best_single_byte_key(ck)["key"]), k)


func test_ngram_fitness() -> void:
	var english: PackedInt32Array = TextUtil.letter_indices(EnglishSample.TEXT)
	var scrambled: PackedInt32Array = TextUtil.letter_indices(Substitution.encrypt(EnglishSample.TEXT, "QWERTYUIOPASDFGHJKLZXCVBNM"))
	assert_gt(EnglishScore.fitness(english), EnglishScore.fitness(scrambled))
	assert_gt(EnglishScore.trigram_logp(19, 7, 4), EnglishScore.trigram_logp(16, 16, 16)) # THE > QQQ
	assert_eq(EnglishScore.quadgram_table().size(), 456976)


func test_crib_substitution() -> void:
	var key: String = "QWERTYUIOPASDFGHJKLZXCVBNM"
	var c: String = Substitution.encrypt("WE REMAIN, YOUR SERVANT IN ETERNITY", key)
	var crib: String = "YOUR SERVANT IN ETERNITY"
	var pos: PackedInt32Array = Crib.substitution_positions(c, crib)
	assert_eq(pos, PackedInt32Array([11]))
	assert_true(Crib.substitution_fits(c, crib, 11))
	assert_false(Crib.substitution_fits(c, crib, 0))
	assert_false(Crib.substitution_fits(c, crib, 30))
	var m: Dictionary = Crib.substitution_mapping(c, crib, 11)
	assert_eq(int(m[key.unicode_at(4)]), 69) # cipher for E maps back to E
	assert_eq(Crib.substitution_mapping(c, "", 0), {})
	var st: PackedInt32Array = Crib.substitution_letter_status(c, crib, 11)
	assert_eq(st.size(), crib.length())
	assert_false(st.has(0), "every letter consistent at the true offset")
	var bad: PackedInt32Array = Crib.substitution_letter_status("XY Z", "AA B", 0)
	assert_eq(bad, PackedInt32Array([1, 0, 1, 1]))
	assert_eq(Crib.substitution_letter_status("AB", "ABC", 0)[2], -1)
	assert_eq(Crib.substitution_letter_status("A.", "AB", 0)[1], 0, "letter vs punctuation")
	# Pattern conflict: "AA" can't sit on two different cipher letters.
	assert_false(Crib.substitution_fits("XY", "AA", 0))
	assert_false(Crib.substitution_fits("XX", "AB", 0))


func test_crib_drag_two_time_pad() -> void:
	var pad: PackedByteArray = XorOps.random_pad(Pcg32.new(77), 40)
	var p1: PackedByteArray = "THE TITHE IS TAKEN AT THE SALT BARN".to_ascii_buffer()
	var p2: PackedByteArray = "OUR FRIEND IN THE QUILL SENDS KEYS".to_ascii_buffer()
	var stream: PackedByteArray = XorOps.xor_bytes(XorOps.xor_bytes(p1, pad), XorOps.xor_bytes(p2, pad))
	assert_eq(stream, XorOps.xor_bytes(p1, p2)) # the pad cancels
	var frag: PackedByteArray = Crib.drag(stream, "THE TITHE".to_ascii_buffer(), 0)
	assert_eq(frag.get_string_from_ascii(), "OUR FRIEN")
	assert_true(Crib.is_plausible_upper(frag))
	assert_false(Crib.is_plausible_upper(Crib.drag(stream, "THE TITHE".to_ascii_buffer(), 3)))
	assert_eq(Crib.drag(stream, "ABC".to_ascii_buffer(), stream.size() - 1).size(), 1)
	assert_true(Crib.reads_like_english("OUR FRIEN".to_ascii_buffer()))
	assert_false(Crib.reads_like_english("XQZJ VKPW".to_ascii_buffer()), "letters but not English")
	assert_false(Crib.reads_like_english("THE.MOON".to_ascii_buffer()), "full stop glued to a word")
	assert_false(Crib.reads_like_english("THE  MOON".to_ascii_buffer()), "double space")
	assert_false(Crib.reads_like_english(PackedByteArray([0, 65, 66])), "unprintable")
