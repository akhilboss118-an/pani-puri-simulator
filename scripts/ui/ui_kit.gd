class_name UIKit
extends RefCounted
## Shared visual language for every screen: warm street-food palette, chunky
## touch-friendly buttons, one theme built once.

const BG := Color("140f0c")
const PANEL := Color("241a14")
const PANEL_2 := Color("2e211a")
const PANEL_3 := Color("3a2b22")
const CARD := Color("243832")
const BORDER := Color("4a382b")
const CREAM := Color("f7e9cf")
const MUTED := Color("bda98d")
const ORANGE := Color("f28c3a")
const GOLD := Color("e0b77a")
const TEAL := Color("2fb7a5")
const RED := Color("d9532f")
const GREEN := Color("6fbf5f")

## A little vertical rhythm helper: the value is added on top of the default
## label size so headers and notes can share a single source of truth.
const HDR := 4


static func theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_stylebox("panel", "PanelContainer", style(PANEL, 16, BORDER, 1, 18))
	t.set_stylebox("panel", "Panel", style(PANEL, 16, BORDER, 1, 18))
	t.set_stylebox("background", "PanelContainer", style(PANEL_3, 4, BORDER, 1, 6))
	t.set_stylebox("background", "Panel", style(PANEL_3, 4, BORDER, 1, 6))

	t.set_stylebox("normal", "Button", style(PANEL_2, 12, BORDER, 1, 16))
	t.set_stylebox("hover", "Button", style(Color("3d2b20"), 12, ORANGE, 1, 16))
	t.set_stylebox("pressed", "Button", style(ORANGE, 12, ORANGE, 1, 16))
	t.set_stylebox("disabled", "Button", style(Color("241c17"), 12, Color("3a2d24"), 1, 16))
	t.set_stylebox("focus", "Button", style(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 16))
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color("241a14"))
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.4))
	t.set_font_size("font_size", "Button", 18)
	t.set_constant("outline_size", "Button", 0)

	t.set_stylebox("background", "ProgressBar", style(PANEL_3, 6, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("fill", "ProgressBar", style(ORANGE, 6, Color(0, 0, 0, 0), 0, 0))
	t.set_color("font_color", "ProgressBar", CREAM)

	t.set_stylebox("panel", "PopupPanel", style(PANEL, 12, BORDER, 1, 12))
	t.set_stylebox("normal", "OptionButton", style(PANEL_2, 10, BORDER, 1, 12))
	t.set_stylebox("hover", "OptionButton", style(Color("3d2b20"), 10, ORANGE, 1, 12))
	t.set_color("font_color", "OptionButton", CREAM)

	t.set_stylebox("slider", "HSlider", style(PANEL_3, 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_area", "HSlider", style(ORANGE, 4, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", style(ORANGE.lightened(0.15), 4, Color(0, 0, 0, 0), 0, 0))

	t.set_color("font_color", "CheckBox", CREAM)
	t.set_color("font_pressed_color", "CheckBox", CREAM)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)
	return t


static func style(bg: Color, radius: int = 12, border: Color = BORDER, border_width: int = 1, margin: int = 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.border_color = border
	sb.border_width_left = border_width
	sb.border_width_right = border_width
	sb.border_width_top = border_width
	sb.border_width_bottom = border_width
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin
	sb.content_margin_bottom = margin
	return sb


static func label(text: String, size: int = 18, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_height: int = 46) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_NONE
	return b


static func hsep(height: int = 10) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


static func panel(margin: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := style(PANEL, 16, BORDER, 1, margin)
	p.add_theme_stylebox_override("panel", sb)
	return p
