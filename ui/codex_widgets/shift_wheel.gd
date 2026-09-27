extends VBoxContainer
## Codex widget: a small Cipher Wheel over a sample line. Turn it and watch the reading.

const SAMPLE: String = "WKH EORRG LV RZHG"

var _card: InterlinearText = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var hint: Label = Label.new()
	hint.text = tr("UI_WIDGET_SHIFT_HELP")
	hint.theme_type_variation = "SmallLabel"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	_card = InterlinearText.new()
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_card)
	var wheel: CipherWheel = (load("res://tools/cipher_wheel/cipher_wheel.tscn") as PackedScene).instantiate() as CipherWheel
	wheel.custom_minimum_size = Vector2(0, 620)
	add_child(wheel)
	wheel.shift_changed.connect(func(s: int) -> void: _card.set_pair(SAMPLE, Caesar.decrypt(SAMPLE, s)))
	_card.set_pair(SAMPLE, SAMPLE)
