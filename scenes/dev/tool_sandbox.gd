extends Control
## Dev sandbox: every tactile tool, playable with sample data from the crypto core.
## Run: $GODOT --path . res://scenes/dev/tool_sandbox.tscn   (tap the tool names)
## Or pass `-- <tool_id>` to open one tool directly.

const TOOLS: Array[String] = ["cipher_wheel", "tally_scroll", "substitution_board", "multi_wheel",
	"kasiski_lens", "column_loom", "bit_rosary", "key_dial", "hamming_comb", "crib_dragger"]
const SAMPLE: String = "THE STEWARD SENDS THE TITHE ROLL AT THE NEW MOON AND THE REEVE MUST COUNT THE HEADS OF HOLLOWMERE BEFORE THE CARTS COME"

var _area: Control = null
var _card: InterlinearText = null
var _tool: ToolBase = null
var _status: Label = null


func _ready() -> void:
	theme = ThemeBuilder.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: ColorRect = ColorRect.new()
	bg.color = Palette.SOOT
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m: MarginContainer = MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(k, 24)
	add_child(m)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	m.add_child(col)
	var picker: HFlowContainer = HFlowContainer.new()
	col.add_child(picker)
	for id: String in TOOLS:
		var b: Button = Button.new()
		b.text = id
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(open_tool.bind(id))
		picker.add_child(b)
	var card: ParchmentPanel = ParchmentPanel.new()
	card.custom_minimum_size = Vector2(0, 360)
	col.add_child(card)
	var sc: ScrollContainer = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(sc)
	_card = InterlinearText.new()
	_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_card)
	_status = Label.new()
	_status.theme_type_variation = "LightSmallLabel"
	col.add_child(_status)
	_area = VBoxContainer.new()
	_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_area)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	open_tool(args[0] if args.size() > 0 and TOOLS.has(args[0]) else "cipher_wheel")
	if args.size() > 1:
		_shoot(args[1])


func _shoot(path: String) -> void:
	for _i: int in range(20):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit(0)


