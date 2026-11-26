class_name SettingsPanel
extends OverlayPanel
## Sensitivity, quality, volume and accessibility options. Everything applies
## immediately and is written to user://settings.cfg.

func _init() -> void:
	title_text = "Settings"


func _build_content() -> void:
	_add_slider("Mouse sensitivity", 0.05, 0.9, 0.01, float(Game.settings.mouse_sensitivity), "mouse_sensitivity")
	_add_quality_row()
	_add_slider("Master volume", 0.0, 1.0, 0.01, float(Game.settings.master_volume), "master_volume")
	_add_check("Invert vertical look", bool(Game.settings.invert_y), "invert_y")
	_add_check("Reduced camera motion", bool(Game.settings.reduced_motion), "reduced_motion")
	content.add_child(UIKit.hsep(4))
	content.add_child(UIKit.label("Low quality disables shadows and limits crowd size - best for phones and browsers.", 14, UIKit.MUTED))
	var close_button := UIKit.button("Done", 48)
	close_button.pressed.connect(close)
	content.add_child(close_button)


func _add_slider(text: String, min_value: float, max_value: float, step: float, value: float, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name_label := UIKit.label(text, 17)
	name_label.custom_minimum_size = Vector2(210, 0)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(220, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := UIKit.label("%.2f" % value, 15, UIKit.MUTED)
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
	row.add_theme_constant_override("separation", 12)
	var name_label := UIKit.label("Graphics quality", 17)
	name_label.custom_minimum_size = Vector2(210, 0)
	row.add_child(name_label)
	var option := OptionButton.new()
	option.add_item("Low", 0)
	option.add_item("Medium", 1)
	option.add_item("High", 2)
	option.selected = clampi(int(Game.settings.quality), 0, 2)
	option.custom_minimum_size = Vector2(220, 38)
	option.item_selected.connect(func(index: int):
		Game.apply_setting("quality", index)
		if Game.root:
			Game.root.call("apply_quality")
	)
	row.add_child(option)
	content.add_child(row)


func _add_check(text: String, value: bool, key: String) -> void:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = value
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(pressed: bool): Game.apply_setting(key, pressed))
	content.add_child(check)
