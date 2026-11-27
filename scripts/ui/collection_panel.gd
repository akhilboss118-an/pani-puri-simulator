class_name CollectionPanel
extends OverlayPanel
## Badges and recipe mastery in one scrollable screen.

var _hint: Label
var _list: VBoxContainer


func _init() -> void:
	title_text = "Collection"


func _build_content() -> void:
	_hint = UIKit.label("", 15, UIKit.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 520)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	content.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	var back := UIKit.button("Back to stall", 44)
	back.pressed.connect(close)
	content.add_child(back)

	Events.achievement_unlocked.connect(func(_id: String, _title: String, _c: int, _x: int):
		if visible:
			_refresh()
	)
	Events.achievement_progress.connect(func(_id: String, _value: int):
		if visible:
			_refresh()
	)
	Events.recipe_mastery_changed.connect(func(_id: String, _stars: int):
		if visible:
			_refresh()
	)


func _on_open() -> void:
	_refresh()


func _refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	_hint.text = "%d of %d badges earned. 3-star recipes pay 10%% more." % [
		Achievements.unlocked_count(), Achievements.DEFS.size(),
	]

	var header := UIKit.label("ACHIEVEMENTS", 18, UIKit.ORANGE)
	_list.add_child(header)
	for def in Achievements.DEFS:
		var entry: Dictionary = def
		var id := String(entry["id"])
		var done := Achievements.unlocked.has(id)
		var line := "[DONE]  " if done else "[    ]  "
		line += String(entry["title"]) + "   " + Achievements.progress_text(id)
		var name_label := UIKit.label(line, 16, UIKit.GREEN if done else UIKit.CREAM)
		_list.add_child(name_label)
		_list.add_child(UIKit.label("        " + String(entry["desc"]), 13, UIKit.MUTED))

	_list.add_child(UIKit.hsep(8))
	var recipes_header := UIKit.label("RECIPE MASTERY", 18, UIKit.ORANGE)
	_list.add_child(recipes_header)
	for recipe in GameData.recipes():
		var stars := Progression.recipe_stars(recipe.id)
		var stats: Dictionary = Progression.recipe_stats.get(recipe.id, {})
		var locked := Progression.level < recipe.unlock_level
		var label_text := "%s   [%s]" % [
			recipe.display_name,
			"locked LV %d" % recipe.unlock_level if locked else "*".repeat(stars) + ".".repeat(3 - stars),
		]
		var detail := "%d serves   best %d%%" % [
			int(stats.get("serves", 0)), int(round(float(stats.get("best", 0.0)) * 100.0)),
		]
		var row := HBoxContainer.new()
		var left := UIKit.label(label_text, 16, UIKit.MUTED if locked else UIKit.CREAM)
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(left)
		row.add_child(UIKit.label(detail, 14, UIKit.GOLD if stars >= 3 else UIKit.MUTED))
		_list.add_child(row)
