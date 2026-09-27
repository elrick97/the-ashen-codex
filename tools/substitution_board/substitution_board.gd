class_name SubstitutionBoard
extends ToolBase
## A tray of cipher glyph tiles (the letters in the letter, commonest first) above 26
## plaintext slots. Drag a tile into a slot, or tap a tile then tap a slot. Tiles snap
## magnetically with a squash; a placed tile can be dragged elsewhere or back to the tray.
## Long-press a filled slot to lock it. Optional Crib tab: slide a known phrase along the
## letter; the mode reports which of its letters are consistent.
## Mapping keys and values are letter strings: {"X": "E"} = cipher X reads as plain E.

signal mapping_changed()
signal tile_selected(cipher: String)
signal crib_moved(offset: int)
signal crib_pin_requested(offset: int)

const COLS: int = 7
const LONG_PRESS: float = 0.5
const DRAG_THRESHOLD: float = 22.0

var tiles: Array[Dictionary] = [] # [{"c": "X", "n": 14}]
var mapping: Dictionary = {}
var locks: Dictionary = {} # plain letter -> true
var selected: String = ""
var crib_enabled: bool = false
var crib_text: String = ""
var crib_offset: int = 0
var crib_status: PackedInt32Array = PackedInt32Array()
var crib_window: String = "" # ciphertext for the crib view
var crib_fits: bool = false
var tab: int = 0
## When the mode draws its own tab bar, the board hides its internal one.
var external_tabs: bool = false

var _tabs: HBoxContainer = null
var _board: Control = null
var _crib: Control = null
var _pin_btn: Button = null
var _crib_row: HBoxContainer = null
var _tray_scroll: float = 0.0
var _press: Dictionary = {}
var _drag_tile: String = ""
var _drag_pos: Vector2 = Vector2.ZERO
var _hover_slot: int = -1
var _squash: Dictionary = {} # plain -> float scale boost
var _crib_drag_x: float = -1.0
var _crib_drag_offset: int = 0


func _ready() -> void:
	tool_id = "substitution_board"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(360, 420)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	box.add_child(_tabs)
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(2):
		var b: Button = Button.new()
		b.text = tr("UI_BOARD_TAB") if i == 0 else tr("UI_CRIB_TAB")
		b.toggle_mode = true
		b.button_group = g
		b.button_pressed = i == 0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			tab = i
			_sync_tabs())
		_tabs.add_child(b)
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.mouse_filter = Control.MOUSE_FILTER_STOP
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_board_input)
	box.add_child(_board)
	_crib = Control.new()
	_crib.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_crib.mouse_filter = Control.MOUSE_FILTER_STOP
	_crib.draw.connect(_draw_crib)
	_crib.gui_input.connect(_crib_input)
	box.add_child(_crib)
	var crib_row: HBoxContainer = HBoxContainer.new()
	crib_row.add_theme_constant_override("separation", 10)
	_crib_row = crib_row
	box.add_child(crib_row)
	for spec: Array in [["<<", -5], ["<", -1], [">", 1], [">>", 5]]:
		var nb: Button = Button.new()
		nb.text = spec[0]
		nb.custom_minimum_size = Vector2(130, 130)
		var step: int = spec[1]
		nb.pressed.connect(func() -> void: _move_crib(crib_offset + step))
		crib_row.add_child(nb)
	_pin_btn = Button.new()
	_pin_btn.text = tr("UI_CRIB_PIN")
	_pin_btn.theme_type_variation = "RubricButton"
	_pin_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pin_btn.pressed.connect(func() -> void: crib_pin_requested.emit(crib_offset))
	crib_row.add_child(_pin_btn)
	set_process(false)
	_sync_tabs()


func configure_crib(text: String, cipher_text: String) -> void:
	crib_enabled = text != ""
	crib_text = text
	crib_window = cipher_text
	_sync_tabs()


func set_tiles(t: Array[Dictionary]) -> void:
	tiles = t
	_board.queue_redraw()


