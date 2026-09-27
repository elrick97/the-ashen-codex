extends Screen
## Sub-chapter summary (args.chapter) or the act folio (args.act): grades per puzzle,
## frenzies, and for the act the choices that were made.


func _build() -> void:
	Audio.set_ambience("vault")
	var root: MarginContainer = make_safe_root(28)
	var page: ParchmentPanel = ParchmentPanel.new()
	page.page_seed = 11.0
	root.add_child(page)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	page.add_child(col)
	var chapters: Array[ChapterDef] = []
	var title_text: String = ""
	var sub_text: String = ""
	if args.has("act"):
		chapters = ctx.db.chapters_of_act(int(args["act"]))
		title_text = tr("UI_ACT_FOLIO")
		sub_text = tr("CH_A%d_TITLE" % int(args["act"]))
	else:
		var ch: ChapterDef = ctx.db.chapter(str(args.get("chapter", "")))
		if ch != null:
			chapters.append(ch)
			title_text = tr(ch.title_key)
			sub_text = tr(ch.subtitle_key)
	var title: Label = Label.new()
	title.text = title_text
	title.theme_type_variation = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var sub: Label = Label.new()
	sub.text = sub_text
	sub.theme_type_variation = "SmallLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var counts: Dictionary = {}
	for ch: ChapterDef in chapters:
		if chapters.size() > 1:
			var chl: Label = Label.new()
			chl.text = tr(ch.title_key)
			chl.theme_type_variation = "RubricLabel"
			list.add_child(chl)
		for g: Dictionary in ctx.progression.grades_for(ch):
			var row: HBoxContainer = HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			list.add_child(row)
			var seal: GradeSeal = GradeSeal.new()
			seal.grade = str(g["grade"])
			seal.custom_minimum_size = Vector2(84, 84)
			row.add_child(seal)
			var nm: Label = Label.new()
			nm.text = "%d. %s" % [int(g["number"]), tr(str(g["title_key"]))]
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(nm)
			var gl: Label = Label.new()
			gl.text = tr("UI_GRADE_" + str(g["grade"]).to_upper()) if str(g["grade"]) != "" else "-"
			gl.theme_type_variation = "SmallLabel"
			row.add_child(gl)
			counts[str(g["grade"])] = int(counts.get(str(g["grade"]), 0)) + 1
	var frenzies: int = int(ctx.progression.flag("frenzy_count", 0))
	var tally: Label = Label.new()
	tally.text = tr("UI_SUMMARY_TALLY") % [int(counts.get(ThirstConfig.GRADE_SANCTIFIED, 0)), int(counts.get(ThirstConfig.GRADE_STAINED, 0)), int(counts.get(ThirstConfig.GRADE_DAMNED, 0)), frenzies, int(round(Thirst.value))]
	tally.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tally.theme_type_variation = "SmallLabel"
	col.add_child(tally)
	if args.has("act"):
		var choices: PackedStringArray = PackedStringArray()
		for flag: String in ["courier_drained", "courier_spared", "drank_wenna", "refused_wenna", "act1_warned", "act1_silent"]:
			if bool(ctx.progression.flag(flag, false)):
				choices.append(tr("UI_CHOICE_" + flag.to_upper()))
		if not choices.is_empty():
			var cl: Label = Label.new()
			cl.text = tr("UI_SUMMARY_CHOICES") + "\n" + "\n".join(choices)
			cl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(cl)
	var go: Button = Button.new()
	go.text = tr("UI_CONTINUE")
	go.theme_type_variation = "RubricButton"
	go.pressed.connect(func() -> void:
		EventBus.sfx.emit("page_turn")
		done.emit({}))
	col.add_child(go)
