class_name Birds
extends Node3D
## Birds on Ashford's green (12 November, Gary: "3 only", to "birds that fly
## up from the grass when you run near them").
##
## By day a few small flocks of doves stand about on the green's paths
## (in the grass, which is taller than they are, they can't be seen),
## pecking, taking a hop, turning. Anyone who comes at them sends
## the flock up: a runner from REACH_RUN away, a walker from REACH_WALK,
## someone standing only if a bird all but hops onto their boots. They go up
## the way away from whoever it was, each a moment after the next, wings
## going, and are over the rooftops and gone in a few seconds, with the
## sound of it (birds_up). Some while later they come down again somewhere
## clear, near where the camera is looking but not on top of anyone.
##
## The first drops of a shower send them up too, and so does the evening;
## none come down in rain, after dark, on the morning after the fires, or
## into a staged scene. A world that isn't on show is left alone.
##
## The birds are drawn here (a body, a head, a tail, two wings that beat),
## since there is no model of one: at the walking camera's distance a bird
## is a dozen pixels long. Ashford builds this beside its Weather.

const FLOCKS := [1, 2, 3]          # how many flocks, by Gfx.level()
const IN_FLOCK := [3, 5]           # birds in one
const DAY := 0.6                   # AshfordVillage.daylight from this up: day enough for them
const DRY := 0.12                  # Weather.amount under this: no rain to speak of
const SPREAD := 1.0                # how far from the flock's middle a bird stands (m)

const REACH_RUN := 4.6             # a runner this near the flock sends it up (m)
const REACH_WALK := 2.1            # ...a walker
const REACH_STILL := 0.6           # ...someone stood still
const RUN_FROM := 3.0              # this fast is running (m/s)
const WALK_FROM := 0.25            # ...and this, walking
const PLACED := 14.0               # faster than this wasn't moving: they were put there
const CHECK := 0.12                # seconds between one look round and the next

const BACK := [20.0, 46.0]         # seconds until a flock that went up comes down again
const UP_SECS := 3.4               # how long one going up is seen for
const DOWN_SECS := 2.8             # how long one is coming down
const SPEED := [5.4, 7.0]          # how fast they get away (m/s)
const CLIMB := [3.0, 4.2]          # ...and upward
const APART := 0.3                 # the last bird starts this long after the first (s)
const FLAP_HZ := 7.5
const FLAP := 1.15                 # how far a wing goes each way (radians)
const SIZE := [1.15, 1.4]          # (a wood pigeon's size: 35 to 42 cm from beak to tail)
const DOWN_FROM := Vector2(12.0, 8.0)   # where one coming down is first seen: this far back and up

const LAND_VIEW := [5.0, 15.0]     # a flock comes down this far from the spot on screen
const CLEAR_PLAYER := 6.5          # ...and at least this far from the player
const CLEAR_OTHERS := 3.2          # ...and from anyone else
const CLEAR_FLOCK := 7.0           # ...and from another flock
const CLEAR_WALL := 1.6            # ...and from any wall
const LEVEL := 0.05                # the ground under a flock rises no more than this in half a metre
const ON_PATH := 0.4               # ...and is this much path (AshfordVillage.path_at): the grass hides a bird

const DB := -5.0                   # the wings, heard from close by
const HEARD_NEAR := 14.0           # as loud as that within this of the camera (m)
const HEARD_FAR_DB := 18.0         # ...and not at all once this much quieter

var world: World
var village: AshfordVillage
var flocks: Array = []             # of Flock
var went_up := 0                   # flocks sent up, in all (the tests)
var came_down := 0                 # flocks come down, in all
var _check := 0.0
var _was: Dictionary = {}          # each figure's spot at the last look round, by its id
var _placed := false
var _age := 0.0
static var _meshes: Dictionary = {}


## A flock: where it is and what it's doing ("away", "ground", "up", "down").
class Flock:
	var state := "away"
	var at := Vector3.ZERO
	var birds: Array = []
	var t := 0.0               # seconds in this state
	var back_in := 0.0         # seconds until it comes down again (away)


## One bird.
class Bird extends Node3D:
	var size := 1.0
	var home := Vector3.ZERO       # where it stands
	var yaw := 0.0
	var wait := 0.0                # until it starts (up, down)
	var dir := Vector3.FORWARD     # the way it flies
	var speed := 6.0
	var climb := 3.5
	var beat := 0.0                # where its wings are in their stroke
	var next_in := 1.0             # until it next does something (ground)
	var doing := ""                # "peck", "hop", "turn"
	var done := 0.0
	var hop_from := Vector3.ZERO
	var hop_to := Vector3.ZERO
	var turn_to := 0.0
	var wings: Array = []          # [left, right] hinges
	var was := Vector3.ZERO


