class_name ReportPanel
extends OverlayPanel
## End-of-day summary. This is the moment the player sees whether the shift
## actually made money.

var report: Dictionary = {}
var _body: VBoxContainer
var _headline: Label


func _init() -> void:
	title_text = "Day Report"


func _build_content() -> void:
	content.add_child(UIKit.section_header("Summary", UIKit.FILIGREE))

	_headline = UIKit.label("", 20, UIKit.CREAM)
	_headline.add_theme_font_override("font", UIKit.ui_font(700, 2))
	content.add_child(_headline)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	fit_to_viewport(scroll, 0.46, 360.0)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 4)
	scroll.add_child(_body)
	content.add_child(UIKit.hsep(6))

	content.add_child(UIKit.section_header("Close shift", UIKit.FILIGREE_DIM))

	var next_button := UIKit.gold_slab("Start next day", 50)
	next_button.pressed.connect(_on_next_day)
	content.add_child(next_button)
	var menu_button := UIKit.slab_button("Back to main menu", UIKit.FILIGREE_DIM, 44)
	menu_button.pressed.connect(_on_menu)
	content.add_child(menu_button)


func set_report(data: Dictionary) -> void:
	report = data
	if visible:
		_refresh()


func _on_open() -> void:
	_refresh()


func _refresh() -> void:
	if _body == null:
		return
	for child in _body.get_children():
		child.queue_free()
	var day := int(report.get("day", Game.day))
	var revenue := int(report.get("revenue", 0))
	var expenses := int(report.get("expenses", 0))
	var profit := int(report.get("profit", revenue - expenses))
	var served := int(report.get("served", 0))
	var lost := int(report.get("lost", 0))
	var rating := float(report.get("rating", 0.0))
	var rep := float(report.get("reputation", Progression.reputation))

	_headline.text = "Day %d closed" % day
	if profit >= 0:
		_headline.add_theme_color_override("font_color", UIKit.GREEN)
	else:
		_headline.add_theme_color_override("font_color", Color("ff8a6a"))

	_row("Sales revenue", "₹%d" % revenue, UIKit.CREAM)
	_row("Supplies & upgrades", "- ₹%d" % expenses, UIKit.MUTED)
	_row("Net profit", "₹%d" % profit, UIKit.GREEN if profit >= 0 else Color("ff8a6a"))
	_row("Puris served", str(served), UIKit.CREAM)
	_row("Customers lost", str(lost), UIKit.RED if lost > 0 else UIKit.MUTED)
	_row("Tips earned", "₹%d" % int(report.get("tips", 0)), UIKit.GOLD)
	_row("Best combo", "x%d" % int(report.get("best_combo", 0)), UIKit.TEAL)
	_row("Average rating", "%d%%" % int(round(rating * 100.0)), UIKit.CREAM)
	_row("Reputation", "%d / 100" % int(round(rep)), UIKit.ORANGE)
	_row("Day theme", String(report.get("theme", "CLEAR DAY")), UIKit.GOLD)
	var xp_gained := int(report.get("xp_gained", 0))
	var level := int(report.get("level", Progression.level))
	_row("XP earned", "%d (+ %d / %d XP)" % [xp_gained, Progression.xp, Progression.xp_to_next()], UIKit.TEAL)
	_row("Level", "LV %d - %s" % [level, Progression.level_title()], UIKit.ORANGE)
	_add_goals(report.get("goals", {}))

	if lost > 0:
		var tip := UIKit.label("Tip: start a puri the moment an order appears. Patience runs out fast.", 14, UIKit.MUTED)
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(tip)


func _add_goals(stored: Variant) -> void:
	if typeof(stored) != TYPE_DICTIONARY:
		return
	var data: Dictionary = stored
	var all: Array = data.get("goals", [])
	if all.is_empty():
		return
	_body.add_child(UIKit.hsep(6))
	var header := UIKit.label("DAILY GOALS   %d / %d" % [
		int(data.get("completed", 0)), all.size(),
	], 16, UIKit.ORANGE)
	_body.add_child(header)
	for entry in all:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var goal: Dictionary = entry
		var done := bool(goal.get("done", false))
		var value := "DONE" if done else "%d / %d" % [
			int(goal.get("progress", 0)), int(goal.get("target", 1)),
		]
		_row(String(goal.get("label", "Goal")), value, UIKit.GREEN if done else UIKit.MUTED)


func _row(label_text: String, value_text: String, value_color: Color) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var left := UIKit.kicker(label_text, UIKit.MUTED, 12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var right := UIKit.label(value_text, 16, value_color)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(right)
	_body.add_child(row)


func _on_next_day() -> void:
	close()
	Game.next_day()


func _on_menu() -> void:
	close()
	Game.quit_to_menu()
