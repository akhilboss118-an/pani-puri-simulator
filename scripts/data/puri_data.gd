class_name PuriData
extends Resource
## Logical state of one puri. Visuals are driven from this, never the other
## way around, so an order can be validated even if a mesh is hidden.

enum State { EMPTY, OPENED, FILLED, READY }

var state: State = State.EMPTY
var contents: Dictionary = {}     # ingredient_id -> count
var pani: String = "none"         # none / mint / garlic
var spice: int = 0                # 0 mild, 1 medium, 2 hot
var sweet: bool = false
var dropped: bool = false


func copy() -> PuriData:
	var d := PuriData.new()
	d.state = state
	d.contents = contents.duplicate()
	d.pani = pani
	d.spice = spice
	d.sweet = sweet
	d.dropped = dropped
	return d


func open() -> void:
	if state == State.EMPTY:
		state = State.OPENED


func add_ingredient(id: String, max_per_puri: int = 2) -> bool:
	var count := int(contents.get(id, 0))
	if count >= max_per_puri:
		return false
	contents[id] = count + 1
	if id == "masala":
		spice = clampi(count + 1, 0, 2)
	state = State.FILLED
	return true


func has_ingredient(id: String) -> bool:
	return int(contents.get(id, 0)) > 0


func filling_count() -> int:
	var total := 0
	for key in contents:
		total += int(contents[key])
	return total


func add_pani(flavour: String) -> void:
	pani = flavour
	state = State.READY


func add_chutney() -> void:
	sweet = true


func is_ready() -> bool:
	return state == State.READY and has_ingredient("potato") and pani != "none"


func is_empty() -> bool:
	return state == State.EMPTY


func describe() -> String:
	if state == State.EMPTY:
		return "Empty puri"
	var parts: Array[String] = []
	if has_ingredient("potato"):
		parts.append("potato")
	if has_ingredient("chickpea"):
		parts.append("chickpea")
	if has_ingredient("onion"):
		parts.append("onion")
	if has_ingredient("coriander"):
		parts.append("coriander")
	if has_ingredient("masala"):
		parts.append("masala")
	if pani == "mint":
		parts.append("mint pani")
	elif pani == "garlic":
		parts.append("garlic pani")
	if sweet:
		parts.append("sweet chutney")
	if parts.is_empty():
		return "Opened puri"
	return "Puri: " + ", ".join(parts)


## Returns 0..1 quality for one puri against a customer order dictionary.
func score_against(order: Dictionary) -> float:
	var score := 1.0
	if not is_ready():
		score -= 0.65
	if pani != String(order.get("pani", "mint")):
		score -= 0.35
	var wanted_spice := int(order.get("spice", 1))
	score -= absf(float(spice - wanted_spice)) * 0.14
	if sweet != bool(order.get("sweet", false)):
		score -= 0.2
	if has_ingredient("onion") != bool(order.get("onion", false)):
		score -= 0.15
	if has_ingredient("chickpea") != bool(order.get("chickpea", true)):
		score -= 0.15
	if not has_ingredient("potato"):
		score -= 0.4
	if dropped:
		score -= 0.3
	return clampf(score, 0.0, 1.0)


## What the player still has to do, used for the interaction prompt.
func next_step_hint() -> String:
	if state == State.EMPTY:
		return "Crack the puri open"
	if not has_ingredient("potato"):
		return "Add potato filling"
	if pani == "none":
		return "Dip it in pani"
	return "Ready to serve"
