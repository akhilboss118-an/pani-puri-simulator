class_name MainMenu
extends Control
## Title screen. The 3D street keeps moving softly behind it so the game sells
## itself before the player presses anything.

signal new_game_pressed
signal continue_pressed
signal quit_pressed

var _continue_button: Button
var _credits: Control
var _settings: SettingsPanel
var _title: Label
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	_build_background()
	_build_content()
	_build_credits()
	_settings = SettingsPanel.new()
	add_child(_settings)


func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.04, 0.03, 0.02, 0.95))
	gradient.add_point(0.35, Color(0.05, 0.04, 0.03, 0.8))
	gradient.add_point(0.6, Color(0.07, 0.05, 0.03, 0.45))
	gradient.set_color(1, Color(0.1, 0.08, 0.05, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)


func _build_content() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	box.offset_left = 90
	box.offset_right = 620
	box.offset_top = 34

# Kicker + title are animated on _process (title pulses).
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)

	var kicker := UIKit.label("A STREET FOOD STORY", 13, UIKit.TEAL)
	box.add_child(kicker)
	_title = UIKit.label("PANI PURI SIMULATOR", 68, UIKit.CREAM)
	box.add_child(_title)
	var tagline := UIKit.label(
		"Earn cash, level up and grow your cart into a fancy restaurant.",
		16, UIKit.MUTED)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.custom_minimum_size = Vector2(420, 0)
	box.add_child(tagline)

	var new_game := UIKit.button("New Game", 58)
	new_game.add_theme_stylebox_override("normal", UIKit.style(UIKit.GOLD, 12, UIKit.GOLD.lightened(0.2), 1, 16))
	new_game.add_theme_stylebox_override("hover", UIKit.style(UIKit.GOLD.lightened(0.2), 12, UIKit.CREAM, 1, 16))
	new_game.add_theme_stylebox_override("pressed", UIKit.style(UIKit.GOLD.darkened(0.15), 12, UIKit.GOLD, 1, 16))
	new_game.add_theme_color_override("font_color", Color("241a14"))
	new_game.add_theme_color_override("font_hover_color", Color("241a14"))
	new_game.add_theme_color_override("font_pressed_color", Color("241a14"))
	new_game.pressed.connect(func(): new_game_pressed.emit())
	box.add_child(new_game)

	_continue_button = UIKit.button("Continue", 46)
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	box.add_child(_continue_button)

	var settings := UIKit.button("Settings", 46)
	settings.pressed.connect(func(): _settings.open())
	box.add_child(settings)

	var credits := UIKit.button("Credits", 46)
	credits.pressed.connect(func(): _credits.visible = true)
	box.add_child(credits)

	var quit := UIKit.button("Quit", 46)
	quit.pressed.connect(func(): quit_pressed.emit())
	box.add_child(quit)

	var version := UIKit.label("v%s  -  Godot 4.7  -  Compatibility renderer  -  Publish-ready" % Game.VERSION, 12, Color(0.78, 0.7, 0.55, 0.75))
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.offset_left = 88
	version.offset_top = -40
	version.offset_right = 760
	version.offset_bottom = -20
	add_child(version)

	var controls := UIKit.label(
		"WASD move  -  Mouse look  -  E interact  -  Tab stock  -  U upgrades  -  Esc menu",
		13, Color(0.85, 0.78, 0.68, 0.55))
	controls.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.offset_left = -760
	controls.offset_top = -40
	controls.offset_right = -88
	controls.offset_bottom = -20
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(controls)


func _process(delta: float) -> void:
	_time += delta
	var pulse := 1.0 + 0.035 * sin(_time * 2.2)
	_title.scale = Vector2(pulse, pulse)


func _build_credits() -> void:
	_credits = Control.new()
	_credits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.visible = false
	_credits.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_credits)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_credits.add_child(center)
	var panel := UIKit.panel(24)
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UIKit.label("CREDITS & ATTRIBUTIONS", 26, UIKit.GOLD))

	var text := UIKit.label(
		"Pani Puri Simulator\n\n" +
		"Built with OpenCode - Godot 4.7.2, Compatibility renderer.\n\n" +
		"Procedural art: street, stall, customers and audio are all synthesised\n" +
		"in-engine from low-poly primitives.\n\n" +
		"Real 3D models (CC0, downloaded with a licence review):\n" +
		"  - Kenney Nature Kit, Survival Kit and Furniture Kit (kenney.nl)\n" +
		"  - Customer characters (user-supplied, anonymised to Customer 1..7)\n\n" +
		"Sketchfab environment models are imported after manual review - see\n" +
		"ART_PIPELINE.md and assets/manifest.json.\n\n" +
		"Drum rolls welcome. Third-party credits go here.",
		16, UIKit.CREAM)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	var close := UIKit.button("Close", 46)
	close.pressed.connect(func(): _credits.visible = false)
	box.add_child(close)


func refresh() -> void:
	if _continue_button:
		_continue_button.disabled = not SaveManager.has_save()
