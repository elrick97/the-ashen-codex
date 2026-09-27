class_name ThemeBuilder
extends RefCounted
## Builds the game Theme in code so the text-size setting can rescale every font.
## Type variations used by screens:
##   Label: InkLabel (default, on parchment), LightLabel (on dark), TitleLabel (blackletter),
##          HeaderLabel, SmallLabel, MonoLabel, RubricLabel
##   Button: default (vellum), RubricButton (primary action), GhostButton (text-only on dark)

const FONT_BODY: String = "res://ui/theme/fonts/EBGaramond.ttf"
const FONT_ITALIC: String = "res://ui/theme/fonts/EBGaramond-Italic.ttf"
const FONT_TITLE: String = "res://ui/theme/fonts/PirataOne.ttf"
const FONT_FRAKTUR: String = "res://ui/theme/fonts/UnifrakturMaguntia.ttf"
const FONT_MONO: String = "res://ui/theme/fonts/JetBrainsMono.ttf"
const FONT_FELL: String = "res://ui/theme/fonts/IMFellEnglish.ttf"

const SIZE_BODY: int = 44
const SIZE_SMALL: int = 36
const SIZE_HEADER: int = 60
const SIZE_TITLE: int = 104
const SIZE_MONO: int = 40
const SIZE_BUTTON: int = 46

static var _fonts: Dictionary = {}


static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var f: Font = null
	match kind:
		"body":
			f = _load_font(FONT_BODY)
		"italic":
			f = _load_font(FONT_ITALIC)
		"title":
			f = _load_font(FONT_TITLE)
		"fraktur":
			f = _load_font(FONT_FRAKTUR)
		"mono":
			f = _load_font(FONT_MONO)
		"fell":
			f = _load_font(FONT_FELL)
		"semibold":
			var v: FontVariation = FontVariation.new()
			v.base_font = _load_font(FONT_BODY)
			v.variation_opentype = {"wght": 600}
			f = v
		"mono_bold":
			var mv: FontVariation = FontVariation.new()
			mv.base_font = _load_font(FONT_MONO)
			mv.variation_opentype = {"wght": 700}
			f = mv
	_fonts[kind] = f
	return f


static func size(base: int) -> int:
	return int(round(float(base) * Settings.text_scale()))


static func build() -> Theme:
	var t: Theme = Theme.new()
	t.default_font = font("body")
	t.default_font_size = size(SIZE_BODY)

	t.set_color("font_color", "Label", Palette.INK)
	_variation(t, "InkLabel", "Label", Palette.INK, "body", SIZE_BODY)
	_variation(t, "LightLabel", "Label", Palette.ON_DARK, "body", SIZE_BODY)
	_variation(t, "LightSmallLabel", "Label", Palette.ON_DARK_FADED, "italic", SIZE_SMALL)
	_variation(t, "TitleLabel", "Label", Palette.RUBRIC, "title", SIZE_TITLE)
	_variation(t, "LightTitleLabel", "Label", Palette.GOLD_LIGHT, "title", SIZE_TITLE)
	_variation(t, "HeaderLabel", "Label", Palette.INK, "semibold", SIZE_HEADER)
	_variation(t, "LightHeaderLabel", "Label", Palette.ON_DARK, "semibold", SIZE_HEADER)
	_variation(t, "SmallLabel", "Label", Palette.INK_FADED, "italic", SIZE_SMALL)
	_variation(t, "MonoLabel", "Label", Palette.INK, "mono", SIZE_MONO)
	_variation(t, "RubricLabel", "Label", Palette.RUBRIC, "semibold", SIZE_BODY)

	t.set_color("default_color", "RichTextLabel", Palette.INK)
	t.set_font("normal_font", "RichTextLabel", font("body"))
	t.set_font("italics_font", "RichTextLabel", font("italic"))
	t.set_font("bold_font", "RichTextLabel", font("semibold"))
	t.set_font("mono_font", "RichTextLabel", font("mono"))
	for k: String in ["normal_font_size", "italics_font_size", "bold_font_size", "mono_font_size"]:
		t.set_font_size(k, "RichTextLabel", size(SIZE_BODY))

	_button(t, "Button", Palette.VELLUM_MID, Palette.INK, Palette.INK_FADED)
	_button(t, "RubricButton", Palette.RUBRIC, Palette.VELLUM, Color("5e1010"))
	t.set_type_variation("RubricButton", "Button")
	_button(t, "GhostButton", Color(0, 0, 0, 0), Palette.ON_DARK, Palette.GOLD)
	t.set_type_variation("GhostButton", "Button")

	var sb_panel: StyleBoxFlat = StyleBoxFlat.new()
	sb_panel.bg_color = Color(0.08, 0.06, 0.05, 0.92)
	sb_panel.border_color = Palette.GOLD
	sb_panel.set_border_width_all(3)
	sb_panel.set_corner_radius_all(14)
	sb_panel.set_content_margin_all(36)
	t.set_stylebox("panel", "PanelContainer", sb_panel)

	var grab: StyleBoxFlat = StyleBoxFlat.new()
	grab.bg_color = Palette.RUBRIC
	grab.set_corner_radius_all(24)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Palette.VELLUM_SHADOW
	track.set_corner_radius_all(8)
	track.content_margin_top = 12
	track.content_margin_bottom = 12
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	t.set_icon("grabber", "HSlider", _circle_icon(56, Palette.RUBRIC))
	t.set_icon("grabber_highlight", "HSlider", _circle_icon(60, Palette.BLOOD))

	var sb_scroll: StyleBoxFlat = StyleBoxFlat.new()
	sb_scroll.bg_color = Color(Palette.INK_FADED, 0.25)
	sb_scroll.set_corner_radius_all(6)
	sb_scroll.content_margin_left = 6
	sb_scroll.content_margin_right = 6
	var sb_grab: StyleBoxFlat = StyleBoxFlat.new()
	sb_grab.bg_color = Color(Palette.RUBRIC, 0.7)
	sb_grab.set_corner_radius_all(6)
	t.set_stylebox("scroll", "VScrollBar", sb_scroll)
	t.set_stylebox("grabber", "VScrollBar", sb_grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", sb_grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", sb_grab)

	t.set_font_size("font_size", "CheckButton", size(SIZE_BODY))
	t.set_color("font_color", "CheckButton", Palette.ON_DARK)
	t.set_color("font_hover_color", "CheckButton", Palette.GOLD_LIGHT)
	t.set_color("font_pressed_color", "CheckButton", Palette.ON_DARK)
	t.set_color("font_hover_pressed_color", "CheckButton", Palette.GOLD_LIGHT)
	t.set_color("font_focus_color", "CheckButton", Palette.ON_DARK)
	t.set_icon("checked", "CheckButton", _toggle_icon(true))
	t.set_icon("unchecked", "CheckButton", _toggle_icon(false))
	return t


