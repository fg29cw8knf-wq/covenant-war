extends Node
## The porridge eaten at the bar (AshfordP1._eat), measured as it's drawn
## (8 November, Gary: "When eating the porridge the spoon doesn't go all the
## way to the mouth, it only gets to about chest level"): the game picked up
## at the taproom, Bram's lines tapped through, the bowl tapped; then every
## frame of the eating, where the spoon's bowl end is against the mouth (the
## Head bone as drawn, with the model's mouth offset: AshfordP1.mouth_of) and
## where the right palm is against the hand's target, read inside the
## skeleton's own pass so they're the pose on screen. The nearest the spoon
## comes on each mouthful is printed, with a still from the game's camera and
## one close in from the player's right at that moment.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/eat_probe.tscn -- <out_dir> [look=a|b|c|d] [near=0.05]
## Ends "EAT PROBE: ok" (every mouthful within `near` of the mouth) or the problems.

var out := "/tmp/eat"
var look := "a"
var near := 0.05
var world: World
var hud: WorldHUD
var close_vp: SubViewport
var close_cam: Camera3D
var rec: Recorder
var problems: Array = []
var _n := 0
var _wait := 0

const WALL_CAP_MS := 420000
## (11 November, Gary: "players arm twists in an unnatural way") the most a
## forearm rolls between the bowl and the lips, and the furthest it turns
## either way from the palm facing in (degrees).
const ROLL_SWEEP_MOST := 80.0
const ROLL_MOST := 110.0
## What's natural (9 November): a wrist bends about 70 degrees back or down at
## most, and less sideways; an elbow bent under 15 degrees is all but locked;
## a hand reaching briskly and easing in and out accelerates at up to 6 to 8
## m/s/s, so at 10 frames a second its speed changes by under a metre a second
## from one frame to the next (the 8 November eating's lurches were 2.3).
const WRIST_MOST := 70.0
const ELBOW_STRAIGHT := 15.0
const EAT_JUMP := 1.0


## Reads the pose at the end of the skeleton's modifier pass (after the
## reaches, the hand turn and the held spoon are placed), where the drawn
## pose is: the Head bone, the right palm, the spoon's bowl end.
class Recorder:
	extends SkeletonModifier3D
	var fig: Figure3D
	var spoon: Node3D
	var head := Vector3.INF
	var palm := Vector3.INF
	var tip := Vector3.INF
	var mouth := Vector3.INF
	var frames := 0
	## (9 November, Gary: "When eating porridge hand moves in an unnatural
	## way"): the right arm as drawn, for how bent the wrist and the elbow are
	var wrist_bend := 0.0    # degrees between the forearm and the hand's own line
	var elbow_bend := 0.0    # degrees the elbow is bent (0 straight)
	var grip := Vector3.INF  # the palm's middle (where the spoon's held)
	var rest_wrist := -1.0   # the same angle as modelled (the rest pose), taken off
	var roll := 0.0          # the forearm's roll, degrees (see below)

	func _process_modification_with_delta(_delta: float) -> void:
		if not is_instance_valid(fig):
			return
		var sk := get_skeleton()
		var hb := sk.find_bone("Head")
		if hb >= 0:
			head = sk.global_transform * sk.get_bone_global_pose(hb).origin
			mouth = AshfordP1.mouth_of(fig)
		var pf := fig.palm_frame("right")
		palm = pf.origin
		grip = pf.origin
		var ua := sk.find_bone("RightArm")
		var fa := sk.find_bone("RightForeArm")
		var hd := sk.find_bone("RightHand")
		if ua >= 0 and fa >= 0 and hd >= 0:
			var xf := sk.global_transform
			var s0 := xf * sk.get_bone_global_pose(ua).origin
			var e0 := xf * sk.get_bone_global_pose(fa).origin
			var w0 := xf * sk.get_bone_global_pose(hd).origin
			var fore := (w0 - e0).normalized()
			elbow_bend = rad_to_deg((e0 - s0).normalized().angle_to(fore))
			if rest_wrist < 0.0:
				var mid := sk.find_bone("RightHandMiddle1")
				if mid >= 0:
					var r_e := sk.get_bone_global_rest(fa).origin
					var r_w := sk.get_bone_global_rest(hd).origin
					rest_wrist = rad_to_deg((r_w - r_e).normalized().angle_to((sk.get_bone_global_rest(mid).origin - r_w).normalized()))
				else:
					rest_wrist = 0.0
			wrist_bend = maxf(0.0, rad_to_deg(fore.angle_to(pf.basis.z)) - rest_wrist)
			# (11 November) the forearm's roll: which way the palm faces round
			# the forearm, from facing in across the body (0: the thumb up, a
			# handshake), towards palm down (+90) or palm up (-90); 180 is palm
			# out, thumb down, which no forearm does
			var hinge := (e0 - s0).cross(fore)
			if hinge.length() > 0.05:
				var inn := -hinge.normalized()   # (the right arm's inward way)
				var pn: Vector3 = pf.basis.y - fore * pf.basis.y.dot(fore)
				if pn.length() > 0.05:
					roll = -rad_to_deg(inn.signed_angle_to(pn.normalized(), fore))
		if is_instance_valid(spoon) and spoon.is_inside_tree():
			tip = spoon.to_global(Vector3(0, 0, AshfordP1.SPOON_LEN * 0.5))
		frames += 1


