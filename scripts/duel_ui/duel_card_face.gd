class_name DuelCardFace
extends RefCounted
## Draws the v1 duel cards (DuelCards): Totems, Rites, Wards and Summons.
## Authored on the same 250 x 350 grid as CardFace and scaled to any size.
## The painting comes from assets/art/cards/<card id>.png when it exists,
## otherwise CardFace's painted placeholder in the card's element colours.

const W := 250.0
const H := 350.0
const COMPACT_BELOW := 150.0

const INK := CardFace.INK
const PANEL := CardFace.PANEL
const TEXT := CardFace.TEXT
const TEXT_DIM := CardFace.TEXT_DIM
const GOLD := CardFace.GOLD
const ESSENCE := Color("7fe3ff")
const ESSENCE_DARK := Color("1b4f7a")
const RITE_COL := Color("5c8fd6")
const WARD_COL := Color("b25bd6")


static func f(kind: String) -> Font:
	return CardFace.font(kind)


static func _R(o: Vector2, s: float, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s)


static func _P(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


static func _fs(s: float, n: float) -> int:
	return maxi(1, int(round(n * s)))


## A cut-crystal Essence gem with a number, centred at c.
static func essence_gem(ci: CanvasItem, c: Vector2, r: float, value: int, dim: bool = false) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0 - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var dark := ESSENCE_DARK if not dim else Color("2a2e44")
	var main := ESSENCE if not dim else Color("5a5d72")
	ci.draw_colored_polygon(pts + PackedVector2Array(), Color(0, 0, 0, 0.5))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.9)
	ci.draw_colored_polygon(inner, dark)
	var hi := PackedVector2Array([inner[5], inner[0], inner[1], c])
	ci.draw_colored_polygon(hi, Color(main, 0.55))
	var closed := inner.duplicate()
	closed.append(inner[0])
	ci.draw_polyline(closed, Color(main.lightened(0.3), 0.95), maxf(1.0, r * 0.1), true)
	var fs := int(r * 1.15)
	CardFace.text_in(ci, f("display_bold"), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), str(value), fs, Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, maxi(1, int(r * 0.18)), Color(0, 0, 0, 0.8))


## A small hollow Essence pip (for move costs).
static func essence_pips(ci: CanvasItem, pos: Vector2, s: float, n: int) -> float:
	var x := pos.x
	for i in n:
		var c := Vector2(x, pos.y)
		var d := 5.6 * s
		var pts := PackedVector2Array([c + Vector2(0, -d), c + Vector2(d * 0.8, 0), c + Vector2(0, d), c + Vector2(-d * 0.8, 0)])
		ci.draw_colored_polygon(pts, ESSENCE)
		pts.append(pts[0])
		ci.draw_polyline(pts, ESSENCE_DARK, maxf(1.0, s), true)
		x += 11.0 * s
	return x


# ================================================================== card ===

## opts: attrs (Dictionary: the holder's attributes, lights up Attuned),
##       compact (bool), hp_left (int), cost (int: shown instead of the printed cost)
static func draw_card(ci: CanvasItem, rect: Rect2, id: String, opts: Dictionary = {}) -> void:
	var d: Dictionary = DuelCards.CARDS[id]
	if opts.get("compact", rect.size.x < COMPACT_BELOW):
		_draw_compact(ci, rect, id, d, opts)
		return
	var s := rect.size.x / W
	var o := rect.position
	match d.kind:
		"totem":
			_draw_totem(ci, o, s, id, d, opts)
		"summon":
			_draw_summon(ci, o, s, id, d, opts)
		_:
			_draw_spell(ci, o, s, id, d, opts)


static func _shell(ci: CanvasItem, o: Vector2, s: float, tier: int) -> void:
	CardFace._shell(ci, o, s, tier)


