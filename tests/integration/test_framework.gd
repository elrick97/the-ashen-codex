extends GutTest
## Thirst, grades, save/load (atomic, backup, corruption, migration), dialogue runner,
## progression. Saves go to a scratch folder so the player's save is never touched.

const DIR: String = "user://test_saves"

var _saved_dir: String = ""
var _saved_data: Dictionary = {}
var _frenzies: int = 0


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	_saved_dir = Save.directory
	_saved_data = Save.data
	Save.directory = DIR
	Save.delete_save()
	Thirst.set_value(0.0)
	_frenzies = 0


func after_each() -> void:
	Save.delete_save()
	Save.directory = _saved_dir
	Save.data = _saved_data
	Save.autosave_enabled = false
	Thirst.set_value(0.0)


func _on_frenzy() -> void:
	_frenzies += 1


func test_thirst_config_values() -> void:
	var c: ThirstConfig = Thirst.config
	assert_eq(c.wrong_commit, 8)
	assert_eq(c.hint_cost(1), 5)
	assert_eq(c.hint_cost(2), 12)
	assert_eq(c.hint_cost(3), 25)
	assert_eq(c.thresholds, PackedInt32Array([40, 65, 90]))


func test_grade_thresholds() -> void:
	var c: ThirstConfig = Thirst.config
	assert_eq(c.grade_for(0), ThirstConfig.GRADE_SANCTIFIED)
	assert_eq(c.grade_for(10), ThirstConfig.GRADE_SANCTIFIED)
	assert_eq(c.grade_for(11), ThirstConfig.GRADE_STAINED)
	assert_eq(c.grade_for(35), ThirstConfig.GRADE_STAINED)
	assert_eq(c.grade_for(36), ThirstConfig.GRADE_DAMNED)


func test_thirst_levels_and_clamp() -> void:
	assert_eq(Thirst.level(), 0)
	Thirst.spend(39, "t")
	assert_eq(Thirst.level(), 0)
	Thirst.spend(1, "t")
	assert_eq(Thirst.level(), 1)
	Thirst.spend(25, "t")
	assert_eq(Thirst.level(), 2)
	Thirst.spend(25, "t")
	assert_eq(Thirst.level(), 3)
	Thirst.restore(80)
	assert_eq(Thirst.value, 10.0)
	assert_eq(Thirst.level(), 0)
	Thirst.restore(50)
	assert_eq(Thirst.value, 0.0)
	Thirst.apply_delta(-5, "story")
	assert_eq(Thirst.value, 0.0)
	Thirst.apply_delta(7, "story")
	assert_eq(Thirst.value, 7.0)


func test_frenzy_fires_once_and_resets() -> void:
	EventBus.frenzy_triggered.connect(_on_frenzy)
	Thirst.spend(95, "t")
	assert_eq(_frenzies, 0)
	Thirst.spend(8, "t")
	assert_eq(Thirst.value, 100.0)
	assert_eq(_frenzies, 1)
	Thirst.spend(8, "t")
	assert_eq(_frenzies, 1, "frenzy fires once until resolved")
	assert_true(Thirst.is_frenzy_pending())
	Thirst.after_frenzy()
	assert_eq(Thirst.value, 70.0)
	assert_false(Thirst.is_frenzy_pending())
	Thirst.spend(30, "t")
	assert_eq(_frenzies, 2)
	EventBus.frenzy_triggered.disconnect(_on_frenzy)


func test_save_round_trip_and_atomic_files() -> void:
	var d: Dictionary = SaveService.fresh()
	d["chapter_id"] = "a1_ii"
	d["step_index"] = 4
	d["thirst"] = 42.5
	d["flags"] = {"courier_spared": true}
	d["active_puzzle"] = {"id": "a1_p05", "tool_states": {"mapping": {"65": 84}}}
	assert_true(Save.save_game(d))
	assert_false(FileAccess.file_exists(Save.temp_path()), "temp file renamed away")
	assert_true(Save.has_save())
	Save.data = {}
	var loaded: Dictionary = Save.load_game()
	assert_eq(Save.last_load_source, "main")
	assert_eq(str(loaded["chapter_id"]), "a1_ii")
	assert_eq(int(loaded["step_index"]), 4)
	assert_almost_eq(float(loaded["thirst"]), 42.5, 0.001)
	assert_true(bool(loaded["flags"]["courier_spared"]))
	assert_eq(int(loaded["active_puzzle"]["tool_states"]["mapping"]["65"]), 84)
	# Second save rotates the first into the backup.
	d["step_index"] = 5
	Save.save_game(d)
	assert_true(FileAccess.file_exists(Save.backup_path()))


