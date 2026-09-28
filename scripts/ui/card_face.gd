class_name CardFace
extends RefCounted
## Draws Sigil cards: the full face, a compact face for small sizes, and the back.
## Everything is vector-drawn except the illustration, which is loaded from
## res://assets/art/cards/<card id>.png when it exists. Until then a painted
## placeholder in the card's element colours stands in.
##
## The layout is authored on a 250 x 350 grid and scaled to any size.

const W := 250.0
const H := 350.0
const ASPECT := H / W

## Below this width (in pixels) a card is drawn with the compact layout.
const COMPACT_BELOW := 150.0

const INK := Color("0b0d15")
const PANEL := Color("141827")
const TEXT := Color("ece7da")
const TEXT_DIM := Color("9c9aa8")
const GOLD := Color("f2c96b")

## Frame metal for each tier: light, main, dark.
const TIER_METAL := [
	["c9ccd6", "8a8f9e", "3c404c"],
	["c9ccd6", "8a8f9e", "3c404c"],  # 1 Spark: pewter
	["f4f6fb", "b3bbcc", "555d70"],  # 2 Glimmer: silver
	["c8fbff", "5cc7d8", "1d5563"],  # 3 Crystal: aquamarine
	["f3cf9a", "b07a3c", "4e3014"],  # 4 Relic: bronze
	["fff2b0", "e1b340", "6e4c0c"],  # 5 Legend: gold
	["ffd6f2", "c77ad8", "4b1f63"],  # 6 Demigod: amethyst
	["ffffff", "f5dc8a", "8a6a1c"],  # 7 Divine: white gold
]

static var _fonts := {}
static var _art := {}


# ================================================================== fonts ===

## "display" (Cinzel), "display_bold", "body", "bold".
static func font(kind: String = "body") -> Font:
	if _fonts.is_empty():
		_fonts["display"] = _load_font(["Cinzel-SemiBold.woff2", "LilitaOne-Regular.ttf"])
		_fonts["display_bold"] = _load_font(["Cinzel-Bold.woff2", "LilitaOne-Regular.ttf"])
		_fonts["body"] = _load_font(["SourceSans3-SemiBold.woff2", "Nunito-SemiBold.ttf"])
		_fonts["bold"] = _load_font(["SourceSans3-Bold.woff2", "Nunito-ExtraBold.ttf"])
	return _fonts.get(kind, _fonts["body"])


static func _load_font(files: Array) -> Font:
	for f in files:
		var p: String = "res://assets/fonts/" + f
		if ResourceLoader.exists(p):
			return load(p)
	return ThemeDB.fallback_font


# ================================================================ helpers ===

static func metal(tier: int, i: int = 1) -> Color:
	return Color(TIER_METAL[clampi(tier, 1, 7)][i])


static func ecol(element: String, i: int = 1) -> Color:
	return Lore.color(element, i)


static func text(ci: CanvasItem, f: Font, pos: Vector2, s: String, size: int, col: Color,
		align: int = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0, outline: int = 0,
		ocol: Color = Color(0, 0, 0, 0.85)) -> void:
	if size < 1:
		return
	if outline > 0:
		ci.draw_string_outline(f, pos, s, align, width, size, outline, ocol)
	ci.draw_string(f, pos, s, align, width, size, col)


## Draws text vertically centred in `rect`.
static func text_in(ci: CanvasItem, f: Font, rect: Rect2, s: String, size: int, col: Color,
		align: int = HORIZONTAL_ALIGNMENT_CENTER, outline: int = 0, ocol: Color = Color(0, 0, 0, 0.85)) -> void:
	var base := rect.position.y + (rect.size.y + f.get_ascent(size) - f.get_descent(size)) * 0.5
	text(ci, f, Vector2(rect.position.x, base), s, size, col, align, rect.size.x, outline, ocol)


## Largest font size <= size that fits `s` into `width`.
static func fit_size(f: Font, s: String, size: int, width: float, min_size: int = 6) -> int:
	var sz := size
	while sz > min_size and f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width:
		sz -= 1
	return sz


