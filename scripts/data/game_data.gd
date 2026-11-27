class_name GameData
extends RefCounted
## Single source of truth for tunable content: ingredients, recipes, upgrades
## and the art palette. Everything is data, nothing here has behaviour.

const SPICE_NAMES := ["Mild", "Medium", "Hot"]
const SPICE_COLORS := [Color("7fbf6a"), Color("e8a13c"), Color("d9532f")]

# --- world palette (warm, dusty Indian street) -------------------------------
const C_ROAD := Color("4a4440")
const C_ROAD_LINE := Color("d9cdb2")
const C_PAVEMENT := Color("8a7d68")
const C_CURB := Color("c2b49a")
const C_WALL_A := Color("d8a86a")
const C_WALL_B := Color("c47f63")
const C_WALL_C := Color("a9b6a0")
const C_WALL_D := Color("d9c7a1")
const C_TEAL := Color("2f8f86")
const C_ORANGE := Color("e8762c")
const C_RED := Color("b8433a")
const C_WOOD := Color("6b4a2f")
const C_STEEL := Color("9aa0a5")
const C_SKIN := [Color("8d5524"), Color("b07a4a"), Color("c68642"), Color("6b4423"), Color("a1663a")]
const C_CLOTH := [
	Color("c94f4f"), Color("3d7fb8"), Color("d9a441"), Color("5c9e63"),
	Color("8e5aa8"), Color("d97a9c"), Color("3f8f8a"), Color("e07a3c"),
]
const C_PURI := Color("e5c07a")
const C_POTATO := Color("e0b04c")
const C_CHICKPEA := Color("c79a55")
const C_ONION := Color("d78ba6")
const C_CORIANDER := Color("5f9440")
const C_MASALA := Color("a8512b")
const C_PANI := Color("6f8f3a")
const C_CHUTNEY := Color("6b3b1f")
const C_TILE_A := Color("e7d6b8")
const C_TILE_B := Color("b96a48")
const C_GOLD := Color("d8a84e")
const C_CARPET := Color("8e2f2f")

static var _ingredients: Array[IngredientDef] = []
static var _recipes: Array[RecipeDef] = []
static var _upgrades: Array[Dictionary] = []


static func ingredients() -> Array[IngredientDef]:
	if _ingredients.is_empty():
		_ingredients = [
			IngredientDef.make("puri", "Puri shells", C_PURI, 180, 60, 90, 48, true),
			IngredientDef.make("raw_potato", "Raw potatoes", C_POTATO, 120, 40, 70, 30),
			IngredientDef.make("potato", "Potato filling", C_POTATO, 80, 30, 60, 24, true),
			IngredientDef.make("chickpea", "Chickpeas", C_CHICKPEA, 60, 24, 55, 18),
			IngredientDef.make("onion", "Chopped onion", C_ONION, 50, 20, 40, 14),
			IngredientDef.make("coriander", "Coriander", C_CORIANDER, 40, 16, 25, 10),
			IngredientDef.make("masala", "Masala", C_MASALA, 50, 20, 35, 14),
			IngredientDef.make("pani_mint", "Mint pani", C_PANI, 60, 24, 45, 20),
			IngredientDef.make("chutney_sweet", "Sweet chutney", C_CHUTNEY, 40, 16, 40, 12),
		]
	return _ingredients


static func ingredient(id: String) -> IngredientDef:
	for def in ingredients():
		if def.id == id:
			return def
	return null


static func recipes() -> Array[RecipeDef]:
	if _recipes.is_empty():
		_recipes = [
			RecipeDef.make("classic", "Classic Pani Puri", 30, ["potato"], "mint", 1, false, false, true, 0.0, 3.0),
			RecipeDef.make("onion", "Onion Special", 34, ["potato"], "mint", 1, false, true, true, 12.0, 2.0),
			RecipeDef.make("sweet", "Sweet & Tangy", 36, ["potato"], "mint", 0, true, false, false, 22.0, 1.5),
			RecipeDef.make("fire", "Fire Golgappa", 42, ["potato"], "mint", 2, false, true, true, 35.0, 1.2),
			RecipeDef.make("dahi", "Dahi Puri", 40, ["potato"], "mint", 0, true, false, true, 8.0, 1.5, 2),
			RecipeDef.make("masala_blast", "Masala Blast", 50, ["potato"], "mint", 2, false, true, true, 30.0, 1.1, 4),
			RecipeDef.make("royal", "Royal Pani Puri", 62, ["potato"], "mint", 1, true, true, true, 50.0, 0.8, 6),
			RecipeDef.make("signature", "Signature Platter", 74, ["potato"], "mint", 1, true, true, true, 70.0, 0.6, 8),
			RecipeDef.make("chaat_bomb", "Chaat Bomb", 88, ["potato", "chickpea"], "mint", 2, true, true, true, 45.0, 0.7, 10),
			RecipeDef.make("tandoori", "Tandoori Pani Puri", 105, ["potato", "chickpea"], "mint", 2, true, true, true, 60.0, 0.6, 12),
		]
	return _recipes


