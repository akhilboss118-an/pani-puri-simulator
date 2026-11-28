class_name Reticle
extends Control
## Responsive warm reticle: subtle center dot that blooms into a crisp
## saffron-gold targeting ring when aiming at an actionable station.

var active: bool = false
var _pulse: float = 0.0
var _focus_blend: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	_focus_blend = lerpf(_focus_blend, 1.0 if active else 0.0, delta * 14.0)
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var glow := 0.72 + 0.14 * sin(_pulse * 2.4)
	var base_col := Color(1.0, 0.95, 0.86, glow)
	var gold_col := Color(0.95, 0.75, 0.32, 0.95)
	var col := base_col.lerp(gold_col, _focus_blend)
	var shadow := Color(0, 0, 0, 0.4)

	# Outer interactive ring when hovering an interactable station
	if _focus_blend > 0.04:
		var r := lerpf(6.0, 11.5, _focus_blend)
		draw_arc(c, r, 0.0, TAU, 24, Color(0, 0, 0, 0.32 * _focus_blend), 3.0, true)
		draw_arc(c, r, 0.0, TAU, 24, Color(gold_col.r, gold_col.g, gold_col.b, 0.88 * _focus_blend), 1.8, true)

	# Four delicate ticks
	var inner := lerpf(4.2, 6.2, _focus_blend)
	var outer := lerpf(7.6, 9.6, _focus_blend)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var a: Vector2 = c + dir * inner
		var b: Vector2 = c + dir * outer
		draw_line(a + Vector2(0.6, 0.6), b + Vector2(0.6, 0.6), shadow, 2.0, true)
		draw_line(a, b, col, 1.6, true)

	# Center dot
	var dot_r := lerpf(1.7, 2.5, _focus_blend)
	draw_circle(c + Vector2(0.5, 0.5), dot_r + 0.6, shadow)
	draw_circle(c, dot_r, col)