static func _art_placeholder(ci: CanvasItem, r: Rect2, id: String, d: Dictionary) -> void:
	var el: String = d.get("element", "any")
	if d.kind == "rite" or d.kind == "ward":
		var tex := CardFace.art(id)
		if tex != null:
			CardFace.draw_cover(ci, r, tex)
			return
		if el == "any":
			var accent := RITE_COL if d.kind == "rite" else WARD_COL
			CardFace.vgrad_rect(ci, r, accent.lightened(0.15), accent.darkened(0.65))
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(id)
			for i in 12:
				ci.draw_circle(r.position + Vector2(rng.randf(), rng.randf()) * r.size, (1 + rng.randf() * 2.5) * r.size.x / W, Color(1, 1, 1, 0.25))
			Glyphs.draw(ci, "intellect" if d.kind == "rite" else "cunning", r.get_center(), minf(r.size.x, r.size.y) * 0.24, Color(1, 1, 1, 0.4))
			return
	CardFace.draw_art(ci, r, id, el, 0.42)


static func _draw_totem(ci: CanvasItem, o: Vector2, s: float, id: String, d: Dictionary, opts: Dictionary) -> void:
	var tier := int(d.get("tier", 1))
	var el: String = d.element
	_shell(ci, o, s, tier)
	var art_r := _R(o, s, 9, 9, 232, 168)
	_art_placeholder(ci, art_r, id, d)
	CardFace._foil(ci, art_r, s, tier)
	CardFace.vgrad_rect(ci, _R(o, s, 9, 9, 232, 56), Color(0, 0, 0, 0.8), Color(0, 0, 0, 0))
	CardFace.vgrad_rect(ci, _R(o, s, 9, 147, 232, 30), Color(0, 0, 0, 0), Color(0, 0, 0, 0.75))
	CardFace._rim(ci, art_r, s, tier, 5)

	# cost gem, name, element
	var stage := int(d.get("stage", 0))
	essence_gem(ci, _P(o, s, 27, 29), 17 * s, int(opts.get("cost", d.get("cost", 0))))
	var nsz := CardFace.fit_size(f("display_bold"), d.name, _fs(s, 18), 150 * s)
	CardFace.text(ci, f("display_bold"), _P(o, s, 50, 30), d.name, nsz, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 3))
	var sub := "BASIC TOTEM"
	if stage > 0:
		sub = "%s · ASCENDS FROM %s" % [DuelCards.stage_name(stage).to_upper(), String(DuelCards.CARDS[d.ascends_from].name).to_upper()]
	var ssz := CardFace.fit_size(f("bold"), sub, _fs(s, 7.5), 170 * s, 4)
	CardFace.text(ci, f("bold"), _P(o, s, 51, 44), sub, ssz, Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 2))
	CardFace.orb(ci, _P(o, s, 225, 26), 13 * s, el)

	# HP over the bottom-right of the art, tier + affinity bottom-left
	var hp := int(d.hp)
	var attrs: Dictionary = opts.get("attrs", {})
	var at: Dictionary = d.get("attuned", {})
	var attuned := not at.is_empty() and not attrs.is_empty() and int(attrs.get(d.get("affinity", ""), 0)) >= int(at.get("min", 99))
	if attuned:
		hp += int(at.get("hp", 0))
	var hp_s := str(opts.get("hp_left", hp))
	CardFace.text(ci, f("display_bold"), _P(o, s, 150, 172), hp_s, _fs(s, 22), Color("ffe3d6"), HORIZONTAL_ALIGNMENT_RIGHT, 84 * s, _fs(s, 3))
	var hpw := f("display_bold").get_string_size(hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 22)).x
	CardFace.text(ci, f("bold"), _P(o, s, 150, 171) - Vector2(hpw + 3 * s, 0), "HP", _fs(s, 9), Color("ffb8a0"), HORIZONTAL_ALIGNMENT_RIGHT, 84 * s, _fs(s, 2))
	CardFace.tier_gems(ci, _P(o, s, 19, 168), s, tier)
	CardFace.text(ci, f("bold"), _P(o, s, 19 + tier * 9 + 2, 171.5), Lore.TIER_NAMES[tier].to_upper(), _fs(s, 8.5), CardFace.metal(tier, 0), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 2))

	# moves
	var panel := _R(o, s, 9, 181, 232, 112)
	CardFace.box(ci, panel, 6 * s, PANEL)
	ci.draw_line(_P(o, s, 14, 181.5), _P(o, s, 236, 181.5), Color(CardFace.ecol(el, 1), 0.8), maxf(1.0, 1.5 * s))
	_draw_moves(ci, o, s, d, 181.0, 112.0, attuned)

	# keywords + attuned
	var y := 296.0
	var kw: Array = d.get("keywords", [])
	if not kw.is_empty():
		var names := []
		for k in kw:
			names.append(DuelCards.KEYWORDS[k].name)
		var kt := " · ".join(names)
		CardFace.text(ci, f("bold"), _P(o, s, 16, y + 11), kt.to_upper(), CardFace.fit_size(f("bold"), kt.to_upper(), _fs(s, 9), 150 * s, 5), GOLD)
	var aff: String = d.get("affinity", "")
	if aff != "":
		Glyphs.draw(ci, aff, _P(o, s, 229, y + 7), 6.5 * s, Color(1, 1, 1, 0.85))
		CardFace.text(ci, f("bold"), _P(o, s, 140, y + 11), Lore.ATTRIBUTE_NAMES[aff].to_upper(), _fs(s, 8.5), Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, 80 * s)
	_draw_attuned(ci, _R(o, s, 9, 311, 232, 17), s, d, attrs)
	# weakness
	var weak: Array = Lore.weak_to(el)
	CardFace.text(ci, f("bold"), _P(o, s, 16, 341), "WEAK", _fs(s, 8), TEXT_DIM)
	var wx := 48.0
	for w in weak:
		CardFace.orb(ci, _P(o, s, wx, 338), 5.5 * s, w)
		wx += 13.0
	if not weak.is_empty():
		CardFace.text(ci, f("display_bold"), _P(o, s, wx - 4, 342), "×%s" % str(DuelRules.weakness_mult), _fs(s, 9), TEXT)


