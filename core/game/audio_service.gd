extends Node
## Autoload "Audio": bus layout, pooled SFX, looping ambience, Thirst heartbeat layers,
## and ducking of music/ambience while dialogue is on screen.
## Sounds are WAVs in res://audio/generated/<id>.wav (tools_dev/synth_sfx.py).
## Swap a file with the same name to upgrade a sound; no code changes needed.

const SFX_DIR: String = "res://audio/generated/"
const BUSES: Array[String] = ["Music", "SFX", "Ambience", "UI"]
const POOL_SIZE: int = 8
const DUCK_DB: float = -9.0

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _ambience: AudioStreamPlayer = null
var _ambience_id: String = ""
var _drone: AudioStreamPlayer = null
var _heartbeat: AudioStreamPlayer = null
var _duck_tween: Tween = null


func _ready() -> void:
	_ensure_buses()
	for i: int in range(POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_ambience = _make_loop_player("Ambience")
	_drone = _make_loop_player("Music")
	_heartbeat = _make_loop_player("SFX")
	EventBus.sfx.connect(play)
	EventBus.thirst_level_changed.connect(_on_thirst_level)
	EventBus.dialogue_active.connect(duck)
	Settings.apply()


func play(id: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var s: AudioStream = _stream(id)
	if s == null:
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.bus = "UI" if id.begins_with("ui_") else "SFX"
	p.play()


## "vault" or "marsh"; "" stops. Also starts the matching drone.
func set_ambience(id: String) -> void:
	if id == _ambience_id:
		return
	_ambience_id = id
	_crossfade(_ambience, _stream("amb_" + id) if id != "" else null)
	_crossfade(_drone, _stream("drone_" + id) if id != "" else null)


func duck(active: bool) -> void:
	if _duck_tween != null:
		_duck_tween.kill()
	_duck_tween = create_tween().set_parallel(true)
	var target: float = DUCK_DB if active else 0.0
	_duck_tween.tween_property(_ambience, "volume_db", target, 0.4)
	_duck_tween.tween_property(_drone, "volume_db", target, 0.4)


func _on_thirst_level(level: int) -> void:
	if level <= 0:
		_crossfade(_heartbeat, null)
		return
	var s: AudioStream = _stream("heartbeat")
	if _heartbeat.stream != s or not _heartbeat.playing:
		_crossfade(_heartbeat, s)
	_heartbeat.pitch_scale = 1.0 + 0.12 * float(level - 1)
	_heartbeat.volume_db = -14.0 + 4.0 * float(level)


func _stream(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	var path: String = SFX_DIR + id + ".wav"
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path) as AudioStream
	_streams[id] = s
	return s


func _make_loop_player(bus_name: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = bus_name
	add_child(p)
	p.finished.connect(func() -> void:
		if p.stream != null:
			p.play())
	return p


func _crossfade(player: AudioStreamPlayer, stream: AudioStream) -> void:
	var t: Tween = create_tween()
	if player.playing:
		t.tween_property(player, "volume_db", -40.0, 0.6)
	t.tween_callback(func() -> void:
		player.stop()
		player.stream = stream
		if stream != null:
			player.volume_db = -40.0
			player.play())
	if stream != null:
		t.tween_property(player, "volume_db", 0.0, 1.2)


func _ensure_buses() -> void:
	for b: String in BUSES:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var idx: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")
