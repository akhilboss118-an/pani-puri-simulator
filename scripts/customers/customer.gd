class_name Customer
extends Node3D
## One reusable low-poly customer. Walks in, queues, shows an order bubble,
## waits with a visible patience bar, reacts, pays and leaves.
##
## The seven imported GLB characters are the primary look. If a model is
## missing the procedural body below is used instead, so the game always runs.

signal departed(customer: Customer)
signal walked_out(customer: Customer)

enum State { WALK_IN, QUEUE, ORDER, REACTION, LEAVING }

const MODEL_COUNT := 9
const MODEL_DIR := "res://assets/models/customers"

static var _model_cache: Dictionary = {}

var order: Dictionary = {}
var customer_name: String = "Customer"
var model_index: int = 1
var state: State = State.WALK_IN
var patience_max: float = 28.0
var patience_left: float = 28.0
var queue_index: int = 0
var target_position: Vector3 = Vector3.ZERO
var exit_position: Vector3 = Vector3(18, 0, 6.5)
var has_arrived: bool = false
var is_vip: bool = false
var personality: String = "tourist"
var is_regular: bool = false
var visits: int = 1
var favourite_recipe: String = ""

var _body: Node3D
var _model: Node3D
var _model_base_scale: float = 1.0
var _animation_player: AnimationPlayer
var _animated: bool = false
var _leg_l: Node3D
var _leg_r: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _head: Node3D
var _bubble: Label3D
var _bubble_bg: MeshInstance3D
var _bubble_frame: MeshInstance3D
var _badge: Label3D
var _bar_fill: MeshInstance3D
var _bar_bg: MeshInstance3D
var _phase: float = 0.0
var _reaction_timer: float = 0.0
var _walk_speed: float = 1.25
var _leaving: bool = false


func _ready() -> void:
	add_to_group("customer")
	_build()
	_bubble.visible = false
	_bubble_bg.visible = false
	_bubble_frame.visible = false
	_bar_fill.visible = false
	_bar_bg.visible = false
	if _badge:
		_badge.visible = false
	_play_animation("idle")


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	if not _build_imported_model():
		_build_procedural_body()
	_build_order_overlay()


func _build_imported_model() -> bool:
	var key := "%s/customer_%d.glb" % [MODEL_DIR, clampi(model_index, 1, MODEL_COUNT)]
	if not _model_cache.has(key):
		_model_cache[key] = load(key) if ResourceLoader.exists(key) else null
	var packed: Resource = _model_cache[key]
	if packed == null or not (packed is PackedScene):
		print("Customer: GLB missing ", key, " - using procedural fallback")
		return false
	var instance: Node = (packed as PackedScene).instantiate()
	if instance == null or not (instance is Node3D):
		return false
	print("Customer: GLB loaded ", key)
	_model = instance as Node3D
	_model.name = "ImportedModel"
	var height_scale := randf_range(0.97, 1.03)
	_model.scale = Vector3.ONE * height_scale
	_model_base_scale = height_scale
	_body.add_child(_model)
	var anim_players: Array[Node] = _model.find_children("*", "AnimationPlayer", true, false)
	_animation_player = anim_players[0] as AnimationPlayer if not anim_players.is_empty() else null
	_animated = _animation_player != null
	_animated = _animation_player != null
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return true