## Draws the move list into the panel; returns nothing.
static func _draw_moves(ci: CanvasItem, o: Vector2, s: float, d: Dictionary, top: float, height: float, attuned: bool) -> void:
	var moves: Array = d.get("moves", [])
	if moves.is_empty():
		return
	var body := f("body")
	var bonus := int(d.get("attuned", {}).get("damage", 0)) if attuned else 0
	var rows := []
	var total := 0.0
	for m in moves:
		var h := 21.0
		var extra := move_detail(m, d)
		if extra != "":
			h += 12.0 * _lines(body, extra, 214 * s, _fs(s, 8.8)) + 1
		rows.append({"h": h, "extra": extra})
		total += h
	var gap := maxf(2.0, (height - total) / (moves.size() + 1))
	var y := top + gap
	for i in moves.size():
		var m: Dictionary = moves[i]
		var cost := int(m.get("cost", 0))
		var x := 17.0
		if cost == 0:
			CardFace.box(ci, _R(o, s, 15, y + 3, 38, 13), 6.5 * s, Color(1, 1, 1, 0.12))
			CardFace.text_in(ci, f("bold"), _R(o, s, 15, y + 3, 38, 13), "STRIKE", _fs(s, 7), Color(1, 1, 1, 0.85))
			x = 58.0
		else:
			x = (essence_pips(ci, _P(o, s, 22, y + 9.5), s, cost) - o.x) / s + 2.0
		var name_w := 180.0 - x
		var nsz := CardFace.fit_size(f("display_bold"), m.name, _fs(s, 13), name_w * s)
		CardFace.text(ci, f("display_bold"), _P(o, s, x, y + 14), m.name, nsz, TEXT)
		var dmg := int(m.get("damage", 0))
		var dtxt := ""
		if m.has("fate"):
			dtxt = "d20"
		elif dmg > 0:
			dtxt = str(dmg + bonus)
		if dtxt != "":
			var col := Color.WHITE if bonus == 0 or m.has("fate") else GOLD
			CardFace.text(ci, f("display_bold"), _P(o, s, 170, y + 15), dtxt, _fs(s, 16 if dtxt != "d20" else 12), col, HORIZONTAL_ALIGNMENT_RIGHT, 64 * s)
		var extra: String = rows[i].extra
		if extra != "":
			ci.draw_multiline_string(body, _P(o, s, 17, y + 27), extra, HORIZONTAL_ALIGNMENT_LEFT, 214 * s, _fs(s, 8.8), -1, TEXT_DIM)
		y += rows[i].h
		if i < moves.size() - 1:
			ci.draw_line(_P(o, s, 18, y + gap * 0.5), _P(o, s, 232, y + gap * 0.5), Color(1, 1, 1, 0.07), maxf(1.0, s))
		y += gap