static func box(ci: CanvasItem, r: Rect2, rad: float, col: Color, border: Color = Color(0, 0, 0, 0),
		bw: float = 0.0, shadow: float = 0.0, shadow_col: Color = Color(0, 0, 0, 0.5),
		shadow_off: Vector2 = Vector2(0, 3)) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(round(rad)))
	if bw > 0.0:
		sb.border_color = border
		sb.set_border_width_all(int(ceil(bw)))
	if shadow > 0.0:
		sb.shadow_size = int(shadow)
		sb.shadow_color = shadow_col
		sb.shadow_offset = shadow_off
	sb.anti_aliasing = true
	sb.draw(ci.get_canvas_item(), r)


static func round_rect_points(r: Rect2, rad: float, seg: int = 6) -> PackedVector2Array:
	var pts := PackedVector2Array()
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var corners := [
		[r.position + Vector2(r.size.x - rad, rad), -PI * 0.5, 0.0],
		[r.position + Vector2(r.size.x - rad, r.size.y - rad), 0.0, PI * 0.5],
		[r.position + Vector2(rad, r.size.y - rad), PI * 0.5, PI],
		[r.position + Vector2(rad, rad), PI, PI * 1.5],
	]
	for c in corners:
		for i in seg + 1:
			var a: float = lerpf(c[1], c[2], float(i) / seg)
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return pts


## A rounded rectangle filled with a vertical gradient.
static func vgrad(ci: CanvasItem, r: Rect2, rad: float, top: Color, bottom: Color) -> void:
	var pts := round_rect_points(r, rad)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, clampf((p.y - r.position.y) / r.size.y, 0.0, 1.0)))
	ci.draw_polygon(pts, cols)


## A plain rectangle with a vertical gradient (no rounding, cheap).
static func vgrad_rect(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## Element orb: a coloured gem with the element's glyph.
static func orb(ci: CanvasItem, c: Vector2, r: float, element: String) -> void:
	var light := ecol(element, 0)
	var main := ecol(element, 1)
	var dark := ecol(element, 2)
	ci.draw_circle(c + Vector2(0, maxf(1.0, r * 0.14)), r * 1.02, Color(0, 0, 0, 0.45))
	ci.draw_circle(c, r, dark)
	ci.draw_circle(c, r * 0.86, main)
	ci.draw_circle(c + Vector2(-r * 0.2, -r * 0.24), r * 0.52, Color(light, 0.38))
	Glyphs.draw(ci, element, c, r * 0.56, Color(1, 1, 1, 0.96))
	if Lore.is_divine(element):
		ci.draw_arc(c, r, 0, TAU, maxi(20, int(r * 3)), GOLD, maxf(1.0, r * 0.16), true)
	else:
		ci.draw_arc(c, r, 0, TAU, maxi(20, int(r * 3)), Color(dark.darkened(0.3), 0.9), maxf(1.0, r * 0.1), true)


## Small diamonds showing the tier (1-7).
static func tier_gems(ci: CanvasItem, pos: Vector2, s: float, tier: int, gap: float = 9.0) -> void:
	var col := metal(tier, 0)
	for i in tier:
		var c := pos + Vector2(i * gap * s, 0)
		var d := 3.4 * s
		var pts := PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)])
		ci.draw_colored_polygon(pts, col)
		ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.6), maxf(1.0, 0.8 * s), true)


# ==================================================================== art ===

static func has_art(card_id: String) -> bool:
	return art(card_id) != null


static func art(card_id: String) -> Texture2D:
	if _art.has(card_id):
		return _art[card_id]
	var tex: Texture2D = null
	for ext in ["png", "jpg", "webp"]:
		var p := "res://assets/art/cards/%s.%s" % [card_id, ext]
		if ResourceLoader.exists(p):
			tex = load(p)
			break
	_art[card_id] = tex
	return tex


