class_name DuelStatusMarks
extends RefCounted
## What a Totem carries, shown on it for as long as it lasts (12 November,
## Gary: "every effect shows on the person affected somehow"). Each of the 24
## conditions and 6 boons has a sign of its own on the 3D field, riding with
## the creature: flames at its feet while it's Burned, ice round them while
## it's Frozen, stars round its head while it's Stunned, a Z rising while it
## sleeps, a target over it while it's Marked, an eye half shut and three
## candles while it's Doomed (one goes out at each of its owner's Dawns),
## a bubble while it's Shielded, a halo while it's Blessed, and so on. The
## landing of each is still DuelField3D.status_motif and status_ring; these
## are what stays. Its plate still names them (DuelViews).
##
## DuelField3D builds one mark per effect (build), keeps them on the slot
## while the effect lasts and moves them each frame (tick). Some also tint
## the creature (tint): Petrified to stone, Frozen to ice, Enraged red,
## Possessed violet.

const ICONS := "res://assets/art/fx/status/"
## The ring the Glyph Warden binds with (Silenced by it), else a cold silver.
const SILENCE_GLYPH := Color(0.62, 0.45, 1.0)
const SILENCE_SILVER := Color(0.78, 0.82, 0.92)
## Discs on the ground lie just over the card in the slot (it's at 0.05).
const FLOOR_Y := 0.075
## The ring's colour on the ground where its own (DuelConditions.color) is too
## dark or too pale to read as light: Doomed's is near black, Cursed's deep.
const FLOOR_COL := {"doomed": Color(0.62, 0.25, 0.9), "cursed": Color(0.7, 0.3, 0.95),
	"petrified": Color(0.85, 0.8, 0.7), "staggered": Color(0.85, 0.95, 0.9), "blinded": Color(1.0, 0.95, 0.75),
	"silenced": Color(0.78, 0.82, 0.92), "veiled": Color(0.85, 0.8, 1.0)}
## The sign on a round badge over its head for each effect (tools/
## make_status_icons.py), in a row with the others it carries, so what's on
## it reads at a glance on any floor and from any seat; tapped, it says what
## the effect does (DuelEffectTip). Under it, a dot for each turn it has
## left (12 November, evening: Gary said yes to both). Asleep, Stunned,
## Confused, Charmed, Blessed and Possessed show at its head in their own way
## as well (Zs, stars, ?s, hearts, the halo, the crown).
const BADGES := {"burn": "flame", "poison": "venom", "corroded": "drips", "bleed": "claws",
	"frozen": "flake", "shocked": "bolt", "soaked": "drop", "rooted": "sprout", "petrified": "rock",
	"staggered": "swirl", "blinded": "eye_shut", "terrified": "bang", "enraged": "vein",
	"hexed": "hex", "cursed": "skull", "marked": "target", "drained": "down", "doomed": "eye",
	"shielded": "shield", "empowered": "up", "regenerating": "plus", "veiled": "mist", "hastened": "fast",
	"silenced": "hush", "sleep": "zed", "stun": "star", "confused": "question", "charmed": "heart",
	"blessed": "halo", "possessed": "strings"}
## Signs drawn bigger than the rest, made smaller on the badge.
const SIGN_K := {"heart": 0.8, "zed": 0.86, "question": 0.92}
## How big a badge is, how far apart they sit in the row (m).
const BADGE := 0.46
const BADGE_GAP := 0.52
## The glow behind a badge you can cure (12 November, night): gold.
const CURE_GOLD := Color(1.0, 0.8, 0.3)
## A turn-left dot: its size, how far apart, how far under the badge's middle.
const PIP := 0.11
const PIP_GAP := 0.13
const PIP_Y := 0.31
## The ones whose own signs rise over its head: the row of badges sits higher.
const RISERS := ["sleep", "charmed", "stun", "confused", "blessed", "possessed"]

static var _icon_cache := {}


## Every effect a Totem has now: its conditions, its boons, and Shielded
## while its shield holds.
static func effects_of(t) -> Array:
	var out: Array = t.conditions().duplicate()
	for b in t.boons:
		if not out.has(b):
			out.append(b)
	if t.shield > 0 and not out.has("shielded"):
		out.append("shielded")
	out.sort()
	return out


