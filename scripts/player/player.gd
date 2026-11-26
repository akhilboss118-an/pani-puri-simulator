class_name Player
extends CharacterBody3D
## First-person player: movement, look, and a camera-centred interaction ray.
## Touch input feeds the same variables as mouse and keyboard so both builds
## share one controller.

const WALK_SPEED := 3.1
const SPRINT_SPEED := 4.6
const ACCELERATION := 12.0
const GRAVITY := 22.0
const INTERACT_RANGE := 2.7

var held_item: PuriItem = null
var camera: Camera3D
var hand_anchor: Node3D

var mobile_move := Vector2.ZERO
var _look_accum := Vector2.ZERO
var _target: Interactable = null
var _last_prompt := ""
var _bob := 0.0
var _active := false
var _base_camera_y := 1.62


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
	camera.fov = 72.0
	camera.near = 0.05
	camera.current = true
	add_child(camera)

	hand_anchor = Node3D.new()
	hand_anchor.name = "HandAnchor"
	hand_anchor.position = Vector3(0.26, -0.24, -0.42)
	camera.add_child(hand_anchor)


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
	var speed := WALK_SPEED
	if Input.is_action_pressed("sprint") and mobile_move.length() < 0.05:
		speed = SPRINT_SPEED

	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta * 10.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta * 10.0)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	move_and_slide()

	# Gentle head bob; disabled by the reduced-motion accessibility setting.
	var horizontal := Vector2(velocity.x, velocity.z).length()
	if horizontal > 0.4 and not Game.settings.reduced_motion:
		_bob += delta * horizontal * 2.4
		camera.position.y = _base_camera_y + sin(_bob) * 0.012
	else:
		camera.position.y = lerpf(camera.position.y, _base_camera_y, delta * 6.0)

	# The held puri sways a little so it feels hand-held, not glued.
	if hand_anchor and hand_anchor.get_child_count() > 0:
		var sway := Vector3(cos(_bob * 0.6) * 0.004, sin(_bob * 0.9) * 0.004, 0)
		hand_anchor.position = Vector3(0.26, -0.24, -0.42) + sway

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
	_target = target
	var prompt := ""
	if target != null:
		prompt = target.get_prompt(self)
	if prompt != _last_prompt:
		_last_prompt = prompt
		Events.prompt_changed.emit(prompt)


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
	item.rotation = Vector3(-0.55, 0.4, 0.0)
	item.scale = Vector3(1.55, 1.55, 1.55)
	Events.held_changed.emit(item.data.describe())
	if not from_world:
		Audio.play("click", 1.6, -18.0)


func take_held_item() -> PuriItem:
	var item := held_item
	held_item = null
	Events.held_changed.emit("")
	return item


func has_held_item() -> bool:
	return held_item != null


func try_interact() -> void:
	_try_interact()
