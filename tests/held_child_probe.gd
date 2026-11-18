extends Node
## (16 November, Gary: "When Bram says I got you to the baby the baby is
## halfway through his coat"; "When baby hand reaches for card hand doesn't
## look very real also hand goes through bram".) Measures how much of the
## child is inside Bram as he's drawn (his skinned meshes baked in the pose
## of that frame, after every reach and bend: WhiteSky's own), and takes
## stills of each moment:
##
##   carry  the child in his hands at "Hush, now. I've got you." (the pick-up
##          just done), then in his left arm once tucked, stood and walking
##   knee   down on his knee with it, as at "I've got you. I've got you." in
##          the duel (_carry_child, his kneel), from the shot of the two of
##          them (TO_CHILD_CAM)
##   hand   the walk out, the small hand coming up, its fingers opening and
##          closing as it reaches (Gary's yes, 16 November), taking its card
##          and going down: every few frames (every frame while it grasps),
##          the hand's skin against Bram and against the card
##
## A point counts as inside when four of six rays from it leave through the
## inside of a face (tests/body_check.gd's way). Prints, for each moment,
## "inside n/N, deepest d cm"; FAIL when any of the child is more than
## TOL inside him (or the hand more than TOL inside its card).
##
##   arms   (18 November, the body sweep: "his right hand is 10.0 cm inside
##          ... baby_bundle", "his left forearm is 7.8 cm inside") the other
##          way about: how far the lines of his forearms and hands (elbow to
##          wrist, wrist to knuckle) are inside the child's bundle, its mesh
##          as a solid: held in his hands, tucked, turned away from the
##          hunter with his right arm across it, on his knee, and (with
##          "hand") every few frames of the walk out. A forearm under a
##          bundle isn't in it: FAIL at more than ARM_IN.
##
##   godot --headless --fixed-fps 10 --path . res://tests/held_child_probe.tscn -- [<dir>] [carry] [knee] [hand] [arms]
##   (stills: under xvfb, drawn, as white_sky_look)

const DrawHold = preload("res://tests/draw_hold.gd")
const MODES := ["carry", "knee", "hand", "front", "scan", "arms"]
## How deep any of the child may be inside his body before it counts (m):
## the wool pressed to his coat (bent over it on his knee, 2 cm).
const TOL := 0.025
const HAND_TOL := 0.004
## (his arm under it and round it: sunk into the wool a little more)
const ARM_TOL := 0.03
const RAY := 3.0
## How far the line of a forearm or hand may be inside the bundle (m): the
## wool gives a little under an arm.
const ARM_IN := 0.01
## (the knuckles under it, taking its weight: a little more)
const HAND_IN := 0.025
const DIRS := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]

var out := ""
var m: WhiteSky
var _n := 0
var _space := RID()
var _body := RID()
var _shape: ConcavePolygonShape3D
var _faces := PackedVector3Array()
var _peek := false
var _pos := Vector3.ZERO
var _look := Vector3.ZERO
var _fov := 40.0
var fails: Array = []
var _drawn := false
var _named := false
var _drawn_bones := {}
var _deep_part := ""


func _ready() -> void:
	process_priority = 100
	var a := Array(OS.get_cmdline_user_args())
	for s in a:
		if not MODES.has(String(s)) and out == "" and not String(s).begins_with("-"):
			out = String(s)
	_drawn = DisplayServer.get_name() != "headless" and out != ""
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	Gfx.setup(get_tree())
	m = WhiteSky.new()
	m.prep_early = false
	add_child(m)
	_run.call_deferred()


func _process(_d: float) -> void:
	if _peek and m != null and m._cam != null:
		m._cam_mode = "peek"
		m._cam_pos = _pos
		m._cam_look = _look
		m._cam.fov = _fov
		m._apply_cam()


func _shot(nm: String) -> void:
	if not _drawn:
		return
	# (the game all but stopped while a still is drawn: a still takes three
	# frames, and at ten frames a second what it was of had gone by)
	var ts := Engine.time_scale
	Engine.time_scale = 0.001
	await _shot_now(nm)
	Engine.time_scale = ts


func _shot_now(nm: String) -> void:
	DrawHold.hold()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DrawHold.release()
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	print("held_child_probe: still ", nm)


func _wait(s: float) -> void:
	var el := 0.0
	while el < s:
		await get_tree().process_frame
		el += 0.1


