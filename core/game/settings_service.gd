extends Node
## Autoload "Settings": player settings in user://settings.json (atomic write).

const FILE_NAME: String = "settings.json"
const TEXT_SCALES: Array[float] = [1.0, 1.18, 1.36]

var directory: String = "user://"
var text_size: int = 0
## Clear Mind / Reduce Motion: disables every distortion shader, wobble and shake.
var clear_mind: bool = false
var haptics: bool = true
var vol_master: float = 0.9
var vol_music: float = 0.7
var vol_sfx: float = 0.8
var hint_confirm: bool = true


func _ready() -> void:
	load_settings()


func text_scale() -> float:
	return TEXT_SCALES[clampi(text_size, 0, TEXT_SCALES.size() - 1)]


func to_dict() -> Dictionary:
	return {
		"text_size": text_size, "clear_mind": clear_mind, "haptics": haptics,
		"vol_master": vol_master, "vol_music": vol_music, "vol_sfx": vol_sfx,
		"hint_confirm": hint_confirm,
	}


func from_dict(d: Dictionary) -> void:
	text_size = clampi(int(d.get("text_size", text_size)), 0, TEXT_SCALES.size() - 1)
	clear_mind = bool(d.get("clear_mind", clear_mind))
	haptics = bool(d.get("haptics", haptics))
	vol_master = clampf(float(d.get("vol_master", vol_master)), 0.0, 1.0)
	vol_music = clampf(float(d.get("vol_music", vol_music)), 0.0, 1.0)
	vol_sfx = clampf(float(d.get("vol_sfx", vol_sfx)), 0.0, 1.0)
	hint_confirm = bool(d.get("hint_confirm", hint_confirm))


func path() -> String:
	return directory.path_join(FILE_NAME)


func load_settings() -> void:
	if FileAccess.file_exists(path()):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path()))
		if parsed is Dictionary:
			from_dict(parsed)
	apply()


func save_settings() -> void:
	var tmp: String = path() + ".tmp"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	DirAccess.rename_absolute(tmp, path())


## Sets one setting by name, applies it and saves.
func set_value(key: String, v: Variant) -> void:
	var d: Dictionary = to_dict()
	d[key] = v
	from_dict(d)
	apply()
	save_settings()


func apply() -> void:
	_set_bus("Master", vol_master)
	_set_bus("Music", vol_music)
	_set_bus("Ambience", vol_music)
	_set_bus("SFX", vol_sfx)
	_set_bus("UI", vol_sfx)
	EventBus.settings_changed.emit()


## Vibrates if haptics are on and the platform supports it.
func vibrate(ms: int) -> void:
	if haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _set_bus(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
		AudioServer.set_bus_mute(idx, linear <= 0.001)
