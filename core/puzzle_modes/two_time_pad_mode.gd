extends PuzzleMode
## Two letters under one pad. The Crib Dragger shows C1 xor C2 (= P1 xor P2); dragging a
## crib shows stream xor crib beneath it. A pin commits "this crib is in letter A (or B)
## here": right pins reveal both letters' bytes there; wrong pins cost Thirst.
## Seal once the tithe night and the traitor's name are fully recovered.

var dragger: CribDragger = null
var card_a: InterlinearText = null
var card_b: InterlinearText = null
var goal: Label = null
var stream: PackedByteArray = PackedByteArray()
var known: Array[PackedByteArray] = []


func _build() -> void:
	var overlap: int = int(inst.extras["overlap"])
	stream = XorOps.xor_bytes(inst.cipher_bytes[0], inst.cipher_bytes[1]).slice(0, overlap)
	for i: int in range(2):
		var kb: PackedByteArray = PackedByteArray()
		kb.resize(inst.plain_bytes[i].size())
		kb.fill(0)
		known.append(kb)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	goal = Label.new()
	goal.theme_type_variation = "RubricLabel"
	goal.add_theme_font_override("font", ThemeBuilder.font("mono_bold"))
	goal.add_theme_font_size_override("font_size", ThemeBuilder.size(36))
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(goal)
	for i: int in range(2):
		var l: Label = Label.new()
		l.text = tr(inst.def.sender_keys[i]) if i < inst.def.sender_keys.size() else ""
		l.theme_type_variation = "SmallLabel"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
		var t: InterlinearText = InterlinearText.new()
		t.show_cipher = false
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(t)
		if i == 0:
			card_a = t
		else:
			card_b = t
	host.set_letter_content(box)
	host.set_sender("")
	dragger = host.add_tool("crib_dragger") as CribDragger
	dragger.show_targets = false
	dragger.configure(stream, inst.extras["crib_tray"])
	dragger.offset_changed.connect(func(_o: int) -> void: _update_fragment())
	dragger.crib_changed.connect(func(_c: String) -> void: _update_fragment())
	dragger.row_changed.connect(func(_r: int) -> void: _update_fragment())
	dragger.pin_requested.connect(_on_pin)
	track(dragger)
	_update_fragment()
	sync_views()


func _update_fragment() -> void:
	var frag: PackedByteArray = Crib.drag(stream, dragger.crib.to_ascii_buffer(), dragger.offset)
	dragger.set_fragment(frag, Crib.reads_like_english(frag))


func _on_pin(offset: int, row: int) -> void:
	var crib: PackedByteArray = dragger.crib.to_ascii_buffer()
	if offset + crib.size() > stream.size():
		return
	var truth: PackedByteArray = inst.plain_bytes[row].slice(offset, offset + crib.size())
	var other_truth: PackedByteArray = inst.plain_bytes[1 - row].slice(offset, offset + crib.size())
	if truth != crib and other_truth == crib:
		# Right words, right place, other letter: the fragment makes that plain to a reader,
		# so the pin is filed where it belongs instead of being charged.
		row = 1 - row
		truth = other_truth
		EventBus.toast.emit(tr("UI_CRIBDRAG_OTHER_LETTER"))
	if truth == crib:
		var other: PackedByteArray = Crib.drag(stream, crib, offset)
		for i: int in range(crib.size()):
			known[row][offset + i] = crib[i]
			known[1 - row][offset + i] = other[i]
		EventBus.sfx.emit("quill")
		EventBus.haptic.emit("snap")
		host.changed()
	else:
		host.wrong_feedback()
		host.charge(inst.trial_cost, "trial")
	sync_views()


func _text_of(row: int) -> String:
	var kb: PackedByteArray = known[row]
	var out: PackedByteArray = PackedByteArray()
	for i: int in range(kb.size()):
		out.append(kb[i] if kb[i] != 0 else 95) # "_" for unknown
	return out.get_string_from_ascii()


func _target_text(t: Dictionary) -> String:
	var s: String = _text_of(int(t["msg"]))
	return s.substr(int(t["start"]), int(t["length"]))


func targets_revealed() -> bool:
	for t: Dictionary in inst.extras["targets"]:
		var kb: PackedByteArray = known[int(t["msg"])]
		for i: int in range(int(t["start"]), int(t["start"]) + int(t["length"])):
			if kb[i] == 0:
				return false
	return true


func sync_views() -> void:
	card_a.set_pair(_text_of(0), _text_of(0))
	card_b.set_pair(_text_of(1), _text_of(1))
	dragger.set_known(0, known[0])
	dragger.set_known(1, known[1])
	var tl: Array[Dictionary] = []
	for t: Dictionary in inst.extras["targets"]:
		tl.append({"label": str(t["label_key"]), "text": _target_text(t)})
	dragger.set_targets(tl)
	var lines: PackedStringArray = PackedStringArray()
	for t2: Dictionary in tl:
		lines.append("%s %s" % [tr(str(t2["label"])), str(t2["text"])])
	goal.text = "\n".join(lines)
	host.refresh_bar()


func can_commit() -> bool:
	return targets_revealed()


func commit() -> Verdict:
	return Verdict.SOLVED if targets_revealed() else Verdict.WRONG


func status_text() -> String:
	return tr("UI_MODE_OTP") % inst.trial_cost


func get_state() -> Dictionary:
	return {"known_a": BytesUtil.to_hex(known[0]), "known_b": BytesUtil.to_hex(known[1]), "dragger": dragger.get_state()}


func set_state(d: Dictionary) -> void:
	for i: int in range(2):
		var kb: PackedByteArray = BytesUtil.from_hex(str(d.get("known_a" if i == 0 else "known_b", "")))
		if kb.size() == known[i].size():
			known[i] = kb
	dragger.set_state(d.get("dragger", {}))
	_update_fragment()
	sync_views()


## Reveals the target phrases only (as a player who dragged the right cribs would).
func apply_solution() -> void:
	for t: Dictionary in inst.extras["targets"]:
		var m: int = int(t["msg"])
		for i: int in range(int(t["start"]), int(t["start"]) + int(t["length"])):
			known[m][i] = inst.plain_bytes[m][i]
			known[1 - m][i] = inst.plain_bytes[1 - m][i]
	sync_views()
