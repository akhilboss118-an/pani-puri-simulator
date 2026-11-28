extends RefCounted
## Custom vector-drawn UI icons, logo banner, preparation stage emblems,
## and live street minimap matching the warm illustrated style.


class IconGlyph extends Control:
	var kind: String = "star"
	var accent: Color = Color.WHITE

	func _init(k: String = "star", sz: Vector2 = Vector2(24, 24), col: Color = Color.WHITE) -> void:
		kind = k
		accent = col
		custom_minimum_size = sz
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.44
		match kind:
			"cash":
				var rect := Rect2(c.x - r * 1.05, c.y - r * 0.68, r * 2.1, r * 1.36)
				draw_rect(rect, Color("2e9c46"), true)
				draw_rect(rect, Color("86e896"), false, 1.6)
				draw_circle(c, r * 0.36, Color("1f6f31"))
				draw_circle(c, r * 0.16, Color("b8f5c2"))
			"sun":
				for i in 8:
					var a := TAU * float(i) / 8.0
					var p0 := c + Vector2(cos(a), sin(a)) * (r * 0.62)
					var p1 := c + Vector2(cos(a), sin(a)) * (r * 0.96)
					draw_line(p0, p1, Color("ffd447"), 2.0, true)
				draw_circle(c, r * 0.46, Color("ffc82e"))
			"moon":
				draw_circle(c, r * 0.72, Color("d8e8ff"))
				draw_circle(c + Vector2(r * 0.32, -r * 0.24), r * 0.58, Color(0.08, 0.06, 0.05, 1.0))
			"rain":
				draw_circle(c + Vector2(-r * 0.25, -r * 0.1), r * 0.42, Color("9fc2de"))
				draw_circle(c + Vector2(r * 0.2, -r * 0.15), r * 0.48, Color("b5d2ea"))
				for x in [-0.35, 0.0, 0.35]:
					draw_line(c + Vector2(r * x, r * 0.35), c + Vector2(r * x - r * 0.12, r * 0.75), Color("5eb6ff"), 1.8, true)
			"happy":
				draw_circle(c, r * 0.88, Color("ffd23f"))
				draw_arc(c, r * 0.88, 0.0, TAU, 24, Color("8a5314"), 1.6, true)
				draw_circle(c + Vector2(-r * 0.3, -r * 0.2), r * 0.12, Color("2e1808"))
				draw_circle(c + Vector2(r * 0.3, -r * 0.2), r * 0.12, Color("2e1808"))
				draw_arc(c + Vector2(0, r * 0.04), r * 0.42, 0.25, PI - 0.25, 14, Color("2e1808"), 2.0, true)
			"star":
				_draw_star(c, r * 0.92, r * 0.42, Color("ffd23f"), Color("8a5314"))
			"clock":
				draw_circle(c, r * 0.86, Color("e8f4ff"))
				draw_arc(c, r * 0.86, 0.0, TAU, 24, Color("3c82d6"), 2.2, true)
				draw_line(c, c + Vector2(0, -r * 0.52), Color("244a7c"), 2.0, true)
				draw_line(c, c + Vector2(r * 0.38, r * 0.14), Color("244a7c"), 2.0, true)
			"chart":
				var pts := PackedVector2Array([
					Vector2(c.x - r * 0.9, c.y + r * 0.6),
					Vector2(c.x - r * 0.2, c.y + r * 0.1),
					Vector2(c.x + r * 0.2, c.y + r * 0.3),
					Vector2(c.x + r * 0.85, c.y - r * 0.55),
				])
				draw_polyline(pts, Color("56d96c"), 3.0, true)
				draw_circle(pts[3], 3.0, Color("8ef59e"))
			"hand":
				draw_circle(c + Vector2(0, r * 0.2), r * 0.42, accent)
				for i in 4:
					var fx := -0.38 + float(i) * 0.24
					var fh := 0.58 if (i == 1 or i == 2) else 0.46
					draw_line(c + Vector2(r * fx, r * 0.05), c + Vector2(r * fx, -r * fh), accent, maxf(2.6, r * 0.22), true)
				draw_line(c + Vector2(-r * 0.32, r * 0.3), c + Vector2(-r * 0.72, -r * 0.02), accent, maxf(2.6, r * 0.22), true)
			"wasd":
				_draw_key(Rect2(c.x - r * 0.32, c.y - r * 0.88, r * 0.64, r * 0.64), "W", r * 0.4)
				_draw_key(Rect2(c.x - r * 1.02, c.y - r * 0.14, r * 0.64, r * 0.64), "A", r * 0.4)
				_draw_key(Rect2(c.x - r * 0.32, c.y - r * 0.14, r * 0.64, r * 0.64), "S", r * 0.4)
				_draw_key(Rect2(c.x + r * 0.38, c.y - r * 0.14, r * 0.64, r * 0.64), "D", r * 0.4)
			"mouse":
				var mrect := Rect2(c.x - r * 0.48, c.y - r * 0.76, r * 0.96, r * 1.52)
				draw_rect(mrect, Color(1, 1, 1, 0.12), true)
				draw_rect(mrect, Color("fff3dc"), false, 2.0)
				draw_line(Vector2(c.x, mrect.position.y), Vector2(c.x, c.y - r * 0.1), Color("fff3dc"), 1.6)
				draw_line(Vector2(mrect.position.x, c.y - r * 0.1), Vector2(mrect.end.x, c.y - r * 0.1), Color("fff3dc"), 1.6)
				draw_circle(Vector2(c.x, c.y - r * 0.35), 2.2, Color("ffd23f"))
			"key_e":
				_draw_key(Rect2(c.x - r * 0.62, c.y - r * 0.62, r * 1.24, r * 1.24), "E", r * 0.65)
			"key_esc":
				_draw_key(Rect2(c.x - r * 0.85, c.y - r * 0.56, r * 1.7, r * 1.12), "Esc", r * 0.48)
			"touch":
				var prect := Rect2(c.x - r * 0.46, c.y - r * 0.8, r * 0.92, r * 1.6)
				draw_rect(prect, Color(1, 1, 1, 0.12), true)
				draw_rect(prect, Color("fff3dc"), false, 2.0)
				draw_circle(c, r * 0.25, Color("ffd23f"))
			"ingredients":
				draw_circle(c + Vector2(0, r * 0.15), r * 0.68, Color("c47d38"))
				draw_circle(c + Vector2(-r * 0.2, -r * 0.18), r * 0.3, Color("66c968"))
				draw_circle(c + Vector2(r * 0.2, -r * 0.2), r * 0.32, Color("e8a642"))
			"upgrades":
				var roof := PackedVector2Array([
					Vector2(c.x, c.y - r * 0.82),
					Vector2(c.x + r * 0.82, c.y - r * 0.05),
					Vector2(c.x - r * 0.82, c.y - r * 0.05),
				])
				draw_colored_polygon(roof, Color("ffd23f"))
				draw_rect(Rect2(c.x - r * 0.55, c.y - r * 0.05, r * 1.1, r * 0.78), Color("d98c42"), true)
			"inventory":
				var brect := Rect2(c.x - r * 0.72, c.y - r * 0.58, r * 1.44, r * 1.24)
				draw_rect(brect, Color("b87336"), true)
				draw_rect(brect, Color("f2bd52"), false, 1.8)
				draw_line(Vector2(brect.position.x, c.y - r * 0.12), Vector2(brect.end.x, c.y - r * 0.12), Color("f2bd52"), 1.6)
			"stats":
				var heights := [0.65, 1.1, 1.45]
				for i in 3:
					var h: float = float(heights[i]) * r
					var x: float = c.x - r * 0.68 + float(i) * r * 0.52
					draw_rect(Rect2(x, c.y + r * 0.72 - h, r * 0.36, h), Color("66c968") if i == 2 else Color("f2bd52"), true)
			"stall":
				draw_rect(Rect2(c.x - r * 0.75, c.y - r * 0.7, r * 1.5, r * 0.4), Color("e45e3c"), true)
				draw_rect(Rect2(c.x - r * 0.62, c.y + r * 0.05, r * 1.24, r * 0.65), Color("8a5024"), true)
				draw_rect(Rect2(c.x - r * 0.52, c.y - r * 0.3, r * 1.04, r * 0.35), Color("38c2ae"), true)
			"pani":
				draw_circle(c, r * 0.78, Color("c4cbd0"))
				draw_circle(c, r * 0.58, Color("5a9c36"))
				draw_circle(c + Vector2(-r * 0.18, -r * 0.14), r * 0.12, Color("8ee068"))
			"decor":
				draw_circle(c, r * 0.76, Color("f08a34"))
				draw_circle(c, r * 0.45, Color("ffd447"))
				draw_circle(c, r * 0.18, Color("e45e3c"))
			"puri_0", "puri_1", "puri_2", "puri_3", "puri_4":
				_draw_puri_stage(c, r, int(kind.substr(5, 1)))
			"logo_emblem":
				_draw_logo_emblem(c, r)

	func _draw_key(rect: Rect2, label: String, fsize: float) -> void:
		draw_rect(rect, Color("f5ebd6"), true)
		draw_rect(rect, Color("5a3818"), false, 1.4)
		var font := UIKit.ui_font(800, 0)
		var sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, int(maxf(9.0, fsize)))
		draw_string(font, rect.position + Vector2((rect.size.x - sz.x) * 0.5, rect.size.y * 0.74), label, HORIZONTAL_ALIGNMENT_LEFT, -1, int(maxf(9.0, fsize)), Color("26160a"))

	func _draw_star(c: Vector2, outer_r: float, inner_r: float, fill: Color, stroke: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var a := -PI * 0.5 + float(i) * PI / 5.0
			var rad := outer_r if i % 2 == 0 else inner_r
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, stroke, 1.4, true)

	func _draw_puri_stage(c: Vector2, r: float, stage: int) -> void:
		# Outer crispy puri sphere
		draw_circle(c + Vector2(0, 1.5), r * 0.92, Color(0, 0, 0, 0.35))
		draw_circle(c, r * 0.88, Color("db923b"))
		draw_arc(c, r * 0.88, 0.0, TAU, 20, Color("f6c86e"), 1.6, true)
		if stage >= 0:
			# Cracked hollow cavity
			draw_circle(c + Vector2(0, -r * 0.08), r * 0.48, Color("613313"))
		if stage >= 1:
			# Potato & masala
			draw_circle(c + Vector2(-r * 0.14, r * 0.04), r * 0.24, Color("e6bc58"))
			draw_circle(c + Vector2(r * 0.16, 0.0), r * 0.18, Color("cc7b32"))
		if stage >= 2:
			# Sweet chutney
			draw_circle(c + Vector2(0, -r * 0.04), r * 0.26, Color("6c2612"))
		if stage >= 3:
			# Bright emerald pani fill
			draw_circle(c + Vector2(0, -r * 0.04), r * 0.42, Color("569e32"))
			draw_circle(c + Vector2(-r * 0.12, -r * 0.16), r * 0.1, Color("99e36e"))
		if stage >= 4:
			# Finished gleaming puri ready to serve
			draw_arc(c, r * 0.94, 0.0, TAU, 22, Color("74e076"), 2.0, true)

	func _draw_logo_emblem(c: Vector2, r: float) -> void:
		# Fresh green mint leaves behind
		draw_circle(c + Vector2(-r * 0.65, -r * 0.35), r * 0.36, Color("499e35"))
		draw_circle(c + Vector2(r * 0.68, -r * 0.28), r * 0.32, Color("5ab840"))
		# Golden puri bowl
		draw_circle(c + Vector2(0, r * 0.08), r * 0.82, Color("d88b34"))
		draw_arc(c + Vector2(0, r * 0.08), r * 0.82, 0.0, TAU, 24, Color("4b240b"), 2.4, true)
		draw_circle(c + Vector2(0, -r * 0.05), r * 0.56, Color("6b3512"))
		# Filling + green pani
		draw_circle(c + Vector2(-r * 0.18, 0.0), r * 0.22, Color("eab94e"))
		draw_circle(c + Vector2(r * 0.18, r * 0.06), r * 0.2, Color("c47d38"))
		draw_circle(c + Vector2(0, -r * 0.12), r * 0.28, Color("57a632"))


