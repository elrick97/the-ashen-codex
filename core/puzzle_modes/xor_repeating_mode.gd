extends PuzzleMode
## Repeating-key XOR: the Hamming Comb suggests the key size; choosing it transposes the
## letter into that many strands, each set by one Key Dial column with its own
## English-ness gauge (the same scoring function the solver uses).

var comb: HammingComb = null
var dial: KeyDial = null
var grid: ByteGrid = null
var cipher: PackedByteArray = PackedByteArray()
var keysize: int = 0


func _build() -> void:
	cipher = inst.cipher_bytes[0]
	grid = ByteGrid.new()
	host.set_letter_content(grid)
	var lo: int = int(inst.param("keysize_min", 2))
	var hi: int = int(inst.param("keysize_max", 40))
	comb = host.add_tool("hamming_comb") as HammingComb
	comb.set_scores(Hamming.keysize_scores(cipher, lo, hi), lo, hi)
	comb.keysize_chosen.connect(_choose)
	track(comb)
	dial = host.add_tool("key_dial") as KeyDial
	dial.value_changed.connect(func(_c: int, _v: int) -> void: sync_views())
	dial.column_selected.connect(func(_c: int) -> void: sync_views())
	track(dial)
	make_tabs([comb, dial], PackedStringArray(["UI_TAB_COMB", "UI_TAB_DIAL"]))
	sync_views()


func _choose(k: int) -> void:
	keysize = k
	dial.set_columns(k)
	dial.state_changed.emit()
	show_tab(1)
	EventBus.toast.emit(tr("UI_MODE_REPXOR_SIZE") % k)
	sync_views()


func _key() -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	for v: int in dial.values:
		out.append(v)
	return out


func sync_views() -> void:
	if keysize <= 0:
		grid.set_bytes(cipher)
		host.refresh_bar()
		return
	var key: PackedByteArray = _key()
	grid.set_bytes(cipher, XorOps.xor_repeating(cipher, key))
	var cols: Array[PackedByteArray] = XorOps.transpose(cipher, keysize)
	var g: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(keysize):
		g.append(EnglishScore.gauge(XorOps.xor_single(cols[i], dial.values[i])))
	dial.set_gauges(g)
	grid.highlights.clear()
	for i: int in range(dial.selected, cipher.size(), keysize):
		grid.highlights[i] = Color(Palette.GOLD, 0.3)
	grid.queue_redraw()
	host.refresh_bar()


func can_commit() -> bool:
	return keysize > 0


func commit() -> Verdict:
	return Verdict.SOLVED if XorOps.xor_repeating(cipher, _key()) == inst.plain_bytes[0] else Verdict.WRONG


func status_text() -> String:
	return tr("UI_MODE_REPXOR_1") if keysize <= 0 else tr("UI_MODE_REPXOR_2") % keysize


func get_state() -> Dictionary:
	return {"keysize": keysize, "comb": comb.get_state(), "dial": dial.get_state(), "tab": current_tab}


func set_state(d: Dictionary) -> void:
	comb.set_state(d.get("comb", {}))
	keysize = int(d.get("keysize", 0))
	if keysize > 0:
		dial.set_state(d.get("dial", {}))
	show_tab(int(d.get("tab", 0)))
	sync_views()


func apply_solution() -> void:
	var key: PackedByteArray = inst.key
	_choose(key.size())
	for i: int in range(key.size()):
		dial.set_value(i, key[i])
	comb.set_state({"selected": key.size()})
	sync_views()