## Draws `tex` so it fills `r` completely (cropping the edges if needed).
## `focus_y` (0-1) chooses which part of a tall image stays visible.
static func draw_cover(ci: CanvasItem, r: Rect2, tex: Texture2D, focus_y: float = 0.45) -> void:
	var ts := Vector2(tex.get_width(), tex.get_height())
	var k := maxf(r.size.x / ts.x, r.size.y / ts.y)
	var src_size := r.size / k
	var src := Rect2(Vector2((ts.x - src_size.x) * 0.5, (ts.y - src_size.y) * focus_y), src_size)
	ci.draw_texture_rect_region(tex, r, src)


## The illustration, or a painted placeholder in the card's colours.
static func draw_art(ci: CanvasItem, r: Rect2, card_id: String, element: String, focus_y: float = 0.45) -> void:
	var tex := art(card_id)
	if tex != null:
		draw_cover(ci, r, tex, focus_y)
		return
	var light := ecol(element, 0)
	var main := ecol(element, 1)
	var dark := ecol(element, 2)
	vgrad_rect(ci, r, main.lerp(light, 0.25).darkened(0.1), dark.darkened(0.45))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(card_id)
	var scale := r.size.x / W
	# soft light behind the subject
	var ctr := r.get_center() + Vector2(0, -r.size.y * 0.04)
	var glow := minf(r.size.x, r.size.y) * 0.5
	for i in 7:
		ci.draw_circle(ctr, glow * (1.0 - i * 0.12), Color(light, 0.05))
	# drifting motes
	for i in 16:
		var p := r.position + Vector2(rng.randf(), rng.randf()) * r.size
		var rad := (1.0 + rng.randf() * 3.2) * scale
		ci.draw_circle(p, rad, Color(light, 0.18 + rng.randf() * 0.3))
	# big glyph as the "subject"
	var gr := minf(r.size.x, r.size.y) * 0.3
	Glyphs.draw(ci, element, ctr + Vector2(0, 2 * scale), gr, Color(0, 0, 0, 0.25))
	Glyphs.draw(ci, element, ctr, gr, Color(light, 0.75))
	# vignette
	var v := r.size.y * 0.35
	vgrad_rect(ci, Rect2(r.position.x, r.end.y - v, r.size.x, v), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))


# ============================================================== card face ===

## Draws a whole card into `rect` (keeps the 5:7 shape; any size).
## opts: "attuned" (bool, highlight/dim the Attuned line), "compact" (bool).
static func draw_card(ci: CanvasItem, rect: Rect2, card_id: String, opts: Dictionary = {}) -> void:
	var d: Dictionary = SigilDB.CARDS[card_id]
	var compact: bool = opts.get("compact", rect.size.x < COMPACT_BELOW)
	if compact:
		_draw_compact(ci, rect, card_id, d)
		return
	var s := rect.size.x / W
	var o := rect.position
	match d.kind:
		"totem":
			_draw_totem(ci, o, s, card_id, d, opts)
		"summon":
			_draw_summon(ci, o, s, card_id, d, opts)
		"rite", "ally":
			_draw_rite(ci, o, s, card_id, d)
		"energy":
			_draw_energy(ci, o, s, card_id, d)


static func _R(o: Vector2, s: float, x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s)


static func _P(o: Vector2, s: float, x: float, y: float) -> Vector2:
	return o + Vector2(x, y) * s


static func _fs(s: float, n: float) -> int:
	return maxi(1, int(round(n * s)))


## The outer shell: dark card stock with a metal rim in the tier's colour.
static func _shell(ci: CanvasItem, o: Vector2, s: float, tier: int) -> void:
	var full := _R(o, s, 0, 0, W, H)
	box(ci, full, 13 * s, metal(tier, 2))
	vgrad(ci, full.grow(-1.5 * s), 12 * s, metal(tier, 0), metal(tier, 1).darkened(0.25))
	box(ci, _R(o, s, 5, 5, W - 10, H - 10), 9 * s, INK)


## Thin inner rim around a panel.
static func _rim(ci: CanvasItem, r: Rect2, s: float, tier: int, rad: float = 6.0) -> void:
	var pts := round_rect_points(r, rad * s)
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(metal(tier, 0), 0.85), maxf(1.0, 1.2 * s), true)


