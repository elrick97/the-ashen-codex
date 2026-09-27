extends VBoxContainer
## Codex widget: the Column Loom over a Vigenere sample (key VEIL). Slide N and watch
## the vial jump at N = 4 and its multiples.

const SAMPLE: String = "The steward writes that the tithe will be taken at the salt barn when the moon is dark and that the reeve must count the heads of every house in the village before the carts come down the causeway road"
const KEY: String = "VEIL"

var _loom: ColumnLoom = null
var _cipher: String = ""


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var hint: Label = Label.new()
	hint.text = tr("UI_WIDGET_IOC_HELP")
	hint.theme_type_variation = "SmallLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	_cipher = Vigenere.encrypt(TextUtil.letters_only(SAMPLE), KEY)
	_loom = (load("res://tools/column_loom/column_loom.tscn") as PackedScene).instantiate() as ColumnLoom
	_loom.custom_minimum_size = Vector2(0, 640)
	add_child(_loom)
	_loom.configure(12)
	_loom.n_changed.connect(_update)
	_loom.period_chosen.connect(func(_n: int) -> void: pass)
	_update(1)


func _update(n: int) -> void:
	_loom.set_strands(Vigenere.columns(_cipher, n), IndexOfCoincidence.average_column_ic(_cipher, n))
