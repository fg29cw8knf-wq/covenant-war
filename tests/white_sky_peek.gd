extends Node
## Close looks at parts of the Night of the White Sky (WhiteSky), without
## playing it through (6 November, Gary's notes on it):
##   walk   Bram walking, from behind as the game films him and from the side,
##          a still every 0.1 s (his gait, his feet on the snow, his back)
##   ice    the ice spires near and far, the crater's shards from the rim
##   cards  Sigils falling round him and standing in the snow, close
##   lift   the pick-up of the child, a still every 0.1 s, as filmed and from
##          the side (the hands under the bundle while it's on the snow); the
##          wrists and elbows measured each frame ("nowrists": left to the
##          reach alone, the 8 November before)
##   hunter the hunter on the rim with his cards raised, as filmed and close on
##          each hand (11 November)
##   duel   the cut from the hunter's raised cards to the filmed duel: how long
##          the white holds, and what's seen in it (a still every 0.1 s)
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/white_sky_peek.tscn -- <dir> <walk|ice|cards|lift|duel> [side]

var out := "/tmp/ws_peek"
var what := "walk"
var side := false
var m: WhiteSky
var _peek := false
var _peek_pos := Vector3.ZERO
var _peek_look := Vector3.ZERO
var _n := 0


func _ready() -> void:
	process_priority = 100   # (after WhiteSky's own camera)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		what = a[1]
	side = a.has("side")
	DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	m = WhiteSky.new()
	add_child(m)
	_run.call_deferred()


func _process(_d: float) -> void:
	# (12 November: Bram's duel is played; each of his three moves is made as it's asked for)
	if m != null and is_instance_valid(m) and m.asking() != "" and m._hint.modulate.a > 0.9:
		m.play_move()
	if _peek and m != null and m._cam != null:
		m._cam_mode = "peek"
		m._cam.global_position = _peek_pos
		m._cam.look_at(_peek_look, Vector3.UP)


func _shot(nm: String) -> void:
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%s_%03d_%s.png" % [what, _n, nm]))


func _frames(secs: float, every: float, tag: String) -> void:
	var t := 0.0
	while t < secs:
		await _shot("%s_%04.1f" % [tag, t])
		await get_tree().create_timer(every, false).timeout
		t += every


func _peek_at(pos: Vector3, look: Vector3) -> void:
	_peek = true
	_peek_pos = pos
	_peek_look = look


func _run() -> void:
	await get_tree().process_frame
	m._ov = m._own_overlay()
	m._black.modulate.a = 0.0
	for k in 4:
		await get_tree().process_frame
	match what:
		"walk":
			await _walk()
		"ice":
			await _ice()
		"cards":
			await _cards()
		"lift":
			await _lift()
		"duel":
			await _duel()
		"hunter":
			await _hunter_look()
		"feet":
			_feet()
	print("WHITE SKY PEEK: done ", what, " in ", out)
	get_tree().quit()


## The hunter on the rim, his cards raised, as the game shows him and close
## on each hand (11 November, Gary: the hunter "before brams battle has
## deformed right hand").
func _hunter_look() -> void:
	m._bram.position = WhiteSky.CRATER - Vector3(0, 0, -0.5)
	var at := WhiteSky.CRATER + Vector3(0, 0, -8.6)
	at.y = WhiteSky.height(at.x, at.z)
	m._hunter.position = at
	m._hunter.look_at_dir(m._bram.position - m._hunter.position)
	m._hunter.visible = true
	m._hunter._set_fade(1.0)
	m._shot(WhiteSky.CRATER + Vector3(0.9, 1.0, 2.6), m._hunter.position + Vector3(0, 2.2, 0), 38.0)
	m._hunter.raise_cards()
	await get_tree().create_timer(1.6, false).timeout
	await _shot("as_filmed")
	var sk := m._hunter.find_child("Skeleton3D", true, false) as Skeleton3D
	for k in 2:
		for side in ["Right", "Left"]:
			var hb := sk.find_bone(side + "Hand") if sk != null else -1
			if hb < 0:
				continue
			var hp := sk.global_transform * sk.get_bone_global_pose(hb).origin
			var to_b := (m._bram.position - m._hunter.position).normalized()
			_peek_at(hp + to_b * 1.1 + Vector3(0, 0.15, 0), hp + Vector3(0, -0.12, 0))
			await _shot("%s_hand_front_%d" % [side.to_lower(), k])
			_peek_at(hp + to_b.rotated(Vector3.UP, 1.2 if side == "Left" else -1.2) * 1.1 + Vector3(0, 0.1, 0), hp + Vector3(0, -0.12, 0))
			await _shot("%s_hand_side_%d" % [side.to_lower(), k])
		await get_tree().create_timer(0.7, false).timeout
	_peek_at(m._hunter.position + (m._bram.position - m._hunter.position).normalized() * 4.2 + Vector3(0, 1.5, 0), m._hunter.position + Vector3(0, 1.3, 0))
	await _shot("whole_front")


