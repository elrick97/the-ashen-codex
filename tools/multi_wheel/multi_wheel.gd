class_name MultiWheel
extends ToolBase
## N stacked cipher wheels seen edge-on, like a cryptex: one drum per key column, each
## showing its key letter in the window (A = shift 0). Drag a drum up or down to turn it
## notch by notch (detents, ticks, inertia unless rusted). Drum colours match the strand
## colours on the letter card. Optional period stepper when the key length is unknown.

signal shifts_changed(shifts: PackedInt32Array)
signal drum_notch(drum: int)
signal drum_selected(drum: int)
signal period_changed(period: int)

const MAX_DRUMS: int = 12
const NOTCH_PX: float = 64.0

var period: int = 5
var shifts: PackedInt32Array = PackedInt32Array()
var selected: int = 0
var period_editable: bool = false
var period_max: int = 12
var rusted: bool = false

var _pos: PackedFloat32Array = PackedFloat32Array() # continuous notch position per drum
var _vel: PackedFloat32Array = PackedFloat32Array()
var _drag_drum: int = -1
var _drag_y: float = 0.0
var _drag_start: float = 0.0
var _last_notch: PackedInt32Array = PackedInt32Array()
var _stepper: HBoxContainer = null
var _period_label: Label = null
var _drums: Control = null


func _ready() -> void:
	tool_id = "multi_wheel"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(360, 420)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_stepper = HBoxContainer.new()
	_stepper.alignment = BoxContainer.ALIGNMENT_CENTER
	_stepper.add_theme_constant_override("separation", 16)
	box.add_child(_stepper)
	var minus: Button = Button.new()
	minus.text = "-"
	minus.custom_minimum_size = Vector2(144, 132)
	minus.pressed.connect(func() -> void: _set_period_player(period - 1))
	_stepper.add_child(minus)
	_period_label = Label.new()
	_period_label.theme_type_variation = "LightLabel"
	_period_label.custom_minimum_size = Vector2(360, 0)
	_period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stepper.add_child(_period_label)
	var plus: Button = Button.new()
	plus.text = "+"
	plus.custom_minimum_size = Vector2(144, 132)
	plus.pressed.connect(func() -> void: _set_period_player(period + 1))
	_stepper.add_child(plus)
	_drums = Control.new()
	_drums.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_drums.mouse_filter = Control.MOUSE_FILTER_STOP
	_drums.draw.connect(_draw_drums)
	_drums.gui_input.connect(_drums_input)
	box.add_child(_drums)
	set_period(period)
	set_process(false)


func configure(p_period: int, editable: bool, p_max: int, p_rusted: bool) -> void:
	period_editable = editable
	period_max = clampi(p_max, 1, MAX_DRUMS)
	rusted = p_rusted
	set_period(p_period)


func set_period(n: int) -> void:
	period = clampi(n, 1, period_max)
	var old: PackedInt32Array = shifts
	shifts = PackedInt32Array()
	shifts.resize(period)
	for i: int in range(period):
		shifts[i] = old[i] if i < old.size() else 0
	_pos = PackedFloat32Array()
	_vel = PackedFloat32Array()
	_last_notch = PackedInt32Array()
	for i: int in range(period):
		_pos.append(float(shifts[i]))
		_vel.append(0.0)
		_last_notch.append(shifts[i])
	selected = clampi(selected, 0, period - 1)
	if _stepper != null:
		_stepper.visible = period_editable
		_period_label.text = tr("UI_MULTI_PERIOD") % period
		_drums.queue_redraw()