func open_tool(id: String) -> void:
	if _tool != null:
		_tool.queue_free()
	_tool = (load("res://tools/%s/%s.tscn" % [id, id]) as PackedScene).instantiate() as ToolBase
	_area.add_child(_tool)
	_status.text = id
	var cipher: String = Caesar.encrypt(SAMPLE, 7)
	_card.show_plain = true
	_card.set_pair(cipher, Caesar.decrypt(cipher, 0))
	match id:
		"cipher_wheel":
			var w: CipherWheel = _tool as CipherWheel
			w.configure(true, false)
			w.shift_changed.connect(func(k: int) -> void: _card.set_plain(Caesar.decrypt(cipher, k)))
		"tally_scroll":
			var t: TallyScroll = _tool as TallyScroll
			t.configure(true, true, 1)
			t.set_english(Frequency.ENGLISH, Frequency.COMMON_BIGRAMS, Frequency.COMMON_TRIGRAMS)
			t.set_counts(Frequency.counts(cipher))
			t.set_ngrams(Frequency.top_ngrams(cipher, 2, 8, true), Frequency.top_ngrams(cipher, 3, 8, true))
			t.read_as.connect(func(i: int, p: int) -> void: _card.set_plain(Caesar.decrypt(cipher, Caesar.shift_between(p, i))))
		"substitution_board":
			var key: String = Substitution.random_key(Pcg32.new(3))
			var sc2: String = Substitution.encrypt(SAMPLE, key)
			var b: SubstitutionBoard = _tool as SubstitutionBoard
			var tiles: Array[Dictionary] = []
			var counts: PackedInt32Array = Frequency.counts(sc2)
			for i: int in Frequency.ranked(sc2):
				if counts[i] > 0:
					tiles.append({"c": String.chr(65 + i), "n": counts[i]})
			b.set_tiles(tiles)
			b.configure_crib("THE TITHE", sc2)
			var update: Callable = func() -> void:
				var m2: Dictionary = {}
				for k2: Variant in b.mapping.keys():
					m2[str(k2).unicode_at(0)] = str(b.mapping[k2]).unicode_at(0)
				_card.set_pair(sc2, Substitution.decrypt_partial(sc2, m2))
				b.set_crib_status(Crib.substitution_letter_status(sc2, b.crib_text, b.crib_offset), Crib.substitution_fits(sc2, b.crib_text, b.crib_offset))
			b.mapping_changed.connect(update)
			b.crib_moved.connect(func(_o: int) -> void: update.call())
			update.call()
		"multi_wheel":
			var vc: String = Vigenere.encrypt(TextUtil.letters_only(SAMPLE), "ASHEN")
			var mw: MultiWheel = _tool as MultiWheel
			mw.configure(5, true, 12, false)
			_card.set_pair(TextUtil.group(vc), TextUtil.group(vc))
			mw.shifts_changed.connect(func(s: PackedInt32Array) -> void: _card.set_plain(TextUtil.group(Vigenere.decrypt_with_shifts(vc, s))))
		"kasiski_lens":
			var kc: String = Vigenere.encrypt(TextUtil.letters_only(SAMPLE + SAMPLE), "MORROW")
			var kl: KasiskiLens = _tool as KasiskiLens
			var reps: Array[Dictionary] = Kasiski.find_repeats(kc)
			kl.configure(kc.length(), 2, 12, reps.size())
			_card.show_plain = false
			_card.set_pair(kc, kc)
			_card.cell_long_pressed.connect(func(i: int) -> void:
				for r: Dictionary in reps:
					for p: int in r["positions"]:
						if i >= p and i < p + str(r["seq"]).length():
							kl.show_repeat(r)
							kl.set_tally(Kasiski.factor_tally(kl.all_spacings(), 2, 12))
							return
				kl.show_repeat({}))
		"column_loom":
			var lc: String = Vigenere.encrypt(TextUtil.letters_only(SAMPLE), "VEIL")
			var lo: ColumnLoom = _tool as ColumnLoom
			lo.configure(12)
			_card.show_plain = false
			_card.set_pair(TextUtil.group(lc), "")
			var upd: Callable = func(n: int) -> void: lo.set_strands(Vigenere.columns(lc, n), IndexOfCoincidence.average_column_ic(lc, n))
			lo.n_changed.connect(upd)
			upd.call(1)
		"bit_rosary":
			var br: BitRosary = _tool as BitRosary
			var st: Dictionary = {"k": 0}
			var push: Callable = func() -> void:
				var k3: int = int(st["k"])
				br.set_rows([{"label": "UI_ROSARY_A", "value": 65, "kind": "given"}, {"label": "UI_ROSARY_KEY", "value": k3, "editable": true, "kind": "key"},
					{"label": "UI_ROSARY_RESULT", "value": 65 ^ k3, "kind": "result"}, {"label": "UI_ROSARY_TARGET", "value": 84, "kind": "target"}])
			br.bead_flipped.connect(func(_r: int, bit: int) -> void:
				st["k"] = int(st["k"]) ^ (1 << bit)
				push.call())
			push.call()
		"key_dial":
			var data: PackedByteArray = XorOps.xor_single(SAMPLE.to_ascii_buffer(), 0x5A)
			var kd: KeyDial = _tool as KeyDial
			kd.value_changed.connect(func(_c: int, v: int) -> void:
				var dec: PackedByteArray = XorOps.xor_single(data, v)
				kd.set_gauges(PackedFloat32Array([EnglishScore.gauge(dec)]))
				_card.set_pair(BytesUtil.to_printable(data), BytesUtil.to_printable(dec)))
			kd.value_changed.emit(0, 0)
		"hamming_comb":
			var hd: PackedByteArray = XorOps.xor_repeating((SAMPLE + " " + SAMPLE + " " + SAMPLE).to_ascii_buffer(), "NOX AETERNA".to_ascii_buffer())
			(_tool as HammingComb).set_scores(Hamming.keysize_scores(hd, 2, 40), 2, 40)
		"crib_dragger":
			var pad: PackedByteArray = XorOps.random_pad(Pcg32.new(9), 80)
			var p1: PackedByteArray = "THE TITHE IS TAKEN AT THE SALT BARN ON THE BLACK MOON".to_ascii_buffer()
			var p2: PackedByteArray = "OUR FRIEND IN THE QUILL IS BROTHER ANSGAR THE KEY WARDEN".to_ascii_buffer()
			var s: PackedByteArray = XorOps.xor_bytes(XorOps.xor_bytes(p1, pad), XorOps.xor_bytes(p2, pad))
			var cd: CribDragger = _tool as CribDragger
			cd.configure(s, PackedStringArray([" THE ", "TITHE", "BROTHER", "QUILL"]))
			var upd2: Callable = func() -> void:
				var frag: PackedByteArray = Crib.drag(s, cd.crib.to_ascii_buffer(), cd.offset)
				cd.set_fragment(frag, Crib.is_plausible_upper(frag))
			cd.offset_changed.connect(func(_o: int) -> void: upd2.call())
			cd.crib_changed.connect(func(_c: String) -> void: upd2.call())
			upd2.call()
