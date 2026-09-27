class_name ColumnLoom
extends ToolBase
## Slide N: the letter is split into N coloured strands (every Nth letter), and the
## "blood purity" vial shows their average index of coincidence. Wrong N: the strands
## look random (about 0.038). Right N: each strand is a plain Caesar of English and the
## vial jumps toward 0.066. Every N you try leaves a mark on the history rail.

signal n_changed(n: int)
signal period_chosen(n: int)

const IC_MIN: float = 0.030
const IC_MAX: float = 0.080
const IC_RANDOM: float = 0.0385
const IC_ENGLISH: float = 0.0667

var n: int = 1
var n_max: int = 12
var strands: PackedStringArray = PackedStringArray()
var ic_value: float = 0.0
var seen: Dictionary = {} # n -> ic

var _slider: HSlider = null
var _label: Label = null
var _view: Control = null
var _weave: Button = null
var _shown_ic: float = 0.0


func _ready() -> void:
	tool_id = "column_loom"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(360, 420)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	_label = Label.new()
	_label.theme_type_variation = "LightHeaderLabel"
	_label.custom_minimum_size = Vector2(250, 0)
	row.add_child(_label)
	_slider = HSlider.new()
	_slider.min_value = 1
	_slider.max_value = n_max
	_slider.step = 1
	_slider.value = n
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.custom_minimum_size = Vector2(0, 132)
	_slider.value_changed.connect(_on_slider)
	row.add_child(_slider)
	_view = Control.new()
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.draw.connect(_draw_view)
	box.add_child(_view)
	_weave = Button.new()
	_weave.theme_type_variation = "RubricButton"
	_weave.pressed.connect(func() -> void:
		EventBus.sfx.emit("tile_snap")
		period_chosen.emit(n))
	box.add_child(_weave)
	_refresh()


func configure(p_max: int) -> void:
	n_max = p_max
	_slider.max_value = n_max
	_refresh()


func set_strands(s: PackedStringArray, ic: float) -> void:
	strands = s
	ic_value = ic
	seen[n] = ic
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void:
		_shown_ic = v
		_view.queue_redraw(), _shown_ic, ic, 0.0 if Settings.clear_mind else 0.35)
	_refresh()


func get_state() -> Dictionary:
	var s: Dictionary = {}
	for k: Variant in seen.keys():
		s[str(k)] = seen[k]
	return {"n": n, "seen": s}


func set_state(d: Dictionary) -> void:
	seen = {}
	var s: Dictionary = d.get("seen", {})
	for k: Variant in s.keys():
		seen[int(str(k))] = float(s[k])
	n = clampi(int(d.get("n", 1)), 1, n_max)
	_slider.set_value_no_signal(n)
	n_changed.emit(n)
	_refresh()


func _on_slider(v: float) -> void:
	var m: int = int(v)
	if m == n:
		return
	snapshot()
	n = m
	EventBus.sfx.emit("detent")
	EventBus.haptic.emit("tick")
	n_changed.emit(n)
	state_changed.emit()
	_refresh()


func _refresh() -> void:
	if _label == null:
		return
	_label.text = tr("UI_LOOM_N") % n
	_weave.text = tr("UI_LOOM_WEAVE") % n
	_view.queue_redraw()


func _draw_view() -> void:
	var w: float = _view.size.x
	var h: float = _view.size.y
	_view.draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.07, 0.05, 0.9))
	var vial_w: float = 170.0
	var strands_w: float = w - vial_w - 30.0
	# Strands
	var f: Font = ThemeBuilder.font("mono_bold")
	var rows: int = mini(strands.size(), 12)
	var rh: float = minf(58.0, (h - 150.0) / float(maxi(rows, 1)))
	var fs: int = int(rh * 0.7)
	var cw: float = f.get_char_size(77, fs).x + 2.0
	for i: int in range(rows):
		var y: float = 20.0 + i * rh
		var col: Color = Palette.strand(i)
		_view.draw_rect(Rect2(10, y, 10, rh - 8), col.lightened(0.2))
		var s: String = strands[i]
		var max_chars: int = int((strands_w - 40.0) / cw)
		for k: int in range(mini(s.length(), max_chars)):
			_view.draw_char(f, Vector2(30 + k * cw, y + rh * 0.72), s[k], fs, col.lightened(0.45))
	# Vial
	var vx: float = w - vial_w - 10.0
	var vtop: float = 30.0
	var vh: float = h - 170.0
	var body: Rect2 = Rect2(vx + 40, vtop, vial_w - 80, vh)
	_view.draw_rect(body, Color(0.05, 0.03, 0.03))
	var frac: float = clampf((_shown_ic - IC_MIN) / (IC_MAX - IC_MIN), 0.0, 1.0)
	var fill_h: float = body.size.y * frac
	var purity: Color = Color("5a1010").lerp(Palette.BLOOD.lightened(0.15), clampf((_shown_ic - IC_RANDOM) / (IC_ENGLISH - IC_RANDOM), 0.0, 1.0))
	_view.draw_rect(Rect2(body.position.x, body.end.y - fill_h, body.size.x, fill_h), purity)
	_view.draw_rect(body, Palette.GOLD, false, 3.0)
	var lf: Font = ThemeBuilder.font("semibold")
	for mark: Array in [[IC_RANDOM, "UI_LOOM_RANDOM"], [IC_ENGLISH, "UI_LOOM_ENGLISH"]]:
		var my: float = body.end.y - body.size.y * (float(mark[0]) - IC_MIN) / (IC_MAX - IC_MIN)
		_view.draw_line(Vector2(body.position.x - 14, my), Vector2(body.end.x + 14, my), Palette.GOLD_LIGHT, 3.0)
		_view.draw_string(lf, Vector2(vx - 30, my - 8), tr(str(mark[1])), HORIZONTAL_ALIGNMENT_RIGHT, 100, 26, Palette.GOLD_LIGHT)
	var val: String = "%.3f" % _shown_ic
	_view.draw_string(lf, Vector2(vx, body.end.y + 44), val, HORIZONTAL_ALIGNMENT_CENTER, vial_w, 40, Palette.ON_DARK)
	_view.draw_string(ThemeBuilder.font("italic"), Vector2(vx - 20, body.end.y + 80), tr("UI_LOOM_VIAL"), HORIZONTAL_ALIGNMENT_CENTER, vial_w + 30, 26, Palette.ON_DARK_FADED)
	# History rail: one tick per N tried
	var ry: float = h - 60.0
	var rw: float = strands_w - 20.0
	_view.draw_line(Vector2(20, ry), Vector2(20 + rw, ry), Color(Palette.GOLD, 0.6), 2.0)
	for k: int in range(1, n_max + 1):
		var x: float = 20.0 + rw * float(k - 1) / float(maxi(n_max - 1, 1))
		_view.draw_string(lf, Vector2(x - 12, ry + 40), str(k), HORIZONTAL_ALIGNMENT_CENTER, 24, 24, Palette.ON_DARK_FADED if k != n else Palette.GOLD_LIGHT)
		if seen.has(k):
			var v: float = float(seen[k])
			var bh: float = 70.0 * clampf((v - IC_MIN) / (IC_MAX - IC_MIN), 0.0, 1.0)
			_view.draw_rect(Rect2(x - 7, ry - bh, 14, bh), Palette.BLOOD.lightened(0.1) if v < 0.055 else Palette.GOLD_LIGHT)


func coach_rect() -> Rect2:
	return _slider.get_global_rect().merge(_view.get_global_rect()) if _view != null else get_global_rect()