class StreetMinimap extends Control:
	var customer_count: int = 0

	func _init() -> void:
		custom_minimum_size = Vector2(98, 98)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("e8dcc4"), true)
		# City blocks
		draw_rect(Rect2(4, 4, size.x * 0.34, size.y - 8), Color("d1bfa0"), true)
		draw_rect(Rect2(size.x * 0.64, 4, size.x * 0.32, size.y - 8), Color("d1bfa0"), true)
		# Central street
		draw_rect(Rect2(size.x * 0.40, 2, size.x * 0.22, size.y - 4), Color("7d7872"), true)
		# Center dashed line
		for i in 5:
			var y := 8.0 + float(i) * 18.0
			draw_rect(Rect2(size.x * 0.50, y, 2, 10), Color("f5ecd8"), true)
		# Stall marker pin (amber/red)
		var pin := Vector2(size.x * 0.56, size.y * 0.54)
		draw_circle(pin, 7.0, Color("e44e32"))
		draw_circle(pin, 3.2, Color("ffd447"))
		# Active customer / queue dots
		var q_count := 0
		if Game.root != null and Game.root.world != null and Game.root.world.customer_manager != null:
			q_count = Game.root.world.customer_manager.queue.size()
		for i in mini(q_count, 5):
			draw_circle(Vector2(size.x * 0.48, size.y * 0.54 - 10.0 - float(i) * 7.0), 2.5, Color("38c2ae"))
		# Border
		draw_rect(rect, Color("6e4a28"), false, 2.0)


