class_name InventoryPanel
extends OverlayPanel
## Stock overview and restocking. Refills are the main daily expense, so the
## cost is shown per ingredient and for the whole basket.

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
	_money_label = UIKit.label("Cash: Rs 0", 19, UIKit.ORANGE)
	content.add_child(_money_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_refill_all = UIKit.button("Refill everything", 48)
	_refill_all.pressed.connect(func(): Inventory.refill_all())
	content.add_child(_refill_all)


func _on_open() -> void:
	_refresh()


func _refresh() -> void:
	if _list == null:
		return
	_money_label.text = "Cash: Rs %d" % Economy.cash
	for child in _list.get_children():
		child.queue_free()
	for def in GameData.ingredients():
		_list.add_child(_make_row(def))
	_refill_all.text = "Refill everything (Rs %d)" % _basket_cost()
	_refill_all.disabled = _basket_cost() == 0 or not Economy.can_afford(_basket_cost())


func _make_row(def: IngredientDef) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIKit.style(UIKit.PANEL_2, 10, UIKit.BORDER, 1, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var name_label := UIKit.label(def.display_name, 16)
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
	bar.custom_minimum_size = Vector2(150, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var color := UIKit.GREEN if ratio > 0.4 else (UIKit.ORANGE if ratio > 0.15 else UIKit.RED)
	bar.add_theme_stylebox_override("fill", UIKit.style(color, 6, Color(0, 0, 0, 0), 0, 0))
	row.add_child(bar)

	var count := UIKit.label("%d / %d" % [stock, capacity], 14, UIKit.MUTED)
	count.custom_minimum_size = Vector2(78, 0)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(count)

	var cost := Inventory.refill_cost(def.id)
	var button := UIKit.button("+%d  Rs %d" % [def.refill_amount, cost], 38)
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
