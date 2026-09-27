class_name Portrait
extends Control
## Procedural silhouette portraits with a red rim-light, built from polygons.
## Speakers: isaak, kett, marquise, steward, lord, wenna, courier. "narrator" draws nothing.
## Swap-in path for painted art: res://ui/portraits/<speaker>.png (see ASSET_MANIFEST).

@export var speaker: String = "":
	set(v):
		speaker = v
		_art = null
		var p: String = "res://ui/portraits/%s.png" % v
		if v != "" and ResourceLoader.exists(p):
			_art = load(p) as Texture2D
		queue_redraw()
@export var facing_left: bool = false
@export var rim: Color = Color(0.75, 0.08, 0.06)

var _art: Texture2D = null
var _breath: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if Settings.clear_mind or speaker == "" or speaker == "narrator":
		return
	_breath += delta
	queue_redraw()


func _draw() -> void:
	if speaker == "" or speaker == "narrator":
		return
	if _art != null:
		draw_texture_rect(_art, Rect2(Vector2.ZERO, size), false)
		return
	var s: float = minf(size.x, size.y * 0.85)
	var o: Vector2 = Vector2(size.x * 0.5, size.y)
	var b: float = 0.0 if Settings.clear_mind else sin(_breath * 1.3) * s * 0.004
	var shapes: Array[PackedVector2Array] = _shapes(speaker, s, o + Vector2(0, b))
	if facing_left:
		for i: int in range(shapes.size()):
			shapes[i] = _mirror(shapes[i], o.x)
	# Glow behind
	var head: Vector2 = o + Vector2(0, -s * 0.72)
	for i: int in range(10, 0, -1):
		draw_circle(head, s * 0.07 * i, Color(rim, 0.02))
	# Rim light: the silhouette offset toward the light, in red.
	var light_dir: Vector2 = Vector2(-1 if facing_left else 1, -0.35).normalized() * s * 0.012
	for poly: PackedVector2Array in shapes:
		var moved: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in poly:
			moved.append(p + light_dir)
		draw_colored_polygon(moved, rim)
	for poly: PackedVector2Array in shapes:
		draw_colored_polygon(poly, Color(0.035, 0.025, 0.025))
	_details(speaker, s, o + Vector2(0, b))


func _shapes(who: String, s: float, o: Vector2) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var shoulders: PackedVector2Array = PackedVector2Array([
		o + Vector2(-s * 0.46, 0), o + Vector2(-s * 0.42, -s * 0.3), o + Vector2(-s * 0.2, -s * 0.44),
		o + Vector2(s * 0.2, -s * 0.44), o + Vector2(s * 0.42, -s * 0.3), o + Vector2(s * 0.46, 0)])
	var neck: PackedVector2Array = PackedVector2Array([
		o + Vector2(-s * 0.07, -s * 0.42), o + Vector2(-s * 0.06, -s * 0.58),
		o + Vector2(s * 0.06, -s * 0.58), o + Vector2(s * 0.07, -s * 0.42)])
	var head_c: Vector2 = o + Vector2(0, -s * 0.72)
	match who:
		"isaak":
			out.append(shoulders)
			out.append(neck)
			out.append(_ellipse(head_c, s * 0.12, s * 0.165, 0.0))
			out.append(PackedVector2Array([head_c + Vector2(-s * 0.13, -s * 0.05), head_c + Vector2(-s * 0.09, -s * 0.19),
				head_c + Vector2(s * 0.1, -s * 0.18), head_c + Vector2(s * 0.14, -s * 0.02), head_c + Vector2(s * 0.16, s * 0.2),
				head_c + Vector2(s * 0.1, s * 0.05), head_c + Vector2(-s * 0.1, s * 0.05), head_c + Vector2(-s * 0.16, s * 0.2)]))
		"kett":
			out.append(PackedVector2Array([o + Vector2(-s * 0.5, 0), o + Vector2(-s * 0.4, -s * 0.36), o + Vector2(-s * 0.16, -s * 0.5),
				o + Vector2(s * 0.16, -s * 0.5), o + Vector2(s * 0.4, -s * 0.36), o + Vector2(s * 0.5, 0)]))
			out.append(_ellipse(head_c + Vector2(0, s * 0.02), s * 0.13, s * 0.16, 0.0))
			out.append(PackedVector2Array([head_c + Vector2(-s * 0.2, s * 0.22), head_c + Vector2(-s * 0.19, -s * 0.08),
				head_c + Vector2(-s * 0.08, -s * 0.22), head_c + Vector2(s * 0.08, -s * 0.22), head_c + Vector2(s * 0.19, -s * 0.08),
				head_c + Vector2(s * 0.2, s * 0.22), head_c + Vector2(s * 0.12, s * 0.12), head_c + Vector2(s * 0.14, -s * 0.02),
				head_c + Vector2(-s * 0.14, -s * 0.02), head_c + Vector2(-s * 0.12, s * 0.12)]))
		"marquise":
			out.append(PackedVector2Array([o + Vector2(-s * 0.4, 0), o + Vector2(-s * 0.36, -s * 0.28), o + Vector2(-s * 0.16, -s * 0.4),
				o + Vector2(s * 0.16, -s * 0.4), o + Vector2(s * 0.36, -s * 0.28), o + Vector2(s * 0.4, 0)]))
			# High collar
			out.append(PackedVector2Array([o + Vector2(-s * 0.2, -s * 0.38), o + Vector2(-s * 0.26, -s * 0.72), o + Vector2(-s * 0.08, -s * 0.52),
				o + Vector2(s * 0.08, -s * 0.52), o + Vector2(s * 0.26, -s * 0.72), o + Vector2(s * 0.2, -s * 0.38)]))
			out.append(neck)
			out.append(_ellipse(head_c, s * 0.105, s * 0.15, 0.0))
			out.append(_ellipse(head_c + Vector2(0, -s * 0.2), s * 0.12, s * 0.11, 0.0))
			out.append(_ellipse(head_c + Vector2(0, -s * 0.3), s * 0.07, s * 0.07, 0.0))
		"steward":
			out.append(shoulders)
			out.append(neck)
			out.append(_ellipse(head_c, s * 0.12, s * 0.16, 0.0))
			out.append(PackedVector2Array([head_c + Vector2(-s * 0.2, -s * 0.1), head_c + Vector2(s * 0.2, -s * 0.1),
				head_c + Vector2(s * 0.13, -s * 0.14), head_c + Vector2(s * 0.12, -s * 0.44), head_c + Vector2(-s * 0.12, -s * 0.44),
				head_c + Vector2(-s * 0.13, -s * 0.14)]))
		"lord":
			out.append(PackedVector2Array([o + Vector2(-s * 0.5, 0), o + Vector2(-s * 0.46, -s * 0.34), o + Vector2(-s * 0.22, -s * 0.46),
				o + Vector2(s * 0.22, -s * 0.46), o + Vector2(s * 0.46, -s * 0.34), o + Vector2(s * 0.5, 0)]))
			out.append(neck)
			out.append(_ellipse(head_c, s * 0.12, s * 0.16, 0.0))
			var crown: PackedVector2Array = PackedVector2Array([head_c + Vector2(-s * 0.12, -s * 0.1)])
			for k: int in range(5):
				var x: float = -s * 0.12 + s * 0.06 * k
				crown.append(head_c + Vector2(x + s * 0.03, -s * 0.3))
				crown.append(head_c + Vector2(x + s * 0.06, -s * 0.16))
			crown.append(head_c + Vector2(s * 0.12, -s * 0.1))
			out.append(crown)
		"wenna":
			out.append(shoulders)
			out.append(_ellipse(head_c, s * 0.11, s * 0.15, 0.0))
			out.append(PackedVector2Array([head_c + Vector2(-s * 0.17, s * 0.3), head_c + Vector2(-s * 0.16, -s * 0.06),
				head_c + Vector2(0, -s * 0.2), head_c + Vector2(s * 0.16, -s * 0.06), head_c + Vector2(s * 0.17, s * 0.3),
				head_c + Vector2(s * 0.1, s * 0.12), head_c + Vector2(-s * 0.1, s * 0.12)]))
		"courier":
			out.append(shoulders)
			out.append(neck)
			out.append(_ellipse(head_c, s * 0.115, s * 0.155, 0.0))
			out.append(PackedVector2Array([head_c + Vector2(-s * 0.15, -s * 0.06), head_c + Vector2(-s * 0.1, -s * 0.18),
				head_c + Vector2(s * 0.1, -s * 0.18), head_c + Vector2(s * 0.25, -s * 0.05)]))
		_:
			out.append(shoulders)
			out.append(_ellipse(head_c, s * 0.12, s * 0.16, 0.0))
	return out


