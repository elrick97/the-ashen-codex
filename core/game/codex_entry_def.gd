class_name CodexEntryDef
extends Resource
## One Codex (grimoire) entry. Text lives in the translation CSV under CDX_<ID>_*.

@export var id: String = ""
@export var act: int = 1
@export var chapter_id: String = ""
@export var order: int = 0
@export var title_key: String = ""
@export var body_key: String = ""
@export var example_key: String = ""
@export var wrong_key: String = ""
@export var aside_key: String = ""
@export var margin_keys: PackedStringArray = PackedStringArray()
## "", "shift_wheel", "frequency", "ioc", "xor_beads"
@export var widget: String = ""
## Acts II-V stubs: shown sealed with a one-line teaser.
@export var placeholder: bool = false
