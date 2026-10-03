class_name DuelViews
extends RefCounted
## The pieces the Duel screen is built from: each Totem standing in its rune
## circle, the cards in hand, each duellist's Life plate and Ward zone, the
## round End Turn and Divine Gift buttons, the d20, and pop-up pickers.

const STATUS_COL := {"burn": Color("ff9a4a"), "poison": Color("9be15d"), "stun": Color("ffe066"), "sleep": Color("b9a4ff")}
const STATUS_SHORT := {"burn": "BURN", "poison": "POISON", "stun": "STUN", "sleep": "SLEEP"}


static func ellipse(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color, n: int = 48) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
	ci.draw_colored_polygon(pts, col)


static func ring(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color, w: float, n: int = 64) -> void:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
	ci.draw_polyline(pts, col, w, true)


## A small rounded label ("BURN", "◈ 40"). Returns its width.
static func pill(ci: CanvasItem, pos: Vector2, label: String, bg: Color, fg: Color, size: int = 16, h: float = 26.0) -> float:
	var fnt := CardFace.font("bold")
	var w := fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 18
	var r := Rect2(pos, Vector2(w, h))
	CardFace.box(ci, r, h * 0.5, bg, Color(0, 0, 0, 0.5), 1.5)
	CardFace.text_in(ci, fnt, r, label, size, fg)
	return w


## A gem-cut Essence crystal.
static func crystal(ci: CanvasItem, c: Vector2, h: float, full: bool, t: float = 0.0) -> void:
	var w := h * 0.62
	var pts := PackedVector2Array([c + Vector2(0, -h * 0.5), c + Vector2(w * 0.5, -h * 0.1), c + Vector2(0, h * 0.5), c + Vector2(-w * 0.5, -h * 0.1)])
	if full:
		var lt := DuelCardFace.ESSENCE.lightened(0.45)
		ci.draw_polygon(pts, PackedColorArray([lt, DuelCardFace.ESSENCE, DuelCardFace.ESSENCE_DARK, DuelCardFace.ESSENCE]))
		ci.draw_colored_polygon(PackedVector2Array([pts[0], pts[1], c + Vector2(0, -h * 0.05), pts[3]]), Color(1, 1, 1, 0.28 + 0.12 * sin(t * 3.0 + c.x * 0.05)))
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(1, 1, 1, 0.55), 1.5, true)
	else:
		ci.draw_colored_polygon(pts, Color(0.05, 0.08, 0.14, 0.85))
		pts.append(pts[0])
		ci.draw_polyline(pts, Color(DuelCardFace.ESSENCE, 0.35), 1.5, true)