static func recipe(id: String) -> RecipeDef:
	for def in recipes():
		if def.id == id:
			return def
	return recipes()[0]


static func upgrades() -> Array[Dictionary]:
	if _upgrades.is_empty():
		_upgrades = [
			{
				"id": "bigger_plate", "name": "Bigger Serving Plate",
				"description": "Hold 9 puris instead of 6 on the serving plate.",
				"cost": 650, "icon": "plate",
			},
			{
				"id": "signboard", "name": "Painted Signboard",
				"description": "A bright sign pulls in more customers and boosts patience.",
				"cost": 900, "icon": "sign",
			},
			{
				"id": "queue_bench", "name": "Waiting Bench",
				"description": "One extra queue spot. Customers wait longer before leaving.",
				"cost": 1100, "icon": "bench",
			},
			{
				"id": "bulk_supplier", "name": "Bulk Supplier Deal",
				"description": "Refills cost 15% less for the rest of the game.",
				"cost": 1400, "icon": "box",
			},
			{
				"id": "garlic_pani", "name": "Garlic Pani Pot",
				"description": "Unlocks a second pani flavour worth a higher price.",
				"cost": 1800, "icon": "pot",
			},
			{
				"id": "street_permit", "name": "Street Expansion Permit",
				"description": "Opens the market stretch and lets the queue grow to six.",
				"cost": 3200, "icon": "gate",
			},
			{
				"id": "potato_machine", "name": "Automatic Potato Prep Machine",
				"description": "Peels and mashes raw potatoes into filling automatically. Consumes raw potatoes.",
				"cost": 18000, "icon": "pot", "level": 5,
			},
			{
				"id": "turbo_peeler", "name": "Turbo Peeler Drum",
				"description": "The prep machine produces potato filling twice as fast.",
				"cost": 32000, "icon": "pot", "level": 7,
				"requires": "potato_machine",
			},
			{
				"id": "auto_fill_arm", "name": "Auto-Fill Arm",
				"description": "Walks near the machine with an open puri and potato is added for you.",
				"cost": 55000, "icon": "box", "level": 9,
				"requires": "turbo_peeler",
			},
			{
				"id": "restaurant_reno", "name": "Restaurant Renovation",
				"description": "Tiled terrace, tables, planters and a proper restaurant front. Opens an extra queue spot.",
				"cost": 4500, "icon": "restaurant", "level": 3, "tier": "restaurant",
			},
			{
				"id": "fine_dining", "name": "Fine Dining Terrace",
				"description": "Balcony dining deck, chandeliers, table service and a finer menu. Another queue spot.",
				"cost": 12000, "icon": "chandelier", "level": 5, "tier": "restaurant",
				"requires": "restaurant_reno",
			},
			{
				"id": "pani_puri_palace", "name": "Pani Puri Palace",
				"description": "A landmark restaurant: grand marquee, gold trim, red carpet, fountain and the royal menu.",
				"cost": 30000, "icon": "palace", "level": 7, "tier": "restaurant",
				"requires": "fine_dining",
			},
			{
				"id": "franchise_hq", "name": "Franchise Headquarters",
				"description": "Corporate office, delivery fleet and celebrity chef. +2 queue spots and VIP customers.",
				"cost": 75000, "icon": "office", "level": 8, "tier": "restaurant",
				"requires": "pani_puri_palace",
			},
			{
				"id": "world_tour", "name": "World Tour Expansion",
				"description": "Take Pani Puri global: food trucks in London, Tokyo and New York. +3 queue spots.",
				"cost": 150000, "icon": "globe", "level": 10, "tier": "restaurant",
				"requires": "franchise_hq",
			},
		]
	return _upgrades


static func upgrade(id: String) -> Dictionary:
	for u in upgrades():
		if u.id == id:
			return u
	return {}


static func weather_for_day(day: int) -> String:
	var cycle := (day - 1) % 6
	if cycle == 2:
		return "rain"
	if cycle == 3:
		return "heat"
	return "clear"


static func festival_for_day(day: int) -> String:
	var cycle := (day - 1) % 10
	if cycle == 4:
		return "Diwali"
	if cycle == 9:
		return "Holi"
	return ""


static func theme_label(day: int) -> String:
	var weather := weather_for_day(day)
	var festival := festival_for_day(day)
	var parts: Array[String] = []
	match weather:
		"rain":
			parts.append("MONSOON SHOWERS")
		"heat":
			parts.append("HEAT WAVE")
	if festival != "":
		parts.append(festival.to_upper() + " FESTIVAL")
	if parts.is_empty():
		return "CLEAR DAY"
	return "  /  ".join(parts)