## Every crystal's foot (its prism's bottom ring, UV.y 0) under the snow?
func _feet() -> void:
	var worst := -1e9
	var bad := 0
	var n := 0
	var where := Vector3.ZERO
	for mi in m._set.get_children():
		if not (mi is MeshInstance3D) or not ((mi as MeshInstance3D).mesh is ArrayMesh) or not ((mi as MeshInstance3D).material_override is ShaderMaterial):
			continue
		if not ((mi as MeshInstance3D).material_override as ShaderMaterial).shader.code.contains("ICE_") and not ((mi as MeshInstance3D).material_override as ShaderMaterial).shader.code.contains("fracture"):
			continue
		var am := (mi as MeshInstance3D).mesh as ArrayMesh
		if am.get_surface_count() == 0:
			continue
		var arr := am.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		if uvs.is_empty():
			continue
		n += 1
		for i in vs.size():
			if uvs[i].y > 0.001:
				continue
			var w := (mi as MeshInstance3D).global_transform * vs[i]
			var above := w.y - WhiteSky.height(w.x, w.z)
			if above > 0.0:
				bad += 1
			if above > worst:
				worst = above
				where = w
	print("FEET: %d crystals, %d foot corners above the snow, the worst %.2f m at %s" % [n, bad, worst, str(where)])


func _walk() -> void:
	var fig := m._bram as Figure3D
	if OS.get_cmdline_user_args().has("noposture") and fig != null and fig._skel != null and fig._skel.has_node("Posture"):
		fig._skel.get_node("Posture").free()
	if fig != null:
		print("WALK: model ", fig._model_name, " clip pace ", fig._gait_pace("walk"), " clips ", fig.anim.get_animation_list() if fig.anim != null else [])
	m._flat = WhiteSky.WALK_FROM
	m._bram.position = Vector3(m._flat.x, WhiteSky.height(m._flat.x, m._flat.z), m._flat.z)
	m._cam_mode = "roam"
	m._cam_pos = Vector3.ZERO
	m._roam = true
	Input.action_press("move_up")
	await get_tree().create_timer(1.5, false).timeout
	if side:
		var b := m._bram
		_peek = true
		var t := 0.0
		while t < 2.4:
			var p := b.global_position
			_peek_pos = p + Vector3(3.2, 1.0, 0.0)
			_peek_look = p + Vector3(0, 0.95, 0)
			await _shot("side_%04.1f" % t)
			await get_tree().create_timer(0.1, false).timeout
			t += 0.1
		_peek = false
		t = 0.0
		while t < 1.6:
			var p := b.global_position
			_peek = true
			_peek_pos = p + Vector3(0.0, 0.5, 2.6)
			_peek_look = p + Vector3(0, 0.8, 0)
			await _shot("low_back_%04.1f" % t)
			await get_tree().create_timer(0.1, false).timeout
			t += 0.1
	else:
		await _frames(2.4, 0.1, "behind")
	Input.action_release("move_up")


func _ice() -> void:
	m._bram.position = Vector3(0, WhiteSky.height(0, -2), -2)
	m.tear_now()   # (14 November: the sky open, as WhiteSky lights it now)
	var views := [
		[Vector3(0.75, 1.85, 0.9), Vector3(0.1, 1.35, -9.0), "start"],
		[Vector3(0.0, 1.7, -14.0), Vector3(0.0, 0.5, -30.0), "towards_crater"],
		[Vector3(-0.6, 3.6, -21.0), Vector3(0.0, -1.0, -30.0), "rim"],
	]
	# the nearest spires to the walk, close
	var near: Array = []
	for sp in m._spires:
		near.append([Vector2(float(sp[0]), float(sp[1]) + 15.0).length(), sp])
	near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
	for k in 2:
		var sp: Array = near[k][1]
		var c := Vector3(float(sp[0]), 0, float(sp[1]))
		c.y = WhiteSky.height(c.x, c.z)
		views.append([c + Vector3(2.6, 1.6, 2.6), c + Vector3(0, 1.4, 0), "spire%d" % k])
		views.append([c + Vector3(3.6, 0.5, 0.0), c + Vector3(0, 0.6, 0), "spire%d_low" % k])
		views.append([c + Vector3(0.0, 6.0, 0.5), c + Vector3(0, 0.0, 0), "spire%d_top" % k])
	for v in views:
		_peek_at(v[0], v[1])
		for k in 3:
			await get_tree().process_frame
		await _shot(String(v[2]))


