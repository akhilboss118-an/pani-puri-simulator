class_name TrashStation
extends Interactable
## Waste bin. Throwing a puri away is always allowed, but it shows up in the
## daily report so careless preparation has a cost.

var _lid: MeshInstance3D


func _ready() -> void:
	super._ready()
	station_label = "Waste bin"
	_build()
	add_hit_box(Vector3(0.4, 0.7, 0.4), Vector3(0, 0.35, 0))


func _build() -> void:
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
	if _lid:
		_lid.position.y = 0.62
		var tween := create_tween()
		tween.tween_property(_lid, "position:y", 0.57, 0.18)
