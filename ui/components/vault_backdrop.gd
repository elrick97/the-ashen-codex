class_name VaultBackdrop
extends Control
## Procedural backdrops drawn in code:
##   "vault": stone arch, chains, a lectern, candles with a flickering glow
##   "marsh": night sky, moon behind cloud, reed silhouettes, low fog
##   "title": the vault arch with the Codex on the lectern
## Candle flicker and fog drift stop under Clear Mind.

@export var kind: String = "vault"

var _t: float = 0.0
var _flicker: float = 1.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 7
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if Settings.clear_mind:
		if _flicker != 1.0:
			_flicker = 1.0
			queue_redraw()
		return
	_t += delta
	_flicker = 0.88 + 0.08 * sin(_t * 7.3) + 0.05 * sin(_t * 13.1 + 1.7) + 0.03 * sin(_t * 23.0)
	queue_redraw()


func _draw() -> void:
	match kind:
		"marsh":
			_draw_marsh()
		_:
			_draw_vault()


func _draw_vault() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), Palette.SOOT)
	# Stone courses
	var row_h: float = 96.0
	var y: float = 0.0
	var row: int = 0
	while y < h:
		var off: float = 0.0 if row % 2 == 0 else 110.0
		var x: float = -off
		while x < w:
			var shade: float = 0.10 + 0.035 * float(posmod(row * 7 + floori(x / 37.0), 5)) / 5.0
			draw_rect(Rect2(x + 3, y + 3, 214, row_h - 6), Color(shade, shade * 0.86, shade * 0.74))
			x += 220.0
		y += row_h
		row += 1
	# Candle glow
	var cpos: Vector2 = Vector2(w * 0.78, h * 0.34)
	for i: int in range(14, 0, -1):
		var r: float = 60.0 * i * _flicker
		draw_circle(cpos, r, Color(Palette.CANDLE, 0.018 * (15 - i) * 0.35))
	# Arch
	var arch_w: float = w * 0.82
	var ax: float = (w - arch_w) * 0.5
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(33):
		var a: float = PI + PI * float(i) / 32.0
		pts.append(Vector2(w * 0.5 + cos(a) * arch_w * 0.5, h * 0.3 + sin(a) * arch_w * 0.42))
	pts.append(Vector2(ax + arch_w, h))
	pts.append(Vector2(ax, h))
	draw_colored_polygon(pts, Color(0.03, 0.02, 0.02, 0.55))
	draw_polyline(pts.slice(0, 33), Color(Palette.GOLD, 0.25), 6.0)
	# Chains hanging left
	for c: int in range(2):
		var cx: float = w * (0.12 + 0.09 * c)
		var link: float = 0.0
		while link < h * (0.42 + 0.1 * c):
			draw_arc(Vector2(cx, link + 20), 14.0, 0.0, TAU, 12, Color(0.25, 0.22, 0.2), 5.0)
			link += 34.0
	# Lectern
	var lx: float = w * 0.7
	var ly: float = h * 0.46
	draw_colored_polygon(PackedVector2Array([Vector2(lx - 150, ly), Vector2(lx + 150, ly - 40), Vector2(lx + 160, ly - 10), Vector2(lx - 140, ly + 30)]), Color(0.16, 0.1, 0.07))
	draw_rect(Rect2(lx - 20, ly + 10, 40, h * 0.2), Color(0.12, 0.08, 0.05))
	# Candles
	for k: int in range(3):
		var bx: float = cpos.x - 60.0 + 60.0 * k
		var by: float = cpos.y + 40.0 + (k % 2) * 16.0
		draw_rect(Rect2(bx - 10, by, 20, 70 - k * 8), Color(0.85, 0.8, 0.68))
		var fl: float = 22.0 * _flicker
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 8, by), Vector2(bx, by - fl * 1.6), Vector2(bx + 8, by)]), Palette.CANDLE)
		draw_circle(Vector2(bx, by - 6), 6.0, Color(1, 0.95, 0.8))
	# Floor shadow
	draw_rect(Rect2(0, h * 0.78, w, h * 0.22), Color(0, 0, 0, 0.45))


func _draw_marsh() -> void:
	var w: float = size.x
	var h: float = size.y
	var top: Color = Color("0b0d14")
	var bottom: Color = Color("1c2324")
	var bands: int = 24
	for i: int in range(bands):
		var c: Color = top.lerp(bottom, float(i) / float(bands - 1))
		draw_rect(Rect2(0, h * float(i) / bands, w, h / bands + 1.0), c)
	# Moon
	var moon: Vector2 = Vector2(w * 0.72, h * 0.14)
	for i: int in range(8, 0, -1):
		draw_circle(moon, 40.0 + 22.0 * i, Color(0.8, 0.82, 0.7, 0.012 * (9 - i)))
	draw_circle(moon, 70.0, Color(0.86, 0.84, 0.72))
	draw_circle(moon + Vector2(24, -10), 64.0, Color(0.09, 0.1, 0.13, 0.55))
	# Water line
	var wl: float = h * 0.52
	draw_rect(Rect2(0, wl, w, h - wl), Color("0e1414"))
	for i: int in range(18):
		var yy: float = wl + 20.0 + i * 26.0
		draw_line(Vector2(fmod(i * 173.0, w * 0.6), yy), Vector2(fmod(i * 173.0, w * 0.6) + 140.0, yy), Color(0.6, 0.65, 0.6, 0.06), 2.0)
	# Reeds
	_rng.seed = 11
	for i: int in range(70):
		var x: float = _rng.randf() * w
		var rh: float = 160.0 + _rng.randf() * 420.0
		var base: float = wl + 30.0 + _rng.randf() * 160.0
		var sway: float = 0.0 if Settings.clear_mind else sin(_t * 0.9 + i) * 8.0
		var tip: Vector2 = Vector2(x + 30.0 * (_rng.randf() - 0.5) + sway, base - rh)
		draw_line(Vector2(x, base), tip, Color(0.03, 0.035, 0.03), 4.0 + _rng.randf() * 3.0)
		if _rng.randf() < 0.3:
			draw_line(tip, tip + Vector2(3, 46), Color(0.05, 0.04, 0.03), 11.0)
	# Fog
	for i: int in range(6):
		var fy: float = wl - 40.0 + i * 38.0
		var drift: float = 0.0 if Settings.clear_mind else sin(_t * 0.2 + i) * 40.0
		draw_rect(Rect2(-60 + drift, fy, w + 120, 60), Color(0.6, 0.66, 0.66, 0.035))
