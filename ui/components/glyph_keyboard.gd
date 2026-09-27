class_name GlyphKeyboard
extends Control
## An in-world keyboard for writing a custom crib: A-Z, space, a few marks, delete, done.
## Emits `submitted(text)` or `cancelled`, then frees itself.

signal submitted(text: String)
signal cancelled

const ROWS: Array[String] = ["ABCDEFG", "HIJKLMN", "OPQRSTU", "VWXYZ.,"]
const MAX_LEN: int = 24

var text: String = ""
var _preview: Label = null


static func open(parent: Node) -> GlyphKeyboard:
	var k: GlyphKeyboard = GlyphKeyboard.new()
	parent.add_child(k)
	k._build()
	return k


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel: ParchmentPanel = ParchmentPanel.new()
	panel.page_seed = 17.0
	panel.padding = 30
	add_child(panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var head: Label = Label.new()
	head.text = tr("UI_KEYBOARD_TITLE")
	head.theme_type_variation = "HeaderLabel"
	col.add_child(head)
	_preview = Label.new()
	_preview.theme_type_variation = "MonoLabel"
	_preview.add_theme_font_size_override("font_size", ThemeBuilder.size(52))
	_preview.custom_minimum_size = Vector2(0, 90)
	col.add_child(_preview)
	for row: String in ROWS:
		var hb: HBoxContainer = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		col.add_child(hb)
		for ch: String in row:
			var b: Button = Button.new()
			b.text = ch
			b.custom_minimum_size = Vector2(128, 132)
			b.add_theme_font_override("font", ThemeBuilder.font("mono_bold"))
			b.pressed.connect(_type.bind(ch))
			hb.add_child(b)
	var last: HBoxContainer = HBoxContainer.new()
	last.add_theme_constant_override("separation", 6)
	col.add_child(last)
	var space: Button = Button.new()
	space.text = tr("UI_KEYBOARD_SPACE")
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	space.pressed.connect(_type.bind(" "))
	last.add_child(space)
	var del: Button = Button.new()
	del.text = tr("UI_KEYBOARD_DELETE")
	del.pressed.connect(func() -> void:
		text = text.substr(0, maxi(0, text.length() - 1))
		_sync())
	last.add_child(del)
	var ok_row: HBoxContainer = HBoxContainer.new()
	ok_row.add_theme_constant_override("separation", 10)
	col.add_child(ok_row)
	var cancel: Button = Button.new()
	cancel.text = tr("UI_CANCEL")
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free())
	ok_row.add_child(cancel)
	var ok: Button = Button.new()
	ok.text = tr("UI_KEYBOARD_DONE")
	ok.theme_type_variation = "RubricButton"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.pressed.connect(func() -> void:
		if text.strip_edges() != "":
			submitted.emit(text)
		queue_free())
	ok_row.add_child(ok)
	_sync()
	PanelPlace.bottom(panel, self)


func _type(ch: String) -> void:
	if text.length() >= MAX_LEN:
		return
	text += ch
	EventBus.sfx.emit("quill")
	_sync()


func _sync() -> void:
	_preview.text = (text + "_") if text.length() < MAX_LEN else text
