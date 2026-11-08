extends Node3D
## Corin's clerkship letter against his body, measured through his day's
## clips (8 November, Gary: "Corin's letter has moved from his pocket to his
## chest"). Corin alone on a plain stage, the letter on the bone where
## AshfordP1 puts it (AshfordP1.COAT_LETTER*), then each clip in turn: his
## idle, his walk, talking with his hands, the cheer and the fight stance he
## shows off with on the green, and the slump after the Lantern Duel.
##
## Every frame, with the modifiers' poses on the bones (skeleton_updated),
## his skin is worked out on the CPU (bone pose times bind pose, as the
## renderer does it) and measured against the letter:
##   - the arms: any vertex of his arms or hands inside the letter (grown
##     half a centimetre) is a hit;
##   - the coat: a grid of points over the letter's face, in rows by height;
##     a point shows if no triangle of his coat lies in front of it straight
##     out from his chest, and how far a showing point stands off the coat
##     behind it. In a pocket the top row shows, the bottom row never does,
##     and nothing stands more than 2 cm off him.
## His vest's two patch pockets are found by their place in his picture
## (POCKET_UV) and printed in the chest bone's space, so the letter can be
## put in one.
##
##   godot --headless --path . res://tests/corin_letter_probe.tscn -- [stills=<dir>] [at=x,y,z] [rot=x,y,z]
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x720 \
##       --path . res://tests/corin_letter_probe.tscn -- stills=/tmp/letter
## Ends "LETTER PROBE: ok" or with the problems.

## The vest's patch pockets in Corin's picture (u0, v0, u1, v1), upper and lower.
const POCKET_UV := {"upper": [0.570, 0.334, 0.593, 0.365], "lower": [0.572, 0.384, 0.594, 0.412]}
const ARM_BONES := ["Arm", "ForeArm", "Hand"]
const CLIPS := [["idle", 2.5], ["walk", 2.4], ["talk", 3.0], ["cheer", -1.0], ["fight_stance", -1.0], ["slump", 3.0]]

var stills := ""
var fig: Figure3D
var skel: Skeleton3D
var letter: Node3D
var letter_bone := "Spine2"
var cam: Camera3D
var problems: Array = []
var _binds := {}
var _used := {}
## [mesh-space vertex, normal, bones x4, weights x4] for the coat near the letter, and the arms
var _coat: Array = []
var _arms: Array = []
var _tris := PackedInt32Array()   # the coat's triangles, as places in _coat
var _stat := {}
var _clip := ""
var _measure := false


