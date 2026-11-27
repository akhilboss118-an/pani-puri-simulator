class_name WorldBuilder
extends Node3D
## Builds the whole street procedurally. Everything is primitives plus shared
## materials, so the scene stays tiny to download and cheap to draw on mobile.

var player: Player
var customer_manager
var plate: PlateStation
var stall: Dictionary = {}
var restaurant: Dictionary = {}

var queue_points: Array[Vector3] = []
var spawn_point := Vector3(15.0, 0.14, 7.4)
var exit_point := Vector3(17.0, 0.14, 7.4)
var player_spawn := Vector3(0, 0.2, 10.65)

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _world_environment: Environment
var _theme_root: Node3D
var _rain: GPUParticles3D
var _confetti: GPUParticles3D
var _festival_lights: Node3D
var _gate: Node3D
var _gate_body: StaticBody3D
var _menu_label: Label3D
var _quality: int = 1


func build(quality: int) -> void:
	_quality = quality
	_setup_environment()
	_ground()
	_shops()
	_street_props()
	_build_stall()
	restaurant = RestaurantBuilder.build(self, _quality)
	EnvironmentLoader.apply(self)
	_build_customers()
	_boundaries()
	_expansion_gate()
	_build_theme_visuals()
	Events.upgrade_purchased.connect(_on_upgrade)
	Events.price_changed.connect(_on_price_changed)
	sync_upgrades()
	apply_day_theme(Game.day)


func apply_quality(quality: int) -> void:
	_quality = quality
	if _sun:
		_sun.shadow_enabled = quality >= 1
		_sun.directional_shadow_max_distance = 40.0 if quality >= 2 else 28.0
		_sun.light_energy = 0.95 if quality >= 1 else 0.85


# ------------------------------------------------------------------ lighting

func _setup_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("4a7cb0")
	sky_mat.sky_horizon_color = Color("e2b487")
	sky_mat.ground_bottom_color = Color("4a3f32")
	sky_mat.ground_horizon_color = Color("d3a87c")
	sky_mat.sun_angle_max = 18.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.fog_enabled = true
	env.fog_light_color = Color("d9b58d")
	env.fog_density = 0.0035
	world_env.environment = env
	add_child(world_env)
	_world_env = world_env
	_world_environment = env

	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.rotation_degrees = Vector3(-48, 200, 0)
	_sun.light_color = Color("ffe6c4")
	_sun.light_energy = 1.0
	_sun.shadow_enabled = _quality >= 1
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 30.0
	_sun.shadow_bias = 0.04
	add_child(_sun)

	# two cheap warm lights under the canopy, no shadows
	for x in [-1.3, 1.3]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 2.4, 8.6)
		lamp.light_color = Color("ffbd73")
		lamp.light_energy = 0.35
		lamp.omni_range = 3.0
		lamp.shadow_enabled = false
		add_child(lamp)

	# a soft fill behind the street for evening reads
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color("ffcfb3")
	fill.light_energy = 0.12
	fill.shadow_enabled = false
	add_child(fill)
	fill.global_position = Vector3(0, 12, 24)


# -------------------------------------------------------------------- ground

func _ground() -> void:
	MeshFactory.add_box_collider(self, Vector3(90, 0.5, 60), Vector3(0, -0.13, 0), 1)
	MeshFactory.box(self, Vector3(70, 0.12, 11), Vector3(0, 0.06, 0), GameData.C_ROAD, "Road", 0.0, false)
	MeshFactory.box(self, Vector3(70, 0.12, 6), Vector3(0, 0.06, 8.5), GameData.C_PAVEMENT, "PavementNear", 0.0, false)
	MeshFactory.box(self, Vector3(70, 0.12, 6), Vector3(0, 0.06, -8.5), GameData.C_PAVEMENT.darkened(0.06), "PavementFar", 0.0, false)
	MeshFactory.box(self, Vector3(70, 0.14, 0.14), Vector3(0, 0.07, 5.53), GameData.C_CURB, "CurbNear", 0.0, false)
	MeshFactory.box(self, Vector3(70, 0.14, 0.14), Vector3(0, 0.07, -5.53), GameData.C_CURB, "CurbFar", 0.0, false)

	for i in 17:
		var x := -32.0 + i * 4.0
		MeshFactory.box(self, Vector3(1.7, 0.012, 0.12), Vector3(x, 0.128, 0), GameData.C_ROAD_LINE, "Dash", 0.0, false)
	for i in 8:
		MeshFactory.box(self, Vector3(0.16, 0.014, 5.2), Vector3(-14.0 + i * 4.0, 0.129, 0), GameData.C_ROAD_LINE, "Zebra", 0.0, false)

	# dust patches to break up the flat road
	for i in 7:
		var patch := MeshFactory.quad(self, Vector2(randf_range(1.5, 3.5), randf_range(0.8, 2.0)), Vector3(randf_range(-22, 22), 0.127, randf_range(-4.5, 4.5)), Color(0.16, 0.14, 0.12, 0.35))
		patch.rotation.x = -PI / 2.0
		patch.rotation.z = randf_range(0, TAU)


