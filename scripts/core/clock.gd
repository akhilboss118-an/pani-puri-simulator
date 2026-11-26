extends Node
## Business hours. One day runs from 9:00 to 21:00 in game time, compressed
## into a short real-time shift so a session stays casual-friendly.

const START_MINUTES := 9 * 60
const END_MINUTES := 21 * 60
const DAY_REAL_SECONDS := 420.0

var minutes: int = START_MINUTES
var running: bool = false
var _last_emitted: int = -1
var _minute_accum: float = 0.0


func reset() -> void:
	minutes = START_MINUTES
	running = false
	_last_emitted = -1
	_minute_accum = 0.0
	_emit_time()


func begin_day() -> void:
	minutes = START_MINUTES
	running = true
	_last_emitted = -1
	_minute_accum = 0.0
	_emit_time()


func stop() -> void:
	running = false


## Resume a saved day from its stored time (continue, rather than a fresh 9 AM).
func resume() -> void:
	running = true
	_emit_time()


func _process(delta: float) -> void:
	if not running:
		return
	var game_minutes_per_second := float(END_MINUTES - START_MINUTES) / DAY_REAL_SECONDS
	_minute_accum += game_minutes_per_second * delta
	var step := int(_minute_accum)
	if step > 0:
		minutes += step
		_minute_accum -= float(step)
	if minutes != _last_emitted:
		_emit_time()
	if minutes >= END_MINUTES:
		running = false
		Game.end_day(false)


func _emit_time() -> void:
	_last_emitted = minutes
	var h := int(minutes / 60) % 24
	var m := int(minutes) % 60
	Events.time_changed.emit(h, m)


func hour() -> int:
	return int(minutes / 60) % 24


func time_string() -> String:
	var h := int(minutes / 60) % 24
	var m := int(minutes) % 60
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m, suffix]


func progress() -> float:
	return clampf(float(minutes - START_MINUTES) / float(END_MINUTES - START_MINUTES), 0.0, 1.0)


func is_late() -> bool:
	return minutes >= END_MINUTES - 90


func to_dict() -> Dictionary:
	return {"minutes": minutes}


func from_dict(data: Dictionary) -> void:
	minutes = int(data.get("minutes", START_MINUTES))
	_minute_accum = 0.0
	_emit_time()
