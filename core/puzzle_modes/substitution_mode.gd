extends PuzzleMode
## Monoalphabetic substitution: the Substitution Board holds the player's alphabet, the
## Tally Scroll counts letters (and pairs/triples when allowed), and an optional crib
## strip tests a known phrase at each offset. Partial reveals are free; sealing a wrong
## complete alphabet costs Thirst.

var board: SubstitutionBoard = null
var tally: TallyScroll = null
var card: InterlinearText = null
var cipher: String = "" # as displayed (grouped for letters-only)
var cipher_raw: String = ""
var grouped: bool = false
var crib: String = ""
## The crib is matched on letters only, so word shapes can't give its place away.
var cipher_letters: String = ""


func _build() -> void:
	cipher_raw = inst.ciphertexts[0]
	grouped = bool(inst.param("group5", false)) or inst.def.normalization == TextUtil.LETTERS_ONLY
	cipher = TextUtil.group(cipher_raw) if grouped else cipher_raw
	card = InterlinearText.new()
	card.cell_pressed.connect(_on_card_tap)
	host.set_letter_content(card)
	board = host.add_tool("substitution_board") as SubstitutionBoard
	var counts: PackedInt32Array = Frequency.counts(cipher_raw)
	var tiles: Array[Dictionary] = []
	for i: int in Frequency.ranked(cipher_raw):
		if counts[i] > 0:
			tiles.append({"c": String.chr(65 + i), "n": counts[i]})
	board.set_tiles(tiles)
	var crib_key: String = str(inst.param("crib_key", ""))
	if crib_key != "":
		crib = TextUtil.letters_only(tr(crib_key))
		cipher_letters = TextUtil.letters_only(cipher_raw)
		board.configure_crib(crib, cipher_letters)
		board.crib_moved.connect(func(_o: int) -> void: _update_crib())
		board.crib_pin_requested.connect(_pin_crib)
	board.mapping_changed.connect(sync_views)
	board.tile_selected.connect(_on_tile_selected)
	track(board)
	tally = host.add_tool("tally_scroll") as TallyScroll
	var ngrams: bool = bool(inst.param("ngrams", false))
	tally.configure(ngrams, false, 0)
	tally.set_english(Frequency.ENGLISH, Frequency.COMMON_BIGRAMS, Frequency.COMMON_TRIGRAMS)
	tally.set_counts(counts)
	if ngrams:
		tally.set_ngrams(Frequency.top_ngrams(cipher_raw, 2, 8, not grouped), Frequency.top_ngrams(cipher_raw, 3, 8, not grouped))
	tally.letter_selected.connect(func(i: int) -> void:
		if counts[i] > 0:
			_on_tile_selected(String.chr(65 + i)))
	tally.gram_selected.connect(_highlight_gram)
	track(tally)
	if crib != "":
		board.external_tabs = true
		make_tabs([board, board, tally], PackedStringArray(["UI_TAB_BOARD", "UI_CRIB_TAB", "UI_TAB_TALLY"]))
	else:
		make_tabs([board, tally], PackedStringArray(["UI_TAB_BOARD", "UI_TAB_TALLY"]))
	_update_crib()
	sync_views()


func _mapping_codes() -> Dictionary:
	var m: Dictionary = {}
	for k: Variant in board.mapping.keys():
		m[str(k).unicode_at(0)] = str(board.mapping[k]).unicode_at(0)
	return m


func sync_views() -> void:
	card.set_pair(cipher, Substitution.decrypt_partial(cipher, _mapping_codes()))
	host.refresh_bar()


func _on_tile_selected(c: String) -> void:
	board.select(c)
	tally.select_letter(c.unicode_at(0) - 65)
	card.underlined.clear()
	card.highlights.clear()
	for i: int in range(cipher.length()):
		if cipher[i] == c:
			card.underlined[i] = true
	_highlight_crib()
	card.refresh()


func _on_card_tap(i: int) -> void:
	var ch: String = cipher[i]
	if ch >= "A" and ch <= "Z":
		_on_tile_selected(ch)


