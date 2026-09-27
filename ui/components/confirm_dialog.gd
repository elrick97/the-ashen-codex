class_name ConfirmDialog
extends Control
## Modal question on a dimmed backdrop. Emits `answered(true/false)` and frees itself.

signal answered(yes: bool)


static func ask(parent: Node, message: String, yes_text: String, no_text: String) -> ConfirmDialog:
	var d: ConfirmDialog = ConfirmDialog.new()
	parent.add_child(d)
	d._build(message, yes_text, no_text)
	return d


func _build(message: String, yes_text: String, no_text: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel: ParchmentPanel = ParchmentPanel.new()
	panel.page_seed = 4.0
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 32)
	panel.add_child(box)
	var msg: Label = Label.new()
	msg.text = message
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.custom_minimum_size = Vector2(760, 0)
	box.add_child(msg)
	var yes: Button = Button.new()
	yes.text = yes_text
	yes.theme_type_variation = "RubricButton"
	yes.pressed.connect(_answer.bind(true))
	box.add_child(yes)
	var no: Button = Button.new()
	no.text = no_text
	no.pressed.connect(_answer.bind(false))
	box.add_child(no)
	PanelPlace.bottom(panel, self, 900.0, 0.62)


func _answer(yes: bool) -> void:
	EventBus.sfx.emit("ui_tap")
	answered.emit(yes)
	queue_free()
