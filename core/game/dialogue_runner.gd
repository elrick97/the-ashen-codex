class_name DialogueRunner
extends RefCounted
## State machine over one dialogue JSON (format: docs/TECH_DESIGN.md section 4).
## Pure logic: effects (flags, Thirst) go out through the `effect` signal.

signal effect(set_flags: Dictionary, thirst_delta: int)

var nodes: Array = []
var index: int = -1
var finished: bool = false
var _labels: Dictionary = {}
var _flags: Callable


## Starts a dialogue. `flag_source` returns the current flags Dictionary.
func start(dialogue: Dictionary, flag_source: Callable) -> Dictionary:
	nodes = dialogue.get("nodes", [])
	_flags = flag_source
	_labels.clear()
	for i: int in range(nodes.size()):
		var n: Dictionary = nodes[i]
		if n.has("label"):
			_labels[str(n["label"])] = i
	finished = false
	return _enter(0)


func current() -> Dictionary:
	if finished or index < 0 or index >= nodes.size():
		return {}
	return nodes[index]


func has_choices() -> bool:
	return not visible_choices().is_empty()


## Choices of the current node whose conditions hold.
func visible_choices() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n: Dictionary = current()
	for c: Variant in n.get("choices", []):
		var cd: Dictionary = c
		if not cd.has("if") or eval_cond(cd["if"], _flags.call()):
			out.append(cd)
	return out


## Moves past the current line. Does nothing while a choice is pending.
func next() -> Dictionary:
	var n: Dictionary = current()
	if n.is_empty():
		return {}
	if has_choices():
		return n
	if bool(n.get("end", false)):
		return _finish()
	if n.has("goto"):
		return _jump(str(n["goto"]))
	return _enter(index + 1)


func choose(i: int) -> Dictionary:
	var choices: Array[Dictionary] = visible_choices()
	if i < 0 or i >= choices.size():
		return current()
	var c: Dictionary = choices[i]
	_apply(c)
	if c.has("goto"):
		return _jump(str(c["goto"]))
	return _enter(index + 1)


static func eval_cond(cond: Variant, flags: Dictionary) -> bool:
	if not cond is Dictionary:
		return true
	var c: Dictionary = cond
	if c.has("all"):
		for sub: Variant in c["all"]:
			if not eval_cond(sub, flags):
				return false
		return true
	if c.has("any"):
		for sub: Variant in c["any"]:
			if eval_cond(sub, flags):
				return true
		return false
	if c.has("not"):
		return not eval_cond(c["not"], flags)
	if c.has("flag"):
		var v: Variant = flags.get(str(c["flag"]), null)
		if c.has("eq"):
			return _same(v, c["eq"])
		if c.has("gte"):
			return v != null and float(v) >= float(c["gte"])
		return _truthy(v)
	return true


## Type-safe equality (JSON numbers are floats; flags may be ints or bools).
static func _same(a: Variant, b: Variant) -> bool:
	var num: Array[int] = [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in num and typeof(b) in num:
		return float(a) == float(b)
	if typeof(a) != typeof(b):
		return false
	return a == b


static func _truthy(v: Variant) -> bool:
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return bool(v)
		TYPE_INT, TYPE_FLOAT:
			return float(v) != 0.0
		TYPE_STRING:
			return str(v) != ""
	return true


func _jump(label: String) -> Dictionary:
	if not _labels.has(label):
		push_error("DialogueRunner: unknown label " + label)
		return _finish()
	return _enter(int(_labels[label]))


## Enters the first node at or after i whose condition holds, applying its effects.
func _enter(i: int) -> Dictionary:
	var j: int = i
	while j < nodes.size():
		var n: Dictionary = nodes[j]
		if not n.has("if") or eval_cond(n["if"], _flags.call()):
			index = j
			_apply(n)
			return n
		j += 1
	return _finish()


func _finish() -> Dictionary:
	finished = true
	index = nodes.size()
	return {}


func _apply(n: Dictionary) -> void:
	var s: Dictionary = n.get("set", {})
	var t: int = int(n.get("thirst", 0))
	if not s.is_empty() or t != 0:
		effect.emit(s, t)
