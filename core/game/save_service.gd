class_name SaveService
extends Node
## Autoload "Save": versioned JSON save with migrations, atomic writes and a backup.
##
## Write: save.json.tmp -> copy save.json to save.json.bak -> rename tmp over save.json.
## Load: save.json, else save.json.bak, else a fresh game. A file that fails to parse or
## validate counts as missing. Schema: docs/TECH_DESIGN.md section 7.

const VERSION: int = 1
const FILE_NAME: String = "save.json"

## Directory for save files; tests point this at a scratch folder.
var directory: String = "user://"
## The live save data. Progression mutates it in place.
var data: Dictionary = {}
## "main", "backup" or "fresh" after load_game().
var last_load_source: String = "fresh"
## True while a game is in progress; enables save-on-pause.
var autosave_enabled: bool = false


func _ready() -> void:
	data = fresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if autosave_enabled:
			save_game()


static func fresh() -> Dictionary:
	return {
		"version": VERSION,
		"updated_unix": 0,
		"chapter_id": "",
		"step_index": 0,
		"thirst": 0.0,
		"flags": {},
		"puzzles": {},
		"active_puzzle": {},
		"codex_unlocked": [],
		"frenzies": [],
		"coach_seen": {},
	}


func main_path() -> String:
	return directory.path_join(FILE_NAME)


func backup_path() -> String:
	return main_path() + ".bak"


func temp_path() -> String:
	return main_path() + ".tmp"


func has_save() -> bool:
	for p: String in [main_path(), backup_path()]:
		if _read(p).size() > 0:
			return true
	return false


func load_game() -> Dictionary:
	var d: Dictionary = _read(main_path())
	last_load_source = "main"
	if d.is_empty():
		d = _read(backup_path())
		last_load_source = "backup"
	if d.is_empty():
		d = fresh()
		last_load_source = "fresh"
	data = d
	return data


## Atomically writes `data` (or the given dictionary, which becomes `data`).
func save_game(d: Dictionary = {}) -> bool:
	if not d.is_empty():
		data = d
	data["version"] = VERSION
	data["updated_unix"] = int(Time.get_unix_time_from_system())
	var text: String = JSON.stringify(data, "\t")
	var f: FileAccess = FileAccess.open(temp_path(), FileAccess.WRITE)
	if f == null:
		push_warning("Save: cannot open temp file (%d)" % FileAccess.get_open_error())
		return false
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(main_path()) and not _read(main_path()).is_empty():
		DirAccess.copy_absolute(main_path(), backup_path())
	var err: Error = DirAccess.rename_absolute(temp_path(), main_path())
	if err != OK:
		push_warning("Save: rename failed (%d)" % err)
		return false
	return true


func delete_save() -> void:
	for p: String in [main_path(), backup_path(), temp_path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	data = fresh()
	autosave_enabled = false


## Parses, migrates and validates one file. Returns {} when unusable.
func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return {}
	if not json.data is Dictionary:
		return {}
	var d: Dictionary = migrate(json.data)
	return d if validate(d) else {}


## Upgrades any older schema to VERSION, one step at a time.
static func migrate(d: Dictionary) -> Dictionary:
	var out: Dictionary = d.duplicate(true)
	var v: int = int(out.get("version", 0))
	if v < 1:
		out = _migrate_0_to_1(out)
		v = 1
	out["version"] = v
	return out


## v0 (prototype): {"thirst", "current_puzzle", "solved": [ids], "flags"}.
static func _migrate_0_to_1(old: Dictionary) -> Dictionary:
	var out: Dictionary = fresh()
	out["thirst"] = float(old.get("thirst", 0.0))
	var flags: Variant = old.get("flags", {})
	out["flags"] = flags if flags is Dictionary else {}
	var puzzles: Dictionary = {}
	var solved: Variant = old.get("solved", [])
	if solved is Array:
		for pid: Variant in solved:
			puzzles[str(pid)] = {"solved": true, "variant": 0, "thirst_spent": 0, "grade": ThirstConfig.GRADE_STAINED, "hints_bought": 0}
	out["puzzles"] = puzzles
	out["migrated_from"] = 0
	out["resume_puzzle"] = str(old.get("current_puzzle", ""))
	return out


static func validate(d: Dictionary) -> bool:
	if int(d.get("version", -1)) != VERSION:
		return false
	var shapes: Dictionary = {
		"flags": TYPE_DICTIONARY, "puzzles": TYPE_DICTIONARY, "active_puzzle": TYPE_DICTIONARY,
		"codex_unlocked": TYPE_ARRAY, "frenzies": TYPE_ARRAY, "coach_seen": TYPE_DICTIONARY,
		"chapter_id": TYPE_STRING,
	}
	for k: String in shapes.keys():
		if not d.has(k) or typeof(d[k]) != int(shapes[k]):
			return false
	var t: Variant = d.get("thirst", null)
	if typeof(t) != TYPE_FLOAT and typeof(t) != TYPE_INT:
		return false
	return true
