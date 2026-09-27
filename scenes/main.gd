extends Control
## Root of the game: owns the screen stack, overlay screens (Codex, Settings), the
## ink-bleed transition, the Thirst overlay and toasts, and walks the story via
## Progression. See docs/TECH_DESIGN.md section 3.

const SCREENS: Dictionary = {
	"boot": "res://scenes/boot/boot.tscn",
	"title": "res://scenes/title/title.tscn",
	"dialogue": "res://scenes/dialogue/dialogue_screen.tscn",
	"puzzle": "res://scenes/puzzle_host/puzzle_host.tscn",
	"folio": "res://scenes/folio/folio.tscn",
	"summary": "res://scenes/summary/summary.tscn",
	"card": "res://scenes/card/card.tscn",
	"codex": "res://scenes/codex/codex.tscn",
	"settings": "res://scenes/settings/settings.tscn",
	"credits": "res://scenes/credits/credits.tscn",
}
const WIPE_SHADER: Shader = preload("res://ui/shaders/ink_wipe.gdshader")
const OVERLAY_SHADER: Shader = preload("res://ui/shaders/thirst_overlay.gdshader")

var ctx: GameContext = null
var screen: Screen = null
var screen_id: String = ""
var overlay: Screen = null

var _screen_root: Control = null
var _overlay_root: Control = null
var _wipe: ColorRect = null
var _wipe_mat: ShaderMaterial = null
var _thirst_rect: ColorRect = null
var _thirst_mat: ShaderMaterial = null
var _toast: Label = null
var _busy: bool = false
var _text_size: int = -1
var _time: float = 0.0
var _drip: float = 0.0
var _fx: Vector4 = Vector4.ZERO # vignette, ink, desat, pulse targets


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rebuild_theme()
	ctx = GameContext.create()
	_build_layers()
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.toast.connect(show_toast)
	EventBus.haptic.connect(_on_haptic)
	EventBus.thirst_level_changed.connect(_on_thirst_level)
	EventBus.codex_unlocked.connect(_on_codex_unlocked)
	_on_thirst_level(Thirst.level())
	if not Engine.has_meta("tour"):
		goto("boot")


func _process(delta: float) -> void:
	_time += delta
	if _thirst_rect.visible:
		_thirst_mat.set_shader_parameter("time", _time)
		_thirst_mat.set_shader_parameter("drip", _drip)


## Replaces the current screen behind the ink wipe.
func goto(id: String, a: Dictionary = {}) -> void:
	if _busy:
		await get_tree().process_frame
	_busy = true
	await _cover()
	close_overlay()
	if screen != null:
		screen.queue_free()
	screen = _instance(id)
	screen_id = id
	_screen_root.add_child(screen)
	screen.setup(ctx, self, a)
	screen.done.connect(_on_done.bind(id))
	await _reveal()
	_busy = false


## Instantly swaps screens without the wipe (screenshot tour).
func show_now(id: String, a: Dictionary = {}) -> Screen:
	close_overlay()
	if screen != null:
		screen.queue_free()
	screen = _instance(id)
	screen_id = id
	_screen_root.add_child(screen)
	screen.setup(ctx, self, a)
	screen.done.connect(_on_done.bind(id))
	return screen


## Opens Codex or Settings above the current screen (the screen underneath keeps its state).
func open_overlay(id: String, a: Dictionary = {}) -> Screen:
	close_overlay()
	overlay = _instance(id)
	_overlay_root.add_child(overlay)
	overlay.setup(ctx, self, a)
	overlay.done.connect(func(_r: Dictionary) -> void: close_overlay())
	overlay.modulate.a = 0.0
	create_tween().tween_property(overlay, "modulate:a", 1.0, 0.18)
	EventBus.sfx.emit("page_turn")
	return overlay


func close_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null


## Shows whatever the current story step asks for.
func run_story() -> void:
	var step: Dictionary = ctx.progression.current_step()
	if step.is_empty():
		goto("title")
		return
	var kind: String = str(step.get("type", ""))
	match kind:
		"dialogue":
			goto("dialogue", {"id": str(step["id"])})
		"puzzle":
			var pid: String = str(step["id"])
			if ctx.progression.is_solved(pid):
				# Resumed on the folio of a solved letter: show it again, don't replay it.
				var def: PuzzleDef = ctx.db.puzzle(pid)
				goto("folio", {"puzzle_id": pid, "record": ctx.progression.puzzle_record(pid), "unlocked": def.codex_unlocks if def != null else PackedStringArray()})
			else:
				goto("puzzle", {"id": pid})
		"summary":
			goto("summary", {"chapter": ctx.progression.current_chapter().id})
		"act_folio":
			goto("summary", {"act": ctx.progression.current_chapter().act})
		"card":
			goto("card", {"text": str(step.get("text", ""))})
		_:
			push_error("Main: unknown step type " + kind)
			ctx.progression.advance()
			run_story()


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.2)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: _toast.visible = false)


## Blood drips down from the top edge (threshold crossings and the frenzy).
func blood_drips(strength: float = 1.0) -> void:
	if Settings.clear_mind:
		return
	_thirst_rect.visible = true
	var tw: Tween = create_tween()
	tw.tween_property(self, "_drip", strength, 1.4).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.6)
	tw.tween_property(self, "_drip", 0.0, 1.2)
	tw.tween_callback(_apply_fx)


