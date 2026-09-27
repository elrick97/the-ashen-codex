extends Node
## Automated screenshot tour. Boots the real Main scene and walks every screen, every
## puzzle's start and solved states, Thirst levels, the frenzy, hints, Codex widgets and
## the largest text size. Saves PNGs to qa/screenshots/<W>x<H>/.
## Run (needs a display):
##   $GODOT --path . --rendering-driver opengl3 --resolution 1080x1920 res://tools_dev/screenshot_tour.tscn
## Optional user args: -- notch   (simulate a notch/home-bar safe area)

const SAVE_DIR: String = "user://tour_saves"
const TOOLS: Array[String] = ["cipher_wheel", "tally_scroll", "substitution_board", "multi_wheel",
	"kasiski_lens", "column_loom", "bit_rosary", "key_dial", "hamming_comb", "crib_dragger"]

var main: Node = null
var out_dir: String = ""
var shot: int = 0
var ctx: GameContext = null


func _ready() -> void:
	Engine.set_meta("tour", true)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("notch"):
		SafeArea.debug_override = Vector4(0, 96, 0, 70)
	var size: Vector2i = DisplayServer.window_get_size()
	var root_dir: String = ProjectSettings.globalize_path("res://").path_join("qa/screenshots")
	out_dir = root_dir.path_join("%dx%d%s" % [size.x, size.y, "_notch" if args.has("notch") else ""])
	DirAccess.make_dir_recursive_absolute(out_dir)
	for f: String in DirAccess.get_files_at(out_dir):
		if f.ends_with(".png"):
			DirAccess.remove_absolute(out_dir.path_join(f))
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	Save.directory = SAVE_DIR
	Settings.directory = SAVE_DIR
	Settings.from_dict({"text_size": 0, "clear_mind": false, "haptics": false, "vol_master": 0.0})
	Settings.apply()
	main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await _frames(3)
	ctx = main.get("ctx")
	await _run()
	print("TOUR DONE: %d screenshots in %s" % [shot, out_dir])
	Save.delete_save()
	get_tree().quit(0)


func _frames(n: int) -> void:
	for _i: int in range(n):
		await get_tree().process_frame


func _snap(label: String, settle: int = 20) -> void:
	await _frames(settle)
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	shot += 1
	img.save_png(out_dir.path_join("%02d_%s.png" % [shot, label]))


func _show(id: String, a: Dictionary = {}) -> Screen:
	return main.call("show_now", id, a) as Screen


func _seen_all_coach() -> void:
	for t: String in TOOLS:
		ctx.progression.mark_coach_seen(t)


