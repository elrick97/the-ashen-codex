extends Screen
## Settings: text size, Clear Mind, haptics, volumes, hint confirmation, reset progress.


var _preview: Label = null


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 1.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var root: MarginContainer = make_safe_root(44)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	root.add_child(col)
	var title: Label = Label.new()
	title.text = tr("UI_SETTINGS")
	title.theme_type_variation = "LightTitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 26)
	scroll.add_child(list)

	_heading(list, "UI_SET_TEXT_SIZE")
	var sizes: HBoxContainer = HBoxContainer.new()
	sizes.add_theme_constant_override("separation", 16)
	list.add_child(sizes)
	var group: ButtonGroup = ButtonGroup.new()
	for i: int in range(3):
		var b: Button = Button.new()
		b.text = tr("UI_SET_SIZE_%d" % i)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = Settings.text_size == i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			Settings.set_value("text_size", i)
			_refresh_preview())
		sizes.add_child(b)
	_preview = Label.new()
	_preview.theme_type_variation = "LightSmallLabel"
	_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(_preview)
	_refresh_preview()

	_toggle(list, "UI_SET_CLEAR_MIND", "UI_SET_CLEAR_MIND_HELP", "clear_mind", Settings.clear_mind)
	_toggle(list, "UI_SET_HAPTICS", "", "haptics", Settings.haptics)
	_toggle(list, "UI_SET_HINT_CONFIRM", "", "hint_confirm", Settings.hint_confirm)
	_slider(list, "UI_SET_VOL_MASTER", "vol_master", Settings.vol_master)
	_slider(list, "UI_SET_VOL_MUSIC", "vol_music", Settings.vol_music)
	_slider(list, "UI_SET_VOL_SFX", "vol_sfx", Settings.vol_sfx)

	var reset: Button = Button.new()
	reset.text = tr("UI_SET_RESET")
	reset.theme_type_variation = "GhostButton"
	reset.add_theme_color_override("font_color", Palette.BLOOD.lightened(0.3))
	reset.pressed.connect(_on_reset)
	list.add_child(reset)

	var close: Button = Button.new()
	close.text = tr("UI_CLOSE")
	close.theme_type_variation = "RubricButton"
	close.pressed.connect(func() -> void: done.emit({}))
	col.add_child(close)


func _heading(parent: Container, key: String) -> void:
	var l: Label = Label.new()
	l.text = tr(key)
	l.theme_type_variation = "LightHeaderLabel"
	parent.add_child(l)


func _toggle(parent: Container, key: String, help_key: String, setting: String, value: bool) -> void:
	var c: CheckButton = CheckButton.new()
	c.text = tr(key)
	c.button_pressed = value
	c.toggled.connect(func(on: bool) -> void:
		EventBus.sfx.emit("ui_tap")
		Settings.set_value(setting, on))
	parent.add_child(c)
	if help_key != "":
		var h: Label = Label.new()
		h.text = tr(help_key)
		h.theme_type_variation = "LightSmallLabel"
		h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		parent.add_child(h)


func _slider(parent: Container, key: String, setting: String, value: float) -> void:
	var l: Label = Label.new()
	l.text = tr(key)
	l.theme_type_variation = "LightLabel"
	parent.add_child(l)
	var s: HSlider = HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 96)
	s.value_changed.connect(func(v: float) -> void: Settings.set_value(setting, v))
	s.drag_ended.connect(func(_changed: bool) -> void: EventBus.sfx.emit("tick"))
	parent.add_child(s)


func _refresh_preview() -> void:
	_preview.text = tr("UI_SET_SIZE_PREVIEW")


func _on_reset() -> void:
	var d1: ConfirmDialog = ConfirmDialog.ask(self, tr("UI_SET_RESET_Q1"), tr("UI_SET_RESET_YES"), tr("UI_CANCEL"))
	d1.answered.connect(func(yes: bool) -> void:
		if not yes:
			return
		var d2: ConfirmDialog = ConfirmDialog.ask(self, tr("UI_SET_RESET_Q2"), tr("UI_SET_RESET_YES2"), tr("UI_CANCEL"))
		d2.answered.connect(func(yes2: bool) -> void:
			if yes2:
				Save.delete_save()
				Thirst.set_value(0.0)
				EventBus.toast.emit(tr("UI_SET_RESET_DONE"))
				if main != null and main.has_method("goto"):
					main.call("goto", "title")))
