extends PuzzleMode
## Caesar: the Cipher Wheel sets the shift; the letter card previews the reading live.
## Costed (rusted) puzzles charge per notch and per "read the peak as E" from the Tally.

var wheel: CipherWheel = null
var tally: TallyScroll = null
var card: InterlinearText = null
var cipher: String = ""


func _build() -> void:
	cipher = inst.ciphertexts[0]
	card = InterlinearText.new()
	host.set_letter_content(card)
	wheel = host.add_tool("cipher_wheel") as CipherWheel
	wheel.configure(false, inst.def.brute_force_costed)
	wheel.shift_changed.connect(func(_s: int) -> void: sync_views())
	wheel.notch_crossed.connect(func(_s: int) -> void: spend_trial())
	track(wheel)
	var tools: Array[Control] = [wheel]
	var labels: PackedStringArray = PackedStringArray(["UI_TAB_WHEEL"])
	if inst.def.tools.has("tally_scroll"):
		tally = host.add_tool("tally_scroll") as TallyScroll
		tally.configure(false, true, inst.trial_cost if inst.def.brute_force_costed else 0)
		tally.set_english(Frequency.ENGLISH, Frequency.COMMON_BIGRAMS, Frequency.COMMON_TRIGRAMS)
		tally.set_counts(Frequency.counts(cipher))
		tally.read_as_e.connect(_on_read_as_e)
		tally.letter_selected.connect(_underline_letter)
		track(tally)
		tools.append(tally)
		labels.append("UI_TAB_TALLY")
	make_tabs(tools, labels)
	sync_views()


func sync_views() -> void:
	card.set_pair(cipher, Caesar.decrypt(cipher, wheel.shift))


func _on_read_as_e(letter: int) -> void:
	spend_trial()
	wheel.turn_to(Caesar.shift_between(Frequency.INDEX_E, letter))
	show_tab(0)
	host.changed()


func _underline_letter(letter: int) -> void:
	card.underlined.clear()
	var code: int = 65 + letter
	for i: int in range(cipher.length()):
		if cipher.unicode_at(i) == code:
			card.underlined[i] = true
	card.refresh()


func commit() -> Verdict:
	return Verdict.SOLVED if wheel.shift == int(inst.key) else Verdict.WRONG


func status_text() -> String:
	return tr("UI_MODE_CAESAR_RUSTED") % inst.trial_cost if inst.def.brute_force_costed else tr("UI_MODE_CAESAR")


func get_state() -> Dictionary:
	return {"wheel": wheel.get_state(), "tally": tally.get_state() if tally != null else {}, "tab": current_tab}


func set_state(d: Dictionary) -> void:
	wheel.set_state(d.get("wheel", {}))
	if tally != null:
		tally.set_state(d.get("tally", {}))
	show_tab(int(d.get("tab", 0)))
	sync_views()


func apply_solution() -> void:
	wheel.set_state({"shift": int(inst.key), "mode": CipherWheel.MODE_SHIFT})
	sync_views()
