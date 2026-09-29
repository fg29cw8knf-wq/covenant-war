class_name DuelViews
extends RefCounted
## The pieces the Duel Lab screen is built from: the Totem on its platform,
## cards in hand, each duellist's panel, the d20, and pop-up pickers.


# ================================================================ TotemView ===
## One of the Circle's slots. When a Totem stands in it, the creature is drawn
## "summoned out of its card": its painting in an arched window over a glowing
## platform, with HP, shield, conditions and keywords. Tap it to open its moves.
class TotemView:
	extends Control
	signal tapped(view)

	var side := 0              # which duellist's slot this is
	var slot := 0
	var mine := false
	var totem: DuelTotem = null
	var highlight := ""        # "", "target", "selected", "ready", "dim"
	var offset := Vector2.ZERO # lunge / shake
	var pop := 1.0             # scale for summon / KO
	var fade := 1.0
	var flash := 0.0
	var flash_color := Color(1, 0.25, 0.2)
	var shown_hp := -1.0
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_totem(t: DuelTotem) -> void:
		if t != totem:
			shown_hp = -1.0
		totem = t
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if totem != null:
			var target := float(totem.hp_left())
			if shown_hp < 0.0:
				shown_hp = target
			shown_hp = move_toward(shown_hp, target, delta * 160.0)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tapped.emit(self)
			accept_event()

	func art_rect() -> Rect2:
		var w := size.x * 0.6
		var h := size.y * 0.56
		var bob := sin(_t * 1.6 + slot * 1.3) * 3.0 if totem != null and not totem.asleep else 0.0
		return Rect2(Vector2((size.x - w) * 0.5, size.y * 0.04 + bob), Vector2(w, h))

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		draw_set_transform(c + offset, 0.0, Vector2(pop, pop))
		var o := -c
		var plat := Rect2(o + Vector2(size.x * 0.1, size.y * 0.53), Vector2(size.x * 0.8, size.y * 0.14))
		var el := "any" if totem == null else totem.element()
		var ecol := Lore.color(el, 1)
		# platform
		var glow := 0.18 + (0.12 * sin(_t * 2.4) if highlight == "ready" else 0.0)
		_ellipse(plat.get_center(), plat.size * 0.5, Color(ecol if totem != null else Color(1, 1, 1), glow * fade))
		_ellipse_ring(plat.get_center(), plat.size * 0.5, Color(ecol.lightened(0.3) if totem != null else Color(1, 1, 1, 0.5), (0.5 if totem != null else 0.18) * fade), 3.0)
		if totem == null:
			if highlight == "target":
				var a := 0.55 + 0.35 * sin(_t * 5.0)
				_ellipse(plat.get_center(), plat.size * 0.5, Color(UITheme.GOLD, 0.2))
				_ellipse_ring(plat.get_center(), plat.size * 0.5, Color(UITheme.GOLD, a), 5.0)
				CardFace.text(self, CardFace.font("bold"), o + Vector2(0, size.y * 0.5), "TAP", 26, Color(UITheme.GOLD, a), HORIZONTAL_ALIGNMENT_CENTER, size.x)
			draw_set_transform(Vector2.ZERO)
			return
		var ar := art_rect()
		ar.position += o
		# the creature: art in an arched window with the element's rim
		var pts := _arch(ar)
		var mod := Color(1, 1, 1, fade)
		if highlight == "dim":
			mod = Color(0.55, 0.55, 0.6, fade)
		draw_colored_polygon(pts, Color(0, 0, 0, 0.6 * fade))
		var tex := CardFace.art(totem.id())
		_draw_art_clipped(ar, pts, tex, mod)
		var closed := pts.duplicate()
		closed.append(pts[0])
		var rim := CardFace.metal(totem.tier(), 0)
		draw_polyline(closed, Color(rim, 0.9 * fade), 4.0, true)
		if flash > 0.0:
			draw_colored_polygon(pts, Color(flash_color, flash * 0.6))
		if totem.asleep:
			CardFace.text(self, CardFace.font("display_bold"), ar.position + Vector2(ar.size.x - 30, 40 + sin(_t * 2.0) * 6.0), "z", 34, Color("c9b8ff", 0.9 * fade), HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
			CardFace.text(self, CardFace.font("display_bold"), ar.position + Vector2(ar.size.x - 12, 14 + sin(_t * 2.0 + 1.0) * 6.0), "Z", 26, Color("c9b8ff", 0.7 * fade), HORIZONTAL_ALIGNMENT_LEFT, -1, 5)
		# shield bubble
		if totem.shield > 0:
			var sc := ar.get_center()
			draw_arc(sc, ar.size.x * 0.58, 0, TAU, 72, Color("9fe8ff", (0.45 + 0.2 * sin(_t * 3.0)) * fade), 5.0, true)
			_chip(Rect2(ar.position + Vector2(ar.size.x - 70, ar.size.y - 34), Vector2(76, 30)), "◈ %d" % totem.shield, Color("9fe8ff"), Color("0b2a3a"))
		# element orb + stage
		CardFace.orb(self, ar.position + Vector2(ar.size.x - 6, 6), 22, el)
		if totem.stage() > 0:
			_chip(Rect2(ar.position + Vector2(-14, -6), Vector2(54, 30)), ["", "II", "III"][totem.stage()], UITheme.GOLD, Color("2a1d05"))
		# name + HP bar
		var ny := o.y + size.y * 0.75
		var nm := totem.card_name()
		var nsz := CardFace.fit_size(CardFace.font("display_bold"), nm, 26, size.x - 20)
		CardFace.text(self, CardFace.font("display_bold"), Vector2(o.x, ny), nm, nsz, Color(UITheme.TEXT, fade), HORIZONTAL_ALIGNMENT_CENTER, size.x, 6)
		_draw_hp(Rect2(Vector2(o.x + size.x * 0.14, ny + 12), Vector2(size.x * 0.72, 34)))
		# conditions + keywords, stacked on the left of the art
		var y := ar.position.y + 30
		for cnd in totem.conditions():
			var label: String = DuelCards.STATUS_NAMES[cnd].to_upper()
			var col: Color = {"burn": Color("ff9a4a"), "poison": Color("9be15d"), "stun": Color("ffe066"), "sleep": Color("b9a4ff")}[cnd]
			_chip(Rect2(Vector2(o.x + 4, y), Vector2(0, 30)), label, col, Color("1a1420"))
			y += 36
		var kx := o.x + size.x - 36
		var ky := ar.position.y + 60
		for k in totem.keywords():
			var glyph: String = {"guardian": "resolve", "swift": "swiftness", "channel": "presence", "thorns": "venom", "harvest": "heart", "burrow": "earth"}.get(k, "any")
			draw_circle(Vector2(kx + 14, ky), 18, Color(0, 0, 0, 0.7 * fade))
			draw_arc(Vector2(kx + 14, ky), 18, 0, TAU, 32, Color(UITheme.GOLD, 0.8 * fade), 2.0, true)
			Glyphs.draw(self, glyph, Vector2(kx + 14, ky), 11, Color(UITheme.GOLD, fade))
			ky += 42
		# highlights
		if highlight == "target" or highlight == "selected":
			var a := 0.6 + 0.4 * sin(_t * 5.0)
			var col := UITheme.GOLD if highlight == "target" else UITheme.MINE
			var big := _arch(ar.grow(8))
			big.append(big[0])
			draw_polyline(big, Color(col, a), 6.0, true)
		elif highlight == "ready":
			var big := _arch(ar.grow(6))
			big.append(big[0])
			draw_polyline(big, Color(UITheme.MINE, 0.35 + 0.25 * sin(_t * 2.4)), 4.0, true)
		draw_set_transform(Vector2.ZERO)

	func _draw_hp(r: Rect2) -> void:
		var mx := float(totem.max_hp())
		var left := shown_hp if shown_hp >= 0.0 else float(totem.hp_left())
		var frac := clampf(left / maxf(1.0, mx), 0.0, 1.0)
		var col := Color("7ee08a")
		if frac <= 0.25:
			col = Color("ff6a5a")
		elif frac <= 0.5:
			col = Color("ffd166")
		CardFace.box(self, r, r.size.y * 0.5, Color(0.03, 0.03, 0.06, 0.85 * fade), Color(col, 0.6 * fade), 2.0)
		var inner := r.grow(-5)
		CardFace.box(self, Rect2(inner.position, Vector2(inner.size.x * frac, inner.size.y)), inner.size.y * 0.5, Color(col, 0.85 * fade))
		CardFace.text_in(self, CardFace.font("display_bold"), r, "%d / %d" % [int(round(left)), int(mx)], 22, Color(1, 1, 1, fade), HORIZONTAL_ALIGNMENT_CENTER, 4)

	func _chip(r: Rect2, label: String, bg: Color, fg: Color) -> void:
		var fnt := CardFace.font("bold")
		var w := fnt.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 20
		if r.size.x < w:
			r.size.x = w
		CardFace.box(self, r, r.size.y * 0.5, Color(bg, 0.95 * fade))
		CardFace.text_in(self, fnt, r, label, 18, fg)

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

	func _draw_art_clipped(r: Rect2, pts: PackedVector2Array, tex: Texture2D, mod: Color) -> void:
		if tex != null:
			var ts := Vector2(tex.get_width(), tex.get_height())
			var k := maxf(r.size.x / ts.x, r.size.y / ts.y)
			var src := Rect2((ts - r.size / k) * Vector2(0.5, 0.4), r.size / k)
			var uvs := PackedVector2Array()
			for p in pts:
				uvs.append((src.position + (p - r.position) / k) / ts)
			var cols := PackedColorArray()
			for p in pts:
				cols.append(mod)
			draw_polygon(pts, cols, uvs, tex)
			return
		# Placeholder: the element's colours with its glyph as the "creature".
		var el := totem.element()
		var cols := PackedColorArray()
		var light := Lore.color(el, 0)
		var dark := Lore.color(el, 2)
		for p in pts:
			var k := clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)
			cols.append(Color(light.lerp(dark.darkened(0.4), k), mod.a))
		draw_polygon(pts, cols)
		var ctr := r.get_center() + Vector2(0, r.size.y * 0.04)
		for i in 5:
			draw_circle(ctr, r.size.x * (0.42 - i * 0.07), Color(light, 0.06 * mod.a))
		Glyphs.draw(self, el, ctr + Vector2(0, 3), r.size.x * 0.3, Color(0, 0, 0, 0.25 * mod.a))
		Glyphs.draw(self, el, ctr, r.size.x * 0.3, Color(light.lightened(0.2), 0.85 * mod.a) * Color(mod.r, mod.g, mod.b, 1))
		var nm := totem.card_name()
		var initials := nm.substr(0, 1)
		CardFace.text(self, CardFace.font("display_bold"), Vector2(r.position.x, r.end.y - 16), initials, 30, Color(1, 1, 1, 0.25 * mod.a), HORIZONTAL_ALIGNMENT_CENTER, r.size.x)

	func _ellipse(c: Vector2, rad: Vector2, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48.0
			pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
		draw_colored_polygon(pts, col)

	func _ellipse_ring(c: Vector2, rad: Vector2, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			pts.append(c + Vector2(cos(a) * rad.x, sin(a) * rad.y))
		draw_polyline(pts, col, w, true)


# ================================================================= HandCard ===
class HandCard:
	extends Control
	signal tapped(v)

	var card: DuelCard
	var state := "normal"      # normal, playable, selected, unaffordable
	var cost_shown := -1
	var lift := 0.0
	var _t := 0.0
	var attrs: Dictionary = {}

	func _init(c: DuelCard) -> void:
		card = c
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		var want := 40.0 if state == "selected" else 0.0
		lift = move_toward(lift, want, delta * 400.0)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tapped.emit(self)
			accept_event()

	func _draw() -> void:
		var r := Rect2(Vector2(0, -lift), size)
		if state == "playable" or state == "selected":
			var a := 0.5 + 0.35 * sin(_t * 3.0) if state == "playable" else 1.0
			var col := UITheme.MINE if state == "playable" else UITheme.GOLD
			CardFace.box(self, r.grow(5), 18, Color(0, 0, 0, 0), Color(col, a), 5.0)
		var opts := {"compact": true, "attrs": attrs}
		if cost_shown >= 0:
			opts["cost"] = cost_shown
		opts["unaffordable"] = state == "unaffordable"
		DuelCardFace.draw_card(self, r, card.id, opts)
		if state == "unaffordable":
			CardFace.box(self, r, 12, Color(0, 0, 0, 0.35))


# ============================================================== PlayerPanel ===
## A duellist's panel: name, patron, Life, Guard, Essence, Wards, deck and hand.
class PlayerPanel:
	extends Control
	signal tapped(panel)

	var player: DuelPlayer = null
	var mine := false
	var active := false
	var targetable := false
	var shown_life := -1.0
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
			shown_life = move_toward(shown_life, float(player.life), delta * 220.0)
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
			tapped.emit(self)
			accept_event()

	func life_rect() -> Rect2:
		return Rect2(Vector2(16, 86), Vector2(size.x - 32, 92))

	func _draw() -> void:
		if player == null:
			return
		var off := Vector2(sin(_t * 60.0) * shake, 0)
		draw_set_transform(off)
		var r := Rect2(Vector2.ZERO, size)
		var edge := UITheme.MINE if mine else UITheme.THEIRS
		CardFace.box(self, r, 18, Color(0.04, 0.05, 0.09, 0.92), Color(edge, 0.9 if active else 0.3), 3.0 if active else 2.0)
		# patron medallion + name
		var patron := player.patron()
		var pc := Vector2(52, 46)
		draw_circle(pc, 32, Color(0, 0, 0, 0.6))
		if patron == "":
			draw_arc(pc, 32, 0, TAU, 48, Color(UITheme.TEXT_DIM, 0.8), 3.0, true)
			Glyphs.draw(self, "crown_sigil", pc, 18, UITheme.TEXT_DIM)
		else:
			CardFace.orb(self, pc, 30, Lore.GODS[patron].element)
		var nm := player.player_name
		CardFace.text(self, CardFace.font("display_bold"), Vector2(96, 42), nm, CardFace.fit_size(CardFace.font("display_bold"), nm, 30, size.x - 110), UITheme.TEXT)
		var sub := "Unsworn" if patron == "" else "Sworn to %s" % Lore.GODS[patron].name
		CardFace.text(self, CardFace.font("body"), Vector2(97, 70), sub, 20, UITheme.TEXT_DIM)
		# Life
		var lr := life_rect()
		var frac := clampf(shown_life / maxf(1.0, player.max_life), 0.0, 1.0)
		var lcol := Color("ff5d73") if frac > 0.3 else Color("ff3030")
		CardFace.box(self, lr, 16, Color(0.1, 0.02, 0.05, 0.9), Color(lcol, 0.5), 2.0)
		CardFace.box(self, Rect2(lr.position + Vector2(6, 58), Vector2((lr.size.x - 12) * frac, 22)), 11, Color(lcol, 0.9))
		CardFace.text(self, CardFace.font("bold"), lr.position + Vector2(16, 30), "LIFE", 20, Color(lcol.lightened(0.4), 0.9))
		CardFace.text(self, CardFace.font("display_bold"), lr.position + Vector2(0, 50), str(int(round(shown_life))), 46, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, lr.size.x - 16, 6)
		if targetable:
			var a := 0.55 + 0.4 * sin(_t * 5.0)
			CardFace.box(self, lr.grow(6), 20, Color(UITheme.GOLD, 0.08), Color(UITheme.GOLD, a), 5.0)
			CardFace.text(self, CardFace.font("bold"), lr.position + Vector2(76, 30), "TAP TO STRIKE", 18, Color(UITheme.GOLD, a))
		if flash > 0.0:
			CardFace.box(self, lr, 16, Color(flash_color, flash * 0.6))
		# Guard + Essence
		var y := 196.0
		Glyphs.draw(self, "resolve", Vector2(34, y + 14), 14, Color("c7d2ff"))
		CardFace.text(self, CardFace.font("bold"), Vector2(56, y + 22), "Guard %d" % player.guard(), 21, Color("c7d2ff"))
		CardFace.text(self, CardFace.font("bold"), Vector2(0, y + 22), "Deck %d" % player.deck.size(), 21, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 18)
		y += 44
		CardFace.text(self, CardFace.font("bold"), Vector2(18, y + 16), "ESSENCE", 18, DuelCardFace.ESSENCE)
		CardFace.text(self, CardFace.font("display_bold"), Vector2(0, y + 18), "%d / %d" % [player.essence, player.essence_max], 24, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 18)
		y += 30
		var n := maxi(player.essence_max, player.essence)
		var gap := minf(26.0, (size.x - 40) / maxf(1.0, n))
		for i in n:
			var c := Vector2(30 + i * gap, y + 14)
			var full := i < player.essence
			var d := 10.0
			var pts := PackedVector2Array([c + Vector2(0, -d), c + Vector2(d * 0.75, 0), c + Vector2(0, d), c + Vector2(-d * 0.75, 0)])
			draw_colored_polygon(pts, DuelCardFace.ESSENCE if full else Color(1, 1, 1, 0.08))
			pts.append(pts[0])
			draw_polyline(pts, Color(DuelCardFace.ESSENCE, 0.6), 1.5, true)
		y += 40
		# Wards and hand
		CardFace.text(self, CardFace.font("bold"), Vector2(18, y + 18), "WARDS", 18, Color("d9a6f0"))
		for i in player.ward_slots():
			var wr := Rect2(Vector2(104 + i * 58, y), Vector2(46, 64))
			if i < player.wards.size():
				if reveal_wards:
					DuelCardFace.draw_card(self, wr, player.wards[i].id, {"compact": true})
				else:
					CardFace.draw_back(self, wr)
			else:
				CardFace.box(self, wr, 6, Color(1, 1, 1, 0.04), Color(1, 1, 1, 0.15), 1.5)
		if not mine:
			CardFace.text(self, CardFace.font("bold"), Vector2(0, y + 18), "Hand %d" % player.hand.size(), 21, UITheme.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 18)
		if player.fortune_left > 0:
			CardFace.text(self, CardFace.font("bold"), Vector2(0, y + 50), "Fortune %d" % player.fortune_left, 19, UITheme.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, size.x - 18)
		draw_set_transform(Vector2.ZERO)


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

	func _draw() -> void:
		var c := Vector2(size.x * 0.36, size.y * 0.5)
		var rad := 110.0
		CardFace.box(self, Rect2(Vector2(size.x * 0.1, size.y * 0.5 - 190), Vector2(size.x * 0.8, 380)), 28, Color(0.02, 0.02, 0.05, 0.9), Color(UITheme.GOLD, 0.5), 3.0)
		# d20 silhouette: hexagon with inner triangle facets
		var pts := PackedVector2Array()
		for i in 6:
			var a := TAU * i / 6.0 - PI / 2.0 + spin
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		var col := Color("3b2a78") if not landed else Color("5a3fb5")
		draw_colored_polygon(pts, col)
		var tri := PackedVector2Array()
		for i in 3:
			var a := TAU * i / 3.0 - PI / 2.0 + spin
			tri.append(c + Vector2(cos(a), sin(a)) * rad * 0.62)
		draw_colored_polygon(tri, col.lightened(0.18))
		for i in 6:
			draw_line(pts[i], tri[(i + 1) / 2 % 3], Color(1, 1, 1, 0.18), 2.0, true)
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color(UITheme.GOLD, 0.9), 4.0, true)
		var fcol := Color.WHITE
		if landed and face == 20:
			fcol = UITheme.GOLD
		elif landed and face == 1:
			fcol = Color("ff6a5a")
		CardFace.text_in(self, CardFace.font("display_bold"), Rect2(c - Vector2(rad, rad), Vector2(rad, rad) * 2), str(face), 64, fcol, HORIZONTAL_ALIGNMENT_CENTER, 8)
		var x := size.x * 0.52
		var y := size.y * 0.5 - 150
		CardFace.text(self, CardFace.font("display_bold"), Vector2(x, y), String(info.get("label", "Fate")), CardFace.fit_size(CardFace.font("display_bold"), String(info.get("label", "Fate")), 30, size.x * 0.36), UITheme.GOLD)
		y += 44
		if landed:
			var mod := int(info.get("mod", 0))
			var line := "Rolled %d" % int(info.roll)
			if mod > 0:
				line += "  +%d  =  %d" % [mod, int(info.total)]
			if info.get("forced", false):
				line = "Foresight: a natural 20"
			CardFace.text(self, CardFace.font("bold"), Vector2(x, y), line, 26, UITheme.TEXT)
		y += 22
		var bands: Array = info.get("bands", [])
		for i in bands.size():
			var b: Dictionary = bands[i]
			var br := Rect2(Vector2(x, y + i * 50), Vector2(size.x * 0.34, 44))
			var hit := landed and int(info.get("index", -1)) == i
			CardFace.box(self, br, 10, Color(UITheme.GOLD, 0.22) if hit else Color(1, 1, 1, 0.05), Color(UITheme.GOLD, 0.9) if hit else Color(1, 1, 1, 0.1), 2.0)
			CardFace.text(self, CardFace.font("display_bold"), br.position + Vector2(14, 31), DuelCards.band_range(bands, i), 24, UITheme.GOLD if hit else UITheme.TEXT_DIM)
			var t := DuelCards.outcome_text(int(b.get("damage", 0)), b.get("effects", []), "foe", b.get("text", "Miss"))
			CardFace.text(self, CardFace.font("body"), br.position + Vector2(96, 30), t, CardFace.fit_size(CardFace.font("body"), t, 23, br.size.x - 104), Color.WHITE if hit else UITheme.TEXT)
		if bands.is_empty() and landed:
			CardFace.text(self, CardFace.font("display_bold"), Vector2(x, y + 40), String(info.get("text", "")), 30, UITheme.TEXT)


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
