class_name PuriBoxStation
extends Interactable
## The puri storage tin: take a shell, then crack it open.

var _stack: Node3D


func _ready() -> void:
	super._ready()
	station_label = "Puri tin"
	_build()
	add_hit_box(Vector3(0.42, 0.34, 0.36), Vector3(0, 0.14, 0))


func _build() -> void:
	MeshFactory.box(self, Vector3(0.4, 0.2, 0.32), Vector3(0, 0.1, 0), Color("d9d2c4"), "Tin")
	MeshFactory.box(self, Vector3(0.42, 0.03, 0.34), Vector3(0, 0.215, 0), Color("b8bcc0"), "Lid")
	MeshFactory.signboard(self, "PURI", Vector3(0, 0.17, 0.17), 0.22, GameData.C_ORANGE, Color.WHITE, 0.1)
	_stack = Node3D.new()
	_stack.name = "PuriStack"
	add_child(_stack)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		var p := MeshFactory.sphere(_stack, 0.05, Vector3(cos(angle) * 0.1, 0.235, sin(angle) * 0.08), GameData.C_PURI, "Shell", 10, false)
		p.scale = Vector3(1.0, 0.4, 1.0)


func get_prompt(player: Node) -> String:
	var held = player.get("held_item")
	if held == null:
		if Inventory.has("puri"):
			return "Take a puri shell"
		return "Out of puri shells - restock in Inventory"
	if held.data.state == PuriData.State.EMPTY:
		return "Crack the puri open"
	return "Hands full - finish this puri first"


func interact(player: Node) -> void:
	var held = player.get("held_item")
	if held == null:
		if not Inventory.consume("puri"):
			Events.toast.emit("Out of puri shells. Restock in the Inventory panel.", "bad")
			Audio.play("bad", 1.0, -10.0)
			return
		var item := PuriItem.create()
		player.call("carry_item", item)
		Audio.play("scoop", 1.1, -9.0)
		return
	if held.data.state == PuriData.State.EMPTY:
		held.data.open()
		held.refresh()
		Audio.play("crack", 1.0, -7.0)
		return
	Events.toast.emit("This puri is already open. Add filling or place it on the plate.", "info")
