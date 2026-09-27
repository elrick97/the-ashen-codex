extends PuzzleMode
## Bit Rosary, three stages:
##  1. Find the key byte K that pours letter A into letter B (A xor K = B).
##  2. Pour a word with K, then pour it again: XOR undoes itself.
##  3. Single-byte XOR: turn the Key Dial; the English-ness gauge scores each reading.

var rosary: BitRosary = null
var dial: KeyDial = null
var grid: ByteGrid = null
var lesson: Label = null
var card: VBoxContainer = null
var stage: int = 1
var k: int = 0
var pours: int = 0
var a: int = 0
var b: int = 0
var word: PackedByteArray = PackedByteArray()


func _build() -> void:
	a = int(inst.extras["stage1_a"])
	b = int(inst.extras["stage1_b"])
	word = inst.extras["stage2_word"]
	card = VBoxContainer.new()
	lesson = Label.new()
	lesson.theme_type_variation = "MonoLabel"
	lesson.add_theme_font_size_override("font_size", ThemeBuilder.size(52))
	lesson.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(lesson)
	grid = ByteGrid.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(grid)
	host.set_letter_content(card)
	rosary = host.add_tool("bit_rosary") as BitRosary
	rosary.bead_flipped.connect(_on_flip)
	rosary.pour_pressed.connect(_on_pour)
	track(rosary)
	dial = host.add_tool("key_dial") as KeyDial
	dial.set_columns(1)
	dial.value_changed.connect(func(_c: int, _v: int) -> void: sync_views())
	track(dial)
	_enter_stage(1)


func _enter_stage(s: int) -> void:
	stage = s
	rosary.visible = stage < 3
	lesson.visible = stage < 3
	dial.visible = stage == 3
	if stage == 2:
		pours = 0
	sync_views()
	host.refresh_bar()


func _on_flip(_row: int, bit: int) -> void:
	if stage != 1:
		return
	k ^= 1 << bit
	sync_views()


func _on_pour() -> void:
	if stage != 2:
		return
	pours = mini(pours + 1, 2)
	sync_views()
	host.changed()


func sync_views() -> void:
	match stage:
		1:
			rosary.set_rows([
				{"label": "UI_ROSARY_A", "value": a, "kind": "given"},
				{"label": "UI_ROSARY_KEY", "value": k, "editable": true, "kind": "key"},
				{"label": "UI_ROSARY_RESULT", "value": a ^ k, "kind": "result"},
				{"label": "UI_ROSARY_TARGET", "value": b, "kind": "target"}])
			rosary.set_pour("")
			lesson.text = tr("UI_ROSARY_EQ1") % [String.chr(a), BytesUtil.byte_to_bits(k), _glyph(a ^ k), String.chr(b)]
			grid.set_bytes(PackedByteArray([a, k, a ^ k, b]))
			host.set_sender(tr("UI_ROSARY_STAGE1") % [String.chr(a), String.chr(b)])
		2:
			var key2: int = a ^ b
			var shown: PackedByteArray = word
			if pours == 1:
				shown = XorOps.xor_single(word, key2)
			elif pours >= 2:
				shown = XorOps.xor_single(XorOps.xor_single(word, key2), key2)
			var first: int = shown[0] if shown.size() > 0 else 0
			rosary.set_rows([
				{"label": "UI_ROSARY_WORD", "value": word[0] if word.size() > 0 else 0, "kind": "given"},
				{"label": "UI_ROSARY_KEY", "value": key2, "kind": "key"},
				{"label": "UI_ROSARY_RESULT", "value": first, "kind": "result"}])
			rosary.set_pour(tr("UI_ROSARY_POUR_AGAIN") if pours == 1 else (tr("UI_ROSARY_POUR") if pours == 0 else ""))
			grid.set_bytes(shown)
			lesson.text = tr("UI_ROSARY_EQ2") % [word.get_string_from_ascii(), BytesUtil.to_printable(shown)]
			host.set_sender(tr("UI_ROSARY_STAGE2") % pours)
		3:
			var c: PackedByteArray = inst.cipher_bytes[0]
			var dec: PackedByteArray = XorOps.xor_single(c, dial.values[0])
			grid.set_bytes(c, dec)
			dial.set_gauges(PackedFloat32Array([EnglishScore.gauge(dec)]))
			host.set_sender(tr(inst.def.sender_keys[0]) if inst.def.sender_keys.size() > 0 else "")
	host.refresh_bar()


static func _glyph(v: int) -> String:
	return String.chr(v) if v >= 33 and v <= 126 else "0x" + BytesUtil.byte_to_hex(v)


func can_commit() -> bool:
	return stage != 2 or pours >= 2


func commit() -> Verdict:
	match stage:
		1:
			if (a ^ k) == b:
				_enter_stage(2)
				return Verdict.STAGE
			return Verdict.WRONG
		2:
			if pours >= 2:
				_enter_stage(3)
				return Verdict.STAGE
			return Verdict.NONE
	return Verdict.SOLVED if dial.values[0] == int(inst.key) else Verdict.WRONG


func status_text() -> String:
	return tr("UI_MODE_ROSARY_%d" % stage)


func coach_tools() -> PackedStringArray:
	return PackedStringArray(["bit_rosary"]) if stage < 3 else PackedStringArray(["key_dial"])


func get_state() -> Dictionary:
	return {"stage": stage, "k": k, "pours": pours, "rosary": rosary.get_state(), "dial": dial.get_state()}


func set_state(d: Dictionary) -> void:
	k = int(d.get("k", 0))
	rosary.set_state(d.get("rosary", {}))
	dial.set_state(d.get("dial", {}))
	_enter_stage(int(d.get("stage", 1)))
	pours = int(d.get("pours", 0))
	sync_views()


func apply_solution() -> void:
	k = a ^ b
	_enter_stage(3)
	dial.set_value(0, int(inst.key))
	sync_views()
