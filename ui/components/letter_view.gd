class_name LetterView
extends VBoxContainer
## A decrypted letter (or Codex text) set as a manuscript page: an illuminated initial
## with the first few lines set beside it, then the rest at full width. Godot labels
## can't float text around a box, so the opening is split at a word boundary once the
## width is known (and again on resize / text-size change).

const CAP: float = 150.0
const LINES_BESIDE_CAP: int = 3

var _text: String = ""
var _seed: int = 1
var _font_size: int = 46
var _row: HBoxContainer = null
var _beside: Label = null
var _rest: Label = null
var _others: VBoxContainer = null
var _last_width: float = -1.0


static func make(text: String, seed_value: int) -> LetterView:
	var v: LetterView = LetterView.new()
	v._text = text.strip_edges()
	v._seed = seed_value
	v._build()
	return v


func _build() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_font_size = ThemeBuilder.size(46)
	var paras: PackedStringArray = _text.split("\n", false)
	if paras.is_empty():
		return
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 18)
	add_child(_row)
	var cap: DropCap = DropCap.new()
	cap.letter = paras[0].strip_edges().substr(0, 1).to_upper()
	cap.seed_value = _seed
	cap.custom_minimum_size = Vector2(CAP, CAP)
	cap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_row.add_child(cap)
	_beside = _label()
	_beside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_beside.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_row.add_child(_beside)
	_rest = _label()
	add_child(_rest)
	_others = VBoxContainer.new()
	_others.add_theme_constant_override("separation", 10)
	add_child(_others)
	for i: int in range(1, paras.size()):
		var p: Label = _label()
		p.text = paras[i].strip_edges()
		if i == paras.size() - 1 and paras.size() > 2 and p.text.length() < 60:
			p.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			p.add_theme_color_override("font_color", Palette.RUBRIC)
		_others.add_child(p)
	_beside.text = paras[0].strip_edges().substr(1)
	_rest.visible = false
	resized.connect(_split)


func _label() -> Label:
	var l: Label = Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", ThemeBuilder.font("fell"))
	l.add_theme_font_size_override("font_size", _font_size)
	return l


## Puts roughly LINES_BESIDE_CAP lines of the first paragraph next to the initial.
func _split() -> void:
	if _beside == null or is_equal_approx(size.x, _last_width) or size.x < 200.0:
		return
	_last_width = size.x
	var first: String = _text.split("\n", false)[0].strip_edges().substr(1)
	var f: Font = ThemeBuilder.font("fell")
	var avail: float = size.x - CAP - 18.0
	var words: PackedStringArray = first.split(" ")
	var line_w: float = 0.0
	var lines: int = 1
	var space_w: float = f.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
	var cut: int = words.size()
	for i: int in range(words.size()):
		var w: float = f.get_string_size(words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x
		if line_w > 0.0 and line_w + space_w + w > avail:
			lines += 1
			line_w = w
			if lines > LINES_BESIDE_CAP:
				cut = i
				break
		else:
			line_w += (space_w if line_w > 0.0 else 0.0) + w
	_beside.text = " ".join(words.slice(0, cut))
	_rest.text = " ".join(words.slice(cut))
	_rest.visible = _rest.text != ""
