class_name MainMenu
extends Control
## Centered title screen matching the warm illustrated Pani Puri Simulator
## layout over the live sunlit Indian bazaar street vista.

const UIIcons := preload("res://scripts/ui/ui_icons.gd")

signal new_game_pressed
signal continue_pressed
signal quit_pressed

var _continue_button: Button
var _credits: Control
var _controls_modal: Control
var _settings: SettingsPanel
var _logo: Control
var _box: VBoxContainer
var _center: CenterContainer
var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIKit.theme()
	_build_background()
	_build_content()
	_build_credits()
	_build_controls()
	_settings = SettingsPanel.new()
	add_child(_settings)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _build_background() -> void:
	# Gentle warm vignette around edges while keeping the center bazaar bright and crisp.
	var vignette := TextureRect.new()
	vignette.texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, 0.0)],
		[0.62, Color(0.03, 0.02, 0.015, 0.06)],
		[0.88, Color(0.03, 0.02, 0.015, 0.22)],
		[1.0, Color(0.02, 0.012, 0.008, 0.42)],
	], Vector2(0.5, 0.5), 0.78, 96)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _build_content() -> void:
	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_center)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_child(_box)

	_logo = UIIcons.LogoBanner.new()
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_logo)

	_box.add_child(UIKit.hsep(6))

	var btn_col := VBoxContainer.new()
	btn_col.custom_minimum_size = Vector2(280, 0)
	btn_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_col.add_theme_constant_override("separation", 10)
	_box.add_child(btn_col)

	var new_game := UIKit.wood_menu_button("Start Game", 52)
	new_game.pressed.connect(func(): new_game_pressed.emit())
	btn_col.add_child(new_game)

	_continue_button = UIKit.wood_menu_button("Continue", 46)
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	btn_col.add_child(_continue_button)

	var settings := UIKit.wood_menu_button("Settings", 48)
	settings.pressed.connect(func(): _settings.open())
	btn_col.add_child(settings)

	var controls_btn := UIKit.wood_menu_button("Controls", 48)
	controls_btn.pressed.connect(func(): _controls_modal.visible = true)
	btn_col.add_child(controls_btn)

	var exit_btn := UIKit.wood_menu_button("Exit", 48)
	exit_btn.pressed.connect(func(): quit_pressed.emit())
	btn_col.add_child(exit_btn)

	var credits_btn := UIKit.ghost_button("Credits", 34)
	credits_btn.custom_minimum_size = Vector2(100, 34)
	credits_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	credits_btn.offset_left = -126
	credits_btn.offset_right = -24
	credits_btn.offset_top = -50
	credits_btn.offset_bottom = -16
	credits_btn.pressed.connect(func(): _credits.visible = true)
	add_child(credits_btn)

	var version := UIKit.label("v%s  •  Godot 4.7" % Game.VERSION, 11, Color(0.96, 0.9, 0.78, 0.8))
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.offset_left = 24
	version.offset_top = -32
	version.offset_right = 320
	version.offset_bottom = -12
	add_child(version)


func _layout() -> void:
	if _logo == null:
		return
	var vp := get_viewport_rect().size
	var scale_f := clampf(vp.y / 720.0, 0.75, 1.15)
	_logo.custom_minimum_size = Vector2(460.0 * scale_f, 174.0 * scale_f)
	if _continue_button:
		_continue_button.visible = SaveManager.has_save()


func _process(delta: float) -> void:
	_time += delta
	if _logo:
		var pulse := 1.0 + 0.008 * sin(_time * 1.6)
		_logo.pivot_offset = _logo.size * 0.5
		_logo.scale = Vector2(pulse, pulse)


func _build_controls() -> void:
	_controls_modal = Control.new()
	_controls_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls_modal.visible = false
	_controls_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_controls_modal)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls_modal.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_controls_modal.add_child(center)
	var panel := UIKit.panel(26)
	panel.custom_minimum_size = Vector2(460, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	var hdr := UIKit.heading("Controls", 30, UIKit.CREAM, 700)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hdr)
	box.add_child(UIKit.divider(UIKit.GOLD, 0.5))

	var bindings := [
		["wasd", "Move"],
		["mouse", "Look Around"],
		["key_e", "Interact"],
		["key_esc", "Pause"],
		["touch", "Touch Controls (Mobile)"],
	]
	for b in bindings:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 24)
		var icon_wrap := CenterContainer.new()
		icon_wrap.custom_minimum_size = Vector2(80, 44)
		icon_wrap.add_child(UIIcons.IconGlyph.new(String(b[0]), Vector2(46, 40)))
		r.add_child(icon_wrap)
		var desc := UIKit.label(String(b[1]), 18, UIKit.CREAM)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		r.add_child(desc)
		box.add_child(r)

	box.add_child(UIKit.hsep(4))
	var close := UIKit.wood_menu_button("Back", 46)
	close.pressed.connect(func(): _controls_modal.visible = false)
	box.add_child(close)


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
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(UIKit.gold_pill("Attributions", UIKit.GOLD, UIKit.INK, 10))
	box.add_child(UIKit.heading("Credits", 32, UIKit.CREAM))
	box.add_child(UIKit.divider(UIKit.GOLD, 0.45))

	var text := UIKit.label(
		"Pani Puri Simulator  -  v%s\n\n" % Game.VERSION +
		"Godot 4.7.2, Compatibility renderer.\n\n" +
		"Type: Fraunces, Manrope & Noto Sans Devanagari (SIL OFL 1.1).\n" +
		"3D assets: Kenney Nature/Survival/Furniture Kits (CC0) & customer models.\n\n" +
		"Thank you for playing.",
		15, UIKit.CREAM)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text)
	var close := UIKit.wood_menu_button("Close", 46)
	close.pressed.connect(func(): _credits.visible = false)
	box.add_child(close)


func refresh() -> void:
	if _continue_button:
		_continue_button.visible = SaveManager.has_save()
		_continue_button.disabled = not SaveManager.has_save()
