extends Node
## Cloud-ready backup + local leaderboards.
##
## Offline-first: snapshots are copied locally and a shareable base64 save code
## can move progress between devices. Play Games cloud sync can be enabled in a
## Play Store build when the Google Play Games plugin is added; see
## docs/play_store/. No network is required for the offline path.

const SAVE_PATH := "user://panipuri_save.json"
const BACKUP_PATH := "user://cloud_backup.json"
const META_PATH := "user://cloud_backup_meta.json"
const LEADERBOARD_PATH := "user://leaderboards.json"

var _leaderboards: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_leaderboards()


func snapshot() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		Events.toast.emit("No save to back up yet.", "info")
		return false
	var text := FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text()
	var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	if backup == null:
		return false
	backup.store_string(text)
	backup.close()
	var meta := FileAccess.open(META_PATH, FileAccess.WRITE)
	if meta != null:
		meta.store_string(JSON.stringify({
			"saved_at": Time.get_datetime_string_from_system(),
			"game_version": Game.VERSION,
			"day": Game.day,
		}, "\t"))
		meta.close()
	Events.toast.emit("Backup saved.", "good")
	return true


func restore() -> bool:
	if not FileAccess.file_exists(BACKUP_PATH):
		Events.toast.emit("No backup found.", "info")
		return false
	var text := FileAccess.open(BACKUP_PATH, FileAccess.READ).get_as_text()
	var out := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if out == null:
		return false
	out.store_string(text)
	out.close()
	var loaded := SaveManager.load_game()
	Events.toast.emit("Restored from backup." if loaded else "Backup could not be loaded.", "good" if loaded else "bad")
	return loaded


func export_code() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return ""
	var text := FileAccess.open(SAVE_PATH, FileAccess.READ).get_as_text()
	return Marshalls.raw_to_base64(text.to_utf8_buffer())


func import_code(code: String) -> bool:
	var cleaned := code.strip_edges().replace(" ", "").replace("\n", "").replace("\t", "")
	if cleaned.is_empty():
		return false
	var bytes := Marshalls.base64_to_raw(cleaned)
	if bytes.is_empty():
		return false
	var text := bytes.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		Events.toast.emit("Save code is not valid.", "bad")
		return false
	var out := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if out == null:
		return false
	out.store_string(text)
	out.close()
	var loaded := SaveManager.load_game()
	Events.toast.emit("Save code imported." if loaded else "Could not import save code.", "good" if loaded else "bad")
	return loaded


# -------------------------------------------------------------- leaderboards

func publish_score(metric: String, value: float) -> void:
	if not _leaderboards.has(metric):
		_leaderboards[metric] = []
	var list: Array = _leaderboards[metric]
	list.append({"value": value, "day": Game.day, "at": Time.get_datetime_string_from_system(), "prestige": Progression.prestige_level})
	list.sort_custom(func(a: Dictionary, b: Dictionary): return float(a["value"]) > float(b["value"]))
	while list.size() > 25:
		list.pop_back()
	_leaderboards[metric] = list
	_save_leaderboards()
	Events.settings_changed.emit()


func leaderboard(metric: String) -> Array:
	return (_leaderboards.get(metric, []) as Array).duplicate()


func _load_leaderboards() -> void:
	if not FileAccess.file_exists(LEADERBOARD_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.open(LEADERBOARD_PATH, FileAccess.READ).get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_leaderboards = parsed


func _save_leaderboards() -> void:
	var f := FileAccess.open(LEADERBOARD_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_leaderboards, "\t"))
		f.close()


## Play Games hook (no-op until the Google Play Games plugin is present).
func publish_play_games() -> bool:
	if OS.has_feature("android") and Engine.has_singleton("AndroidRuntime"):
		# TODO: call Play Games APIs when the plugin is added; offline data stays source of truth.
		return false
	return false
