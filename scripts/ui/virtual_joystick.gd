class_name StickInput
extends Control
## Touch joystick. Draws itself with primitives so it needs no textures.

signal moved(value: Vector2)

var radius: float = 62.0
var value: Vector2 = Vector2.ZERO

var _touch_index: int = -1
var _knob: Vector2 = Vector2.ZERO
var _active: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.4, radius * 2.4)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.08, 0.06, 0.05, 0.42))
	draw_arc(center, radius, 0, TAU, 40, Color(0.96, 0.86, 0.72, 0.35), 2.0, true)
	draw_circle(center + _knob, radius * 0.42, Color(0.96, 0.55, 0.24, 0.75))
	draw_arc(center + _knob, radius * 0.42, 0, TAU, 24, Color(1, 0.9, 0.75, 0.8), 2.0, true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_touch_index = event.index
			_update_from(event.position)
		elif not event.pressed and event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_from(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _active:
			_active = true
			_touch_index = -1
			_update_from(event.position)
		elif not event.pressed and _active:
			_release()
	elif event is InputEventMouseMotion and _active and _touch_index == -1:
		_update_from(event.position)


func _update_from(local_position: Vector2) -> void:
	var center := size * 0.5
	var offset := local_position - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	_knob = offset
	value = offset / radius
	moved.emit(value)
	queue_redraw()


func _release() -> void:
	_active = false
	_touch_index = -1
	_knob = Vector2.ZERO
	value = Vector2.ZERO
	moved.emit(value)
	queue_redraw()