class LogoBanner extends Control:
	## Cinematic wordmark: no emblem, no ribbon. A serif title held between two
	## tapered gold rules with a small diamond, and a tracked subtitle beneath.
	func _init() -> void:
		custom_minimum_size = Vector2(460, 150)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var cx := w * 0.5
		var scale_f := clampf(size.y / 150.0, 0.6, 1.6)

		_rule(cx, 12.0, w * 0.42, 0.55 * scale_f)
		_diamond(Vector2(cx, 12.0), 3.5 * scale_f, 0.9)

		var title_font := UIKit.display_font(900, 1)
		var title_size := int(round(66.0 * scale_f))
		var title := "PANI PURI"
		var ts := title_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size)
		var ty := 12.0 + ts.y * 0.82 + 14.0 * scale_f
		draw_string(title_font, Vector2(cx - ts.x * 0.5, ty + 4.0 * scale_f), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0, 0, 0, 0.6))
		draw_string(title_font, Vector2(cx - ts.x * 0.5, ty), title,
			HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color("f7ead2"))

		_rule(cx, ty + 16.0 * scale_f, w * 0.26, 0.35 * scale_f)

		var sub_font := UIKit.ui_font(600, 9)
		var sub_size := int(round(14.0 * scale_f))
		var sub := "SIMULATOR"
		var ss := sub_font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size)
		var sy := ty + 16.0 * scale_f + 12.0 * scale_f + ss.y * 0.72
		draw_string(sub_font, Vector2(cx - ss.x * 0.5, sy), sub,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Color("d9b877"))

	func _rule(cx: float, y: float, half: float, alpha: float) -> void:
		var cols := int(maxf(half, 8.0))
		for i in cols:
			var t := float(i) / float(cols)
			var a := alpha * (1.0 - t) * (1.0 - t * 0.2)
			var c := Color(0.86, 0.72, 0.44, a)
			draw_rect(Rect2(cx - float(i) - 1.0, y, 1.0, 1.0), c, true)
			draw_rect(Rect2(cx + float(i), y, 1.0, 1.0), c, true)

	func _diamond(p: Vector2, d: float, alpha: float) -> void:
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -d), p + Vector2(d, 0), p + Vector2(0, d), p + Vector2(-d, 0),
		]), Color(0.9, 0.76, 0.46, alpha))
