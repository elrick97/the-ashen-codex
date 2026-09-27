extends Screen
## Plays one dialogue (Vault frame or memory scene): portrait, parchment box, typewriter
## reveal, tap to complete/advance, fast-forward, history log and choices.

const CHARS_PER_SEC: float = 55.0
const LEFT_SPEAKERS: Array[String] = ["isaak", "kett", "wenna", "courier"]

var runner: DialogueRunner = DialogueRunner.new()
var _data: Dictionary = {}
var _portrait: Portrait = null
var _name: Label = null
var _text: Label = null
var _choices: VBoxContainer = null
var _prompt: Label = null
var _history: Array[String] = []
var _typing: bool = false
var _fast: bool = false
var _fast_btn: Button = null
var _box: ParchmentPanel = null
var _whispers: WhisperLayer = null


func _build() -> void:
	_data = ctx.db.dialogue(str(args.get("id", "")))
	var location: String = str(_data.get("location", "vault"))
	var bg: VaultBackdrop = VaultBackdrop.new()
	bg.kind = "marsh" if location == "memory" else "vault"
	add_child(bg)
	Audio.set_ambience(str(_data.get("ambience", "marsh" if location == "memory" else "vault")))

	_portrait = Portrait.new()
	_portrait.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(_portrait)
	if location == "vault":
		_whispers = WhisperLayer.new()
		add_child(_whispers)

	var root: MarginContainer = make_safe_root(36)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	root.add_child(col)
	var top: HBoxContainer = HBoxContainer.new()
	col.add_child(top)
	var place: Label = Label.new()
	place.text = tr("UI_PLACE_VAULT") if location == "vault" else tr("UI_PLACE_MEMORY")
	place.theme_type_variation = "LightSmallLabel"
	place.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(place)
	var hist: Button = Button.new()
	hist.text = tr("UI_HISTORY")
	hist.theme_type_variation = "GhostButton"
	hist.pressed.connect(_show_history)
	top.add_child(hist)
	_fast_btn = Button.new()
	_fast_btn.text = tr("UI_FAST")
	_fast_btn.theme_type_variation = "GhostButton"
	_fast_btn.toggle_mode = true
	_fast_btn.toggled.connect(func(on: bool) -> void:
		_fast = on
		if on and not _typing and not runner.has_choices():
			_advance())
	top.add_child(_fast_btn)

	var grow: Control = Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(grow)

	_box = ParchmentPanel.new()
	_box.page_seed = 2.0
	_box.custom_minimum_size = Vector2(0, 560)
	col.add_child(_box)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 20)
	_box.add_child(inner)
	_name = Label.new()
	_name.theme_type_variation = "RubricLabel"
	inner.add_child(_name)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	inner.add_child(_text)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 18)
	inner.add_child(_choices)
	_prompt = Label.new()
	_prompt.text = tr("UI_TAP_CONTINUE")
	_prompt.theme_type_variation = "SmallLabel"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inner.add_child(_prompt)

	resized.connect(_layout_portrait)
	_layout_portrait.call_deferred()
	runner.effect.connect(_on_effect)
	EventBus.dialogue_active.emit(true)
	_show(runner.start(_data, ctx.progression.flags))


func _exit_tree() -> void:
	EventBus.dialogue_active.emit(false)


func _layout_portrait() -> void:
	var vs: Vector2 = size
	var h: float = vs.y - 560.0 - 180.0
	_portrait.size = Vector2(vs.x * 0.8, maxf(400.0, h))
	_portrait.position = Vector2(vs.x * 0.1, 150.0)


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		tapped = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	if tapped:
		accept_event()
		_on_tap()


func _on_tap() -> void:
	if _typing:
		_text.visible_ratio = 1.0
		_typing = false
		_after_typed()
		return
	if runner.has_choices():
		return
	_advance()


func _advance() -> void:
	EventBus.sfx.emit("page_turn")
	_show(runner.next())


func _show(node: Dictionary) -> void:
	for c: Node in _choices.get_children():
		c.queue_free()
	if node.is_empty():
		done.emit({})
		return
	var who: String = str(node.get("speaker", "narrator"))
	_name.text = tr("SPK_" + who.to_upper()) if who != "narrator" else ""
	_name.visible = who != "narrator"
	_text.text = tr(str(node.get("text", "")))
	_text.theme_type_variation = "InkLabel"
	if who == "narrator":
		_text.add_theme_font_override("font", ThemeBuilder.font("italic"))
	else:
		_text.remove_theme_font_override("font")
	_portrait.speaker = who
	_portrait.facing_left = not LEFT_SPEAKERS.has(who)
	_history.append(("%s: %s" % [_name.text, _text.text]) if _name.visible else _text.text)
	if node.has("sfx"):
		EventBus.sfx.emit(str(node["sfx"]))
	_prompt.visible = false
	_text.visible_ratio = 0.0
	_typing = true
	var dur: float = 0.0 if _fast else float(_text.text.length()) / CHARS_PER_SEC
	var tw: Tween = create_tween()
	tw.tween_property(_text, "visible_ratio", 1.0, dur)
	tw.tween_callback(func() -> void:
		if _typing:
			_typing = false
			_after_typed())


func _after_typed() -> void:
	var choices: Array[Dictionary] = runner.visible_choices()
	if choices.is_empty():
		_prompt.visible = true
		if _fast:
			get_tree().create_timer(0.55).timeout.connect(func() -> void:
				if _fast and not _typing and is_inside_tree():
					_advance())
		return
	_fast = false
	_fast_btn.set_pressed_no_signal(false)
	for i: int in range(choices.size()):
		var b: Button = Button.new()
		b.text = tr(str(choices[i].get("text", "")))
		b.theme_type_variation = "RubricButton" if i == 0 else "Button"
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_choose.bind(i))
		_choices.add_child(b)


func _choose(i: int) -> void:
	EventBus.sfx.emit("quill")
	EventBus.haptic.emit("snap")
	var labels: Array[Dictionary] = runner.visible_choices()
	if i < labels.size():
		_history.append("> " + tr(str(labels[i].get("text", ""))))
	_show(runner.choose(i))


func _on_effect(set_flags: Dictionary, thirst_delta: int) -> void:
	ctx.progression.apply_flags(set_flags)
	if thirst_delta != 0:
		Thirst.apply_delta(thirst_delta, "story")
	ctx.progression.save()


func _show_history() -> void:
	var panel: Control = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(dim)
	var m: MarginContainer = MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm: Vector4 = safe_margins()
	m.add_theme_constant_override("margin_left", int(sm.x + 48))
	m.add_theme_constant_override("margin_right", int(sm.z + 48))
	m.add_theme_constant_override("margin_top", int(sm.y + 64))
	m.add_theme_constant_override("margin_bottom", int(sm.w + 48))
	panel.add_child(m)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	m.add_child(col)
	var title: Label = Label.new()
	title.text = tr("UI_HISTORY")
	title.theme_type_variation = "LightHeaderLabel"
	col.add_child(title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var body: Label = Label.new()
	body.theme_type_variation = "LightLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = "\n\n".join(PackedStringArray(_history))
	scroll.add_child(body)
	var close: Button = Button.new()
	close.text = tr("UI_CLOSE")
	close.pressed.connect(panel.queue_free)
	col.add_child(close)
	scroll.ready.connect(func() -> void: scroll.scroll_vertical = 1 << 20)