## The birds of the world `w`, if it has any.
static func of(w: Node) -> Birds:
	return w.get_meta("birds") as Birds if w != null and w.has_meta("birds") else null


func setup(w: World, v: AshfordVillage) -> Birds:
	world = w
	village = v
	return self


func _ready() -> void:
	var count := int(FLOCKS[clampi(Gfx.level(), 0, 2)])
	for i in count:
		var f := Flock.new()
		for k in randi_range(IN_FLOCK[0], IN_FLOCK[1]):
			var b := _make_bird((i + k) % 3)
			b.visible = false
			add_child(b)
			f.birds.append(b)
		f.back_in = randf_range(4.0, 12.0) * (i + 1)
		flocks.append(f)


## How near someone going at `speed` (m/s) may come before a flock goes up.
static func reach_for(speed: float) -> float:
	if speed >= RUN_FROM:
		return REACH_RUN
	return REACH_WALK if speed >= WALK_FROM else REACH_STILL


## Whether this is a time for birds to be on the green at all: the world on
## show, a fair dry day, nothing burning.
func about() -> bool:
	if world == null or village == null or world.attract or world.held or not world.is_visible_in_tree():
		return false
	if Ambience.hush > 0 or village.daylight < DAY or village.time_kind == "dawn" or village.time_kind == "burning" or village.sigil_on:
		return false
	for h: Dictionary in village.houses:
		if h.get("burning", false):
			return false
	var wx := Weather.of(world)
	return wx == null or wx.amount < DRY


## Whether the screen is wholly black (a scene being set behind it).
func _black() -> bool:
	return world.has_meta("cine_overlay") and is_instance_valid(world.get_meta("cine_overlay")) \
			and (world.get_meta("cine_overlay") as CineOverlay).is_black()


func _process(delta: float) -> void:
	if world == null or village == null or world.attract or world.held or not world.is_visible_in_tree():
		return
	var ok := about()
	_age += delta
	# the day's first flocks are already down when the green is first seen
	# (a moment in, so everything solid in the village is there to be asked about)
	if not _placed and ok and world.player != null and _age > 0.5:
		_placed = true
		for f: Flock in flocks:
			var spot := _spot(false)
			if spot != Vector3.INF:
				_settle(f, spot)
	for f: Flock in flocks:
		f.t += delta
		match f.state:
			"ground":
				if not ok:
					send_up(f, Vector3.INF)   # (rain, or the light going: off to roost)
				else:
					for b: Bird in f.birds:
						_idle(b, f, delta)
			"up":
				var left := false
				for b: Bird in f.birds:
					if _rise(b, f.t, delta):
						left = true
				if not left:
					f.state = "away"
					f.t = 0.0
			"down":
				var landing := false
				for b: Bird in f.birds:
					if _descend(b, f.t, delta):
						landing = true
				if not landing:
					f.state = "ground"
					f.t = 0.0
					came_down += 1
			"away":
				f.back_in -= delta
				if f.back_in <= 0.0 and ok and not world.cine and world.player != null:
					var spot := _spot(true)
					if spot == Vector3.INF:
						f.back_in = 3.0   # (nowhere clear just now: look again shortly)
					else:
						_bring_down(f, spot)
	_check -= delta
	if _check <= 0.0:
		_look_round(CHECK - _check)
		_check = CHECK


# ------------------------------------------------------------ who is near ---

## Everyone in the world, how fast each is going, and any flock they're
## near enough to send up.
func _look_round(since: float) -> void:
	var now: Dictionary = {}
	for n in get_tree().get_nodes_in_group(Figure3D.GROUP):
		var fig := n as Node3D
		if fig == null or not fig.is_visible_in_tree() or not world.is_ancestor_of(fig):
			continue
		var at := fig.global_position
		var id := fig.get_instance_id()
		now[id] = at
		if not _was.has(id):
			continue
		var speed := at.distance_to(_was[id]) / maxf(since, 0.001)
		for f: Flock in flocks:
			if f.state != "ground":
				continue
			var far := at.distance_to(f.at)
			if speed > PLACED:
				# (put down on top of them by a scene: they were never there)
				if far < SPREAD + 1.2:
					_vanish(f)
			elif far < reach_for(speed) + SPREAD * 0.5:
				send_up(f, at)
	_was = now


