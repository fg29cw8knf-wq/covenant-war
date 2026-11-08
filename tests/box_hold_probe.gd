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
## Since 8 November the hands' skin itself is checked too, every vertex of
## it (tests/hand_skin.gd), against the box as modelled (box_size) and its
## lid, with a fourth stage, `open`, the lid up; and the hand's profile
## under the box is printed (the highest point of the palm, the fingers, the
## thumb and the forearm each centimetre along and across the hand), which
## is where Ashford.BOX_FIT's `bottom` and `thumb` for each look come from.
## `open=<deg> thumb=<deg>` turns a model's fingers open and its thumb down
## as Figure3D.OPEN_FLAT would, to try angles. Stills from the front, both
## sides, above and below.
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 800x600 --path . --script res://tests/box_hold_probe.gd -- <out_dir> [a|b|c|d] [noshots] [open=<deg>] [thumb=<deg>]
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
	var half: Vector3 = Ashford.box_size(box) * 0.5
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
	# (8 November) the hands' skin itself against the box's body as modelled
	# (Player A's finger and thumb bones lie off his fingers: the skin is the
	# check for him), the lid too when it's open
	if _hs != null:
		for side in ["left", "right"]:
			var r: Array = _hs.in_box(side, bx, _body_half, 0.0)
			var lid_r: Array = [0.0, 0, Vector3.ZERO]
			if _lid != null:
				lid_r = _hs.in_box(side, Transform3D(Basis(), -_lid_aabb.get_center()) * _lid.global_transform.affine_inverse(), _lid_aabb.size * 0.5, 0.0)
			var parts := ""
			for part in [["palm", 0], ["fingers", 1], ["thumb", 2]]:
				var pr: Array = _hs.in_box(side, bx, _body_half, 0.0, int(part[1]))
				parts += " %s %d/%.1f cm" % [part[0], pr[1], float(pr[0]) * 100.0]
			print("    %s hand's skin: %d vertices in the box's body (deepest %.1f cm at %s:%s); %d in the lid (deepest %.1f cm)" % [side, r[1], float(r[0]) * 100.0, (r[2] as Vector3).snapped(Vector3(0.001, 0.001, 0.001)), parts, lid_r[1], float(lid_r[0]) * 100.0])
			if float(r[0]) > 0.002 or float(lid_r[0]) > 0.002:
				problems += 1
		# the carrying hand's skin under the box's footprint, in the palm's own
		# frame (y up off the palm): how high the palm, the fingers and the
		# thumb each come under it, against the box's bottom
		var pf := f.palm_frame(cs)
		var pinv := pf.affine_inverse()
		var bq := pinv * box.global_position
		var bottom := bq.y - _body_half.y
		var tops := ""
		for part in [["palm", 0], ["fingers", 1], ["thumb", 2]]:
			var top := -INF
			var n := 0
			for p in _hs.points(cs, int(part[1])):
				var q: Vector3 = pinv * p
				if absf(q.x - bq.x) < _body_half.x and absf(q.z - bq.z) < _body_half.z:
					n += 1
					top = maxf(top, q.y)
			tops += " %s %s (%d)" % [part[0], ("%.1f cm" % (top * 100.0)) if n > 0 else "none", n]
		print("    under the box (the " + cs + " palm's frame, y off the palm): the box's bottom at %.1f cm, its middle %s; the skin's top:%s" % [bottom * 100.0, bq.snapped(Vector3(0.001, 0.001, 0.001)), tops])
		if mode == "left":
			print("    the " + cs + " hand's profile within the box's width (x %.1f to %.1f cm), the box from z %.1f to %.1f cm:" % [(bq.x - _body_half.x) * 100.0, (bq.x + _body_half.x) * 100.0, (bq.z - _body_half.z) * 100.0, (bq.z + _body_half.z) * 100.0])
			print(_hs.profile(cs, pf, bq.x - _body_half.x, bq.x + _body_half.x, -0.12, 0.14))
			print("    and across (x to their left), within z -12 to 14 cm:")
			print(_hs.profile_x(cs, pf, -0.14, 0.10, -0.12, 0.14))


var _hs = null
var _body_half := Vector3.ZERO
var cs := "left"   # the hand the box is carried on (Ashford.carry_side)


