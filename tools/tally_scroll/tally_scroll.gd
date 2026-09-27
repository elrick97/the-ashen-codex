class_name TallyScroll
extends ToolBase
## Free analysis: how often each cipher letter occurs, drawn above the English baseline.
## Tabs for pairs and triples (bigrams/trigrams) when the puzzle allows, and a column
## selector when the letter is several Caesars interleaved (Vigenere).
## Tapping a bar selects that cipher letter; "Read it as E / T / A / O" asks the mode to
## act. When the mode sets an alignment (the wheel's current shift), the English row is
## drawn under the cipher letters it would stand for, so matching shapes can be seen,
## and a "shapes agree" readout (Frequency.profile_match) is shown.

signal letter_selected(index: int)
signal read_as(index: int, plain: int)
signal column_selected(column: int)
signal gram_selected(gram: String)

const TAB_LETTERS: int = 0
const TAB_BIGRAMS: int = 1
const TAB_TRIGRAMS: int = 2

var counts: PackedInt32Array = PackedInt32Array()
var english: Array[float] = []
var bigrams: Array[Dictionary] = []
var trigrams: Array[Dictionary] = []
var english_bigrams: PackedStringArray = PackedStringArray()
var english_trigrams: PackedStringArray = PackedStringArray()
var show_ngrams: bool = false
var show_read_as_e: bool = false
var read_as_e_cost: int = 0
var columns: int = 0
var column: int = -1 # -1 = whole text
var selected: int = -1
var tab: int = TAB_LETTERS
## Shift the English row is drawn at (-1 = plain A..Z order).
var align_shift: int = -1
## Profile agreement 0..1 pushed by the mode (-1 = hidden).
var match_value: float = -1.0
const READ_AS: Array[int] = [4, 19, 0, 14] # E, T, A, O

var _tabs: HBoxContainer = null
var _cols: HBoxContainer = null
var _cols_scroll: ScrollContainer = null
var _chart: Control = null
var _info: Label = null
var _read_row: HBoxContainer = null
var _read_label: Label = null
var _grams: HBoxContainer = null
var _gram_left: VBoxContainer = null
var _gram_right: VBoxContainer = null
var _tab_buttons: Array[Button] = []


func _ready() -> void:
	tool_id = "tally_scroll"
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(360, 420)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	box.add_child(_tabs)
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(3):
		var b: Button = Button.new()
		b.text = tr(["UI_TALLY_LETTERS", "UI_TALLY_PAIRS", "UI_TALLY_TRIPLES"][i])
		b.toggle_mode = true
		b.button_group = g
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_tab.bind(i))
		_tabs.add_child(b)
		_tab_buttons.append(b)
	_cols_scroll = ScrollContainer.new()
	_cols_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cols_scroll.custom_minimum_size = Vector2(0, 150)
	box.add_child(_cols_scroll)
	_cols = HBoxContainer.new()
	_cols.add_theme_constant_override("separation", 8)
	_cols_scroll.add_child(_cols)
	_chart = Control.new()
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chart.custom_minimum_size = Vector2(0, 300)
	_chart.mouse_filter = Control.MOUSE_FILTER_STOP
	_chart.draw.connect(_draw_chart)
	_chart.gui_input.connect(_chart_input)
	box.add_child(_chart)
	_grams = HBoxContainer.new()
	_grams.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grams.add_theme_constant_override("separation", 24)
	box.add_child(_grams)
	_gram_left = VBoxContainer.new()
	_gram_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grams.add_child(_gram_left)
	_gram_right = VBoxContainer.new()
	_gram_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grams.add_child(_gram_right)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_info = Label.new()
	_info.theme_type_variation = "LightSmallLabel"
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_info)
	_read_row = HBoxContainer.new()
	_read_row.add_theme_constant_override("separation", 8)
	box.add_child(_read_row)
	_read_label = Label.new()
	_read_label.theme_type_variation = "LightLabel"
	_read_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_read_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_read_row.add_child(_read_label)
	for plain: int in READ_AS:
		var b: Button = Button.new()
		b.text = String.chr(65 + plain)
		b.theme_type_variation = "RubricButton" if plain == 4 else ""
		b.custom_minimum_size = Vector2(118, 124)
		b.pressed.connect(func() -> void:
			if selected >= 0:
				read_as.emit(selected, plain))
		_read_row.add_child(b)
	_refresh()


func configure(p_show_ngrams: bool, p_show_read_as_e: bool, p_cost: int) -> void:
	show_ngrams = p_show_ngrams
	show_read_as_e = p_show_read_as_e
	read_as_e_cost = p_cost
	_refresh()


