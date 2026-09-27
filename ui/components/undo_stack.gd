class_name UndoStack
extends RefCounted
## Snapshot undo for tools: push the state before each change, pop to undo.

var limit: int = 50
var _stack: Array[Dictionary] = []


func push(state: Dictionary) -> void:
	_stack.append(state.duplicate(true))
	while _stack.size() > limit:
		_stack.pop_front()


func can_undo() -> bool:
	return not _stack.is_empty()


## Returns the last snapshot, or {} if there is none.
func pop() -> Dictionary:
	if _stack.is_empty():
		return {}
	return _stack.pop_back()


func clear() -> void:
	_stack.clear()


func size() -> int:
	return _stack.size()
