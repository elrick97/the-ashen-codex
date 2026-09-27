extends SceneTree
## Dev helper: renders one screen and saves a PNG.
## Usage: $GODOT --path . --rendering-driver opengl3 --resolution 540x960 -s res://tools_dev/snap.gd -- <screen> <out.png> [json args]

func _initialize() -> void:
	var argv: PackedStringArray = OS.get_cmdline_user_args()
	var screen_id: String = argv[0] if argv.size() > 0 else "title"
	var out: String = argv[1] if argv.size() > 1 else "user://snap.png"
	var extra: Dictionary = {}
	if argv.size() > 2:
		var parsed: Variant = JSON.parse_string(argv[2])
		if parsed is Dictionary:
			extra = parsed
	Engine.set_meta("tour", true)
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	if extra.has("new_game"):
		(main.get("ctx") as Object).get("progression").call("new_game")
	if extra.has("thirst"):
		root.get_node("Thirst").call("set_value", float(extra["thirst"]))
	main.call("show_now", screen_id, extra)
	for _i: int in range(int(extra.get("frames", 30))):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out)
	quit(0)
