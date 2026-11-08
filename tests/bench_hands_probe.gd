extends Node
## Nell's bench and the people on it, measured every frame (8 November,
## Gary: "Hand goes through bench when you sit down with Nell"): Nell sat on
## her bench (AshfordP1.nell_sit), her pat on the seat beside her
## (nell_pats), the player walking to it and sitting down beside her
## (sit_with_nell's walk and sit_down), sitting a while, both talking (their
## sat "talk" clips), and the player getting up (nell_stand). For both of
## them, every frame, as drawn: the hands' skin (tests/hand_skin.gd, the
## skinned mesh's own vertices) and the whole body's skin (every vertex,
## skinned on the CPU) against the bench as built (AshfordP1.dress: the seat,
## the backrest, the two legs, the lantern post), each a box in the bench's
## own frame. A hand's skin more than HAND_TOL in, or the body's (but its
## hands and forearms) more than BODY_TOL into anything but the seat's top
## (BODY_SEAT_TOL there: a seated body's cloth and thighs press on it), is a
## problem.
##
##   godot --headless --fixed-fps 15 --path . res://tests/bench_hands_probe.tscn -- <out_dir> [stills] [nobody] [nolap]
##   (stills: needs a screen; run under xvfb-run with --rendering-driver opengl3)
## Ends with "BENCH HANDS: ok" or the problems.

const HAND_TOL := 0.005
const BODY_TOL := 0.005
const BODY_SEAT_TOL := 0.025

