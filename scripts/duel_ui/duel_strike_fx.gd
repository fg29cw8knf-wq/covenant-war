class_name DuelStrikeFX
extends RefCounted
## The pieces every attack and card is drawn with on the 3D field (29 October,
## Gary: "In the card battle I want animations added to each card or attacks
## effect"): how a blow of each element crosses the Circle (travel) and how it
## lands (impact), and the pictures for the Rites, Wards, answers and Relics
## that had none. DuelFXStyle says which piece plays; DuelField3D owns the
## world they're drawn in and calls these (strike_travel, strike_impact,
## card_motif...).
##
## Everything is light and plain shapes: CPU particles in modest numbers
## (they draw the same under the phone link's Compatibility renderer as under
## Forward+), additive glows, a few simple meshes, and at most one light per
## piece (every light is another pass over the floor on the phone). The
## particle materials are shared (DuelStrikeFX.pmat), so nothing new has to
## be compiled in the middle of a blow, and DuelField3D.warm_fx() draws each
## once as the duel opens.

static var _mats := {}
static var _tex := {}


# ============================================================== materials ===

## A soft texture by name: dot, glow (DuelFX's), star (a four-pointed
## sparkle), leaf, ring and rune (the field's own rings).
static func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var t: Texture2D = null
	match name:
		"dot":
			t = DuelFX.dot_tex()
		"glow":
			t = DuelFX.glow_tex()
		"star":
			t = _star_tex()
		"leaf":
			t = _leaf_tex()
		"ring":
			t = load("res://assets/art/fx/ring.png")
		"rune":
			t = load("res://assets/art/fx/rune_ring.png")
		"pillar":
			t = load("res://assets/art/fx/pillar.png")
		_:
			t = DuelFX.dot_tex()
	_tex[name] = t
	return t