func _cards() -> void:
	m._flat = Vector3(0, 0, -8)
	m._bram.position = Vector3(0, WhiteSky.height(0, -8), -8)
	m.tear_now()   # (14 November: the sky open, as WhiteSky lights it now)
	m._rain_cards(true)
	m._strike_burst(6, 0.4)
	m._rain_next = 0.0
	_peek_at(Vector3(0.75, 1.85, -5.1), Vector3(0.1, 2.2, -15.0))
	await get_tree().create_timer(1.0, false).timeout
	await _frames(6.0, 0.5, "rain")
	# a landed one, close
	for k in 20:
		if not m._landed.is_empty():
			break
		await get_tree().create_timer(0.3, false).timeout
	if OS.get_cmdline_user_args().has("nopool"):
		for e in m._landed:
			if is_instance_valid(e[1]):
				(e[1] as Node3D).visible = false
	for k in mini(3, m._landed.size()):
		var c: Node3D = m._landed[m._landed.size() - 1 - k][0]
		if is_instance_valid(c):
			_peek_at(c.global_position + Vector3(0.6, 0.35, 0.7), c.global_position)
			for j in 3:
				await get_tree().process_frame
			await _shot("landed%d" % k)
	# a falling one, close
	for f in m._falling:
		var n: Node3D = f[0]
		if is_instance_valid(n) and n.position.y > 3.0:
			for j in 8:
				_peek_at(n.global_position + Vector3(1.2, 0.4, 1.2), n.global_position)
				await _shot("falling%d" % j)
				await get_tree().create_timer(0.1, false).timeout
			break


func _lift() -> void:
	# at the bottom by the child, as _crater leaves him
	var b := WhiteSky.CRATER + Vector3(0, 0, WhiteSky.RIM_AT)
	m._bram.position = b
	m._ad = (WhiteSky.CRATER - b)
	m._ad.y = 0
	m._ad = m._kneel_dir(m._ad.normalized())
	var rt := m._ad.cross(Vector3.UP)
	m._bottom = m._kneel_spot(m._ad)
	m._bram.position = m._bottom
	WhiteSky._face(m._bram, m._ad)
	for k in 10:
		await get_tree().process_frame
	m._shot(m._bottom - m._ad * 1.9 + rt * 1.45 + Vector3(0, 1.15, 0), m._baby.position + Vector3(0, 0.2, 0), 40.0)
	if side:
		var c := m._bottom + m._ad * 0.3
		_peek_at(c + rt * 2.4 + Vector3(0, 0.7, 0), c + Vector3(0, 0.55, 0))
	if OS.get_cmdline_user_args().has("nowrists"):
		m.turn_wrists = false   # (the wrists left to the reach: the 8 November before)
	m._lift_child()
	var fig := m._bram as Figure3D
	var sk := fig._skel
	var dump := [false]
	sk.skeleton_updated.connect(func() -> void:
		if not dump[0]:
			return
		dump[0] = false
		var gp := func(bn: String) -> Vector3:
			return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bn)).origin
		var base := fig.global_position
		print("  ground ", base.y, " bundle ", m._baby.global_position - base)
		for bn in ["Hips", "Spine2", "Neck", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]:
			print("  %-12s %s" % [bn, str(fig.to_own(gp.call(bn)))])
		for c in m._baby.get_children():
			if c is Node3D and not (c is MeshInstance3D) and not (c is OmniLight3D) and c.get_child_count() == 0:
				print("  mark ", fig.to_own((c as Node3D).global_position)))
	get_tree().create_timer(1.6, false).timeout.connect(func() -> void: dump[0] = true)
	get_tree().create_timer(4.5, false).timeout.connect(func() -> void: dump[0] = true)   # (standing with it)
	# the wrists (8 November, Gary: "Bram's hands twist when he picks up the
	# baby"): on the pose as drawn each frame, how far each palm faces off
	# the way it should under its end of the bundle (up and in towards the
	# bundle's middle, at 45 degrees: 0 is just so, past 90 is turned away
	# from the bundle), how far the fingers are off the bundle's length (0
	# along it), how far the palm's middle is under the bundle's axis (m),
	# and the elbows: each one's distance out from its own shoulder, across
	# him (+ out, - in past it). Frames with the hands on the bundle and a
	# palm turned away from it are flagged.
	var wr := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]   # L palm off up-and-in, L fingers off length, R palm, R fingers, L elbow out, R elbow out, L palm under axis (m), R
	sk.skeleton_updated.connect(func() -> void:
		var bx := m._baby.global_transform
		var along := bx.basis.z.normalized()
		var bup := bx.basis.y.normalized()
		for s in 2:
			var sd := "left" if s == 0 else "right"
			var pf := fig.palm_frame(sd)
			var d := pf.origin - bx.origin
			# the way a palm under this end should face: up and in towards the
			# bundle's middle, at 45 degrees (WhiteSky.LIFT_PALM)
			var inward := -along if d.dot(along) > 0.0 else along
			var want := (bup + inward).normalized()
			wr[s * 2] = rad_to_deg(acos(clampf(pf.basis.y.dot(want), -1.0, 1.0)))
			wr[s * 2 + 1] = rad_to_deg(acos(clampf(absf(pf.basis.z.dot(along)), 0.0, 1.0)))
			wr[6 + s] = -d.dot(bup)   # (+ under the bundle's axis)
			var pre := "Left" if s == 0 else "Right"
			var sh := fig.to_own(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(pre + "Arm")).origin)
			var el := fig.to_own(sk.global_transform * sk.get_bone_global_pose(sk.find_bone(pre + "ForeArm")).origin)
			wr[4 + s] = (el.x - sh.x) * (1.0 if s == 0 else -1.0))
	var tag := "side" if side else "film"
	var t := 0.0
	var away := 0
	var near_frames := 0
	var worst := [0.0, 0.0]
	while t < 6.0:
		var flag := ""
		for s in 2:
			if m.lift_gap < 0.2:   # (the hands on it: the reach, the lift, the rise)
				near_frames += 1
				worst[s] = maxf(worst[s], wr[s * 2])
				if wr[s * 2] > 90.0:
					away += 1
					flag += " AWAY-" + ("L" if s == 0 else "R")
		print("  wrist %4.1f  gap %.2f | L palm off up-and-in %5.1f fingers off length %5.1f elbow out %+.2f under %+.2f | R palm %5.1f fingers %5.1f elbow %+.2f under %+.2f%s" % [
			t, m.lift_gap, wr[0], wr[1], wr[4], wr[6], wr[2], wr[3], wr[5], wr[7], flag])
		await _shot("%s_%04.1f_gap%.2f" % [tag, t, m.lift_gap])
		await get_tree().create_timer(0.1, false).timeout
		t += 0.1
	print("LIFT: hands' gap at the lift %.3f m (left %.3f, right %.3f)" % [m.lift_gap, m.lift_gaps[0], m.lift_gaps[1]])
	print("WRISTS: %d hand-frames with the hands on the bundle, %d with a palm turned away from it (past 90 degrees off up-and-in); the palm's worst angle off up-and-in left %.0f, right %.0f" % [near_frames, away, worst[0], worst[1]])


