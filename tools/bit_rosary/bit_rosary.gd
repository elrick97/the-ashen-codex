class_name BitRosary
extends ToolBase
## Bytes as prayer beads: eight beads per strand, a dark bead is a 1. Tap a bead on an
## editable strand to flip it. The chalice pours two strands together (XOR: a bead is
## dark where exactly one of the two was dark). View toggle: binary, hex, ASCII, decimal.
## Rows are pushed by the mode: [{"label", "value", "editable", "kind"}], where kind is
## "given", "key", "result" or "target".

signal bead_flipped(row: int, bit: int)
signal pour_pressed()

const VIEWS: Array[String] = ["bin", "hex", "ascii", "dec"]

var rows: Array[Dictionary] = []
var view: String = "bin"
var pour_label: String = ""
var _canvas: Control = null
var _pour_btn: Button = null
var _view_btns: Array[Button] = []
var _pour_anim: float = 0.0


func _ready() -> void:
	tool_id = "bit_rosary"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(360, 420)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var views: HBoxContainer = HBoxContainer.new()
	views.add_theme_constant_override("separation", 8)
	box.add_child(views)
	var g: ButtonGroup = ButtonGroup.new()
	for v: String in VIEWS:
		var b: Button = Button.new()
		b.text = tr("UI_ROSARY_VIEW_" + v.to_upper())
		b.toggle_mode = true
		b.button_group = g
		b.button_pressed = v == view
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			snapshot()
			view = v
			state_changed.emit()
			_canvas.queue_redraw())
		views.add_child(b)
		_view_btns.append(b)
	_canvas = Control.new()
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_canvas)
	_canvas.gui_input.connect(_canvas_input)
	box.add_child(_canvas)
	_pour_btn = Button.new()
	_pour_btn.theme_type_variation = "RubricButton"
	_pour_btn.visible = false
	_pour_btn.pressed.connect(func() -> void:
		EventBus.sfx.emit("pour")
		_animate_pour()
		pour_pressed.emit())
	box.add_child(_pour_btn)


func set_rows(r: Array[Dictionary]) -> void:
	rows = r
	_canvas.queue_redraw()


func set_pour(label: String) -> void:
	pour_label = label
	_pour_btn.text = label
	_pour_btn.visible = label != ""


func get_state() -> Dictionary:
	return {"view": view}


func set_state(d: Dictionary) -> void:
	view = str(d.get("view", "bin"))
	for i: int in range(VIEWS.size()):
		_view_btns[i].set_pressed_no_signal(VIEWS[i] == view)
	_canvas.queue_redraw()


func _animate_pour() -> void:
	if Settings.clear_mind:
		return
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void:
		_pour_anim = v
		_canvas.queue_redraw(), 0.0, 1.0, 0.6)
	tw.tween_callback(func() -> void:
		_pour_anim = 0.0
		_canvas.queue_redraw())


func _geom() -> Dictionary:
	var w: float = _canvas.size.x
	var label_w: float = 190.0
	var readout_w: float = 190.0
	var bead_area: float = w - label_w - readout_w
	var pitch: float = bead_area / 8.0
	var row_h: float = minf(170.0, _canvas.size.y / float(maxi(rows.size(), 1)))
	return {"label_w": label_w, "pitch": pitch, "row_h": row_h, "radius": minf(pitch, row_h) * 0.36}


func _bead_center(row: int, bit: int) -> Vector2:
	var g: Dictionary = _geom()
	var col: int = 7 - bit
	return Vector2(float(g["label_w"]) + float(g["pitch"]) * (col + 0.5), float(g["row_h"]) * (row + 0.5))


