class_name Breath
extends Node3D
## Breath that shows in the cold (12 November, Gary: "Yes to all 3", to
## "breath showing in the cold, in the snow memory and at dawn"): every few
## seconds each figure it looks after lets out a small cloud at the mouth,
## which drifts the way they face, rises a little, spreads and is gone.
##
## It looks after the figures it's given (`who`: Bram in his memory), or
## every figure under `under` (the Ashford world on the morning after the
## fires: Weather turns it `on`), as long as they're on show and within
## REACH of the camera. A handful of small soft shapes a breath, from a few
## emitters taken in turn: nothing a slow machine would notice.

const EVERY := [3.4, 5.0]   # seconds between one figure's breaths
const HARD := [1.5, 2.2]    # ...when they're running
const LIFE := 1.5           # how long a breath hangs
const PUFFS := 6            # soft shapes in one
const SIZE := 0.075         # a shape's width as it leaves the mouth (m); it swells to SWELL times that
const SWELL := 3.4
const OUT := [0.28, 0.5]    # how fast it leaves (m/s)
const RISE := 0.14          # ...and lifts (m/s per s)
const COL := Color(0.96, 0.97, 1.0, 0.16)
const REACH := 34.0         # no breath is drawn for a figure further than this from the camera
const SCAN := 1.0           # seconds between looking for who's about
const POOL := 10

var who: Array = []       # the figures looked after, if set by hand
var under: Node = null    # ...or every figure under this
var on := true
## A wind that carries the breath off as it leaves (m/s per s, flat): the
## storm in Bram's memory takes his away to one side, where it's seen from
## behind him.
var wind := Vector3.ZERO
static var count := 0     # breaths let out, in all (the tests)

var _due := {}            # figure id -> seconds till its next breath
var _found: Array = []
var _scan := 0.0
var _pool: Array = []
var _turn := 0


func _ready() -> void:
	for i in POOL:
		var p := _make()
		add_child(p)
		_pool.append(p)


func _process(delta: float) -> void:
	if not on:
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = SCAN
		_found = who.duplicate() if under == null else []
		if under != null and is_instance_valid(under) and is_inside_tree():
			for f in get_tree().get_nodes_in_group(Figure3D.GROUP):
				if under.is_ancestor_of(f):
					_found.append(f)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	for f in _found:
		if not is_instance_valid(f) or not (f is Figure3D):
			continue
		var fig := f as Figure3D
		var id := fig.get_instance_id()
		if not _due.has(id):
			_due[id] = randf_range(0.2, float(EVERY[1]))   # (not everyone at once)
		_due[id] = float(_due[id]) - delta
		if float(_due[id]) > 0.0:
			continue
		var pace: Array = HARD if fig.walking and fig.gait == "run" else EVERY
		_due[id] = randf_range(float(pace[0]), float(pace[1]))
		if not fig.is_visible_in_tree():
			continue
		if cam != null and cam.global_position.distance_to(fig.global_position) > REACH:
			continue
		_puff(fig)


func _puff(fig: Figure3D) -> void:
	var m: Array = fig.mouth()
	var out: Vector3 = m[1]
	var p: CPUParticles3D = _pool[_turn]
	_turn = (_turn + 1) % _pool.size()
	p.global_position = m[0]
	p.direction = (out + Vector3(0, 0.12, 0)).normalized()
	p.gravity = Vector3(wind.x, RISE, wind.z)
	p.restart()
	p.emitting = true
	count += 1


func _make() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = PUFFS
	p.lifetime = LIFE
	p.explosiveness = 0.45
	p.local_coords = false
	p.spread = 13.0
	p.initial_velocity_min = float(OUT[0])
	p.initial_velocity_max = float(OUT[1])
	p.gravity = Vector3(0, RISE, 0)
	p.damping_min = 0.5
	p.damping_max = 0.8
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.25
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 1.0 / SWELL))
	grow.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = grow
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	p.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(SIZE * SWELL, SIZE * SWELL)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = DuelFX.dot_tex()
	mat.albedo_color = COL
	mat.vertex_color_use_as_albedo = true
	mat.disable_receive_shadows = true
	q.material = mat
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p