# --------------------------------------------------------------------- shops

func _shops() -> void:
	var far := [
		{"x": -24.0, "w": 7.0, "h": 7.0, "c": GameData.C_WALL_A, "a": GameData.C_TEAL, "n": "SHARMA STORES"},
		{"x": -16.0, "w": 7.5, "h": 8.5, "c": GameData.C_WALL_B, "a": GameData.C_ORANGE, "n": "CHAI POINT"},
		{"x": -7.5, "w": 8.0, "h": 6.5, "c": GameData.C_WALL_D, "a": GameData.C_RED, "n": "MEENA TAILORS"},
		{"x": 1.5, "w": 8.0, "h": 9.0, "c": GameData.C_WALL_C, "a": GameData.C_TEAL, "n": "GUPTA SWEETS"},
		{"x": 10.5, "w": 8.0, "h": 7.5, "c": GameData.C_WALL_A, "a": GameData.C_ORANGE, "n": "KIRANA MARKET"},
		{"x": 19.5, "w": 8.0, "h": 8.0, "c": GameData.C_WALL_B, "a": GameData.C_RED, "n": "PAAN HOUSE"},
	]
	for shop in far:
		_shop(float(shop.x), -11.5, 1.0, float(shop.w), float(shop.h), 6.0, shop.c, shop.a, String(shop.n))

	var near := [
		{"x": -22.0, "w": 9.0, "h": 8.0, "c": GameData.C_WALL_D, "a": GameData.C_RED, "n": "SALON"},
		{"x": -11.0, "w": 9.0, "h": 9.5, "c": GameData.C_WALL_C, "a": GameData.C_TEAL, "n": "MOBILE REPAIR"},
		{"x": 7.0, "w": 10.0, "h": 8.5, "c": GameData.C_WALL_A, "a": GameData.C_ORANGE, "n": "FRIENDS CAFE"},
		{"x": 18.0, "w": 9.0, "h": 7.0, "c": GameData.C_WALL_B, "a": GameData.C_RED, "n": "BOOK DEPOT"},
	]
	for shop in near:
		_shop(float(shop.x), 12.6, -1.0, float(shop.w), float(shop.h), 6.0, shop.c, shop.a, String(shop.n))

	# distant skyline so the street does not end in empty sky
	for i in 9:
		var h := randf_range(8.0, 16.0)
		MeshFactory.box(self, Vector3(randf_range(5, 9), h, 6), Vector3(-30.0 + i * 7.5, h * 0.5, -32.0), Color("b9a58c").darkened(randf_range(0.0, 0.25)), "Skyline", 0.0, false)