func test_corrupted_save_falls_back_to_backup() -> void:
	var d: Dictionary = SaveService.fresh()
	d["chapter_id"] = "a1_i"
	d["step_index"] = 2
	Save.save_game(d)
	d["step_index"] = 3
	Save.save_game(d) # backup now holds step 2
	var f: FileAccess = FileAccess.open(Save.main_path(), FileAccess.WRITE)
	f.store_string("{\"version\": 1, \"chapter_id\": \"a1_i\", \"step_ind") # torn write
	f.close()
	var loaded: Dictionary = Save.load_game()
	assert_eq(Save.last_load_source, "backup")
	assert_eq(int(loaded["step_index"]), 2)


func test_both_files_corrupted_gives_fresh() -> void:
	for p: String in [Save.main_path(), Save.backup_path()]:
		var f: FileAccess = FileAccess.open(p, FileAccess.WRITE)
		f.store_string("not json at all")
		f.close()
	var loaded: Dictionary = Save.load_game()
	assert_eq(Save.last_load_source, "fresh")
	assert_eq(int(loaded["version"]), SaveService.VERSION)


func test_invalid_shape_is_rejected() -> void:
	var f: FileAccess = FileAccess.open(Save.main_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "flags": [], "thirst": "lots"}))
	f.close()
	Save.load_game()
	assert_eq(Save.last_load_source, "fresh")


func test_migration_from_v0_file() -> void:
	var v0: Dictionary = {"thirst": 30, "current_puzzle": "a1_p03", "solved": ["a1_p01", "a1_p02"], "flags": {"courier_drained": true}}
	var f: FileAccess = FileAccess.open(Save.main_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(v0))
	f.close()
	var loaded: Dictionary = Save.load_game()
	assert_eq(Save.last_load_source, "main")
	assert_eq(int(loaded["version"]), 1)
	assert_eq(int(loaded["migrated_from"]), 0)
	assert_almost_eq(float(loaded["thirst"]), 30.0, 0.001)
	assert_true(bool(loaded["puzzles"]["a1_p01"]["solved"]))
	assert_true(bool(loaded["puzzles"]["a1_p02"]["solved"]))
	assert_eq(str(loaded["resume_puzzle"]), "a1_p03")
	assert_true(bool(loaded["flags"]["courier_drained"]))
	assert_true(SaveService.validate(loaded))


func test_migrate_is_idempotent_on_current_version() -> void:
	var d: Dictionary = SaveService.fresh()
	assert_eq(SaveService.migrate(d), d)


func test_dialogue_runner_flow() -> void:
	var dlg: Dictionary = {"id": "t", "nodes": [
		{"speaker": "kett", "text": "A"},
		{"speaker": "isaak", "text": "B", "if": {"flag": "seen"}},
		{"speaker": "isaak", "text": "C", "choices": [
			{"text": "C1", "set": {"picked": 1}, "thirst": -10, "goto": "one"},
			{"text": "C2", "set": {"picked": 2}, "goto": "two"},
			{"text": "C3", "if": {"flag": "never"}},
		]},
		{"label": "one", "speaker": "kett", "text": "D", "goto": "end"},
		{"label": "two", "speaker": "kett", "text": "E", "set": {"two_seen": true}},
		{"label": "end", "speaker": "narrator", "text": "F", "end": true},
		{"speaker": "narrator", "text": "unreachable"},
	]}
	var flags: Dictionary = {}
	var effects: Array = []
	var r: DialogueRunner = DialogueRunner.new()
	r.effect.connect(func(s: Dictionary, t: int) -> void:
		flags.merge(s, true)
		effects.append(t))
	assert_eq(str(r.start(dlg, func() -> Dictionary: return flags)["text"]), "A")
	assert_eq(str(r.next()["text"]), "C", "conditional line skipped")
	assert_true(r.has_choices())
	assert_eq(r.visible_choices().size(), 2, "hidden choice filtered")
	assert_eq(str(r.next()["text"]), "C", "next() waits for a choice")
	assert_eq(str(r.choose(0)["text"]), "D")
	assert_eq(int(flags["picked"]), 1)
	assert_eq(effects, [-10])
	assert_eq(str(r.next()["text"]), "F")
	assert_eq(r.next(), {})
	assert_true(r.finished)
	# Other branch
	flags.clear()
	flags["seen"] = true
	r.start(dlg, func() -> Dictionary: return flags)
	assert_eq(str(r.next()["text"]), "B")
	r.next()
	assert_eq(str(r.choose(1)["text"]), "E")
	assert_true(bool(flags["two_seen"]))
	assert_eq(str(r.next()["text"]), "F")