func _duel() -> void:
	if OS.get_cmdline_user_args().has("prebuild"):
		# as the game does it: built behind the picture while the pick-up
		# prompt waits, well before the white
		var tp := Time.get_ticks_msec()
		m._prepare_duel()
		print("WHITE SKY PEEK: prepare_duel took %d ms (the frame it's built in)" % (Time.get_ticks_msec() - tp))
		await get_tree().create_timer(4.0, false).timeout
	m._bram.position = WhiteSky.CRATER - Vector3(0, 0, -0.5)
	m._hunter.position = WhiteSky.CRATER + Vector3(0, 0, -8.6)
	m._hunter.visible = true
	m._hunter._set_fade(1.0)
	m._shot(WhiteSky.CRATER + Vector3(0.9, 1.0, 2.6), m._hunter.position + Vector3(0, 2.2, 0), 38.0)
	m._hunter.raise_cards()
	await get_tree().create_timer(1.6, false).timeout
	await _shot("cards_up")
	var t0 := Time.get_ticks_msec()
	var fl := create_tween()
	fl.tween_property(m._white, "modulate:a", 1.0, 0.5)
	await fl.finished
	var done := [false]
	var go := func() -> void:
		await m._duel()
		done[0] = true
	var t1 := Time.get_ticks_msec()
	go.call()
	print("WHITE SKY PEEK: _duel's first frame took %d ms" % (Time.get_ticks_msec() - t1))
	var t := 0.0
	var last := Time.get_ticks_msec()
	while t < 6.0:
		var now := Time.get_ticks_msec()
		print("  t %.1f white %.2f real %d ms since last still" % [t, m._white.modulate.a, now - last])
		last = now
		await _shot("w%.2f_%04.1f" % [m._white.modulate.a, t])
		await get_tree().create_timer(0.1, false).timeout
		t += 0.1
	print("WHITE SKY PEEK: white at %.2f after %.1f s (real %d ms)" % [m._white.modulate.a, t, Time.get_ticks_msec() - t0])
	m.skip()
