class_name HUD
extends Control
## In-game HUD: money, time, reputation, active order, interaction prompt,
## toasts and (on touch devices) the virtual joystick and use button.
##
## The layout is built from floating glass cards rather than one long column,
## so the 3D street stays visible on a phone screen.

var player: Player

var _money_label: Label
var _day_label: Label
var _theme_label: Label
var _rep_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _fps_label: Label
var _fps_ticks: int = 0
var _fps_accum: float = 0.0
var _stock_warning: Label
var _rush_label: Label
var _combo_label: Label
var _tips_label: Label
var _goals_label: Label
var _badge_label: Label
var _order_card: PanelContainer
var _order_title: Label
var _order_body: Label
var _order_bar: ProgressBar
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _subtitle_panel: PanelContainer
var _subtitle_label: Label
var _subtitle_kicker: Label
var _subtitle_serial: int = 0
var _held_panel: PanelContainer
var _held_label: Label
var _toast_box: VBoxContainer
var _crosshair: Control
var _top_right: Control
var _top_left_panel: PanelContainer
var _touch_controls: Array[Control] = []

var _mobile: bool = false
var _joystick: StickInput
var _look_area: Control
var _look_touch: int = -1
var _look_last: Vector2 = Vector2.ZERO
var _patience_bucket: int = -1


func setup(p: Player) -> void:
	player = p
	_build()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UIKit.theme()
	_mobile = Game.is_mobile()

	if _mobile:
		_build_look_area()
	_build_top_left()
	_build_top_right()
	_build_order_card()
	_build_prompt()
	_build_subtitle()
	_build_held()
	_build_toasts()
	_build_crosshair()
	if _mobile:
		_build_touch_controls()

	Events.money_changed.connect(_on_money_changed)
	Events.time_changed.connect(_on_time_changed)
	Events.reputation_changed.connect(_on_reputation_changed)
	Events.xp_changed.connect(_on_xp_changed)
	Events.level_up.connect(_on_level_up)
	Events.prompt_changed.connect(_on_prompt_changed)
	Events.held_changed.connect(_on_held_changed)
	Events.order_updated.connect(_on_order_updated)
	Events.order_cleared.connect(_on_order_cleared)
	Events.toast.connect(_on_toast)
	Events.stock_changed.connect(_on_stock_changed)
	Events.overlay_changed.connect(_on_overlay_changed)
	Events.rush_hour_changed.connect(_on_rush_hour_changed)
	Events.combo_changed.connect(_on_combo_changed)
	Events.tip_earned.connect(_on_tip_earned)
	Events.goals_changed.connect(_on_goals_changed)
	Events.achievement_unlocked.connect(_on_achievement_changed)
	Events.achievement_progress.connect(_on_achievement_changed_broad)
	Events.day_theme_changed.connect(_on_theme_changed)
	Events.dialogue_spoken.connect(_on_dialogue_spoken)

	_on_money_changed(Economy.cash)
	_on_reputation_changed(Progression.reputation)
	_on_time_changed(Clock.hour(), 0)
	_on_xp_changed(Progression.level, Progression.xp, Progression.xp_to_next(), Progression.xp_ratio())
	_on_stock_changed("")
	_on_rush_hour_changed(Progression.rush_hour_active())
	_on_combo_changed(Orders.combo, Orders.combo_multiplier())
	_on_tip_earned(0, Orders.day_tips)
	_on_goals_changed(Goals.to_dict())
	_on_achievement_changed_broad("", 0)
	_on_theme_changed(Game.weather(), GameData.theme_label(Game.day))
	_on_prompt_changed("")
	_on_held_changed("")


# ------------------------------------------------------------------ top bars

