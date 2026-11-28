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
var _rim: DirectionalLight3D
var _fill: DirectionalLight3D
var _world_env: WorldEnvironment
var _world_environment: Environment
var _sky_mat: ProceduralSkyMaterial
var _road_mat: StandardMaterial3D
var _window_mat: StandardMaterial3D
var _lamp_bulb_mat: StandardMaterial3D
var _string_bulb_mat: StandardMaterial3D
var _stall_lamps: Array[OmniLight3D] = []
var _street_lights: Array[OmniLight3D] = []
var _theme_root: Node3D
var _rain: GPUParticles3D
var _confetti: GPUParticles3D
var _festival_lights: Node3D
var _gate: Node3D
var _gate_body: StaticBody3D
var _menu_label: Label3D
var _chalk_label: Label3D
var _quality: int = 1
var _current_weather: String = "clear"


func build(quality: int) -> void:
	_quality = quality
	_setup_environment()
	_ground()
	_shops()
	_landmarks()
	_street_props()
	_string_lights()
	_build_stall()
	_stall_details()
	_contact_shadows()
	restaurant = RestaurantBuilder.build(self, _quality)
	EnvironmentLoader.apply(self)
	_build_customers()
	_boundaries()
	_expansion_gate()
	_build_theme_visuals()
	Events.upgrade_purchased.connect(_on_upgrade)
	Events.price_changed.connect(_on_price_changed)
	Events.time_changed.connect(_on_time_changed)
	sync_upgrades()
	apply_day_theme(Game.day)


func apply_quality(quality: int) -> void:
	_quality = quality
	if _sun:
		_sun.shadow_enabled = quality >= 1
		_sun.directional_shadow_max_distance = 44.0 if quality >= 2 else 30.0
		_sun.shadow_blur = 1.8 if quality >= 2 else 1.0
	if _world_environment != null:
		_world_environment.adjustment_enabled = quality >= 1
	_update_atmosphere()


# ------------------------------------------------------------------ lighting

func _setup_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("1e4a72")
	sky_mat.sky_horizon_color = Color("f7bd7f")
	sky_mat.ground_bottom_color = Color("2e2119")
	sky_mat.ground_horizon_color = Color("c08a58")
	sky_mat.sun_angle_max = 14.0
	sky_mat.sky_energy_multiplier = 1.1
	sky_mat.ground_energy_multiplier = 0.7
	sky.sky_material = sky_mat
	_sky_mat = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.84
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color("d9a97a")
	env.fog_density = 0.0022
	env.fog_sky_affect = 0.24
	env.fog_aerial_perspective = 0.12
	# Sekiro-ish grade: deeper blacks, warm highlights, cool shadows, restrained
	# saturation in the mids so the food colours still pop.
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.18
	env.adjustment_saturation = 1.1
	world_env.environment = env
	add_child(world_env)
	_world_env = world_env
	_world_environment = env

	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.rotation_degrees = Vector3(-34, 206, 0)
	_sun.light_color = Color("ffd9a8")
	_sun.light_energy = 1.45
	_sun.light_angular_distance = 1.6
	_sun.shadow_enabled = _quality >= 1
	_sun.shadow_blur = 1.3
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 38.0
	_sun.shadow_bias = 0.03
	add_child(_sun)

	# Cool sky-fill rim from behind the street separates silhouettes crisply.
	_rim = DirectionalLight3D.new()
	_rim.name = "Rim"
	_rim.rotation_degrees = Vector3(-22, 24, 0)
	_rim.light_color = Color("8fb8e0")
	_rim.light_energy = 0.55
	_rim.shadow_enabled = false
	add_child(_rim)

	# Warm bounce off the sunlit pavement. Sells the Forza-style low sun.
	var bounce := DirectionalLight3D.new()
	bounce.name = "Bounce"
	bounce.rotation_degrees = Vector3(118, 20, 0)
	bounce.light_color = Color("e8b078")
	bounce.light_energy = 0.12
	bounce.shadow_enabled = false
	add_child(bounce)

	_build_sun_flare()

	# Warm practicals under the canopy, no shadows.
	for x in [-1.35, 0.0, 1.35]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 2.3, 8.85)
		lamp.light_color = Color("ffb566")
		lamp.light_energy = 0.55
		lamp.omni_range = 4.2
		lamp.omni_attenuation = 1.35
		lamp.shadow_enabled = false
		add_child(lamp)
		_stall_lamps.append(lamp)

	# Soft warm bounce from the sunlit street keeps faces and food luminous.
	_fill = DirectionalLight3D.new()
	_fill.name = "FillLight"
	_fill.light_color = Color("ffe0c4")
	_fill.light_energy = 0.24
	_fill.shadow_enabled = false
	add_child(_fill)
	_fill.global_position = Vector3(0, 12, 24)
	_fill.rotation_degrees = Vector3(-62, 0, 0)

	_window_mat = StandardMaterial3D.new()
	_window_mat.albedo_color = Color("2d404b")
	_window_mat.roughness = 0.25
	_window_mat.metallic = 0.2
	_window_mat.emission_enabled = true
	_window_mat.emission = Color("ffb966")
	_window_mat.emission_energy_multiplier = 0.12

	_lamp_bulb_mat = StandardMaterial3D.new()
	_lamp_bulb_mat.albedo_color = Color("ffe3ad")
	_lamp_bulb_mat.emission_enabled = true
	_lamp_bulb_mat.emission = Color("ffba5e")
	_lamp_bulb_mat.emission_energy_multiplier = 0.8


# ------------------------------------------------------------------ sun flare
#
# Compatibility renderer has no bloom or lens flare, so the sun gets a pair of
# additive billboards parked far down the light direction. Two draw calls, no
# screen reads, and it is what sells the "golden hour" read at a glance.

func _build_sun_flare() -> void:
	if _quality < 1:
		return
	var dir := -(_sun.global_transform.basis.z)
	var flare_root := Node3D.new()
	flare_root.name = "SunFlare"
	add_child(flare_root)

	# Warm, tight core: a white sun desaturates the teal sky into grey. Keep the
	# halo amber and small so the Sekiro-style cool/warm contrast survives.
	_flare_sprite(flare_root, dir * 240.0, 84.0, Color(1.0, 0.72, 0.36, 0.22), [
		[0.0, Color(1, 0.84, 0.54, 1.0)],
		[0.24, Color(1, 0.66, 0.28, 0.52)],
		[0.58, Color(0.96, 0.46, 0.16, 0.12)],
		[1.0, Color(0.8, 0.34, 0.12, 0.0)],
	])
	_flare_sprite(flare_root, dir * 238.0, 30.0, Color(1.0, 0.88, 0.62, 0.42), [
		[0.0, Color(1, 0.96, 0.80, 1.0)],
		[0.32, Color(1, 0.82, 0.48, 0.68)],
		[1.0, Color(1, 0.70, 0.34, 0.0)],
	])


