extends GutTest
## Plays Act I start to finish through the real Main scene: boot warning, title, every
## dialogue (taking the first choice), all 12 puzzles (solved configuration, then Seal),
## folios, summaries, the act folio and the ending card. Also checks input and settings.

const DIR: String = "user://test_playthrough"

var main: Node = null
var _old: String = ""


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_old = Save.directory
	Save.directory = DIR
	Engine.set_meta("tour", true)


func after_all() -> void:
	Save.delete_save()
	Save.directory = _old
	Engine.remove_meta("tour")
	Thirst.set_value(0.0)
	Settings.from_dict({"clear_mind": false, "text_size": 0})
	Settings.apply()


func before_each() -> void:
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)


func _wait_screen(id: String, frames: int = 120) -> bool:
	for _i: int in range(frames):
		if str(main.get("screen_id")) == id and not bool(main.get("_busy")):
			return true
		await wait_process_frames(1)
	return false


func test_full_act_one_playthrough() -> void:
	main.call("goto", "boot")
	assert_true(await _wait_screen("boot"), "boot warning shown")
	(main.get("screen") as Screen).done.emit({})
	assert_true(await _wait_screen("title"), "title after the warning")
	(main.get("screen") as Screen).done.emit({"action": "new"})
	var ctx: GameContext = main.get("ctx")
	var seen: Dictionary = {}
	var puzzles_played: Dictionary = {}
	for _step: int in range(200):
		await wait_process_frames(2)
		var id: String = str(main.get("screen_id"))
		while bool(main.get("_busy")):
			await wait_process_frames(1)
		id = str(main.get("screen_id"))
		var s: Screen = main.get("screen")
		seen[id] = int(seen.get(id, 0)) + 1
		match id:
			"dialogue":
				var r: DialogueRunner = s.get("runner")
				for _k: int in range(80):
					if r.finished:
						break
					if r.has_choices():
						s.call("_choose", 0)
					else:
						s.call("_advance")
					await wait_process_frames(1)
			"puzzle":
				var host: PuzzleHost = s as PuzzleHost
				puzzles_played[host.def.id] = true
				host.mode.apply_solution()
				var v: PuzzleMode.Verdict = host.mode.commit()
				if v == PuzzleMode.Verdict.NONE:
					var order: Array = host.mode.call("answer_order")
					var correct: String = str(host.inst.param("answer_keys", [])[int(host.inst.param("correct_answer", 0))])
					var panel: Node = _find_panel(host)
					(panel as ChoicePanel).chosen.emit(order.find(correct))
				else:
					host.resolve(v)
				await wait_process_frames(50)
			"folio", "summary":
				s.done.emit({})
			"card":
				s.done.emit({})
				await wait_process_frames(40)
				break
			"title":
				break
	for n: int in range(1, 13):
		assert_true(ctx.progression.is_solved("a1_p%02d" % n), "puzzle %d solved" % n)
	assert_gt(int(seen.get("dialogue", 0)), 20, "all dialogue scenes played")
	assert_eq(puzzles_played.size(), 12, "12 puzzles played")
	assert_gt(int(seen.get("summary", 0)), 3, "sub-chapter summaries and the act folio")
	assert_eq(int(seen.get("card", 0)), 1, "the To-be-continued card")
	assert_true(bool(ctx.progression.flag("courier_drained", false)), "I.i choice recorded")
	assert_true(bool(ctx.progression.flag("drank_wenna", false)), "I.ii choice recorded")
	assert_true(bool(ctx.progression.flag("act1_warned", false)), "act choice recorded")
	assert_eq(ctx.codex.unlocked().size(), 14, "all 14 Act I Codex entries written")
	assert_true(await _wait_screen("title"), "back to the title after the card")


static func _find_panel(n: Node) -> Node:
	for c: Node in n.get_children():
		if c is ChoicePanel:
			return c
		var f: Node = _find_panel(c)
		if f != null:
			return f
	return null


