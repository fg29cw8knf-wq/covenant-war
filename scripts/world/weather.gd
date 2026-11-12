class_name Weather
extends Node3D
## Ashford's weather (12 November, Gary: "yes re weather", then "Yes to all
## 3 suggestions": the shower heard from inside the inn, a rainbow as one
## ends, mist on the morning after the fires).
##
## A shower. Light rain with the sun still out, for about a minute, a few
## minutes into a day on the green and again some minutes after: thin
## streaks falling where the camera is looking, and the green's bed of sound
## changing to rain (Ashford.ambience_at reads raining()). It only comes by
## full day while the player has the run of the green: a staged scene out
## there, a film, the sun going down or a house on fire sees it off in a few
## seconds. Its clock only runs out on the green too, so a long talk doesn't
## bring one on. Going into the inn doesn't stop one that's falling: it
## isn't drawn in there, but it's heard on the roof from the taproom and the
## attic (amb_fire_rain, amb_attic_rain), and it's still raining, or just
## over, when the player comes back out.
##
## A rainbow. As some showers end (BOW_CHANCE), one end of a rainbow comes
## down on the green a few steps past the player and stands for half a
## minute: the walking camera, which never sees the sky, sees its foot in
## the grass; a camera down among the people sees it go up and over the
## village. The same things that see a shower off see it off.
##
## Mist. On the morning after the fires (the village dressed for "dawn") a
## thin, still mist lies low over the green: flat soft sheets a hand to a
## yard off the grass, barely drifting. The Pale Herald's own mist, which
## rolls down the road against the wind, comes in over it.
##
## The sky, the light and the ground are left as they are: nothing here
## changes what the place looks like on a dry, clear day.

const FIRST := [150.0, 300.0]   # seconds of a day on the green before the first shower
const LAST := [55.0, 90.0]      # how long one lasts
const GAP := [360.0, 660.0]     # dry between two
const EASE_IN := 6.0            # seconds from the first drops to all of it
const EASE_OUT := 3.0           # ...and from all of it to none
const DAY := 0.9                # AshfordVillage.daylight at least this: full day
const HEARD_FROM := 0.25        # how much of a shower before the place sounds of rain
const GREEN_REACH := 140.0      # the village: this far from its middle and no further
const DROPS := [700, 1500, 2600]   # streaks in the air at once, by Gfx.level()
const BOX := Vector3(15.0, 0.5, 15.0)   # where they start: this far each way from where the camera looks...
const TOP := 9.5                # ...and this far above it
const FALL := 14.5              # how fast they fall (m/s)
const LEAN := Vector3(0.14, -1.0, 0.05)   # ...and which way: a little on the wind

const BOW_CHANCE := 0.6         # of showers that end by themselves
const BOW_HOLD := 32.0          # seconds it stands
const BOW_IN := 5.0
const BOW_OUT := 9.0
const BOW_RADIUS := 90.0        # the arc's size (m): its far end comes down beyond the hills
const BOW_WIDTH := 4.2
const BOW_AT := Vector2(5.5, 3.0)   # where its near end stands: this far to the right of, and past, the spot the camera looks at
const BOW_LIGHT := 0.4         # how bright it is at its brightest

const MIST_SHEETS := [36, 60, 84]   # by Gfx.level()
const MIST_BOX := Vector3(30.0, 0.32, 26.0)   # how far each way from MIST_MID they lie
const MIST_MID := Vector3(0.0, 0.5, 9.0)
const MIST_SIZE := [7.0, 12.0]  # a sheet's width (m)
const MIST_LIFE := 16.0         # seconds a sheet takes to come, lie and go
const MIST_DRIFT := 0.12        # m/s
const MIST_COL := Color(0.86, 0.84, 0.8, 0.26)
const MIST_BANKS := [16, 28, 40]    # the low banks that stand up off the grass, by Gfx.level()
const MIST_BANK_TALL := 0.14        # a bank's height as a share of its width
const MIST_BANK_COL := Color(0.88, 0.86, 0.82, 0.2)