func _glass(margin: int = 12, border: Color = Color(1, 0.93, 0.82, 0.12)) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UIKit.style(Color(0.055, 0.043, 0.035, 0.82), 16, border, 1, margin)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _build_top_left() -> void:
	var panel := _glass(13)
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(238, 0)
	add_child(panel)
	_top_left_panel = panel

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	var cash_head := HBoxContainer.new()
	cash_head.add_theme_constant_override("separation", 6)
	cash_head.add_child(UIKit.kicker("Cash", UIKit.GOLD, 10))
	_level_label = UIKit.label("LV 1", 11, UIKit.TEAL)
	_level_label.add_theme_font_override("font", UIKit.ui_font(800, 2))
	_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cash_head.add_child(_level_label)
	box.add_child(cash_head)

	_money_label = UIKit.heading("Rs 500", 34, UIKit.CREAM, 700)
	_money_label.pivot_offset = Vector2(70, 20)
	box.add_child(_money_label)

	_day_label = UIKit.label("Day 1  -  9:00 AM", 13, UIKit.MUTED)
	box.add_child(_day_label)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 8)
	_theme_label = UIKit.kicker("Clear Day", UIKit.GOLD, 10)
	_theme_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.add_child(_theme_label)
	_rep_label = UIKit.kicker("Rep 20", UIKit.ORANGE, 10)
	meta_row.add_child(_rep_label)
	box.add_child(meta_row)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 8)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 6)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 90
	_xp_bar.value = 0
	_xp_bar.add_theme_stylebox_override("fill", UIKit.bar_fill(UIKit.TEAL, 6))
	xp_row.add_child(_xp_bar)
	_xp_text = UIKit.label("0 / 90", 10, UIKit.MUTED)
	xp_row.add_child(_xp_text)
	box.add_child(xp_row)

	_fps_label = UIKit.label("FPS", 10, UIKit.MUTED)
	_fps_label.visible = _mobile
	box.add_child(_fps_label)

	_stock_warning = UIKit.label("", 12, UIKit.RED)
	_stock_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_stock_warning)

	_rush_label = UIKit.label("RUSH HOUR", 11, UIKit.GOLD)
	_rush_label.add_theme_font_override("font", UIKit.ui_font(800, 2))
	_rush_label.visible = false
	box.add_child(_rush_label)

	_combo_label = UIKit.label("", 13, UIKit.GOLD)
	_combo_label.visible = false
	box.add_child(_combo_label)
	_tips_label = UIKit.label("", 12, UIKit.GOLD)
	_tips_label.visible = false
	box.add_child(_tips_label)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 12)
	_goals_label = UIKit.label("GOALS  0/3  G", 10, UIKit.TEAL)
	_badge_label = UIKit.label("BADGES  0/18  B", 10, UIKit.GOLD)
	stats.add_child(_goals_label)
	stats.add_child(_badge_label)
	box.add_child(stats)


func _build_top_right() -> void:
	var mobile := _mobile
	var container: BoxContainer
	if mobile:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		column.alignment = BoxContainer.ALIGNMENT_END
		container = column
	else:
		container = HBoxContainer.new()
		container.add_theme_constant_override("separation", 8)
		(container as HBoxContainer).alignment = BoxContainer.ALIGNMENT_END

	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.offset_left = -640 if not mobile else -260
	container.offset_right = -18
	container.offset_top = 16
	container.offset_bottom = 64
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	_top_right = container

	var primary := HBoxContainer.new()
	primary.add_theme_constant_override("separation", 6)
	primary.alignment = BoxContainer.ALIGNMENT_END
	container.add_child(primary)

	for spec in [["Stock", "open_inventory"], ["Upgrades", "open_upgrades"], ["Goals", "open_goals"]]:
		primary.add_child(_hud_button(String(spec[0]), String(spec[1])))

	var secondary: HBoxContainer
	if mobile:
		secondary = HBoxContainer.new()
		secondary.add_theme_constant_override("separation", 6)
		secondary.alignment = BoxContainer.ALIGNMENT_END
		container.add_child(secondary)
	else:
		secondary = primary

	for spec in [["Badges", "open_collection"], ["Models", "open_models"], ["Menu", "open_pause"]]:
		secondary.add_child(_hud_button(String(spec[0]), String(spec[1])))