func _build_procedural_body() -> void:
	var skin: Color = GameData.C_SKIN[randi() % GameData.C_SKIN.size()]
	var cloth: Color = GameData.C_CLOTH[randi() % GameData.C_CLOTH.size()]
	var cloth2: Color = cloth.darkened(0.42)
	var accent: Color = GameData.C_CLOTH[(randi() + 3) % GameData.C_CLOTH.size()]
	var hair := Color("241812") if randf() < 0.7 else Color("3a2a1c")

	# legs
	_leg_l = Node3D.new()
	_leg_l.position = Vector3(-0.09, 0.78, 0)
	_body.add_child(_leg_l)
	MeshFactory.box(_leg_l, Vector3(0.12, 0.72, 0.14), Vector3(0, -0.36, 0), cloth2, "LegL", 0.0, false)
	MeshFactory.box(_leg_l, Vector3(0.13, 0.07, 0.22), Vector3(0, -0.72, 0.03), Color("2b2520"), "ShoeL", 0.0, false)

	_leg_r = Node3D.new()
	_leg_r.position = Vector3(0.09, 0.78, 0)
	_body.add_child(_leg_r)
	MeshFactory.box(_leg_r, Vector3(0.12, 0.72, 0.14), Vector3(0, -0.36, 0), cloth2, "LegR", 0.0, false)
	MeshFactory.box(_leg_r, Vector3(0.13, 0.07, 0.22), Vector3(0, -0.72, 0.03), Color("2b2520"), "ShoeR", 0.0, false)

	# torso / kurta
	MeshFactory.box(_body, Vector3(0.36, 0.56, 0.22), Vector3(0, 1.08, 0), cloth, "Kurta")
	MeshFactory.box(_body, Vector3(0.38, 0.06, 0.24), Vector3(0, 0.82, 0), cloth2, "Hem", 0.0, false)
	MeshFactory.box(_body, Vector3(0.4, 0.05, 0.25), Vector3(0, 1.34, 0), accent, "Collar", 0.0, false)
	MeshFactory.box(_body, Vector3(0.075, 0.46, 0.02), Vector3(-0.1, 1.06, 0.115), accent, "Scarf", 0.0, false)

	# arms: sleeve + bare forearm so they read against the torso
	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-0.21, 1.3, 0)
	_body.add_child(_arm_l)
	MeshFactory.box(_arm_l, Vector3(0.095, 0.3, 0.115), Vector3(0, -0.14, 0), cloth, "SleeveL", 0.0, false)
	MeshFactory.box(_arm_l, Vector3(0.078, 0.24, 0.09), Vector3(0, -0.4, 0), skin, "ForearmL", 0.0, false)
	MeshFactory.box(_arm_l, Vector3(0.08, 0.1, 0.09), Vector3(0, -0.55, 0), skin, "HandL", 0.0, false)

	_arm_r = Node3D.new()
	_arm_r.position = Vector3(0.21, 1.3, 0)
	_body.add_child(_arm_r)
	MeshFactory.box(_arm_r, Vector3(0.095, 0.3, 0.115), Vector3(0, -0.14, 0), cloth, "SleeveR", 0.0, false)
	MeshFactory.box(_arm_r, Vector3(0.078, 0.24, 0.09), Vector3(0, -0.4, 0), skin, "ForearmR", 0.0, false)
	MeshFactory.box(_arm_r, Vector3(0.08, 0.1, 0.09), Vector3(0, -0.55, 0), skin, "HandR", 0.0, false)

	# head
	_head = Node3D.new()
	_head.position = Vector3(0, 1.52, 0)
	_body.add_child(_head)
	MeshFactory.sphere(_head, 0.125, Vector3.ZERO, skin, "Head", 12)
	MeshFactory.sphere(_head, 0.105, Vector3(0, 0.08, -0.012), hair, "Hair", 10, false)
	MeshFactory.box(_head, Vector3(0.026, 0.018, 0.012), Vector3(-0.046, 0.01, 0.118), Color("1b1410"), "EyeL", 0.0, false)
	MeshFactory.box(_head, Vector3(0.026, 0.018, 0.012), Vector3(0.046, 0.01, 0.118), Color("1b1410"), "EyeR", 0.0, false)
	MeshFactory.box(_head, Vector3(0.018, 0.034, 0.02), Vector3(0, -0.018, 0.122), skin.darkened(0.12), "Nose", 0.0, false)
	MeshFactory.box(_head, Vector3(0.042, 0.009, 0.01), Vector3(0, -0.058, 0.118), Color("6b3a2e"), "Smile", 0.0, false)

	if is_vip:
		var crown := MeshFactory.cylinder(_head, 0.05, 0.03, Vector3(0, 0.15, 0), GameData.C_GOLD, "Crown", 8, false)
		crown.scale = Vector3(1.0, 1.8, 1.0)
		var jewel := MeshFactory.sphere(_head, 0.025, Vector3(0, 0.19, 0), GameData.C_RED, "Jewel", 6, false)
		var jewel_mat := MeshFactory.material(GameData.C_RED, 0.2, 0.0, true)
		jewel_mat.emission_enabled = true
		jewel_mat.emission = GameData.C_RED
		jewel_mat.emission_energy_multiplier = 1.5
		jewel.material_override = jewel_mat


