class_name HUD
extends Control
## In-game HUD matching the warm street-cart visual layout:
## - Top-left cash pill + Happiness/Reputation/Service Time card with Street Minimap
## - Top-right Day/Time weather pill + compact menu actions
## - White customer speech-bubble order card
## - Bottom-center "Press [E] to ..." prompt + 5-step Preparation Mechanism strip

const UIIcons := preload("res://scripts/ui/ui_icons.gd")

var player: Player

var _money_label: Label
var _day_pill: PanelContainer
var _day_label: Label
var _weather_icon: Control
var _rep_bar: ProgressBar
var _happy_bar: ProgressBar
var _service_bar: ProgressBar
var _level_label: PanelContainer
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
var _order_qty: Label
var _order_chips: HBoxContainer
var _order_note: Label

var _prep_panel: PanelContainer
var _prep_steps: Array[PanelContainer] = []
var _prep_labels: Array[Label] = []

var _prompt_panel: HBoxContainer
var _prompt_key_box: PanelContainer
var _prompt_label: Label
var _subtitle_panel: PanelContainer
var _subtitle_label: Label
var _subtitle_kicker: Label
var _subtitle_serial: int = 0
var _held_panel: PanelContainer
var _held_label: Label
var _toast_box: VBoxContainer
var _crosshair: Reticle
var _top_right: Control
var _top_left_col: VBoxContainer
var _cash_pill: PanelContainer
var _stats_card: PanelContainer
var _touch_controls: Array[Control] = []

var _mobile: bool = false
var _joystick: StickInput
var _look_area: Control
var _look_touch: int = -1
var _look_last: Vector2 = Vector2.ZERO
var _patience_bucket: int = -1
var _last_prep_stage: int = -1


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
	_build_prep_bar()
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
	_refresh_prep_bar()


# ------------------------------------------------------------------ styling

func _glass(margin: int = 10, border: Color = Color("7d522c")) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UIKit.style(Color(0.09, 0.06, 0.04, 0.86), 14, border, 2, margin)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _build_top_left() -> void:
	_top_left_col = VBoxContainer.new()
	_top_left_col.position = Vector2(18, 14)
	_top_left_col.add_theme_constant_override("separation", 8)
	_top_left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_left_col)

	# Cash Pill: [💵] ₹250
	_cash_pill = _glass(8, Color("6c4a28"))
	_cash_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_top_left_col.add_child(_cash_pill)
	var cash_row := HBoxContainer.new()
	cash_row.add_theme_constant_override("separation", 8)
	_cash_pill.add_child(cash_row)
	cash_row.add_child(UIIcons.IconGlyph.new("cash", Vector2(26, 20)))
	_money_label = UIKit.heading("₹500", 24, UIKit.CREAM, 800)
	_money_label.pivot_offset = Vector2(40, 14)
	cash_row.add_child(_money_label)
	_level_label = UIKit.gold_pill("LV 1", UIKit.GOLD, UIKit.INK, 10)
	cash_row.add_child(_level_label)
	_tips_label = UIKit.label("", 12, UIKit.GREEN)
	_tips_label.visible = false
	cash_row.add_child(_tips_label)

	# UI Elements Card: Happiness / Reputation / Service Time + Minimap
	_stats_card = _glass(10, Color("8a5a2e"))
	_stats_card.custom_minimum_size = Vector2(310, 0)
	_top_left_col.add_child(_stats_card)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 10)
	_stats_card.add_child(main_row)

	var bars := VBoxContainer.new()
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.add_theme_constant_override("separation", 6)
	main_row.add_child(bars)

	_happy_bar = _metric_row(bars, "happy", "Customer Happiness", Color("64c856"), 80.0)
	_rep_bar = _metric_row(bars, "star", "Reputation", Color("f29a32"), 20.0)
	_service_bar = _metric_row(bars, "clock", "Service Time", Color("429ae8"), 100.0)

	var meta_row := HBoxContainer.new()
	meta_row.add_theme_constant_override("separation", 10)
	_goals_label = UIKit.label("Goals 0/3 [G]", 10, UIKit.TEAL)
	_badge_label = UIKit.label("Badges 0/18 [B]", 10, UIKit.GOLD)
	meta_row.add_child(_goals_label)
	meta_row.add_child(_badge_label)
	bars.add_child(meta_row)

	var minimap: Control = UIIcons.StreetMinimap.new()
	minimap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_row.add_child(minimap)

	_rush_label = UIKit.label("RUSH HOUR!", 11, UIKit.GOLD)
	_rush_label.add_theme_font_override("font", UIKit.ui_font(800, 2))
	_rush_label.visible = false
	_top_left_col.add_child(_rush_label)

	_combo_label = UIKit.label("", 12, UIKit.GOLD)
	_combo_label.add_theme_font_override("font", UIKit.ui_font(800, 1))
	_combo_label.visible = false
	_top_left_col.add_child(_combo_label)

	_stock_warning = UIKit.label("", 12, Color("ff8a6a"))
	_stock_warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stock_warning.visible = false
	_top_left_col.add_child(_stock_warning)

	_fps_label = UIKit.label("FPS", 10, UIKit.MUTED)
	_fps_label.visible = _mobile or bool(Game.settings.get("show_fps", false))
	_top_left_col.add_child(_fps_label)


