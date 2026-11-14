class_name ShardSet
extends RefCounted
## The Shardlands' look, shared by the walk and the duel of the Night of the
## White Sky (WhiteSky). 14 November 2026, Gary: "Can we make the bram bit at
## the beginning look visually better and smoother - I want best looking
## graphics and scenery - also how could we make the battle more dramatic".
##
## Until then the walk was a pale lilac haze from edge to edge (the fog lit
## the whole sky), the snow a flat floor with dots on it, the snowflakes
## hard round spots, the wind's streaks stood upright like rain (a
## camera-facing particle ignores the way it's going), nothing stood on the
## horizon and the crater's light couldn't be seen until he stood over it.
## The duel stood on a different ground altogether: a flat dark blue floor
## that read as sea, under a black sky.
##
## What's here:
##   snow_tex()         one tiling texture made once (broad drifts, grain, the
##                      wind's ridges, glints): the ground's shader reads it a
##                      dozen times a pixel where the old one worked eleven
##                      layers of noise out by hand for every pixel
##   ground_material()  the snow: wind-carved ridges in the light, snow
##                      snaking across it on the wind, glints that come and go
##                      as the camera moves, the crater's black glass
##   ground_mesh()      the snowfield, finer near its middle
##   far_range()        the Shardlands themselves: shards as big as hills
##                      standing round the horizon, dark until the sky opens
##   storm()            the snow: small driven flakes drawn as short streaks
##                      along the wind, big soft ones near the lens, sheets
##                      tearing along the ground, banks of blown snow
##   shaft()            a column of light (the crater's, seen from the start)
##   Prints             his footprints, filling in behind him
##   vignette()         the picture's corners drawn down a little
##   night()            the night's light and air

## The way the storm blows (m/s).
const WIND := Vector3(-5.5, -2.6, 1.6)

static var _tex: ImageTexture
static var _ground_sh: Shader
static var _streak_sh: Shader
static var _soft: GradientTexture2D


## The snow's texture, 512 square and tiling, made once: R broad drifts, G
## fine grain, B the wind's ridges (sharp crests, smooth hollows), A glints
## (a texel in a hundred).
static func snow_tex() -> ImageTexture:
	if _tex != null:
		return _tex
	const N := 512
	var broad := FastNoiseLite.new()
	broad.seed = 11
	broad.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	broad.frequency = 0.006
	broad.fractal_type = FastNoiseLite.FRACTAL_FBM
	broad.fractal_octaves = 5
	var fine := FastNoiseLite.new()
	fine.seed = 23
	fine.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fine.frequency = 0.045
	fine.fractal_type = FastNoiseLite.FRACTAL_FBM
	fine.fractal_octaves = 3
	var ridge := FastNoiseLite.new()
	ridge.seed = 37
	ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridge.frequency = 0.008
	ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridge.fractal_octaves = 2
	ridge.fractal_gain = 0.35
	var a := broad.get_seamless_image(N, N).get_data()
	var b := fine.get_seamless_image(N, N).get_data()
	var c := ridge.get_seamless_image(N, N).get_data()
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var data := PackedByteArray()
	data.resize(N * N * 4)
	for i in N * N:
		var k := i * 4
		data[k] = a[i]
		data[k + 1] = b[i]
		data[k + 2] = c[i]
		data[k + 3] = 0
	for i in N * N / 110:
		data[r.randi_range(0, N * N - 1) * 4 + 3] = r.randi_range(110, 255)
	var img := Image.create_from_data(N, N, false, Image.FORMAT_RGBA8, data)
	img.generate_mipmaps()
	_tex = ImageTexture.create_from_image(img)
	return _tex


## The snow's material. `crater_r` 0: no crater (the duel's field).
static func ground_material(crater: Vector3, crater_r: float) -> ShaderMaterial:
	if _ground_sh == null:
		_ground_sh = Shader.new()
		_ground_sh.code = GROUND
	var m := ShaderMaterial.new()
	m.shader = _ground_sh
	m.set_shader_parameter("drift", snow_tex())
	m.set_shader_parameter("crater", crater)
	m.set_shader_parameter("crater_r", crater_r)
	var w := Vector2(WIND.x, WIND.z).normalized()
	m.set_shader_parameter("wind", w)
	return m