# --------------------------------------------------------------- up, down ---

## The flock goes up, away from `from` (Vector3.INF: any way it likes).
func send_up(f: Flock, from: Vector3) -> void:
	if f.state != "ground":
		return
	if _black():
		_vanish(f)
		return
	var away := Vector3(f.at.x - from.x, 0.0, f.at.z - from.z) if from != Vector3.INF else Vector3.ZERO
	away = away.normalized() if away.length() > 0.05 else Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU)
	var order: Array = f.birds.duplicate()
	if from != Vector3.INF:
		# the nearest to whoever it was goes first
		order.sort_custom(func(a: Bird, b: Bird) -> bool: return a.home.distance_squared_to(from) < b.home.distance_squared_to(from))
	else:
		order.shuffle()
	for i in order.size():
		var b: Bird = order[i]
		b.home = b.global_position
		b.wait = APART * float(i) / maxf(1.0, order.size() - 1.0) + randf_range(0.0, 0.05)
		b.dir = away.rotated(Vector3.UP, randf_range(-0.75, 0.75))
		b.speed = randf_range(SPEED[0], SPEED[1])
		b.climb = randf_range(CLIMB[0], CLIMB[1])
		b.beat = randf() * TAU
		b.doing = ""
		b.was = b.home
	f.state = "up"
	f.t = 0.0
	f.back_in = randf_range(BACK[0], BACK[1])
	went_up += 1
	_heard(f.at)


## The wings, as loud as the flock is near (not at all from indoors).
func _heard(at: Vector3) -> void:
	if world.cam == null or world.cam.global_position.y < World.INDOORS_BELOW:
		return
	var far := world.cam.global_position.distance_to(at)
	var off := 20.0 * log(maxf(far, HEARD_NEAR) / HEARD_NEAR) / log(10.0)
	if off <= HEARD_FAR_DB:
		Sfx.shared().play("birds_up", randf_range(0.94, 1.08), DB - off)


## Gone without being seen to go (a scene set down on top of them).
func _vanish(f: Flock) -> void:
	for b: Bird in f.birds:
		b.visible = false
	f.state = "away"
	f.t = 0.0
	f.back_in = randf_range(BACK[0], BACK[1])


## One bird going up, `t` seconds after its flock went: true while it can
## still be seen.
func _rise(b: Bird, t: float, delta: float) -> bool:
	var u := t - b.wait
	if u <= 0.0:
		return true
	if u >= UP_SECS:
		b.visible = false
		return false
	var along := b.speed * (u - 0.4 * (1.0 - exp(-u / 0.4)))
	var up := b.climb * (u - 0.25 * (1.0 - exp(-u / 0.25)))
	var side := b.dir.cross(Vector3.UP)
	var p := b.home + b.dir * along + Vector3.UP * up + side * (0.22 * sin(u * 2.3 + b.beat))
	_fly(b, p, delta, 1.0 - smoothstep(UP_SECS - 0.5, UP_SECS, u))
	return true


## One bird coming down: true until it is on the ground.
func _descend(b: Bird, t: float, delta: float) -> bool:
	var u := t - b.wait
	if u <= 0.0:
		return true
	var k := clampf(u / DOWN_SECS, 0.0, 1.0)
	if k >= 1.0:
		_stand(b)
		return false
	var from := b.home - b.dir * DOWN_FROM.x + Vector3.UP * DOWN_FROM.y
	var e := 1.0 - (1.0 - k) * (1.0 - k)
	var p := Vector3(lerpf(from.x, b.home.x, e), b.home.y + DOWN_FROM.y * pow(1.0 - k, 1.7), lerpf(from.z, b.home.z, e))
	b.visible = true
	_fly(b, p, delta, smoothstep(0.0, 0.45, u))
	return true


