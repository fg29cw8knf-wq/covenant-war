extends Node
## Gary's 8 November notes after midnight, staged for real with stills (the
## game's shot and a close camera of the test's own) and measured as they play:
##
##   bed:    the awakening in the attic (AshfordNight.awakening): Bram's hand
##           on the player's shoulder sat on the bed, and again at the window
##           after "A Herald is approaching!" ("When Bram puts his hand on
##           player shoulder it goes through it when you're both sitting on
##           the bed"; "After it mentions about the Herald, Bram's arm
##           distorts"). Every frame his hand is reaching: his hand's bones
##           against the player's body as drawn (the player's own mesh,
##           skinned on the CPU from the bones' poses: inside it or not, and
##           how deep), the reach's target against the length of his arm, and
##           the bend at his elbow (a locked-straight arm reads as stretched);
##           his forearm with the hand; and the two bodies against each other
##           (sat together, and stood turned to each other at the window).
##   dawn:   the dawn and the Pale Herald (Ashford._dawn): the time each frame
##           takes through it ("after Hob's line, it takes a while to load":
##           the longest frames, and what was built in them), and from the
##           Herald's going to Bram's first hub line, each frame: his clip,
##           any held pose, his hips' height and whether either arm is still
##           reaching ("when it cuts to Bram he is crouched and distorted").
##           A stall is a frame longer than STALL_OVER times the usual frame
##           before Hob's line (and STALL_MS at least): under llvmpipe every
##           frame of the green is over a second, and a close shot of two
##           figures half as long again. Before the "Dawn" caption
##           the black must be up and the picture all black (the warm-up of
##           the Herald behind it): stills of it, and their brightest pixel.
##   cellar: That Day (AshfordNight.that_day): every bone of both figures
##           against the cellar's steps every frame ("his body is going
##           through the stairs"), and Bram's reach to each mark against his
##           arm (note 13).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/after_midnight_shot.tscn -- <out_dir> bed|dawn|cellar [every=10] [choice=0] [nomesh] [warmonly]
## Ends with "AFTER MIDNIGHT: ok" or the problems.

var out := "/tmp/after_midnight"
var part := "bed"
var every := 10
var choice := 0
var mesh_check := true
var warm_only := false   # dawn: stop once the "Dawn" caption is up (the warm-up checked, a minute's run)
var world: World
var cam: Camera3D
var problems: Array = []
var _frame := 0
var _busy := false
var _done := false
var _line_frames := 0
var _line := ""
var _lines := 0
var _start_part := ""
var _t_prev := 0
var _dts: Array = []


var _body = null


