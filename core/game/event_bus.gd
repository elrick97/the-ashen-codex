extends Node
## Autoload "EventBus": global signals only, no state.

@warning_ignore("unused_signal")
signal thirst_changed(value: float, delta: float, reason: String)
@warning_ignore("unused_signal")
signal thirst_level_changed(level: int)
@warning_ignore("unused_signal")
signal frenzy_triggered()
@warning_ignore("unused_signal")
signal settings_changed()
@warning_ignore("unused_signal")
signal codex_unlocked(entry_id: String)
@warning_ignore("unused_signal")
signal toast(text: String)
## kind: "tick", "snap", "thud", "pulse"
@warning_ignore("unused_signal")
signal haptic(kind: String)
@warning_ignore("unused_signal")
signal sfx(id: String)
@warning_ignore("unused_signal")
signal dialogue_active(active: bool)
