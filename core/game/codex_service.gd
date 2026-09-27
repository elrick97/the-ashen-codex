class_name CodexService
extends RefCounted
## Which Codex entries Isaak has written. Reading is always free.

var db: ContentDB = null


func _init(content: ContentDB) -> void:
	db = content


func unlocked() -> Array:
	return Save.data["codex_unlocked"]


func is_unlocked(id: String) -> bool:
	return unlocked().has(id)


## Unlocks entries; returns the ids that were new.
func unlock(ids: PackedStringArray) -> PackedStringArray:
	var added: PackedStringArray = PackedStringArray()
	for id: String in ids:
		if db.codex.has(id) and not is_unlocked(id):
			unlocked().append(id)
			added.append(id)
			EventBus.codex_unlocked.emit(id)
	return added


## Entries to list: every Act I entry (sealed if locked) and the later-act placeholders.
func entries() -> Array[CodexEntryDef]:
	return db.codex_sorted()