func set_english(freqs: Array[float], top_bigrams: PackedStringArray, top_trigrams: PackedStringArray) -> void:
	english = freqs
	english_bigrams = top_bigrams
	english_trigrams = top_trigrams
	_refresh()


func set_counts(c: PackedInt32Array) -> void:
	counts = c
	_refresh()


func set_ngrams(bi: Array[Dictionary], tri: Array[Dictionary]) -> void:
	bigrams = bi
	trigrams = tri
	_refresh()


## The English row slides with the wheel; `m` is the shapes-agree score (or -1).
func set_alignment(shift: int, m: float) -> void:
	align_shift = shift
	match_value = m
	_refresh()


func set_columns(n: int) -> void:
	columns = n
	if column >= columns:
		column = -1
	_rebuild_columns()
	_refresh()


func select_letter(i: int) -> void:
	selected = i
	_refresh()


func get_state() -> Dictionary:
	return {"tab": tab, "column": column, "selected": selected}


func set_state(d: Dictionary) -> void:
	tab = int(d.get("tab", TAB_LETTERS))
	column = int(d.get("column", -1))
	selected = int(d.get("selected", -1))
	_rebuild_columns()
	_refresh()
	column_selected.emit(column)


func _on_tab(i: int) -> void:
	tab = i
	EventBus.sfx.emit("page_turn")
	_refresh()


func _rebuild_columns() -> void:
	if _cols == null:
		return
	for c: Node in _cols.get_children():
		c.queue_free()
	_cols_scroll.visible = columns > 0
	if columns <= 0:
		return
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(-1, columns):
		var b: Button = Button.new()
		b.text = tr("UI_TALLY_ALL") if i < 0 else str(i + 1)
		b.toggle_mode = true
		b.button_group = g
		b.button_pressed = i == column
		b.custom_minimum_size = Vector2(120, 132)
		if i >= 0:
			b.add_theme_color_override("font_color", Palette.strand(i).lightened(0.1))
			b.add_theme_color_override("font_pressed_color", Palette.strand(i))
		b.pressed.connect(func() -> void:
			column = i
			selected = -1
			EventBus.sfx.emit("tick")
			column_selected.emit(i)
			_refresh())
		_cols.add_child(b)


func _refresh() -> void:
	if _chart == null:
		return
	_tabs.visible = show_ngrams
	for i: int in range(_tab_buttons.size()):
		_tab_buttons[i].set_pressed_no_signal(i == tab)
	_chart.visible = tab == TAB_LETTERS
	_grams.visible = tab != TAB_LETTERS
	var total: int = 0
	for v: int in counts:
		total += v
	if tab == TAB_LETTERS:
		if selected >= 0 and selected < counts.size():
			var pct: float = 100.0 * float(counts[selected]) / float(maxi(total, 1))
			_info.text = tr("UI_TALLY_SELECTED") % [String.chr(65 + selected), counts[selected], total, pct]
		else:
			_info.text = tr("UI_TALLY_TAP")
		if match_value >= 0.0:
			_info.text += "  " + tr("UI_TALLY_MATCH") % int(round(match_value * 100.0))
		_read_row.visible = show_read_as_e and selected >= 0
		if selected >= 0:
			_read_label.text = (tr("UI_TALLY_READ_AS_COST") % [String.chr(65 + selected), read_as_e_cost]) if read_as_e_cost > 0 else (tr("UI_TALLY_READ_AS") % String.chr(65 + selected))
	else:
		_read_row.visible = false
		_info.text = tr("UI_TALLY_GRAM_HELP")
		_fill_grams()
	_chart.queue_redraw()


func _fill_grams() -> void:
	for c: Node in _gram_left.get_children():
		c.queue_free()
	for c: Node in _gram_right.get_children():
		c.queue_free()
	var mine: Array[Dictionary] = bigrams if tab == TAB_BIGRAMS else trigrams
	var theirs: PackedStringArray = english_bigrams if tab == TAB_BIGRAMS else english_trigrams
	var h1: Label = Label.new()
	h1.text = tr("UI_TALLY_IN_LETTER")
	h1.theme_type_variation = "LightSmallLabel"
	_gram_left.add_child(h1)
	var h2: Label = Label.new()
	h2.text = tr("UI_TALLY_IN_ENGLISH")
	h2.theme_type_variation = "LightSmallLabel"
	_gram_right.add_child(h2)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_gram_left.add_child(grid)
	for i: int in range(mini(6, mine.size())):
		var gram: String = str(mine[i]["gram"])
		var b: Button = Button.new()
		b.text = "%s  %d" % [gram, int(mine[i]["count"])]
		b.add_theme_font_override("font", ThemeBuilder.font("mono_bold"))
		b.add_theme_font_size_override("font_size", ThemeBuilder.size(34))
		b.add_theme_color_override("font_color", Palette.RUBRIC)
		b.custom_minimum_size = Vector2(0, 96)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: gram_selected.emit(gram))
		grid.add_child(b)
	var eng: Label = Label.new()
	eng.text = "\n".join(theirs.slice(0, 6))
	eng.theme_type_variation = "LightLabel"
	eng.add_theme_font_override("font", ThemeBuilder.font("mono_bold"))
	eng.add_theme_font_size_override("font_size", ThemeBuilder.size(38))
	_gram_right.add_child(eng)


