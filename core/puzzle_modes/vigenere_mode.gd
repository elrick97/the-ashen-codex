extends PuzzleMode
## Vigenere: the Multi-Wheel holds one drum per key column; the Tally Scroll counts each
## column; the Kasiski Lens (long-press the letter) or the Column Loom (IoC) finds the
## period when it is not given. Letters-only text in groups of five, coloured by strand.

var wheels: MultiWheel = null
var tally: TallyScroll = null
var lens: KasiskiLens = null
var loom: ColumnLoom = null
var card: InterlinearText = null
var cipher: String = ""
var repeats: Array[Dictionary] = []
var period_max: int = 12


func _build() -> void:
	cipher = inst.ciphertexts[0]
	period_max = int(inst.param("period_max", 12))
	var given: int = int(inst.param("period_given", 0))
	card = InterlinearText.new()
	host.set_letter_content(card)
	var tools: Array[Control] = []
	var labels: PackedStringArray = PackedStringArray()
	if inst.def.tools.has("kasiski_lens"):
		lens = host.add_tool("kasiski_lens") as KasiskiLens
		repeats = Kasiski.find_repeats(cipher, 3, 8)
		lens.configure(cipher.length(), 2, period_max, repeats.size())
		lens.period_chosen.connect(_choose_period)
		lens.state_changed.connect(_update_lens_tally)
		card.cell_long_pressed.connect(_on_long_press)
		track(lens)
		tools.append(lens)
		labels.append("UI_TAB_LENS")
	if inst.def.tools.has("column_loom"):
		loom = host.add_tool("column_loom") as ColumnLoom
		loom.configure(period_max)
		loom.n_changed.connect(_on_loom)
		loom.period_chosen.connect(_choose_period)
		track(loom)
		tools.append(loom)
		labels.append("UI_TAB_LOOM")
	wheels = host.add_tool("multi_wheel") as MultiWheel
	wheels.configure(given if given > 0 else 1, given <= 0, period_max, inst.def.brute_force_costed)
	wheels.shifts_changed.connect(func(_s: PackedInt32Array) -> void: sync_views())
	wheels.period_changed.connect(func(_p: int) -> void: _period_changed())
	wheels.drum_notch.connect(func(_d: int) -> void: spend_trial())
	wheels.drum_selected.connect(func(d: int) -> void:
		tally.column = d
		_update_tally())
	track(wheels)
	tools.append(wheels)
	labels.append("UI_TAB_WHEELS")
	tally = host.add_tool("tally_scroll") as TallyScroll
	tally.configure(false, true, inst.trial_cost if inst.def.brute_force_costed else 0)
	tally.set_english(Frequency.ENGLISH, Frequency.COMMON_BIGRAMS, Frequency.COMMON_TRIGRAMS)
	tally.column_selected.connect(func(_c: int) -> void: _update_tally())
	tally.read_as.connect(_on_read_as)
	track(tally)
	tools.append(tally)
	labels.append("UI_TAB_TALLY")
	make_tabs(tools, labels)
	if loom != null:
		_on_loom(loom.n)
	_period_changed()


func _period_changed() -> void:
	tally.set_columns(wheels.period)
	_update_tally()
	sync_views()


func _update_tally() -> void:
	var col: int = tally.column
	if col >= 0 and col < wheels.period:
		var cc: PackedInt32Array = Frequency.counts(Vigenere.columns(cipher, wheels.period)[col])
		tally.set_counts(cc)
		tally.show_read_as_e = true
		tally.set_alignment(wheels.shifts[col], Frequency.profile_match(cc, wheels.shifts[col]))
	else:
		tally.set_counts(Frequency.counts(cipher))
		tally.show_read_as_e = false
		tally.set_alignment(-1, -1.0)
	tally.select_letter(-1)


