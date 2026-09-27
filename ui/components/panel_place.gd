class_name PanelPlace
extends RefCounted
## Places a modal panel near the bottom of the screen (thumb reach), full width minus
## margins, and keeps it there when its content or the window changes. Reacts only to
## minimum_size_changed / viewport size_changed, never to `resized`, so setting the size
## can't re-trigger itself.


## `anchor_y`: 0..1 vertical centre, or < 0 to sit on the bottom edge.
static func bottom(panel: Control, owner: Control, max_width: float = 100000.0, anchor_y: float = -1.0) -> void:
	var place: Callable = func() -> void:
		if not is_instance_valid(panel) or not panel.is_inside_tree():
			return
		var vs: Vector2 = owner.get_viewport_rect().size
		var m: Vector4 = SafeArea.margins(owner)
		var w: float = minf(max_width, vs.x - 60.0 - m.x - m.z)
		if not is_equal_approx(panel.custom_minimum_size.x, w):
			panel.custom_minimum_size.x = w
		panel.reset_size()
		var y: float = vs.y - m.w - panel.size.y - 40.0
		if anchor_y >= 0.0:
			y = clampf(vs.y * anchor_y - panel.size.y * 0.5, m.y + 20.0, vs.y - m.w - panel.size.y - 20.0)
		panel.position = Vector2((vs.x - panel.size.x) * 0.5, y)
	panel.minimum_size_changed.connect(place)
	owner.get_viewport().size_changed.connect(place)
	place.call_deferred()
