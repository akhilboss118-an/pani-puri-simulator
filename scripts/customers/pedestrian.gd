class_name Pedestrian
extends Node3D
## Background street walker using one of the two animated NPC GLBs.

var point_a: Vector3 = Vector3(-20, 0, -8)
var point_b: Vector3 = Vector3(20, 0, -8)
var speed: float = 1.0
var model_index: int = 1
var _target: Vector3
var _body: Node3D
var _anim_player: AnimationPlayer


func _ready() -> void:
	_build()
	_target = point_b
	global_position = point_a


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	var packed := Customer.load_model_scene(model_index)
	if packed == null:
		return
	var instance := packed.instantiate() as Node3D
	if instance == null:
		return
	instance.name = "ImportedModel"
	_body.add_child(instance)
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	var players := instance.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim_player = players[0] as AnimationPlayer
		Customer.configure_model_animations(_anim_player)
		if _anim_player.has_animation("walk"):
			_anim_player.speed_scale = clampf(speed / 1.15, 0.85, 1.35)
			_anim_player.play("walk")
			var anim := _anim_player.get_animation("walk")
			if anim != null and anim.length > 0.05:
				_anim_player.seek(randf_range(0.0, anim.length), true)


func _process(delta: float) -> void:
	if Game.state != Game.State.PLAYING:
		return
	if _anim_player != null and _anim_player.has_animation("walk") and not _anim_player.is_playing():
		_anim_player.play("walk")
	var flat_target := Vector3(_target.x, global_position.y, _target.z)
	if global_position.distance_to(flat_target) < 0.4:
		_target = point_a if _target == point_b else point_b
		flat_target = Vector3(_target.x, global_position.y, _target.z)
	var direction := (flat_target - global_position).normalized()
	global_position += direction * speed * delta
	if direction.length_squared() > 0.0025:
		var target_basis := Basis.looking_at(direction, Vector3.UP)
		_body.basis = _body.basis.orthonormalized().slerp(target_basis, minf(1.0, delta * 8.0))
