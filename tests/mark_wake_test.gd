extends Node
## The memory's end handed on to the attic (15 November, Gary's yes to "the
## mark links the two times" and "the title after the memory"). A new game
## with the Night of the White Sky skipped to its end, as a player who has
## seen it can: the child's mark comes up on the black (SealMark.Held),
## Morrowen's last line under it, the game's title under it, the attic's
## caption under it; then the attic's first picture, the hero's own mark
## where the child's was (AshfordP1._wake_on_the_mark), the camera a little
## way back from it as it goes out, and through the dark to the bed's own
## shot, where he wakes.
##
## Checks: the held mark came up and was let go; the title was shown; the
## attic opened on the mark, with the hero's own within a fiftieth of the
## screen of where the held one was and the same size to a fifth; the child's
## he gets up and the walk is handed to the player (the washbasin's lesson).
## Stills of each moment in <dir> when it's drawn:
##
##   godot --headless --fixed-fps 10 --path . res://tests/mark_wake_test.tscn
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/mark_wake_test.tscn -- <dir>

var out := ""
var world: World
var _t := 0.0
var _n := 0
var _m: WhiteSky
var _skipped := false
var _line_t := 0.0
var _title_t := 0.0
var _held_at := Vector2.ZERO
var _held_size := 0.0
var _held_seen := false
var _held_gone := false
var _title := false
var _wake_t := -1.0
var _off := -1.0
var _size_k := -1.0
var _done := false
var _taken := {}
var _lesson := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
		DirAccess.make_dir_recursive_absolute(out)
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	Game.settings["seen_white_sky"] = true   # (so it can be skipped)
	# ("look=<b|c|d>": as another of the four looks, Gary's standing rule)
	if args.has("notent"):
		AshfordP1.lift_blanket = false
	for a in args:
		if String(a).begins_with("look="):
			DollArt.test_look = String(a).substr(5)
	AshfordP1.test_memory = true
	AshfordP1.mark_wakes = 0
	world = World.new().setup("ashford", "green")
	add_child(world)