func _hud_button(text: String, method: String) -> Button:
	var b := UIKit.button(text, 36)
	b.add_theme_font_override("font", UIKit.ui_font(700, 0))
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_stylebox_override("normal", UIKit.style(Color(0.055, 0.043, 0.035, 0.8), 999, Color(1, 0.93, 0.82, 0.16), 1, 12))
	b.add_theme_stylebox_override("hover", UIKit.style(Color(0.16, 0.12, 0.09, 0.92), 999, UIKit.GOLD, 1, 12))
	b.add_theme_stylebox_override("pressed", UIKit.style(UIKit.GOLD, 999, UIKit.GOLD, 1, 12))
	b.add_theme_color_override("font_pressed_color", UIKit.INK)
	b.pressed.connect(func(): Game.root.call(method))
	return b


func _build_order_card() -> void:
	_order_card = PanelContainer.new()
	var sb := UIKit.style(UIKit.PAPER, 16, UIKit.GOLD.darkened(0.15), 1, 16)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 22
	sb.shadow_offset = Vector2(0, 8)
	sb.border_width_left = 5
	sb.border_color = UIKit.ORANGE
	_order_card.add_theme_stylebox_override("panel", sb)
	_order_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_order_card.offset_left = -336
	_order_card.offset_right = -18
	_order_card.offset_top = 76
	_order_card.offset_bottom = 244
	_order_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_order_card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_order_card.add_child(box)

	var head := HBoxContainer.new()
	_order_title = UIKit.kicker("Order", UIKit.COPPER, 11)
	_order_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_order_title)
	head.add_child(UIKit.kicker("Live", UIKit.GREEN.darkened(0.15), 10))
	box.add_child(head)

	_order_body = UIKit.label("", 18, UIKit.PAPER_INK)
	_order_body.add_theme_font_override("font", UIKit.ui_font(700, 0))
	_order_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_order_body)

	var rule := ColorRect.new()
	rule.color = Color(0.42, 0.31, 0.2, 0.22)
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)

	_order_bar = ProgressBar.new()
	_order_bar.min_value = 0
	_order_bar.max_value = 100
	_order_bar.value = 100
	_order_bar.show_percentage = false
	_order_bar.custom_minimum_size = Vector2(0, 7)
	_order_bar.add_theme_stylebox_override("background", UIKit.style(Color(0.78, 0.7, 0.58, 0.5), 4, Color(0, 0, 0, 0), 0, 0))
	_order_bar.add_theme_stylebox_override("fill", UIKit.bar_fill(UIKit.GREEN, 4))
	box.add_child(_order_bar)
	_order_card.visible = false


# ------------------------------------------------------------------- prompts

func _build_subtitle() -> void:
	_subtitle_panel = UIKit.panel(12)
	_subtitle_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_panel.offset_left = -430
	_subtitle_panel.offset_right = 430
	_subtitle_panel.offset_top = -206
	_subtitle_panel.offset_bottom = -118
	var sb := UIKit.style(Color(0.05, 0.04, 0.032, 0.9), 14, Color(0.9, 0.75, 0.5, 0.45), 1, 12)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 16
	_subtitle_panel.add_theme_stylebox_override("panel", sb)
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_subtitle_panel.add_child(box)
	_subtitle_kicker = UIKit.kicker("Customer", UIKit.GOLD, 9)
	_subtitle_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle_kicker)

	_subtitle_label = UIKit.label("", 20, UIKit.CREAM)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font_path := "res://assets/fonts/NotoSansDevanagari-Regular.ttf"
	if ResourceLoader.exists(font_path):
		var font: Resource = load(font_path)
		if font is Font:
			_subtitle_label.add_theme_font_override("font", font)
	box.add_child(_subtitle_label)
	_subtitle_panel.visible = false