var out := "/tmp/bench_hands"
var stills := false
var body_check := true
## nolap: as it was before 8 November (no hands in the lap, Nell's old pat)
var old_way := false
var world: World
var problems: Array = []
var phase := ""
var _n := 0
## who -> phase -> {"hand": [frames, deepest, where], "body": [...]}
var _seen := {}
var _hs := {}      # who -> hand_skin
var _bs := {}      # who -> [verts(mesh), bones x4, weights x4] for the body
var _bench: Node3D
## The bench's parts in its own frame: [name, centre, half size, x tilt].
var _parts: Array = []


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var look := "a"
	for s in a:
		if String(s) == "stills":
			stills = true
		elif String(s) == "nobody":
			body_check = false
		elif String(s) == "nolap":
			old_way = true
		elif String(s).begins_with("look="):
			look = String(s).substr(5)
		elif not String(s).begins_with("-"):
			out = String(s)
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("look", look)   # (every look plays as Player A in the game: DollArt.player_look)
	Game.set_flag("arrived_ashford")
	AshfordP1.lap_rest = not old_way
	for f in ["ash_started", "p1_crate_down", "corin_met", "first_deck", "ash_won_lantern", "ash_tam", "ash_tilly"]:
		Game.set_flag(f)
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	if world.hud != null:
		world.hud.visible = false
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	world.busy = true
	world.cine = true
	await _frames(10)
	_bench = AshfordP1.meta(AshfordP1.village(world), "p1_bench")
	# as AshfordP1.dress builds it (its own frame: x along it, z out of its front)
	_parts = [
		["the seat", Vector3(0, 0.44, 0), Vector3(0.85, 0.035, 0.21), 0.0],
		["the backrest", Vector3(0, 0.66, -0.2), Vector3(0.85, 0.16, 0.03), -0.15],
		["the west leg", Vector3(-0.7, 0.22, 0), Vector3(0.04, 0.22, 0.19), 0.0],
		["the east leg", Vector3(0.7, 0.22, 0), Vector3(0.04, 0.22, 0.19), 0.0],
		["the lantern post", Vector3(1.05, 0.85, -0.12), Vector3(0.04, 0.85, 0.04), 0.0],
	]
	AshfordP1.nell_sit(world)
	await _secs(0.8)
	for who in ["player", "nell"]:
		var f = Cine.fig(world, who)
		if not (f is Figure3D):
			problems.append("%s isn't a 3D figure" % who)
			continue
		var hs = load("res://tests/hand_skin.gd").new()
		var nv: int = hs.setup(f as Figure3D)
		_hs[who] = hs
		if body_check:
			_bs[who] = _gather_body(f as Figure3D)
		print("  %s: %d hand vertices, %d body vertices" % [who, nv, (_bs.get(who, [PackedVector3Array()])[0] as PackedVector3Array).size()])
		_watch(who, f as Figure3D)
	var seat := AshfordP1.bench_seat(world, true)
	var nseat := AshfordP1.bench_seat(world)
	var fwd := AshfordP1.bench_facing(world)
	var side := fwd.cross(Vector3.UP).normalized()
	# the player stands in front of her, as her talk has them
	Cine.place(world, "player", seat + fwd * 1.5 + side * 0.4, nseat)
	await _secs(0.4)
	# 1. her pat on the seat beside her
	phase = "pat"
	print("  -- ", phase)
	Cine.shot(world, (seat + nseat) * 0.5 + fwd * 1.6 - side * 1.2 + Vector3(0, 0.9, 0), (seat + nseat) * 0.5 + Vector3(0, 0.45, 0), 34.0)
	var pat := func() -> void: await AshfordP1.nell_pats(world)
	if old_way:
		pat = func() -> void: await _old_pat()
	pat.call()
	for i in 6:
		await _secs(0.25)
		await _shot("pat_%d" % i)
	await _secs(0.4)
	# 2. the walk to where the feet will be, and down onto the seat
	phase = "sit_down"
	print("  -- ", phase)
	Cine.shot(world, seat + fwd * 2.4 - side * 1.6 + Vector3(0, 0.9, 0), seat + Vector3(0, 0.5, 0), 36.0)
	var pf := Cine.fig(world, "player") as Figure3D
	var ahead := pf.seat_feet_ahead() if pf != null else 0.6
	await Cine.path(world, "player", [seat + fwd * ahead], 1.3)
	var down := func() -> void: await AshfordP1.sit_down(world, "player", seat, fwd, AshfordP1.BENCH_H, 0.6, true)
	down.call()
	for i in 8:
		await _secs(0.12)
		await _shot("sit_%d" % i)
	await _secs(0.6)
	# 3. sat together
	phase = "sat"
	print("  -- ", phase)
	Cine.shot(world, (seat + nseat) * 0.5 + fwd * 2.9 + Vector3(0, 1.05, 0), (seat + nseat) * 0.5 + Vector3(0, 0.85, 0), 36.0)
	await _secs(0.5)
	await _shot("sat_front")
	for v in [["sat_her_side", nseat - side * 1.7 + fwd * 0.7 + Vector3(0, 0.75, 0)], ["sat_his_side", seat + side * 1.7 + fwd * 0.7 + Vector3(0, 0.75, 0)],
			["sat_low", (seat + nseat) * 0.5 + fwd * 1.4 + Vector3(0, 0.55, 0)], ["sat_above", (seat + nseat) * 0.5 + fwd * 0.9 + Vector3(0, 1.9, 0)]]:
		Cine.shot(world, v[1], (seat + nseat) * 0.5 + Vector3(0, 0.5, 0), 38.0)
		await _secs(0.3)
		await _shot(String(v[0]))
	await _secs(1.5)
	# 4. talking, sat (each says a line: their sat talk clip)
	phase = "talk"
	print("  -- ", phase)
	Cine.shot(world, (seat + nseat) * 0.5 + fwd * 2.4 + Vector3(0, 0.9, 0), (seat + nseat) * 0.5 + Vector3(0, 0.6, 0), 36.0)
	for who in ["nell", "player", "nell"]:
		var tf = Cine.fig(world, who)
		if tf is Figure3D:
			(tf as Figure3D).talking = true
			(tf as Figure3D).act("talk", 1.0)
		for i in 4:
			await _secs(0.5)
			if i % 2 == 1:
				await _shot("talk_%s_%d" % [who, i])
		if tf is Figure3D:
			(tf as Figure3D).talking = false
	await _secs(0.8)
	# 5. up off the bench
	phase = "stand"
	print("  -- ", phase)
	Cine.shot(world, seat + fwd * 2.4 + side * 1.6 + Vector3(0, 0.9, 0), seat + Vector3(0, 0.5, 0), 36.0)
	var up := func() -> void: await AshfordP1.nell_stand(world)
	up.call()
	for i in 10:
		await _secs(0.12)
		await _shot("stand_%d" % i)
	await _secs(1.0)
	phase = ""
	# the numbers
	for who in _seen:
		for ph in ["pat", "sit_down", "sat", "talk", "stand"]:
			var r: Dictionary = _seen[who].get(ph, {})
			for hs in ["left", "right"]:
				if r.has("lap_" + hs):
					print("  %s, %s: %s hand over its thigh's top %.1f to %.1f cm (negative: into it)" % [who, ph, hs, r["lap_" + hs][0] * 100.0, r["lap_" + hs][1] * 100.0])
			for kind in ["hand", "body"]:
				if not r.has(kind):
					continue
				var e: Array = r[kind]
				print("  %s, %s: %s into the bench %d frames, deepest %.1f cm (%s)" % [who, ph, kind, e[0], e[1] * 100.0, e[2]])
				var tol := HAND_TOL if kind == "hand" else BODY_TOL
				# (what they sit on, pressing into the seat's top: the hips and
				# thighs as Figure3D.SEAT_PAD sets them, told but not a problem
				# here; the hands, and anything into the backrest, the legs or
				# the post, are)
				var sat_on: bool = kind == "body" and String(e[2]).begins_with("the seat, by") and ("Hips" in String(e[2]) or "UpLeg" in String(e[2]))
				if int(e[0]) > 0 and float(e[1]) > tol and not sat_on:
					problems.append("%s's %s %.1f cm into %s (%s, %d frames)" % [who, kind, float(e[1]) * 100.0, e[2], ph, e[0]])
	print("BENCH HANDS: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


## Nell's pat as it was before 8 November (her hand's middle 2.5 cm over
## the seat, down 4 cm, and let go back to the clip).
func _old_pat() -> void:
	var f := Cine.fig(world, "nell") as Figure3D
	var pat := Node3D.new()
	world.add_child(pat)
	var seat := AshfordP1.bench_seat(world, true).lerp(AshfordP1.bench_seat(world), 0.3)
	for k in 2:
		pat.global_position = seat + Vector3(0, 0.5, 0) + AshfordP1.bench_facing(world) * 0.05
		f.reach(pat, null, 0.3)
		await Cine.wait(world, 0.35)
		var tw := world.create_tween()
		tw.tween_property(pat, "global_position:y", pat.global_position.y - 0.04, 0.12)
		await tw.finished
	f.let_go(0.4)
	pat.queue_free()


## Every vertex of the figure's skinned meshes, with its four bones and
## weights, for skinning on the CPU (every fourth vertex: enough to find a
## knee or a sleeve in the wood).
func _gather_body(fig: Figure3D) -> Array:
	var skel := fig._skel
	var vs := PackedVector3Array()
	var bs := PackedInt32Array()
	var ws := PackedFloat32Array()
	var binds := {}
	for mi: MeshInstance3D in fig.model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skeleton == NodePath():
			continue
		var skin: Skin = mi.skin
		if skin == null:
			skin = skel.create_skin_from_rest_transforms()
		var bind_bone: Array = []
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = skel.find_bone(skin.get_bind_name(i))
			bind_bone.append(b)
			if b >= 0 and not binds.has(b):
				binds[b] = skin.get_bind_pose(i)
		var local := Transform3D.IDENTITY
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
			for vi in range(0, verts.size(), 4):
				vs.append(local * verts[vi])
				for k in 4:
					if k < per:
						var bi := int(bones[vi * per + k])
						bs.append(bind_bone[bi] if bi < bind_bone.size() else -1)
						ws.append(float(weights[vi * per + k]))
					else:
						bs.append(-1)
						ws.append(0.0)
	var heavy := PackedInt32Array()
	heavy.resize(vs.size())
	var arm := PackedByteArray()
	arm.resize(vs.size())
	for vi in vs.size():
		var hb := -1
		var hw := 0.0
		for k in 4:
			if ws[vi * 4 + k] > hw:
				hw = ws[vi * 4 + k]
				hb = bs[vi * 4 + k]
		heavy[vi] = hb
		# (the hands and forearms are the hand check's: left out of the body's)
		var nm := skel.get_bone_name(hb) if hb >= 0 else ""
		arm[vi] = 1 if ("Hand" in nm or "ForeArm" in nm) else 0
	return [vs, bs, ws, binds, heavy, arm]


func _body_points(fig: Figure3D, data: Array) -> PackedVector3Array:
	var skel := fig._skel
	var xf := skel.global_transform
	var binds: Dictionary = data[3]
	var bt := {}
	for b in binds:
		bt[b] = xf * skel.get_bone_global_pose(b) * (binds[b] as Transform3D)
	var vs: PackedVector3Array = data[0]
	var bs: PackedInt32Array = data[1]
	var ws: PackedFloat32Array = data[2]
	var out := PackedVector3Array()
	out.resize(vs.size())
	for vi in vs.size():
		var p := Vector3.ZERO
		var wsum := 0.0
		for k in 4:
			var b := bs[vi * 4 + k]
			var w := ws[vi * 4 + k]
			if b < 0 or w <= 0.0 or not bt.has(b):
				continue
			p += (bt[b] as Transform3D) * vs[vi] * w
			wsum += w
		out[vi] = p / wsum if wsum > 0.0 else Vector3(0, -100, 0)
	return out


## How far `p` (world) is inside the bench's parts (m; 0 outside), and which.
var _inv := Transform3D.IDENTITY

func _depth(p: Vector3) -> Array:
	var lp := _inv * p
	var best := 0.0
	var where := ""
	for part in _parts:
		var q: Vector3 = lp - (part[1] as Vector3)
		var tilt: float = part[3]
		if tilt != 0.0:
			q = Basis(Vector3.RIGHT, tilt).inverse() * q
		var h: Vector3 = part[2]
		var d := minf(minf(h.x - absf(q.x), h.y - absf(q.y)), h.z - absf(q.z))
		if d > best:
			best = d
			where = String(part[0])
	return [best, where]


func _watch(who: String, fig: Figure3D) -> void:
	_seen[who] = {}
	var sk: Skeleton3D = fig._skel
	var n := [0]
	sk.skeleton_updated.connect(func() -> void:
		if phase == "":
			return
		var rec: Dictionary = _seen[who].get(phase, {})
		_seen[who][phase] = rec
		_inv = _bench.global_transform.affine_inverse()
		# the hands
		var deep := 0.0
		var at := ""
		for side in ["left", "right"]:
			for part in [0, 1, 2, 3]:
				var hp: PackedVector3Array = _hs[who].points(side, part)
				for p in hp:
					var d: Array = _depth(p)
					if float(d[0]) > deep:
						deep = d[0]
						at = "%s hand's %s in %s" % [side, ["palm", "fingers", "thumb", "forearm"][part], d[1]]
		_note(rec, "hand", deep, at)
		# the rest of them, every third frame (the seat's top a little softer)
		n[0] += 1
		if _bs.has(who) and n[0] % 3 == 0:
			var bdeep := 0.0
			var bat := ""
			var pts := _body_points(fig, _bs[who])
			if phase in ["sat", "talk"]:
				_lap_gap(who, fig, pts, rec)
			var arm: PackedByteArray = _bs[who][5]
			for vi in pts.size():
				if arm[vi] == 1:
					continue
				var p := pts[vi]
				var d: Array = _depth(p)
				var dd: float = d[0]
				if String(d[1]) == "the seat":
					var lp := _inv * p
					# (pressed down onto the seat's top: allowed BODY_SEAT_TOL)
					if 0.475 - lp.y < BODY_SEAT_TOL and dd <= 0.475 - lp.y + 0.0001:
						dd = 0.0
					else:
						dd = maxf(0.0, dd - 0.0)
				if dd > bdeep:
					bdeep = dd
					var hb: int = (_bs[who][4] as PackedInt32Array)[vi]
					var lp2 := _inv * p
					bat = "%s, by %s, %.1f cm under the seat's top" % [String(d[1]), fig._skel.get_bone_name(hb) if hb >= 0 else "?", (0.475 - lp2.y) * 100.0]
			_note(rec, "body", bdeep, bat))


## A hand at rest on its thigh: how far its skin is over the thigh's top
## (negative: into it), round the middle of the thigh. "Up" is the thigh's
## top (as LapMarks has it: square to the thigh, up and a little forward);
## the thigh's top there is its skin's highest point that way, the hand's
## its lowest that way, among the hand's points over the thigh.
func _lap_gap(who: String, fig: Figure3D, pts: PackedVector3Array, rec: Dictionary) -> void:
	var sk := fig._skel
	var heavy: PackedInt32Array = _bs[who][4]
	var o := fig.to_world(Vector3.ZERO)
	var fwd := (fig.to_world(Vector3(0, 0, 1)) - o).normalized()
	for side in ["left", "right"]:
		var pre := "Left" if side == "left" else "Right"
		var up := sk.find_bone(pre + "UpLeg")
		var kn := sk.find_bone(pre + "Leg")
		if up < 0 or kn < 0:
			continue
		var a := sk.global_transform * sk.get_bone_global_pose(up).origin
		var b := sk.global_transform * sk.get_bone_global_pose(kn).origin
		var ab := b - a
		var L := ab.length()
		var t := ab / L
		var v := Vector3.UP + fwd * 0.25
		var n := (v - t * v.dot(t)).normalized()
		var top := -INF
		for vi in pts.size():
			if heavy[vi] != up:
				continue
			var d := pts[vi] - a
			var u := d.dot(t) / L
			if u < 0.45 or u > 0.8:
				continue
			var rad := d - t * d.dot(t)
			if rad.length() > 0.001 and rad.normalized().dot(n) > 0.8:
				top = maxf(top, rad.dot(n))
		if top == -INF:
			continue
		var low := INF
		var hp: PackedVector3Array = _hs[who].points(side, -1)
		for p in hp:
			var d: Vector3 = p - a
			var u: float = d.dot(t) / L
			if u < 0.4 or u > 0.85:
				continue
			var rad: Vector3 = d - t * d.dot(t)
			var side_off: float = (rad - n * rad.dot(n)).length()
			if side_off < 0.06:
				low = minf(low, rad.dot(n))
		var key: String = "lap_" + String(side)
		if low < INF:
			if not rec.has(key):
				rec[key] = [INF, -INF]
			rec[key][0] = minf(rec[key][0], low - top)
			rec[key][1] = maxf(rec[key][1], low - top)


func _note(rec: Dictionary, kind: String, deep: float, at: String) -> void:
	if not rec.has(kind):
		rec[kind] = [0, 0.0, ""]
	var e: Array = rec[kind]
	if deep > (HAND_TOL if kind == "hand" else BODY_TOL):
		e[0] = int(e[0]) + 1
	if deep > float(e[1]):
		e[1] = deep
		e[2] = at


func _shot(label: String) -> void:
	if not stills:
		return
	_n += 1
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out.path_join("%03d_%s.png" % [_n, label]))


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