var world: World
var village: AshfordVillage
var amount := 0.0        # how much of a shower there is now, 0 to 1
var bow := 0.0           # how much of a rainbow, 0 to 1
var mist := 0.0          # how much mist is wanted, 0 or 1 (the sheets come and go by themselves)
var _clock := 0.0        # seconds of free daylight on the green so far
var _next := 0.0         # the clock's time of the next shower
var _left := 0.0         # seconds of this shower still to come
var _forced := -1.0      # the tests: rain for this long whatever the clock says
var _bow_left := 0.0
var _rain: GPUParticles3D
var _bow: MeshInstance3D
var _bow_mat: ShaderMaterial
var _mist: GPUParticles3D
var _banks: GPUParticles3D


## The weather of a world, or null.
static func of(w: Node) -> Weather:
	return w.get_meta("weather") as Weather if w != null and w.has_meta("weather") else null


func setup(w: World, v: AshfordVillage) -> Weather:
	world = w
	village = v
	_next = randf_range(FIRST[0], FIRST[1])
	return self


func _ready() -> void:
	var level := clampi(Gfx.level(), 0, 2)
	_rain = _make_rain(int(DROPS[level]))
	add_child(_rain)
	_rain.emitting = false
	_bow = _make_bow()
	add_child(_bow)
	_bow.visible = false
	# the mist: flat sheets (what's seen from above) and low banks standing
	# up off the grass (what's seen from down among the people)
	_mist = _make_mist(int(MIST_SHEETS[level]), false)
	_banks = _make_mist(int(MIST_BANKS[level]), true)
	for m: GPUParticles3D in [_mist, _banks]:
		add_child(m)
		if village != null:
			m.position.y = village.height(MIST_MID.x, MIST_MID.z) + (MIST_MID.y if m == _mist else 0.0)
		m.emitting = false
		m.visible = false


## Is it raining enough to hear?
func raining() -> bool:
	return amount >= HEARD_FROM


## The tests: a shower now, for this long.
func force(secs: float) -> void:
	_forced = secs


## The tests: a rainbow now, as if a shower had just ended.
func force_bow() -> void:
	_bow_start()


## Where the camera is looking: "green" (out of doors in the village),
## "inn" (one of its rooms, below the ground) or "" (somewhere else: the
## mill, nowhere).
func where() -> String:
	if world == null or world.cam == null:
		return ""
	var at := world.cam_ground()
	if at.y < World.INDOORS_BELOW:
		return "inn"
	return "green" if Vector2(at.x, at.z).length() <= GREEN_REACH else ""


## Whether the day is one a shower could be falling on at all: a full day,
## nothing on fire, no film playing, the world on show.
func fair_day() -> bool:
	if world == null or village == null:
		return false
	if world.attract or world.held or not world.is_visible_in_tree():
		return false
	if Ambience.hush > 0 or village.daylight < DAY or village.time_kind == "dawn" or village.time_kind == "burning":
		return false
	for h: Dictionary in village.houses:
		if h.get("burning", false):
			return false
	return true


## Whether a shower may be falling now: a fair day, and either out on the
## green with the player free, or indoors (where one already falling is
## only heard).
func may_rain() -> bool:
	if not fair_day():
		return false
	match where():
		"green":
			return not world.cine
		"inn":
			return true
	return false


func _process(delta: float) -> void:
	var place := where()
	var ok := may_rain()
	var want := 0.0
	if _forced > 0.0:
		_forced -= delta
		want = 1.0
	elif ok:
		if place == "green":
			_clock += delta   # (only a day spent out on the green brings one on)
		if _left > 0.0:
			_left -= delta
			want = 1.0
			if _left <= 0.0:
				_next = _clock + randf_range(GAP[0], GAP[1])
				if place == "green" and randf() < BOW_CHANCE:
					_bow_start()
		elif place == "green" and _clock >= _next:
			_left = randf_range(LAST[0], LAST[1])
	elif _left > 0.0:
		# (seen off by a scene or the evening: the next one waits its turn)
		_left = 0.0
		_next = _clock + randf_range(GAP[0], GAP[1])
	amount = move_toward(amount, want, delta / (EASE_IN if want > amount else EASE_OUT))
	# the streaks: only out of doors, over the spot of ground on screen
	var drawn := amount > 0.01 and place == "green"
	if drawn:
		var at := world.cam_ground()
		_rain.global_position = Vector3(at.x, at.y + TOP, at.z)
	_rain.emitting = drawn
	_rain.amount_ratio = clampf(amount, 0.02, 1.0)
	_tick_bow(delta, ok and place == "green")
	_tick_mist()


