extends CanvasLayer
## Cheap cinematic finish for the 3D view: a warm colour wash, a soft vignette
## and optional top/bottom falloff. One CanvasLayer, two full-screen textures,
## no screen reads - safe on low-end phones and WebGL2.

var _vignette: TextureRect
var _grade: ColorRect
var _quality: int = 1


func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS

	_grade = ColorRect.new()
	_grade.color = Color(1.0, 0.92, 0.80, 0.022)
	_grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grade)

	_vignette = TextureRect.new()
	_vignette.texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, 0.0)],
		[0.64, Color(0, 0, 0, 0.03)],
		[0.86, Color(0, 0, 0, 0.14)],
		[1.0, Color(0.02, 0.012, 0.008, 0.38)],
	], Vector2(0.5, 0.48), 0.78, 96)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)


func apply_quality(quality: int) -> void:
	_quality = quality
	if _vignette:
		_vignette.modulate.a = 1.0 if quality >= 1 else 0.75
	if _grade:
		_grade.visible = quality >= 1
