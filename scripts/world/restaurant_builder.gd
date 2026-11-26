class_name RestaurantBuilder
extends RefCounted
## Builds the restaurant that the cart grows into. Three cumulative tiers:
##   1. Restaurant Renovation - tiled terrace, tables, pergola, entrance arch
##   2. Fine Dining Terrace  - balcony deck, chandeliers, tablecloths
##   3. Pani Puri Palace     - grand marquee, red carpet, topiary, fountain
## Everything is primitives with shared materials so the web build stays small.

const DECK_Z := 10.9
const DECK_WIDTH := 15.0
const DECK_DEPTH := 3.0
const DECK_Y := 0.132


static func build(parent: Node3D, quality: int) -> Dictionary:
	var root := Node3D.new()
	root.name = "Restaurant"
	parent.add_child(root)

	var tier1 := Node3D.new()
	tier1.name = "Tier1Renovation"
	root.add_child(tier1)
	var tier2 := Node3D.new()
	tier2.name = "Tier2FineDining"
	root.add_child(tier2)
	var tier3 := Node3D.new()
	tier3.name = "Tier3Palace"
	root.add_child(tier3)

	_tier1(tier1, quality)
	_tier2(tier2, quality)
	_tier3(tier3, quality)

	tier1.visible = false
	tier2.visible = false
	tier3.visible = false
	var fountain_body: StaticBody3D = tier3.get_meta("fountain_body", null)
	return {
		"root": root,
		"tier1": tier1,
		"tier2": tier2,
		"tier3": tier3,
		"fountain_body": fountain_body,
	}


static func sync(built: Dictionary, tier: int) -> void:
	if built.is_empty():
		return
	var t1: Node3D = built.get("tier1")
	var t2: Node3D = built.get("tier2")
	var t3: Node3D = built.get("tier3")
	if t1:
		t1.visible = tier >= 1
	if t2:
		t2.visible = tier >= 2
	if t3:
		t3.visible = tier >= 3
	var fountain: StaticBody3D = built.get("fountain_body")
	if fountain:
		fountain.collision_layer = 1 if tier >= 3 else 0


# ------------------------------------------------------------------ tier 1

static func _tier1(root: Node3D, quality: int) -> void:
	_checker_floor(root)
	_deck_trim(root)

	# four tables with two chairs each, leaving the centre aisle clear
	var tables := [-5.3, -3.2, 3.2, 5.3]
	for tx in tables:
		_table(root, Vector3(tx, DECK_Y, 11.6), quality >= 1)

	# planters at the terrace corners
	for px in [-7.0, 7.0]:
		for pz in [10.05, 12.0]:
			_planter(root, Vector3(px, DECK_Y, pz))

	# back railing
	_railing(root, 12.42, -7.5, 7.5, DECK_Y, GameData.C_GOLD, quality >= 1)

	# pergola
	for px in [-7.2, 7.2]:
		for pz in [9.9, 12.0]:
			MeshFactory.box(root, Vector3(0.18, 2.85, 0.18), Vector3(px, DECK_Y + 1.42, pz), GameData.C_WOOD, "PergolaPost")
	for pz in [9.9, 12.0]:
		MeshFactory.box(root, Vector3(15.0, 0.14, 0.18), Vector3(0, 2.92, pz), GameData.C_WOOD.darkened(0.08), "PergolaBeam")
	for px in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		MeshFactory.box(root, Vector3(0.1, 0.08, 3.0), Vector3(px, 3.0, DECK_Z), GameData.C_WOOD.lightened(0.05), "PergolaSlat", 0.0, false)

	# string lights under the pergola
	if quality >= 1:
		for pz in [10.15, 11.9]:
			MeshFactory.box(root, Vector3(13.8, 0.018, 0.018), Vector3(0, 2.78, pz), Color("2b2622"), "LightWire", 0.0, false)
			for i in 7:
				var bx := -6.3 + i * 2.1
				var bulb := MeshFactory.sphere(root, 0.05, Vector3(bx, 2.7, pz), Color("ffd27a"), "Bulb", 6, false)
				bulb.material_override = _glow(Color("ffd27a"), Color("ffb347"), 1.4)

	_entrance_arch(root)
	_host_stand(root)
	_menu_stand(root)

	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 3.1, 9.6)
	lamp.light_color = Color("ffc27a")
	lamp.light_energy = 0.45
	lamp.omni_range = 5.5
	lamp.shadow_enabled = false
	root.add_child(lamp)