func _ready() -> void:
	# (11 November: "oldwrist" turns hands at the wrist alone, however far, as
	# they were until then: Figure3D.wrist_natural, the before)
	if "oldwrist" in OS.get_cmdline_user_args():
		Figure3D.wrist_natural = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
	if "oldpalm" in a:
		AshfordP1.spoon_palm_easy = false   # (the 9 November palm: square to the spoon all the way)
	if a.size() > 0:
		out = a[0]
	for s in a.slice(1):
		if String(s).begins_with("look="):
			look = String(s).substr(5)
		elif String(s).begins_with("near="):
			near = float(String(s).substr(5))
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.set_flag("look", look)
	Game.settings["first_steps"] = 2
	Game.set_flag("p1_stage", "taproom")
	world = World.new().setup("ashford", "green")
	add_child(world)
	hud = world.hud
	close_vp = SubViewport.new()
	close_vp.size = Vector2i(540, 540)
	close_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(close_vp)
	close_cam = Camera3D.new()
	close_cam.fov = 28.0
	close_vp.add_child(close_cam)
	close_cam.current = true
	await _frames(20)
	_force_look()
	await _run()
	print("EAT PROBE: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


## (The game plays Player A whatever the look: DollArt.player_look. The other
## looks are put on here so their arms are measured too.)
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


func _process(_d: float) -> void:
	# (a hard cap on the wall clock: a gate that never opens must not hold
	# the machine's one Godot for good)
	if Time.get_ticks_msec() > WALL_CAP_MS:
		print("EAT PROBE: timed out on the wall clock (%d s)" % (WALL_CAP_MS / 1000))
		get_tree().quit(2)
		return
	if world == null or hud == null:
		return
	if hud.dialogue._waiting:
		_wait += 1
		if _wait > 6:
			_wait = 0
			hud.dialogue._advance.emit()
	if hud.dialogue._choices.visible:
		hud.dialogue._chosen.emit(0)


func _run() -> void:
	# Bram's lines through, the bowl glowing: the player's own walk (walk_room
	# keeps world.busy up through it: the objective is the gate)
	await _until(func() -> bool: return String(Game.flag("objective_key", "")) == "crate_or_eat", 90.0, "the bowl's turn")
	if not problems.is_empty():
		return
	var e: Dictionary = world.get_meta("village").get_meta("eve")
	var bowl: Node3D = e.porridge
	var spoon: Node3D = bowl.get_node_or_null("Spoon")
	var me := world.player_doll as Figure3D
	print("  player %s: head bone standing %.3f, shoulder %.3f, arm %.3f" % [me._model_name, me._top, me._shoulder, me._arm])
	var mo := AshfordP1.mouth_of(me)
	print("  mouth as drawn (own frame) %s; head bone %s" % [me.to_own(mo).snapped(Vector3(0.001, 0.001, 0.001)), me.to_own(me.bone_pos("Head")).snapped(Vector3(0.001, 0.001, 0.001))])
	rec = Recorder.new()
	rec.name = "EatProbe"
	rec.fig = me
	rec.spoon = spoon
	me._skel.add_child(rec)
	await _secs(0.5)
	# a tap on the bowl (within reach from where they stand)
	hud.tapped.emit(world.cam.unproject_position(bowl.global_position))
	await _until(func() -> bool: return world.busy and String(Game.flag("objective_key", "")) == "", 10.0, "the eating to start")
	if not problems.is_empty():
		return
	# every frame until the flag's set: the spoon's end against the mouth,
	# the palm against its target
	var t := 0.0
	var f := 0
	var best := INF
	var best_t := 0.0
	var worst_palm := 0.0
	var mouthfuls: Array = []
	var rising := false
	var mouthful_t := -1.0   # (the lips' in and out at one mouthful is one)
	var last_d := INF
	var shot_due := 0
	var hand: Node3D = null
	var head_pitch_seen := 0.0
	# the arm (9 November): the wrist's bend and the elbow's, and how the hand
	# moves frame to frame (a sudden change of speed is a jerk on screen)
	var wrist_most := 0.0
	var elbow_most := 0.0
	var elbow_least := 999.0
	var last_grip := Vector3.INF
	var last_v := Vector3.ZERO
	var jerk_most := 0.0
	var jerk_at := 0.0
	var speed_most := 0.0
	var jumps := 0
	var jump_at: Array = []
	var path_len := 0.0
	var roll_lo := INF
	var roll_hi := -INF
	var roll_last := INF
	var roll_step := 0.0
	while not Game.flag("p1_ate") and t < 20.0:
		await get_tree().process_frame
		me._skel.move_child(rec, -1)   # (after the hands, whatever moved them)
		f += 1
		t += get_process_delta_time()
		if hand == null:
			hand = me._pivot.get_node_or_null("SpoonHand")
		if rec.tip == Vector3.INF or rec.mouth == Vector3.INF:
			continue
		var d := rec.tip.distance_to(rec.mouth)
		var to_own := me.to_own(rec.tip) - me.to_own(rec.mouth)
		var ik0 = me._ik.get("right")
		var held := ik0 != null and is_instance_valid(ik0) and (ik0 as TwoBoneIK3D).active and float((ik0 as TwoBoneIK3D).influence) > 0.9
		# (only while the hand's on the spoon: not as it comes or goes)
		if hand != null and rec.grip != Vector3.INF and held:
			wrist_most = maxf(wrist_most, rec.wrist_bend)
			roll_lo = minf(roll_lo, rec.roll)
			roll_hi = maxf(roll_hi, rec.roll)
			if roll_last != INF:
				roll_step = maxf(roll_step, absf(wrapf(rec.roll - roll_last, -180.0, 180.0)))
			roll_last = rec.roll
			elbow_most = maxf(elbow_most, rec.elbow_bend)
			elbow_least = minf(elbow_least, rec.elbow_bend)
			var dt := maxf(get_process_delta_time(), 0.001)
			if last_grip != Vector3.INF:
				var v := (me.to_own(rec.grip) - last_grip) / dt
				path_len += v.length() * dt
				speed_most = maxf(speed_most, v.length())
				# a change of velocity in one frame bigger than a hand's easing allows
				var dv := (v - last_v).length()
				if dv > jerk_most:
					jerk_most = dv
					jerk_at = t
				if dv > EAT_JUMP:
					jumps += 1
					jump_at.append("%.1f s %.2f" % [t, dv])
				last_v = v
			last_grip = me.to_own(rec.grip)
		elif not held:
			last_grip = Vector3.INF
			last_v = Vector3.ZERO
		var palm_err := 0.0
		if hand != null and is_instance_valid(hand):
			palm_err = rec.palm.distance_to(hand.global_position)
			worst_palm = maxf(worst_palm, palm_err)
		var ik = me._ik.get("right")
		var infl := float((ik as TwoBoneIK3D).influence) if ik != null and is_instance_valid(ik) else 0.0
		if f % 2 == 0 or d < 0.08:
			print("  t %5.2f tip-mouth %5.1f cm (own: %+.3f left %+.3f up %+.3f ahead)  palm-target %4.1f cm  wrist %3.0f elbow %3.0f deg  ik %.2f  target(own) %s" % [
				t, d * 100.0, to_own.x, to_own.y, to_own.z, palm_err * 100.0, rec.wrist_bend, rec.elbow_bend, infl,
				(hand.position.snapped(Vector3(0.001, 0.001, 0.001)) if hand != null and is_instance_valid(hand) else Vector3.INF)])
		# the nearest point of each mouthful (the distance turning back up)
		if d < last_d - 0.0005:
			rising = true
		elif rising and d > last_d + 0.0005 and last_d < 0.2 and not (mouthful_t >= 0.0 and t - mouthful_t < 0.8):
			rising = false
			mouthful_t = t
			mouthfuls.append(last_d)
			print("  mouthful %d: nearest %.1f cm at %.2f s" % [mouthfuls.size(), last_d * 100.0, t])
			await _shot("mouthful_%d" % mouthfuls.size(), rec.mouth, rec.tip)
		last_d = d
		if d < best:
			best = d
			best_t = t
		if shot_due <= 0:
			await _shot("f%04d" % f, rec.mouth, rec.tip)
			shot_due = 4
		shot_due -= 1
	await _shot("done", rec.mouth, rec.tip)
	print("  nearest the spoon's end came to the mouth: %.1f cm at %.2f s; the palm at most %.1f cm off the arm's IK target" % [best * 100.0, best_t, worst_palm * 100.0])
	print("  the arm: wrist bent at most %.0f degrees; elbow bent %.0f to %.0f degrees; the hand at most %.2f m/s, %.2f m of path; its speed changing by at most %.2f m/s in a frame (at %.2f s), %d frames over %.2f" % [
		wrist_most, elbow_least, elbow_most, speed_most, path_len, jerk_most, jerk_at, jumps, EAT_JUMP])
	print("  the forearm's roll (0 the palm in, +90 palm down, -90 palm up, 180 palm out): from %.0f to %.0f degrees through the eating, %.0f degrees at most in a frame" % [roll_lo, roll_hi, roll_step])
	if roll_hi - roll_lo > ROLL_SWEEP_MOST:
		problems.append("the forearm rolled %.0f degrees between the bowl and the lips (a spoon comes up on about %.0f)" % [roll_hi - roll_lo, ROLL_SWEEP_MOST])
	if roll_hi > ROLL_MOST or roll_lo < -ROLL_MOST:
		problems.append("the palm was turned out past what a forearm does (%.0f to %.0f degrees)" % [roll_lo, roll_hi])
	if not jump_at.is_empty():
		print("  the jerks (when, the change of speed in m/s): ", ", ".join(jump_at))
	if mouthfuls.is_empty():
		problems.append("no mouthful seen (the spoon never came up and went down)")
	if wrist_most > WRIST_MOST:
		problems.append("the wrist bent %.0f degrees (a wrist goes to about %.0f)" % [wrist_most, WRIST_MOST])
	if elbow_least < ELBOW_STRAIGHT:
		problems.append("the elbow straightened to %.0f degrees (locked)" % elbow_least)
	if jumps > 0:
		problems.append("the hand jerked in %d frames (its speed changed by up to %.2f m/s in one frame)" % [jumps, jerk_most])
	for i in mouthfuls.size():
		if float(mouthfuls[i]) > near:
			problems.append("mouthful %d stopped %.1f cm from the mouth" % [i + 1, float(mouthfuls[i]) * 100.0])
	# (the palm sits off the arm's IK target by the hand's own length once
	# the hand is turned into a fist, and AshfordP1._eat's feedback moves the
	# target by that: printed, not a problem)


## The game's own frame, and a close one from the player's right (the hand's
## side), on the face and the spoon.
func _shot(label: String, mouth: Vector3, tip: Vector3) -> void:
	_n += 1
	if DisplayServer.get_name() == "headless":
		return
	var me := world.player_doll as Figure3D
	var right := (me.global_position - me.to_world(Vector3(1, 0, 0))).normalized()   # (own x is their left)
	var ahead := me.facing()
	var at := (mouth + tip) * 0.5
	close_cam.global_position = at + right * 0.75 + ahead * 0.45 + Vector3(0, 0.12, 0)
	close_cam.look_at(at, Vector3.UP)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out.path_join("%03d_%s.png" % [_n, label]))
	var ci := close_vp.get_texture().get_image()
	if ci != null:
		ci.save_png(out.path_join("%03d_%s_close.png" % [_n, label]))


func _until(cond: Callable, secs: float, what: String) -> void:
	var t := 0.0
	while not cond.call() and t < secs:
		await get_tree().process_frame
		t += get_process_delta_time()
	if not cond.call():
		problems.append("timed out waiting for %s (%.0f s)" % [what, secs])


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
