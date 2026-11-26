class_name HUD
extends Control
## In-game HUD: money, time, reputation, active order, interaction prompt,
## toasts and (on touch devices) the virtual joystick and use button.

var player: Player

var _money_label: Label
var _day_label: Label
var _rep_label: Label
var _level_label: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _fps_label: Label
var _fps_ticks: int = 0
var _fps_accum: float = 0.0
var _stock_warning: Label
var _rush_label: Label
var _order_card: PanelContainer
var _order_title: Label
var _order_body: Label
var _order_bar: ProgressBar
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _held_panel: PanelContainer
var _held_label: Label
var _toast_box: VBoxContainer
var _crosshair: Control
var _top_right: HBoxContainer
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

	_on_money_changed(Economy.cash)
	_on_reputation_changed(Progression.reputation)
	_on_time_changed(Clock.hour(), 0)
	_on_xp_changed(Progression.level, Progression.xp, Progression.xp_to_next(), Progression.xp_ratio())
	_on_stock_changed("")
	_on_rush_hour_changed(Progression.rush_hour_active())
	_on_prompt_changed("")
	_on_held_changed("")


# ------------------------------------------------------------------ top bars

func _build_top_left() -> void:
	_level_label = UIKit.label("LV 1", 14, UIKit.TEAL)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(110, 7)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.show_percentage = false
	_xp_bar.max_value = 90
	_xp_bar.value = 0

	var panel := UIKit.panel(8)
	panel.position = Vector2(16, 14)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	box.add_child(_level_label)

	_money_label = UIKit.label("Rs 500", 22, UIKit.CREAM)
	_money_label.pivot_offset = Vector2(66, 15)
	box.add_child(_money_label)
	_day_label = UIKit.label("Day 1  -  9:00 AM", 14, UIKit.MUTED)
	box.add_child(_day_label)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 6)
	xp_row.add_theme_constant_override("margin_left", 2)
	xp_row.add_theme_constant_override("margin_right", 2)
	xp_row.add_child(_xp_bar)
	_xp_text = UIKit.label("0 / 90 XP", 11, UIKit.MUTED)
	xp_row.add_child(_xp_text)
	box.add_child(xp_row)

	_fps_label = UIKit.label("FPS", 11, UIKit.MUTED)
	_fps_label.visible = _mobile
	box.add_child(_fps_label)

	_stock_warning = UIKit.label("", 13, UIKit.RED)
	box.add_child(_stock_warning)

	_rush_label = UIKit.label("RUSH HOUR", 12, UIKit.GOLD)
	_rush_label.visible = false
	box.add_child(_rush_label)


func _build_top_right() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	row.offset_left = -580
	row.offset_right = -20
	row.offset_top = 18
	row.offset_bottom = 70
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_top_right = row

	var rep_panel := UIKit.panel(8)
	rep_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rep_panel.custom_minimum_size = Vector2(0, 28)
	row.add_child(rep_panel)
	_rep_label = UIKit.label("REP 20", 15, UIKit.ORANGE)
	rep_panel.add_child(_rep_label)

	var stock_button := UIKit.button("Stock", 40)
	stock_button.pressed.connect(func(): Game.root.call("open_inventory"))
	row.add_child(stock_button)
	var upgrade_button := UIKit.button("Upgrades", 40)
	upgrade_button.pressed.connect(func(): Game.root.call("open_upgrades"))
	row.add_child(upgrade_button)
	var menu_button := UIKit.button("Menu", 40)
	menu_button.pressed.connect(func(): Game.root.call("open_pause"))
	row.add_child(menu_button)


func _build_order_card() -> void:
	_order_card = UIKit.panel(14)
	_order_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_order_card.offset_left = -350
	_order_card.offset_right = -20
	_order_card.offset_top = 84
	_order_card.offset_bottom = 250
	_order_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_order_card.add_theme_stylebox_override("panel", UIKit.style(UIKit.PANEL, 14, UIKit.ORANGE, 2, 14))
	add_child(_order_card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_order_card.add_child(box)
	_order_title = UIKit.label("ORDER", 16, UIKit.ORANGE)
	box.add_child(_order_title)
	_order_body = UIKit.label("", 19, UIKit.CREAM)
	_order_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_order_body)
	_order_bar = ProgressBar.new()
	_order_bar.min_value = 0
	_order_bar.max_value = 100
	_order_bar.value = 100
	_order_bar.show_percentage = false
	_order_bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(_order_bar)
	_order_card.visible = false


# ------------------------------------------------------------------- prompts

