class_name BowlStation
extends Interactable
## A steel bowl of filling. One script serves potato, chickpeas, onion,
## coriander and masala by configuration instead of five copies.

var ingredient_id: String = "potato"
var max_per_puri: int = 2
var bowl_radius: float = 0.1
var _spoon: Node3D
var _visual: Node3D


func configure(id: String, per_puri: int = 2, radius: float = 0.1) -> void:
	ingredient_id = id
	max_per_puri = per_puri
	bowl_radius = radius


func _ready() -> void:
	super._ready()
	var def := GameData.ingredient(ingredient_id)
	station_label = def.display_name if def else ingredient_id
	_build()
	add_hit_box(Vector3(bowl_radius * 2.2, 0.22, bowl_radius * 2.2), Vector3(0, 0.1, 0))


func _build() -> void:
	_visual = Node3D.new()
	_visual.name = "BowlVisual"
	add_child(_visual)

	var def := GameData.ingredient(ingredient_id)
	var color: Color = def.color if def else Color.WHITE
	var steel := MeshFactory.material(Color("cdd3d8"), 0.24, 0.85)

	var bowl_h := 0.125 if bowl_radius > 0.11 else 0.088
	var bowl := MeshFactory.cylinder(_visual, bowl_radius, bowl_h, Vector3(0, bowl_h * 0.5, 0), GameData.C_STEEL, "Bowl", 20)
	bowl.material_override = steel
	var rim := MeshFactory.torus(_visual, bowl_radius - 0.008, bowl_radius + 0.009, Vector3(0, bowl_h, 0), Color("dde2e6"), "Rim", 0.2, 0.88)
	rim.material_override = steel

	var mound := MeshFactory.sphere(_visual, bowl_radius * 0.86, Vector3(0, bowl_h - 0.014, 0), color, "Contents", 12, false)
	mound.scale = Vector3(1.0, 0.42, 1.0)
	if ingredient_id == "potato":
		for i in 7:
			var a := TAU * float(i) / 7.0
			var r := bowl_radius * (0.45 if i % 2 == 0 else 0.22)
			MeshFactory.sphere(_visual, 0.018, Vector3(cos(a) * r, bowl_h + 0.015, sin(a) * r), color.lightened(0.08), "Chunk", 6, false)
		for i in 5:
			var a := TAU * float(i) / 5.0
			MeshFactory.sphere(_visual, 0.011, Vector3(cos(a) * bowl_radius * 0.45, bowl_h + 0.025, sin(a) * bowl_radius * 0.45), GameData.C_CORIANDER, "Herb", 6, false)
	elif ingredient_id == "onion":
		for i in 5:
			MeshFactory.box(_visual, Vector3(0.014, 0.007, 0.01), Vector3(-0.035 + i * 0.018, bowl_h + 0.01, 0.012 * ((i % 3) - 1)), color.lightened(0.12), "Bit", 0.4 * i, false)
	elif ingredient_id == "chickpea":
		for i in 10:
			var a := TAU * float(i) / 10.0
			var r := bowl_radius * (0.52 if i % 2 == 0 else 0.25)
			MeshFactory.sphere(_visual, 0.012, Vector3(cos(a) * r, bowl_h + 0.012, sin(a) * r), color.lightened(0.1), "Pea", 6, false)
	elif ingredient_id == "coriander":
		for i in 6:
			var a := TAU * float(i) / 6.0
			MeshFactory.box(_visual, Vector3(0.014, 0.004, 0.012), Vector3(cos(a) * bowl_radius * 0.42, bowl_h + 0.01, sin(a) * bowl_radius * 0.42), color.lightened(0.14), "Leaf", a, false)

	# Interactive stainless steel serving spoon resting in the bowl
	_spoon = Node3D.new()
	_spoon.position = Vector3(bowl_radius * 0.4, bowl_h + 0.016, 0.0)
	_visual.add_child(_spoon)
	var handle := MeshFactory.box(_spoon, Vector3(0.011, 0.008, 0.15), Vector3(0.025, 0.022, 0.02), Color("d8dde2"), "Spoon", 0.35, false)
	handle.material_override = steel
	handle.rotation.x = -0.35
	var scoop := MeshFactory.sphere(_spoon, 0.016, Vector3(-0.005, -0.004, -0.045), Color("d8dde2"), "SpoonHead", 8, false)
	scoop.scale = Vector3(1.0, 0.4, 1.3)
	scoop.material_override = steel


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
	if player.has_method("play_hand_action"):
		player.call("play_hand_action", "scoop")
	if held.has_method("play_fill_fx"):
		var def := GameData.ingredient(ingredient_id)
		held.call("play_fill_fx", def.color if def else Color.WHITE)
	_animate_spoon()
	Audio.play("scoop", randf_range(0.9, 1.15), -9.0)


func _animate_spoon() -> void:
	if _spoon == null or Game.settings.get("reduced_motion", false):
		return
	var base_y := 0.141 if bowl_radius > 0.11 else 0.104
	var tw := create_tween()
	tw.tween_property(_spoon, "position:y", base_y + 0.04, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_spoon, "rotation:x", -0.35, 0.09)
	tw.tween_property(_spoon, "position:y", base_y, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_spoon, "rotation:x", 0.0, 0.14)
