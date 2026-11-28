class_name MainMenu
extends Control
## Title screen. The 3D street keeps moving softly behind it so the game sells
## itself before the player presses anything.
##
## Presentation is deliberately editorial: a serif wordmark, a gold hairline,
## quiet meta chips and one gold call to action.

signal new_game_pressed
signal continue_pressed
signal quit_pressed

var _continue_button: Button
var _credits: Control
var _settings: SettingsPanel
var _title: Label
var _title_2: Label
var _rule: Control
var _glow: TextureRect
var _box: VBoxContainer
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	_build_background()
	_build_content()
	_build_credits()
	_settings = SettingsPanel.new()
	add_child(_settings)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _build_background() -> void:
	# Left-hand scrim: dark behind the wordmark, clear over the stall.
	var rect := TextureRect.new()
	rect.texture = UIKit.radial_texture([
		[0.0, Color(0.035, 0.027, 0.022, 0.97)],
		[0.42, Color(0.042, 0.032, 0.025, 0.9)],
		[0.7, Color(0.055, 0.042, 0.03, 0.55)],
		[1.0, Color(0.08, 0.062, 0.045, 0.0)],
	], Vector2(0.02, 0.5), 0.92, 128)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)

	# Warm bloom over the stall, so the 3D scene reads as a lit photograph.
	_glow = TextureRect.new()
	_glow.texture = UIKit.radial_texture([
		[0.0, Color(1.0, 0.72, 0.38, 0.16)],
		[0.55, Color(1.0, 0.62, 0.30, 0.07)],
		[1.0, Color(1.0, 0.55, 0.25, 0.0)],
	], Vector2(0.5, 0.5), 0.72, 96)
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_glow.offset_left = -360
	_glow.offset_top = -260
	_glow.offset_right = 160
	_glow.offset_bottom = 260
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)

	# Cinematic vignette.
	var vignette := TextureRect.new()
	vignette.texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, 0.0)],
		[0.62, Color(0, 0, 0, 0.05)],
		[0.85, Color(0, 0, 0, 0.22)],
		[1.0, Color(0.02, 0.012, 0.008, 0.52)],
	], Vector2(0.46, 0.46), 0.74, 96)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _build_content() -> void:
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_box.add_theme_constant_override("separation", 12)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)

	_box.add_child(UIKit.kicker("A Street Food Story", UIKit.TEAL, 12))
	_box.add_child(UIKit.hsep(2))

	_title = UIKit.heading("PANI PURI", 78, UIKit.CREAM, 800)
	_title.add_theme_constant_override("line_spacing", -6)
	_box.add_child(_title)

	_title_2 = UIKit.heading("SIMULATOR", 34, UIKit.GOLD, 600)
	_title_2.add_theme_font_override("font", UIKit.ui_font(800, 8))
	_title_2.add_theme_font_size_override("font_size", 19)
	_box.add_child(_title_2)

	_box.add_child(UIKit.hsep(2))
	_rule = UIKit.divider(UIKit.GOLD, 0.6)
	_rule.custom_minimum_size = Vector2(300, 1)
	_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_box.add_child(_rule)

	var tagline := UIKit.label(
		"Crack, fill, dip, serve. Grow a roadside cart into a\nworld-famous pani puri house.",
		16, UIKit.MUTED)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(tagline)

	_box.add_child(UIKit.hsep(6))

	var new_game := UIKit.primary_button("New Game", 56)
	new_game.pressed.connect(func(): new_game_pressed.emit())
	_box.add_child(new_game)

	_continue_button = UIKit.button("Continue", 46)
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	_box.add_child(_continue_button)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var settings := UIKit.ghost_button("Settings", 44)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func(): _settings.open())
	row.add_child(settings)
	var credits := UIKit.ghost_button("Credits", 44)
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits.pressed.connect(func(): _credits.visible = true)
	row.add_child(credits)
	var quit := UIKit.ghost_button("Quit", 44)
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.pressed.connect(func(): quit_pressed.emit())
	row.add_child(quit)
	_box.add_child(row)

	_box.add_child(UIKit.hsep(4))
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 6)
	for item in [["Offline", UIKit.TEAL], ["No Ads", UIKit.GOLD], ["Mobile + Web", UIKit.MUTED]]:
		var chip_color: Color = item[1]
		meta.add_child(UIKit.chip(String(item[0]), chip_color, 10))
	_box.add_child(meta)

	var version := UIKit.label("v%s  -  Godot 4.7  -  Compatibility renderer" % Game.VERSION, 10, Color(0.82, 0.74, 0.6, 0.7))
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.offset_left = 32
	version.offset_top = -30
	version.offset_right = 500
	version.offset_bottom = -12
	add_child(version)

	var controls := UIKit.label(
		"WASD move   -   Mouse look   -   E interact   -   Tab stock   -   U upgrades   -   Esc menu",
		11, Color(0.85, 0.78, 0.68, 0.58))
	controls.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.offset_left = -700
	controls.offset_top = -30
	controls.offset_right = -32
	controls.offset_bottom = -12
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(controls)