func set_mapping(m: Dictionary) -> void:
	mapping = m.duplicate()
	_board.queue_redraw()


func set_crib_status(status: PackedInt32Array, fits: bool) -> void:
	crib_status = status
	crib_fits = fits
	_pin_btn.disabled = not fits
	_crib.queue_redraw()


func select(cipher: String) -> void:
	selected = cipher
	_board.queue_redraw()


func is_complete() -> bool:
	for t: Dictionary in tiles:
		if not mapping.has(str(t["c"])):
			return false
	return true


func get_state() -> Dictionary:
	return {"mapping": mapping.duplicate(), "locks": locks.keys(), "tab": tab, "crib_offset": crib_offset, "selected": selected}


func set_state(d: Dictionary) -> void:
	mapping = {}
	var m: Dictionary = d.get("mapping", {})
	for k: Variant in m.keys():
		mapping[str(k)] = str(m[k])
	locks = {}
	for l: Variant in d.get("locks", []):
		locks[str(l)] = true
	tab = int(d.get("tab", 0))
	crib_offset = int(d.get("crib_offset", 0))
	selected = str(d.get("selected", ""))
	_sync_tabs()
	mapping_changed.emit()
	crib_moved.emit(crib_offset)
	_board.queue_redraw()


func _sync_tabs() -> void:
	if _tabs == null:
		return
	_tabs.visible = crib_enabled and not external_tabs
	if not crib_enabled:
		tab = 0
	var i: int = 0
	for b: Node in _tabs.get_children():
		(b as Button).set_pressed_no_signal(i == tab)
		i += 1
	_board.visible = tab == 0
	_crib.visible = tab == 1
	_crib_row.visible = tab == 1
	_board.queue_redraw()
	_crib.queue_redraw()


# ---------------------------------------------------------------- board geometry

func _tray_rect() -> Rect2:
	return Rect2(0, 0, _board.size.x, 150)


func _tile_w() -> float:
	return 128.0


func _slot_rect(i: int) -> Rect2:
	var top: float = 170.0
	var w: float = _board.size.x / COLS
	var rows: int = 4
	var h: float = minf(150.0, (_board.size.y - top) / rows)
	@warning_ignore("integer_division")
	var row: int = i / COLS
	var col: int = i % COLS
	var x0: float = 0.0
	if row == 3:
		x0 = w # centre the last row of five
	return Rect2(x0 + col * w + 4, top + row * h + 4, w - 8, h - 8)


func _tray_tile_rect(k: int) -> Rect2:
	return Rect2(8 + k * (_tile_w() + 10) - _tray_scroll, 10, _tile_w(), 130)


func _slot_at(p: Vector2) -> int:
	var best: int = -1
	var best_d: float = 110.0
	for i: int in range(26):
		var r: Rect2 = _slot_rect(i)
		if r.has_point(p):
			return i
		var d: float = r.get_center().distance_to(p)
		if d < best_d:
			best_d = d
			best = i
	return best


func _tile_at(p: Vector2) -> int:
	if not _tray_rect().has_point(p):
		return -1
	for k: int in range(tiles.size()):
		if _tray_tile_rect(k).has_point(p):
			return k
	return -1


func _plain_of(cipher: String) -> String:
	return str(mapping.get(cipher, ""))


func _cipher_in_slot(plain: String) -> String:
	for c: Variant in mapping.keys():
		if str(mapping[c]) == plain:
			return str(c)
	return ""


# ---------------------------------------------------------------- board input

