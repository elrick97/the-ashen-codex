extends SceneTree


func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var s: GDScript = load("res://tests/solvers/_adv_iii_flow.gd")
	var n: Node = s.new()
	root.add_child(n)