## A four-pointed sparkle: a bright core and two crossed rays.
static func _star_tex() -> Texture2D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var core := exp(-r * r * 22.0)
			var rays := exp(-absf(u) * 16.0) * maxf(0.0, 1.0 - absf(v)) + exp(-absf(v) * 16.0) * maxf(0.0, 1.0 - absf(u))
			var halo := exp(-r * r * 5.0) * 0.18
			var a := clampf(core + rays * 0.85 + halo, 0.0, 1.0) * clampf((1.0 - r) * 4.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## A leaf (or a petal): pointed at both ends, a little darker down the middle.
static func _leaf_tex() -> Texture2D:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (x + 0.5) / n * 2.0 - 1.0
			var v := (y + 0.5) / n * 2.0 - 1.0
			var w := (1.0 - v * v) * 0.55   # half its width at this height
			var a := clampf((w - absf(u)) * 14.0, 0.0, 1.0)
			var shade := 0.8 + 0.2 * clampf(absf(u) / maxf(0.01, w), 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## The particle material for a texture, a blend (add: light; mix: things,
## smoke, leaves) and a way to face the camera (face; streak: stretched along
## its flight; spin: turned as it tumbles). Shared: colour comes from the
## particles themselves. `bright` lifts additive light into the bloom.
static func pmat(tname: String, blend: String = "add", mode: String = "face", bright: float = 1.0) -> StandardMaterial3D:
	var key := "%s|%s|%s|%.1f" % [tname, blend, mode, bright]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(tname)
	m.albedo_color = Color(bright, bright, bright, 1.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if blend == "add" else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	match mode:
		"streak":
			m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		"spin":
			m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		"flat":
			m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		_:
			m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	_mats[key] = m
	return m


## An unlit additive material for a mesh of light (rings, beams), its own
## (its colour is tweened).
static func light_mat(col: Color, tname: String = "glow", k: float = 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(tname)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(col.r * k, col.g * k, col.b * k, 1.0)
	return m


## A plain lit material for a solid thing (a blade, an ice shard, a stone),
## with a little glow of its own.
static func solid_mat(col: Color, rough: float = 0.6, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = glow
	return m


# ============================================================== particles ===

## A burst (or, with emit_for, a stream) of particles. o: amount, life, speed
## (a number: up to it; or [min, max]), dir, spread, gravity, damp ([min,
## max]), size, quad (Vector2: a stretched one), scale ([min, max]), tex,
## blend, mode (face, streak, spin), bright, cols (first to last), fade_in,
## grow (shrink, grow, swell, flat), shape (point, sphere, box, ring,
## points), radius, box, points, explode, local, radial ([min, max]),
## tangent ([min, max]), emit_for (s), parent (a node to ride with, the
## particles left behind in the world), basis.
static func emit(f: DuelField3D, at: Vector3, o: Dictionary) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var stream := float(o.get("emit_for", 0.0))
	var life := float(o.get("life", 0.7))
	p.one_shot = stream <= 0.0
	p.explosiveness = float(o.get("explode", 0.9 if stream <= 0.0 else 0.0))
	p.amount = maxi(1, int(o.get("amount", 30)))
	p.lifetime = life
	p.local_coords = bool(o.get("local", false))
	p.direction = o.get("dir", Vector3.UP)
	p.spread = float(o.get("spread", 180.0))
	var sp = o.get("speed", 4.0)
	if sp is Array:
		p.initial_velocity_min = float(sp[0])
		p.initial_velocity_max = float(sp[1])
	else:
		p.initial_velocity_min = float(sp) * 0.35
		p.initial_velocity_max = float(sp)
	p.gravity = o.get("gravity", Vector3(0, -9.0, 0))
	var dm = o.get("damp", [0.0, 0.0])
	p.damping_min = float(dm[0])
	p.damping_max = float(dm[1])
	if o.has("radial"):
		p.radial_accel_min = float(o.radial[0])
		p.radial_accel_max = float(o.radial[1])
	if o.has("tangent"):
		p.tangential_accel_min = float(o.tangent[0])
		p.tangential_accel_max = float(o.tangent[1])
	match String(o.get("shape", "point")):
		"sphere":
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = float(o.get("radius", 0.5))
		"box":
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = o.get("box", Vector3(0.5, 0.1, 0.5))
		"ring":
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
			p.emission_ring_axis = Vector3.UP
			p.emission_ring_radius = float(o.get("radius", 0.9))
			p.emission_ring_inner_radius = float(o.get("radius", 0.9)) * 0.85
			p.emission_ring_height = 0.1
		"points":
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
			p.emission_points = o.get("points", PackedVector3Array([Vector3.ZERO]))
	var sc = o.get("scale", [0.5, 1.0])
	p.scale_amount_min = float(sc[0])
	p.scale_amount_max = float(sc[1])
	var curve := Curve.new()
	match String(o.get("grow", "shrink")):
		"grow":
			curve.add_point(Vector2(0, 0.35))
			curve.add_point(Vector2(1, 1))
		"swell":
			curve.add_point(Vector2(0, 0.3))
			curve.add_point(Vector2(0.35, 1))
			curve.add_point(Vector2(1, 0))
		"flat":
			curve.add_point(Vector2(0, 1))
			curve.add_point(Vector2(1, 1))
		_:
			curve.add_point(Vector2(0, 1))
			curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	var cols: Array = o.get("cols", [Color.WHITE])
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cs := PackedColorArray()
	var n := cols.size()
	var fade_in := bool(o.get("fade_in", false))
	for i in n:
		offs.append(float(i) / maxf(1.0, n) if n > 1 else 0.0)
		var c: Color = cols[i]
		cs.append(Color(c, c.a * (0.0 if fade_in and i == 0 else 1.0)))
	offs.append(1.0)
	var last: Color = cols[n - 1]
	cs.append(Color(last, 0.0))
	g.offsets = offs
	g.colors = cs
	p.color_ramp = g
	if String(o.get("mode", "face")) == "spin":
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -280.0
		p.angular_velocity_max = 280.0
	if String(o.get("mode", "face")) == "streak":
		p.particle_flag_align_y = true
	var q := QuadMesh.new()
	var sz := float(o.get("size", 0.12))
	q.size = o.get("quad", Vector2(sz, sz))
	q.material = pmat(String(o.get("tex", "dot")), String(o.get("blend", "add")), String(o.get("mode", "face")), float(o.get("bright", 1.0)))
	p.mesh = q
	var parent: Node3D = o.get("parent", null)
	if parent != null and is_instance_valid(parent):
		parent.add_child(p)
		p.position = at
	else:
		f._fx_parent().add_child(p)
		p.position = at
	if o.has("basis"):
		p.basis = o.basis
	p.emitting = true
	var tree := f.get_tree()
	# (bound to the emitter itself, so a timer outliving it calls nothing)
	if stream > 0.0 and stream < 60.0:
		tree.create_timer(stream).timeout.connect(p.set.bind("emitting", false))
	if stream < 60.0:
		tree.create_timer(maxf(0.0, stream) + life + 0.5).timeout.connect(p.queue_free)
	return p


## A glowing billboard (a projectile's core or halo): a quad facing the
## camera with its own unlit material, drawn over what's behind it. (A
## Sprite3D here vanished under the Compatibility renderer when a particle
## trail rode on the same node: 29 October.)
static func glow(parent: Node3D, col: Color, size: float, k: float = 1.6, tname: String = "glow", blend: String = "add") -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex(tname)
	mat.albedo_color = Color(col.r * k, col.g * k, col.b * k, col.a)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if blend == "add" else BaseMaterial3D.BLEND_MODE_MIX
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.no_depth_test = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m


## A ring of light (a torus), its own material.
static func ring_mesh(col: Color, r: float, thick: float = 0.06) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - thick
	tm.outer_radius = r + thick
	tm.rings = 28
	tm.ring_segments = 6
	m.mesh = tm
	m.material_override = light_mat(col, "glow", 1.8)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## A flat disc of a texture on the floor (a rune circle, a ring).
static func floor_disc(f: DuelField3D, at: Vector3, col: Color, tname: String, size: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	m.mesh = q
	m.rotation_degrees.x = -90
	m.position = at + Vector3(0, 0.05, 0)
	m.material_override = light_mat(col, tname, 1.8)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f._fx_parent().add_child(m)
	return m


# ================================================================ movers ===

## Something flying across the field along an arc: a projectile and its
## trails. Its children are its look; `arrived` fires when it gets there,
## then its trails stop, its glows go out and it's gone.
class Mover:
	extends Node3D
	signal arrived
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var arc := 1.2
	var side := Vector3.ZERO     # a sideways bow in the flight (wisps)
	var dur := 0.3
	var ease_in := true
	var face := false            # turned to point along its flight (shards, blades)
	var spin := Vector3.ZERO     # the spin of its "pivot" child, radians/s
	var pivot: Node3D = null
	var lamp: OmniLight3D = null
	var on_step := Callable()
	var t := 0.0
	var _done := false

	func _ready() -> void:
		position = a

	func at(k: float) -> Vector3:
		var mid := (a + b) * 0.5 + Vector3(0, arc, 0) + side
		return a.lerp(mid, k).lerp(mid.lerp(b, k), k)

	func _process(dt: float) -> void:
		if _done:
			return
		t = minf(1.0, t + dt / maxf(0.01, dur))
		var k := t * t if ease_in else t
		var p := at(k)
		if face:
			var ahead := at(minf(1.0, k + 0.05)) - p
			if ahead.length() > 0.001:
				look_at(p + ahead, Vector3.UP if absf(ahead.normalized().y) < 0.98 else Vector3.RIGHT)
		position = p
		if pivot != null:
			pivot.rotation += spin * dt
		if on_step.is_valid():
			on_step.call(self, t)
		if t >= 1.0:
			_arrive()

	func _arrive() -> void:
		_done = true
		arrived.emit()
		for c in get_children():
			if c is CPUParticles3D:
				(c as CPUParticles3D).emitting = false
			elif c is Sprite3D or c is MeshInstance3D:
				(c as Node3D).visible = false
		if pivot != null:
			pivot.visible = false
		var tw := create_tween()
		if lamp != null:
			tw.tween_property(lamp, "light_energy", 0.0, 0.2)
		tw.tween_interval(0.7)
		tw.tween_callback(queue_free)


static func mover(f: DuelField3D, a: Vector3, b: Vector3, arc: float, dur: float) -> Mover:
	var m := Mover.new()
	m.a = a
	m.b = b
	# (the camera looks down the length of the Circle: a blow lobbed high
	# seems to hang over the far Totem, so it flies low and at an even pace,
	# down or up the screen where it can be seen)
	m.arc = arc * 0.5
	m.dur = dur
	m.ease_in = false
	f._fx_parent().add_child(m)
	return m


static func lamp(parent: Node3D, col: Color, energy: float = 2.5, range_m: float = 4.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = range_m
	l.shadow_enabled = false
	parent.add_child(l)
	return l


# ============================================================ attacks ===
# A blow crossing the field. `a` is the attacker's body, `b` where it lands;
# `k` sizes it (a small blow 0.8, a big one 1.25); `spd` is the battle speed.
# Each returns when the blow has arrived.

static func travel(f: DuelField3D, st: Dictionary, a: Vector3, b: Vector3, k: float, spd: float) -> void:
	var kind := String(st.get("kind", "travel"))
	var col: Color = st.col
	var hot: Color = st.hot
	match kind:
		"breath":
			await breath(f, st, a, b, k, spd)
		"beam":
			await beam(f, a + Vector3(0, 0.25, 0), b, col, hot, k, spd)
		"fall":
			await fall(f, String(st.get("fall", "meteor")), b, col, hot, k, spd)
		"wave":
			var flat := Vector3(b.x - a.x, 0, b.z - a.z)
			f.wave(Vector3(b.x, 0.0, b.z), flat.normalized() if flat.length() > 0.01 else Vector3(0, 0, -1), col)
			await f.get_tree().create_timer(0.24 / spd).timeout
		"howl":
			await howl(f, a + Vector3(0, 0.3, 0), b, col, hot, k, spd)
		"lash":
			await lash(f, String(st.get("el", "verdant")), a, b, col, hot, k, spd)
		_:
			await missile(f, String(st.get("travel", "orb")), a, b, col, hot, k, spd)


## The thrown, spat and cast blows, one look per element.
static func missile(f: DuelField3D, look: String, a: Vector3, b: Vector3, col: Color, hot: Color, k: float, spd: float) -> void:
	match look:
		"fireball":
			var m := mover(f, a, b, 1.2, 0.32 / spd)
			glow(m, Color(1.0, 0.42, 0.08, 0.95), 1.2 * k, 1.0, "glow", "mix")
			glow(m, col, 1.9 * k, 1.5)
			glow(m, hot, 0.75 * k, 3.0)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 46, "life": 0.55, "speed": [0.3, 1.1],
				"gravity": Vector3(0, 1.8, 0), "size": 0.17 * k, "bright": 1.8, "cols": [hot, col, Color(0.55, 0.14, 0.04)], "explode": 0.0})
			flame_trail(f, m, col, k)
			m.lamp = lamp(m, col, 2.8)
			await m.arrived
		"water_jet":
			var m := mover(f, a, b, 1.7, 0.36 / spd)
			glow(m, Color(col.r * 0.6, col.g * 0.8, col.b, 0.9), 1.1 * k, 1.0, "glow", "mix")
			glow(m, col, 1.6 * k, 1.3)
			glow(m, hot, 0.65 * k, 2.2)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 60, "life": 0.5, "speed": [0.4, 1.6], "spread": 70.0,
				"gravity": Vector3(0, -9.0, 0), "size": 0.12 * k, "blend": "mix", "cols": [Color(0.85, 0.95, 1.0, 0.95), Color(col.r * 0.6, col.g * 0.8, col.b, 0.8)], "explode": 0.0})
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 16, "life": 0.35, "speed": 0.3, "gravity": Vector3.ZERO,
				"tex": "glow", "size": 0.6 * k, "cols": [Color(hot, 0.35)], "grow": "grow", "explode": 0.0})
			await m.arrived
		"venom_glob":
			var m := mover(f, a, b, 2.0, 0.38 / spd)
			glow(m, Color(col.r * 0.6, col.g * 0.85, col.b * 0.3, 0.92), 0.95 * k, 1.0, "glow", "mix")
			glow(m, col, 1.2 * k, 1.4)
			glow(m, hot, 0.45 * k, 2.0)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 40, "life": 0.6, "speed": [0.1, 0.5], "spread": 40.0,
				"dir": Vector3.DOWN, "gravity": Vector3(0, -6.0, 0), "size": 0.12 * k, "cols": [hot, col, col.darkened(0.4)], "explode": 0.0})
			await m.arrived
		"mind_rings":
			var m := mover(f, a, b, 0.5, 0.34 / spd)
			glow(m, col, 1.0 * k, 1.5)
			glow(m, hot, 0.4 * k, 2.6)
			var last := [0.0]
			m.on_step = func(mv: Mover, t: float) -> void:
				if t - last[0] > 0.16:
					last[0] = t
					_ring_pulse(f, mv.position, (mv.b - mv.a).normalized(), col, 0.35 * k, 1.1 * k, 0.32 / spd)
			await m.arrived
		"runes":
			var m := mover(f, a, b, 0.8, 0.36 / spd)
			glow(m, col, 0.9 * k, 1.5)
			glow(m, hot, 0.35 * k, 2.6)
			var piv := Node3D.new()
			m.add_child(piv)
			m.pivot = piv
			m.spin = Vector3(0, 9.0, 0)
			for i in 3:
				var r := glow(piv, col, 0.5 * k, 2.0, "rune")
				r.position = Vector3(cos(TAU * i / 3.0), 0, sin(TAU * i / 3.0)) * 0.45 * k
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 30, "life": 0.45, "speed": 0.5, "gravity": Vector3.ZERO,
				"tex": "star", "size": 0.16 * k, "cols": [hot, col], "explode": 0.0})
			await m.arrived
		"blades":
			var m := mover(f, a, b, 0.5, 0.28 / spd)
			var piv := Node3D.new()
			m.add_child(piv)
			m.pivot = piv
			m.spin = Vector3(0, 0, 26.0)
			var steel := solid_mat(Color(0.86, 0.9, 0.98), 0.18, 0.9, 0.35)
			for i in 3:
				var bl := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.2 * k
				cm.bottom_radius = 0.2 * k
				cm.height = 0.025
				cm.radial_segments = 10
				bl.mesh = cm
				bl.material_override = steel
				bl.rotation = Vector3(PI * 0.5, 0, 0)
				bl.position = Vector3(cos(TAU * i / 3.0), sin(TAU * i / 3.0), 0) * 0.25 * k
				piv.add_child(bl)
			glow(m, hot, 0.5 * k, 2.4)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 36, "life": 0.3, "speed": [1.0, 3.0],
				"gravity": Vector3(0, -6.0, 0), "mode": "streak", "quad": Vector2(0.035, 0.22) * k, "cols": [Color(1, 1, 0.9), hot], "explode": 0.0})
			await m.arrived
		"ice_volley":
			var first: Mover = null
			for i in 5:
				var off := Vector3(randf_range(-0.35, 0.35), randf_range(-0.2, 0.25), randf_range(-0.2, 0.2)) * k
				var m := mover(f, a + off * 0.4, b + off, 0.6 + randf() * 0.4, (0.28 + 0.04 * i) / spd)
				m.face = true
				var sh := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = 0.075 * k
				cm.height = 0.6 * k
				cm.radial_segments = 6
				sh.mesh = cm
				sh.material_override = solid_mat(Color(0.82, 0.95, 1.0, 0.85), 0.05, 0.3, 0.9)
				sh.rotation.x = -PI * 0.5   # its point along the flight
				m.add_child(sh)
				emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 14, "life": 0.3, "speed": 0.3, "gravity": Vector3.ZERO,
					"tex": "star", "size": 0.12 * k, "cols": [Color.WHITE, col], "explode": 0.0})
				if first == null:
					first = m
			await first.arrived
		"leaf_flurry":
			var m := mover(f, a, b, 0.9, 0.38 / spd)
			glow(m, col, 1.3 * k, 1.6)
			glow(m, hot, 0.5 * k, 2.6)
			# (light leaves and petals: dark green ones were lost on the lawn)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 40, "life": 0.55, "speed": [0.4, 1.4],
				"gravity": Vector3(0, -1.2, 0), "tex": "leaf", "blend": "mix", "mode": "spin", "size": 0.26 * k,
				"cols": [Color(0.86, 1.0, 0.55), Color(1.0, 0.86, 0.5), col.lightened(0.3)], "grow": "flat", "explode": 0.0})
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 18, "life": 0.4, "speed": 0.4, "gravity": Vector3.ZERO,
				"size": 0.12 * k, "cols": [hot, col], "explode": 0.0})
			await m.arrived
		"arc":
			f.lightning(a + Vector3(0, 0.2, 0), b, col, 0.36 / spd, 0.18 * k)
			f.lightning(a + Vector3(0, 0.2, 0), b, Color.WHITE, 0.22 / spd, 0.07 * k, false)
			emit(f, a, {"amount": 14, "life": 0.3, "speed": 3.0, "gravity": Vector3(0, -6.0, 0), "mode": "streak",
				"quad": Vector2(0.03, 0.18), "cols": [Color.WHITE, col]})
			await f.get_tree().create_timer(0.1 / spd).timeout
		"gust":
			var m := mover(f, a, b, 0.15, 0.3 / spd)
			m.ease_in = false
			m.face = true
			var piv := Node3D.new()
			m.add_child(piv)
			m.pivot = piv
			m.spin = Vector3(0, 0, 14.0)
			var r := ring_mesh(col, 0.5 * k, 0.05)
			r.rotation.x = PI * 0.5
			piv.add_child(r)
			var r2 := ring_mesh(hot, 0.32 * k, 0.035)
			r2.rotation.x = PI * 0.5
			r2.position.z = 0.3
			piv.add_child(r2)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 40, "life": 0.3, "speed": [0.5, 1.5],
				"gravity": Vector3.ZERO, "mode": "streak", "quad": Vector2(0.04, 0.4) * k, "cols": [Color(hot, 0.8), Color(col, 0.4)], "explode": 0.0})
			await m.arrived
		"fissure":
			await fissure(f, a, b, col, Color(0.66, 0.58, 0.46), k, spd)
		"radiant_beam":
			await beam(f, a + Vector3(0, 0.25, 0), b, col, hot, k, spd)
		"shadow_wisps":
			var first: Mover = null
			for i in 3:
				var m := mover(f, a, b, 0.5 + 0.6 * i, (0.34 + 0.05 * i) / spd)
				var across := (b - a).cross(Vector3.UP).normalized()
				m.side = across * (float(i) - 1.0) * 1.1 * k
				glow(m, Color(0.06, 0.02, 0.12, 0.95), 0.9 * k, 1.0, "glow", "mix")
				glow(m, col, 0.45 * k, 1.6)
				emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 26, "life": 0.5, "speed": 0.25, "gravity": Vector3(0, 0.4, 0),
					"tex": "glow", "blend": "mix", "size": 0.45 * k, "cols": [Color(0.08, 0.03, 0.14, 0.75), Color(0.12, 0.05, 0.2, 0.4)], "grow": "grow", "explode": 0.0})
				emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 10, "life": 0.3, "speed": 0.5, "gravity": Vector3.ZERO,
					"size": 0.1 * k, "cols": [hot, col], "explode": 0.0})
				if first == null:
					first = m
			await first.arrived
		"star_fall":
			var m := mover(f, a, b, 2.6, 0.36 / spd)
			var s := glow(m, hot, 0.9 * k, 2.6, "star")
			glow(m, col, 1.1 * k, 1.2)
			m.pivot = s
			m.spin = Vector3(0, 0, 0)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 36, "life": 0.5, "speed": 0.3, "gravity": Vector3(0, -0.6, 0),
				"tex": "star", "size": 0.2 * k, "cols": [Color.WHITE, hot, col], "explode": 0.0})
			await m.arrived
		_:
			var bo := f.bolt(a, b, col, 0.3 / spd, 1.0 * k, 1.4)
			await bo.arrived