func _ready() -> void:
	# (11 November: "oldwrist" turns hands at the wrist alone, however far, as
	# they were until then: Figure3D.wrist_natural, the before)
	if "oldwrist" in OS.get_cmdline_user_args():
		Figure3D.wrist_natural = false
	# (12 November: "hinge" bends the reaching arms at the elbow's hinge,
	# Figure3D.pole_hinge, to see against the old way; "body" runs the body
	# check over it, tests/body_check.gd)
	if "hinge" in OS.get_cmdline_user_args():
		Figure3D.pole_hinge = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		part = args[1]
	for a in args.slice(2):
		var s := String(a)
		if s.begins_with("every="):
			every = int(s.substr(6))
		elif s.begins_with("choice="):
			choice = int(s.substr(7))
		elif s == "nomesh":
			mesh_check = false
		elif s == "warmonly":
			warm_only = true
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Rowan", "")
	Game.settings["first_steps"] = 2
	for f in ["arrived_ashford", "ash_started", "ash_tam", "ash_tilly", "ash_nell", "ash_ready", "tilly_talked", "ash_evening",
			"first_deck", "has_lantern_moth", "moth_given", "ash_lantern_duel", "ash_won_lantern", "ash_marked"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	Game.set_flag("pro_part", {"bed": "awakening", "dawn": "dawn", "cellar": "that_day"}.get(part, "awakening"))
	_start_part = String(Game.flag("pro_part"))
	world = World.new().setup("ashford", "green")
	world.story_next.connect(func(_w: String) -> void: _finish())
	add_child(world)
	if "body" in OS.get_cmdline_user_args():
		_body = load("res://tests/body_check.gd").watch(world, out.path_join("body"))
	cam = Camera3D.new()
	add_child(cam)
	for i in 20:
		await get_tree().process_frame
	print("AFTER MIDNIGHT: %s, player %s" % [part, (world.player_doll as Figure3D)._model_name if world.player_doll is Figure3D else "?"])
	_t_prev = Time.get_ticks_usec()
	match part:
		"bed":
			_watch_bed()
		"dawn":
			_watch_dawn()
		"cellar":
			_watch_cellar()


func _finish() -> void:
	if _done:
		return
	_done = true
	match part:
		"bed":
			_sum_bed()
		"dawn":
			_sum_dawn()
		"cellar":
			_sum_cellar()
	if _body != null:
		print(_body.summary())
	print("AFTER MIDNIGHT: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _process(_d: float) -> void:
	_frame += 1
	if world == null or _done:
		return
	var now := Time.get_ticks_usec()
	var dt := float(now - _t_prev) / 1000.0
	_t_prev = now
	if part == "dawn":
		_frame_time(dt)
	# tap through lines and choices (a line is left up a few frames)
	if world.has_meta("cine_overlay"):
		var ov: CineOverlay = world.get_meta("cine_overlay")
		if ov._waiting:
			_line_frames += 1
			if _line_frames == 2:
				var txt := ov._line.get_parsed_text().strip_edges()
				if txt != "" and txt != _line:
					_line = txt
					_lines += 1
					print("  f%d line %d: %s" % [_frame, _lines, txt.left(70)])
					_on_line(txt)
			if _line_frames > 8 and not _busy:
				_line_frames = 0
				ov._next.emit()
		else:
			_line_frames = 0
		if ov._choices.visible and ov._choices.get_child_count() > 0 and not _busy:
			ov._chosen.emit(mini(choice, ov._choices.get_child_count() - 1))
	if world.hud != null and world.hud.dialogue._waiting and not _busy:
		world.hud.dialogue._advance.emit()
	if _frame > 30 and String(Game.flag("pro_part")) != _start_part:
		_finish()
		return
	match part:
		"bed":
			_bed_frame()
		"dawn":
			_dawn_frame()
		"cellar":
			_cellar_frame()


func _on_line(txt: String) -> void:
	match part:
		"bed":
			_on_line_bed(txt)
		"dawn":
			_on_line_dawn(txt)


# ============================================================ the mesh ===

## The player's upper body as drawn: the triangles of their mesh whose
## vertices follow the upper body's bones, skinned on the CPU from the bones'
## poses this frame (world space). [PackedVector3Array verts, PackedInt32Array tris]
const UPPER := ["Spine", "Spine1", "Spine2", "Neck", "Head", "LeftShoulder", "LeftArm", "LeftForeArm", "RightShoulder", "RightArm", "RightForeArm"]
var _mesh_src := []   # per surface: {mi, verts, bones, weights, stride, idx, keep (PackedByteArray), binds (Array of Transform3D), bind_bones}


func _mesh_prepare(fig: Figure3D) -> void:
	_mesh_src.clear()
	var sk: Skeleton3D = fig._skel
	if sk == null:
		return
	var upper := {}
	for b in UPPER:
		var i := sk.find_bone(b)
		if i >= 0:
			upper[i] = true
	var nv := 0
	var nt := 0
	for mi: MeshInstance3D in fig.model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skin == null:
			continue
		var skin: Skin = mi.skin
		var binds: Array = []
		var bind_bones: Array = []
		for k in skin.get_bind_count():
			binds.append(skin.get_bind_pose(k))
			var bn := skin.get_bind_bone(k)
			if bn < 0:
				bn = sk.find_bone(skin.get_bind_name(k))
			bind_bones.append(bn)
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			var idx = arr[Mesh.ARRAY_INDEX]
			if verts.is_empty() or bones == null or weights == null:
				continue
			var stride: int = int(bones.size() / verts.size())
			var keep := PackedByteArray()
			keep.resize(verts.size())
			for vi in verts.size():
				var best := -1
				var bw := -1.0
				for j in stride:
					var wgt := float(weights[vi * stride + j])
					if wgt > bw:
						bw = wgt
						best = int(bones[vi * stride + j])
				var bone_i: int = bind_bones[best] if best >= 0 and best < bind_bones.size() else -1
				keep[vi] = 1 if upper.has(bone_i) else 0
			var tris := PackedInt32Array()
			if idx == null or (idx as PackedInt32Array).is_empty():
				for t in range(0, verts.size() - 2, 3):
					if keep[t] == 1 and keep[t + 1] == 1 and keep[t + 2] == 1:
						tris.append_array([t, t + 1, t + 2])
			else:
				var ix: PackedInt32Array = idx
				for t in range(0, ix.size() - 2, 3):
					if keep[ix[t]] == 1 and keep[ix[t + 1]] == 1 and keep[ix[t + 2]] == 1:
						tris.append_array([ix[t], ix[t + 1], ix[t + 2]])
			_mesh_src.append({"mi": mi, "verts": verts, "bones": bones, "weights": weights, "stride": stride, "tris": tris,
				"keep": keep, "binds": binds, "bind_bones": bind_bones})
			nv += verts.size()
			nt += tris.size() / 3
	print("  mesh: %d surfaces, %d vertices, %d upper-body triangles" % [_mesh_src.size(), nv, nt])
	# the shoulder as modelled (rest pose): how far its top is above the Arm
	# joint, and how far out its side is, for the hand's target
	for side in ["Left", "Right"]:
		var ai := sk.find_bone(side + "Arm")
		if ai < 0:
			continue
		var aj := sk.get_bone_global_rest(ai).origin
		var top := -INF
		var outer := 0.0
		var fwd := 0.0
		var back := 0.0
		for src in _mesh_src:
			var verts: PackedVector3Array = src.verts
			var keep: PackedByteArray = src.keep
			for vi in verts.size():
				if keep[vi] == 0:
					continue
				var p: Vector3 = verts[vi]
				if absf(p.x - aj.x) < 0.035 and absf(p.z - aj.z) < 0.035 and p.y > aj.y - 0.02 and p.y < aj.y + 0.2:
					top = maxf(top, p.y - aj.y)
				if absf(p.y - aj.y) < 0.03 and absf(p.z - aj.z) < 0.03:
					outer = maxf(outer, absf(p.x - aj.x))
				if absf(p.y - aj.y) < 0.03 and absf(p.x - aj.x) < 0.03:
					fwd = maxf(fwd, p.z - aj.z)
					back = maxf(back, aj.z - p.z)
		print("  %s shoulder (rest): top %.1f cm above the joint, %.1f cm out from it, %.1f cm forward, %.1f cm back" % [side, top * 100.0, outer * 100.0, fwd * 100.0, back * 100.0])


## The upper body's triangles this frame, world space.
func _mesh_now(fig: Figure3D) -> Array:
	var sk: Skeleton3D = fig._skel
	var xf := sk.global_transform
	var out_v := PackedVector3Array()
	var out_t := PackedInt32Array()
	for src in _mesh_src:
		var verts: PackedVector3Array = src.verts
		var bones = src.bones
		var weights = src.weights
		var stride: int = src.stride
		var keep: PackedByteArray = src.keep
		var binds: Array = src.binds
		var bind_bones: Array = src.bind_bones
		# each bind's full transform this frame
		var bx: Array = []
		for k in binds.size():
			var bn: int = bind_bones[k]
			bx.append((xf * sk.get_bone_global_pose(bn) * (binds[k] as Transform3D)) if bn >= 0 else xf)
		var base := out_v.size()
		var map := PackedInt32Array()
		map.resize(verts.size())
		for vi in verts.size():
			if keep[vi] == 0:
				map[vi] = -1
				continue
			var p := Vector3.ZERO
			var tot := 0.0
			for j in stride:
				var wgt := float(weights[vi * stride + j])
				if wgt <= 0.0:
					continue
				var b: int = int(bones[vi * stride + j])
				if b >= bx.size():
					continue
				p += (bx[b] as Transform3D) * verts[vi] * wgt
				tot += wgt
			if tot > 0.0:
				p /= tot
			map[vi] = out_v.size()
			out_v.append(p)
		var tris: PackedInt32Array = src.tris
		for t in range(0, tris.size() - 2, 3):
			out_t.append_array([map[tris[t]], map[tris[t + 1]], map[tris[t + 2]]])
	return [out_v, out_t]


## Is `p` inside the closed surface (an odd number of crossings along a ray)?
## And how far it is from the surface's nearest vertex (m).
func _inside(mesh: Array, p: Vector3) -> Array:
	var v: PackedVector3Array = mesh[0]
	var t: PackedInt32Array = mesh[1]
	var dir := Vector3(0.21, 0.93, 0.31).normalized()
	var hits := 0
	for i in range(0, t.size() - 2, 3):
		if Geometry3D.ray_intersects_triangle(p, dir, v[t[i]], v[t[i + 1]], v[t[i + 2]]) != null:
			hits += 1
	var near := INF
	for q in v:
		near = minf(near, q.distance_squared_to(p))
	return [hits % 2 == 1, sqrt(near)]


# ============================================================== the bed ===

const HAND_BONES := ["Hand", "HandIndex1", "HandIndex2", "HandIndex3", "HandMiddle1", "HandMiddle2", "HandMiddle3",
	"HandRing1", "HandRing3", "HandPinky1", "HandPinky3", "HandThumb2", "HandThumb3"]
var _bed_phase := "bed"       # "bed" until the Herald line, then "window"
var _bed_stats := {}          # phase -> {frames, in_frames, deep, worst_bone, reach_over, straight, elbow_min}
var _bed_mesh_n := 0
var _bed_tracked := false
var _bed_last_still := -100


func _watch_bed() -> void:
	var bf := Cine.fig(world, "bram") as Figure3D
	var pf := world.player_doll as Figure3D
	if bf == null or pf == null:
		problems.append("no 3D Bram or player")
		return
	if mesh_check:
		_mesh_prepare(pf)
	for ph in ["bed", "window"]:
		_bed_stats[ph] = {"frames": 0, "in_frames": 0, "deep": 0.0, "worst": "", "worst_frame": 0, "reach": 0.0, "reach_over": 0,
			"elbow_min": 180.0, "elbow_max": 0.0, "straight": 0, "target_d": 0.0, "arm": bf.arm_reach() + 0.075 * bf.stature(),
			"mesh_in": 0, "mesh_checked": 0, "mesh_deep": 0.0, "mesh_worst": "", "meet_frames": 0, "meet": 0.0, "meet_worst": "", "gap": INF}
	bf._skel.skeleton_updated.connect(func() -> void: _bed_measure(bf, pf))


func _on_line_bed(txt: String) -> void:
	if txt.find("Herald is approaching") >= 0:
		_bed_phase = "window"


func _bed_measure(bf: Figure3D, pf: Figure3D) -> void:
	if _done:
		return
	var ik = bf._ik.get("right")
	if ik == null or not is_instance_valid(ik) or not (ik as TwoBoneIK3D).active or (ik as TwoBoneIK3D).influence < 0.5:
		_bed_tracked = false
		return
	var st: Dictionary = _bed_stats[_bed_phase]
	st.frames += 1
	var sk: Skeleton3D = bf._skel
	var xf := sk.global_transform
	# the reach: the target's distance from his shoulder against his arm
	var tgt = ik.get_meta("target") if ik.has_meta("target") else null
	var sh := xf * sk.get_bone_global_pose(sk.find_bone("RightArm")).origin
	var el := xf * sk.get_bone_global_pose(sk.find_bone("RightForeArm")).origin
	var hd := xf * sk.get_bone_global_pose(sk.find_bone("RightHand")).origin
	if tgt != null and is_instance_valid(tgt):
		var d := sh.distance_to((tgt as Node3D).global_position)
		st.target_d = maxf(st.target_d, d)
		if d > st.arm:
			st.reach_over += 1
			st.reach = maxf(st.reach, d - st.arm)
	var elbow := rad_to_deg((sh - el).angle_to(hd - el))
	st.elbow_min = minf(st.elbow_min, elbow)
	st.elbow_max = maxf(st.elbow_max, elbow)
	if elbow > 172.0:
		st.straight += 1
	# his hand's bones against the player's body: quick capsules every frame
	var pts := {}
	for bn in HAND_BONES:
		var b := sk.find_bone("Right" + bn)
		if b >= 0:
			pts[bn] = xf * sk.get_bone_global_pose(b).origin
	pts["palm"] = bf._palm_point("Right")
	if st.frames == 25 or st.frames == 8 or st.frames == 9:
		# the hand's bones from the wrist, settled on the shoulder (cm), and the shoulder joint from the wrist
		var jb := "LeftArm" if pf.bone_pos("LeftArm").distance_to(hd) < pf.bone_pos("RightArm").distance_to(hd) else "RightArm"
		var jp := pf._skel.global_transform * pf._skel.get_bone_global_pose(pf._skel.find_bone(jb)).origin
		var jq := pf.bone_pos(jb)
		var row := "  f%d %s: his right hand's bones from the wrist (cm), the player's %s joint at (%.1f, %.1f, %.1f) by the skeleton, (%.1f, %.1f, %.1f) by bone_pos, the player's hips %.2f up: " % [_frame, _bed_phase, jb, (jp.x - hd.x) * 100.0, (jp.y - hd.y) * 100.0, (jp.z - hd.z) * 100.0, (jq.x - hd.x) * 100.0, (jq.y - hd.y) * 100.0, (jq.z - hd.z) * 100.0, pf.bone_pos("Hips").y - pf.global_position.y]
		for k in pts:
			var q: Vector3 = pts[k] - hd
			row += "%s (%.1f, %.1f, %.1f)  " % [k, q.x * 100.0, q.y * 100.0, q.z * 100.0]
		print(row)
		if st.frames == 8:
			# and at rest (the skeleton's own frame), from the wrist: where the thumb lies against the palm as modelled
			var r0 := sk.get_bone_global_rest(sk.find_bone("RightHand")).origin
			var rrow := "  his right hand at rest, from the wrist (cm): "
			for bn in HAND_BONES:
				var bi := sk.find_bone("Right" + bn)
				if bi >= 0:
					var q := sk.get_bone_global_rest(bi).origin - r0
					rrow += "%s (%.1f, %.1f, %.1f)  " % [bn, q.x * 100.0, q.y * 100.0, q.z * 100.0]
			print(rrow)
	# (and the forearm, elbow to wrist: it comes to the shoulder from behind
	# or in front, past the back or the chest)
	for k in [0.3, 0.55, 0.8]:
		pts["forearm_%d" % int(k * 100)] = el.lerp(hd, k)
	var deep := 0.0
	var worst := ""
	var thumb := 0.0
	for k in pts:
		var dd := _in_player(pf, pts[k], HAND_SKIN if not String(k).begins_with("forearm") else 0.035)
		if String(k).begins_with("HandThumb"):
			# (the thumb apart: on Bram's model it rests folded under the
			# palm, its tip 7 cm below it, so a palm laid flat on anything
			# has it in that thing; reported, not counted)
			thumb = maxf(thumb, dd)
			continue
		if dd > deep:
			deep = dd
			worst = k
	st.thumb = maxf(float(st.get("thumb", 0.0)), thumb)
	if deep > 0.0:
		st.in_frames += 1
		if deep > st.deep:
			st.deep = deep
			st.worst = worst
			st.worst_frame = _frame
	# the two bodies against each other (his trunk, head and his other arm
	# against the player's trunk, head and arms)
	var bd := _bodies_meet(bf, pf)
	if float(bd[0]) > 0.0:
		st.meet_frames += 1
		if float(bd[0]) > st.meet:
			st.meet = float(bd[0])
			st.meet_worst = "%s f%d" % [bd[1], _frame]
	# and against the mesh itself every few frames (slow)
	if mesh_check and not _mesh_src.is_empty() and (_frame % maxi(1, every / 2) == 0):
		var m := _mesh_now(pf)
		st.mesh_checked += 1
		var any := false
		for k in pts:
			var r: Array = _inside(m, pts[k])
			if r[0]:
				if String(k).begins_with("HandThumb"):
					st.mesh_thumb = st.get("mesh_thumb", 0) + 1
					continue
				any = true
				if float(r[1]) > st.mesh_deep:
					st.mesh_deep = float(r[1])
					st.mesh_worst = "%s f%d" % [k, _frame]
		if any:
			st.mesh_in += 1
	if _frame - _bed_last_still >= (every if _bed_phase == "bed" else maxi(1, every / 3)):
		_bed_last_still = _frame
		var tp: Vector3 = (tgt as Node3D).global_position if tgt != null and is_instance_valid(tgt) else Vector3.INF
		print("  f%d %s: bram at %s facing %s, player at %s facing %s; his R shoulder %s elbow %s wrist %s palm %s; target %s; player's L shoulder %s R shoulder %s; deep %.1f cm (%s)" % [
			_frame, _bed_phase, _v(bf.global_position), _v(bf.facing()), _v(pf.global_position), _v(pf.facing()), _v(sh), _v(el), _v(hd), _v(pts.get("palm", hd)), _v(tp),
			_v(pf.bone_pos("LeftArm")), _v(pf.bone_pos("RightArm")), deep * 100.0, worst])
		_bed_still("%s_f%05d" % [_bed_phase, _frame], bf, pf, pts.get("palm", hd))


func _v(p: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [p.x, p.y, p.z]


## How deep a point is in the player's shoulder, upper arm, neck or chest
## (capsules round the bones, radii as Player A's mesh has them: see
## PLAYER_R), m; 0 outside.
const PLAYER_R := {"shoulder": 0.10, "upper_arm": 0.055, "neck": 0.06, "chest": 0.11, "head": 0.1}
const HAND_SKIN := 0.012


func _in_player(pf: Figure3D, p: Vector3, skin := HAND_SKIN) -> float:
	var sk: Skeleton3D = pf._skel
	var xf := sk.global_transform
	var bp := func(n: String) -> Vector3: return xf * sk.get_bone_global_pose(sk.find_bone(n)).origin
	var deep := 0.0
	for side in ["Left", "Right"]:
		var a: Vector3 = bp.call(side + "Arm")
		var f: Vector3 = bp.call(side + "ForeArm")
		deep = maxf(deep, PLAYER_R.shoulder + skin - a.distance_to(p))
		deep = maxf(deep, PLAYER_R.upper_arm + skin - _seg_dist(p, a, f))
	var la: Vector3 = bp.call("LeftArm")
	var ra: Vector3 = bp.call("RightArm")
	var nk: Vector3 = bp.call("Neck")
	var hd: Vector3 = bp.call("Head")
	var sp: Vector3 = bp.call("Spine1")
	var hp: Vector3 = bp.call("Hips")
	deep = maxf(deep, PLAYER_R.chest + skin - _seg_dist(p, la, ra))
	deep = maxf(deep, PLAYER_R.chest + skin - _seg_dist(p, sp, nk))
	deep = maxf(deep, PLAYER_R.chest + skin - _seg_dist(p, hp, sp))
	deep = maxf(deep, PLAYER_R.neck + skin - _seg_dist(p, nk, hd))
	deep = maxf(deep, PLAYER_R.head + skin - hd.distance_to(p + Vector3(0, -0.08, 0)))
	return maxf(0.0, deep)


## Bram's trunk, head and left arm (not the arm that reaches) against the
## player's body: [the deepest overlap (m), which of his bones]. Radii as
## his coat model has them (BRAM_R).
const BRAM_R := {"Hips": 0.16, "Spine": 0.15, "Spine1": 0.15, "Spine2": 0.15, "Neck": 0.06, "Head": 0.11,
	"LeftArm": 0.06, "LeftForeArm": 0.045, "LeftHand": 0.02, "RightArm": 0.06}


func _bodies_meet(bf: Figure3D, pf: Figure3D) -> Array:
	var sk: Skeleton3D = bf._skel
	var xf := sk.global_transform
	var deep := 0.0
	var worst := ""
	for bn in BRAM_R:
		var b := sk.find_bone(bn)
		if b < 0:
			continue
		var p := xf * sk.get_bone_global_pose(b).origin
		var pts := [p]
		for c in sk.get_bone_children(b):
			var q := xf * sk.get_bone_global_pose(c).origin
			for k in [0.33, 0.66]:
				pts.append(p.lerp(q, k))
			break
		for q in pts:
			var d := _in_player(pf, q, BRAM_R[bn])
			if d > deep:
				deep = d
				worst = bn
	return [deep, worst]


func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	return Geometry3D.get_closest_point_to_segment(p, a, b).distance_to(p)


func _bed_frame() -> void:
	pass


## The game's shot, then close on the hand from in front of the two of them
## and from above Bram's side.
func _bed_still(tag: String, bf: Figure3D, pf: Figure3D, hand: Vector3) -> void:
	if _busy:
		return
	_busy = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_game.png" % [out, tag])
	var fwd: Vector3 = pf.facing()
	var side := fwd.cross(Vector3.UP)
	var to_bram := bf.global_position - pf.global_position
	to_bram.y = 0.0
	if side.dot(to_bram) < 0.0:
		side = -side   # (Bram's side)
	if to_bram.normalized().dot(fwd) > 0.6:
		# face to face (the window): from beside the two of them
		fwd = side
		side = -pf.facing()
	var shots := {
		"front": [hand + fwd * 0.9 + side * 0.25 + Vector3(0, 0.15, 0), hand, 30.0],
		"above": [hand + side * 0.55 + Vector3(0, 0.55, 0) - fwd * 0.3, hand, 30.0],
		"behind": [hand - fwd * 0.8 + side * 0.4 + Vector3(0, 0.3, 0), hand, 30.0],
	}
	for k in shots:
		var s: Array = shots[k]
		cam.global_position = s[0]
		cam.look_at(s[1], Vector3.UP)
		cam.fov = s[2]
		cam.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, k])
	world.cam.make_current()
	_busy = false


func _sum_bed() -> void:
	for ph in ["bed", "window"]:
		var st: Dictionary = _bed_stats[ph]
		print("  %s: %d frames reaching; capsules: in the player %d frames, deepest %.1f cm (%s, f%d); mesh: %d of %d checked frames inside, deepest %.1f cm from the skin (%s); the thumb apart: %.1f cm in by the capsules, in the mesh %d checked frames; target %.2f m from the shoulder (arm %.2f), over it %d frames by %.1f cm; elbow %.0f..%.0f deg, locked straight %d frames; his body into the player's %d frames, deepest %.1f cm (%s)" % [
			ph, st.frames, st.in_frames, st.deep * 100.0, st.worst, st.worst_frame, st.mesh_in, st.mesh_checked, st.mesh_deep * 100.0, st.mesh_worst, float(st.get("thumb", 0.0)) * 100.0, st.get("mesh_thumb", 0),
			st.target_d, st.arm, st.reach_over, st.reach * 100.0, st.elbow_min, st.elbow_max, st.straight, st.meet_frames, st.meet * 100.0, st.meet_worst])
		if st.frames == 0:
			problems.append("%s: Bram's hand never reached" % ph)
			continue
		if st.deep > 0.01:
			problems.append("%s: Bram's hand %.1f cm into the player (%s) in %d frames" % [ph, st.deep * 100.0, st.worst, st.in_frames])
		if mesh_check and st.mesh_in > 0:
			problems.append("%s: Bram's hand bones inside the player's mesh in %d of %d checked frames (%.1f cm, %s)" % [ph, st.mesh_in, st.mesh_checked, st.mesh_deep * 100.0, st.mesh_worst])
		if st.reach_over > 2:
			problems.append("%s: the shoulder was out of Bram's reach by %.1f cm in %d frames" % [ph, st.reach * 100.0, st.reach_over])
		if st.straight > 5:
			problems.append("%s: Bram's arm locked straight (>172 deg) in %d frames" % [ph, st.straight])
		if st.meet > 0.02:
			problems.append("%s: Bram's %s %.1f cm into the player's body in %d frames" % [ph, st.meet_worst, st.meet * 100.0, st.meet_frames])


# ============================================================= the dawn ===

var _dawn_hitches: Array = []     # [frame, ms, line, dn]
var _dawn_nodes := 0
var _dawn_watch := false          # from the Herald's last line to Bram's first hub line
var _dawn_rows: Array = []
var _dawn_stand_hips := 0.0
var _dawn_crouched := 0
var _dawn_ik_walk := 0
var _dawn_last_still := -100
var _dawn_hob_frame := -1
var _dawn_worst := 0.0
var _dawn_worst_frame := 0
var _dawn_worst_line := ""
var _dawn_usual: Array = []        # the frames' ms before Hob's line (from f60)
var _dawn_caption := false         # the "Dawn" caption has come up
var _dawn_black_lost := 0          # frames before it with the black not fully up
var _dawn_bright := 0.0            # the brightest pixel seen in a still before it
var _dawn_bright_frame := 0
var _dawn_warm_still := -100
var _busy_frame := -100            # the last frame the test was taking stills in (its own cost, not the game's)
const STALL_OVER := 2.0   # (Gary's stall was 2.8 times the usual frame, with 176 nodes built in it; a close two-shot under llvmpipe is 1.3 to 1.6 times an ordinary one)
const STALL_MS := 250.0


func _watch_dawn() -> void:
	var bf := Cine.fig(world, "bram") as Figure3D
	if bf != null:
		_dawn_stand_hips = bf._hips


func _frame_time(ms: float) -> void:
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var dn := nodes - _dawn_nodes
	_dawn_nodes = nodes
	if _frame < (2 if warm_only else 30):
		return
	var black := 0.0
	if world.has_meta("cine_overlay"):
		black = (world.get_meta("cine_overlay") as CineOverlay)._black.modulate.a
	if _busy:
		_busy_frame = _frame
	var own := _frame - _busy_frame <= 1   # (the test's own stills: a few PNGs saved and cameras switched)
	if ms > 60.0:
		_dawn_hitches.append([_frame, ms, _line.left(40), dn, black, own])
	if _dawn_hob_frame < 0 and _frame >= 60:
		_dawn_usual.append(ms)
	if own:
		return
	if _dawn_hob_frame > 0 and _frame - _dawn_hob_frame < 400 and ms > _dawn_worst:
		_dawn_worst = ms
		_dawn_worst_frame = _frame
		_dawn_worst_line = _line.left(40)


func _on_line_dawn(txt: String) -> void:
	if txt.begins_with("Lost half the barley"):
		_dawn_hob_frame = _frame
		print("  f%d: Hob's line (the stall comes after it)" % _frame)
	if txt.begins_with("A Pale Herald") or txt.begins_with("Glyphmere"):
		_dawn_still("kneel_f%05d" % _frame)
		_kneel_report()
	if txt.find("I name the Unsworn") >= 0:
		_dawn_watch = true
	if txt.find("Covenant's shadow") >= 0 or txt.find("Because a Champion") >= 0:
		# his first hub line is up: a last still, and done watching
		_dawn_still("hub_f%05d" % _frame)
		_dawn_watch = false


## Everyone on one knee: each 3D figure's knee, feet and hips over the
## ground under them (the knee KNEEL_PAD up, nothing under the grass).
func _kneel_report() -> void:
	for who in ["bram", "player", "corin", "nell", "tam", "hob", "ned", "tilly", "kid"]:
		var f = Cine.fig(world, who)
		var b := Cine.body(world, who)
		if not (f is Figure3D) or b == null:
			continue
		var fig := f as Figure3D
		var g := Cine.ground(world, b.global_position)
		var parts := {}
		var lowest := INF
		var low_bone := ""
		for bn in ["RightLeg", "LeftLeg", "RightFoot", "LeftFoot", "RightToeBase", "LeftToeBase", "Hips"]:
			if fig._skel.find_bone(bn) < 0:
				continue
			var y := fig.bone_pos(bn).y - g
			parts[bn] = y
			if bn != "Hips" and y < lowest:
				lowest = y
				low_bone = bn
		var row := "  %s kneeling (%s): " % [who, fig._clip]
		for bn in parts:
			row += "%s %.2f  " % [bn, parts[bn]]
		print(row)
		if lowest < -0.03:
			problems.append("%s's %s %.1f cm under the grass on their knee" % [who, low_bone, -lowest * 100.0])


func _dawn_frame() -> void:
	if not _dawn_caption and world.has_meta("cine_overlay"):
		var ov: CineOverlay = world.get_meta("cine_overlay")
		if ov._cap.modulate.a > 0.01:
			_dawn_caption = true
			print("  f%d: the \"Dawn\" caption is up (the warm-up was before it)" % _frame)
			if warm_only:
				_finish()
				return
		elif _frame >= 2:
			if ov._black.modulate.a < 0.999:
				_dawn_black_lost += 1
			if _frame - _dawn_warm_still >= every:
				_dawn_warm_still = _frame
				_warm_still("warm_f%05d" % _frame)
	if not _dawn_watch:
		return
	var bf := Cine.fig(world, "bram") as Figure3D
	if bf == null:
		return
	var b := Cine.body(world, "bram")
	var hips := bf.bone_pos("Hips").y - b.global_position.y
	var l_ik = bf._ik.get("left")
	var r_ik = bf._ik.get("right")
	var l_on := l_ik != null and is_instance_valid(l_ik) and (l_ik as TwoBoneIK3D).active and (l_ik as TwoBoneIK3D).influence > 0.05
	var r_on := r_ik != null and is_instance_valid(r_ik) and (r_ik as TwoBoneIK3D).active and (r_ik as TwoBoneIK3D).influence > 0.05
	var row := "f%d clip %s action '%s' held %s anim %s %s pos %.2f walking %s hips %.2f (standing %.2f) ik L %s R %s rot %s" % [
		_frame, bf._clip, bf._action, bf._held, bf.anim.current_animation, "playing" if bf.anim.is_playing() else "PAUSED",
		bf.anim.current_animation_position, bf.walking, hips, _dawn_stand_hips, l_on, r_on, bf.rotation]
	_dawn_rows.append(row)
	if _frame % 5 == 0:
		print("  ", row)
	if bf.walking and hips < _dawn_stand_hips - 0.08:
		_dawn_crouched += 1
	if bf.walking and (l_on or r_on):
		_dawn_ik_walk += 1
	if _frame - _dawn_last_still >= every:
		_dawn_last_still = _frame
		_dawn_still("bram_f%05d" % _frame)


## A still of the game's picture before the caption, and its brightest pixel
## (the black should be up: nothing of the Herald's warm-up may show).
func _warm_still(tag: String) -> void:
	if _busy:
		return
	_busy = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s_game.png" % [out, tag])
	var bright := 0.0
	for y in range(0, img.get_height(), 6):
		for x in range(0, img.get_width(), 6):
			var c := img.get_pixel(x, y)
			bright = maxf(bright, maxf(c.r, maxf(c.g, c.b)))
	print("  f%d warm-up still: brightest pixel %.3f, %d nodes" % [_frame, bright, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	if bright > _dawn_bright:
		_dawn_bright = bright
		_dawn_bright_frame = _frame
	_busy = false


func _dawn_still(tag: String) -> void:
	if _busy:
		return
	_busy = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_game.png" % [out, tag])
	var b := Cine.body(world, "bram")
	var bf := Cine.fig(world, "bram") as Figure3D
	if b != null and bf != null:
		var at := b.global_position + Vector3(0, 0.95, 0)
		var fwd: Vector3 = bf.facing()
		var side := fwd.cross(Vector3.UP)
		var shots := {"side": [at + side * 2.6 + Vector3(0, 0.3, 0), at, 36.0], "front": [at + fwd * 2.4 + side * 0.6 + Vector3(0, 0.35, 0), at, 36.0]}
		for k in shots:
			var s: Array = shots[k]
			cam.global_position = s[0]
			cam.look_at(s[1], Vector3.UP)
			cam.fov = s[2]
			cam.make_current()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, k])
	world.cam.make_current()
	_busy = false


func _sum_dawn() -> void:
	print("  frames over 60 ms (frame, ms, line up, nodes added, the black's alpha):")
	for h in _dawn_hitches:
		print("    f%d %.0f ms  '%s'  %+d nodes  black %.2f%s" % [h[0], h[1], h[2], h[3], h[4], "  (the test's stills)" if h[5] else ""])
	var usual := 0.0
	if not _dawn_usual.is_empty():
		var srt := _dawn_usual.duplicate()
		srt.sort()
		usual = float(srt[srt.size() / 2])
	print("  the usual frame before Hob's line: %.0f ms (median of %d); the longest frame in the 40 s after Hob's line: %.0f ms at f%d ('%s'), %.2f times the usual" % [
		usual, _dawn_usual.size(), _dawn_worst, _dawn_worst_frame, _dawn_worst_line, _dawn_worst / maxf(usual, 1.0)])
	print("  before the caption: the black not fully up in %d frames; the brightest pixel in a still %.3f (f%d)" % [_dawn_black_lost, _dawn_bright, _dawn_bright_frame])
	if _dawn_black_lost > 0:
		problems.append("the black was not fully up in %d frames before the Dawn caption" % _dawn_black_lost)
	if _dawn_bright > 0.02:
		problems.append("something showed before the Dawn caption (brightest pixel %.2f at f%d)" % [_dawn_bright, _dawn_bright_frame])
	var f := FileAccess.open(out.path_join("bram_rows.txt"), FileAccess.WRITE)
	if f != null:
		for r in _dawn_rows:
			f.store_line(r)
	print("  Bram from the Herald's going to his hub: %d frames watched, crouched while walking %d, an arm reaching while walking %d (rows in bram_rows.txt)" % [_dawn_rows.size(), _dawn_crouched, _dawn_ik_walk])
	if _dawn_crouched > 0:
		problems.append("Bram walked crouched for %d frames after the Herald" % _dawn_crouched)
	if _dawn_ik_walk > 0:
		problems.append("Bram's arm was still reaching while he walked for %d frames" % _dawn_ik_walk)
	if _dawn_hob_frame > 0 and _dawn_worst > maxf(STALL_MS, usual * STALL_OVER):
		problems.append("a %.0f ms frame after Hob's line (f%d), %.1f times the usual %.0f ms" % [_dawn_worst, _dawn_worst_frame, _dawn_worst / maxf(usual, 1.0), usual])


# =========================================================== the cellar ===

var _steps: Array = []        # the steps' boxes (world AABBs)
var _cask: Array = []         # [centre, radius, half height]
var _cellar_stats := {}       # who -> {frames, in_frames, deep, worst, worst_frame}
var _cellar_reach := {"n": 0, "over": 0, "by": 0.0, "d": 0.0, "arm": 0.0, "elbow_min": 180.0, "straight": 0, "cask": 0, "cask_deep": 0.0,
	"timber": 0, "timber_deep": 0.0, "timber_bone": "", "knee_timber": 0.0, "knee_timber_bone": "", "knee_floor": INF, "knee_floor_bone": ""}
var _timber_x := INF         # the timber's face (world x; the room is at +x of it)
var _cellar_knelt := false   # Bram has been seen down at the marks
const RK_BODY := 0.24
var _cellar_last_still := -100
const BONE_R := {"Hips": 0.12, "Spine": 0.11, "Spine1": 0.11, "Spine2": 0.11, "Neck": 0.05, "Head": 0.1,
	"LeftUpLeg": 0.07, "RightUpLeg": 0.07, "LeftLeg": 0.05, "RightLeg": 0.05, "LeftFoot": 0.04, "RightFoot": 0.04, "LeftToeBase": 0.03, "RightToeBase": 0.03,
	"LeftArm": 0.05, "RightArm": 0.05, "LeftForeArm": 0.04, "RightForeArm": 0.04, "LeftHand": 0.012, "RightHand": 0.012}


func _watch_cellar() -> void:
	var v: AshfordVillage = world.get_meta("village")
	var r := InnRooms.cellar(v)
	var root: Node3D = r.root
	var W := 6.5
	for k in 8:
		var c := root.to_global(Vector3(W * 0.5 - 0.6, 0.15 + k * 0.3, 1.9 - k * 0.32))
		_steps.append(AABB(c - Vector3(0.55, 0.15, 0.16), Vector3(1.1, 0.3, 0.32)))
	var rr: Dictionary = AshfordNight.cellar(v)
	if rr.has("cask"):
		var ck: Node3D = rr.cask
		_cask = [ck.global_position, 0.3, AshfordVillage.BARREL_HALF]
	if rr.has("marks") and not (rr.marks as Array).is_empty():
		_timber_x = (rr.marks[0] as Node3D).global_position.x - 0.01   # (the marks stand 1 cm proud of it)
	for who in ["bram", "player"]:
		_cellar_stats[who] = {"frames": 0, "in_frames": 0, "deep": 0.0, "worst": "", "worst_frame": 0}
		var f := Cine.fig(world, who) as Figure3D
		if f == null:
			problems.append("no 3D " + who)
			continue
		f._skel.skeleton_updated.connect(func() -> void: _cellar_measure(who, f))
	var bf := Cine.fig(world, "bram") as Figure3D
	if bf != null:
		_cellar_reach.arm = bf.arm_reach() + 0.075 * bf.stature()
	# (11 November, Gary: after the Herald, "his body goes through the
	# stairs": the Reckoning's two cellar scenes) where each of them stands
	# and every step of the ways they go between, a body's half width
	# (RK_BODY) clear of every tread and of the room's walls
	var N := AshfordNight
	var ways := {"Bram, hoofbeats overhead": [N.RK_BRAM_1], "the player, hoofbeats overhead": [N.RK_PLAYER_1],
		"the player's run for the stairs": [N.RK_PLAYER_2, N.RK_RUN_VIA, N.STAIRS_FOOT],
		"Bram after them": [N.RK_BRAM_2, N.RK_BRAM_CATCH]}
	var tight := INF
	for nm in ways:
		var pts: Array = ways[nm]
		var worst := INF
		for i in pts.size():
			var a: Vector3 = (r.stairs as Vector3) + (pts[i] as Vector3)
			var b: Vector3 = (r.stairs as Vector3) + (pts[mini(i + 1, pts.size() - 1)] as Vector3)
			for k in 21:
				var p := a.lerp(b, k / 20.0)
				for box in _steps:
					var bx: AABB = box
					var dx := maxf(maxf(bx.position.x - p.x, p.x - bx.end.x), 0.0)
					var dz := maxf(maxf(bx.position.z - p.z, p.z - bx.end.z), 0.0)
					worst = minf(worst, Vector2(dx, dz).length())
				var lp := root.to_local(p)
				worst = minf(worst, minf(W * 0.5 - absf(lp.x), 5.5 * 0.5 - absf(lp.z)) - 0.1)
		tight = minf(tight, worst)
		if worst < RK_BODY:
			problems.append("the Reckoning's cellar: %s comes within %.0f cm of the steps or a wall" % [nm, worst * 100.0])
	print("  the Reckoning's cellar scenes: nobody nearer the steps or a wall than %.0f cm (a body's half width is %.0f)" % [tight * 100.0, RK_BODY * 100.0])
	if "oldspots" in OS.get_cmdline_user_args():
		# the places as they were before 8 November (the player half a metre
		# west of the `stairs` point, Bram 0.7 m off the marks), for the
		# before numbers
		await get_tree().create_timer(1.0).timeout
		var wall: Vector3 = rr.marks_at
		Cine.place(world, "bram", wall + Vector3(0.7, 0, 0.0), wall)
		Cine.place(world, "player", r.stairs + Vector3(-0.5, 0, 0.4), wall)
		var s: Node3D = AshfordNight.satchel(v)
		s.global_position = r.stairs + Vector3(-0.6, 0.0, -0.3)
		print("  (old spots)")


func _cellar_measure(who: String, f: Figure3D) -> void:
	if _done or not f.is_visible_in_tree():
		return
	var v: AshfordVillage = world.get_meta("village")
	var r := InnRooms.cellar(v)
	if f.global_position.distance_to((r.root as Node3D).global_position) > 8.0:
		return   # (not in the cellar yet)
	var st: Dictionary = _cellar_stats[who]
	st.frames += 1
	var sk: Skeleton3D = f._skel
	var xf := sk.global_transform
	var deep := 0.0
	var worst := ""
	for bn in BONE_R:
		var b := sk.find_bone(bn)
		if b < 0:
			continue
		var p := xf * sk.get_bone_global_pose(b).origin
		var rad: float = BONE_R[bn]
		# the bone's length too: points along it to its first child
		var pts := [p]
		for c in sk.get_bone_children(b):
			var q := xf * sk.get_bone_global_pose(c).origin
			for k in [0.25, 0.5, 0.75]:
				pts.append(p.lerp(q, k))
			break
		for q in pts:
			for box in _steps:
				var g := (box as AABB).grow(rad)
				if g.has_point(q):
					var d := minf(minf(q.x - g.position.x, g.end.x - q.x), minf(minf(q.y - g.position.y, g.end.y - q.y), minf(q.z - g.position.z, g.end.z - q.z)))
					if d > deep:
						deep = d
						worst = bn
	if deep > 0.0:
		st.in_frames += 1
		if deep > st.deep:
			st.deep = deep
			st.worst = worst
			st.worst_frame = _frame
	if who == "bram":
		var ik = f._ik.get("right")
		if ik != null and is_instance_valid(ik) and (ik as TwoBoneIK3D).active and (ik as TwoBoneIK3D).influence > 0.5:
			_cellar_reach.n += 1
			var sh := xf * sk.get_bone_global_pose(sk.find_bone("RightArm")).origin
			var el := xf * sk.get_bone_global_pose(sk.find_bone("RightForeArm")).origin
			var hd := xf * sk.get_bone_global_pose(sk.find_bone("RightHand")).origin
			var tgt = ik.get_meta("target") if ik.has_meta("target") else null
			if _cellar_reach.n == 1 or _cellar_reach.n % 10 == 0:
				# where he is against the marks: his shoulder, and the nearest marks' distances from it
				var rr: Dictionary = AshfordNight.cellar(v)
				var ds: Array = []
				for m: MeshInstance3D in rr.marks:
					ds.append([sh.distance_to(m.global_position + Vector3(AshfordNight.MARKS_OFF, 0, 0)), m.get_index()])
				ds.sort()
				var near := ""
				for k in mini(7, ds.size()):
					near += "#%d %.2f  " % [ds[k][1], ds[k][0]]
				if _cellar_reach.n == 1 or _cellar_reach.n == 30:
					# his right hand's bones from the wrist, as drawn (which of them lie along the fingers)
					var row := "  f%d his right hand's bones from the wrist (cm): " % _frame
					for bn in HAND_BONES:
						var bi := sk.find_bone("Right" + bn)
						if bi >= 0:
							var q := xf * sk.get_bone_global_pose(bi).origin - hd
							row += "%s (%.1f, %.1f, %.1f)  " % [bn, q.x * 100.0, q.y * 100.0, q.z * 100.0]
					print(row)
				if _cellar_reach.n == 1:
					# and his legs on the floor: the knee, ankle and toes as drawn, over the floor, and the foot's rest direction
					var fl0 := (r.root as Node3D).global_position.y
					for side in ["Right", "Left"]:
						var leg := ""
						for bn in ["UpLeg", "Leg", "Foot", "ToeBase"]:
							var bi := sk.find_bone(side + bn)
							if bi >= 0:
								var q := xf * sk.get_bone_global_pose(bi).origin
								leg += "%s %s (%.2f over the floor)  " % [bn, _v(q), q.y - fl0]
						var fi := sk.find_bone(side + "Foot")
						var ti := sk.find_bone(side + "ToeBase")
						if fi >= 0 and ti >= 0:
							leg += "foot at rest points %s" % _v((sk.get_bone_global_rest(ti).origin - sk.get_bone_global_rest(fi).origin).normalized())
						print("  his %s leg: %s" % [side.to_lower(), leg])
				print("  f%d bram at %s facing %s, R shoulder %s (%.2f off the marks' plane, %.2f up), elbow %s, wrist %s, palm %s, target %s; nearest marks: %s" % [
					_frame, _v(f.global_position), _v(f.facing()), _v(sh), sh.x - (rr.marks[0] as Node3D).global_position.x, sh.y - f.global_position.y, _v(el), _v(hd), _v(f._palm_point("Right")),
					_v((tgt as Node3D).global_position) if tgt != null and is_instance_valid(tgt) else "-", near])
			if tgt != null and is_instance_valid(tgt):
				var d := sh.distance_to((tgt as Node3D).global_position)
				_cellar_reach.d = maxf(_cellar_reach.d, d)
				if d > _cellar_reach.arm:
					_cellar_reach.over += 1
					_cellar_reach.by = maxf(_cellar_reach.by, d - _cellar_reach.arm)
			var elbow := rad_to_deg((sh - el).angle_to(hd - el))
			_cellar_reach.elbow_min = minf(_cellar_reach.elbow_min, elbow)
			if elbow > 172.0:
				_cellar_reach.straight += 1
			if not _cask.is_empty():
				for q in [hd, el, (hd + el) * 0.5, f._palm_point("Right")]:
					var c: Vector3 = _cask[0]
					var flat := Vector2(q.x - c.x, q.z - c.z).length()
					if flat < float(_cask[1]) and q.y > c.y - float(_cask[2]) and q.y < c.y + float(_cask[2]):
						_cellar_reach.cask += 1
						_cellar_reach.cask_deep = maxf(_cellar_reach.cask_deep, float(_cask[1]) - flat)
						break
			# his hand and forearm against the timber's face (a bone's middle
			# within half a finger of it, or behind it, is in it)
			if _timber_x != INF:
				var hp := {"wrist": hd, "elbow": el, "forearm": (hd + el) * 0.5, "palm": f._palm_point("Right")}
				for bn in ["HandMiddle3", "HandIndex3", "HandThumb3", "HandPinky3", "HandMiddle1"]:
					var bi := sk.find_bone("Right" + bn)
					if bi >= 0:
						hp[bn] = xf * sk.get_bone_global_pose(bi).origin
				var deep_t := 0.0
				var worst_t := ""
				for k in hp:
					var dd: float = _timber_x + 0.008 - (hp[k] as Vector3).x
					if String(k).begins_with("HandThumb"):
						# (the thumb apart: it rests folded under the palm on
						# this model, 6 to 7 cm below it; reported, not counted)
						_cellar_reach.thumb = maxf(float(_cellar_reach.get("thumb", 0.0)), dd)
						continue
					if dd > deep_t:
						deep_t = dd
						worst_t = k
				if deep_t > 0.0:
					_cellar_reach.timber += 1
					if deep_t > _cellar_reach.timber_deep:
						_cellar_reach.timber_deep = deep_t
						_cellar_reach.timber_bone = "%s f%d" % [worst_t, _frame]
				_cellar_knelt = true
		# on his knees: the knees and feet against the timber (their own
		# depth, BONE_R; turned on his knees, his feet swing round behind him),
		# once he is down on them (the way down is behind the caption's black)
		if _timber_x != INF and _cellar_knelt:
			for bn in ["RightLeg", "LeftLeg", "RightFoot", "LeftFoot", "RightToeBase", "LeftToeBase"]:
				var bi := sk.find_bone(bn)
				if bi < 0:
					continue
				var q := xf * sk.get_bone_global_pose(bi).origin
				var into := _timber_x + float(BONE_R[bn]) - q.x
				if into > _cellar_reach.knee_timber:
					_cellar_reach.knee_timber = into
					_cellar_reach.knee_timber_bone = "%s f%d" % [bn, _frame]
	# on their knees (both of them), settled (a hand reaching: at the marks,
	# on the satchel): the floor under the knees and feet
	var ik_r = f._ik.get("right")
	var ik_l = f._ik.get("left")
	var settled := false
	for ikx in [ik_r, ik_l]:
		if ikx != null and is_instance_valid(ikx) and (ikx as TwoBoneIK3D).active and (ikx as TwoBoneIK3D).influence > 0.95:
			settled = true
	if settled and f._held:
		var fl := (r.root as Node3D).global_position.y
		for bn in ["RightLeg", "LeftLeg", "RightFoot", "LeftFoot", "RightToeBase", "LeftToeBase"]:
			var bi := sk.find_bone(bn)
			if bi < 0:
				continue
			var q := xf * sk.get_bone_global_pose(bi).origin
			if q.y - fl < st.get("floor", INF):
				st.floor = q.y - fl
				st.floor_bone = "%s f%d" % [bn, _frame]
		st.floor_frames = st.get("floor_frames", 0) + 1
	if who == "player" and _frame - _cellar_last_still >= every:
		_cellar_last_still = _frame
		_cellar_still("f%05d" % _frame)


func _cellar_frame() -> void:
	pass


## The game's shot, then the stairs from the room's middle (the player beside
## them) and Bram at the wall from the room's middle.
func _cellar_still(tag: String) -> void:
	if _busy:
		return
	_busy = true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_game.png" % [out, tag])
	var v: AshfordVillage = world.get_meta("village")
	var r := InnRooms.cellar(v)
	var root: Node3D = r.root
	var rr: Dictionary = AshfordNight.cellar(v)
	var wall: Vector3 = rr.marks_at
	var shots := {
		"stairs": [root.to_global(Vector3(-0.2, 1.5, 0.2)), root.to_global(Vector3(2.4, 0.5, 1.5)), 40.0],
		"stairs_low": [root.to_global(Vector3(1.0, 0.5, -0.4)), root.to_global(Vector3(2.4, 0.3, 1.6)), 40.0],
		"wall": [wall + Vector3(2.6, 1.3, -1.6), wall + Vector3(0.4, 0.7, 0.2), 40.0],
		"wall_side": [wall + Vector3(0.9, 1.1, 1.0), wall + Vector3(-0.1, 0.7, 0.4), 40.0],
	}
	for k in shots:
		var s: Array = shots[k]
		cam.global_position = s[0]
		cam.look_at(s[1], Vector3.UP)
		cam.fov = s[2]
		cam.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, k])
	world.cam.make_current()
	_busy = false


