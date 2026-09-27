class_name HintPanel
extends Control
## Brother Kett's remembered advice: bought tiers (free to reread) and the next tier's
## price in Thirst. Optional confirmation before paying (Settings > hint_confirm).

var _host: PuzzleHost = null
var _hints: HintService = null
var _def: PuzzleDef = null
var _list: VBoxContainer = null
var _buy: Button = null


static func open(host: PuzzleHost, hints: HintService, def: PuzzleDef) -> HintPanel:
	var p: HintPanel = HintPanel.new()
	p._host = host
	p._hints = hints
	p._def = def
	host.add_child(p)
	p._build()
	return p


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if ToolBase.is_press(e):
			queue_free())
	add_child(dim)
	var panel: ParchmentPanel = ParchmentPanel.new()
	panel.page_seed = 21.0
	add_child(panel)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	panel.add_child(col)
	var title: Label = Label.new()
	title.text = tr("UI_HINT_TITLE")
	title.theme_type_variation = "HeaderLabel"
	col.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16)
	col.add_child(_list)
	_buy = Button.new()
	_buy.theme_type_variation = "RubricButton"
	_buy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_buy.pressed.connect(_on_buy)
	col.add_child(_buy)
	var close: Button = Button.new()
	close.text = tr("UI_CLOSE")
	close.pressed.connect(queue_free)
	col.add_child(close)
	_refresh()
	var place: Callable = func() -> void:
		var vs: Vector2 = get_viewport_rect().size
		var m: Vector4 = SafeArea.margins(self)
		panel.size = Vector2(vs.x - 60.0 - m.x - m.z, 0)
		panel.reset_size()
		panel.position = Vector2(30.0 + m.x, vs.y - m.w - panel.size.y - 30.0)
	panel.resized.connect(place)
	place.call_deferred()


func _refresh() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	var bought: int = _hints.bought()
	if bought == 0:
		var none: Label = Label.new()
		none.text = tr("UI_HINT_NONE")
		none.theme_type_variation = "SmallLabel"
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(none)
	for tier: int in range(1, bought + 1):
		var head: Label = Label.new()
		head.text = tr("UI_HINT_TIER_%d" % tier)
		head.theme_type_variation = "RubricLabel"
		_list.add_child(head)
		var body: Label = Label.new()
		body.text = _hints.text(_def, tier)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_override("font", ThemeBuilder.font("italic"))
		_list.add_child(body)
	var cost: int = _hints.next_cost()
	_buy.visible = cost > 0
	if cost > 0:
		_buy.text = tr("UI_HINT_BUY") % [tr("UI_HINT_TIER_%d" % (bought + 1)), cost]


func _on_buy() -> void:
	if Settings.hint_confirm:
		var d: ConfirmDialog = ConfirmDialog.ask(self, tr("UI_HINT_CONFIRM") % _hints.next_cost(), tr("UI_HINT_CONFIRM_YES"), tr("UI_CANCEL"))
		d.answered.connect(func(yes: bool) -> void:
			if yes:
				_do_buy())
	else:
		_do_buy()


func _do_buy() -> void:
	if _hints.buy_next() > 0:
		EventBus.sfx.emit("quill")
		_host.refresh_bar()
		if is_inside_tree():
			_refresh()