func _still(nm: String) -> void:
	if out == "" or DisplayServer.get_name() == "headless" or _taken.has(nm):
		return
	_taken[nm] = true
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	print("mark_wake_test: still ", nm)
	# ("views": the hand at his neck seen from over the bed and from the
	# wall's side too, where the arm comes up out of the blanket)
	if OS.get_cmdline_user_args().has("views") and (nm == "7c_hand_on_his_neck" or nm == "7b2_hand_nearly_there"):
		var pf = world.player_doll
		if pf is Figure3D:
			var fig := pf as Figure3D
			var chest: Vector3 = fig.bone_pos("Spine2")
			var to_head := (fig.bone_pos("Head") - fig.bone_pos("Hips")).normalized()
			var left := to_head.cross(Vector3.UP).normalized()
			var c := Camera3D.new()
			world.add_child(c)
			c.fov = 45.0
			var k := _n
			# (close on his neck: from his right, the room's side, and from
			# over his chest)
			var neck: Vector3 = fig.bone_pos("Neck")
			for v in [[-left * 0.42 + Vector3.UP * 0.12 - to_head * 0.08, "close_right"], [-to_head * 0.45 + Vector3.UP * 0.32 - left * 0.12, "close_chest"]]:
				c.global_position = neck + (v[0] as Vector3)
				c.look_at(neck - to_head * 0.03, Vector3.UP)
				c.make_current()
				await RenderingServer.frame_post_draw
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s_%s.png" % [k, nm, v[1]]))
			c.queue_free()
			if world.cam != null:
				world.cam.make_current()


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	if _m == null:
		for c in world.get_children():
			if c is WhiteSky:
				_m = c
	# (and the walk is handed to the player after it: the washbasin's lesson)
	if _wake_t >= 0.0 and String(Game.flag("objective_key", "")) == "basin":
		_lesson = true
	# the memory, skipped a moment in
	if _m != null and is_instance_valid(_m) and not _skipped and _m._roam:
		_skipped = true
		_m.skip()
	# its last line, and the attic's lines: read a moment, then tapped on
	var ov := Cine.overlay(world)
	if ov._waiting:
		_line_t += delta
		if _line_t > 0.7 and _held_seen and not _title:
			_still("1_the_line")
		if _line_t > 1.4:
			_line_t = 0.0
			ov._next.emit()
	else:
		_line_t = 0.0
	if _m != null and is_instance_valid(_m) and _m.title_shown:
		_title = true
		_title_t += delta
		# (18 November: the title takes WhiteSky.TITLE_IN to come in, a part at a time)
		# (and, later that day, the mark's light falling to draw its rule)
		for st: Array in [[0.6, "2a_light_leaving"], [0.9, "2b_light_falling"], [1.15, "2c_landed"], [1.6, "2d_rule_drawn_out"], [2.5, "2e_name_coming"]]:
			if _title_t > float(st[0]) and _title_t < float(st[0]) + 0.25:
				_still(String(st[1]))
		if _title_t > WhiteSky.TITLE_IN + 0.9:
			_still("2_the_title")
		if _title_t > WhiteSky.TITLE_IN + 1.5:
			_m._tapped = true
	var held := SealMark.held(get_tree())
	if held != null:
		_held_seen = true
		_held_at = held.at
		_held_size = held.size
		if _title and (_m == null or not is_instance_valid(_m) or _m._done) and ov._cap != null and ov._cap.visible and ov._cap.modulate.a > 0.9:
			_still("3_the_caption")
	elif _held_seen:
		_held_gone = true
	if AshfordP1.mark_wakes > 0 and _wake_t < 0.0:
		_wake_t = _t
		# where his own mark is on the picture, against where the held one was
		var mi := SealMark.on_hero(world)
		var view := world.get_viewport().get_visible_rect().size
		if mi != null and world.cam != null and view.y > 0.0:
			var px := world.cam.unproject_position(mi.global_position)
			_off = (Vector2(px.x / view.x, px.y / view.y) - _held_at).length()
			var d := world.cam.global_position.distance_to(mi.global_position)
			var tall := 2.0 * d * tan(deg_to_rad(world.cam.fov) * 0.5)
			_size_k = (SealMark.SIZE / tall) / maxf(_held_size, 0.001)
	if _wake_t >= 0.0:
		var since := _t - _wake_t
		# (15 November, evening, Gary: "have camera draw back to show all of
		# him": drawn back from the mark to the whole of him, head to foot,
		# held, then round to the bed's shot as he stirs)
		var whole_at := AshfordP1.MARK_WAKE_HOLD + AshfordP1.MARK_WAKE_BACK
		# (and "31 yes": the first thing he does, his hand to his neck where
		# the mark was, before the camera goes round to the bed)
		var hand_at := whole_at + AshfordP1.MARK_WAKE_WHOLE_HOLD
		var round_at := hand_at + AshfordP1.NECK_HAND_UP + AshfordP1.NECK_HAND_HOLD + AshfordP1.NECK_HAND_DOWN
		for pair in [["4_attic_coming_up", 0.5], ["5_his_own_mark", 1.7], ["6_drawing_back", AshfordP1.MARK_WAKE_HOLD + AshfordP1.MARK_WAKE_BACK * 0.5],
				["7_the_whole_of_him", whole_at + 0.4], ["7a_hand_starting", hand_at + AshfordP1.NECK_HAND_UP * 0.25],
				["7b_hand_going_up", hand_at + AshfordP1.NECK_HAND_UP * 0.5], ["7b2_hand_nearly_there", hand_at + AshfordP1.NECK_HAND_UP * 0.8],
				["7c_hand_on_his_neck", hand_at + AshfordP1.NECK_HAND_UP + AshfordP1.NECK_HAND_HOLD * 0.5],
				["7d_hand_going_down", hand_at + AshfordP1.NECK_HAND_UP + AshfordP1.NECK_HAND_HOLD + AshfordP1.NECK_HAND_DOWN * 0.5],
				["7e_hand_down", hand_at + AshfordP1.NECK_HAND_UP + AshfordP1.NECK_HAND_HOLD + AshfordP1.NECK_HAND_DOWN + 0.3],
				["8_round_to_the_bed", round_at + 1.2], ["9_waking", round_at + 4.5]]:
			if since > float(pair[1]):
				_still(String(pair[0]))
		# (19 November, Gary: getting out of bed "more natural": each part of
		# it at its own pace, AshfordP1.rise_pace) the rise by the clip's own
		# clock: sitting up, the legs round, on the edge, rising, stood
		var rf = world.player_doll
		if rf is Figure3D and (rf as Figure3D).anim != null and String((rf as Figure3D).anim.current_animation).begins_with("rooted_get_out_of_bed"):
			var cp: float = (rf as Figure3D).anim.current_animation_position
			if _rise_from < 0.0:
				_rise_from = _t
			_rise_to = _t
			for pair in [["9a_sitting_up", 1.6], ["9b_legs_round", 2.4], ["9c_on_the_edge", 3.0], ["9d_rising", 3.7], ["9e_nearly_up", 4.2], ["9f_stood", 4.8]]:
				if cp > float(pair[1]):
					_still(String(pair[0]))
		if since > whole_at + 0.3 and _whole_in < 0.0:
			_whole_in = _in_picture()
		# ("arm": where his left arm is, as drawn, against the mattress and
		# the blanket, through his hand to his neck)
		if OS.get_cmdline_user_args().has("arm") and since > hand_at - 0.3 and since < round_at + 0.5:
			_arm_dump(since - hand_at)
		# (16 November) the blanket lifted over his arm as it goes up under it
		var bl = InnRooms.attic(AshfordP1.village(world)).get("blanket", null)
		var tent := BlanketTent.on(bl) if bl is Node else null
		if tent != null:
			_tent_seen = true
			_tent_most = maxf(_tent_most, tent.lifted)

		if _lesson or since > 40.0:
			_finish()


