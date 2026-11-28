class_name UIKit
extends RefCounted
## Shared visual language for every screen.
##
## Premium street-food palette: espresso darks, saffron gold, jade accents and
## warm cream type. Two typefaces do the heavy lifting - Fraunces (display
## serif) for headings and Manrope (geometric sans) for everything else.

const BG := Color("0e0b09")
const PANEL := Color("19130f")
const PANEL_2 := Color("261c15")
const PANEL_3 := Color("34261c")
const CARD := Color("20302b")
const BORDER := Color("6e5335")
const CREAM := Color("fcf3e2")
const MUTED := Color("cbb79b")
const ORANGE := Color("f28836")
const GOLD := Color("f2bd52")
const TEAL := Color("38c2ae")
const RED := Color("e45e3c")
const GREEN := Color("66c968")

const INK := Color("1a120c")
const COPPER := Color("c68042")
const PAPER := Color("faecd0")
const PAPER_INK := Color("26180f")

## AAA layer: smoked glass slabs, aged-gold filigree and cinematic fades.
const SMOKE := Color("0b0908")
const SMOKE_2 := Color("131010")
const FILIGREE := Color("c9a35c")
const FILIGREE_DIM := Color("8a6a3a")
const STEEL := Color("a9b6c2")
const EMBER := Color("ff8a3c")

## Sharp corners everywhere - rounded pills read as casual, square slabs read
## as cinematic. Screens that want a softer edge pass their own radius.
const SHARP := 2

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
	t.set_stylebox("normal", "Button", button_style(Color(0.05, 0.04, 0.032, 0.80), Color(FILIGREE.r, FILIGREE.g, FILIGREE.b, 0.38), CREAM))
	t.set_stylebox("hover", "Button", button_style(Color(0.79, 0.64, 0.36, 0.20), FILIGREE, Color.WHITE))
	t.set_stylebox("pressed", "Button", button_style(GOLD, GOLD.lightened(0.2), INK))
	t.set_stylebox("disabled", "Button", button_style(Color(0.04, 0.034, 0.03, 0.6), Color(1, 1, 1, 0.08), Color("948371")))
	t.set_stylebox("focus", "Button", style(Color(0, 0, 0, 0), SHARP, Color(0, 0, 0, 0), 0, 14))
	t.set_color("font_color", "Button", Color(0.93, 0.89, 0.82))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("948371"))
	t.set_font("font", "Button", ui_font(700, 2))
	t.set_font_size("font_size", "Button", 14)
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
	var sb := style(Color(0.035, 0.028, 0.024, 0.95), SHARP, Color(FILIGREE.r, FILIGREE.g, FILIGREE.b, 0.34), 1, margin)
	sb.shadow_color = Color(0, 0, 0, 0.66)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 10)
	sb.anti_aliasing = true
	return sb


## Legacy name kept for the credits/controls modals: now an AAA action slab.
static func wood_menu_button(text: String, min_height: int = 50) -> Button:
	var b := slab_button(text, FILIGREE, min_height)
	b.add_theme_font_size_override("font_size", 17)
	return b


static func button_style(bg: Color, border: Color, _font_color: Color) -> StyleBoxFlat:
	var sb := style(bg, SHARP, border, 1, 15)
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
	b.text = I18n.t(text).to_upper()
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
	b.add_theme_stylebox_override("disabled", button_style(Color("2e241b"), Color("4a3a2b"), Color("948371")))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color("948371"))
	b.add_theme_font_override("font", ui_font(800, 1))
	b.add_theme_font_size_override("font_size", 18)
	return b


## Emerald-green action button for purchasing / refilling.
static func action_button(text: String, min_height: int = 42) -> Button:
	var b := button(text, min_height)
	b.add_theme_stylebox_override("normal", button_style(Color("2a7a3b"), Color("66c968"), Color.WHITE))
	b.add_theme_stylebox_override("hover", button_style(Color("349648"), Color("8ee090"), Color.WHITE))
	b.add_theme_stylebox_override("pressed", button_style(Color("205e2d"), Color("66c968"), Color.WHITE))
	b.add_theme_stylebox_override("disabled", button_style(Color("221a15"), Color("46382c"), Color("8e7e6c")))
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("8e7e6c"))
	b.add_theme_font_override("font", ui_font(700, 0))
	b.add_theme_font_size_override("font_size", 15)
	return b