func _flare_sprite(parent: Node3D, pos: Vector3, diameter: float, tint: Color, stops: Array) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(diameter, diameter)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.no_depth_test = true
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = UIKit.radial_texture(stops, Vector2(0.5, 0.5), 0.5, 96)
	mat.albedo_color = tint
	var mi := MeshInstance3D.new()
	mi.name = "Flare"
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.extra_cull_margin = 400.0
	parent.add_child(mi)


## Soft contact shadow used to ground props and people. Cheap fake AO: one
## unshaded radial quad lying flat on the ground. `depth` squashes it along Z
## so carts and counters get an elliptical pool instead of a circle.
func blob_shadow(parent: Node3D, pos: Vector3, radius: float, alpha: float = 0.34, depth: float = 1.0) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 2.0, radius * 2.0 * depth)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, alpha)],
		[0.45, Color(0, 0, 0, alpha * 0.72)],
		[0.78, Color(0, 0, 0, alpha * 0.24)],
		[1.0, Color(0, 0, 0, 0.0)],
	], Vector2(0.5, 0.5), 0.5, 64)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_receive_shadows = true
	var mi := MeshInstance3D.new()
	mi.name = "ContactShadow"
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.rotation.x = -PI * 0.5
	parent.add_child(mi)
	return mi


## Ground the cart and its dressing so nothing looks pasted onto the pavement.
func _contact_shadows() -> void:
	var ground_y := 0.126
	# Long pool under the cart, plus a denser one right at the wheels.
	blob_shadow(self, Vector3(0.0, ground_y, 8.85), 2.35, 0.42, 0.46)
	blob_shadow(self, Vector3(0.0, ground_y + 0.002, 8.55), 1.9, 0.34, 0.34)
	# Side props.
	blob_shadow(self, Vector3(-3.35, ground_y, 9.7), 0.55, 0.38)
	blob_shadow(self, Vector3(-4.25, ground_y, 9.85), 0.62, 0.34, 0.72)
	blob_shadow(self, Vector3(2.62, ground_y, 9.5), 0.48, 0.38)
	blob_shadow(self, Vector3(3.2, ground_y, 9.1), 0.52, 0.36)


# -------------------------------------------------------------------- ground

func _ground() -> void:
	MeshFactory.add_box_collider(self, Vector3(96, 0.5, 64), Vector3(0, -0.13, 0), 1)

	var road_tex := MeshFactory.noise_texture("asphalt", GameData.C_ROAD, 0.035, 96, 17)
	_road_mat = StandardMaterial3D.new()
	_road_mat.albedo_texture = road_tex
	_road_mat.uv1_scale = Vector3(26, 6, 1)
	# Damp tarmac: a broad warm sheen down the road sells the low sun.
	_road_mat.roughness = 0.64
	_road_mat.metallic = 0.12
	var road := MeshFactory.box(self, Vector3(76, 0.12, 11.0), Vector3(0, 0.06, 0), GameData.C_ROAD, "Road", 0.0, false)
	road.material_override = _road_mat

	var pave_tex := MeshFactory.stone_tile_texture("pavement_stone", GameData.C_PAVEMENT.lightened(0.08), GameData.C_PAVEMENT.darkened(0.14), 4, 64)
	var pave_mat := StandardMaterial3D.new()
	pave_mat.albedo_texture = pave_tex
	pave_mat.uv1_scale = Vector3(28, 4, 1)
	pave_mat.roughness = 0.76
	pave_mat.metallic = 0.06

	var pave_near := MeshFactory.box(self, Vector3(76, 0.12, 6.4), Vector3(0, 0.06, 8.7), GameData.C_PAVEMENT, "PavementNear", 0.0, false)
	pave_near.material_override = pave_mat
	var pave_far := MeshFactory.box(self, Vector3(76, 0.12, 6.4), Vector3(0, 0.06, -8.7), GameData.C_PAVEMENT, "PavementFar", 0.0, false)
	pave_far.material_override = pave_mat

	# Segmented sandstone curbs
	MeshFactory.box(self, Vector3(76, 0.16, 0.22), Vector3(0, 0.08, 5.53), GameData.C_CURB, "CurbNear", 0.0, false)
	MeshFactory.box(self, Vector3(76, 0.16, 0.22), Vector3(0, 0.08, -5.53), GameData.C_CURB, "CurbFar", 0.0, false)
	for i in 18:
		var cx := -32.0 + i * 3.8
		var accent_col := Color("d69d46") if i % 2 == 0 else Color("2a2623")
		MeshFactory.box(self, Vector3(1.85, 0.168, 0.23), Vector3(cx, 0.082, 5.53), accent_col, "CurbPaintN", 0.0, false)
		MeshFactory.box(self, Vector3(1.85, 0.168, 0.23), Vector3(cx, 0.082, -5.53), accent_col, "CurbPaintF", 0.0, false)

	# Road centre dashes and crisp pedestrian crossings
	for i in 19:
		var x := -34.0 + i * 3.8
		MeshFactory.box(self, Vector3(1.75, 0.01, 0.13), Vector3(x, 0.126, 0), Color("e6d7b8"), "Dash", 0.0, false)
	for z_off in [-1.8, -0.9, 0.0, 0.9, 1.8]:
		MeshFactory.box(self, Vector3(1.9, 0.012, 0.36), Vector3(-9.5, 0.127, z_off), Color("e6d7b8"), "CrosswalkL", 0.0, false)
		MeshFactory.box(self, Vector3(1.9, 0.012, 0.36), Vector3(9.5, 0.127, z_off), Color("e6d7b8"), "CrosswalkR", 0.0, false)

	_puddles()


## Shallow rain puddles. Compatibility has no screen-space reflections, so each
## puddle is a near-black, very smooth quad that catches the sun as a bright
## streak - the cheapest convincing wet-road read.
func _puddles() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.035, 0.045, 0.055, 0.72)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.07
	mat.metallic = 0.55
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var spots := [
		[-13.5, 2.9, 2.1, 0.9],
		[-6.2, -3.2, 1.7, 0.75],
		[2.4, 3.4, 2.4, 1.0],
		[8.6, -2.6, 1.5, 0.7],
		[15.2, 3.1, 2.0, 0.85],
		[-18.4, -3.4, 1.4, 0.65],
	]
	for spot in spots:
		var quad := QuadMesh.new()
		quad.size = Vector2(float(spot[2]), float(spot[3]))
		var mi := MeshInstance3D.new()
		mi.name = "Puddle"
		mi.mesh = quad
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(float(spot[0]), 0.129, float(spot[1]))
		mi.rotation.x = -PI * 0.5
		add_child(mi)


# --------------------------------------------------------------------- shops

