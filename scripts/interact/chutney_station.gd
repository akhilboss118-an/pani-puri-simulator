class_name ChutneyStation
extends Interactable
## Sweet tamarind chutney jar. Optional, but customers notice when it is wrong.

var _spoon: Node3D


func _ready() -> void:
	super._ready()
	station_label = "Sweet chutney"
	_build()
	add_hit_box(Vector3(0.3, 0.28, 0.3), Vector3(0, 0.14, 0))


func _build() -> void:
	var ceramic := MeshFactory.material(Color("cbb48e"), 0.35, 0.05)
	var chutney_mat := MeshFactory.material(Color("5c2612"), 0.12, 0.08)
	var wood := MeshFactory.material(Color("7b5233"), 0.72, 0.02)

	MeshFactory.cylinder(self, 0.115, 0.18, Vector3(0, 0.09, 0), Color("cbb48e"), "Jar", 16).material_override = ceramic
	MeshFactory.cylinder(self, 0.106, 0.022, Vector3(0, 0.175, 0), Color("5c2612"), "Chutney", 16, false).material_override = chutney_mat
	MeshFactory.torus(self, 0.105, 0.125, Vector3(0, 0.184, 0), Color("7b5233"), "Rim", 0.55, 0.0).material_override = wood

	_spoon = Node3D.new()
	_spoon.position = Vector3(0.04, 0.19, 0.0)
	add_child(_spoon)
	var handle := MeshFactory.box(_spoon, Vector3(0.012, 0.008, 0.18), Vector3(0.02, 0.03, 0.02), Color("8c5f3b"), "Spoon", 0.3, false)
	handle.material_override = wood
	handle.rotation.x = -0.35

	MeshFactory.signboard(self, "SWEET", Vector3(0, 0.04, 0.155), 0.18, Color("8e2c22"), Color("fff4dc"), 0.072, 0.0, false)


func _blocked_reason(player: Node) -> String:
	var held = player.get("held_item")
	if held == null:
		return "Pick up a puri first"
	var data: PuriData = held.data
	if data.state == PuriData.State.EMPTY:
		return "Crack the puri open first"
	if data.sweet:
		return "Already has sweet chutney"
	if not Inventory.has("chutney_sweet"):
		return "Chutney is empty - restock"
	return ""


func get_prompt(player: Node) -> String:
	var reason := _blocked_reason(player)
	if reason != "":
		return reason
	return "Add sweet chutney"


func can_interact(player: Node) -> bool:
	return _blocked_reason(player) == ""


func interact(player: Node) -> void:
	var reason := _blocked_reason(player)
	if reason != "":
		Events.toast.emit(reason + ".", "info")
		Audio.play("bad", 1.0, -12.0)
		return
	if not Inventory.consume("chutney_sweet"):
		return
	var held = player.get("held_item")
	held.data.add_chutney()
	held.refresh()
	if player.has_method("play_hand_action"):
		player.call("play_hand_action", "scoop")
	if held.has_method("play_fill_fx"):
		held.call("play_fill_fx", Color("6b2d14"))
	if _spoon != null and not Game.settings.get("reduced_motion", false):
		var tw := create_tween()
		tw.tween_property(_spoon, "position:y", 0.23, 0.09)
		tw.tween_property(_spoon, "position:y", 0.19, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Audio.play("scoop", 0.8, -8.0)