## Flames licking off a fireball or a meteor as it flies: saturated puffs,
## mixed rather than added, so they read on a bright ground.
static func flame_trail(f: DuelField3D, m: Node3D, col: Color, k: float) -> void:
	emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 26, "life": 0.4, "speed": [0.2, 0.6], "gravity": Vector3(0, 1.5, 0),
		"tex": "glow", "blend": "mix", "size": 0.6 * k, "grow": "grow",
		"cols": [Color(1.0, 0.62, 0.15, 0.85), Color(col.r * 0.9, col.g * 0.35, col.b * 0.2, 0.55), Color(0.25, 0.08, 0.04, 0.25)], "explode": 0.0})


## A ring of light thrown off along the way (a psychic blow, a howl).
static func _ring_pulse(f: DuelField3D, at: Vector3, dir: Vector3, col: Color, r0: float, r1: float, dur: float) -> void:
	var r := ring_mesh(col, 1.0, 0.07)
	f._fx_parent().add_child(r)
	r.position = at
	if dir.length() > 0.01:
		r.look_at(at + dir, Vector3.UP if absf(dir.y) < 0.98 else Vector3.RIGHT)
		r.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	r.scale = Vector3.ONE * r0
	var mat := r.material_override as StandardMaterial3D
	var tw := r.create_tween().set_parallel(true)
	tw.tween_property(r, "scale", Vector3.ONE * r1, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(r.queue_free)


## A breath: a stream poured from the mouth at the target (fire, frost,
## venom, pollen...), billowing as it goes.
static func breath(f: DuelField3D, st: Dictionary, a: Vector3, b: Vector3, k: float, spd: float) -> void:
	var col: Color = st.col
	var hot: Color = st.hot
	var el := String(st.get("el", "fire"))
	var mouth := a + Vector3(0, 0.3, 0) + (b - a).normalized() * 0.5
	var d := b - mouth
	var dist := d.length()
	var fly := 0.32
	var mix := el in ["venom", "verdant"]
	var cols := [hot, col, col.darkened(0.5)] if el == "fire" else [hot, col]
	var p := emit(f, mouth, {"emit_for": 0.42 / spd, "amount": 100, "life": fly, "dir": d.normalized(), "spread": 13.0,
		"speed": [dist / fly * 0.85, dist / fly * 1.05], "gravity": Vector3(0, 1.2 if el == "fire" else -1.0, 0),
		"tex": "glow", "blend": "add", "bright": 2.0, "size": 0.8 * k, "scale": [0.6, 1.0], "grow": "grow", "cols": cols, "explode": 0.0})
	# its body: the element's own colour, mixed rather than added, so the
	# stream reads on a bright ground (Ashford's green) as well as a dark one
	var body := Color(col.r, col.g * (0.75 if el == "fire" else 0.95), col.b * (0.5 if el == "fire" else 1.0), 0.85)
	emit(f, mouth, {"emit_for": 0.4 / spd, "amount": 70, "life": fly * 1.1, "dir": d.normalized(), "spread": 16.0,
		"speed": [dist / fly * 0.8, dist / fly], "gravity": Vector3(0, 1.0 if el == "fire" else -0.5, 0), "tex": "glow",
		"blend": "mix", "size": 0.85 * k, "scale": [0.5, 1.0], "grow": "grow",
		"cols": [Color(body, 0.0), body, Color(body.darkened(0.45), 0.4)], "explode": 0.0})
	if mix:
		# (pollen and venom carry motes in the stream too)
		emit(f, mouth, {"emit_for": 0.42 / spd, "amount": 40, "life": fly, "dir": d.normalized(), "spread": 12.0,
			"speed": [dist / fly * 0.8, dist / fly], "gravity": Vector3.ZERO, "size": 0.12 * k, "cols": [hot, col], "explode": 0.0})
	var l := lamp(f._fx_parent(), col, 3.0, 5.0)
	l.position = mouth.lerp(b, 0.5)
	var tw := l.create_tween()
	tw.tween_interval(0.4 / spd)
	tw.tween_property(l, "light_energy", 0.0, 0.25)
	tw.tween_callback(l.queue_free)
	if p != null:
		await f.get_tree().create_timer(fly / spd + 0.04).timeout


## A beam of light from one to the other: it reaches across, holds a breath
## and narrows away, motes along it.
static func beam(f: DuelField3D, a: Vector3, b: Vector3, col: Color, hot: Color, k: float, spd: float) -> void:
	var d := b - a
	var dist := maxf(0.1, d.length())
	var holder := Node3D.new()
	f._fx_parent().add_child(holder)
	holder.position = a
	holder.look_at(b, Vector3.UP if absf(d.normalized().y) < 0.98 else Vector3.RIGHT)
	var parts := []
	for layer in [[0.26 * k, col, 0.9], [0.08 * k, hot, 1.6]]:
		var m := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = float(layer[0])
		cm.bottom_radius = float(layer[0])
		cm.height = 1.0
		cm.radial_segments = 12
		cm.rings = 1
		m.mesh = cm
		m.material_override = light_mat(layer[1], "glow", float(layer[2]))
		(m.material_override as StandardMaterial3D).albedo_texture = null
		m.rotation.x = -PI * 0.5   # its length along the beam (-Z)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(m)
		parts.append(m)
	holder.scale = Vector3(1, 1, 0.01)
	for m in parts:
		(m as MeshInstance3D).position = Vector3(0, 0, -0.5)
	var grow := 0.14 / spd
	var tw := holder.create_tween()
	tw.tween_property(holder, "scale", Vector3(1, 1, dist), grow).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.16 / spd)
	tw.tween_property(holder, "scale", Vector3(0.02, 0.02, dist), 0.26 / spd).set_ease(Tween.EASE_IN)
	tw.tween_callback(holder.queue_free)
	emit(f, a.lerp(b, 0.5), {"amount": 26, "life": 0.6, "speed": 0.5, "gravity": Vector3(0, 0.6, 0), "tex": "star",
		"shape": "box", "box": Vector3(0.15, 0.15, dist * 0.5), "basis": holder.basis.orthonormalized(),
		"size": 0.16 * k, "cols": [Color.WHITE, hot, col]})
	f.flash_light(a.lerp(b, 0.6), col, 4.0, 0.5 / spd, 7.0)
	await f.get_tree().create_timer(grow).timeout


