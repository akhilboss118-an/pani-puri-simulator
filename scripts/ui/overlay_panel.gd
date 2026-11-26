class_name OverlayPanel
extends Control
## Base for every modal screen. Dims the game, pauses it, and restores the
## mouse capture when closed.

var panel_box: PanelContainer
var content: VBoxContainer
var title_text: String = "Panel"
var pause_game: bool = true

var _title_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UIKit.theme()

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(center)

	panel_box = PanelContainer.new()
	panel_box.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel_box)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel_box.add_child(margin)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	_title_label = UIKit.label(title_text, 26, UIKit.ORANGE)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	var close_button := UIKit.button("X", 40)
	close_button.custom_minimum_size = Vector2(48, 40)
	close_button.pressed.connect(close)
	header.add_child(close_button)

	var divider := ColorRect.new()
	divider.color = UIKit.BORDER
	divider.custom_minimum_size = Vector2(0, 1)
	content.add_child(divider)

	_build_content()


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
	_on_open()


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
