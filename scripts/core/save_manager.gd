extends Node
## Versioned JSON save. Missing fields fall back to safe defaults so an older
## save never crashes a newer build.

const SAVE_PATH := "user://panipuri_save.json"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	if Game.state == Game.State.MENU:
		return false
	var data := {
		"version": SAVE_VERSION,
		"game_version": Game.VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"day": Game.day,
		"cash": Economy.cash,
		"total_revenue": Economy.total_revenue,
		"total_expenses": Economy.total_expenses,
		"stock": Inventory.to_dict(),
		"progress": Progression.to_dict(),
		"clock": Clock.to_dict(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is corrupt, starting a new game.")
		return false
	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("Save comes from a newer version; loading what we understand.")

	Game.day = maxi(1, int(data.get("day", 1)))
	Inventory.reset()
	var stock_data: Variant = data.get("stock", {})
	if typeof(stock_data) == TYPE_DICTIONARY:
		Inventory.from_dict(stock_data)
	Progression.from_dict(data.get("progress", {}))
	Clock.from_dict(data.get("clock", {}))

	Economy.reset()
	Economy.cash = maxi(0, int(data.get("cash", 500)))
	Economy.total_revenue = int(data.get("total_revenue", 0))
	Economy.total_expenses = int(data.get("total_expenses", 0))
	Economy.begin_day()
	Events.money_changed.emit(Economy.cash)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