## From above, onto the target: a meteor, falling rocks, a bolt, a star,
## a whirlpool, falling ice or leaves.
static func fall(f: DuelField3D, look: String, b: Vector3, col: Color, hot: Color, k: float, spd: float) -> void:
	var foot := Vector3(b.x, 0.0, b.z)
	# what falls comes down slantwise, from a corner of the sky towards the
	# middle of the Circle: the camera sees little of the sky straight over
	# the far Totems, and a star dropped from straight above showed for only
	# the last moment of its fall. `zc` is towards the middle.
	var zc := 1.0 if b.z < 0.0 else -1.0
	match look:
		"rockfall":
			f.rockfall(foot, col)
			await f.get_tree().create_timer(0.3).timeout
		"bolt_down":
			f.lightning(foot + Vector3(0.3, 4.6, 0), b, col, 0.4 / spd, 0.3 * k)
			f.lightning(foot + Vector3(-0.4, 4.6, 0.2), b, Color.WHITE, 0.26 / spd, 0.12 * k, false)
			await f.get_tree().create_timer(0.06 / spd).timeout
		"whirlpool":
			f.swirl(foot, col, 0.8, 3.0)
			f.pillar(foot, col, 2.6, 1.6, 0.6 / spd)
			emit(f, foot + Vector3(0, 0.1, 0), {"amount": 40, "life": 0.7, "speed": [1.0, 2.0], "shape": "ring", "radius": 1.1,
				"tangent": [5.0, 7.0], "radial": [-3.0, -2.0], "gravity": Vector3(0, 1.5, 0), "size": 0.13 * k, "cols": [hot, col]})
			await f.get_tree().create_timer(0.25 / spd).timeout
		"ice_fall", "leaf_fall":
			var first: Mover = null
			for i in 4:
				var off := Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.5, 0.5))
				var m := mover(f, b + off + Vector3(1.4, 2.9, 2.0 * zc), b + off * 0.4, 0.0, (0.36 + 0.05 * i) / spd)
				m.ease_in = true
				m.face = true
				if look == "ice_fall":
					var sh := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = 0.0
					cm.bottom_radius = 0.1 * k
					cm.height = 0.7 * k
					cm.radial_segments = 6
					sh.mesh = cm
					sh.material_override = solid_mat(Color(0.82, 0.95, 1.0, 0.85), 0.05, 0.3, 0.9)
					sh.rotation.x = -PI * 0.5
					m.add_child(sh)
				else:
					emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 16, "life": 0.5, "speed": 0.6, "gravity": Vector3(0, -1.0, 0),
						"tex": "leaf", "blend": "mix", "mode": "spin", "size": 0.22 * k, "cols": [col.lightened(0.2), col.darkened(0.25)], "grow": "flat", "explode": 0.0})
				emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 12, "life": 0.3, "speed": 0.3, "gravity": Vector3.ZERO,
					"tex": "star", "size": 0.12 * k, "cols": [Color.WHITE, col], "explode": 0.0})
				if first == null:
					first = m
			await first.arrived
		"star_fall":
			# a shooting star, streaking down from the left
			var m := mover(f, b + Vector3(-4.5, 2.6, 1.8 * zc), b, 0.0, 0.42 / spd)
			glow(m, hot, 1.0 * k, 2.8, "star")
			glow(m, col, 1.3 * k, 1.3)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 40, "life": 0.55, "speed": 0.3, "gravity": Vector3.ZERO,
				"tex": "star", "size": 0.22 * k, "cols": [Color.WHITE, hot, col], "explode": 0.0})
			m.lamp = lamp(m, col, 2.4)
			await m.arrived
		_:
			# a meteor in the element's colours
			var m := mover(f, b + Vector3(3.6, 2.8, 1.8 * zc), b, 0.0, 0.38 / spd)
			m.ease_in = true
			glow(m, Color(col.r, col.g * 0.7, col.b * 0.5, 0.95), 1.2 * k, 1.0, "glow", "mix")
			glow(m, col, 1.6 * k, 1.5)
			glow(m, hot, 0.7 * k, 3.0)
			emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 50, "life": 0.45, "speed": [0.3, 1.0],
				"gravity": Vector3(0, 2.0, 0), "size": 0.18 * k, "bright": 1.8, "cols": [hot, col, col.darkened(0.6)], "explode": 0.0})
			flame_trail(f, m, col, k)
			m.lamp = lamp(m, col, 3.0)
			await m.arrived