func _metric_row(parent: VBoxContainer, icon_kind: String, title: String, fill_col: Color, initial_val: float) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	parent.add_child(row)
	row.add_child(UIIcons.IconGlyph.new(icon_kind, Vector2(20, 20)))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var lbl := UIKit.label(title, 11, UIKit.CREAM)
	lbl.add_theme_font_override("font", UIKit.ui_font(600, 0))
	col.add_child(lbl)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = initial_val
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.add_theme_stylebox_override("background", UIKit.style(Color("241a12"), 4, Color(0, 0, 0, 0.3), 0, 0))
	bar.add_theme_stylebox_override("fill", UIKit.bar_fill(fill_col, 4))
	col.add_child(bar)
	return bar


func _build_top_right() -> void:
	var right_col := VBoxContainer.new()
	right_col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_col.offset_left = -560 if not _mobile else -280
	right_col.offset_right = -18
	right_col.offset_top = 14
	right_col.offset_bottom = 110
	right_col.add_theme_constant_override("separation", 6)
	right_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_col)
	_top_right = right_col

	# Top row: Day 1 9:00 AM pill + action buttons
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_theme_constant_override("separation", 6)
	right_col.add_child(top_row)

	_day_pill = _glass(6, Color("8a5a2e"))
	var drow := HBoxContainer.new()
	drow.add_theme_constant_override("separation", 6)
	_day_pill.add_child(drow)
	_weather_icon = UIIcons.IconGlyph.new("sun", Vector2(20, 20))
	drow.add_child(_weather_icon)
	_day_label = UIKit.label("Day 1  9:00 AM", 13, UIKit.CREAM)
	_day_label.add_theme_font_override("font", UIKit.ui_font(700, 0))
	drow.add_child(_day_label)
	top_row.add_child(_day_pill)

	for spec in [["Stock", "open_inventory"], ["Upgrades", "open_upgrades"], ["Goals", "open_goals"], ["Badges", "open_collection"], ["Menu", "open_pause"]]:
		top_row.add_child(_hud_button(String(spec[0]), String(spec[1])))


func _hud_button(text: String, method: String) -> Button:
	var b := UIKit.button(text, 34)
	b.add_theme_font_override("font", UIKit.ui_font(700, 0))
	b.add_theme_font_size_override("font_size", 12)
	b.custom_minimum_size = Vector2(0, 34)
	b.add_theme_stylebox_override("normal", UIKit.style(Color(0.11, 0.075, 0.05, 0.9), 10, Color("7d522c"), 1, 10))
	b.add_theme_stylebox_override("hover", UIKit.style(Color(0.24, 0.16, 0.1, 0.96), 10, UIKit.GOLD, 1, 10))
	b.add_theme_stylebox_override("pressed", UIKit.style(UIKit.GOLD, 10, UIKit.GOLD, 1, 10))
	b.add_theme_color_override("font_pressed_color", UIKit.INK)
	b.pressed.connect(func(): Game.root.call(method))
	return b