func _board_input(event: InputEvent) -> void:
	if ToolBase.is_press(event):
		var p: Vector2 = ToolBase.press_pos(event)
		_press = {"pos": p, "time": 0.0, "moved": false, "tile": _tile_at(p), "slot": -1, "scroll0": _tray_scroll, "long": false}
		if int(_press["tile"]) < 0 and p.y > 160.0:
			var s: int = _slot_at(p)
			if s >= 0 and _slot_rect(s).has_point(p):
				_press["slot"] = s
		set_process(true)
	elif ToolBase.is_drag(event) and not _press.is_empty():
		var p2: Vector2 = ToolBase.drag_pos(event)
		var d: Vector2 = p2 - Vector2(_press["pos"])
		if _drag_tile != "":
			_drag_pos = p2
			_hover_slot = _slot_at(p2) if p2.y > 150.0 else -1
			_board.queue_redraw()
			return
		if d.length() > DRAG_THRESHOLD:
			_press["moved"] = true
			var tk: int = int(_press["tile"])
			if tk >= 0 and absf(d.y) > absf(d.x):
				_begin_drag(str(tiles[tk]["c"]), p2)
			elif tk >= 0 or Vector2(_press["pos"]).y < 150.0:
				_tray_scroll = clampf(float(_press["scroll0"]) - d.x, 0.0, maxf(0.0, tiles.size() * (_tile_w() + 10) + 16 - _board.size.x))
				_board.queue_redraw()
			elif int(_press["slot"]) >= 0:
				var plain: String = String.chr(65 + int(_press["slot"]))
				var c: String = _cipher_in_slot(plain)
				if c != "" and not locks.has(plain):
					_begin_drag(c, p2)
	elif ToolBase.is_release(event) and not _press.is_empty():
		set_process(false)
		var p3: Vector2 = ToolBase.press_pos(event)
		if _drag_tile != "":
			_end_drag(p3)
		elif not bool(_press["moved"]) and not bool(_press["long"]):
			_tap(p3)
		_press = {}


func _process(delta: float) -> void:
	if _press.is_empty():
		set_process(false)
		return
	_press["time"] = float(_press["time"]) + delta
	if not bool(_press["moved"]) and not bool(_press["long"]) and float(_press["time"]) >= LONG_PRESS and int(_press["slot"]) >= 0:
		_press["long"] = true
		var plain: String = String.chr(65 + int(_press["slot"]))
		if _cipher_in_slot(plain) != "":
			snapshot()
			if locks.has(plain):
				locks.erase(plain)
			else:
				locks[plain] = true
			EventBus.sfx.emit("tile_snap")
			EventBus.haptic.emit("pulse")
			state_changed.emit()
			_board.queue_redraw()


func _tap(p: Vector2) -> void:
	var tk: int = _tile_at(p)
	if tk >= 0:
		selected = str(tiles[tk]["c"])
		EventBus.sfx.emit("tick")
		tile_selected.emit(selected)
		_board.queue_redraw()
		return
	var s: int = _slot_at(p)
	if s < 0 or not _slot_rect(s).grow(12.0).has_point(p):
		return
	var plain: String = String.chr(65 + s)
	if selected != "":
		_place(selected, plain)
		return
	var c: String = _cipher_in_slot(plain)
	if c != "":
		selected = c
		tile_selected.emit(c)
		_board.queue_redraw()


func _begin_drag(cipher: String, p: Vector2) -> void:
	_drag_tile = cipher
	_drag_pos = p
	selected = cipher
	tile_selected.emit(cipher)
	EventBus.sfx.emit("tick")
	_board.queue_redraw()


func _end_drag(p: Vector2) -> void:
	var cipher: String = _drag_tile
	_drag_tile = ""
	_hover_slot = -1
	if p.y < 150.0:
		_unplace(cipher)
	else:
		var s: int = _slot_at(p)
		if s >= 0:
			_place(cipher, String.chr(65 + s))
	_board.queue_redraw()


func _place(cipher: String, plain: String) -> void:
	var existing: String = _cipher_in_slot(plain)
	if locks.has(plain) or (mapping.has(cipher) and locks.has(_plain_of(cipher))):
		EventBus.sfx.emit("wrong_soft")
		EventBus.haptic.emit("thud")
		return
	if existing == cipher:
		return
	snapshot()
	if existing != "":
		mapping.erase(existing)
	mapping[cipher] = plain
	_squash[plain] = 1.0
	if not Settings.clear_mind:
		var tw: Tween = create_tween()
		tw.tween_method(func(v: float) -> void:
			_squash[plain] = v
			_board.queue_redraw(), 1.0, 0.0, 0.25)
	EventBus.sfx.emit("tile_snap")
	EventBus.haptic.emit("snap")
	mapping_changed.emit()
	state_changed.emit()
	_board.queue_redraw()