func set_shift(drum: int, k: int, animate: bool = true) -> void:
	if drum < 0 or drum >= period:
		return
	snapshot()
	var target: int = posmod(k, 26)
	shifts[drum] = target
	_last_notch[drum] = target
	if animate and not Settings.clear_mind:
		var from: float = _pos[drum]
		var delta: float = wrapf(float(target) - from, -13.0, 13.0)
		var tw: Tween = create_tween()
		tw.tween_method(func(v: float) -> void:
			_pos[drum] = v
			_drums.queue_redraw(), from, from + delta, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_pos[drum] = float(target)
	EventBus.sfx.emit("detent")
	shifts_changed.emit(shifts)
	state_changed.emit()
	_drums.queue_redraw()


func get_state() -> Dictionary:
	return {"period": period, "shifts": Array(shifts), "selected": selected}


func set_state(d: Dictionary) -> void:
	var s: Array = d.get("shifts", [])
	period = clampi(int(d.get("period", period)), 1, period_max)
	shifts = PackedInt32Array()
	for v: Variant in s:
		shifts.append(int(v))
	set_period(period)
	selected = int(d.get("selected", 0))
	period_changed.emit(period)
	shifts_changed.emit(shifts)
	drum_selected.emit(selected)
	_drums.queue_redraw()


func _set_period_player(n: int) -> void:
	var m: int = clampi(n, 1, period_max)
	if m == period:
		return
	snapshot()
	set_period(m)
	EventBus.sfx.emit("tile_snap")
	period_changed.emit(period)
	shifts_changed.emit(shifts)
	state_changed.emit()


func _drum_w() -> float:
	return _drums.size.x / float(maxi(period, 1))


func _drums_input(event: InputEvent) -> void:
	if ToolBase.is_press(event):
		var p: Vector2 = ToolBase.press_pos(event)
		var d: int = clampi(int(p.x / _drum_w()), 0, period - 1)
		snapshot()
		_drag_drum = d
		_drag_y = p.y
		_drag_start = _pos[d]
		_vel[d] = 0.0
		if selected != d:
			selected = d
			drum_selected.emit(d)
		set_process(true)
		_drums.queue_redraw()
	elif ToolBase.is_drag(event) and _drag_drum >= 0:
		var y: float = ToolBase.drag_pos(event).y
		var old: float = _pos[_drag_drum]
		var factor: float = 0.6 if rusted else 1.0
		_pos[_drag_drum] = _drag_start + (y - _drag_y) / NOTCH_PX * factor
		var dt: float = maxf(get_process_delta_time(), 0.001)
		_vel[_drag_drum] = lerpf(_vel[_drag_drum], (_pos[_drag_drum] - old) / dt, 0.35)
		_check_notch(_drag_drum)
		_drums.queue_redraw()
	elif ToolBase.is_release(event) and _drag_drum >= 0:
		if rusted:
			_vel[_drag_drum] = 0.0
		_drag_drum = -1


func _process(delta: float) -> void:
	var busy: bool = false
	for d: int in range(period):
		if d == _drag_drum:
			busy = true
			continue
		if absf(_vel[d]) > 0.8 and not rusted:
			_pos[d] += _vel[d] * delta
			_vel[d] *= exp(-5.5 * delta)
			_check_notch(d)
			busy = true
		else:
			_vel[d] = 0.0
			var target: float = round(_pos[d])
			if absf(_pos[d] - target) > 0.01:
				_pos[d] = lerpf(_pos[d], target, minf(1.0, delta * 14.0))
				busy = true
			elif _pos[d] != target:
				_pos[d] = target
				_check_notch(d)
				state_changed.emit()
	_drums.queue_redraw()
	if not busy:
		set_process(false)


func _check_notch(d: int) -> void:
	var n: int = int(round(_pos[d]))
	var changed: bool = false
	while n != _last_notch[d]:
		_last_notch[d] += 1 if n > _last_notch[d] else -1
		EventBus.sfx.emit("detent")
		EventBus.haptic.emit("tick")
		drum_notch.emit(d)
		changed = true
	if changed:
		shifts[d] = posmod(n, 26)
		shifts_changed.emit(shifts)


func _draw_drums() -> void:
	if _drums.size.x < 60.0 or _drums.size.y < 120.0:
		return
	var w: float = _drum_w()
	var h: float = _drums.size.y
	var f: Font = ThemeBuilder.font("mono_bold")
	var cy: float = h * 0.5
	var row_h: float = minf(96.0, h / 6.0)
	for d: int in range(period):
		var x: float = d * w
		var col: Color = Palette.strand(d)
		var body: Rect2 = Rect2(x + 6, 10, w - 12, h - 20)
		_drums.draw_rect(body, Color("2b2119"))
		# Drum shading: lighter band in the middle like a cylinder
		for k: int in range(6):
			var t: float = float(k) / 5.0
			var band: Rect2 = Rect2(body.position.x, body.position.y + body.size.y * t * 0.5, body.size.x, body.size.y * (1.0 - t))
			_drums.draw_rect(band, Color(0.94, 0.88, 0.74, 0.06))
		var fs: int = int(minf(w * 0.55, 62.0))
		for k: int in range(-3, 4):
			var val: float = _pos[d] - float(k)
			var li: int = posmod(int(round(val)), 26)
			var frac: float = val - round(val)
			var yy: float = cy + (float(k) + frac) * row_h
			if yy < body.position.y + 20.0 or yy > body.end.y - 10.0:
				continue
			var fade: float = 1.0 - absf(yy - cy) / (h * 0.5)
			var ch: String = String.chr(65 + li)
			var cw: float = f.get_char_size(ch.unicode_at(0), fs).x
			var c2: Color = Palette.VELLUM if k == 0 else Color(Palette.VELLUM, 0.25 + 0.5 * fade)
			_drums.draw_char(f, Vector2(x + (w - cw) * 0.5, yy + fs * 0.35), ch, fs, c2)
		# Window with the strand colour
		var win: Rect2 = Rect2(x + 2, cy - row_h * 0.5, w - 4, row_h)
		_drums.draw_rect(win, Color(col, 0.35))
		_drums.draw_rect(win, col.lightened(0.35) if d != selected else Palette.GOLD_LIGHT, false, 5.0 if d == selected else 3.0)
		# Column number
		var nf: Font = ThemeBuilder.font("semibold")
		var num: String = str(d + 1)
		_drums.draw_string(nf, Vector2(x + 12, body.end.y - 12), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col.lightened(0.4))
	if rusted:
		_drums.draw_string(ThemeBuilder.font("italic"), Vector2(10, 40), tr("UI_MULTI_RUSTED"), HORIZONTAL_ALIGNMENT_LEFT, _drums.size.x - 20.0, 30, Color("d9a07a"))


func coach_rect() -> Rect2:
	return _drums.get_global_rect() if _drums != null else get_global_rect()
