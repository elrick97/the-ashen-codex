class_name HammingComb
extends ToolBase
## A bone comb whose teeth are key sizes 2..40. Each tooth's length is the average
## normalized Hamming distance between neighbouring blocks of that size (pushed by the
## mode). The right key size lines up repeated key bytes, so its tooth is short.
## Tap a tooth to read it; "Transpose" splits the letter into that many strands.

signal keysize_chosen(size: int)

var scores: PackedFloat64Array = PackedFloat64Array()
var min_size: int = 2
var max_size: int = 40
var selected: int = -1

var _comb: Control = null
var _info: Label = null
var _go: Button = null


func _ready() -> void:
	tool_id = "hamming_comb"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(600, 560)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_comb = Control.new()
	_comb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_comb.mouse_filter = Control.MOUSE_FILTER_STOP
	_comb.draw.connect(_draw_comb)
	_comb.gui_input.connect(_comb_input)
	box.add_child(_comb)
	_info = Label.new()
	_info.theme_type_variation = "LightSmallLabel"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_info)
	_go = Button.new()
	_go.theme_type_variation = "RubricButton"
	_go.pressed.connect(func() -> void:
		if selected >= min_size:
			EventBus.sfx.emit("tile_snap")
			keysize_chosen.emit(selected))
	box.add_child(_go)
	_refresh()


func set_scores(s: PackedFloat64Array, lo: int, hi: int) -> void:
	scores = s
	min_size = lo
	max_size = hi
	_refresh()


func get_state() -> Dictionary:
	return {"selected": selected}


func set_state(d: Dictionary) -> void:
	selected = int(d.get("selected", -1))
	_refresh()


func _refresh() -> void:
	if _info == null:
		return
	if selected >= min_size and selected < scores.size():
		_info.text = tr("UI_COMB_SELECTED") % [selected, scores[selected]]
		_go.text = tr("UI_COMB_GO") % selected
		_go.disabled = false
	else:
		_info.text = tr("UI_COMB_TAP")
		_go.text = tr("UI_COMB_GO_NONE")
		_go.disabled = true
	_comb.queue_redraw()


func _tooth_x(k: int) -> float:
	var n: int = max_size - min_size + 1
	return 20.0 + (_comb.size.x - 40.0) * (float(k - min_size) + 0.5) / float(n)


func _draw_comb() -> void:
	var w: float = _comb.size.x
	var h: float = _comb.size.y
	_comb.draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.07, 0.05, 0.9))
	var spine_y: float = 70.0
	_comb.draw_rect(Rect2(14, spine_y - 34, w - 28, 34), Color("d9c9a3"))
	_comb.draw_rect(Rect2(14, spine_y - 34, w - 28, 34), Palette.GOLD_TEXT, false, 2.0)
	var lo_v: float = INF
	var hi_v: float = 0.0
	for k: int in range(min_size, mini(max_size + 1, scores.size())):
		if scores[k] < INF:
			lo_v = minf(lo_v, scores[k])
			hi_v = maxf(hi_v, scores[k])
	var n: int = max_size - min_size + 1
	var tw: float = (w - 40.0) / float(n) * 0.62
	var max_len: float = h - spine_y - 70.0
	var best: int = -1
	for k: int in range(min_size, mini(max_size + 1, scores.size())):
		if best < 0 or scores[k] < scores[best]:
			best = k
	var sf: Font = ThemeBuilder.font("semibold")
	for k: int in range(min_size, mini(max_size + 1, scores.size())):
		var v: float = scores[k]
		if v == INF:
			continue
		var t: float = (v - lo_v) / maxf(hi_v - lo_v, 0.0001)
		var length: float = max_len * (0.18 + 0.82 * t)
		var x: float = _tooth_x(k)
		var col: Color = Color("e6d7b5")
		if k == selected:
			col = Palette.GOLD_LIGHT
		var tooth: PackedVector2Array = PackedVector2Array([
			Vector2(x - tw * 0.5, spine_y), Vector2(x + tw * 0.5, spine_y),
			Vector2(x + tw * 0.3, spine_y + length), Vector2(x, spine_y + length + tw * 0.4), Vector2(x - tw * 0.3, spine_y + length)])
		_comb.draw_colored_polygon(tooth, col)
		if k == best:
			_comb.draw_polyline(tooth + PackedVector2Array([tooth[0]]), Palette.BLOOD, 3.0)
		if k % 5 == 0 or k == min_size or k == selected:
			_comb.draw_string(sf, Vector2(x - 30, h - 20), str(k), HORIZONTAL_ALIGNMENT_CENTER, 60, 28, Palette.ON_DARK if k != selected else Palette.GOLD_LIGHT)
	_comb.draw_string(ThemeBuilder.font("italic"), Vector2(20, 26), tr("UI_COMB_TITLE"), HORIZONTAL_ALIGNMENT_LEFT, w - 40.0, 28, Palette.ON_DARK_FADED)


func _comb_input(event: InputEvent) -> void:
	if not ToolBase.is_press(event) and not (ToolBase.is_drag(event)):
		return
	var p: Vector2 = ToolBase.press_pos(event) if ToolBase.is_press(event) else ToolBase.drag_pos(event)
	var best: int = -1
	var best_d: float = INF
	for k: int in range(min_size, max_size + 1):
		var d: float = absf(_tooth_x(k) - p.x)
		if d < best_d:
			best_d = d
			best = k
	if best != selected and best >= 0:
		snapshot()
		selected = best
		EventBus.sfx.emit("tick")
		EventBus.haptic.emit("tick")
		state_changed.emit()
		_refresh()


func coach_rect() -> Rect2:
	return _comb.get_global_rect() if _comb != null else get_global_rect()