func _unplace(cipher: String) -> void:
	if not mapping.has(cipher) or locks.has(_plain_of(cipher)):
		return
	snapshot()
	mapping.erase(cipher)
	EventBus.sfx.emit("page_turn")
	mapping_changed.emit()
	state_changed.emit()


# ---------------------------------------------------------------- board drawing

func _draw_board() -> void:
	if _board.size.x < 200.0 or _board.size.y < 300.0:
		return
	var f: Font = ThemeBuilder.font("mono_bold")
	var small: Font = ThemeBuilder.font("semibold")
	_board.draw_rect(_tray_rect(), Color(0.1, 0.07, 0.05, 0.9))
	_board.draw_rect(_tray_rect(), Palette.GOLD, false, 2.0)
	for k: int in range(tiles.size()):
		var r: Rect2 = _tray_tile_rect(k)
		if r.end.x < 0.0 or r.position.x > _board.size.x:
			continue
		var c: String = str(tiles[k]["c"])
		var placed: bool = mapping.has(c)
		_tile(r, c, c == selected, placed, f)
		var sub: String = ("=" + _plain_of(c)) if placed else str(int(tiles[k]["n"]))
		_board.draw_string(small, r.position + Vector2(8, r.size.y - 10), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.INK_FADED if not placed else Palette.RUBRIC)
	for i: int in range(26):
		var plain: String = String.chr(65 + i)
		var r2: Rect2 = _slot_rect(i)
		var c2: String = _cipher_in_slot(plain)
		var hl: bool = i == _hover_slot
		_board.draw_rect(r2, Color(0.93, 0.88, 0.76, 0.95) if not hl else Palette.GOLD_LIGHT)
		_board.draw_rect(r2, Palette.GOLD_TEXT, false, 2.0)
		_board.draw_string(small, r2.position + Vector2(8, 34), plain, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Palette.INK)
		if c2 != "":
			var boost: float = float(_squash.get(plain, 0.0))
			var tr2: Rect2 = Rect2(r2.position + Vector2(r2.size.x * 0.28, 10), Vector2(r2.size.x * 0.66, r2.size.y - 20))
			tr2 = tr2.grow_individual(boost * 6.0, -boost * 6.0, boost * 6.0, -boost * 6.0)
			_tile(tr2, c2, c2 == selected, false, f)
			if locks.has(plain):
				_lock_icon(r2.position + Vector2(10, r2.size.y - 40))
		elif selected != "":
			_board.draw_rect(r2.grow(-6.0), Color(Palette.GOLD, 0.12))
	if _drag_tile != "":
		var dr: Rect2 = Rect2(_drag_pos - Vector2(60, 110), Vector2(120, 130))
		_board.draw_rect(dr.grow(6.0), Color(0, 0, 0, 0.35))
		_tile(dr, _drag_tile, true, false, f)


func _tile(r: Rect2, c: String, sel: bool, dim: bool, f: Font) -> void:
	var bg: Color = Color("f3e8cf") if not dim else Color("a89878")
	_board.draw_rect(r, bg)
	_board.draw_rect(r, Palette.GOLD_LIGHT if sel else Palette.GOLD_TEXT, false, 5.0 if sel else 2.0)
	var fs: int = int(minf(r.size.y * 0.55, 64.0))
	var w: float = f.get_char_size(c.unicode_at(0), fs).x
	_board.draw_char(f, Vector2(r.position.x + (r.size.x - w) * 0.5, r.position.y + r.size.y * 0.5 + fs * 0.34), c, fs, Palette.RUBRIC if not dim else Palette.INK_FADED)


