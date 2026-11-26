class_name BowlStation
extends Interactable
## A steel bowl of filling. One script serves potato, chickpeas, onion,
## coriander and masala by configuration instead of five copies.

var ingredient_id: String = "potato"
var max_per_puri: int = 2
var bowl_radius: float = 0.1


func configure(id: String, per_puri: int = 2, radius: float = 0.1) -> void:
	ingredient_id = id
	max_per_puri = per_puri
	bowl_radius = radius


func _ready() -> void:
	super._ready()
	var def := GameData.ingredient(ingredient_id)
	station_label = def.display_name if def else ingredient_id
	_build()
	add_hit_box(Vector3(bowl_radius * 2.2, 0.2, bowl_radius * 2.2), Vector3(0, 0.1, 0))


func _build() -> void:
	var def := GameData.ingredient(ingredient_id)
	var color: Color = def.color if def else Color.WHITE
	MeshFactory.cylinder(self, bowl_radius, 0.075, Vector3(0, 0.037, 0), GameData.C_STEEL, "Bowl", 14)
	MeshFactory.cylinder(self, bowl_radius * 0.86, 0.02, Vector3(0, 0.075, 0), color, "Contents", 14, false)
	if ingredient_id == "onion":
		for i in 4:
			MeshFactory.box(self, Vector3(0.014, 0.006, 0.01), Vector3(-0.03 + i * 0.02, 0.085, 0.01 * (i % 2)), color, "Bit", 0.3 * i, false)
	elif ingredient_id == "chickpea":
		for i in 5:
			var a := TAU * float(i) / 5.0
			MeshFactory.sphere(self, 0.009, Vector3(cos(a) * 0.045, 0.085, sin(a) * 0.045), color, "Pea", 6, false)
	# small serving spoon leaning in the bowl
	MeshFactory.box(self, Vector3(0.012, 0.012, 0.16), Vector3(bowl_radius * 0.7, 0.1, 0), Color("cfd3d6"), "Spoon", 0.35, false)


func _blocked_reason(player: Node) -> String:
	var held = player.get("held_item")
	if held == null:
		return "Pick up a puri first"
	var data: PuriData = held.data
	if data.state == PuriData.State.EMPTY:
		return "Crack the puri open first"
	if data.pani != "none":
		return "This puri is already dipped in pani"
	if int(data.contents.get(ingredient_id, 0)) >= max_per_puri:
		var def := GameData.ingredient(ingredient_id)
		return "Enough %s already" % (def.display_name.to_lower() if def else ingredient_id)
	if not Inventory.has(ingredient_id):
		var def2 := GameData.ingredient(ingredient_id)
		return "%s is empty - restock" % (def2.display_name if def2 else ingredient_id)
	return ""


func get_prompt(player: Node) -> String:
	var reason := _blocked_reason(player)
	if reason != "":
		return reason
	var def := GameData.ingredient(ingredient_id)
	return "Add " + def.display_name.to_lower()


func can_interact(player: Node) -> bool:
	return _blocked_reason(player) == ""


func interact(player: Node) -> void:
	var reason := _blocked_reason(player)
	if reason != "":
		Events.toast.emit(reason + ".", "info")
		Audio.play("bad", 1.0, -12.0)
		return
	if not Inventory.consume(ingredient_id):
		Events.toast.emit("Out of stock. Open Inventory to restock.", "bad")
		return
	var held = player.get("held_item")
	held.data.add_ingredient(ingredient_id, max_per_puri)
	held.refresh()
	Audio.play("scoop", randf_range(0.9, 1.15), -9.0)