# ---------------------------------------------------------------- rainbow ---

func _bow_start() -> void:
	if world == null or world.cam == null:
		return
	# its near end a few steps past the spot on screen and off to the right,
	# its arc square to the camera and away to the right
	var fwd := -world.cam.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var right := fwd.cross(Vector3.UP).normalized()
	var at := world.cam_ground()
	var foot := at + right * BOW_AT.x + fwd * BOW_AT.y
	foot.y = village.height(foot.x, foot.z) if village != null else at.y
	_bow.global_transform = Transform3D(Basis(right, Vector3.UP, right.cross(Vector3.UP)), foot + right * BOW_RADIUS)
	_bow_mat.set_shader_parameter("ground", foot.y)
	_bow_left = BOW_HOLD


func _tick_bow(delta: float, ok: bool) -> void:
	var want := 0.0
	if _bow_left > 0.0:
		if ok:
			_bow_left -= delta
			want = 1.0
		else:
			_bow_left = 0.0   # (seen off, as a shower is)
	bow = move_toward(bow, want, delta / (BOW_IN if want > bow else (BOW_OUT if ok else EASE_OUT)))
	_bow.visible = bow > 0.004
	if _bow.visible:
		_bow_mat.set_shader_parameter("amount", bow * BOW_LIGHT)


## The arc: a band standing in a ring on the ground, half of it above it,
## red on its outside and violet within, as light added to what's behind.
func _make_bow() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 120
	var r0 := BOW_RADIUS - BOW_WIDTH * 0.5
	var r1 := BOW_RADIUS + BOW_WIDTH * 0.5
	for i in segs:
		var a0 := PI * float(i) / segs
		var a1 := PI * float(i + 1) / segs
		var d0 := Vector3(cos(a0), sin(a0), 0.0)
		var d1 := Vector3(cos(a1), sin(a1), 0.0)
		var quad := [[d0 * r0, Vector2(0, float(i) / segs)], [d0 * r1, Vector2(1, float(i) / segs)], [d1 * r1, Vector2(1, float(i + 1) / segs)],
			[d0 * r0, Vector2(0, float(i) / segs)], [d1 * r1, Vector2(1, float(i + 1) / segs)], [d1 * r0, Vector2(0, float(i + 1) / segs)]]
		for q: Array in quad:
			st.set_uv(q[1])
			st.add_vertex(q[0])
	st.index()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float amount = 0.0;