## (8 November) Player A's fingers as he modelled them stand up in a loose
## fist (Figure3D.FROZEN keeps them so): opened here by turning each finger
## at its root about the knuckle line, and the thumb down along the side of
## the hand, to see whether his skin takes it. `open=<deg>` on the command
## line turns the fingers that much (and `thumb=<deg>` the thumb).
class FingersOpen:
	extends SkeletonModifier3D
	var fingers := 0.0   # radians
	var thumb := 0.0
	var sides := ["Left", "Right"]

	func _process_modification_with_delta(_delta: float) -> void:
		var sk := get_skeleton()
		if sk == null:
			return
		for pre in sides:
			var h := sk.find_bone(pre + "Hand")
			var i := sk.find_bone(pre + "HandIndex1")
			var p := sk.find_bone(pre + "HandPinky1")
			var m := sk.find_bone(pre + "HandMiddle1")
			if h < 0 or i < 0 or p < 0 or m < 0:
				continue
			# the hand's own frame at rest: along the fingers, across the
			# knuckles, and the palm's way out (as Figure3D.palm_frame)
			var r0 := sk.get_bone_global_rest(h).origin
			var f_b := (sk.get_bone_global_rest(m).origin - r0).normalized()
			var across := sk.get_bone_global_rest(i).origin - sk.get_bone_global_rest(p).origin
			var p_b := across.cross(f_b) if pre == "Right" else f_b.cross(across)
			p_b = (p_b - f_b * p_b.dot(f_b)).normalized()
			var a_b := p_b.cross(f_b).normalized()   # across, square to both
			# (turned as the hand is turned now)
			var gp := sk.get_bone_global_pose(h)
			var rest_b := Basis(sk.get_bone_global_rest(h).basis).orthonormalized()
			var turn := gp.basis.orthonormalized() * rest_b.inverse()
			var ax := (turn * a_b).normalized()
			for fn in ["Index", "Middle", "Ring", "Pinky"]:
				var b := sk.find_bone(pre + "Hand" + fn + "1")
				if b < 0:
					continue
				_turn_bone(sk, b, ax, fingers)
			var tb := sk.find_bone(pre + "HandThumb1")
			if tb >= 0 and thumb != 0.0:
				var fz := (turn * f_b).normalized()
				_turn_bone(sk, tb, fz, thumb if pre == "Left" else -thumb)

	func _turn_bone(sk: Skeleton3D, b: int, axis: Vector3, ang: float) -> void:
		var g := sk.get_bone_global_pose(b)
		var par := sk.get_bone_parent(b)
		var pg := sk.get_bone_global_pose(par).basis.orthonormalized() if par >= 0 else Basis()
		var ng := Basis(axis, ang) * g.basis.orthonormalized()
		sk.set_bone_pose_rotation(b, (pg.inverse() * ng).orthonormalized().get_rotation_quaternion())
var _lid: Node3D = null
var _lid_aabb := AABB()


