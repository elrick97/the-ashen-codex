class_name CribDragger
extends ToolBase
## Two letters under one pad: C1 xor C2 = P1 xor P2, so the pad is gone. The stream is
## laid out in cells: letter A's reading on top, the xor byte in the middle, letter B's
## reading below. Drag a crib (a guessed word) along the stream: wherever it sits, the
## other letter's row shows stream xor crib. Readable output means the guess is right.
## Pin it to commit (a wrong pin costs Thirst). Tray of story words, or write your own.

signal offset_changed(offset: int)
signal row_changed(row: int)
signal crib_changed(crib: String)
signal pin_requested(offset: int, row: int)

const CELLS_PER_LINE: int = 14
const LINES: int = 4

var stream: PackedByteArray = PackedByteArray()
var known: Array[PackedByteArray] = [PackedByteArray(), PackedByteArray()] # 0 = unknown
var crib: String = ""
var fragment: PackedByteArray = PackedByteArray()
var fragment_ok: bool = false
var tray: PackedStringArray = PackedStringArray()
var custom: PackedStringArray = PackedStringArray()
var offset: int = 0
var row: int = 0 # which letter the crib is placed in
var targets: Array[Dictionary] = [] # [{"label", "text"}]

var _grid: Control = null
var _tray_box: HBoxContainer = null
var _row_btns: Array[Button] = []
var _pin_btn: Button = null
var _targets_label: Label = null
var _drag_from: int = -1
var _drag_offset0: int = 0


func _ready() -> void:
	tool_id = "crib_dragger"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(600, 700)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var tray_scroll: ScrollContainer = ScrollContainer.new()
	tray_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tray_scroll.custom_minimum_size = Vector2(0, 144)
	box.add_child(tray_scroll)
	_tray_box = HBoxContainer.new()
	_tray_box.add_theme_constant_override("separation", 8)
	tray_scroll.add_child(_tray_box)
	var rows_box: HBoxContainer = HBoxContainer.new()
	rows_box.add_theme_constant_override("separation", 8)
	box.add_child(rows_box)
	var rl: Label = Label.new()
	rl.text = tr("UI_CRIBDRAG_IN")
	rl.theme_type_variation = "LightSmallLabel"
	rows_box.add_child(rl)
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(2):
		var b: Button = Button.new()
		b.text = tr("UI_CRIBDRAG_LETTER_A") if i == 0 else tr("UI_CRIBDRAG_LETTER_B")
		b.toggle_mode = true
		b.button_group = g
		b.button_pressed = i == row
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			snapshot()
			row = i
			row_changed.emit(row)
			state_changed.emit()
			_refresh())
		rows_box.add_child(b)
		_row_btns.append(b)
	_grid = Control.new()
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.custom_minimum_size = Vector2(0, 420)
	_grid.mouse_filter = Control.MOUSE_FILTER_STOP
	_grid.draw.connect(_draw_grid)
	_grid.gui_input.connect(_grid_input)
	box.add_child(_grid)
	var nav: HBoxContainer = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	box.add_child(nav)
	for spec: Array in [["<<", -CELLS_PER_LINE], ["<", -1], [">", 1], [">>", CELLS_PER_LINE]]:
		var nb: Button = Button.new()
		nb.text = spec[0]
		nb.custom_minimum_size = Vector2(120, 132)
		var step: int = spec[1]
		nb.pressed.connect(func() -> void: set_offset_player(offset + step))
		nav.add_child(nb)
	_pin_btn = Button.new()
	_pin_btn.theme_type_variation = "RubricButton"
	_pin_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pin_btn.pressed.connect(func() -> void: pin_requested.emit(offset, row))
	nav.add_child(_pin_btn)
	_targets_label = Label.new()
	_targets_label.theme_type_variation = "LightLabel"
	_targets_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_targets_label)
	_refresh()


func configure(s: PackedByteArray, tray_words: PackedStringArray) -> void:
	stream = s
	tray = tray_words
	known = [PackedByteArray(), PackedByteArray()]
	for r: int in range(2):
		known[r].resize(stream.size())
		known[r].fill(0)
	if crib == "" and tray.size() > 0:
		crib = tray[0]
	_rebuild_tray()
	_refresh()