func _shops() -> void:
	var far := [
		{"x": -24.0, "w": 7.0, "h": 7.5, "c": GameData.C_WALL_A, "a": GameData.C_TEAL, "n": "SHARMA STORES"},
		{"x": -16.0, "w": 7.5, "h": 9.2, "c": GameData.C_WALL_B, "a": GameData.C_ORANGE, "n": "CHAI POINT"},
		{"x": -7.5, "w": 8.0, "h": 7.0, "c": GameData.C_WALL_D, "a": GameData.C_RED, "n": "MEENA TAILORS"},
		{"x": 1.5, "w": 8.0, "h": 9.6, "c": GameData.C_WALL_C, "a": GameData.C_TEAL, "n": "GUPTA SWEETS"},
		{"x": 10.5, "w": 8.0, "h": 8.0, "c": GameData.C_WALL_A, "a": GameData.C_ORANGE, "n": "KIRANA MARKET"},
		{"x": 19.5, "w": 8.0, "h": 8.8, "c": GameData.C_WALL_B, "a": GameData.C_RED, "n": "PAAN HOUSE"},
	]
	for shop in far:
		_shop(float(shop.x), -11.5, 1.0, float(shop.w), float(shop.h), 6.0, shop.c, shop.a, String(shop.n))

	var near := [
		{"x": -22.0, "w": 9.0, "h": 8.4, "c": GameData.C_WALL_D, "a": GameData.C_RED, "n": "SALON"},
		{"x": -11.0, "w": 9.0, "h": 9.8, "c": GameData.C_WALL_C, "a": GameData.C_TEAL, "n": "MOBILE REPAIR"},
		{"x": 7.0, "w": 10.0, "h": 8.8, "c": GameData.C_WALL_A, "a": GameData.C_ORANGE, "n": "FRIENDS CAFE"},
		{"x": 18.0, "w": 9.0, "h": 7.5, "c": GameData.C_WALL_B, "a": GameData.C_RED, "n": "BOOK DEPOT"},
	]
	for shop in near:
		_shop(float(shop.x), 12.6, -1.0, float(shop.w), float(shop.h), 6.0, shop.c, shop.a, String(shop.n))

	# Detailed multi-story Apartment GLBs forming the bazaar skyline & framing the street
	var far_skyline := [
		{"x": -22.0, "z": -19.2, "ry": 0.0, "s": 0.84},
		{"x": -12.0, "z": -18.8, "ry": 0.0, "s": 0.94},
		{"x": 6.5, "z": -18.8, "ry": 0.0, "s": 0.98},
		{"x": 17.5, "z": -19.2, "ry": 0.0, "s": 0.88},
		{"x": 29.0, "z": -15.5, "ry": -0.58, "s": 0.90},
	]
	var near_skyline := [
		{"x": -29.5, "z": 14.0, "ry": 2.38, "s": 0.86},
		{"x": -20.5, "z": 19.8, "ry": PI, "s": 0.88},
		{"x": -8.5, "z": 20.4, "ry": PI, "s": 0.94},
		{"x": 9.0, "z": 20.0, "ry": PI, "s": 0.92},
		{"x": 20.5, "z": 19.6, "ry": PI, "s": 0.85},
		{"x": 29.5, "z": 14.5, "ry": -2.42, "s": 0.86},
	]
	for entry in far_skyline + near_skyline:
		var pos := Vector3(float(entry.x), 0.12, float(entry.z))
		if EnvironmentLoader.spawn_prop(self, "res://assets/environment/props/apartment_building.glb", pos, float(entry.ry), float(entry.s), false) == null:
			MeshFactory.box(self, Vector3(8.0, 14.0, 6.0), pos + Vector3(0, 7.0, 0), Color("c9a47e"), "Skyline", 0.0, false)


func _landmarks() -> void:
	var lm := Node3D.new()
	lm.name = "BazaarLandmarks"
	add_child(lm)

	# Sandstone Temple Shikhara rising at the far street vista + side temple silhouette
	for tpos in [Vector3(31.5, 0.0, 0.0), Vector3(-2.5, 0.0, -21.5)]:
		var tx: float = tpos.x
		var tz: float = tpos.z
		var stone := Color("d69a63")
		var stone_dark := Color("b07342")
		MeshFactory.box(lm, Vector3(6.4, 5.5, 5.6), Vector3(tx, 2.75, tz), stone, "TempleBase", 0.0, false)
		MeshFactory.box(lm, Vector3(6.8, 0.45, 6.0), Vector3(tx, 5.6, tz), stone_dark, "TempleCornice", 0.0, false)
		for i in 5:
			var w := 5.2 - i * 0.85
			var y := 6.5 + i * 1.35
			var col := stone.lightened(0.04) if i % 2 == 0 else stone_dark
			MeshFactory.box(lm, Vector3(w, 1.3, w * 0.88), Vector3(tx, y, tz), col, "ShikharaTier", 0.0, false)
		MeshFactory.cylinder(lm, 0.75, 0.45, Vector3(tx, 13.0, tz), Color("e6b85c"), "Amalaka", 12, false)
		MeshFactory.cone(lm, 0.35, 0.02, 1.4, Vector3(tx, 13.9, tz), Color("f2cb6b"), "Kalash", 10, false)

	# Bazaar Heritage Archways framing both ends of the street (eliminates empty sky edge!)
	for end_x in [-27.5, 27.5]:
		var arch := Node3D.new()
		arch.position = Vector3(end_x, 0.12, 0.0)
		lm.add_child(arch)
		for pz in [-5.8, 5.8]:
			MeshFactory.box(arch, Vector3(1.1, 6.2, 1.1), Vector3(0, 3.1, pz), Color("c97b4f"), "GatePillar", 0.0, false)
			MeshFactory.box(arch, Vector3(1.3, 0.35, 1.3), Vector3(0, 6.25, pz), Color("e6b85c"), "GateCap", 0.0, false)
			MeshFactory.cone(arch, 0.55, 0.05, 1.1, Vector3(0, 6.95, pz), Color("b84a36"), "GateDome", 10, false)
		MeshFactory.box(arch, Vector3(1.0, 1.3, 12.8), Vector3(0, 5.8, 0), Color("d69a63"), "GateSpan", 0.0, false)
		MeshFactory.box(arch, Vector3(1.15, 0.25, 13.2), Vector3(0, 6.55, 0), Color("e6b85c"), "GateCrown", 0.0, false)
		var rot := PI * 0.5 if end_x < 0.0 else -PI * 0.5
		MeshFactory.signboard(arch, "CHAAT BAZAAR", Vector3(0.55 if end_x < 0.0 else -0.55, 5.8, 0), 4.8, Color("8a2e22"), Color("fff2d4"), 0.82, rot)