var _arm_last := -9.0
var _rise_from := -1.0
var _rise_to := -1.0

func _arm_dump(t: float) -> void:
	if t - _arm_last < 0.15:
		return
	_arm_last = t
	var pf = world.player_doll
	if not (pf is Figure3D):
		return
	var fig := pf as Figure3D
	var sk := fig._skel
	var a := InnRooms.attic(AshfordP1.village(world))
	var top: float = (a.lie_at as Vector3).y + float(a.bed_top)
	var bl := a.get("blanket", null) as MeshInstance3D
	var cb := func() -> void:
		var line := "mark_wake_test: arm at %+.2f s:" % t
		for bn in ["LeftArm", "LeftForeArm", "LeftHand", "LeftHandIndex3", "LeftHandMiddle3"]:
			var i := sk.find_bone(bn)
			if i < 0:
				continue
			var p := sk.global_transform * sk.get_bone_global_pose(i).origin
			var over := "-"
			if bl != null:
				# the blanket's height over that point (its mesh as it is now)
				var lp := bl.to_local(p)
				var best := INF
				var hy := 0.0
				for v in bl.mesh.get_faces():
					var d := Vector2(v.x - lp.x, v.z - lp.z).length()
					if d < best:
						best = d
						hy = v.y
				over = ("%+.0f" % ((lp.y - hy) * 100.0)) if best < 0.06 else "off"
			line += "  %s %+.0f cm over the mattress, %s cm over the blanket;" % [bn.replace("Left", ""), (p.y - top) * 100.0, over]
		print(line)
	sk.skeleton_updated.connect(cb, CONNECT_ONE_SHOT)


## How much of him is in the picture now, head to foot: his head, hips, both
## hands and both feet each inside the screen (with a margin), as a share.
var _whole_in := -1.0
var _tent_seen := false
var _tent_most := 0.0
var _whole_misses: Array = []

