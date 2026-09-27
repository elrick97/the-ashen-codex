class_name CoachMark
extends Control
## First-use coach mark drawn as an ink annotation: a hand-drawn loop around the target,
## a curling arrow, and Kett's note. Tap anywhere to dismiss.

signal dismissed

var target: Rect2 = Rect2()
var note: String = ""
var _label: Label = null
var _t: float = 0.0


static func show_for(parent: Control, global_rect: Rect2, text: String) -> CoachMark:
	var c: CoachMark = CoachMark.new()
	c.note = text
	parent.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.target = Rect2(global_rect.position - parent.global_position, global_rect.size)
	c._build()
	return c


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label = Label.new()
	_label.text = note
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.theme_type_variation = "LightLabel"
	_label.add_theme_font_override("font", ThemeBuilder.font("italic"))
	_label.add_theme_font_size_override("font_size", ThemeBuilder.size(48))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.04, 0.9)
	sb.border_color = Palette.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(26)
	_label.add_theme_stylebox_override("normal", sb)
	add_child(_label)
	var place: Callable = func() -> void:
		var w: float = size.x - 120.0
		_label.custom_minimum_size = Vector2(w, 0)
		_label.size = Vector2(w, 0)
		var above: bool = target.position.y > size.y * 0.5
		_label.position = Vector2(60, target.position.y - 380.0 if above else target.end.y + 140.0)
		_label.position.y = clampf(_label.position.y, 60.0, size.y - 400.0)
	place.call_deferred()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	_t = minf(_t + delta * 2.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	var c: Vector2 = target.get_center()
	var rx: float = target.size.x * 0.56 + 16.0
	var ry: float = target.size.y * 0.56 + 16.0
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = int(48.0 * _t)
	for i: int in range(steps + 1):
		var a: float = -PI * 0.5 + TAU * 1.06 * float(i) / 48.0
		var wob: float = 1.0 + 0.03 * sin(a * 5.0)
		pts.append(c + Vector2(cos(a) * rx * wob, sin(a) * ry * wob))
	if pts.size() > 1:
		draw_polyline(pts, Palette.BLOOD.lightened(0.2), 7.0, true)
	if _label != null and _t >= 1.0:
		var from: Vector2 = _label.position + Vector2(_label.size.x * 0.5, 0.0 if _label.position.y > c.y else _label.size.y)
		var to: Vector2 = c + Vector2(0, ry if from.y > c.y else -ry)
		var mid: Vector2 = (from + to) * 0.5 + Vector2(90, 0)
		var curve: PackedVector2Array = PackedVector2Array()
		for i: int in range(17):
			var t: float = float(i) / 16.0
			curve.append(from.lerp(mid, t).lerp(mid.lerp(to, t), t))
		draw_polyline(curve, Palette.GOLD_LIGHT, 5.0, true)
		var dir: Vector2 = (to - curve[14]).normalized()
		draw_colored_polygon(PackedVector2Array([to, to - dir * 30.0 + dir.orthogonal() * 14.0, to - dir * 30.0 - dir.orthogonal() * 14.0]), Palette.GOLD_LIGHT)


func _gui_input(event: InputEvent) -> void:
	if ToolBase.is_press(event) and _t >= 1.0:
		accept_event()
		dismissed.emit()
		queue_free()
