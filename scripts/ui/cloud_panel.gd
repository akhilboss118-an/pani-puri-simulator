class_name CloudPanel
extends OverlayPanel
## Offline-first backup, shareable save code and local leaderboards.

var _status: Label
var _code_edit: LineEdit
var _board: VBoxContainer


func _init() -> void:
	title_text = "Save & Leaderboards"


func _build_content() -> void:
	content.add_child(UIKit.section_header("Backup", UIKit.FILIGREE))
	_status = UIKit.label("", 13, UIKit.MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_status)

	var backup := UIKit.slab_button("Save backup", UIKit.FILIGREE, 42)
	backup.pressed.connect(func(): CloudSave.snapshot(); _refresh())
	content.add_child(backup)
	var restore := UIKit.slab_button("Restore backup", UIKit.FILIGREE, 42)
	restore.pressed.connect(func(): CloudSave.restore(); _refresh())
	content.add_child(restore)

	content.add_child(UIKit.section_header("Save code", UIKit.FILIGREE_DIM))
	var copy := UIKit.slab_button("Copy save code", UIKit.FILIGREE, 42)
	copy.pressed.connect(func():
		var code := CloudSave.export_code()
		DisplayServer.clipboard_set(code)
		Events.toast.emit("Save code copied.", "good")
	)
	content.add_child(copy)

	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = "PASTE SAVE CODE..."
	content.add_child(_code_edit)
	var import_button := UIKit.slab_button("Import save code", UIKit.FILIGREE, 42)
	import_button.pressed.connect(func(): CloudSave.import_code(_code_edit.text); _refresh())
	content.add_child(import_button)

	content.add_child(UIKit.hsep(6))
	content.add_child(UIKit.section_header("Leaderboard", UIKit.GOLD))
	_board = VBoxContainer.new()
	_board.add_theme_constant_override("separation", 4)
	content.add_child(_board)

	content.add_child(UIKit.hsep(4))
	var back := UIKit.slab_button("Back", UIKit.FILIGREE_DIM, 44)
	back.pressed.connect(close)
	content.add_child(back)

	Events.settings_changed.connect(func(): if visible: _refresh())


func _on_open() -> void:
	_refresh()


func _refresh() -> void:
	_status.text = "Offline backup ready. Save code can move progress between devices."
	for child in _board.get_children():
		child.queue_free()
	var rows := CloudSave.leaderboard("best_day_profit")
	if rows.is_empty():
		_board.add_child(UIKit.label("No scores yet", 14, UIKit.MUTED))
		return
	for i in mini(5, rows.size()):
		var row: Dictionary = rows[i]
		_board.add_child(UIKit.label("#%d  Rs %d  day %d" % [
			i + 1, int(row.get("value", 0)), int(row.get("day", 0)),
		], 14, UIKit.CREAM))
