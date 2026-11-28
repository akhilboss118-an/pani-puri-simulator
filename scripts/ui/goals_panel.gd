class_name GoalsPanel
extends OverlayPanel
## Daily goals screen. Shows the three rotating tasks, their live progress and
## the cash/XP awarded for each. Progress updates even while the panel is open.

var _hint: Label
var _list: VBoxContainer


func _init() -> void:
	title_text = "Daily Goals"


func _build_content() -> void:
	_hint = UIKit.label("", 14, UIKit.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_hint)
	content.add_child(UIKit.hsep(4))

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	content.add_child(_list)
	content.add_child(UIKit.hsep(6))
	var back := UIKit.slab_button("Back to stall", UIKit.FILIGREE_DIM, 44)
	back.pressed.connect(close)
	content.add_child(back)

	Events.goals_changed.connect(func(_data: Dictionary):
		if visible:
			_refresh()
	)
	Events.goal_progress.connect(func(_id: String, _current: int, _target: int):
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
	var data: Dictionary = Goals.to_dict()
	var all: Array = data.get("goals", [])
	_hint.text = "Day %d  -  %d of %d complete. Rewards pay out the moment a goal is met." % [
		int(data.get("day", Game.day)), int(data.get("completed", 0)), all.size(),
	]
	for entry in all:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var goal: Dictionary = entry
		var done := bool(goal.get("done", false))
		var label_text := "[DONE]  " if done else "[    ]  "
		label_text += String(goal.get("label", "Goal"))
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 3)
		var title := UIKit.label(label_text, 17, UIKit.GREEN if done else UIKit.CREAM)
		title.add_theme_font_override("font", UIKit.ui_font(700, 2))
		card.add_child(title)
		var reward := UIKit.kicker("Reward: Rs %d   +%d XP" % [
			int(goal.get("reward_cash", 0)), int(goal.get("reward_xp", 0)),
		], UIKit.MUTED, 11)
		card.add_child(reward)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = maxi(1, int(goal.get("target", 1)))
		bar.value = int(goal.get("progress", 0))
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 3)
		bar.add_theme_stylebox_override("background", UIKit.bar_track(3))
		bar.add_theme_stylebox_override("fill", UIKit.thin_bar(UIKit.GREEN if done else UIKit.GOLD, 3))
		card.add_child(bar)

		var slab := PanelContainer.new()
		slab.add_theme_stylebox_override("panel", UIKit.slab_style(0.72, 12,
			UIKit.GREEN if done else UIKit.FILIGREE_DIM))
		slab.add_child(card)
		_list.add_child(slab)
