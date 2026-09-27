class_name CipherWheel
extends ToolBase
## Two concentric brass-and-vellum rings. The OUTER ring carries the cipher alphabet and
## turns under the thumb (angular drag, inertia, detents with a tick per notch); the INNER
## ring is the plain alphabet. With the outer ring turned k notches, the cipher letter
## above plain letter p is p+k: the wheel's value is the Caesar shift k.
## Mirror mode (Atbash) reverses the inner ring and locks the wheel: no key to turn.
## Rusted: no inertia, and each notch crossed is reported as a trial.

signal shift_changed(shift: int)
signal notch_crossed(new_shift: int)
signal wheel_mode_changed(mode: String)

const MODE_SHIFT: String = "shift"
const MODE_MIRROR: String = "mirror"
const FRICTION: float = 5.5

@export var allow_mirror: bool = false
@export var rusted: bool = false
@export var locked: bool = false

var mode: String = MODE_SHIFT
var shift: int = 0
var _angle: float = 0.0 # continuous offset in notches
var _visual: float = 0.0 # animation-only offset added when drawing
var _anim: Tween = null
var _dragging: bool = false
var _last_ang: float = 0.0
var _velocity: float = 0.0 # notches per second
var _last_notch: int = 0
var _mode_buttons: HBoxContainer = null
var _mirror_btn: Button = null
var _shift_btn: Button = null


func _ready() -> void:
	tool_id = "cipher_wheel"
	custom_minimum_size = Vector2(360, 420)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_mode_buttons = HBoxContainer.new()
	_mode_buttons.add_theme_constant_override("separation", 12)
	add_child(_mode_buttons)
	_shift_btn = Button.new()
	_shift_btn.text = tr("UI_WHEEL_SHIFT")
	_shift_btn.toggle_mode = true
	_mirror_btn = Button.new()
	_mirror_btn.text = tr("UI_WHEEL_MIRROR")
	_mirror_btn.toggle_mode = true
	var g: ButtonGroup = ButtonGroup.new()
	_shift_btn.button_group = g
	_mirror_btn.button_group = g
	_shift_btn.button_pressed = true
	_shift_btn.pressed.connect(func() -> void: set_mode(MODE_SHIFT, true))
	_mirror_btn.pressed.connect(func() -> void: set_mode(MODE_MIRROR, true))
	_mode_buttons.add_child(_shift_btn)
	_mode_buttons.add_child(_mirror_btn)
	resized.connect(_place_buttons)
	_refresh_buttons()
	set_process(false)


func configure(p_allow_mirror: bool, p_rusted: bool) -> void:
	allow_mirror = p_allow_mirror
	rusted = p_rusted
	_refresh_buttons()
	queue_redraw()


func get_state() -> Dictionary:
	return {"shift": shift, "mode": mode}


func set_state(d: Dictionary) -> void:
	mode = str(d.get("mode", MODE_SHIFT))
	var k: int = int(d.get("shift", 0))
	_angle = float(k)
	_last_notch = k
	_visual = 0.0
	shift = k
	_refresh_buttons()
	wheel_mode_changed.emit(mode)
	shift_changed.emit(shift)
	queue_redraw()


