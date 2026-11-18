class_name BlanketThrow
extends Node
## The attic blanket thrown back by the sleeper's own hand (Gary, 23
## October: "bed sheets move on their own"). The blanket keeps its grid of
## points as laid over him (InnRooms._blanket_points); while a hand has hold
## of the hem's near corner the cloth follows it, that corner on the hand
## and the rest dragged after it, each point on its own way from where it
## lay to its place in the heap against the wall (the bed's blanket_off),
## the near edge first and the far edge last. Let go, what's left settles
## into the heap. The mesh is built again each frame (26 x 16 quads).
##   var bt := BlanketThrow.start(blanket, hand)   # the hand node at the corner
##   ... (tween the hand across the bed) ...
##   bt.let_go()                                    # the rest settles; done in half a second

var mi: MeshInstance3D
var rows: Array = []          # the points as laid (local to the blanket)
var heap: Transform3D         # local: a point as laid -> in the heap
var hand: Node3D = null       # the hand holding the corner (null once let go)
var grip := Vector2i(1, 15)   # the gripped corner: row (from the hem) and column (the near edge); of a 26 by 16 blanket (grip_of)
var secs := 1.2               # how long the throw takes with the corner held
var t := 0.0                  # the throw's progress, 0 as laid .. 1 in the heap
var _pull := 1.0              # how much the hand's pull still counts (fades once let go)
var _held := true
var _done := false
var _last_hand := Vector3.ZERO
const HELD_TO := 0.8          # how far the throw gets with the corner still held
const REACH := 0.75           # m: how far from the corner the hand's pull is felt


## Which point of a blanket's grid the hand takes: a square in from the hem
## and from the near edge on the blanket as it was (26 by 16 squares), and
## the same place on a finer one (18 November: BlanketDrape's is 52 by 32).
static func grip_of(r: Array, row := 1, col := 15) -> Vector2i:
	var nx := r.size() - 1
	var nz := (r[0] as Array).size() - 1
	return Vector2i(clampi(roundi(row * nx / 26.0), 0, nx), clampi(roundi(col * nz / 16.0), 0, nz))


## The corner of the hem the hand takes, in the world.
static func corner_of(blanket: MeshInstance3D, row := 1, col := 15) -> Vector3:
	var r: Array = blanket.get_meta("rows")
	var g := grip_of(r, row, col)
	return blanket.global_transform * ((r[g.x] as Array)[g.y] as Vector3)


## Where that corner ends up in the heap, in the world (for the hand's sweep).
static func corner_in_heap(blanket: MeshInstance3D, off: Transform3D, row := 1, col := 15) -> Vector3:
	var r: Array = heap_rows(blanket)
	var g := grip_of(r, row, col)
	return off * ((r[g.x] as Array)[g.y] as Vector3)


static var _plain := {}

## The blanket's points as they go into the heap (before the heap's own
## squash and place): laid by rule, as it always was, not over him (18
## November: laid over him it has his shape in it, his legs and his boots,
## and a heap by the wall with his legs in it isn't a heap), at the size of
## grid it has now.
static func heap_rows(blanket: MeshInstance3D) -> Array:
	var r: Array = blanket.get_meta("rows")
	var nx := r.size() - 1
	var nz := (r[0] as Array).size() - 1
	var key := Vector2i(nx, nz)
	if not _plain.has(key):
		_plain[key] = InnRooms._blanket_points(InnRooms.BLANKET_L, float(blanket.get_meta("width", 0.96)), nx, nz)
	return _plain[key]


static func start(blanket: MeshInstance3D, off: Transform3D, hand: Node3D, secs := 1.2) -> BlanketThrow:
	var bt := BlanketThrow.new()
	bt.mi = blanket
	bt.rows = blanket.get_meta("rows")
	# (16 November) lifted over an arm (BlanketTent): thrown from where it lies
	var tent := BlanketTent.on(blanket)
	if tent != null:
		bt.rows = tent.points()
		tent.stop(true)
	bt.heap = blanket.transform.affine_inverse() * off
	bt.hand = hand
	bt.secs = secs
	bt._last_hand = blanket.to_local(hand.global_position)
	bt._ready_points(blanket)
	blanket.add_child(bt)
	return bt


