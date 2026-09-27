class_name ThirstVial
extends Control
## The Thirst meter: a glass vial filling with blood, threshold notches, and the number.
## Red is never the only signal: the numeric value and notch marks carry the same info,
## and a fang glyph appears from the first threshold.

var value: float = 0.0
var _shown: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(250, 96)
	value = Thirst.value
	_shown = value
	EventBus.thirst_changed.connect(_on_changed)


func _on_changed(v: float, _delta: float, _reason: String) -> void:
	value = v
	var tw: Tween = create_tween()
	tw.tween_property(self, "_shown", v, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_method(func(_x: float) -> void: queue_redraw(), 0.0, 1.0, 0.5)


func _process(delta: float) -> void:
	if Thirst.level() >= 3 and not Settings.clear_mind:
		_pulse += delta * 5.0
		queue_redraw()


func _draw() -> void:
	var h: float = size.y
	var body: Rect2 = Rect2(Vector2(h * 0.62, h * 0.22), Vector2(size.x - h * 1.9, h * 0.56))
	# Glass
	draw_rect(body, Color(0.1, 0.07, 0.06, 0.85))
	var frac: float = clampf(_shown / Thirst.MAX_VALUE, 0.0, 1.0)
	var fill: Rect2 = Rect2(body.position + Vector2(3, 3), Vector2((body.size.x - 6.0) * frac, body.size.y - 6.0))
	var blood: Color = Palette.BLOOD
	if Thirst.level() >= 3 and not Settings.clear_mind:
		blood = blood.lightened(0.15 * (0.5 + 0.5 * sin(_pulse)))
	draw_rect(fill, blood)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.3)), Color(1, 1, 1, 0.12))
	draw_rect(body, Palette.GOLD, false, 3.0)
	# Stopper and bulb
	draw_circle(Vector2(h * 0.36, h * 0.5), h * 0.3, Palette.GOLD)
	draw_circle(Vector2(h * 0.36, h * 0.5), h * 0.23, Color(0.1, 0.07, 0.06))
	draw_circle(Vector2(h * 0.36, h * 0.5), h * 0.19 * clampf(frac * 3.0, 0.0, 1.0), blood)
	# Threshold notches
	for t: int in Thirst.config.thresholds:
		var x: float = body.position.x + body.size.x * float(t) / Thirst.MAX_VALUE
		draw_line(Vector2(x, body.position.y - 8), Vector2(x, body.end.y + 8), Palette.GOLD_LIGHT, 3.0)
	# Number
	var f: Font = ThemeBuilder.font("semibold")
	var fs: int = int(h * 0.5)
	var s: String = str(int(round(_shown)))
	draw_string(f, Vector2(body.end.x + 14, h * 0.5 + fs * 0.36), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.ON_DARK)
	if Thirst.level() >= 1:
		var fx: float = size.x - h * 0.3
		var fang: PackedVector2Array = PackedVector2Array([Vector2(fx - 12, h * 0.3), Vector2(fx + 12, h * 0.3), Vector2(fx, h * 0.72)])
		draw_colored_polygon(fang, Palette.ON_DARK)
