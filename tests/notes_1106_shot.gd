extends Node
## Gary's 6 November notes on Ashford's first day, staged for real with
## stills (main camera and a close camera) and measured as they play:
##
##   walk:   the opening's green part, from the crate in arms to Corin's first
##           line ("Corin starts walking up when you put down lanterns but then
##           it cuts to him back where he was and walks up again"): Corin's
##           place every frame, any jump over 15 cm in a frame is a problem,
##           and his walk must not start over. The moments are timed (8
##           November, "Corin is back to taking ages to walk over to you
##           instead of as soon as you put crates down"): when he's sent and
##           first moves, when the crate's on the grass, when he's at his
##           mark, when his first line shows; he must be on his way within
##           half a second of the crate touching the grass, and there (or
##           nearly, and not walking) when his line comes.
##   deck:   Bram's box out and the player taking it, the reveal, the low hold
##           ("Bram's card box now goes through player's arm while he's
##           holding it"): the forearms' bones against the box every frame;
##           since 8 November ("Left hand still goes through box as you're
##           holding it when you open it to reveal cards") each hand's skin,
##           every vertex of it, against the box's body as modelled and its
##           lid wherever it's swung, every frame (tests/hand_skin.gd), and
##           the thumbs' bones printed.
##   pond:   the evening on the mill-race wall, the talk to its end with
##           Corin's beats and his button ("his hands look through the wall
##           he is sitting on; his legs also go through the wall when he turns
##           to you"; "When Corin hands you something your hand goes through
##           his"): Corin's hands and legs against the wall every frame, the
##           two hands at the button.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/notes_1106_shot.tscn -- <out_dir> walk|deck|pond [look=a|b|c|d] [newgame]
## (walk newgame: in as a New Game is, World's intro() then resume(); walk
## alone: in from a save at the street part. Both must pass. restage: the
## green staged again as the opening ends, as resume() did after a New
## Game's opening until 8 November; must fail, with Corin's jump.)
## Ends with "NOTES SHOT: ok" or the problems.

const Ashford := preload("res://scripts/world/areas/ashford.gd")

var out := "/tmp/notes"
var mode := "walk"
var look := "a"
var world: World
var hud: WorldHUD
var close_cam: Camera3D
var close_vp: SubViewport
var problems: Array = []
var _n := 0
var _wait := 0
var _done := false
var _drive := false
var _body = null   # "body": the body check over it (tests/body_check.gd)