## Details drawn over the silhouette: eyes that catch the candle, Kett's patch, chains.
func _details(who: String, s: float, o: Vector2) -> void:
	var head_c: Vector2 = o + Vector2(0, -s * 0.72)
	var eye_col: Color = Color(0.85, 0.15, 0.1) if who in ["marquise", "lord", "steward"] else Color(0.9, 0.8, 0.6, 0.8)
	var dx: float = s * 0.045
	var ey: float = head_c.y - s * 0.01
	match who:
		"kett":
			draw_circle(Vector2(head_c.x - dx, ey + s * 0.02), s * 0.008, eye_col)
			draw_line(head_c + Vector2(-s * 0.12, -s * 0.06), head_c + Vector2(s * 0.12, s * 0.02), Color(0.3, 0.2, 0.15), 3.0)
			draw_circle(Vector2(head_c.x + dx, ey + s * 0.015), s * 0.02, Color(0.3, 0.2, 0.15))
		"isaak":
			draw_circle(Vector2(head_c.x - dx, ey), s * 0.008, Color(0.95, 0.3, 0.2))
			draw_circle(Vector2(head_c.x + dx, ey), s * 0.008, Color(0.95, 0.3, 0.2))
			for k: int in range(6):
				draw_arc(o + Vector2(-s * 0.1 + s * 0.04 * k, -s * 0.42), s * 0.02, 0.0, TAU, 10, Color(0.35, 0.3, 0.28), 3.0)
		_:
			draw_circle(Vector2(head_c.x - dx, ey), s * 0.007, eye_col)
			draw_circle(Vector2(head_c.x + dx, ey), s * 0.007, eye_col)
	if who == "marquise":
		draw_circle(head_c + Vector2(-s * 0.11, s * 0.08), s * 0.012, Palette.GOLD)
		draw_circle(head_c + Vector2(s * 0.11, s * 0.08), s * 0.012, Palette.GOLD)
	if who == "lord":
		draw_polyline(PackedVector2Array([head_c + Vector2(-s * 0.12, -s * 0.12), head_c + Vector2(s * 0.12, -s * 0.12)]), Palette.GOLD, 3.0)


static func _ellipse(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var a: float = TAU * float(i) / 28.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func _mirror(poly: PackedVector2Array, cx: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in range(poly.size() - 1, -1, -1):
		out.append(Vector2(2.0 * cx - poly[i].x, poly[i].y))
	return out
