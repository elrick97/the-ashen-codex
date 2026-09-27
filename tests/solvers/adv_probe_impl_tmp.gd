extends Node
## TEMPORARY adversarial probe (delete after use).

var main: Node = null


func _ready() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i: int in range(n):
		await get_tree().process_frame


func _open(id: String) -> PuzzleHost:
	var ctx: GameContext = main.get("ctx")
	S().data["chapter_id"] = ctx.db.puzzle(id).chapter_id
	return main.call("show_now", "puzzle", {"id": id}) as PuzzleHost


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://adv_probe")
	S().directory = "user://adv_probe"
	Engine.set_meta("tour", true)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await _frames(2)
	(main.get("ctx") as GameContext).progression.new_game()

	# ---- P05: lock then pin -> dangling lock
	var host: PuzzleHost = _open("a1_p05")
	await _frames(3)
	var mode: Node = host.mode
	var board: SubstitutionBoard = mode.get("board")
	var inst: PuzzleInstance = host.inst
	var crib: String = str(mode.get("crib"))
	var pos: PackedInt32Array = Crib.substitution_positions(inst.ciphertexts[0], crib)
	print("P05 crib positions: ", pos, " len ", inst.ciphertexts[0].length())
	var m: Dictionary = Crib.substitution_mapping(inst.ciphertexts[0], crib, pos[0])
	# cipher letter that the crib maps to plain 'T'
	var cs: String = ""
	for k: Variant in m.keys():
		if int(m[k]) == 84:
			cs = String.chr(int(k))
	print("cipher for T: ", cs)
	# player wrongly places cs on Q and locks Q
	board._place(cs, "Q")
	board.snapshot()
	board.locks["Q"] = true
	board.state_changed.emit()
	print("before pin mapping[cs]=", board.mapping.get(cs, ""), " locks=", board.locks.keys())
	mode.call("_pin_crib", pos[0])
	print("after pin mapping[cs]=", board.mapping.get(cs, ""), " cipher in Q slot='", board._cipher_in_slot("Q"), "' locks=", board.locks.keys())
	# try to place any tile into Q
	var other: String = str(board.tiles[board.tiles.size() - 1]["c"])
	board.selected = other
	board._place(other, "Q")
	print("placing ", other, " into locked-empty Q -> mapping has? ", board.mapping.get(other, "<none>"))
	# save/resume: does the dangling lock persist?
	host.save_now()
	print("saved locks: ", (S().data["active_puzzle"]["tool_states"]["board"] as Dictionary).get("locks"))

	# ---- P05: undo after sliding the crib
	board.locks.clear()
	board.undo_stack = UndoStack.new()
	mode.set("_undo_order", [] as Array[ToolBase])
	board.set_mapping({})
	var tile_a: String = str(board.tiles[0]["c"])
	board._place(tile_a, "E")
	print("placed ", tile_a, "->E; now slide crib 3 steps")
	board._move_crib(1)
	board._move_crib(2)
	board._move_crib(3)
	var ok: bool = mode.undo()
	print("undo#1 ok=", ok, " mapping=", board.mapping, " crib_offset=", board.crib_offset)

	# ---- P04: phantom tile via tally bar with zero count
	host.queue_free()
	await _frames(2)
	var host4: PuzzleHost = _open("a1_p04")
	await _frames(3)
	var mode4: Node = host4.mode
	var b4: SubstitutionBoard = mode4.get("board")
	var t4: TallyScroll = mode4.get("tally")
	var zero: int = -1
	for i: int in range(26):
		if t4.counts[i] == 0:
			zero = i
	print("P04 zero-count cipher letter: ", String.chr(65 + zero), " tiles=", b4.tiles.size())
	var real: String = str(b4.tiles[0]["c"])
	b4._place(real, "E")
	t4.letter_selected.emit(zero)
	print("board.selected after tally tap: ", b4.selected)
	b4._tap(b4._slot_rect(4).get_center())
	print("after tapping slot E: mapping=", b4.mapping, " is_complete=", b4.is_complete())

	# ---- P06 n-gram tab contents
	host4.queue_free()
	await _frames(2)
	var host6: PuzzleHost = _open("a1_p06")
	await _frames(3)
	var t6: TallyScroll = host6.mode.get("tally")
	print("P06 bigrams: ", t6.bigrams.slice(0, 6))
	print("P06 trigrams: ", t6.trigrams.slice(0, 6))
	host6.queue_free()
	await _frames(2)
	S().delete_save()
	get_tree().quit(0)


func S() -> Node:
	return get_tree().root.get_node("Save")
