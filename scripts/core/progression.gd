extends Node
## Reputation, XP/levels, pricing and upgrades. Upgrades are the only place
## where gameplay numbers are allowed to change at runtime.

const MAX_LEVEL := 10

var reputation: float = 20.0
var price_per_puri: int = 30
var level: int = 1
var xp: int = 0
var lifetime_xp: int = 0
var purchased: Dictionary = {}
var recipe_stats: Dictionary = {}   # recipe_id -> {serves, best, stars}

var _rush_was_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	_check_rush_hour()


func reset() -> void:
	reputation = 20.0
	price_per_puri = 30
	level = 1
	xp = 0
	lifetime_xp = 0
	purchased.clear()
	recipe_stats.clear()
	Events.reputation_changed.emit(reputation)
	Events.price_changed.emit(price_per_puri)
	_emit_xp()


func begin_day() -> void:
	# Reputation slowly drifts toward a neutral 50 if the stall stays closed.
	pass


# ------------------------------------------------------------------- levels

## XP required to go from `for_level` to the next level.
func xp_to_next(for_level: int = -1) -> int:
	var lv := level if for_level < 0 else for_level
	if lv >= MAX_LEVEL:
		return 0
	var step := lv - 1
	return 90 + step * 70 + step * step * 10


func xp_ratio() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	return clampf(float(xp) / float(maxi(1, xp_to_next())), 0.0, 1.0)


## Adds XP and returns how many levels were gained.
func add_xp(amount: int) -> int:
	if amount <= 0 or level >= MAX_LEVEL:
		return 0
	lifetime_xp += amount
	xp += amount
	var gained := 0
	while level < MAX_LEVEL and xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		gained += 1
		Events.level_up.emit(level)
		Events.toast.emit("Level %d!  %s" % [level, level_reward_text(level)], "good")
		Audio.play("good", 1.15, -6.0)
		Audio.haptic(60)
	if level >= MAX_LEVEL:
		xp = 0
	_emit_xp()
	return gained


func level_title() -> String:
	if level >= 10:
		return "Global Chain"
	if level >= 8:
		return "Franchise HQ"
	if level >= 7:
		return "Pani Puri Palace"
	if level >= 5:
		return "Fine Dining House"
	if level >= 3:
		return "Pani Puri House"
	if level >= 2:
		return "Corner Stall"
	return "Street Cart"


func level_reward_text(for_level: int) -> String:
	match for_level:
		2:
			return "New recipe: Dahi Puri."
		3:
			return "Restaurant Renovation unlocked in Upgrades."
		4:
			return "New recipe: Masala Blast."
		5:
			return "Fine Dining Terrace unlocked in Upgrades."
		6:
			return "New recipe: Royal Pani Puri."
		7:
			return "Pani Puri Palace unlocked in Upgrades."
		8:
			return "New recipe: Signature Platter. Franchise HQ unlocked."
		9:
			return "New recipe: Chaat Bomb. Rare VIP customers appear."
		10:
			return "New recipe: Tandoori Pani Puri. World Tour unlocked."
		_:
			return "Customers are noticing your stall."


func _emit_xp() -> void:
	Events.xp_changed.emit(level, xp, xp_to_next(), xp_ratio())


# --------------------------------------------------------------- reputation

func add_reputation(delta: float) -> void:
	reputation = clampf(reputation + delta, 0.0, 100.0)
	Events.reputation_changed.emit(reputation)


func set_price(value: int) -> void:
	price_per_puri = clampi(value, 20, 50)
	Events.price_changed.emit(price_per_puri)


func price_for(recipe: RecipeDef) -> int:
	var premium := maxi(0, recipe.base_price - 30)
	var price := price_per_puri + premium
	if recipe_stars(recipe.id) >= 3:
		price += int(round(float(recipe.base_price) * 0.1))
	return price


func recipe_stars(recipe_id: String) -> int:
	var entry: Dictionary = recipe_stats.get(recipe_id, {})
	var serves := int(entry.get("serves", 0))
	var best := float(entry.get("best", 0.0))
	if serves >= 40 and best >= 0.85:
		return 3
	if serves >= 15 and best >= 0.7:
		return 2
	if serves >= 5:
		return 1
	return 0