func _run() -> void:
	var names: Array = Array(OS.get_cmdline_user_args()).filter(func(x): return MODES.has(String(x)))
	if names.is_empty():
		names = ["carry", "knee", "hand"]
	if _drawn and not OS.get_cmdline_user_args().has("drawall"):
		DrawHold.start_keys()
	await get_tree().process_frame
	m._ov = m._own_overlay()
	m._black.modulate.a = 0.0
	var fig := m._bram as Figure3D
	var kd := m._kneel_dir(Vector3.FORWARD)
	var bottom := m._kneel_spot(kd)
	m._ad = kd
	m._bottom = bottom
	m._bram.position = bottom
	fig.snap_face(kd)
	m._shaft_k = 0.0
	m._child_beacon(false)
	m._crater_k = 0.32
	m._raining = false
	var rt := kd.cross(Vector3.UP)
	m._shot(bottom - kd * 1.9 + rt * 1.45 + Vector3(0, 1.15, 0), m._baby.position + Vector3(0, 0.2, 0), 40.0)
	await m._lift_child()
	# "Hush, now. I've got you.": the shot of it is the high one over his
	# shoulder (_held_shot)
	_arms = names.has("arms")
	_arms_dbg = OS.get_cmdline_user_args().has("armsdbg")
	if _arms:
		await _wait(0.3)
		await _measure_arms("in his hands at \"Hush, now\"")
	if names.has("carry"):
		await _wait(0.3)
		await _measure_child("hush (in his hands)")
		var held: Array = m._held_shot()
		m._shot(held[0], held[1], 36.0)
		await _shot("carry_1_hush")
		await _side_shots("carry_1")
	m._tuck()
	await _wait(1.6)
	if names.has("front"):
		await _front_table()
	if names.has("scan"):
		await _scan()
	if names.has("carry"):
		await _measure_child("tucked, stood")
		await _side_shots("carry_2_tucked")
	if _arms:
		await _measure_arms("tucked, stood")
		# turned away from the hunter, his right arm across it (_the_demand)
		fig.face(kd.rotated(Vector3.UP, deg_to_rad(WhiteSky.SHIELD_TURN)), m._cam)
		if m._lean == null:
			m._lean = m._bend(fig, "Lean", WhiteSky.GUST_LEAN)
		if m._lean != null:
			create_tween().tween_property(m._lean, "amount", 0.85, WhiteSky.DEMAND_TURN)
		m._shield_arm(fig, WhiteSky.DEMAND_TURN * 0.8)
		await _wait(WhiteSky.DEMAND_TURN + 0.6)
		await _measure_arms("turned away, his right arm across it")
		await _side_shots("arms_1_shield")
		# (and his right hand his own again, as it is by the duel: _stage_duellists)
		fig._reach("right", null, 0.2)
		fig.palm("right", Vector3.ZERO, 0.2)
		fig.elbow("right", Vector3.INF, 0.2)
		if m._lean != null:
			m._lean.amount = 0.0
		fig.snap_face(kd)
		await _wait(0.5)
	if names.has("knee"):
		m._carry_child(fig)
		fig.kneel(WhiteSky.KNEE_DOWN, WhiteSky.KNEE_LEAN, false, true)
		m._knee_hand(true, WhiteSky.KNEE_DOWN)
		await _wait(1.4)
		await _measure_child("on his knee")
		if _arms:
			await _measure_arms("on his knee")
		var head := fig.bone_pos("Head")
		var child := m._baby.global_position
		var own := fig.global_basis.orthonormalized() * Basis(Vector3.UP, fig._yaw)
		# (the duel's shot of the two of them, TO_CHILD_CAM, in his own frame:
		# 1.6 m out to his left)
		var cam := head + own * Vector3(-WhiteSky.TO_CHILD_CAM.x, WhiteSky.TO_CHILD_CAM.y, -WhiteSky.TO_CHILD_CAM.z)
		_at(cam, head.lerp(child, WhiteSky.TO_CHILD_LOOK), WhiteSky.TO_CHILD_LENS)
		await _shot("knee_1_to_the_child")
		await _side_shots("knee_2")
		_peek = false
		fig.rise(WhiteSky.KNEE_UP)
		m._knee_hand(false, WhiteSky.KNEE_UP)
		await _wait(1.2)
		m._carry_on = false
	if names.has("hand"):
		await _hand_run()
	if _arms:
		for part: String in _arms_worst:
			print("held_child_probe: his %s in the bundle: at most %.1f cm (%s)" % [part, float(_arms_worst[part][0]) * 100.0, _arms_worst[part][1]])
		if _arms_worst.is_empty():
			print("held_child_probe: his arms in the bundle: never")
	m._cam_mode = "roam"
	print("held_child_probe: %s" % ("PASS" if fails.is_empty() else "FAIL " + ", ".join(fails)))
	get_tree().quit(0 if fails.is_empty() else 1)


func _at(pos: Vector3, look: Vector3, fov := 40.0) -> void:
	_peek = true
	_pos = pos
	_look = look
	_fov = fov


## From his left side and from the front, close, looking at the child: the
## bundle against his chest seen edge on.
func _side_shots(nm: String) -> void:
	if not _drawn:
		return
	var fig := m._bram as Figure3D
	var c := m._baby.global_position
	var own := fig.global_basis.orthonormalized() * Basis(Vector3.UP, fig._yaw)
	_at(c + own * Vector3(1.25, 0.15, 0.25), c + own * Vector3(0, 0.02, -0.05), 30.0)
	await _shot(nm + "_side")
	_at(c + own * Vector3(0.35, 0.35, 1.3), c, 30.0)
	await _shot(nm + "_front")
	_peek = false
	m._cam_mode = "follow"


# ---------------------------------------------------------------- measuring ---

