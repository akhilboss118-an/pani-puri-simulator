class_name PuriItem
extends Node3D
## A single puri in the world. Purely visual: all truth lives in PuriData and
## this node just mirrors it, so validation never depends on meshes.

var data: PuriData

var _opening: MeshInstance3D
var _potato: MeshInstance3D
var _chickpea: Node3D
var _onion: Node3D
var _coriander: Node3D
var _masala: MeshInstance3D
var _pani: MeshInstance3D
var _chutney: MeshInstance3D
var _broken: bool = false


static func create(puri_data: PuriData = null) -> PuriItem:
	var item := PuriItem.new()
	item.data = puri_data if puri_data != null else PuriData.new()
	return item


func _ready() -> void:
	if data == null:
		data = PuriData.new()
	_build()
	refresh()


func _build() -> void:
	var shell_mat := MeshFactory.material(Color("e6a94e"), 0.58, 0.02)
	var base := MeshFactory.sphere(self, 0.058, Vector3.ZERO, GameData.C_PURI, "Base", 14, false)
	base.scale = Vector3(1.0, 0.58, 1.0)
	base.material_override = shell_mat

	_opening = MeshFactory.cylinder(self, 0.028, 0.008, Vector3(0, 0.029, 0), Color("5e3616"), "Opening", 14, false)
	_potato = MeshFactory.sphere(self, 0.022, Vector3(0, 0.036, 0), GameData.C_POTATO, "Potato", 10, false)
	_potato.scale = Vector3(1.0, 0.62, 1.0)

	_chickpea = Node3D.new()
	_chickpea.name = "Chickpeas"
	add_child(_chickpea)
	for i in 4:
		var angle := TAU * float(i) / 4.0 + 0.3
		MeshFactory.sphere(_chickpea, 0.0075, Vector3(cos(angle) * 0.016, 0.043, sin(angle) * 0.016), GameData.C_CHICKPEA, "Chickpea", 6, false)

	_onion = Node3D.new()
	_onion.name = "Onion"
	add_child(_onion)
	for i in 4:
		var angle := TAU * float(i) / 4.0 + 0.7
		MeshFactory.box(_onion, Vector3(0.012, 0.005, 0.008), Vector3(cos(angle) * 0.015, 0.046, sin(angle) * 0.015), GameData.C_ONION.lightened(0.08), "OnionBit", angle, false)

	_coriander = Node3D.new()
	_coriander.name = "Coriander"
	add_child(_coriander)
	for i in 5:
		MeshFactory.box(_coriander, Vector3(0.009, 0.003, 0.008), Vector3(cos(i * 1.4) * 0.018, 0.049, sin(i * 1.4) * 0.018), GameData.C_CORIANDER.lightened(0.1), "Leaf", 0.7 * i, false)

	_masala = MeshFactory.cylinder(self, 0.024, 0.003, Vector3(0, 0.048, 0), GameData.C_MASALA, "Masala", 10, false)
	_pani = MeshFactory.cylinder(self, 0.023, 0.006, Vector3(0, 0.033, 0), Color("528b30"), "Pani", 12, false)
	_chutney = MeshFactory.box(self, Vector3(0.032, 0.005, 0.015), Vector3(0, 0.051, 0), Color("5c2612"), "Chutney", 0.5, false)


func play_crack_fx() -> void:
	_pop_scale(Vector3(1.16, 0.84, 1.16))
	_spawn_burst(Color("e6a94e"), 8, 0.006, 1.0)


func play_fill_fx(color: Color) -> void:
	_pop_scale(Vector3(1.08, 0.92, 1.08))
	_spawn_burst(color, 5, 0.0055, 0.7)


func play_dip_fx(color: Color) -> void:
	_pop_scale(Vector3(0.92, 1.12, 0.92))
	_spawn_burst(color.lightened(0.18), 8, 0.006, 1.15)


func _pop_scale(squash: Vector3) -> void:
	if Game.settings.get("reduced_motion", false):
		return
	var base_s := scale
	scale = Vector3(base_s.x * squash.x, base_s.y * squash.y, base_s.z * squash.z)
	var tw := create_tween()
	tw.tween_property(self, "scale", base_s, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _spawn_burst(color: Color, count: int, radius: float, speed: float) -> void:
	if Game.settings.get("reduced_motion", false):
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	var origin := global_position
	var mat := MeshFactory.material(color, 0.45, 0.0)
	for i in count:
		var shard := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3.ONE * radius
		shard.mesh = sm
		shard.material_override = mat
		shard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(shard)
		shard.global_position = origin + Vector3(randf_range(-0.02, 0.02), 0.02, randf_range(-0.02, 0.02))
		var vel := Vector3(randf_range(-1.0, 1.0), randf_range(0.6, 1.5), randf_range(-1.0, 1.0)).normalized() * speed
		var target := shard.global_position + vel * 0.28 + Vector3(0, -0.35, 0)
		var tw := shard.create_tween().set_parallel(true)
		tw.tween_property(shard, "global_position:x", target.x, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "global_position:z", target.z, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "global_position:y", origin.y + 0.14, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(shard, "global_position:y", target.y, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(shard, "scale", Vector3.ZERO, 0.22)
		tw.chain().tween_callback(shard.queue_free)


func break_it() -> void:
	if _broken:
		return
	_broken = true
	Audio.play("crack", 1.3, -8.0)
	_spawn_burst(Color("e6a94e"), 14, 0.015, 1.7)
	var flash := MeshFactory.sphere(self, 0.058, Vector3.ZERO, Color("fff6e0"), "BreakFlash", 12, false)
	var mat := MeshFactory.material(Color("fff6e0"), 0.25, 0.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color("ffe2a5")
	mat.emission_energy_multiplier = 0.9
	flash.material_override = mat
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3(1.0, 2.6, 1.0), 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(flash.queue_free)
	queue_free()


func refresh() -> void:
	if _opening == null or data == null:
		return
	var opened := data.state != PuriData.State.EMPTY
	_opening.visible = opened
	_potato.visible = opened and data.has_ingredient("potato")
	_chickpea.visible = opened and data.has_ingredient("chickpea")
	_onion.visible = opened and data.has_ingredient("onion")
	_coriander.visible = opened and data.has_ingredient("coriander")
	_masala.visible = opened and data.has_ingredient("masala")
	_pani.visible = opened and data.pani != "none"
	_chutney.visible = opened and data.sweet
	if data.pani == "garlic":
		_pani.material_override = MeshFactory.material(Color("b59b3c"), 0.12, 0.1)
	else:
		_pani.material_override = MeshFactory.material(Color("528b30"), 0.12, 0.1)