func test_mouse_and_touch_turn_the_wheel() -> void:
	var ctx: GameContext = main.get("ctx")
	ctx.progression.new_game()
	for t: String in ["cipher_wheel", "tally_scroll"]:
		ctx.progression.mark_coach_seen(t)
	var host: PuzzleHost = main.call("show_now", "puzzle", {"id": "a1_p01"})
	await wait_process_frames(5)
	for c: Node in host.get_children():
		if c is CoachMark:
			c.queue_free()
	var wheel: CipherWheel = null
	for t: Node in host.tool_area.get_children():
		if t is CipherWheel:
			wheel = t
	assert_not_null(wheel)
	var c0: Vector2 = wheel.get_global_rect().get_center()
	var r: float = minf(wheel.size.x, wheel.size.y) * 0.4
	# Mouse: press on the ring, drag a quarter turn, release.
	var start: int = wheel.shift
	_mouse(MOUSE_BUTTON_LEFT, true, c0 + Vector2(0, -r))
	for i: int in range(1, 13):
		var a: float = -PI * 0.5 + PI * 0.5 * float(i) / 12.0
		_motion(c0 + Vector2(cos(a), sin(a)) * r)
		await wait_process_frames(1)
	_mouse(MOUSE_BUTTON_LEFT, false, c0 + Vector2(r, 0))
	await wait_process_frames(40)
	assert_ne(wheel.shift, start, "mouse drag turned the wheel")
	# Touch: the same gesture as screen touches (Godot emulates the mouse from touch).
	var after_mouse: int = wheel.shift
	_touch(true, c0 + Vector2(r, 0))
	for i2: int in range(1, 13):
		var a2: float = PI * 0.5 * float(i2) / 12.0
		_drag(c0 + Vector2(cos(a2), sin(a2)) * r)
		await wait_process_frames(1)
	_touch(false, c0 + Vector2(0, r))
	await wait_process_frames(40)
	assert_ne(wheel.shift, after_mouse, "touch drag turned the wheel")


func test_clear_mind_removes_every_distortion() -> void:
	Settings.set_value("clear_mind", true)
	Thirst.set_value(95.0)
	await wait_process_frames(3)
	var mat: ShaderMaterial = (main.get("_thirst_mat") as ShaderMaterial)
	for p: String in ["ink", "desat", "pulse", "drip"]:
		assert_eq(float(mat.get_shader_parameter(p)), 0.0, "Clear Mind zeroes " + p)
	main.call("blood_drips", 1.0)
	await wait_process_frames(10)
	assert_eq(float(main.get("_drip")), 0.0, "no drips under Clear Mind")
	Settings.set_value("clear_mind", false)
	await wait_process_frames(2)
	assert_gt(float(mat.get_shader_parameter("desat")), 0.0, "effects return without Clear Mind")
	Thirst.set_value(0.0)


func test_text_size_rebuilds_theme() -> void:
	Settings.set_value("text_size", 0)
	await wait_process_frames(1)
	var small: int = (main as Control).theme.default_font_size
	Settings.set_value("text_size", 2)
	await wait_process_frames(1)
	assert_gt((main as Control).theme.default_font_size, small, "largest text size scales the theme")
	Settings.set_value("text_size", 0)


## Canvas coordinates -> window coordinates (the stretch transform), as real input arrives.
func _win(pos: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * pos


func _mouse(button: MouseButton, pressed: bool, pos: Vector2) -> void:
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.position = _win(pos)
	e.global_position = _win(pos)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(e)


func _motion(pos: Vector2) -> void:
	var e: InputEventMouseMotion = InputEventMouseMotion.new()
	e.position = _win(pos)
	e.global_position = _win(pos)
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(e)


func _touch(pressed: bool, pos: Vector2) -> void:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = _win(pos)
	Input.parse_input_event(e)


func _drag(pos: Vector2) -> void:
	var e: InputEventScreenDrag = InputEventScreenDrag.new()
	e.index = 0
	e.position = _win(pos)
	Input.parse_input_event(e)
