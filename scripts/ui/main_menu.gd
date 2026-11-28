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
	# Cinematic scrim: a soft centre glow behind the wordmark, a heavy vignette
	# and a fine grain pass. Everything is baked - no shaders, no screen reads.
	var glow := TextureRect.new()
	glow.texture = UIKit.radial_texture([
		[0.0, Color(0.85, 0.62, 0.30, 0.20)],
		[0.45, Color(0.55, 0.36, 0.16, 0.10)],
		[1.0, Color(0.1, 0.07, 0.04, 0.0)],
	], Vector2(0.5, 0.42), 0.62, 128)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var scrim := TextureRect.new()
	scrim.texture = UIKit.linear_texture([
		[0.0, Color(0.02, 0.016, 0.012, 0.90)],
		[0.42, Color(0.02, 0.016, 0.012, 0.74)],
		[0.72, Color(0.03, 0.02, 0.015, 0.32)],
		[1.0, Color(0.04, 0.028, 0.02, 0.0)],
	], Vector2(0.0, 1.0), Vector2i(192, 108))
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var vignette := TextureRect.new()
	vignette.texture = UIKit.radial_texture([
		[0.0, Color(0, 0, 0, 0.0)],
		[0.52, Color(0.02, 0.014, 0.01, 0.10)],
		[0.82, Color(0.02, 0.014, 0.01, 0.42)],
		[1.0, Color(0.01, 0.008, 0.006, 0.80)],
	], Vector2(0.5, 0.46), 0.72, 128)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	add_child(UIKit.grain_overlay(0.05, 180.0))


func _build_content() -> void:
	_center = CenterContainer.new()
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_center)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_center.add_child(_box)

	var eyebrow := UIKit.kicker("An Indian Street Food Story", UIKit.FILIGREE_DIM, 11)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(eyebrow)

	_logo = UIIcons.LogoBanner.new()
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_logo)

	var tagline := UIKit.label("Crack  •  Fill  •  Dip  •  Serve", 13, Color(0.80, 0.73, 0.62))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(tagline)

	_box.add_child(UIKit.hsep(16))

	var btn_col := VBoxContainer.new()
	btn_col.custom_minimum_size = Vector2(320, 0)
	btn_col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_col.add_theme_constant_override("separation", 8)
	_box.add_child(btn_col)

	var new_game := UIKit.gold_slab("Start Game", 56)
	new_game.pressed.connect(func(): new_game_pressed.emit())
	btn_col.add_child(new_game)

	_continue_button = UIKit.slab_button("Continue", UIKit.FILIGREE, 50)
	_continue_button.pressed.connect(func(): continue_pressed.emit())
	btn_col.add_child(_continue_button)

	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 8)
	sub_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_col.add_child(sub_row)

	var settings := UIKit.slab_button("Settings", UIKit.FILIGREE_DIM, 44)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.pressed.connect(func(): _settings.open())
	sub_row.add_child(settings)

	var controls_btn := UIKit.slab_button("Controls", UIKit.FILIGREE_DIM, 44)
	controls_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_btn.pressed.connect(func(): _controls_modal.visible = true)
	sub_row.add_child(controls_btn)

	var exit_btn := UIKit.slab_button("Exit", UIKit.FILIGREE_DIM, 44)
	exit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exit_btn.pressed.connect(func(): quit_pressed.emit())
	sub_row.add_child(exit_btn)

	_box.add_child(UIKit.hsep(10))

	var credits_btn := UIKit.ghost_button("Credits", 34)
	credits_btn.custom_minimum_size = Vector2(120, 34)
	credits_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	credits_btn.pressed.connect(func(): _credits.visible = true)
	_box.add_child(credits_btn)

	var version := UIKit.label("v%s   •   GODOT 4.7   •   COMPATIBILITY" % Game.VERSION, 10, Color(0.72, 0.66, 0.57, 0.75))
	version.add_theme_font_override("font", UIKit.ui_font(600, 2))
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.offset_left = 26
	version.offset_top = -32
	version.offset_right = 420
	version.offset_bottom = -12
	add_child(version)

	# Staggered entrance, weighty and slow.
	if not Game.settings.get("reduced_motion", false):
		for i in _box.get_child_count():
			UIKit.fade_in(_box.get_child(i), 0.07 * float(i))


func _layout() -> void:
	if _logo == null:
		return
	var vp := get_viewport_rect().size
	var scale_f := clampf(vp.y / 720.0, 0.72, 1.2)
	_logo.custom_minimum_size = Vector2(460.0 * scale_f, 150.0 * scale_f)
	if _continue_button:
		_continue_button.visible = SaveManager.has_save()


func _process(delta: float) -> void:
	_time += delta


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