func _build_prompt() -> void:
	_prompt_panel = UIKit.panel(10)
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -300
	_prompt_panel.offset_right = 300
	_prompt_panel.offset_top = -104
	_prompt_panel.offset_bottom = -58
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_panel.add_theme_stylebox_override("panel", UIKit.style(Color(0.08, 0.06, 0.05, 0.82), 12, UIKit.ORANGE, 1, 8))
	add_child(_prompt_panel)
	_prompt_label = UIKit.label("", 20, UIKit.CREAM)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_panel.add_child(_prompt_label)
	_prompt_panel.visible = false


func _build_held() -> void:
	_held_panel = UIKit.panel(10)
	_held_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_held_panel.offset_left = 20
	_held_panel.offset_right = 460
	_held_panel.offset_top = -78
	_held_panel.offset_bottom = -30
	_held_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_held_panel)
	_held_label = UIKit.label("", 16, UIKit.MUTED)
	_held_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_held_panel.add_child(_held_label)
	_held_panel.visible = false


func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_left = -260
	_toast_box.offset_right = 260
	_toast_box.offset_top = 92
	_toast_box.offset_bottom = 280
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.add_theme_constant_override("separation", 4)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_crosshair() -> void:
	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 0.95, 0.85, 0.75)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -2
	_crosshair.offset_right = 2
	_crosshair.offset_top = -2
	_crosshair.offset_bottom = 2
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
	use_button.add_theme_font_size_override("font_size", 22)
	use_button.custom_minimum_size = Vector2(120, 120)
	use_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	use_button.offset_left = -170
	use_button.offset_right = -50
	use_button.offset_top = -190
	use_button.offset_bottom = -70
	use_button.add_theme_stylebox_override("normal", UIKit.style(Color(0.95, 0.55, 0.23, 0.9), 60, Color(1, 0.85, 0.6), 2, 0))
	use_button.add_theme_stylebox_override("hover", UIKit.style(Color(1, 0.62, 0.28, 0.95), 60, Color(1, 0.9, 0.7), 2, 0))
	use_button.add_theme_stylebox_override("pressed", UIKit.style(Color(0.85, 0.45, 0.18, 0.95), 60, Color(1, 0.85, 0.6), 2, 0))
	use_button.add_theme_color_override("font_color", Color("241a14"))
	use_button.pressed.connect(_on_use_pressed)
	add_child(use_button)
	_touch_controls.append(use_button)

	var hint := UIKit.label("drag to look", 13, Color(1, 0.94, 0.84, 0.5))
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
	_money_label.scale = Vector2(1.12, 1.12)
	tween.tween_property(_money_label, "scale", Vector2.ONE, 0.18)


func _on_time_changed(_hour: int, _minute: int) -> void:
	if _day_label:
		_day_label.text = "Day %d  -  %s" % [Game.day, Clock.time_string()]


func _on_reputation_changed(value: float) -> void:
	if _rep_label:
		_rep_label.text = "REP %d" % int(round(value))


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


func _on_prompt_changed(text: String) -> void:
	if _prompt_panel == null:
		return
	if text == "" or Game.overlay_open:
		_prompt_panel.visible = false
		return
	_prompt_panel.visible = true
	_prompt_label.text = text if _mobile else "[E]  " + text


func _on_held_changed(text: String) -> void:
	if _held_panel == null:
		return
	_held_panel.visible = text != ""
	if text != "":
		_held_label.text = "IN HAND  " + text


func _on_order_updated(order: Dictionary) -> void:
	if _order_card == null:
		return
	_order_card.visible = true
	_order_title.text = "ORDER  -  " + String(order.get("customer", "Customer"))
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
	panel.add_theme_stylebox_override("panel", UIKit.style(Color(0.08, 0.06, 0.05, 0.86), 10, color.darkened(0.35), 1, 8))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UIKit.label(text, 17, color)
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
	_stock_warning.text = "Low: " + ", ".join(names)


func _process(delta: float) -> void:
	_update_fps(delta)
	if _order_card and _order_card.visible and Orders.active_customer != null and is_instance_valid(Orders.active_customer):
		var ratio: float = Orders.active_customer.patience_ratio()
		_order_bar.value = ratio * 100.0
		var bucket := 0 if ratio > 0.5 else (1 if ratio > 0.25 else 2)
		if bucket != _patience_bucket:
			_patience_bucket = bucket
			var color: Color = [UIKit.GREEN, UIKit.ORANGE, UIKit.RED][bucket]
			_order_bar.add_theme_stylebox_override("fill", UIKit.style(color, 6, Color(0, 0, 0, 0), 0, 0))


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
