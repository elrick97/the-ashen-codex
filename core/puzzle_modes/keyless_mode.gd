extends PuzzleMode
## Keyless court notes (ROT13 / Atbash). The wheel has Shift and Mirror modes; each note
## keeps its own wheel setting. Sealing needs every note read by the right scheme, then
## the concept question: what actually protects these letters?

var wheel: CipherWheel = null
var card: InterlinearText = null
var note_bar: HBoxContainer = null
var note_buttons: Array[Button] = []
var settings: Array[Dictionary] = [] # per note {"shift", "mode"}
var current: int = 0
var _loading: bool = false


func _build() -> void:
	card = InterlinearText.new()
	host.set_letter_content(card)
	note_bar = HBoxContainer.new()
	note_bar.add_theme_constant_override("separation", 10)
	host.tool_area.add_child(note_bar)
	var g: ButtonGroup = ButtonGroup.new()
	for i: int in range(inst.ciphertexts.size()):
		settings.append({"shift": 0, "mode": CipherWheel.MODE_SHIFT})
		var b: Button = Button.new()
		b.text = tr("UI_KEYLESS_NOTE") % (i + 1)
		b.toggle_mode = true
		b.button_group = g
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(select_note.bind(i))
		note_bar.add_child(b)
		note_buttons.append(b)
	wheel = host.add_tool("cipher_wheel") as CipherWheel
	wheel.configure(true, false)
	wheel.shift_changed.connect(func(_s: int) -> void: _store())
	wheel.wheel_mode_changed.connect(func(_m: String) -> void: _store())
	track(wheel)
	select_note(0)


func select_note(i: int) -> void:
	current = i
	for k: int in range(note_buttons.size()):
		note_buttons[k].set_pressed_no_signal(k == i)
	_loading = true
	wheel.set_state(settings[i])
	wheel.undo_stack.clear()
	_loading = false
	var sk: String = inst.def.sender_keys[i] if i < inst.def.sender_keys.size() else ""
	host.set_sender(tr(sk) if sk != "" else "")
	EventBus.sfx.emit("page_turn")
	sync_views()


func _store() -> void:
	if _loading:
		return
	settings[current] = wheel.get_state()
	sync_views()


func _reading(i: int) -> String:
	var s: Dictionary = settings[i]
	var c: String = inst.ciphertexts[i]
	if str(s["mode"]) == CipherWheel.MODE_MIRROR:
		return Caesar.atbash(c)
	return Caesar.decrypt(c, int(s["shift"]))


func note_read_correctly(i: int) -> bool:
	return _reading(i) == inst.plaintexts[i]


func sync_views() -> void:
	card.set_pair(inst.ciphertexts[current], _reading(current))
	for k: int in range(note_buttons.size()):
		note_buttons[k].text = tr("UI_KEYLESS_NOTE") % (k + 1)


func commit() -> Verdict:
	for i: int in range(inst.ciphertexts.size()):
		if not note_read_correctly(i):
			return Verdict.WRONG
	var opts: PackedStringArray = PackedStringArray()
	for k: Variant in inst.param("answer_keys", []):
		opts.append(tr(str(k)))
	var panel: ChoicePanel = ChoicePanel.ask(host, tr(str(inst.param("question_key", ""))), opts)
	panel.chosen.connect(func(idx: int) -> void:
		host.resolve(Verdict.SOLVED if idx == int(inst.param("correct_answer", 0)) else Verdict.WRONG))
	return Verdict.NONE


func status_text() -> String:
	return tr("UI_MODE_KEYLESS")


func get_state() -> Dictionary:
	return {"settings": settings.duplicate(true), "current": current}


func set_state(d: Dictionary) -> void:
	var s: Array = d.get("settings", [])
	for i: int in range(mini(s.size(), settings.size())):
		var e: Dictionary = s[i]
		settings[i] = {"shift": int(e.get("shift", 0)), "mode": str(e.get("mode", CipherWheel.MODE_SHIFT))}
	select_note(clampi(int(d.get("current", 0)), 0, settings.size() - 1))


func apply_solution() -> void:
	var schemes: Array = inst.key
	for i: int in range(settings.size()):
		settings[i] = {"shift": 13, "mode": CipherWheel.MODE_SHIFT} if schemes[i] == "rot13" else {"shift": 0, "mode": CipherWheel.MODE_MIRROR}
	select_note(current)
