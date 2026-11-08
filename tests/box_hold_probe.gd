extends SceneTree
## The player holding Bram's card box as Ashford._first_deck holds it, on a
## plain stage, measured and photographed (6 November, Gary: "Bram's card box
## now goes through player's arm while he's holding it"): `both` the two
## hands under it as it's taken, `centred` the left hand under its middle and
## the right still under its other half (just before the right goes round to
## the lid), `left` the box on the flat of the left hand alone (the right
## hand away, as the deck comes out and after). Every finger bone of both
## hands and each forearm are checked against the box, anything more than a
## few millimetres in counted (the thumbs' only printed: Player A's and C's
## thumb joints don't lie along the thumbs, so the stills are their check).
## Stills from the front, both sides, above and below.
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 800x600 --path . --script res://tests/box_hold_probe.gd -- <out_dir> [a|b|c|d] [noshots]
## Ends "BOX HOLD: ok" or "BOX HOLD: n problems".
var Ashford = null
var out := "/tmp/boxhold"
var look := "a"
var shots := true
var problems := 0

const FINGER_R := 0.008
const FOREARM_R := 0.03


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: look = a[1]
	shots = not ("noshots" in a)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _shot(name: String) -> void:
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")


func _wait(secs: float) -> void:
	await create_timer(secs).timeout


func _depth(q: Vector3, half: Vector3, r: float) -> float:
	var e := q.abs() - half
	var outside := Vector3(maxf(e.x, 0.0), maxf(e.y, 0.0), maxf(e.z, 0.0)).length()
	var inside := minf(maxf(e.x, maxf(e.y, e.z)), 0.0)
	return maxf(0.0, r - (outside + inside))


func _check(f: Figure3D, box: Node3D, mode: String) -> void:
	var sk: Skeleton3D = f._skel
	var bx := box.global_transform.affine_inverse()
	var half: Vector3 = Ashford.CARD_BOX_SIZE * 0.5
	var xf := sk.global_transform
	var worst := 0.0
	var thumb := 0.0
	var where := ""
	for pre in ["Left", "Right"]:
		for fn in ["Thumb", "Index", "Middle", "Ring", "Pinky"]:
			for j in [1, 2, 3, 4]:
				var b := sk.find_bone(pre + "Hand" + fn + str(j))
				if b < 0:
					continue
				var p := bx * (xf * sk.get_bone_global_pose(b).origin)
				var d := _depth(p, half, FINGER_R)
				# (and the bone's far end: the next joint along, or a third again
				# beyond the last, where the fingertip is)
				var tip := p
				var nb := sk.find_bone(pre + "Hand" + fn + str(j + 1))
				if nb < 0:
					var par := sk.get_bone_parent(b)
					tip = p + (p - bx * (xf * sk.get_bone_global_pose(par).origin)) * 0.8
					d = maxf(d, _depth(tip, half, FINGER_R))
				# (thumbs as rigged are only a guide: Player A's and C's thumb
				# joints don't lie along the thumbs, so they're looked at in the
				# stills and only printed here)
				if fn == "Thumb":
					thumb = maxf(thumb, d)
					continue
				if d > worst:
					worst = d
					where = "%sHand%s%d at %s" % [pre, fn, j, p.snapped(Vector3(0.002, 0.002, 0.002))]
		var e := xf * sk.get_bone_global_pose(sk.find_bone(pre + "ForeArm")).origin
		var wr := xf * sk.get_bone_global_pose(sk.find_bone(pre + "Hand")).origin
		for k in 8:
			var p := bx * e.lerp(wr, float(k) / 8.0)
			var d := _depth(p, half, FOREARM_R * f.stature())
			if d > worst:
				worst = d
				where = "%s forearm %d/8 at %s" % [pre, k, p.snapped(Vector3(0.002, 0.002, 0.002))]
	if "bones" in OS.get_cmdline_user_args():
		var pfr := f.palm_frame("left")
		print("    palm frame origin %s normal %s fingers %s" % [(bx * pfr.origin).snapped(Vector3(0.002, 0.002, 0.002)), (bx.basis * pfr.basis.y).snapped(Vector3(0.01, 0.01, 0.01)), (bx.basis * pfr.basis.z).snapped(Vector3(0.01, 0.01, 0.01))])
		for bn in ["LeftHandPinky1", "LeftHandRing1", "LeftHandMiddle1"]:
			var bi := sk.find_bone(bn)
			if bi >= 0:
				print("    %s %s" % [bn, (bx * (xf * sk.get_bone_global_pose(bi).origin)).snapped(Vector3(0.002, 0.002, 0.002))])
		for bn in ["LeftHand", "LeftHandThumb1", "LeftHandThumb3", "LeftHandIndex1", "LeftHandIndex3", "RightHand", "RightHandThumb3", "RightHandIndex3"]:
			var bi := sk.find_bone(bn)
			if bi >= 0:
				print("    %s %s" % [bn, (bx * (xf * sk.get_bone_global_pose(bi).origin)).snapped(Vector3(0.002, 0.002, 0.002))])
	print("  %s %s: deepest %.1f cm (%s); thumb bones %.1f cm" % [look, mode, worst * 100.0, where, thumb * 100.0])
	if worst > 0.004:
		problems += 1


