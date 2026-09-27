class_name ContentDB
extends RefCounted
## Loads every PuzzleDef, ChapterDef, CodexEntryDef and dialogue file once.

const PUZZLE_DIR: String = "res://content/puzzles"
const CHAPTER_DIR: String = "res://content/chapters"
const CODEX_DIR: String = "res://content/codex"
const DIALOGUE_DIR: String = "res://content/dialogue"
const FIRST_CHAPTER: String = "a1_i"

var puzzles: Dictionary = {}   # id -> PuzzleDef
var chapters: Dictionary = {}  # id -> ChapterDef
var codex: Dictionary = {}     # id -> CodexEntryDef
var dialogues: Dictionary = {} # id -> Dictionary (parsed JSON)


func load_all() -> void:
	for r: Resource in _load_resources(PUZZLE_DIR):
		var p: PuzzleDef = r as PuzzleDef
		if p != null:
			puzzles[p.id] = p
	for r: Resource in _load_resources(CHAPTER_DIR):
		var c: ChapterDef = r as ChapterDef
		if c != null:
			chapters[c.id] = c
	for r: Resource in _load_resources(CODEX_DIR):
		var e: CodexEntryDef = r as CodexEntryDef
		if e != null:
			codex[e.id] = e
	for f: String in DirAccess.get_files_at(DIALOGUE_DIR):
		if f.ends_with(".json"):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_DIR.path_join(f)))
			if d is Dictionary:
				dialogues[str(d.get("id", f.get_basename()))] = d
			else:
				push_error("ContentDB: bad dialogue file " + f)


func puzzle(id: String) -> PuzzleDef:
	return puzzles.get(id, null) as PuzzleDef


func chapter(id: String) -> ChapterDef:
	return chapters.get(id, null) as ChapterDef


func dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})


## Chapters of an act in order.
func chapters_of_act(act: int) -> Array[ChapterDef]:
	var out: Array[ChapterDef] = []
	for c: ChapterDef in chapters.values():
		if c.act == act:
			out.append(c)
	out.sort_custom(func(a: ChapterDef, b: ChapterDef) -> bool: return a.order < b.order)
	return out


## Puzzles of an act in number order.
func puzzles_of_act(act: int) -> Array[PuzzleDef]:
	var out: Array[PuzzleDef] = []
	for c: ChapterDef in chapters_of_act(act):
		for pid: String in c.puzzle_ids:
			var p: PuzzleDef = puzzle(pid)
			if p != null:
				out.append(p)
	return out


## Codex entries sorted by act, then order.
func codex_sorted() -> Array[CodexEntryDef]:
	var out: Array[CodexEntryDef] = []
	for e: CodexEntryDef in codex.values():
		out.append(e)
	out.sort_custom(func(a: CodexEntryDef, b: CodexEntryDef) -> bool:
		return a.act < b.act or (a.act == b.act and a.order < b.order))
	return out


static func _load_resources(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	for f: String in ResourceLoader.list_directory(dir):
		if f.ends_with(".tres") or f.ends_with(".res"):
			var r: Resource = load(dir.path_join(f))
			if r != null:
				out.append(r)
	return out
