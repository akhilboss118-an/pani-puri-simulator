class_name PaniStation
extends Interactable
## A pot of pani. Dipping is the step that turns a filled puri into a ready one.

var flavour: String = "mint"
var _liquid: MeshInstance3D


func configure(pani_flavour: String) -> void:
	flavour = pani_flavour


func set_enabled(value: bool) -> void:
	visible = value
	collision_layer = 4 if value else 0


func _ready() -> void:
	super._ready()
	station_label = "Garlic pani pot" if flavour == "garlic" else "Mint pani pot"
	_build()
	add_hit_box(Vector3(0.34, 0.3, 0.34), Vector3(0, 0.15, 0))


func _build() -> void:
	var liquid_color := Color("8fae4a") if flavour == "mint" else Color("b3a34c")
	MeshFactory.cylinder(self, 0.14, 0.2, Vector3(0, 0.1, 0), GameData.C_STEEL, "Pot", 16)
	MeshFactory.cylinder(self, 0.132, 0.02, Vector3(0, 0.2, 0), liquid_color, "Pani", 16, false)
	MeshFactory.cylinder(self, 0.145, 0.02, Vector3(0, 0.205, 0), Color("a8adb2"), "Rim", 16, false)
	# ladle
	MeshFactory.box(self, Vector3(0.015, 0.015, 0.26), Vector3(0.1, 0.26, 0.02), Color("c8ccd0"), "Ladle", 0.45, false)
	MeshFactory.sphere(self, 0.03, Vector3(0.16, 0.24, 0.1), Color("c8ccd0"), "LadleBowl", 8, false)
	var label_text := "GARLIC" if flavour == "garlic" else "PANI"
	MeshFactory.signboard(self, label_text, Vector3(0, 0.02, 0.19), 0.2, GameData.C_TEAL, Color.WHITE, 0.09)


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
	Audio.play("pour", randf_range(0.95, 1.05), -7.0)
