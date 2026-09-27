class_name Palette
extends RefCounted
## The illuminated-manuscript palette. Contrast ratios (WCAG) against VELLUM are noted
## where text uses the colour; body text stays >= 4.5:1.

const VELLUM: Color = Color("e9dcc0")        # page
const VELLUM_MID: Color = Color("d8c6a0")
const VELLUM_SHADOW: Color = Color("b89f74")
const INK: Color = Color("1e1a16")           # iron-gall ink, 13.6:1 on VELLUM
const INK_FADED: Color = Color("4a3f33")     # secondary text, 8.3:1 on VELLUM
const RUBRIC: Color = Color("8e1b1b")        # blood-red rubrication, 7.0:1 on VELLUM
const BLOOD: Color = Color("b3261e")         # bright blood (effects, never the only signal)
const GOLD: Color = Color("b08d3c")          # tarnished gold leaf (ornament)
const GOLD_LIGHT: Color = Color("d4b25e")
const GOLD_TEXT: Color = Color("6e5418")     # gold readable as text, 5.6:1 on VELLUM
const SOOT: Color = Color("14100d")          # background
const STONE: Color = Color("2a231e")
const CANDLE: Color = Color("f2b455")
const ON_DARK: Color = Color("e9dcc0")       # vellum text on SOOT, 14.9:1
const ON_DARK_FADED: Color = Color("b5a78c") # 8.4:1 on SOOT

## Eight strand colours for the Column Loom / Multi-Wheel columns (distinct in hue and
## lightness, each >= 3:1 on VELLUM as graphics).
const STRANDS: Array[Color] = [
	Color("8e1b1b"), Color("1f4e79"), Color("5a6e1f"), Color("7a3e8e"),
	Color("a35a00"), Color("1d6b63"), Color("6e4b2a"), Color("9e2a6b"),
]


static func strand(i: int) -> Color:
	return STRANDS[posmod(i, STRANDS.size())]
