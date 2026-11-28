class_name Reticle
extends Control
## Minimal warm reticle: a soft dot with four short ticks. Reads on any
## background without looking like a military crosshair.

var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var glow := 0.62 + 0.12 * sin(_pulse * 2.2)
	var warm := Color(1.0, 0.95, 0.86, glow)
	var shadow := Color(0, 0, 0, 0.35)
	# halo
	draw_circle(c, 3.4, Color(1, 0.9, 0.75, 0.10))
	# ticks
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var a: Vector2 = c + dir * 4.6
		var b: Vector2 = c + dir * 8.4
		draw_line(a + Vector2(0.6, 0.6), b + Vector2(0.6, 0.6), shadow, 2.0, true)
		draw_line(a, b, warm, 1.6, true)
	# centre dot
	draw_circle(c, 2.1, shadow)
	draw_circle(c, 1.5, warm)
