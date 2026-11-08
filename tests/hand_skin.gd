extends RefCounted
## A figure's hands as drawn: the skinned mesh's own vertices (8 November,
## Gary: "Left hand still goes through box as you're holding it when you open
## it to reveal cards"). Player A's finger bones lie jumbled at his knuckles
## (Figure3D.FROZEN), so his bones say nothing about where his fingers are;
## the skin does. setup(fig) gathers every vertex weighted mostly to the
## bones of each hand (the hand, its fingers and thumb); points(side) gives
## where they are this frame (world), worked out the way the renderer does
## (bone global pose times the skin's bind pose, in the skeleton's frame).
## Read inside skeleton_updated, while the modifiers' poses are on the bones.
##
##   var hs = preload("res://tests/hand_skin.gd").new()
##   hs.setup(fig)
##   for p in hs.points("left"): ...

var skel: Skeleton3D
## side -> Array of [PackedVector3Array vertices (mesh space), PackedInt32Array bone (skeleton index) x4, PackedFloat32Array weights x4]
var _sets := {"left": [], "right": []}
var _binds := {}   # skeleton bone index -> inverse bind (Transform3D)
var _bones_used := {}


func setup(fig: Figure3D, cut := 0.5) -> int:
	skel = fig._skel
	if skel == null:
		return 0
	var n_total := 0
	for mi: MeshInstance3D in fig.model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skeleton == NodePath():
			continue
		var skin: Skin = mi.skin
		if skin == null:
			skin = skel.create_skin_from_rest_transforms()
		# bind index -> skeleton bone
		var bind_bone: Array = []
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = skel.find_bone(skin.get_bind_name(i))
			bind_bone.append(b)
			if b >= 0 and not _binds.has(b):
				_binds[b] = skin.get_bind_pose(i)
		var local := Transform3D.IDENTITY
		# (the mesh's own transform under the skeleton, usually identity)
		var cur: Node = mi
		while cur != null and cur != skel:
			if cur is Node3D:
				local = (cur as Node3D).transform * local
			cur = cur.get_parent()
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			if verts.is_empty() or bones == null or weights == null:
				continue
			var per := int(bones.size() / verts.size())
			if per < 1:
				continue
			for side in ["left", "right"]:
				var pre := "Left" if side == "left" else "Right"
				var vs := PackedVector3Array()
				var bs := PackedInt32Array()
				var ws := PackedFloat32Array()
				var gs := PackedByteArray()
				for vi in verts.size():
					var on_hand := 0.0
					var heavy := -1
					var heavy_w := 0.0
					for k in per:
						var bi := int(bones[vi * per + k])
						var bone: int = bind_bone[bi] if bi < bind_bone.size() else -1
						if bone >= 0 and (skel.get_bone_name(bone).begins_with(pre + "Hand") or skel.get_bone_name(bone) == pre + "ForeArm"):
							on_hand += float(weights[vi * per + k])
							if float(weights[vi * per + k]) > heavy_w:
								heavy_w = float(weights[vi * per + k])
								heavy = bone
					if on_hand < cut:
						continue
					vs.append(local * verts[vi])
					# (which part of the hand it mostly belongs to: 0 the palm, 1
					# a finger, 2 the thumb, 3 the forearm)
					var nm := skel.get_bone_name(heavy) if heavy >= 0 else ""
					gs.append(3 if nm == pre + "ForeArm" else (2 if "Thumb" in nm else (1 if ("Index" in nm or "Middle" in nm or "Ring" in nm or "Pinky" in nm) else 0)))
					# (the four heaviest, in order as stored)
					for k in 4:
						if k < per:
							var bi := int(bones[vi * per + k])
							bs.append(bind_bone[bi] if bi < bind_bone.size() else -1)
							ws.append(float(weights[vi * per + k]))
						else:
							bs.append(-1)
							ws.append(0.0)
				if not vs.is_empty():
					_sets[side].append([vs, bs, ws, gs])
					n_total += vs.size()
					for b in bs:
						if b >= 0:
							_bones_used[b] = true
	return n_total


func count(side: String) -> int:
	var n := 0
	for s in _sets[side]:
		n += (s[0] as PackedVector3Array).size()
	return n


## Where the hand's skin is this frame (world). `part`: -1 all of it, 0 the
## palm (and the back of the hand), 1 the fingers, 2 the thumb, 3 the
## forearm (its vertices are kept too: a box set back on the heel of the
## hand sits over the wrist).
func points(side: String, part := -1) -> PackedVector3Array:
	var out := PackedVector3Array()
	if skel == null:
		return out
	var xf := skel.global_transform
	var bt := {}
	for b in _bones_used:
		bt[b] = xf * skel.get_bone_global_pose(b) * (_binds[b] as Transform3D)
	for s in _sets[side]:
		var vs: PackedVector3Array = s[0]
		var bs: PackedInt32Array = s[1]
		var ws: PackedFloat32Array = s[2]
		var gs: PackedByteArray = s[3]
		for vi in vs.size():
			if part >= 0 and int(gs[vi]) != part:
				continue
			var p := Vector3.ZERO
			var wsum := 0.0
			for k in 4:
				var b := bs[vi * 4 + k]
				var w := ws[vi * 4 + k]
				if b < 0 or w <= 0.0:
					continue
				p += (bt[b] as Transform3D) * vs[vi] * w
				wsum += w
			if wsum > 0.0:
				out.append(p / wsum)
	return out