## The creature's own colours drawn towards one effect's, and how far
## (0 = untouched): the first of these it has.
static func tint(effects: Array, t: float) -> Array:
	if effects.has("petrified"):
		return [Color(0.52, 0.52, 0.54), 0.9]
	if effects.has("frozen"):
		return [Color(0.72, 0.9, 1.0), 0.5]
	if effects.has("enraged"):
		return [Color(1.0, 0.42, 0.3), 0.22 + 0.1 * sin(t * 5.0)]
	if effects.has("possessed"):
		return [Color(0.62, 0.48, 1.0), 0.28]
	return [Color.WHITE, 0.0]


## One effect's mark, `h` the creature's height (m). Its parts are children;
## anything tick moves is named.
static func build(f: DuelField3D, id: String, h: float, info: Dictionary = {}) -> Node3D:
	var m := Node3D.new()
	m.name = "mark_" + id
	m.set_meta("id", id)
	var col := DuelConditions.color(id)
	match id:
		# ------------------------------------------------------- Body ---
		"burn":
			_flat(m, _tex_named("glow"), 2.0, Color(1.0, 0.45, 0.12, 0.7), FLOOR_Y, "embers")
			_stream(f, m, Vector3(0, 0.1, 0), {"amount": 20, "life": 0.75, "shape": "ring", "radius": 0.45,
				"speed": [0.8, 1.7], "dir": Vector3.UP, "spread": 12.0, "gravity": Vector3(0, 0.6, 0),
				"tex": "glow", "size": 0.5, "scale": [0.6, 1.2], "grow": "swell",
				"cols": [Color(1.0, 0.85, 0.4), Color(1.0, 0.45, 0.12), Color(0.8, 0.15, 0.05)]})
			_stream(f, m, Vector3(0, h * 0.3, 0), {"amount": 7, "life": 1.6, "shape": "sphere", "radius": 0.4,
				"speed": [0.4, 0.9], "dir": Vector3.UP, "spread": 25.0, "gravity": Vector3(0, 0.3, 0),
				"tex": "dot", "size": 0.06, "cols": [Color(1.0, 0.7, 0.3), Color(1.0, 0.35, 0.1)]})
		"poison":
			_stream(f, m, Vector3(0, h * 0.35, 0), {"amount": 10, "life": 1.7, "shape": "sphere", "radius": 0.45,
				"speed": [0.15, 0.45], "dir": Vector3.UP, "spread": 30.0, "gravity": Vector3(0, 0.25, 0),
				"tex": "ring", "size": 0.24, "scale": [0.5, 1.0], "grow": "grow",
				"cols": [Color(0.8, 1.0, 0.5), Color(0.45, 0.95, 0.25)]})
			_stream(f, m, Vector3(0, 0.15, 0), {"amount": 5, "life": 2.2, "shape": "ring", "radius": 0.5,
				"speed": [0.05, 0.2], "dir": Vector3.UP, "spread": 40.0, "gravity": Vector3.ZERO,
				"tex": "glow", "size": 1.2, "grow": "swell", "cols": [Color(0.5, 0.95, 0.3, 0.45)]})
		"corroded":
			_stream(f, m, Vector3(0, h * 0.6, 0), {"amount": 10, "life": 1.0, "shape": "sphere", "radius": 0.42,
				"speed": [0.05, 0.3], "dir": Vector3.DOWN, "spread": 30.0, "gravity": Vector3(0, -1.6, 0),
				"tex": "shard", "size": 0.24, "mode": "spin", "bright": 2.4, "cols": [Color(0.92, 1.0, 0.45), Color(0.6, 0.7, 0.2)]})
			_flat(m, _tex_named("glow"), 2.4, Color(0.62, 0.72, 0.12, 0.55), FLOOR_Y, "acid", "mix")
		"bleed":
			# (blood off, 24 October: motes of crimson light, not drops)
			_stream(f, m, Vector3(0, h * 0.55, 0), {"amount": 8, "life": 0.9, "shape": "sphere", "radius": 0.35,
				"speed": [0.05, 0.2], "dir": Vector3.DOWN, "spread": 20.0, "gravity": Vector3(0, -1.8, 0),
				"tex": "dot", "size": 0.18, "bright": 2.4, "cols": [Color(1.0, 0.5, 0.5), Color(0.8, 0.15, 0.25)]})
			_band(m, Color(1.0, 0.25, 0.3), maxf(0.6, h * 0.28), 0.12, "wound", 0.05)
		"frozen":
			_spikes(m, Color(0.75, 0.92, 1.0), 9, 0.6, 0.4, 0.95, 0.12, 0.8, 0.35)
			_flat(m, _tex_named("glow"), 2.4, Color(0.7, 0.9, 1.0, 0.6), FLOOR_Y, "frost")
			_stream(f, m, Vector3(0, h * 0.8, 0), {"amount": 9, "life": 1.8, "shape": "sphere", "radius": 0.5,
				"speed": [0.05, 0.2], "dir": Vector3.DOWN, "spread": 40.0, "gravity": Vector3(0, -0.45, 0),
				"tex": "star", "size": 0.1, "mode": "spin", "cols": [Color(1, 1, 1), Color(0.7, 0.9, 1.0)]})
		"shocked":
			_stream(f, m, Vector3(0, h * 0.5, 0), {"amount": 7, "life": 0.22, "shape": "sphere", "radius": 0.5,
				"speed": [1.0, 2.6], "dir": Vector3.UP, "spread": 180.0, "gravity": Vector3.ZERO,
				"tex": "shard", "size": 0.45, "mode": "streak", "bright": 2.6, "cols": [Color(1, 1, 0.85), Color(1.0, 0.9, 0.3)]})
			_band(m, Color(1.0, 0.92, 0.35), maxf(0.55, h * 0.26), h * 0.5, "arc", 0.04)
			var zap := DuelStrikeFX.glow(m, Color(1.0, 0.95, 0.5, 0.0), 1.4, 1.4)
			zap.name = "zap"
		"soaked":
			_stream(f, m, Vector3(0, h * 0.85, 0), {"amount": 10, "life": 0.5, "shape": "sphere", "radius": 0.42,
				"speed": [0.2, 0.5], "dir": Vector3.DOWN, "spread": 10.0, "gravity": Vector3(0, -6.0, 0),
				"tex": "dot", "quad": Vector2(0.08, 0.3), "mode": "streak", "bright": 2.4, "cols": [Color(0.75, 0.9, 1.0), Color(0.4, 0.65, 1.0)]})
			_flat(m, _tex_named("glow"), 2.4, Color(0.25, 0.45, 0.95, 0.5), FLOOR_Y, "puddle", "mix")
		"rooted":
			_spikes(m, Color(0.36, 0.55, 0.22), 9, 0.55, 0.5, 0.95, 0.09, 0.25, -0.5)
			_stream(f, m, Vector3(0, 0.2, 0), {"amount": 4, "life": 1.6, "shape": "ring", "radius": 0.5,
				"speed": [0.1, 0.3], "dir": Vector3.UP, "spread": 30.0, "gravity": Vector3(0, -0.2, 0),
				"tex": "leaf", "size": 0.18, "mode": "spin", "blend": "mix", "cols": [Color(0.5, 0.8, 0.35)]})
		"petrified":
			_stream(f, m, Vector3(0, h * 0.6, 0), {"amount": 5, "life": 1.2, "shape": "sphere", "radius": 0.4,
				"speed": [0.0, 0.1], "dir": Vector3.DOWN, "spread": 20.0, "gravity": Vector3(0, -1.2, 0),
				"tex": "dot", "size": 0.05, "blend": "mix", "cols": [Color(0.75, 0.7, 0.62)]})
		"staggered":
			var r := DuelStrikeFX.ring_mesh(Color(0.85, 0.95, 0.9), 0.55, 0.025)
			r.name = "wobble"
			m.add_child(r)
		"blinded":
			var band := DuelStrikeFX.ring_mesh(Color(1.0, 0.97, 0.8), maxf(0.6, h * 0.28), 0.09)
			band.name = "band"
			m.add_child(band)
			var haze := DuelStrikeFX.glow(m, Color(1.0, 0.97, 0.8, 0.5), 1.6, 1.2)
			haze.name = "haze"
		# ------------------------------------------------------- Mind ---
		"sleep":
			for i in 3:
				var z := _icon(m, "zed", col, 0.36)
				z.name = "z%d" % i
		"stun":
			for i in 4:
				var st := DuelStrikeFX.glow(m, Color(1.0, 0.86, 0.3), 0.32, 1.6, "star")
				st.name = "star%d" % i
		"confused":
			for i in 3:
				var q := _icon(m, "question", col, 0.4)
				q.name = "q%d" % i
		"charmed":
			for i in 2:
				var hh := _icon(m, "heart", col, 0.38)
				hh.name = "heart%d" % i
		"terrified":
			_stream(f, m, Vector3(0, h * 0.7, 0), {"amount": 8, "life": 1.3, "shape": "sphere", "radius": 0.45,
				"speed": [0.05, 0.25], "dir": Vector3.DOWN, "spread": 30.0, "gravity": Vector3(0, -0.5, 0),
				"tex": "glow", "size": 0.55, "grow": "swell", "cols": [Color(0.6, 0.5, 1.0, 0.8), Color(0.35, 0.25, 0.65, 0.5)]})
		"enraged":
			_stream(f, m, Vector3(0, 0.1, 0), {"amount": 18, "life": 0.8, "shape": "ring", "radius": 0.6,
				"speed": [1.0, 2.2], "dir": Vector3.UP, "spread": 8.0, "gravity": Vector3(0, 0.8, 0),
				"tex": "glow", "size": 0.5, "grow": "swell", "cols": [Color(1.0, 0.55, 0.3), Color(1.0, 0.2, 0.1)]})
			_flat(m, _tex_named("glow"), 2.6, Color(0.85, 0.12, 0.06, 0.5), FLOOR_Y, "rage", "mix")
		"silenced":
			# the Glyph Warden's own ring when it bound it, round its feet and,
			# smaller, round its head: a seal on its voice
			var by := String(info.get("silence_by", ""))
			var sc := SILENCE_GLYPH if by == "glyph_warden" else SILENCE_SILVER
			# (as bright as the ring that leapt there, so it's plainly the same ring)
			var lit := Color(sc.r * 1.9, sc.g * 1.9, sc.b * 1.9, 1.0)
			_flat(m, load("res://assets/art/fx/glyph_ring.png"), 2.6, lit, FLOOR_Y, "seal_floor")
			_flat(m, load("res://assets/art/fx/glyph_ring.png"), maxf(1.7, h * 0.8), lit, h * 0.85, "seal_head")
		# ------------------------------------------------------- Soul ---
		"possessed":
			_stream(f, m, Vector3(0, h * 0.4, 0), {"amount": 12, "life": 1.4, "shape": "sphere", "radius": 0.45,
				"speed": [0.4, 0.9], "dir": Vector3.UP, "spread": 20.0, "gravity": Vector3(0, 0.4, 0),
				"tex": "glow", "size": 0.5, "grow": "swell", "cols": [Color(0.6, 0.45, 1.0, 0.9), Color(0.35, 0.18, 0.7, 0.5)]})
			var cr := DuelStrikeFX.ring_mesh(Color(0.5, 0.36, 1.0), 0.42, 0.03)
			cr.name = "crown"
			m.add_child(cr)
		"hexed":
			pass   # (its crooked sigil on its badge)
		"cursed":
			_stream(f, m, Vector3(0, h * 0.5, 0), {"amount": 9, "life": 1.3, "shape": "sphere", "radius": 0.4,
				"speed": [0.05, 0.2], "dir": Vector3.DOWN, "spread": 30.0, "gravity": Vector3(0, -0.9, 0),
				"tex": "dot", "size": 0.14, "cols": [Color(0.7, 0.4, 0.95), Color(0.4, 0.15, 0.6)]})
			_flat(m, _tex_named("glow"), 2.6, Color(0.28, 0.06, 0.4, 0.6), FLOOR_Y, "stain", "mix")
		"marked":
			pass   # (the target on its badge)
		"drained":
			_stream(f, m, Vector3(0, h * 0.5, 0), {"amount": 12, "life": 1.1, "shape": "sphere", "radius": 0.4,
				"speed": [0.8, 1.6], "dir": Vector3.UP, "spread": 25.0, "gravity": Vector3(0, 1.0, 0),
				"tangent": [0.5, 1.2], "tex": "star", "size": 0.24, "mode": "spin", "bright": 2.4, "cols": [Color(0.6, 1.0, 0.95), Color(0.3, 0.82, 0.77)]})
			_band(m, Color(0.4, 1.0, 0.9), maxf(0.55, h * 0.26), h * 0.55, "drain", 0.04)
		"doomed":
			# (the eye on its badge; its three candles burning down round its feet)
			for i in 3:
				var fl := DuelStrikeFX.glow(m, Color(1.0, 0.62, 0.25), 0.22, 1.7)
				fl.name = "candle%d" % i
		# ------------------------------------------------------- Boons ---
		"shielded":
			var bub := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 1.0
			sm.height = 2.0
			sm.radial_segments = 24
			sm.rings = 12
			bub.mesh = sm
			var bm := StandardMaterial3D.new()
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			bm.cull_mode = BaseMaterial3D.CULL_BACK
			bm.albedo_color = Color(0.45, 0.8, 1.0, 0.16)
			bub.material_override = bm
			bub.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			bub.name = "bubble"
			m.add_child(bub)
		"empowered":
			_stream(f, m, Vector3(0, h * 0.2, 0), {"amount": 10, "life": 1.2, "shape": "sphere", "radius": 0.45,
				"speed": [0.6, 1.2], "dir": Vector3.UP, "spread": 15.0, "gravity": Vector3(0, 0.6, 0),
				"tex": "star", "size": 0.16, "mode": "spin", "cols": [Color(1.0, 0.85, 0.45), Color(1.0, 0.55, 0.15)]})
			var core := DuelStrikeFX.glow(m, Color(1.0, 0.7, 0.3, 0.6), 1.9, 1.5)
			_band(m, Color(1.0, 0.75, 0.3), maxf(0.65, h * 0.3), 0.12, "power", 0.05)
			core.name = "core"
		"regenerating":
			_stream(f, m, Vector3(0, 0.3, 0), {"amount": 9, "life": 1.6, "shape": "ring", "radius": 0.55,
				"speed": [0.4, 0.8], "dir": Vector3.UP, "spread": 10.0, "gravity": Vector3.ZERO,
				"tex": "star", "size": 0.2, "mode": "spin", "cols": [Color(0.75, 1.0, 0.75), Color(0.4, 0.9, 0.5)]})
			_flat(m, _tex_named("rune"), 2.6, Color(0.45, 0.95, 0.55, 0.9), FLOOR_Y, "rune")
		"veiled":
			_stream(f, m, Vector3(0, h * 0.4, 0), {"amount": 8, "life": 2.0, "shape": "sphere", "radius": 0.55,
				"speed": [0.05, 0.2], "dir": Vector3.UP, "spread": 40.0, "gravity": Vector3.ZERO,
				"tex": "glow", "size": 1.3, "grow": "swell", "blend": "mix", "cols": [Color(0.82, 0.78, 0.98, 0.35)]})
		"blessed":
			var halo := DuelStrikeFX.ring_mesh(Color(1.0, 0.92, 0.6), 0.38, 0.05)
			halo.name = "halo"
			m.add_child(halo)
			var hg := DuelStrikeFX.glow(m, Color(1.0, 0.92, 0.6, 0.35), 0.9, 1.0)
			hg.name = "halo_glow"
		"hastened":
			_stream(f, m, Vector3(0, 0.25, 0), {"amount": 12, "life": 0.6, "shape": "ring", "radius": 0.65,
				"speed": [0.2, 0.4], "dir": Vector3.UP, "spread": 5.0, "gravity": Vector3.ZERO,
				"tangent": [5.0, 7.0], "tex": "shard", "quad": Vector2(0.09, 0.5), "mode": "streak",
				"cols": [Color(0.75, 1.0, 0.98), Color(0.4, 0.95, 0.9)]})
			_flat(m, _tex_named("ring"), 2.3, Color(0.5, 1.0, 0.95, 0.7), FLOOR_Y, "wind")
		_:
			# anything new without a sign of its own yet: its ring on the ground (below)
			pass
	# (every effect, besides its own sign: a ring of its colour on the ground
	# round its feet, so what it carries reads at a glance on any floor; the
	# Silence's and Hastened's own rings, and Regenerating's runes, stand for it)
	var rc := FLOOR_COL.get(id, col) as Color
	if id == "silenced" and String(info.get("silence_by", "")) == "glyph_warden":
		rc = SILENCE_GLYPH
	if not ["silenced", "hastened", "regenerating"].has(id):
		_flat(m, _tex_named("ring"), 2.35, Color(rc, 0.85), FLOOR_Y + 0.004, "floor")
	if BADGES.has(id):
		_badge(m, String(BADGES[id]), rc, pip_total(id))
	m.set_meta("born", f._t)
	return m