## Bram as drawn this frame (every mesh of his, skinned in the pose the
## frame draws, but the child's), made solid in a space of the probe's own.
func _bake_bram() -> void:
	var fig := m._bram as Figure3D
	var sk: Skeleton3D = fig._skel
	var done := [false]
	var faces := PackedVector3Array()
	var cb := func() -> void:
		if done[0]:
			return
		done[0] = true
		for bn in ["LeftArm", "LeftForeArm", "LeftHand", "LeftHandMiddle1", "LeftHandMiddle2", "RightArm", "RightForeArm", "RightHand", "RightHandMiddle1", "Spine", "Spine1", "Spine2", "Hips", "Head"]:
			var bi := sk.find_bone(bn)
			if bi >= 0:
				_drawn_bones[bn] = (sk.global_transform * sk.get_bone_global_pose(bi)).origin
		for n in fig.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree():
				continue
			if is_instance_valid(m._baby) and m._baby.is_ancestor_of(mi):
				continue
			var gi := mi as GeometryInstance3D
			if gi.material_override != null and gi.material_override is StandardMaterial3D \
					and (gi.material_override as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				continue
			var fs := PackedVector3Array()
			if mi.skin != null and mi.get_node_or_null(mi.skeleton) is Skeleton3D:
				fs = skinned(mi, true)
			else:
				fs = mi.mesh.get_faces()
				var xf := mi.global_transform
				for i in fs.size():
					fs[i] = xf * fs[i]
			if not _named:
				print("held_child_probe: his mesh %s (%d faces)" % [mi.name, fs.size() / 3])
			faces.append_array(fs)
	sk.skeleton_updated.connect(cb, CONNECT_ONE_SHOT)
	var waited := 0
	while not done[0] and waited < 20:
		await get_tree().process_frame
		waited += 1
	_solid(faces)
	_named = true
	await get_tree().physics_frame
	await get_tree().physics_frame


func _solid(faces: PackedVector3Array) -> void:
	if _body.is_valid():
		PhysicsServer3D.free_rid(_body)
	if not _space.is_valid():
		_space = PhysicsServer3D.space_create()
		PhysicsServer3D.space_set_active(_space, true)
	_faces = faces
	_shape = ConcavePolygonShape3D.new()
	_shape.backface_collision = true
	_shape.set_faces(faces)
	_body = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(_body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_add_shape(_body, _shape.get_rid())
	PhysicsServer3D.body_set_collision_layer(_body, 1)
	PhysicsServer3D.body_set_collision_mask(_body, 0)
	PhysicsServer3D.body_set_space(_body, _space)


## How deep `p` is inside him (m), or -1.
func _inside(p: Vector3) -> float:
	return _inside_of(_space, _faces, p)


func _inside_of(space: RID, faces: PackedVector3Array, p: Vector3) -> float:
	var _faces := faces
	var ss := PhysicsServer3D.space_get_direct_state(space)
	if ss == null:
		return -1.0
	var votes := 0
	var near := INF
	for dir in DIRS:
		var q := PhysicsRayQueryParameters3D.create(p, p + dir * RAY, 1)
		q.hit_back_faces = true
		q.hit_from_inside = true
		var hit := ss.intersect_ray(q)
		if hit.is_empty():
			continue
		var fi := int(hit.get("face_index", -1))
		if fi < 0 or fi * 3 + 2 >= _faces.size():
			continue
		var a := _faces[fi * 3]
		var b := _faces[fi * 3 + 1]
		var c := _faces[fi * 3 + 2]
		if (c - a).cross(b - a).dot(dir) > 0.0:
			votes += 1
			near = minf(near, p.distance_to(hit.position))
	return near if votes >= 4 else -1.0


# ------------------------------------------------- his arms in the bundle ---

var _space2 := RID()
var _body2 := RID()
var _shape2: ConcavePolygonShape3D
var _arms := false
var _arms_dbg := false
var _arms_worst := {}     # part -> [m, when]

## The lines of his forearms and hands against the bundle's own mesh, both
## read in the same pass of his bones (after the child's been put where his
## chest is: this is connected last).
func _measure_arms(what: String, say := true) -> void:
	var fig := m._bram as Figure3D
	var sk: Skeleton3D = fig._skel
	var done := [false]
	var parts := {}
	var faces := PackedVector3Array()
	var xfs := [Transform3D.IDENTITY, Transform3D.IDENTITY]
	var cb := func() -> void:
		if done[0]:
			return
		done[0] = true
		var pos := func(bn: String) -> Vector3:
			return (sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bn))).origin
		for sd in ["Left", "Right"]:
			var e: Vector3 = pos.call(sd + "ForeArm")
			var w: Vector3 = pos.call(sd + "Hand")
			var k: Vector3 = pos.call(sd + "HandMiddle1")
			var fa := PackedVector3Array()
			for i in 9:
				fa.append(e.lerp(w, 0.12 + 0.88 * i / 8.0))
			parts[sd.to_lower() + " forearm"] = fa
			var hd := PackedVector3Array()
			for i in 4:
				hd.append(w.lerp(k, i / 3.0))
			parts[sd.to_lower() + " hand"] = hd
		xfs[0] = m._baby.global_transform
		xfs[1] = fig.global_transform * Transform3D(Basis(Vector3.UP, fig._yaw), Vector3.ZERO)
		for n in m._baby.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree() or mi.skin != null or not String(m._baby.get_path_to(mi)).contains("baby_bundle"):
				continue
			var fs := mi.mesh.get_faces()
			var xf := mi.global_transform
			for i in fs.size():
				fs[i] = xf * fs[i]
			faces.append_array(fs)
	sk.skeleton_updated.connect(cb, CONNECT_ONE_SHOT)
	var waited := 0
	while not done[0] and waited < 20:
		await get_tree().process_frame
		waited += 1
	if faces.is_empty():
		return
	if _body2.is_valid():
		PhysicsServer3D.free_rid(_body2)
	if not _space2.is_valid():
		_space2 = PhysicsServer3D.space_create()
		PhysicsServer3D.space_set_active(_space2, true)
	_shape2 = ConcavePolygonShape3D.new()
	_shape2.backface_collision = true
	_shape2.set_faces(faces)
	_body2 = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(_body2, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_add_shape(_body2, _shape2.get_rid())
	PhysicsServer3D.body_set_collision_layer(_body2, 1)
	PhysicsServer3D.body_set_collision_mask(_body2, 0)
	PhysicsServer3D.body_set_space(_body2, _space2)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var line := ""
	var detail := say
	for part: String in parts:
		var deep := 0.0
		var at := -1
		var k := 0
		for p: Vector3 in parts[part]:
			var d := _inside_of(_space2, faces, p)
			if d > deep:
				deep = d
				at = k
			k += 1
		line += "  %s %s" % [part, ("%.1f cm (point %d of %d)" % [deep * 100.0, at + 1, (parts[part] as PackedVector3Array).size()]) if deep > 0.0 else "out"]
		if deep > float((_arms_worst.get(part, [0.0, ""]) as Array)[0]):
			_arms_worst[part] = [deep, what]
			if _arms_dbg and deep > ARM_IN:
				detail = true
		if deep > (HAND_IN if part.ends_with("hand") else ARM_IN) and not fails.has("his %s in the bundle" % part):
			fails.append("his %s in the bundle" % part)
	if say:
		print("held_child_probe: his arms in the bundle, %s:%s" % [what, line])
	if _arms_dbg and detail:
		# (where: each elbow and wrist in the bundle's own frame, and in his,
		# as they all were in that pass)
		var inv: Transform3D = (xfs[0] as Transform3D).affine_inverse()
		var lo := Vector3.INF
		var hi := -Vector3.INF
		for f: Vector3 in faces:
			var q := inv * f
			lo = lo.min(q)
			hi = hi.max(q)
		var his: Transform3D = (xfs[1] as Transform3D).affine_inverse()
		var own := func(p: Vector3) -> Vector3:
			return (his * p).snappedf(0.005)
		var bx: Transform3D = xfs[0]
		print("held_child_probe:   the bundle's box in its own frame %s to %s; its middle in his frame %s, its axes in his frame x %s y %s z %s" % [str(lo.snappedf(0.005)), str(hi.snappedf(0.005)),
			str(own.call(bx.origin)), str((his.basis * bx.basis.x).snappedf(0.01)), str((his.basis * bx.basis.y).snappedf(0.01)), str((his.basis * bx.basis.z).snappedf(0.01))])
		for part: String in parts:
			var a: PackedVector3Array = parts[part]
			print("held_child_probe:   %s from %s to %s in the bundle's frame; %s to %s in his" % [part, str((inv * a[0]).snappedf(0.005)), str((inv * a[a.size() - 1]).snappedf(0.005)), str(own.call(a[0])), str(own.call(a[a.size() - 1]))])


## A skinned mesh as drawn now, in the world: its triangles (three points
## each) or, `want_faces` false, its points (about `most` of them). Skinned
## here, on the CPU, the way the renderer does it (the engine's own
## bake_mesh_from_current_skeleton_pose won't take these models). Read
## inside the skeleton's update to have every reach in it.
static func skinned(mi: MeshInstance3D, want_faces: bool, most := 0) -> PackedVector3Array:
	var sk := mi.get_node(mi.skeleton) as Skeleton3D
	var skin: Skin = mi.skin
	var bx: Array = []
	for i in skin.get_bind_count():
		var b := skin.get_bind_bone(i)
		if b < 0:
			b = sk.find_bone(skin.get_bind_name(i))
		bx.append(sk.global_transform * sk.get_bone_global_pose(b) * skin.get_bind_pose(i) if b >= 0 else sk.global_transform)
	var local := Transform3D.IDENTITY
	var cur: Node = mi
	while cur != null and cur != sk:
		if cur is Node3D:
			local = (cur as Node3D).transform * local
		cur = cur.get_parent()
	var out := PackedVector3Array()
	for si in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(si)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bs = arr[Mesh.ARRAY_BONES]
		var ws = arr[Mesh.ARRAY_WEIGHTS]
		if vs.is_empty() or bs == null or ws == null:
			continue
		var per := int(bs.size() / vs.size())
		var step := 1 if want_faces or most <= 0 else maxi(1, vs.size() / most)
		var posed := PackedVector3Array()
		posed.resize(vs.size())
		for vi in range(0, vs.size(), step):
			var v := local * vs[vi]
			var p := Vector3.ZERO
			var tot := 0.0
			for k in per:
				var wv := float(ws[vi * per + k])
				if wv <= 0.0:
					continue
				var bi := int(bs[vi * per + k])
				if bi < 0 or bi >= bx.size():
					continue
				p += (bx[bi] as Transform3D) * v * wv
				tot += wv
			posed[vi] = p / tot if tot > 0.0 else sk.global_transform * v
		if want_faces:
			var ix = arr[Mesh.ARRAY_INDEX]
			if ix == null or (ix as PackedInt32Array).is_empty():
				out.append_array(posed)
			else:
				for t in (ix as PackedInt32Array):
					out.append(posed[t])
		else:
			for vi in range(0, vs.size(), step):
				out.append(posed[vi])
	return out


## Points on a node's meshes as drawn (skinned ones skinned), at most `most`.
static func points_of(root: Node, most := 900) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for n in root.find_children("*", "MeshInstance3D", true, false) + ([root] if root is MeshInstance3D else []):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var gi := mi as GeometryInstance3D
		if gi.material_override is StandardMaterial3D and (gi.material_override as StandardMaterial3D).blend_mode == BaseMaterial3D.BLEND_MODE_ADD:
			continue
		if mi.mesh is QuadMesh:
			continue
		if mi.skin != null and mi.get_node_or_null(mi.skeleton) is Skeleton3D:
			pts.append_array(skinned(mi, false, most))
			continue
		var mesh: Mesh = mi.mesh
		for si in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(si)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var step := maxi(1, vs.size() / most)
			for i in range(0, vs.size(), step):
				pts.append(mi.global_transform * vs[i])
	return pts


## (diagnostic) where his front is, in his own frame: for heights under his
## shoulder joint and across him, how far ahead of him the first of him is;
## and where the child is.
func _front_table() -> void:
	await _bake_bram()
	var fig := m._bram as Figure3D
	var sh := fig.to_own(fig.bone_pos("LeftArm"))
	var ss := PhysicsServer3D.space_get_direct_state(_space)
	print("held_child_probe: his left shoulder joint at %s in his frame; the child at %s; hold_point(0.2, 0.42) %s, arm %.2f; his chest bone (as drawn) at %s, stature %.3f" % [
		str(sh), str(fig.to_own(m._baby.global_position)), str(fig.hold_point(0.2, 0.42)), fig.arm_reach(), str(fig.to_own(_drawn_bones.get("Spine2", Vector3.ZERO))), fig.stature()])
	for dy in [0.0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6]:
		var line := "  y %+.1f:" % dy
		for x in [-0.15, -0.05, 0.05, 0.15, 0.25]:
			var a := fig.to_world(Vector3(x, sh.y + dy, 1.0))
			var b := fig.to_world(Vector3(x, sh.y + dy, -0.6))
			var q := PhysicsRayQueryParameters3D.create(a, b, 1)
			q.hit_back_faces = true
			var hit := ss.intersect_ray(q)
			line += "  x %+.2f: %s" % [x, ("z %.3f" % fig.to_own(hit.position).z) if not hit.is_empty() else "-"]
		print(line)


## (diagnostic) the child held at each of a few places in front of him,
## how much of it is inside him and how far his hand is from its place
## under it.
func _scan() -> void:
	var fig := m._bram as Figure3D
	var base: Vector3 = m._baby.position
	var hand0 := m._tuck_hand.position if m._tuck_hand != null else Vector3.ZERO
	for y in [1.30, 1.34]:
		for z in [0.24, 0.27, 0.30]:
			for hy in [-0.13, -0.16]:
				m._baby.position = Vector3(base.x, y, z)
				if m._tuck_hand != null:
					m._tuck_hand.position = Vector3(hand0.x, hy, hand0.z)
				await _wait(0.8)
				await _bake_bram()
				var r := _split(points_of(m._baby))
				print("held_child_probe: scan at y %.2f z %.2f hand y %.2f: in his body %d (%.1f cm), in his arm %d (%.1f cm)" % [
					y, z, hy, r[0], r[1] * 100.0, r[2], r[3] * 100.0])
	m._baby.position = base


## The child's points inside him, by where: [in his body, deepest, in his
## left arm (within 9 cm of its bones as drawn), deepest].
func _split(pts: PackedVector3Array) -> Array:
	var fig := m._bram as Figure3D
	var sk := fig._skel
	var bones := [_drawn_bones.get("LeftArm", Vector3.INF), _drawn_bones.get("LeftForeArm", Vector3.INF), _drawn_bones.get("LeftHand", Vector3.INF)]
	var hand_end: Vector3 = _drawn_bones.get("LeftHandMiddle2", Vector3.INF)
	if hand_end != Vector3.INF:
		bones.append(hand_end)
	var r := [0, 0.0, 0, 0.0]
	for p in pts:
		var d := _inside(p)
		if d < 0.0:
			continue
		var near := INF
		var part := 0
		for i in bones.size() - 1:
			var sd := _seg(p, bones[i], bones[i + 1])
			if sd < near:
				near = sd
				part = i
		if near < 0.09:
			r[2] += 1
			if d > float(r[3]):
				r[3] = d
				_deep_part = ["upper arm", "forearm", "hand"][mini(part, 2)]
		else:
			r[0] += 1
			r[1] = maxf(r[1], d)
	return r


static func _seg(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## How far his right hand (as drawn, its forearm's line 7.5 cm past the
## wrist: Figure3D._reach) is from where it's reaching for, over the blanket.
func _right_gap() -> float:
	var fig := m._bram as Figure3D
	var sk := fig._skel
	var got := [INF]
	var tgt: Node3D = null
	for c in m._baby.get_children():
		if c is Node3D and c != m._tuck_hand and not (c is MeshInstance3D) and not (c is Light3D) and c.get_child_count() == 0:
			tgt = c
	if tgt == null:
		return INF
	var cb := func() -> void:
		var w := (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("RightHand"))).origin
		var e := (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("RightForeArm"))).origin
		got[0] = (w + (w - e).normalized() * 0.075).distance_to(tgt.global_position)
	sk.skeleton_updated.connect(cb, CONNECT_ONE_SHOT)
	await get_tree().process_frame
	await get_tree().process_frame
	return float(got[0])


