class_name MeshFactory
extends RefCounted
## Small helpers that assemble low-poly props from Godot primitives. Materials
## are cached by colour so the whole street shares a handful of materials,
## which keeps draw calls and memory low on mobile and web.

static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}
static var _textures: Dictionary = {}


static func material(color: Color, roughness: float = 0.85, metallic: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
	var key := "%s_%.2f_%.2f_%s" % [color.to_html(), roughness, metallic, str(unshaded)]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[key] = mat
	return mat


static func material_glass(color: Color, alpha: float = 0.24, roughness: float = 0.12) -> StandardMaterial3D:
	var key := "glass_%s_%.2f_%.2f" % [color.to_html(), alpha, roughness]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = roughness
	mat.metallic = 0.08
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = mat
	return mat


static func material_emissive(color: Color, emission: Color, energy: float = 1.4, roughness: float = 0.4) -> StandardMaterial3D:
	var key := "em_%s_%s_%.2f_%.2f" % [color.to_html(), emission.to_html(), energy, roughness]
	if _materials.has(key):
		return _materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	_materials[key] = mat
	return mat


static func noise_texture(key_name: String, base: Color, variance: float = 0.08, size: int = 64, seed_val: int = 42) -> ImageTexture:
	if _textures.has(key_name):
		return _textures[key_name]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var n := rng.randf_range(-variance, variance)
			var c := Color(
				clampf(base.r + n, 0.0, 1.0),
				clampf(base.g + n * 0.95, 0.0, 1.0),
				clampf(base.b + n * 0.9, 0.0, 1.0),
				1.0
			)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_textures[key_name] = tex
	return tex


static func stone_tile_texture(key_name: String, base: Color, grout: Color, tiles: int = 4, size: int = 64) -> ImageTexture:
	if _textures.has(key_name):
		return _textures[key_name]
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cell := maxi(4, size / tiles)
	for y in size:
		for x in size:
			var is_grout := (x % cell == 0) or (y % cell == 0)
			if is_grout:
				img.set_pixel(x, y, grout)
			else:
				var n := rng.randf_range(-0.04, 0.04)
				img.set_pixel(x, y, Color(
					clampf(base.r + n, 0.0, 1.0),
					clampf(base.g + n, 0.0, 1.0),
					clampf(base.b + n, 0.0, 1.0),
					1.0
				))
	var tex := ImageTexture.create_from_image(img)
	_textures[key_name] = tex
	return tex


static func torus(parent: Node3D, inner_r: float, outer_r: float, pos: Vector3, color: Color, node_name: String = "Torus", roughness: float = 0.35, metallic: float = 0.75) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner_r
	mesh.outer_radius = outer_r
	mesh.rings = 18
	mesh.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = material(color, roughness, metallic)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func cone(parent: Node3D, bottom_r: float, top_r: float, height: float, pos: Vector3, color: Color, node_name: String = "Cone", segments: int = 12, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom_r
	mesh.top_radius = top_r
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _add(parent, mesh, pos, color, node_name, 0.0, cast_shadow)


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, node_name: String = "Box", rot_y: float = 0.0, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, color, node_name, rot_y, cast_shadow)


static func cylinder(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, node_name: String = "Cylinder", segments: int = 12, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _add(parent, mesh, pos, color, node_name, 0.0, cast_shadow)


static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, node_name: String = "Sphere", segments: int = 10, cast_shadow: bool = true) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = maxi(4, int(segments * 0.6))
	return _add(parent, mesh, pos, color, node_name, 0.0, cast_shadow)


static func quad(parent: Node3D, size: Vector2, pos: Vector3, color: Color, node_name: String = "Quad", unshaded: bool = true) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	var mi := _add(parent, mesh, pos, color, node_name, 0.0, false)
	var mat := material(color, 1.0, 0.0, unshaded)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi


static func _add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, node_name: String, rot_y: float, cast_shadow: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation.y = rot_y
	mi.material_override = material(color)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func label(parent: Node3D, text: String, pos: Vector3, size: int = 48, color: Color = Color.WHITE, pixel_size: float = 0.004) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = pos
	label.font_size = size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = maxi(2, int(size * 0.08))
	label.outline_modulate = Color(0, 0, 0, 0.75)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	parent.add_child(label)
	return label


static func signboard(parent: Node3D, text: String, pos: Vector3, width: float, color: Color, text_color: Color = Color("2a1a10"), height: float = 0.55, rot_y: float = 0.0, framed: bool = true) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	parent.add_child(root)
	var board := box(root, Vector3(width, height, 0.06), Vector3.ZERO, color, "Board")
	board.material_override = material(color, 0.65, 0.04)
	if framed:
		var trim := Color("4a311e")
		box(root, Vector3(width + 0.05, 0.045, 0.08), Vector3(0, height * 0.5, 0), trim, "TrimTop", 0.0, false)
		box(root, Vector3(width + 0.05, 0.045, 0.08), Vector3(0, -height * 0.5, 0), trim, "TrimBot", 0.0, false)
	var label := Label3D.new()
	label.text = text
	label.font = UIKit.display_font(700)
	label.font_size = 48
	label.pixel_size = clampf(height * 0.5 / 48.0, 0.0006, 0.008)
	label.position = Vector3(0, 0, 0.042)
	label.modulate = text_color
	label.outline_size = 2
	label.outline_modulate = Color(0, 0, 0, 0.35)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.no_depth_test = false
	root.add_child(label)
	return root


static func add_box_collider(parent: Node3D, size: Vector3, pos: Vector3, layer: int = 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	return body


static func clear_cache() -> void:
	_materials.clear()
	_meshes.clear()
	_textures.clear()