uniform float ground = 0.0;
varying float high;
void vertex() {
	high = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
vec3 band(float t) {
	// from the inside of the bow out: violet, blue, green, yellow, orange, red
	vec3 c = mix(vec3(0.46, 0.2, 0.9), vec3(0.16, 0.42, 1.0), smoothstep(0.0, 0.22, t));
	c = mix(c, vec3(0.16, 0.86, 0.42), smoothstep(0.22, 0.42, t));
	c = mix(c, vec3(1.0, 0.93, 0.3), smoothstep(0.42, 0.6, t));
	c = mix(c, vec3(1.0, 0.58, 0.2), smoothstep(0.6, 0.78, t));
	return mix(c, vec3(1.0, 0.22, 0.2), smoothstep(0.78, 1.0, t));
}
void fragment() {
	float edge = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	// (it thins away into the grass at its foot)
	float foot = smoothstep(ground + 0.05, ground + 1.4, high);
	ALBEDO = band(UV.x) * edge * foot * amount;
}
"""
	_bow_mat = ShaderMaterial.new()
	_bow_mat.shader = sh
	var mi := MeshInstance3D.new()
	mi.name = "Rainbow"
	mi.mesh = st.commit()
	mi.material_override = _bow_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.extra_cull_margin = 4.0
	return mi


# ------------------------------------------------------------------- mist ---

func _tick_mist() -> void:
	var want := world != null and village != null and village.time_kind == "dawn" and not world.attract and not world.held and where() == "green"
	mist = 1.0 if want else 0.0
	if want and not _mist.emitting:
		# (there from the first frame of the morning, which opens on black)
		for m: GPUParticles3D in [_mist, _banks]:
			m.visible = true
			m.emitting = true
			m.restart()
	elif not want and _mist.emitting:
		# (what's there goes in its own time)
		_mist.emitting = false
		_banks.emitting = false


## The mist's flat sheets, or (`banks`) its low banks: wide soft shapes that
## stand a yard high on the grass and turn to the camera, their edges thinned
## to nothing so they sit on the ground without a line.
func _make_mist(count: int, banks: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "MistBanks" if banks else "Mist"
	p.amount = count
	p.lifetime = MIST_LIFE
	p.preprocess = MIST_LIFE
	p.randomness = 1.0
	p.local_coords = false
	p.position = MIST_MID
	p.visibility_aabb = AABB(-MIST_BOX - Vector3(14, 2, 14), MIST_BOX * 2.0 + Vector3(28, 4, 28))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(MIST_BOX.x, 0.02, MIST_BOX.z) if banks else MIST_BOX
	pm.direction = Vector3(1.0, 0.0, 0.25).normalized()
	pm.spread = 25.0
	pm.flatness = 1.0
	pm.initial_velocity_min = MIST_DRIFT * 0.5
	pm.initial_velocity_max = MIST_DRIFT * 1.5
	pm.gravity = Vector3.ZERO
	pm.scale_min = float(MIST_SIZE[0])
	pm.scale_max = float(MIST_SIZE[1])
	# each sheet comes out of nothing and goes back to it
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = g
	pm.color_ramp = ramp
	p.process_material = pm
	var q := QuadMesh.new()
	var m := StandardMaterial3D.new()
	if banks:
		# a wide low shape standing on the grass (its middle half its height up)
		q.size = Vector2(1.0, MIST_BANK_TALL)
		q.center_offset = Vector3(0.0, MIST_BANK_TALL * 0.5, 0.0)
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.billboard_keep_scale = true
		m.albedo_color = MIST_BANK_COL
	else:
		# a flat soft sheet, lying level
		q.size = Vector2(1.0, 1.0)
		q.orientation = PlaneMesh.FACE_Y
		m.albedo_color = MIST_COL
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = DuelFX.dot_tex()
	m.vertex_color_use_as_albedo = true
	m.disable_receive_shadows = true
	# (where a sheet meets a leg or a wall it thins to nothing, not a line;
	# the phone link's renderer has no depth to read for that)
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		m.proximity_fade_enabled = true
		m.proximity_fade_distance = 0.45
	q.material = m
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return p


# ------------------------------------------------------------------- rain ---

func _make_rain(count: int) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "Rain"
	p.amount = count
	p.lifetime = (TOP + 1.5) / FALL
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-BOX.x - 4.0, -TOP - 4.0, -BOX.z - 4.0), Vector3(BOX.x * 2.0 + 8.0, TOP + 6.0, BOX.z * 2.0 + 8.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = BOX
	pm.direction = LEAN.normalized()
	pm.spread = 1.5
	pm.initial_velocity_min = FALL * 0.9
	pm.initial_velocity_max = FALL * 1.1
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.7
	pm.scale_max = 1.25
	p.process_material = pm
	# a thin soft streak that stands upright and turns to the camera
	var q := QuadMesh.new()
	q.size = Vector2(0.016, 0.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = DuelFX.dot_tex()
	m.albedo_color = Color(0.86, 0.91, 1.0, 0.34)
	m.disable_receive_shadows = true
	q.material = m
	p.draw_pass_1 = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	return p
