extends SceneTree
## TEMPORARY launcher (delete after use).

func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	await process_frame
	var s: Node = (load("res://tests/solvers/adv_probe_impl_tmp.gd") as GDScript).new()
	root.add_child(s)