func record_recipe_serve(recipe_id: String, score: float) -> void:
	var entry: Dictionary = (recipe_stats.get(recipe_id, {"serves": 0, "best": 0.0, "stars": 0}) as Dictionary).duplicate()
	entry["serves"] = int(entry.get("serves", 0)) + 1
	entry["best"] = maxf(float(entry.get("best", 0.0)), score)
	var stars := recipe_stars(recipe_id)
	if stars > int(entry.get("stars", 0)):
		entry["stars"] = stars
		Events.recipe_mastery_changed.emit(recipe_id, stars)
		Events.toast.emit("Recipe mastered: %s - %d star%s!" % [
			GameData.recipe(recipe_id).display_name, stars, "" if stars == 1 else "s",
		], "good")
	recipe_stats[recipe_id] = entry


# ----------------------------------------------------------------- upgrades

func has_upgrade(id: String) -> bool:
	return purchased.has(id)


func upgrade_unlocked(id: String) -> bool:
	return upgrade_lock_reason(id) == ""


func upgrade_lock_reason(id: String) -> String:
	if has_upgrade(id):
		return ""
	var data := GameData.upgrade(id)
	if data.is_empty():
		return "Unknown upgrade"
	var required_level := int(data.get("level", 1))
	if level < required_level:
		return "Unlocks at level %d" % required_level
	var requires := String(data.get("requires", ""))
	if requires != "" and not has_upgrade(requires):
		var parent := GameData.upgrade(requires)
		return "Needs " + String(parent.get("name", requires))
	return ""


func can_buy(id: String) -> bool:
	if has_upgrade(id):
		return false
	var data := GameData.upgrade(id)
	if data.is_empty():
		return false
	if not upgrade_unlocked(id):
		return false
	return Economy.can_afford(int(data.cost))


func buy(id: String) -> bool:
	var data := GameData.upgrade(id)
	if data.is_empty() or has_upgrade(id):
		return false
	if not upgrade_unlocked(id):
		Events.toast.emit("%s - %s." % [data.name, upgrade_lock_reason(id)], "bad")
		return false
	var cost := int(data.cost)
	if not Economy.spend(cost, "Upgrade: " + String(data.name)):
		Events.toast.emit("Not enough cash for %s." % data.name, "bad")
		return false
	purchased[id] = true
	Events.upgrade_purchased.emit(id)
	Events.toast.emit("%s installed!" % data.name, "good")
	if id == "signboard":
		add_reputation(3.0)
	if String(data.get("tier", "")) == "restaurant":
		add_reputation(5.0)
	return true


## 0 = street cart, 1 = restaurant, 2 = fine dining, 3 = palace,
## 4 = franchise HQ, 5 = world tour.
func restaurant_tier() -> int:
	if has_upgrade("world_tour"):
		return 5
	if has_upgrade("franchise_hq"):
		return 4
	if has_upgrade("pani_puri_palace"):
		return 3
	if has_upgrade("fine_dining"):
		return 2
	if has_upgrade("restaurant_reno"):
		return 1
	return 0


# ------------------------------------------------------------------ effects

func plate_capacity() -> int:
	return 9 if has_upgrade("bigger_plate") else 6


func queue_size() -> int:
	var size := 4
	if has_upgrade("queue_bench"):
		size += 1
	if has_upgrade("street_permit"):
		size += 1
	size += restaurant_tier()
	return mini(size, 12)


func max_customers() -> int:
	var cap := 4
	if has_upgrade("queue_bench"):
		cap += 1
	if has_upgrade("street_permit"):
		cap += 2
	cap += restaurant_tier()
	if Game.settings.quality == 0:
		cap = mini(cap, 6)
	return mini(cap, 12)


func patience_bonus() -> float:
	var bonus := 0.0
	if has_upgrade("signboard"):
		bonus += 0.12
	if has_upgrade("queue_bench"):
		bonus += 0.15
	bonus += restaurant_tier() * 0.04
	return bonus