## Programmatic turn (e.g. "read this peak as E"). Animates; does not count notches.
func turn_to(k: int, animate: bool = true) -> void:
	snapshot()
	var target: int = posmod(k, 26)
	var from: float = _angle
	var delta: float = wrapf(float(target) - from, -13.0, 13.0)
	_velocity = 0.0
	set_process(false)
	# The real angle jumps at once (notches are never counted for it); only the drawing
	# eases from the old position through `_visual`.
	_angle = float(target)
	_last_notch = target
	if _anim != null:
		_anim.kill()
	_visual = 0.0
	if animate and not Settings.clear_mind:
		_visual = -delta
		_anim = create_tween()
		_anim.tween_method(func(v: float) -> void:
			_visual = v
			queue_redraw(), -delta, 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_set_shift_internal(target)
	EventBus.sfx.emit("detent")
	EventBus.haptic.emit("snap")
	state_changed.emit()
	queue_redraw()


func set_mode(m: String, by_player: bool = false) -> void:
	if m == mode:
		return
	if by_player:
		snapshot()
	mode = m
	if mode == MODE_MIRROR:
		_velocity = 0.0
		_angle = 0.0
		_last_notch = 0
		_set_shift_internal(0)
	_refresh_buttons()
	wheel_mode_changed.emit(mode)
	if by_player:
		EventBus.sfx.emit("tile_snap")
		state_changed.emit()
	queue_redraw()


func _refresh_buttons() -> void:
	if _mode_buttons == null:
		return
	_mode_buttons.visible = allow_mirror
	_shift_btn.set_pressed_no_signal(mode == MODE_SHIFT)
	_mirror_btn.set_pressed_no_signal(mode == MODE_MIRROR)
	_place_buttons()


func _place_buttons() -> void:
	if _mode_buttons != null:
		_mode_buttons.reset_size()
		_mode_buttons.position = Vector2((size.x - _mode_buttons.size.x) * 0.5, 0)


func _wheel_center() -> Vector2:
	var top: float = 170.0 if allow_mirror else 0.0
	return Vector2(size.x * 0.5, top + (size.y - top) * 0.5)


func _radius() -> float:
	var top: float = 170.0 if allow_mirror else 0.0
	return minf(size.x, size.y - top) * 0.48


func _gui_input(event: InputEvent) -> void:
	if ToolBase.is_press(event):
		var p: Vector2 = ToolBase.press_pos(event)
		var c: Vector2 = _wheel_center()
		if p.distance_to(c) > _radius() * 1.08 or p.distance_to(c) < _radius() * 0.18:
			return
		accept_event()
		if locked or mode == MODE_MIRROR:
			_rattle()
			return
		if _anim != null:
			_anim.kill()
		_visual = 0.0
		snapshot()
		_dragging = true
		_velocity = 0.0
		_last_ang = (p - c).angle()
		set_process(true)
	elif ToolBase.is_release(event) and _dragging:
		_dragging = false
		if rusted:
			_velocity = 0.0
		set_process(true)
	elif ToolBase.is_drag(event) and _dragging:
		accept_event()
		var p2: Vector2 = ToolBase.drag_pos(event)
		var ang: float = (p2 - _wheel_center()).angle()
		var d: float = wrapf(ang - _last_ang, -PI, PI)
		_last_ang = ang
		# The ring follows the finger; turning it clockwise lowers the shift.
		var dn: float = d / (TAU / 26.0)
		if rusted:
			dn *= 0.55
		_angle -= dn
		var dt: float = maxf(get_process_delta_time(), 0.001)
		_velocity = lerpf(_velocity, -dn / dt, 0.35)
		_check_notch()
		queue_redraw()


func _process(delta: float) -> void:
	if _dragging:
		return
	if absf(_velocity) > 0.8 and not rusted:
		_angle += _velocity * delta
		_velocity *= exp(-FRICTION * delta)
		_check_notch()
		queue_redraw()
		return
	# Settle into the nearest detent.
	var target: float = round(_angle)
	_angle = lerpf(_angle, target, minf(1.0, delta * 14.0))
	if absf(_angle - target) < 0.01:
		_angle = target
		_velocity = 0.0
		set_process(false)
		_check_notch()
		state_changed.emit()
	queue_redraw()


func _check_notch() -> void:
	var n: int = int(round(_angle))
	while n != _last_notch:
		_last_notch += 1 if n > _last_notch else -1
		EventBus.sfx.emit("detent")
		EventBus.haptic.emit("tick")
		notch_crossed.emit(posmod(_last_notch, 26))
	_set_shift_internal(posmod(n, 26))


func _set_shift_internal(k: int) -> void:
	if k != shift:
		shift = k
		shift_changed.emit(shift)


func _rattle() -> void:
	EventBus.sfx.emit("wrong_soft")
	EventBus.haptic.emit("thud")
	if Settings.clear_mind:
		return
	var tw: Tween = create_tween()
	for i: int in range(3):
		tw.tween_method(func(v: float) -> void:
			_angle = v
			queue_redraw(), 0.0, 0.12 * (1 if i % 2 == 0 else -1), 0.05)
	tw.tween_callback(func() -> void:
		_angle = float(shift)
		queue_redraw())


func _draw() -> void:
	if _radius() < 60.0:
		return
	var c: Vector2 = _wheel_center()
	var r: float = _radius()
	var step: float = TAU / 26.0
	var fnt: Font = ThemeBuilder.font("semibold")
	var outer_fs: int = int(r * 0.13)
	var inner_fs: int = int(r * 0.115)
	# Shadow and rings
	draw_circle(c + Vector2(0, 10), r * 1.02, Color(0, 0, 0, 0.45))
	draw_circle(c, r, Palette.GOLD)
	draw_circle(c, r * 0.97, Color("ddcba4") if not rusted else Color("b98e63"))
	draw_circle(c, r * 0.74, Palette.GOLD_TEXT)
	draw_circle(c, r * 0.725, Color("efe3c8"))
	draw_circle(c, r * 0.47, Palette.GOLD)
	draw_circle(c, r * 0.455, Color("2b2119"))
	if rusted:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 5
		for i: int in range(160):
			var a: float = rng.randf() * TAU
			var rr: float = r * (0.76 + rng.randf() * 0.2)
			draw_circle(c + Vector2(cos(a), sin(a)) * rr, rng.randf_range(2.0, 7.0), Color(0.45, 0.2, 0.08, rng.randf_range(0.25, 0.6)))
	# Reading window at the top
	var win_a: float = -PI * 0.5
	var wpts: PackedVector2Array = PackedVector2Array()
	for k: int in range(9):
		var a2: float = win_a - step * 0.5 + step * float(k) / 8.0
		wpts.append(c + Vector2(cos(a2), sin(a2)) * r * 1.0)
	for k: int in range(8, -1, -1):
		var a3: float = win_a - step * 0.5 + step * float(k) / 8.0
		wpts.append(c + Vector2(cos(a3), sin(a3)) * r * 0.47)
	draw_colored_polygon(wpts, Color(Palette.BLOOD, 0.22))
	draw_polyline(wpts, Palette.RUBRIC, 3.0, true)
	for i: int in range(26):
		# Inner (plain) ring: fixed. Mirror mode reverses it.
		var a_in: float = win_a + step * i
		var plain_letter: int = (25 - i) if mode == MODE_MIRROR else i
		_draw_glyph(fnt, c + Vector2(cos(a_in), sin(a_in)) * r * 0.6, a_in, String.chr(65 + plain_letter), inner_fs, Palette.INK)
		# Outer (cipher) ring: letter at plain position i is i + angle.
		var a_out: float = win_a + step * (float(i) - _angle - _visual)
		_draw_glyph(fnt, c + Vector2(cos(a_out), sin(a_out)) * r * 0.855, a_out, String.chr(65 + i), outer_fs, Palette.RUBRIC)
		# Tick marks between outer letters
		var at: float = a_out + step * 0.5
		draw_line(c + Vector2(cos(at), sin(at)) * r * 0.76, c + Vector2(cos(at), sin(at)) * r * 0.8, Color(Palette.GOLD_TEXT, 0.8), 2.0)
	# Hub readout
	var hub_fs: int = int(r * 0.2)
	var label: String = str(shift) if mode == MODE_SHIFT else "<>"
	var w: float = fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, hub_fs).x
	draw_string(fnt, c + Vector2(-w * 0.5, hub_fs * 0.1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, hub_fs, Palette.GOLD_LIGHT)
	var sub: String = tr("UI_WHEEL_MIRRORED") if mode == MODE_MIRROR else (tr("UI_WHEEL_SHIFT_LABEL") if allow_mirror else tr("UI_WHEEL_KEY"))
	var sub_fs: int = int(r * 0.075)
	var sw: float = fnt.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs).x
	draw_string(fnt, c + Vector2(-sw * 0.5, hub_fs * 0.1 + sub_fs * 1.4), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_fs, Palette.ON_DARK_FADED)
	# Blood-drop pointer
	var tip: Vector2 = c + Vector2(0, -r * 1.02)
	draw_colored_polygon(PackedVector2Array([tip + Vector2(-16, -34), tip + Vector2(16, -34), tip + Vector2(0, 4)]), Palette.RUBRIC)
	if locked or mode == MODE_MIRROR:
		draw_arc(c, r * 0.47, 0.0, TAU, 48, Palette.RUBRIC, 5.0)


func _draw_glyph(f: Font, pos: Vector2, ang: float, ch: String, fs: int, col: Color) -> void:
	draw_set_transform(pos, ang + PI * 0.5, Vector2.ONE)
	var w: float = f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(-w * 0.5, fs * 0.36), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func coach_rect() -> Rect2:
	var c: Vector2 = _wheel_center()
	var r: float = _radius()
	return Rect2(global_position + c - Vector2(r, r), Vector2(r, r) * 2.0)
