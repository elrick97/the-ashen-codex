class_name PuzzleDef
extends Resource
## Declarative puzzle definition (see docs/TECH_DESIGN.md section 4).
## Adding a puzzle of an existing mode needs only a new .tres file.

@export var id: String = ""
@export var chapter_id: String = ""
@export var number: int = 0
@export var title_key: String = ""
@export var brief_key: String = ""
## caesar, keyless, substitution, vigenere, xor_rosary, xor_repeating, two_time_pad
@export var mode: String = ""
@export var tools: PackedStringArray = PackedStringArray()
@export var plaintext_keys: PackedStringArray = PackedStringArray()
@export var sender_keys: PackedStringArray = PackedStringArray()
## upper_keep, letters_only, ascii, upper_ascii
@export var normalization: String = "upper_keep"
@export var key_rule: Dictionary = {}
@export var base_seed: int = 1
@export var params: Dictionary = {}
@export var brute_force_costed: bool = false
@export var trial_cost: int = 1
@export var hint_keys: PackedStringArray = PackedStringArray()
@export var codex_unlocks: PackedStringArray = PackedStringArray()
@export var frenzy_dialogue: String = ""
@export var frenzy_overrides: Dictionary = {}
## Dev note: why the free live preview can't solve this without the target concept.
@export_multiline var anti_cheese: String = ""


func seed_for_variant(variant: int) -> int:
	return base_seed + 7919 * variant