func _build_prompt() -> void:
	_prompt_panel = UIKit.panel(10)
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -300
	_prompt_panel.offset_right = 300
	_prompt_panel.offset_top = -108
	_prompt_panel.offset_bottom = -60
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UIKit.style(Color(0.05, 0.04, 0.032, 0.86), 999, Color(0.95, 0.78, 0.5, 0.4), 1, 10)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 12
	_prompt_panel.add_theme_stylebox_override("panel", sb)
	add_child(_prompt_panel)
	_prompt_label = UIKit.label("", 18, UIKit.CREAM)
	_prompt_label.add_theme_font_override("font", UIKit.ui_font(600, 1))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)
	_prompt_panel.visible = false


func _build_held() -> void:
	_held_panel = UIKit.panel(10)
	_held_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_held_panel.offset_left = 20
	_held_panel.offset_right = 460
	_held_panel.offset_top = -80
	_held_panel.offset_bottom = -32
	_held_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UIKit.style(Color(0.05, 0.04, 0.032, 0.8), 12, Color(0.95, 0.78, 0.5, 0.25), 1, 10)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 10
	_held_panel.add_theme_stylebox_override("panel", sb)
	add_child(_held_panel)
	_held_label = UIKit.label("", 15, UIKit.MUTED)
	_held_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_held_panel.add_child(_held_label)
	_held_panel.visible = false


func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_left = -260
	_toast_box.offset_right = 260
	_toast_box.offset_top = 96
	_toast_box.offset_bottom = 290
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.add_theme_constant_override("separation", 6)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_crosshair() -> void:
	_crosshair = Reticle.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -11
	_crosshair.offset_right = 11
	_crosshair.offset_top = -11
	_crosshair.offset_bottom = 11
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)


# ------------------------------------------------------------- touch controls

func _build_look_area() -> void:
	_look_area = Control.new()
	_look_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_look_area.mouse_filter = Control.MOUSE_FILTER_PASS
	_look_area.gui_input.connect(_on_look_input)
	add_child(_look_area)


func _build_touch_controls() -> void:
	_joystick = StickInput.new()
	_joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick.offset_left = 34
	_joystick.offset_top = -230
	_joystick.offset_right = 204
	_joystick.offset_bottom = -60
	_joystick.moved.connect(_on_joystick)
	add_child(_joystick)
	_touch_controls.append(_joystick)

	var use_button := Button.new()
	use_button.text = "USE"
	use_button.add_theme_font_override("font", UIKit.ui_font(800, 2))
	use_button.add_theme_font_size_override("font_size", 20)
	use_button.custom_minimum_size = Vector2(120, 120)
	use_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	use_button.offset_left = -170
	use_button.offset_right = -50
	use_button.offset_top = -190
	use_button.offset_bottom = -70
	use_button.add_theme_stylebox_override("normal", UIKit.style(Color(0.95, 0.62, 0.28, 0.94), 60, Color(1, 0.9, 0.7), 2, 0))
	use_button.add_theme_stylebox_override("hover", UIKit.style(Color(1, 0.7, 0.34, 0.98), 60, Color(1, 0.95, 0.8), 2, 0))
	use_button.add_theme_stylebox_override("pressed", UIKit.style(Color(0.85, 0.5, 0.2, 0.98), 60, Color(1, 0.9, 0.7), 2, 0))
	use_button.add_theme_color_override("font_color", UIKit.INK)
	use_button.pressed.connect(_on_use_pressed)
	add_child(use_button)
	_touch_controls.append(use_button)

	var hint := UIKit.label("drag to look", 12, Color(1, 0.94, 0.84, 0.45))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -260
	hint.offset_right = -60
	hint.offset_top = -214
	hint.offset_bottom = -196
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)


func _on_look_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _look_touch == -1:
			_look_touch = event.index
			_look_last = event.position
		elif not event.pressed and event.index == _look_touch:
			_look_touch = -1
	elif event is InputEventScreenDrag and event.index == _look_touch:
		var drag := event as InputEventScreenDrag
		var delta: Vector2 = drag.position - _look_last
		_look_last = drag.position
		if player and delta.length() < 80.0:
			player.add_look(delta * 0.0042)


