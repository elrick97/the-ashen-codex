class_name InterlinearText
extends Control
## The letter card's text: each cipher glyph drawn small in rubric red with the
## player's reading directly beneath it in ink. Wraps at spaces, honours newlines,
## and sizes its own height (put it in a ScrollContainer). Tapping a cell emits
## cell_pressed; holding emits cell_long_pressed (the Kasiski Lens uses that).

signal cell_pressed(index: int)
signal cell_long_pressed(index: int)

const LONG_PRESS_S: float = 0.45
const UNKNOWN: String = "_"

@export var base_font_size: int = 40
@export var show_cipher: bool = true
@export var show_plain: bool = true

var cipher: String = ""
var plain: String = ""
## index -> Color drawn behind the cell.
var highlights: Dictionary = {}
## index -> Color for the reading glyph (strand colours etc.).
var plain_colors: Dictionary = {}
## index -> Color for the cipher glyph.
var cipher_colors: Dictionary = {}
## Indices drawn with a rubric underline (e.g. the selected letter everywhere it occurs).
var underlined: Dictionary = {}

var _pos: PackedVector2Array = PackedVector2Array()
var _cell: Vector2 = Vector2(24, 60)
var _cipher_size: int = 30
var _plain_size: int = 40
var _press_index: int = -1
var _press_time: float = 0.0
var _long_fired: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_relayout)
	EventBus.settings_changed.connect(_relayout)
	set_process(false)


func set_pair(cipher_text: String, plain_text: String) -> void:
	cipher = cipher_text
	plain = plain_text
	_relayout()


func set_plain(plain_text: String) -> void:
	var relayout: bool = plain_text.length() != plain.length()
	plain = plain_text
	if relayout:
		_relayout()
	else:
		queue_redraw()


func refresh() -> void:
	queue_redraw()


## Index of the cell under a local position, or -1.
func cell_at(p: Vector2) -> int:
	for i: int in range(_pos.size()):
		var q: Vector2 = _pos[i]
		if q.x < 0.0:
			continue
		if Rect2(q, _cell).has_point(p):
			return i
	return -1


## Local rect of a cell (for coach marks and lenses).
func cell_rect(i: int) -> Rect2:
	if i < 0 or i >= _pos.size() or _pos[i].x < 0.0:
		return Rect2()
	return Rect2(_pos[i], _cell)


func _font() -> Font:
	return ThemeBuilder.font("mono")


func _relayout() -> void:
	var scale_f: float = Settings.text_scale()
	_plain_size = int(base_font_size * scale_f)
	_cipher_size = int(base_font_size * 0.72 * scale_f)
	var f: Font = _font()
	var cw: float = f.get_char_size(77, _plain_size).x
	var rows: float = 0.0
	if show_cipher:
		rows += _cipher_size * 1.15
	if show_plain:
		rows += _plain_size * 1.2
	_cell = Vector2(cw, rows + 10.0)
	var width: float = maxf(size.x, cw * 8.0)
	var cols: int = maxi(1, int(width / cw))
	var text: String = cipher if cipher.length() >= plain.length() else plain
	var n: int = text.length()
	_pos.resize(n)
	var col: int = 0
	var row: int = 0
	var i: int = 0
	while i < n:
		var ch: String = text[i]
		if ch == "\n":
			_pos[i] = Vector2(-1, -1)
			row += 1
			col = 0
			i += 1
			continue
		if ch == " ":
			if col == 0:
				_pos[i] = Vector2(-1, -1)
			else:
				_pos[i] = Vector2(col * cw, row * _cell.y)
				col += 1
			i += 1
			continue
		var j: int = i
		while j < n and text[j] != " " and text[j] != "\n":
			j += 1
		var wlen: int = j - i
		if col > 0 and col + wlen > cols:
			row += 1
			col = 0
		for k: int in range(i, j):
			if col >= cols:
				row += 1
				col = 0
			_pos[k] = Vector2(col * cw, row * _cell.y)
			col += 1
		i = j
	custom_minimum_size.y = (row + 1) * _cell.y + 8.0
	queue_redraw()


func _draw() -> void:
	var f: Font = _font()
	var asc_c: float = f.get_ascent(_cipher_size)
	var asc_p: float = f.get_ascent(_plain_size)
	var cipher_y: float = 4.0
	var plain_y: float = (_cipher_size * 1.15 if show_cipher else 0.0) + 4.0
	for i: int in range(_pos.size()):
		var p: Vector2 = _pos[i]
		if p.x < 0.0:
			continue
		if highlights.has(i):
			draw_rect(Rect2(p + Vector2(-1, 1), _cell - Vector2(-2, 4)), highlights[i])
		var c_ch: String = cipher[i] if i < cipher.length() else " "
		if c_ch == " ":
			continue
		if show_cipher:
			var cc: Color = cipher_colors.get(i, Palette.RUBRIC)
			var cx: float = p.x + (_cell.x - f.get_char_size(c_ch.unicode_at(0), _cipher_size).x) * 0.5
			draw_char(f, Vector2(cx, p.y + cipher_y + asc_c), c_ch, _cipher_size, cc)
		if show_plain:
			var p_ch: String = plain[i] if i < plain.length() else UNKNOWN
			var py: float = p.y + plain_y
			if p_ch == UNKNOWN:
				draw_line(Vector2(p.x + 4, py + asc_p), Vector2(p.x + _cell.x - 4, py + asc_p), Color(Palette.INK_FADED, 0.55), 2.0)
			elif p_ch != " ":
				var pc: Color = plain_colors.get(i, Palette.INK)
				draw_char(f, Vector2(p.x, py + asc_p), p_ch, _plain_size, pc)
		if underlined.has(i):
			var uy: float = p.y + _cell.y - 6.0
			draw_line(Vector2(p.x + 2, uy), Vector2(p.x + _cell.x - 2, uy), Palette.RUBRIC, 4.0)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = false
	var released: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event
		pressed = mb.pressed
		released = not mb.pressed
		pos = mb.position
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		pressed = st.pressed
		released = not st.pressed
		pos = st.position
	if pressed:
		_press_index = cell_at(pos)
		_press_time = 0.0
		_long_fired = false
		set_process(_press_index >= 0)
	elif released:
		set_process(false)
		if _press_index >= 0 and not _long_fired and cell_at(pos) == _press_index:
			cell_pressed.emit(_press_index)
		_press_index = -1


func _process(delta: float) -> void:
	_press_time += delta
	if _press_time >= LONG_PRESS_S and not _long_fired and _press_index >= 0:
		_long_fired = true
		cell_long_pressed.emit(_press_index)
		EventBus.haptic.emit("pulse")
		set_process(false)