func _lock_icon(p: Vector2) -> void:
	_board.draw_rect(Rect2(p + Vector2(0, 12), Vector2(26, 20)), Palette.INK)
	_board.draw_arc(p + Vector2(13, 12), 9.0, PI, TAU, 10, Palette.INK, 4.0)


# ---------------------------------------------------------------- crib view

func _move_crib(o: int) -> void:
	var maxo: int = maxi(0, crib_window.length() - crib_text.length())
	var n: int = clampi(o, 0, maxo)
	if n == crib_offset:
		return
	crib_offset = n
	EventBus.sfx.emit("tick")
	EventBus.haptic.emit("tick")
	crib_moved.emit(crib_offset)
	state_changed.emit()
	_crib.queue_redraw()


func _crib_cell_w() -> float:
	return 58.0


func _draw_crib() -> void:
	var f: Font = ThemeBuilder.font("mono_bold")
	var w: float = _crib.size.x
	var h: float = _crib.size.y
	_crib.draw_rect(Rect2(0, 0, w, h), Color(0.1, 0.07, 0.05, 0.9))
	var cw: float = _crib_cell_w()
	var visible_cells: int = int(w / cw)
	var start: int = clampi(crib_offset - 2, 0, maxi(0, crib_window.length() - visible_cells))
	var y1: float = h * 0.3
	var y2: float = h * 0.62
	var lf: Font = ThemeBuilder.font("italic")
	_crib.draw_string(lf, Vector2(10, 44), tr("UI_CRIB_LETTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.ON_DARK_FADED)
	_crib.draw_string(lf, Vector2(10, h - 20), tr("UI_CRIB_HELP"), HORIZONTAL_ALIGNMENT_LEFT, w - 20.0, 30, Palette.ON_DARK_FADED)
	for k: int in range(visible_cells):
		var idx: int = start + k
		if idx >= crib_window.length():
			break
		var x: float = k * cw
		var ch: String = crib_window[idx]
		if ch == "\n":
			ch = " "
		_crib.draw_char(f, Vector2(x + 12, y1), ch, 46, Color("f0b8a8"))
		var ci: int = idx - crib_offset
		if ci >= 0 and ci < crib_text.length():
			var st: int = crib_status[ci] if ci < crib_status.size() else 1
			var box: Rect2 = Rect2(x + 2, y1 + 14, cw - 4, 90)
			_crib.draw_rect(box, Color("efe3c8") if st != 0 else Color("e8b4a4"))
			_crib.draw_rect(box, Palette.GOLD if crib_fits else Palette.GOLD_TEXT, false, 3.0 if crib_fits else 1.5)
			_crib.draw_char(f, Vector2(x + 12, y1 + 76), crib_text[ci], 46, Palette.INK)
			if st == 0:
				# A cross (shape, not only colour) marks a contradiction.
				var cc: Vector2 = Vector2(x + cw * 0.5, y1 + 118)
				_crib.draw_line(cc + Vector2(-10, -10), cc + Vector2(10, 10), Palette.RUBRIC, 5.0)
				_crib.draw_line(cc + Vector2(-10, 10), cc + Vector2(10, -10), Palette.RUBRIC, 5.0)
	if crib_fits:
		_crib.draw_string(ThemeBuilder.font("semibold"), Vector2(10, y2 + 110), tr("UI_CRIB_FITS"), HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Palette.GOLD_LIGHT)


func _crib_input(event: InputEvent) -> void:
	if ToolBase.is_press(event):
		_crib_drag_x = ToolBase.press_pos(event).x
		_crib_drag_offset = crib_offset
	elif ToolBase.is_drag(event) and _crib_drag_x >= 0.0:
		var dx: float = ToolBase.drag_pos(event).x - _crib_drag_x
		_move_crib(_crib_drag_offset + int(round(dx / _crib_cell_w())))
	elif ToolBase.is_release(event):
		_crib_drag_x = -1.0


func coach_rect() -> Rect2:
	return _board.get_global_rect() if _board != null else get_global_rect()