func _shop(x: float, z_front: float, normal: float, width: float, height: float, depth: float, wall: Color, awning: Color, shop_name: String) -> void:
	var shop := Node3D.new()
	shop.name = shop_name.replace(" ", "")
	add_child(shop)
	var center_z := z_front - normal * depth * 0.5
	var body := MeshFactory.box(shop, Vector3(width, height, depth), Vector3(x, 0.12 + height * 0.5, center_z), wall, "Body")
	body.material_override = MeshFactory.material(wall, 0.92, 0.0)
	# Plinth and decorative cornice
	MeshFactory.box(shop, Vector3(width + 0.16, 0.42, depth + 0.12), Vector3(x, 0.33, center_z), wall.darkened(0.28), "Plinth", 0.0, false)
	MeshFactory.box(shop, Vector3(width + 0.42, 0.32, depth + 0.24), Vector3(x, 0.12 + height + 0.16, center_z), wall.darkened(0.16), "Parapet", 0.0, false)
	MeshFactory.box(shop, Vector3(width + 0.48, 0.1, depth + 0.28), Vector3(x, 0.12 + height + 0.35, center_z), awning.darkened(0.1), "ParapetTrim", 0.0, false)
	var fz := z_front + normal * 0.07

	# Pilasters framing the facade
	for sx in [-1.0, 1.0]:
		MeshFactory.box(shop, Vector3(0.28, height, 0.16), Vector3(x + sx * (width * 0.5 - 0.14), 0.12 + height * 0.5, fz), wall.darkened(0.12), "Pilaster", 0.0, false)

	# Ground-floor shopfront bay
	MeshFactory.box(shop, Vector3(1.5, 2.45, 0.12), Vector3(x - width * 0.24, 1.34, fz), Color("33261d"), "Door")
	MeshFactory.box(shop, Vector3(0.66, 2.1, 0.06), Vector3(x - width * 0.24, 1.24, fz + normal * 0.03), Color("5b4433"), "DoorPanel", 0.0, false)
	for i in 2:
		var wx := x + width * 0.08 + i * width * 0.26
		var win := MeshFactory.box(shop, Vector3(width * 0.2, 1.18, 0.06), Vector3(wx, 1.78, fz + normal * 0.01), Color("2e3f47"), "Window", 0.0, false)
		win.material_override = _window_mat
		MeshFactory.box(shop, Vector3(width * 0.2 + 0.08, 1.24, 0.04), Vector3(wx, 1.78, fz - normal * 0.01), Color("f2e2c4"), "WindowFrame", 0.0, false)
		MeshFactory.box(shop, Vector3(width * 0.24, 0.08, 0.14), Vector3(wx, 1.14, fz + normal * 0.04), wall.darkened(0.2), "WindowSill", 0.0, false)

	var rot := 0.0 if normal > 0.0 else PI
	MeshFactory.signboard(shop, shop_name, Vector3(x, 2.95, fz + normal * 0.06), width * 0.72, awning, Color("fff4dc"), 0.62, rot)

	# Striped shop awning with scalloped front trim
	for s in 5:
		var seg_w := (width * 0.84) / 5.0
		var sx := x - width * 0.42 + seg_w * (float(s) + 0.5)
		var seg_col := awning if s % 2 == 0 else Color("f6e7cb")
		var aw := MeshFactory.box(shop, Vector3(seg_w, 0.06, 1.35), Vector3(sx, 3.42, z_front + normal * 0.68), seg_col, "AwningSeg", 0.0, false)
		aw.rotation.x = 0.14 * normal
	for sx in [-1.0, 1.0]:
		MeshFactory.cylinder(shop, 0.028, 3.3, Vector3(x + sx * width * 0.39, 1.77, z_front + normal * 1.24), Color("3c332d"), "AwningPole", 6, false)
		# Small warm shopfront lantern hanging from awning corner
		var l_pos := Vector3(x + sx * width * 0.38, 3.08, z_front + normal * 1.22)
		var l_bulb := MeshFactory.sphere(shop, 0.065, l_pos, Color("ffe3ad"), "ShopLantern", 6, false)
		l_bulb.material_override = _lamp_bulb_mat

	# Upper floors + carved balcony ledge
	var floors := maxi(1, int(height / 2.9))
	for f in range(1, floors):
		var fy := 0.12 + f * 2.9
		if fy < height - 0.3:
			MeshFactory.box(shop, Vector3(width + 0.18, 0.12, 0.14), Vector3(x, fy, fz + normal * 0.04), wall.darkened(0.2), "FloorBand", 0.0, false)
			if f == 1:
				# Balcony slab + railing
				MeshFactory.box(shop, Vector3(width * 0.78, 0.08, 0.75), Vector3(x, fy + 0.06, z_front + normal * 0.38), wall.darkened(0.15), "Balcony", 0.0, false)
				MeshFactory.box(shop, Vector3(width * 0.78, 0.05, 0.05), Vector3(x, fy + 0.68, z_front + normal * 0.72), Color("2f2822"), "BalconyRail", 0.0, false)
				for rp in 5:
					var rpx := x - width * 0.34 + rp * (width * 0.68 / 4.0)
					MeshFactory.box(shop, Vector3(0.04, 0.62, 0.04), Vector3(rpx, fy + 0.38, z_front + normal * 0.72), Color("2f2822"), "BalconyPost", 0.0, false)
			for i in 3:
				var ux := x - width * 0.3 + i * width * 0.3
				var fwin := MeshFactory.box(shop, Vector3(width * 0.16, 0.94, 0.05), Vector3(ux, fy + 1.28, fz + normal * 0.02), Color("2e3f47"), "FloorWindow", 0.0, false)
				fwin.material_override = _window_mat
				MeshFactory.box(shop, Vector3(width * 0.16 + 0.06, 1.0, 0.03), Vector3(ux, fy + 1.28, fz - normal * 0.005), Color("f2e2c4"), "FloorFrame", 0.0, false)

	if height > 6.5:
		var ad_y := height * 0.68
		var ad_w := width * 0.5
		MeshFactory.signboard(shop, shop_name, Vector3(x + width * 0.19, ad_y, fz + normal * 0.06), ad_w, awning.darkened(0.14), Color("fff2d8"), 1.35, rot)
	for i in 2:
		MeshFactory.box(shop, Vector3(0.42, 0.34, 0.2), Vector3(x - width * 0.24 + i * width * 0.48, height * 0.42, fz + normal * 0.12), Color("b9b2a4"), "ACUnit", 0.0, false)
	if height > 7.0:
		MeshFactory.cylinder(shop, 0.42, 0.9, Vector3(x + width * 0.22, height + 0.58, center_z), Color("2f3438"), "WaterTank", 10, false)
		MeshFactory.box(shop, Vector3(0.08, 0.4, 0.08), Vector3(x + width * 0.22, height + 0.2, center_z), Color("4a4540"), "TankLeg", 0.0, false)

	MeshFactory.add_box_collider(shop, Vector3(width, height, depth), Vector3(x, 0.12 + height * 0.5, center_z), 1)


# -------------------------------------------------------------- street props