func _run() -> void:
	await _show_and_snap("boot", {}, "boot_warning")
	await _show_and_snap("title", {}, "title_new")
	ctx.progression.new_game()
	await _show_and_snap("title", {}, "title_continue")
	_show("title")
	await _frames(2)
	main.call("open_overlay", "settings")
	await _snap("settings")
	main.call("close_overlay")
	await _show_and_snap("credits", {}, "credits")
	# Dialogue: vault and memory, mid-line and with a choice.
	var d: Screen = _show("dialogue", {"id": "a1_vault_open"})
	await _frames(4)
	for _i: int in range(2):
		d.call("_on_tap")
		d.call("_on_tap")
	await _snap("dialogue_vault")
	d = _show("dialogue", {"id": "a1_i_intro"})
	await _frames(4)
	for _i: int in range(3):
		d.call("_on_tap")
		d.call("_on_tap")
	await _snap("dialogue_memory")
	d = _show("dialogue", {"id": "a1_i_end"})
	await _frames(4)
	for _i: int in range(40):
		var runner: DialogueRunner = d.get("runner")
		if runner.has_choices() or runner.finished:
			break
		d.call("_on_tap")
		d.call("_on_tap")
	await _snap("dialogue_choice")
	# First puzzle with its coach mark.
	var host: PuzzleHost = _show("puzzle", {"id": "a1_p01"}) as PuzzleHost
	await _snap("p01_coach_mark", 40)
	_seen_all_coach()
	# Every puzzle: start and solved.
	for n: int in range(1, 13):
		var id: String = "a1_p%02d" % n
		Save.data["chapter_id"] = ctx.db.puzzle(id).chapter_id
		host = _show("puzzle", {"id": id}) as PuzzleHost
		await _snap("p%02d_start" % n, 30)
		await _extra_start_views(n, host)
		host.mode.apply_solution()
		await _snap("p%02d_solved" % n, 15)
		ctx.progression.complete_puzzle(id)
		_show("folio", {"puzzle_id": id, "record": ctx.progression.puzzle_record(id), "unlocked": ctx.db.puzzle(id).codex_unlocks})
		if n in [1, 5, 12]:
			await _snap("p%02d_folio" % n)
		ctx.codex.unlock(ctx.db.puzzle(id).codex_unlocks)
	# Hints panel.
	host = _show("puzzle", {"id": "a1_p02"}) as PuzzleHost
	await _frames(5)
	ctx.hints.buy_next()
	ctx.hints.buy_next()
	HintPanel.open(host, ctx.hints, host.def)
	await _snap("hints_panel")
	# Thirst levels.
	for v: int in [45, 70, 95]:
		Thirst.set_value(float(v))
		host = _show("puzzle", {"id": "a1_p07"}) as PuzzleHost
		await _snap("thirst_%d" % v, 30)
	Thirst.set_value(70.0)
	_show("dialogue", {"id": "a1_vault_i"})
	await _snap("thirst_70_vault_whispers", 30)
	# Frenzy.
	host = _show("puzzle", {"id": "a1_p02"}) as PuzzleHost
	await _frames(5)
	Thirst.set_value(96.0)
	host.charge(8, "wrong_commit")
	await _snap("frenzy_scene", 60)
	var o: Screen = main.get("overlay")
	if o != null:
		o.done.emit({})
	await _snap("frenzy_after_variant", 30)
	# Clear Mind at high Thirst: no distortion.
	Settings.set_value("clear_mind", true)
	Thirst.set_value(95.0)
	_show("puzzle", {"id": "a1_p07"})
	await _snap("thirst_95_clear_mind", 30)
	Settings.set_value("clear_mind", false)
	Thirst.set_value(10.0)
	# Codex index and entries with widgets.
	var cx: Screen = _show("codex")
	await _snap("codex_index")
	for e: String in ["a1_key", "a1_frequency", "a1_substitution", "a1_ioc", "a1_xor", "a1_otp"]:
		cx.call("show_entry", e)
		await _snap("codex_" + e)
	# Summaries and the ending.
	await _show_and_snap("summary", {"chapter": "a1_i"}, "summary_a1_i")
	ctx.progression.set_flag("courier_spared", true)
	ctx.progression.set_flag("refused_wenna", true)
	ctx.progression.set_flag("act1_silent", true)
	await _show_and_snap("summary", {"act": 1}, "act_folio")
	await _show_and_snap("card", {"text": "CARD_A1_END"}, "ending_card")
	# Largest text size on the busiest screens.
	Settings.set_value("text_size", 2)
	await _frames(2)
	for id2: String in ["a1_p04", "a1_p12"]:
		Save.data["chapter_id"] = ctx.db.puzzle(id2).chapter_id
		_show("puzzle", {"id": id2})
		await _snap("largest_text_" + id2, 30)
	_show("dialogue", {"id": "a1_vault_end"})
	await _snap("largest_text_dialogue", 30)
	var cx2: Screen = _show("codex")
	cx2.call("show_entry", "a1_kasiski")
	await _snap("largest_text_codex")
	Settings.set_value("text_size", 0)


func _extra_start_views(n: int, host: PuzzleHost) -> void:
	var m: PuzzleMode = host.mode
	match n:
		2, 7:
			if m.tabs.size() > 1:
				m.show_tab(m.tabs.size() - 1)
				await _snap("p%02d_tally" % n)
				m.show_tab(0)
		4:
			m.show_tab(1)
			await _snap("p04_tally")
			m.show_tab(0)
		5:
			var b: SubstitutionBoard = host.mode.get("board")
			b.tab = 1
			b.call("_sync_tabs")
			await _snap("p05_crib")
			b.tab = 0
			b.call("_sync_tabs")
		6:
			var t: TallyScroll = host.mode.get("tally")
			m.show_tab(1)
			t.call("_on_tab", TallyScroll.TAB_TRIGRAMS)
			await _snap("p06_trigrams")
			m.show_tab(0)
		8:
			var cipher: String = host.mode.get("cipher")
			var reps: Array[Dictionary] = Kasiski.find_repeats(cipher, 3, 8)
			if reps.size() > 0:
				var p0: int = (reps[0]["positions"] as PackedInt32Array)[0]
				host.mode.call("_on_long_press", PuzzleMode.grouped_index_of_letter(p0))
			await _snap("p08_lens")
		9:
			var loom: ColumnLoom = host.mode.get("loom")
			loom.call("_on_slider", float(str(host.inst.key).length()))
			await _snap("p09_loom_right_n")
		11:
			var comb: HammingComb = host.mode.get("comb")
			comb.set_state({"selected": (host.inst.key as PackedByteArray).size()})
			await _snap("p11_comb")
		12:
			var dr: CribDragger = host.mode.get("dragger")
			var tray: PackedStringArray = host.inst.extras["crib_tray"]
			var a: PackedByteArray = host.inst.plain_bytes[0]
			for w: String in tray:
				var pos: int = a.get_string_from_ascii().find(w)
				if pos >= 0 and pos + w.length() <= int(host.inst.extras["overlap"]):
					dr.call("_choose_crib", w)
					dr.set_offset_player(pos)
					break
			await _snap("p12_crib_readable")


func _show_and_snap(id: String, a: Dictionary, label: String) -> void:
	_show(id, a)
	await _snap(label)
