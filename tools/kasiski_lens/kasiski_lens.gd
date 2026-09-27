class_name KasiskiLens
extends ToolBase
## Hold a letter on the page: if a sequence of three or more letters through it repeats,
## the lens shows every occurrence on a ruler with the spacings between them, and the
## repeat is collected. The factor tray counts how many collected spacings each number
## divides; common divisors glow. Tap a factor to try it as the key length.

signal period_chosen(period: int)

var text_length: int = 1
var current: Dictionary = {} # {"seq", "positions", "spacings"}
var collected: Array[Dictionary] = []
var tally: PackedInt32Array = PackedInt32Array()
var tally_lo: int = 2
var tally_hi: int = 12
var found_total: int = 0
var chosen: int = 0

var _ruler: Control = null
var _tray: GridContainer = null
var _info: Label = null
var _list: Label = null


func _ready() -> void:
	tool_id = "kasiski_lens"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(600, 560)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_info = Label.new()
	_info.theme_type_variation = "LightSmallLabel"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_info)
	_ruler = Control.new()
	_ruler.custom_minimum_size = Vector2(0, 190)
	_ruler.draw.connect(_draw_ruler)
	box.add_child(_ruler)
	_list = Label.new()
	_list.theme_type_variation = "LightLabel"
	_list.add_theme_font_override("font", ThemeBuilder.font("mono"))
	_list.add_theme_font_size_override("font_size", ThemeBuilder.size(32))
	_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_list)
	var th: Label = Label.new()
	th.text = tr("UI_KASISKI_TRAY")
	th.theme_type_variation = "LightSmallLabel"
	box.add_child(th)
	_tray = GridContainer.new()
	_tray.columns = 6
	_tray.add_theme_constant_override("h_separation", 8)
	_tray.add_theme_constant_override("v_separation", 8)
	_tray.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_tray)
	_refresh()


func configure(length: int, lo: int, hi: int, total_repeats: int) -> void:
	text_length = maxi(length, 1)
	tally_lo = lo
	tally_hi = hi
	found_total = total_repeats
	_refresh()


## Mode calls this after a long-press found a repeat (or {} for none).
func show_repeat(r: Dictionary) -> void:
	current = r
	if not r.is_empty():
		var seen: bool = false
		for c: Dictionary in collected:
			if str(c["seq"]) == str(r["seq"]):
				seen = true
		if not seen:
			snapshot()
			collected.append(r)
			EventBus.sfx.emit("quill")
			state_changed.emit()
	_refresh()


func set_tally(t: PackedInt32Array) -> void:
	tally = t
	_refresh()


func get_state() -> Dictionary:
	var c: Array = []
	for r: Dictionary in collected:
		c.append({"seq": r["seq"], "positions": Array(r["positions"]), "spacings": Array(r["spacings"])})
	return {"collected": c, "chosen": chosen}


func set_state(d: Dictionary) -> void:
	collected = []
	for v: Variant in d.get("collected", []):
		var r: Dictionary = v
		collected.append({"seq": str(r["seq"]), "positions": PackedInt32Array(r["positions"]), "spacings": PackedInt32Array(r["spacings"])})
	chosen = int(d.get("chosen", 0))
	current = collected[collected.size() - 1] if not collected.is_empty() else {}
	state_changed.emit()
	_refresh()


func all_spacings() -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	for r: Dictionary in collected:
		out.append_array(r["spacings"])
	return out


func _refresh() -> void:
	if _info == null:
		return
	_info.text = tr("UI_KASISKI_INFO") % [collected.size(), found_total]
	var lines: PackedStringArray = PackedStringArray()
	for r: Dictionary in collected:
		var sp: PackedStringArray = PackedStringArray()
		for s: int in r["spacings"]:
			sp.append(str(s))
		lines.append("%s  %s" % [str(r["seq"]), ", ".join(sp)])
	_list.text = "\n".join(lines) if not lines.is_empty() else tr("UI_KASISKI_EMPTY")
	for c: Node in _tray.get_children():
		c.queue_free()
	var best: int = 0
	for f: int in range(tally_lo, mini(tally_hi, tally.size() - 1) + 1):
		best = maxi(best, tally[f])
	for f: int in range(tally_lo, tally_hi + 1):
		var n: int = tally[f] if f < tally.size() else 0
		var b: Button = Button.new()
		b.text = "%d\n%d" % [f, n]
		b.custom_minimum_size = Vector2(0, 150)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", ThemeBuilder.size(34))
		if best > 0 and n == best:
			b.theme_type_variation = "RubricButton"
		elif best > 0 and float(n) >= 0.75 * float(best):
			b.add_theme_color_override("font_color", Palette.RUBRIC)
		if f == chosen:
			b.add_theme_color_override("font_color", Palette.GOLD_LIGHT)
		b.pressed.connect(func() -> void:
			snapshot()
			chosen = f
			EventBus.sfx.emit("tile_snap")
			state_changed.emit()
			period_chosen.emit(f)
			_refresh())
		_tray.add_child(b)
	_ruler.queue_redraw()


func _draw_ruler() -> void:
	var w: float = _ruler.size.x
	var h: float = _ruler.size.y
	_ruler.draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.07, 0.05, 0.9))
	var y: float = h * 0.72
	_ruler.draw_line(Vector2(20, y), Vector2(w - 20, y), Palette.GOLD, 3.0)
	var span: float = w - 40.0
	var f: Font = ThemeBuilder.font("semibold")
	for i: int in range(0, text_length + 1, 10):
		var x: float = 20.0 + span * float(i) / float(text_length)
		_ruler.draw_line(Vector2(x, y - 8), Vector2(x, y + 8), Color(Palette.GOLD, 0.6), 2.0)
	if current.is_empty():
		_ruler.draw_string(ThemeBuilder.font("italic"), Vector2(24, 50), tr("UI_KASISKI_HOLD"), HORIZONTAL_ALIGNMENT_LEFT, w - 40.0, 32, Palette.ON_DARK_FADED)
		return
	var pos: PackedInt32Array = current["positions"]
	_ruler.draw_string(ThemeBuilder.font("mono_bold"), Vector2(24, 44), str(current["seq"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Palette.GOLD_LIGHT)
	for i: int in range(pos.size()):
		var x2: float = 20.0 + span * float(pos[i]) / float(text_length)
		_ruler.draw_circle(Vector2(x2, y), 11.0, Palette.BLOOD)
		if i > 0:
			var x1: float = 20.0 + span * float(pos[i - 1]) / float(text_length)
			var mid: Vector2 = Vector2((x1 + x2) * 0.5, y)
			var r: float = (x2 - x1) * 0.5
			_ruler.draw_arc(mid, r, PI, TAU, 24, Palette.RUBRIC.lightened(0.3), 3.0)
			var d: String = str(pos[i] - pos[i - 1])
			var dw: float = f.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
			_ruler.draw_string(f, Vector2(mid.x - dw * 0.5, y - minf(r, 90.0) - 8.0), d, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Palette.ON_DARK)


func coach_rect() -> Rect2:
	return _ruler.get_global_rect() if _ruler != null else get_global_rect()