static func _checker_floor(parent: Node3D) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(DECK_WIDTH, DECK_DEPTH)
	var mi := MeshInstance3D.new()
	mi.name = "TiledTerrace"
	mi.mesh = quad
	mi.position = Vector3(0, DECK_Y, DECK_Z)
	mi.rotation.x = -PI / 2.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 tile_a : source_color = vec4(0.91, 0.84, 0.72, 1.0);
uniform vec4 tile_b : source_color = vec4(0.73, 0.42, 0.28, 1.0);
uniform vec2 tiles = vec2(20.0, 4.0);
void fragment() {
	vec2 cell = floor(UV * tiles);
	float checker = mod(cell.x + cell.y, 2.0);
	ALBEDO = mix(tile_a.rgb, tile_b.rgb, checker);
	ROUGHNESS = 0.86;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mi.material_override = mat
	parent.add_child(mi)


static func _deck_trim(parent: Node3D) -> void:
	var trim := GameData.C_TEAL.darkened(0.1)
	MeshFactory.box(parent, Vector3(DECK_WIDTH + 0.2, 0.07, 0.12), Vector3(0, DECK_Y + 0.01, 9.4), trim, "DeckTrim", 0.0, false)
	MeshFactory.box(parent, Vector3(DECK_WIDTH + 0.2, 0.07, 0.12), Vector3(0, DECK_Y + 0.01, 12.4), trim, "DeckTrim", 0.0, false)
	MeshFactory.box(parent, Vector3(0.12, 0.07, DECK_DEPTH), Vector3(-7.55, DECK_Y + 0.01, DECK_Z), trim, "DeckTrim", 0.0, false)
	MeshFactory.box(parent, Vector3(0.12, 0.07, DECK_DEPTH), Vector3(7.55, DECK_Y + 0.01, DECK_Z), trim, "DeckTrim", 0.0, false)


static func _table(parent: Node3D, pos: Vector3, with_chairs: bool) -> void:
	MeshFactory.cylinder(parent, 0.09, 0.72, pos + Vector3(0, 0.36, 0), GameData.C_WOOD, "TableLeg", 8, false)
	MeshFactory.cylinder(parent, 0.28, 0.05, pos + Vector3(0, 0.03, 0), GameData.C_WOOD.darkened(0.2), "TableFoot", 10, false)
	MeshFactory.cylinder(parent, 0.52, 0.07, pos + Vector3(0, 0.74, 0), Color("f2e2c4"), "TableTop", 16)
	MeshFactory.box(parent, Vector3(0.7, 0.012, 0.22), pos + Vector3(0, 0.78, 0), GameData.C_TEAL, "TableRunner", 0.0, false)
	if not with_chairs:
		return
	for dz in [-0.82, 0.82]:
		var facing := 0.0 if dz < 0.0 else PI
		_chair(parent, pos + Vector3(0, 0, dz), facing)


static func _chair(parent: Node3D, pos: Vector3, facing: float) -> void:
	var chair := Node3D.new()
	chair.position = pos
	chair.rotation.y = facing
	parent.add_child(chair)
	MeshFactory.box(chair, Vector3(0.44, 0.06, 0.44), Vector3(0, 0.45, 0), GameData.C_WOOD, "Seat", 0.0, false)
	MeshFactory.box(chair, Vector3(0.44, 0.52, 0.06), Vector3(0, 0.72, -0.2), GameData.C_WOOD.darkened(0.08), "Back", 0.0, false)
	for sx in [-0.18, 0.18]:
		MeshFactory.box(chair, Vector3(0.05, 0.44, 0.4), Vector3(sx, 0.22, 0), Color("3a2d22"), "Leg", 0.0, false)


static func _planter(parent: Node3D, pos: Vector3) -> void:
	MeshFactory.cylinder(parent, 0.27, 0.4, pos + Vector3(0, 0.2, 0), Color("a85a3a"), "Pot", 10, false)
	MeshFactory.cylinder(parent, 0.31, 0.06, pos + Vector3(0, 0.41, 0), Color("c26b47"), "PotRim", 10, false)
	MeshFactory.cylinder(parent, 0.045, 0.55, pos + Vector3(0, 0.68, 0), GameData.C_WOOD, "Stem", 6, false)
	var leaves := MeshFactory.sphere(parent, 0.36, pos + Vector3(0, 1.05, 0), Color("4f7a3a"), "Leaves", 8, false)
	leaves.scale = Vector3(1.0, 1.25, 1.0)


static func _railing(parent: Node3D, z: float, x0: float, x1: float, y: float, color: Color, with_posts: bool) -> void:
	var length := x1 - x0
	var mid := (x0 + x1) * 0.5
	MeshFactory.box(parent, Vector3(length, 0.07, 0.07), Vector3(mid, y + 1.02, z), color, "TopRail", 0.0, false)
	MeshFactory.box(parent, Vector3(length, 0.05, 0.05), Vector3(mid, y + 0.68, z), color.darkened(0.12), "MidRail", 0.0, false)
	if not with_posts:
		return
	var posts := 6
	for i in posts:
		var px := lerpf(x0, x1, float(i) / float(posts - 1))
		MeshFactory.box(parent, Vector3(0.08, 1.05, 0.08), Vector3(px, y + 0.53, z), color, "RailPost", 0.0, false)


static func _entrance_arch(parent: Node3D) -> void:
	for px in [-3.25, 3.25]:
		MeshFactory.box(parent, Vector3(0.5, 0.35, 0.5), Vector3(px, 0.18, 9.45), GameData.C_TEAL.darkened(0.18), "ArchBase")
		MeshFactory.box(parent, Vector3(0.28, 3.8, 0.28), Vector3(px, 2.1, 9.45), GameData.C_TEAL, "ArchColumn")
		MeshFactory.box(parent, Vector3(0.34, 0.1, 0.34), Vector3(px, 1.25, 9.45), GameData.C_GOLD, "ArchBand", 0.0, false)
		MeshFactory.box(parent, Vector3(0.34, 0.1, 0.34), Vector3(px, 2.95, 9.45), GameData.C_GOLD, "ArchBand", 0.0, false)
		MeshFactory.sphere(parent, 0.12, Vector3(px, 4.12, 9.45), GameData.C_GOLD, "Finial", 8, false)
	MeshFactory.box(parent, Vector3(7.0, 0.42, 0.36), Vector3(0, 4.02, 9.45), GameData.C_TEAL.darkened(0.12), "ArchBeam")
	MeshFactory.box(parent, Vector3(7.1, 0.07, 0.42), Vector3(0, 4.26, 9.45), GameData.C_GOLD, "ArchGold", 0.0, false)
	MeshFactory.signboard(parent, "PANI PURI HOUSE", Vector3(0, 3.55, 9.24), 5.2, GameData.C_ORANGE, Color("fff4dc"), 0.7, PI)


static func _host_stand(parent: Node3D) -> void:
	MeshFactory.box(parent, Vector3(0.55, 0.92, 0.45), Vector3(-2.9, 0.58, 9.85), GameData.C_WOOD, "HostStand")
	MeshFactory.box(parent, Vector3(0.66, 0.06, 0.56), Vector3(-2.9, 1.06, 9.85), GameData.C_TEAL, "HostTop", 0.0, false)
	MeshFactory.signboard(parent, "HOST", Vector3(-2.9, 0.86, 9.6), 0.5, GameData.C_GOLD, Color("2a1a10"), 0.2, PI)


static func _menu_stand(parent: Node3D) -> void:
	for px in [2.72, 3.08]:
		MeshFactory.box(parent, Vector3(0.05, 1.35, 0.05), Vector3(px, 0.79, 9.85), GameData.C_WOOD, "MenuPost", 0.0, false)
	MeshFactory.signboard(parent, "MENU", Vector3(2.9, 1.25, 9.83), 0.95, Color("211812"), Color("f7e6c4"), 0.62, PI)


# ------------------------------------------------------------------ tier 2

static func _tier2(root: Node3D, quality: int) -> void:
	# balcony deck sits on the pergola and becomes the terrace ceiling
	var deck := MeshFactory.box(root, Vector3(15.0, 0.16, 1.95), Vector3(0, 3.2, 11.35), GameData.C_WOOD.darkened(0.05), "BalconyDeck", 0.0, false)
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	MeshFactory.box(root, Vector3(15.1, 0.34, 0.09), Vector3(0, 3.1, 10.37), GameData.C_TEAL, "BalconyFascia", 0.0, false)
	MeshFactory.box(root, Vector3(15.1, 0.06, 0.12), Vector3(0, 3.28, 10.36), GameData.C_GOLD, "BalconyGold", 0.0, false)
	for px in [-7.2, 7.2]:
		for pz in [10.55, 12.2]:
			MeshFactory.box(root, Vector3(0.2, 3.2, 0.2), Vector3(px, 1.6, pz), GameData.C_TEAL.darkened(0.15), "BalconyColumn")

	_railing(root, 12.42, -7.5, 7.5, 3.2, GameData.C_GOLD, quality >= 1)
	# small gold caps on the ground railing
	for px in [-7.5, -4.5, -1.5, 1.5, 4.5, 7.5]:
		MeshFactory.sphere(root, 0.07, Vector3(px, 4.3, 12.42), GameData.C_GOLD, "RailCap", 6, false)

	# balcony bistro tables
	for tx in [-4.6, 0.0, 4.6]:
		_table(root, Vector3(tx, 3.28, 11.5), quality >= 1)
	# tablecloths + candles on the ground tables
	for tx in [-5.3, -3.2, 3.2, 5.3]:
		MeshFactory.cylinder(root, 0.55, 0.035, Vector3(tx, 0.79, 11.6), Color("f6ead2"), "Tablecloth", 16, false)
		MeshFactory.cylinder(root, 0.035, 0.16, Vector3(tx, 0.86, 11.6), GameData.C_GOLD, "Candle", 6, false)
		var flame := MeshFactory.sphere(root, 0.035, Vector3(tx, 0.96, 11.6), Color("ffd27a"), "Flame", 6, false)
		flame.material_override = _glow(Color("ffd27a"), Color("ff9d3c"), 1.8)

	# chandeliers over the ground terrace
	var chandeliers := [-3.6, 3.6] if quality >= 1 else [0.0]
	for cx in chandeliers:
		MeshFactory.cylinder(root, 0.012, 0.55, Vector3(cx, 2.83, 10.9), Color("2b2622"), "ChandelierCord", 6, false)
		MeshFactory.cylinder(root, 0.26, 0.06, Vector3(cx, 2.52, 10.9), GameData.C_GOLD, "ChandelierRing", 12, false)
		MeshFactory.sphere(root, 0.08, Vector3(cx, 2.52, 10.9), GameData.C_GOLD, "ChandelierHub", 8, false)
		for i in 6:
			var angle := TAU * float(i) / 6.0
			var bulb := MeshFactory.sphere(root, 0.055, Vector3(cx + cos(angle) * 0.26, 2.47, 10.9 + sin(angle) * 0.26), Color("ffe6b0"), "ChandelierBulb", 6, false)
			bulb.material_override = _glow(Color("ffe6b0"), Color("ffb347"), 1.6)
		var light := OmniLight3D.new()
		light.position = Vector3(cx, 2.45, 10.9)
		light.light_color = Color("ffd9a0")
		light.light_energy = 0.4
		light.omni_range = 4.5
		light.shadow_enabled = false
		root.add_child(light)

	MeshFactory.signboard(root, "FINE DINING", Vector3(0, 3.1, 10.31), 3.0, Color("211812"), Color("f2d79b"), 0.32, PI)


# ------------------------------------------------------------------ tier 3

static func _tier3(root: Node3D, quality: int) -> void:
	# grand marquee framing the whole stall
	for px in [-4.35, 4.35]:
		MeshFactory.box(root, Vector3(0.42, 4.7, 0.42), Vector3(px, 2.47, 9.45), GameData.C_GOLD.darkened(0.12), "MarqueeColumn")
		MeshFactory.box(root, Vector3(0.58, 0.3, 0.58), Vector3(px, 0.27, 9.45), Color("3a2b1c"), "MarqueeBase")
		MeshFactory.sphere(root, 0.16, Vector3(px, 4.95, 9.45), GameData.C_GOLD, "MarqueeFinial", 8, false)
	MeshFactory.box(root, Vector3(9.1, 0.46, 0.5), Vector3(0, 4.72, 9.45), Color("5c1f1f"), "MarqueeBeam")
	MeshFactory.box(root, Vector3(9.2, 0.08, 0.56), Vector3(0, 4.98, 9.45), GameData.C_GOLD, "MarqueeGold", 0.0, false)
	MeshFactory.signboard(root, "PANI PURI PALACE", Vector3(0, 4.16, 9.06), 7.4, Color("5c1f1f"), Color("f6d58c"), 0.78, PI)

	# scalloped valance under the marquee
	for i in 6:
		var vx := -3.6 + i * 1.44
		var valance := MeshFactory.box(root, Vector3(1.4, 0.26, 0.06), Vector3(vx, 4.48, 9.2), GameData.C_CARPET, "Valance", 0.0, false)
		valance.rotation.z = 0.06 if i % 2 == 0 else -0.06

	# red carpet from the arch to the fountain
	MeshFactory.box(root, Vector3(1.5, 0.014, 2.65), Vector3(0, DECK_Y + 0.012, 10.85), GameData.C_CARPET, "Carpet", 0.0, false)
	for sx in [-0.78, 0.78]:
		MeshFactory.box(root, Vector3(0.05, 0.014, 2.65), Vector3(sx, DECK_Y + 0.013, 10.85), GameData.C_GOLD, "CarpetTrim", 0.0, false)

	# topiary either side of the entrance
	for px in [-2.55, 2.55]:
		MeshFactory.cylinder(root, 0.24, 0.38, Vector3(px, 0.31, 9.9), Color("2f2a26"), "TopiaryPot", 10, false)
		MeshFactory.cylinder(root, 0.05, 0.45, Vector3(px, 0.72, 9.9), GameData.C_WOOD, "TopiaryStem", 6, false)
		var ball := MeshFactory.sphere(root, 0.3, Vector3(px, 1.05, 9.9), Color("3f6b33"), "TopiaryBall", 10, false)
		ball.scale = Vector3(1.0, 1.15, 1.0)

	# plaza fountain beside the terrace, clear of the serving aisle
	MeshFactory.cylinder(root, 1.25, 0.05, Vector3(-10.2, 0.145, 10.4), Color("b9a88e"), "FountainApron", 18, false)
	MeshFactory.cylinder(root, 0.95, 0.28, Vector3(-10.2, 0.27, 10.4), Color("b9a88e"), "FountainBase", 18, false)
	MeshFactory.cylinder(root, 0.8, 0.04, Vector3(-10.2, 0.43, 10.4), Color("4f8f86"), "FountainWater", 18, false)
	MeshFactory.cylinder(root, 0.12, 0.75, Vector3(-10.2, 0.78, 10.4), Color("b9a88e"), "FountainColumn", 10, false)
	MeshFactory.cylinder(root, 0.34, 0.08, Vector3(-10.2, 1.16, 10.4), Color("c9b89e"), "FountainBowl", 12, false)
	MeshFactory.sphere(root, 0.09, Vector3(-10.2, 1.27, 10.4), GameData.C_GOLD, "FountainFinial", 8, false)
	for px in [-11.9, -8.5]:
		_planter(root, Vector3(px, 0.12, 10.4))
	var body := MeshFactory.add_box_collider(root, Vector3(2.4, 1.1, 2.4), Vector3(-10.2, 0.55, 10.4), 1)
	root.set_meta("fountain_body", body)

	# brass lanterns on the railing
	for px in [-5.6, -2.6, 2.6, 5.6]:
		MeshFactory.box(root, Vector3(0.05, 0.35, 0.05), Vector3(px, 1.36, 12.42), Color("2b2622"), "LanternPost", 0.0, false)
		var lamp := MeshFactory.box(root, Vector3(0.18, 0.24, 0.18), Vector3(px, 1.6, 12.42), Color("ffd27a"), "Lantern", 0.0, false)
		lamp.material_override = _glow(Color("ffd27a"), Color("ffb347"), 1.3)

	if quality >= 1:
		for lx in [-3.0, 3.0]:
			var light := OmniLight3D.new()
			light.position = Vector3(lx, 2.6, 11.2)
			light.light_color = Color("ffcf8f")
			light.light_energy = 0.5
			light.omni_range = 6.0
			light.shadow_enabled = false
			root.add_child(light)


# ------------------------------------------------------------------ helpers

static func _glow(base: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var mat := MeshFactory.material(base, 0.5, 0.0, true)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	return mat
