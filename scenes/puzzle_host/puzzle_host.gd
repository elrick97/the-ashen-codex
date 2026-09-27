class_name PuzzleHost
extends Screen
## Hosts one puzzle: top bar (settings, title, Codex bookmark), Thirst vial, the letter
## card, the tool area (filled by the mode controller), and the bottom bar
## (Undo, Hint, Seal). Handles commits, hints, frenzy, autosave and coach marks.

const SAVE_DELAY: float = 1.0

var def: PuzzleDef = null
var inst: PuzzleInstance = null
var mode: PuzzleMode = null
var letter_card: ParchmentPanel = null
var letter_scroll: ScrollContainer = null
var sender_label: Label = null
var tool_area: VBoxContainer = null
var status_label: Label = null
var seal_button: Button = null
var hint_button: Button = null
var undo_button: Button = null
var _letter_box: VBoxContainer = null
var _save_timer: Timer = null
var _frenzy_running: bool = false
var _finished: bool = false
var _col: VBoxContainer = null


func _build() -> void:
	def = ctx.db.puzzle(str(args.get("id", "")))
	if def == null:
		push_error("PuzzleHost: unknown puzzle " + str(args.get("id", "")))
		return
	Audio.set_ambience("marsh")
	var bg: VaultBackdrop = VaultBackdrop.new()
	bg.kind = "marsh"
	add_child(bg)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.012, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var root: MarginContainer = make_safe_root(22)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 14)
	root.add_child(_col)

	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	_col.add_child(top)
	var menu: Button = Button.new()
	menu.text = tr("UI_MENU")
	menu.theme_type_variation = "GhostButton"
	menu.custom_minimum_size = Vector2(150, 144)
	menu.pressed.connect(func() -> void: main.open_overlay("settings"))
	top.add_child(menu)
	var title: Label = Label.new()
	title.text = "%s. %s" % [str(def.number), tr(def.title_key)]
	title.theme_type_variation = "LightHeaderLabel"
	title.add_theme_font_size_override("font_size", ThemeBuilder.size(50))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	var codex: Button = Button.new()
	codex.text = tr("UI_CODEX_TAB")
	codex.theme_type_variation = "RubricButton"
	codex.custom_minimum_size = Vector2(150, 144)
	codex.pressed.connect(_open_codex)
	top.add_child(codex)

	var vial_row: HBoxContainer = HBoxContainer.new()
	_col.add_child(vial_row)
	var tl: Label = Label.new()
	tl.text = tr("UI_THIRST")
	tl.theme_type_variation = "LightSmallLabel"
	vial_row.add_child(tl)
	var vial: ThirstVial = ThirstVial.new()
	vial.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vial_row.add_child(vial)

	letter_card = ParchmentPanel.new()
	letter_card.page_seed = float(def.number) * 1.93
	letter_card.padding = 34
	letter_card.burn_width = 22.0
	_col.add_child(letter_card)
	_letter_box = VBoxContainer.new()
	_letter_box.add_theme_constant_override("separation", 6)
	letter_card.add_child(_letter_box)
	sender_label = Label.new()
	sender_label.theme_type_variation = "SmallLabel"
	sender_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_letter_box.add_child(sender_label)
	letter_scroll = ScrollContainer.new()
	letter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	letter_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_letter_box.add_child(letter_scroll)

	status_label = Label.new()
	status_label.theme_type_variation = "LightSmallLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(status_label)

	tool_area = VBoxContainer.new()
	tool_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tool_area.add_theme_constant_override("separation", 12)
	_col.add_child(tool_area)

	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	_col.add_child(bottom)
	undo_button = Button.new()
	undo_button.text = tr("UI_UNDO")
	undo_button.pressed.connect(_on_undo)
	bottom.add_child(undo_button)
	hint_button = Button.new()
	hint_button.pressed.connect(_open_hints)
	bottom.add_child(hint_button)
	seal_button = Button.new()
	seal_button.text = tr("UI_SEAL")
	seal_button.theme_type_variation = "RubricButton"
	seal_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seal_button.pressed.connect(_on_seal)
	bottom.add_child(seal_button)

	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)
	EventBus.frenzy_triggered.connect(_on_frenzy)
	resized.connect(_layout)

	var a: Dictionary = ctx.progression.start_puzzle(def.id)
	var added: PackedStringArray = ctx.codex.unlock(def.codex_unlocks)
	if not added.is_empty():
		ctx.progression.save()
	_start_mode(int(a.get("variant", 0)), bool(a.get("frenzied", false)), a.get("tool_states", {}))
	_layout.call_deferred()
	_show_coach_marks.call_deferred()


func _layout() -> void:
	letter_card.custom_minimum_size.y = clampf(size.y * 0.30, 360.0, 720.0)


func _start_mode(variant: int, frenzied: bool, state: Dictionary) -> void:
	if mode != null:
		mode.queue_free()
		for c: Node in tool_area.get_children():
			c.queue_free()
		for c: Node in letter_scroll.get_children():
			c.queue_free()
	inst = PuzzleFactory.build(def, variant, frenzied)
	var script: GDScript = load("res://core/puzzle_modes/%s_mode.gd" % def.mode) as GDScript
	mode = script.new() as PuzzleMode
	add_child(mode)
	sender_label.text = tr(def.sender_keys[0]) if def.sender_keys.size() > 0 else ""
	sender_label.visible = sender_label.text != ""
	mode.setup(self, inst)
	if not state.is_empty():
		mode.set_state(state)
	refresh_bar()


