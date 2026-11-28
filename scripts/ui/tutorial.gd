class_name Tutorial
extends Control
## First-order guided lesson. It runs on day 1 only: the clock and normal
## customer arrivals are frozen, one scripted customer asks for a single mild
## classic puri, and a banner plus a floating 3D arrow guide the six steps.
## Progress is inferred from the real player/plate state, so doing steps out of
## order never desynchronises the lesson.

const STEP_COPY := [
	{
		"title": "Take a puri shell",
		"hint": "Walk up to the PURI tin on the counter and press E (or USE on mobile).",
	},
	{
		"title": "Crack it open",
		"hint": "Use the tin again to crack the shell. A hollow puri is ready to fill.",
	},
	{
		"title": "Add potato filling",
		"hint": "Move to the potato bowl on the counter and press E.",
	},
	{
		"title": "Dip it in mint pani",
		"hint": "Move to the PANI pot and press E. This is what makes a puri ready.",
	},
	{
		"title": "Place it on the plate",
		"hint": "Walk to the serving plate on the right and press E to set it down.",
	},
	{
		"title": "Serve the customer",
		"hint": "Press E at the plate once more. This customer only wants one puri.",
	},
]

var player: Player
var world: WorldBuilder

var _active: bool = false
var _step: int = 0
var _time: float = 0.0
var _arrow_base_y: float = 0.0

var _step_label: Label
var _title_label: Label
var _hint_label: Label
var _arrow: Node3D


func setup(p: Player, w: WorldBuilder) -> void:
	player = p
	world = w
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_build_arrow()
	visible = false


func _build_ui() -> void:
	theme = UIKit.theme()
	var panel := UIKit.panel(14)
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = -248
	panel.offset_bottom = -126
	panel.add_theme_stylebox_override("panel", UIKit.frame_style(14))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)

	_step_label = UIKit.kicker("STEP 1 OF 6", UIKit.GOLD, 11)
	box.add_child(_step_label)
	box.add_child(UIKit.divider(UIKit.FILIGREE, 0.35))
	_title_label = UIKit.label("Take a puri shell", 21, UIKit.CREAM)
	_title_label.add_theme_font_override("font", UIKit.ui_font(700, 2))
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title_label)
	_hint_label = UIKit.label("", 13, UIKit.MUTED)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var skip := UIKit.slab_button("Skip tutorial", UIKit.FILIGREE_DIM, 30)
	skip.custom_minimum_size.x = 150
	skip.pressed.connect(func(): end_tutorial(true))
	row.add_child(skip)


func _build_arrow() -> void:
	if world == null:
		return
	_arrow = Node3D.new()
	_arrow.name = "TutorialArrow"
	var mat := MeshFactory.material(Color("ffd27a"), 0.4, 0.0, true)
	mat.emission_enabled = true
	mat.emission = Color("ffb347")
	mat.emission_energy_multiplier = 1.2

	var cone := CylinderMesh.new()
	cone.top_radius = 0.13
	cone.bottom_radius = 0.0
	cone.height = 0.3
	cone.radial_segments = 10
	var tip := MeshInstance3D.new()
	tip.name = "ArrowTip"
	tip.mesh = cone
	tip.material_override = mat
	_arrow.add_child(tip)
	var shaft := MeshFactory.cylinder(_arrow, 0.045, 0.3, Vector3(0, 0.3, 0), Color("f7e9cf"), "ArrowShaft", 8, false)
	shaft.material_override = mat
	world.add_child(_arrow)
	_arrow.visible = false


func start() -> void:
	if player == null or world == null or world.customer_manager == null:
		return
	_active = true
	visible = true
	Clock.reset()
	world.customer_manager.call("freeze_for_tutorial")
	world.customer_manager.call("spawn_tutorial_customer")
	Events.toast.emit("First order: I'll walk you through it step by step.", "info")
	_set_step(0)


func _process(delta: float) -> void:
	if not _active:
		return
	_time += delta
	if _arrow != null and _arrow.visible:
		_arrow.position.y = _arrow_base_y + sin(_time * 3.0) * 0.08
		_arrow.rotation.y += delta * 1.6
	var next := _infer_step()
	if next != _step:
		_set_step(next)


## Reads the real game state so the lesson follows the player, never a timer.
func _infer_step() -> int:
	if Orders.day_served > 0:
		return STEP_COPY.size()
	if world.plate != null and not world.plate.puris.is_empty() and player.held_item == null:
		return 5
	var held = player.held_item
	if held == null:
		return 0
	var data: PuriData = held.data
	if data.state == PuriData.State.EMPTY:
		return 1
	if not data.has_ingredient("potato"):
		return 2
	if data.pani == "none":
		return 3
	return 4


func _set_step(step: int) -> void:
	_step = clampi(step, 0, STEP_COPY.size())
	if _step >= STEP_COPY.size():
		end_tutorial(false)
		return
	var copy: Dictionary = STEP_COPY[_step]
	_step_label.text = "STEP %d OF %d" % [_step + 1, STEP_COPY.size()]
	_title_label.text = String(copy["title"])
	_hint_label.text = String(copy["hint"])
	var target: Node3D = _target_for_step(_step)
	if target != null and _arrow != null:
		_arrow.visible = true
		_arrow_base_y = target.global_position.y + 1.05
		_arrow.global_position = target.global_position + Vector3(0.0, 1.05, 0.0)


func _target_for_step(step: int) -> Node3D:
	if world == null:
		return null
	match step:
		0, 1:
			return world.stall.get("puri_box") as Node3D
		2:
			return world.stall.get("potato") as Node3D
		3:
			return world.stall.get("pani_mint") as Node3D
		4, 5:
			return world.stall.get("plate") as Node3D
	return null


func end_tutorial(skipped: bool = false) -> void:
	if not _active:
		return
	_active = false
	visible = false
	if _arrow != null:
		_arrow.visible = false
	Game.apply_setting("tutorial_done", true)
	if world != null and world.customer_manager != null:
		world.customer_manager.call("end_tutorial")
	Clock.begin_day()
	if skipped:
		Events.toast.emit("Tutorial skipped - the stall is yours.", "info")
	else:
		Audio.play("good", 1.2, -6.0)
		Events.toast.emit("First puri served! The shop is officially open.", "good")


## Leaving to the menu mid-lesson keeps the flag unset so it runs again later.
func cancel() -> void:
	if not _active:
		return
	_active = false
	visible = false
	if _arrow != null:
		_arrow.visible = false
	if world != null and world.customer_manager != null:
		world.customer_manager.call("end_tutorial")


func is_active() -> bool:
	return _active
