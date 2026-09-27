class_name GradeSeal
extends Control
## A wax seal for a grade. Each grade has its own shape and word, so colour is never
## the only signal: Sanctified = halo ring + cross, Stained = blot, Damned = broken seal.

@export var grade: String = ""


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.42
	match grade:
		ThirstConfig.GRADE_SANCTIFIED:
			_wax(c, r, Color("6e5418"))
			draw_arc(c, r * 0.72, 0.0, TAU, 40, Palette.GOLD_LIGHT, 4.0)
			draw_line(c + Vector2(0, -r * 0.45), c + Vector2(0, r * 0.45), Palette.GOLD_LIGHT, 5.0)
			draw_line(c + Vector2(-r * 0.3, -r * 0.12), c + Vector2(r * 0.3, -r * 0.12), Palette.GOLD_LIGHT, 5.0)
		ThirstConfig.GRADE_STAINED:
			_wax(c, r, Color("7a2a1a"))
			var blot: PackedVector2Array = PackedVector2Array()
			for i: int in range(18):
				var a: float = TAU * i / 18.0
				blot.append(c + Vector2(cos(a), sin(a)) * r * (0.38 + 0.12 * sin(a * 3.0 + 1.0)))
			draw_colored_polygon(blot, Color("2b0c08"))
		ThirstConfig.GRADE_DAMNED:
			_wax(c, r, Color("5e0d0d"))
			draw_line(c + Vector2(-r * 0.2, -r * 0.9), c + Vector2(r * 0.1, -r * 0.1), Palette.SOOT, 6.0)
			draw_line(c + Vector2(r * 0.1, -r * 0.1), c + Vector2(-r * 0.15, r * 0.9), Palette.SOOT, 6.0)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.05), r * 0.1, Palette.SOOT)
			draw_circle(c + Vector2(r * 0.3, -r * 0.05), r * 0.1, Palette.SOOT)
		_:
			draw_arc(c, r, 0.0, TAU, 40, Color(Palette.INK_FADED, 0.5), 3.0)


func _wax(c: Vector2, r: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var a: float = TAU * i / 28.0
		pts.append(c + Vector2(cos(a), sin(a)) * r * (1.0 + 0.06 * sin(a * 5.0)))
	draw_colored_polygon(pts, col)
	draw_arc(c, r * 0.9, 0.0, TAU, 36, col.lightened(0.2), 3.0)
