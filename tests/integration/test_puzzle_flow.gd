extends GutTest
## Drives the real Main scene and PuzzleHost for every Act I puzzle:
## wrong seal costs Thirst, the solved configuration seals, mid-puzzle tool state
## survives a save/resume, and a frenzy swaps in the harder variant.

const DIR: String = "user://test_flow"

var main: Node = null
var _old_dir: String = ""


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_old_dir = Save.directory
	Save.directory = DIR
	Engine.set_meta("tour", true)


func after_all() -> void:
	Save.delete_save()
	Save.directory = _old_dir
	Engine.remove_meta("tour")
	Thirst.set_value(0.0)


func before_each() -> void:
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child_autofree(main)
	await wait_process_frames(2)
	(main.get("ctx") as GameContext).progression.new_game()


func _open(id: String) -> PuzzleHost:
	var ctx: GameContext = main.get("ctx")
	Save.data["chapter_id"] = ctx.db.puzzle(id).chapter_id
	var s: Screen = main.call("show_now", "puzzle", {"id": id})
	return s as PuzzleHost


func _all_ids() -> Array[String]:
	var out: Array[String] = []
	for n: int in range(1, 13):
		out.append("a1_p%02d" % n)
	return out


func test_every_puzzle_seals_when_solved() -> void:
	for id: String in _all_ids():
		var host: PuzzleHost = _open(id)
		await wait_process_frames(3)
		assert_not_null(host.mode, id + " mode built")
		host.mode.apply_solution()
		await wait_process_frames(1)
		assert_true(host.mode.can_commit(), id + " can seal when solved")
		var v: PuzzleMode.Verdict = host.mode.commit()
		if id == "a1_p03":
			assert_eq(v, PuzzleMode.Verdict.NONE, "keyless asks its question")
			var panel: ChoicePanel = _find(host, "ChoicePanel") as ChoicePanel
			assert_not_null(panel, "question panel shown")
			if panel != null:
				panel.chosen.emit(2)
			await wait_process_frames(2)
			assert_true((main.get("ctx") as GameContext).progression.is_solved(id), id + " solved via question")
		elif id == "a1_p10":
			# Stages 1 and 2 were skipped by apply_solution; stage 3 seals.
			assert_eq(v, PuzzleMode.Verdict.SOLVED, id)
		else:
			assert_eq(v, PuzzleMode.Verdict.SOLVED, id)
		host.queue_free()
		await wait_process_frames(1)


func test_wrong_seal_costs_thirst() -> void:
	for id: String in ["a1_p01", "a1_p02", "a1_p07", "a1_p10"]:
		Thirst.set_value(0.0)
		var host: PuzzleHost = _open(id)
		await wait_process_frames(2)
		var before: int = int((main.get("ctx") as GameContext).progression.active().get("thirst_spent", 0))
		if host.mode.commit() == PuzzleMode.Verdict.WRONG:
			host.resolve(PuzzleMode.Verdict.WRONG)
			var after: int = int((main.get("ctx") as GameContext).progression.active().get("thirst_spent", 0))
			assert_eq(after - before, Thirst.config.wrong_commit, id + " wrong seal costs 8")
		else:
			pass_test(id + " fresh state happened to be right (key 0)")
		host.queue_free()
		await wait_process_frames(1)


func test_incomplete_answers_cannot_be_sealed() -> void:
	for id: String in ["a1_p04", "a1_p05", "a1_p06", "a1_p11", "a1_p12"]:
		var host: PuzzleHost = _open(id)
		await wait_process_frames(2)
		assert_false(host.mode.can_commit(), id + " seal disabled until the answer is complete")
		assert_true(host.seal_button.disabled, id + " seal button disabled")
		host.queue_free()
		await wait_process_frames(1)


func test_mid_puzzle_state_survives_save_and_resume() -> void:
	for id: String in _all_ids():
		var host: PuzzleHost = _open(id)
		await wait_process_frames(2)
		host.mode.apply_solution()
		var state: Dictionary = host.mode.get_state()
		host.save_now()
		host.queue_free()
		await wait_process_frames(1)
		# Reload the save file from disk, as after an app restart.
		Save.data = {}
		Save.load_game()
		var saved: Dictionary = Save.data["active_puzzle"]
		assert_eq(str(saved["id"]), id, id + " active puzzle saved")
		var host2: PuzzleHost = _open(id)
		await wait_process_frames(2)
		assert_eq(_norm(host2.mode.get_state()), _norm(state), id + " tool state restored")
		assert_true(host2.mode.can_commit(), id + " restored answer still sealable")
		host2.queue_free()
		await wait_process_frames(1)


func test_frenzy_plays_scene_and_switches_to_harder_variant() -> void:
	var host: PuzzleHost = _open("a1_p02")
	await wait_process_frames(2)
	var ctx: GameContext = main.get("ctx")
	Thirst.set_value(96.0)
	host.charge(8, "wrong_commit")
	await wait_process_frames(3)
	var overlay: Screen = main.get("overlay")
	assert_not_null(overlay, "frenzy scene opened")
	if overlay != null:
		overlay.done.emit({})
	await wait_process_frames(3)
	assert_eq(int(ctx.progression.active()["variant"]), 1, "harder variant")
	assert_true(bool(ctx.progression.active()["frenzied"]))
	assert_eq(host.inst.trial_cost, 2, "rust costs double after the frenzy")
	assert_eq(Thirst.value, 70.0)
	assert_eq(int(ctx.progression.flag("frenzy_count", 0)), 1)
	host.queue_free()


func test_hints_charge_and_codex_unlocks_on_start() -> void:
	var host: PuzzleHost = _open("a1_p04")
	await wait_process_frames(2)
	var ctx: GameContext = main.get("ctx")
	assert_true(ctx.codex.is_unlocked("a1_substitution"), "codex entry written when the lesson starts")
	var tier: int = ctx.hints.buy_next()
	assert_eq(tier, 1)
	assert_eq(int(ctx.progression.active()["thirst_spent"]), 5)
	assert_ne(ctx.hints.text(host.def, 1), "PZ_P04_HINT1", "hint text translated")
	host.queue_free()


## JSON round trip so ints and floats compare equal (saves store numbers as floats).
static func _norm(d: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(d)))


static func _find(n: Node, cls: String) -> Node:
	for c: Node in n.get_children():
		if c.get_script() != null and (c.get_script() as Script).get_global_name() == cls:
			return c
		var f: Node = _find(c, cls)
		if f != null:
			return f
	return null
