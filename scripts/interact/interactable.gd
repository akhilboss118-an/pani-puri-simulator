class_name Interactable
extends StaticBody3D
## Base class for anything the player can look at and use. Interaction is
## discovered by the player's raycast, never hardcoded per object.

var station_label: String = "Station"


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("interactable")


## Short action text shown in the HUD. Return "" to hide the prompt.
func get_prompt(_player: Node) -> String:
	return "Use " + station_label


func can_interact(_player: Node) -> bool:
	return true


func interact(_player: Node) -> void:
	pass


func add_hit_box(size: Vector3, offset: Vector3 = Vector3.ZERO) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = offset
	add_child(shape)
