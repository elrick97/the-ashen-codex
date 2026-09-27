class_name Progression
extends RefCounted
## Where the player is (chapter + step), story flags, puzzle records and grades.
## Operates directly on Save.data so every change is part of the next autosave.

var db: ContentDB = null


func _init(content: ContentDB) -> void:
	db = content


func data() -> Dictionary:
	return Save.data


func new_game() -> void:
	Save.delete_save()
	Save.data = SaveService.fresh()
	Save.data["chapter_id"] = ContentDB.FIRST_CHAPTER
	Save.data["step_index"] = 0
	Thirst.set_value(0.0)
	Save.autosave_enabled = true
	save()


## Loads the save (main, backup or fresh) and restores Thirst. Returns the load source.
func continue_game() -> String:
	var d: Dictionary = Save.load_game()
	if str(d.get("chapter_id", "")) == "" and Save.last_load_source == "fresh":
		new_game()
		return "fresh"
	var resume: String = str(d.get("resume_puzzle", ""))
	if resume != "":
		_jump_to_puzzle(resume)
		d.erase("resume_puzzle")
	if str(d.get("chapter_id", "")) == "":
		d["chapter_id"] = ContentDB.FIRST_CHAPTER
	Thirst.set_value(float(d.get("thirst", 0.0)))
	Save.autosave_enabled = true
	return Save.last_load_source


func save() -> void:
	Save.data["thirst"] = Thirst.value
	Save.save_game()


func current_chapter() -> ChapterDef:
	return db.chapter(str(Save.data.get("chapter_id", "")))


func step_index() -> int:
	return int(Save.data.get("step_index", 0))


## The current step, or {} when the act is over.
func current_step() -> Dictionary:
	var ch: ChapterDef = current_chapter()
	if ch == null:
		return {}
	var i: int = step_index()
	if i < 0 or i >= ch.steps.size():
		return {}
	return ch.steps[i]


func advance() -> void:
	var ch: ChapterDef = current_chapter()
	if ch == null:
		return
	var i: int = step_index() + 1
	if i >= ch.steps.size():
		Save.data["chapter_id"] = ch.next_chapter
		i = 0
	Save.data["step_index"] = i
	save()


func flags() -> Dictionary:
	return Save.data["flags"]


func flag(name: String, default_value: Variant = false) -> Variant:
	return flags().get(name, default_value)


func set_flag(name: String, v: Variant) -> void:
	flags()[name] = v


func apply_flags(d: Dictionary) -> void:
	for k: Variant in d.keys():
		set_flag(str(k), d[k])


func puzzle_record(id: String) -> Dictionary:
	return (Save.data["puzzles"] as Dictionary).get(id, {})


func is_solved(id: String) -> bool:
	return bool(puzzle_record(id).get("solved", false))


## Starts (or resumes) the active puzzle record for `id`.
func start_puzzle(id: String) -> Dictionary:
	var a: Dictionary = active()
	if str(a.get("id", "")) == id:
		return a
	var fresh: Dictionary = {
		"id": id, "variant": 0, "frenzied": false, "thirst_spent": 0, "hints_bought": 0,
		"trials": 0, "wrong_commits": 0, "tool_states": {}, "mode_state": {},
	}
	Save.data["active_puzzle"] = fresh
	save()
	return fresh


func active() -> Dictionary:
	return Save.data["active_puzzle"]


## Thirst cost attributed to the active puzzle (grade) and to Isaak (Thirst).
func charge(amount: int, reason: String) -> void:
	if amount <= 0:
		return
	var a: Dictionary = active()
	if not a.is_empty():
		a["thirst_spent"] = int(a.get("thirst_spent", 0)) + amount
		if reason == "trial":
			a["trials"] = int(a.get("trials", 0)) + 1
		elif reason == "wrong_commit":
			a["wrong_commits"] = int(a.get("wrong_commits", 0)) + 1
	Thirst.spend(amount, reason)
	save()


## Logs a frenzy and moves the active puzzle to its next, harder variant.
func record_frenzy(puzzle_id: String) -> void:
	var ch: ChapterDef = current_chapter()
	(Save.data["frenzies"] as Array).append({"puzzle": puzzle_id, "unix": int(Time.get_unix_time_from_system())})
	set_flag("frenzy_count", int(flag("frenzy_count", 0)) + 1)
	if ch != null:
		set_flag("frenzied_" + ch.id, true)
	var a: Dictionary = active()
	a["variant"] = int(a.get("variant", 0)) + 1
	a["frenzied"] = true
	a.erase("frenzy_pending")
	a["tool_states"] = {}
	a["mode_state"] = {}
	Thirst.after_frenzy()
	save()


## Records the solved puzzle with its grade and clears the active record.
func complete_puzzle(id: String) -> Dictionary:
	if is_solved(id):
		# The first seal stands; a replay can't launder the grade.
		Save.data["active_puzzle"] = {}
		save()
		return puzzle_record(id)
	var a: Dictionary = active()
	var spent: int = int(a.get("thirst_spent", 0))
	var rec: Dictionary = {
		"solved": true, "variant": int(a.get("variant", 0)), "thirst_spent": spent,
		"grade": Thirst.config.grade_for(spent), "hints_bought": int(a.get("hints_bought", 0)),
		"frenzied": bool(a.get("frenzied", false)), "wrong_commits": int(a.get("wrong_commits", 0)),
	}
	(Save.data["puzzles"] as Dictionary)[id] = rec
	Save.data["active_puzzle"] = {}
	save()
	return rec


## [{"id", "number", "title_key", "grade", "thirst_spent"}] for a chapter ("" grade = unsolved).
func grades_for(chapter: ChapterDef) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pid: String in chapter.puzzle_ids:
		var def: PuzzleDef = db.puzzle(pid)
		var rec: Dictionary = puzzle_record(pid)
		out.append({
			"id": pid, "number": def.number if def != null else 0,
			"title_key": def.title_key if def != null else "",
			"grade": str(rec.get("grade", "")), "thirst_spent": int(rec.get("thirst_spent", 0)),
		})
	return out


func coach_seen(tool_id: String) -> bool:
	return bool((Save.data["coach_seen"] as Dictionary).get(tool_id, false))


func mark_coach_seen(tool_id: String) -> void:
	(Save.data["coach_seen"] as Dictionary)[tool_id] = true


func _jump_to_puzzle(puzzle_id: String) -> void:
	for ch: ChapterDef in db.chapters.values():
		for i: int in range(ch.steps.size()):
			var st: Dictionary = ch.steps[i]
			if str(st.get("type", "")) == "puzzle" and str(st.get("id", "")) == puzzle_id:
				Save.data["chapter_id"] = ch.id
				Save.data["step_index"] = i
				return
