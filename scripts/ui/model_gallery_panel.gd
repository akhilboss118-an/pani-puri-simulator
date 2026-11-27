class_name ModelGalleryPanel
extends OverlayPanel
## In-game model presentation: scans the customer and environment GLBs, lists
## them, and shows a rotating live 3D preview with a framed camera.

var _list: VBoxContainer
var _hint: Label
var _selected_label: Label
var _preview: SubViewport
var _preview_root: Node3D
var _preview_camera: Camera3D
var _anim_player: AnimationPlayer
var _models: Array[Dictionary] = []


func _init() -> void:
	title_text = "Model Gallery"


func _build_content() -> void:
	_hint = UIKit.label("", 14, UIKit.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_hint)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(240, 420)
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	row.add_child(right)
	_selected_label = UIKit.label("Select a model", 18, UIKit.ORANGE)
	_selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_selected_label)
	_build_preview(right)

	var back := UIKit.button("Back to stall", 44)
	back.pressed.connect(close)
	content.add_child(back)


func _build_preview(parent: VBoxContainer) -> void:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(320, 360)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(container)

	_preview = SubViewport.new()
	_preview.size = Vector2(320, 360)
	_preview.transparent_bg = true
	_preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(_preview)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.07, 0.06, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.45)
	env.ambient_light_energy = 1.1
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_preview.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_energy = 1.3
	_preview.add_child(sun)

	_preview_root = Node3D.new()
	_preview_root.name = "ModelRoot"
	_preview.add_child(_preview_root)

	_preview_camera = Camera3D.new()
	_preview_camera.position = Vector3(0, 0.2, 3.0)
	_preview_camera.fov = 45.0
	_preview_camera.current = true
	_preview.add_child(_preview_camera)


func _on_open() -> void:
	_rebuild()


func _rebuild() -> void:
	_models = _collect_models()
	_hint.text = "%d models  -  %d customers + %d props. Live 3D preview; drag not needed, it rotates." % [
		_models.size(), _count_category("customer"), _count_category("prop"),
	]
	for child in _list.get_children():
		child.queue_free()
	for entry in _models:
		var button := UIKit.button(String(entry["name"]), 34)
		button.pressed.connect(func(e=entry): _show_model(e))
		_list.add_child(button)
	if not _models.is_empty():
		_show_model(_models[0])


func _count_category(kind: String) -> int:
	var n := 0
	for entry in _models:
		if String(entry.get("kind", "")) == kind:
			n += 1
	return n


func _collect_models() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_scan_dir("res://assets/models/customers", "customer", out)
	_scan_dir("res://assets/environment/props", "prop", out)
	out.sort_custom(func(a: Dictionary, b: Dictionary): return String(a["name"]) < String(b["name"]))
	return out


func _scan_dir(dir_path: String, kind: String, out: Array[Dictionary]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".glb"):
			continue
		out.append({
			"name": file_name.get_basename(),
			"path": dir_path + "/" + file_name,
			"kind": kind,
		})


func _show_model(entry: Dictionary) -> void:
	if _preview_root == null:
		return
	for child in _preview_root.get_children():
		child.queue_free()
	_anim_player = null
	_selected_label.text = "%s\n%s\n%s" % [
		String(entry["name"]), String(entry["kind"]).capitalize(), String(entry["path"]),
	]
	var packed: Resource = load(String(entry["path"]))
	if not (packed is PackedScene):
		_selected_label.text += "\n(failed to load)"
		return
	var inst := (packed as PackedScene).instantiate() as Node3D
	if inst == null:
		return
	_preview_root.add_child(inst)
	_fit(inst)
	var players := inst.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim_player = players[0] as AnimationPlayer
		if _anim_player.has_animation("idle"):
			_anim_player.play("idle")
		else:
			var list := _anim_player.get_animation_list()
			if not list.is_empty():
				_anim_player.play(list[0])


func _fit(inst: Node3D) -> void:
	var boxes: Array[AABB] = []
	_collect_aabb(inst, Transform3D.IDENTITY, boxes)
	if boxes.is_empty():
		return
	var total: AABB = boxes[0]
	for i in range(1, boxes.size()):
		total = total.merge(boxes[i])
	var size := total.size
	var max_dim := maxf(maxf(size.x, size.y), maxf(size.z, 0.0001))
	var scale := 1.5 / max_dim
	inst.scale = Vector3.ONE * scale
	var center := total.position + total.size * 0.5
	inst.position = -center * scale + Vector3(0.0, 0.05, 0.0)


func _collect_aabb(node: Node3D, xform: Transform3D, boxes: Array[AABB]) -> void:
	var local := xform * node.transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		boxes.append(local * (node as MeshInstance3D).mesh.get_aabb())
	for child in node.get_children():
		if child is Node3D:
			_collect_aabb(child as Node3D, local, boxes)


func _process(delta: float) -> void:
	if not visible or _preview_root == null:
		return
	_preview_root.rotation.y += delta * 0.9
