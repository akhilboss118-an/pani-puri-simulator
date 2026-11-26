class_name Pedestrian
extends Node3D
## Cheap background walker. No AI, no collision, no order - just enough motion
## to make the street feel alive on a low-end device.

var point_a: Vector3 = Vector3(-20, 0, -8)
var point_b: Vector3 = Vector3(20, 0, -8)
var speed: float = 1.0
var _target: Vector3
var _phase: float = 0.0
var _body: Node3D
var _legs: Array[Node3D] = []


func _ready() -> void:
	_build()
	_target = point_b
	global_position = point_a


func _build() -> void:
	var skin: Color = GameData.C_SKIN[randi() % GameData.C_SKIN.size()]
	var cloth: Color = GameData.C_CLOTH[randi() % GameData.C_CLOTH.size()]
	_body = Node3D.new()
	add_child(_body)
	MeshFactory.box(_body, Vector3(0.3, 0.5, 0.2), Vector3(0, 1.05, 0), cloth, "Torso")
	MeshFactory.sphere(_body, 0.11, Vector3(0, 1.45, 0), skin, "Head", 10)
	MeshFactory.sphere(_body, 0.115, Vector3(0, 1.5, 0.01), Color("241812"), "Hair", 10, false)
	for i in 2:
		var leg := Node3D.new()
		leg.position = Vector3(-0.08 + i * 0.16, 0.75, 0)
		_body.add_child(leg)
		MeshFactory.box(leg, Vector3(0.1, 0.7, 0.12), Vector3(0, -0.35, 0), cloth.darkened(0.2), "Leg", 0.0, false)
		_legs.append(leg)


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	var flat_target := Vector3(_target.x, global_position.y, _target.z)
	if global_position.distance_to(flat_target) < 0.4:
		_target = point_a if _target == point_b else point_b
	var direction := (flat_target - global_position).normalized()
	global_position += direction * speed * delta
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	_phase += delta * 7.0
	var swing := sin(_phase) * 0.45
	for i in _legs.size():
		_legs[i].rotation.x = swing if i == 0 else -swing
	_body.position.y = absf(sin(_phase)) * 0.02