func _on_done(result: Dictionary, id: String) -> void:
	match id:
		"boot":
			goto("title")
		"title":
			match str(result.get("action", "")):
				"new":
					ctx.progression.new_game()
					run_story()
				"continue":
					var src: String = ctx.progression.continue_game()
					if src == "backup":
						show_toast(tr("UI_SAVE_RESTORED_BACKUP"))
					run_story()
				"credits":
					goto("credits")
				"settings":
					open_overlay("settings")
				"codex":
					open_overlay("codex")
		"dialogue", "folio", "summary":
			ctx.progression.advance()
			run_story()
		"puzzle":
			goto("folio", result)
		"card":
			ctx.progression.advance()
			goto("title")
		"credits":
			goto("title")


func _instance(id: String) -> Screen:
	var ps: PackedScene = load(SCREENS[id]) as PackedScene
	return ps.instantiate() as Screen


func _build_layers() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Palette.SOOT
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_screen_root = Control.new()
	_screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen_root)

	var thirst_layer: CanvasLayer = CanvasLayer.new()
	thirst_layer.layer = 10
	add_child(thirst_layer)
	_thirst_rect = ColorRect.new()
	_thirst_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thirst_mat = ShaderMaterial.new()
	_thirst_mat.shader = OVERLAY_SHADER
	_thirst_rect.material = _thirst_mat
	_thirst_rect.visible = false
	thirst_layer.add_child(_thirst_rect)

	var overlay_layer: CanvasLayer = CanvasLayer.new()
	overlay_layer.layer = 20
	add_child(overlay_layer)
	_overlay_root = Control.new()
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(_overlay_root)
	_overlay_root.theme = theme

	var toast_layer: CanvasLayer = CanvasLayer.new()
	toast_layer.layer = 30
	add_child(toast_layer)
	_toast = Label.new()
	_toast.theme = theme
	_toast.theme_type_variation = "LightLabel"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.04, 0.03, 0.92)
	sb.border_color = Palette.GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(28)
	_toast.add_theme_stylebox_override("normal", sb)
	toast_layer.add_child(_toast)

	var wipe_layer: CanvasLayer = CanvasLayer.new()
	wipe_layer.layer = 40
	add_child(wipe_layer)
	_wipe = ColorRect.new()
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wipe_mat = ShaderMaterial.new()
	_wipe_mat.shader = WIPE_SHADER
	_wipe.material = _wipe_mat
	_wipe.visible = false
	wipe_layer.add_child(_wipe)

	get_viewport().size_changed.connect(_layout_layers)
	_layout_layers()


func _layout_layers() -> void:
	var s: Vector2 = get_viewport_rect().size
	for r: Control in [_thirst_rect, _overlay_root, _wipe]:
		r.position = Vector2.ZERO
		r.size = s
	_thirst_mat.set_shader_parameter("rect_size", s)
	_wipe_mat.set_shader_parameter("rect_size", s)
	var m: Vector4 = SafeArea.margins(self)
	_toast.custom_minimum_size = Vector2(s.x - 160.0, 0)
	_toast.position = Vector2(80, m.y + 250.0)
	_toast.size = Vector2(s.x - 160.0, 0)


func _cover() -> void:
	_wipe.visible = true
	_wipe.mouse_filter = Control.MOUSE_FILTER_STOP
	if Settings.clear_mind:
		_wipe_mat.set_shader_parameter("progress", 1.0)
		_wipe.modulate.a = 0.0
		var f: Tween = create_tween()
		f.tween_property(_wipe, "modulate:a", 1.0, 0.2)
		await f.finished
		return
	_wipe.modulate.a = 1.0
	EventBus.sfx.emit("quill")
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: _wipe_mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.38)
	await tw.finished


func _reveal() -> void:
	if Settings.clear_mind:
		var f: Tween = create_tween()
		f.tween_property(_wipe, "modulate:a", 0.0, 0.2)
		await f.finished
	else:
		var tw: Tween = create_tween()
		tw.tween_method(func(v: float) -> void: _wipe_mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.42)
		await tw.finished
	_wipe.visible = false
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _rebuild_theme() -> void:
	if Settings.text_size == _text_size:
		return
	_text_size = Settings.text_size
	theme = ThemeBuilder.build()
	if _overlay_root != null:
		_overlay_root.theme = theme
	if _toast != null:
		_toast.theme = theme


func _on_settings_changed() -> void:
	_rebuild_theme()
	_apply_fx()


func _on_thirst_level(level: int) -> void:
	var prev: Vector4 = _fx
	_fx = Vector4(
		0.55 if level >= 1 else 0.0,
		0.6 if level >= 2 else 0.0,
		0.75 if level >= 3 else 0.0,
		1.0 if level >= 3 else 0.0)
	_apply_fx()
	if level > 0 and _fx.x + _fx.y + _fx.z > prev.x + prev.y + prev.z:
		blood_drips(0.5 + 0.25 * level)


func _apply_fx() -> void:
	var cm: bool = Settings.clear_mind
	var v: float = _fx.x
	_thirst_mat.set_shader_parameter("vignette", v * (0.5 if cm else 1.0))
	_thirst_mat.set_shader_parameter("ink", 0.0 if cm else _fx.y)
	_thirst_mat.set_shader_parameter("desat", 0.0 if cm else _fx.z)
	_thirst_mat.set_shader_parameter("pulse", 0.0 if cm else _fx.w)
	if cm:
		_drip = 0.0
	_thirst_rect.visible = v > 0.0 or _drip > 0.0


func _on_haptic(kind: String) -> void:
	var ms: Dictionary = {"tick": 8, "snap": 14, "pulse": 24, "thud": 40}
	Settings.vibrate(int(ms.get(kind, 10)))


func _on_codex_unlocked(entry_id: String) -> void:
	var e: CodexEntryDef = ctx.db.codex.get(entry_id, null) as CodexEntryDef
	if e != null:
		show_toast(tr("UI_CODEX_NEW") % tr(e.title_key))
