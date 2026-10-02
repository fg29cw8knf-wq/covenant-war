class_name DuelFX
extends RefCounted
## Light and particle effects for the duel: soft glows, sparks, shockwaves,
## projectiles, lightning, slashes and the big damage numbers. Everything is
## drawn with additive blending so it reads as light on the dark arena, and
## works on the web / phone renderer (no post-processing needed).

static var _glow: Texture2D = null
static var _dot: Texture2D = null
static var _add: CanvasItemMaterial = null


## A soft white radial glow (white centre fading to nothing).
static func glow_tex() -> Texture2D:
	if _glow == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.12), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 128
		t.height = 128
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_glow = t
	return _glow


## A small hard-centred dot for particles.
static func dot_tex() -> Texture2D:
	if _dot == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 32
		t.height = 32
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_dot = t
	return _dot


static func additive() -> CanvasItemMaterial:
	if _add == null:
		_add = CanvasItemMaterial.new()
		_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add


## The bright colour used for an element's light.
static func light(el: String) -> Color:
	match el:
		"fire": return Color(1.0, 0.55, 0.2)
		"storm": return Color(1.0, 0.9, 0.35)
		"tide": return Color(0.35, 0.75, 1.0)
		"verdant": return Color(0.5, 1.0, 0.45)
		"earth": return Color(1.0, 0.75, 0.4)
		"metal": return Color(0.8, 0.9, 1.0)
		"psychic": return Color(1.0, 0.5, 0.9)
		"venom": return Color(0.7, 1.0, 0.3)
		"spirit": return Color(0.5, 1.0, 0.95)
		"mystic": return Color(0.7, 0.55, 1.0)
	return Color(1.0, 0.85, 0.55)


## Draws a soft glow (normal blending) centred on `c` - for use inside _draw.
static func draw_glow(ci: CanvasItem, c: Vector2, rad: Vector2, col: Color) -> void:
	ci.draw_texture_rect(glow_tex(), Rect2(c - rad, rad * 2.0), false, col)


# ================================================================ particles ===

## A one-shot burst of sparks. `dir` and `spread` (degrees) aim it.
static func burst(parent: Node, pos: Vector2, col: Color, amount: int = 26, speed: float = 420.0,
		size: float = 14.0, life: float = 0.7, gravity := Vector2(0, 260), spread: float = 180.0,
		dir := Vector2.UP, time_scale: float = 1.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = amount
	p.lifetime = life
	p.speed_scale = time_scale
	p.texture = dot_tex()
	p.material = additive()
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.damping_min = speed * 0.4
	p.damping_max = speed * 0.9
	p.scale_amount_min = size / 32.0 * 0.5
	p.scale_amount_max = size / 32.0
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0))
	p.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(col.lightened(0.5), 1), Color(col, 0.9), Color(col, 0)])
	p.color_ramp = g
	p.emitting = true
	parent.add_child(p)
	parent.get_tree().create_timer((life + 0.3) / maxf(0.1, time_scale)).timeout.connect(p.queue_free)
	return p


## Particles that drift upward from an area (healing sparkles, a KO's soul).
static func rise(parent: Node, pos: Vector2, col: Color, width: float = 160.0, amount: int = 30,
		life: float = 1.1, time_scale: float = 1.0) -> CPUParticles2D:
	var p := burst(parent, pos, col, amount, 140.0, 12.0, life, Vector2(0, -160), 25.0, Vector2.UP, time_scale)
	p.explosiveness = 0.55
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width * 0.5, 20)
	p.damping_min = 0
	p.damping_max = 20
	return p


# =================================================================== shapes ===

