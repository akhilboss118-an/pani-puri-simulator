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
	var base := MeshFactory.sphere(self, 0.058, Vector3.ZERO, GameData.C_PURI, "Base", 12, false)
	base.scale = Vector3(1.0, 0.52, 1.0)

	_opening = MeshFactory.cylinder(self, 0.026, 0.006, Vector3(0, 0.027, 0), Color("8a5a2b"), "Opening", 12, false)
	_potato = MeshFactory.sphere(self, 0.02, Vector3(0, 0.034, 0), GameData.C_POTATO, "Potato", 8, false)
	_potato.scale = Vector3(1.0, 0.6, 1.0)

	_chickpea = Node3D.new()
	_chickpea.name = "Chickpeas"
	add_child(_chickpea)
	for i in 3:
		var angle := TAU * float(i) / 3.0
		MeshFactory.sphere(_chickpea, 0.007, Vector3(cos(angle) * 0.016, 0.04, sin(angle) * 0.016), GameData.C_CHICKPEA, "Chickpea", 6, false)

	_onion = Node3D.new()
	_onion.name = "Onion"
	add_child(_onion)
	for i in 3:
		MeshFactory.box(_onion, Vector3(0.012, 0.004, 0.006), Vector3(-0.012 + i * 0.012, 0.043, 0.01), GameData.C_ONION, "OnionBit", 0.4 * i, false)

	_coriander = Node3D.new()
	_coriander.name = "Coriander"
	add_child(_coriander)
	for i in 4:
		MeshFactory.box(_coriander, Vector3(0.008, 0.003, 0.008), Vector3(cos(i * 1.7) * 0.02, 0.046, sin(i * 1.7) * 0.02), GameData.C_CORIANDER, "Leaf", 0.7 * i, false)

	_masala = MeshFactory.cylinder(self, 0.023, 0.003, Vector3(0, 0.045, 0), GameData.C_MASALA, "Masala", 10, false)
	_pani = MeshFactory.cylinder(self, 0.02, 0.005, Vector3(0, 0.03, 0), Color("6f9a3d"), "Pani", 10, false)
	_chutney = MeshFactory.box(self, Vector3(0.03, 0.004, 0.014), Vector3(0, 0.048, 0), GameData.C_CHUTNEY, "Chutney", 0.5, false)


func break_it() -> void:
	if _broken:
		return
	_broken = true
	Audio.play("crack", 1.3, -8.0)
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
		_pani.material_override = MeshFactory.material(Color("a8a04a"))
	else:
		_pani.material_override = MeshFactory.material(Color("6f9a3d"))
