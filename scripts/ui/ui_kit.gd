class_name UIKit
extends RefCounted
## Shared visual language for every screen.
##
## Premium street-food palette: espresso darks, saffron gold, jade accents and
## warm cream type. Two typefaces do the heavy lifting - Fraunces (display
## serif) for headings and Manrope (geometric sans) for everything else.

const BG := Color("0e0b09")
const PANEL := Color("1b1410")
const PANEL_2 := Color("251b15")
const PANEL_3 := Color("33251c")
const CARD := Color("20302b")
const BORDER := Color("5a4630")
const CREAM := Color("f8ecd7")
const MUTED := Color("b9a68c")
const ORANGE := Color("f0913f")
const GOLD := Color("e6c07d")
const TEAL := Color("38c2ae")
const RED := Color("e05a38")
const GREEN := Color("77c86a")

const INK := Color("1a120c")
const COPPER := Color("b9793f")
const PAPER := Color("f6e7cb")
const PAPER_INK := Color("2a1c12")

## A little vertical rhythm helper: the value is added on top of the default
## label size so headers and notes can share a single source of truth.
const HDR := 4

const DISPLAY_PATH := "res://assets/fonts/Fraunces-Variable.ttf"
const UI_PATH := "res://assets/fonts/Manrope-Variable.ttf"

static var _font_cache: Dictionary = {}


# ------------------------------------------------------------------- fonts

static func display_font(weight: int = 700, tracking: int = 0) -> Font:
	return _font(DISPLAY_PATH, weight, tracking, 96.0)


static func ui_font(weight: int = 500, tracking: int = 0) -> Font:
	return _font(UI_PATH, weight, tracking, 0.0)


static func _font(path: String, weight: int, tracking: int, optical: float) -> Font:
	var key := "%s_%d_%d_%d" % [path, weight, tracking, int(optical)]
	if _font_cache.has(key):
		return _font_cache[key]
	var fallback: Font = ThemeDB.fallback_font
	if not ResourceLoader.exists(path):
		return fallback
	var base: Resource = load(path)
	if not (base is Font):
		return fallback
	var variation := FontVariation.new()
	variation.base_font = base as Font
	var axes := {"wght": weight}
	if optical > 0.0:
		axes["opsz"] = optical
		axes["SOFT"] = 30
	variation.variation_opentype = axes
	variation.spacing_glyph = tracking
	_font_cache[key] = variation
	return variation


# ------------------------------------------------------------------- theme