static func _foil(ci: CanvasItem, r: Rect2, s: float, tier: int) -> void:
	# A faint diagonal sheen on higher tiers.
	if tier < 3:
		return
	var a := clampf(0.04 + (tier - 3) * 0.025, 0.0, 0.16)
	var band := PackedVector2Array([r.position + Vector2(r.size.x * 0.15, 0), r.position + Vector2(r.size.x * 0.45, 0),
		r.position + Vector2(r.size.x * 0.05, r.size.y), r.position + Vector2(-r.size.x * 0.25, r.size.y)])
	var clipped := Geometry2D.intersect_polygons(band, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]))
	for poly in clipped:
		ci.draw_colored_polygon(poly, Color(1, 1, 1, a))


static func _draw_totem(ci: CanvasItem, o: Vector2, s: float, card_id: String, d: Dictionary, opts: Dictionary) -> void:
	var tier := int(d.get("tier", 1))
	var el: String = d.element
	_shell(ci, o, s, tier)

	# --- illustration with the name plate over it
	var art_r := _R(o, s, 9, 9, 232, 198)
	draw_art(ci, art_r, card_id, el)
	_foil(ci, art_r, s, tier)
	vgrad_rect(ci, _R(o, s, 9, 9, 232, 54), Color(0, 0, 0, 0.78), Color(0, 0, 0, 0))
	vgrad_rect(ci, _R(o, s, 9, 175, 232, 32), Color(0, 0, 0, 0), Color(0, 0, 0, 0.72))
	_rim(ci, art_r, s, tier, 5)

	# HP, right-aligned before the element orb; the name gets what's left.
	var hp_s := str(int(d.hp))
	var hpw := font("display_bold").get_string_size(hp_s, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 21)).x
	var hplw := font("bold").get_string_size("HP", HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 9)).x
	text(ci, font("display_bold"), _P(o, s, 150, 34), hp_s, _fs(s, 21), Color("ffe3d6"), HORIZONTAL_ALIGNMENT_RIGHT, 57 * s, _fs(s, 3))
	text(ci, font("bold"), _P(o, s, 150, 33) - Vector2(hpw + 2 * s, 0), "HP", _fs(s, 9), Color("ffb8a0"), HORIZONTAL_ALIGNMENT_RIGHT, 57 * s, _fs(s, 2))
	var name_font := font("display_bold")
	var name_w := (207 - 16) * s - hpw - hplw - 8 * s
	var nsz := fit_size(name_font, d.name, _fs(s, 19), name_w)
	text(ci, name_font, _P(o, s, 16, 33), d.name, nsz, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 3))
	orb(ci, _P(o, s, 225, 26), 13 * s, el)

	var stage := int(d.get("stage", 0))
	var sub := "BASE TOTEM"
	if stage > 0:
		sub = "AWAKENS FROM " + String(SigilDB.CARDS[d.awakens_from].name).to_upper()
	text(ci, font("bold"), _P(o, s, 17, 49), sub, _fs(s, 8), Color(1, 1, 1, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 2))

	# tier + affinity along the bottom of the art
	tier_gems(ci, _P(o, s, 19, 196), s, tier)
	text(ci, font("bold"), _P(o, s, 19 + tier * 9 + 2, 199.5), Lore.TIER_NAMES[tier].to_upper(), _fs(s, 8.5), metal(tier, 0), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 2))
	var aff: String = d.get("affinity", "")
	if aff != "":
		Glyphs.draw(ci, aff, _P(o, s, 229, 195), 7 * s, Color(1, 1, 1, 0.85))
		text(ci, font("bold"), _P(o, s, 140, 199.5), Lore.ATTRIBUTE_NAMES[aff].to_upper(), _fs(s, 8.5), Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, 78 * s, _fs(s, 2))

	# --- attacks
	var panel := _R(o, s, 9, 211, 232, 84)
	box(ci, panel, 6 * s, PANEL)
	ci.draw_line(_P(o, s, 14, 211.5), _P(o, s, 236, 211.5), Color(ecol(el, 1), 0.8), maxf(1.0, 1.5 * s))
	_draw_attacks(ci, o, s, d.get("attacks", []), 211.0, 84.0)

	# --- attuned line
	var att_r := _R(o, s, 9, 298, 232, 19)
	_draw_attuned(ci, att_r, s, d, opts.get("attuned", null))

	# --- footer: weakness and retreat
	var fy := 320.0
	var lab := font("bold")
	var labc := TEXT_DIM
	text(ci, lab, _P(o, s, 16, fy + 13), "WEAK", _fs(s, 8.5), labc)
	var weak: Array = Lore.weak_to(el)
	var wx := 52.0
	for w in weak:
		orb(ci, _P(o, s, wx, fy + 10), 6.5 * s, w)
		wx += 15.0
	if not weak.is_empty():
		text(ci, font("display_bold"), _P(o, s, wx - 5, fy + 14), "×1.5", _fs(s, 10), TEXT)
	text(ci, lab, _P(o, s, 150, fy + 13), "RETREAT", _fs(s, 8.5), labc)
	var rc := int(d.get("retreat", 0))
	if rc == 0:
		text(ci, font("display_bold"), _P(o, s, 196, fy + 14), "Free", _fs(s, 10), TEXT)
	else:
		for i in rc:
			orb(ci, _P(o, s, 200 + i * 13, fy + 10), 5.5 * s, "any")