static func _variation(t: Theme, name: String, base: String, color: Color, font_kind: String, font_size: int) -> void:
	t.set_type_variation(name, base)
	t.set_color("font_color", name, color)
	t.set_font("font", name, font(font_kind))
	t.set_font_size("font_size", name, size(font_size))


static func _button(t: Theme, type_name: String, bg: Color, fg: Color, border: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(3 if bg.a > 0.0 else 0)
	normal.set_corner_radius_all(12)
	normal.content_margin_left = 36
	normal.content_margin_right = 36
	normal.content_margin_top = 34
	normal.content_margin_bottom = 34
	normal.shadow_color = Color(0, 0, 0, 0.35 if bg.a > 0.0 else 0.0)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 4)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = bg.darkened(0.18) if bg.a > 0.0 else Color(1, 1, 1, 0.08)
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 1)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = bg.lightened(0.06) if bg.a > 0.0 else Color(1, 1, 1, 0.05)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(bg, bg.a * 0.45)
	disabled.border_color = Color(border, 0.4)
	var focus: StyleBoxFlat = normal.duplicate()
	focus.draw_center = false
	focus.border_color = Palette.GOLD_LIGHT
	focus.set_border_width_all(4)
	t.set_stylebox("normal", type_name, normal)
	t.set_stylebox("pressed", type_name, pressed)
	t.set_stylebox("hover", type_name, hover)
	t.set_stylebox("hover_pressed", type_name, pressed)
	t.set_stylebox("disabled", type_name, disabled)
	t.set_stylebox("focus", type_name, focus)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, type_name, fg)
	t.set_color("font_disabled_color", type_name, Color(fg, 0.45))
	t.set_font("font", type_name, font("semibold"))
	t.set_font_size("font_size", type_name, size(SIZE_BUTTON))


static func _circle_icon(d: int, c: Color) -> ImageTexture:
	var img: Image = Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r: float = d * 0.5
	for y: int in range(d):
		for x: int in range(d):
			var dist: float = Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a: float = clampf(r - dist, 0.0, 1.0)
			var col: Color = c if dist < r - 5.0 else Palette.GOLD_LIGHT
			img.set_pixel(x, y, Color(col, a))
	return ImageTexture.create_from_image(img)


static func _toggle_icon(on: bool) -> ImageTexture:
	var w: int = 132
	var h: int = 72
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track: Color = Palette.RUBRIC if on else Palette.INK_FADED
	for y: int in range(h):
		for x: int in range(w):
			var cx: float = clampf(float(x) + 0.5, h * 0.5, w - h * 0.5)
			var dist: float = Vector2(x + 0.5 - cx, y + 0.5 - h * 0.5).length()
			var a: float = clampf(h * 0.5 - dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(track, a))
	var knob_x: float = w - h * 0.5 if on else h * 0.5
	for y: int in range(h):
		for x: int in range(w):
			var dist: float = Vector2(x + 0.5 - knob_x, y + 0.5 - h * 0.5).length()
			var a: float = clampf(h * 0.5 - 7.0 - dist, 0.0, 1.0)
			if a > 0.0:
				img.set_pixel(x, y, Color(Palette.VELLUM, a).blend(Color(Palette.GOLD, 0.0)))
	return ImageTexture.create_from_image(img)


static func _load_font(path: String) -> Font:
	var f: FontFile = load(path) as FontFile
	return f
