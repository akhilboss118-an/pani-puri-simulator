class_name SettingsPanel
extends OverlayPanel
## Sensitivity, quality, volume and accessibility options. Everything applies
## immediately and is written to user://settings.cfg.

func _init() -> void:
	title_text = "Settings"


func _build_content() -> void:
	content.add_child(UIKit.section_header("Controls", UIKit.FILIGREE))

	_add_slider("Mouse sensitivity", 0.05, 0.9, 0.01, float(Game.settings.mouse_sensitivity), "mouse_sensitivity")
	_add_check("Invert vertical look", bool(Game.settings.invert_y), "invert_y")
	_add_check("Reduced camera motion", bool(Game.settings.reduced_motion), "reduced_motion")

	content.add_child(UIKit.section_header("Display", UIKit.FILIGREE_DIM))
	_add_quality_row()
	_add_language_row()

	content.add_child(UIKit.section_header("Audio", UIKit.FILIGREE_DIM))
	_add_slider("Master volume", 0.0, 1.0, 0.01, float(Game.settings.master_volume), "master_volume")

	content.add_child(UIKit.hsep(6))
	var note := UIKit.label("Low quality disables shadows and limits crowd size - best for phones and browsers.", 13, UIKit.MUTED)
	note.add_theme_font_override("font", UIKit.ui_font(600, 2))
	content.add_child(note)

	content.add_child(UIKit.hsep(4))
	var close_button := UIKit.slab_button("Done", UIKit.FILIGREE_DIM, 44)
	close_button.pressed.connect(close)
	content.add_child(close_button)


func _add_slider(text: String, min_value: float, max_value: float, step: float, value: float, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := UIKit.kicker(text, UIKit.MUTED, 12)
	name_label.custom_minimum_size = Vector2(180, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(240, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := UIKit.label("%.2f" % value, 14, UIKit.MUTED)
	value_label.custom_minimum_size = Vector2(54, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	slider.value_changed.connect(func(v: float):
		value_label.text = "%.2f" % v
		Game.apply_setting(key, v)
	)
	content.add_child(row)


func _add_quality_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := UIKit.kicker("Graphics quality", UIKit.MUTED, 12)
	name_label.custom_minimum_size = Vector2(180, 0)
	row.add_child(name_label)
	var option := OptionButton.new()
	option.add_item("Low", 0)
	option.add_item("Medium", 1)
	option.add_item("High", 2)
	option.selected = clampi(int(Game.settings.quality), 0, 2)
	option.custom_minimum_size = Vector2(220, 36)
	option.item_selected.connect(func(index: int):
		Game.apply_setting("quality", index)
		if Game.root:
			Game.root.call("apply_quality")
	)
	row.add_child(option)
	content.add_child(row)


func _add_language_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_label := UIKit.kicker("Language", UIKit.MUTED, 12)
	name_label.custom_minimum_size = Vector2(180, 0)
	row.add_child(name_label)
	var option := OptionButton.new()
	option.add_item("English", 0)
	option.add_item("हिंदी", 1)
	option.selected = 1 if String(Game.settings.get("locale", "en")) == "hi" else 0
	option.custom_minimum_size = Vector2(220, 36)
	option.item_selected.connect(func(index: int):
		Game.apply_setting("locale", "hi" if index == 1 else "en")
	)
	row.add_child(option)
	content.add_child(row)


func _add_check(text: String, value: bool, key: String) -> void:
	var check := CheckBox.new()
	check.text = I18n.t(text).to_upper()
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(pressed: bool): Game.apply_setting(key, pressed))
	content.add_child(check)
