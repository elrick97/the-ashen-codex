class_name DropCap
extends Control
## An illuminated initial: blackletter capital in rubric on vellum, inside a gold frame
## with a procedurally drawn vine-and-knot border (arcs and leaves from line primitives).

@export var letter: String = "A"
@export var seed_value: int = 1


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(170, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size).grow(-4.0)
	draw_rect(r, Color("efe3c8"))
	draw_rect(r.grow(-10.0), Color(Palette.GOLD, 0.16))
	draw_rect(r, Palette.GOLD, false, 5.0)
	draw_rect(r.grow(-12.0), Palette.GOLD_TEXT, false, 2.0)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	# Vine: a wavy stem around the inner frame with leaves and knots at the corners.
	var inner: Rect2 = r.grow(-22.0)
	var pts: PackedVector2Array = _perimeter(inner, 64)
	var vine: PackedVector2Array = PackedVector2Array()
	for i: int in range(pts.size()):
		var p: Vector2 = pts[i]
		var n: Vector2 = (p - inner.get_center()).normalized()
		vine.append(p + n * sin(float(i) * 0.9) * 5.0)
	vine.append(vine[0])
	draw_polyline(vine, Color("3f5a24"), 3.0, true)
	for i: int in range(0, pts.size(), 4):
		var p: Vector2 = vine[i]
		var dir: Vector2 = (vine[(i + 1) % vine.size()] - p).normalized().rotated(0.9 if i % 8 == 0 else -0.9)
		var leaf: PackedVector2Array = PackedVector2Array([p, p + dir * 9.0 + dir.orthogonal() * 4.0, p + dir * 15.0, p + dir * 9.0 - dir.orthogonal() * 4.0])
		draw_colored_polygon(leaf, Color("56752f"))
	for c: Vector2 in [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]:
		draw_arc(c, 10.0, 0.0, TAU, 16, Palette.RUBRIC, 3.0)
		draw_arc(c, 5.0, 0.0, TAU, 12, Palette.GOLD, 2.0)
		if rng.randf() < 0.7:
			draw_circle(c, 2.5, Palette.GOLD_LIGHT)
	var f: Font = ThemeBuilder.font("fraktur")
	var fs: int = int(minf(size.x, size.y) * 0.66)
	var w: float = f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base: Vector2 = Vector2((size.x - w) * 0.5, size.y * 0.5 + f.get_ascent(fs) * 0.38)
	draw_string(f, base + Vector2(3, 3), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.25))
	draw_string(f, base, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Palette.RUBRIC)


static func _perimeter(r: Rect2, n: int) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var per: float = 2.0 * (r.size.x + r.size.y)
	for i: int in range(n):
		var d: float = per * float(i) / float(n)
		if d < r.size.x:
			out.append(r.position + Vector2(d, 0))
		elif d < r.size.x + r.size.y:
			out.append(r.position + Vector2(r.size.x, d - r.size.x))
		elif d < 2.0 * r.size.x + r.size.y:
			out.append(r.position + Vector2(r.size.x - (d - r.size.x - r.size.y), r.size.y))
		else:
			out.append(r.position + Vector2(0, r.size.y - (d - 2.0 * r.size.x - r.size.y)))
	return out