static func _draw_attacks(ci: CanvasItem, o: Vector2, s: float, atks: Array, top: float, height: float) -> void:
	if atks.is_empty():
		return
	var body := font("body")
	# Work out heights, shrinking the rules text if the attacks don't fit.
	var tsize := 10.0
	var heights := []
	var total := 0.0
	for attempt in 4:
		heights.clear()
		total = 0.0
		for a in atks:
			var h := 22.0
			var t: String = a.get("text", "")
			if t != "":
				h += body.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, 214 * s, _fs(s, tsize)).y / s + 1
			heights.append(h)
			total += h
		if total <= height - 4 or tsize <= 7.5:
			break
		tsize -= 0.75
	var gap := maxf(2.0, (height - total) / (atks.size() + 1))
	var y := top + gap
	for i in atks.size():
		var a: Dictionary = atks[i]
		var cost: Array = a.get("cost", [])
		var cx := 22.0
		for c in cost:
			orb(ci, _P(o, s, cx, y + 10), 7 * s, c)
			cx += 15.5
		var name_x := maxf(cx + 1, 40.0)
		var dmg := ""
		if int(a.get("damage", 0)) > 0:
			dmg = str(a.damage) + a.get("damage_suffix", "")
		var aname_size := fit_size(font("display_bold"), a.name, _fs(s, 13.5), (190 - name_x) * s)
		text(ci, font("display_bold"), _P(o, s, name_x, y + 15), a.name, aname_size, TEXT)
		if dmg != "":
			text(ci, font("display_bold"), _P(o, s, 170, y + 16), dmg, _fs(s, 17), Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 64 * s)
		var t: String = a.get("text", "")
		if t != "":
			ci.draw_multiline_string(body, _P(o, s, 17, y + 29), t, HORIZONTAL_ALIGNMENT_LEFT,
				214 * s, _fs(s, tsize), -1, TEXT_DIM)
		y += heights[i]
		if i < atks.size() - 1:
			ci.draw_line(_P(o, s, 18, y + gap * 0.5), _P(o, s, 232, y + gap * 0.5), Color(1, 1, 1, 0.07), maxf(1.0, s))
		y += gap


## One line describing a card's Attuned bonus, e.g. "Might 5+: +10 damage".
static func attuned_text(d: Dictionary) -> String:
	var a: Dictionary = d.get("attuned", {})
	if a.is_empty():
		return ""
	var parts := []
	if a.has("damage"):
		parts.append("+%d damage" % int(a.damage))
	if a.has("hp"):
		parts.append("+%d HP" % int(a.hp))
	if a.has("retreat"):
		parts.append("retreat costs %d less" % int(a.retreat))
	if a.has("cost"):
		parts.append("costs %d less" % int(a.cost))
	if a.get("immune", false):
		parts.append("immune to conditions")
	if a.has("draw"):
		parts.append("draw %d when played" % int(a.draw))
	return "%s %d+: %s" % [Lore.ATTRIBUTE_NAMES[d.get("affinity", "might")], int(a.get("min", 5)), ", ".join(parts)]


