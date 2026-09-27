class_name PuzzleMode
extends Node
## Base for mode controllers. A mode builds its tools inside the host, keeps the letter
## card in sync with the crypto core, and judges commits. Tools stay dumb views.

enum Verdict { WRONG, STAGE, SOLVED, NONE }

var host: PuzzleHost = null
var inst: PuzzleInstance = null


func setup(puzzle_host: PuzzleHost, instance: PuzzleInstance) -> void:
	host = puzzle_host
	inst = instance
	_build()


## Override: create tools with host.add_tool(), wire signals, set the letter card.
func _build() -> void:
	pass


## Override: judge the player's committed answer.
func commit() -> Verdict:
	return Verdict.NONE


## Override: a short line under the commit button ("Set the wheel, then seal it.").
func status_text() -> String:
	return ""


## Override: can the Seal button be pressed now?
func can_commit() -> bool:
	return true


## Override: everything needed to resume mid-puzzle.
func get_state() -> Dictionary:
	return {}


func set_state(_d: Dictionary) -> void:
	pass


## Override: undo the last tool change. Returns false if nothing to undo.
func undo() -> bool:
	return false


## Override (dev/tour/tests): put the tools into the solved configuration.
func apply_solution() -> void:
	pass


## Tool ids whose first-use coach mark should show.
func coach_tools() -> PackedStringArray:
	return inst.def.tools


## Called by tools when the player spends a costed trial.
func spend_trial() -> void:
	if inst.def.brute_force_costed:
		host.charge(inst.trial_cost, "trial")
