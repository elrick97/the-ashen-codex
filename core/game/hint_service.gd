class_name HintService
extends RefCounted
## Three tiers per puzzle (Nudge, Concept, Near-answer), voiced by Brother Kett.
## Tiers unlock in order; each costs Thirst once; bought tiers stay readable for free.

const TIERS: int = 3

var progression: Progression = null


func _init(p: Progression) -> void:
	progression = p


func bought() -> int:
	return int(progression.active().get("hints_bought", 0))


## Cost of the next tier, or 0 when all are bought.
func next_cost() -> int:
	var b: int = bought()
	if b >= TIERS:
		return 0
	return Thirst.config.hint_cost(b + 1)


## Buys the next tier and returns it (1..3), or 0 if none is left.
func buy_next() -> int:
	var b: int = bought()
	if b >= TIERS:
		return 0
	progression.active()["hints_bought"] = b + 1
	progression.charge(Thirst.config.hint_cost(b + 1), "hint")
	return b + 1


func text(def: PuzzleDef, tier: int) -> String:
	if tier < 1 or tier > def.hint_keys.size():
		return ""
	return TranslationServer.translate(def.hint_keys[tier - 1])
