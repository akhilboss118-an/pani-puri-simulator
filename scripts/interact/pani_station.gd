class_name PaniStation
extends Interactable
## A pot of pani. Dipping is the step that turns a filled puri into a ready one.

var flavour: String = "mint"
var _liquid: MeshInstance3D
var _ladle: Node3D
var _ripple: MeshInstance3D
var _liquid_color: Color = Color("5e9434")


func configure(pani_flavour: String) -> void:
	flavour = pani_flavour


func set_enabled(value: bool) -> void:
	visible = value
	collision_layer = 4 if value else 0


func _ready() -> void:
	super._ready()
	station_label = "Garlic pani pot" if flavour == "garlic" else "Mint pani pot"
	_build()
	add_hit_box(Vector3(0.38, 0.32, 0.38), Vector3(0, 0.15, 0))


func _build() -> void:
	_liquid_color = Color("528b30") if flavour == "mint" else Color("b59b3c")
	var steel := MeshFactory.material(Color("cfd5da"), 0.22, 0.85)
	var copper := MeshFactory.material(Color("c97b42"), 0.28, 0.78)

	# Stainless steel degchi with copper base band
	var pot := MeshFactory.cylinder(self, 0.155, 0.21, Vector3(0, 0.105, 0), GameData.C_STEEL, "Pot", 20)
	pot.material_override = steel
	var base_band := MeshFactory.cylinder(self, 0.157, 0.045, Vector3(0, 0.025, 0), Color("c97b42"), "CopperBase", 20, false)
	base_band.material_override = copper
	var rim := MeshFactory.torus(self, 0.145, 0.166, Vector3(0, 0.21, 0), Color("dfe4e8"), "Rim", 0.18, 0.9)
	rim.material_override = steel

	# Glossy liquid surface + floating herb/boondi specks
	_liquid = MeshFactory.cylinder(self, 0.145, 0.014, Vector3(0, 0.195, 0), _liquid_color, "Pani", 20, false)
	var liq_mat := MeshFactory.material(_liquid_color, 0.1, 0.12)
	_liquid.material_override = liq_mat
	for i in 7:
		var a := TAU * float(i) / 7.0
		var r := 0.055 if i % 2 == 0 else 0.095
		var speck_col := Color("84c254") if flavour == "mint" else Color("e0ba58")
		MeshFactory.sphere(self, 0.008, Vector3(cos(a) * r, 0.203, sin(a) * r), speck_col, "Speck", 6, false)

	# Expanding ripple ring (hidden until dip)
	_ripple = MeshFactory.torus(self, 0.03, 0.036, Vector3(0, 0.204, 0), _liquid_color.lightened(0.4), "Ripple", 0.2, 0.0)
	_ripple.visible = false

	# Interactive ladle resting across the rim
	_ladle = Node3D.new()
	_ladle.position = Vector3(0.08, 0.22, 0.02)
	add_child(_ladle)
	var handle := MeshFactory.box(_ladle, Vector3(0.014, 0.012, 0.26), Vector3(0.03, 0.04, 0.02), Color("d8dde2"), "Ladle", 0.42, false)
	handle.material_override = steel
	handle.rotation.x = -0.32
	var cup := MeshFactory.sphere(_ladle, 0.032, Vector3(-0.02, -0.005, -0.07), Color("d8dde2"), "LadleBowl", 10, false)
	cup.scale = Vector3(1.0, 0.55, 1.0)
	cup.material_override = steel

	var label_text := "GARLIC" if flavour == "garlic" else "MINT PANI"
	MeshFactory.signboard(self, label_text, Vector3(0, 0.04, 0.195), 0.23, Color("1f5e56") if flavour == "mint" else Color("7a5b22"), Color("fff4dc"), 0.075, 0.0, false)


func _blocked_reason(player: Node) -> String:
	var held = player.get("held_item")
	if held == null:
		return "Pick up a puri first"
	var data: PuriData = held.data
	if data.state == PuriData.State.EMPTY:
		return "Crack the puri open first"
	if not data.has_ingredient("potato"):
		return "Add potato filling first"
	if data.pani != "none":
		return "Already dipped"
	if not Inventory.has("pani_mint"):
		return "Pani is empty - restock"
	return ""


func get_prompt(player: Node) -> String:
	var reason := _blocked_reason(player)
	if reason != "":
		return reason
	return "Dip in " + ("garlic" if flavour == "garlic" else "mint") + " pani"


func can_interact(player: Node) -> bool:
	return _blocked_reason(player) == ""


func interact(player: Node) -> void:
	var reason := _blocked_reason(player)
	if reason != "":
		Events.toast.emit(reason + ".", "info")
		Audio.play("bad", 1.0, -12.0)
		return
	if not Inventory.consume("pani_mint"):
		Events.toast.emit("Out of pani. Restock in Inventory.", "bad")
		return
	var held = player.get("held_item")
	held.data.add_pani(flavour)
	held.refresh()
	if player.has_method("play_hand_action"):
		player.call("play_hand_action", "dip")
	if held.has_method("play_dip_fx"):
		held.call("play_dip_fx", _liquid_color)
	_animate_dip()
	Audio.play("pour", randf_range(0.95, 1.05), -7.0)


func _animate_dip() -> void:
	if Game.settings.get("reduced_motion", false):
		return
	if _ladle != null:
		var tw := create_tween()
		tw.tween_property(_ladle, "position:y", 0.175, 0.08)
		tw.tween_property(_ladle, "position:y", 0.255, 0.12)
		tw.tween_property(_ladle, "position:y", 0.22, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if _ripple != null:
		_ripple.visible = true
		_ripple.scale = Vector3(0.4, 1.0, 0.4)
		var rtw := create_tween()
		rtw.tween_property(_ripple, "scale", Vector3(3.4, 1.0, 3.4), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		rtw.tween_callback(func(): _ripple.visible = false)
