class_name ChutneyStation
extends Interactable
## Sweet tamarind chutney jar. Optional, but customers notice when it is wrong.


func _ready() -> void:
	super._ready()
	station_label = "Sweet chutney"
	_build()
	add_hit_box(Vector3(0.26, 0.28, 0.26), Vector3(0, 0.14, 0))


func _build() -> void:
	MeshFactory.cylinder(self, 0.11, 0.18, Vector3(0, 0.09, 0), Color("c9b28a"), "Jar", 14)
	MeshFactory.cylinder(self, 0.105, 0.02, Vector3(0, 0.18, 0), GameData.C_CHUTNEY, "Chutney", 14, false)
	MeshFactory.cylinder(self, 0.115, 0.02, Vector3(0, 0.19, 0), Color("8a6a4a"), "Rim", 14, false)
	MeshFactory.signboard(self, "SWEET", Vector3(0, 0.02, 0.15), 0.18, GameData.C_RED, Color.WHITE, 0.08)


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
	Audio.play("scoop", 0.8, -8.0)
