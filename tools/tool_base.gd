class_name ToolBase
extends Control
## Base for the tactile tools. Tools are dumb views: they hold UI state, draw it, and
## report what the player did. Mode controllers push every derived number in.
##
## Contract (docs/TECH_DESIGN.md section 6): state_changed after any player change,
## get_state()/set_state() for save/resume, undo() with a 50-step snapshot stack.

signal state_changed

@export var tool_id: String = ""

var undo_stack: UndoStack = UndoStack.new()
var _restoring: bool = false


func get_state() -> Dictionary:
	return {}


func set_state(_d: Dictionary) -> void:
	pass


## Call BEFORE applying a player change.
func snapshot() -> void:
	if not _restoring:
		undo_stack.push(get_state())


func undo() -> bool:
	var s: Dictionary = undo_stack.pop()
	if s.is_empty():
		return false
	_restoring = true
	set_state(s)
	_restoring = false
	state_changed.emit()
	return true


## Global rect a first-use coach mark should circle.
func coach_rect() -> Rect2:
	return get_global_rect()


## Pointer helpers. Only mouse events are handled: on phones Godot synthesizes them
## from touches (input_devices/pointing/emulate_mouse_from_touch), so one code path
## serves both and nothing fires twice.
static func press_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	return Vector2.ZERO


static func is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		return mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed
	return false


static func is_release(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		return mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed
	return false


static func drag_pos(event: InputEvent) -> Vector2:
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	return Vector2(-INF, -INF)


static func is_drag(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		return ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	return false