## Moves a mark: `t` the field's clock, `h` the creature's height, `i` its
## place among the slot's marks (so two over the head don't sit together),
## info: doom_left (Doomed: its candles), shield_k (0-1, Shielded's strength).
static func tick(m: Node3D, t: float, h: float, i: int, info: Dictionary) -> void:
	var head := h + 0.25 + i * 0.12
	var bd := m.get_node_or_null("badge") as Node3D
	if bd != null:
		# its place in the row over the head, the row turned to face the camera
		var row: Array = info.get("badges", [])
		var j := row.find(m.get_meta("id"))
		var n := row.size()
		var right: Vector3 = info.get("right", Vector3.RIGHT)
		var per := mini(n, 4)
		var x := (j % 4 - (mini(n - (j / 4) * 4, per) - 1) * 0.5) * BADGE_GAP
		var y := float(info.get("row_y", h + 0.6)) + (j / 4) * BADGE_GAP + 0.035 * sin(t * 2.2 + j * 1.3)
		bd.position = right * x + Vector3(0, y, 0)
		# (it pops in when the effect lands)
		var u := clampf((t - float(m.get_meta("born", t))) / 0.35, 0.0, 1.0)
		var pop := 1.0 + 2.7 * pow(u - 1.0, 3) + 1.7 * pow(u - 1.0, 2) if u < 1.0 else 1.0
		bd.scale = Vector3.ONE * maxf(0.01, pop)
		# gold behind it if you can cure it: steady while you only hold the cure,
		# breathing bright when you can use it now
		var cg := bd.get_node_or_null("cure") as MeshInstance3D
		if cg != null:
			var lvl := int((info.get("cure", {}) as Dictionary).get(m.get_meta("id"), 0))
			cg.visible = lvl > 0
			if lvl > 0:
				var now := lvl >= 2
				var a := (0.75 + 0.25 * sin(t * 4.0)) if now else 0.42
				(cg.material_override as StandardMaterial3D).albedo_color = Color(CURE_GOLD * (1.6 if now else 1.0), a)
				var gk := (1.0 + 0.07 * sin(t * 4.0)) if now else 0.94
				cg.scale = Vector3(gk, gk, gk)
		# its turns left: the dots under it, lit for each left, spent ones faint
		var total := pip_total(String(m.get_meta("id")))
		if total > 0:
			var lit := int((info.get("left", {}) as Dictionary).get(m.get_meta("id"), total))
			for k in total:
				var pp := bd.get_node_or_null("pip%d" % k) as MeshInstance3D
				if pp == null:
					continue
				pp.position = right * ((k - (total - 1) * 0.5) * PIP_GAP) + Vector3(0, -PIP_Y, 0)
				(pp.material_override as StandardMaterial3D).albedo_color.a = 1.0 if k < lit else 0.2
	var fr := m.get_node_or_null("floor") as MeshInstance3D
	if fr != null:
		var k := 1.0 + i * 0.13
		fr.scale = Vector3(k, k, k)
		fr.rotation_degrees = Vector3(-90, 0, t * (12.0 if i % 2 == 0 else -12.0))
		(fr.material_override as StandardMaterial3D).albedo_color.a = 0.7 + 0.2 * sin(t * 2.0 + i * 1.7)
	match String(m.get_meta("id")):
		"staggered":
			var w := m.get_node("wobble") as Node3D
			w.position.y = h * 0.62
			w.rotation = Vector3(0.45 * sin(t * 3.1), t * 1.4, 0.45 * cos(t * 2.3))
		"blinded":
			var band := m.get_node("band") as Node3D
			band.position.y = h * 0.86
			band.rotation = Vector3(0.12 * sin(t * 1.3), t * 0.8, 0)
			var haze := m.get_node("haze") as MeshInstance3D
			haze.position.y = h * 0.88
			(haze.material_override as StandardMaterial3D).albedo_color.a = 0.4 + 0.15 * sin(t * 2.5)
		"sleep":
			for k in 3:
				var z := m.get_node("z%d" % k) as MeshInstance3D
				var u := fposmod(t * 0.45 + k / 3.0, 1.0)
				z.position = Vector3(0.18 + u * 0.35, head - 0.1 + u * 0.7, 0)
				z.scale = Vector3.ONE * (0.6 + u * 0.7)
				(z.material_override as StandardMaterial3D).albedo_color.a = sin(u * PI)
		"stun":
			for k in 4:
				var st := m.get_node("star%d" % k) as Node3D
				var a := t * 3.2 + k * TAU / 4.0
				st.position = Vector3(cos(a) * 0.45, head - 0.05 + 0.06 * sin(a * 2.0), sin(a) * 0.45)
		"confused":
			for k in 3:
				var q := m.get_node("q%d" % k) as Node3D
				var a := t * 1.6 + k * TAU / 3.0
				q.position = Vector3(cos(a) * 0.5, head + 0.08 * sin(t * 3.0 + k), sin(a) * 0.5)
		"charmed":
			for k in 2:
				var hh := m.get_node("heart%d" % k) as MeshInstance3D
				var u := fposmod(t * 0.4 + k * 0.5, 1.0)
				hh.position = Vector3((-0.25 if k == 0 else 0.25) + 0.08 * sin(t * 2.0 + k), head - 0.15 + u * 0.6, 0)
				(hh.material_override as StandardMaterial3D).albedo_color.a = sin(u * PI)
		"silenced":
			var sf := m.get_node("seal_floor") as Node3D
			sf.rotation_degrees = Vector3(-90, 0, -t * 18.0)
			var sh := m.get_node("seal_head") as MeshInstance3D
			sh.position.y = h * 0.85
			sh.rotation_degrees = Vector3(-90, 0, t * 40.0)
			(sh.material_override as StandardMaterial3D).albedo_color.a = 0.7 + 0.2 * sin(t * 2.2)
		"possessed":
			var cr := m.get_node("crown") as Node3D
			cr.position.y = head - 0.05
			cr.rotation = Vector3(0.2, t * 2.0, 0)
		"marked":
			# (its target throbbing on its badge)
			var k2 := 1.0 + 0.1 * sin(t * 4.0)
			(m.get_node("badge/sign") as Node3D).scale = Vector3(k2, k2, k2)
		"doomed":
			var left := int(info.get("doom_left", 3))
			for k in 3:
				var fl := m.get_node("candle%d" % k) as MeshInstance3D
				var a := PI * 0.5 + (k - 1) * 0.55
				fl.position = Vector3(cos(a) * 0.7, 0.14 + 0.02 * sin(t * 9.0 + k * 2.0), sin(a) * 0.7)
				fl.visible = k < left
				fl.scale = Vector3.ONE * (0.9 + 0.15 * sin(t * 11.0 + k * 1.7))
		"shielded":
			var bub := m.get_node("bubble") as MeshInstance3D
			var rad := maxf(0.75, h * 0.55)
			bub.position.y = h * 0.48
			bub.scale = Vector3(rad, h * 0.62, rad)
			var sk := clampf(float(info.get("shield_k", 1.0)), 0.25, 1.0)
			(bub.material_override as StandardMaterial3D).albedo_color.a = (0.1 + 0.05 * sin(t * 2.4)) * (0.6 + 0.4 * sk)
		"empowered":
			var core := m.get_node("core") as MeshInstance3D
			core.position.y = h * 0.5
			(core.material_override as StandardMaterial3D).albedo_color.a = 0.3 + 0.2 * sin(t * 3.0)
		"regenerating":
			(m.get_node("rune") as Node3D).rotation_degrees = Vector3(-90, 0, t * 15.0)
		"blessed":
			var halo := m.get_node("halo") as Node3D
			halo.position.y = head + 0.05 + 0.04 * sin(t * 1.8)
			halo.rotation = Vector3(0.12, t * 0.6, 0)
			(m.get_node("halo_glow") as Node3D).position.y = halo.position.y
		"soaked":
			(m.get_node("puddle") as MeshInstance3D).scale = Vector3.ONE * (1.0 + 0.04 * sin(t * 2.0))
		"shocked":
			var zap := m.get_node("zap") as MeshInstance3D
			zap.position.y = h * 0.5
			# (a flicker now and then, like a spark jumping)
			var fl := maxf(0.0, sin(t * 23.0) * sin(t * 7.3) - 0.55) * 2.2
			(zap.material_override as StandardMaterial3D).albedo_color.a = fl
			var arc := m.get_node("arc") as MeshInstance3D
			arc.visible = fl > 0.05 or fposmod(t * 3.0, 1.0) < 0.15
			arc.rotation = Vector3(0.6 * sin(t * 13.0), t * 9.0, 0.6 * cos(t * 11.0))
		"hastened":
			(m.get_node("wind") as Node3D).rotation_degrees = Vector3(-90, 0, t * 140.0)
		"bleed":
			var wd := m.get_node("wound") as MeshInstance3D
			(wd.material_override as StandardMaterial3D).albedo_color.a = 0.6 + 0.35 * sin(t * 4.0)
		"drained":
			var dr := m.get_node("drain") as Node3D
			dr.position.y = h * 0.55 + 0.15 * sin(t * 2.0)
			dr.rotation = Vector3(0.25 * sin(t), t, 0)
		"enraged":
			var rg := m.get_node("rage") as MeshInstance3D
			(rg.material_override as StandardMaterial3D).albedo_color.a = 0.38 + 0.15 * sin(t * 5.0)
		"plain":
			pass