## How far his left hand (as drawn) is from where it's reaching for.
func _hand_gap(fig: Figure3D) -> float:
	var sk := fig._skel
	var got := [INF]
	var cb := func() -> void:
		if m._tuck_hand != null:
			got[0] = (sk.global_transform * sk.get_bone_global_pose(sk.find_bone("LeftHand"))).origin.distance_to(m._tuck_hand.global_position)
	sk.skeleton_updated.connect(cb, CONNECT_ONE_SHOT)
	await get_tree().process_frame
	await get_tree().process_frame
	return float(got[0])


func _measure_child(what: String) -> void:
	await _bake_bram()
	var pts := points_of(m._baby)
	var r := _split(pts)
	print("held_child_probe: the child %s: of %d points, in his body %d (deepest %.1f cm), in his left arm round it %d (deepest %.1f cm, his %s)" % [
		what, pts.size(), r[0], r[1] * 100.0, r[2], r[3] * 100.0, _deep_part])
	# where his hands are under it (the bundle's frame: its middle, y up,
	# its underside about 12 cm down): the wrist and the middle knuckle
	var inv := m._baby.global_transform.affine_inverse()
	var line := ""
	for sd in ["Left", "Right"]:
		var w: Vector3 = _drawn_bones.get(sd + "Hand", Vector3.INF)
		var k: Vector3 = _drawn_bones.get(sd + "HandMiddle1", Vector3.INF)
		if w != Vector3.INF and k != Vector3.INF:
			line += "  %s wrist %s knuckle %s" % [sd.to_lower(), str((inv * w).snappedf(0.005)), str((inv * k).snappedf(0.005))]
	print("held_child_probe:   his hands in the bundle's frame:%s" % line)
	if float(r[1]) > TOL or float(r[3]) > ARM_TOL:
		fails.append("the child " + what)