func _shop(x: float, z_front: float, normal: float, width: float, height: float, depth: float, wall: Color, awning: Color, shop_name: String) -> void:
	var shop := Node3D.new()
	shop.name = shop_name.replace(" ", "")
	add_child(shop)
	var center_z := z_front - normal * depth * 0.5
	MeshFactory.box(shop, Vector3(width, height, depth), Vector3(x, 0.12 + height * 0.5, center_z), wall, "Body")
	MeshFactory.box(shop, Vector3(width + 0.35, 0.28, depth + 0.2), Vector3(x, 0.12 + height + 0.14, center_z), wall.darkened(0.14), "Parapet", 0.0, false)
	var fz := z_front + normal * 0.07

	MeshFactory.box(shop, Vector3(1.4, 2.35, 0.1), Vector3(x - width * 0.24, 1.3, fz), Color("3a2f26"), "Door")
	MeshFactory.box(shop, Vector3(0.62, 2.0, 0.06), Vector3(x - width * 0.24, 1.2, fz + normal * 0.02), Color("5a4636"), "DoorPanel", 0.0, false)
	for i in 2:
		var wx := x + width * 0.08 + i * width * 0.26
		MeshFactory.box(shop, Vector3(width * 0.2, 1.15, 0.06), Vector3(wx, 1.75, fz), Color("2e3f47"), "Window", 0.0, false)
		MeshFactory.box(shop, Vector3(width * 0.2 + 0.06, 1.2, 0.03), Vector3(wx, 1.75, fz - normal * 0.01), Color("8a7a63"), "WindowFrame", 0.0, false)
	if height > 6.0:
		for i in 3:
			var ux := x - width * 0.3 + i * width * 0.3
			MeshFactory.box(shop, Vector3(width * 0.18, 1.0, 0.05), Vector3(ux, height - 1.2, fz), Color("2e3f47"), "UpperWindow", 0.0, false)

	var rot := 0.0 if normal > 0.0 else PI
	MeshFactory.signboard(shop, shop_name, Vector3(x, 2.95, fz + normal * 0.04), width * 0.72, awning, Color("2a1a10"), 0.62, rot)
	var aw := MeshFactory.box(shop, Vector3(width * 0.82, 0.06, 1.3), Vector3(x, 3.4, z_front + normal * 0.66), awning, "Awning", 0.0, false)
	aw.rotation.x = 0.13 * normal
	# support poles for the awning
	for sx in [-1.0, 1.0]:
		MeshFactory.cylinder(shop, 0.025, 3.3, Vector3(x + sx * width * 0.38, 1.77, z_front + normal * 1.2), Color("4a4038"), "AwningPole", 6, false)

	MeshFactory.add_box_collider(shop, Vector3(width, height, depth), Vector3(x, 0.12 + height * 0.5, center_z), 1)


# -------------------------------------------------------------- street props

func _street_props() -> void:
	# electric poles and sagging wires along the far pavement
	for x in [-18.0, -7.0, 4.0, 15.0]:
		MeshFactory.cylinder(self, 0.1, 7.2, Vector3(x, 3.7, -6.6), Color("5a5550"), "Pole", 8, false)
		MeshFactory.box(self, Vector3(1.5, 0.08, 0.08), Vector3(x, 6.6, -6.6), Color("4a4540"), "CrossArm", 0.0, false)
		MeshFactory.box(self, Vector3(1.2, 0.04, 0.04), Vector3(x, 6.2, -6.6), Color("3a3530"), "CrossArm2", 0.0, false)
	for i in 3:
		var x0: float = [-18.0, -7.0, 4.0][i]
		var x1: float = [-7.0, 4.0, 15.0][i]
		var mid := (x0 + x1) * 0.5
		var length := x1 - x0
		MeshFactory.box(self, Vector3(length, 0.022, 0.022), Vector3(mid, 6.58, -6.6), Color("2f2a26"), "Wire", 0.0, false)
		MeshFactory.box(self, Vector3(length, 0.018, 0.018), Vector3(mid, 6.18, -6.6), Color("2f2a26"), "Wire2", 0.0, false)

	# trees
	_tree(-20.0, -8.2, 1.0)
	_tree(-11.0, -8.6, 0.85)
	_tree(0.5, -8.4, 1.1)
	_tree(11.5, -8.2, 0.9)
	_tree(-14.0, 10.2, 0.8)
	_tree(12.0, 10.4, 0.85)

	# benches and bins
	_bench(-4.5, -7.9)
	_bench(8.0, -7.9)
	MeshFactory.cylinder(self, 0.22, 0.6, Vector3(4.5, 0.42, 6.4), Color("3f6b52"), "Bin", 10, false)
	MeshFactory.cylinder(self, 0.22, 0.6, Vector3(-13.0, 0.42, -6.4), Color("3f6b52"), "Bin2", 10, false)

	_scooter(-3.2, 6.4, GameData.C_RED)
	_scooter(6.8, 6.5, GameData.C_TEAL)
	_rickshaw(9.5, -3.6)

	# crates and sacks beside the stall
	MeshFactory.box(self, Vector3(0.5, 0.5, 0.5), Vector3(-3.5, 0.37, 9.9), Color("a97b4a"), "Crate", 0.2)
	MeshFactory.box(self, Vector3(0.45, 0.35, 0.4), Vector3(-3.4, 0.8, 9.85), Color("b98b5a"), "Crate2", 0.5)
	MeshFactory.sphere(self, 0.3, Vector3(3.4, 0.42, 9.7), Color("c9b48a"), "Sack", 8, false)