func test_dialogue_conditions() -> void:
	var f: Dictionary = {"a": true, "n": 3, "s": "x", "z": false}
	assert_true(DialogueRunner.eval_cond({"flag": "a"}, f))
	assert_false(DialogueRunner.eval_cond({"flag": "z"}, f))
	assert_false(DialogueRunner.eval_cond({"flag": "missing"}, f))
	assert_true(DialogueRunner.eval_cond({"flag": "n", "eq": 3}, f))
	assert_true(DialogueRunner.eval_cond({"flag": "n", "eq": 3.0}, f))
	assert_true(DialogueRunner.eval_cond({"flag": "n", "gte": 2}, f))
	assert_false(DialogueRunner.eval_cond({"flag": "a", "eq": 1}, f), "bool vs int is not equal and does not error")
	assert_true(DialogueRunner.eval_cond({"not": {"flag": "z"}}, f))
	assert_true(DialogueRunner.eval_cond({"all": [{"flag": "a"}, {"flag": "s", "eq": "x"}]}, f))
	assert_false(DialogueRunner.eval_cond({"all": [{"flag": "a"}, {"flag": "z"}]}, f))
	assert_true(DialogueRunner.eval_cond({"any": [{"flag": "z"}, {"flag": "a"}]}, f))


func test_progression_charge_grade_and_frenzy() -> void:
	var db: ContentDB = ContentDB.new()
	var ch: ChapterDef = ChapterDef.new()
	ch.id = "t_ch"
	ch.steps = [{"type": "puzzle", "id": "t_p"}, {"type": "summary"}]
	ch.puzzle_ids = PackedStringArray(["t_p"])
	db.chapters["t_ch"] = ch
	var p: Progression = Progression.new(db)
	p.new_game()
	Save.data["chapter_id"] = "t_ch"
	assert_eq(str(p.current_step()["type"]), "puzzle")
	p.start_puzzle("t_p")
	p.charge(8, "wrong_commit")
	p.charge(1, "trial")
	p.charge(1, "trial")
	assert_eq(int(p.active()["thirst_spent"]), 10)
	assert_eq(int(p.active()["trials"]), 2)
	assert_eq(int(p.active()["wrong_commits"]), 1)
	assert_eq(Thirst.value, 10.0)
	var resumed: Dictionary = p.start_puzzle("t_p")
	assert_eq(int(resumed["thirst_spent"]), 10, "start_puzzle resumes the same active record")
	p.record_frenzy("t_p")
	assert_eq(int(p.active()["variant"]), 1)
	assert_true(bool(p.active()["frenzied"]))
	assert_eq(int(p.flag("frenzy_count", 0)), 1)
	assert_true(bool(p.flag("frenzied_t_ch", false)))
	assert_eq((Save.data["frenzies"] as Array).size(), 1)
	var rec: Dictionary = p.complete_puzzle("t_p")
	assert_eq(str(rec["grade"]), ThirstConfig.GRADE_SANCTIFIED)
	assert_true(p.is_solved("t_p"))
	assert_true(p.active().is_empty())
	p.advance()
	assert_eq(str(p.current_step()["type"]), "summary")
	p.advance()
	assert_eq(p.current_step(), {}, "chapter with no next_chapter ends")


func test_hint_service_costs_escalate() -> void:
	var db: ContentDB = ContentDB.new()
	var p: Progression = Progression.new(db)
	p.new_game()
	p.start_puzzle("t_p")
	var h: HintService = HintService.new(p)
	assert_eq(h.next_cost(), 5)
	assert_eq(h.buy_next(), 1)
	assert_eq(h.next_cost(), 12)
	assert_eq(h.buy_next(), 2)
	assert_eq(h.buy_next(), 3)
	assert_eq(h.next_cost(), 0)
	assert_eq(h.buy_next(), 0)
	assert_eq(int(p.active()["thirst_spent"]), 42)
	assert_eq(Thirst.value, 42.0)
	assert_eq(Thirst.config.grade_for(int(p.active()["thirst_spent"])), ThirstConfig.GRADE_DAMNED)


func test_settings_round_trip() -> void:
	var old_dir: String = Settings.directory
	var old: Dictionary = Settings.to_dict()
	Settings.directory = DIR
	Settings.set_value("text_size", 2)
	Settings.set_value("clear_mind", true)
	Settings.set_value("vol_sfx", 0.25)
	Settings.from_dict({"text_size": 0, "clear_mind": false, "vol_sfx": 1.0})
	Settings.load_settings()
	assert_eq(Settings.text_size, 2)
	assert_true(Settings.clear_mind)
	assert_almost_eq(Settings.vol_sfx, 0.25, 0.001)
	assert_almost_eq(Settings.text_scale(), 1.36, 0.001)
	Settings.from_dict({"text_size": 9})
	assert_eq(Settings.text_size, 2, "clamped")
	DirAccess.remove_absolute(Settings.path())
	Settings.directory = old_dir
	Settings.from_dict(old)
	Settings.apply()