func _sum_cellar() -> void:
	for who in _cellar_stats:
		var st: Dictionary = _cellar_stats[who]
		print("  %s: %d frames in the cellar, in the steps %d frames, deepest %.1f cm (%s, f%d); on their knees and reaching %d frames, the lowest of the knees and feet %.1f cm over the floor (%s)" % [
			who, st.frames, st.in_frames, st.deep * 100.0, st.worst, st.worst_frame, st.get("floor_frames", 0), float(st.get("floor", INF)) * 100.0, st.get("floor_bone", "")])
		if st.deep > 0.01:
			problems.append("%s's %s went %.1f cm into the steps in %d frames" % [who, st.worst, st.deep * 100.0, st.in_frames])
		if float(st.get("floor", INF)) < -0.03:
			problems.append("%s's %s %.1f cm under the floor on their knees" % [who, st.get("floor_bone", ""), -float(st.floor) * 100.0])
		if who == "player" and st.get("floor_frames", 0) == 0:
			problems.append("the player never knelt reaching for the satchel")
	var cr := _cellar_reach
	print("  Bram's reach to the marks: %d frames, the mark %.2f m from his shoulder at most (arm %.2f), out of reach %d frames by %.1f cm; elbow down to %.0f deg, locked straight %d frames; hand or forearm in the cask %d frames (%.1f cm)" % [
		cr.n, cr.d, cr.arm, cr.over, cr.by * 100.0, cr.elbow_min, cr.straight, cr.cask, cr.cask_deep * 100.0])
	if cr.over > 2:
		problems.append("the marks were out of Bram's reach by %.1f cm in %d frames" % [cr.by * 100.0, cr.over])
	if cr.straight > 5:
		problems.append("Bram's arm locked straight at the marks in %d frames" % cr.straight)
	if cr.cask > 0:
		problems.append("Bram's hand went through the cask in %d frames" % cr.cask)
	print("  Bram's hand against the timber: in it %d frames, deepest %.1f cm (%s); the thumb apart, %.1f cm in at most; his knees and feet into the timber %.1f cm at most (%s)" % [
		cr.timber, cr.timber_deep * 100.0, cr.timber_bone, float(cr.get("thumb", 0.0)) * 100.0, cr.knee_timber * 100.0, cr.knee_timber_bone])
	if cr.timber > 0:
		problems.append("Bram's hand went into the timber in %d frames (%.1f cm, %s)" % [cr.timber, cr.timber_deep * 100.0, cr.timber_bone])
	if cr.knee_timber > 0.01:
		problems.append("Bram's %s went %.1f cm into the timber" % [cr.knee_timber_bone, cr.knee_timber * 100.0])