func _tree(x: float, z: float, scale: float) -> void:
	MeshFactory.cylinder(self, 0.13 * scale, 1.6 * scale, Vector3(x, 0.12 + 0.8 * scale, z), GameData.C_WOOD, "Trunk", 7, false)
	var greens := [Color("4f7a3a"), Color("5f8f42"), Color("446b33")]
	for i in 3:
		var offset := Vector3(cos(i * 2.1) * 0.45, 1.7 + i * 0.32, sin(i * 2.1) * 0.45) * scale
		var foliage := MeshFactory.sphere(self, (0.85 - i * 0.12) * scale, Vector3(x, 0.12, z) + offset, greens[i], "Leaves", 8, i == 0)
		foliage.scale = Vector3(1.0, 0.8, 1.0)


func _bench(x: float, z: float) -> void:
	MeshFactory.box(self, Vector3(1.6, 0.09, 0.45), Vector3(x, 0.58, z), GameData.C_WOOD, "Seat")
	MeshFactory.box(self, Vector3(1.6, 0.5, 0.08), Vector3(x, 0.85, z - 0.2), GameData.C_WOOD.darkened(0.1), "Back")
	for sx in [-0.65, 0.65]:
		MeshFactory.box(self, Vector3(0.08, 0.45, 0.4), Vector3(x + sx, 0.35, z), Color("4a4038"), "Leg", 0.0, false)


func _scooter(x: float, z: float, color: Color) -> void:
	var root := Node3D.new()
	root.position = Vector3(x, 0.12, z)
	root.rotation.y = PI * 0.5
	add_child(root)
	MeshFactory.box(root, Vector3(0.42, 0.32, 1.1), Vector3(0, 0.62, 0), color, "Body")
	MeshFactory.box(root, Vector3(0.36, 0.12, 0.55), Vector3(0, 0.82, 0.15), Color("2b2622"), "Seat", 0.0, false)
	for sz in [-0.55, 0.55]:
		var wheel := MeshFactory.cylinder(root, 0.22, 0.1, Vector3(0, 0.24, sz), Color("2b2622"), "Wheel", 10, false)
		wheel.rotation.z = PI / 2.0
	MeshFactory.cylinder(root, 0.03, 0.6, Vector3(0, 0.95, -0.5), Color("8a8f94"), "Handle", 6, false)
	MeshFactory.box(root, Vector3(0.5, 0.04, 0.04), Vector3(0, 1.24, -0.5), Color("2b2622"), "Bar", 0.0, false)
	MeshFactory.box(root, Vector3(0.22, 0.18, 0.06), Vector3(0, 1.1, -0.58), Color("f2e2c4"), "Plate", 0.0, false)


