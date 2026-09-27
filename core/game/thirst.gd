extends Node
## Autoload "Thirst": Isaak's hunger, 0..100.
## Costs come from content/thirst_config.tres. Reaching frenzy_at emits frenzy_triggered
## once; the puzzle host plays the frenzy scene and then calls after_frenzy().

const CONFIG_PATH: String = "res://content/thirst_config.tres"
const MAX_VALUE: float = 100.0

var config: ThirstConfig = null
var value: float = 0.0
var _level: int = 0
var _frenzy_pending: bool = false


func _ready() -> void:
	config = load(CONFIG_PATH) as ThirstConfig
	if config == null:
		config = ThirstConfig.new()


## Sets the value without costs (loading a save). Updates the level silently.
func set_value(v: float) -> void:
	value = clampf(v, 0.0, MAX_VALUE)
	_level = config.level_for(value)
	_frenzy_pending = false
	EventBus.thirst_changed.emit(value, 0.0, "load")
	EventBus.thirst_level_changed.emit(_level)


func spend(amount: int, reason: String) -> void:
	if amount <= 0:
		return
	value = clampf(value + amount, 0.0, MAX_VALUE)
	EventBus.thirst_changed.emit(value, float(amount), reason)
	_update_level()
	if value >= config.frenzy_at and not _frenzy_pending:
		_frenzy_pending = true
		EventBus.frenzy_triggered.emit()


func restore(amount: int, reason: String = "restore") -> void:
	value = clampf(value - absi(amount), 0.0, MAX_VALUE)
	EventBus.thirst_changed.emit(value, -float(absi(amount)), reason)
	_update_level()


## Applies a signed story delta (dialogue `thirst` fields): negative restores.
func apply_delta(delta: int, reason: String) -> void:
	if delta > 0:
		spend(delta, reason)
	elif delta < 0:
		restore(-delta, reason)


func after_frenzy() -> void:
	value = float(config.frenzy_reset_to)
	_frenzy_pending = false
	EventBus.thirst_changed.emit(value, 0.0, "frenzy")
	_update_level()


func level() -> int:
	return _level


func is_frenzy_pending() -> bool:
	return _frenzy_pending


func _update_level() -> void:
	var l: int = config.level_for(value)
	if l != _level:
		_level = l
		EventBus.thirst_level_changed.emit(_level)
