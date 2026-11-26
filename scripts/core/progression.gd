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


func reset() -> void:
	reputation = 20.0
	price_per_puri = 30
	level = 1
	xp = 0
	lifetime_xp = 0
	purchased.clear()
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
	if level >= MAX_LEVEL:
		xp = 0
	_emit_xp()
	return gained


func level_title() -> String:
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
			return "New recipe: Signature Platter."
		9:
			return "Rare customers start asking by name."
		10:
			return "Pani Puri Palace runner-up. Your street runs the block."
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
	return price_per_puri + premium


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


## 0 = street cart, 1 = restaurant, 2 = fine dining, 3 = palace.
func restaurant_tier() -> int:
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
	size += mini(restaurant_tier(), 2)
	return mini(size, 8)


func max_customers() -> int:
	var cap := 4
	if has_upgrade("queue_bench"):
		cap += 1
	if has_upgrade("street_permit"):
		cap += 2
	cap += restaurant_tier()
	if Game.settings.quality == 0:
		cap = mini(cap, 5)
	return mini(cap, 10)


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
	base *= [1.0, 0.94, 0.88, 0.82][restaurant_tier()]
	return maxf(2.2, base)


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
	return "Pani Puri Palace complete - the whole street is yours."


# --------------------------------------------------------------------- save

func to_dict() -> Dictionary:
	return {
		"reputation": reputation,
		"price": price_per_puri,
		"upgrades": purchased.keys(),
		"level": level,
		"xp": xp,
		"lifetime_xp": lifetime_xp,
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
	Events.reputation_changed.emit(reputation)
	Events.price_changed.emit(price_per_puri)
	_emit_xp()
