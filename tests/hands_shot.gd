extends Node
## Hands on things, close up (Gary, 28 October: Bram's "arm twists in a weird
## way and still passes through his body, and his hand passed through the
## bar"; his "card box is just floating, it's not in his hands, and the
## player's hand is deformed when he reached to take it"). Stages the moment
## for real and takes stills every few tenths of a second, from the scene's
## own camera and from a close camera beside the hands:
##
##   wipe: Bram behind the taproom's counter wiping it (AshfordP1._wipe),
##         the player across it, as the taproom has them;
##   box:  on the green, Corin and the player; Bram walks over with the box,
##         his hand on the player's shoulder, the box out (_box_out_scene)
##         and the player taking it (_first_deck).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
##       res://tests/hands_shot.tscn -- <out_dir> wipe|box [look]
## (look: a, b, c or d, the player's look; a by default)
## Also checks the hands: each one reaching is within a few cm of what it
## reaches for (a hand short of its target is a box floating in the air).
## Ends with "HANDS SHOT: ok" or the problems.

const Ashford := preload("res://scripts/world/areas/ashford.gd")

var out := "/tmp/hands"
var mode := "box"
var world: World
var close_cam: Camera3D
var close_vp: SubViewport
var problems: Array = []
var _n := 0


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		mode = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	if a.size() > 2:
		Game.set_flag("look", a[2])
	Game.set_flag("arrived_ashford")
	if mode == "box":
		for f in ["ash_started", "p1_crate_down"]:
			Game.set_flag(f)
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	if world.hud != null:
		world.hud.visible = false
	# a second camera on the same world, close by the hands
	close_vp = SubViewport.new()
	close_vp.size = Vector2i(640, 640)
	close_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(close_vp)
	close_cam = Camera3D.new()
	close_cam.fov = 30.0
	close_vp.add_child(close_cam)
	close_cam.current = true
	if mode == "wipe":
		await _wipe()
	else:
		await _box()
	print("HANDS SHOT: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _wipe() -> void:
	var v: AshfordVillage = AshfordP1.village(world)
	var e: Dictionary = InnRooms.eve(v)
	AshfordP1.go_inside(v)
	world.busy = true
	world.cine = true
	var root: Node3D = e.root
	var bram_at: Vector3 = e.bar_behind
	var me_at := root.to_global(Vector3(InnRooms.BAR_X + 0.85, 0, 0.35))
	Cine.place(world, "bram", bram_at, me_at)
	Cine.place(world, "player", me_at, bram_at)
	await _frames(10)
	Cine.shot(world, root.to_global(Vector3(-1.55, 1.6, 1.7)), (bram_at + me_at) * 0.5 + Vector3(0, 1.3, 0), 36.0)
	var state := [true]
	AshfordP1._wipe(world, root, state)
	var bf := Cine.fig(world, "bram") as Figure3D
	for i in 12:
		await _secs(0.35)
		# from in front of him and to his right, over the counter
		close_cam.global_position = bf.to_world(Vector3(-0.75, 1.55, 1.25))
		close_cam.look_at(bf.to_world(Vector3(-0.12, 1.2, 0.25)))
		await _shot("wipe_%02d" % i)
		_check_hands("bram", "wipe")
	state[0] = false
	await _secs(0.6)


func _box() -> void:
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
	# Bram up off his stool with the box, over to them (as Corin's hub starts)
	await Ashford._bram_sets_off(world)
	await _shot("arrived")
	var going := [true]
	var watch := func() -> void:
		var i := 0
		while going[0]:
			await _secs(0.25)
			if not going[0]:
				break
			_aim_close()
			var gap := Cine.body(world, "player").global_position.distance_to(Cine.body(world, "bram").global_position)
			print("  box %02d: %.2f m between them%s" % [i, gap, "" if not world.has_meta("bram_stop") else ", his mark %.2f m from the player" % (world.get_meta("bram_stop") as Vector3).distance_to(Cine.body(world, "player").global_position)])
			await _shot("box_%02d" % i)
			_check_hands("bram", "box %02d" % i)
			_check_hands("player", "box %02d" % i)
			i += 1
	watch.call()
	await Ashford._bram_comes(world)
	await _secs(0.8)
	await Ashford._box_out_scene(world)
	await _secs(1.0)
	# _first_deck up to the deck reveal: the reveal itself is a screen of its own
	var fd := func() -> void: await Ashford._first_deck(world)
	fd.call()
	var t := 0.0
	while t < 3.2:
		await get_tree().process_frame
		t += get_process_delta_time()
		for l in world.get_children():
			if l is CanvasLayer:
				for c in l.get_children():
					if c is DeckReveal and not c.has_meta("seen"):
						c.set_meta("seen", true)
						t = 99.0
	going[0] = false
	await _secs(0.3)


## The close camera beside the two of them, square on to the line between them, at hand height.
func _aim_close() -> void:
	var p := Cine.body(world, "player").global_position
	var b := Cine.body(world, "bram").global_position
	var mid := (p + b) * 0.5 + Vector3(0, 1.1, 0)
	var d := b - p
	d.y = 0.0
	var side := d.normalized().cross(Vector3.UP)
	# the side the scene's camera is on, so the two agree
	if side.dot(world.cam.global_position - mid) < 0.0:
		side = -side
	close_cam.global_position = mid + side * 3.0 + Vector3(0, 0.3, 0)
	close_cam.look_at(mid + Vector3(0, -0.05, 0))
	close_cam.fov = 34.0


## Each hand that's reaching: is it at what it reaches for?
func _check_hands(who: String, when: String) -> void:
	var f = Cine.fig(world, who)
	if not (f is Figure3D):
		return
	var fig := f as Figure3D
	var sk: Skeleton3D = fig._skel
	# (the hands as the modifiers leave them: the skeleton puts its poses back
	# once it's drawn, so they're read as it's updated)
	if not sk.has_meta("hands_seen"):
		sk.set_meta("hands_seen", {})
		sk.skeleton_updated.connect(func() -> void:
			var seen: Dictionary = sk.get_meta("hands_seen")
			for nm in ["LeftHand", "RightHand", "LeftArm", "RightArm", "LeftForeArm", "RightForeArm"]:
				var b := sk.find_bone(nm)
				if b >= 0:
					seen[nm] = (sk.global_transform * sk.get_bone_global_pose(b)).origin
			# (and where each hand's target was, the same moment: someone
			# walking has moved on a step by the time this is read)
			for sd in ["left", "right"]:
				var k = fig._ik.get(sd)
				if k != null and is_instance_valid(k) and k.has_meta("target") and is_instance_valid(k.get_meta("target")):
					seen["target_" + sd] = (k.get_meta("target") as Node3D).global_position)
		return
	var seen: Dictionary = sk.get_meta("hands_seen")
	for side in ["left", "right"]:
		var ik = fig._ik.get(side)
		if ik == null or not is_instance_valid(ik) or not (ik as TwoBoneIK3D).active or (ik as TwoBoneIK3D).influence < 0.99:
			continue
		var t = ik.get_meta("target") if ik.has_meta("target") else null
		if not (t is Node3D) or not is_instance_valid(t):
			continue
		var hb := sk.find_bone(("Left" if side == "left" else "Right") + "Hand")
		if not seen.has(sk.get_bone_name(hb)):
			continue
		var hand: Vector3 = seen[sk.get_bone_name(hb)]
		var tp: Vector3 = seen.get("target_" + side, (t as Node3D).global_position)
		var d := hand.distance_to(tp)
		# (the palm reaches the target: the wrist is a palm's length short of it)
		var palm := 0.075 * fig.stature() + 0.05
		if d > palm + 0.04:
			var msg := "%s's %s hand is %.0f cm from what it holds (%s)" % [who, side, d * 100.0, when]
			if OS.get_cmdline_user_args().has("debug"):
				var pre := "Left" if side == "left" else "Right"
				print("    %s at %s yaw %.2f model origin %s skel origin %s hold %s" % [who, fig.global_position, fig._yaw, fig.model.global_position, sk.global_position, fig.to_world(Ashford.BOX_HOLD)])
				print("    %s hand %s target %s shoulder %s elbow %s scale %s" % [who, hand, (t as Node3D).global_position, seen.get(pre + "Arm"), seen.get(pre + "ForeArm"), sk.global_transform.basis.get_scale()])
			if not problems.has(msg):
				problems.append(msg)
				print("  PROBLEM: ", msg)


func _shot(label: String) -> void:
	_n += 1
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out.path_join("%03d_%s.png" % [_n, label]))
	var ci := close_vp.get_texture().get_image()
	if ci != null:
		ci.save_png(out.path_join("%03d_%s_close.png" % [_n, label]))


func _secs(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
