extends Node
## Order lifecycle: generating believable customer orders, scoring a plate of
## puris against the order, and keeping the day's service statistics.

var active_order: Dictionary = {}
var active_customer: Node = null

var day_served: int = 0
var day_lost: int = 0
var day_waste: int = 0
var day_rating: float = 0.0
var _rating_sum: float = 0.0
var _rating_count: int = 0


func reset() -> void:
	active_order.clear()
	active_customer = null
	reset_day()
	day_served = 0
	day_lost = 0


func reset_day() -> void:
	day_served = 0
	day_lost = 0
	day_waste = 0
	day_rating = 0.0
	_rating_sum = 0.0
	_rating_count = 0


# --------------------------------------------------------------- generation

func generate_order(customer_name: String = "Customer", vip: bool = false) -> Dictionary:
	var pool: Array[RecipeDef] = []
	var total_weight := 0.0
	for recipe in GameData.recipes():
		if Progression.level < recipe.unlock_level:
			continue
		if Progression.reputation >= recipe.unlock_reputation:
			pool.append(recipe)
			total_weight += recipe.weight
	if pool.is_empty():
		pool.append(GameData.recipes()[0])

	var roll := randf() * maxf(total_weight, 0.001)
	var picked: RecipeDef = pool[0]
	for recipe in pool:
		roll -= recipe.weight
		if roll <= 0.0:
			picked = recipe
			break

	var quantity := 3
	var rep := Progression.reputation
	if vip:
		quantity = randi_range(4, 8)
	elif rep > 55.0:
		quantity = randi_range(3, 6)
	elif rep > 25.0:
		quantity = randi_range(3, 5)

	var order := {
		"recipe_id": picked.id,
		"name": picked.display_name,
		"quantity": quantity,
		"pani": picked.default_pani,
		"spice": picked.default_spice,
		"sweet": picked.default_sweet,
		"onion": picked.default_onion,
		"chickpea": picked.default_chickpea,
		"price": Progression.price_for(picked),
		"customer": customer_name,
		"note": "",
	}
	# Small personal requests make each order feel like a person, not a form.
	if randf() < 0.22:
		order.onion = not order.onion
		order.note = "No onion please" if not order.onion else "Extra onion!"
	elif randf() < 0.18:
		order.spice = clampi(int(order.spice) + (1 if randf() < 0.6 else -1), 0, 2)
		order.note = "Make it %s" % GameData.SPICE_NAMES[order.spice].to_lower()
	elif randf() < 0.14:
		order.sweet = not order.sweet
		order.note = "Extra sweet chutney" if order.sweet else "Skip the sweet chutney"

	return order


func set_active(order: Dictionary, customer: Node) -> void:
	active_order = order
	active_customer = customer
	Events.order_updated.emit(order)


func clear_active() -> void:
	active_order = {}
	active_customer = null
	Events.order_cleared.emit()


# --------------------------------------------------------------- validation

func evaluate_plate(puris: Array, order: Dictionary, patience_ratio: float = 1.0) -> Dictionary:
	var quantity := int(order.get("quantity", 1))
	var delivered := puris.size()
	var missing := maxi(0, quantity - delivered)
	var extra := maxi(0, delivered - quantity)

	var score_sum := 0.0
	var ready_count := 0
	for puri in puris:
		var data: PuriData = puri if puri is PuriData else puri.data
		score_sum += data.score_against(order)
		if data.is_ready():
			ready_count += 1

	var avg := score_sum / maxf(1.0, float(delivered))
	var quantity_factor := clampf(float(delivered) / float(maxi(1, quantity)), 0.0, 1.0)
	var score := avg * (0.55 + 0.45 * quantity_factor)
	score -= float(extra) * 0.06
	if delivered == 0:
		score = 0.0
	score = clampf(score, 0.0, 1.0)

	var price := int(order.get("price", 30))
	var patience_factor := lerpf(0.78, 1.04, clampf(patience_ratio, 0.0, 1.0))
	var payment := int(round(float(price) * float(delivered) * (0.45 + 0.55 * score) * patience_factor))

	var message := _score_message(score, missing, ready_count, delivered)
	return {
		"score": score,
		"payment": payment,
		"delivered": delivered,
		"missing": missing,
		"extra": extra,
		"ready": ready_count,
		"patience_factor": patience_factor,
		"message": message,
	}


## Called when an order is fully served one-puri-at-a-time. Updates day
## statistics without re-adding cash/reputation (already handled per-puri).
func register_completion(score: float, quantity: int) -> void:
	day_served += quantity
	_rating_sum += score
	_rating_count += 1
	day_rating = _rating_sum / maxi(1.0, float(_rating_count))


func serve_single_puri(puri_data: PuriData, order: Dictionary, patience_ratio: float = 1.0) -> Dictionary:
	var remaining := int(order.get("quantity", 1))
	var score := puri_data.score_against(order)
	var price := int(order.get("price", 30))
	var patience_factor := lerpf(0.78, 1.04, clampf(patience_ratio, 0.0, 1.0))
	var payment := int(round(float(price) * (0.45 + 0.55 * score) * patience_factor))
	order["quantity"] = maxi(0, remaining - 1)
	var complete := remaining <= 1
	var remaining_after := maxi(0, remaining - 1)
	var message := _single_puri_message(score, remaining_after)
	return {
		"score": score,
		"payment": payment,
		"complete": complete,
		"message": message,
		"remaining": remaining_after,
	}


func _single_puri_message(score: float, remaining: int) -> String:
	var msg: String
	if score >= 0.9:
		msg = "Perfect!"
	elif score >= 0.72:
		msg = "Good."
	elif score >= 0.5:
		msg = "A bit off."
	else:
		msg = "Not quite right."
	if remaining > 0:
		msg += "  %d more to go." % remaining
	return msg


func _score_message(score: float, missing: int, ready: int, delivered: int) -> String:
	if delivered == 0:
		return "You served an empty plate."
	if missing > 0:
		return "Short order - %d puri(s) missing." % missing
	if ready < delivered:
		return "Some puris were not finished properly."
	if score >= 0.9:
		return "Perfect! Exactly how they asked."
	if score >= 0.72:
		return "Good, they look happy."
	if score >= 0.5:
		return "They noticed a few things were off."
	return "That was not what they ordered."


# ------------------------------------------------------------------ results

func register_result(score: float, payment: int, order: Dictionary) -> int:
	day_served += int(order.get("quantity", 0))
	_rating_sum += score
	_rating_count += 1
	day_rating = _rating_sum / maxf(1.0, float(_rating_count))
	Economy.add_cash(payment, "Order served")
	Progression.add_reputation((score - 0.55) * 5.0)
	var xp_gain := 8 + int(round(score * 16.0)) + int(order.get("quantity", 0))
	if score >= 0.9:
		xp_gain += 6
	Progression.add_xp(xp_gain)
	Events.quality_result.emit(score, _score_message(score, 0, 0, 1))
	return xp_gain


func register_walkout() -> void:
	day_lost += 1
	Progression.add_reputation(-2.5)


func register_waste(count: int = 1) -> void:
	day_waste += count