func _rickshaw(x: float, z: float) -> void:
	var root := Node3D.new()
	root.position = Vector3(x, 0.12, z)
	root.rotation.y = PI * 0.5
	add_child(root)
	MeshFactory.box(root, Vector3(1.15, 0.75, 1.8), Vector3(0, 0.72, 0), Color("d9b23c"), "Body")
	MeshFactory.box(root, Vector3(1.25, 0.1, 1.9), Vector3(0, 1.6, 0), Color("2b2622"), "Roof", 0.0, false)
	MeshFactory.box(root, Vector3(1.0, 0.55, 0.08), Vector3(0, 1.25, -0.9), Color("33454d"), "Windshield", 0.0, false)
	MeshFactory.box(root, Vector3(1.05, 0.5, 0.08), Vector3(0, 1.2, 0.9), Color("33454d"), "Rear", 0.0, false)
	for sz in [-0.65, 0.65]:
		var wheel := MeshFactory.cylinder(root, 0.24, 0.12, Vector3(0.62, 0.26, sz), Color("2b2622"), "Wheel", 10, false)
		wheel.rotation.z = PI / 2.0
	var front := MeshFactory.cylinder(root, 0.22, 0.1, Vector3(0, 0.25, -0.95), Color("2b2622"), "FrontWheel", 10, false)
	front.rotation.z = PI / 2.0
	MeshFactory.box(root, Vector3(0.5, 0.3, 0.5), Vector3(0, 0.9, -0.7), Color("d9b23c"), "Nose")


# --------------------------------------------------------------------- stall

func _build_stall() -> void:
	stall = StallBuilder.build(self)
	plate = stall.plate
	_menu_label = stall.get("menu_label")
	# bunting across the front of the canopy
	var colors := [GameData.C_ORANGE, GameData.C_TEAL, GameData.C_RED, Color("f2e2c4")]
	for i in 10:
		var flag := MeshFactory.box(self, Vector3(0.16, 0.2, 0.02), Vector3(-1.9 + i * 0.42, 2.38, 8.22), colors[i % colors.size()], "Flag", 0.0, false)
		flag.rotation.z = 0.35


# ----------------------------------------------------------------- customers

func _build_customers() -> void:
	queue_points.clear()
	for i in 12:
		queue_points.append(Vector3(1.5 + i * 0.92, 0.14, 7.55))

	customer_manager = CustomerManager.new()
	customer_manager.name = "CustomerManager"
	customer_manager.queue_points = queue_points
	customer_manager.spawn_point = spawn_point
	customer_manager.exit_point = exit_point
	add_child(customer_manager)

	for i in 2:
		var walker := Pedestrian.new()
		walker.point_a = Vector3(-19.0, 0.14, -8.6 - i * 0.6)
		walker.point_b = Vector3(19.0, 0.14, -8.6 - i * 0.6)
		walker.speed = randf_range(0.85, 1.25)
		add_child(walker)


func _boundaries() -> void:
	MeshFactory.add_box_collider(self, Vector3(0.4, 3.0, 24), Vector3(-26, 1.5, 0), 1)
	MeshFactory.add_box_collider(self, Vector3(0.4, 3.0, 24), Vector3(26, 1.5, 0), 1)
	MeshFactory.add_box_collider(self, Vector3(52, 3.0, 0.4), Vector3(0, 1.5, -12.2), 1)
	MeshFactory.add_box_collider(self, Vector3(52, 3.0, 0.4), Vector3(0, 1.5, 13.2), 1)


func _expansion_gate() -> void:
	_gate = Node3D.new()
	_gate.name = "ExpansionGate"
	add_child(_gate)
	MeshFactory.cylinder(_gate, 0.07, 2.4, Vector3(-13.5, 1.2, 6.2), Color("5a5550"), "Post", 8)
	MeshFactory.cylinder(_gate, 0.07, 2.4, Vector3(-13.5, 1.2, 10.8), Color("5a5550"), "Post2", 8)
	MeshFactory.box(_gate, Vector3(0.1, 0.14, 4.7), Vector3(-13.5, 2.3, 8.5), Color("5a5550"), "Bar", 0.0, false)
	MeshFactory.signboard(_gate, "MARKET STREET", Vector3(-13.5, 1.85, 8.5), 2.2, GameData.C_TEAL, Color("fff4dc"), 0.42, PI / 2.0)
	MeshFactory.signboard(_gate, "PERMIT REQUIRED", Vector3(-13.5, 1.45, 8.5), 1.9, Color("2a221c"), Color("e8c79a"), 0.3, PI / 2.0)
	_gate_body = MeshFactory.add_box_collider(_gate, Vector3(0.3, 2.2, 4.8), Vector3(-13.5, 1.1, 8.5), 1)