func _street_props() -> void:
	# electric poles and sagging wires along the far pavement
	for x in [-18.0, -7.0, 4.0, 15.0]:
		MeshFactory.cylinder(self, 0.09, 7.2, Vector3(x, 3.7, -6.6), Color("5a5550"), "Pole", 8, false)
		MeshFactory.box(self, Vector3(1.5, 0.08, 0.08), Vector3(x, 6.6, -6.6), Color("4a4540"), "CrossArm", 0.0, false)
		MeshFactory.box(self, Vector3(1.2, 0.04, 0.04), Vector3(x, 6.2, -6.6), Color("3a3530"), "CrossArm2", 0.0, false)
	for i in 3:
		var x0: float = [-18.0, -7.0, 4.0][i]
		var x1: float = [-7.0, 4.0, 15.0][i]
		var mid := (x0 + x1) * 0.5
		var length := x1 - x0
		MeshFactory.box(self, Vector3(length, 0.022, 0.022), Vector3(mid, 6.58, -6.6), Color("2f2a26"), "Wire", 0.0, false)
		MeshFactory.box(self, Vector3(length, 0.018, 0.018), Vector3(mid, 6.18, -6.6), Color("2f2a26"), "Wire2", 0.0, false)

	# Heritage street lamps along both sides of the road
	for lx in [-15.0, -4.0, 7.0, 18.0]:
		_street_lamp(lx, -5.9, 1.0)
	for lx in [-12.0, 10.0]:
		_street_lamp(lx, 5.9, -1.0)

	# Lush trees
	_tree(-20.0, -8.2, 1.05)
	_tree(-11.0, -8.6, 0.9)
	_tree(0.5, -8.4, 1.15)
	_tree(11.5, -8.2, 0.95)
	_tree(-14.0, 10.2, 0.85)
	_tree(12.0, 10.4, 0.9)

	# benches and detailed Poly-by-Google waste bins along both curbs
	_bench(-4.5, -7.9)
	_bench(8.0, -7.9)
	for bin_entry in [
		{"x": 4.5, "z": 6.4, "ry": -2.75},
		{"x": -13.0, "z": -6.4, "ry": 0.25},
		{"x": -1.5, "z": -6.5, "ry": -0.2},
		{"x": 13.8, "z": -6.5, "ry": 0.15},
	]:
		var bpos := Vector3(float(bin_entry.x), 0.146, float(bin_entry.z))
		if EnvironmentLoader.spawn_prop(self, "res://assets/environment/props/garbage_bin.glb", bpos, float(bin_entry.ry), 0.28, true) == null:
			MeshFactory.cylinder(self, 0.22, 0.6, Vector3(bpos.x, 0.42, bpos.z), Color("3f6b52"), "Bin", 10, false)

	# Parked MiniPoly scooters/bikes along the near & far bazaar curbs
	for bike_entry in [
		{"x": -5.3, "z": 6.45, "ry": 1.38},
		{"x": 6.8, "z": 6.5, "ry": -1.42},
		{"x": -9.2, "z": -6.4, "ry": -1.32},
		{"x": 5.4, "z": -6.4, "ry": 1.35},
	]:
		var bk_pos := Vector3(float(bike_entry.x), 0.123, float(bike_entry.z))
		if EnvironmentLoader.spawn_prop(self, "res://assets/environment/props/bike.glb", bk_pos, float(bike_entry.ry), 0.165, true) == null:
			_scooter(bk_pos.x, bk_pos.z, GameData.C_TEAL)

	_rickshaw(9.5, -3.6)
	_rickshaw(-11.5, 3.6)

	# Stacked Kay Lousberg Box B supply crates beside the stall and shopfronts
	var crate_clusters := [
		{"x": -3.55, "z": 9.85, "count": 2, "s": 2.6},
		{"x": -23.2, "z": -10.5, "count": 3, "s": 2.6},
		{"x": 2.6, "z": -10.5, "count": 2, "s": 2.5},
		{"x": 11.4, "z": -10.5, "count": 3, "s": 2.6},
	]
	for cl in crate_clusters:
		var bs := float(cl.s)
		var step_h := 0.17 * bs
		for ci in int(cl.count):
			var cpos := Vector3(float(cl.x) + (ci % 2) * 0.05, 0.12 + float(ci) * step_h, float(cl.z) - (ci % 2) * 0.04)
			if EnvironmentLoader.spawn_prop(self, "res://assets/environment/props/box_b.glb", cpos, 0.22 + 0.35 * ci, bs, true) == null:
				MeshFactory.box(self, Vector3(0.45, 0.4, 0.45), cpos + Vector3(0, 0.2, 0), Color("a97b4a"), "Crate", 0.2)
	MeshFactory.sphere(self, 0.3, Vector3(3.4, 0.42, 9.7), Color("c9b48a"), "Sack", 8, false)


func _street_lamp(x: float, z: float, normal: float) -> void:
	var post_mat := MeshFactory.material(Color("26292b"), 0.5, 0.6)
	var pole := MeshFactory.cylinder(self, 0.06, 4.1, Vector3(x, 2.15, z), Color("26292b"), "StreetLampPole", 8, false)
	pole.material_override = post_mat
	MeshFactory.cylinder(self, 0.14, 0.22, Vector3(x, 0.23, z), Color("26292b"), "StreetLampBase", 8, false).material_override = post_mat
	var arm := MeshFactory.box(self, Vector3(0.06, 0.06, 0.65), Vector3(x, 4.12, z + normal * 0.28), Color("26292b"), "StreetLampArm", 0.0, false)
	arm.material_override = post_mat
	var head := MeshFactory.cone(self, 0.22, 0.08, 0.16, Vector3(x, 4.02, z + normal * 0.54), Color("26292b"), "StreetLampHood", 10, false)
	head.material_override = post_mat
	var bulb := MeshFactory.sphere(self, 0.1, Vector3(x, 3.9, z + normal * 0.54), Color("ffe3ad"), "StreetLampBulb", 8, false)
	bulb.material_override = _lamp_bulb_mat
	if _quality >= 1:
		var omni := OmniLight3D.new()
		omni.position = Vector3(x, 3.7, z + normal * 0.54)
		omni.light_color = Color("ffbc66")
		omni.light_energy = 0.0
		omni.omni_range = 7.5
		omni.omni_attenuation = 1.4
		omni.shadow_enabled = false
		add_child(omni)
		_street_lights.append(omni)


# -------------------------------------------------------------- string lights