func _on_joystick(value: Vector2) -> void:
	if player:
		player.mobile_move = value


func _on_use_pressed() -> void:
	if player:
		player.try_interact()


# -------------------------------------------------------------------- events

func _on_money_changed(cash: int) -> void:
	if _money_label == null:
		return
	_money_label.text = "Rs %d" % cash
	var tween := create_tween()
	_money_label.pivot_offset = _money_label.size * 0.5
	_money_label.scale = Vector2(1.06, 1.06)
	tween.tween_property(_money_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_time_changed(_hour: int, _minute: int) -> void:
	if _day_label:
		_day_label.text = "Day %d  -  %s" % [Game.day, Clock.time_string()]


func _on_reputation_changed(value: float) -> void:
	if _rep_label:
		_rep_label.text = "Rep %d" % int(round(value))


func _on_xp_changed(level: int, xp: int, xp_to_next: int, _ratio: float) -> void:
	if _level_label == null or _xp_bar == null:
		return
	_level_label.text = "LV %d" % level
	if xp_to_next <= 0:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_text.text = "MAX"
	else:
		_xp_bar.max_value = xp_to_next
		_xp_bar.value = xp
		_xp_text.text = "%d/%d" % [xp, xp_to_next]


func _on_level_up(level: int) -> void:
	if _level_label == null:
		return
	_level_label.text = "LV %d" % level
	_level_label.pivot_offset = _level_label.size * 0.5
	_level_label.scale = Vector2(1.45, 1.45)
	var tween := create_tween()
	tween.tween_property(_level_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_combo_changed(combo: int, multiplier: float) -> void:
	if _combo_label == null:
		return
	if combo < 2:
		_combo_label.visible = false
		return
	_combo_label.visible = true
	_combo_label.text = "COMBO x%d   +%d%%" % [combo, int(round((multiplier - 1.0) * 100.0))]
	_combo_label.pivot_offset = _combo_label.size * 0.5
	_combo_label.scale = Vector2(1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_tip_earned(_amount: int, total: int) -> void:
	if _tips_label == null:
		return
	_tips_label.visible = total > 0
	_tips_label.text = "TIPS  Rs %d" % total


func _on_goals_changed(data: Dictionary) -> void:
	if _goals_label == null:
		return
	var all: Array = data.get("goals", [])
	_goals_label.text = "GOALS  %d/%d  G" % [int(data.get("completed", 0)), all.size()]


func _refresh_badges() -> void:
	if _badge_label == null:
		return
	_badge_label.text = "BADGES  %d/%d  B" % [Achievements.unlocked_count(), Achievements.DEFS.size()]


func _on_theme_changed(_weather: String, label: String) -> void:
	if _theme_label:
		_theme_label.text = label


func _on_dialogue_spoken(text: String, duration: float) -> void:
	if _subtitle_panel == null:
		return
	if text == "":
		_subtitle_panel.visible = false
		return
	_subtitle_serial += 1
	var serial := _subtitle_serial
	_subtitle_label.text = text
	_subtitle_panel.visible = true
	var timer := get_tree().create_timer(maxf(1.2, duration))
	timer.timeout.connect(func():
		if serial == _subtitle_serial:
			_subtitle_panel.visible = false
	)


func _on_achievement_changed(_id: String, _title: String, _cash: int, _xp: int) -> void:
	_refresh_badges()


func _on_achievement_changed_broad(_id: String, _value: int) -> void:
	_refresh_badges()


func _on_prompt_changed(text: String) -> void:
	if _prompt_panel == null:
		return
	if text == "" or Game.overlay_open:
		_prompt_panel.visible = false
		return
	_prompt_panel.visible = true
	_prompt_label.text = text if _mobile else "E   -   " + text


func _on_held_changed(text: String) -> void:
	if _held_panel == null:
		return
	_held_panel.visible = text != ""
	if text != "":
		_held_label.text = "IN HAND   " + text


func _on_order_updated(order: Dictionary) -> void:
	if _order_card == null:
		return
	_order_card.visible = true
	_order_title.text = "ORDER  -  " + String(order.get("customer", "Customer")).to_upper()
	var prefs: Array[String] = []
	prefs.append(GameData.SPICE_NAMES[clampi(int(order.get("spice", 1)), 0, 2)])
	prefs.append("sweet" if bool(order.get("sweet", false)) else "no sweet")
	prefs.append("onion" if bool(order.get("onion", false)) else "no onion")
	_order_body.text = "%d x %s\n%s" % [
		int(order.get("quantity", 0)),
		String(order.get("name", "Pani Puri")),
		"  -  ".join(prefs),
	]
	if String(order.get("note", "")) != "":
		_order_body.text += "\n" + String(order.note)
	_order_bar.value = 100


func _on_order_cleared() -> void:
	if _order_card:
		_order_card.visible = false


func _on_toast(text: String, kind: String) -> void:
	if _toast_box == null:
		return
	var color := UIKit.CREAM
	if kind == "good":
		color = UIKit.GREEN
	elif kind == "bad":
		color = Color("ff8a6a")
	var panel := PanelContainer.new()
	var sb := UIKit.style(Color(0.05, 0.04, 0.032, 0.9), 999, Color(color.r, color.g, color.b, 0.45), 1, 10)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UIKit.label(text, 15, color)
	label.add_theme_font_override("font", UIKit.ui_font(600, 0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	_toast_box.add_child(panel)
	while _toast_box.get_child_count() > 3:
		var old := _toast_box.get_child(0)
		_toast_box.remove_child(old)
		old.queue_free()
	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


func _on_stock_changed(_id: String) -> void:
	if _stock_warning == null:
		return
	var low := Inventory.low_stock()
	if low.is_empty():
		_stock_warning.text = ""
		return
	var names: Array[String] = []
	for id in low:
		var def := GameData.ingredient(id)
		if def:
			names.append(def.display_name)
	_stock_warning.text = "LOW STOCK  " + ", ".join(names)


func _process(delta: float) -> void:
	_update_fps(delta)
	if _order_card and _order_card.visible and Orders.active_customer != null and is_instance_valid(Orders.active_customer):
		var ratio: float = Orders.active_customer.patience_ratio()
		_order_bar.value = ratio * 100.0
		var bucket := 0 if ratio > 0.5 else (1 if ratio > 0.25 else 2)
		if bucket != _patience_bucket:
			_patience_bucket = bucket
			var color: Color = [UIKit.GREEN, UIKit.ORANGE, UIKit.RED][bucket]
			_order_bar.add_theme_stylebox_override("fill", UIKit.bar_fill(color, 4))


func _update_fps(delta: float) -> void:
	if _fps_label == null or not _fps_label.visible or Game.state != Game.State.PLAYING:
		return
	_fps_ticks += 1
	_fps_accum += delta
	if _fps_ticks >= 10 and _fps_accum > 0.0:
		_fps_label.text = "FPS %d" % int(round(_fps_ticks / _fps_accum))
		_fps_ticks = 0
		_fps_accum = 0.0


func set_visible_playing(value: bool) -> void:
	visible = value
	if value:
		_on_prompt_changed("")


func _on_rush_hour_changed(active: bool) -> void:
	if _rush_label:
		_rush_label.visible = active
		if active:
			_rush_label.modulate = UIKit.GOLD


func _on_overlay_changed(open: bool) -> void:
	if _top_right:
		_top_right.visible = not open
	if _top_left_panel:
		_top_left_panel.visible = not open
	if _order_card:
		_order_card.visible = not open and Orders.active_customer != null
	if _prompt_panel and open:
		_prompt_panel.visible = false
	if _held_panel:
		_held_panel.visible = not open and player != null and player.held_item != null
	if _crosshair:
		_crosshair.visible = not open
	if _toast_box:
		_toast_box.visible = not open
	for control in _touch_controls:
		if is_instance_valid(control):
			control.visible = not open