## A flash of light that blooms and fades.
static func flash(parent: Node, pos: Vector2, col: Color, rad: float = 160.0, dur: float = 0.35) -> void:
	var s := Sprite2D.new()
	s.texture = glow_tex()
	s.material = additive()
	s.modulate = col
	s.position = pos
	var k := rad / 64.0
	s.scale = Vector2(k * 0.4, k * 0.4)
	parent.add_child(s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(k, k), dur * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(s, "modulate:a", 0.0, dur).set_delay(dur * 0.2)
	tw.chain().tween_callback(s.queue_free)


## An expanding ring. `squash` < 1 lays it flat on the floor.
static func shockwave(parent: Node, pos: Vector2, col: Color, rad: float = 180.0, dur: float = 0.45, squash: float = 0.35, width: float = 10.0) -> void:
	var w := Ring.new()
	w.position = pos
	w.col = col
	w.max_rad = rad
	w.squash = squash
	w.width = width
	parent.add_child(w)
	var tw := w.create_tween()
	tw.tween_property(w, "t", 1.0, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(w.queue_free)


class Ring:
	extends Node2D
	var col := Color.WHITE
	var max_rad := 180.0
	var squash := 0.35
	var width := 10.0
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _init() -> void:
		material = DuelFX.additive()

	func _draw() -> void:
		var r := max_rad * (0.15 + 0.85 * t)
		var a := 1.0 - t
		var pts := PackedVector2Array()
		for i in 65:
			var ang := TAU * i / 64.0
			pts.append(Vector2(cos(ang) * r, sin(ang) * r * squash))
		draw_polyline(pts, Color(col, a * 0.5), width * 2.2 * (1.0 - t * 0.5), true)
		draw_polyline(pts, Color(col.lightened(0.4), a), width * 0.6 * (1.0 - t * 0.5), true)


## A pillar of light rising from the floor (Totem called, Ascension).
static func pillar(parent: Node, foot: Vector2, col: Color, width: float = 150.0, height: float = 520.0, dur: float = 0.7) -> void:
	var p := Pillar.new()
	p.position = foot
	p.col = col
	p.w = width
	p.h = height
	parent.add_child(p)
	var tw := p.create_tween()
	tw.tween_property(p, "t", 1.0, dur)
	tw.tween_callback(p.queue_free)


class Pillar:
	extends Node2D
	var col := Color.WHITE
	var w := 150.0
	var h := 520.0
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _init() -> void:
		material = DuelFX.additive()

	func _draw() -> void:
		var grow := clampf(t * 5.0, 0.0, 1.0)
		var a := clampf((1.0 - t) * 1.6, 0.0, 1.0)
		var ww := w * (0.35 + 0.65 * grow) * (1.0 - t * 0.5)
		for i in 4:
			var k := 1.0 - i * 0.22
			var x := ww * k * 0.5
			var c0 := Color(col, 0.0)
			var c1 := Color(col.lightened(0.25 * i), 0.22 * a)
			var pts := PackedVector2Array([Vector2(-x, 0), Vector2(x, 0), Vector2(x * 0.7, -h * grow), Vector2(-x * 0.7, -h * grow)])
			draw_polygon(pts, PackedColorArray([c1, c1, c0, c0]))
		DuelFX.draw_glow(self, Vector2.ZERO, Vector2(w * 0.9, w * 0.3), Color(col, 0.8 * a))


## A glowing orb that flies from `a` to `b` along an arc, trailing sparks.
## Await its `arrived` signal.
static func projectile(parent: Node, a: Vector2, b: Vector2, col: Color, dur: float = 0.35, rad: float = 34.0, arc: float = 120.0) -> Bolt:
	var p := Bolt.new()
	p.a = a
	p.b = b
	p.col = col
	p.rad = rad
	p.arc = arc
	parent.add_child(p)
	var trail := CPUParticles2D.new()
	trail.amount = 40
	trail.lifetime = 0.35
	trail.local_coords = false
	trail.texture = DuelFX.dot_tex()
	trail.material = DuelFX.additive()
	trail.spread = 180
	trail.initial_velocity_min = 10
	trail.initial_velocity_max = 60
	trail.gravity = Vector2.ZERO
	trail.scale_amount_min = rad / 32.0 * 0.4
	trail.scale_amount_max = rad / 32.0 * 0.9
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0))
	trail.scale_amount_curve = sc
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([Color(col, 0.9), Color(col, 0)])
	trail.color_ramp = g
	p.add_child(trail)
	p.trail = trail
	var tw := p.create_tween()
	tw.tween_property(p, "t", 1.0, dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(p._arrive)
	return p


class Bolt:
	extends Node2D
	signal arrived
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var col := Color.WHITE
	var rad := 34.0
	var arc := 120.0
	var trail: CPUParticles2D
	var t := 0.0:
		set(v):
			t = v
			var mid := (a + b) * 0.5 + Vector2(0, -arc)
			position = a.lerp(mid, t).lerp(mid.lerp(b, t), t)
			queue_redraw()

	func _init() -> void:
		material = DuelFX.additive()

	func _ready() -> void:
		t = 0.0

	func _draw() -> void:
		DuelFX.draw_glow(self, Vector2.ZERO, Vector2(rad, rad) * 2.4, Color(col, 0.7))
		DuelFX.draw_glow(self, Vector2.ZERO, Vector2(rad, rad) * 0.9, Color(col.lightened(0.6), 1.0))

	func _arrive() -> void:
		arrived.emit()
		visible = true
		if trail != null:
			trail.emitting = false
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_interval(0.4)
		tw.tween_callback(queue_free)


## A crackling bolt of lightning between two points.
static func lightning(parent: Node, a: Vector2, b: Vector2, col: Color, dur: float = 0.32, width: float = 9.0) -> void:
	var l := Lightning.new()
	l.a = a
	l.b = b
	l.col = col
	l.width = width
	parent.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "t", 1.0, dur)
	tw.tween_callback(l.queue_free)