func _draw_canvas() -> void:
	if _canvas.size.x < 400.0 or _canvas.size.y < 100.0 or rows.is_empty():
		return
	var g: Dictionary = _geom()
	var w: float = _canvas.size.x
	var rh: float = g["row_h"]
	var rad: float = g["radius"]
	var lf: Font = ThemeBuilder.font("semibold")
	var mf: Font = ThemeBuilder.font("mono_bold")
	_canvas.draw_rect(Rect2(0, 0, w, _canvas.size.y), Color(0.1, 0.07, 0.05, 0.9))
	for r: int in range(rows.size()):
		var row: Dictionary = rows[r]
		var value: int = int(row.get("value", 0))
		var kind: String = str(row.get("kind", "given"))
		var y: float = rh * (r + 0.5)
		if kind == "result":
			_canvas.draw_rect(Rect2(0, rh * r + 4, w, rh - 8), Color(Palette.GOLD, 0.12))
		_canvas.draw_string(lf, Vector2(14, y + 12), tr(str(row.get("label", ""))), HORIZONTAL_ALIGNMENT_LEFT, float(g["label_w"]) - 20.0, 32, Palette.ON_DARK)
		# The cord
		_canvas.draw_line(Vector2(float(g["label_w"]), y), Vector2(w - 190.0, y), Color(0.55, 0.45, 0.3), 3.0)
		for bit: int in range(8):
			var c: Vector2 = _bead_center(r, bit)
			if _pour_anim > 0.0 and kind == "result":
				c.y -= (1.0 - _pour_anim) * rh * 0.6
			var on: bool = (value >> bit) & 1 == 1
			_canvas.draw_circle(c + Vector2(3, 4), rad, Color(0, 0, 0, 0.4))
			_canvas.draw_circle(c, rad, Color("2a0c0a") if on else Color("e9dcc0"))
			_canvas.draw_arc(c, rad, 0.0, TAU, 24, Palette.BLOOD if on else Palette.GOLD_TEXT, 4.0 if on else 2.0)
			_canvas.draw_circle(c + Vector2(-rad * 0.35, -rad * 0.35), rad * 0.18, Color(1, 1, 1, 0.25 if on else 0.5))
			if bool(row.get("editable", false)):
				_canvas.draw_arc(c, rad + 8.0, 0.0, TAU, 24, Color(Palette.GOLD_LIGHT, 0.5), 2.0)
			if r == 0:
				var wt: String = str(1 << bit)
				_canvas.draw_string(lf, Vector2(c.x - 40, c.y - rad - 12), wt, HORIZONTAL_ALIGNMENT_CENTER, 80, 22, Palette.ON_DARK_FADED)
		var shown: String = _format(value)
		_canvas.draw_string(mf, Vector2(w - 180.0, y + 14), shown, HORIZONTAL_ALIGNMENT_LEFT, 175.0, 40 if view != "bin" else 26, Palette.GOLD_LIGHT if kind == "result" else Palette.ON_DARK)
		if kind == "target":
			_canvas.draw_rect(Rect2(4, rh * r + 6, w - 8, rh - 12), Palette.GOLD, false, 2.0)


func _format(v: int) -> String:
	match view:
		"hex":
			return "0x" + BytesUtil.byte_to_hex(v)
		"ascii":
			return ("'" + String.chr(v) + "'") if v >= 33 and v <= 126 else ("' '" if v == 32 else "none")
		"dec":
			return str(v)
	return BytesUtil.byte_to_bits(v)


func _canvas_input(event: InputEvent) -> void:
	if not ToolBase.is_press(event):
		return
	var p: Vector2 = ToolBase.press_pos(event)
	var g: Dictionary = _geom()
	for r: int in range(rows.size()):
		if not bool(rows[r].get("editable", false)):
			continue
		for bit: int in range(8):
			if _bead_center(r, bit).distance_to(p) <= float(g["radius"]) + 18.0:
				snapshot()
				EventBus.sfx.emit("bead")
				EventBus.haptic.emit("tick")
				bead_flipped.emit(r, bit)
				state_changed.emit()
				return


func coach_rect() -> Rect2:
	return _canvas.get_global_rect() if _canvas != null else get_global_rect()