static func _draw_attuned(ci: CanvasItem, r: Rect2, s: float, d: Dictionary, state) -> void:
	var t := attuned_text(d)
	if t == "":
		return
	var active: bool = state == true
	var dim: bool = state == false
	var bg := Color(GOLD, 0.2) if active else Color(1, 1, 1, 0.05)
	box(ci, r, 5 * s, bg, Color(GOLD, 0.8 if active else 0.25), maxf(1.0, s))
	var col := GOLD if not dim else Color(TEXT_DIM, 0.8)
	Glyphs.draw(ci, d.get("affinity", "might"), r.position + Vector2(10, r.size.y * 0.5 / s) * s, 6 * s, col)
	var label := "ATTUNED"
	text(ci, font("bold"), r.position + Vector2(20, 13) * s, label, _fs(s, 8), col)
	var lw := font("bold").get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 8)).x
	var avail := r.size.x - lw - 30 * s
	var sz := fit_size(font("body"), t, _fs(s, 9.5), avail, 6)
	text(ci, font("body"), r.position + Vector2(24 * s + lw, 13 * s), t, sz, TEXT if not dim else TEXT_DIM)


static func _draw_summon(ci: CanvasItem, o: Vector2, s: float, card_id: String, d: Dictionary, opts: Dictionary) -> void:
	var tier := int(d.get("tier", 6))
	var el: String = d.element
	_shell(ci, o, s, tier)
	var art_r := _R(o, s, 9, 9, 232, 332)
	draw_art(ci, art_r, card_id, el, 0.35)
	_foil(ci, art_r, s, tier)
	vgrad_rect(ci, _R(o, s, 9, 9, 232, 62), Color(0, 0, 0, 0.8), Color(0, 0, 0, 0))
	vgrad_rect(ci, _R(o, s, 9, 180, 232, 161), Color(0, 0, 0, 0), Color(0, 0, 0, 0.88))
	_rim(ci, art_r, s, tier, 6)

	box(ci, _R(o, s, 16, 14, 64, 14), 7 * s, Color(metal(tier, 1), 0.9))
	text_in(ci, font("bold"), _R(o, s, 16, 14, 64, 14), "SUMMON", _fs(s, 8), INK)
	tier_gems(ci, _P(o, s, 90, 21), s, tier, 8.0)
	text(ci, font("bold"), _P(o, s, 90 + tier * 8, 24.5), Lore.TIER_NAMES[tier].to_upper(), _fs(s, 8), metal(tier, 0), HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 2))
	orb(ci, _P(o, s, 225, 24), 13 * s, el)
	var nsz := fit_size(font("display_bold"), d.name, _fs(s, 18), 214 * s)
	text(ci, font("display_bold"), _P(o, s, 16, 50), d.name, nsz, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 3))

	# cost + effect
	var cost: Array = d.get("cost", [])
	text(ci, font("bold"), _P(o, s, 17, 244), "CALL", _fs(s, 8.5), TEXT_DIM)
	var cx := 50.0
	for c in cost:
		orb(ci, _P(o, s, cx, 241), 7 * s, c)
		cx += 15.5
	ci.draw_multiline_string(font("body"), _P(o, s, 17, 266), d.get("text", ""), HORIZONTAL_ALIGNMENT_LEFT,
		216 * s, _fs(s, 10.5), -1, TEXT)
	_draw_attuned(ci, _R(o, s, 9, 318, 232, 19), s, d, opts.get("attuned", null))