func sync_views() -> void:
	var plain: String = Vigenere.decrypt_with_shifts(cipher, wheels.shifts)
	card.set_pair(TextUtil.group(cipher), TextUtil.group(plain))
	var tc: int = tally.column if tally != null else -1
	if tc >= 0 and tc < wheels.period:
		var cc2: PackedInt32Array = Frequency.counts(Vigenere.columns(cipher, wheels.period)[tc])
		tally.set_alignment(wheels.shifts[tc], Frequency.profile_match(cc2, wheels.shifts[tc]))
	var p: int = wheels.period
	card.cipher_colors.clear()
	if p > 1 or loom != null:
		var strands: int = loom.n if loom != null and tabs.size() > 0 and current_tab < tabs.size() and tabs[current_tab] == loom else p
		for i: int in range(cipher.length()):
			card.cipher_colors[PuzzleMode.grouped_index_of_letter(i)] = Palette.strand(i % maxi(strands, 1))
	card.refresh()
	host.refresh_bar()


func _on_read_as(letter: int, plain_letter: int) -> void:
	var col: int = tally.column
	if col < 0 or col >= wheels.period:
		return
	spend_trial()
	wheels.set_shift(col, Caesar.shift_between(plain_letter, letter))
	sync_views()


func _choose_period(n: int) -> void:
	wheels.snapshot()
	wheels.set_period(n)
	wheels.state_changed.emit()
	_period_changed()
	show_tab(tabs.find(wheels))
	EventBus.toast.emit(tr("UI_MODE_VIG_PERIOD") % n)


func _on_long_press(display_index: int) -> void:
	var li: int = PuzzleMode.letter_index_of_grouped(display_index)
	if li < 0:
		return
	var found: Dictionary = {}
	for r: Dictionary in repeats:
		var n: int = str(r["seq"]).length()
		for p: int in r["positions"]:
			if li >= p and li < p + n:
				found = r
				break
		if not found.is_empty():
			break
	lens.show_repeat(found)
	card.highlights.clear()
	if not found.is_empty():
		for p2: int in found["positions"]:
			for k: int in range(str(found["seq"]).length()):
				card.highlights[PuzzleMode.grouped_index_of_letter(p2 + k)] = Color(Palette.GOLD, 0.5)
	else:
		EventBus.sfx.emit("wrong_soft")
	card.refresh()
	show_tab(tabs.find(lens))
	_update_lens_tally()


func _update_lens_tally() -> void:
	if lens != null:
		lens.set_tally(Kasiski.factor_tally(lens.all_spacings(), 2, period_max))


func _on_loom(n: int) -> void:
	loom.set_strands(Vigenere.columns(cipher, n), IndexOfCoincidence.average_column_ic(cipher, n))
	card.cipher_colors.clear()
	for i: int in range(cipher.length()):
		card.cipher_colors[PuzzleMode.grouped_index_of_letter(i)] = Palette.strand(i % n)
	card.refresh()


func commit() -> Verdict:
	return Verdict.SOLVED if Vigenere.decrypt_with_shifts(cipher, wheels.shifts) == inst.plaintexts[0] else Verdict.WRONG


func status_text() -> String:
	var given: int = int(inst.param("period_given", 0))
	if given > 0:
		return tr("UI_MODE_VIG_GIVEN") % [given, inst.trial_cost]
	if lens != null:
		return tr("UI_MODE_VIG_KASISKI") % inst.trial_cost
	return tr("UI_MODE_VIG_IOC") % inst.trial_cost


func get_state() -> Dictionary:
	return {
		"wheels": wheels.get_state(), "tally": tally.get_state(), "tab": current_tab,
		"lens": lens.get_state() if lens != null else {}, "loom": loom.get_state() if loom != null else {},
	}


func set_state(d: Dictionary) -> void:
	if lens != null:
		lens.set_state(d.get("lens", {}))
		_update_lens_tally()
	if loom != null:
		loom.set_state(d.get("loom", {}))
	wheels.set_state(d.get("wheels", {}))
	tally.set_state(d.get("tally", {}))
	show_tab(int(d.get("tab", 0)))
	_period_changed()


func apply_solution() -> void:
	var shifts: PackedInt32Array = Vigenere.key_to_shifts(str(inst.key))
	wheels.set_state({"period": shifts.size(), "shifts": Array(shifts), "selected": 0})
	_period_changed()
