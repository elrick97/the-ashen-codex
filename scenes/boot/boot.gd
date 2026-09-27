extends Screen
## M-rated content warning shown on every launch before the title.


func _build() -> void:
	var root: MarginContainer = make_safe_root(72)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 40)
	root.add_child(box)
	var rating: Label = Label.new()
	rating.text = tr("UI_WARNING_RATING")
	rating.theme_type_variation = "LightHeaderLabel"
	rating.add_theme_color_override("font_color", Palette.BLOOD.lightened(0.25))
	rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rating)
	var title: Label = Label.new()
	title.text = tr("UI_WARNING_TITLE")
	title.theme_type_variation = "LightTitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var body: Label = Label.new()
	body.text = tr("UI_WARNING_BODY")
	body.theme_type_variation = "LightLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(body)
	var note: Label = Label.new()
	note.text = tr("UI_WARNING_NOTE")
	note.theme_type_variation = "LightSmallLabel"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0, 120)
	box.add_child(spacer)
	var go: Button = Button.new()
	go.text = tr("UI_WARNING_CONTINUE")
	go.theme_type_variation = "RubricButton"
	go.pressed.connect(func() -> void:
		EventBus.sfx.emit("ui_tap")
		done.emit({}))
	box.add_child(go)