func _build_order_card() -> void:
	# Clean white speech-bubble style order card matching "Customer AI & Orders"
	_order_card = PanelContainer.new()
	var sb := UIKit.style(Color("faf6ee"), 16, Color("c8a97e"), 2, 14)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)
	_order_card.add_theme_stylebox_override("panel", sb)
	_order_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_order_card.offset_left = -310
	_order_card.offset_right = -18
	_order_card.offset_top = 66
	_order_card.offset_bottom = 204
	_order_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_order_card)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_order_card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	_order_title = UIKit.kicker("Customer 1", Color("8f4e18"), 10)
	_order_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_order_title)
	head.add_child(UIKit.gold_pill("ORDER", UIKit.GOLD, UIKit.INK, 9))
	box.add_child(head)

	_order_qty = UIKit.label("3 Pani Puris!", 18, Color("24150c"))
	_order_qty.add_theme_font_override("font", UIKit.ui_font(800, 0))
	_order_qty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_order_qty)

	_order_chips = HBoxContainer.new()
	_order_chips.add_theme_constant_override("separation", 5)
	box.add_child(_order_chips)

	_order_note = UIKit.label("", 12, Color("664830"))
	_order_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_order_note.visible = false
	box.add_child(_order_note)
	_order_card.visible = false


# ---------------------------------------------------- preparation mechanism

func _build_prep_bar() -> void:
	_prep_panel = _glass(7, Color("8a5a2e"))
	_prep_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prep_panel.offset_left = -295
	_prep_panel.offset_right = 295
	_prep_panel.offset_top = -66
	_prep_panel.offset_bottom = -10
	add_child(_prep_panel)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	_prep_panel.add_child(row)

	var names := ["Take Puri", "Crack & Fill", "Add Chutney", "Add Pani", "Serve"]
	for i in names.size():
		var pill := PanelContainer.new()
		var sb := UIKit.style(Color(0.14, 0.09, 0.06, 0.85), 10, Color(1, 0.9, 0.7, 0.14), 1, 0)
		sb.content_margin_left = 7
		sb.content_margin_right = 8
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		pill.add_theme_stylebox_override("panel", sb)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		pill.add_child(hbox)
		hbox.add_child(UIIcons.IconGlyph.new("puri_%d" % i, Vector2(22, 22)))
		var lbl := UIKit.label(names[i], 11, UIKit.MUTED)
		lbl.add_theme_font_override("font", UIKit.ui_font(700, 0))
		hbox.add_child(lbl)
		row.add_child(pill)
		_prep_steps.append(pill)
		_prep_labels.append(lbl)
		if i < names.size() - 1:
			var arrow := UIKit.label("→", 12, Color("d8b272"))
			row.add_child(arrow)


func _refresh_prep_bar() -> void:
	if _prep_steps.is_empty():
		return
	var stage := 0
	if player != null and player.held_item != null:
		var data: PuriData = player.held_item.data
		if data.state == PuriData.State.EMPTY or not data.has_ingredient("potato"):
			stage = 1
		elif not data.sweet and data.pani == "none":
			stage = 2
		elif data.pani == "none":
			stage = 3
		else:
			stage = 4
	elif Game.root != null and Game.root.world != null and Game.root.world.plate != null:
		if not Game.root.world.plate.puris.is_empty():
			stage = 4
	if stage == _last_prep_stage:
		return
	_last_prep_stage = stage
	for i in _prep_steps.size():
		var pill := _prep_steps[i]
		var lbl := _prep_labels[i]
		var done := i < stage
		var current := i == stage
		var bg := Color(0.14, 0.38, 0.20, 0.92) if done else (UIKit.GOLD if current else Color(0.14, 0.09, 0.06, 0.78))
		var border := UIKit.GREEN if done else (UIKit.CREAM if current else Color(1, 0.9, 0.7, 0.14))
		var fg := UIKit.CREAM if done else (UIKit.INK if current else UIKit.MUTED)
		var sb := UIKit.style(bg, 10, border, 1, 0)
		sb.content_margin_left = 7
		sb.content_margin_right = 8
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		pill.add_theme_stylebox_override("panel", sb)
		lbl.add_theme_color_override("font_color", fg)


# ------------------------------------------------------------------- prompts

