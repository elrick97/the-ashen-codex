extends VBoxContainer
## Codex widget: the Tally Scroll over a sample paragraph, with a shift slider so the
## reader can watch the whole profile slide while its shape stays the same.

const SAMPLE: String = "The tithe is taken at the new moon and the steward counts every head in the village twice before the carts are loaded and the reeds are searched for those who ran"

var _tally: TallyScroll = null
var _label: Label = null


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	_label = Label.new()
	_label.theme_type_variation = "SmallLabel"
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)
	var slider: HSlider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 25
	slider.step = 1
	slider.custom_minimum_size = Vector2(0, 110)
	add_child(slider)
	_tally = (load("res://tools/tally_scroll/tally_scroll.tscn") as PackedScene).instantiate() as TallyScroll
	_tally.custom_minimum_size = Vector2(0, 520)
	add_child(_tally)
	_tally.set_english(Frequency.ENGLISH, Frequency.COMMON_BIGRAMS, Frequency.COMMON_TRIGRAMS)
	slider.value_changed.connect(func(v: float) -> void: _show(int(v)))
	_show(0)


func _show(shift: int) -> void:
	var text: String = Caesar.encrypt(SAMPLE, shift)
	_tally.set_counts(Frequency.counts(text))
	_label.text = tr("UI_WIDGET_FREQ_HELP") % [shift, String.chr(65 + Frequency.peak(text))]