func _ready() -> void:
	# (11 November: "oldwrist" turns hands at the wrist alone, however far, as
	# they were until then: Figure3D.wrist_natural, the before)
	# (12 November: "nohinge" bends the reaching arms the old way, not at
	# the elbow's hinge (Figure3D.pole_hinge), for the before)
	if "nohinge" in OS.get_cmdline_user_args():
		Figure3D.pole_hinge = false
	if "oldwrist" in OS.get_cmdline_user_args():
		Figure3D.wrist_natural = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	for s in a.slice(1):
		if String(s) in ["walk", "deck", "pond", "wall"]:
			mode = String(s)
		elif String(s).begins_with("look="):
			look = String(s).substr(5)
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("look", look)
	Game.settings["first_steps"] = 2
	# newgame: Ashford not arrived in yet, so World plays the opening through
	# intro() and then calls resume(), as a New Game does (8 November: Corin
	# "disappears and walks over again" only came that way; picked up from a
	# save, resume() stages the green before the opening, which moved nobody)
	if not "newgame" in OS.get_cmdline_user_args():
		Game.set_flag("arrived_ashford")
	match mode:
		"walk":
			# a game picked up at the opening's street part: out of the inn's
			# door with the crate, their own walk to the green, the crate down
			# (Ashford.resume -> AshfordP1.opening), as a player has it
			Game.set_flag("p1_stage", "green" if "fromgreen" in OS.get_cmdline_user_args() else "street")
		"deck":
			for f in ["ash_started", "p1_crate_down"]:
				Game.set_flag(f)
			Game.set_flag("p1_stage", "done")
		"pond", "wall":
			for f in ["ash_started", "p1_crate_down", "corin_met", "first_deck", "ash_won_lantern", "ash_tam", "ash_tilly", "ash_nell", "ash_evening", "tilly_thanks"]:
				Game.set_flag(f)
			Game.set_flag("p1_stage", "done")
	world = World.new().setup("ashford", "green")
	add_child(world)
	if "body" in OS.get_cmdline_user_args():
		_body = load("res://tests/body_check.gd").watch(world, out.path_join("body"))
	hud = world.hud
	close_vp = SubViewport.new()
	close_vp.size = Vector2i(480, 480)
	close_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(close_vp)
	close_cam = Camera3D.new()
	close_cam.fov = 30.0
	close_vp.add_child(close_cam)
	close_cam.current = true
	await _frames(20)
	_force_look()
	await _frames(5)
	match mode:
		"walk":
			await _walk()
		"deck":
			await _deck()
		"pond":
			await _pond()
		"wall":
			await _wall_quick()
	_done = true
	if not Figure3D.wrist_over.is_empty():
		print("  wrists asked past what a wrist does (and stopped there): ", Figure3D.wrist_over)
	if _body != null:
		print(_body.summary())
	print("NOTES SHOT: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


## The game plays Player A whatever the mirror's look (DollArt.player_look,
## Master Script v7); looks B, C and D are put on the player here so their
## hands and arms are seen too (Gary's standing rule: every look).
func _force_look() -> void:
	if look == "a" or not (world.player_doll is Figure3D):
		return
	var old := world.player_doll as Figure3D
	var nd := Figure3D.new().setup("player_" + look) as Figure3D
	world.player.add_child(nd)
	nd.facing_back = old.facing_back
	nd.snap_face(old.facing())
	old.queue_free()
	world.player_doll = nd
	print("  the player is %s" % nd._model_name)


# ================================================================ walk ===

var _backwards := 0
var _hid := false
## A frame's move bigger than this is a jump (m: his brisk walk is 0.2 m a
## frame at the probe's 10 frames a second).
const JUMP := 0.35


func _walk() -> void:
	_drive = true
	# their own walk to the green, the way the test of the opening taps it
	var tapping := [true]
	var taps := func() -> void:
		while tapping[0]:
			await _secs(1.2)
			if tapping[0] and not world.busy and not world.cine:
				var p := world.player.global_position
				var to := p + (Vector3.ZERO - Vector3(p.x, 0, p.z)).normalized() * 5.0
				hud.tapped.emit(world.cam.unproject_position(to))
	taps.call()
	await _until_stage("green", 120.0)
	tapping[0] = false
	if "fromgreen" in OS.get_cmdline_user_args():
		# (picked up at the green: the street's life on the green through
		# the opening's shots, and its picture faded in)
		world.set_meta("life_through_cine", true)
		Cine.overlay(world).black(false)
	var dbg := [true]
	var debug := func() -> void:
		var k := 0
		while dbg[0]:
			await _secs(3.0)
			if not dbg[0]:
				break
			k += 1
			print("  [%d] stage %s busy %s cine %s dlg %s '%s' corin %s player %s" % [k, Game.flag("p1_stage", ""), world.busy, world.cine, hud.dialogue._waiting, hud.dialogue._text.text.left(40), Cine.body(world, "corin").global_position, world.player.global_position])
			if k % 4 == 1:
				await _shot("dbg")
	debug.call()
	print("  at the green (the crate in arms)")
	var cb := Cine.body(world, "corin")
	var trail: Array = []
	var last := cb.global_position
	var jumps := 0
	var started_at := -1
	var t := 0.0
	var next_shot := 0.0
	var f := 0
	# the moments, timed from the green part's start (8 November, Gary: "Corin
	# is back to taking ages to walk over to you instead of as soon as you put
	# crates down"): when he's sent, when he first moves, when the crate
	# touches the grass, when he arrives at his meeting point, when his
	# first line shows
	var when := {}
	var mark := func(key: String, at: float, note := "") -> void:
		if not when.has(key):
			when[key] = snappedf(at, 0.1)
			print("  @ %.1f s: %s%s (Corin %s, %.2f m from the player)" % [at, key, (" " + note) if note != "" else "", Vector2(cb.global_position.x, cb.global_position.z).snapped(Vector2(0.01, 0.01)), Vector2(cb.global_position.x - world.player.global_position.x, cb.global_position.z - world.player.global_position.z).length()])
	var had_crate := world.has_meta("p1_crate")
	var arrived := false
	var sent_at := 0
	# until his first line is up (or long enough)
	while t < 60.0:
		await get_tree().process_frame
		f += 1
		t += get_process_delta_time()
		if not is_instance_valid(cb):
			break
		if world.has_meta("corin_coming"):
			if not when.has("corin sent"):
				sent_at = trail.size()
			mark.call("corin sent", t, "(corin_sets_off)")
		if had_crate and not world.has_meta("p1_crate"):
			mark.call("crate on the grass", t)
		if Game.flag("p1_crate_down"):
			mark.call("p1_crate_down", t)
		if world.get_meta("bram_seated", false):
			mark.call("Bram seated", t)
		if String(Game.flag("p1_stage", "")) == "done":
			if not when.has("opening done") and "restage" in OS.get_cmdline_user_args():
				# (as Ashford.resume did straight after a New Game's opening
				# until 8 November: the probe's own check that it would catch it)
				AshfordP1.pose(world)
				AshfordDay.stage(world)
			mark.call("opening done", t)
		if world._talk_target != null:
			mark.call("talk started", t)
		if cb.has_meta("corin_called"):
			mark.call("corin_calls", t)
		if world.has_meta("corin_meet") and not arrived:
			var mt: Vector3 = world.get_meta("corin_meet")
			if Vector2(cb.global_position.x - mt.x, cb.global_position.z - mt.z).length() < 0.3:
				arrived = true
				mark.call("Corin at his meeting point", t)
		var p := cb.global_position
		var step := Vector2(p.x - last.x, p.z - last.z).length()
		# hidden and shown again (his body, or his model under it)
		var cvis: bool = cb.is_visible_in_tree()
		var cfv = Cine.fig(world, "corin")
		if cfv is Figure3D and (cfv as Figure3D).model != null:
			cvis = cvis and (cfv as Figure3D).model.is_visible_in_tree()
		if not cvis and not _hid:
			_hid = true
			problems.append("Corin was hidden at %.1f s" % t)
			print("  PROBLEM: Corin hidden at %.1f s" % t)
		# walking one way and facing another (turned back to look at
		# where he was, mid-walk)
		var cfw = Cine.fig(world, "corin")
		if step > 0.05 and cfw is Figure3D:
			var mv := Vector3(p.x - last.x, 0, p.z - last.z).normalized()
			if (cfw as Figure3D).facing().dot(mv) < 0.3:
				_backwards += 1
		if step > JUMP:
			jumps += 1
			var msg := "Corin jumped %.2f m in a frame at %.1f s (%s -> %s)" % [step, t, last, p]
			problems.append(msg)
			print("  PROBLEM: ", msg)
			await _shot("jump")
		if step > 0.01 and started_at < 0:
			started_at = f
			print("  Corin sets off at %.1f s from %s" % [t, last])
			mark.call("Corin first moves", t)
		if step > 0.01 and world.has_meta("corin_coming"):
			mark.call("Corin walks over", t, "(his first step on the way)")
		last = p
		trail.append(p)
		if f % 3 == 0:
			var cfg = Cine.fig(world, "corin")
			print("    t %.1f corin %s coming %s busy %s walking %s action '%s' crate_down %s talk %s" % [t, Vector2(p.x, p.z).snapped(Vector2(0.01, 0.01)), world.has_meta("corin_coming"), cb.has_meta("life_busy"), cfg.walking, cfg._action, Game.flag("p1_crate_down"), world._talk_target != null])
		if started_at >= 0 and t >= next_shot:
			next_shot = t + 0.5
			_aim_two("corin", "player")
			await _shot("walk_%.1f" % t)
		if hud.dialogue._waiting and hud.dialogue._name.text == "Corin":
			print("  first line at %.1f s: %s" % [t, hud.dialogue._text.text.left(60)])
			mark.call("Corin's first line", t)
			break
	print("  times (s from the green's start): %s" % str(when))
	if when.has("crate on the grass") and when.has("Corin walks over") and float(when["Corin walks over"]) > float(when["crate on the grass"]) + 0.5:
		problems.append("Corin only set off %.1f s after the crate was on the grass" % (float(when["Corin walks over"]) - float(when["crate on the grass"])))
	elif when.has("crate on the grass") and not when.has("Corin walks over"):
		problems.append("Corin never set off on his own (corin_sets_off)")
	if when.has("Corin's first line"):
		var cfl = Cine.fig(world, "corin")
		var gap := Vector2(cb.global_position.x - world.player.global_position.x, cb.global_position.z - world.player.global_position.z).length()
		if gap > AshfordP1.CORIN_MEET + 0.5 or (cfl != null and cfl.walking):
			problems.append("Corin's first line came with him still on his way (%.2f m off%s)" % [gap, ", walking" if cfl != null and cfl.walking else ""])
	# did he turn back on himself (a second walk from where he started)?
	# (from when he's sent: before that the green's life has him shift a
	# step about his spot, any way it likes)
	var back := 0
	for i in range(sent_at + 10, trail.size()):
		var a: Vector3 = trail[i - 10]
		var b: Vector3 = trail[i]
		var pl := world.player.global_position
		if Vector2(b.x - pl.x, b.z - pl.z).length() > Vector2(a.x - pl.x, a.z - pl.z).length() + 0.3:
			back += 1
	if _backwards > 3:
		problems.append("Corin walked %d frames facing away from his way" % _backwards)
	if back > 0:
		problems.append("Corin went away from the player again (%d frames)" % back)
	dbg[0] = false
	var pl := world.player.global_position
	print("  Corin ends %.2f m from the player; %d jumps" % [Vector2(last.x - pl.x, last.z - pl.z).length(), jumps])
	await _secs(0.6)
	_aim_two("corin", "player")
	await _shot("talk")


# ================================================================ deck ===

var _arm_hits := 0
var _arm_deep := 0.0
var _finger_hits := 0
var _finger_deep := 0.0
var _seen_frames := 0
var _arm_when: Array = []
var _arm_where := ""
var _finger_where := ""
var _finger_when: Array = []
var _t0 := 0.0


func _deck() -> void:
	var v: AshfordVillage = AshfordP1.village(world)
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	world.busy = true
	world.cine = true
	await _frames(10)
	var spot := AshfordP1.GREEN_SPOT
	spot.y = v.height(spot.x, spot.z)
	var corin_at := spot + Vector3(-1.9, 0, -0.6)
	corin_at.y = v.height(corin_at.x, corin_at.z)
	Cine.place(world, "player", spot, corin_at)
	Cine.place(world, "corin", corin_at, spot)
	AshfordP1.bram_sit(world)
	await _frames(20)
	await Ashford._bram_sets_off(world)
	await Ashford._bram_comes(world)
	await _secs(0.6)
	await Ashford._box_out_scene(world)
	print("  look %s: the box sits %.1f cm back from the middle of the left palm" % [look, Ashford._box_back(Cine.fig(world, "player"), Ashford.box_size(world.get_meta("box_bram", null))) * 100.0])
	_t0 = Time.get_ticks_msec() * 0.001
	_watch_box_arms(Cine.fig(world, "player") as Figure3D)
	var going := [true]
	var stills := func() -> void:
		var i := 0
		while going[0]:
			await _secs(0.3)
			if not going[0]:
				break
			_aim_box(i)
			await _shot("box_%02d" % i)
			i += 1
	stills.call()
	var reveal := func() -> void:
		while going[0]:
			await get_tree().process_frame
			for l in world.get_children():
				if l is CanvasLayer:
					for c in l.get_children():
						if c is DeckReveal and not c.has_meta("seen"):
							c.set_meta("seen", true)
							await _secs(1.5)
							(c as DeckReveal)._ready_to_close = true
							(c as DeckReveal)._close()
	reveal.call()
	await Ashford._first_deck(world)
	await _secs(1.5)
	going[0] = false
	await _secs(0.4)
	print("  box: %d frames seen; forearm in the box %d frames (deepest %.1f cm); fingers in it %d frames (deepest %.1f cm)" % [_seen_frames, _arm_hits, _arm_deep * 100.0, _finger_hits, _finger_deep * 100.0])
	print("  deepest forearm point: ", _arm_where)
	print("  deepest finger point: ", _finger_where)
	print("  forearm hits at %s; finger hits at %s (of the frames it's held)" % [str(_arm_when.slice(0, 12)), str(_finger_when.slice(0, 12))])
	print("  thumb bones in the box %d frames (deepest %.1f cm)" % [_thumb_hits, _thumb_deep * 100.0])
	for side in ["left", "right"]:
		var s: Array = _skin[side]
		var l: Array = _lid_skin[side]
		print("  %s hand's skin in the box's body %d frames (deepest %.1f cm, %s; frames %s); in the lid %d frames (deepest %.1f cm, %s; frames %s)" % [
			side, s[0], float(s[1]) * 100.0, s[2], str((s[3] as Array).slice(0, 16)), l[0], float(l[1]) * 100.0, l[2], str((l[3] as Array).slice(0, 16))])
		if int(s[0]) > 0:
			problems.append("the player's %s hand's skin went %.1f cm into the box in %d frames" % [side, float(s[1]) * 100.0, s[0]])
		if int(l[0]) > 0:
			problems.append("the player's %s hand's skin went %.1f cm into the lid in %d frames" % [side, float(l[1]) * 100.0, l[0]])
	if _arm_hits > 0:
		problems.append("the player's forearm went %.1f cm into the box in %d frames" % [_arm_deep * 100.0, _arm_hits])
	# (Player A's finger joints, as his rig placed them, lie jumbled within a
	# centimetre or two of his knuckles and not along the fingers, Figure3D.
	# FROZEN: for him the stills are the check, the bones only printed)
	var pfig := Cine.fig(world, "player") as Figure3D
	if _finger_hits > 0 and not (pfig != null and Figure3D.FROZEN.has(pfig._model_name)):
		problems.append("the player's fingers went %.1f cm into the box in %d frames" % [_finger_deep * 100.0, _finger_hits])


## Every frame, as drawn: points along each forearm (elbow to wrist, the
## forearm's flesh round its bone taken as FOREARM_R) and each finger's bones
## (FINGER_R) against the box the player holds, in the box's own frame.
const FOREARM_R := 0.032
const FOREARM_WRIST_R := 0.022
const FINGER_R := 0.009


## And (8 November, Gary: "Left hand still goes through box as you're holding
## it when you open it to reveal cards") each hand's skin itself, every vertex
## of it (tests/hand_skin.gd: Player A's finger bones say nothing about where
## his fingers are), against the box's body as modelled and against its lid,
## wherever the lid has swung to, every frame it's held.
var _skin := {}         # side -> [frames in the body, deepest, where, when]
var _lid_skin := {}     # side -> [frames in the lid, deepest, where, when]
var _thumb_hits := 0
var _thumb_deep := 0.0
var _body_aabb := AABB()
var _lid_aabb := AABB()
var _lid_node: Node3D = null
var _hs = null


## The box's body (not its lid, not the deck in it) as modelled, in the box's
## own frame; and the lid's, in the lid's frame.
func _box_extents(box: Node3D) -> void:
	_lid_node = box.get_node_or_null("Lid") as Node3D
	if _lid_node == null:
		_lid_node = box.find_child("Lid", true, false) as Node3D
	var first_b := true
	var first_l := true
	for mi: MeshInstance3D in box.find_children("*", "MeshInstance3D", true, false):
		if mi.name in ["Deck", "TopCard"]:
			continue
		var in_lid := _lid_node != null and (mi == _lid_node or _lid_node.is_ancestor_of(mi))
		var root: Node3D = _lid_node if in_lid else box
		var xf := root.global_transform.affine_inverse() * mi.global_transform
		var ab := xf * mi.get_aabb()
		if in_lid:
			_lid_aabb = ab if first_l else _lid_aabb.merge(ab)
			first_l = false
		else:
			_body_aabb = ab if first_b else _body_aabb.merge(ab)
			first_b = false
	print("  the box's body as modelled: %s (CARD_BOX_SIZE %s); its lid: %s" % [_body_aabb, Ashford.CARD_BOX_SIZE, _lid_aabb])


func _in_aabb(q: Vector3, ab: AABB) -> float:
	# how deep inside (m), 0 outside
	if not ab.has_point(q):
		return 0.0
	return minf(minf(q.x - ab.position.x, ab.end.x - q.x), minf(minf(q.y - ab.position.y, ab.end.y - q.y), minf(q.z - ab.position.z, ab.end.z - q.z)))


func _watch_box_arms(fig: Figure3D) -> void:
	if fig == null:
		return
	var sk: Skeleton3D = fig._skel
	_hs = preload("res://tests/hand_skin.gd").new()
	var nv: int = _hs.setup(fig)
	print("  the hands' skin: %d vertices (left %d, right %d)" % [nv, _hs.count("left"), _hs.count("right")])
	for side in ["left", "right"]:
		_skin[side] = [0, 0.0, "", []]
		_lid_skin[side] = [0, 0.0, "", []]
	sk.skeleton_updated.connect(func() -> void:
		var box = world.get_meta("box_player") if world.has_meta("box_player") else null
		if box == null or not is_instance_valid(box) or not (box as Node3D).is_inside_tree() or fig.holding() != box:
			return
		_seen_frames += 1
		if _body_aabb.size == Vector3.ZERO:
			_box_extents(box)
		var bx := (box as Node3D).global_transform.affine_inverse()
		var half: Vector3 = Ashford.box_size(box) * 0.5
		var xf := sk.global_transform
		# the skin of each hand against the body and the lid
		var skin_pts := {}
		for side in ["left", "right"]:
			var pts: PackedVector3Array = _hs.points(side)
			skin_pts[side] = pts
			var deep_b := 0.0
			var where_b := Vector3.ZERO
			var deep_l := 0.0
			var where_l := Vector3.ZERO
			var lx: Transform3D = _lid_node.global_transform.affine_inverse() if _lid_node != null else Transform3D.IDENTITY
			for p in pts:
				var q: Vector3 = bx * p
				var d := _in_aabb(q, _body_aabb)
				if d > deep_b:
					deep_b = d
					where_b = q
				if _lid_node != null:
					var ql: Vector3 = lx * p
					var dl := _in_aabb(ql, _lid_aabb)
					if dl > deep_l:
						deep_l = dl
						where_l = ql
			if deep_b > 0.002:
				_skin[side][0] += 1
				if deep_b > float(_skin[side][1]):
					_skin[side][1] = deep_b
					_skin[side][2] = "%s in the box's frame, frame %d" % [where_b.snapped(Vector3(0.001, 0.001, 0.001)), _seen_frames]
				(_skin[side][3] as Array).append(_seen_frames)
				# (where the hand is, for finding the moment: its wrist in the
				# box's frame, and what the hand's reaching for)
				var pre := "Left" if side == "left" else "Right"
				var wr := bx * (xf * sk.get_bone_global_pose(sk.find_bone(pre + "Hand")).origin)
				var ik = fig._ik.get(side)
				var tgt := ""
				if ik != null and is_instance_valid(ik) and ik.has_meta("target"):
					var tn = ik.get_meta("target")
					tgt = String((tn as Node).name) if tn != null and is_instance_valid(tn) else "?"
				print("    frame %d: the %s hand's skin %.1f cm in at %s; its wrist at %s in the box's frame, reaching for '%s' (%.1f s)" % [_seen_frames, side, deep_b * 100.0, where_b.snapped(Vector3(0.001, 0.001, 0.001)), wr.snapped(Vector3(0.001, 0.001, 0.001)), tgt, Time.get_ticks_msec() * 0.001 - _t0])
			if deep_l > 0.002:
				_lid_skin[side][0] += 1
				if deep_l > float(_lid_skin[side][1]):
					_lid_skin[side][1] = deep_l
					_lid_skin[side][2] = "%s in the lid's frame (lid at %.0f deg), frame %d" % [where_l.snapped(Vector3(0.001, 0.001, 0.001)), rad_to_deg(_lid_node.rotation.x), _seen_frames]
				(_lid_skin[side][3] as Array).append(_seen_frames)
				var pre_l := "Left" if side == "left" else "Right"
				var wr_l: Vector3 = lx * (xf * sk.get_bone_global_pose(sk.find_bone(pre_l + "Hand")).origin)
				var ik_l = fig._ik.get(side)
				var tgt_l := ""
				var inf_l := 0.0
				if ik_l != null and is_instance_valid(ik_l) and ik_l.has_meta("target"):
					var tn_l = ik_l.get_meta("target")
					tgt_l = String((tn_l as Node).name) if tn_l != null and is_instance_valid(tn_l) else "?"
					inf_l = (ik_l as TwoBoneIK3D).influence
				print("    frame %d: the %s hand's skin %.1f cm in the lid at %s (lid at %.0f deg); its wrist at %s in the lid's frame, reaching for '%s' (%.2f on)" % [_seen_frames, side, deep_l * 100.0, where_l.snapped(Vector3(0.001, 0.001, 0.001)), rad_to_deg(_lid_node.rotation.x), wr_l.snapped(Vector3(0.001, 0.001, 0.001)), tgt_l, inf_l])
		var deep_arm := 0.0
		var deep_f := 0.0
		# the thumbs' bones too (printed: Player A's lie off the thumb)
		var thumb_in := false
		for pre in ["Left", "Right"]:
			for j in [1, 2, 3]:
				var tb := sk.find_bone(pre + "HandThumb" + str(j))
				if tb < 0:
					continue
				var tp := xf * sk.get_bone_global_pose(tb).origin
				var td := _depth(bx * tp, half, FINGER_R)
				if td > 0.004:
					_thumb_deep = maxf(_thumb_deep, td)
					thumb_in = true
		if thumb_in:
			_thumb_hits += 1
		for pre in ["Left", "Right"]:
			var e := xf * sk.get_bone_global_pose(sk.find_bone(pre + "ForeArm")).origin
			var wr := xf * sk.get_bone_global_pose(sk.find_bone(pre + "Hand")).origin
			# (the forearm up to 3 cm short of the wrist bone: the heel of the
			# hand is meant to be under the box's back edge)
			var fl := e.distance_to(wr)
			for k in 9:
				var p := e.lerp(wr, float(k) / 8.0 * maxf(0.0, 1.0 - 0.03 / maxf(fl, 0.01)))
				var dd := _depth(bx * p, half, lerpf(FOREARM_R, FOREARM_WRIST_R, float(k) / 8.0) * fig.stature())
				if dd > deep_arm:
					deep_arm = dd
				if dd > _arm_deep:
					_arm_where = "%s forearm, %d/8 of the way to the wrist, at %s in the box's frame (elbow %s, wrist %s, frame %d)" % [pre, k, (bx * p).snapped(Vector3(0.005, 0.005, 0.005)), (bx * e).snapped(Vector3(0.005, 0.005, 0.005)), (bx * wr).snapped(Vector3(0.005, 0.005, 0.005)), _seen_frames]
			for fn in ["Index", "Middle", "Ring", "Pinky"]:
				for j in [1, 2, 3]:
					var b := sk.find_bone(pre + "Hand" + fn + str(j))
					if b < 0:
						continue
					var p := xf * sk.get_bone_global_pose(b).origin
					var dd := _depth(bx * p, half, FINGER_R)
					if dd > deep_f:
						deep_f = dd
					if dd > _finger_deep:
						_finger_where = "%sHand%s%d at %s in the box's frame" % [pre, fn, j, (bx * p).snapped(Vector3(0.005, 0.005, 0.005))]
		var now := Time.get_ticks_msec() * 0.001 - _t0
		if deep_arm > 0.004:
			_arm_hits += 1
			_arm_deep = maxf(_arm_deep, deep_arm)
			_arm_when.append(_seen_frames)
		if deep_f > 0.004:
			_finger_hits += 1
			_finger_deep = maxf(_finger_deep, deep_f)
			_finger_when.append(_seen_frames))


## How deep a ball of radius r at `q` (the box's frame) is in the box of
## half-size `half` (m; 0 if clear).
func _depth(q: Vector3, half: Vector3, r: float) -> float:
	# (the distance from the box's skin, rounded at its edges and corners as
	# a limb's flesh meets them)
	var e := q.abs() - half
	var outside := Vector3(maxf(e.x, 0.0), maxf(e.y, 0.0), maxf(e.z, 0.0)).length()
	var inside := minf(maxf(e.x, maxf(e.y, e.z)), 0.0)
	return maxf(0.0, r - (outside + inside))


func _aim_box(i: int) -> void:
	var bx = world.get_meta("box_player") if world.has_meta("box_player") else (world.get_meta("box_bram") if world.has_meta("box_bram") else null)
	var pf := Cine.fig(world, "player") as Figure3D
	if bx == null or not is_instance_valid(bx) or not (bx as Node3D).is_inside_tree() or pf == null:
		_aim_two("player", "bram")
		return
	var at := (bx as Node3D).global_position
	var fwd := pf.facing()
	# (from the side of the hand it's carried on: their left, or for Player A
	# their right, 9 November, Ashford.carry_side)
	var left := Vector3.UP.cross(fwd).normalized() * Ashford._box_mirror(pf)
	match i % 4:
		0:   # from their left side, level with the box: the forearms under it
			close_cam.global_position = at + left * 0.75 + Vector3(0, 0.05, 0)
		1:   # from in front of them, to their left and a little below, up at
			# the hands (Bram stands square in front)
			close_cam.global_position = at + fwd * 0.35 + left * 0.55 + Vector3(0, -0.14, 0)
		2:   # from above, to their left and a little ahead (down onto the
			# hands, clear of their head and Bram's)
			close_cam.global_position = at + fwd * 0.15 + left * 0.42 + Vector3(0, 0.5, 0)
		3:   # the reveal's own view, nearer: from their left, ahead and over
			# it, down into the box (the left hand under its middle, the lid)
			close_cam.global_position = at + left * 0.32 + fwd * 0.12 + Vector3(0, 0.3, 0)
	close_cam.look_at(at)
	close_cam.fov = 30.0


# ================================================================ pond ===

var _wall: AABB
var _leg_hits := 0
var _leg_deep := 0.0
var _hand_hits := 0
var _hand_deep := 0.0
var _palm_hits := 0
var _palm_deep := 0.0
var _pond_frames := 0


func _pond() -> void:
	var v: AshfordVillage = AshfordP1.village(world)
	var m := MillSet.build(v)
	var root: Node3D = m.root
	# the race wall (MillSet.build: the low wall along the west bank)
	_wall = AABB(root.to_global(Vector3(1.0 - 0.25, 0.0, 7.5 - 3.0)), Vector3(0.5, 0.5, 6.0))
	print("  the wall: %s" % _wall)
	_drive = true
	_watch_corin(Cine.fig(world, "corin") as Figure3D)
	_watch_button()
	var going := [true]
	var stills := func() -> void:
		var i := 0
		while going[0]:
			await _secs(0.45)
			if not going[0] or not AshfordDay.at_mill(Cine.body(world, "corin").global_position):
				continue
			_aim_corin(i)
			await _shot("pond_%03d" % i)
			i += 1
	stills.call()
	await AshfordDay.to_mill(world)
	going[0] = false
	await _secs(0.3)
	print("  pond: %d frames; Corin's legs in the wall %d frames (deepest %.1f cm); hands in it %d frames (deepest %.1f cm); the two palms into each other %d frames (deepest %.1f cm)" % [
		_pond_frames, _leg_hits, _leg_deep * 100.0, _hand_hits, _hand_deep * 100.0, _palm_hits, _palm_deep * 100.0])
	if _leg_hits > 0:
		problems.append("Corin's legs went %.1f cm into the wall in %d frames" % [_leg_deep * 100.0, _leg_hits])
	if _hand_hits > 0:
		problems.append("Corin's hands went %.1f cm into the wall in %d frames" % [_hand_deep * 100.0, _hand_hits])
	if _palm_hits > 0:
		problems.append("the two hands went %.1f cm into each other at the button in %d frames" % [_palm_deep * 100.0, _palm_hits])


## `wall`: the same, quickly: the two of them sat on the wall as the film
## leaves them, Corin talking, his two beats and the button, without the
## rest of the talk (the film itself: `pond`).
func _wall_quick() -> void:
	var v: AshfordVillage = AshfordP1.village(world)
	var m := MillSet.build(v)
	var root: Node3D = m.root
	_wall = AABB(root.to_global(Vector3(1.0 - 0.25, 0.0, 7.5 - 3.0)), Vector3(0.5, 0.5, 6.0))
	world.busy = true
	world.cine = true
	MillSet.enter(world)
	MillSet.lamps(v, true)
	var cb := Cine.body(world, "corin")
	if not AshfordDay.at_mill(cb.global_position):
		AshfordDay._to_spot(world, "corin")
	AshfordDay._sit_corin(world)
	var old := "old" in OS.get_cmdline_user_args()
	if old:
		# (as it was before 6 November: on the wall's middle, the hands the
		# clip's, a beat turning his whole body)
		AshfordDay._corin_up(world)
		AshfordP1.sit_down(world, "corin", MillSet.spot(Vector3(1.0, 0, 7.0)), Vector3.LEFT, 0.5, 0.0)
	var seat := cb.global_position
	var fwd := Vector3.LEFT
	var along := Vector3.BACK
	var beside := seat + along * 0.78
	# (as the film sits them since 8 November: their hands in their lap, the
	# wall solid to them; "old": the clip's hanging arms)
	if not old and world.player_doll is Figure3D:
		(world.player_doll as Figure3D).hands_off([AshfordDay._wall_box()])
	AshfordP1.lap_rest = not old
	AshfordP1.sit_down(world, "player", beside, fwd, 0.5, 0.0, not old)
	await _frames(10)
	var mid := (seat + beside) * 0.5
	Cine.shot(world, mid + fwd * 2.6 + Vector3(0, 1.05, 0), mid + Vector3(0, 0.85, 0), 40.0)
	_watch_corin(Cine.fig(world, "corin") as Figure3D)
	_watch_player_hands(world.player_doll as Figure3D)
	_watch_button()
	var going := [true]
	var stills := func() -> void:
		var i := 0
		while going[0]:
			await _secs(0.35)
			if not going[0]:
				break
			_aim_corin(i)
			await _shot("wall_%03d" % i)
			i += 1
	stills.call()
	await _secs(1.2)
	var cf := Cine.fig(world, "corin") as Figure3D
	cf.talking = true
	await _secs(2.0)
	cf.talking = false
	print("  a beat")
	if old:
		await AshfordP1.beat(world, "corin")
	else:
		await AshfordDay.scene("beat", world)
	await _secs(0.6)
	if old:
		going[0] = false
		await _secs(0.4)
		print("  old: legs in the wall %d frames (deepest %.1f cm); hands in it %d frames (deepest %.1f cm); the player's hands in it %d frames (deepest %.1f cm)" % [_leg_hits, _leg_deep * 100.0, _hand_hits, _hand_deep * 100.0, _p_hand_hits, _p_hand_deep * 100.0])
		return
	print("  the button")
	await AshfordDay.corin_button(world)
	await _secs(1.0)
	print("  a beat")
	await AshfordDay.scene("beat", world)
	await _secs(0.8)
	going[0] = false
	await _secs(0.4)
	print("  wall: %d frames; Corin's legs in the wall %d frames (deepest %.1f cm); hands in it %d frames (deepest %.1f cm); the two palms into each other %d frames (deepest %.1f cm); the player's hands in it %d frames (deepest %.1f cm)" % [
		_pond_frames, _leg_hits, _leg_deep * 100.0, _hand_hits, _hand_deep * 100.0, _palm_hits, _palm_deep * 100.0, _p_hand_hits, _p_hand_deep * 100.0])
	if _p_hand_hits > 0:
		problems.append("the player's hands went %.1f cm into the wall in %d frames" % [_p_hand_deep * 100.0, _p_hand_hits])
	if _leg_hits > 0:
		problems.append("Corin's legs went %.1f cm into the wall in %d frames" % [_leg_deep * 100.0, _leg_hits])
	if _hand_hits > 0:
		problems.append("Corin's hands went %.1f cm into the wall in %d frames" % [_hand_deep * 100.0, _hand_hits])
	if _palm_hits > 0:
		problems.append("the two hands went %.1f cm into each other at the button in %d frames" % [_palm_deep * 100.0, _palm_hits])


const LEG_R := 0.05     # a shin's or thigh's flesh round its bone (m)
const HAND_R := 0.012   # a hand's skin off its bones


func _watch_corin(fig: Figure3D) -> void:
	var sk: Skeleton3D = fig._skel
	sk.skeleton_updated.connect(func() -> void:
		if fig.seat < 0.0 or not AshfordDay.at_mill(fig.global_position):
			return
		_pond_frames += 1
		var xf := sk.global_transform
		var deep_leg := 0.0
		for pre in ["Left", "Right"]:
			var kn := xf * sk.get_bone_global_pose(sk.find_bone(pre + "Leg")).origin
			var ft := xf * sk.get_bone_global_pose(sk.find_bone(pre + "Foot")).origin
			# (the shin, knee to ankle; the thigh lies on the wall's top)
			for k in 7:
				var p := kn.lerp(ft, float(k) / 6.0)
				deep_leg = maxf(deep_leg, _in_wall(p, LEG_R * 0.8))
		if deep_leg > 0.01:
			_leg_hits += 1
			_leg_deep = maxf(_leg_deep, deep_leg)
		var deep_h := 0.0
		for pre in ["Left", "Right"]:
			for bn in ["Hand", "HandIndex1", "HandIndex3", "HandMiddle1", "HandMiddle3", "HandPinky1", "HandPinky3", "HandThumb3"]:
				var b := sk.find_bone(pre + bn)
				if b < 0:
					continue
				deep_h = maxf(deep_h, _in_wall(xf * sk.get_bone_global_pose(b).origin, HAND_R))
		if deep_h > 0.006:
			_hand_hits += 1
			_hand_deep = maxf(_hand_deep, deep_h))


## The player sat on the wall beside him (8 November): their hands' bones
## against it every frame, as Corin's are.
var _p_hand_hits := 0
var _p_hand_deep := 0.0

func _watch_player_hands(fig: Figure3D) -> void:
	if fig == null:
		return
	var sk: Skeleton3D = fig._skel
	sk.skeleton_updated.connect(func() -> void:
		if fig.seat < 0.0 or not AshfordDay.at_mill(fig.global_position):
			return
		var xf := sk.global_transform
		var deep_h := 0.0
		for pre in ["Left", "Right"]:
			for bn in ["Hand", "HandIndex1", "HandIndex3", "HandMiddle1", "HandMiddle3", "HandPinky1", "HandPinky3", "HandThumb3"]:
				var b := sk.find_bone(pre + bn)
				if b < 0:
					continue
				deep_h = maxf(deep_h, _in_wall(xf * sk.get_bone_global_pose(b).origin, HAND_R))
		if deep_h > 0.006:
			_p_hand_hits += 1
			_p_hand_deep = maxf(_p_hand_deep, deep_h))


func _in_wall(p: Vector3, r: float) -> float:
	var b := _wall.grow(r)
	if not b.has_point(p):
		return 0.0
	return minf(minf(p.x - b.position.x, b.end.x - p.x), minf(minf(p.y - b.position.y, b.end.y - p.y), minf(p.z - b.position.z, b.end.z - p.z)))


## While the button changes hands: the two hands' bones, each kept a skin's
## width (HAND_R) off the other's palm plane, close up stills.
func _watch_button() -> void:
	var pf := world.player_doll as Figure3D
	var cf := Cine.fig(world, "corin") as Figure3D
	if pf == null or cf == null:
		return
	var check := func() -> void:
		var b := world.get_node_or_null("Button") as Node3D
		if b == null:
			return
		for pair in [[pf, cf], [cf, pf]]:
			var a: Figure3D = pair[0]
			var o: Figure3D = pair[1]
			for side_o in ["left", "right"]:
				var pre_o := "Left" if side_o == "left" else "Right"
				var ho := o._skel.find_bone(pre_o + "Hand")
				var wo := o._skel.global_transform * o._skel.get_bone_global_pose(ho).origin
				# only the hand near the button
				if wo.distance_to(b.global_position) > 0.2:
					continue
				var fr := o.palm_frame(side_o)
				for pre in ["Left", "Right"]:
					for bn in ["Hand", "HandIndex1", "HandIndex3", "HandMiddle1", "HandMiddle3", "HandRing2", "HandPinky1", "HandPinky3", "HandThumb2", "HandThumb3"]:
						var bi := a._skel.find_bone(pre + bn)
						if bi < 0:
							continue
						var p := a._skel.global_transform * a._skel.get_bone_global_pose(bi).origin
						var q := fr.affine_inverse() * p
						# within the other hand's palm (across 5 cm, along 9 cm from
						# its wrist to its finger roots) and through its thickness
						if absf(q.x) < 0.045 and q.z > -0.06 and q.z < 0.06 and q.y < 0.0 and q.y > -0.04:
							_palm_hits += 1
							_palm_deep = maxf(_palm_deep, -q.y)
	world.get_tree().process_frame.connect(func() -> void:
		if world.get_node_or_null("Button") != null:
			check.call())


func _aim_corin(i: int) -> void:
	var cb := Cine.body(world, "corin")
	var cf := Cine.fig(world, "corin") as Figure3D
	var at := cb.global_position + Vector3(0, 0.75, 0)
	var b := world.get_node_or_null("Button") as Node3D
	if b != null:
		# the button between them: close on the hands, from in front and from
		# above-front
		var mid := b.global_position
		if i % 2 == 0:
			close_cam.global_position = mid + Vector3(-0.75, 0.2, 0.15)
		else:
			close_cam.global_position = mid + Vector3(-0.45, 0.5, -0.35)
		close_cam.look_at(mid)
		close_cam.fov = 32.0
		return
	match i % 3:
		0:   # from the meadow, low: the legs against the wall's face
			close_cam.global_position = at + Vector3(-1.6, -0.25, -0.9)
		1:   # along the wall, level with its top: the hands on it
			close_cam.global_position = at + Vector3(-0.35, 0.05, -1.7)
		2:   # from above and in front: the hands and lap
			close_cam.global_position = at + Vector3(-1.1, 0.8, 0.5)
	close_cam.look_at(at + Vector3(0, -0.15, 0))
	close_cam.fov = 34.0 if cf != null else 40.0


# ============================================================== driving ===

func _process(_d: float) -> void:
	if world == null or hud == null or _done or not _drive:
		return
	var dlg := hud.dialogue
	if dlg._choices.visible:
		_wait += 1
		if _wait > 8:
			_wait = 0
			dlg._chosen.emit(0)
	elif dlg._waiting:
		if dlg._typing:
			dlg._tap()
		_wait += 1
		if _wait == 6:
			print("  ", (dlg._name.text + ": ") if dlg._name.text != "" else "", dlg._text.text.left(80))
		if _wait > 12 and not (mode == "walk" and dlg._name.text == "Corin"):
			_wait = 0
			dlg._advance.emit()
	else:
		_wait = 0


# ============================================================== helpers ===

func _aim_two(a: String, b: String) -> void:
	var pa := Cine.body(world, a)
	var pb := Cine.body(world, b)
	if pa == null or pb == null:
		return
	var mid := (pa.global_position + pb.global_position) * 0.5
	var d := pb.global_position - pa.global_position
	d.y = 0.0
	var side := d.normalized().cross(Vector3.UP) if d.length() > 0.01 else Vector3.RIGHT
	if side.dot(world.cam.global_position - mid) < 0.0:
		side = -side
	close_cam.global_position = mid + side * (3.0 + d.length() * 0.6) + Vector3(0, 1.6, 0)
	close_cam.look_at(mid + Vector3(0, 0.9, 0))
	close_cam.fov = 45.0


func _shot(label: String) -> void:
	_n += 1
	if DisplayServer.get_name() == "headless":
		return   # (the measuring alone: walk runs headless in a minute)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out.path_join("%03d_%s.png" % [_n, label]))
	var ci := close_vp.get_texture().get_image()
	if ci != null:
		ci.save_png(out.path_join("%03d_%s_close.png" % [_n, label]))


func _until_stage(st: String, secs: float) -> void:
	var t := 0.0
	while String(Game.flag("p1_stage", "")) != st and t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