## Warm bulbs strung across the street in three gentle catenaries. All bulbs
## share one MultiMesh, so the whole decoration costs a single draw call.
func _string_lights() -> void:
	var root := Node3D.new()
	root.name = "StringLights"
	add_child(root)

	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.055
	bulb_mesh.height = 0.11
	bulb_mesh.radial_segments = 6
	bulb_mesh.rings = 4

	_string_bulb_mat = StandardMaterial3D.new()
	_string_bulb_mat.albedo_color = Color("ffe3ad")
	_string_bulb_mat.emission_enabled = true
	_string_bulb_mat.emission = Color("ffba5e")
	_string_bulb_mat.emission_energy_multiplier = 0.85

	var wire_mat := MeshFactory.material(Color("2a2420"), 0.9)

	var strands := [
		{"z": 6.4, "y": 4.5, "sag": 0.55, "from": -14.0, "to": 14.0},
		{"z": 2.2, "y": 4.9, "sag": 0.70, "from": -14.0, "to": 14.0},
		{"z": -2.4, "y": 5.1, "sag": 0.60, "from": -14.0, "to": 14.0},
	]
	var positions: Array[Vector3] = []
	for strand in strands:
		var z := float(strand.z)
		var y := float(strand.y)
		var sag := float(strand.sag)
		var x0 := float(strand.from)
		var x1 := float(strand.to)
		for s in 8:
			var p0 := _catenary(x0, x1, y, sag, float(s) / 8.0, z)
			var p1 := _catenary(x0, x1, y, sag, float(s + 1) / 8.0, z)
			var seg := MeshFactory.box(root, Vector3(p0.distance_to(p1), 0.014, 0.014), (p0 + p1) * 0.5, Color("2a2420"), "Wire", 0.0, false)
			seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x)
			seg.material_override = wire_mat
		var count := 22
		for i in count:
			var t := float(i + 1) / float(count + 1)
			positions.append(_catenary(x0, x1, y, sag, t, z) - Vector3(0, 0.085, 0))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bulb_mesh
	mm.instance_count = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis(), positions[i]))
	var bulbs := MultiMeshInstance3D.new()
	bulbs.name = "Bulbs"
	bulbs.multimesh = mm
	bulbs.material_override = _string_bulb_mat
	bulbs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(bulbs)

	# Warm overhead pool under the middle strand.
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 3.9, 4.6)
	glow.light_color = Color("ffb877")
	glow.light_energy = 0.35
	glow.omni_range = 8.0
	glow.shadow_enabled = false
	root.add_child(glow)
	_street_lights.append(glow)


func _catenary(x0: float, x1: float, y: float, sag: float, t: float, z: float) -> Vector3:
	return Vector3(lerpf(x0, x1, t), y - sin(PI * t) * sag, z)


# --------------------------------------------------------------- stall dressing

## Small, non-interactive props that make the cart feel owned: brass pots, a
## chalkboard, a potted plant and a woven rug.
func _stall_details() -> void:
	var root := Node3D.new()
	root.name = "StallDressing"
	add_child(root)

	var brass := MeshFactory.material(Color("c9963f"), 0.28, 0.82)
	var brass_dark := MeshFactory.material(Color("8a6427"), 0.38, 0.72)

	# stacked brass pots, left of the cart
	for i in 3:
		var pot := MeshFactory.cylinder(root, 0.26 - i * 0.04, 0.16, Vector3(-3.35, 0.2 + i * 0.16, 9.7), Color("c9963f"), "BrassPot", 14, true)
		pot.material_override = brass if i % 2 == 0 else brass_dark
		var rim := MeshFactory.torus(root, (0.26 - i * 0.04) - 0.015, (0.26 - i * 0.04) + 0.018, Vector3(-3.35, 0.28 + i * 0.16, 9.7), Color("e6b85c"), "BrassRim", 0.25, 0.85)
		rim.material_override = brass

	# hanging lanterns under the canopy
	for x in [-1.75, 1.75]:
		MeshFactory.cylinder(root, 0.012, 0.48, Vector3(x, 2.35, 9.35), Color("2a2420"), "LanternCord", 5, false)
		var body := MeshFactory.sphere(root, 0.115, Vector3(x, 2.02, 9.35), Color("ffb45f"), "Lantern", 10, false)
		body.material_override = _lamp_bulb_mat
		MeshFactory.cylinder(root, 0.055, 0.035, Vector3(x, 2.13, 9.35), Color("2a2420"), "LanternCap", 8, false)
		MeshFactory.cylinder(root, 0.055, 0.035, Vector3(x, 1.91, 9.35), Color("2a2420"), "LanternBase", 8, false)

	# A-frame chalkboard next to the counter, angled toward customers & vendor
	var board := Node3D.new()
	board.position = Vector3(-4.2, 0.12, 9.85)
	board.rotation.y = 0.5
	root.add_child(board)
	MeshFactory.box(board, Vector3(0.86, 0.06, 0.48), Vector3(0, 0.03, 0), Color("4a3626"), "BoardFoot")
	var slate := MeshFactory.box(board, Vector3(0.78, 0.98, 0.05), Vector3(0, 0.62, 0), Color("1b221e"), "Slate")
	slate.rotation.x = -0.14
	MeshFactory.box(board, Vector3(0.88, 0.06, 0.09), Vector3(0, 1.13, -0.02), Color("6b4c30"), "BoardTop")
	MeshFactory.box(board, Vector3(0.06, 1.0, 0.09), Vector3(-0.41, 0.62, -0.02), Color("6b4c30"), "BoardSideL")
	MeshFactory.box(board, Vector3(0.06, 1.0, 0.09), Vector3(0.41, 0.62, -0.02), Color("6b4c30"), "BoardSideR")
	_chalk_label = Label3D.new()
	_chalk_label.text = "Pani Puri\nRs %d/-\n(6 Pcs)" % Progression.price_per_puri
	_chalk_label.font = UIKit.display_font(700)
	_chalk_label.font_size = 54
	_chalk_label.pixel_size = 0.0029
	_chalk_label.position = Vector3(0, 0.64, 0.042)
	_chalk_label.modulate = Color("f7ecd2")
	_chalk_label.outline_size = 0
	_chalk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chalk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chalk_label.rotation.x = -0.14
	board.add_child(_chalk_label)

	# potted plant, right of the cart
	MeshFactory.cylinder(root, 0.22, 0.34, Vector3(4.05, 0.29, 10.35), Color("8a4a2e"), "PlantPot", 10)
	MeshFactory.torus(root, 0.2, 0.24, Vector3(4.05, 0.46, 10.35), Color("a25a3c"), "PlantRim", 0.85, 0.0)
	for i in 5:
		var leaf := MeshFactory.sphere(root, 0.19, Vector3(4.05 + cos(i * 1.4) * 0.14, 0.62 + i * 0.11, 10.35 + sin(i * 1.4) * 0.14), Color("4f7a3a").lightened(i * 0.04), "PlantLeaf", 8, false)
		leaf.scale = Vector3(0.82, 1.28, 0.82)

	# woven floor mat behind the counter
	var rug := MeshFactory.quad(root, Vector2(3.8, 1.5), Vector3(0.15, 0.132, 10.1), Color("6d2a22"), "Rug")
	rug.rotation.x = -PI / 2.0
	var rug_inner := MeshFactory.quad(root, Vector2(3.4, 1.18), Vector3(0.15, 0.134, 10.1), Color("8a3a2a"), "RugInner")
	rug_inner.rotation.x = -PI / 2.0
	for i in 6:
		var stripe := MeshFactory.quad(root, Vector2(0.1, 1.12), Vector3(-1.3 + i * 0.58, 0.136, 10.1), Color("d9a45c"), "RugStripe")
		stripe.rotation.x = -PI / 2.0