func _build_subtitle() -> void:
	_subtitle_panel = UIKit.panel(10)
	_subtitle_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_panel.offset_left = -330
	_subtitle_panel.offset_right = 330
	_subtitle_panel.offset_top = -188
	_subtitle_panel.offset_bottom = -120
	var sb := UIKit.style(Color(0.08, 0.055, 0.04, 0.9), 14, Color(0.95, 0.76, 0.36, 0.45), 1, 10)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	_subtitle_panel.add_theme_stylebox_override("panel", sb)
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_subtitle_panel.add_child(box)
	_subtitle_kicker = UIKit.kicker("Customer", UIKit.GOLD, 9)
	_subtitle_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_subtitle_kicker)

	_subtitle_label = UIKit.label("", 16, UIKit.CREAM)
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
	var wrap := PanelContainer.new()
	wrap.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	wrap.offset_left = -210
	wrap.offset_right = 210
	wrap.offset_top = -112
	wrap.offset_bottom = -74
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UIKit.style(Color(0.06, 0.04, 0.03, 0.85), 999, Color(0.95, 0.78, 0.4, 0.38), 1, 6)
	wrap.add_theme_stylebox_override("panel", sb)
	add_child(wrap)

	_prompt_panel = HBoxContainer.new()
	_prompt_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	_prompt_panel.add_theme_constant_override("separation", 8)
	wrap.add_child(_prompt_panel)

	if not _mobile:
		var press_lbl := UIKit.label("Press", 15, UIKit.CREAM)
		_prompt_panel.add_child(press_lbl)
		_prompt_key_box = PanelContainer.new()
		var ksb := UIKit.style(Color("f5ebd6"), 6, Color("5a3818"), 1, 0)
		ksb.content_margin_left = 7
		ksb.content_margin_right = 7
		ksb.content_margin_top = 1
		ksb.content_margin_bottom = 1
		_prompt_key_box.add_theme_stylebox_override("panel", ksb)
		var klbl := UIKit.label("E", 14, Color("26160a"))
		klbl.add_theme_font_override("font", UIKit.ui_font(800, 0))
		_prompt_key_box.add_child(klbl)
		_prompt_panel.add_child(_prompt_key_box)

	_prompt_label = UIKit.label("", 15, UIKit.CREAM)
	_prompt_label.add_theme_font_override("font", UIKit.ui_font(700, 0))
	_prompt_panel.add_child(_prompt_label)
	wrap.visible = false
	_prompt_panel.set_meta("wrap", wrap)


func _build_held() -> void:
	_held_panel = _glass(8, Color("7d522c"))
	_held_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_held_panel.offset_left = 18
	_held_panel.offset_right = 310
	_held_panel.offset_top = -54
	_held_panel.offset_bottom = -14
	add_child(_held_panel)
	_held_label = UIKit.label("", 12, UIKit.CREAM)
	_held_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_held_panel.add_child(_held_label)
	_held_panel.visible = false


func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_toast_box.offset_left = 18
	_toast_box.offset_right = 340
	_toast_box.offset_top = 218
	_toast_box.offset_bottom = 390
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toast_box.add_theme_constant_override("separation", 6)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_box)


