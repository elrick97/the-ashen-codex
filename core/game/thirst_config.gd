class_name ThirstConfig
extends Resource
## Every Thirst number in one place (content/thirst_config.tres).

const GRADE_SANCTIFIED: String = "sanctified"
const GRADE_STAINED: String = "stained"
const GRADE_DAMNED: String = "damned"

@export var wrong_commit: int = 8
@export var hint_costs: PackedInt32Array = PackedInt32Array([5, 12, 25])
## Heartbeat/vignette, ink bleed/wobble/whispers, pulse/desaturation.
@export var thresholds: PackedInt32Array = PackedInt32Array([40, 65, 90])
@export var frenzy_at: int = 100
@export var frenzy_reset_to: int = 70
@export var grade_sanctified_max: int = 10
@export var grade_stained_max: int = 35


func grade_for(spent: int) -> String:
	if spent <= grade_sanctified_max:
		return GRADE_SANCTIFIED
	if spent <= grade_stained_max:
		return GRADE_STAINED
	return GRADE_DAMNED


## 0 below the first threshold, then 1..3.
func level_for(value: float) -> int:
	var lvl: int = 0
	for t: int in thresholds:
		if value >= t:
			lvl += 1
	return lvl


func hint_cost(tier: int) -> int:
	return hint_costs[clampi(tier - 1, 0, hint_costs.size() - 1)]
