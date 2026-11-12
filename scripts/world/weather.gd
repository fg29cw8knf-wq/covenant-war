class_name Weather
extends Node3D
## A shower passing over Ashford's green now and then (12 November, Gary:
## "yes re weather", to "weather now and then: rain on the green, wind in
## the attic's eaves"; the attic's wind is its bed of sound, amb_attic).
##
## Light rain with the sun still out, for about a minute, a few minutes into
## a day on the green and again some minutes after: thin streaks falling
## where the camera is looking, and the green's bed of sound changing to
## rain (Ashford.ambience_at reads raining()). It only comes by full day,
## out of doors, while the player has the run of the place: a staged scene,
## a film, the sun going down or a house on fire sees it off in a few
## seconds, and it doesn't come back until the player is walking about
## again. Its clock only runs then too, so a long talk doesn't bring it on.
##
## The sky, the light and the ground are left as they are (a sun shower):
## nothing here changes what the place looks like when it's dry.

const FIRST := [150.0, 300.0]   # seconds of a day on the green before the first shower
const LAST := [55.0, 90.0]      # how long one lasts
const GAP := [360.0, 660.0]     # dry between two
const EASE_IN := 6.0            # seconds from the first drops to all of it
const EASE_OUT := 3.0           # ...and from all of it to none
const DAY := 0.9                # AshfordVillage.daylight at least this: full day
const HEARD_FROM := 0.25        # how much of a shower before the place sounds of rain
const DROPS := [700, 1500, 2600]   # streaks in the air at once, by Gfx.level()
const BOX := Vector3(15.0, 0.5, 15.0)   # where they start: this far each way from where the camera looks...
const TOP := 9.5                # ...and this far above it
const FALL := 14.5              # how fast they fall (m/s)
const LEAN := Vector3(0.14, -1.0, 0.05)   # ...and which way: a little on the wind

var world: World
var village: AshfordVillage
var amount := 0.0        # how much of a shower there is now, 0 to 1
var _clock := 0.0        # seconds of free daylight on the green so far
var _next := 0.0         # the clock's time of the next shower
var _left := 0.0         # seconds of this shower still to come
var _forced := -1.0      # the tests: rain for this long whatever the clock says
var _rain: GPUParticles3D


## The weather of a world, or null.
static func of(w: Node) -> Weather:
	return w.get_meta("weather") as Weather if w != null and w.has_meta("weather") else null


func setup(w: World, v: AshfordVillage) -> Weather:
	world = w
	village = v
	_next = randf_range(FIRST[0], FIRST[1])
	return self


func _ready() -> void:
	_rain = _make_rain(int(DROPS[clampi(Gfx.level(), 0, 2)]))
	add_child(_rain)
	_rain.emitting = false


## Is it raining enough to hear?
func raining() -> bool:
	return amount >= HEARD_FROM


## The tests: a shower now, for this long.
func force(secs: float) -> void:
	_forced = secs


## Whether a shower may fall now: a full day out on the green, the player
## free to walk about, nothing on fire and no film playing.
func may_rain() -> bool:
	if world == null or village == null or world.cam == null:
		return false
	if world.attract or world.held or world.cine or not world.is_visible_in_tree():
		return false
	if Ambience.hush > 0 or village.daylight < DAY or village.time_kind == "dawn" or village.time_kind == "burning":
		return false
	var at := world.cam_ground()
	if at.y < World.INDOORS_BELOW or Vector2(at.x, at.z).length() > 140.0:
		return false
	for h: Dictionary in village.houses:
		if h.get("burning", false):
			return false
	return true


func _process(delta: float) -> void:
	var ok := may_rain()
	var want := 0.0
	if _forced > 0.0:
		_forced -= delta
		want = 1.0
	elif ok:
		_clock += delta
		if _left > 0.0:
			_left -= delta
			want = 1.0
			if _left <= 0.0:
				_next = _clock + randf_range(GAP[0], GAP[1])
		elif _clock >= _next:
			_left = randf_range(LAST[0], LAST[1])
	elif _left > 0.0:
		# (seen off by a scene or the evening: the next one waits its turn)
		_left = 0.0
		_next = _clock + randf_range(GAP[0], GAP[1])
	amount = move_toward(amount, want, delta / (EASE_IN if want > amount else EASE_OUT))
	var on := amount > 0.01
	if on and world != null and world.cam != null:
		# over the spot of ground on screen, wherever the camera goes
		var at := world.cam_ground()
		_rain.global_position = Vector3(at.x, at.y + TOP, at.z)
	_rain.emitting = on
	_rain.amount_ratio = clampf(amount, 0.02, 1.0)


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