## The box's body as modelled (not the lid, not the deck in it), about the
## box's origin: its half-size. (CARD_BOX_SIZE is the drawn box's; Gary's
## model is sized by its width alone.)
func _measure_box(box: Node3D) -> void:
	_lid = box.get_node_or_null("Lid") as Node3D
	if _lid == null:
		_lid = box.find_child("Lid", true, false) as Node3D
	var body := AABB()
	var first := true
	var first_l := true
	for mi: MeshInstance3D in box.find_children("*", "MeshInstance3D", true, false):
		if mi.name in ["Deck", "TopCard"]:
			continue
		var in_lid := _lid != null and (mi == _lid or _lid.is_ancestor_of(mi))
		var root: Node3D = _lid if in_lid else box
		var ab := (root.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		if in_lid:
			_lid_aabb = ab if first_l else _lid_aabb.merge(ab)
			first_l = false
		else:
			body = ab if first else body.merge(ab)
			first = false
	# (about the origin: the larger reach each way)
	_body_half = Vector3(maxf(absf(body.position.x), absf(body.end.x)), maxf(absf(body.position.y), absf(body.end.y)), maxf(absf(body.position.z), absf(body.end.z)))
	print("  the box's body as modelled: %s, half %s (CARD_BOX_SIZE/2 %s); lid %s" % [body, _body_half, Ashford.CARD_BOX_SIZE * 0.5, _lid_aabb])


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
	var open_deg := 0.0
	var thumb_deg := 0.0
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("open="):
			open_deg = float(String(a).substr(5))
		elif String(a).begins_with("thumb="):
			thumb_deg = float(String(a).substr(6))
	if open_deg != 0.0 or thumb_deg != 0.0:
		var fo := FingersOpen.new()
		fo.name = "FingersOpen"
		fo.fingers = deg_to_rad(open_deg)
		fo.thumb = deg_to_rad(thumb_deg)
		f._skel.add_child(fo)
		f._skel.move_child(fo, -1)
		print("  fingers opened %.0f deg, the thumb %.0f deg" % [open_deg, thumb_deg])
	var box: Node3D = Ashford._card_box()
	stage.add_child(box)
	var size: Vector3 = Ashford.box_size(box)
	var back: float = Ashford._box_back(f, size)
	# (9 November: the hand it's carried on, BOX_FIT `carry`; the other goes
	# to the lid, and with `one_hand` isn't put under it at all)
	cs = Ashford.carry_side(f)
	var os: String = Ashford.other_side(f)
	var sx: float = Ashford._box_mirror(f)
	var one: bool = Ashford._box_one_hand(f)
	print("  %s: the box on the %s hand%s, %.1f cm back from its palm's middle" % [look, cs, " alone" if one else "", back * 100.0])
	_measure_box(box)
	_hs = load("res://tests/hand_skin.gd").new()
	print("  the hands' skin: %d vertices (left %d, right %d)" % [_hs.setup(f), _hs.count("left"), _hs.count("right")])
	print("  ", _hs.rest_check(cs))
	# (and the palm frame itself about the wrist, and the knuckles: the hand's
	# own measure, for the skin's numbers to be read against)
	var pre: String = "Left" if cs == "left" else "Right"
	var pfr0 := f.palm_frame(cs)
	var pinv0 := pfr0.affine_inverse()
	var wr0: Vector3 = pinv0 * f.bone_pos(pre + "Hand")
	var kn0: Vector3 = pinv0 * f.bone_pos(pre + "HandIndex1")
	var skin_box := AABB()
	var first0 := true
	for sp in _hs.points(cs):
		var q0: Vector3 = pinv0 * sp
		skin_box = AABB(q0, Vector3.ZERO) if first0 else skin_box.expand(q0)
		first0 = false
	print("  in the %s palm's frame (x across, y off the palm, z along the fingers): the wrist bone at %s, the index knuckle at %s; the hand's skin from %s to %s" % [cs, wr0.snapped(Vector3(0.001, 0.001, 0.001)), kn0.snapped(Vector3(0.001, 0.001, 0.001)), skin_box.position.snapped(Vector3(0.001, 0.001, 0.001)), skin_box.end.snapped(Vector3(0.001, 0.001, 0.001))])
	# as _first_deck: the grip in front of them, the carrying palm under the box
	var both_reach := func(c: Node3D, o: Node3D, secs: float) -> void:
		if cs == "left":
			f.reach(c, o, secs)
		else:
			f.reach(o, c, secs)
	var grip := Node3D.new()
	f.carry(grip, f.hold_point(0.5, 0.62) + Vector3((0.0 if not one else 0.06 * sx), -size.y * 0.5 - Ashford._box_bottom(f), 0.0))
	var lmark := Node3D.new()
	grip.add_child(lmark)
	lmark.position = Ashford._box_carry_at(f, back)
	f.palm(cs, Vector3.UP, 0.0, 1.0, true, Vector3.BACK)
	if not one:
		f.palm(os, Vector3.UP, 0.0, 1.0, true, Vector3.BACK)
	f.elbow(cs, Vector3(0.46 * sx, f._shoulder - 0.38, 0.14), 0.0)
	if not one:
		f.elbow(os, Ashford.BOX_RIGHT_ELBOW * Vector3(sx, 1, 1) + Vector3(0, f._shoulder, 0), 0.0)
	both_reach.call(lmark, null, 0.0)
	await _wait(0.4)
	f.attach(box, "palm", cs, Ashford._box_lift(f, size, back), 0.0, 0.0, -back, -Ashford._box_aside(f) * sx, Ashford._box_tilt(f))
	var rmark := Node3D.new()
	box.add_child(rmark)
	rmark.position = Ashford._box_other_at(f, back, size)
	both_reach.call(lmark, null if one else rmark, 0.0)
	for mode in ["both", "centred", "left", "open"]:
		match mode:
			"centred":
				# (as _first_deck: the carrying hand slides across under it, the
				# box kept where it is)
				var a1: float = Ashford._box_aside(f, false)
				lmark.position += Vector3((a1 - Ashford._box_aside(f)) * sx, 0.0, 0.0)
				f.attach(box, "palm", cs, Ashford._box_lift(f, size, back), 0.0, 0.0, -back, -a1 * sx, Ashford._box_tilt(f))
			"left":
				# (the box on the carrying hand alone)
				both_reach.call(lmark, null, 0.3)
				f.palm(os, Vector3.ZERO, 0.0)
			"open":
				# (the lid up, as the deck comes out: the lid against the hand
				# and the forearm under it)
				if _lid != null:
					_lid.rotation.x = deg_to_rad(-105.0)
		# (the opening of the fingers after the hand's turn, which would put
		# them back at rest: last)
		if f._skel.has_node("FingersOpen"):
			f._skel.move_child(f._skel.get_node("FingersOpen"), -1)
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
