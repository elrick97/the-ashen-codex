class_name PuzzleMode
extends Node
## Base for mode controllers. A mode builds its tools inside the host, keeps the letter
## card in sync with the crypto core, and judges commits. Tools stay dumb views: every
## number they show is computed here from core/crypto.

enum Verdict { WRONG, STAGE, SOLVED, NONE }

var host: PuzzleHost = null
var inst: PuzzleInstance = null
var tabs: Array[Control] = []
var tab_buttons: Array[Button] = []
var current_tab: int = 0

var _undo_order: Array[ToolBase] = []
var _undoing: bool = false


func setup(puzzle_host: PuzzleHost, instance: PuzzleInstance) -> void:
	host = puzzle_host
	inst = instance
	_build()


## Override: create tools with host.add_tool(), wire signals, set the letter card.
func _build() -> void:
	pass


## Override: judge the player's committed answer. Return NONE when the verdict arrives
## later through host.resolve() (e.g. after a question panel).
func commit() -> Verdict:
	return Verdict.NONE


## Override: a short instruction line above the tools.
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


## Override (dev, screenshot tour, tests): put the tools into the solved configuration.
func apply_solution() -> void:
	pass


## Override: refresh derived views after an undo.
func sync_views() -> void:
	pass


## Tool ids whose first-use coach mark should show.
func coach_tools() -> PackedStringArray:
	return inst.def.tools


## A costed trial (a wheel notch, a "read as E").
func spend_trial() -> void:
	if inst.def.brute_force_costed:
		host.charge(inst.trial_cost, "trial")


## Records tool changes for the shared undo order and schedules autosave.
func track(t: ToolBase) -> void:
	if t == null:
		return
	t.state_changed.connect(func() -> void:
		if not _undoing:
			_undo_order.append(t)
		host.changed())


func undo() -> bool:
	while not _undo_order.is_empty():
		var t: ToolBase = _undo_order.pop_back()
		_undoing = true
		var ok: bool = t.undo()
		_undoing = false
		if ok:
			sync_views()
			return true
	return false


## Segmented bar above the tool area; only the selected tool is visible.
func make_tabs(tools: Array[Control], label_keys: PackedStringArray) -> void:
	tabs = tools
	tab_buttons.clear()
	if tools.size() <= 1:
		return
	var bar: HBoxContainer = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	host.tool_area.add_child(bar)
	host.tool_area.move_child(bar, 0)
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(tools.size()):
		var b: Button = Button.new()
		b.text = tr(label_keys[i])
		b.toggle_mode = true
		b.button_group = g
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", mini(ThemeBuilder.size(ThemeBuilder.SIZE_BUTTON), 52))
		b.pressed.connect(show_tab.bind(i))
		bar.add_child(b)
		tab_buttons.append(b)
	show_tab(0)


func show_tab(i: int) -> void:
	current_tab = i
	for k: int in range(tabs.size()):
		tabs[k].visible = k == i
	for k: int in range(tab_buttons.size()):
		tab_buttons[k].set_pressed_no_signal(k == i)
	EventBus.sfx.emit("page_turn")


## Display index -> letter index maps for letters-only text shown in groups of five.
static func grouped_index_of_letter(letter_index: int, group: int = 5) -> int:
	@warning_ignore("integer_division")
	var g: int = letter_index / group
	return letter_index + g


static func letter_index_of_grouped(display_index: int, group: int = 5) -> int:
	@warning_ignore("integer_division")
	var g: int = display_index / (group + 1)
	var within: int = display_index % (group + 1)
	if within == group:
		return -1
	return g * group + within
