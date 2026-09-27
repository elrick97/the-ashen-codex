extends VBoxContainer
## Codex widget: flip the beads of a letter and of a key; the chalice shows their XOR,
## and pouring the key a second time brings the letter back.

var _rosary: BitRosary = null
var _a: int = 72 # H
var _k: int = 0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var hint: Label = Label.new()
	hint.text = tr("UI_WIDGET_XOR_HELP")
	hint.theme_type_variation = "SmallLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	_rosary = (load("res://tools/bit_rosary/bit_rosary.tscn") as PackedScene).instantiate() as BitRosary
	_rosary.custom_minimum_size = Vector2(0, 700)
	add_child(_rosary)
	_rosary.bead_flipped.connect(func(row: int, bit: int) -> void:
		if row == 0:
			_a ^= 1 << bit
		elif row == 1:
			_k ^= 1 << bit
		_push())
	_push()


func _push() -> void:
	var once: int = _a ^ _k
	_rosary.set_rows([
		{"label": "UI_ROSARY_A", "value": _a, "editable": true, "kind": "given"},
		{"label": "UI_ROSARY_KEY", "value": _k, "editable": true, "kind": "key"},
		{"label": "UI_ROSARY_RESULT", "value": once, "kind": "result"},
		{"label": "UI_WIDGET_XOR_TWICE", "value": once ^ _k, "kind": "target"}])
