extends Node
## Throwaway adversarial flow probe for I.iii (delete after use).

var main: Node = null


func _ready() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i: int in range(n):
		await get_tree().process_frame


func _open(id: String) -> PuzzleHost:
	var ctx: GameContext = main.get("ctx")
	ctx.progression.new_game()
	get_tree().root.get_node("/root/Thirst").call("set_value", 0.0)
	(get_tree().root.get_node("/root/Save").get("data") as Dictionary)["chapter_id"] = ctx.db.puzzle(id).chapter_id
	var s: Screen = main.call("show_now", "puzzle", {"id": id})
	return s as PuzzleHost


func _spent() -> int:
	return int((main.get("ctx") as GameContext).progression.active().get("thirst_spent", 0))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://adv_iii")
	get_tree().root.get_node("/root/Save").set("directory", "user://adv_iii")
	Engine.set_meta("tour", true)
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(main)
	await _frames(3)

	# --- P11: dial turned before choosing a size, choose 13, Undo ---
	var host: PuzzleHost = _open("a1_p11")
	await _frames(3)
	var m: Variant = host.mode
	var dial: KeyDial = m.dial
	dial._nudge(1)
	m._choose(13)
	print("P11 before undo: keysize=%d dial.columns=%d" % [m.keysize, dial.columns])
	host._on_undo()
	await _frames(1)
	print("P11 after undo: keysize=%d dial.columns=%d values=%d" % [m.keysize, dial.columns, dial.values.size()])
	print("P11 commit verdict after undo = %d (0 wrong)" % int(m.commit()))
	host.queue_free()
	await _frames(2)

	# --- P10: bead flip then Undo ---
	host = _open("a1_p10")
	await _frames(3)
	m = host.mode
	var ros: BitRosary = m.rosary
	ros.snapshot()
	ros.bead_flipped.emit(1, 0)
	ros.state_changed.emit()
	var k_before: int = m.k
	host._on_undo()
	await _frames(1)
	print("P10 k after flip=%d, after undo=%d (expected 0)" % [k_before, m.k])
	host.queue_free()
	await _frames(2)

	# --- P12: right crib, wrong letter row ---
	host = _open("a1_p12")
	await _frames(3)
	m = host.mode
	var dr: CribDragger = m.dragger
	dr._choose_crib("BROTHER")
	dr.set_offset_player(60)
	dr.row = 0
	var s0: int = _spent()
	dr.pin_requested.emit(60, 0)
	print("P12 BROTHER@60 pinned in A: spent +%d, known B[60]=%d" % [_spent() - s0, m.known[1][60]])
	s0 = _spent()
	dr.pin_requested.emit(60, 1)
	print("P12 BROTHER@60 pinned in B: spent +%d, target text: %s" % [_spent() - s0, m.goal.text.c_escape()])
	# Re-pinning an already known correct crib: free?
	s0 = _spent()
	dr.pin_requested.emit(60, 1)
	print("P12 re-pin same: spent +%d" % (_spent() - s0))
	host.queue_free()
	await _frames(2)

	# --- P08: tray factor highlight for period 6 when all repeats collected ---
	host = _open("a1_p08")
	await _frames(3)
	m = host.mode
	for r: Dictionary in m.repeats:
		m.lens.show_repeat(r)
	m._update_lens_tally()
	var t: PackedInt32Array = m.lens.tally
	print("P08 key=%s tally 2..12: %s" % [str(host.inst.key), str(Array(t.slice(2, 13)))])
	host.queue_free()
	await _frames(2)

	# --- P07: drum drag cost vs read-as-E; tally column button after drum select ---
	host = _open("a1_p07")
	await _frames(3)
	m = host.mode
	s0 = _spent()
	m.wheels.drum_selected.emit(2)
	print("P07 tally.column after drum 3 selected=%d" % m.tally.column)
	m.tally.select_letter(4)
	m.tally.read_as_e.emit(4)
	print("P07 read-as-E cost +%d" % (_spent() - s0))
	host.queue_free()
	await _frames(2)

	get_tree().root.get_node("/root/Save").call("delete_save")
	get_tree().quit(0)