static func _lines(font: Font, t: String, width: float, size: int) -> int:
	var h := font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, width, size).y
	return maxi(1, int(round(h / font.get_height(size))))


## The small print under a move: its target, effects and Fate bands.
static func move_detail(m: Dictionary, _d: Dictionary = {}) -> String:
	var parts := []
	var tk: String = m.get("target", "foe")
	if m.has("fate"):
		var bands: Array = m.fate
		var bl := []
		for i in bands.size():
			var b: Dictionary = bands[i]
			bl.append("%s %s" % [DuelCards.band_range(bands, i),
				DuelCards.outcome_text(int(b.get("damage", 0)), b.get("effects", []), tk, b.get("text", "Miss"))])
		return " · ".join(bl)
	match tk:
		"foe_totem": parts.append("Hits a Totem")
		"all_foes": parts.append("Hits every enemy Totem")
		"ally": parts.append("One of your Totems")
	for e in m.get("effects", []):
		var t := DuelCards.effect_text(e)
		if t != "":
			parts.append(t)
	if parts.is_empty():
		return ""
	var out := ", ".join(parts)
	return out.substr(0, 1).to_upper() + out.substr(1) + "."


static func _draw_attuned(ci: CanvasItem, r: Rect2, s: float, d: Dictionary, attrs: Dictionary) -> void:
	var t := attuned_text(d)
	if t == "":
		return
	var at: Dictionary = d.attuned
	var active := not attrs.is_empty() and int(attrs.get(d.get("affinity", ""), 0)) >= int(at.get("min", 99))
	var dim := not attrs.is_empty() and not active
	CardFace.box(ci, r, 5 * s, Color(GOLD, 0.2) if active else Color(1, 1, 1, 0.05), Color(GOLD, 0.8 if active else 0.25), maxf(1.0, s))
	var col := GOLD if not dim else Color(TEXT_DIM, 0.8)
	CardFace.text(ci, f("bold"), r.position + Vector2(8, 12) * s, "ATTUNED", _fs(s, 7.5), col)
	var lw := f("bold").get_string_size("ATTUNED", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 7.5)).x
	var sz := CardFace.fit_size(f("body"), t, _fs(s, 9), r.size.x - lw - 20 * s, 5)
	CardFace.text(ci, f("body"), r.position + Vector2(13 * s + lw, 12 * s), t, sz, TEXT if not dim else TEXT_DIM)


static func attuned_text(d: Dictionary) -> String:
	var a: Dictionary = d.get("attuned", {})
	if a.is_empty():
		return ""
	var parts := []
	if a.has("damage"):
		parts.append("+%d damage" % int(a.damage))
	if a.has("hp"):
		parts.append("+%d HP" % int(a.hp))
	if a.has("cost"):
		parts.append("moves cost %d less" % int(a.cost))
	if a.has("keyword"):
		parts.append("gains %s" % DuelCards.KEYWORDS[a.keyword].name)
	if a.has("draw"):
		parts.append("draw %d when called" % int(a.draw))
	return "%s %d+: %s" % [Lore.ATTRIBUTE_NAMES[d.get("affinity", "might")], int(a.get("min", 5)), ", ".join(parts)]


