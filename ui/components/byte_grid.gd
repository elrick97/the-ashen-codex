class_name ByteGrid
extends Control
## Bytes as a grid of cells: hex on top, the ASCII reading beneath (a dot for
## unprintable bytes). Optional second row set (`reading`) replaces the ASCII line,
## e.g. a decryption preview. Sizes its own height; tap emits cell_pressed.

signal cell_pressed(index: int)

@export var base_font_size: int = 30
@export var show_hex: bool = true

var data: PackedByteArray = PackedByteArray()
## Optional bytes drawn on the lower line instead of data's own ASCII.
var reading: PackedByteArray = PackedByteArray()
var highlights: Dictionary = {}   # index -> Color
var reading_colors: Dictionary = {} # index -> Color
var unknown_reading: Dictionary = {} # index -> true: draw a blank dash

var _cell: Vector2 = Vector2(60, 80)
var _cols: int = 8
var _hex_size: int = 26
var _txt_size: int = 34


func _ready() -> void:
	resized.connect(_relayout)
	EventBus.settings_changed.connect(_relayout)


func set_bytes(d: PackedByteArray, r: PackedByteArray = PackedByteArray()) -> void:
	data = d
	reading = r
	_relayout()


func set_reading(r: PackedByteArray) -> void:
	reading = r
	queue_redraw()


func cell_rect(i: int) -> Rect2:
	@warning_ignore("integer_division")
	var row: int = i / _cols
	return Rect2(Vector2((i % _cols) * _cell.x, row * _cell.y), _cell)


func _relayout() -> void:
	var s: float = Settings.text_scale()
	_hex_size = int(base_font_size * 0.8 * s)
	_txt_size = int(base_font_size * 1.1 * s)
	var f: Font = ThemeBuilder.font("mono")
	var cw: float = f.get_char_size(77, _hex_size).x * 2.0 + 12.0
	_cell = Vector2(cw, (_hex_size * 1.2 if show_hex else 0.0) + _txt_size * 1.25 + 8.0)
	_cols = maxi(1, int(maxf(size.x, cw) / cw))
	var rows: int = ceili(float(data.size()) / float(_cols))
	custom_minimum_size.y = maxf(1.0, float(rows)) * _cell.y
	queue_redraw()


func _draw() -> void:
	var f: Font = ThemeBuilder.font("mono")
	var fb: Font = ThemeBuilder.font("mono_bold")
	for i: int in range(data.size()):
		var r: Rect2 = cell_rect(i)
		if highlights.has(i):
			draw_rect(r.grow(-2.0), highlights[i])
		var y: float = r.position.y + 4.0
		if show_hex:
			var hx: String = BytesUtil.byte_to_hex(data[i])
			var hw: float = f.get_string_size(hx, HORIZONTAL_ALIGNMENT_LEFT, -1, _hex_size).x
			draw_string(f, Vector2(r.position.x + (r.size.x - hw) * 0.5, y + f.get_ascent(_hex_size)), hx, HORIZONTAL_ALIGNMENT_LEFT, -1, _hex_size, Palette.RUBRIC)
			y += _hex_size * 1.2
		var b: int = reading[i] if i < reading.size() else data[i]
		var cx: float = r.position.x + r.size.x * 0.5
		var base_y: float = y + f.get_ascent(_txt_size)
		if unknown_reading.has(i):
			draw_line(Vector2(cx - 10, base_y), Vector2(cx + 10, base_y), Color(Palette.INK_FADED, 0.5), 2.0)
			continue
		var ch: String = String.chr(b) if b >= 33 and b <= 126 else ("_" if b == 32 else ".")
		var col: Color = reading_colors.get(i, Palette.INK if (b >= 32 and b <= 126) else Color(Palette.INK_FADED, 0.6))
		if b == 32:
			col = Color(Palette.INK_FADED, 0.35)
		var w: float = fb.get_char_size(ch.unicode_at(0), _txt_size).x
		draw_char(fb, Vector2(cx - w * 0.5, base_y), ch, _txt_size, col)


func _gui_input(event: InputEvent) -> void:
	if not ToolBase.is_press(event):
		return
	var pos: Vector2 = ToolBase.press_pos(event)
	for i: int in range(data.size()):
		if cell_rect(i).has_point(pos):
			cell_pressed.emit(i)
			return