func _build_crosshair() -> void:
	_crosshair = Reticle.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -16
	_crosshair.offset_right = 16
	_crosshair.offset_top = -16
	_crosshair.offset_bottom = 16
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
	_joystick.offset_left = 28
	_joystick.offset_top = -236
	_joystick.offset_right = 198
	_joystick.offset_bottom = -66
	_joystick.moved.connect(_on_joystick)
	add_child(_joystick)
	_touch_controls.append(_joystick)

	var use_button := Button.new()
	use_button.text = ""
	use_button.custom_minimum_size = Vector2(96, 96)
	use_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	use_button.offset_left = -132
	use_button.offset_right = -36
	use_button.offset_top = -172
	use_button.offset_bottom = -76
	use_button.add_theme_stylebox_override("normal", UIKit.style(Color(0.08, 0.06, 0.04, 0.72), 48, Color(1, 1, 1, 0.55), 2, 0))
	use_button.add_theme_stylebox_override("hover", UIKit.style(Color(0.14, 0.1, 0.06, 0.85), 48, UIKit.GOLD, 2, 0))
	use_button.add_theme_stylebox_override("pressed", UIKit.style(Color(0.84, 0.56, 0.18, 0.92), 48, Color.WHITE, 2, 0))
	use_button.pressed.connect(_on_use_pressed)
	var hand: Control = UIIcons.IconGlyph.new("hand", Vector2(44, 44), Color.WHITE)
	hand.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hand.offset_left = -22
	hand.offset_right = 22
	hand.offset_top = -22
	hand.offset_bottom = 22
	use_button.add_child(hand)
	add_child(use_button)
	_touch_controls.append(use_button)


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
	_money_label.text = "₹%d" % cash
	var tween := create_tween()
	_money_label.pivot_offset = _money_label.size * 0.5
	_money_label.scale = Vector2(1.06, 1.06)
	tween.tween_property(_money_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_time_changed(_hour: int, _minute: int) -> void:
	if _day_label:
		_day_label.text = "Day %d  %s" % [Game.day, Clock.time_string()]
	if _weather_icon:
		if Clock.hour() >= 18:
			_weather_icon.set("kind", "moon")
		elif Game.weather() == "rain":
			_weather_icon.set("kind", "rain")
		else:
			_weather_icon.set("kind", "sun")
		_weather_icon.queue_redraw()


func _on_reputation_changed(value: float) -> void:
	if _rep_bar:
		_rep_bar.value = clampf(value, 0.0, 100.0)
	if _happy_bar:
		_happy_bar.value = clampf(50.0 + value * 0.5, 10.0, 100.0)


func _on_xp_changed(level: int, _xp: int, _xp_to_next: int, _ratio: float) -> void:
	if _level_label == null:
		return
	var lbl := _level_label.get_child(0) as Label
	if lbl:
		lbl.text = "LV %d" % level


func _on_level_up(level: int) -> void:
	if _level_label == null:
		return
	var lbl := _level_label.get_child(0) as Label
	if lbl:
		lbl.text = "LV %d" % level
	_level_label.pivot_offset = _level_label.size * 0.5
	_level_label.scale = Vector2(1.4, 1.4)
	var tween := create_tween()
	tween.tween_property(_level_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_combo_changed(combo: int, multiplier: float) -> void:
	if _combo_label == null:
		return
	if combo < 2:
		_combo_label.visible = false
		return
	_combo_label.visible = true
	_combo_label.text = "COMBO x%d  (+%d%%)" % [combo, int(round((multiplier - 1.0) * 100.0))]


func _on_tip_earned(_amount: int, total: int) -> void:
	if _tips_label == null:
		return
	_tips_label.visible = total > 0
	_tips_label.text = "+₹%d tips" % total


func _on_goals_changed(data: Dictionary) -> void:
	if _goals_label == null:
		return
	var all: Array = data.get("goals", [])
	_goals_label.text = "Goals %d/%d [G]" % [int(data.get("completed", 0)), all.size()]


func _refresh_badges() -> void:
	if _badge_label == null:
		return
	_badge_label.text = "Badges %d/%d [B]" % [Achievements.unlocked_count(), Achievements.DEFS.size()]


func _on_theme_changed(weather: String, _label: String) -> void:
	if _weather_icon:
		if weather == "rain":
			_weather_icon.set("kind", "rain")
		elif Clock.hour() >= 18:
			_weather_icon.set("kind", "moon")
		else:
			_weather_icon.set("kind", "sun")
		_weather_icon.queue_redraw()


func _on_dialogue_spoken(text: String, duration: float) -> void:
	if _subtitle_panel == null:
		return
	if text == "" or Game.overlay_open:
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
	var wrap: Control = _prompt_panel.get_meta("wrap")
	if text == "" or Game.overlay_open:
		wrap.visible = false
		return
	wrap.visible = true
	_prompt_label.text = text if _mobile else "to " + text.to_lower()


func _on_held_changed(text: String) -> void:
	if _held_panel != null:
		_held_panel.visible = not Game.overlay_open and text != ""
		if text != "":
			_held_label.text = "IN HAND  •  " + text
	_refresh_prep_bar()


func _on_order_updated(order: Dictionary) -> void:
	if _order_card == null:
		return
	_order_card.visible = not Game.overlay_open
	_order_title.text = String(order.get("customer", "Customer")).to_upper()
	var qty := int(order.get("quantity", 0))
	var spice_idx := clampi(int(order.get("spice", 1)), 0, 2)
	var spice_word := "extra spicy " if spice_idx == 2 else ("mild " if spice_idx == 0 else "")
	var pani_word := "garlic pani!" if String(order.get("pani", "mint")) == "garlic" else "pani!"
	_order_qty.text = "%d Pani Puris with %s%s" % [qty, spice_word, pani_word]

	for child in _order_chips.get_children():
		child.queue_free()

	var spice_col: Color = GameData.SPICE_COLORS[spice_idx]
	_order_chips.add_child(UIKit.chip(GameData.SPICE_NAMES[spice_idx], spice_col, 10))
	if bool(order.get("sweet", false)):
		_order_chips.add_child(UIKit.chip("Sweet", UIKit.ORANGE, 10))
	if bool(order.get("onion", false)):
		_order_chips.add_child(UIKit.chip("Onion", Color("f29db8"), 10))
	else:
		_order_chips.add_child(UIKit.chip("No Onion", Color("e3cfa8"), 10))

	var note := String(order.get("note", ""))
	_order_note.visible = note != ""
	_order_note.text = "\"" + note + "\"" if note != "" else ""


func _on_order_cleared() -> void:
	if _order_card:
		_order_card.visible = false
	if _service_bar:
		_service_bar.value = 100.0


func _on_toast(text: String, kind: String) -> void:
	if _toast_box == null:
		return
	var color := UIKit.CREAM
	if kind == "good":
		color = UIKit.GREEN
	elif kind == "bad":
		color = Color("ff8a6a")
	var panel := PanelContainer.new()
	var sb := UIKit.style(Color(0.08, 0.055, 0.04, 0.92), 12, Color(color.r, color.g, color.b, 0.55), 1, 9)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UIKit.label(text, 12, color)
	label.add_theme_font_override("font", UIKit.ui_font(600, 0))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	_toast_box.add_child(panel)
	while _toast_box.get_child_count() > 2:
		var old := _toast_box.get_child(0)
		_toast_box.remove_child(old)
		old.queue_free()
	var tween := create_tween()
	tween.tween_interval(2.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


func _on_stock_changed(_id: String) -> void:
	if _stock_warning == null:
		return
	var low := Inventory.low_stock()
	if low.is_empty():
		_stock_warning.text = ""
		_stock_warning.visible = false
		return
	var names: Array[String] = []
	for id in low:
		var def := GameData.ingredient(id)
		if def:
			names.append(def.display_name)
	_stock_warning.text = "LOW: " + ", ".join(names)
	_stock_warning.visible = true


func _process(delta: float) -> void:
	_update_fps(delta)
	_refresh_prep_bar()
	if _crosshair and player:
		_crosshair.active = player.has_valid_target()
	if _service_bar and Orders.active_customer != null and is_instance_valid(Orders.active_customer):
		var ratio: float = Orders.active_customer.patience_ratio()
		_service_bar.value = ratio * 100.0
		var bucket := 0 if ratio > 0.5 else (1 if ratio > 0.25 else 2)
		if bucket != _patience_bucket:
			_patience_bucket = bucket
			var color: Color = [Color("429ae8"), UIKit.ORANGE, UIKit.RED][bucket]
			_service_bar.add_theme_stylebox_override("fill", UIKit.bar_fill(color, 4))


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
	if _top_left_col:
		_top_left_col.visible = not open
	if _prep_panel:
		_prep_panel.visible = not open
	if _order_card:
		_order_card.visible = not open and Orders.active_customer != null
	if _prompt_panel and open:
		(_prompt_panel.get_meta("wrap") as Control).visible = false
	if _subtitle_panel and open:
		_subtitle_panel.visible = false
	if _held_panel:
		_held_panel.visible = not open and player != null and player.held_item != null
	if _crosshair:
		_crosshair.visible = not open
	if _toast_box:
		_toast_box.visible = not open
	for control in _touch_controls:
		if is_instance_valid(control):
			control.visible = not open
