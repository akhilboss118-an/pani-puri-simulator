extends CanvasLayer
## Cheap cinematic finish for the 3D view: a warm colour wash, a heavy vignette,
## soft top/bottom falloff and a whisper of film grain. One CanvasLayer, four
## full-screen textures, no screen reads - safe on low-end phones and WebGL2.

var _vignette: TextureRect
var _grade: ColorRect
var _letterbox: TextureRect
var _grain: TextureRect
var _quality: int = 1


func _ready() -> void:
	layer = 2
	process_mode = Node.PROCESS_MODE_ALWAYS

	_grade = ColorRect.new()
	_grade.color = Color(1.0, 0.90, 0.74, 0.026)
	_grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grade)

	_vignette = TextureRect.new()
	_vignette.texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, 0.0)],
		[0.52, Color(0, 0, 0, 0.06)],
		[0.80, Color(0, 0, 0, 0.30)],
		[1.0, Color(0.01, 0.008, 0.006, 0.72)],
	], Vector2(0.5, 0.46), 0.74, 128)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	# Soft cinematic falloff at the top and bottom edges.
	_letterbox = TextureRect.new()
	_letterbox.texture = UIKit.linear_texture([
		[0.0, Color(0.01, 0.008, 0.006, 0.55)],
		[0.14, Color(0.01, 0.008, 0.006, 0.16)],
		[0.5, Color(0, 0, 0, 0.0)],
		[0.86, Color(0.01, 0.008, 0.006, 0.16)],
		[1.0, Color(0.01, 0.008, 0.006, 0.55)],
	], Vector2(0.0, 1.0), Vector2i(8, 256))
	_letterbox.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_letterbox.stretch_mode = TextureRect.STRETCH_SCALE
	_letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_letterbox)

	_grain = UIKit.grain_overlay(0.035, 190.0)
	add_child(_grain)


func apply_quality(quality: int) -> void:
	_quality = quality
	if _vignette:
		_vignette.modulate.a = 1.0 if quality >= 1 else 0.7
	if _grade:
		_grade.visible = quality >= 1
	if _letterbox:
		_letterbox.modulate.a = 1.0 if quality >= 1 else 0.5
	if _grain:
		_grain.visible = quality >= 1
