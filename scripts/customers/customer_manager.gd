class_name CustomerManager
extends Node3D
## Spawns customers, keeps the queue ordered and turns a served plate into
## money, reputation and a reaction.

var queue_points: Array[Vector3] = []
var spawn_point: Vector3 = Vector3(-16, 0, 6.5)
var exit_point: Vector3 = Vector3(18, 0, 6.5)

var customers: Array[Customer] = []
var queue: Array[Customer] = []
var active: Customer = null

var _timer: float = 2.0
var _running: bool = false
var _serial: int = 0
var _tutorial_customer: Customer = null


func _ready() -> void:
	add_to_group("customer_manager")


func begin_day() -> void:
	for c in customers:
		if is_instance_valid(c):
			c.queue_free()
	customers.clear()
	queue.clear()
	active = null
	Orders.clear_active()
	_timer = 2.5
	_serial = 0
	_tutorial_customer = null
	_running = true


func close_stall() -> void:
	_running = false
	active = null
	Orders.clear_active()
	for c in customers:
		if is_instance_valid(c) and c.state != Customer.State.LEAVING:
			c.leave(exit_point)


# ------------------------------------------------------------------ tutorial

## Pauses natural arrivals while the guided lesson runs. The scripted customer
## is already placed at the counter and stays active.
func freeze_for_tutorial() -> void:
	_running = false
	_timer = 999.0


func end_tutorial() -> void:
	_tutorial_customer = null
	_running = true
	_timer = 8.0


## One gentle customer with a tiny, fixed order that matches the six tutorial
## steps exactly (one mild mint puri with potato, no onion or chickpea).
func spawn_tutorial_customer() -> Customer:
	for c in customers:
		if is_instance_valid(c):
			c.queue_free()
	customers.clear()
	queue.clear()
	active = null
	Orders.clear_active()
	_serial = 1

	var customer := Customer.new()
	customer.customer_name = "Customer 1"
	customer.model_index = 1
	customer.is_vip = false
	add_child(customer)
	customer.setup(4.0)
	customer.exit_position = exit_point
	var spot := _queue_slot(0)
	customer.global_position = spot
	customer.target_position = spot
	customer.has_arrived = true
	customer.departed.connect(_on_departed)
	customer.walked_out.connect(_on_walked_out)
	customers.append(customer)
	queue.append(customer)
	_tutorial_customer = customer

	var recipe := GameData.recipe("classic")
	var order := {
		"recipe_id": "classic",
		"name": "Classic Pani Puri",
		"quantity": 1,
		"pani": "mint",
		"spice": 0,
		"sweet": false,
		"onion": false,
		"chickpea": false,
		"price": Progression.price_for(recipe),
		"customer": "Customer 1",
		"note": "One puri, please!",
	}
	customer.begin_order(order)
	Orders.set_active(order, customer)
	active = customer
	customer.face_towards(Vector3(0.0, 0.14, 10.65))
	return customer


func _process(delta: float) -> void:
	if not _running or Game.state != Game.State.PLAYING:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = Progression.arrival_interval() * randf_range(0.75, 1.25)
		if queue.size() < Progression.queue_size() and customers.size() < Progression.max_customers():
			_spawn()
	if active == null and not queue.is_empty():
		var front := queue[0]
		if is_instance_valid(front) and front.state == Customer.State.QUEUE and front.has_arrived:
			_promote(front)


func _spawn() -> void:
	_serial += 1
	var customer := Customer.new()
	customer.customer_name = "Customer %d" % _serial
	customer.model_index = ((_serial - 1) % Customer.MODEL_COUNT) + 1
	customer.is_vip = randf() < Progression.vip_chance()
	add_child(customer)
	customer.setup(Progression.patience_bonus())
	customer.exit_position = exit_point
	customer.global_position = spawn_point + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-0.5, 0.5))
	customer.departed.connect(_on_departed)
	customer.walked_out.connect(_on_walked_out)
	customers.append(customer)
	queue.append(customer)
	customer.walk_to(_queue_slot(queue.size() - 1), queue.size() - 1)
	Audio.play("bell", randf_range(0.9, 1.1), -22.0)
	if customer.is_vip:
		Events.toast.emit("A VIP customer has arrived!", "good")


