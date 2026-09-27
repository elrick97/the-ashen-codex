class_name Screen
extends Control
## Base class for every screen Main shows. Main calls setup() after adding the screen.
## A screen reports completion with `done.emit(result)`.

@warning_ignore("unused_signal")
signal done(result: Dictionary)

var ctx: GameContext = null
var main: Node = null
var args: Dictionary = {}


func setup(context: GameContext, main_node: Node, arguments: Dictionary) -> void:
	ctx = context
	main = main_node
	args = arguments
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


## Override: build the UI (called once, after ctx/args are set).
func _build() -> void:
	pass


## Screen-space safe-area margins (left, top, right, bottom) in canvas units.
func safe_margins() -> Vector4:
	return SafeArea.margins(self)


## A full-rect MarginContainer honouring the safe area plus `pad` canvas units.
func make_safe_root(pad: float = 32.0) -> MarginContainer:
	var m: MarginContainer = MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var apply: Callable = func() -> void:
		var s: Vector4 = safe_margins()
		m.add_theme_constant_override("margin_left", int(s.x + pad))
		m.add_theme_constant_override("margin_top", int(s.y + pad))
		m.add_theme_constant_override("margin_right", int(s.z + pad))
		m.add_theme_constant_override("margin_bottom", int(s.w + pad))
	apply.call()
	resized.connect(apply)
	return m
