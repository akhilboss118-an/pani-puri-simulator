class_name InventoryPanel
extends OverlayPanel
## Stock overview and restocking. Refills are the main daily expense, so the
## cost is shown per ingredient and for the whole basket.

const UIIcons := preload("res://scripts/ui/ui_icons.gd")

var _money_label: Label
var _list: VBoxContainer
var _refill_all: Button


func _init() -> void:
	title_text = "Stock & Restock"


func _ready() -> void:
	super._ready()
	Events.stock_changed.connect(func(_id: String):
		if visible:
			_refresh()
	)
	Events.money_changed.connect(func(_cash: int):
		if visible:
			_refresh()
	)


func _build_content() -> void:
	var summary := PanelContainer.new()
	summary.add_theme_stylebox_override("panel", UIKit.slab_style(0.86, 12, UIKit.FILIGREE))
	content.add_child(summary)
	var sum_row := HBoxContainer.new()
	sum_row.add_theme_constant_override("separation", 12)
	summary.add_child(sum_row)

	var left_sum := VBoxContainer.new()
	left_sum.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_sum.add_theme_constant_override("separation", 3)
	sum_row.add_child(left_sum)
	left_sum.add_child(UIKit.section_header("Business management", UIKit.FILIGREE))
	_money_label = UIKit.label("Cash: ₹0", 20, UIKit.CREAM)
	_money_label.add_theme_font_override("font", UIKit.ui_font(700, 2))
	left_sum.add_child(_money_label)
	var profit_lbl := UIKit.kicker("Daily Profit: ₹%d" % (Economy.day_revenue - Economy.day_expenses), UIKit.MUTED, 12)
	profit_lbl.name = "ProfitLabel"
	left_sum.add_child(profit_lbl)

	sum_row.add_child(UIIcons.IconGlyph.new("chart", Vector2(46, 36)))

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 310)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	fit_to_viewport(scroll, 0.34, 320.0)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_refill_all = UIKit.gold_slab("Refill everything", 48)
	_refill_all.pressed.connect(func(): Inventory.refill_all())
	content.add_child(_refill_all)


func _on_open() -> void:
	_refresh()


func _refresh() -> void:
	if _list == null:
		return
	_money_label.text = "Cash: ₹%d" % Economy.cash
	var pl := find_child("ProfitLabel", true, false) as Label
	if pl:
		var profit := Economy.day_revenue - Economy.day_expenses
		pl.text = "Daily Profit: ₹%d" % profit
		pl.add_theme_color_override("font_color", UIKit.GREEN if profit >= 0 else Color("ff8a6a"))
	for child in _list.get_children():
		child.queue_free()
	for def in GameData.ingredients():
		_list.add_child(_make_row(def))
	_refill_all.text = "REFILL EVERYTHING (₹%d)" % _basket_cost()
	_refill_all.disabled = _basket_cost() == 0 or not Economy.can_afford(_basket_cost())


func _make_row(def: IngredientDef) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.slab_style(0.78, 9, UIKit.FILIGREE_DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var name_label := UIKit.kicker(def.display_name, UIKit.CREAM, 13)
	name_label.custom_minimum_size = Vector2(150, 0)
	row.add_child(name_label)

	var stock := Inventory.get_stock(def.id)
	var capacity := maxi(1, Inventory.get_capacity(def.id))
	var ratio := float(stock) / float(capacity)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = capacity
	bar.value = stock
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(150, 3)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var color := UIKit.GREEN if ratio > 0.4 else (UIKit.ORANGE if ratio > 0.15 else UIKit.RED)
	bar.add_theme_stylebox_override("background", UIKit.bar_track(3))
	bar.add_theme_stylebox_override("fill", UIKit.thin_bar(color, 3))
	row.add_child(bar)

	var count := UIKit.label("%d / %d" % [stock, capacity], 14, UIKit.MUTED)
	count.custom_minimum_size = Vector2(78, 0)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(count)

	var cost := Inventory.refill_cost(def.id)
	var button := UIKit.slab_button("+%d  ₹%d" % [def.refill_amount, cost], UIKit.GOLD, 38)
	button.custom_minimum_size = Vector2(130, 38)
	button.disabled = stock >= capacity or not Economy.can_afford(cost)
	button.pressed.connect(_on_refill.bind(def.id))
	row.add_child(button)
	return panel


func _on_refill(id: String) -> void:
	Inventory.refill(id)
	_refresh()


func _basket_cost() -> int:
	var total := 0
	for def in GameData.ingredients():
		if Inventory.get_stock(def.id) < Inventory.get_capacity(def.id):
			total += Inventory.refill_cost(def.id)
	return total