## Everything about each point that doesn't change through the throw, worked
## out once (18 November: four times the points): where it lies, where it
## ends in the heap, when it sets off, how much of the hand's pull it feels,
## and how deep in a fold it lay.
var _npx := 0
var _npz := 0
var _on := PackedVector3Array()
var _to := PackedVector3Array()
var _delay := PackedFloat32Array()
var _feel := PackedFloat32Array()
var _shade := PackedFloat32Array()
var _g := 0

func _ready_points(blanket: MeshInstance3D) -> void:
	_npx = rows.size()
	_npz = (rows[0] as Array).size()
	grip = grip_of(rows)
	_g = grip.x * _npz + grip.y
	_on = BlanketDrape.flat(rows)
	var into: Array = heap_rows(blanket)
	_to = BlanketDrape.flat(into)
	if _to.size() != _on.size():
		_to = _on.duplicate()
	var n := _on.size()
	_delay.resize(n)
	_feel.resize(n)
	var g_on := _on[_g]
	for i in _npx:
		for j in _npz:
			var k := i * _npz + j
			_to[k] = heap * _to[k]
			_delay[k] = _delay_of(i, j, _npx, _npz)
			_feel[k] = smoothstep(REACH, 0.0, _on[k].distance_to(g_on))
	_shade = BlanketDrape.shade_of(blanket, n)


func let_go() -> void:
	_held = false
	hand = null


## Puts the blanket back over the sleeper as it was laid (a new game, or
## the opening played again).
static func reset(blanket: MeshInstance3D) -> void:
	for c in blanket.get_children():
		if c is BlanketThrow:
			c.queue_free()
		elif c is BlanketTent:
			(c as BlanketTent).stop()
	if blanket.has_meta("mesh_on"):
		blanket.mesh = blanket.get_meta("mesh_on")


func _process(dt: float) -> void:
	if _done or mi == null or not is_instance_valid(mi):
		return
	if _held:
		t = minf(HELD_TO, t + dt / secs)
		if hand != null and is_instance_valid(hand):
			_last_hand = mi.to_local(hand.global_position)
	else:
		t = minf(1.0, t + dt / 0.5)
		_pull = maxf(0.0, _pull - dt / 0.35)
	var n := _on.size()
	var gs := smoothstep(_delay[_g], _delay[_g] + 0.35, t)
	var drag := (_last_hand - _on[_g].lerp(_to[_g], gs)) * _pull
	var pts := PackedVector3Array()
	pts.resize(n)
	var shade := PackedFloat32Array()
	var shaded := _shade.size() == n
	if shaded:
		shade.resize(n)
	for k in n:
		var s := smoothstep(_delay[k], _delay[k] + 0.35, t)
		# its own way from where it lay to the heap, and the hand's pull
		# on the cloth near the corner it holds
		pts[k] = _on[k].lerp(_to[k], s) + drag * _feel[k]
		if shaded:
			# (the folds it lay in go out of it as it goes)
			shade[k] = lerpf(_shade[k], 1.0, s)
	mi.mesh = BlanketDrape.mesh_of(pts, _npx, _npz, shade)
	if t >= 1.0 and _pull <= 0.0:
		_done = true
		queue_free()


## When this point sets off (as a share of the throw): the near edge (high
## column) and the hem (low row) first, the far edge last, each on its way
## for 0.35 of the throw.
static func _delay_of(i: int, j: int, nx: int, nz: int) -> float:
	var v := float(j) / float(nz - 1)      # 0 far edge .. 1 near edge
	var u := float(i) / float(nx - 1)      # 0 hem .. 1 foot
	return 0.55 * (1.0 - v) + 0.1 * u