func _tree(x: float, z: float, scale: float) -> void:
	MeshFactory.cylinder(self, 0.14 * scale, 1.8 * scale, Vector3(x, 0.12 + 0.9 * scale, z), Color("5b3d26"), "Trunk", 8, false)
	var b1 := MeshFactory.cylinder(self, 0.07 * scale, 0.9 * scale, Vector3(x - 0.22 * scale, 0.12 + 1.8 * scale, z), Color("5b3d26"), "BranchL", 6, false)
	b1.rotation.z = 0.55
	var b2 := MeshFactory.cylinder(self, 0.07 * scale, 0.9 * scale, Vector3(x + 0.22 * scale, 0.12 + 1.85 * scale, z), Color("5b3d26"), "BranchR", 6, false)
	b2.rotation.z = -0.55
	var greens := [Color("3e6c32"), Color("4f843a"), Color("639943"), Color("487836"), Color("74aa4c")]
	var offsets := [
		Vector3(0.0, 2.55, 0.0),
		Vector3(-0.55, 2.15, 0.25),
		Vector3(0.55, 2.2, -0.22),
		Vector3(0.2, 2.35, 0.45),
		Vector3(-0.15, 2.85, -0.1),
	]
	for i in 5:
		var foliage := MeshFactory.sphere(self, (0.76 - i * 0.04) * scale, Vector3(x, 0.12, z) + offsets[i] * scale, greens[i], "Leaves", 10, i == 0)
		foliage.scale = Vector3(1.1, 0.85, 1.1)


func _bench(x: float, z: float) -> void:
	MeshFactory.box(self, Vector3(1.6, 0.08, 0.46), Vector3(x, 0.56, z), GameData.C_WOOD, "Seat")
	MeshFactory.box(self, Vector3(1.6, 0.44, 0.07), Vector3(x, 0.86, z - 0.2), GameData.C_WOOD.darkened(0.1), "Back")
	for sx in [-0.65, 0.65]:
		MeshFactory.box(self, Vector3(0.07, 0.45, 0.42), Vector3(x + sx, 0.34, z), Color("2b2724"), "Leg", 0.0, false)


func _scooter(x: float, z: float, color: Color) -> void:
	var root := Node3D.new()
	root.position = Vector3(x, 0.12, z)
	root.rotation.y = PI * 0.5
	add_child(root)
	var paint := MeshFactory.material(color, 0.28, 0.25)
	var chrome := MeshFactory.material(Color("cfd4d8"), 0.22, 0.85)
	# Rear cowl + floorboard + front legshield
	var body := MeshFactory.box(root, Vector3(0.42, 0.32, 0.72), Vector3(0, 0.58, 0.25), color, "Body")
	body.material_override = paint
	MeshFactory.box(root, Vector3(0.32, 0.08, 0.5), Vector3(0, 0.36, -0.15), Color("2b2622"), "Floorboard", 0.0, false)
	var shield := MeshFactory.box(root, Vector3(0.36, 0.58, 0.14), Vector3(0, 0.72, -0.42), color, "Shield", 0.0, false)
	shield.material_override = paint
	shield.rotation.x = -0.18
	MeshFactory.box(root, Vector3(0.34, 0.12, 0.58), Vector3(0, 0.8, 0.2), Color("26211e"), "Seat", 0.0, false)
	for sz in [-0.48, 0.48]:
		var wheel := MeshFactory.cylinder(root, 0.21, 0.1, Vector3(0, 0.22, sz), Color("1f1d1b"), "Wheel", 12, false)
		wheel.rotation.z = PI / 2.0
		var hub := MeshFactory.cylinder(root, 0.11, 0.115, Vector3(0, 0.22, sz), Color("cfd4d8"), "Hub", 10, false)
		hub.rotation.z = PI / 2.0
		hub.material_override = chrome
	var stem := MeshFactory.cylinder(root, 0.032, 0.42, Vector3(0, 1.02, -0.45), Color("cfd4d8"), "Handle", 8, false)
	stem.material_override = chrome
	MeshFactory.box(root, Vector3(0.56, 0.05, 0.06), Vector3(0, 1.22, -0.45), color, "HandleHead", 0.0, false).material_override = paint
	var head := MeshFactory.sphere(root, 0.075, Vector3(0, 1.22, -0.5), Color("fff3cc"), "Headlight", 8, false)
	head.material_override = _lamp_bulb_mat


func _rickshaw(x: float, z: float) -> void:
	var root := Node3D.new()
	root.position = Vector3(x, 0.12, z)
	root.rotation.y = PI * 0.5
	add_child(root)
	var green := MeshFactory.material(Color("246b42"), 0.35, 0.15)
	var yellow := MeshFactory.material(Color("eab734"), 0.35, 0.15)
	var chrome := MeshFactory.material(Color("cfd4d8"), 0.25, 0.85)
	# Classic green & yellow Indian auto-rickshaw
	MeshFactory.box(root, Vector3(1.18, 0.52, 1.85), Vector3(0, 0.58, 0), Color("246b42"), "LowerBody").material_override = green
	MeshFactory.box(root, Vector3(1.16, 0.24, 1.8), Vector3(0, 0.94, 0.05), Color("eab734"), "UpperTrim").material_override = yellow
	MeshFactory.box(root, Vector3(1.22, 0.1, 1.92), Vector3(0, 1.66, 0), Color("23211f"), "CanopyRoof", 0.0, false)
	# Canopy struts
	for sx in [-0.54, 0.54]:
		for sz in [-0.78, 0.82]:
			MeshFactory.cylinder(root, 0.025, 0.65, Vector3(sx, 1.32, sz), Color("2b2622"), "Strut", 6, false)
	# Sloped front cowl & windshield
	var cowl := MeshFactory.box(root, Vector3(0.75, 0.55, 0.45), Vector3(0, 0.72, -0.95), Color("eab734"), "FrontCowl")
	cowl.material_override = yellow
	var glass := MeshFactory.box(root, Vector3(0.95, 0.5, 0.05), Vector3(0, 1.28, -0.84), Color("8cb5c7"), "Windshield", 0.0, false)
	glass.material_override = MeshFactory.material_glass(Color("a8d4e6"), 0.42, 0.08)
	glass.rotation.x = 0.18
	var hlight := MeshFactory.sphere(root, 0.09, Vector3(0, 0.76, -1.19), Color("fff4d0"), "Headlight", 8, false)
	hlight.material_override = _lamp_bulb_mat
	for sz in [-0.62, 0.62]:
		for sx in [-0.6, 0.6]:
			if sz < 0.0:
				continue
			var wheel := MeshFactory.cylinder(root, 0.24, 0.13, Vector3(sx, 0.25, sz), Color("1f1d1b"), "Wheel", 12, false)
			wheel.rotation.z = PI / 2.0
			var hub := MeshFactory.cylinder(root, 0.12, 0.145, Vector3(sx, 0.25, sz), Color("cfd4d8"), "Hub", 10, false)
			hub.rotation.z = PI / 2.0
			hub.material_override = chrome
	var front := MeshFactory.cylinder(root, 0.23, 0.11, Vector3(0, 0.24, -1.05), Color("1f1d1b"), "FrontWheel", 12, false)
	front.rotation.z = PI / 2.0


# --------------------------------------------------------------------- stall

