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
var grip := Vector2i(1, 15)   # the gripped corner: row (from the hem) and column (the near edge)
var secs := 1.2               # how long the throw takes with the corner held
var t := 0.0                  # the throw's progress, 0 as laid .. 1 in the heap
var _pull := 1.0              # how much the hand's pull still counts (fades once let go)
var _held := true
var _done := false
var _last_hand := Vector3.ZERO
const HELD_TO := 0.8          # how far the throw gets with the corner still held
const REACH := 0.75           # m: how far from the corner the hand's pull is felt


## The corner of the hem the hand takes, in the world.
static func corner_of(blanket: MeshInstance3D, row := 1, col := 15) -> Vector3:
	var r: Array = blanket.get_meta("rows")
	return blanket.global_transform * ((r[row] as Array)[col] as Vector3)


## Where that corner ends up in the heap, in the world (for the hand's sweep).
static func corner_in_heap(blanket: MeshInstance3D, off: Transform3D, row := 1, col := 15) -> Vector3:
	var r: Array = blanket.get_meta("rows")
	return off * ((r[row] as Array)[col] as Vector3)


static func start(blanket: MeshInstance3D, off: Transform3D, hand: Node3D, secs := 1.2) -> BlanketThrow:
	var bt := BlanketThrow.new()
	bt.mi = blanket
	bt.rows = blanket.get_meta("rows")
	bt.heap = blanket.transform.affine_inverse() * off
	bt.hand = hand
	bt.secs = secs
	bt._last_hand = blanket.to_local(hand.global_position)
	blanket.add_child(bt)
	return bt


func let_go() -> void:
	_held = false
	hand = null


## Puts the blanket back over the sleeper as it was laid (a new game, or
## the opening played again).
static func reset(blanket: MeshInstance3D) -> void:
	for c in blanket.get_children():
		if c is BlanketThrow:
			c.queue_free()
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
	var nx := rows.size()
	var nz := (rows[0] as Array).size()
	var g_on: Vector3 = (rows[grip.x] as Array)[grip.y]
	var g_heap: Vector3 = heap * g_on
	var drag := _last_hand - g_on.lerp(g_heap, _stage(grip.x, grip.y, nx, nz))
	var pts: Array = []
	for i in nx:
		var row: Array = rows[i]
		var out: Array = []
		for j in nz:
			var p: Vector3 = row[j]
			var s := _stage(i, j, nx, nz)
			var at := p.lerp(heap * p, s)
			# the hand's pull on the cloth near the corner it holds
			var w := smoothstep(REACH, 0.0, p.distance_to(g_on)) * _pull
			out.append(at + drag * w)
		pts.append(out)
	mi.mesh = InnRooms._blanket_mesh_of(pts)
	if t >= 1.0 and _pull <= 0.0:
		_done = true
		queue_free()


## How far along its way this point is: the near edge (high column) and
## the hem (low row) move first, the far edge last, each over 0.35 of the
## throw.
func _stage(i: int, j: int, nx: int, nz: int) -> float:
	var v := float(j) / float(nz - 1)      # 0 far edge .. 1 near edge
	var u := float(i) / float(nx - 1)      # 0 hem .. 1 foot
	var delay := 0.55 * (1.0 - v) + 0.1 * u
	return smoothstep(delay, delay + 0.35, t)
