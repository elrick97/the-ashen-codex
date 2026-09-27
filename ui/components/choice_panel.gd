class_name ChoicePanel
extends Control
## A question with several answers on a parchment card. Emits `chosen(index)` or
## `cancelled`, then frees itself.

signal chosen(index: int)
signal cancelled


static func ask(parent: Node, question: String, options: PackedStringArray) -> ChoicePanel:
	var p: ChoicePanel = ChoicePanel.new()
	parent.add_child(p)
	p._build(question, options)
	return p


func _build(question: String, options: PackedStringArray) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel: ParchmentPanel = ParchmentPanel.new()
	panel.page_seed = 8.0
	add_child(panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 22)
	panel.add_child(col)
	var q: Label = Label.new()
	q.text = question
	q.theme_type_variation = "HeaderLabel"
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(q)
	for i: int in range(options.size()):
		var b: Button = Button.new()
		b.text = options[i]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void:
			EventBus.sfx.emit("quill")
			chosen.emit(i)
			queue_free())
		col.add_child(b)
	var back: Button = Button.new()
	back.text = tr("UI_CANCEL")
	back.theme_type_variation = "GhostButton"
	back.add_theme_color_override("font_color", Palette.INK_FADED)
	back.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free())
	col.add_child(back)
	PanelPlace.bottom(panel, self)