## A bird in the air at `p`: turned the way it's going, wings beating.
func _fly(b: Bird, p: Vector3, delta: float, shown: float) -> void:
	var going := p - b.was
	b.was = p
	b.global_position = p
	if going.length() > 0.0005:
		var flat := Vector3(going.x, 0.0, going.z)
		# (level-bodied, nose a little up or down with the climb)
		var aim := (flat.normalized() + Vector3.UP * clampf(going.y / maxf(flat.length(), 0.001), -0.6, 0.6) * 0.5).normalized() if flat.length() > 0.0001 else b.dir
		b.global_basis = Basis.looking_at(aim, Vector3.UP).scaled(Vector3.ONE * maxf(0.001, b.size * shown))
	b.beat += delta * TAU * FLAP_HZ
	var a := sin(b.beat) * FLAP + 0.25
	for w: Node3D in b.wings:
		w.visible = true
	(b.wings[0] as Node3D).rotation.z = -a
	(b.wings[1] as Node3D).rotation.z = a


## A bird on the ground at its place, wings shut.
func _stand(b: Bird) -> void:
	b.visible = true
	b.global_position = b.home
	b.yaw = atan2(-b.dir.x, -b.dir.z)
	b.global_basis = Basis(Vector3.UP, b.yaw).scaled(Vector3.ONE * b.size)
	for w: Node3D in b.wings:
		w.visible = false
	b.doing = ""
	b.next_in = randf_range(0.3, 2.0)


## The flock stood at `spot` from the start (the green's first sight).
func _settle(f: Flock, spot: Vector3) -> void:
	_places(f, spot)
	for b: Bird in f.birds:
		b.dir = Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU)
		_stand(b)
	f.state = "ground"
	f.t = 0.0


## The flock comes down at `spot`.
func _bring_down(f: Flock, spot: Vector3) -> void:
	_places(f, spot)
	# in over the camera's shoulder, more or less: they come down into the picture
	var into := Vector3(1, 0, 0).rotated(Vector3.UP, randf() * TAU)
	if world.cam != null:
		var fwd := -world.cam.global_basis.z
		fwd.y = 0.0
		if fwd.length() > 0.05:
			into = fwd.normalized().rotated(Vector3.UP, randf_range(-0.9, 0.9))
	for i in f.birds.size():
		var b: Bird = f.birds[i]
		b.dir = into.rotated(Vector3.UP, randf_range(-0.2, 0.2))
		b.wait = randf_range(0.0, APART * 2.0)
		b.beat = randf() * TAU
		b.was = b.home - b.dir * DOWN_FROM.x + Vector3.UP * DOWN_FROM.y
		b.visible = false
	f.state = "down"
	f.t = 0.0


## A place for each bird of the flock round `spot`, on the ground as drawn.
func _places(f: Flock, spot: Vector3) -> void:
	f.at = spot
	for i in f.birds.size():
		var b: Bird = f.birds[i]
		var off := Vector2.from_angle(TAU * float(i) / f.birds.size() + randf_range(-0.5, 0.5)) * randf_range(0.3, SPREAD)
		b.home = Vector3(spot.x + off.x, village.ground_y(spot.x + off.x, spot.z + off.y), spot.z + off.y)


# ---------------------------------------------------------- on the ground ---

## What a bird does with its time: a peck, a hop, a turn of the head.
func _idle(b: Bird, f: Flock, delta: float) -> void:
	if b.doing == "":
		b.next_in -= delta
		if b.next_in > 0.0:
			return
		var pick := randf()
		b.done = 0.0
		if pick < 0.55:
			b.doing = "peck"
		elif pick < 0.85:
			b.doing = "hop"
			var to := Vector2.from_angle(randf() * TAU) * randf_range(0.15, 0.4)
			var want := Vector3(b.home.x + to.x, 0.0, b.home.z + to.y)
			# (it keeps to its flock)
			var out := Vector2(want.x - f.at.x, want.z - f.at.z)
			if out.length() > SPREAD:
				out = out.normalized() * SPREAD
				want = Vector3(f.at.x + out.x, 0.0, f.at.z + out.y)
			want.y = village.ground_y(want.x, want.z)
			b.hop_from = b.home
			b.hop_to = want
			b.yaw = atan2(-(want.x - b.home.x), -(want.z - b.home.z))
		else:
			b.doing = "turn"
			b.turn_to = b.yaw + randf_range(-1.6, 1.6)
		return
	b.done += delta
	var lean := 0.0
	match b.doing:
		"peck":
			var k := b.done / 0.34
			lean = sin(clampf(k, 0.0, 1.0) * PI) * 0.75
			if k >= 1.0:
				b.doing = ""
				b.next_in = randf_range(0.15, 1.6) if randf() < 0.5 else randf_range(1.2, 3.2)
		"hop":
			var k := clampf(b.done / 0.2, 0.0, 1.0)
			b.home = b.hop_from.lerp(b.hop_to, k)
			b.global_position = b.home + Vector3.UP * (sin(k * PI) * 0.05)
			if k >= 1.0:
				b.doing = ""
				b.next_in = randf_range(0.2, 2.2)
		"turn":
			var k := clampf(b.done / 0.16, 0.0, 1.0)
			b.yaw = lerp_angle(b.yaw, b.turn_to, k)
			if k >= 1.0:
				b.doing = ""
				b.next_in = randf_range(0.4, 2.6)
	b.global_basis = (Basis(Vector3.UP, b.yaw) * Basis(Vector3.RIGHT, -lean)).scaled(Vector3.ONE * b.size)