## Saffron-gold header pill badge inspired by warm street signage.
static func gold_pill(text: String, bg: Color = GOLD, fg: Color = INK, size: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := style(bg, SHARP, bg.lightened(0.25), 1, 0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = I18n.t(text)
	l.add_theme_font_override("font", ui_font(800, 1))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", fg)
	p.add_child(l)
	return p


## Quiet secondary action: hairline border, no fill.
static func ghost_button(text: String, min_height: int = 44) -> Button:
	var b := button(text, min_height)
	var normal := style(Color(1, 1, 1, 0.03), SHARP, Color(1, 0.95, 0.85, 0.16), 1, 15)
	var hover := style(Color(1, 0.9, 0.75, 0.08), SHARP, GOLD, 1, 15)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", style(Color(1, 0.9, 0.75, 0.14), SHARP, GOLD, 1, 15))
	b.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_font_override("font", ui_font(600, 2))
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
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var sb := style(Color(0.09, 0.07, 0.055, 0.88), SHARP, Color(color.r, color.g, color.b, 0.58), 1, 0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(kicker(text, color, size))
	return p


# --------------------------------------------------------- AAA primitives
#
# The look is "cinematic dark UI": smoked glass, square slabs, a single aged
# gold hairline per surface, tapered filigree rules and corner brackets. Motion
# is slow and weighty rather than bouncy.

## Tapered gold rule with a small diamond at its centre. Reads as an engraved
## divider at any width and costs one _draw() call.
class Ornament extends Control:
	var color: Color = Color("c9a35c")
	var line_alpha: float = 0.6
	var with_diamond: bool = true
	var diamond_size: float = 4.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(0, 9)

	func _draw() -> void:
		var w := size.x
		var cy := floorf(size.y * 0.5) + 0.5
		if w <= 4.0:
			return
		var half := w * 0.5
		var cols := int(maxf(half, 8.0))
		for i in cols:
			var t := float(i) / float(cols)
			var a := line_alpha * (1.0 - t) * (1.0 - t * 0.25)
			var c := Color(color.r, color.g, color.b, a)
			draw_rect(Rect2(half - float(i) - 1.0, cy, 1.0, 1.0), c, true)
			draw_rect(Rect2(half + float(i), cy, 1.0, 1.0), c, true)
		if with_diamond:
			var d := diamond_size
			draw_colored_polygon(PackedVector2Array([
				Vector2(half, cy - d),
				Vector2(half + d, cy),
				Vector2(half, cy + d),
				Vector2(half - d, cy),
			]), Color(color.r, color.g, color.b, minf(line_alpha + 0.3, 1.0)))


## Four L-shaped corner brackets. Sits on top of a panel as a sibling and is
## purely decorative - mouse input passes straight through.
class CornerFrame extends Control:
	var color: Color = Color("c9a35c")
	var alpha: float = 0.5
	var inset: float = 6.0
	var arm: float = 16.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
		if r.size.x <= arm * 2.0 or r.size.y <= arm * 2.0:
			return
		var c := Color(color.r, color.g, color.b, alpha)
		var a := minf(arm, minf(r.size.x, r.size.y) * 0.35)
		var p := r.position
		var e := r.position + r.size
		draw_line(Vector2(p.x, p.y + a), p, c, 1.0)
		draw_line(p, Vector2(p.x + a, p.y), c, 1.0)
		draw_line(Vector2(e.x - a, p.y), Vector2(e.x, p.y), c, 1.0)
		draw_line(Vector2(e.x, p.y), Vector2(e.x, p.y + a), c, 1.0)
		draw_line(Vector2(p.x, e.y - a), Vector2(p.x, e.y), c, 1.0)
		draw_line(Vector2(p.x, e.y), Vector2(p.x + a, e.y), c, 1.0)
		draw_line(Vector2(e.x - a, e.y), e, c, 1.0)
		draw_line(e, Vector2(e.x, e.y - a), c, 1.0)


## Thin slab used for every HUD surface: near-black, one hairline, no rounding.
static func slab_style(alpha: float = 0.82, margin: int = 10, border: Color = FILIGREE_DIM) -> StyleBoxFlat:
	var sb := style(Color(0.035, 0.028, 0.024, alpha), SHARP, Color(border.r, border.g, border.b, 0.55), 1, margin)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	return sb


## Modal surface: smoked glass, gold hairline, deep shadow.
static func frame_style(margin: int = 26) -> StyleBoxFlat:
	var sb := style(Color(0.032, 0.026, 0.022, 0.955), 3, Color(FILIGREE.r, FILIGREE.g, FILIGREE.b, 0.42), 1, margin)
	sb.shadow_color = Color(0, 0, 0, 0.7)
	sb.shadow_size = 34
	sb.shadow_offset = Vector2(0, 14)
	sb.anti_aliasing = true
	return sb


## Big, quiet action slab: square, one gold edge, uppercase tracking.
static func slab_button(text: String, accent: Color = FILIGREE, min_height: int = 52) -> Button:
	var b := button(text, min_height)
	b.text = I18n.t(text).to_upper()
	var normal := style(Color(0.05, 0.04, 0.032, 0.78), SHARP, Color(accent.r, accent.g, accent.b, 0.55), 1, 20)
	normal.border_width_left = 3
	var hover := style(Color(accent.r, accent.g, accent.b, 0.16), SHARP, accent, 1, 20)
	hover.border_width_left = 3
	var pressed := style(Color(accent.r, accent.g, accent.b, 0.9), SHARP, accent.lightened(0.25), 1, 20)
	pressed.border_width_left = 3
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", style(Color(0.04, 0.034, 0.03, 0.6), SHARP, Color(1, 1, 1, 0.08), 1, 20))
	b.add_theme_color_override("font_color", Color(0.93, 0.89, 0.82))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.44))
	b.add_theme_font_override("font", ui_font(700, 2))
	b.add_theme_font_size_override("font_size", 16)
	return b


## The one filled call to action on a screen.
static func gold_slab(text: String, min_height: int = 54) -> Button:
	var b := slab_button(text, GOLD, min_height)
	b.add_theme_stylebox_override("normal", style(Color(GOLD.r, GOLD.g, GOLD.b, 0.92), SHARP, GOLD.lightened(0.25), 1, 20))
	b.add_theme_stylebox_override("hover", style(GOLD.lightened(0.12), SHARP, CREAM, 1, 20))
	b.add_theme_stylebox_override("pressed", style(COPPER, SHARP, GOLD, 1, 20))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_font_override("font", ui_font(800, 2))
	return b


## Small caps section marker with a hairline trailing off to the right.
static func section_header(text: String, color: Color = FILIGREE) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var l := kicker(text, color, 10)
	row.add_child(l)
	var rule := Ornament.new()
	rule.color = color
	rule.line_alpha = 0.28
	rule.with_diamond = false
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.custom_minimum_size = Vector2(24, 7)
	row.add_child(rule)
	return row


## Thin cinematic progress bar (3px, square, bright leading edge).
static func thin_bar(fill: Color, height: int = 3) -> StyleBoxFlat:
	var sb := style(fill, 1, Color(fill.r, fill.g, fill.b, 0.9), 0, 0)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.shadow_color = Color(fill.r, fill.g, fill.b, 0.45)
	sb.shadow_size = 3
	sb.anti_aliasing = false
	return sb


static func bar_track(height: int = 3) -> StyleBoxFlat:
	var sb := style(Color(1, 1, 1, 0.10), 1, Color(1, 1, 1, 0.06), 0, 0)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.anti_aliasing = false
	return sb


static var _grain_tex: ImageTexture


## Deterministic film grain, tiled. One 96x96 texture for the whole game.
static func grain_texture() -> ImageTexture:
	if _grain_tex != null:
		return _grain_tex
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261128
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var v := rng.randf()
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	_grain_tex = ImageTexture.create_from_image(img)
	return _grain_tex


## Full-rect grain layer. `alpha` is the strength, `scale_px` the tile size.
static func grain_overlay(alpha: float = 0.045, scale_px: float = 220.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = grain_texture()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_TILE
	r.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.modulate = Color(1, 1, 1, alpha)
	r.set_meta("tile_px", scale_px)
	return r


## Cinematic entrance: fade in with a barely-there scale settle. Alpha and
## scale are safe to animate inside a Container (position is not).
static func fade_in(node: CanvasItem, delay: float = 0.0, settle: float = 0.985) -> void:
	if node == null or not is_instance_valid(node):
		return
	var target_alpha := node.modulate.a
	node.modulate.a = 0.0
	var control := node as Control
	if control != null:
		control.pivot_offset = control.size * 0.5
		control.scale = Vector2(settle, settle)
	var tween := node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", target_alpha, 0.5).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if control != null:
		tween.tween_property(control, "scale", Vector2.ONE, 0.6).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