## Rings thrown from the attacker at its target (a howl, a gaze, a screech).
static func howl(f: DuelField3D, a: Vector3, b: Vector3, col: Color, hot: Color, k: float, spd: float) -> void:
	var dir := (b - a).normalized()
	for i in 3:
		var r := ring_mesh(col if i != 1 else hot, 1.0, 0.06)
		f._fx_parent().add_child(r)
		r.position = a
		r.look_at(b, Vector3.UP if absf(dir.y) < 0.98 else Vector3.RIGHT)
		r.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		r.scale = Vector3.ONE * 0.3 * k
		var mat := r.material_override as StandardMaterial3D
		var tw := r.create_tween()
		tw.tween_interval(0.07 * i / spd)
		tw.tween_property(r, "position", b, 0.3 / spd).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(r, "scale", Vector3.ONE * 1.1 * k, 0.3 / spd)
		tw.tween_property(mat, "albedo_color:a", 0.0, 0.12)
		tw.tween_callback(r.queue_free)
	await f.get_tree().create_timer(0.3 / spd).timeout


## A lash out of the ground: vines (Verdant), a web (Venom), stone (Earth)
## run along the floor and burst up under the target; Tide whips water.
static func lash(f: DuelField3D, el: String, a: Vector3, b: Vector3, col: Color, hot: Color, k: float, spd: float) -> void:
	match el:
		"tide":
			await missile(f, "water_jet", a, b, col, hot, k * 0.9, spd * 1.2)
		"earth":
			await fissure(f, a, b, col, Color(0.66, 0.58, 0.46), k, spd)
		"venom":
			await fissure(f, a, b, col, Color(0.28, 0.4, 0.14), k, spd)
		_:
			await fissure(f, a, b, col, Color(0.3, 0.55, 0.22), k, spd)


## Spikes (stone shards, or vines and thorns) bursting up out of the floor
## one after another along the way to the target, dust where each comes up.
static func fissure(f: DuelField3D, a: Vector3, b: Vector3, col: Color, stone: Color, k: float, spd: float) -> void:
	var from := Vector3(a.x, 0.0, a.z)
	var to := Vector3(b.x, 0.0, b.z)
	var d := to - from
	var n := clampi(int(d.length() / 0.7), 3, 9)
	var step := 0.035 / spd
	var dust := Color(stone.lightened(0.25), 0.6)
	for i in n:
		var p := from.lerp(to, float(i + 1) / float(n + 1))
		var tree := f.get_tree()
		tree.create_timer(step * i).timeout.connect(func() -> void:
			if not is_instance_valid(f):
				return
			for j in 2:
				var side := d.cross(Vector3.UP).normalized() * randf_range(-0.3, 0.3)
				_spike(f, p + side, stone, 0.7 + 0.4 * float(i) / n, 0.12 * k, 0.14 / spd)
			emit(f, p + Vector3(0, 0.05, 0), {"amount": 6, "life": 0.45, "speed": 1.4, "spread": 50.0, "gravity": Vector3(0, -4.0, 0),
				"tex": "glow", "blend": "mix", "size": 0.32, "cols": [dust], "grow": "grow"}))
	await f.get_tree().create_timer(step * n).timeout
	for j in 6:
		var side2 := Vector3(randf_range(-0.7, 0.7), 0, randf_range(-0.6, 0.6))
		_spike(f, to + side2, stone, 1.5 * k, 0.17 * k, 0.3 / spd)


