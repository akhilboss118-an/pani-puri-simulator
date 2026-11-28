class_name TrashStation
extends Interactable
## Waste bin using the Poly-by-Google Garbage prop. Throwing a puri away is
## always allowed, and shows up in the daily report.

const GARBAGE_MODEL := "res://assets/environment/props/garbage_bin.glb"

var _visual: Node3D
var _lid: MeshInstance3D


func _ready() -> void:
	super._ready()
	station_label = "Waste bin"
	_build()
	add_hit_box(Vector3(0.55, 0.85, 0.55), Vector3(0, 0.42, 0))


func _build() -> void:
	var model := EnvironmentLoader.spawn_prop(self, GARBAGE_MODEL, Vector3(0, 0.025, 0), -0.35, 0.27, true)
	if model != null:
		_visual = model
		var badge := MeshFactory.signboard(model, "WASTE", Vector3(0, 1.48, 1.32), 1.25, Color("263329"), Color("f3ead3"), 0.42, 0.0)
		if badge != null:
			badge.scale = Vector3.ONE
	else:
		MeshFactory.cylinder(self, 0.18, 0.55, Vector3(0, 0.275, 0), Color("4f6b52"), "Bin", 12)
		_lid = MeshFactory.cylinder(self, 0.2, 0.05, Vector3(0, 0.57, 0), Color("3e5541"), "Lid", 12)
		MeshFactory.signboard(self, "WASTE", Vector3(0, 0.34, 0.19), 0.26, Color("2f3f33"), Color("e8e0cf"), 0.1)


func get_prompt(player: Node) -> String:
	var held = player.get("held_item")
	if held == null:
		return "Waste bin - nothing in hand"
	return "Throw away this puri"


func can_interact(player: Node) -> bool:
	return player.get("held_item") != null


func interact(player: Node) -> void:
	var item: PuriItem = player.call("take_held_item")
	if item == null:
		return
	item.break_it()
	Orders.register_waste(1)
	Audio.play("waste", 1.0, -6.0)
	Events.toast.emit("Puri wasted. It will show in the daily report.", "bad")
	if _visual != null:
		var tween := create_tween()
		tween.tween_property(_visual, "position:y", 0.08, 0.10)
		tween.parallel().tween_property(_visual, "rotation:z", 0.09, 0.10)
		tween.tween_property(_visual, "position:y", 0.025, 0.14)
		tween.parallel().tween_property(_visual, "rotation:z", 0.0, 0.14)
	elif _lid != null:
		_lid.position.y = 0.62
		var tween := create_tween()
		tween.tween_property(_lid, "position:y", 0.57, 0.18)