## The snowfield: a square `half` m each way from `centre`, `n` squares a
## side: squares `inner` m across over the middle third of them (the crater's
## bowl and lip, the Circle), then each a little bigger than the last out to
## the edge. Each point's height is asked of `hf` (x, z).
static func ground_mesh(centre: Vector3, half: float, n: int, inner: float, hf: Callable) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# one side's steps out from the middle: `flat` of them even, the rest growing
	var side := maxi(4, n / 2)
	var flat := side / 3
	var grow := side - flat
	var lo := 1.0
	var hi := 1.5
	for k in 40:   # (the growth that brings the last step out to `half`)
		var g := (lo + hi) * 0.5
		var reach := inner * flat + inner * g * (pow(g, grow) - 1.0) / maxf(g - 1.0, 0.00001)
		if reach < half:
			lo = g
		else:
			hi = g
	var out := PackedFloat32Array([0.0])
	var step := inner
	for i in side:
		if i >= flat:
			step *= lo
		out.append(out[-1] + step)
	var line := PackedFloat32Array()
	for i in range(side, 0, -1):
		line.append(-out[i])
	for i in side + 1:
		line.append(out[i])
	var m := line.size()
	for iz in m:
		for ix in m:
			var x: float = centre.x + line[ix]
			var z: float = centre.z + line[iz]
			st.set_uv(Vector2(x, z) * 0.1)
			st.add_vertex(Vector3(x, float(hf.call(x, z)), z))
	for iz in m - 1:
		for ix in m - 1:
			var a := iz * m + ix
			var b := a + 1
			var c := a + m
			var d := c + 1
			for k in [a, b, d, a, d, c]:
				st.add_index(k)
	st.generate_normals()
	return st.commit()


## The Shardlands on the horizon: shards as big as hills in a ring `from` to
## `to` m out from `centre`, each on the ground `hf` gives there. They're drawn
## in their own light (RANGE: no fog on them; they stand in the horizon's haze
## by their own shader), dark against the night until the sky opens: then
## the tear's light finds the faces turned to it. `tall` scales their height.
## Returns their material: "lit" 0..1 the sky's light on them, "haze" the
## horizon's colour, "lit_dir" the way to the light.
static func far_range(parent: Node3D, centre: Vector3, quality: int, seed_v: int, from: float, to: float, hf: Callable, tall := 1.0) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = RANGE
	var m := ShaderMaterial.new()
	m.shader = sh
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var n: int = [16, 24, 36][clampi(quality, 0, 2)]
	for i in n:
		# round the ring in turn, a little uneven, so no gap is left open
		var ang := TAU * (float(i) + r.randf_range(-0.35, 0.35)) / n
		var dist := r.randf_range(from, to)
		var p := centre + Vector3(cos(ang), 0, sin(ang)) * dist
		var hgt := r.randf_range(30.0, 120.0) * (0.75 + 0.5 * dist / to) * tall
		var rad := hgt * r.randf_range(0.1, 0.17)
		var mi := MeshInstance3D.new()
		mi.mesh = WhiteSky._crystal_mesh(r, hgt, rad, r.randi_range(2, 5))
		mi.material_override = m
		mi.position = Vector3(p.x, float(hf.call(p.x, p.z)) - hgt * 0.06, p.z)
		mi.rotation = Vector3(r.randf_range(-0.2, 0.2), r.randf() * TAU, r.randf_range(-0.2, 0.2))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 4.0
		parent.add_child(mi)
	return m


## A soft round dot, clear at its edge (the flakes).
static func soft_tex() -> Texture2D:
	if _soft == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.width = 32
		_soft.height = 32
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(1.0, 0.5)
	return _soft