# ------------------------------------------------------------------ where ---

## Somewhere a flock can stand: level ground on one of the green's paths, clear of
## walls, of anything solid, of the player and everyone else and of the
## other flocks; `in_view` asks for it near the spot on screen too.
## Vector3.INF if there's nowhere.
func _spot(in_view: bool) -> Vector3:
	var mid := Weather.FIREFLY_MID
	var reach := Weather.FIREFLY_REACH * 0.8
	var look := world.cam_ground() if world.cam != null else Vector3.ZERO
	var floor_y := village.ground_y(mid.x, mid.y)
	var people: Array = []
	for n in get_tree().get_nodes_in_group(Figure3D.GROUP):
		if n is Node3D and world.is_ancestor_of(n) and (n as Node3D).is_visible_in_tree():
			people.append((n as Node3D).global_position)
	var player := world.player.global_position if world.player != null else Vector3.INF
	for attempt in 40:
		var at: Vector2
		if in_view:
			at = Vector2(look.x, look.z) + Vector2.from_angle(randf() * TAU) * randf_range(LAND_VIEW[0], LAND_VIEW[1])
			if absf(at.x - mid.x) > reach.x or absf(at.y - mid.y) > reach.y:
				continue
		else:
			var far := sqrt(randf())
			var a := randf() * TAU
			at = mid + Vector2(cos(a) * far * reach.x, sin(a) * far * reach.y)
		if village.path_at(at.x, at.y) < ON_PATH:
			continue
		var y := village.ground_y(at.x, at.y)
		if absf(y - floor_y) > 1.0:
			continue
		if absf(village.ground_y(at.x + 0.6, at.y) - y) > LEVEL or absf(village.ground_y(at.x - 0.6, at.y) - y) > LEVEL \
				or absf(village.ground_y(at.x, at.y + 0.6) - y) > LEVEL or absf(village.ground_y(at.x, at.y - 0.6) - y) > LEVEL:
			continue
		var spot := Vector3(at.x, y, at.y)
		var clear := true
		for fp in village.footprints:
			if at.distance_to(fp[0]) < float(fp[1]) + CLEAR_WALL:
				clear = false
				break
		if clear and player != Vector3.INF and spot.distance_to(player) < (CLEAR_PLAYER if in_view else CLEAR_PLAYER + 2.5):
			clear = false
		if clear:
			for p: Vector3 in people:
				if spot.distance_to(p) < CLEAR_OTHERS:
					clear = false
					break
		if clear:
			for f: Flock in flocks:
				if f.state != "away" and f.at.distance_to(spot) < CLEAR_FLOCK:
					clear = false
					break
		if clear and not _open(spot):
			clear = false
		if clear:
			return spot
	return Vector3.INF


## Nothing solid standing where a flock would (a stall, the well, a cart, a
## post): asked of the world's own colliders, a little above the ground.
func _open(spot: Vector3) -> bool:
	if not is_inside_tree() or get_world_3d() == null:
		return true
	var ball := SphereShape3D.new()
	ball.radius = SPREAD + 0.35
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = ball
	q.transform = Transform3D(Basis.IDENTITY, spot + Vector3.UP * (ball.radius + 0.3))
	q.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


# -------------------------------------------------------------- the birds ---

func _make_bird(kind: int) -> Bird:
	var b := Bird.new()
	b.size = randf_range(SIZE[0], SIZE[1])
	var body := MeshInstance3D.new()
	body.mesh = _mesh("body%d" % kind)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	b.add_child(body)
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		hinge.position = Vector3(0.04 * side, 0.115, -0.01)
		var wing := MeshInstance3D.new()
		wing.mesh = _mesh(("left%d" if side < 0.0 else "wing%d") % kind)
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		hinge.add_child(wing)
		hinge.visible = false
		b.add_child(hinge)
		b.wings.append(hinge)
	return b