static func theme() -> Theme:
	var t := Theme.new()
	t.default_font = ui_font(500)
	t.default_font_size = 17
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_stylebox("panel", "PanelContainer", panel_style(18))
	t.set_stylebox("panel", "Panel", panel_style(18))
	t.set_stylebox("background", "PanelContainer", style(PANEL_3, 8, BORDER, 1, 8))
	t.set_stylebox("background", "Panel", style(PANEL_3, 8, BORDER, 1, 8))

	# buttons -------------------------------------------------------------
	t.set_stylebox("normal", "Button", button_style(PANEL_2, BORDER, CREAM))
	t.set_stylebox("hover", "Button", button_style(Color("3a2a1e"), GOLD, Color.WHITE))
	t.set_stylebox("pressed", "Button", button_style(GOLD, GOLD.lightened(0.2), INK))
	t.set_stylebox("disabled", "Button", button_style(Color("1f1814"), Color("352a22"), MUTED.darkened(0.35)))
	t.set_stylebox("focus", "Button", style(Color(0, 0, 0, 0), 12, Color(0, 0, 0, 0), 0, 14))
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", MUTED.darkened(0.45))
	t.set_font("font", "Button", ui_font(700, 1))
	t.set_font_size("font_size", "Button", 17)
	t.set_constant("outline_size", "Button", 0)
	t.set_constant("h_separation", "Button", 8)

	# progress ------------------------------------------------------------
	t.set_stylebox("background", "ProgressBar", style(Color("241a14"), 8, Color(0, 0, 0, 0.4), 0, 0))
	t.set_stylebox("fill", "ProgressBar", bar_fill(GOLD))
	t.set_color("font_color", "ProgressBar", CREAM)

	# inputs --------------------------------------------------------------
	t.set_stylebox("panel", "PopupPanel", style(PANEL, 14, BORDER, 1, 12))
	t.set_stylebox("panel", "PopupMenu", style(PANEL, 14, BORDER, 1, 8))
	t.set_stylebox("hover", "PopupMenu", style(Color("3a2a1e"), 8, GOLD, 1, 8))
	t.set_stylebox("normal", "OptionButton", button_style(PANEL_2, BORDER, CREAM))
	t.set_stylebox("hover", "OptionButton", button_style(Color("3a2a1e"), GOLD, Color.WHITE))
	t.set_stylebox("pressed", "OptionButton", button_style(Color("3a2a1e"), GOLD, Color.WHITE))
	t.set_stylebox("focus", "OptionButton", style(Color(0, 0, 0, 0), 10, Color(0, 0, 0, 0), 0, 12))
	t.set_color("font_color", "OptionButton", CREAM)
	t.set_font("font", "OptionButton", ui_font(600, 1))
	t.set_stylebox("normal", "LineEdit", input_style())
	t.set_stylebox("focus", "LineEdit", input_style(GOLD))
	t.set_color("font_color", "LineEdit", CREAM)
	t.set_color("font_placeholder_color", "LineEdit", MUTED.darkened(0.15))
	t.set_stylebox("normal", "TextEdit", input_style())
	t.set_stylebox("focus", "TextEdit", input_style(GOLD))
	t.set_color("font_color", "TextEdit", CREAM)

	t.set_stylebox("slider", "HSlider", style(Color("241a14"), 5, Color(0, 0, 0, 0.35), 0, 0))
	t.set_stylebox("grabber_area", "HSlider", bar_fill(GOLD, 5))
	t.set_stylebox("grabber_area_highlight", "HSlider", bar_fill(GOLD.lightened(0.18), 5))

	t.set_color("font_color", "CheckBox", CREAM)
	t.set_color("font_pressed_color", "CheckBox", CREAM)
	t.set_color("font_hover_color", "CheckBox", Color.WHITE)

	# scrollbars ----------------------------------------------------------
	t.set_stylebox("scroll", "VScrollBar", style(Color(0, 0, 0, 0.18), 6, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber", "VScrollBar", style(GOLD.darkened(0.35), 6, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", style(GOLD, 6, Color(0, 0, 0, 0), 0, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", style(GOLD.lightened(0.1), 6, Color(0, 0, 0, 0), 0, 0))

	# tooltips ------------------------------------------------------------
	t.set_stylebox("panel", "TooltipPanel", style(PANEL, 10, BORDER, 1, 10))
	t.set_color("font_color", "TooltipLabel", CREAM)
	return t


static func panel_style(margin: int = 18) -> StyleBoxFlat:
	var sb := style(Color(0.086, 0.067, 0.055, 0.97), 20, Color("5f4a32"), 1, margin)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 10)
	sb.anti_aliasing = true
	return sb


static func button_style(bg: Color, border: Color, _font_color: Color) -> StyleBoxFlat:
	var sb := style(bg, 12, border, 1, 15)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.shadow_color = Color(0, 0, 0, 0.32)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.anti_aliasing = true
	return sb


static func input_style(focus: Color = BORDER) -> StyleBoxFlat:
	return style(Color("191210"), 10, focus, 1, 12)


static func bar_fill(color: Color, radius: int = 8) -> StyleBoxFlat:
	var sb := style(color, radius, color.lightened(0.25), 0, 0)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.shadow_color = Color(color.r, color.g, color.b, 0.35)
	sb.shadow_size = 4
	return sb


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
	sb.anti_aliasing = true
	return sb


# ----------------------------------------------------------------- widgets

static func label(text: String, size: int = 18, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.text = I18n.t(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", ui_font(500))
	return l


## Large editorial heading in Fraunces.
static func heading(text: String, size: int = 34, color: Color = CREAM, weight: int = 700) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", display_font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


## Small all-caps eyebrow text with generous tracking.
static func kicker(text: String, color: Color = TEAL, size: int = 12) -> Label:
	var l := Label.new()
	l.text = I18n.t(text).to_upper()
	l.add_theme_font_override("font", ui_font(700, 3))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, min_height: int = 46) -> Button:
	var b := Button.new()
	b.text = I18n.t(text)
	b.custom_minimum_size = Vector2(0, min_height)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


## Gold call-to-action. The one button a screen is allowed to shout with.
static func primary_button(text: String, min_height: int = 52) -> Button:
	var b := button(text, min_height)
	b.add_theme_stylebox_override("normal", button_style(GOLD, GOLD.lightened(0.3), INK))
	b.add_theme_stylebox_override("hover", button_style(GOLD.lightened(0.14), CREAM, INK))
	b.add_theme_stylebox_override("pressed", button_style(COPPER, GOLD, INK))
	b.add_theme_stylebox_override("disabled", button_style(Color("2a2118"), Color("3a2d22"), MUTED))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	b.add_theme_font_override("font", ui_font(800, 1))
	b.add_theme_font_size_override("font_size", 18)
	return b


## Quiet secondary action: hairline border, no fill.
static func ghost_button(text: String, min_height: int = 44) -> Button:
	var b := button(text, min_height)
	var normal := style(Color(1, 1, 1, 0.03), 12, Color(1, 0.95, 0.85, 0.16), 1, 15)
	var hover := style(Color(1, 0.9, 0.75, 0.08), 12, GOLD, 1, 15)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", style(Color(1, 0.9, 0.75, 0.14), 12, GOLD, 1, 15))
	b.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_font_override("font", ui_font(600, 1))
	return b


static func hsep(height: int = 10) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# ------------------------------------------------------- generated gradients
#
# Godot's GradientTexture2D is unreliable for radial fills (a fully transparent
# black stop comes back as opaque grey), which turns a vignette into a grey
# wash. These helpers bake the gradient into an Image instead, so every stop
# lands exactly where the design says it should.

static func _ramp(stops: Array, t: float) -> Color:
	var count := stops.size()
	if count == 0:
		return Color(0, 0, 0, 0)
	var first: Array = stops[0]
	var first_at := float(first[0])
	var first_color: Color = first[1]
	if t <= first_at:
		return first_color
	var last: Array = stops[count - 1]
	var last_at := float(last[0])
	var last_color: Color = last[1]
	if t >= last_at:
		return last_color
	for i in count - 1:
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		var a_at := float(a[0])
		var b_at := float(b[0])
		if t >= a_at and t <= b_at:
			var a_color: Color = a[1]
			var b_color: Color = b[1]
			var k := (t - a_at) / maxf(b_at - a_at, 0.00001)
			return a_color.lerp(b_color, k)
	return last_color


## Radial ramp. `stops` are [offset, Color] pairs from the centre outwards.
static func radial_texture(stops: Array, center: Vector2, radius: float, size: int = 128) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var safe_radius := maxf(radius, 0.0001)
	for y in size:
		var v := (float(y) + 0.5) / float(size)
		for x in size:
			var u := (float(x) + 0.5) / float(size)
			var t := clampf(Vector2(u - center.x, v - center.y).length() / safe_radius, 0.0, 1.0)
			img.set_pixel(x, y, _ramp(stops, t))
	return ImageTexture.create_from_image(img)


## Directional ramp along `dir` (UV space, its length is the ramp extent).
static func linear_texture(stops: Array, dir: Vector2, size: Vector2i) -> ImageTexture:
	var w := maxi(size.x, 2)
	var h := maxi(size.y, 2)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var denom := maxf(dir.dot(dir), 0.00001)
	for y in h:
		var v := (float(y) + 0.5) / float(h)
		for x in w:
			var u := (float(x) + 0.5) / float(w)
			var t := clampf((u * dir.x + v * dir.y) / denom, 0.0, 1.0)
			img.set_pixel(x, y, _ramp(stops, t))
	return ImageTexture.create_from_image(img)


static var _divider_cache: Dictionary = {}


static func divider(color: Color = GOLD, alpha: float = 0.45) -> Control:
	var key := "%s_%.2f" % [color.to_html(), alpha]
	var tex: Texture2D
	if _divider_cache.has(key):
		tex = _divider_cache[key]
	else:
		tex = linear_texture([
			[0.0, Color(color.r, color.g, color.b, 0.0)],
			[0.5, Color(color.r, color.g, color.b, alpha)],
			[1.0, Color(color.r, color.g, color.b, 0.0)],
		], Vector2(1, 0), Vector2i(256, 2))
		_divider_cache[key] = tex
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(0, 1)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func panel(margin: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(margin))
	return p


## Compact translucent pill used for HUD chips and meta rows.
static func chip(text: String, color: Color = GOLD, size: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := style(Color(0.07, 0.055, 0.045, 0.78), 999, Color(color.r, color.g, color.b, 0.35), 1, 0)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(kicker(text, color, size))
	return p