func set_known(r: int, bytes: PackedByteArray) -> void:
	known[r] = bytes
	_grid.queue_redraw()


func set_fragment(frag: PackedByteArray, readable: bool) -> void:
	fragment = frag
	fragment_ok = readable
	_grid.queue_redraw()


func set_targets(t: Array[Dictionary]) -> void:
	targets = t
	_refresh()


func set_offset_player(o: int) -> void:
	var n: int = clampi(o, 0, maxi(0, stream.size() - crib.length()))
	if n == offset:
		return
	offset = n
	EventBus.sfx.emit("tick")
	EventBus.haptic.emit("tick")
	offset_changed.emit(offset)
	state_changed.emit()
	_grid.queue_redraw()


func get_state() -> Dictionary:
	return {"offset": offset, "row": row, "crib": crib, "custom": Array(custom)}


func set_state(d: Dictionary) -> void:
	offset = int(d.get("offset", 0))
	row = int(d.get("row", 0))
	crib = str(d.get("crib", crib))
	custom = PackedStringArray(d.get("custom", []))
	_rebuild_tray()
	crib_changed.emit(crib)
	row_changed.emit(row)
	offset_changed.emit(offset)
	_refresh()


func _rebuild_tray() -> void:
	if _tray_box == null:
		return
	for c: Node in _tray_box.get_children():
		c.queue_free()
	var all: PackedStringArray = tray.duplicate()
	all.append_array(custom)
	for word: String in all:
		var b: Button = Button.new()
		b.text = word.strip_edges() if word.strip_edges() != "" else "' '"
		b.add_theme_font_override("font", ThemeBuilder.font("mono_bold"))
		b.add_theme_font_size_override("font_size", ThemeBuilder.size(32))
		if word == crib:
			b.theme_type_variation = "RubricButton"
		b.pressed.connect(_choose_crib.bind(word))
		_tray_box.add_child(b)
	var write: Button = Button.new()
	write.text = tr("UI_CRIBDRAG_WRITE")
	write.theme_type_variation = "GhostButton"
	write.pressed.connect(_write_crib)
	_tray_box.add_child(write)


func _choose_crib(word: String) -> void:
	snapshot()
	crib = word
	offset = clampi(offset, 0, maxi(0, stream.size() - crib.length()))
	EventBus.sfx.emit("tile_snap")
	crib_changed.emit(crib)
	offset_changed.emit(offset)
	state_changed.emit()
	_rebuild_tray()
	_refresh()


func _write_crib() -> void:
	var k: GlyphKeyboard = GlyphKeyboard.open(get_tree().current_scene if get_tree().current_scene != null else self)
	k.submitted.connect(func(t: String) -> void:
		if not custom.has(t) and not tray.has(t):
			custom.append(t)
		_choose_crib(t))


func _refresh() -> void:
	if _pin_btn == null:
		return
	for i: int in range(_row_btns.size()):
		_row_btns[i].set_pressed_no_signal(i == row)
	_pin_btn.text = tr("UI_CRIBDRAG_PIN") % (tr("UI_CRIBDRAG_LETTER_A") if row == 0 else tr("UI_CRIBDRAG_LETTER_B"))
	var lines: PackedStringArray = PackedStringArray()
	for t: Dictionary in targets:
		lines.append("%s  %s" % [tr(str(t["label"])), str(t["text"])])
	_targets_label.text = "\n".join(lines)
	_grid.queue_redraw()


func _window_start() -> int:
	var per: int = CELLS_PER_LINE * LINES
	var start: int = offset - CELLS_PER_LINE
	start = clampi(start - posmod(start, CELLS_PER_LINE), 0, maxi(0, stream.size() - per + (CELLS_PER_LINE - posmod(stream.size(), CELLS_PER_LINE)) % CELLS_PER_LINE))
	return start


func _cell_rect(i: int) -> Rect2:
	var start: int = _window_start()
	var k: int = i - start
	var cw: float = _grid.size.x / CELLS_PER_LINE
	var ch: float = (_grid.size.y - 40.0) / LINES
	@warning_ignore("integer_division")
	var line: int = k / CELLS_PER_LINE
	return Rect2((k % CELLS_PER_LINE) * cw, 40.0 + line * ch, cw, ch)