## A material for particles drawn as streaks along the way they go (their
## process material sets particle_flag_align_y): facing the camera across
## their length, where the standard particle billboard stands every particle
## upright on the screen whichever way it's going.
static func streak_material(tint: Color) -> ShaderMaterial:
	if _streak_sh == null:
		_streak_sh = Shader.new()
		_streak_sh.code = STREAK
	var m := ShaderMaterial.new()
	m.shader = _streak_sh
	m.set_shader_parameter("tex", soft_tex())
	m.set_shader_parameter("tint", tint)
	return m


## The storm about the camera, blown along `wind`: {"fall": the flakes,
## "near": big soft ones by the lens, "blown": sheets torn along the ground,
## "mist": banks of blown snow}. None follows its node (they're left where
## they were made): move the nodes with the camera (place_storm).
static func storm(parent: Node3D, quality: int, wind: Vector3 = WIND) -> Dictionary:
	var q := clampi(quality, 0, 2)
	var out := {}
	# the flakes: small, many, each a short streak along the wind
	var fall := _particles([1500, 3000, 5200][q], 5.0, Vector3(18, 9, 18), wind, 0.7, 1.25, 12.0, Vector2(0.03, 0.1), Color(0.9, 0.94, 1.0, 0.7))
	(fall.process_material as ParticleProcessMaterial).turbulence_enabled = true
	(fall.process_material as ParticleProcessMaterial).turbulence_noise_strength = 1.3
	(fall.process_material as ParticleProcessMaterial).turbulence_noise_scale = 3.2
	parent.add_child(fall)
	out["fall"] = fall
	# by the lens: a few big soft ones, out of focus
	var near := _particles([30, 55, 80][q], 3.0, Vector3(4, 3, 4), wind * 0.85, 0.8, 1.2, 14.0, Vector2(0.065, 0.15), Color(0.92, 0.95, 1.0, 0.16))
	parent.add_child(near)
	out["near"] = near
	# along the ground: long thin sheets torn off the drifts
	var flat := Vector3(wind.x, wind.y * 0.05, wind.z)
	var blown := _particles([140, 280, 460][q], 3.0, Vector3(24, 0.7, 24), flat * 1.5, 0.75, 1.3, 7.0, Vector2(0.42, 1.7), Color(0.9, 0.94, 1.0, 0.065))
	(blown.process_material as ParticleProcessMaterial).gravity = Vector3(0, -0.2, 0)
	(blown.process_material as ParticleProcessMaterial).turbulence_enabled = true
	(blown.process_material as ParticleProcessMaterial).turbulence_noise_strength = 1.6
	(blown.process_material as ParticleProcessMaterial).turbulence_noise_scale = 1.8
	parent.add_child(blown)
	out["blown"] = blown
	# banks of blown snow drifting through, low: what gives the storm its depth
	var mist := GPUParticles3D.new()
	mist.amount = [8, 14, 22][q]
	mist.lifetime = 8.0
	mist.preprocess = 8.0
	mist.visibility_aabb = AABB(Vector3(-90, -20, -90), Vector3(180, 50, 180))
	var mp := ParticleProcessMaterial.new()
	mp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mp.emission_box_extents = Vector3(34, 1.2, 34)
	mp.direction = Vector3(wind.x, 0.0, wind.z).normalized()
	mp.spread = 6.0
	mp.initial_velocity_min = 3.0
	mp.initial_velocity_max = 5.5
	mp.gravity = Vector3.ZERO
	mp.scale_min = 0.7
	mp.scale_max = 1.5
	mp.angle_min = 0.0
	mp.angle_max = 360.0
	var cr := Curve.new()
	cr.add_point(Vector2(0, 0.0))
	cr.add_point(Vector2(0.3, 1.0))
	cr.add_point(Vector2(0.7, 1.0))
	cr.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = cr
	mp.alpha_curve = ct
	mist.process_material = mp
	var mq := QuadMesh.new()
	mq.size = Vector2(9.0, 4.2)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.billboard_keep_scale = true
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.albedo_texture = soft_tex()
	mm.albedo_color = Color(0.62, 0.68, 0.84, 0.085)
	mm.vertex_color_use_as_albedo = true
	mm.proximity_fade_enabled = quality >= 1   # (no hard line where a bank meets the snow or the lens)
	mm.proximity_fade_distance = 1.6
	mm.disable_receive_shadows = true
	mq.material = mm
	mist.draw_pass_1 = mq
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mist)
	out["mist"] = mist
	return out