# ---------------------------------------------------------------- the hand ---

var _hand_worst := 0.0
var _hand_worst_at := ""
var _card_worst := 0.0
var _card_worst_at := ""
var _hand_checks := 0
var _grasp_most := 0.0
var _grasp_frames := 0
var _grasp_from := -1.0
var _tuck_seen := false
var _tuck_worst := 0.0
var _tuck_gap := INF
var _grasp_to := -1.0
var _hand_pts := 0
var _card_near := INF
var _take_gap := INF
var _take_at := Vector3.INF
var _take_palm := INF
var _take_palm_far := 0.0
var _take_palm_at := Vector3.ZERO
var _take_palm_n := Vector3.ZERO
var _take_palm_f := Vector3.ZERO

func _hand_run() -> void:
	var fig := m._bram as Figure3D
	m._white.modulate.a = 1.0
	var done := [false]
	var run := func() -> void:
		await m._walk_out()
		done[0] = true
	run.call()
	Input.action_press("move_up")
	var tt := 0.0
	var got := {}
	var k := 0
	while not done[0] and tt < 90.0:
		await get_tree().process_frame
		tt += 0.1
		k += 1
		if _arms and k % 4 == 0:
			await _measure_arms("%.1f s into the walk out" % tt, _arms_dbg)
		if k % 50 == 0:
			print("held_child_probe: (%.0f s into the walk out: %.1f m from the crater, the hand %s rise %.2f)" % [tt, m._crater_dist(), str(m._hand_on), m._tiny_rise])
		if m._hand_on and m._tiny != null and m._tiny.visible and m._tiny_rise > 0.05 and (k % 3 == 0 or m.grasping > 0.05):
			await _measure_hand("rise %.2f curl %.2f grasping %.2f" % [m._tiny_rise, m._tiny_curl, m.grasping])
		# (16 November, Gary's yes) the fingers opening and closing as it reaches
		_grasp_most = maxf(_grasp_most, m.grasping)
		if m.grasping > 0.8:
			_grasp_frames += 1
			if _grasp_from < 0.0:
				_grasp_from = m._t
			_grasp_to = m._t
			if _grasp_frames == 1 or _grasp_frames == 5:
				await _shot("hand_0_grasping_%d" % _grasp_frames)
		# (18 November, Gary: the card "just dissapears rather then Bram taking
		# it": his hand to the card in the small fist, the card his, brought
		# down flat under his palm onto the bundle, and in under the blanket)
		if m.tucking and not m.card_taken and m._take_follow:
			_take_gap = await _right_gap()
		if m.card_taken and _take_at == Vector3.INF and is_instance_valid(m._mote):
			_take_at = m._mote.global_position
			_take_palm = INF
		if m.card_taken and is_instance_valid(m._mote):
			# (the card against his palm as he carries it, as drawn)
			# (both read in the same frame's pass, after the card's been put in
			# his hand: he's walking, a tenth of a metre a frame)
			var cbk := func() -> void:
				if is_instance_valid(m._mote):
					_take_palm_far = maxf(_take_palm_far, fig.palm_frame("right").origin.distance_to(m._mote.global_position))
			fig._skel.skeleton_updated.connect(cbk, CONNECT_ONE_SHOT)
			await get_tree().process_frame
			await get_tree().process_frame
		for st in [["hand_1_open", m._tiny_rise > 0.97 and m._tiny_curl < 0.05], ["hand_2_taken", m._tiny_curl > 0.97],
				["hand_3_white", m.card_whitened],
				["hand_4_his_hand_on_it", m.tucking and not m.card_taken and _take_gap < 0.03 and m._mote_white < 0.9],
				["hand_5_his", m.card_taken and m._take_k > 0.12], ["hand_6_coming_down", m._take_k > 0.55],
				["hand_7_on_the_blanket", m._take_k > 0.99], ["hand_8_tucked", m.card_tucked]]:
			if st[1] and not got.has(st[0]):
				got[st[0]] = true
				await _shot(st[0])
				if st[0] in ["hand_1_open", "hand_2_taken", "hand_4_his_hand_on_it", "hand_5_his", "hand_6_coming_down", "hand_7_on_the_blanket"]:
					await _hand_side(st[0])
		# (16 November, Gary's yes) Bram's right hand drawing the blanket over
		# where the small hand went in: the bundle against his hand, and how
		# near his hand gets to its place
		if m.tucking:
			_tuck_seen = true

			if true:
				await _bake_bram()
				var bp := points_of(m._baby)
				var r := _split(bp)
				if float(r[1]) > _tuck_worst + 0.005:
					# (where: the deepest point, in his frame, and the nearest of his bones)
					var bf := m._bram as Figure3D
					var dp := Vector3.ZERO
					var dd := 0.0
					for p in bp:
						var d := _inside(p)
						if d > dd:
							dd = d
							dp = p
					var nb := ""
					var nd := INF
					for bn in _drawn_bones:
						var q: Vector3 = _drawn_bones[bn]
						if q.distance_to(dp) < nd:
							nd = q.distance_to(dp)
							nb = bn
					print("held_child_probe:   (the tuck: %.1f cm in at %s in his frame, nearest %s %.0f cm; his right elbow %s, wrist %s; his hand %.1f cm off its place)" % [
						dd * 100.0, str(bf.to_own(dp).snappedf(0.005)), nb, nd * 100.0,
						str(bf.to_own(_drawn_bones.get("RightForeArm", Vector3.ZERO)).snappedf(0.01)), str(bf.to_own(_drawn_bones.get("RightHand", Vector3.ZERO)).snappedf(0.01)),
						(await _right_gap()) * 100.0])
				_tuck_worst = maxf(_tuck_worst, float(r[1]))
				_tuck_gap = minf(_tuck_gap, await _right_gap())
			if not got.has("hand_5_tucking") and m._tuck_hand != null:
				var rh := _drawn_bones.get("RightHand", Vector3.INF) as Vector3
				if rh != Vector3.INF and _tuck_gap < 0.03:
					got["hand_5_tucking"] = true
					await _shot("hand_5_tucking")
					await _hand_side("hand_5_tucking")
		if m.hand_caught and not m._hand_on and not m.tucking:
			break
	Input.action_release("move_up")
	print("held_child_probe: the small hand: %d checks of %d points, deepest in him %.1f cm (%s), deepest in its card %.1f mm (%s); nearest its card's face when taken %.1f mm; the grip %s %s" % [
		_hand_checks, _hand_pts, _hand_worst * 100.0, _hand_worst_at, _card_worst * 1000.0, _card_worst_at, _card_near * 1000.0, str(m.tiny_grip_ok), str(m._tiny_shut)])
	print("held_child_probe: Bram's hand over the blanket: %s, the bundle at most %.1f cm into him (his hand), his hand %.1f cm at nearest from its place; the coo asked for %d" % [
		str(_tuck_seen), _tuck_worst * 100.0, _tuck_gap * 100.0, m.coo_played])
	print("held_child_probe: as he took it the middle of his palm was %s from the card's middle (his own frame; its mark %s), his palm facing %s, his fingers pointing %s" % [
		str(m.take_palm_at.snappedf(0.005)), str(WhiteSky.TAKE_AT), str(m.take_palm_way.snappedf(0.05)), str(m.take_palm_fingers.snappedf(0.05))])
	print("held_child_probe: Bram takes the card: his hand %.1f cm from its place on the card as he took it, the card taken %s, at most %.1f cm from his palm as he carried it, in under the blanket %s" % [
		_take_gap * 100.0, str(m.card_taken), _take_palm_far * 100.0, str(m.card_tucked)])
	if not m.card_taken:
		fails.append("Bram didn't take the card")
	elif _take_gap > 0.04:
		fails.append("Bram's hand wasn't on the card when he took it (%.1f cm off)" % (_take_gap * 100.0))
	elif m.take_palm_at == Vector3.INF or absf(m.take_palm_at.y) > 0.03 or absf(m.take_palm_at.z) > 0.04 or m.take_palm_at.x > -0.06 or m.take_palm_at.x < -0.13:
		# (his palm's middle beside the card's near edge, level with its middle, at its face: his fingers on it)
		fails.append("Bram's fingers weren't on the card's edge when he took it (his palm %s from its middle)" % str(m.take_palm_at.snappedf(0.005)))
	elif _take_palm_far > 0.16:
		fails.append("the card left his hand as he carried it (%.1f cm)" % (_take_palm_far * 100.0))
	if not m.card_tucked:
		fails.append("the card didn't go in under the blanket")
	if not _tuck_seen:
		fails.append("Bram's hand didn't come over the blanket")
	elif _tuck_worst > TOL:
		fails.append("Bram's hand into the bundle")
	elif _tuck_gap > 0.09:
		fails.append("Bram's hand didn't get to the blanket")
	if m.coo_played != 1:
		fails.append("the coo asked for %d times" % m.coo_played)
	var gs := maxf(0.0, _grasp_to - _grasp_from)
	print("held_child_probe: its fingers grasping as it reached: at most %.2f, %.1f s of it" % [_grasp_most, gs])
	if _grasp_most < 0.8 or gs < 0.9:
		fails.append("the small hand's fingers didn't open and close as it reached")
	if _hand_checks == 0:
		fails.append("the small hand never came up")
	if _hand_worst > HAND_TOL:
		fails.append("the small hand in Bram")
	if _card_worst > 0.0015:
		fails.append("the small hand through its card")


