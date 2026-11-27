extends Node
## Permanent badges plus lifetime counters. Unlocks stay with the player across
## new games; counters reset so each run can chase them again. Rewards are paid
## once per badge through the normal Economy/Progression services.

const DEFS := [
	{"id": "first_perfect", "title": "First Perfect Puri", "desc": "Score 100% on one puri", "counter": "perfect", "goal": 1, "cash": 120, "xp": 20},
	{"id": "serve_10", "title": "Ten Puris", "desc": "Serve 10 puris in total", "counter": "serves", "goal": 10, "cash": 150, "xp": 25},
	{"id": "serve_50", "title": "Regular Vendor", "desc": "Serve 50 puris in total", "counter": "serves", "goal": 50, "cash": 400, "xp": 60},
	{"id": "serve_100", "title": "Hundred Puri Hero", "desc": "Serve 100 puris in total", "counter": "serves", "goal": 100, "cash": 900, "xp": 120},
	{"id": "first_tip", "title": "Nice Work", "desc": "Earn your first tip", "counter": "tips", "goal": 1, "cash": 100, "xp": 15},
	{"id": "tips_100", "title": "Well Tipped", "desc": "Earn Rs 100 in tips", "counter": "tips", "goal": 100, "cash": 350, "xp": 55},
	{"id": "combo_10", "title": "On a Roll", "desc": "Reach a x10 combo", "counter": "combo", "goal": 10, "cash": 450, "xp": 70},
	{"id": "level_5", "title": "Fine Dining", "desc": "Reach level 5", "counter": "level", "goal": 5, "cash": 300, "xp": 40},
	{"id": "level_10", "title": "Global Chain", "desc": "Reach level 10", "counter": "level", "goal": 10, "cash": 1200, "xp": 150},
	{"id": "first_upgrade", "title": "Investing", "desc": "Buy your first upgrade", "counter": "upgrades", "goal": 1, "cash": 120, "xp": 20},
	{"id": "palace", "title": "Landmark", "desc": "Build the Pani Puri Palace", "counter": "tier", "goal": 3, "cash": 600, "xp": 80},
	{"id": "world", "title": "Around the World", "desc": "Finish the World Tour", "counter": "tier", "goal": 5, "cash": 2000, "xp": 200},
	{"id": "goal_master", "title": "Clean Sweep", "desc": "Finish all 3 goals in one day", "counter": "goals_day", "goal": 3, "cash": 350, "xp": 50},
	{"id": "no_walkout", "title": "Nobody Left", "desc": "Close a day with no walkouts", "counter": "no_walkout", "goal": 1, "cash": 300, "xp": 45},
	{"id": "vip_served", "title": "VIP Treatment", "desc": "Serve a VIP customer", "counter": "vip", "goal": 1, "cash": 250, "xp": 35},
	{"id": "festival", "title": "Festive Spirit", "desc": "Serve on a festival day", "counter": "festival", "goal": 1, "cash": 250, "xp": 35},
	{"id": "machine", "title": "Let the Machine Do It", "desc": "Serve 25 machine-filled puris", "counter": "machine", "goal": 25, "cash": 500, "xp": 70},
	{"id": "recipe_master", "title": "Recipe Master", "desc": "Take a recipe to 3 stars", "counter": "recipe_master", "goal": 1, "cash": 400, "xp": 60},
]

var unlocked: Dictionary = {}
var counters: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.tip_earned.connect(_on_tip)
	Events.combo_changed.connect(_on_combo)
	Events.level_up.connect(_on_level)
	Events.upgrade_purchased.connect(_on_upgrade)
	Events.recipe_mastery_changed.connect(_on_recipe_mastery)


func reset() -> void:
	counters.clear()
	_emit_progress()


func on_puri_served(score: float, recipe_id: String, auto_filled: bool, vip: bool) -> void:
	_bump("serves", 1)
	if score >= 0.9:
		_bump("perfect", 1)
	if auto_filled:
		_bump("machine", 1)
	if vip:
		_bump("vip", 1)
	Progression.record_recipe_serve(recipe_id, score)
	_check()


func on_festival_served() -> void:
	_bump("festival", 1)
	_check()


func on_day_end(report: Dictionary) -> void:
	if int(report.get("lost", 0)) == 0:
		_bump("no_walkout", 1)
	var goals: Variant = report.get("goals", {})
	if typeof(goals) == TYPE_DICTIONARY and int((goals as Dictionary).get("completed", 0)) >= 3:
		_bump("goals_day", 1)
	_check()


func _on_tip(amount: int, _total: int) -> void:
	_bump("tips", amount)
	_check()


func _on_combo(combo: int, _multiplier: float) -> void:
	if combo > int(counters.get("combo", 0)):
		counters["combo"] = combo
		_check()


func _on_level(level: int) -> void:
	if level > int(counters.get("level", 0)):
		counters["level"] = level
		_check()


func _on_upgrade(id: String) -> void:
	_bump("upgrades", 1)
	var tier := Progression.restaurant_tier()
	if tier > int(counters.get("tier", 0)):
		counters["tier"] = tier
	if id == "world_tour":
		Events.toast.emit("Achievement hunt: World Tour complete!", "good")
	_check()


func _on_recipe_mastery(_recipe_id: String, stars: int) -> void:
	if stars >= 3:
		_bump("recipe_master", 1)
		_check()


func _bump(key: String, amount: int) -> void:
	counters[key] = int(counters.get(key, 0)) + amount


func _check() -> void:
	for def in DEFS:
		var entry: Dictionary = def
		var id := String(entry["id"])
		if unlocked.has(id):
			continue
		if int(counters.get(String(entry["counter"]), 0)) >= int(entry["goal"]):
			unlock(id)


func unlock(id: String) -> void:
	if unlocked.has(id):
		return
	var def := def_for(id)
	if def.is_empty():
		return
	unlocked[id] = true
	var cash := int(def.get("cash", 0))
	var xp := int(def.get("xp", 0))
	Economy.add_cash(cash, "Achievement: " + String(def["title"]))
	Progression.add_xp(xp)
	Events.achievement_unlocked.emit(id, String(def["title"]), cash, xp)
	Events.toast.emit("Achievement: %s   +Rs %d, +%d XP" % [def["title"], cash, xp], "good")
	Audio.play("good", 1.3, -5.0)
	Audio.haptic(45)
	_emit_progress()


func def_for(id: String) -> Dictionary:
	for def in DEFS:
		if String((def as Dictionary).get("id", "")) == id:
			return def
	return {}


func progress_text(id: String) -> String:
	var def := def_for(id)
	if def.is_empty():
		return ""
	var goal := int(def["goal"])
	var value := mini(int(counters.get(String(def["counter"]), 0)), goal)
	return "%d / %d" % [value, goal]


func unlocked_count() -> int:
	return unlocked.size()


func _emit_progress() -> void:
	for def in DEFS:
		var id := String((def as Dictionary).get("id", ""))
		if id != "":
			Events.achievement_progress.emit(id, int(counters.get(String((def as Dictionary)["counter"]), 0)))


# ---------------------------------------------------------------------- save

func to_dict() -> Dictionary:
	return {
		"unlocked": unlocked.keys(),
		"counters": counters.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	unlocked.clear()
	for id in data.get("unlocked", []):
		unlocked[String(id)] = true
	counters.clear()
	var stored: Variant = data.get("counters", {})
	if typeof(stored) == TYPE_DICTIONARY:
		for key in (stored as Dictionary).keys():
			counters[String(key)] = int((stored as Dictionary)[key])
	_emit_progress()
