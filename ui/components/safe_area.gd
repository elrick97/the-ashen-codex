class_name SafeArea
extends RefCounted
## Converts DisplayServer.get_display_safe_area() (screen pixels) into the canvas units
## of a Control, so notches and home bars are respected at any stretch scale.

## Canvas-unit margins used instead of the display's (screenshot tour simulates a notch).
static var debug_override: Vector4 = Vector4(-1, -1, -1, -1)


static func margins(node: Control) -> Vector4:
	if debug_override.x >= 0.0:
		return debug_override
	if not node.is_inside_tree():
		return Vector4.ZERO
	var win: Window = node.get_window()
	var win_size: Vector2 = Vector2(win.size)
	if win_size.x <= 0.0 or win_size.y <= 0.0:
		return Vector4.ZERO
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2 = Vector2(DisplayServer.screen_get_size())
	if safe.size.x <= 0 or screen_size.x <= 0.0 or not OS.has_feature("mobile"):
		return Vector4.ZERO
	var canvas: Vector2 = node.get_viewport_rect().size
	var sx: float = canvas.x / win_size.x
	var sy: float = canvas.y / win_size.y
	var left: float = maxf(0.0, float(safe.position.x)) * sx
	var top: float = maxf(0.0, float(safe.position.y)) * sy
	var right: float = maxf(0.0, screen_size.x - float(safe.end.x)) * sx
	var bottom: float = maxf(0.0, screen_size.y - float(safe.end.y)) * sy
	return Vector4(left, top, right, bottom)
