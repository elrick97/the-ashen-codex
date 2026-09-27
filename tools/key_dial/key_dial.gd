class_name KeyDial
extends ToolBase
## A brass dial of 256 notches (one key byte). Turn it with the thumb (detents, inertia),
## or nudge with the arrows. The "English-ness" gauge beside it is pushed by the mode and
## uses the very scoring function the solvers use (EnglishScore). With several columns,
## chips choose which column's byte the dial sets; each chip shows its own gauge.

signal value_changed(column: int, value: int)
signal column_selected(column: int)

var columns: int = 1
var values: PackedInt32Array = PackedInt32Array([0])
var gauges: PackedFloat32Array = PackedFloat32Array([0.0])
var selected: int = 0

var _dial: Control = null
var _chips: HBoxContainer = null
var _chips_scroll: ScrollContainer = null
var _angle: float = 0.0
var _dragging: bool = false
var _last_ang: float = 0.0
var _vel: float = 0.0
var _last_notch: int = 0


func _ready() -> void:
	tool_id = "key_dial"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(600, 600)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_chips_scroll = ScrollContainer.new()
	_chips_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chips_scroll.custom_minimum_size = Vector2(0, 150)
	box.add_child(_chips_scroll)
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override("separation", 8)
	_chips_scroll.add_child(_chips)
	_dial = Control.new()
	_dial.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dial.mouse_filter = Control.MOUSE_FILTER_STOP
	_dial.draw.connect(_draw_dial)
	_dial.gui_input.connect(_dial_input)
	box.add_child(_dial)
	var nudge: HBoxContainer = HBoxContainer.new()
	nudge.add_theme_constant_override("separation", 12)
	box.add_child(nudge)
	for spec: Array in [["-16", -16], ["-1", -1], ["+1", 1], ["+16", 16]]:
		var b: Button = Button.new()
		b.text = spec[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var step: int = spec[1]
		b.pressed.connect(func() -> void: _nudge(step))
		nudge.add_child(b)
	set_process(false)
	set_columns(1)


func set_columns(n: int) -> void:
	columns = maxi(1, n)
	var old: PackedInt32Array = values
	values = PackedInt32Array()
	gauges = PackedFloat32Array()
	for i: int in range(columns):
		values.append(old[i] if i < old.size() else 0)
		gauges.append(0.0)
	selected = clampi(selected, 0, columns - 1)
	_angle = float(values[selected])
	_last_notch = values[selected]
	_rebuild_chips()
	_dial.queue_redraw()


func set_gauges(g: PackedFloat32Array) -> void:
	gauges = g
	_update_chip_labels()
	_dial.queue_redraw()


func set_value(col: int, v: int) -> void:
	values[col] = v & 0xFF
	if col == selected:
		_angle = float(values[col])
		_last_notch = values[col]
	_update_chip_labels()
	_dial.queue_redraw()


func get_state() -> Dictionary:
	return {"columns": columns, "values": Array(values), "selected": selected}


func set_state(d: Dictionary) -> void:
	set_columns(int(d.get("columns", columns)))
	var v: Array = d.get("values", [])
	for i: int in range(mini(v.size(), columns)):
		values[i] = int(v[i]) & 0xFF
	selected = clampi(int(d.get("selected", 0)), 0, columns - 1)
	_angle = float(values[selected])
	_last_notch = values[selected]
	for i: int in range(columns):
		value_changed.emit(i, values[i])
	column_selected.emit(selected)
	_rebuild_chips()
	_dial.queue_redraw()


func _rebuild_chips() -> void:
	for c: Node in _chips.get_children():
		c.queue_free()
	_chips_scroll.visible = columns > 1
	if columns <= 1:
		return
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(columns):
		var b: Button = Button.new()
		b.toggle_mode = true
		b.button_group = g
		b.button_pressed = i == selected
		b.custom_minimum_size = Vector2(150, 132)
		b.add_theme_font_size_override("font_size", ThemeBuilder.size(30))
		b.pressed.connect(func() -> void:
			selected = i
			_angle = float(values[i])
			_last_notch = values[i]
			EventBus.sfx.emit("tick")
			column_selected.emit(i)
			_dial.queue_redraw())
		_chips.add_child(b)
	_update_chip_labels()


func _update_chip_labels() -> void:
	var i: int = 0
	for c: Node in _chips.get_children():
		var b: Button = c as Button
		if i < columns:
			var pct: int = int(round(100.0 * (gauges[i] if i < gauges.size() else 0.0)))
			b.text = "%d: %s\n%d%%" % [i + 1, BytesUtil.byte_to_hex(values[i]), pct]
		i += 1


func _nudge(step: int) -> void:
	snapshot()
	var v: int = posmod(values[selected] + step, 256)
	values[selected] = v
	_angle = float(v)
	_last_notch = v
	EventBus.sfx.emit("detent")
	EventBus.haptic.emit("tick")
	value_changed.emit(selected, v)
	state_changed.emit()
	_update_chip_labels()
	_dial.queue_redraw()


func _center() -> Vector2:
	return Vector2(_dial.size.x * 0.36, _dial.size.y * 0.5)


func _radius() -> float:
	return minf(_dial.size.x * 0.34, _dial.size.y * 0.47)


func _dial_input(event: InputEvent) -> void:
	if ToolBase.is_press(event):
		var p: Vector2 = ToolBase.press_pos(event)
		if p.distance_to(_center()) > _radius() * 1.1:
			return
		snapshot()
		_dragging = true
		_vel = 0.0
		_last_ang = (p - _center()).angle()
		set_process(true)
	elif ToolBase.is_drag(event) and _dragging:
		var ang: float = (ToolBase.drag_pos(event) - _center()).angle()
		var d: float = wrapf(ang - _last_ang, -PI, PI)
		_last_ang = ang
		# 64 notches per full turn: fine enough to aim, a full byte in four turns.
		var dn: float = d / (TAU / 64.0)
		_angle += dn
		_vel = lerpf(_vel, dn / maxf(get_process_delta_time(), 0.001), 0.35)
		_check()
		_dial.queue_redraw()
	elif ToolBase.is_release(event) and _dragging:
		_dragging = false


func _process(delta: float) -> void:
	if _dragging:
		return
	if absf(_vel) > 1.0:
		_angle += _vel * delta
		_vel *= exp(-5.0 * delta)
		_check()
	else:
		var t: float = round(_angle)
		_angle = lerpf(_angle, t, minf(1.0, delta * 14.0))
		if absf(_angle - t) < 0.01:
			_angle = t
			_check()
			set_process(false)
			state_changed.emit()
	_dial.queue_redraw()


func _check() -> void:
	var n: int = int(round(_angle))
	if n != _last_notch:
		_last_notch = n
		var v: int = posmod(n, 256)
		values[selected] = v
		EventBus.sfx.emit("detent")
		EventBus.haptic.emit("tick")
		value_changed.emit(selected, v)
		_update_chip_labels()


func _draw_dial() -> void:
	var c: Vector2 = _center()
	var r: float = _radius()
	var f: Font = ThemeBuilder.font("mono_bold")
	var sf: Font = ThemeBuilder.font("semibold")
	_dial.draw_circle(c + Vector2(0, 8), r, Color(0, 0, 0, 0.45))
	_dial.draw_circle(c, r, Palette.GOLD)
	_dial.draw_circle(c, r * 0.95, Color("3a2c1e"))
	var rot: float = -_angle * TAU / 64.0
	for i: int in range(64):
		var a: float = rot + TAU * i / 64.0 - PI * 0.5
		var major: bool = i % 4 == 0
		var r1: float = r * (0.78 if major else 0.85)
		_dial.draw_line(c + Vector2(cos(a), sin(a)) * r1, c + Vector2(cos(a), sin(a)) * r * 0.93, Palette.GOLD_LIGHT if major else Color(Palette.GOLD, 0.6), 4.0 if major else 2.0)
	_dial.draw_circle(c, r * 0.55, Color("efe3c8"))
	_dial.draw_arc(c, r * 0.55, 0.0, TAU, 48, Palette.GOLD_TEXT, 3.0)
	var v: int = values[selected]
	var dec: String = str(v)
	var fs: int = int(r * 0.3)
	var w: float = f.get_string_size(dec, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_dial.draw_string(f, c + Vector2(-w * 0.5, fs * 0.1), dec, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.RUBRIC)
	var sub: String = "0x%s  %s" % [BytesUtil.byte_to_hex(v), BytesUtil.byte_to_bits(v)]
	var sfs: int = int(r * 0.075)
	var sw: float = f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs).x
	_dial.draw_string(f, c + Vector2(-sw * 0.5, fs * 0.1 + sfs * 1.8), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sfs, Palette.INK)
	_dial.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -r - 30), c + Vector2(16, -r - 30), c + Vector2(0, -r + 6)]), Palette.RUBRIC)
	# English-ness gauge (vertical)
	var gx: float = _dial.size.x * 0.78
	var gtop: float = c.y - r
	var gh: float = r * 2.0
	var body: Rect2 = Rect2(gx, gtop, 90, gh)
	_dial.draw_rect(body, Color(0.06, 0.04, 0.03))
	var g: float = gauges[selected] if selected < gauges.size() else 0.0
	_dial.draw_rect(Rect2(body.position.x, body.end.y - gh * g, body.size.x, gh * g), Palette.GOLD_LIGHT.lerp(Palette.BLOOD, 1.0 - g))
	_dial.draw_rect(body, Palette.GOLD, false, 3.0)
	for t: float in [0.25, 0.5, 0.75]:
		_dial.draw_line(Vector2(body.position.x, body.end.y - gh * t), Vector2(body.position.x + 20, body.end.y - gh * t), Palette.GOLD_LIGHT, 2.0)
	var pct: String = "%d%%" % int(round(g * 100.0))
	_dial.draw_string(sf, Vector2(gx - 30, body.end.y + 44), pct, HORIZONTAL_ALIGNMENT_CENTER, 150, 40, Palette.ON_DARK)
	_dial.draw_string(ThemeBuilder.font("italic"), Vector2(gx - 60, gtop - 16), tr("UI_DIAL_GAUGE"), HORIZONTAL_ALIGNMENT_CENTER, 210, 28, Palette.ON_DARK_FADED)


func coach_rect() -> Rect2:
	var c: Vector2 = _center()
	var r: float = _radius()
	return Rect2(_dial.global_position + c - Vector2(r, r), Vector2(r, r) * 2.0) if _dial != null else get_global_rect()