static func _spike(f: DuelField3D, p: Vector3, col: Color, h: float, w: float, hold: float) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = w
	cm.height = h
	cm.radial_segments = 5
	m.mesh = cm
	var mat := solid_mat(col.lightened(randf_range(-0.08, 0.08)), 0.85, 0.0, 0.25)
	m.material_override = mat
	m.position = p + Vector3(0, -h * 0.5, 0)
	m.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
	f._fx_parent().add_child(m)
	var tw := m.create_tween()
	tw.tween_property(m, "position:y", p.y + h * 0.45, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(hold)
	tw.tween_property(m, "position:y", p.y - h * 0.5, 0.3).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(m.queue_free)


# ============================================================== impacts ===
# Where a blow lands: `body` the middle of the Totem it hits, `big` for a
# hard one. One flash of real light each.

static func impact(f: DuelField3D, st: Dictionary, body: Vector3, big: bool, k: float = 1.0) -> void:
	var col: Color = st.col
	var hot: Color = st.hot
	var foot := Vector3(body.x, 0.0, body.z)
	var s := k * (1.25 if big else 1.0)
	match String(st.get("impact", "plain")):
		"flare":
			f.flash_sprite(body, col, 1.9 * s, 0.3)
			f.pillar(foot, col, 2.2 * s, 1.3 * s, 0.5)
			emit(f, body, {"amount": int(36 * s), "life": 0.9, "speed": [2.0, 5.5], "gravity": Vector3(0, 2.2, 0), "damp": [2.0, 4.0],
				"size": 0.15 * s, "cols": [hot, col, Color(0.6, 0.15, 0.04)]})
			emit(f, body, {"amount": 14, "life": 0.6, "speed": 1.4, "gravity": Vector3(0, 1.2, 0), "tex": "glow", "blend": "mix",
				"size": 0.8 * s, "cols": [Color(1.0, 0.6, 0.15, 0.85), Color(0.9, 0.3, 0.06, 0.6), Color(0.3, 0.1, 0.05, 0.3)], "grow": "grow"})
			f.floor_wave(foot, col.darkened(0.2), 2.6 * s, 0.5)
		"splash":
			f.flash_sprite(body, col, 1.7 * s, 0.28)
			emit(f, body + Vector3(0, -0.3, 0), {"amount": int(44 * s), "life": 0.9, "dir": Vector3.UP, "spread": 38.0,
				"speed": [3.5, 6.5], "gravity": Vector3(0, -13.0, 0), "size": 0.14 * s, "blend": "mix",
				"cols": [Color(0.9, 0.97, 1.0, 0.95), Color(col.r * 0.55, col.g * 0.8, col.b, 0.85)]})
			emit(f, body, {"amount": 10, "life": 0.5, "speed": 1.0, "gravity": Vector3.ZERO, "tex": "glow", "size": 1.0 * s,
				"cols": [Color(hot, 0.5)], "grow": "grow"})
			f.floor_wave(foot, col, 2.4 * s, 0.45)
			f.get_tree().create_timer(0.12).timeout.connect(func() -> void:
				if is_instance_valid(f):
					f.floor_wave(foot, hot, 3.2 * s, 0.55))
		"rock_burst":
			rocks(f, body, Color(0.5, 0.45, 0.38), int(7 * s), 1.0 * s)
			emit(f, foot + Vector3(0, 0.15, 0), {"amount": 16, "life": 0.9, "speed": [0.6, 1.8], "spread": 70.0, "gravity": Vector3(0, 0.3, 0),
				"damp": [0.8, 1.5], "tex": "glow", "blend": "mix", "size": 0.75 * s, "cols": [Color(0.62, 0.55, 0.45, 0.55), Color(0.5, 0.45, 0.38, 0.3)], "grow": "grow"})
			f.floor_wave(foot, col, 2.6 * s, 0.45)
			f.cam_punch(0.05)
		"arc_burst":
			f.flash_sprite(body, col, 1.3 * s, 0.2)
			for i in 3:
				var to := foot + Vector3(randf_range(-1.3, 1.3), 0.05, randf_range(-1.0, 1.0))
				f.lightning(body, to, col, 0.25, 0.08 * s, false)
			emit(f, body, {"amount": int(34 * s), "life": 0.45, "speed": [3.0, 7.0], "gravity": Vector3(0, -9.0, 0), "mode": "streak",
				"quad": Vector2(0.035, 0.24), "cols": [Color.WHITE, hot, col]})
		"gust_burst":
			f.swirl(foot, col, 0.7, 2.6)
			emit(f, foot + Vector3(0, 0.2, 0), {"amount": 24, "life": 0.5, "speed": [2.0, 4.0], "spread": 80.0, "gravity": Vector3.ZERO,
				"mode": "streak", "quad": Vector2(0.04, 0.45), "cols": [Color(hot, 0.8), Color(col, 0.3)]})
			f.floor_wave(foot, col, 2.8 * s, 0.45)
		"ice_burst":
			f.spikes(foot, Color(0.8, 0.94, 1.0), 6, 1.0 * s, 0.3, 0.09)
			emit(f, body, {"amount": int(30 * s), "life": 0.8, "speed": [1.5, 4.0], "gravity": Vector3(0, -3.0, 0), "tex": "star",
				"size": 0.2 * s, "cols": [Color.WHITE, hot, col]})
			f.flash_sprite(body, col, 1.7 * s, 0.3)
		"thorn_burst":
			f.spikes(foot, Color(0.3, 0.55, 0.22), 6, 0.9 * s, 0.3, 0.08)
			emit(f, body, {"amount": int(26 * s), "life": 1.0, "speed": [1.5, 3.5], "gravity": Vector3(0, -3.5, 0), "tex": "leaf",
				"blend": "mix", "mode": "spin", "size": 0.22 * s, "cols": [Color(0.86, 1.0, 0.55), col.lightened(0.25)], "grow": "flat"})
			f.flash_sprite(body, col, 1.4 * s, 0.3)
		"metal_sparks":
			f.flash_sprite(body, col, 1.4 * s, 0.2)
			emit(f, body, {"amount": int(46 * s), "life": 0.55, "speed": [4.0, 9.0], "gravity": Vector3(0, -14.0, 0), "mode": "streak",
				"quad": Vector2(0.03, 0.22), "cols": [Color(1, 1, 0.92), Color(1.0, 0.8, 0.4), Color(1.0, 0.45, 0.15)]})
		"venom_splat":
			emit(f, body + Vector3(0, -0.2, 0), {"amount": int(30 * s), "life": 0.7, "dir": Vector3.UP, "spread": 70.0, "speed": [2.0, 4.0],
				"gravity": Vector3(0, -10.0, 0), "size": 0.15 * s, "blend": "mix", "cols": [Color(hot, 0.95), Color(col.r * 0.6, col.g * 0.85, col.b * 0.3, 0.9)]})
			emit(f, foot + Vector3(0, 0.3, 0), {"amount": 14, "life": 1.0, "speed": 0.7, "spread": 180.0, "gravity": Vector3(0, 0.2, 0),
				"tex": "glow", "size": 0.9 * s, "cols": [Color(col, 0.0), Color(col, 0.45)], "grow": "swell"})
			f.floor_wave(foot, col, 2.3 * s, 0.5)
		"mind_burst":
			for i in 3:
				var r := ring_mesh(col if i != 1 else hot, 1.0, 0.05)
				f._fx_parent().add_child(r)
				r.position = body + Vector3(0, -0.2 + 0.25 * i, 0)
				r.scale = Vector3.ONE * 0.25
				var mat := r.material_override as StandardMaterial3D
				var tw := r.create_tween().set_parallel(true)
				tw.tween_property(r, "scale", Vector3.ONE * (1.3 + 0.3 * i) * s, 0.45).set_delay(0.05 * i).set_ease(Tween.EASE_OUT)
				tw.tween_property(mat, "albedo_color:a", 0.0, 0.45).set_delay(0.05 * i)
				tw.chain().tween_callback(r.queue_free)
			f.flash_sprite(body, col, 1.7 * s, 0.3)
		"rune_burst":
			var disc := floor_disc(f, foot, col, "rune", 1.0)
			disc.scale = Vector3.ONE * 0.4
			var dmat := disc.material_override as StandardMaterial3D
			var tw2 := disc.create_tween().set_parallel(true)
			tw2.tween_property(disc, "scale", Vector3.ONE * 3.0 * s, 0.5).set_ease(Tween.EASE_OUT)
			tw2.tween_property(disc, "rotation:y", 1.6, 0.6)
			tw2.tween_property(dmat, "albedo_color:a", 0.0, 0.6).set_delay(0.1)
			tw2.chain().tween_callback(disc.queue_free)
			emit(f, foot + Vector3(0, 0.1, 0), {"amount": int(30 * s), "life": 0.9, "speed": [1.2, 2.6], "spread": 25.0,
				"shape": "ring", "radius": 0.9, "gravity": Vector3.ZERO, "tex": "star", "size": 0.16 * s, "cols": [hot, col]})
			f.flash_sprite(body, col, 1.6 * s, 0.3)
		"radiant_burst":
			var star := glow(f._fx_parent(), hot, 2.6 * s, 1.8, "star")
			star.position = body
			star.scale = Vector3.ONE * 0.3
			var smat := star.material_override as StandardMaterial3D
			var tw3 := star.create_tween().set_parallel(true)
			tw3.tween_property(star, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT)
			tw3.tween_property(smat, "albedo_color:a", 0.0, 0.45).set_delay(0.15)
			tw3.chain().tween_callback(star.queue_free)
			emit(f, foot + Vector3(0, 0.2, 0), {"amount": int(30 * s), "life": 1.1, "speed": [1.0, 2.4], "spread": 18.0, "shape": "box",
				"box": Vector3(0.6, 0.1, 0.5), "gravity": Vector3.ZERO, "tex": "star", "size": 0.17 * s, "cols": [Color.WHITE, hot, col]})
			f.flash_sprite(body, col, 1.6 * s, 0.3)
		"shadow_burst":
			emit(f, body, {"amount": int(18 * s), "life": 0.9, "speed": [0.8, 2.0], "gravity": Vector3(0, 0.4, 0), "damp": [1.0, 2.0],
				"tex": "glow", "blend": "mix", "size": 1.0 * s, "cols": [Color(0.06, 0.02, 0.12, 0.85), Color(0.14, 0.06, 0.24, 0.4)], "grow": "grow"})
			emit(f, body, {"amount": int(26 * s), "life": 0.6, "speed": [2.0, 4.5], "gravity": Vector3.ZERO, "damp": [3.0, 5.0],
				"size": 0.13 * s, "cols": [hot, col]})
			f.flash_sprite(body, col, 1.8 * s, 0.3)
		"star_burst":
			emit(f, body, {"amount": int(34 * s), "life": 0.9, "speed": [1.5, 4.5], "gravity": Vector3(0, -1.5, 0), "damp": [1.0, 2.0],
				"tex": "star", "size": 0.24 * s, "cols": [Color.WHITE, hot, col]})
			f.flash_sprite(body, col, 1.8 * s, 0.3)
		_:
			f.flash_sprite(body, col, 1.7 * s, 0.3)
			f.burst(body, col, int(30 * s), 6.0, 0.7, 0.13, 0.0)
	f.flash_light(body, col, 5.0 if big else 3.5, 0.4, 6.0)


## Stones (or chips) thrown out of a point, tumbling and falling, then gone.
static func rocks(f: DuelField3D, at: Vector3, stone: Color, n: int, k: float) -> void:
	var mat := solid_mat(stone, 0.95, 0.0, 0.0)
	for i in n:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var sz := randf_range(0.12, 0.26) * k
		bm.size = Vector3(sz, sz * 0.8, sz * 0.9)
		m.mesh = bm
		m.material_override = mat
		m.position = at
		m.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		f._fx_parent().add_child(m)
		var v := Vector3(randf_range(-1, 1), randf_range(0.6, 1.4), randf_range(-1, 1)).normalized() * randf_range(2.5, 4.5) * k
		var land := Vector3(at.x + v.x * 0.55, sz * 0.4, at.z + v.z * 0.55)
		var top := (at + land) * 0.5 + Vector3(0, v.y * 0.25, 0)
		var dur := randf_range(0.45, 0.65)
		var tw := m.create_tween().set_parallel(true)
		tw.tween_method(func(t: float) -> void:
			if is_instance_valid(m):
				m.position = at.lerp(top, t).lerp(top.lerp(land, t), t), 0.0, 1.0, dur)
		tw.tween_property(m, "rotation", m.rotation + Vector3(randf_range(-6, 6), randf_range(-6, 6), randf_range(-6, 6)), dur)
		tw.chain().tween_interval(0.35)
		tw.chain().tween_property(m, "scale", Vector3.ONE * 0.01, 0.35).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(m.queue_free)


## A blow's mark on the striker itself as it lunges (a melee move): its
## element trailing off it for a moment.
static func lunge_trail(f: DuelField3D, st: Dictionary, parent: Node3D, at: Vector3, dur: float) -> CPUParticles3D:
	var col: Color = st.col
	var hot: Color = st.hot
	var el := String(st.get("el", "any"))
	var o := {"parent": parent, "emit_for": dur, "amount": 30, "life": 0.4, "speed": 0.6, "gravity": Vector3(0, 0.8, 0),
		"size": 0.16, "cols": [hot, col], "explode": 0.0, "shape": "sphere", "radius": 0.35}
	match el:
		"verdant":
			o.merge({"tex": "leaf", "blend": "mix", "mode": "spin", "size": 0.18, "gravity": Vector3(0, -1.5, 0),
				"cols": [col.lightened(0.15), col.darkened(0.3)], "grow": "flat"}, true)
		"frost", "astral", "radiant", "spirit", "mystic":
			o.merge({"tex": "star", "size": 0.16}, true)
		"umbral", "void":
			o.merge({"tex": "glow", "blend": "mix", "size": 0.35, "cols": [Color(0.08, 0.03, 0.14, 0.7)], "grow": "grow"}, true)
		"metal", "storm":
			o.merge({"mode": "streak", "quad": Vector2(0.03, 0.18), "speed": 1.5, "gravity": Vector3(0, -4.0, 0)}, true)
		"tide":
			o.merge({"gravity": Vector3(0, -6.0, 0), "speed": 1.2}, true)
	return emit(f, at, o)


# ============================================================ card motifs ===
# The pictures for the cards that had none (25 October's rite_motif covers the
# rest): a standing Rite's banner, a revival, a blessing, a veil, Wards
# setting and springing, answers, Relics. Each returns how long it plays.

## A rune circle flaring on the floor where a card is cast, in its colour.
static func cast_sigil(f: DuelField3D, at: Vector3, col: Color, size: float = 2.6, dur: float = 0.8) -> void:
	var disc := floor_disc(f, at, col, "rune", size)
	disc.scale = Vector3.ONE * 0.6
	var mat := disc.material_override as StandardMaterial3D
	mat.albedo_color.a = 0.0
	var tw := disc.create_tween().set_parallel(true)
	tw.tween_property(disc, "scale", Vector3.ONE, dur * 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(mat, "albedo_color:a", 1.0, dur * 0.2)
	tw.tween_property(disc, "rotation:y", 1.2, dur)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur * 0.5).set_delay(dur * 0.5)
	tw.chain().tween_callback(disc.queue_free)


## A Continuous Rite takes its stand: a rune circle and a standing column of
## its light, with a flourish of its element.
static func banner(f: DuelField3D, at: Vector3, el: String, col: Color) -> float:
	cast_sigil(f, at, col, 3.0, 1.3)
	f.pillar(at, col, 4.2, 1.2, 1.2)
	flourish(f, at + Vector3(0, 0.6, 0), el, 0.8)
	return 1.0


## A small piece of an element (a called Totem, a banner): embers, a ripple,
## leaves, sparks, frost, wisps...
static func flourish(f: DuelField3D, at: Vector3, el: String, k: float = 1.0) -> void:
	var col := DuelFXStyle.col(el)
	var hot := DuelFXStyle.hot(el)
	match el:
		"fire":
			emit(f, at, {"amount": int(26 * k), "life": 1.0, "speed": [0.6, 2.0], "gravity": Vector3(0, 1.5, 0), "shape": "sphere",
				"radius": 0.5, "size": 0.14, "cols": [hot, col, Color(0.5, 0.12, 0.04)]})
		"tide":
			f.floor_wave(Vector3(at.x, 0.0, at.z), col, 2.2 * k, 0.6)
			emit(f, at, {"amount": int(20 * k), "life": 0.8, "dir": Vector3.UP, "spread": 30.0, "speed": [2.0, 3.5],
				"gravity": Vector3(0, -9.0, 0), "size": 0.11, "cols": [hot, col]})
		"verdant":
			emit(f, at, {"amount": int(18 * k), "life": 1.2, "speed": [0.6, 1.6], "gravity": Vector3(0, -1.0, 0), "tex": "leaf",
				"blend": "mix", "mode": "spin", "size": 0.2, "cols": [Color(0.86, 1.0, 0.55), col.lightened(0.25)], "grow": "flat"})
		"earth":
			emit(f, Vector3(at.x, 0.1, at.z), {"amount": 12, "life": 0.9, "speed": [0.5, 1.4], "spread": 70.0, "gravity": Vector3(0, 0.2, 0),
				"tex": "glow", "blend": "mix", "size": 0.6, "cols": [Color(0.62, 0.55, 0.45, 0.5)], "grow": "grow"})
		"storm", "metal":
			emit(f, at, {"amount": int(22 * k), "life": 0.45, "speed": [2.0, 5.0], "gravity": Vector3(0, -8.0, 0), "mode": "streak",
				"quad": Vector2(0.03, 0.2), "cols": [Color.WHITE, hot, col]})
		"umbral", "void":
			emit(f, at, {"amount": 14, "life": 1.0, "speed": 0.8, "gravity": Vector3(0, 0.5, 0), "tex": "glow", "blend": "mix",
				"size": 0.7, "cols": [Color(0.07, 0.03, 0.13, 0.7)], "grow": "grow"})
		_:
			emit(f, at, {"amount": int(22 * k), "life": 1.0, "speed": [0.6, 1.6], "gravity": Vector3(0, 0.6, 0), "tex": "star",
				"shape": "sphere", "radius": 0.5, "size": 0.15, "cols": [Color.WHITE, hot, col]})


## Light coming down from above onto a Totem or a duellist's side: a
## blessing, Last Stand, Rallying Light.
static func blessing(f: DuelField3D, foot: Vector3, col: Color) -> float:
	var hot := col.lightened(0.5)
	f.pillar(foot, col, 5.5, 1.5, 1.1)
	var halo := ring_mesh(hot, 0.75, 0.05)
	f._fx_parent().add_child(halo)
	halo.position = foot + Vector3(0, 2.6, 0)
	var hmat := halo.material_override as StandardMaterial3D
	var tw2 := halo.create_tween()
	tw2.tween_property(halo, "position:y", foot.y + 0.15, 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw2.parallel().tween_property(halo, "scale", Vector3.ONE * 1.5, 0.7)
	tw2.tween_property(hmat, "albedo_color:a", 0.0, 0.3)
	tw2.tween_callback(halo.queue_free)
	emit(f, foot + Vector3(0, 3.0, 0), {"amount": 36, "life": 1.2, "dir": Vector3.DOWN, "spread": 10.0, "speed": [1.5, 2.6],
		"shape": "box", "box": Vector3(0.6, 0.2, 0.5), "gravity": Vector3.ZERO, "tex": "star", "size": 0.16, "cols": [Color.WHITE, hot, col]})
	f.flash_light(foot + Vector3(0, 1.5, 0), col, 4.0, 1.0, 7.0)
	return 1.0


## Something brought back: light gathering out of the air into a column that
## rises from the ground.
static func revival(f: DuelField3D, foot: Vector3, col: Color) -> float:
	emit(f, foot + Vector3(0, 1.2, 0), {"amount": 40, "life": 0.7, "speed": [0.0, 0.3], "shape": "sphere", "radius": 1.8,
		"gravity": Vector3.ZERO, "radial": [-10.0, -7.0], "tex": "star", "size": 0.16, "grow": "grow", "cols": [Color(col, 0.3), col.lightened(0.5)]})
	f.get_tree().create_timer(0.55).timeout.connect(func() -> void:
		if not is_instance_valid(f):
			return
		f.pillar(foot, col, 5.0, 1.6, 0.9)
		f.rise(foot, col, 36, 1.2, 1.2)
		f.flash_sprite(foot + Vector3(0, 1.0, 0), col.lightened(0.4), 2.6, 0.4))
	return 1.1


## Shadow wrapping round a Totem (a veil, a cloak), then settling into it.
static func veil(f: DuelField3D, foot: Vector3, col: Color) -> float:
	emit(f, foot + Vector3(0, 0.2, 0), {"amount": 26, "life": 1.0, "speed": [0.8, 1.2], "shape": "ring", "radius": 1.0, "dir": Vector3.UP,
		"spread": 10.0, "tangent": [3.0, 4.5], "radial": [-1.4, -0.8], "gravity": Vector3.ZERO, "tex": "glow", "blend": "mix",
		"size": 0.7, "cols": [Color(0.06, 0.02, 0.12, 0.0), Color(0.07, 0.03, 0.14, 0.75), Color(0.1, 0.04, 0.18, 0.5)], "grow": "swell"})
	emit(f, foot + Vector3(0, 0.6, 0), {"amount": 24, "life": 0.9, "speed": [0.5, 1.2], "shape": "sphere", "radius": 0.8,
		"gravity": Vector3(0, 0.5, 0), "size": 0.12, "cols": [col.lightened(0.4), col]})
	return 0.9


## Quick feet: a gust whirling up round a Totem, streaks of wind.
static func haste(f: DuelField3D, foot: Vector3, col: Color) -> float:
	f.swirl(foot, col, 0.6, 3.2)
	emit(f, foot + Vector3(0, 0.6, 0), {"amount": 26, "life": 0.4, "speed": [2.5, 4.0], "spread": 60.0, "dir": Vector3.UP,
		"gravity": Vector3.ZERO, "mode": "streak", "quad": Vector2(0.04, 0.5), "cols": [Color(1, 1, 1, 0.8), Color(col, 0.4)]})
	return 0.6


## A shield springing up round a Totem: a dome of light that flashes, holds
## and fades (a Ward, an answer cancelling a blow, Guard).
static func shield(f: DuelField3D, foot: Vector3, col: Color, r: float = 1.25, hold: float = 0.35) -> float:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.is_hemisphere = true
	sm.radial_segments = 24
	sm.rings = 10
	m.mesh = sm
	var mat := ShaderMaterial.new()
	mat.shader = DuelCrystal.shield_shader()
	mat.set_shader_parameter("tint", Color(col.r, col.g, col.b))
	mat.set_shader_parameter("power", 0.0)
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = foot + Vector3(0, 0.02, 0)
	m.scale = Vector3(0.7, 0.4, 0.7)
	f._fx_parent().add_child(m)
	var tw := m.create_tween()
	tw.tween_property(m, "scale", Vector3.ONE, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_method(func(v: float) -> void: mat.set_shader_parameter("power", v), 0.0, 1.15, 0.12)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("power", v), 1.15, 0.7, 0.2)
	tw.tween_interval(hold)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("power", v), 0.7, 0.0, 0.35)
	tw.tween_callback(m.queue_free)
	emit(f, foot + Vector3(0, r * 0.6, 0), {"amount": 22, "life": 0.6, "speed": [1.5, 3.0], "shape": "sphere", "radius": r * 0.9,
		"gravity": Vector3.ZERO, "damp": [2.0, 3.0], "tex": "star", "size": 0.14, "cols": [Color.WHITE, col]})
	f.flash_light(foot + Vector3(0, 1.0, 0), col, 4.0, 0.5, 6.0)
	return 0.5 + hold


## A rune seal: a circle of runes closes over something and breaks it
## (a Rite or a Ward cancelled).
static func rune_seal(f: DuelField3D, at: Vector3, col: Color) -> float:
	var disc := floor_disc(f, Vector3(at.x, 0.0, at.z), col, "rune", 3.2)
	disc.position.y = at.y
	disc.rotation_degrees.x = 0
	disc.scale = Vector3.ONE * 1.6
	var mat := disc.material_override as StandardMaterial3D
	var tw := disc.create_tween()
	tw.tween_property(disc, "scale", Vector3.ONE * 0.5, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(disc, "rotation:z", 2.0, 0.35)
	tw.tween_callback(func() -> void:
		if is_instance_valid(f):
			emit(f, at, {"amount": 30, "life": 0.6, "speed": [2.0, 4.5], "gravity": Vector3(0, -3.0, 0), "tex": "star", "size": 0.16,
				"cols": [Color.WHITE, col]})
			f.flash_sprite(at, col, 2.4, 0.3))
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tw.tween_callback(disc.queue_free)
	return 0.6


## A gem glinting down onto a Totem as a Relic is hung on it, then its glow.
static func relic(f: DuelField3D, foot: Vector3, col: Color) -> float:
	var m := mover(f, foot + Vector3(0, 3.4, 0), foot + Vector3(0, 1.0, 0), 0.0, 0.4)
	m.ease_in = false
	glow(m, Color.WHITE, 0.7, 2.6, "star")
	glow(m, col, 0.9, 1.4)
	m.arrived.connect(func() -> void:
		if is_instance_valid(f):
			f.aura(foot, col)
			f.flash_sprite(foot + Vector3(0, 1.0, 0), col.lightened(0.4), 2.0, 0.35))
	return 0.9


## Ash falling and catching on every Totem across (Rite of Ashes).
static func ash_storm(f: DuelField3D, foot: Vector3, col: Color) -> float:
	emit(f, foot + Vector3(0, 3.2, 0), {"amount": 40, "life": 0.9, "dir": Vector3.DOWN, "spread": 15.0, "speed": [2.0, 3.5],
		"shape": "box", "box": Vector3(0.9, 0.2, 0.7), "gravity": Vector3(0, -2.0, 0), "tex": "glow", "blend": "mix",
		"size": 0.25, "cols": [Color(0.3, 0.28, 0.26, 0.8), Color(0.2, 0.18, 0.17, 0.5)], "grow": "flat"})
	f.get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if is_instance_valid(f):
			impact(f, {"impact": "flare", "col": col, "hot": col.lightened(0.5)}, foot + Vector3(0, 0.9, 0), true))
	return 0.9


## Golden sparkle round the plate and a card drawn (Loaded Dice).
static func dice(f: DuelField3D, at: Vector3, col: Color) -> float:
	emit(f, at + Vector3(0, 0.8, 0), {"amount": 30, "life": 0.9, "speed": [1.5, 3.0], "gravity": Vector3(0, -2.0, 0), "tex": "star",
		"size": 0.2, "cols": [Color(1, 0.95, 0.7), Color(1.0, 0.8, 0.3)]})
	return f.cards_fan(at, col)


## Light drawn out of the target back to whoever cast it (a drain).
static func drain(f: DuelField3D, from_body: Vector3, to: Vector3, col: Color) -> float:
	for i in 4:
		var m := mover(f, from_body + Vector3(randf_range(-0.3, 0.3), randf_range(-0.2, 0.3), 0), to + Vector3(0, 0.6, 0), 1.0 + 0.3 * i, 0.5 + 0.06 * i)
		m.ease_in = false
		glow(m, col, 0.5, 1.8)
		emit(f, Vector3.ZERO, {"parent": m, "emit_for": 99.0, "amount": 12, "life": 0.35, "speed": 0.2, "gravity": Vector3.ZERO,
			"size": 0.1, "cols": [col.lightened(0.4), col], "explode": 0.0})
	f.get_tree().create_timer(0.55).timeout.connect(func() -> void:
		if is_instance_valid(f):
			f.mend(Vector3(to.x, 0.0, to.z), col))
	return 0.8