func _in_picture() -> float:
	var pf = world.player_doll
	if not (pf is Figure3D) or world.cam == null:
		return 0.0
	var view := world.get_viewport().get_visible_rect().size
	var n := 0
	var bones := ["Head", "Hips", "LeftHand", "RightHand", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
	for b in bones:
		var p := (pf as Figure3D).bone_pos(b)
		if world.cam.is_position_behind(p):
			_whole_misses.append(b)
			continue
		var px := world.cam.unproject_position(p)
		if px.x > view.x * 0.03 and px.x < view.x * 0.97 and px.y > view.y * 0.05 and px.y < view.y * 0.95:
			n += 1
		else:
			_whole_misses.append(b)
	return float(n) / float(bones.size())


func _finish() -> void:
	_done = true
	var fails: Array = []
	print("mark_wake_test: the whole of him in the picture when it had drawn back: %.2f (out of it: %s)" % [_whole_in, str(_whole_misses)])
	# (where the hand got to is seen in the stills, 7b and 7c: the bones read
	# here are the clip's, before the arm's reach is put on them)
	print("mark_wake_test: his hand to his neck where the mark was: %d time(s)" % AshfordP1.hand_to_neck)
	# (19 November) how long the get-up clip took, its parts at their own pace
	if _rise_from >= 0.0:
		print("mark_wake_test: up out of bed (the clip) over %.1f s" % (_rise_to - _rise_from))
	if AshfordP1.hand_to_neck != AshfordP1.mark_wakes:
		fails.append("his hand didn't go to his neck as he woke on the mark")
	# (16 November, Gary: "When player puts hand to neck in bed his hand goes
	# through the bed") the blanket lifted over his arm while it's under it
	print("mark_wake_test: the blanket lifted over his arm %s, at most %.1f cm" % [str(_tent_seen), _tent_most * 100.0])
	if world.player_doll is Figure3D:
		# (18 November: his arm's thickness, sleeve and all, off his own model)
		var rr: Array = BlanketTent.radii_of(world.player_doll as Figure3D, "left")
		print("mark_wake_test: his arm as the blanket takes it: upper arm %.1f cm, forearm %.1f cm, hand %.1f cm from the bone (it was 5.0, 4.2, 3.6)" % [float(rr[0]) * 100.0, float(rr[1]) * 100.0, float(rr[2]) * 100.0])
	if not _tent_seen and AshfordP1.lift_blanket:
		fails.append("the blanket wasn't lifted over his arm as his hand went to his neck")
	if _whole_in < 0.99:
		fails.append("the camera didn't draw back to all of him (%.2f in the picture; out: %s)" % [_whole_in, str(_whole_misses)])
	if not _held_seen:
		fails.append("the mark never came up on the black")
	if not _held_gone:
		fails.append("the held mark was never let go")
	if not _title:
		fails.append("the title wasn't shown")
	if AshfordP1.mark_wakes != 1:
		fails.append("the attic opened on the mark %d times" % AshfordP1.mark_wakes)
	if _off < 0.0 or _off > 0.02:
		fails.append("his own mark was %.3f of the screen from the held one" % _off)
	if _size_k < 0.8 or _size_k > 1.2:
		fails.append("his own mark was %.2f of the held one's size" % _size_k)
	var a := InnRooms.attic(AshfordP1.village(world))
	var wide: Vector3 = (a.root as Node3D).to_global(Vector3(2.45, 1.6, 1.3))
	var cam_off := world.cam.global_position.distance_to(wide)
	if not _lesson:
		fails.append("he never got up to be walked to the washbasin")
	print("mark_wake_test: the held mark at (%.2f, %.2f), %.2f of the screen tall; his own %.3f of the screen from it, %.2f of its size; the walk his at the washbasin's lesson %s, %.1f s after the attic came up (the camera %.1f m from the bed's shot by then)" % [
		_held_at.x, _held_at.y, _held_size, _off, _size_k, str(_lesson), _t - _wake_t, cam_off])
	if fails.is_empty():
		print("mark_wake_test: PASS")
	else:
		for f in fails:
			print("mark_wake_test: FAIL: ", f)
	get_tree().quit(0 if fails.is_empty() else 1)