## The storm's nodes put about a camera at `cam` looking along `fwd` (flat),
## over ground at height `ground`: each upwind and a little ahead, so what it
## sheds blows through the picture.
static func place_storm(st: Dictionary, cam: Vector3, fwd: Vector3, ground: float) -> void:
	var up := -Vector3(WIND.x, 0.0, WIND.z).normalized()
	var ahead := Vector3(fwd.x, 0.0, fwd.z)
	ahead = ahead.normalized() if ahead.length() > 0.01 else Vector3.FORWARD
	if st.has("fall") and is_instance_valid(st.fall):
		(st.fall as Node3D).position = cam + ahead * 7.0 + up * 6.0 + Vector3(0, 3.5, 0)
	if st.has("near") and is_instance_valid(st.near):
		(st.near as Node3D).position = cam + ahead * 2.2 + up * 2.0 + Vector3(0, 1.0, 0)
	if st.has("blown") and is_instance_valid(st.blown):
		(st.blown as Node3D).position = Vector3(cam.x, ground + 0.5, cam.z) + ahead * 10.0 + up * 9.0
	if st.has("mist") and is_instance_valid(st.mist):
		(st.mist as Node3D).position = Vector3(cam.x, ground + 1.3, cam.z) + ahead * 16.0 + up * 12.0


