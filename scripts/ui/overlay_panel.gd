class_name OverlayPanel
extends Control
## Base for every modal screen. Dims the game, pauses it, and restores the
## mouse capture when closed.
##
## Every panel inherits the same premium chrome: an editorial title, a gold
## hairline, a floating card with a soft shadow and a short entrance animation.

var panel_box: PanelContainer
var content: VBoxContainer
var title_text: String = "Panel"
var subtitle_text: String = ""
var pause_game: bool = true

var _title_label: Label
var _dim: ColorRect
var _center: CenterContainer
var _fit_targets: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UIKit.theme()

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.015, 0.012, 0.68)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	# Warm vignette on top of the dim so panels feel lit, not greyed out.
	var vignette := TextureRect.new()
	vignette.texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, 0.0)],
		[0.7, Color(0, 0, 0, 0.12)],
		[1.0, Color(0, 0, 0, 0.55)],
	], Vector2(0.5, 0.45), 0.72, 96)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_center)

	panel_box = PanelContainer.new()
	panel_box.add_theme_stylebox_override("panel", UIKit.panel_style(26))
	_center.add_child(panel_box)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel_box.add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	content.add_child(header)

	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 1)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)

	titles.add_child(UIKit.gold_pill("Pani Puri Simulator", UIKit.GOLD, UIKit.INK, 10))
	_title_label = UIKit.heading(title_text, 32, UIKit.CREAM)
	titles.add_child(_title_label)
	if subtitle_text != "":
		titles.add_child(UIKit.label(subtitle_text, 13, UIKit.MUTED))

	var close_button := UIKit.ghost_button("Close", 38)
	close_button.custom_minimum_size = Vector2(84, 38)
	close_button.add_theme_font_size_override("font_size", 14)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_button.pressed.connect(close)
	header.add_child(close_button)

	content.add_child(UIKit.divider(UIKit.GOLD, 0.5))

	_build_content()

	# Keep the card usable on narrow phones.
	_resize_card()
	get_viewport().size_changed.connect(_resize_card)


func _resize_card() -> void:
	if panel_box == null or content == null:
		return
	var width := get_viewport_rect().size.x
	var target := clampf(width * 0.94, 320.0, 640.0)
	panel_box.custom_minimum_size = Vector2(target, 0)
	content.custom_minimum_size = Vector2(target - 68.0, 0)
	_apply_fits()


## Keeps a tall list inside the card on short screens (720p, phones, web).
## `ratio` is the share of the viewport height the list may use.
func fit_to_viewport(node: Control, ratio: float, maximum: float) -> void:
	_fit_targets.append({"node": node, "ratio": ratio, "max": maximum})
	_apply_fits()


func _apply_fits() -> void:
	var height := get_viewport_rect().size.y
	for entry in _fit_targets:
		var node: Control = entry["node"]
		if is_instance_valid(node):
			node.custom_minimum_size.y = clampf(
				height * float(entry["ratio"]), 140.0, float(entry["max"]))


func _build_content() -> void:
	pass


func open() -> void:
	visible = true
	move_to_front()
	Game.overlay_open = true
	Events.overlay_changed.emit(true)
	if pause_game:
		get_tree().paused = true
	if not Game.is_mobile():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_animate_in()
	_on_open()


func _animate_in() -> void:
	if Game.settings.get("reduced_motion", false):
		return
	panel_box.pivot_offset = panel_box.size * 0.5
	panel_box.scale = Vector2(0.975, 0.975)
	panel_box.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel_box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_box, "modulate:a", 1.0, 0.16)


func close() -> void:
	visible = false
	Game.overlay_open = false
	Events.overlay_changed.emit(false)
	get_tree().paused = false
	if Game.state == Game.State.PLAYING and not Game.is_mobile():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_on_close()


func _on_open() -> void:
	pass


func _on_close() -> void:
	pass


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
