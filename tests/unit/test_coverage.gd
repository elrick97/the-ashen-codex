extends GutTest
## Proves every public static function in core/crypto is called by at least one unit test.
## Scans the sources, so a new crypto function without a test fails this check.

const CRYPTO_DIRS: PackedStringArray = ["res://core/crypto", "res://core/crypto/analysis"]
const TEST_DIR: String = "res://tests/unit"


func test_every_crypto_function_is_tested() -> void:
	var tests_src: String = ""
	for f: String in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_coverage.gd":
			tests_src += FileAccess.get_file_as_string(TEST_DIR.path_join(f))
	var missing: PackedStringArray = PackedStringArray()
	var total: int = 0
	var re_class: RegEx = RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	var re_func: RegEx = RegEx.create_from_string("(?m)^static func ([a-z]\\w*)\\(")
	for dir: String in CRYPTO_DIRS:
		for f: String in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			var src: String = FileAccess.get_file_as_string(dir.path_join(f))
			var cm: RegExMatch = re_class.search(src)
			assert_not_null(cm, "%s has a class_name" % f)
			if cm == null:
				continue
			var cls: String = cm.get_string(1)
			for m: RegExMatch in re_func.search_all(src):
				total += 1
				var fn: String = m.get_string(1)
				if tests_src.find("%s.%s(" % [cls, fn]) < 0:
					missing.append("%s.%s" % [cls, fn])
	# Pcg32 methods are instance methods; check them by name.
	for fn: String in ["next_u32", "next_int", "range_int", "next_float", "shuffle", "pick", "reseed"]:
		total += 1
		if tests_src.find("." + fn + "(") < 0:
			missing.append("Pcg32." + fn)
	gut.p("crypto functions checked: %d" % total)
	assert_gt(total, 80)
	assert_eq(missing, PackedStringArray(), "untested crypto functions: %s" % ", ".join(missing))