## Instantiates tools/<id>/<id>.tscn into the tool area (or `parent`).
func add_tool(id: String, parent: Container = null) -> Control:
	var ps: PackedScene = load("res://tools/%s/%s.tscn" % [id, id]) as PackedScene
	var t: Control = ps.instantiate() as Control
	(parent if parent != null else tool_area).add_child(t)
	return t


## Puts a Control into the letter card's scroll area.
func set_letter_content(c: Control) -> void:
	for old: Node in letter_scroll.get_children():
		old.queue_free()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	letter_scroll.add_child(c)


func set_sender(text: String) -> void:
	sender_label.text = text
	sender_label.visible = text != ""


func charge(amount: int, reason: String) -> void:
	ctx.progression.charge(amount, reason)
	if reason == "trial":
		EventBus.sfx.emit("tick")
	refresh_bar()


## Call after any tool change: refreshes buttons and schedules an autosave.
func changed() -> void:
	refresh_bar()
	_save_timer.start()


func save_now() -> void:
	if _finished or mode == null:
		return
	var a: Dictionary = ctx.progression.active()
	if str(a.get("id", "")) == def.id:
		a["tool_states"] = mode.get_state()
		ctx.progression.save()


func refresh_bar() -> void:
	if mode == null:
		return
	status_label.text = mode.status_text()
	status_label.visible = status_label.text != ""
	seal_button.disabled = not mode.can_commit()
	var cost: int = ctx.hints.next_cost()
	hint_button.text = tr("UI_HINT_COST") % cost if cost > 0 else tr("UI_HINTS")


func _on_seal() -> void:
	if _finished or _frenzy_running:
		return
	EventBus.sfx.emit("quill")
	var v: PuzzleMode.Verdict = mode.commit()
	match v:
		PuzzleMode.Verdict.SOLVED:
			_solved()
		PuzzleMode.Verdict.STAGE:
			EventBus.sfx.emit("snap")
			EventBus.haptic.emit("snap")
			save_now()
			refresh_bar()
		PuzzleMode.Verdict.WRONG:
			wrong_feedback()
			charge(Thirst.config.wrong_commit, "wrong_commit")
			save_now()
		_:
			pass


func wrong_feedback() -> void:
	EventBus.sfx.emit("wrong")
	EventBus.haptic.emit("thud")
	EventBus.toast.emit(tr("UI_WRONG_%d" % (randi() % 4 + 1)))
	if not Settings.clear_mind:
		var p: Vector2 = letter_card.position
		var tw: Tween = create_tween()
		for i: int in range(4):
			tw.tween_property(letter_card, "position", p + Vector2(18.0 * (1 if i % 2 == 0 else -1), 0), 0.04)
		tw.tween_property(letter_card, "position", p, 0.04)


func _solved() -> void:
	_finished = true
	EventBus.sfx.emit("solve")
	EventBus.haptic.emit("pulse")
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(Palette.GOLD_LIGHT, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_STOP
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var rec: Dictionary = ctx.progression.complete_puzzle(def.id)
	var tw: Tween = create_tween()
	tw.tween_property(flash, "color:a", 0.0 if Settings.clear_mind else 0.35, 0.25)
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		done.emit({"puzzle_id": def.id, "record": rec, "unlocked": def.codex_unlocks}))


func _on_undo() -> void:
	if mode != null and mode.undo():
		EventBus.sfx.emit("page_turn")
		changed()


func _open_codex() -> void:
	var entry: String = def.codex_unlocks[0] if def.codex_unlocks.size() > 0 else ""
	main.open_overlay("codex", {"entry": entry})


func _open_hints() -> void:
	HintPanel.open(self, ctx.hints, def)


func _on_frenzy() -> void:
	if _frenzy_running or _finished or not is_inside_tree():
		return
	_frenzy_running = true
	save_now()
	EventBus.sfx.emit("frenzy")
	EventBus.haptic.emit("thud")
	if main.has_method("blood_drips"):
		main.call("blood_drips", 1.0)
	var o: Screen = main.call("open_overlay", "dialogue", {"id": def.frenzy_dialogue})
	o.done.connect(func(_r: Dictionary) -> void:
		ctx.progression.record_frenzy(def.id)
		var a: Dictionary = ctx.progression.active()
		_start_mode(int(a.get("variant", 1)), true, {})
		_frenzy_running = false
		EventBus.toast.emit(tr("UI_FRENZY_AFTER")))


func _show_coach_marks() -> void:
	for tool_id: String in mode.coach_tools():
		if ctx.progression.coach_seen(tool_id):
			continue
		var target: Control = null
		for c: Node in _all_children(tool_area):
			if c.has_method("coach_rect") and str(c.get("tool_id")) == tool_id:
				target = c as Control
				break
		if target == null:
			continue
		ctx.progression.mark_coach_seen(tool_id)
		var cm: CoachMark = CoachMark.show_for(self, target.call("coach_rect"), tr("UI_COACH_" + tool_id.to_upper()))
		await cm.dismissed
	ctx.progression.save()


static func _all_children(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c: Node in n.get_children():
		out.append(c)
		out.append_array(_all_children(c))
	return out
