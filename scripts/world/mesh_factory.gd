class_name MeshFactory
extends RefCounted
## Small helpers that assemble low-poly props from Godot primitives. Materials
## are cached by colour so the whole street shares a handful of materials,
## which keeps draw calls and memory low on mobile and web.

static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


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


static func signboard(parent: Node3D, text: String, pos: Vector3, width: float, color: Color, text_color: Color = Color("2a1a10"), height: float = 0.55, rot_y: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = rot_y
	parent.add_child(root)
	box(root, Vector3(width, height, 0.08), Vector3.ZERO, color, "Board")
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = clampf(height * 0.5 / 48.0, 0.0006, 0.008)
	label.position = Vector3(0, 0, 0.05)
	label.modulate = text_color
	label.outline_size = 0
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
