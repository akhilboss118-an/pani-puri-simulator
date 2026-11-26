extends Node
## Ingredient stock. Refills cost money, preparation consumes stock, and the
## preparation stations ask here before letting the player add anything.

var stock: Dictionary = {}       # id -> int
var capacity: Dictionary = {}    # id -> int


func reset() -> void:
	stock.clear()
	capacity.clear()
	for def in GameData.ingredients():
		stock[def.id] = def.start_stock
		capacity[def.id] = def.capacity
	for def in GameData.ingredients():
		Events.stock_changed.emit(def.id)


func begin_day() -> void:
	# Small daily spoilage of fresh items keeps restocking meaningful.
	for id in ["coriander", "onion", "chickpea"]:
		if stock.has(id):
			stock[id] = maxi(0, int(stock[id]) - 1)
			Events.stock_changed.emit(id)


func get_stock(id: String) -> int:
	return int(stock.get(id, 0))


func get_capacity(id: String) -> int:
	return int(capacity.get(id, 0))


func has(id: String, amount: int = 1) -> bool:
	return get_stock(id) >= amount


func consume(id: String, amount: int = 1) -> bool:
	if not has(id, amount):
		return false
	stock[id] = get_stock(id) - amount
	Events.stock_changed.emit(id)
	return true


func missing_for_step(id: String) -> String:
	var def := GameData.ingredient(id)
	if def == null:
		return id
	return def.display_name + " is empty"


func refill_cost(id: String) -> int:
	var def := GameData.ingredient(id)
	if def == null:
		return 0
	var discount := 0.85 if Progression.has_upgrade("bulk_supplier") else 1.0
	return int(round(def.refill_cost * discount))


func refill(id: String) -> bool:
	var def := GameData.ingredient(id)
	if def == null:
		return false
	if get_stock(id) >= get_capacity(id):
		Events.toast.emit("%s is already full." % def.display_name, "info")
		return false
	var cost := refill_cost(id)
	if not Economy.spend(cost, "Refill " + def.display_name):
		Events.toast.emit("Not enough cash for %s." % def.display_name, "bad")
		return false
	stock[id] = mini(get_capacity(id), get_stock(id) + def.refill_amount)
	Events.stock_changed.emit(id)
	Events.toast.emit("%s restocked." % def.display_name, "good")
	return true


func refill_all() -> void:
	var total := 0
	for def in GameData.ingredients():
		if get_stock(def.id) < get_capacity(def.id):
			total += refill_cost(def.id)
	if total == 0:
		Events.toast.emit("Everything is already stocked.", "info")
		return
	if not Economy.can_afford(total):
		Events.toast.emit("Restocking everything costs Rs %d. Not enough cash." % total, "bad")
		return
	for def in GameData.ingredients():
		if get_stock(def.id) < get_capacity(def.id):
			refill(def.id)
	Events.toast.emit("Full restock complete.", "good")


func low_stock() -> Array[String]:
	var out: Array[String] = []
	for def in GameData.ingredients():
		if float(get_stock(def.id)) / float(maxi(1, get_capacity(def.id))) < 0.25:
			out.append(def.id)
	return out


func to_dict() -> Dictionary:
	return stock.duplicate()


func from_dict(data: Dictionary) -> void:
	for def in GameData.ingredients():
		stock[def.id] = int(data.get(def.id, def.start_stock))
		capacity[def.id] = def.capacity
		Events.stock_changed.emit(def.id)