func _highlight_gram(gram: String) -> void:
	card.highlights.clear()
	card.underlined.clear()
	if grouped:
		var start: int = cipher_raw.find(gram)
		while start >= 0:
			for k: int in range(gram.length()):
				card.highlights[PuzzleMode.grouped_index_of_letter(start + k)] = Color(Palette.GOLD, 0.45)
			start = cipher_raw.find(gram, start + 1)
	else:
		var s2: int = cipher.find(gram)
		while s2 >= 0:
			for k: int in range(gram.length()):
				card.highlights[s2 + k] = Color(Palette.GOLD, 0.45)
			s2 = cipher.find(gram, s2 + 1)
	card.refresh()


func _update_crib() -> void:
	if crib == "":
		return
	var o: int = board.crib_offset
	board.set_crib_status(Crib.substitution_letter_status(cipher_letters, crib, o), Crib.substitution_fits(cipher_letters, crib, o))
	card.highlights.clear()
	_highlight_crib()
	card.refresh()


## Gold under the letters the crib strip currently covers (crib offset is in letters).
func _highlight_crib() -> void:
	if crib == "":
		return
	var o: int = board.crib_offset
	var li: int = 0
	for i: int in range(cipher.length()):
		if TextUtil.is_upper(cipher.unicode_at(i)):
			if li >= o and li < o + crib.length():
				card.highlights[i] = Color(Palette.GOLD, 0.35)
			li += 1


func _pin_crib(offset: int) -> void:
	var m: Dictionary = Crib.substitution_mapping(cipher_letters, crib, offset)
	if m.is_empty():
		return
	var merged: Dictionary = board.mapping.duplicate()
	for c: Variant in m.keys():
		var cs: String = String.chr(int(c))
		var ps: String = String.chr(int(m[c]))
		# A locked tile stays where the player locked it, and a locked slot keeps its tile.
		if board.is_locked_tile(cs) or (board.locks.has(ps) and board._cipher_in_slot(ps) != cs):
			continue
		for other: Variant in merged.keys():
			if str(merged[other]) == ps:
				merged.erase(other)
		merged[cs] = ps
	board.snapshot()
	board.set_mapping(merged)
	board.state_changed.emit()
	EventBus.sfx.emit("tile_snap")
	EventBus.haptic.emit("snap")
	sync_views()


## Tabs may share a tool (the board serves Alphabet and Crib); show whichever is chosen.
func show_tab(i: int) -> void:
	current_tab = i
	var chosen: Control = tabs[i] if i < tabs.size() else null
	for t: Control in tabs:
		t.visible = t == chosen
	for k: int in range(tab_buttons.size()):
		tab_buttons[k].set_pressed_no_signal(k == i)
	if crib != "" and chosen == board:
		board.tab = 1 if i == 1 else 0
		board.call("_sync_tabs")
	EventBus.sfx.emit("page_turn")


func can_commit() -> bool:
	return board != null and board.is_complete()


func commit() -> Verdict:
	return Verdict.SOLVED if Substitution.decrypt_partial(cipher_raw, _mapping_codes()) == inst.plaintexts[0] else Verdict.WRONG


func status_text() -> String:
	if crib != "":
		return tr("UI_MODE_SUB_CRIB")
	if bool(inst.param("ngrams", false)):
		return tr("UI_MODE_SUB_NGRAMS")
	return tr("UI_MODE_SUB")


func get_state() -> Dictionary:
	return {"board": board.get_state(), "tally": tally.get_state(), "tab": current_tab}


func set_state(d: Dictionary) -> void:
	board.set_state(d.get("board", {}))
	tally.set_state(d.get("tally", {}))
	show_tab(int(d.get("tab", 0)))
	_update_crib()
	sync_views()


func apply_solution() -> void:
	var m: Dictionary = {}
	var true_map: Dictionary = Substitution.mapping_for_text(cipher_raw, str(inst.key))
	for c: Variant in true_map.keys():
		m[String.chr(int(c))] = String.chr(int(true_map[c]))
	board.set_mapping(m)
	sync_views()
