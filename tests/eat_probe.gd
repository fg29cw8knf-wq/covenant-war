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

	func _process_modification_with_delta(_delta: float) -> void:
		if not is_instance_valid(fig):
			return
		var sk := get_skeleton()
		var hb := sk.find_bone("Head")
		if hb >= 0:
			head = sk.global_transform * sk.get_bone_global_pose(hb).origin
			mouth = AshfordP1.mouth_of(fig)
		palm = fig.palm_frame("right").origin
		if is_instance_valid(spoon) and spoon.is_inside_tree():
			tip = spoon.to_global(Vector3(0, 0, AshfordP1.SPOON_LEN * 0.5))
		frames += 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var a := OS.get_cmdline_user_args()
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
	var last_d := INF
	var shot_due := 0
	var hand: Node3D = null
	var head_pitch_seen := 0.0
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
		var palm_err := 0.0
		if hand != null and is_instance_valid(hand):
			palm_err = rec.palm.distance_to(hand.global_position)
			worst_palm = maxf(worst_palm, palm_err)
		var ik = me._ik.get("right")
		var infl := float((ik as TwoBoneIK3D).influence) if ik != null and is_instance_valid(ik) else 0.0
		if f % 2 == 0 or d < 0.08:
			print("  t %5.2f tip-mouth %5.1f cm (own: %+.3f left %+.3f up %+.3f ahead)  palm-target %4.1f cm  ik %.2f  target(own) %s" % [
				t, d * 100.0, to_own.x, to_own.y, to_own.z, palm_err * 100.0, infl,
				(hand.position.snapped(Vector3(0.001, 0.001, 0.001)) if hand != null and is_instance_valid(hand) else Vector3.INF)])
		# the nearest point of each mouthful (the distance turning back up)
		if d < last_d - 0.0005:
			rising = true
		elif rising and d > last_d + 0.0005 and last_d < 0.2:
			rising = false
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
	if mouthfuls.is_empty():
		problems.append("no mouthful seen (the spoon never came up and went down)")
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