## How deep the hand's skin is in a box of half-size `half` at `bx` (the
## box's inverse transform) this frame: [deepest (m), how many vertices in,
## the deepest point in the box's frame].
func in_box(side: String, bx: Transform3D, half: Vector3, grow := 0.0, part := -1) -> Array:
	var deepest := 0.0
	var n := 0
	var where := Vector3.ZERO
	for p in points(side, part):
		var q: Vector3 = bx * p
		var e := q.abs() - half
		var inside := maxf(e.x, maxf(e.y, e.z))
		var d := grow - inside
		if d > 0.0:
			n += 1
			if d > deepest:
				deepest = d
				where = q
	return [deepest, n, where]


## A check on the numbers (the skinning done here against the mesh as
## modelled): the hand's vertices at rest, about the hand bone's rest
## position (the skeleton's frame), as an AABB; and the same vertices as
## skinned this frame, about the hand bone as posed. The two should be the
## same size and sit the same way about the bone.
func rest_check(side: String) -> String:
	if skel == null:
		return "no skeleton"
	var pre := "Left" if side == "left" else "Right"
	var h := skel.find_bone(pre + "Hand")
	if h < 0:
		return "no hand bone"
	var r0 := skel.get_bone_global_rest(h).origin
	var rest := AABB()
	var first := true
	for s in _sets[side]:
		var vs: PackedVector3Array = s[0]
		for vi in vs.size():
			var p := vs[vi] - r0
			rest = AABB(p, Vector3.ZERO) if first else rest.expand(p)
			first = false
	var xf := skel.global_transform
	var now := xf * skel.get_bone_global_pose(h).origin
	var posed := AABB()
	first = true
	for p in points(side):
		var q: Vector3 = p - now
		posed = AABB(q, Vector3.ZERO) if first else posed.expand(q)
		first = false
	return "%s hand at rest about its bone: %s to %s (size %s); skinned, about the bone (world): %s to %s (size %s)" % [side, rest.position.snapped(Vector3(0.001, 0.001, 0.001)), rest.end.snapped(Vector3(0.001, 0.001, 0.001)), rest.size.snapped(Vector3(0.001, 0.001, 0.001)), posed.position.snapped(Vector3(0.001, 0.001, 0.001)), posed.end.snapped(Vector3(0.001, 0.001, 0.001)), posed.size.snapped(Vector3(0.001, 0.001, 0.001))]


## The hand's skin as a profile along the fingers' way, in `frame` (a palm
## frame: y off the palm, z along the fingers): for each centimetre of z
## from `z0` to `z1`, the highest y of each part (palm, fingers, thumb,
## forearm) among the vertices within `x0`..`x1` across; a line per
## centimetre, "-" where a part has nothing there.
func profile(side: String, frame: Transform3D, x0: float, x1: float, z0: float, z1: float) -> String:
	var inv := frame.affine_inverse()
	var n := int(ceil((z1 - z0) * 100.0))
	var tops: Array = []
	for i in n:
		tops.append([-INF, -INF, -INF, -INF])
	for s in _sets[side]:
		var gs: PackedByteArray = s[3]
		var pts := _points_of(s)
		for vi in pts.size():
			var q: Vector3 = inv * pts[vi]
			if q.x < x0 or q.x > x1:
				continue
			var bin := int(floor((q.z - z0) * 100.0))
			if bin < 0 or bin >= n:
				continue
			var part := int(gs[vi])
			if q.y > float(tops[bin][part]):
				tops[bin][part] = q.y
	var out := "    z(cm)  palm  fingers thumb forearm\n"
	for i in n:
		var row := "    %5.1f" % (z0 * 100.0 + i)
		for part in 4:
			var v: float = tops[i][part]
			row += "  %5s" % (("%.1f" % (v * 100.0)) if v > -INF else "-")
		out += row + "\n"
	return out


func _points_of(s: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	var xf := skel.global_transform
	var bt := {}
	for b in _bones_used:
		bt[b] = xf * skel.get_bone_global_pose(b) * (_binds[b] as Transform3D)
	var vs: PackedVector3Array = s[0]
	var bs: PackedInt32Array = s[1]
	var ws: PackedFloat32Array = s[2]
	for vi in vs.size():
		var p := Vector3.ZERO
		var wsum := 0.0
		for k in 4:
			var b := bs[vi * 4 + k]
			var w := ws[vi * 4 + k]
			if b < 0 or w <= 0.0:
				continue
			p += (bt[b] as Transform3D) * vs[vi] * w
			wsum += w
		out.append(p / wsum if wsum > 0.0 else p)
	return out


## The same across the hand: for each centimetre of x from `x0` to `x1`,
## the highest y of each part among the vertices within `z0`..`z1`.
func profile_x(side: String, frame: Transform3D, x0: float, x1: float, z0: float, z1: float) -> String:
	var inv := frame.affine_inverse()
	var n := int(ceil((x1 - x0) * 100.0))
	var tops: Array = []
	for i in n:
		tops.append([-INF, -INF, -INF, -INF])
	for s in _sets[side]:
		var gs: PackedByteArray = s[3]
		var pts := _points_of(s)
		for vi in pts.size():
			var q: Vector3 = inv * pts[vi]
			if q.z < z0 or q.z > z1:
				continue
			var bin := int(floor((q.x - x0) * 100.0))
			if bin < 0 or bin >= n:
				continue
			var part := int(gs[vi])
			if q.y > float(tops[bin][part]):
				tops[bin][part] = q.y
	var out := "    x(cm)  palm  fingers thumb forearm\n"
	for i in n:
		var row := "    %5.1f" % (x0 * 100.0 + i)
		for part in 4:
			var v: float = tops[i][part]
			row += "  %5s" % (("%.1f" % (v * 100.0)) if v > -INF else "-")
		out += row + "\n"
	return out
