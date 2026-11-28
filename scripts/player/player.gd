class_name Player
extends CharacterBody3D
## First-person player: movement, look, and a camera-centred interaction ray.
## Touch input feeds the same variables as mouse and keyboard so both builds
## share one controller.

const WALK_SPEED := 3.2
const SPRINT_SPEED := 4.8
const ACCELERATION := 13.0
const GRAVITY := 22.0
const INTERACT_RANGE := 2.85
const BASE_HAND_POS := Vector3(-0.18, -0.22, -0.40)

var held_item: PuriItem = null
var camera: Camera3D
var hand_anchor: Node3D
var _hand_rig: Node3D
var _right_hand_rig: Node3D
var _hand_action_offset: Vector3 = Vector3.ZERO
var _hand_action_rot: Vector3 = Vector3.ZERO
var _hand_tween: Tween

var mobile_move := Vector2.ZERO
var _look_accum := Vector2.ZERO
var _look_sway := Vector2.ZERO
var _target: Interactable = null
var _last_prompt := ""
var _bob := 0.0
var _active := false
var _base_camera_y := 1.62
var _base_fov := 72.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_build()
	add_to_group("player")


func _build() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	shape.shape = capsule
	shape.position = Vector3(0, 0.85, 0)
	add_child(shape)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, _base_camera_y, 0)
	camera.fov = _base_fov
	camera.near = 0.05
	camera.current = true
	add_child(camera)

	hand_anchor = Node3D.new()
	hand_anchor.name = "HandAnchor"
	hand_anchor.position = BASE_HAND_POS
	camera.add_child(hand_anchor)

	_build_hand_rig()


func _build_hand_rig() -> void:
	_hand_rig = Node3D.new()
	_hand_rig.name = "VendorHand"
	hand_anchor.add_child(_hand_rig)
	var skin := MeshFactory.material(Color("b67a48"), 0.72, 0.0)
	var sleeve := MeshFactory.material(Color("c94f4f"), 0.85, 0.0)
	# Subtle forearm + palm + curled thumb/fingers cradling the puri from below
	var arm := MeshFactory.box(_hand_rig, Vector3(0.068, 0.058, 0.24), Vector3(0.05, -0.075, 0.14), Color("b67a48"), "Forearm", 0.0, false)
	arm.material_override = skin
	arm.rotation = Vector3(-0.22, -0.25, 0.1)
	var cuff := MeshFactory.box(_hand_rig, Vector3(0.078, 0.068, 0.08), Vector3(0.078, -0.095, 0.23), Color("c94f4f"), "Sleeve", 0.0, false)
	cuff.material_override = sleeve
	cuff.rotation = Vector3(-0.22, -0.25, 0.1)
	var palm := MeshFactory.box(_hand_rig, Vector3(0.072, 0.026, 0.078), Vector3(0.0, -0.044, 0.015), Color("b67a48"), "Palm", 0.0, false)
	palm.material_override = skin
	var thumb := MeshFactory.box(_hand_rig, Vector3(0.02, 0.018, 0.048), Vector3(-0.042, -0.022, -0.004), Color("b67a48"), "Thumb", 0.0, false)
	thumb.material_override = skin
	thumb.rotation = Vector3(0.25, -0.35, -0.35)
	for i in 3:
		var fx := -0.016 + i * 0.022
		var finger := MeshFactory.box(_hand_rig, Vector3(0.016, 0.016, 0.044), Vector3(fx, -0.03, -0.036), Color("b67a48"), "Finger", 0.0, false)
		finger.material_override = skin
		finger.rotation.x = 0.42
	_hand_rig.visible = false

	# Second helper hand on the right side of the camera (visible while preparing!)
	_right_hand_rig = Node3D.new()
	_right_hand_rig.name = "VendorRightHand"
	_right_hand_rig.position = Vector3(0.24, -0.25, -0.38)
	camera.add_child(_right_hand_rig)
	var r_arm := MeshFactory.box(_right_hand_rig, Vector3(0.068, 0.056, 0.22), Vector3(0.05, -0.06, 0.14), Color("b67a48"), "RForearm", 0.0, false)
	r_arm.material_override = skin
	r_arm.rotation = Vector3(-0.2, 0.25, -0.1)
	var r_palm := MeshFactory.box(_right_hand_rig, Vector3(0.068, 0.025, 0.072), Vector3(0.0, -0.03, 0.02), Color("b67a48"), "RPalm", 0.0, false)
	r_palm.material_override = skin
	for i in 3:
		var fx := -0.018 + i * 0.019
		var f := MeshFactory.box(_right_hand_rig, Vector3(0.015, 0.015, 0.042), Vector3(fx, -0.02, -0.028), Color("b67a48"), "RFinger", 0.0, false)
		f.material_override = skin
		f.rotation.x = 0.35
	_right_hand_rig.visible = false


func set_active(value: bool) -> void:
	_active = value
	if not value:
		_set_target(null)
		if not Game.is_mobile():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif not Game.is_mobile():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or Game.state != Game.State.PLAYING:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var sens: float = float(Game.settings.mouse_sensitivity) * 0.01
		add_look(event.relative * sens)
	elif event.is_action_pressed("interact"):
		_try_interact()


func add_look(amount: Vector2) -> void:
	_look_accum += amount