static func _draw_rite(ci: CanvasItem, o: Vector2, s: float, card_id: String, d: Dictionary) -> void:
	var tier := int(d.get("tier", 1))
	var ally: bool = d.kind == "ally"
	_shell(ci, o, s, tier)
	var accent := Color("d8893a") if ally else Color("5c8fd6")
	var art_el := "radiant" if ally else "mystic"
	var art_r := _R(o, s, 9, 9, 232, 190)
	# Rites/allies have no element; use a warm or cool placeholder.
	var tex := art(card_id)
	if tex != null:
		draw_cover(ci, art_r, tex)
	else:
		vgrad_rect(ci, art_r, accent.lightened(0.15), accent.darkened(0.65))
		Glyphs.draw(ci, "presence" if ally else "intellect", art_r.get_center(), 46 * s, Color(1, 1, 1, 0.35))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(card_id)
		for i in 12:
			ci.draw_circle(art_r.position + Vector2(rng.randf(), rng.randf()) * art_r.size, (1 + rng.randf() * 2.5) * s, Color(1, 1, 1, 0.25))
	vgrad_rect(ci, _R(o, s, 9, 9, 232, 50), Color(0, 0, 0, 0.78), Color(0, 0, 0, 0))
	_rim(ci, art_r, s, tier, 5)
	var nsz := fit_size(font("display_bold"), d.name, _fs(s, 18), 160 * s)
	text(ci, font("display_bold"), _P(o, s, 16, 33), d.name, nsz, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 3))
	box(ci, _R(o, s, 184, 17, 50, 16), 8 * s, accent)
	text_in(ci, font("bold"), _R(o, s, 184, 17, 50, 16), "ALLY" if ally else "RITE", _fs(s, 8.5), Color.WHITE)
	var panel := _R(o, s, 9, 203, 232, 138)
	box(ci, panel, 6 * s, PANEL)
	ci.draw_line(_P(o, s, 14, 203.5), _P(o, s, 236, 203.5), Color(accent, 0.9), maxf(1.0, 1.5 * s))
	ci.draw_multiline_string(font("body"), _P(o, s, 19, 230), d.get("text", ""), HORIZONTAL_ALIGNMENT_LEFT,
		212 * s, _fs(s, 13), -1, TEXT)
	var rule := "You may call only 1 Ally each turn." if ally else "Play as many Rites as you like on your turn."
	ci.draw_multiline_string(font("body"), _P(o, s, 15, 330), rule, HORIZONTAL_ALIGNMENT_CENTER,
		220 * s, _fs(s, 8.5), -1, TEXT_DIM)


static func _draw_energy(ci: CanvasItem, o: Vector2, s: float, _card_id: String, d: Dictionary) -> void:
	var el: String = d.element
	_shell(ci, o, s, 1)
	var r := _R(o, s, 9, 9, 232, 332)
	vgrad_rect(ci, r, ecol(el, 1).darkened(0.1), ecol(el, 2).darkened(0.55))
	var ctr := _P(o, s, 125, 150)
	for i in 8:
		ci.draw_circle(ctr, (110 - i * 12) * s, Color(ecol(el, 0), 0.045))
	orb(ci, ctr, 62 * s, el)
	_rim(ci, r, s, 1, 5)
	text(ci, font("bold"), _P(o, s, 9, 32), "ENERGY", _fs(s, 10), Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 232 * s)
	var ns := fit_size(font("display_bold"), Lore.element_name(el), _fs(s, 26), 200 * s)
	text(ci, font("display_bold"), _P(o, s, 9, 270), Lore.element_name(el), ns, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 232 * s, _fs(s, 4))
	text(ci, font("body"), _P(o, s, 9, 300), "Attach one Energy each turn.", _fs(s, 10), Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_CENTER, 232 * s)


