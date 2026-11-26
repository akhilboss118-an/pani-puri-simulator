class_name IngredientDef
extends Resource
## Data definition for one ingredient or supply. Tuning lives here, never in
## gameplay scripts.

@export var id: String = ""
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export var capacity: int = 40
@export var refill_amount: int = 20
@export var refill_cost: int = 40
@export var start_stock: int = 20
@export var per_puri: int = 1
@export var is_base: bool = false


static func make(
	p_id: String,
	p_name: String,
	p_color: Color,
	p_capacity: int,
	p_refill: int,
	p_cost: int,
	p_start: int,
	p_base: bool = false
) -> IngredientDef:
	var d := IngredientDef.new()
	d.id = p_id
	d.display_name = p_name
	d.color = p_color
	d.capacity = p_capacity
	d.refill_amount = p_refill
	d.refill_cost = p_cost
	d.start_stock = p_start
	d.is_base = p_base
	return d
