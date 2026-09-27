extends Screen
## Full-screen card, e.g. "To be continued: Act II, The Stained Glass".


func _build() -> void:
	var root: MarginContainer = make_safe_root(80)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 48)
	root.add_child(box)
	var lines: PackedStringArray = tr(str(args.get("text", ""))).split("\n")
	for i: int in range(lines.size()):
		var l: Label = Label.new()
		l.text = lines[i]
		l.theme_type_variation = "LightTitleLabel" if i == 1 else "LightLabel"
		if i == 0:
			l.theme_type_variation = "LightSmallLabel"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
		if i == 1:
			var rule: ColorRect = ColorRect.new()
			rule.color = Palette.GOLD
			rule.custom_minimum_size = Vector2(0, 3)
			box.add_child(rule)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 160)
	box.add_child(spacer)
	var b: Button = Button.new()
	b.text = tr("UI_RETURN_TITLE")
	b.theme_type_variation = "GhostButton"
	b.pressed.connect(func() -> void: done.emit({}))
	box.add_child(b)
	EventBus.sfx.emit("toll")
	Audio.set_ambience("vault")
