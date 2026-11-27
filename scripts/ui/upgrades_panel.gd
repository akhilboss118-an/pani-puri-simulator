class_name UpgradesPanel
extends OverlayPanel
## Stall upgrades, restaurant tiers and pricing. Buying here is the main way
## the stall visibly grows: bigger plate, signboard, garlic pani, then a full
## restaurant with a terrace, balcony and palace marquee.

var _level_label: Label
var _xp_bar: ProgressBar
var _xp_text: Label
var _rep_label: Label
var _price_label: Label
var _price_slider: HSlider
var _list: VBoxContainer
var _hint: Label


func _init() -> void:
	title_text = "Upgrades & Pricing"


func _ready() -> void:
	super._ready()
	Events.money_changed.connect(func(_c: int):
		if visible:
			_refresh()
	)
	Events.upgrade_purchased.connect(func(_id: String):
		if visible:
			_refresh()
	)
	Events.xp_changed.connect(func(_l: int, _x: int, _n: int, _r: float):
		if visible:
			_refresh()
	)
	Events.level_up.connect(func(_l: int):
		if visible:
			_refresh()
	)


func _build_content() -> void:
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 10)
	_level_label = UIKit.label("Level 1 - Street Cart", 18, UIKit.TEAL)
	_level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(_level_label)
	_rep_label = UIKit.label("Reputation: 20", 16, UIKit.ORANGE)
	meta.add_child(_rep_label)
	content.add_child(meta)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 10)
	_xp_bar = ProgressBar.new()
	_xp_bar.custom_minimum_size = Vector2(0, 9)
	_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.show_percentage = false
	xp_row.add_child(_xp_bar)
	_xp_text = UIKit.label("0 / 90 XP", 13, UIKit.MUTED)
	xp_row.add_child(_xp_text)
	content.add_child(xp_row)

	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 12)
	price_row.add_child(UIKit.label("Price per puri", 17))
	_price_slider = HSlider.new()
	_price_slider.min_value = 20
	_price_slider.max_value = 50
	_price_slider.step = 1
	_price_slider.value = Progression.price_per_puri
	_price_slider.custom_minimum_size = Vector2(240, 32)
	_price_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price_row.add_child(_price_slider)
	_price_label = UIKit.label("Rs 30", 17, UIKit.CREAM)
	price_row.add_child(_price_label)
	content.add_child(price_row)
	_price_slider.value_changed.connect(func(value: float):
		Progression.set_price(int(value))
		_price_label.text = "Rs %d" % int(value)
	)

	content.add_child(UIKit.label("Customers pay less when the price is high for their taste.", 13, UIKit.MUTED))

	var prestige_row := HBoxContainer.new()
	prestige_row.add_theme_constant_override("separation", 10)
	var prestige_text := VBoxContainer.new()
	prestige_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prestige_text.add_child(UIKit.label("PRESTIGE  %d  -  +%d%% prices" % [Progression.prestige_level, int(round((Progression.prestige_multiplier() - 1.0) * 100.0))], 16, UIKit.GOLD))
	prestige_text.add_child(UIKit.label("Reach level %d, then open a new branch. Resets day/cash/level; keeps upgrades." % Progression.MAX_LEVEL, 12, UIKit.MUTED))
	prestige_row.add_child(prestige_text)
	var prestige_button := UIKit.button("Open new branch", 40)
	prestige_button.disabled = not Progression.can_prestige()
	prestige_button.pressed.connect(func():
		if Progression.prestige():
			_refresh()
	)
	prestige_row.add_child(prestige_button)
	content.add_child(prestige_row)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_hint = UIKit.label("", 14, UIKit.TEAL)
	content.add_child(_hint)


func _on_open() -> void:
	_price_slider.value = Progression.price_per_puri
	_price_label.text = "Rs %d" % Progression.price_per_puri
	_refresh()


func _refresh() -> void:
	if _list == null:
		return
	_level_label.text = "Level %d - %s" % [Progression.level, Progression.level_title()]
	_rep_label.text = "Reputation: %d / 100" % int(round(Progression.reputation))
	var need := Progression.xp_to_next()
	if need <= 0:
		_xp_bar.max_value = 1
		_xp_bar.value = 1
		_xp_text.text = "MAX LEVEL"
	else:
		_xp_bar.max_value = need
		_xp_bar.value = Progression.xp
		_xp_text.text = "%d / %d XP" % [Progression.xp, need]

	for child in _list.get_children():
		child.queue_free()

	_list.add_child(_section_label("STREET STALL"))
	var restaurant_header := false
	for data in GameData.upgrades():
		var is_restaurant := String(data.get("tier", "")) == "restaurant"
		if is_restaurant and not restaurant_header:
			restaurant_header = true
			_list.add_child(_section_label("GROW INTO A RESTAURANT"))
		_list.add_child(_make_row(data))
	_hint.text = Progression.unlock_progress_text()


func _section_label(text: String) -> Control:
	var label := UIKit.label(text, 12, UIKit.ORANGE)
	label.custom_minimum_size = Vector2(0, 24)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return label


func _make_row(data: Dictionary) -> Control:
	var id := String(data.id)
	var owned := Progression.has_upgrade(id)
	var locked_reason := Progression.upgrade_lock_reason(id)
	var required_level := int(data.get("level", 1))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.PANEL_2, 10, UIKit.GREEN if owned else UIKit.BORDER, 1, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	title_row.add_child(UIKit.label(String(data.name), 16, UIKit.CREAM))
	if required_level > 1:
		var badge := UIKit.label("LV %d" % required_level, 11, UIKit.GREEN if owned else UIKit.TEAL)
		badge.custom_minimum_size = Vector2(44, 0)
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_row.add_child(badge)
	text_box.add_child(title_row)

	var desc := UIKit.label(String(data.description), 13, UIKit.MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(330, 0)
	text_box.add_child(desc)

	if owned:
		var owned_label := UIKit.label("OWNED", 15, UIKit.GREEN)
		owned_label.custom_minimum_size = Vector2(110, 0)
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(owned_label)
	elif locked_reason != "":
		var locked := UIKit.label(locked_reason, 12, UIKit.MUTED)
		locked.custom_minimum_size = Vector2(110, 0)
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(locked)
	else:
		var cost := int(data.cost)
		var button := UIKit.button("Rs %d" % cost, 44)
		button.custom_minimum_size = Vector2(118, 44)
		button.disabled = not Economy.can_afford(cost)
		button.pressed.connect(_on_buy.bind(id))
		row.add_child(button)
	return panel


func _on_buy(id: String) -> void:
	Progression.buy(id)
	_refresh()