# ================================================================ TotemView ===
## One of the Circle's slots: a glowing rune circle on the arena floor. When a
## Totem stands in it, the creature is drawn standing in the circle with its
## nameplate (name, HP, conditions) underneath. Tap it to open its moves.
## `depth` < 1 draws it further away (the rival's row).
class TotemView:
	extends Control
	signal tapped(view)

	var side := 0              # which duellist's slot this is
	var slot := 0
	var mine := false
	var depth := 1.0
	var totem: DuelTotem = null
	var highlight := ""        # "", "target", "selected", "ready", "dim"
	var offset := Vector2.ZERO # lunge / shake
	var pop := 1.0             # scale for summon / KO
	var fade := 1.0
	var flash := 0.0
	var flash_color := Color(1, 0.25, 0.2)
	var rise := 0.0            # 0-1: the creature rising out of its card when called
	var field3d := false       # the creature is drawn by the 3D field; this view draws the nameplate
	var body_rect_3d := Rect2()  # where the 3D creature is on screen (set by the screen)
	var shown_hp := -1.0
	var lag_hp := -1.0
	var _t := 0.0
	var _zone: ZoneLayer

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_zone = ZoneLayer.new()
		_zone.view = self
		add_child(_zone)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and _zone != null:
			_zone.size = size

	func set_totem(t: DuelTotem) -> void:
		if t != totem:
			shown_hp = -1.0
			lag_hp = -1.0
		totem = t
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if totem != null:
			var target := float(totem.hp_left())
			if shown_hp < 0.0:
				shown_hp = target
				lag_hp = target
			shown_hp = move_toward(shown_hp, target, delta * 220.0)
			lag_hp = maxf(lag_hp, shown_hp)
			lag_hp = move_toward(lag_hp, shown_hp, delta * 55.0)
		queue_redraw()
		_zone.queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tapped.emit(self)
			accept_event()

	## The rune circle on the floor, in this view's coordinates.
	func plat_rect() -> Rect2:
		var w := 272.0 * depth
		var h := 50.0 * depth
		var c := Vector2(size.x * 0.5, size.y * 0.6)
		return Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))

	## Roughly the middle of the creature, in this view's coordinates.
	func body_point() -> Vector2:
		var p := plat_rect()
		var sf := _size_factor() if totem != null else 0.8
		return p.get_center() - Vector2(0, 211.0 * sf * depth * 0.45) + offset

	## Where the creature's feet are.
	func foot_point() -> Vector2:
		return plat_rect().get_center() + offset

	## Kept for older callers: the area the creature fills.
	func art_rect() -> Rect2:
		var p := plat_rect()
		var h := 211.0 * depth
		return Rect2(Vector2(p.position.x, p.get_center().y - h), Vector2(p.size.x, h))

	func _draw() -> void:
		_zone.visible = not field3d
		var c := size * 0.5
		draw_set_transform(c, 0.0, Vector2(1.0, 1.0) if field3d else Vector2(pop, pop))
		var o := -c
		var plat := plat_rect()
		plat.position += o
		if totem == null:
			if highlight == "target":
				var a := 0.6 + 0.35 * sin(_t * 5.0)
				CardFace.text(self, CardFace.font("display_bold"), Vector2(o.x, plat.get_center().y + 10), "TAP", 28, Color(UITheme.GOLD, a), HORIZONTAL_ALIGNMENT_CENTER, size.x, 6)
			draw_set_transform(Vector2.ZERO)
			return
		var mod := Color(1, 1, 1, fade)
		if highlight == "dim":
			mod = Color(0.55, 0.55, 0.6, fade)
		var ar: Rect2
		if field3d:
			# the creature stands in the 3D field; only the plaque and badges are drawn here.
			# body_rect_3d is in stage coordinates; this transform's origin is the view's centre.
			if body_rect_3d.size.x > 0:
				ar = Rect2(body_rect_3d.position - position - c, body_rect_3d.size)
			else:
				ar = Rect2(plat.get_center() - Vector2(90, 220), Vector2(180, 200))
		else:
			var cut := DuelArt.creature(totem.id())
			if cut != null:
				ar = _draw_cutout(cut, plat, o, mod)
			else:
				ar = _draw_window(plat, mod)
		if totem.asleep:
			CardFace.text(self, CardFace.font("display_bold"), ar.position + Vector2(ar.size.x - 30, 40 + sin(_t * 2.0) * 6.0), "z", 34, Color("c9b8ff", 0.9 * fade), HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
			CardFace.text(self, CardFace.font("display_bold"), ar.position + Vector2(ar.size.x - 12, 14 + sin(_t * 2.0 + 1.0) * 6.0), "Z", 26, Color("c9b8ff", 0.7 * fade), HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
		# shield: a bubble of light around the creature
		if totem.shield > 0:
			var sc := ar.get_center()
			var rr := Vector2(ar.size.x * 0.56, ar.size.y * 0.58)
			DuelViews.ellipse(self, sc, rr, Color("9fe8ff", 0.07 * fade))
			DuelViews.ring(self, sc, rr, Color("9fe8ff", (0.45 + 0.2 * sin(_t * 3.0)) * fade), 4.0)
		# keywords: small gold seals down the creature's right side
		var kx := plat.get_center().x + plat.size.x * 0.5 + 6
		var ky := ar.position.y + 40
		for k in totem.keywords():
			var glyph: String = {"guardian": "resolve", "swift": "swiftness", "channel": "presence", "thorns": "venom", "harvest": "heart", "burrow": "earth"}.get(k, "any")
			draw_circle(Vector2(kx, ky), 17, Color(0.05, 0.04, 0.02, 0.85 * fade))
			draw_arc(Vector2(kx, ky), 17, 0, TAU, 32, Color(UITheme.GOLD, 0.85 * fade), 2.0, true)
			Glyphs.draw(self, glyph, Vector2(kx, ky), 10, Color(UITheme.GOLD, fade))
			ky += 40
		_draw_plaque(plat)
		draw_set_transform(Vector2.ZERO)

	## How big a creature stands: little Sparks are small, evolved and rare ones loom.
	func _size_factor() -> float:
		if totem.stage() >= 2 or totem.tier() >= 3:
			return 1.0
		if totem.stage() == 1:
			return 0.9
		return 0.84 if totem.tier() == 2 else 0.76

	## Draws the transparent battlefield creature standing in its circle and
	## returns the rectangle it fills (for the overlays drawn on top).
	func _draw_cutout(tex: Texture2D, plat: Rect2, o: Vector2, mod: Color) -> Rect2:
		var ts := Vector2(tex.get_width(), tex.get_height())
		var sf := _size_factor()
		var box := Vector2(292, 211) * sf * depth
		var k := minf(box.x / ts.x, box.y / ts.y)
		var w := ts.x * k
		var h := ts.y * k
		var fly := DuelArt.FLYERS.has(totem.id())
		var foot := plat.get_center() + Vector2(0, plat.size.y * 0.1) + offset
		if fly:
			foot.y -= (24.0 + sin(_t * 1.8 + slot) * 7.0) * depth
		# contact shadow
		DuelViews.ellipse(self, plat.get_center() + offset + Vector2(0, plat.size.y * 0.08), Vector2(w * 0.34, plat.size.y * 0.3), Color(0, 0, 0, (0.3 if fly else 0.55) * fade))
		# the creature, breathing; the rival's side faces the other way
		var breathe := sin(_t * 2.1 + slot * 1.7)
		var sx := 1.0 - 0.006 * breathe
		var sy := 1.0 + 0.014 * breathe
		if totem.asleep:
			sy = 1.0 + 0.02 * sin(_t * 1.1)
		var flip := 1.0 if mine else -1.0
		var m := Color(mod)
		if flash > 0.0:
			m = Color(1, 1, 1, mod.a).lerp(Color(flash_color.r * 2.2, flash_color.g * 2.2, flash_color.b * 2.2, mod.a), clampf(flash * 0.7, 0.0, 1.0))
			if highlight == "dim":
				m = m * Color(0.55, 0.55, 0.6, 1)
		var base := Transform2D(0.0, Vector2(pop, pop), 0.0, size * 0.5)
		draw_set_transform_matrix(base * Transform2D(0.0, Vector2(sx * flip, sy), 0.0, foot))
		draw_texture_rect(tex, Rect2(Vector2(-w * 0.5, -h), Vector2(w, h)), false, m)
		draw_set_transform_matrix(base)
		var top := foot.y - h * sy
		return Rect2(Vector2(foot.x - w * 0.5, top), Vector2(w, foot.y - top))

	## Without a cut-out: the card's painting in an arched window over the circle.
	func _draw_window(plat: Rect2, mod: Color) -> Rect2:
		var w := 200.0 * depth
		var h := 190.0 * depth
		var ar := Rect2(Vector2(plat.get_center().x - w * 0.5, plat.get_center().y - h - 6) + offset, Vector2(w, h))
		var pts := _arch(ar)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.6 * fade))
		var tex := CardFace.art(totem.id())
		if tex != null:
			var ts := Vector2(tex.get_width(), tex.get_height())
			var k := maxf(ar.size.x / ts.x, ar.size.y / ts.y)
			var src := Rect2((ts - ar.size / k) * Vector2(0.5, 0.4), ar.size / k)
			var uvs := PackedVector2Array()
			for p in pts:
				uvs.append((src.position + (p - ar.position) / k) / ts)
			draw_polygon(pts, PackedColorArray([mod]), uvs, tex)
		else:
			var el := totem.element()
			draw_colored_polygon(pts, Color(Lore.color(el, 1), mod.a))
			Glyphs.draw(self, el, ar.get_center(), ar.size.x * 0.3, Color(1, 1, 1, 0.85 * mod.a))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(CardFace.metal(totem.tier(), 0), 0.9 * fade), 4.0, true)
		if flash > 0.0:
			draw_colored_polygon(pts, Color(flash_color, flash * 0.6))
		return ar

	## The nameplate under the circle: element, name, HP bar and number.
	func _draw_plaque(plat: Rect2) -> void:
		var f := fade
		var pc := plat.get_center()
		var pr := Rect2(Vector2(pc.x - 128, plat.end.y + 10), Vector2(256, 58))
		CardFace.vgrad(self, pr, 13, Color(0.1, 0.11, 0.18, 0.93 * f), Color(0.02, 0.02, 0.05, 0.93 * f))
		CardFace.box(self, pr, 13, Color(0, 0, 0, 0), Color(UITheme.GOLD_DIM, 0.9 * f), 2.0)
		draw_line(pr.position + Vector2(16, 4), Vector2(pr.end.x - 16, pr.position.y + 4), Color(1, 1, 1, 0.12 * f), 1.5)
		var el := totem.element()
		CardFace.orb(self, Vector2(pr.position.x + 4, pr.get_center().y), 24, el)
		var fnt := CardFace.font("display_bold")
		var nm := totem.card_name()
		CardFace.text(self, fnt, pr.position + Vector2(34, 26), nm, CardFace.fit_size(fnt, nm, 21, 142), Color(UITheme.TEXT, f), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		# HP bar with a white "damage lag" chunk
		var mx := maxf(1.0, float(totem.max_hp()))
		var left := shown_hp if shown_hp >= 0.0 else float(totem.hp_left())
		var frac := clampf(left / mx, 0.0, 1.0)
		var lag := clampf(lag_hp / mx, 0.0, 1.0) if lag_hp >= 0.0 else frac
		var col := Color("6fe08a")
		if frac <= 0.25:
			col = Color("ff5a4a")
		elif frac <= 0.5:
			col = Color("ffc94a")
		var br := Rect2(pr.position + Vector2(34, 36), Vector2(146, 11))
		CardFace.box(self, br, 5.5, Color(0, 0, 0, 0.75 * f))
		if lag > frac:
			CardFace.box(self, Rect2(br.position, Vector2(br.size.x * lag, br.size.y)), 5.5, Color(1, 0.95, 0.9, 0.8 * f))
		if frac > 0.0:
			CardFace.vgrad(self, Rect2(br.position, Vector2(maxf(br.size.y, br.size.x * frac), br.size.y)), 5.5, Color(col.lightened(0.35), f), Color(col.darkened(0.2), f))
		CardFace.text(self, fnt, Vector2(pr.end.x - 72, pr.position.y + 43), str(int(round(left))), 34, Color(1, 1, 1, f), HORIZONTAL_ALIGNMENT_RIGHT, 62, 6)
		# stage seal
		if totem.stage() > 0:
			DuelViews.pill(self, pr.position + Vector2(28, -14), ["", "II", "III"][totem.stage()], Color("3a2a08", 0.95 * f), UITheme.GOLD, 15, 22)
		# conditions and shield, in a row above the plaque
		var x := pr.position.x + (70.0 if totem.stage() > 0 else 28.0)
		for cnd in totem.conditions():
			x += DuelViews.pill(self, Vector2(x, pr.position.y - 14), DuelViews.STATUS_SHORT.get(cnd, cnd.to_upper()), Color(DuelViews.STATUS_COL.get(cnd, Color.WHITE), 0.95 * f), Color("140f18"), 14, 22) + 5
		if totem.shield > 0:
			DuelViews.pill(self, Vector2(pr.end.x - 78, pr.position.y - 14), "◈ %d" % totem.shield, Color("9fe8ff", 0.95 * f), Color("0b2a3a"), 14, 22)

	func _arch(r: Rect2) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var rad := r.size.x * 0.5
		var cy := r.position.y + rad
		for i in 25:
			var a := PI + PI * i / 24.0
			pts.append(Vector2(r.get_center().x + cos(a) * rad, cy + sin(a) * rad))
		pts.append(r.end)
		pts.append(Vector2(r.position.x, r.end.y))
		return pts


## The light under a Totem: its rune circle, floor glow and highlight rings,
## drawn additively behind the creature.
class ZoneLayer:
	extends Control
	var view: TotemView

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		show_behind_parent = true
		material = DuelFX.additive()

	func _p(pc: Vector2, rad: Vector2, u: Vector2) -> Vector2:
		return pc + Vector2(u.x * rad.x, u.y * rad.y)

	func _draw() -> void:
		var v := view
		if v == null:
			return
		var c := v.size * 0.5
		draw_set_transform(c, 0.0, Vector2(v.pop, v.pop))
		var plat := v.plat_rect()
		plat.position -= c
		var pc := plat.get_center()
		var rad := plat.size * 0.5
		var t := v._t
		var occupied := v.totem != null
		var base := Color(0.62, 0.72, 1.0) if not occupied else DuelFX.light(v.totem.element())
		var a := (0.3 if not occupied else 0.6) * v.fade
		var hc := base
		var h := v.highlight
		match h:
			"target":
				hc = UITheme.GOLD
				a = 0.8 + 0.2 * sin(t * 6.0)
			"selected":
				hc = Color(0.65, 0.9, 1.0)
				a = 1.0
			"ready":
				hc = base.lerp(Color(0.6, 0.85, 1.0), 0.45)
				a = 0.65 + 0.3 * sin(t * 2.6)
		# floor glow and a soft light behind the creature
		DuelFX.draw_glow(self, pc, Vector2(rad.x * 1.25, rad.y * 2.3), Color(hc, 0.45 * a))
		var body := v.body_point() - c
		if occupied:
			DuelFX.draw_glow(self, body, Vector2(140, 150) * v.depth, Color(base, 0.16 * v.fade))
		if v.flash > 0.0:
			DuelFX.draw_glow(self, body, Vector2(220, 220) * v.depth, Color(v.flash_color, 0.8 * v.flash))
		# the rune circle
		DuelViews.ring(self, pc, rad * 1.1, Color(hc, 0.3 * a), 1.2)
		DuelViews.ring(self, pc, rad, Color(hc, 0.85 * a), 3.0)
		DuelViews.ring(self, pc, rad * 0.84, Color(hc, 0.5 * a), 1.6)
		var spin := t * (0.18 if not occupied else 0.32) * (1.0 if v.side == 0 else -1.0)
		for i in 32:
			var ang := TAU * i / 32.0 + spin
			var d := Vector2(cos(ang), sin(ang))
			draw_line(_p(pc, rad, d * 0.87), _p(pc, rad, d * (0.98 if i % 4 == 0 else 0.93)), Color(hc, 0.7 * a), 2.0, true)
		for k in 2:
			var pts := PackedVector2Array()
			for i in 4:
				var ang := TAU * (i % 3) / 3.0 + k * PI / 3.0 - spin * 0.6 - PI / 2.0
				pts.append(_p(pc, rad, Vector2(cos(ang), sin(ang)) * 0.82))
			draw_polyline(pts, Color(hc, 0.28 * a), 1.6, true)
		# highlights
		if h == "target":
			var pulse := 0.5 + 0.5 * sin(t * 6.0)
			for i in 4:
				var ang := TAU * i / 4.0 + PI / 4.0 + t * 0.8
				var d := Vector2(cos(ang), sin(ang))
				var n := Vector2(-d.y, d.x)
				var tip := _p(pc, rad, d * (1.16 + 0.12 * pulse))
				var w1 := _p(pc, rad, d * (1.42 + 0.12 * pulse) + n * 0.16)
				var w2 := _p(pc, rad, d * (1.42 + 0.12 * pulse) - n * 0.16)
				draw_polyline(PackedVector2Array([w1, tip, w2]), Color(UITheme.GOLD, 0.95), 5.0, true)
			DuelViews.ellipse(self, pc, rad * 0.95, Color(UITheme.GOLD, 0.12 * a))
		if h == "selected" or h == "ready" or (h == "target" and occupied):
			for i in 12:
				var ph := fmod(t * 0.55 + i * 0.29, 1.0)
				var ang := TAU * i / 12.0 + i * 0.7
				var p := _p(pc, rad, Vector2(cos(ang), sin(ang)) * 0.92) + Vector2(0, -ph * 150.0 * v.depth)
				draw_circle(p, 3.5 * (1.0 - ph) * v.depth, Color(hc, (1.0 - ph) * a))
		if h == "selected":
			DuelViews.ellipse(self, pc, rad * 0.9, Color(hc, 0.14))
		draw_set_transform(Vector2.ZERO)


# ================================================================= HandCard ===
class HandCard:
	extends Control
	signal tapped(v)

	var card: DuelCard
	var state := "normal"      # normal, playable, selected, unaffordable
	var cost_shown := -1
	var _t := 0.0
	var attrs: Dictionary = {}

	func _init(c: DuelCard) -> void:
		card = c
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tapped.emit(self)
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# drop shadow
		CardFace.box(self, Rect2(r.position + Vector2(6, 10), r.size), 14, Color(0, 0, 0, 0.45))
		if state == "playable" or state == "selected":
			var col := Color(0.55, 0.85, 1.0) if state == "playable" else UITheme.GOLD
			var a := 0.55 + 0.35 * sin(_t * 3.0) if state == "playable" else 1.0
			for i in 4:
				CardFace.box(self, r.grow(3 + i * 4), 16 + i * 4, Color(0, 0, 0, 0), Color(col, a * (0.5 - i * 0.11)), 4.0)
			# a spark running round the edge
			var per := 2.0 * (r.size.x + r.size.y)
			var d := fmod(_t * 420.0, per)
			var p := Vector2.ZERO
			if d < r.size.x:
				p = Vector2(d, 0)
			elif d < r.size.x + r.size.y:
				p = Vector2(r.size.x, d - r.size.x)
			elif d < 2.0 * r.size.x + r.size.y:
				p = Vector2(r.size.x - (d - r.size.x - r.size.y), r.size.y)
			else:
				p = Vector2(0, r.size.y - (d - 2.0 * r.size.x - r.size.y))
			DuelFX.draw_glow(self, p, Vector2(26, 26), Color(1, 1, 1, 0.9 * a))
		var opts := {"compact": true, "attrs": attrs}
		if cost_shown >= 0:
			opts["cost"] = cost_shown
		opts["unaffordable"] = state == "unaffordable"
		DuelCardFace.draw_card(self, r, card.id, opts)
		if state == "unaffordable":
			CardFace.box(self, r, 12, Color(0, 0, 0, 0.4))


# ============================================================== PlayerPanel ===
## A duellist's Life plate: portrait, name, Life with a draining bar, Guard,
## deck and hand counts, and Essence crystals.
class PlayerPanel:
	extends Control
	signal tapped(panel)

	var player: DuelPlayer = null
	var mine := false
	var active := false
	var targetable := false
	var shown_life := -1.0
	var lag_life := -1.0
	var shake := 0.0
	var flash := 0.0
	var flash_color := Color(1, 0.2, 0.2)
	var reveal_wards := false
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		if player != null:
			if shown_life < 0.0:
				shown_life = player.life
				lag_life = player.life
			shown_life = move_toward(shown_life, float(player.life), delta * 260.0)
			lag_life = maxf(lag_life, shown_life)
			lag_life = move_toward(lag_life, shown_life, delta * 70.0)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tapped.emit(self)
			accept_event()

	func main_rect() -> Rect2:
		return Rect2(Vector2(58, 12), Vector2(size.x - 62, 140))

	func life_rect() -> Rect2:
		var m := main_rect()
		return Rect2(Vector2(140, 80), Vector2(m.end.x - 150, 70))

	func portrait_center() -> Vector2:
		return Vector2(72, 82)

	func _draw() -> void:
		if player == null:
			return
		var off := Vector2(sin(_t * 60.0) * shake, 0)
		draw_set_transform(off)
		var edge := UITheme.MINE if mine else UITheme.THEIRS
		var m := main_rect()
		# the plate: dark glass, a wash of the side's colour, gold trim
		CardFace.box(self, Rect2(m.position + Vector2(0, 6), m.size), 18, Color(0, 0, 0, 0.45))
		CardFace.vgrad(self, m, 18, Color(0.1, 0.11, 0.19, 0.95), Color(0.025, 0.03, 0.06, 0.95))
		CardFace.vgrad(self, Rect2(m.position, Vector2(m.size.x, 56)), 18, Color(edge, 0.3), Color(edge, 0.0))
		CardFace.box(self, m, 18, Color(0, 0, 0, 0), Color(UITheme.GOLD_DIM, 0.95), 2.0)
		CardFace.box(self, m.grow(-6), 13, Color(0, 0, 0, 0), Color(1, 1, 1, 0.06), 1.0)
		if active:
			CardFace.box(self, m.grow(4), 22, Color(0, 0, 0, 0), Color(edge, 0.45 + 0.3 * sin(_t * 3.0)), 3.0)
		# portrait medallion
		var pc := portrait_center()
		var pr := 60.0
		draw_circle(pc, pr + 11, Color(0.02, 0.02, 0.04, 0.95))
		if active:
			for i in 3:
				var a0 := _t * 1.6 + i * TAU / 3.0
				draw_arc(pc, pr + 8, a0, a0 + 1.2, 24, Color(edge, 0.9), 4.0, true)
		var patron := player.patron()
		if patron == "" or not DuelArt.god_medallion(self, pc, pr, patron, UITheme.GOLD):
			draw_circle(pc, pr, Color("141a30"))
			if patron != "":
				CardFace.orb(self, pc, pr * 0.7, Lore.GODS[patron].element)
			else:
				Glyphs.draw(self, "crown_sigil", pc, pr * 0.55, UITheme.TEXT_DIM)
		draw_arc(pc, pr + 3, 0, TAU, 64, UITheme.GOLD, 4.0, true)
		draw_arc(pc, pr + 10, 0, TAU, 64, Color(UITheme.GOLD_DIM, 0.6), 1.5, true)
		# name and patron
		var fnt := CardFace.font("display_bold")
		var nm := player.player_name
		CardFace.text(self, fnt, Vector2(142, 50), nm, CardFace.fit_size(fnt, nm, 28, m.end.x - 150), UITheme.TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		var sub := "Unsworn" if patron == "" else "Sworn to %s" % Lore.GODS[patron].name
		CardFace.text(self, CardFace.font("body"), Vector2(143, 74), sub, 18, UITheme.TEXT_DIM)
		# Life: big number and a draining bar
		var frac := clampf(shown_life / maxf(1.0, player.max_life), 0.0, 1.0)
		var lag := clampf(lag_life / maxf(1.0, player.max_life), 0.0, 1.0)
		var lcol := Color("ff5d73") if frac > 0.3 else Color("ff2d3d")
		CardFace.text(self, CardFace.font("bold"), Vector2(142, 118), "LIFE", 17, Color(lcol.lightened(0.35), 0.95))
		CardFace.text(self, fnt, Vector2(190, 124), str(int(round(shown_life))), 50, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, m.end.x - 204, 7)
		var br := Rect2(Vector2(142, 132), Vector2(m.end.x - 156, 11))
		CardFace.box(self, br, 5.5, Color(0, 0, 0, 0.75))
		if lag > frac:
			CardFace.box(self, Rect2(br.position, Vector2(br.size.x * lag, br.size.y)), 5.5, Color(1, 0.92, 0.85, 0.85))
		if frac > 0.0:
			CardFace.vgrad(self, Rect2(br.position, Vector2(maxf(11.0, br.size.x * frac), br.size.y)), 5.5, lcol.lightened(0.3), lcol.darkened(0.25))
		if targetable:
			var a := 0.55 + 0.45 * sin(_t * 6.0)
			CardFace.box(self, m.grow(8), 24, Color(UITheme.GOLD, 0.1 * a), Color(UITheme.GOLD, a), 5.0)
			DuelViews.pill(self, Vector2(m.end.x - 150, m.position.y - 14), "TAP TO STRIKE", Color(UITheme.GOLD, 0.95), Color("2a1d05"), 16, 28)
		if flash > 0.0:
			CardFace.box(self, m, 18, Color(flash_color, flash * 0.55))
		# Guard, deck and hand
		var y := m.end.y + 10
		var x := 70.0
		x += _stat(Vector2(x, y), "resolve", "Guard %d" % player.guard(), Color("c7d2ff")) + 10
		x += _stat(Vector2(x, y), "deck", "%d" % player.deck.size(), UITheme.TEXT_DIM) + 10
		if not mine:
			x += _stat(Vector2(x, y), "duel", "Hand %d" % player.hand.size(), UITheme.TEXT_DIM) + 10
		if player.fortune_left > 0:
			x += _stat(Vector2(x, y), "coin", "Fortune %d" % player.fortune_left, UITheme.GOLD) + 10
		# Essence crystals
		y += 46
		var n := maxi(player.essence_max, player.essence)
		var gap := minf(30.0, (size.x - 170.0) / maxf(1.0, n))
		CardFace.text(self, CardFace.font("display_bold"), Vector2(70, y + 24), "%d/%d" % [player.essence, player.essence_max], 26, DuelCardFace.ESSENCE, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		for i in n:
			DuelViews.crystal(self, Vector2(150 + i * gap, y + 16), 28, i < player.essence, _t)
		draw_set_transform(Vector2.ZERO)

	func _stat(pos: Vector2, glyph: String, label: String, col: Color) -> float:
		var fnt := CardFace.font("bold")
		var w := fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 46
		var r := Rect2(pos, Vector2(w, 34))
		CardFace.box(self, r, 17, Color(0.03, 0.035, 0.07, 0.85), Color(1, 1, 1, 0.1), 1.0)
		Glyphs.draw(self, glyph, pos + Vector2(19, 17), 10, col)
		CardFace.text_in(self, fnt, Rect2(pos + Vector2(34, 0), Vector2(w - 40, 34)), label, 18, col, HORIZONTAL_ALIGNMENT_LEFT)
		return w


# ================================================================= WardZone ===
## A duellist's Ward zone on the field: face-down cards waiting to spring.
class WardZone:
	extends Control
	var player: DuelPlayer = null
	var mine := false
	var reveal := false
	var _t := 0.0

	const CARD := Vector2(78, 109)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func card_rect(i: int) -> Rect2:
		return Rect2(Vector2(96 + i * 94, 8), CARD)

	func _draw() -> void:
		if player == null:
			return
		var col := Color("d9a6f0")
		CardFace.text(self, CardFace.font("display_bold"), Vector2(4, 58), "WARDS", 18, Color(col, 0.85), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		CardFace.text(self, CardFace.font("body"), Vector2(4, 82), "%d / %d" % [player.wards.size(), player.ward_slots()], 17, Color(col, 0.6))
		for i in player.ward_slots():
			var r := card_rect(i)
			if i < player.wards.size():
				DuelFX.draw_glow(self, r.get_center(), r.size * 0.95, Color(DuelCardFace.WARD_COL, 0.35 + 0.1 * sin(_t * 2.0 + i)))
				if reveal:
					DuelCardFace.draw_card(self, r, player.wards[i].id, {"compact": true})
				else:
					CardFace.draw_back(self, r)
			else:
				CardFace.box(self, r, 8, Color(col, 0.04), Color(col, 0.22), 1.5)
				Glyphs.draw(self, "crown_sigil", r.get_center(), 14, Color(col, 0.18))


# ================================================================ HandBacks ===
## The rival's hand, fanned face-down at the top of the screen.
class HandBacks:
	extends Control
	var count := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if count <= 0:
			return
		var cs := Vector2(80, 112)
		var pivot := Vector2(size.x * 0.5, -620)
		var step := minf(5.0, 34.0 / maxf(1.0, count - 1))
		for i in count:
			var ang := deg_to_rad((i - (count - 1) * 0.5) * step)
			var xf := Transform2D(ang, pivot) * Transform2D(0.0, Vector2(0, 700))
			draw_set_transform_matrix(xf)
			CardFace.box(self, Rect2(Vector2(-cs.x * 0.5 + 3, -cs.y + 4), cs), 8, Color(0, 0, 0, 0.4))
			CardFace.draw_back(self, Rect2(Vector2(-cs.x * 0.5, -cs.y), cs))
		draw_set_transform(Vector2.ZERO)


# ============================================================= EmblemButton ===
## The round End Turn button. States: on, glow (nothing else to do), wait, off.
class EmblemButton:
	extends Control
	signal pressed
	var state := "off"
	var label := "END TURN"
	var wait_label := "RIVAL'S TURN"
	var _t := 0.0
	var _press := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		_press = move_toward(_press, 0.0, delta * 4.0)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			if state == "on" or state == "glow":
				_press = 1.0
				pressed.emit()
			accept_event()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 14.0
		r *= 1.0 - 0.06 * _press
		var live := state == "on" or state == "glow"
		if state == "glow":
			for i in 16:
				var a := TAU * i / 16.0 + _t * 0.4
				var d := Vector2(cos(a), sin(a))
				var nn := Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([c + d * r * 0.9 + nn * 10, c + d * r * 1.32, c + d * r * 0.9 - nn * 10]), Color(UITheme.GOLD, 0.22 + 0.12 * sin(_t * 3.0 + i)))
		draw_circle(c + Vector2(0, 6), r + 10, Color(0, 0, 0, 0.5))
		draw_circle(c, r + 10, Color("1a1408"))
		# the disc
		var top := Color("2a5ca8")
		var bot := Color("0c1c3e")
		if state == "glow":
			top = Color("f6d27a")
			bot = Color("9a6414")
		elif not live:
			top = Color("2c2f3e")
			bot = Color("12141c")
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in 48:
			var a := TAU * i / 48.0
			var p := c + Vector2(cos(a), sin(a)) * r
			pts.append(p)
			cols.append(top.lerp(bot, clampf((p.y - (c.y - r)) / (2.0 * r), 0.0, 1.0)))
		draw_polygon(pts, cols)
		draw_circle(c + Vector2(0, -r * 0.45), r * 0.55, Color(1, 1, 1, 0.07))
		# rims and turning ticks
		var rim := UITheme.GOLD if live else Color("6a6f86")
		draw_arc(c, r, 0, TAU, 72, rim, 5.0, true)
		draw_arc(c, r + 9, 0, TAU, 72, Color(rim, 0.7), 2.0, true)
		for i in 24:
			var a := TAU * i / 24.0 + (_t * 0.15 if live else 0.0)
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * (r + 3), c + d * (r + (8 if i % 2 == 0 else 5)), Color(rim, 0.8), 2.0, true)
		var fnt := CardFace.font("display_bold")
		var txt := label if live else wait_label
		var words := txt.split(" ", false, 1)
		var tcol := Color("2a1a02") if state == "glow" else (Color.WHITE if live else Color("8a8ea4"))
		var oc := Color(1, 1, 1, 0.0) if state == "glow" else Color(0, 0, 0, 0.7)
		var fs := 34 if live else 24
		if words.size() == 2:
			CardFace.text(self, fnt, Vector2(0, c.y - 4), words[0], CardFace.fit_size(fnt, words[0], fs, r * 1.6), tcol, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4, oc)
			CardFace.text(self, fnt, Vector2(0, c.y + fs - 2), words[1], CardFace.fit_size(fnt, words[1], fs, r * 1.6), tcol, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4, oc)
		else:
			CardFace.text(self, fnt, Vector2(0, c.y + fs * 0.35), txt, CardFace.fit_size(fnt, txt, fs, r * 1.7), tcol, HORIZONTAL_ALIGNMENT_CENTER, size.x, 4, oc)


# =============================================================== GiftButton ===
## The patron's medallion: tap it to call on the Divine Gift (once a duel).
class GiftButton:
	extends Control
	signal pressed
	var god := ""
	var gift_name := ""
	var used := false
	var enabled := false
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.x * 0.5)
		var r := size.x * 0.5 - 18.0
		if enabled:
			for i in 12:
				var a := TAU * i / 12.0 - _t * 0.5
				var d := Vector2(cos(a), sin(a))
				var nn := Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([c + d * r * 0.95 + nn * 8, c + d * (r + 20), c + d * r * 0.95 - nn * 8]), Color(UITheme.GOLD, 0.3 + 0.15 * sin(_t * 3.0 + i)))
		draw_circle(c + Vector2(0, 5), r + 6, Color(0, 0, 0, 0.5))
		draw_circle(c, r + 6, Color("1a1408"))
		if god == "" or not DuelArt.god_medallion(self, c, r, god, UITheme.GOLD):
			draw_circle(c, r, Color("141a30"))
			Glyphs.draw(self, "crown_sigil", c, r * 0.55, UITheme.GOLD)
		if used or not enabled:
			draw_circle(c, r, Color(0, 0, 0, 0.55 if used else 0.3))
		var rim := UITheme.GOLD if enabled else Color("8a7a50")
		draw_arc(c, r + 2, 0, TAU, 64, rim, 4.0, true)
		if enabled:
			draw_arc(c, r + 9, 0, TAU, 64, Color(UITheme.GOLD, 0.5 + 0.4 * sin(_t * 4.0)), 3.0, true)
		if used:
			CardFace.text_in(self, CardFace.font("display_bold"), Rect2(c - Vector2(r, 20), Vector2(r * 2, 40)), "USED", 26, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 4)
		var fnt := CardFace.font("display_bold")
		var t := gift_name.to_upper()
		CardFace.text(self, fnt, Vector2(0, size.y - 6), t, CardFace.fit_size(fnt, t, 18, size.x), UITheme.GOLD if enabled else Color("9a8a60"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 4)


# =============================================================== IconButton ===
## A small round button with a glyph (the menu).
class IconButton:
	extends Control
	signal pressed
	var glyph := "menu"

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 4
		draw_circle(c, r, Color(0.04, 0.05, 0.09, 0.9))
		draw_arc(c, r, 0, TAU, 48, UITheme.GOLD_DIM, 2.5, true)
		if glyph == "menu":
			for i in 3:
				var y := c.y + (i - 1) * 11
				draw_line(Vector2(c.x - 15, y), Vector2(c.x + 15, y), UITheme.GOLD, 4.0, true)
		else:
			Glyphs.draw(self, glyph, c, r * 0.5, UITheme.GOLD)


# ================================================================= HintView ===
## The line of guidance across the middle of the field.
class HintView:
	extends Control
	var text := "":
		set(v):
			text = v
			queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if text == "":
			return
		var fnt := CardFace.font("bold")
		var fs := CardFace.fit_size(fnt, text, 30, size.x - 80)
		var w := fnt.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 120
		var r := Rect2(Vector2((size.x - w) * 0.5, 0), Vector2(w, size.y))
		var mid := Color(0.02, 0.02, 0.05, 0.78)
		var clear := Color(0.02, 0.02, 0.05, 0.0)
		var pts := PackedVector2Array([r.position, r.position + Vector2(60, 0), r.position + Vector2(60, r.size.y), Vector2(r.position.x, r.end.y)])
		draw_polygon(pts, PackedColorArray([clear, mid, mid, clear]))
		draw_rect(Rect2(r.position + Vector2(60, 0), Vector2(r.size.x - 120, r.size.y)), mid)
		pts = PackedVector2Array([Vector2(r.end.x - 60, r.position.y), Vector2(r.end.x, r.position.y), r.end, Vector2(r.end.x - 60, r.end.y)])
		draw_polygon(pts, PackedColorArray([mid, clear, clear, mid]))
		draw_line(r.position + Vector2(30, 0), Vector2(r.end.x - 30, r.position.y), Color(UITheme.GOLD, 0.45), 1.5)
		draw_line(Vector2(r.position.x + 30, r.end.y), r.end - Vector2(30, 0), Color(UITheme.GOLD, 0.45), 1.5)
		CardFace.text_in(self, fnt, Rect2(Vector2.ZERO, size), text, fs, UITheme.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 4)


# ================================================================= DiceView ===
## A d20 that tumbles and lands, with the move's bands beside it.
class DiceView:
	extends Control
	var info: Dictionary = {}
	var face := 1
	var landed := false
	var spin := 0.0
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func die_center() -> Vector2:
		return Vector2(size.x * 0.27, size.y * 0.5)

	func _draw() -> void:
		var c := die_center()
		var rad := 118.0
		# a pool of shadow behind it all, so the field stays visible around it
		DuelFX.draw_glow(self, size * 0.5, Vector2(size.x * 0.62, size.y * 0.75), Color(0, 0, 0, 0.85))
		CardFace.text(self, CardFace.font("display_bold"), Vector2(c.x - 200, c.y - rad - 34), "FATE", 30, Color(UITheme.GOLD, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 400, 5)
		var face_col := Color("5a3fb5")
		if landed and face == 20:
			face_col = Color("c99a2e")
		elif landed and face == 1:
			face_col = Color("9a2a3a")
		_draw_d20(c, rad * (1.0 + (0.08 * sin(_t * 30.0) if not landed else 0.0)), spin if not landed else 0.0, face_col)
		var fcol := Color.WHITE
		if landed and face == 20:
			fcol = Color("fff3c4")
		var fnt := CardFace.font("display_bold")
		CardFace.text_in(self, fnt, Rect2(c - Vector2(rad, rad * 0.75), Vector2(rad * 2, rad * 1.5)), str(face), 76, fcol, HORIZONTAL_ALIGNMENT_CENTER, 9, Color(0.05, 0.02, 0.1, 0.9))
		# the bands
		var x := size.x * 0.46
		var w := size.x * 0.5
		var y := size.y * 0.5 - 150
		var label := String(info.get("label", "Fate"))
		CardFace.text(self, fnt, Vector2(x, y), label, CardFace.fit_size(fnt, label, 32, w), UITheme.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
		y += 42
		if landed:
			var mod := int(info.get("mod", 0))
			var line := "Rolled %d" % int(info.roll)
			if mod > 0:
				line += "  +%d  =  %d" % [mod, int(info.total)]
			if info.get("forced", false):
				line = "Foresight: a natural 20"
			CardFace.text(self, CardFace.font("bold"), Vector2(x, y), line, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
		y += 22
		var bands: Array = info.get("bands", [])
		for i in bands.size():
			var b: Dictionary = bands[i]
			var br := Rect2(Vector2(x, y + i * 56), Vector2(w, 48))
			var hit := landed and int(info.get("index", -1)) == i
			if hit:
				DuelFX.draw_glow(self, br.get_center(), br.size * Vector2(0.65, 1.6), Color(UITheme.GOLD, 0.35))
				CardFace.vgrad(self, br, 12, Color(UITheme.GOLD, 0.4), Color(UITheme.GOLD, 0.16))
				CardFace.box(self, br, 12, Color(0, 0, 0, 0), UITheme.GOLD, 2.5)
			else:
				CardFace.vgrad(self, br, 12, Color(0.12, 0.13, 0.22, 0.85), Color(0.04, 0.04, 0.08, 0.85))
				CardFace.box(self, br, 12, Color(0, 0, 0, 0), Color(1, 1, 1, 0.12), 1.5)
			CardFace.text(self, fnt, br.position + Vector2(16, 34), DuelCards.band_range(bands, i), 25, UITheme.GOLD if hit else UITheme.TEXT_DIM)
			var t := DuelCards.outcome_text(int(b.get("damage", 0)), b.get("effects", []), "foe", b.get("text", "Miss"))
			CardFace.text(self, CardFace.font("bold"), br.position + Vector2(104, 33), t, CardFace.fit_size(CardFace.font("bold"), t, 24, br.size.x - 116), Color.WHITE if hit else UITheme.TEXT)
		if bands.is_empty() and landed:
			CardFace.text(self, fnt, Vector2(x, y + 40), String(info.get("text", "")), 30, UITheme.TEXT)

	## A twenty-sided die seen face-on: a hexagon of shaded facets.
	func _draw_d20(c: Vector2, r: float, rot: float, col: Color) -> void:
		var outer := PackedVector2Array()
		for i in 6:
			var a := -PI / 2.0 + TAU * i / 6.0 + rot
			outer.append(c + Vector2(cos(a), sin(a)) * r)
		var inner := PackedVector2Array()
		for i in 3:
			var a := -PI / 2.0 + TAU * i / 3.0 + rot
			inner.append(c + Vector2(cos(a), sin(a)) * r * 0.6)
		DuelFX.draw_glow(self, c, Vector2(r, r) * 1.9, Color(col.lightened(0.4), 0.45))
		draw_colored_polygon(outer, col.darkened(0.45))
		# the three corner facets (darkest) and three side facets (mid)
		for i in 3:
			var o := outer[i * 2]
			var o_prev := outer[(i * 2 + 5) % 6]
			var o_next := outer[(i * 2 + 1) % 6]
			draw_colored_polygon(PackedVector2Array([o, o_next, inner[i]]), col.darkened(0.15 + 0.1 * i))
			draw_colored_polygon(PackedVector2Array([o, inner[i], o_prev]), col.darkened(0.25 + 0.1 * i))
			draw_colored_polygon(PackedVector2Array([inner[i], o_next, inner[(i + 1) % 3]]), col.lerp(Color.WHITE, 0.08))
		draw_polygon(inner, PackedColorArray([col.lightened(0.45), col.lightened(0.15), col.lightened(0.15)]))
		var edge := Color(UITheme.GOLD, 0.95)
		var closed := outer.duplicate()
		closed.append(outer[0])
		draw_polyline(closed, edge, 4.0, true)
		var tri := inner.duplicate()
		tri.append(inner[0])
		draw_polyline(tri, Color(edge, 0.8), 2.5, true)
		for i in 3:
			draw_line(inner[i], outer[i * 2], Color(edge, 0.6), 2.0, true)
			draw_line(inner[i], outer[(i * 2 + 1) % 6], Color(edge, 0.6), 2.0, true)
			draw_line(inner[i], outer[(i * 2 + 5) % 6], Color(edge, 0.6), 2.0, true)


# =============================================================== CardPicker ===
## A pop-up that shows cards (or Totems) and lets the player choose some.
class CardPicker:
	extends Control
	signal done(chosen: Array)

	var items: Array = []        # DuelCard or DuelTotem
	var min_n := 1
	var max_n := 1
	var prompt := ""
	var picked: Array = []
	var extra: Array = []        # cards shown for information only (e.g. revealed Wards)
	var _cells: Array = []
	var _ok: Button

	func setup(p_prompt: String, p_items: Array, p_min: int, p_max: int, p_extra: Array = []) -> CardPicker:
		prompt = p_prompt
		items = p_items
		min_n = p_min
		max_n = p_max
		extra = p_extra
		return self

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.72)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		var box := VBoxContainer.new()
		box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		box.add_theme_constant_override("separation", 22)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(box)
		var l := UITheme.label(prompt, 34, UITheme.GOLD, "display_bold", 6)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(minf(1700, maxf(600, items.size() * 250 + 40)), 390)
		sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(sc)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 20)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(row)
		for it in items:
			var cell := PickCell.new()
			cell.item = it
			cell.custom_minimum_size = Vector2(230, 322)
			cell.tapped.connect(_toggle)
			row.add_child(cell)
			_cells.append(cell)
		if not extra.is_empty():
			var el := UITheme.label("Their Wards: " + ", ".join(extra.map(func(c): return c.card_name())), 26, Color("d9a6f0"))
			el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(el)
		_ok = UITheme.button("Confirm", true, 360)
		_ok.pressed.connect(func() -> void: done.emit(picked.duplicate()))
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_child(_ok)
		box.add_child(hb)
		_update()
		box.position = (get_viewport_rect().size - box.get_combined_minimum_size()) * 0.5

	func _toggle(cell) -> void:
		if picked.has(cell.item):
			picked.erase(cell.item)
		else:
			if max_n == 1:
				picked.clear()
			if picked.size() < max_n:
				picked.append(cell.item)
		_update()

	func _update() -> void:
		for c in _cells:
			c.picked = picked.has(c.item)
			c.queue_redraw()
		_ok.disabled = picked.size() < min_n
		_ok.text = "Confirm" if picked.size() > 0 or min_n > 0 else "Skip"

	class PickCell:
		extends Control
		signal tapped(cell)
		var item
		var picked := false

		func _gui_input(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				tapped.emit(self)
				accept_event()

		func _draw() -> void:
			var r := Rect2(Vector2.ZERO, size)
			if item is DuelTotem:
				DuelCardFace.draw_card(self, r, item.id(), {"hp_left": item.hp_left(), "attrs": item.attrs})
			else:
				DuelCardFace.draw_card(self, r, item.id)
			if picked:
				CardFace.box(self, r.grow(4), 16, Color(UITheme.GOLD, 0.12), UITheme.GOLD, 6.0)


# ================================================================== Dialog ===
## A small question with two answers.
class Dialog:
	extends Control
	signal answered(yes: bool)
	var question := ""
	var yes_text := "Yes"
	var no_text := "No"
	var card_id := ""

	func setup(q: String, y: String, n: String, p_card: String = "") -> Dialog:
		question = q
		yes_text = y
		no_text = n
		card_id = p_card
		return self

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.6)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UITheme.sb(UITheme.PANEL, UITheme.GOLD_DIM, 22, 3, 36))
		add_child(panel)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 24)
		panel.add_child(box)
		if card_id != "":
			var cv := CardPicker.PickCell.new()
			var dc := DuelCard.new(0, card_id, 0)
			cv.item = dc
			cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cv.custom_minimum_size = Vector2(230, 322)
			cv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(cv)
		var l := UITheme.label(question, 30, UITheme.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(700, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 24)
		box.add_child(hb)
		var yb := UITheme.button(yes_text, true, 300)
		yb.pressed.connect(func() -> void: answered.emit(true))
		hb.add_child(yb)
		var nb := UITheme.button(no_text, false, 300)
		nb.pressed.connect(func() -> void: answered.emit(false))
		hb.add_child(nb)
		await get_tree().process_frame
		panel.position = (get_viewport_rect().size - panel.size) * 0.5


# ================================================================ Floaters ===
static func float_text(parent: Control, pos: Vector2, text: String, col: Color, size: int = 56, dur: float = 1.0) -> void:
	var l := UITheme.label(text, size, col, "display_bold", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(400, size + 20)
	l.position = pos - Vector2(200, size * 0.6)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.6, 0.6)
	parent.add_child(l)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2(1, 1), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y - 70, dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
	tw.chain().tween_callback(l.queue_free)