func _ready() -> void:
	var at: Vector3 = AshfordP1.COAT_LETTER
	var size: float = AshfordP1.COAT_LETTER_SCALE
	var bone: String = AshfordP1.COAT_LETTER_BONE
	var rot: Vector3 = AshfordP1.COAT_LETTER_ROT
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("stills="):
			stills = s.substr(7)
		elif s.begins_with("at="):
			var p := s.substr(3).split(",")
			at = Vector3(float(p[0]), float(p[1]), float(p[2]))
		elif s.begins_with("scale="):
			size = float(s.substr(6))
		elif s.begins_with("bone="):
			bone = s.substr(5)
		elif s.begins_with("rot="):
			var p := s.substr(4).split(",")
			rot = Vector3(float(p[0]), float(p[1]), float(p[2]))
	if stills != "":
		DirAccess.make_dir_recursive_absolute(stills)
	var v := AshfordVillage.new()
	v.spread = true
	add_child(v)
	v.make_materials()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.4, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	env.environment.ambient_light_energy = 0.8
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	sun.light_energy = 1.3
	add_child(sun)
	fig = Figure3D.new().setup("corin")
	add_child(fig)
	fig.snap_face(Vector3.FORWARD)
	await get_tree().process_frame
	await get_tree().process_frame
	skel = fig._skel
	letter = AshfordP1.letter(v)
	letter.scale = Vector3.ONE * size
	AshfordP1.attach(fig, bone, letter, at, rot)
	letter_bone = bone
	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	await get_tree().create_timer(0.3).timeout
	_gather()
	_pockets()
	if "fit" in OS.get_cmdline_user_args():
		_fit()
	skel.skeleton_updated.connect(_on_pose)
	for c in CLIPS:
		await _play(String(c[0]), float(c[1]))
	print("  per clip: frames, arm-hit frames (deepest cm), rows showing (top first) as % of frames, coat over/under (cm)")
	for k in _stat:
		var s: Dictionary = _stat[k]
		var n: int = maxi(1, int(s.get("measured", 0)))
		var rows := []
		for r in (s.rows as Array).size():
			rows.append("%d%%" % roundi(100.0 * float(s.rows[r]) / n))
		print("    %-13s %4d  arms %3d (%.1f)  rows %s  stands off %.1f cm at most, (%d frames measured)" % [k, s.frames, s.arm_frames, s.arm_deep * 100.0,
			" ".join(rows), s.off * 100.0, n])
		if s.has("worst"):
			print("      (the furthest off: %s)" % s.worst)
		if int(s.arm_frames) > 0:
			problems.append("%s: an arm through the letter in %d frames (%.1f cm)" % [k, s.arm_frames, s.arm_deep * 100.0])
		# tucked in a pocket: the top row shows, the bottom row never does
		if float(s.rows[0]) / n < 0.9:
			problems.append("%s: the letter's top hidden in %d%% of frames" % [k, roundi(100.0 - 100.0 * float(s.rows[0]) / n)])
		if float(s.rows[ROWS - 1]) / n > 0.1:
			problems.append("%s: the letter's foot shows over the coat in %d%% of frames" % [k, roundi(100.0 * float(s.rows[ROWS - 1]) / n)])
		if float(s.off) > 0.02:
			problems.append("%s: the letter stands %.1f cm off his coat" % [k, s.off * 100.0])
	print("LETTER PROBE: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _play(clip: String, secs: float) -> void:
	_clip = clip
	fig.release(0.0)
	fig.walking = false
	fig.talking = false
	await get_tree().process_frame
	var done := [false]
	match clip:
		"walk":
			fig.walking = true
		"talk":
			fig.talking = true
		"slump":
			fig.slump(0.85, 1.0)
		"idle":
			pass
		_:
			if fig.anim == null or not fig.anim.has_animation(clip):
				print("  (no %s clip)" % clip)
				return
			var f := func() -> void:
				await fig.act(clip, 1.0, 0.2)
				done[0] = true
			f.call()
	_measure = true
	var t := 0.0
	var next_still := 0.25
	var k := 0
	while (secs > 0.0 and t < secs) or (secs < 0.0 and not done[0] and t < 8.0):
		await get_tree().process_frame
		t += get_process_delta_time()
		if stills != "" and t >= next_still and k < 3:
			next_still += maxf(0.6, absf(secs) / 3.0) if secs > 0.0 else 0.9
			await _still("%s_%d" % [clip, k])
			k += 1
	_measure = false
	fig.walking = false
	fig.talking = false
	fig.release(0.2)


func _still(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var c := letter.global_position
	var fwd := fig.facing()
	var rt := fwd.cross(Vector3.UP)
	for view in [["front", fwd * 1.5 + rt * 0.5 + Vector3(0, 0.15, 0), 34.0], ["near", fwd * 0.7 - rt * 0.35 + Vector3(0, 0.1, 0), 30.0],
			["side", -rt * 1.1 + fwd * 0.3 + Vector3(0, 0.1, 0), 34.0]]:
		cam.global_position = c + (view[1] as Vector3)
		cam.look_at(c + Vector3(0, -0.12, 0), Vector3.UP)
		cam.fov = float(view[2])
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [stills, label, view[0]])


# --------------------------------------------------------------- the skin ---

func _gather() -> void:
	var lc := letter.global_position
	for mi: MeshInstance3D in fig.model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skeleton == NodePath():
			continue
		var skin: Skin = mi.skin if mi.skin != null else skel.create_skin_from_rest_transforms()
		var bind_bone: Array = []
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = skel.find_bone(skin.get_bind_name(i))
			bind_bone.append(b)
			if b >= 0 and not _binds.has(b):
				_binds[b] = skin.get_bind_pose(i)
		var local := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != skel:
			if cur is Node3D:
				local = (cur as Node3D).transform * local
			cur = cur.get_parent()
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			if verts.is_empty() or bones == null or weights == null or norms.size() != verts.size():
				continue
			var per := int(bones.size() / verts.size())
			var to_coat := {}   # this surface's vertex -> its place in _coat
			for vi in verts.size():
				var bs: Array = []
				var ws: Array = []
				var arm := 0.0
				for k in 4:
					if k < per:
						var bi := int(bones[vi * per + k])
						var b: int = bind_bone[bi] if bi < bind_bone.size() else -1
						bs.append(b)
						ws.append(float(weights[vi * per + k]))
						if b >= 0:
							var nm := skel.get_bone_name(b)
							for ab in ARM_BONES:
								if nm.ends_with(ab) or (nm.contains("Hand") and (nm.begins_with("Left") or nm.begins_with("Right"))):
									arm += float(weights[vi * per + k])
									break
					else:
						bs.append(-1)
						ws.append(0.0)
				var rec := [local * verts[vi], local.basis * norms[vi], bs, ws]
				var p := _skin_point(rec)
				if p.distance_to(lc) > 0.35:
					continue
				for b in bs:
					if b >= 0:
						_used[b] = true
				if arm > 0.5:
					_arms.append(rec)
				else:
					to_coat[vi] = _coat.size()
					_coat.append(rec)
			# the coat's triangles near the letter (all three corners on the coat)
			var idx = arr[Mesh.ARRAY_INDEX]
			if idx != null:
				for ti in range(0, (idx as PackedInt32Array).size() - 2, 3):
					var a := int(idx[ti])
					var b := int(idx[ti + 1])
					var c := int(idx[ti + 2])
					if to_coat.has(a) and to_coat.has(b) and to_coat.has(c):
						_tris.append(int(to_coat[a]))
						_tris.append(int(to_coat[b]))
						_tris.append(int(to_coat[c]))
	print("  near the letter: %d coat vertices (%d triangles), %d arm vertices" % [_coat.size(), _tris.size() / 3, _arms.size()])


## Where a vertex is this frame (world), and its normal.
func _skin(rec: Array, bt: Dictionary) -> Array:
	var p := Vector3.ZERO
	var n := Vector3.ZERO
	var wsum := 0.0
	for k in 4:
		var b: int = rec[2][k]
		var wt: float = rec[3][k]
		if b < 0 or wt <= 0.0:
			continue
		var t: Transform3D = bt[b]
		p += t * (rec[0] as Vector3) * wt
		n += t.basis * (rec[1] as Vector3) * wt
		wsum += wt
	if wsum <= 0.0:
		return [Vector3.ZERO, Vector3.UP]
	return [p / wsum, n.normalized()]


func _bone_xf(bones: Dictionary) -> Dictionary:
	var xf := skel.global_transform
	var bt := {}
	for b in bones:
		bt[b] = xf * skel.get_bone_global_pose(b) * (_binds[b] as Transform3D)
	return bt


func _skin_point(rec: Array) -> Vector3:
	var bt := {}
	for b in rec[2]:
		if int(b) >= 0 and _binds.has(int(b)):
			bt[int(b)] = skel.global_transform * skel.get_bone_global_pose(int(b)) * (_binds[int(b)] as Transform3D)
	return _skin(rec, bt)[0]


## The patch pockets, by their place in the picture, in the chest bone's space.
func _pockets() -> void:
	var cb := skel.find_bone(letter_bone)
	var bone_xf := skel.global_transform * skel.get_bone_global_pose(cb)
	print("  the %s bone: at %s, scale %s, its x %s y %s z %s (world); the letter at %s in its space, %s in the world" % [letter_bone,
		bone_xf.origin.snapped(Vector3.ONE * 0.001), bone_xf.basis.get_scale().snapped(Vector3.ONE * 0.001),
		bone_xf.basis.x.normalized().snapped(Vector3.ONE * 0.01), bone_xf.basis.y.normalized().snapped(Vector3.ONE * 0.01), bone_xf.basis.z.normalized().snapped(Vector3.ONE * 0.01),
		(bone_xf.affine_inverse() * letter.global_position).snapped(Vector3.ONE * 0.001), letter.global_position.snapped(Vector3.ONE * 0.001)])
	# the coat's front, straight ahead of the letter: the nearest coat vertex
	# to a line from the letter forward
	var bt := _bone_xf(_used)
	var fwd := fig.facing()
	var front := -INF
	for rec in _coat:
		var sv: Array = _skin(rec, bt)
		var q: Vector3 = sv[0]
		var rel := q - letter.global_position
		var side := rel - fwd * rel.dot(fwd)
		if side.length() < 0.02 and rel.dot(fwd) > front:
			front = rel.dot(fwd)
	print("  his coat's front is %.1f cm ahead of the letter's middle" % (front * 100.0))
	for mi: MeshInstance3D in fig.model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var skin: Skin = mi.skin if mi.skin != null else skel.create_skin_from_rest_transforms()
		var bind_bone: Array = []
		var binds := {}
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = skel.find_bone(skin.get_bind_name(i))
			bind_bone.append(b)
			if b >= 0:
				binds[b] = skin.get_bind_pose(i)
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uvs = arr[Mesh.ARRAY_TEX_UV]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			if uvs == null or bones == null:
				continue
			var per := int(bones.size() / verts.size())
			for nm in POCKET_UV:
				var box: Array = POCKET_UV[nm]
				var lo := Vector3.INF
				var hi := -Vector3.INF
				var n := 0
				for vi in verts.size():
					var uv: Vector2 = uvs[vi]
					if uv.x < float(box[0]) or uv.x > float(box[2]) or uv.y < float(box[1]) or uv.y > float(box[3]):
						continue
					var p := Vector3.ZERO
					var wsum := 0.0
					for k in per:
						var b: int = bind_bone[int(bones[vi * per + k])]
						var wt := float(weights[vi * per + k])
						if b < 0 or wt <= 0.0:
							continue
						p += (skel.global_transform * skel.get_bone_global_pose(b) * (binds[b] as Transform3D)) * verts[vi] * wt
						wsum += wt
					if wsum <= 0.0:
						continue
					var q := bone_xf.affine_inverse() * (p / wsum)
					var top := ""
					var top_w := 0.0
					for k in per:
						var b2: int = bind_bone[int(bones[vi * per + k])]
						if b2 >= 0 and float(weights[vi * per + k]) > top_w:
							top_w = float(weights[vi * per + k])
							top = skel.get_bone_name(b2)
					print("      %s pocket vertex %s uv %s mostly %s (%.2f)" % [nm, q.snapped(Vector3.ONE * 0.001), uv.snapped(Vector2.ONE * 0.001), top, top_w])
					lo = lo.min(q)
					hi = hi.max(q)
					n += 1
				if n > 0:
					print("  the %s pocket: %d vertices, in the %s bone's space from %s to %s (middle %s)" % [nm, n, letter_bone,
						lo.snapped(Vector3.ONE * 0.001), hi.snapped(Vector3.ONE * 0.001), ((lo + hi) * 0.5).snapped(Vector3.ONE * 0.001)])


# ------------------------------------------------------------ fitting ---

## The pocket's top edge and middle across, in the bone's space (the
## upper patch on his right: Spine1, from its vertices and the picture).
const FIT_TOP := 0.018
const FIT_X := -0.077
## Where the search for the letter's depth at the edge starts (bone z, m).
const FIT_Z_FROM := 0.11
## How much of the letter shows above the pocket (m), and how deep the
## part in the pocket must be under the coat at the least (m).
const FIT_SHOW := 0.02
const FIT_UNDER := 0.005
const FIT_OFF_MOST := 0.011

## The coat's front, straight out of the bone at (x, y) in its space: its
## depth there (bone z), or NAN if nothing's hit.
func _surface(tris: PackedVector3Array, x: float, y: float) -> float:
	var best := -INF
	for ti in range(0, tris.size(), 3):
		var h = Geometry3D.ray_intersects_triangle(Vector3(x, y, 0.6), Vector3(0, 0, -1), tris[ti], tris[ti + 1], tris[ti + 2])
		if h != null:
			best = maxf(best, (h as Vector3).z)
	return best if best > -INF else NAN


## Stands the letter in the pocket: its middle FIT_X across, FIT_SHOW of it
## above the pocket's top edge, leant out at the top just enough that the
## part below the edge is FIT_UNDER under the coat everywhere and the part
## above stands no more than FIT_OFF_MOST off it; prints the numbers for
## AshfordP1 and puts the letter there.
func _fit() -> void:
	var bxf := skel.global_transform * skel.get_bone_global_pose(skel.find_bone(letter_bone))
	var inv := bxf.affine_inverse()
	var bt := _bone_xf(_used)
	var tris := PackedVector3Array()
	for ti in _tris:
		tris.append(inv * (_skin(_coat[ti], bt)[0] as Vector3))
	var hh := HALF.x * letter.scale.x   # (stood on end: its length is its height)
	var hw := HALF.y * letter.scale.x
	var yc := FIT_TOP + FIT_SHOW - hh
	print("  the coat's front by the pocket (bone z, cm), rows y from %.3f to %.3f:" % [yc + hh, yc - hh])
	var cols := [FIT_X - hw * 0.85, FIT_X, FIT_X + hw * 0.85]
	var ys: Array = []
	for i in 9:
		ys.append(lerpf(yc + hh, yc - hh, float(i) / 8.0))
	var surf := {}
	for y in ys:
		var line := "    y %.3f:" % y
		for x in cols:
			var z := _surface(tris, x, y)
			surf[Vector2(x, y)] = z
			line += "  %.1f" % (z * 100.0)
		print(line)
	var chosen := []
	var best_margin := -INF
	for deg in range(0, 46, 1):
		var a := deg_to_rad(float(deg))
		for zi in range(0, 61):
			var z0 := FIT_Z_FROM + float(zi) * 0.0005
			var ok := true
			var off_most := 0.0
			var show_least := INF
			var under_least := INF
			var edge_least := INF
			for k in surf:
				var p: Vector2 = k
				var zs: float = surf[k]
				if is_nan(zs):
					continue
				var zl := z0 + (p.y - FIT_TOP) * tan(a)
				if p.y < FIT_TOP - 0.012:
					under_least = minf(under_least, zs - zl)
				elif p.y < FIT_TOP - 0.003:
					edge_least = minf(edge_least, zs - zl)
				elif p.y > FIT_TOP + 0.005:
					off_most = maxf(off_most, zl - zs)
					show_least = minf(show_least, zl - zs)
			if under_least < FIT_UNDER or edge_least < 0.001 or off_most > FIT_OFF_MOST or show_least < 0.001:
				continue
			var margin := minf(under_least - FIT_UNDER, minf(show_least, FIT_OFF_MOST - off_most))
			if margin > best_margin:
				best_margin = margin
				chosen = [a, z0, under_least, off_most, show_least]
		if not chosen.is_empty():
			break
	if chosen.is_empty():
		print("  FIT: nothing fits")
		problems.append("no fit for the pocket")
		return
	var a: float = chosen[0]
	var zc: float = float(chosen[1]) + (yc - FIT_TOP) * tan(a)
	var at := Vector3(FIT_X, yc, zc)
	var rot := Vector3(a, 0.0, -PI * 0.5)
	print("  FIT: at %s rot %s scale %.2f (leant %.0f degrees; under the coat %.1f cm at the least, the showing part %.1f to %.1f cm off it)" % [
		at.snapped(Vector3.ONE * 0.001), rot.snapped(Vector3.ONE * 0.001), letter.scale.x, rad_to_deg(a), float(chosen[2]) * 100.0, float(chosen[4]) * 100.0, float(chosen[3]) * 100.0])
	letter.position = at
	letter.rotation = rot


# ------------------------------------------------------------ measuring ---

const ROWS := 5
const MEASURE_EVERY := 2
var _tick := 0
## The letter's paper (AshfordP1.letter: 14 x 9.5 cm, 6 mm thick).
const HALF := Vector3(0.07, 0.0475, 0.003)


func _on_pose() -> void:
	if not _measure:
		return
	var bt := _bone_xf(_used)
	var lx := (letter.get_child(0) as Node3D).global_transform if letter.get_child_count() > 0 else letter.global_transform
	var inv := lx.affine_inverse()
	if not _stat.has(_clip):
		var rows: Array = []
		rows.resize(ROWS)
		rows.fill(0)
		_stat[_clip] = {"frames": 0, "arm_frames": 0, "arm_deep": 0.0, "rows": rows, "off": 0.0, "under": 0.0}
	var st: Dictionary = _stat[_clip]
	st.frames += 1
	# the arms
	var deepest := 0.0
	for rec in _arms:
		var q: Vector3 = inv * (_skin(rec, bt)[0] as Vector3)
		var e := q.abs() - (HALF + Vector3.ONE * 0.005)
		var inside := -maxf(e.x, maxf(e.y, e.z))
		if inside > 0.0:
			deepest = maxf(deepest, inside)
	if deepest > 0.0:
		st.arm_frames += 1
		st.arm_deep = maxf(float(st.arm_deep), deepest)
	# the coat: the letter's face, in rows by height (its top edge first,
	# however it's turned). A point shows if nothing of his coat lies in front
	# of it straight out from his chest (a ray from it, out, against the
	# coat's triangles); then how far it stands off the coat behind it (the
	# ray in). Every MEASURE_EVERY frames.
	_tick += 1
	if _tick % MEASURE_EVERY != 0:
		return
	var out_dir := (skel.global_transform.basis * skel.get_bone_global_pose(skel.find_bone(letter_bone)).basis).z.normalized()
	var lc := letter.global_position
	var near := PackedVector3Array()
	near.resize(_coat.size())
	var keep := PackedByteArray()
	keep.resize(_coat.size())
	for i in _coat.size():
		var q: Vector3 = _skin(_coat[i], bt)[0]
		near[i] = q
		keep[i] = 1 if q.distance_to(lc) < 0.2 else 0
	var tris := PackedVector3Array()
	for ti in range(0, _tris.size(), 3):
		var a := _tris[ti]
		var b := _tris[ti + 1]
		var c := _tris[ti + 2]
		if keep[a] == 1 or keep[b] == 1 or keep[c] == 1:
			tris.append(near[a])
			tris.append(near[b])
			tris.append(near[c])
	var pts: Array = []
	var ylo := INF
	var yhi := -INF
	for c in 5:
		for r in 5:
			var wp := lx * Vector3(lerpf(-HALF.x, HALF.x, float(c) / 4.0) * 0.95, lerpf(-HALF.y, HALF.y, float(r) / 4.0) * 0.95, 0.0)
			pts.append(wp)
			ylo = minf(ylo, wp.y)
			yhi = maxf(yhi, wp.y)
	var shows: Array = []
	shows.resize(ROWS)
	shows.fill(false)
	st.measured = int(st.get("measured", 0)) + 1
	for wp: Vector3 in pts:
		var row := clampi(int((yhi - wp.y) / maxf(0.001, yhi - ylo) * ROWS), 0, ROWS - 1)
		var hidden := false
		var behind := INF
		for ti in range(0, tris.size(), 3):
			if not hidden and Geometry3D.ray_intersects_triangle(wp, out_dir, tris[ti], tris[ti + 1], tris[ti + 2]) != null:
				hidden = true
			var hb = Geometry3D.ray_intersects_triangle(wp, -out_dir, tris[ti], tris[ti + 1], tris[ti + 2])
			if hb != null:
				behind = minf(behind, (hb as Vector3).distance_to(wp))
		if not hidden:
			shows[row] = true
			if behind < INF and behind > float(st.off):
				st.off = behind
				st["worst"] = "row %d, at %s in the letter's frame" % [row, (inv * wp).snapped(Vector3.ONE * 0.001)]
	for r in ROWS:
		if shows[r]:
			st.rows[r] += 1