func _build_stall() -> void:
	stall = StallBuilder.build(self)
	plate = stall.plate
	_menu_label = stall.get("menu_label")
	_chalk_label = stall.get("chalk_label")
	# bunting across the front of the canopy
	var colors := [GameData.C_ORANGE, GameData.C_TEAL, GameData.C_RED, Color("f2e2c4")]
	for i in 10:
		var flag := MeshFactory.box(self, Vector3(0.16, 0.2, 0.02), Vector3(-1.9 + i * 0.42, 2.38, 8.22), colors[i % colors.size()], "Flag", 0.0, false)
		flag.rotation.z = 0.35


# ----------------------------------------------------------------- customers

func _build_customers() -> void:
	queue_points.clear()
	for i in 12:
		queue_points.append(Vector3(-0.1 + i * 0.92, 0.14, 7.45))

	customer_manager = CustomerManager.new()
	customer_manager.name = "CustomerManager"
	customer_manager.queue_points = queue_points
	customer_manager.spawn_point = spawn_point
	customer_manager.exit_point = exit_point
	add_child(customer_manager)

	for i in 2:
		var walker := Pedestrian.new()
		walker.model_index = (i % Customer.MODEL_COUNT) + 1
		walker.point_a = Vector3(-19.0, 0.14, -8.6 - i * 0.6)
		walker.point_b = Vector3(19.0, 0.14, -8.6 - i * 0.6)
		walker.speed = randf_range(0.95, 1.25)
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
		Vector3(22, 0.2, 18), Color(0.75, 0.88, 1.0, 0.62), 0.032,
		Vector3(0, -1, 0), 14.0, 260
	)
	var rain_quad := _rain.draw_pass_1 as QuadMesh
	if rain_quad != null:
		rain_quad.size = Vector2(0.025, 0.28)
	_rain.position = Vector3(0, 5.2, 2.0)
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
	var bulb_mat := MeshFactory.material_emissive(Color("ffd27a"), Color("ffb347"), 1.8, 0.35)
	for i in 14:
		var x := -2.8 + i * 0.43
		var bulb := MeshFactory.sphere(_festival_lights, 0.055, Vector3(x, 2.2, 8.15), Color("ffd27a"), "Diya", 6, false)
		bulb.material_override = bulb_mat
	for i in 10:
		var x2 := -6.3 + i * 1.4
		var lamp := MeshFactory.sphere(_festival_lights, 0.06, Vector3(x2, 3.2, 12.35), Color("ffd27a"), "TerraceDiya", 6, false)
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
	_current_weather = GameData.weather_for_day(day)
	var festival := GameData.festival_for_day(day)
	if _rain != null:
		_rain.visible = _current_weather == "rain"
	if _confetti != null:
		_confetti.visible = festival == "Holi"
	if _festival_lights != null:
		_festival_lights.visible = festival != ""
	if _road_mat != null:
		_road_mat.roughness = 0.22 if _current_weather == "rain" else 0.88
	_update_atmosphere()
	Events.day_theme_changed.emit(_current_weather, GameData.theme_label(day))


func _on_time_changed(_hour: int, _minute: int) -> void:
	_update_atmosphere()


func _update_atmosphere() -> void:
	if _world_environment == null or _sun == null:
		return
	var p := Clock.progress() # 0.0 (9 AM) -> 1.0 (9 PM)
	# Sunset starts around 0.58 (~4 PM) and settles into warm night by 0.88 (~7:30 PM)
	var sunset := clampf((p - 0.55) / 0.22, 0.0, 1.0)
	var night := clampf((p - 0.72) / 0.22, 0.0, 1.0)

	var day_top := Color("2e6ba6")
	var dusk_top := Color("3b4d78")
	var night_top := Color("0f1930")
	var day_hor := Color("f4c188")
	var dusk_hor := Color("f08a56")
	var night_hor := Color("2a233b")

	if _current_weather == "rain":
		day_top = Color("465866")
		day_hor = Color("9aa8b2")
		dusk_top = Color("2a3442")
		dusk_hor = Color("5f6c78")
	elif _current_weather == "heat":
		day_top = Color("34669c")
		day_hor = Color("f7c272")

	var sky_top := day_top.lerp(dusk_top, sunset).lerp(night_top, night)
	var sky_hor := day_hor.lerp(dusk_hor, sunset).lerp(night_hor, night)
	if _sky_mat != null:
		_sky_mat.sky_top_color = sky_top
		_sky_mat.sky_horizon_color = sky_hor
		_sky_mat.ground_horizon_color = sky_hor.darkened(0.25)
		_sky_mat.sky_energy_multiplier = lerpf(1.05, 0.45, night)

	# Sun angle & color
	_sun.rotation_degrees.x = lerpf(-44.0, -14.0, p)
	_sun.rotation_degrees.y = lerpf(212.0, 165.0, p)
	var sun_col := Color("ffe6c4").lerp(Color("ff9e52"), sunset).lerp(Color("6c82b8"), night)
	_sun.light_color = sun_col
	var base_sun := 0.78 if _current_weather == "rain" else (1.35 if _current_weather == "heat" else 1.25)
	_sun.light_energy = lerpf(base_sun, 0.22, night)

	if _rim != null:
		_rim.light_energy = lerpf(0.45, 0.28, night)
	if _fill != null:
		_fill.light_energy = lerpf(0.24, 0.12, night)

	# Ambient + fog
	var base_amb := 0.42 if _current_weather == "rain" else 0.48
	_world_environment.ambient_light_energy = lerpf(base_amb, 0.24, night)
	_world_environment.fog_light_color = sky_hor.lerp(Color("342c44"), night)
	_world_environment.fog_density = 0.0052 if _current_weather == "rain" else lerpf(0.0018, 0.0028, night)
	_world_environment.adjustment_saturation = 0.96 if _current_weather == "rain" else 1.15

	# Lamps, string bulbs & warm lit windows glow as evening arrives (or during rain)
	var lamp_factor := maxf(night, 0.45 if _current_weather == "rain" else sunset * 0.55)
	if _window_mat != null:
		_window_mat.emission_energy_multiplier = lerpf(0.12, 1.45, lamp_factor)
	if _lamp_bulb_mat != null:
		_lamp_bulb_mat.emission_energy_multiplier = lerpf(0.65, 2.2, lamp_factor)
	if _string_bulb_mat != null:
		_string_bulb_mat.emission_energy_multiplier = lerpf(0.75, 2.4, lamp_factor)
	for lamp in _stall_lamps:
		if is_instance_valid(lamp):
			lamp.light_energy = lerpf(0.55, 1.35, lamp_factor)
	for sl in _street_lights:
		if is_instance_valid(sl):
			sl.light_energy = lerpf(0.12, 1.15, lamp_factor)


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
		_menu_label.text = "PANI PURI  ₹%d\nEXTRA PURI  ₹%d" % [price, price]
	if _chalk_label:
		_chalk_label.text = "Pani Puri\n₹%d/-\n(6 Pcs)" % price
