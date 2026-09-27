extends Screen
## Title: the Codex on the Marquise's lectern. Primary actions in the bottom 60%.


func _build() -> void:
	var bg: VaultBackdrop = VaultBackdrop.new()
	bg.kind = "title"
	add_child(bg)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var root: MarginContainer = make_safe_root(64)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 26)
	root.add_child(col)
	var top_space: Control = Control.new()
	top_space.custom_minimum_size = Vector2(0, 150)
	col.add_child(top_space)
	var title: Label = Label.new()
	title.text = tr("UI_TITLE_GAME")
	title.theme_type_variation = "LightTitleLabel"
	title.add_theme_font_size_override("font_size", ThemeBuilder.size(150))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(title)
	var rule: ColorRect = ColorRect.new()
	rule.color = Palette.GOLD
	rule.custom_minimum_size = Vector2(0, 4)
	col.add_child(rule)
	var tag: Label = Label.new()
	tag.text = tr("UI_TAGLINE")
	tag.theme_type_variation = "LightSmallLabel"
	tag.add_theme_font_size_override("font_size", ThemeBuilder.size(46))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tag)
	var act: Label = Label.new()
	act.text = tr("UI_TITLE_ACT")
	act.theme_type_variation = "LightLabel"
	act.add_theme_color_override("font_color", Palette.GOLD_LIGHT)
	act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(act)
	var grow: Control = Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(grow)
	var buttons: VBoxContainer = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 22)
	col.add_child(buttons)
	var has_save: bool = Save.has_save()
	if has_save:
		_button(buttons, "UI_CONTINUE", "RubricButton", func() -> void: done.emit({"action": "continue"}))
	_button(buttons, "UI_NEW_GAME", "" if has_save else "RubricButton", _on_new.bind(has_save))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	buttons.add_child(row)
	for spec: Array in [["UI_CODEX", "codex"], ["UI_SETTINGS", "settings"], ["UI_CREDITS", "credits"]]:
		var b: Button = _button(row, spec[0], "GhostButton", func() -> void: done.emit({"action": spec[1]}))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bottom: Control = Control.new()
	bottom.custom_minimum_size = Vector2(0, 40)
	col.add_child(bottom)
	Audio.set_ambience("vault")


func _button(parent: Container, key: String, variation: String, cb: Callable) -> Button:
	var b: Button = Button.new()
	b.text = tr(key)
	b.theme_type_variation = variation
	b.pressed.connect(func() -> void:
		EventBus.sfx.emit("ui_tap")
		cb.call())
	parent.add_child(b)
	return b


func _on_new(has_save: bool) -> void:
	if not has_save:
		done.emit({"action": "new"})
		return
	var d: ConfirmDialog = ConfirmDialog.ask(self, tr("UI_NEW_GAME_CONFIRM"), tr("UI_NEW_GAME_YES"), tr("UI_CANCEL"))
	d.answered.connect(func(yes: bool) -> void:
		if yes:
			done.emit({"action": "new"}))