static func _draw_spell(ci: CanvasItem, o: Vector2, s: float, id: String, d: Dictionary, opts: Dictionary) -> void:
	var tier := int(d.get("tier", 1))
	var is_ward: bool = d.kind == "ward"
	var accent := WARD_COL if is_ward else RITE_COL
	_shell(ci, o, s, tier)
	var art_r := _R(o, s, 9, 9, 232, 180)
	_art_placeholder(ci, art_r, id, d)
	CardFace.vgrad_rect(ci, _R(o, s, 9, 9, 232, 56), Color(0, 0, 0, 0.8), Color(0, 0, 0, 0))
	CardFace._rim(ci, art_r, s, tier, 5)
	essence_gem(ci, _P(o, s, 27, 29), 17 * s, int(opts.get("cost", d.get("cost", 0))))
	var nsz := CardFace.fit_size(f("display_bold"), d.name, _fs(s, 18), 150 * s)
	CardFace.text(ci, f("display_bold"), _P(o, s, 50, 32), d.name, nsz, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 3))
	var el: String = d.get("element", "any")
	if el != "any":
		CardFace.orb(ci, _P(o, s, 225, 26), 13 * s, el)
	var tag := _R(o, s, 184 if el == "any" else 150, 170, 52 if el == "any" else 52, 16)
	tag = _R(o, s, 180, 168, 54, 16)
	CardFace.box(ci, tag, 8 * s, accent)
	CardFace.text_in(ci, f("bold"), tag, "WARD" if is_ward else "RITE", _fs(s, 8.5), Color.WHITE)
	CardFace.tier_gems(ci, _P(o, s, 19, 176), s, tier)
	var panel := _R(o, s, 9, 193, 232, 148)
	CardFace.box(ci, panel, 6 * s, PANEL)
	ci.draw_line(_P(o, s, 14, 193.5), _P(o, s, 236, 193.5), Color(accent, 0.9), maxf(1.0, 1.5 * s))
	var text := DuelCards.card_text(id)
	var tsz := 13.0
	while tsz > 8.0 and f("body").get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, 212 * s, _fs(s, tsz)).y > 100 * s:
		tsz -= 0.5
	ci.draw_multiline_string(f("body"), _P(o, s, 19, 218), text, HORIZONTAL_ALIGNMENT_LEFT, 212 * s, _fs(s, tsz), -1, TEXT)
	var rule := "Set face down. Springs on your opponent's turn." if is_ward else "Cast on your turn, then discard."
	ci.draw_multiline_string(f("body"), _P(o, s, 15, 334), rule, HORIZONTAL_ALIGNMENT_CENTER, 220 * s, _fs(s, 8.5), -1, TEXT_DIM)


