class_name WhisperLayer
extends Control
## Thirst 65+: faint whispers written in the margins of the Vault (non-critical text).
## They wobble; under Clear Mind they are still and fainter. Never over the dialogue box.

const LINES: Array[String] = ["UI_WHISPER_1", "UI_WHISPER_2", "UI_WHISPER_3", "UI_WHISPER_4", "UI_WHISPER_5", "UI_WHISPER_6"]

var _t: float = 0.0
var _items: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventBus.thirst_level_changed.connect(func(_l: int) -> void: _reseed())
	resized.connect(_reseed)
	_reseed()


func _reseed() -> void:
	_items.clear()
	if Thirst.level() < 2:
		queue_redraw()
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 99
	for i: int in range(5):
		_items.append({
			"text": tr(LINES[rng.randi() % LINES.size()]),
			"pos": Vector2(rng.randf_range(40.0, maxf(60.0, size.x - 460.0)), rng.randf_range(170.0, maxf(180.0, size.y * 0.52))),
			"rot": rng.randf_range(-0.25, 0.25),
			"phase": rng.randf() * TAU,
		})
	queue_redraw()


func _process(delta: float) -> void:
	if _items.is_empty() or Settings.clear_mind:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var f: Font = ThemeBuilder.font("italic")
	var still: bool = Settings.clear_mind
	for it: Dictionary in _items:
		var ph: float = float(it["phase"])
		var wob: float = 0.0 if still else sin(_t * 1.7 + ph) * 0.05
		var off: Vector2 = Vector2.ZERO if still else Vector2(sin(_t * 0.9 + ph) * 6.0, cos(_t * 1.1 + ph) * 4.0)
		var alpha: float = 0.28 if still else 0.3 + 0.18 * sin(_t * 0.8 + ph)
		draw_set_transform(Vector2(it["pos"]) + off, float(it["rot"]) + wob, Vector2.ONE)
		draw_string(f, Vector2.ZERO, str(it["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeBuilder.size(40), Color(Palette.BLOOD.lightened(0.2), alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