func _chart_geom() -> Dictionary:
	var w: float = _chart.size.x
	var h: float = _chart.size.y
	var bw: float = w / 26.0
	return {"w": w, "h": h, "bw": bw, "top_h": h * 0.5, "label_h": 40.0}


func _draw_chart() -> void:
	if _chart.size.x < 130.0 or _chart.size.y < 120.0:
		return
	var g: Dictionary = _chart_geom()
	var w: float = g["w"]
	var h: float = g["h"]
	var bw: float = g["bw"]
	var f: Font = ThemeBuilder.font("mono_bold")
	var fs: int = int(minf(bw * 0.8, 36.0))
	_chart.draw_rect(Rect2(0, 0, w, h), Color(0.08, 0.06, 0.05, 0.85))
	var total: int = 0
	var maxc: int = 1
	for v: int in counts:
		total += v
		maxc = maxi(maxc, v)
	var half: float = h * 0.5
	var bar_area: float = half - 50.0
	var max_share: float = maxf(0.13, float(maxc) / float(maxi(total, 1)))
	# Top: this letter
	for i: int in range(26):
		var x: float = i * bw
		var share: float = float(counts[i]) / float(maxi(total, 1)) if i < counts.size() else 0.0
		var bh: float = bar_area * share / max_share
		var col: Color = Palette.GOLD_LIGHT if i == selected else Palette.BLOOD.lightened(0.1)
		_chart.draw_rect(Rect2(x + 3, half - 44.0 - bh, bw - 6, bh), col)
		var ch: String = String.chr(65 + i)
		var cw: float = f.get_char_size(ch.unicode_at(0), fs).x
		_chart.draw_char(f, Vector2(x + (bw - cw) * 0.5, half - 12.0), ch, fs, Palette.GOLD_LIGHT if i == selected else Color("f0b8a8"))
		if i == selected:
			_chart.draw_rect(Rect2(x + 1, 6, bw - 2, half - 12), Palette.GOLD_LIGHT, false, 3.0)
	# Bottom: English baseline. Aligned: under cipher letter i sits the English letter it
	# would stand for at the wheel's current shift, so matching shapes line up.
	for i: int in range(26):
		var x2: float = i * bw
		var p: int = posmod(i - align_shift, 26) if align_shift >= 0 else i
		var e: float = english[p] if p < english.size() else 0.0
		var bh2: float = bar_area * e / max_share
		_chart.draw_rect(Rect2(x2 + 3, half + 44.0, bw - 6, bh2), Color(Palette.VELLUM_SHADOW, 0.9) if align_shift < 0 else Color("c9b27c"))
		var ch2: String = String.chr(65 + p)
		var cw2: float = f.get_char_size(ch2.unicode_at(0), fs).x
		_chart.draw_char(f, Vector2(x2 + (bw - cw2) * 0.5, half + 34.0), ch2, fs, Palette.ON_DARK)
	_chart.draw_line(Vector2(0, half), Vector2(w, half), Palette.GOLD, 2.0)
	var lf: Font = ThemeBuilder.font("italic")
	var lfs: int = ThemeBuilder.size(30)
	_chart.draw_string(lf, Vector2(8, 34), tr("UI_TALLY_THIS_LETTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, lfs, Palette.ON_DARK_FADED)
	_chart.draw_string(lf, Vector2(8, h - 12), tr("UI_TALLY_ENGLISH_ALIGNED") if align_shift >= 0 else tr("UI_TALLY_ENGLISH"), HORIZONTAL_ALIGNMENT_LEFT, -1, lfs, Palette.ON_DARK_FADED)


func _chart_input(event: InputEvent) -> void:
	if not ToolBase.is_press(event):
		return
	var g: Dictionary = _chart_geom()
	var p: Vector2 = ToolBase.press_pos(event)
	if p.y > float(g["h"]) * 0.5:
		return
	var i: int = clampi(int(p.x / float(g["bw"])), 0, 25)
	snapshot()
	selected = i
	EventBus.sfx.emit("tick")
	EventBus.haptic.emit("tick")
	letter_selected.emit(i)
	state_changed.emit()
	_refresh()


func coach_rect() -> Rect2:
	return _chart.get_global_rect() if _chart != null else get_global_rect()
