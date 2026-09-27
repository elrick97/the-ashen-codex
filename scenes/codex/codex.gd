extends Screen
## Isaak's grimoire. Index of every entry (sealed until learned; Acts II-V as placeholders)
## and the entry page: explanation, worked example, a live widget, "How the Court got it
## wrong", the Scribe's Aside (real-world note) and Kett's margin notes. Reading is free.

var _page: ParchmentPanel = null
var _content: VBoxContainer = null
var _scroll: ScrollContainer = null


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 1.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var root: MarginContainer = make_safe_root(24)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	root.add_child(col)
	_page = ParchmentPanel.new()
	_page.page_seed = 33.0
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_page)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 22)
	_scroll.add_child(_content)
	var close: Button = Button.new()
	close.text = tr("UI_CODEX_CLOSE")
	close.theme_type_variation = "RubricButton"
	close.pressed.connect(func() -> void: done.emit({}))
	col.add_child(close)
	var entry: String = str(args.get("entry", ""))
	if entry != "" and ctx.codex.is_unlocked(entry):
		show_entry(entry)
	else:
		show_index()


func _clear() -> void:
	for c: Node in _content.get_children():
		c.queue_free()
	_scroll.scroll_vertical = 0


func show_index() -> void:
	_clear()
	var title: Label = Label.new()
	title.text = tr("UI_CODEX_TITLE")
	title.theme_type_variation = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)
	var intro: Label = Label.new()
	intro.text = tr("UI_CODEX_INTRO")
	intro.theme_type_variation = "SmallLabel"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(intro)
	var last_group: String = ""
	for e: CodexEntryDef in ctx.codex.entries():
		var group: String = ("CH_" + e.chapter_id.to_upper() + "_TITLE") if not e.placeholder else ("CH_A%d_TITLE" % e.act)
		if group != last_group:
			last_group = group
			var gl: Label = Label.new()
			gl.text = tr(group)
			gl.theme_type_variation = "RubricLabel"
			_content.add_child(gl)
		var unlocked: bool = ctx.codex.is_unlocked(e.id)
		var b: Button = Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if e.placeholder:
			b.text = tr(e.title_key) + "  -  " + tr("UI_CODEX_LATER")
			b.disabled = true
		elif unlocked:
			b.text = tr(e.title_key)
			b.pressed.connect(show_entry.bind(e.id))
		else:
			b.text = tr("UI_CODEX_SEALED")
			b.disabled = true
		_content.add_child(b)


func show_entry(id: String) -> void:
	var e: CodexEntryDef = ctx.db.codex.get(id, null) as CodexEntryDef
	if e == null:
		show_index()
		return
	_clear()
	EventBus.sfx.emit("page_turn")
	var back: Button = Button.new()
	back.text = tr("UI_CODEX_INDEX")
	back.theme_type_variation = "GhostButton"
	back.add_theme_color_override("font_color", Palette.RUBRIC)
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(show_index)
	_content.add_child(back)
	var title: Label = Label.new()
	title.text = tr(e.title_key)
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", ThemeBuilder.size(84))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(title)
	_content.add_child(LetterView.make(tr(e.body_key), e.order + 100))
	_section("UI_CODEX_EXAMPLE")
	var ex: Label = Label.new()
	ex.text = tr(e.example_key)
	ex.theme_type_variation = "MonoLabel"
	ex.add_theme_font_size_override("font_size", ThemeBuilder.size(34))
	ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var exbox: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(Palette.VELLUM_SHADOW, 0.35)
	sb.border_color = Palette.GOLD_TEXT
	sb.set_border_width_all(2)
	sb.set_content_margin_all(22)
	exbox.add_theme_stylebox_override("panel", sb)
	exbox.add_child(ex)
	_content.add_child(exbox)
	if e.widget != "":
		var path: String = "res://ui/codex_widgets/%s.gd" % e.widget
		if ResourceLoader.exists(path):
			_section("UI_CODEX_TRY")
			var w: Control = (load(path) as GDScript).new() as Control
			_content.add_child(w)
	_section("UI_CODEX_WRONG")
	_para(tr(e.wrong_key), Palette.INK)
	var aside: PanelContainer = PanelContainer.new()
	var asb: StyleBoxFlat = StyleBoxFlat.new()
	asb.bg_color = Color("1f2a2e")
	asb.set_corner_radius_all(10)
	asb.set_content_margin_all(26)
	aside.add_theme_stylebox_override("panel", asb)
	var av: VBoxContainer = VBoxContainer.new()
	aside.add_child(av)
	var ah: Label = Label.new()
	ah.text = tr("UI_CODEX_ASIDE")
	ah.theme_type_variation = "LightHeaderLabel"
	ah.add_theme_font_size_override("font_size", ThemeBuilder.size(40))
	av.add_child(ah)
	var at: Label = Label.new()
	at.text = tr(e.aside_key)
	at.theme_type_variation = "LightLabel"
	at.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	at.add_theme_font_size_override("font_size", ThemeBuilder.size(38))
	av.add_child(at)
	_content.add_child(aside)
	for mk: String in e.margin_keys:
		var note: Label = Label.new()
		note.text = tr("UI_CODEX_KETT") % tr(mk)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_override("font", ThemeBuilder.font("italic"))
		note.add_theme_color_override("font_color", Palette.RUBRIC)
		note.add_theme_font_size_override("font_size", ThemeBuilder.size(40))
		_content.add_child(note)


func _section(key: String) -> void:
	var l: Label = Label.new()
	l.text = tr(key)
	l.theme_type_variation = "RubricLabel"
	l.add_theme_font_override("font", ThemeBuilder.font("title"))
	l.add_theme_font_size_override("font_size", ThemeBuilder.size(56))
	_content.add_child(l)


func _para(text: String, color: Color) -> void:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", color)
	_content.add_child(l)