static func _draw_summon(ci: CanvasItem, o: Vector2, s: float, id: String, d: Dictionary, opts: Dictionary) -> void:
	var tier := int(d.get("tier", 6))
	var el: String = d.element
	_shell(ci, o, s, tier)
	var art_r := _R(o, s, 9, 9, 232, 332)
	CardFace.draw_art(ci, art_r, id, el, 0.35)
	CardFace._foil(ci, art_r, s, tier)
	CardFace.vgrad_rect(ci, _R(o, s, 9, 9, 232, 70), Color(0, 0, 0, 0.82), Color(0, 0, 0, 0))
	CardFace.vgrad_rect(ci, _R(o, s, 9, 190, 232, 151), Color(0, 0, 0, 0), Color(0, 0, 0, 0.9))
	CardFace._rim(ci, art_r, s, tier, 6)
	essence_gem(ci, _P(o, s, 27, 29), 17 * s, int(opts.get("cost", d.get("cost", 0))))
	CardFace.box(ci, _R(o, s, 50, 16, 62, 14), 7 * s, Color(CardFace.metal(tier, 1), 0.9))
	CardFace.text_in(ci, f("bold"), _R(o, s, 50, 16, 62, 14), "SUMMON", _fs(s, 8), INK)
	CardFace.tier_gems(ci, _P(o, s, 120, 23), s, tier, 8.0)
	CardFace.orb(ci, _P(o, s, 225, 26), 13 * s, el)
	var nm: String = d.name
	var nsz := CardFace.fit_size(f("display_bold"), nm, _fs(s, 17), 214 * s)
	CardFace.text(ci, f("display_bold"), _P(o, s, 16, 60), nm, nsz, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 3))
	var mv: Dictionary = d.move
	CardFace.text(ci, f("display_bold"), _P(o, s, 16, 262), mv.name, _fs(s, 15), GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 2))
	var text := DuelCards.card_text(id)
	ci.draw_multiline_string(f("body"), _P(o, s, 17, 282), text, HORIZONTAL_ALIGNMENT_LEFT, 216 * s, _fs(s, 10.5), -1, TEXT)


## A simple face for small sizes (the hand on a phone): art, cost, name, HP.
static func _draw_compact(ci: CanvasItem, rect: Rect2, id: String, d: Dictionary, opts: Dictionary) -> void:
	var s := rect.size.x / W
	var o := rect.position
	var tier := int(d.get("tier", 1))
	_shell(ci, o, s, tier)
	var inner := _R(o, s, 9, 9, 232, 332)
	_art_placeholder(ci, inner, id, d)
	if d.kind == "rite" or d.kind == "ward":
		var accent := WARD_COL if d.kind == "ward" else RITE_COL
		CardFace.box(ci, _R(o, s, 9, 250, 232, 38), 0, Color(accent, 0.92))
		CardFace.text_in(ci, f("bold"), _R(o, s, 9, 250, 232, 38), "WARD" if d.kind == "ward" else "RITE", _fs(s, 26), Color.WHITE)
	elif d.kind == "summon":
		CardFace.box(ci, _R(o, s, 9, 250, 232, 38), 0, Color(CardFace.metal(tier, 1), 0.95))
		CardFace.text_in(ci, f("bold"), _R(o, s, 9, 250, 232, 38), "SUMMON", _fs(s, 26), INK)
	else:
		CardFace.orb(ci, _P(o, s, 206, 48), 30 * s, d.element)
		var hp := str(opts.get("hp_left", int(d.hp)))
		CardFace.text(ci, f("display_bold"), _P(o, s, 150, 280), hp, _fs(s, 46), Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 84 * s, _fs(s, 7))
		if int(d.get("stage", 0)) > 0:
			CardFace.box(ci, _R(o, s, 18, 250, 70, 32), 16 * s, Color(0, 0, 0, 0.65), Color(GOLD, 0.8), maxf(1.0, 2 * s))
			CardFace.text_in(ci, f("bold"), _R(o, s, 18, 250, 70, 32), ["", "II", "III"][clampi(int(d.stage), 0, 2)], _fs(s, 24), GOLD)
	CardFace.vgrad_rect(ci, _R(o, s, 9, 288, 232, 53), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.9))
	var nsz := CardFace.fit_size(f("display_bold"), d.name, _fs(s, 32), 222 * s, 4)
	CardFace.text(ci, f("display_bold"), _P(o, s, 9, 330), d.name, nsz, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 232 * s, _fs(s, 6))
	CardFace._rim(ci, inner, s, tier, 5)
	essence_gem(ci, _P(o, s, 44, 46), 34 * s, int(opts.get("cost", d.get("cost", 0))), opts.get("unaffordable", false))


static func draw_back(ci: CanvasItem, rect: Rect2) -> void:
	CardFace.draw_back(ci, rect)
