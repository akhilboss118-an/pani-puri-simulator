class_name Interactable
extends StaticBody3D
## Base class for anything the player can look at and use. Interaction is
## discovered by the player's raycast, never hardcoded per object.

var station_label: String = "Station"
var _focused: bool = false
var _focus_tween: Tween


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("interactable")


func set_focused(focused: bool) -> void:
	if _focused == focused:
		return
	_focused = focused
	if Game.settings.get("reduced_motion", false):
		return
	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()
	var target_scale := Vector3(1.045, 1.045, 1.045) if focused else Vector3.ONE
	_focus_tween = create_tween()
	_focus_tween.tween_property(self, "scale", target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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