## The three kinds' colours: [body, head, wing, wing's tip, tail, beak].
const KINDS := [
	[Color(0.66, 0.67, 0.71), Color(0.5, 0.52, 0.6), Color(0.58, 0.59, 0.64), Color(0.24, 0.25, 0.3), Color(0.3, 0.31, 0.36), Color(0.78, 0.6, 0.35)],
	[Color(0.92, 0.91, 0.87), Color(0.94, 0.93, 0.9), Color(0.88, 0.87, 0.84), Color(0.62, 0.62, 0.63), Color(0.82, 0.81, 0.78), Color(0.8, 0.55, 0.4)],
	[Color(0.8, 0.74, 0.68), Color(0.76, 0.7, 0.66), Color(0.7, 0.63, 0.57), Color(0.36, 0.31, 0.28), Color(0.5, 0.45, 0.41), Color(0.5, 0.42, 0.36)],
]


## A dove about 30 cm long, beak towards -Z, feet at the origin ("body0");
## or one of its wings, hinged at the origin and reaching out along +X
## ("wing0") or -X ("left0"). The number is the kind (KINDS).
static func _mesh(what: String) -> ArrayMesh:
	if _meshes.has(what):
		return _meshes[what]
	var kind := int(what.right(1))
	var cols: Array = KINDS[kind]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if what.begins_with("body"):
		_ball(st, Vector3(0, 0.095, 0.0), Vector3(0.055, 0.058, 0.105), cols[0], cols[2])
		_ball(st, Vector3(0, 0.158, -0.082), Vector3(0.036, 0.036, 0.04), cols[1], cols[1])
		# beak
		var tip := Vector3(0, 0.15, -0.15)
		for tri: Array in [[Vector3(-0.012, 0.158, -0.115), Vector3(0.012, 0.158, -0.115)], [Vector3(0.012, 0.158, -0.115), Vector3(0, 0.144, -0.115)], [Vector3(0, 0.144, -0.115), Vector3(-0.012, 0.158, -0.115)]]:
			_tri(st, tri[0], tri[1], tip, cols[5])
		# tail: a flat fan behind
		var root_l := Vector3(-0.03, 0.1, 0.085)
		var root_r := Vector3(0.03, 0.1, 0.085)
		var end_l := Vector3(-0.045, 0.085, 0.2)
		var end_r := Vector3(0.045, 0.085, 0.2)
		_tri(st, root_l, end_l, root_r, cols[4])
		_tri(st, root_r, end_l, end_r, cols[4])
	else:
		# a wing: broad at the body, a dark pointed tip (the left one the
		# right one's mirror)
		var out := -1.0 if what.begins_with("left") else 1.0
		var a := Vector3(0.0, 0.0, -0.055)
		var b := Vector3(0.0, 0.0, 0.065)
		var c := Vector3(0.17 * out, 0.0, -0.065)
		var d := Vector3(0.16 * out, 0.0, 0.06)
		var e := Vector3(0.31 * out, 0.0, 0.01)
		_tri(st, a, b, c, cols[2])
		_tri(st, c, b, d, cols[2])
		_tri(st, c, d, e, cols[3])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	var m := st.commit()
	_meshes[what] = m
	return m


## A flat-coloured triangle, lit as if it faced up.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
	for p: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.set_color(col)
		st.add_vertex(p)


## A rounded shape (the body, the head): `top` over its back, `under` below.
static func _ball(st: SurfaceTool, mid: Vector3, r: Vector3, under: Color, top: Color) -> void:
	var rings := 5
	var segs := 8
	for i in rings:
		var a0 := PI * float(i) / rings
		var a1 := PI * float(i + 1) / rings
		for k in segs:
			var b0 := TAU * float(k) / segs
			var b1 := TAU * float(k + 1) / segs
			var quad: Array = []
			for pair: Array in [[a0, b0], [a1, b0], [a1, b1], [a0, b1]]:
				var u := Vector3(sin(pair[0]) * cos(pair[1]), cos(pair[0]), sin(pair[0]) * sin(pair[1]))
				quad.append(u)
			for idx: int in [0, 2, 1, 0, 3, 2]:
				var u: Vector3 = quad[idx]
				st.set_normal((u / r).normalized())
				st.set_color(top if u.y > 0.25 else under)
				st.add_vertex(mid + u * r)