func _hand_side(nm: String) -> void:
	if not _drawn or OS.get_cmdline_user_args().has("gameonly"):
		return
	var fig := m._bram as Figure3D
	var hp := m._hand_point()
	var own := fig.global_basis.orthonormalized() * Basis(Vector3.UP, fig._yaw)
	var was: String = m._cam_mode
	var wp := m._cam_pos
	var wl := m._cam_look
	var wf := m._cam.fov
	_at(hp + own * Vector3(0.9, 0.05, 0.1), hp + own * Vector3(0, -0.12, 0), 34.0)
	await _shot(nm + "_side")
	_at(hp + own * Vector3(-0.15, 0.08, 0.8), hp + own * Vector3(0, -0.08, 0), 34.0)
	await _shot(nm + "_front")
	_peek = false
	m._cam_mode = was
	m._cam_pos = wp
	m._cam_look = wl
	m._cam.fov = wf


func _measure_hand(what: String) -> void:
	await _bake_bram()
	_hand_checks += 1
	var pts := points_of(m._tiny, 1200)
	_hand_pts = pts.size()
	for p in pts:
		var d := _inside(p)
		if d > _hand_worst:
			_hand_worst = d
			_hand_worst_at = what
	# against its card (a box: CARD_SIZE by 6 mm, scaled)
	var card := m._mote.get_node_or_null("Card") as MeshInstance3D if m._mote != null and is_instance_valid(m._mote) else null
	if card == null:
		return
	var inv := card.global_transform.affine_inverse()
	var half := Vector3(WhiteSky.CARD_SIZE.x * 0.5, WhiteSky.CARD_SIZE.y * 0.5, 0.003)
	var sc := card.global_transform.basis.get_scale().x
	for p in pts:
		var q := inv * p
		var dx := half.x - absf(q.x)
		var dy := half.y - absf(q.y)
		var dz := half.z - absf(q.z)
		if m._tiny_curl > 0.97 and dx > 0.0 and dy > 0.0:
			_card_near = minf(_card_near, maxf(0.0, -dz) * sc)
		if dx > 0.0 and dy > 0.0 and dz > 0.0:
			var d := minf(dx, minf(dy, dz)) * sc
			if d > _card_worst:
				_card_worst = d
				_card_worst_at = what
