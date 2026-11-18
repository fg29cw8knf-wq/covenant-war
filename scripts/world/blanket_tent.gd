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
## (18 November: laid over him as he lies, BlanketDrape, the cloth has his
## arm's shape in it where the arm lay. These are its points as it would lie
## without that arm under it: what the cloth is lifted from, wherever the arm
## is now, so no empty ridge stays behind as the hand goes to his neck. The
## same as `rows` on a blanket laid by rule.)
var free: Array = []
var _npx := 0
var _npz := 0
var _laid := PackedVector3Array()
var _free := PackedVector3Array()
var _shade := PackedFloat32Array()
var _segs_was: Array = []
var _segs: Array = []     # [from, to, radius] in the blanket's frame, as drawn
var lifted := 0.0         # how far the cloth is lifted at most, this frame (m; the tests read it)
var k := 0.0              # how much of the lift there is (eased in as it starts)
var _last: Array = []     # the points as last draped
## How thick each part of the arm is (m, its radius) and how far clear of it
## the cloth lies; how steeply the cloth falls away beside it (m down per m out).
## (18 November, Gary: "Still looks weird when player puts his hand to neck
## and back and his arm goes through the blanket". These three were a bare
## arm's, guessed: 5, 4.2 and 3.6 cm. Player A's arm is in a loose shirt, its
## sleeve rolled above the elbow: measured off his model, the upper arm with
## its sleeve is 7 to 9 cm from its bone, the forearm 5.5 to 8, the hand 5 to
## 7 across the palm and thumb. So the cloth was lifted to two-thirds of the
## arm's real height and the sleeve came up through it all the way along.
## Now each part's thickness is measured off the figure's own model
## (radii_of: once a model), and these are only the least they can be.)
const RADII := [0.05, 0.042, 0.036]
const RADII_MOST := [0.12, 0.1, 0.085]
const CLEAR := 0.012
const DRAPE := 0.85
## How much of a part's skin lies within the thickness taken for it (the
## rest: a cuff's edge, a thumb held out, a stray fold).
const RADII_SHARE := 0.95
var radii: Array = RADII
static var _radii_by := {}
## How softly the lifted cloth meets the cloth as it lay (m).
const SOFT := 0.02