func _run() -> void:
	Ashford = load("res://scripts/world/areas/ashford.gd")
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 60, 0)
	sun.light_energy = 1.5
	stage.add_child(sun)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 30.0
	cam.current = true
	var body := Node3D.new()
	stage.add_child(body)
	var model: String = "player" if look == "a" else ("player_" + look)
	var f := Figure3D.make(model, model) as Figure3D
	body.add_child(f)
	f.snap_face(Vector3.BACK)
	for k in 10:
		await process_frame
	var box: Node3D = Ashford._card_box()
	stage.add_child(box)
	var size: Vector3 = Ashford.CARD_BOX_SIZE
	var back: float = Ashford._box_back(f)
	print("  %s: the box %.1f cm back from the left palm's middle" % [look, back * 100.0])
	# as _first_deck: the grip in front of them, the left palm under the box
	var grip := Node3D.new()
	f.carry(grip, f.hold_point(0.5, 0.62) + Vector3(0.0, -size.y * 0.5 - 0.012, 0.0))
	var lmark := Node3D.new()
	grip.add_child(lmark)
	lmark.position = Ashford._box_left_at(f, back)
	f.palm("left", Vector3.UP, 0.0, 1.0, true, Vector3.BACK)
	f.palm("right", Vector3.UP, 0.0, 1.0, true, Vector3.BACK)
	f.elbow("left", Vector3(0.46, f._shoulder - 0.38, 0.14), 0.0)
	f.elbow("right", Ashford.BOX_RIGHT_ELBOW + Vector3(0, f._shoulder, 0), 0.0)
	f.reach(lmark, null, 0.0)
	await _wait(0.4)
	f.attach(box, "palm", "left", Ashford._box_lift(f), 0.0, 0.0, -back, -Ashford._box_aside(f))
	var rmark := Node3D.new()
	box.add_child(rmark)
	rmark.position = Ashford._box_right_at(f, back)
	f.reach(lmark, rmark, 0.0)
	for mode in ["both", "centred", "left"]:
		match mode:
			"centred":
				# (as _first_deck: the left hand slides across under it, the box
				# kept where it is)
				var a1: float = Ashford._box_aside(f, false)
				lmark.position += Vector3(a1 - Ashford._box_aside(f), 0.0, 0.0)
				f.attach(box, "palm", "left", Ashford._box_lift(f), 0.0, 0.0, -back, -a1)
			"left":
				var away := Node3D.new()
				stage.add_child(away)
				away.global_position = box.to_global(Vector3(-size.x * 0.5 - 0.12, -0.02, -0.05))
				f.reach(lmark, null, 0.3)
				f.palm("right", Vector3.ZERO, 0.0)
		await _wait(0.8)
		# (the bones as drawn: read while the skeleton's modifiers have them)
		var once := [false]
		var cb := func() -> void:
			if not once[0]:
				once[0] = true
				_check(f, box, mode)
		f._skel.skeleton_updated.connect(cb)
		while not once[0]:
			await process_frame
		f._skel.skeleton_updated.disconnect(cb)
		if not shots:
			continue
		var at: Vector3 = box.global_position
		var fwd := f.facing()
		var side := fwd.cross(Vector3.UP)
		var views := {"front": at + fwd * 0.8 + Vector3(0, 0.15, 0), "right": at + side * 0.8 + Vector3(0, 0.05, 0),
			"left": at - side * 0.8 + Vector3(0, 0.05, 0), "above": at + fwd * 0.3 + Vector3(0, 0.75, 0), "below": at + fwd * 0.6 - Vector3(0, 0.4, 0),
			# (level with the box's bottom, close, from their left and from in
			# front: does it sit on the palm, or over it?)
			"level": at - side * 0.45 - Vector3(0, size.y * 0.5, 0), "levelfront": at + fwd * 0.45 - Vector3(0, size.y * 0.5, 0)}
		for k in views:
			cam.global_position = views[k]
			cam.look_at(at - Vector3(0, size.y * 0.5, 0) if k.begins_with("level") else at, Vector3.UP)
			await _shot("%s_%s_%s" % [look, mode, k])
	print("BOX HOLD: ", "ok" if problems == 0 else "%d problems" % problems)
	quit()
