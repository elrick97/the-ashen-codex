extends GutTest
## All player-facing text goes through tr() with keys in content/i18n/strings.csv:
## scripts never assign literal words to .text, every tr("KEY") exists, and every key
## referenced by puzzles, chapters, Codex entries and dialogue exists.

const CODE_DIRS: PackedStringArray = ["res://core", "res://scenes", "res://tools", "res://ui"]


func _scripts(dir: String, out: PackedStringArray) -> void:
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d: String in DirAccess.get_directories_at(dir):
		if d != "dev":
			_scripts(dir.path_join(d), out)


func _has(key: String) -> bool:
	return TranslationServer.translate(key) != key


func test_no_literal_text_in_scripts() -> void:
	var files: PackedStringArray = PackedStringArray()
	for d: String in CODE_DIRS:
		_scripts(d, files)
	var literal: RegEx = RegEx.create_from_string("\\.text\\s*=\\s*\"[A-Za-z]{2,}")
	var bad: PackedStringArray = PackedStringArray()
	for f: String in files:
		var src: String = FileAccess.get_file_as_string(f)
		for m: RegExMatch in literal.search_all(src):
			bad.append("%s: %s" % [f, m.get_string()])
	assert_eq(bad, PackedStringArray(), "literal player-facing text")
	assert_gt(files.size(), 50)


func test_every_tr_key_exists() -> void:
	var files: PackedStringArray = PackedStringArray()
	for d: String in CODE_DIRS:
		_scripts(d, files)
	var re: RegEx = RegEx.create_from_string("\\btr\\(\"([A-Z][A-Z0-9_]+)\"\\)")
	var missing: PackedStringArray = PackedStringArray()
	var count: int = 0
	for f: String in files:
		for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(f)):
			count += 1
			if not _has(m.get_string(1)):
				missing.append(m.get_string(1))
	gut.p("tr() keys checked: %d" % count)
	assert_eq(missing, PackedStringArray())


func test_every_content_key_exists() -> void:
	var db: ContentDB = ContentDB.new()
	db.load_all()
	var missing: PackedStringArray = PackedStringArray()
	var keys: PackedStringArray = PackedStringArray()
	for p: PuzzleDef in db.puzzles.values():
		keys.append_array([p.title_key, p.brief_key])
		keys.append_array(p.plaintext_keys)
		keys.append_array(p.sender_keys)
		keys.append_array(p.hint_keys)
	for c: ChapterDef in db.chapters.values():
		keys.append_array([c.title_key, c.subtitle_key])
	for e: CodexEntryDef in db.codex.values():
		keys.append_array([e.title_key, e.body_key, e.example_key, e.wrong_key, e.aside_key])
		keys.append_array(e.margin_keys)
	for d: Dictionary in db.dialogues.values():
		for n: Variant in d.get("nodes", []):
			keys.append(str((n as Dictionary).get("text", "")))
			for ch: Variant in (n as Dictionary).get("choices", []):
				keys.append(str((ch as Dictionary).get("text", "")))
	for k: String in keys:
		if not _has(k):
			missing.append(k)
	gut.p("content keys checked: %d" % keys.size())
	assert_gt(keys.size(), 400)
	assert_eq(missing, PackedStringArray())