static func start(blanket: MeshInstance3D, p_fig: Figure3D, p_side := "left") -> BlanketTent:
	var t := BlanketTent.new()
	t.mi = blanket
	t.fig = p_fig
	t.side = p_side
	t.rows = blanket.get_meta("rows")
	t.free = blanket.get_meta("rows_free", t.rows) if p_side == "left" else t.rows
	if t.free.size() != t.rows.size():
		t.free = t.rows
	t._npx = t.rows.size()
	t._npz = (t.rows[0] as Array).size()
	t._laid = BlanketDrape.flat(t.rows)
	t._free = BlanketDrape.flat(t.free)
	t._shade = BlanketDrape.shade_of(blanket, t._laid.size())
	t.radii = radii_of(p_fig, p_side)
	blanket.add_child(t)
	if p_fig._skel != null:
		p_fig._skel.skeleton_updated.connect(t._on_skel)
	# (eased in: asleep, the hand by his side already sits up in the cloth a
	# little, and the cloth shouldn't jump onto it)
	t.create_tween().tween_property(t, "k", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	return t


## How thick the three parts of a figure's arm are (m: the upper arm, the
## forearm, the hand), sleeve and all: off the model's own skin as it was
## bound, each point that a part's bone moves most measured from that bone's
## line, the thickness that takes in RADII_SHARE of them (never under RADII,
## nor over RADII_MOST). Kept for each model and side.
static func radii_of(fig: Figure3D, side: String) -> Array:
	var key := "%s:%s" % [fig._model_name, side]
	if _radii_by.has(key):
		return _radii_by[key]
	var out: Array = RADII.duplicate()
	_radii_by[key] = out
	var sk := fig._skel
	if sk == null or fig.model == null:
		return out
	var src: MeshInstance3D = null
	for n in fig.model.find_children("*", "MeshInstance3D", true, false):
		var c := n as MeshInstance3D
		if c.skin != null and c.mesh != null and c.mesh.get_surface_count() > 0 and c.name != "SealMarkSkin":
			src = c
			break
	if src == null:
		return out
	var pre := "Left" if side == "left" else "Right"
	var tip := sk.find_bone(pre + "HandMiddle2")
	if tip < 0:
		tip = sk.find_bone(pre + "HandIndex1")
	var ends := [[sk.find_bone(pre + "Arm"), sk.find_bone(pre + "ForeArm")], [sk.find_bone(pre + "ForeArm"), sk.find_bone(pre + "Hand")], [sk.find_bone(pre + "Hand"), tip]]
	for e: Array in ends:
		if int(e[0]) < 0 or int(e[1]) < 0:
			return out
	# each bind of the skin: which part it moves (-1: none), and what takes a
	# point of the mesh to the skeleton's own space as it rests
	var part_of: Array = []
	var to_rest: Array = []
	for i in src.skin.get_bind_count():
		var nm := String(src.skin.get_bind_name(i))
		var bone := sk.find_bone(nm) if nm != "" else src.skin.get_bind_bone(i)
		var part := -1
		if bone >= 0:
			var bn := sk.get_bone_name(bone)
			if bn == pre + "Arm":
				part = 0
			elif bn == pre + "ForeArm":
				part = 1
			elif bn.begins_with(pre + "Hand"):
				part = 2
		part_of.append(part)
		to_rest.append(sk.get_bone_global_rest(bone) * src.skin.get_bind_pose(i) if bone >= 0 else Transform3D.IDENTITY)
	var arr := src.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bones = arr[Mesh.ARRAY_BONES]
	var weights = arr[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty() or bones == null or weights == null:
		return out
	var per := int(bones.size() / verts.size())
	var far: Array = [[], [], []]
	for vi in verts.size():
		# the bind that moves it most
		var best := 0
		for j in range(1, per):
			if weights[vi * per + j] > weights[vi * per + best]:
				best = j
		var bi: int = bones[vi * per + best]
		if bi < 0 or bi >= part_of.size() or int(part_of[bi]) < 0:
			continue
		var part: int = part_of[bi]
		var p: Vector3 = (to_rest[bi] as Transform3D) * verts[vi]
		var a := sk.get_bone_global_rest(int(ends[part][0])).origin
		var b := sk.get_bone_global_rest(int(ends[part][1])).origin
		var ab := b - a
		var u := (p - a).dot(ab) / maxf(ab.length_squared(), 0.000001)
		# (a hand's fingers and thumb run on past its line's end: along the line, not from its end)
		if u < -0.1 or (u > 1.1 and part < 2):
			continue
		(far[part] as Array).append((p - (a + ab * u)).length())
	var scale := sk.global_transform.basis.get_scale().x
	for part in 3:
		var d: Array = far[part]
		if d.size() < 20:
			continue
		d.sort()
		out[part] = clampf(d[int((d.size() - 1) * RADII_SHARE)] * scale, float(RADII[part]), float(RADII_MOST[part]))
	_radii_by[key] = out
	return out


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
	_segs = [[sh, el, radii[0]], [el, wr, radii[1]], [wr, tip, radii[2]]]
	_drape()


## How far round the arm the cloth is looked at (m): beyond that it lies as
## it lay.
const ROUND := 0.3

func _drape() -> void:
	# (nothing's moved since it was last draped: it lies as it lies)
	if k >= 1.0 and _segs_was.size() == _segs.size() and not _last.is_empty():
		var same := true
		for i in _segs.size():
			if ((_segs[i] as Array)[0] as Vector3).distance_to((_segs_was[i] as Array)[0]) > 0.001 \
					or ((_segs[i] as Array)[1] as Vector3).distance_to((_segs_was[i] as Array)[1]) > 0.001:
				same = false
				break
		if same:
			return
	_segs_was = _segs.duplicate(true)
	lifted = 0.0
	# the part of the cloth the arm can reach, across and along it
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for sg in _segs:
		for e in 2:
			var p: Vector3 = sg[e]
			lo = Vector2(minf(lo.x, p.x - ROUND), minf(lo.y, p.z - ROUND))
			hi = Vector2(maxf(hi.x, p.x + ROUND), maxf(hi.y, p.z + ROUND))
	var flat := PackedVector3Array()
	flat.resize(_laid.size())
	var pts: Array = []
	for i in _npx:
		var out: Array = []
		for j in _npz:
			var n := i * _npz + j
			var was: Vector3 = _laid[n]
			var q: Vector3 = _free[n]
			if q.x > lo.x and q.x < hi.x and q.z > lo.y and q.z < hi.y:
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
					q.y = lerpf(q.y, need, hk) + SOFT * hk * (1.0 - hk)
			# (eased in from how it was laid)
			q.y = lerpf(was.y, q.y, k)
			lifted = maxf(lifted, q.y - was.y)
			flat[n] = q
			out.append(q)
		pts.append(out)
	_last = pts
	mi.mesh = BlanketDrape.mesh_of(flat, _npx, _npz, _shade)
