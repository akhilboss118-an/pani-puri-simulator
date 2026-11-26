class_name RecipeDef
extends Resource
## A menu item. Orders are generated from these templates so that recipe
## balance can be tuned without touching customer code.

@export var id: String = ""
@export var display_name: String = ""
@export var base_price: int = 30
@export var required_filling: Array[String] = ["potato"]
@export var default_pani: String = "mint"
@export var default_spice: int = 1
@export var default_sweet: bool = false
@export var default_onion: bool = false
@export var default_chickpea: bool = true
@export var unlock_reputation: float = 0.0
@export var unlock_level: int = 1
@export var weight: float = 1.0


static func make(
	p_id: String,
	p_name: String,
	p_price: int,
	p_filling: Array[String],
	p_pani: String,
	p_spice: int,
	p_sweet: bool,
	p_onion: bool,
	p_chickpea: bool,
	p_unlock: float,
	p_weight: float = 1.0,
	p_unlock_level: int = 1
) -> RecipeDef:
	var r := RecipeDef.new()
	r.id = p_id
	r.display_name = p_name
	r.base_price = p_price
	r.required_filling = p_filling
	r.default_pani = p_pani
	r.default_spice = p_spice
	r.default_sweet = p_sweet
	r.default_onion = p_onion
	r.default_chickpea = p_chickpea
	r.unlock_reputation = p_unlock
	r.weight = p_weight
	r.unlock_level = p_unlock_level
	return r
