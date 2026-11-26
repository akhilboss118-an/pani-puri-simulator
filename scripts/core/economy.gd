extends Node
## Central money service. Every rupee in the game moves through here so the
## HUD and the daily report can never disagree with the real balance.

var cash: int = 500
var day_revenue: int = 0
var day_expenses: int = 0
var total_revenue: int = 0
var total_expenses: int = 0
var transactions: Array[Dictionary] = []


func reset() -> void:
	cash = 500
	day_revenue = 0
	day_expenses = 0
	total_revenue = 0
	total_expenses = 0
	transactions.clear()
	Events.money_changed.emit(cash)


func begin_day() -> void:
	day_revenue = 0
	day_expenses = 0


func can_afford(amount: int) -> bool:
	return cash >= amount


func add_cash(amount: int, reason: String = "Sale") -> void:
	if amount == 0:
		return
	cash += amount
	if amount > 0:
		day_revenue += amount
		total_revenue += amount
	_log(amount, reason)
	Events.money_changed.emit(cash)


func spend(amount: int, reason: String = "Purchase") -> bool:
	if amount > cash:
		return false
	cash -= amount
	day_expenses += amount
	total_expenses += amount
	_log(-amount, reason)
	Events.money_changed.emit(cash)
	return true


func profit_today() -> int:
	return day_revenue - day_expenses


func _log(amount: int, reason: String) -> void:
	transactions.append({"amount": amount, "reason": reason, "day": Game.day})
	if transactions.size() > 60:
		transactions.pop_front()