func _build_order_overlay() -> void:
	# order bubble: a cream card with a thin brass frame
	_bubble_frame = MeshFactory.quad(self, Vector2(1.2, 0.5), Vector3(0, 2.14, -0.006), Color(0.79, 0.63, 0.36, 0.98))
	var frame_mat := _bubble_frame.material_override as StandardMaterial3D
	frame_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	frame_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bubble_bg = MeshFactory.quad(self, Vector2(1.12, 0.42), Vector3(0, 2.14, 0), Color(1, 0.98, 0.92, 0.97))
	var mat := _bubble_bg.material_override as StandardMaterial3D
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bubble = Label3D.new()
	_bubble.text = ""
	_bubble.position = Vector3(0, 2.14, 0.012)
	_bubble.font = UIKit.ui_font(800)
	_bubble.font_size = 36
	_bubble.pixel_size = 0.0031
	_bubble.modulate = Color("2a1c12")
	_bubble.outline_size = 0
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.width = 340
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_bubble)
	_badge = MeshFactory.label(self, "", Vector3(0.9, 2.16, 0.012), 17, Color("2a1c12"), 0.0024)
	_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_badge.visible = false

	# patience bar
	_bar_bg = MeshFactory.quad(self, Vector2(0.5, 0.06), Vector3(0, 1.84, 0), Color(0.15, 0.12, 0.1, 0.85))
	(_bar_bg.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	(_bar_bg.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_bar_fill = MeshFactory.quad(self, Vector2(0.48, 0.04), Vector3(0, 1.84, 0.002), Color("6fbf5f"))
	(_bar_fill.material_override as StandardMaterial3D).billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED


func setup(patience_bonus: float) -> void:
	patience_max = randf_range(26.0, 34.0) * (1.0 + patience_bonus)
	if is_vip:
		patience_max *= 1.6
		_walk_speed = randf_range(1.4, 1.9)
	else:
		_walk_speed = randf_range(1.05, 1.5)
	patience_left = patience_max


func set_personality(kind: String, regular: bool = false) -> void:
	personality = kind
	is_regular = regular
	var bubble_color := Color(1.0, 0.98, 0.92, 0.96)
	var tag := ""
	match kind:
		"impatient":
			bubble_color = Color(1.0, 0.88, 0.78, 0.96)
			tag = "HURRY!"
			patience_max *= 0.75
			patience_left = patience_max
		"foodie":
			bubble_color = Color(0.94, 0.86, 1.0, 0.96)
			tag = "FOODIE"
		"tourist":
			bubble_color = Color(0.86, 0.96, 1.0, 0.96)
			tag = "TOURIST"
		"regular":
			bubble_color = Color(0.86, 1.0, 0.88, 0.96)
			tag = "REGULAR"
	if is_regular:
		tag = "REGULAR"
	if _bubble_bg != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = bubble_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_bubble_bg.material_override = mat
	if _badge != null:
		_badge.text = tag
		_badge.visible = tag != ""


func walk_to(position: Vector3, index: int) -> void:
	target_position = position
	queue_index = index
	has_arrived = false
	state = State.WALK_IN


func face_towards(world_position: Vector3) -> void:
	if _body == null:
		return
	var flat := Vector3(world_position.x, global_position.y, world_position.z)
	if flat.distance_to(global_position) > 0.05:
		_body.look_at(flat, Vector3.UP)


func begin_order(order_data: Dictionary) -> void:
	order = order_data
	state = State.ORDER
	has_arrived = true
	_bubble.text = order_text()
	_bubble.visible = true
	_bubble_bg.visible = true
	_bubble_frame.visible = true
	_bar_fill.visible = true
	_bar_bg.visible = true
	Audio.play("bell", 1.2, -18.0)
	var line := String(order_data.get("dialogue", ""))
	if line != "":
		Audio.play_dialogue(line, global_position)


func order_text() -> String:
	if order.is_empty():
		return ""
	var qty := int(order.get("quantity", 0))
	var spice := int(order.get("spice", 1))
	var lines: Array[String] = []
	lines.append("%d x %s" % [qty, String(order.get("name", "Pani Puri"))])
	var prefs: Array[String] = []
	prefs.append(GameData.SPICE_NAMES[clampi(spice, 0, 2)])
	if bool(order.get("sweet", false)):
		prefs.append("sweet")
	if bool(order.get("onion", false)):
		prefs.append("onion")
	else:
		prefs.append("no onion")
	lines.append(" - ".join(prefs))
	if String(order.get("note", "")) != "":
		lines.append(String(order.note))
	return "\n".join(lines)


func patience_ratio() -> float:
	return clampf(patience_left / maxf(1.0, patience_max), 0.0, 1.0)


func receive(score: float, message: String) -> void:
	state = State.REACTION
	_reaction_timer = 1.6
	_bubble.text = message
	_bubble.visible = true
	_bubble_bg.visible = true
	_bubble_frame.visible = true
	_bar_fill.visible = false
	_bar_bg.visible = false
	Audio.play("good" if score >= 0.6 else "bad", 1.0, -8.0)
	var reaction := "serve_bad" if score < 0.6 else ("serve_perfect" if score >= 0.9 else "serve_good")
	Audio.play_dialogue(reaction, global_position)
	_play_animation("eat")
	if score >= 0.6:
		var tween := create_tween()
		tween.tween_property(_body, "position:y", 0.14, 0.12)
		tween.tween_property(_body, "position:y", 0.0, 0.18)
	else:
		var tween2 := create_tween()
		tween2.tween_property(_body, "rotation:z", 0.12, 0.08)
		tween2.tween_property(_body, "rotation:z", -0.12, 0.12)
		tween2.tween_property(_body, "rotation:z", 0.0, 0.08)


func leave(exit_position: Vector3) -> void:
	state = State.LEAVING
	_leaving = true
	target_position = exit_position
	has_arrived = false
	_play_animation("walk")
	_bubble.visible = false
	_bubble_bg.visible = false
	_bubble_frame.visible = false
	_bar_fill.visible = false
	_bar_bg.visible = false
	if _badge:
		_badge.visible = false


func _process(delta: float) -> void:
	if not _active_state():
		return
	match state:
		State.WALK_IN, State.QUEUE, State.LEAVING:
			_move(delta)
		State.ORDER:
			_patience_tick(delta)
			_idle_anim(delta)
		State.REACTION:
			_reaction_timer -= delta
			if _reaction_timer <= 0.0:
				leave(exit_position)


func _active_state() -> bool:
	return Game.state == Game.State.PLAYING


func _play_animation(name: String) -> void:
	if _animation_player == null or not _animation_player.has_animation(name):
		return
	if _animation_player.current_animation == name and _animation_player.is_playing():
		return
	_animation_player.play(name)


func _move(delta: float) -> void:
	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)
	var distance := global_position.distance_to(flat_target)
	if distance < 0.08:
		if not has_arrived:
			has_arrived = true
			if state == State.WALK_IN:
				state = State.QUEUE
			elif state == State.LEAVING:
				departed.emit(self)
		_play_animation("walk" if state == State.LEAVING else "idle")
		_idle_anim(delta)
		return
	_play_animation("walk")
	var direction := (flat_target - global_position).normalized()
	global_position += direction * _walk_speed * delta
	var look_target := global_position + direction
	if _body:
		_body.look_at(look_target, Vector3.UP)
	_phase += delta * 9.0
	var swing := sin(_phase) * 0.5
	if _leg_l and _leg_r:
		_leg_l.rotation.x = swing
		_leg_r.rotation.x = -swing
	if _arm_l and _arm_r:
		_arm_l.rotation.x = -swing * 0.7
		_arm_r.rotation.x = swing * 0.7
	if _model != null and not _animated:
		_model.position.y = absf(sin(_phase)) * 0.035
		_model.rotation.z = sin(_phase * 0.5) * 0.035
		_model.rotation.x = -0.04
	elif _model == null:
		_body.position.y = absf(sin(_phase)) * 0.03


func _idle_anim(delta: float) -> void:
	if _leg_l:
		_leg_l.rotation.x = lerpf(_leg_l.rotation.x, 0.0, delta * 8.0)
		_leg_r.rotation.x = lerpf(_leg_r.rotation.x, 0.0, delta * 8.0)
	if _arm_l:
		_arm_l.rotation.x = lerpf(_arm_l.rotation.x, 0.0, delta * 8.0)
		_arm_r.rotation.x = lerpf(_arm_r.rotation.x, 0.0, delta * 8.0)
	if _model != null and not _animated:
		_model.position.y = lerpf(_model.position.y, 0.0, delta * 6.0)
		_model.rotation.z = lerpf(_model.rotation.z, 0.0, delta * 6.0)
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, delta * 6.0)
		var breathe := 1.0 + sin(Time.get_ticks_msec() * 0.0016) * 0.004
		_model.scale.y = _model_base_scale * breathe
	if _body and not _model:
		_body.position.y = lerpf(_body.position.y, 0.0, delta * 6.0)


func _patience_tick(delta: float) -> void:
	patience_left -= delta
	var ratio := patience_ratio()
	if _bar_fill:
		_bar_fill.scale.x = maxf(0.02, ratio)
		_bar_fill.position.x = -0.24 + 0.24 * ratio
		var col := Color("6fbf5f") if ratio > 0.5 else (Color("e8a13c") if ratio > 0.25 else Color("d9532f"))
		var bar_mat := MeshFactory.material(col, 1.0, 0.0, true)
		bar_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_bar_fill.material_override = bar_mat
	if ratio < 0.25 and _head and not Game.settings.reduced_motion:
		_head.position.x = sin(Time.get_ticks_msec() * 0.02) * 0.008
	if patience_left <= 0.0:
		_bubble.text = "Too slow!"
		_bubble.visible = true
		_bubble_bg.visible = true
		_bubble_frame.visible = true
		Audio.play_dialogue("walkout", global_position)
		walked_out.emit(self)