# ------------------------------------------------------------------- day theme

func _build_theme_visuals() -> void:
	_theme_root = Node3D.new()
	_theme_root.name = "DayTheme"
	add_child(_theme_root)

	_rain = _make_particles(
		Vector3(22, 0.2, 18), Color(0.7, 0.85, 1.0, 0.55), 0.035,
		Vector3(0, -1, 0), 12.0, 220
	)
	var rain_quad := _rain.draw_pass_1 as QuadMesh
	if rain_quad != null:
		rain_quad.size = Vector2(0.03, 0.22)
	_rain.position = Vector3(0, 5.0, 2.0)
	_theme_root.add_child(_rain)

	_confetti = _make_particles(
		Vector3(16, 1.0, 12), Color(0.95, 0.45, 0.75, 0.9), 0.07,
		Vector3(0, -0.35, 0), 0.6, 130
	)
	_confetti.position = Vector3(0, 5.0, 8.0)
	_theme_root.add_child(_confetti)

	_festival_lights = Node3D.new()
	_festival_lights.name = "FestivalLights"
	_theme_root.add_child(_festival_lights)
	var bulb_mat := MeshFactory.material(Color("ffd27a"), 0.4, 0.0, true)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color("ffb347")
	bulb_mat.emission_energy_multiplier = 1.5
	for i in 14:
		var x := -2.8 + i * 0.43
		var bulb := MeshFactory.sphere(_festival_lights, 0.05, Vector3(x, 2.2, 8.15), Color("ffd27a"), "Diya", 6, false)
		bulb.material_override = bulb_mat
	for i in 10:
		var x2 := -6.3 + i * 1.4
		var lamp := MeshFactory.sphere(_festival_lights, 0.055, Vector3(x2, 3.2, 12.35), Color("ffd27a"), "TerraceDiya", 6, false)
		lamp.material_override = bulb_mat
	_festival_lights.visible = false


func _make_particles(extents: Vector3, color: Color, size: float, direction: Vector3, gravity: float, amount: int) -> GPUParticles3D:
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = direction
	process.spread = 0.18
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 5.0
	process.gravity = Vector3(0, -gravity, 0)
	process.scale_min = 0.6
	process.scale_max = 1.4
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size * 2.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = mat
	var particles := GPUParticles3D.new()
	particles.process_material = process
	particles.draw_pass_1 = quad
	particles.amount = amount
	particles.lifetime = 2.2
	particles.visible = false
	return particles


func apply_day_theme(day: int) -> void:
	var weather := GameData.weather_for_day(day)
	var festival := GameData.festival_for_day(day)
	if _world_environment != null:
		match weather:
			"rain":
				_world_environment.fog_density = 0.008
				_world_environment.ambient_light_energy = 0.5
				_world_environment.fog_light_color = Color("aeb6bb")
			"heat":
				_world_environment.fog_density = 0.002
				_world_environment.ambient_light_energy = 0.82
				_world_environment.fog_light_color = Color("f0d6a2")
			_:
				_world_environment.fog_density = 0.0035
				_world_environment.ambient_light_energy = 0.65
				_world_environment.fog_light_color = Color("d9b58d")
	if _sun != null:
		_sun.light_energy = 0.65 if weather == "rain" else (1.2 if weather == "heat" else 1.0)
	if _rain != null:
		_rain.visible = weather == "rain"
	if _confetti != null:
		_confetti.visible = festival == "Holi"
	if _festival_lights != null:
		_festival_lights.visible = festival != ""
	Events.day_theme_changed.emit(weather, GameData.theme_label(day))


# ------------------------------------------------------------------- upgrades

