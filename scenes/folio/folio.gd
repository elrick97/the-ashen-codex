extends Screen
## The folio after a solved puzzle: the letter as story (with an illuminated initial),
## the grade seal, Thirst spent, hints bought, and new Codex entries.


func _build() -> void:
	var def: PuzzleDef = ctx.db.puzzle(str(args.get("puzzle_id", "")))
	var rec: Dictionary = args.get("record", {})
	var unlocked: PackedStringArray = args.get("unlocked", PackedStringArray())
	Audio.set_ambience("vault")
	var root: MarginContainer = make_safe_root(28)
	var page: ParchmentPanel = ParchmentPanel.new()
	page.page_seed = float(def.number) * 3.7 if def != null else 1.0
	root.add_child(page)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	page.add_child(col)
	var head: Label = Label.new()
	head.text = tr("UI_FOLIO")
	head.theme_type_variation = "TitleLabel"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(head)
	if def == null:
		return
	var sub: Label = Label.new()
	sub.text = "%s. %s" % [_roman(def.number), tr(def.title_key)]
	sub.theme_type_variation = "HeaderLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var letters: VBoxContainer = VBoxContainer.new()
	letters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	letters.add_theme_constant_override("separation", 28)
	scroll.add_child(letters)
	for i: int in range(def.plaintext_keys.size()):
		if i < def.sender_keys.size():
			var from: Label = Label.new()
			from.text = tr(def.sender_keys[i])
			from.theme_type_variation = "SmallLabel"
			from.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			letters.add_child(from)
		letters.add_child(LetterView.make(tr(def.plaintext_keys[i]), def.number * 10 + i))

	var stats: HBoxContainer = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 24)
	col.add_child(stats)
	var seal: GradeSeal = GradeSeal.new()
	seal.grade = str(rec.get("grade", ""))
	seal.custom_minimum_size = Vector2(150, 150)
	stats.add_child(seal)
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(info)
	var grade: Label = Label.new()
	grade.text = tr("UI_GRADE_" + str(rec.get("grade", "stained")).to_upper())
	grade.theme_type_variation = "RubricLabel"
	grade.add_theme_font_override("font", ThemeBuilder.font("title"))
	grade.add_theme_font_size_override("font_size", ThemeBuilder.size(64))
	info.add_child(grade)
	var line: Label = Label.new()
	line.text = tr("UI_FOLIO_STATS") % [int(rec.get("thirst_spent", 0)), int(rec.get("hints_bought", 0))]
	line.theme_type_variation = "SmallLabel"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(line)
	if bool(rec.get("frenzied", false)):
		var fz: Label = Label.new()
		fz.text = tr("UI_FOLIO_FRENZY")
		fz.theme_type_variation = "SmallLabel"
		fz.add_theme_color_override("font_color", Palette.RUBRIC)
		info.add_child(fz)
	for id: String in unlocked:
		var e: CodexEntryDef = ctx.db.codex.get(id, null) as CodexEntryDef
		if e != null:
			var cl: Label = Label.new()
			cl.text = tr("UI_FOLIO_CODEX") % tr(e.title_key)
			cl.theme_type_variation = "SmallLabel"
			cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(cl)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	var codex_btn: Button = Button.new()
	codex_btn.text = tr("UI_CODEX")
	codex_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_btn.pressed.connect(func() -> void: main.open_overlay("codex", {"entry": unlocked[0] if unlocked.size() > 0 else ""}))
	row.add_child(codex_btn)
	var go: Button = Button.new()
	go.text = tr("UI_CONTINUE")
	go.theme_type_variation = "RubricButton"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(func() -> void:
		EventBus.sfx.emit("page_turn")
		done.emit({}))
	row.add_child(go)
	EventBus.sfx.emit("toll" if str(rec.get("grade", "")) == ThirstConfig.GRADE_SANCTIFIED else "page_turn")


static func _roman(n: int) -> String:
	var vals: Array[int] = [10, 9, 5, 4, 1]
	var syms: Array[String] = ["X", "IX", "V", "IV", "I"]
	var out: String = ""
	var v: int = n
	for i: int in range(vals.size()):
		while v >= vals[i]:
			out += syms[i]
			v -= vals[i]
	return out