class Lightning:
	extends Node2D
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var col := Color.WHITE
	var width := 9.0
	var _pts := PackedVector2Array()
	var _k := 0.0
	var t := 0.0:
		set(v):
			t = v
			if v - _k > 0.12 or _pts.is_empty():
				_k = v
				_pts = DuelFX.jagged(a, b, 12, 46.0)
			queue_redraw()

	func _init() -> void:
		material = DuelFX.additive()

	func _draw() -> void:
		var al := 1.0 - t * t
		draw_polyline(_pts, Color(col, 0.35 * al), width * 3.0, true)
		draw_polyline(_pts, Color(col, 0.9 * al), width, true)
		draw_polyline(_pts, Color(1, 1, 1, al), width * 0.35, true)
		DuelFX.draw_glow(self, b, Vector2(90, 90), Color(col, al))


static func jagged(a: Vector2, b: Vector2, n: int, amp: float) -> PackedVector2Array:
	var pts := PackedVector2Array([a])
	var d := b - a
	var nrm := Vector2(-d.y, d.x).normalized()
	for i in range(1, n):
		var k := float(i) / n
		pts.append(a + d * k + nrm * randf_range(-amp, amp) * sin(k * PI))
	pts.append(b)
	return pts


## A sweeping slash across a target (claws, bites, blades).
static func slash(parent: Node, c: Vector2, col: Color, rad: float = 130.0, angle: float = -0.6, dur: float = 0.26) -> void:
	var s := Slash.new()
	s.position = c
	s.rotation = angle
	s.col = col
	s.rad = rad
	parent.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "t", 1.0, dur).set_ease(Tween.EASE_OUT)
	tw.tween_callback(s.queue_free)


class Slash:
	extends Node2D
	var col := Color.WHITE
	var rad := 130.0
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _init() -> void:
		material = DuelFX.additive()

	func _draw() -> void:
		# a crescent that sweeps from left to right, its tail fading
		var head := lerpf(-1.4, 1.4, clampf(t * 1.6, 0.0, 1.0))
		var tail := lerpf(-1.4, 1.4, clampf(t * 1.6 - 0.45, 0.0, 1.0))
		if head - tail < 0.02:
			return
		var al := clampf((1.0 - t) * 2.0, 0.0, 1.0)
		var n := 18
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		var cols := PackedColorArray()
		for i in n + 1:
			var ang := lerpf(tail, head, float(i) / n)
			var k := float(i) / n
			var thick := rad * 0.22 * sin(k * PI) + 2.0
			outer.append(Vector2(cos(ang), sin(ang)) * rad)
			inner.append(Vector2(cos(ang), sin(ang)) * (rad - thick))
		var poly := PackedVector2Array()
		for p in outer:
			poly.append(p)
		for i in range(inner.size() - 1, -1, -1):
			poly.append(inner[i])
		for i in poly.size():
			cols.append(Color(col.lightened(0.5), al))
		draw_polygon(poly, cols)
		draw_polyline(outer, Color(col, 0.6 * al), 8.0, true)


# ============================================================= damage numbers ===

## A big number that punches in and floats up. Returns the label.
static func number(parent: Control, pos: Vector2, text: String, col: Color, size: int = 84, dur: float = 1.0, sub: String = "") -> Label:
	var l := UITheme.label(text, size, col, "display_bold", maxi(10, size / 6))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.04, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(520, size + 30)
	l.position = pos - Vector2(260, size * 0.6) + Vector2(randf_range(-18, 18), 0)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(1.9, 1.9)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	if sub != "":
		var s := UITheme.label(sub, int(size * 0.36), Color("ffe066"), "display_bold", 8)
		s.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.04, 1))
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.size = Vector2(520, size * 0.5)
		s.position = Vector2(0, size * 0.95)
		l.add_child(s)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2(1, 1), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(dur * 0.35)
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 90, dur * 0.65).set_ease(Tween.EASE_IN)
	tw.tween_property(l, "modulate:a", 0.0, dur * 0.65).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(l.queue_free)
	return l