# ------------------------------------------------------------- the parts ---

## A stream of particles that rides with the mark (never ends while it stands).
static func _stream(f: DuelField3D, m: Node3D, at: Vector3, o: Dictionary) -> CPUParticles3D:
	var oo := o.duplicate()
	oo["parent"] = m
	oo["local"] = true
	oo["emit_for"] = 999.0
	oo["explode"] = 0.0
	# (bright enough to read on the lit floors as well as the dark: additive
	# light on a gold floor all but vanished at 1)
	if not oo.has("bright") and String(oo.get("blend", "add")) == "add":
		oo["bright"] = 1.9
	oo["amount"] = int(round(float(oo.get("amount", 10)) * 1.5))
	var p := DuelStrikeFX.emit(f, at, oo)
	p.preprocess = float(o.get("life", 1.0))
	return p


## A flat disc of a texture lying on the ground (or, at `y`, in the air).
static func _flat(m: Node3D, tex: Texture2D, size: float, col: Color, y: float, nm: String, blend := "add") -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	q.mesh = qm
	q.rotation_degrees.x = -90
	q.position.y = y
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = col
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# (a colour laid over the ground, "mix", shows on a lit floor as on a dark one)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if blend == "add" else BaseMaterial3D.BLEND_MODE_MIX
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.name = nm
	m.add_child(q)
	return q