func _layout() -> void:
	if _box == null:
		return
	var vp := get_viewport_rect().size
	var mobile := vp.x < 760.0
	var left := 40.0 if mobile else 88.0
	var width := minf(vp.x * 0.92, 560.0)
	if mobile:
		left = maxf(20.0, (vp.x - width) * 0.5)
	_box.offset_left = left
	_box.offset_right = left + width
	_box.offset_top = 30
	_box.offset_bottom = -30
	_title.add_theme_font_size_override("font_size", int(clampf(vp.x * 0.1, 40.0, 78.0)))
	_title_2.add_theme_font_size_override("font_size", int(clampf(vp.x * 0.024, 14.0, 19.0)))
	if mobile:
		_box.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		_box.alignment = BoxContainer.ALIGNMENT_CENTER


func _process(delta: float) -> void:
	_time += delta
	if _title:
		var pulse := 1.0 + 0.006 * sin(_time * 1.4)
		_title.pivot_offset = _title.size * 0.5
		_title.scale = Vector2(pulse, pulse)
	if _glow:
		_glow.modulate.a = 0.82 + 0.12 * sin(_time * 0.9)
	if _rule:
		_rule.modulate.a = 0.75 + 0.2 * sin(_time * 1.1)


func _build_credits() -> void:
	_credits = Control.new()
	_credits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.visible = false
	_credits.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_credits)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.add_child(center)
	var panel := UIKit.panel(26)
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UIKit.kicker("Attributions", UIKit.GOLD, 11))
	box.add_child(UIKit.heading("Credits", 34, UIKit.CREAM))
	box.add_child(UIKit.divider(UIKit.GOLD, 0.45))

	var text := UIKit.label(
		"Pani Puri Simulator  -  v%s\n\n" % Game.VERSION +
		"Built with OpenCode - Godot 4.7.2, Compatibility renderer.\n\n" +
		"Procedural art: street, stall, customers and audio are all synthesised\n" +
		"in-engine from low-poly primitives.\n\n" +
		"Type: Fraunces and Manrope (SIL Open Font License 1.1).\n" +
		"Devanagari: Noto Sans Devanagari (SIL OFL 1.1).\n\n" +
		"Real 3D models (CC0, downloaded with a licence review):\n" +
		"  - Kenney Nature Kit, Survival Kit and Furniture Kit (kenney.nl)\n" +
		"  - Customer characters (user-supplied, anonymised to Customer 1..9)\n\n" +
		"Sketchfab environment models are imported after manual review - see\n" +
		"ART_PIPELINE.md and assets/manifest.json.\n\n" +
		"Thank you for playing.",
		15, UIKit.CREAM)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	var close := UIKit.primary_button("Close", 46)
	close.pressed.connect(func(): _credits.visible = false)
	box.add_child(close)


func refresh() -> void:
	if _continue_button:
		_continue_button.disabled = not SaveManager.has_save()
