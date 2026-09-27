extends Screen
## Credits and licences.


func _build() -> void:
	var root: MarginContainer = make_safe_root(56)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	root.add_child(col)
	var title: Label = Label.new()
	title.text = tr("UI_CREDITS")
	title.theme_type_variation = "LightTitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var body: Label = Label.new()
	body.text = tr("UI_CREDITS_BODY")
	body.theme_type_variation = "LightLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll.add_child(body)
	var back: Button = Button.new()
	back.text = tr("UI_BACK")
	back.pressed.connect(func() -> void: done.emit({}))
	col.add_child(back)
