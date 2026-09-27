class_name LetterView
extends VBoxContainer
## A decrypted letter set as a manuscript page: an illuminated initial beside the
## opening line, the rest in body type. Paragraphs split on blank lines / newlines.


static func make(text: String, seed_value: int) -> LetterView:
	var v: LetterView = LetterView.new()
	v._fill(text, seed_value)
	return v


func _fill(text: String, seed_value: int) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	var paras: PackedStringArray = text.strip_edges().split("\n", false)
	if paras.is_empty():
		return
	var first: String = paras[0].strip_edges()
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	var cap: DropCap = DropCap.new()
	cap.letter = first.substr(0, 1).to_upper()
	cap.seed_value = seed_value
	cap.custom_minimum_size = Vector2(150, 150)
	row.add_child(cap)
	var rest: Label = Label.new()
	rest.text = first.substr(1)
	rest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rest.add_theme_font_override("font", ThemeBuilder.font("fell"))
	rest.add_theme_font_size_override("font_size", ThemeBuilder.size(48))
	row.add_child(rest)
	for i: int in range(1, paras.size()):
		var p: Label = Label.new()
		p.text = paras[i].strip_edges()
		p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.add_theme_font_override("font", ThemeBuilder.font("fell"))
		p.add_theme_font_size_override("font_size", ThemeBuilder.size(46))
		if i == paras.size() - 1 and paras.size() > 2:
			p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			p.add_theme_color_override("font_color", Palette.RUBRIC)
		add_child(p)