## A sign facing the camera (status/<name>.png), drawn over what's behind it.
static func _icon(m: Node3D, name: String, col: Color, size: float) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(size, size)
	q.mesh = qm
	var mat := StandardMaterial3D.new()
	if not _icon_cache.has(name):
		_icon_cache[name] = load(ICONS + name + ".png")
	mat.albedo_texture = _icon_cache[name]
	mat.albedo_color = Color(col.r * 1.3, col.g * 1.3, col.b * 1.3, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.no_depth_test = true
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.add_child(q)
	return q


## A badge: the effect's sign, lit, on a dark disc in a rim of its colour, a
## little over its head (tick places it in the row). Drawn over everything
## (it's a sign, not a thing in the scene).
static func _badge(m: Node3D, sign: String, col: Color, pips := 0) -> Node3D:
	var bd := Node3D.new()
	bd.name = "badge"
	m.add_child(bd)
	# (a gold glow behind it while you hold a way to cure it: hidden till then)
	var cg := _icon(bd, "cure_glow", CURE_GOLD, BADGE * 1.75)
	cg.name = "cure"
	(cg.material_override as StandardMaterial3D).render_priority = 9
	cg.visible = false
	var back := _icon(bd, "badge", col, BADGE)
	back.name = "back"
	var bm := back.material_override as StandardMaterial3D
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	bm.albedo_color = Color(col, 0.95)
	bm.render_priority = 10
	var sg := _icon(bd, sign, col.lerp(Color.WHITE, 0.35), BADGE * 0.74 * float(SIGN_K.get(sign, 1.0)))
	sg.name = "sign"
	(sg.material_override as StandardMaterial3D).render_priority = 11
	for k in pips:
		var pp := _icon(bd, "pip", col.lerp(Color.WHITE, 0.3), PIP)
		pp.name = "pip%d" % k
		(pp.material_override as StandardMaterial3D).render_priority = 12
	return bd


## How many dots its badge has: the turns it lasts (Doomed: its three
## Dawns); none for one that lasts until cured, broken free or used up.
static func pip_total(id: String) -> int:
	if id == "doomed":
		return 3
	return DuelConditions.turns(id)


## A ring of light round it at height y (a torus), named for tick.
static func _band(m: Node3D, col: Color, r: float, y: float, nm: String, thick := 0.05) -> MeshInstance3D:
	var b := DuelStrikeFX.ring_mesh(col, r, thick)
	b.position.y = y
	b.name = nm
	m.add_child(b)
	return b


static func _tex_named(n: String) -> Texture2D:
	return DuelStrikeFX.tex(n)


## Spikes round its feet (ice, roots): n of them on a ring of radius r,
## heights h0 to h1, width w, leaning out by lean (radians; inwards when
## negative), glowing by glow.
static func _spikes(m: Node3D, col: Color, n: int, r: float, h0: float, h1: float, w: float, glow: float, lean: float) -> void:
	var mat := DuelStrikeFX.solid_mat(col, 0.35 if glow > 0.0 else 0.85, 0.0, glow)
	for k in n:
		var a := TAU * k / n + 0.4 * sin(k * 2.3)
		var sp := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var hh := lerpf(h0, h1, 0.5 + 0.5 * sin(k * 1.9))
		cm.top_radius = 0.0
		cm.bottom_radius = w
		cm.height = hh
		cm.radial_segments = 5
		cm.rings = 1
		sp.mesh = cm
		sp.material_override = mat
		var dir := Vector3(cos(a), 0, sin(a))
		sp.position = dir * r + Vector3(0, hh * 0.45, 0)
		# lean out (or in) along the ring's radius
		sp.basis = Basis(dir.cross(Vector3.UP).normalized(), -lean)
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(sp)