func _queue_slot(index: int) -> Vector3:
	if queue_points.is_empty():
		return spawn_point
	return queue_points[clampi(index, 0, queue_points.size() - 1)]


func _promote(customer: Customer) -> void:
	active = customer
	var order := Orders.generate_order(customer.customer_name, customer.is_vip)
	if customer.is_vip:
		order.price = int(order.price * 1.5)
		order.name = "VIP: " + order.name
	customer.begin_order(order)
	Orders.set_active(order, customer)
	Events.toast.emit("%s wants %d puris." % [customer.customer_name, int(order.quantity)], "info")
	if customer.is_vip:
		Events.toast.emit("VIP order - pays 50%% more!", "good")


func _on_walked_out(customer: Customer) -> void:
	if not is_instance_valid(customer):
		return
	queue.erase(customer)
	if active == customer:
		active = null
		Orders.clear_active()
	Orders.register_walkout()
	Orders.break_combo()
	Events.toast.emit("%s got tired of waiting and left." % customer.customer_name, "bad")
	customer.leave(exit_point)
	_refresh_queue()


func _on_departed(customer: Customer) -> void:
	customers.erase(customer)
	queue.erase(customer)
	if active == customer:
		active = null
		Orders.clear_active()
	if is_instance_valid(customer):
		customer.queue_free()
	_refresh_queue()


func _refresh_queue() -> void:
	for i in queue.size():
		var customer := queue[i]
		if not is_instance_valid(customer):
			continue
		if customer == active:
			continue
		if customer.state == Customer.State.LEAVING:
			continue
		customer.walk_to(_queue_slot(i), i)


## Called by the serving plate. Feeds the customer one puri at a time: each
## puri on the plate is checked against the order and paid for individually.
## When the order quantity is reached, the customer leaves and the next queue
## customer steps up.
func serve_plate(puris: Array[PuriData]) -> bool:
	if active == null or not is_instance_valid(active):
		Events.toast.emit("No customer is waiting at the counter.", "info")
		return false
	var order := Orders.active_order
	var order_quantity := int(order.get("quantity", 1))
	var total_payment := 0
	var total_score := 0.0
	var count := 0
	var complete := false
	var final_message := ""
	for puri in puris.duplicate():
		var result := Orders.serve_single_puri(puri, order, active.patience_ratio())
		total_payment += result.payment
		total_score += result.score
		count += 1
		final_message = result.message
		if result.complete:
			complete = true
			break
	Economy.add_cash(total_payment, "Order served")
	Progression.add_reputation((total_score / maxi(1, count) - 0.55) * 5.0)
	var xp_gain := 8 + int(round(total_score * 8.0)) + count
	Progression.add_xp(xp_gain)
	var avg_score := total_score / maxi(1, count)
	var tip := 0
	if complete:
		var patience := active.patience_ratio() if is_instance_valid(active) else 0.0
		tip = Orders.register_completion(avg_score, order_quantity, patience, int(order.get("price", 30)))
	_spawn_money_text(active.global_position + Vector3(0, 2.0, 0), total_payment, xp_gain, tip)
	var message := final_message + "  +Rs %d" % total_payment
	if tip > 0:
		message += "  +Rs %d tip!" % tip
	Events.toast.emit(message, "good" if avg_score >= 0.6 else "bad")
	if complete:
		active.receive(avg_score, final_message)
		active.leave(active.exit_position)
		var just_served := active
		Orders.clear_active()
		queue.erase(just_served)
		active = null
		_refresh_queue()
	return true


func _spawn_money_text(world_position: Vector3, amount: int, xp_gain: int = 0, tip: int = 0) -> void:
	var label := Label3D.new()
	label.text = "+ Rs %d" % amount
	if tip > 0:
		label.text += "\n+ Rs %d tip" % tip
	if xp_gain > 0:
		label.text += "   +%d XP" % xp_gain
	label.font_size = 64
	label.pixel_size = 0.005
	label.modulate = Color("ffe08a")
	label.outline_size = 6
	label.outline_modulate = Color(0.1, 0.06, 0.02, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	label.global_position = world_position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", world_position.y + 0.8, 1.2)
	tween.tween_property(label, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(label.queue_free)


func waiting_count() -> int:
	return queue.size()


