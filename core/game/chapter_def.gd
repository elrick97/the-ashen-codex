class_name ChapterDef
extends Resource
## One sub-chapter of an act. `steps` is walked in order by Progression:
##   {"type": "dialogue", "id": "a1_i_intro"}
##   {"type": "puzzle", "id": "a1_p01"}
##   {"type": "summary"}                      sub-chapter grades
##   {"type": "act_folio"}                    all grades of the act
##   {"type": "card", "text": "CARD_A1_END"}  full-screen card, then title

@export var id: String = ""
@export var act: int = 1
@export var order: int = 0
@export var title_key: String = ""
@export var subtitle_key: String = ""
@export var steps: Array[Dictionary] = []
@export var next_chapter: String = ""
@export var puzzle_ids: PackedStringArray = PackedStringArray()
