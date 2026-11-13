class_name DuelCracks
extends RefCounted
## The stone under a hurt Totem cracking (12 November, Gary's yes to "a crack
## spreading across the Totem's base as it's hurt"): dark cracks running out
## from under its feet across its slot's floor, as far as it has lost of its
## Health (none at full; at its last few points they reach the rune circle's
## edge), spreading out over a moment after each blow rather than all at
## once, their newest ends glowing in the Totem's own colour as they run
## (the light in it leaking out) and dimming after. Healed, they close up
## again; a new Totem in the slot starts on whole stone. In the 3D field only
## (DuelField3D.sync calls sync each frame for each Totem standing).
##
## One crack picture for every slot (made once, CRACK_SEED): a few cracks
## branching out from the middle, each pixel's red its darkness and its green
## how far out along its crack it lies (0 at the middle, 1 at the tips), so
## the shader shows a crack as far as `amount` reaches. Each slot turns it
## its own way so no two read alike.

## The floor the cracks cover (m across; the rune circle is 3.1). Seen from
## the duel's camera a crack has to be a hand wide to show at all.
const SIZE := 3.0
## Just over the floor's glow and under the rune circle (m).
const LIFT := 0.018
## How fast they spread to where the Health says (share of the way a second).
const SPREAD := 0.75
## How fast they close up again when it's healed.
const CLOSE := 1.5
## A knockout: how far out the cracks run at once as it shatters (split),
## how many chips fly, and how long the broken stone stays after the slot is
## cleared (s), fading over the last AFTER_KO_FADE of it.
const SPLIT_REACH := 1.0
const SPLIT_CHIPS := 26
const AFTER_KO := 1.6
const AFTER_KO_FADE := 0.8
## Their glow after a blow (fades over this long, s).
const GLOW_SECS := 1.1
## The picture: its size in pixels, its cracks, its seed.
const TEX := 512
const MAIN := 7
const CRACK_SEED := 4127
## A main crack's half-width where it starts (px of TEX: 6 mm a pixel), its
## branches thinner.
const WIDE := 13.0

## The picture made once and kept (tools/make_base_cracks.gd writes it from
## make_image(); made here as the game runs only if it's missing, which
## takes most of a second).
const PICTURE := "res://assets/art/fx/base_cracks.png"

static var _tex: Texture2D = null
static var _shader: Shader = null

const SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D cracks : filter_linear, repeat_disable;
uniform float amount = 0.0;
uniform float glow = 0.0;
uniform vec4 col : source_color = vec4(1.0);
uniform float fade = 1.0;
void fragment() {
	vec4 c = texture(cracks, UV);
	float reach = c.g;
	float line = c.r;
	// shown as far out as it has reached, the front softened
	float shown = 1.0 - smoothstep(amount - 0.04, amount, reach);
	// the deep middle of a crack, and the chipped pale stone along its lips
	float core = smoothstep(0.5, 0.8, line);
	float lip = smoothstep(0.04, 0.35, line) * (1.0 - core);
	// light leaking up out of the deep of it, in its colour: a little always,
	// and the newest part, near the front, lit while the glow lasts
	float front = smoothstep(amount - 0.3, amount, reach);
	float leak = core * (0.1 + 0.9 * front * glow);
	vec3 dark = vec3(0.02, 0.016, 0.014);
	vec3 pale = vec3(0.62, 0.57, 0.5);
	vec3 rgb = mix(pale, dark, core);
	ALBEDO = mix(rgb, col.rgb * 2.6, clamp(leak, 0.0, 1.0));
	ALPHA = clamp(core + lip * 0.45, 0.0, 1.0) * shown * fade;
}
"""


## Each frame, for a slot with a Totem standing in it: the cracks under it as
## far as its Health says, in its colour (col), faded with the slot (fade).
static func sync(_field: Node, s: Node3D, t, col: Color, fade: float, dt: float) -> void:
	var m := (s.get_meta("base_crack") if s.has_meta("base_crack") else null) as MeshInstance3D
	var who: int = t.get_instance_id() if t != null else 0
	if t == null and m != null and m.visible and float(s.get_meta("base_crack_k", 0.0)) > 0.005:
		# (its Totem gone, knocked out and shattered: the broken stone stays a
		# moment and fades, AFTER_KO, rather than mending as the slot clears)
		var left := float(s.get_meta("base_crack_left", AFTER_KO)) - dt
		s.set_meta("base_crack_left", left)
		var mat0 := m.material_override as ShaderMaterial
		mat0.set_shader_parameter("fade", clampf(left / AFTER_KO_FADE, 0.0, 1.0))
		var g0 := maxf(0.0, float(s.get_meta("base_crack_glow", 0.0)) - dt / GLOW_SECS)
		s.set_meta("base_crack_glow", g0)
		mat0.set_shader_parameter("glow", g0)
		if left > 0.0:
			return
	if s.has_meta("base_crack_left"):
		s.remove_meta("base_crack_left")
	if int(s.get_meta("base_crack_of", 0)) != who:
		# (a new Totem: whole stone)
		s.set_meta("base_crack_of", who)
		s.set_meta("base_crack_k", 0.0)
		s.set_meta("base_crack_target", 0.0)
		s.set_meta("base_crack_glow", 0.0)
	var target := 0.0
	if t != null and t.max_hp() > 0:
		target = clampf(1.0 - float(maxi(0, t.hp_left())) / float(t.max_hp()), 0.0, 1.0)
	var was_target := float(s.get_meta("base_crack_target", 0.0))
	var glow := float(s.get_meta("base_crack_glow", 0.0))
	if target > was_target + 0.001:
		glow = 1.0   # (hurt again: the new cracks run lit)
	s.set_meta("base_crack_target", target)
	var k := float(s.get_meta("base_crack_k", 0.0))
	if k < target:
		k = minf(target, k + SPREAD * dt * maxf(0.35, target - k + 0.35))
	elif k > target:
		k = maxf(target, k - CLOSE * dt)
	glow = maxf(0.0, glow - dt / GLOW_SECS)
	s.set_meta("base_crack_k", k)
	s.set_meta("base_crack_glow", glow)
	if k <= 0.005:
		if m != null:
			m.visible = false
		return
	if m == null:
		m = _make(s)
	m.visible = fade > 0.02
	var mat := m.material_override as ShaderMaterial
	# (the cracks' reach drawn out a little past the Health lost: a Totem a
	# quarter down shows cracks a third of the way out, so a first blow reads)
	mat.set_shader_parameter("amount", 0.12 + k * 0.92)
	mat.set_shader_parameter("glow", glow)
	mat.set_shader_parameter("col", col)
	mat.set_shader_parameter("fade", clampf(fade, 0.0, 1.0))


## A knocked-out Totem shattering (DuelField3D.crystal_death, as it bursts:
## 12 November, later, Gary's yes): the stone under it splits through, its
## cracks run out to the edge at once and blaze in its colour (`col`), and
## chips of it fly up and fall back about the slot (SPLIT_CHIPS).
static func split(s: Node3D, col: Color, spd := 1.0) -> void:
	s.set_meta("base_crack_k", maxf(float(s.get_meta("base_crack_k", 0.0)), SPLIT_REACH))
	s.set_meta("base_crack_target", 1.0)
	s.set_meta("base_crack_glow", 1.0)
	if not s.has_meta("base_crack"):
		_make(s)
	var mm := s.get_meta("base_crack") as MeshInstance3D
	mm.visible = true
	var mat := mm.material_override as ShaderMaterial
	mat.set_shader_parameter("amount", 0.12 + SPLIT_REACH * 0.92)
	mat.set_shader_parameter("glow", 1.0)
	mat.set_shader_parameter("col", col)
	var p := CPUParticles3D.new()
	p.name = "StoneChips"
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = SPLIT_CHIPS
	p.lifetime = 1.3 / maxf(0.1, spd)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.95
	p.emission_ring_inner_radius = 0.35
	p.emission_ring_height = 0.02
	p.direction = Vector3.UP
	p.spread = 50.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.2
	p.gravity = Vector3(0, -11.0, 0)
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.particle_flag_rotate_y = true
	p.scale_amount_min = 0.55
	p.scale_amount_max = 1.5
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 1))
	shrink.add_point(Vector2(0.75, 1))
	shrink.add_point(Vector2(1, 0))
	p.scale_amount_curve = shrink
	var chip := BoxMesh.new()
	chip.size = Vector3(0.08, 0.045, 0.065)
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.46, 0.43, 0.39)
	cm.roughness = 0.95
	chip.material = cm
	p.mesh = chip
	s.add_child(p)
	p.position = Vector3(0, 0.05, 0)
	p.emitting = true
	s.get_tree().create_timer(p.lifetime + 0.6, false).timeout.connect(p.queue_free)


## Where a slot's cracks reach now (0 whole, 1 broken through), for the tests.
static func reach(s: Node3D) -> float:
	return float(s.get_meta("base_crack_k", 0.0))


static func _make(s: Node3D) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = "BaseCrack"
	var q := QuadMesh.new()
	q.size = Vector2(SIZE, SIZE)
	m.mesh = q
	m.rotation_degrees = Vector3(-90, 0, 37.0 + 71.0 * float(s.get("index") if s.get("index") != null else 0) + 113.0 * float(s.get("side") if s.get("side") != null else 0))
	m.position.y = LIFT
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("cracks", texture())
	m.material_override = mat
	m.sorting_offset = 0.01
	s.add_child(m)
	s.set_meta("base_crack", m)
	return m


## The crack picture: red how dark, green how far out along it.
static func texture() -> Texture2D:
	if _tex != null:
		return _tex
	if ResourceLoader.exists(PICTURE):
		_tex = load(PICTURE) as Texture2D
	else:
		_tex = ImageTexture.create_from_image(make_image())
	return _tex


static func make_image() -> Image:
	var img := Image.create(TEX, TEX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = CRACK_SEED
	var c := Vector2(TEX, TEX) * 0.5
	var reach_px := TEX * 0.47
	for i in MAIN:
		var ang := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / MAIN
		_crack(img, rng, c + Vector2.from_angle(ang) * rng.randf_range(4.0, 18.0), ang, reach_px * rng.randf_range(0.8, 1.0), 0.0, WIDE, 0, reach_px)
	return img


## One crack from `p` heading `ang`, `length` px long, starting `from` of
## the way out, `w` px wide: straight runs at sharp turns, as stone breaks,
## thinning to its tip, now and then splitting off a thinner one.
static func _crack(img: Image, rng: RandomNumberGenerator, p: Vector2, ang: float, length: float, from: float, w: float, depth: int, reach_px: float) -> void:
	var gone := 0.0
	var a := ang
	var run_left := 0.0
	var wob := 1.0
	while gone < length:
		if run_left <= 0.0:
			# (a new straight run, at a sharp turn from the last, pulled back
			# to its way out so it doesn't curl round)
			a = ang + rng.randf_range(-0.55, 0.55)
			run_left = rng.randf_range(7.0, 18.0)
			wob = rng.randf_range(0.75, 1.15)
		var k := gone / length
		var ww := maxf(2.5, w * (1.0 - 0.7 * k) * wob)
		var step := clampf(ww * 0.45, 0.6, 2.0)
		p += Vector2.from_angle(a) * step
		gone += step
		run_left -= step
		var out := clampf(from + gone / reach_px, 0.0, 1.0)
		_stamp(img, p, ww, out)
		if depth < 2 and gone > 12.0 and rng.randf() < 0.022 * step:
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			_crack(img, rng, p, a + side * rng.randf_range(0.5, 1.1), (length - gone) * rng.randf_range(0.3, 0.65), out, ww * 0.55, depth + 1, reach_px)


static func _stamp(img: Image, p: Vector2, r: float, out: float) -> void:
	var x0 := int(floor(p.x - r - 1.0))
	var y0 := int(floor(p.y - r - 1.0))
	var x1 := int(ceil(p.x + r + 1.0))
	var y1 := int(ceil(p.y + r + 1.0))
	for y in range(maxi(0, y0), mini(TEX - 1, y1) + 1):
		for x in range(maxi(0, x0), mini(TEX - 1, x1) + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(p)
			# (dark in the middle, fading out to its lips)
			var v := 1.0 - smoothstep(r * 0.3, r + 0.5, d)
			if v <= 0.0:
				continue
			var old := img.get_pixel(x, y)
			if v > old.r or (old.r > 0.0 and out < old.g):
				# (the darker line wins, and where two meet, the nearer the middle)
				img.set_pixel(x, y, Color(maxf(v, old.r), out if old.r <= 0.0 else minf(out, old.g), 0, 1))