static func _particles(amount: int, life: float, extents: Vector3, wind: Vector3, v_lo: float, v_hi: float, spread: float, size: Vector2, tint: Color) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.preprocess = life
	p.visibility_aabb = AABB(-extents * 2.5 - Vector3(0, 14, 0), extents * 5.0 + Vector3(0, 14, 0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = wind.normalized()
	pm.spread = spread
	pm.initial_velocity_min = wind.length() * v_lo
	pm.initial_velocity_max = wind.length() * v_hi
	pm.gravity = Vector3(0, -0.5, 0)
	pm.scale_min = 0.55
	pm.scale_max = 1.35
	pm.particle_flag_align_y = true
	var cr := Curve.new()
	cr.add_point(Vector2(0, 0.0))
	cr.add_point(Vector2(0.12, 1.0))
	cr.add_point(Vector2(0.85, 1.0))
	cr.add_point(Vector2(1, 0.0))
	var ct := CurveTexture.new()
	ct.curve = cr
	pm.alpha_curve = ct
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = size
	q.material = streak_material(tint)
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


## A column of light `hgt` m tall and `wid` across at its foot, standing on
## its node (turned to the camera about its own height). Its material:
## "k" its brightness (0: gone).
static func shaft(hgt: float, wid: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(wid, hgt)
	q.center_offset = Vector3(0, hgt * 0.5, 0)
	mi.mesh = q
	var sh := Shader.new()
	sh.code = SHAFT
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("col", col)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = hgt
	return mi


## The picture's corners drawn down (`strength` 0..1 at the very corner).
static func vignette(strength: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color.BLACK
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("strength", strength)
	r.material = m
	return r


## The night's light and air on `env` (the walk's and the duel's): a dark
## clear sky over a low haze (the fog no longer lights the sky), little light
## but what the moon, the tear and the Sigils give.
static func night(env: Environment, quality: int) -> void:
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.24, 0.32, 0.56)
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.7
	env.glow_enabled = true
	env.glow_intensity = 0.72
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.fog_enabled = true
	env.fog_light_color = HAZE_NIGHT
	env.fog_density = 0.021
	env.fog_sky_affect = 0.0
	if quality >= 2:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.009
		env.volumetric_fog_albedo = Color(0.78, 0.84, 1.0)
		env.volumetric_fog_length = 56.0
		env.volumetric_fog_anisotropy = 0.35     # (the haze glows towards a light seen through it)
		env.volumetric_fog_ambient_inject = 0.0   # (lit by the lights alone: no flat grey veil)
		env.volumetric_fog_sky_affect = 0.0       # (the sky stays the sky)
		env.ssao_enabled = true
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.13
	env.adjustment_saturation = 0.94


## The haze's colour at night, and with the sky open; and what the great
## shards on the horizon stand in (the far haze, lit: lighter than the near).
const HAZE_NIGHT := Color(0.055, 0.07, 0.125)
const HAZE_TORN := Color(0.12, 0.12, 0.22)
const FAR_NIGHT := Color(0.11, 0.14, 0.23)
const FAR_TORN := Color(0.25, 0.26, 0.44)


## His footprints (and anyone's): a pool of prints laid on the snow where a
## foot comes down, each darkening the snow under it (pressed snow, in
## shadow), fading as the wind fills it. Nothing is made after the pool is.
class Prints:
	extends Node3D

	const MOST := 60
	const SIZE := Vector2(0.17, 0.36)
	var life := 30.0
	var _pool: Array = []
	var _next := 0
	var _mat: ShaderMaterial
	var _now := 0.0

	func _ready() -> void:
		var sh := Shader.new()
		sh.code = ShardSet.PRINT
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		_mat.set_shader_parameter("life", life)
		var q := QuadMesh.new()
		q.size = SIZE
		q.orientation = PlaneMesh.FACE_Y
		for i in MOST:
			var mi := MeshInstance3D.new()
			mi.mesh = q
			mi.material_override = _mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.set_instance_shader_parameter("born", -1000.0)
			mi.position = Vector3(0, -50, 0)
			add_child(mi)
			_pool.append(mi)

	func _process(delta: float) -> void:
		_now += delta
		_mat.set_shader_parameter("now", _now)

	## A foot down at `at` on ground whose normal is `nrm`, the toe along `dir`.
	func step(at: Vector3, nrm: Vector3, dir: Vector3) -> void:
		dir.y = 0.0
		if dir.length() < 0.01 or _pool.is_empty():
			return
		var mi: MeshInstance3D = _pool[_next]
		_next = (_next + 1) % _pool.size()
		var up := nrm.normalized()
		var fwd := (dir - up * dir.dot(up)).normalized()
		var side := up.cross(fwd).normalized()
		# (the quad lies in x, z: its length, z, along the foot)
		mi.global_transform = Transform3D(Basis(side, up, fwd), at + up * 0.025)
		mi.set_instance_shader_parameter("born", _now)

	func clear() -> void:
		for mi in _pool:
			(mi as MeshInstance3D).set_instance_shader_parameter("born", -1000.0)


## A bolt of lightning out of the torn sky, a long way off: `a` in the sky to
## `b` on the ground, jagged by its length, with a fork or two, struck twice
## (bright, gone, bright again, fading) over `secs`; facing `cam`.
class SkyBolt:
	extends MeshInstance3D
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var col := Color(0.8, 0.8, 1.0)
	var width := 0.7
	var secs := 0.5
	var cam: Camera3D
	var _lines: Array = []   # each a list of points
	var _el := 0.0

	func _ready() -> void:
		mesh = ImmediateMesh.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.vertex_color_use_as_albedo = true
		m.disable_fog = true
		material_override = m
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		extra_cull_margin = 200.0
		_lines.append(_jag(a, b, 14))
		var main: Array = _lines[0]
		for k in 2:
			var from: Vector3 = main[randi_range(4, 9)]
			var d := (b - a) * randf_range(0.18, 0.3)
			var out := d.cross(Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1))).normalized() * d.length() * 0.7
			_lines.append(_jag(from, from + d + out, 6))

	func _jag(from: Vector3, to: Vector3, n: int) -> Array:
		var pts := [from]
		var d := to - from
		var side := d.cross(Vector3.UP)
		if side.length() < 0.01:
			side = d.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(d).normalized()
		var amp := d.length() * 0.055
		for i in range(1, n):
			var k := float(i) / n
			pts.append(from + d * k + side * randf_range(-amp, amp) + up * randf_range(-amp, amp))
		pts.append(to)
		return pts

	func _process(delta: float) -> void:
		_el += delta
		var t := _el / maxf(0.05, secs)
		if t >= 1.0:
			queue_free()
			return
		# struck, gone, struck again, dying away
		var al := 1.0 if t < 0.16 else (0.12 if t < 0.3 else (1.0 - (t - 0.3) / 0.7) * 0.9)
		var im := mesh as ImmediateMesh
		im.clear_surfaces()
		if cam == null or not is_instance_valid(cam):
			return
		for li in _lines.size():
			var pts: Array = _lines[li]
			var wk := 1.0 if li == 0 else 0.45
			for layer in [[width * 3.2 * wk, Color(col, 0.3 * al)], [width * wk, Color(col, 0.9 * al)], [width * 0.34 * wk, Color(1, 1, 1, al)]]:
				var w: float = layer[0]
				var c: Color = layer[1]
				im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
				for i in pts.size():
					var p: Vector3 = pts[i]
					var dir: Vector3 = ((pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
					var to_cam := (cam.global_position - p).normalized()
					var sd := dir.cross(to_cam).normalized() * w * 0.5
					im.surface_set_color(c)
					im.surface_add_vertex(p + sd)
					im.surface_set_color(c)
					im.surface_add_vertex(p - sd)
				im.surface_end()


## The picture's edges flared in a colour for a moment (wash's material: "col",
## "k"): a blow's flash, lightning.
static func wash() -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = WASH
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("k", 0.0)
	r.material = m
	return r


# ================================================================ shaders ===

## The snow (ground_material). The drifts' shape in the light comes from the
## texture's heights (broad drifts, and the ridged noise stretched along the
## wind: sastrugi), taken as a slope across three readings; over it snow
## snakes along the wind (two layers of the ridges sliding past each other),
## and glints come and go with the camera. In the crater: black glass.
const GROUND := """
shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
uniform sampler2D drift : repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec3 crater = vec3(0.0, 0.0, -30.0);
uniform float crater_r = 7.0;
uniform float glow = 0.6;
uniform vec2 wind = vec2(-0.96, 0.28);
uniform float blow = 1.0;
uniform float sparkle = 0.35;
uniform float relief = 0.5;
uniform float tone = 1.0;
varying vec3 wp;
varying vec3 wn0;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn0 = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float hgt(vec2 p, vec2 a) {
	return texture(drift, p * 0.023).r * 0.55 + texture(drift, vec2(a.x * 0.011, a.y * 0.052)).b * 0.42;
}
void fragment() {
	vec2 p = wp.xz;
	vec2 across = vec2(-wind.y, wind.x);
	vec2 a = vec2(dot(p, wind), dot(p, across));
	float e = 0.3;
	float h0 = hgt(p, a);
	float hx = (hgt(p + vec2(e, 0.0), a + vec2(wind.x, across.x) * e) - h0) / e;
	float hz = (hgt(p + vec2(0.0, e), a + vec2(wind.y, across.y) * e) - h0) / e;
	float fine = texture(drift, p * 0.37).g;
	float fx = texture(drift, (p + vec2(0.05, 0.0)) * 0.37).g - fine;
	float fz = texture(drift, (p + vec2(0.0, 0.05)) * 0.37).g - fine;
	// snow snaking over it on the wind
	float t = TIME * blow;
	float s1 = texture(drift, vec2(a.x * 0.043 - t * 0.09, a.y * 0.19 + 0.13)).b;
	float s2 = texture(drift, vec2(a.x * 0.017 - t * 0.05, a.y * 0.07 + 0.61)).r;
	float sd = smoothstep(0.52, 0.9, s1 * 0.6 + s2 * 0.62) * clamp(blow, 0.0, 1.4);
	// the bowl: black glass, fused by the fall, snow only at its edges
	float inner = 0.0;
	float d = 0.0;
	if (crater_r > 0.0) {
		d = length(p - crater.xz);
		inner = smoothstep(crater_r * 0.98, crater_r * 0.55, d + (fine - 0.5) * 1.6);
	}
	vec3 n = normalize(wn0 + vec3(-hx * relief - fx * 0.18, 0.0, -hz * relief - fz * 0.18) * (1.0 - sd * 0.6) * (1.0 - inner * 0.85));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float crest = smoothstep(0.3, 0.7, h0 / 1.05);
	vec3 snow = mix(vec3(0.6, 0.67, 0.83), vec3(0.92, 0.94, 0.985), crest * 0.75 + fine * 0.25);
	snow = mix(snow, vec3(0.96, 0.97, 1.0), sd * 0.55) * tone;
	// (dark: lit from a metre or two off by the child's own light, anything
	// paler went grey-white and the bowl was a white dish)
	vec3 glass = mix(vec3(0.02, 0.025, 0.04), vec3(0.09, 0.11, 0.16), fine * 0.45);
	ALBEDO = mix(snow, glass, inner);
	// (and not much of a mirror: it showed the whole torn sky back as a
	// white sheet across the floor)
	ROUGHNESS = mix(mix(0.74, 0.9, sd), 0.3, inner);
	SPECULAR = mix(0.4, 0.16, inner);
	// glints: one texel in a hundred, each lit only from some ways of looking
	float spk = texture(drift, p * 0.33).a;
	vec3 vw = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float tw = fract(spk * 43.0 + dot(vw, vec3(7.1, 3.3, 5.7)) * 2.5);
	vec3 em = vec3(0.7, 0.82, 1.0) * spk * smoothstep(0.62, 1.0, tw) * sparkle * (1.0 - inner) * (1.0 - sd);
	// the light at the bottom of the bowl: a pool of it under the child (it
	// lay bright three metres out, and every close shot in the bowl had a
	// white floor behind it)
	em += vec3(0.85, 0.9, 1.0) * glow * inner * exp(-d * 1.8) * 1.4;
	EMISSION = em;
}
"""


## The far shards (far_range): dark glass in the night's own colour, each
## facet its own shade, a faint rim; `lit` brings the tear's light onto the
## faces turned towards `lit_dir` and along their edges; low down and far
## off they go into the haze.
const RANGE := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back, shadows_disabled;
uniform vec3 night : source_color = vec3(0.06, 0.085, 0.16);
uniform vec3 haze : source_color = vec3(0.11, 0.14, 0.23);
uniform vec3 lit_col : source_color = vec3(0.6, 0.56, 1.0);
uniform vec3 lit_dir = vec3(0.03, 0.6, -0.8);
uniform float lit = 0.0;
uniform float haze_top = 26.0;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 n = normalize(wn);
	vec3 vw = normalize(CAMERA_POSITION_WORLD - wp);
	float fres = pow(1.0 - clamp(dot(n, vw), 0.0, 1.0), 2.5);
	float facing = clamp(dot(n, normalize(lit_dir)) * 0.5 + 0.5, 0.0, 1.0);
	vec3 c = night * (0.6 + 0.9 * facing) + vec3(0.2, 0.34, 0.62) * fres * 0.05;
	// the tear's light: on the faces turned to it, along the facets' edges
	// (UV2.y: 1 across a face, 0 at the point; UV.x across it) and at the rim
	float half_w = 0.5 * max(UV2.y, 0.001);
	float edge = 1.0 - smoothstep(0.0, 0.035, min(half_w - abs(UV.x - 0.5), 0.5) / max(UV2.y, 0.05));
	c += lit_col * (pow(facing, 2.5) * 0.3 + fres * 0.2 + edge * 0.16) * lit;
	float low = exp(-max(wp.y - 8.0, 0.0) / haze_top);
	float far = clamp(length(wp.xz - CAMERA_POSITION_WORLD.xz) / 300.0, 0.0, 1.0);
	ALBEDO = mix(c, haze, clamp(low * 0.9 + far * 0.45, 0.0, 0.97));
}
"""


## A particle drawn as a streak along its own y (the way it's going).
const STREAK := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;
uniform sampler2D tex : source_color, repeat_disable, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(0.92, 0.95, 1.0, 0.8);
void vertex() {
	vec3 c = MODEL_MATRIX[3].xyz;
	vec3 up = MODEL_MATRIX[1].xyz;
	float s = length(up);
	up /= max(s, 0.0001);
	vec3 to_cam = normalize(CAMERA_POSITION_WORLD - c);
	vec3 side = cross(up, to_cam);
	float sl = length(side);
	side = sl > 0.001 ? side / sl : vec3(1.0, 0.0, 0.0);
	vec3 w = c + (side * VERTEX.x + up * VERTEX.y) * s;
	VERTEX = (VIEW_MATRIX * vec4(w, 1.0)).xyz;
	NORMAL = (VIEW_MATRIX * vec4(to_cam, 0.0)).xyz;
}
void fragment() {
	ALBEDO = tint.rgb * COLOR.rgb;
	ALPHA = texture(tex, UV).a * tint.a * COLOR.a;
}
"""


## A column of light (shaft): bright up its middle, fading to its sides and
## up its height, drifting a little.
const SHAFT := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, skip_vertex_transform;
uniform vec4 col : source_color = vec4(0.5, 0.6, 1.0, 1.0);
uniform float k = 1.0;
void vertex() {
	vec3 c = MODEL_MATRIX[3].xyz;
	vec3 to_cam = CAMERA_POSITION_WORLD - c;
	to_cam.y = 0.0;
	to_cam = normalize(to_cam + vec3(0.0001, 0.0, 0.0));
	vec3 side = cross(vec3(0.0, 1.0, 0.0), to_cam);
	vec3 w = c + side * VERTEX.x + vec3(0.0, 1.0, 0.0) * VERTEX.y;
	VERTEX = (VIEW_MATRIX * vec4(w, 1.0)).xyz;
}
void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = 1.0 - UV.y;
	float body = exp(-x * x * 14.0) + exp(-x * x * 3.0) * 0.3;
	float up = pow(1.0 - y, 1.8) * smoothstep(0.0, 0.02, y);
	float drift = 0.86 + 0.14 * sin(TIME * 1.1 + y * 17.0 + x * 3.0);
	ALBEDO = col.rgb * body * up * drift * k * (1.0 - smoothstep(0.85, 1.0, x));
}
"""


## A footprint (Prints): the snow under it darkened, in the shape of a boot's
## sole, fading with its age.
const PRINT := """
shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, shadows_disabled, fog_disabled, cull_disabled;
instance uniform float born = -1000.0;
uniform float now = 0.0;
uniform float life = 30.0;
void fragment() {
	vec2 q = (UV - 0.5) * 2.0;
	// the ball of the foot wider than the heel (the toe at UV.y 1)
	float wdt = mix(0.62, 0.92, smoothstep(-0.7, 0.5, q.y));
	float dd = length(vec2(q.x / wdt, q.y));
	float m = 1.0 - smoothstep(0.55, 1.0, dd);
	float age = clamp((now - born) / life, 0.0, 1.0);
	float k = m * (1.0 - age * age) * 0.72;
	ALBEDO = mix(vec3(1.0), vec3(0.42, 0.5, 0.7), k);
}
"""


const WASH := """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 col : source_color = vec4(0.8, 0.85, 1.0, 1.0);
uniform float k = 0.0;
void fragment() {
	vec2 q = (UV - 0.5) * vec2(1.0, 0.82);
	float v = smoothstep(0.12, 0.9, length(q) * 1.5);
	COLOR = vec4(col.rgb * (0.22 + 0.78 * v) * k, 1.0);
}
"""


const VIGNETTE := """
shader_type canvas_item;
uniform float strength = 0.4;
void fragment() {
	vec2 q = (UV - 0.5) * vec2(1.0, 0.86);
	float v = smoothstep(0.38, 0.92, length(q) * 1.45);
	COLOR = vec4(0.0, 0.0, 0.02, v * strength);
}
"""