func _on_upgrade(id: String) -> void:
	sync_upgrades()
	match id:
		"garlic_pani":
			Events.toast.emit("Garlic pani pot added to the counter.", "good")
		"street_permit":
			Events.toast.emit("Market street is open - more customers are coming.", "good")
		"bigger_plate":
			if plate:
				plate.clear_plate()
		"potato_machine":
			Events.toast.emit("Potato prep machine installed - raw potatoes now become filling.", "good")
		"turbo_peeler":
			Events.toast.emit("Turbo drum fitted - the peeler is twice as fast.", "good")
		"auto_fill_arm":
			Events.toast.emit("Auto-fill arm ready - walk close with an open puri.", "good")
		"restaurant_reno":
			Events.toast.emit("The cart is now a restaurant - turn around to see the terrace.", "good")
		"fine_dining":
			Events.toast.emit("The balcony dining deck is open.", "good")
		"pani_puri_palace":
			Events.toast.emit("Pani Puri Palace is complete. The whole street knows your name.", "good")
		"franchise_hq":
			Events.toast.emit("Franchise HQ open - the delivery fleet is rolling.", "good")
		"world_tour":
			Events.toast.emit("World Tour launched - Pani Puri is global!", "good")


## Re-applies every purchased upgrade to the 3D world. Called after building and
## after loading a save, so a reloaded restaurant looks the same as a bought one.
func sync_upgrades() -> void:
	var tier := Progression.restaurant_tier()
	RestaurantBuilder.sync(restaurant, tier)
	if stall.has("pani_garlic") and stall.pani_garlic != null:
		stall.pani_garlic.set_enabled(Progression.has_upgrade("garlic_pani"))
	if stall.has("potato_machine") and stall.potato_machine != null:
		stall.potato_machine.set_enabled(Progression.has_upgrade("potato_machine"))
	if _gate:
		var permit := Progression.has_upgrade("street_permit")
		_gate.visible = not permit
		if _gate_body:
			_gate_body.collision_layer = 0 if permit else 1
	_apply_signboard(Progression.has_upgrade("signboard"))
	_update_signage(tier)


func _sign_node(key: String) -> Node:
	if not stall.has(key):
		return null
	var node: Node = stall.get(key)
	return node


func _sign_board() -> MeshInstance3D:
	var sign_root := _sign_node("sign")
	if sign_root == null:
		return null
	var board := sign_root.get_node_or_null("Board")
	return board as MeshInstance3D


func _sign_label(key: String) -> Label3D:
	var node := _sign_node(key)
	if node == null:
		return null
	for child in node.get_children():
		if child is Label3D:
			return child
	return null


func _apply_signboard(installed: bool) -> void:
	var board := _sign_board()
	if board == null:
		return
	if installed:
		var mat := MeshFactory.material(Color("ff8a3d"), 0.6)
		mat.emission_enabled = true
		mat.emission = Color("ff6a1f")
		mat.emission_energy_multiplier = 0.6
		board.material_override = mat
	else:
		board.material_override = MeshFactory.material(GameData.C_ORANGE, 0.85)


func _update_signage(tier: int) -> void:
	var main_label := _sign_label("sign")
	var sub_label := _sign_label("sub_sign")
	if main_label:
		match tier:
			0:
				main_label.text = "PANI PURI"
			3:
				main_label.text = "PANI PURI PALACE"
			4:
				main_label.text = "PANI PURI HQ"
			5:
				main_label.text = "PANI PURI WORLD"
			_:
				main_label.text = "PANI PURI HOUSE"
	if sub_label:
		match tier:
			2:
				sub_label.text = "FINE DINING  -  CHAAT"
			3:
				sub_label.text = "ROYAL CHAAT HOUSE"
			4:
				sub_label.text = "FRANCHISE  -  CHAAT"
			5:
				sub_label.text = "WORLD TOUR  -  CHAAT"
			_:
				sub_label.text = "GOLGAPPA  -  CHAAT"
	if Progression.has_upgrade("signboard"):
		return
	var board := _sign_board()
	if board == null:
		return
	var color := GameData.C_ORANGE
	if tier >= 5:
		color = Color("1d2b53")
	elif tier == 4:
		color = Color("17312f")
	elif tier == 3:
		color = Color("5c1f1f")
	elif tier == 2:
		color = GameData.C_TEAL
	elif tier == 1:
		color = Color("d97a34")
	board.material_override = MeshFactory.material(color, 0.85)


func _on_price_changed(price: int) -> void:
	if _menu_label:
		_menu_label.text = "PANI PURI  Rs %d\nEXTRA PURI  Rs %d" % [price, price]