func _apply_look() -> void:
	if _look_accum == Vector2.ZERO:
		return
	var invert := -1.0 if Game.settings.invert_y else 1.0
	rotate_y(-_look_accum.x)
	camera.rotation.x = clampf(camera.rotation.x - _look_accum.y * invert, -1.35, 1.35)
	_look_sway.x = clampf(_look_sway.x - _look_accum.x * 0.32, -0.045, 0.045)
	_look_sway.y = clampf(_look_sway.y + _look_accum.y * invert * 0.25, -0.035, 0.035)
	_look_accum = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_apply_look()

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if mobile_move.length() > 0.05:
		input = mobile_move
	if input.length() > 1.0:
		input = input.normalized()

	var direction := (transform.basis * Vector3(input.x, 0.0, input.y))
	direction.y = 0.0
	var sprinting := Input.is_action_pressed("sprint") and mobile_move.length() < 0.05 and input.length() > 0.1
	var speed := SPRINT_SPEED if sprinting else WALK_SPEED

	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta * 10.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta * 10.0)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	# Smooth head bob, strafe roll, and sprint FOV kick (respects reduced_motion)
	var horizontal := Vector2(velocity.x, velocity.z).length()
	var reduced := bool(Game.settings.get("reduced_motion", false))
	if horizontal > 0.4 and not reduced:
		_bob += delta * horizontal * 2.5
		camera.position.y = _base_camera_y + sin(_bob) * 0.013
		camera.rotation.z = lerpf(camera.rotation.z, -input.x * 0.012, delta * 8.0)
	else:
		camera.position.y = lerpf(camera.position.y, _base_camera_y, delta * 7.0)
		camera.rotation.z = lerpf(camera.rotation.z, 0.0, delta * 8.0)

	var target_fov := _base_fov + (4.2 if sprinting and not reduced else 0.0)
	camera.fov = lerpf(camera.fov, target_fov, delta * 7.5)

	# Spring-damper carry sway + hand action offset
	_look_sway = _look_sway.lerp(Vector2.ZERO, delta * 10.0)
	if hand_anchor:
		var bob_sway := Vector3.ZERO
		if not reduced:
			bob_sway = Vector3(cos(_bob * 0.55) * 0.005, sin(_bob * 1.1) * 0.005, 0.0)
		var sway_vec := Vector3(_look_sway.x, _look_sway.y, 0.0)
		hand_anchor.position = BASE_HAND_POS + bob_sway + sway_vec + _hand_action_offset
		hand_anchor.rotation = Vector3(_look_sway.y * 1.4, -_look_sway.x * 1.6, 0.0) + _hand_action_rot

	_update_target()


func _update_target() -> void:
	if camera == null:
		return
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * INTERACT_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | 4, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var found: Interactable = null
	if not hit.is_empty():
		var collider = hit.get("collider")
		if collider is Interactable:
			found = collider
	_set_target(found)


func _set_target(target: Interactable) -> void:
	if _target != target:
		if _target != null and is_instance_valid(_target):
			_target.set_focused(false)
		_target = target
		if _target != null and is_instance_valid(_target):
			_target.set_focused(_target.can_interact(self))
	elif _target != null and is_instance_valid(_target):
		_target.set_focused(_target.can_interact(self))
	var prompt := ""
	if target != null:
		prompt = target.get_prompt(self)
	if prompt != _last_prompt:
		_last_prompt = prompt
		Events.prompt_changed.emit(prompt)


func has_valid_target() -> bool:
	return _target != null and is_instance_valid(_target) and _target.can_interact(self)


func play_hand_action(kind: String) -> void:
	if Game.settings.get("reduced_motion", false):
		return
	if _hand_tween and _hand_tween.is_valid():
		_hand_tween.kill()
	_hand_tween = create_tween()
	match kind:
		"take":
			_hand_action_offset = Vector3(0.0, -0.06, -0.09)
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"crack":
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3(-0.04, 0.04, -0.08), 0.06)
			_hand_tween.parallel().tween_property(self, "_hand_action_rot", Vector3(-0.25, 0.0, 0.15), 0.06)
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3(0.0, -0.03, 0.0), 0.06)
			_hand_tween.parallel().tween_property(self, "_hand_action_rot", Vector3.ZERO, 0.12)
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3.ZERO, 0.1)
		"scoop":
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3(-0.03, -0.04, -0.07), 0.08)
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"dip":
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3(0.0, -0.11, -0.1), 0.1)
			_hand_tween.parallel().tween_property(self, "_hand_action_rot", Vector3(0.28, 0.0, 0.0), 0.1)
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			_hand_tween.parallel().tween_property(self, "_hand_action_rot", Vector3.ZERO, 0.16)
		"place", "serve":
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3(0.0, 0.03, -0.1), 0.08)
			_hand_tween.tween_property(self, "_hand_action_offset", Vector3.ZERO, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _try_interact() -> void:
	if _target == null:
		return
	if not _target.can_interact(self):
		Events.toast.emit(_target.get_prompt(self) + ".", "info")
		Audio.play("bad", 1.0, -14.0)
		return
	_target.interact(self)
	_update_target()


func carry_item(item: PuriItem, from_world: bool = false) -> void:
	if held_item != null:
		return
	held_item = item
	if item.get_parent() == null:
		hand_anchor.add_child(item)
	else:
		item.reparent(hand_anchor)
	item.position = Vector3.ZERO
	item.rotation = Vector3(-0.42, 0.35, 0.0)
	item.scale = Vector3(1.55, 1.55, 1.55)
	if _hand_rig:
		_hand_rig.visible = true
	if _right_hand_rig:
		_right_hand_rig.visible = true
	Events.held_changed.emit(item.data.describe())
	if not from_world:
		Audio.play("click", 1.6, -18.0)


func take_held_item() -> PuriItem:
	var item := held_item
	held_item = null
	if _hand_rig:
		_hand_rig.visible = false
	if _right_hand_rig:
		_right_hand_rig.visible = false
	Events.held_changed.emit("")
	return item


func has_held_item() -> bool:
	return held_item != null


func try_interact() -> void:
	_try_interact()