func _draw_grid() -> void:
	var w: float = _grid.size.x
	var h: float = _grid.size.y
	_grid.draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.07, 0.05, 0.92))
	# Position bar
	var bar: Rect2 = Rect2(10, 10, w - 20, 16)
	_grid.draw_rect(bar, Color(Palette.GOLD, 0.25))
	if stream.size() > 0:
		var s0: float = float(_window_start()) / float(stream.size())
		var s1: float = minf(1.0, float(_window_start() + CELLS_PER_LINE * LINES) / float(stream.size()))
		_grid.draw_rect(Rect2(bar.position.x + bar.size.x * s0, bar.position.y, bar.size.x * (s1 - s0), bar.size.y), Palette.GOLD)
		var cx: float = bar.position.x + bar.size.x * float(offset) / float(stream.size())
		_grid.draw_rect(Rect2(cx - 3, 4, 6, 28), Palette.BLOOD)
	var f: Font = ThemeBuilder.font("mono_bold")
	var start: int = _window_start()
	var end: int = mini(stream.size(), start + CELLS_PER_LINE * LINES)
	for i: int in range(start, end):
		var r: Rect2 = _cell_rect(i)
		var in_crib: bool = i >= offset and i < offset + crib.length()
		if in_crib:
			_grid.draw_rect(r.grow(-2.0), Color(Palette.GOLD, 0.22))
		_grid.draw_rect(r.grow(-2.0), Color(Palette.GOLD_TEXT, 0.5), false, 1.0)
		var fs: int = int(minf(r.size.x * 0.62, r.size.y * 0.3))
		var hex: String = BytesUtil.byte_to_hex(stream[i])
		_grid.draw_string(f, Vector2(r.position.x, r.get_center().y + fs * 0.25), hex, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(fs * 0.62), Color("f0b8a8"))
		for rr: int in range(2):
			var y: float = r.position.y + (fs + 4.0 if rr == 0 else r.size.y - 10.0)
			var ch: String = ""
			var col: Color = Palette.ON_DARK
			var kb: PackedByteArray = known[rr]
			if i < kb.size() and kb[i] != 0:
				ch = String.chr(kb[i])
				col = Palette.VELLUM
			elif in_crib:
				var ci: int = i - offset
				if rr == row:
					ch = crib[ci]
					col = Color("9fc3e8")
				elif ci < fragment.size():
					var b: int = fragment[ci]
					ch = String.chr(b) if b >= 32 and b <= 126 else "?"
					col = Palette.GOLD_LIGHT if fragment_ok else Color("e07a6a")
			if ch == " ":
				ch = "_"
				col = Color(col, 0.45)
			if ch != "":
				_grid.draw_string(f, Vector2(r.position.x, y), ch, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, col)
			else:
				_grid.draw_line(Vector2(r.position.x + r.size.x * 0.3, y), Vector2(r.position.x + r.size.x * 0.7, y), Color(Palette.ON_DARK_FADED, 0.4), 2.0)


func _grid_input(event: InputEvent) -> void:
	if ToolBase.is_press(event):
		var p: Vector2 = ToolBase.press_pos(event)
		var i: int = _cell_at(p)
		if i < 0:
			return
		_drag_from = i
		_drag_offset0 = offset
		if i < offset or i >= offset + crib.length():
			set_offset_player(i)
			_drag_offset0 = offset
	elif ToolBase.is_drag(event) and _drag_from >= 0:
		var j: int = _cell_at(ToolBase.drag_pos(event))
		if j >= 0:
			set_offset_player(_drag_offset0 + (j - _drag_from))
	elif ToolBase.is_release(event):
		_drag_from = -1


func _cell_at(p: Vector2) -> int:
	var start: int = _window_start()
	var end: int = mini(stream.size(), start + CELLS_PER_LINE * LINES)
	for i: int in range(start, end):
		if _cell_rect(i).has_point(p):
			return i
	return -1


func coach_rect() -> Rect2:
	return _grid.get_global_rect() if _grid != null else get_global_rect()