## A simplified face for small sizes (hand, bench): art, name, HP and element.
static func _draw_compact(ci: CanvasItem, rect: Rect2, card_id: String, d: Dictionary) -> void:
	var s := rect.size.x / W
	var o := rect.position
	var tier := int(d.get("tier", 1))
	var el: String = d.get("element", "any")
	_shell(ci, o, s, tier)
	var inner := _R(o, s, 9, 9, 232, 332)
	match d.kind:
		"energy":
			vgrad_rect(ci, inner, ecol(el, 1).darkened(0.1), ecol(el, 2).darkened(0.55))
			orb(ci, _P(o, s, 125, 160), 78 * s, el)
		"rite", "ally":
			var accent := Color("d8893a") if d.kind == "ally" else Color("5c8fd6")
			var tex := art(card_id)
			if tex != null:
				draw_cover(ci, inner, tex)
			else:
				vgrad_rect(ci, inner, accent.lightened(0.15), accent.darkened(0.65))
				Glyphs.draw(ci, "presence" if d.kind == "ally" else "intellect", _P(o, s, 125, 150), 60 * s, Color(1, 1, 1, 0.4))
			box(ci, _R(o, s, 9, 9, 232, 50), 0, Color(accent, 0.95))
			text_in(ci, font("bold"), _R(o, s, 9, 9, 232, 50), "ALLY" if d.kind == "ally" else "RITE", _fs(s, 30), Color.WHITE)
		_:
			draw_art(ci, inner, card_id, el, 0.4)
			orb(ci, _P(o, s, 206, 44), 30 * s, el)
			if d.kind == "totem":
				text(ci, font("display_bold"), _P(o, s, 18, 64), str(int(d.hp)), _fs(s, 50), Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(s, 8))
			else:
				box(ci, _R(o, s, 16, 18, 120, 36), 18 * s, Color(metal(tier, 1), 0.95))
				text_in(ci, font("bold"), _R(o, s, 16, 18, 120, 36), "SUMMON", _fs(s, 22), INK)
			if int(d.get("stage", 0)) > 0:
				box(ci, _R(o, s, 18, 76, 58, 30), 15 * s, Color(0, 0, 0, 0.6), Color(GOLD, 0.8), maxf(1.0, 2 * s))
				text_in(ci, font("bold"), _R(o, s, 18, 76, 58, 30), "AW %d" % int(d.stage), _fs(s, 22), GOLD)
	# name band
	vgrad_rect(ci, _R(o, s, 9, 250, 232, 91), Color(0, 0, 0, 0), Color(0, 0, 0, 0.85))
	var nm: String = d.name if d.kind != "energy" else Lore.element_name(el)
	var nsz := fit_size(font("display_bold"), nm, _fs(s, 34), 220 * s, 4)
	text(ci, font("display_bold"), _P(o, s, 9, 326), nm, nsz, TEXT, HORIZONTAL_ALIGNMENT_CENTER, 232 * s, _fs(s, 6))
	if d.kind == "totem" or d.kind == "summon":
		tier_gems(ci, _P(o, s, 125 - (tier - 1) * 9, 282), s * 1.4, tier, 9.0 / 1.4 * 1.4)
	_rim(ci, inner, s, tier, 5)


# ============================================================== card back ===

static func draw_back(ci: CanvasItem, rect: Rect2) -> void:
	var s := rect.size.x / W
	var o := rect.position
	box(ci, rect, 13 * s, Color("0c0e18"))
	vgrad(ci, _R(o, s, 5, 5, W - 10, H - 10), 9 * s, Color("1d2450"), Color("0a0d22"))
	var inner := _R(o, s, 13, 13, W - 26, H - 26)
	var pts := round_rect_points(inner, 6 * s)
	pts.append(pts[0])
	ci.draw_polyline(pts, Color(GOLD, 0.7), maxf(1.0, 1.5 * s), true)
	# radiating lines
	var c := rect.get_center()
	var poly := PackedVector2Array([inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)])
	for i in 24:
		var a := TAU * i / 24.0
		var seg := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([c + Vector2(cos(a), sin(a)) * 60 * s, c + Vector2(cos(a), sin(a)) * 300 * s]), poly)
		for sg in seg:
			ci.draw_polyline(sg, Color(GOLD, 0.08), maxf(1.0, 1.2 * s))
	ci.draw_circle(c, 64 * s, Color(GOLD, 0.06))
	ci.draw_arc(c, 60 * s, 0, TAU, 64, Color(GOLD, 0.55), maxf(1.0, 2 * s), true)
	ci.draw_arc(c, 52 * s, 0, TAU, 64, Color(GOLD, 0.25), maxf(1.0, 1 * s), true)
	Glyphs.draw(ci, "crown_sigil", c, 40 * s, GOLD)
	if s > 0.4:
		text(ci, font("display_bold"), Vector2(o.x, c.y + 100 * s), "THE COVENANT WAR", _fs(s, 15), GOLD, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)
