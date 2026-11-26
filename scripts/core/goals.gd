extends Node
## Three deterministic daily goals. The same day always produces the same set,
## so the report and a saved/resumed day agree. Goals pay cash and XP and are
## stored in the save file alongside the rest of the day's state.

const TEMPLATES := [
	{
		"id": "serve_puris", "label": "Serve %d puris", "metric": "puris",
		"targets": [8, 12, 16], "rewards": [[150, 25], [220, 35], [320, 50]],
	},
	{
		"id": "earn_cash", "label": "Earn Rs %d", "metric": "income",
		"targets": [350, 600, 900], "rewards": [[180, 25], [260, 40], [380, 55]],
	},
	{
		"id": "perfect_puris", "label": "Make %d perfect puris", "metric": "perfect",
		"targets": [3, 5, 7], "rewards": [[200, 30], [300, 45], [420, 60]],
	},
	{
		"id": "complete_orders", "label": "Complete %d orders", "metric": "orders",
		"targets": [2, 3, 4], "rewards": [[160, 22], [240, 32], [320, 42]],
	},
	{
		"id": "combo", "label": "Reach a x%d combo", "metric": "combo",
		"targets": [4, 6, 8], "rewards": [[180, 25], [260, 40], [360, 55]],
	},
	{
		"id": "tips", "label": "Earn Rs %d in tips", "metric": "tips",
		"targets": [15, 30, 50], "rewards": [[150, 20], [220, 30], [320, 45]],
	},
]

var goals: Array[Dictionary] = []
var completed: int = 0
var _day: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.income.connect(_on_income)
	Events.tip_earned.connect(_on_tip)
	Events.order_completed.connect(_on_order_completed)
	Events.combo_changed.connect(_on_combo)


func begin_day(day: int) -> void:
	_day = day
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for(day)
	var picked: Array[int] = []
	while picked.size() < 3:
		var index := rng.randi_range(0, TEMPLATES.size() - 1)
		if not picked.has(index):
			picked.append(index)
	var tier := 0 if day <= 2 else (1 if day <= 5 else 2)

	goals.clear()
	completed = 0
	for index in picked:
		var source: Dictionary = TEMPLATES[index]
		var targets: Array = source["targets"]
		var rewards: Array = source["rewards"]
		var target := int(targets[tier])
		var reward: Array = rewards[tier]
		goals.append({
			"id": String(source["id"]),
			"label": String(source["label"]) % target,
			"metric": String(source["metric"]),
			"target": target,
			"progress": 0,
			"reward_cash": int(reward[0]),
			"reward_xp": int(reward[1]),
			"done": false,
		})
	_emit()


func _seed_for(day: int) -> int:
	var text := str(day)
	var hash_value := 2166136261
	for i in text.length():
		hash_value = (hash_value ^ text.unicode_at(i)) * 16777619
	return hash_value


# ------------------------------------------------------------------ tracking

func on_puri_served(score: float) -> void:
	_advance("puris", 1)
	if score >= 0.9:
		_advance("perfect", 1)


func _on_income(amount: int) -> void:
	_advance("income", amount)


func _on_tip(amount: int, _total: int) -> void:
	_advance("tips", amount)


func _on_order_completed(_quantity: int) -> void:
	_advance("orders", 1)


func _on_combo(combo: int, _multiplier: float) -> void:
	_set_metric("combo", combo)


func _advance(metric: String, amount: int) -> void:
	if goals.is_empty() or amount <= 0:
		return
	for i in goals.size():
		var goal: Dictionary = goals[i]
		if bool(goal.get("done", false)) or String(goal.get("metric", "")) != metric:
			continue
		var target := maxi(1, int(goal.get("target", 1)))
		var before := int(goal.get("progress", 0))
		var after := mini(target, before + amount)
		if after == before:
			continue
		goal["progress"] = after
		Events.goal_progress.emit(String(goal["id"]), after, target)
		if after >= target:
			_award(i)
	_emit()


func _set_metric(metric: String, value: int) -> void:
	if goals.is_empty():
		return
	for i in goals.size():
		var goal: Dictionary = goals[i]
		if bool(goal.get("done", false)) or String(goal.get("metric", "")) != metric:
			continue
		var target := maxi(1, int(goal.get("target", 1)))
		var after := mini(target, value)
		if after <= int(goal.get("progress", 0)):
			continue
		goal["progress"] = after
		Events.goal_progress.emit(String(goal["id"]), after, target)
		if after >= target:
			_award(i)
	_emit()


func _award(index: int) -> void:
	var goal: Dictionary = goals[index]
	if bool(goal.get("done", false)):
		return
	goal["done"] = true
	goal["progress"] = int(goal.get("target", 1))
	completed += 1
	var cash := int(goal.get("reward_cash", 0))
	var xp := int(goal.get("reward_xp", 0))
	Economy.add_cash(cash, "Daily goal")
	Progression.add_xp(xp)
	Events.goal_completed.emit(String(goal["id"]), String(goal["label"]), cash, xp)
	Events.toast.emit("Daily goal: %s   +Rs %d, +%d XP" % [goal["label"], cash, xp], "good")
	Audio.play("good", 1.25, -6.0)


func _emit() -> void:
	Events.goals_changed.emit(to_dict())


func summary() -> String:
	return "%d / %d" % [completed, goals.size()]


# ---------------------------------------------------------------------- save

func to_dict() -> Dictionary:
	return {
		"day": _day,
		"completed": completed,
		"goals": goals.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	_day = maxi(1, int(data.get("day", Game.day)))
	var stored: Variant = data.get("goals", [])
	goals.clear()
	completed = 0
	if typeof(stored) == TYPE_ARRAY:
		for entry in stored:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var goal: Dictionary = (entry as Dictionary).duplicate(true)
			goals.append(goal)
			if bool(goal.get("done", false)):
				completed += 1
	if goals.is_empty():
		begin_day(_day)
		return
	_emit()