func arrival_interval() -> float:
	var base := lerpf(11.0, 4.2, clampf(reputation / 100.0, 0.0, 1.0))
	if has_upgrade("signboard"):
		base *= 0.82
	if has_upgrade("street_permit"):
		base *= 0.8
	base *= maxf(0.72, 1.0 - float(level - 1) * 0.025)
	base *= [1.0, 0.94, 0.88, 0.82, 0.76, 0.70][restaurant_tier()]
	base *= rush_multiplier()
	if Game.weather() == "rain":
		base *= 1.3
	elif Game.weather() == "heat":
		base *= 0.95
	return maxf(2.2, base)


func machine_interval() -> float:
	if not has_upgrade("potato_machine"):
		return 0.0
	return 4.0 if has_upgrade("turbo_peeler") else 8.0


func available_pani() -> Array[String]:
	var list: Array[String] = ["mint"]
	if has_upgrade("garlic_pani"):
		list.append("garlic")
	return list


func unlock_progress_text() -> String:
	if level < 3:
		return "Level 3 unlocks the Restaurant Renovation."
	if not has_upgrade("restaurant_reno"):
		return "Restaurant Renovation is ready in this panel."
	if level < 5:
		return "Level 5 unlocks the Fine Dining Terrace."
	if not has_upgrade("fine_dining"):
		return "Fine Dining Terrace is ready in this panel."
	if level < 7:
		return "Level 7 unlocks the Pani Puri Palace."
	if not has_upgrade("pani_puri_palace"):
		return "Pani Puri Palace is ready in this panel."
	if level < 8:
		return "Level 8 unlocks the Franchise Headquarters."
	if not has_upgrade("franchise_hq"):
		return "Franchise Headquarters is ready in this panel."
	if level < 10:
		return "Level 10 unlocks the World Tour Expansion."
	if not has_upgrade("world_tour"):
		return "World Tour Expansion is ready in this panel."
	return "World Tour complete - Pani Puri is global."


# --------------------------------------------------------------- rush hour

## Rush hour windows (lunch and dinner) bring faster arrivals and VIP customers.
func rush_hour_active() -> bool:
	var h := Clock.hour()
	return h >= 12 and h < 14 or h >= 18 and h < 20


## Arrival speed multiplier during rush hour (lower = faster arrivals).
func rush_multiplier() -> float:
	if rush_hour_active():
		return 0.55
	return 1.0


## Chance a spawned customer is a VIP (pays more, more patient, complex orders).
func vip_chance() -> float:
	if not rush_hour_active():
		return 0.0
	if has_upgrade("world_tour"):
		return 0.45
	if has_upgrade("franchise_hq"):
		return 0.35
	if has_upgrade("pani_puri_palace"):
		return 0.25
	return 0.15


func _check_rush_hour() -> void:
	var active := rush_hour_active()
	if active != _rush_was_active:
		_rush_was_active = active
		Events.rush_hour_changed.emit(active)
		if active:
			Events.toast.emit("Rush hour! Customers are lining up.", "good")


# --------------------------------------------------------------------- save

func to_dict() -> Dictionary:
	return {
		"reputation": reputation,
		"price": price_per_puri,
		"upgrades": purchased.keys(),
		"level": level,
		"xp": xp,
		"lifetime_xp": lifetime_xp,
		"recipe_stats": recipe_stats.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	reputation = float(data.get("reputation", 20.0))
	price_per_puri = int(data.get("price", 30))
	level = clampi(int(data.get("level", 1)), 1, MAX_LEVEL)
	xp = maxi(0, int(data.get("xp", 0)))
	lifetime_xp = maxi(xp, int(data.get("lifetime_xp", xp)))
	purchased.clear()
	for id in data.get("upgrades", []):
		purchased[String(id)] = true
	recipe_stats.clear()
	var stored: Variant = data.get("recipe_stats", {})
	if typeof(stored) == TYPE_DICTIONARY:
		for key in (stored as Dictionary).keys():
			recipe_stats[String(key)] = (stored as Dictionary)[key]
	Events.reputation_changed.emit(reputation)
	Events.price_changed.emit(price_per_puri)
	_emit_xp()
