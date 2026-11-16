class_name BlanketTent
extends Node
## The attic blanket lifted over an arm that moves under it (16 November,
## Gary: "When player puts hand to neck in bed his hand goes through the
## bed"). Asleep, the hero's arms lie under the blanket at his sides; when
## his left hand went up to his neck, where the mark had been, it came up
## through the blanket, which lay as it was. Now, while it's there, the
## cloth is lifted over the arm wherever the arm is under it (the upper
## arm, the forearm, the hand: each a round bar as thick as it, read from
## the skeleton as it's drawn, the reach included), draped down either side
## of it, so the hand slides up under the blanket and out over its hem, and
## back. Stopped, the blanket lies as it was laid.
##   var t := BlanketTent.start(blanket, fig, "left")
##   ... (the arm moves) ...
##   t.stop()

var mi: MeshInstance3D
var fig: Figure3D
var side := "left"
var rows: Array = []      # the points as laid (the blanket's own frame)
var _segs: Array = []     # [from, to, radius] in the blanket's frame, as drawn
var lifted := 0.0         # how far the cloth is lifted at most, this frame (m; the tests read it)
var k := 0.0              # how much of the lift there is (eased in as it starts)
var _last: Array = []     # the points as last draped
## How thick each part of the arm is (m, its radius) and how far clear of it
## the cloth lies; how steeply the cloth falls away beside it (m down per m out).
const RADII := [0.05, 0.042, 0.036]
const CLEAR := 0.012
const DRAPE := 0.85
## How softly the lifted cloth meets the cloth as it lay (m).
const SOFT := 0.02


static func start(blanket: MeshInstance3D, p_fig: Figure3D, p_side := "left") -> BlanketTent:
	var t := BlanketTent.new()
	t.mi = blanket
	t.fig = p_fig
	t.side = p_side
	t.rows = blanket.get_meta("rows")
	blanket.add_child(t)
	if p_fig._skel != null:
		p_fig._skel.skeleton_updated.connect(t._on_skel)
	# (eased in: asleep, the hand by his side already sits up in the cloth a
	# little, and the cloth shouldn't jump onto it)
	t.create_tween().tween_property(t, "k", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	return t


## The blanket's tent over the arm, if there is one.
static func on(blanket: Node) -> BlanketTent:
	if blanket == null or not is_instance_valid(blanket):
		return null
	for c in blanket.get_children():
		if c is BlanketTent and not c.is_queued_for_deletion():
			return c
	return null


## Done: the blanket as it was laid (`keep`: as it lies now, for the throw
## that takes it from here: BlanketThrow.start takes its points).
func stop(keep := false) -> void:
	if fig != null and is_instance_valid(fig) and fig._skel != null and fig._skel.skeleton_updated.is_connected(_on_skel):
		fig._skel.skeleton_updated.disconnect(_on_skel)
	if not keep and mi != null and is_instance_valid(mi) and mi.has_meta("mesh_on"):
		mi.mesh = mi.get_meta("mesh_on")
	queue_free()


## Where the cloth's points are now (the blanket's frame), as laid if it
## hasn't been draped yet.
func points() -> Array:
	return _last if not _last.is_empty() else rows


func _exit_tree() -> void:
	if fig != null and is_instance_valid(fig) and fig._skel != null and fig._skel.skeleton_updated.is_connected(_on_skel):
		fig._skel.skeleton_updated.disconnect(_on_skel)


## The arm as it's drawn this frame (inside the skeleton's update, after
## every reach), then the cloth over it.
func _on_skel() -> void:
	if mi == null or not is_instance_valid(mi) or not mi.is_inside_tree():
		return
	var sk := fig._skel
	var pre := "Left" if side == "left" else "Right"
	var at := func(b: String) -> Vector3:
		var i := sk.find_bone(pre + b)
		return mi.to_local(sk.global_transform * sk.get_bone_global_pose(i).origin) if i >= 0 else Vector3.INF
	var sh: Vector3 = at.call("Arm")
	var el: Vector3 = at.call("ForeArm")
	var wr: Vector3 = at.call("Hand")
	if sh == Vector3.INF or el == Vector3.INF or wr == Vector3.INF:
		return
	var tip: Vector3 = at.call("HandMiddle2")
	if tip == Vector3.INF:
		tip = at.call("HandIndex1")
	if tip == Vector3.INF:
		tip = wr + (wr - el).normalized() * 0.06
	else:
		tip = wr + (tip - wr) * 1.5   # (on past the knuckles to the fingers' ends)
	_segs = [[sh, el, RADII[0]], [el, wr, RADII[1]], [wr, tip, RADII[2]]]
	_drape()


func _drape() -> void:
	lifted = 0.0
	var pts: Array = []
	for row in rows:
		var out: Array = []
		for p in row:
			var q: Vector3 = p
			var need := -INF
			for sg in _segs:
				var a: Vector3 = sg[0]
				var b: Vector3 = sg[1]
				var r: float = sg[2]
				var ab := Vector2(b.x - a.x, b.z - a.z)
				var t := 0.0
				if ab.length_squared() > 1e-8:
					t = clampf(Vector2(q.x - a.x, q.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
				var c := a.lerp(b, t)
				var dh := Vector2(q.x - c.x, q.z - c.z).length()
				need = maxf(need, c.y + r + CLEAR - DRAPE * maxf(0.0, dh - r * 0.5))
			if need > q.y - SOFT:
				# (a soft maximum of the two: the cloth eases up onto the arm)
				var hk := clampf(0.5 + 0.5 * (need - q.y) / SOFT, 0.0, 1.0)
				var y := lerpf(q.y, need, hk) + SOFT * hk * (1.0 - hk)
				y = lerpf(q.y, y, k)
				lifted = maxf(lifted, y - q.y)
				q.y = y
			out.append(q)
		pts.append(out)
	_last = pts
	mi.mesh = InnRooms._blanket_mesh_of(pts)
