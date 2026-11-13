extends Node
## The body check (12 November, Gary: "we seem to have a lot of model
## glitches that I'm having to keep going through and ask you to fix"; the
## answer: before each update is handed over, every scene is played through
## and checked for hands and bodies passing through things and for twisted
## joints). It watches every 3D figure while a play-through runs, as drawn
## (read inside the skeleton's skeleton_updated, with every modifier's pose
## on the bones: the reaches, the natural wrist, the look round), and prints
## what would look wrong with a body (lines start "BODY:"):
##   joint    a joint turned or bent past what a body does: a wrist or an arm
##            twisted round, an elbow or a knee bent backwards or sideways,
##            the head turned too far round. The limit is a body's, or the
##            furthest the model's own clips take that joint if that's more
##            (a clip's own pose isn't the staging's glitch: tests/body_probe
##            looks at the clips themselves).
##   skin     the skin pulled out of shape ("his arms distort in weird
##            ways"): the mesh's triangles turned inside out, stretched or
##            crushed, skinned on the CPU the way the renderer does it.
##   through  a part of a body inside something solid: a hand in a box or the
##            counter, a body in the stairs or a door, a knee in a bench. The
##            solids are the set's own meshes as drawn, closed surfaces
##            tested with rays six ways, in a physics space of the check's
##            own (nothing in the game sees them).
##   person   a hand inside someone else's body (Bram's hand through the
##            player's shoulder): the other's skin, skinned on the CPU.
##   hangs    something let go of that stays in the air, out of every hand and
##            resting on nothing (Corin's coin).
## A finding has to last two checks running (or be gross) to be reported. It
## is reported once as it starts, with two stills when the run draws (the
## game's own picture and a close look from beside it: <out>/glitch_NNN_*.png),
## and summed up as it ends ("BODY-END:").
##
##   var bc = preload("res://tests/body_check.gd").watch(world_or_root, out_dir)
##   ... print(bc.summary())
##
## Command-line options the drivers pass through: body_every=<n> (frames
## between checks, 2), body_only=player (the player's figure only),
## body_shots=<n> (stills at most, 150), body_skin=<n> (the skin check every
## n-th check, 2; 0 for none).

const DrawHold = preload("res://tests/draw_hold.gd")

## [the bone, the bone it turns against, the bone it points at ("" = from
## its parent's way), what it's called, its kind]
const JOINTS := [
	["LeftArm", "LeftShoulder", "LeftForeArm", "left shoulder", "ball"],
	["LeftForeArm", "LeftArm", "LeftHand", "left elbow", "elbow"],
	["LeftHand", "LeftForeArm", "LeftHandMiddle1", "left wrist", "wrist"],
	["RightArm", "RightShoulder", "RightForeArm", "right shoulder", "ball"],
	["RightForeArm", "RightArm", "RightHand", "right elbow", "elbow"],
	["RightHand", "RightForeArm", "RightHandMiddle1", "right wrist", "wrist"],
	["Head", "Spine2", "", "neck", "neck"],
	["LeftUpLeg", "Hips", "LeftLeg", "left hip", "hip"],
	["LeftLeg", "LeftUpLeg", "LeftFoot", "left knee", "knee"],
	["LeftFoot", "LeftLeg", "LeftToeBase", "left ankle", "ankle"],
	["RightUpLeg", "Hips", "RightLeg", "right hip", "hip"],
	["RightLeg", "RightUpLeg", "RightFoot", "right knee", "knee"],
	["RightFoot", "RightLeg", "RightToeBase", "right ankle", "ankle"],
]
## A body's limits (degrees): twist about the bone's own length, swing off
## its rest line, and for a hinge (elbow, knee) how far it may bend the
## wrong way ("back") or out of its hinge ("side"), and folded flat ("fold").
const LIMITS := {
	"ball": {"twist": 110.0, "swing": 180.0},
	"elbow": {"twist": 170.0, "back": 14.0, "side": 40.0, "fold": 160.0},
	"wrist": {"twist": 80.0, "swing": 90.0},
	"neck": {"twist": 95.0, "swing": 80.0},
	"hip": {"twist": 70.0, "swing": 145.0},
	"knee": {"twist": 50.0, "back": 12.0, "side": 40.0, "fold": 165.0},
	"ankle": {"twist": 50.0, "swing": 70.0},
}
## How far past the furthest the model's own clips take a joint the staging
## may take it (degrees) before it counts.
const CLIP_MARGIN := 15.0
## Past a limit by this much (degrees) is gross: reported at once.
const GROSS_DEG := 30.0

## The skin: a triangle edge longer than this many times its length as
## modelled is stretched, shorter than CRUSH crushed; a triangle facing more
## than ~105 degrees away from where its bone turned it is inside out.
const STRETCH := 1.9
const CRUSH := 0.4
const FOLD_DOT := -0.25
const SKIN_TRIS := 1500          # triangles sampled a figure (most of them at the joints)
## Only figures this near the camera are checked (m): further off, a body is
## too small on screen for its joints or its hands to show.
const RANGE := 9.0
## ...and the skin only this near (m): the skin's shape shows close up.
const SKIN_RANGE := 6.0
## A region (the triangles mostly on one bone) counts as pulled out of shape
## when this many of its sampled triangles are.
const SKIN_BAD := 8
## ...and at least SKIN_STRONG of them inside out, crushed under 0.25 or
## stretched over 2.5 (a few triangles of an armpit going a bit further
## than usual isn't something anyone sees).
const SKIN_STRONG := 4

const RAY := 1.5                 # m: how far the inside test's rays look
const MAX_MESH := 40.0           # m: bigger than this is the ground or the sky
const LAYER := 1

var root: Node
var w: World = null
var out_dir := ""
var every := 4
var skin_every := 3
var only_player := false
var max_shots := 150
var frame := 0
var checks := 0
var _shots := 0
var _due := false
var _figs: Array = []            # Figure3D
var _data := {}                  # figure instance id -> Dictionary (_build)
var _found := {}                 # this check's findings: key -> Dictionary
var _found_frame := -1
var episodes := {}               # key -> Dictionary
var counts := {}
var reported: Array = []         # every reported finding (Dictionary)
var _shown := {}                 # key -> [frame last shown, its worst]
## Frames before the same finding (who, what, where) is shown again, unless worse.
const REPEAT_GAP := 400
var _space: RID
var _solids := {}                # MeshInstance3D id -> {mi, body, shape, scale}
var _scan_frame := -999
var _sub: SubViewport
var _sub_cam: Camera3D
var _was_held := {}              # node id -> {node, who, at (frame let go, -1 while held)}
var _cam: Camera3D
var _cur_vp: Viewport             # the viewport of the figure being checked
var _ms := [0.0, 0.0, 0.0, 0.0]   # time spent (ms): joints, through, people, skin
var _ms_solids := 0.0
var _segs := {}                  # this check's bone segments by figure: [[bone, from, to]]
var _segs_check := -1


static func watch(where: Node, out := "") -> Node:
	var m = load("res://tests/body_check.gd").new()
	m.root = where
	if where is World:
		m.w = where
	m.out_dir = out
	m.name = "BodyCheck"
	where.add_child(m)
	return m


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("body_every="):
			every = maxi(1, int(s.substr(11)))
		elif s == "body_only=player":
			only_player = true
		elif s.begins_with("body_shots="):
			max_shots = int(s.substr(11))
		elif s.begins_with("body_skin="):
			skin_every = int(s.substr(10))
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
	_space = PhysicsServer3D.space_create()
	PhysicsServer3D.space_set_active(_space, true)
	get_tree().process_frame.connect(_tick)
	get_tree().node_added.connect(_on_added)
	for n in root.find_children("*", "Node3D", true, false):
		if n is Figure3D:
			_add(n)


func _exit_tree() -> void:
	if get_tree().process_frame.is_connected(_tick):
		get_tree().process_frame.disconnect(_tick)
	if get_tree().node_added.is_connected(_on_added):
		get_tree().node_added.disconnect(_on_added)
	for k in _solids:
		PhysicsServer3D.free_rid(_solids[k].body)
	_solids.clear()
	if _space.is_valid():
		PhysicsServer3D.free_rid(_space)


func _on_added(n: Node) -> void:
	if n is Figure3D:
		_add(n)


func _add(f: Figure3D) -> void:
	if not _figs.has(f):
		_figs.append(f)


# ------------------------------------------------------------------ frames ---

func _tick() -> void:
	frame += 1
	if _found_frame >= 0:
		# a figure whose skeleton didn't update since the check began (no
		# modifier on it and its clip held still): read as it stands, since
		# then what's stored is what's drawn
		for f in _figs:
			if not is_instance_valid(f):
				continue
			var d0 = _data.get(f.get_instance_id())
			if d0 != null and not d0.done and f._skel != null:
				d0.done = true
				_check_fig(f, d0)
		_settle()
		_found_frame = -1
	_due = frame % every == 0
	if not _due:
		return
	checks += 1
	if checks % 250 == 0:
		print("BODY-PROGRESS: f%d, %d checks; %.0f s joints, %.0f s through, %.0f s people, %.0f s skin, %.0f s solids" % [frame, checks,
			_ms[0] / 1000.0, _ms[1] / 1000.0, _ms[2] / 1000.0, _ms[3] / 1000.0, _ms_solids / 1000.0])
	_cam = get_viewport().get_camera_3d()
	_found = {}
	_found_frame = frame
	if _black():
		_due = false
		return
	for f in _figs.duplicate():
		if not is_instance_valid(f):
			_figs.erase(f)
			continue
		var d = _data.get(f.get_instance_id())
		if d == null:
			if f._skel == null or not f.is_inside_tree():
				continue
			d = _build(f)
			_data[f.get_instance_id()] = d
			f._skel.skeleton_updated.connect(_on_skel.bind(f))
		d.done = false
	var ts := Time.get_ticks_usec()
	if frame - _scan_frame > 16:
		_scan_solids()
	_move_solids()
	_ms_solids += (Time.get_ticks_usec() - ts) / 1000.0
	_check_hanging()


func _who(f: Figure3D) -> String:
	if w != null:
		if f == w.player_doll:
			return "player"
		for n in w.npcs:
			if n.doll == f:
				return String(n.def.get("id", f._model_name))
		var ex: Dictionary = w.get_meta("extras", {}) if w.has_meta("extras") else {}
		for id in ex:
			if ex[id].get("doll") == f:
				return String(id)
	return f._model_name


## On screen: in front of the camera of the viewport they're drawn in (the
## game's, or a film's own: the Night of the White Sky draws in its own).
func _visible(f: Figure3D) -> bool:
	if not f.is_inside_tree() or not f.is_visible_in_tree():
		return false
	var cam := f.get_viewport().get_camera_3d()
	if cam == null:
		return false
	var p := f.global_position
	if p.distance_to(cam.global_position) > RANGE:
		return false
	return cam.is_position_in_frustum(p + Vector3(0, 1.0 * f.stature(), 0)) or cam.is_position_in_frustum(p + Vector3(0, 0.3, 0)) \
		or cam.is_position_in_frustum(f.bone_pos("LeftHand")) or cam.is_position_in_frustum(f.bone_pos("RightHand"))


func _black() -> bool:
	if w == null:
		return false
	if w.has_meta("cine_overlay"):
		var ov = w.get_meta("cine_overlay")
		if is_instance_valid(ov) and ov._black.modulate.a > 0.9:
			return true
	return w.hud != null and w.hud._fade != null and w.hud._fade.modulate.a > 0.9


## What's on screen now, to find the moment again: the line up, if any.
func _context() -> String:
	if w == null:
		return "-"
	var s := ""
	if w.has_meta("cine_overlay"):
		var ov = w.get_meta("cine_overlay")
		if is_instance_valid(ov) and ov._line.modulate.a > 0.01:
			s = ov._line.get_parsed_text().strip_edges()
	if s == "" and w.hud != null and w.hud.dialogue.visible:
		s = String(w.hud.dialogue._name.text) + ": " + w.hud.dialogue._text.get_parsed_text()
	return s.left(70) if s != "" else "-"


func _on_skel(f: Figure3D) -> void:
	if not _due or not is_instance_valid(f):
		return
	var d = _data.get(f.get_instance_id())
	if d == null or d.done:
		return
	d.done = true
	_check_fig(f, d)


func _check_fig(f: Figure3D, d: Dictionary) -> void:
	_cur_vp = f.get_viewport()
	var who := _who(f)
	if only_player and who != "player":
		return
	if not _visible(f):
		return
	var sk := f._skel
	var xf := sk.global_transform
	var g := {}   # bone -> global pose (the skeleton's frame), as drawn
	for b in d.bones_needed:
		g[b] = sk.get_bone_global_pose(b)
	var t0 := Time.get_ticks_usec()
	_check_joints(f, d, who, g)
	var t1 := Time.get_ticks_usec()
	_check_through(f, d, who, g, xf)
	var t2 := Time.get_ticks_usec()
	_check_people(f, d, who, g, xf)
	var t3 := Time.get_ticks_usec()
	var cam3 := f.get_viewport().get_camera_3d()
	if skin_every > 0 and checks % skin_every == 0 and not d.skin.is_empty() and cam3 != null \
			and cam3.global_position.distance_to(f.global_position) < SKIN_RANGE:
		_check_skin(f, d, who, xf)
	var t4 := Time.get_ticks_usec()
	_ms[0] += (t1 - t0) / 1000.0
	_ms[1] += (t2 - t1) / 1000.0
	_ms[2] += (t3 - t2) / 1000.0
	_ms[3] += (t4 - t3) / 1000.0
	var h := f.holding()
	if h != null:
		_was_held[h.get_instance_id()] = {"node": h, "who": who, "at": -1}


func _find(kind: String, who: String, part: String, over: float, gross: bool, text: String, at: Vector3) -> void:
	var key := "%s|%s|%s" % [who, kind, part]
	var old = _found.get(key)
	if old != null and float(old.over) >= over:
		return
	_found[key] = {"kind": kind, "who": who, "part": part, "over": over, "gross": gross, "text": text, "at": at, "vp": _cur_vp}


## After a check: findings that go on, start, or have stopped.
func _settle() -> void:
	for key in _found:
		var f: Dictionary = _found[key]
		var ep = episodes.get(key)
		if ep == null or frame - int(ep.last) > every * 3:
			ep = {"kind": f.kind, "who": f.who, "part": f.part, "start": frame, "last": frame, "n": 0, "worst": 0.0,
				"text": f.text, "worst_text": f.text, "ctx": _context(), "reported": false, "at": f.at, "vp": f.vp}
			episodes[key] = ep
		ep.last = frame
		ep.n = int(ep.n) + 1
		if float(f.over) > float(ep.worst):
			ep.worst = float(f.over)
			ep.worst_text = f.text
			ep.at = f.at
		if not ep.reported and (int(ep.n) >= 2 or bool(f.gross)):
			ep.reported = true
			# (the same thing again soon after, no worse: counted, not shown again)
			var last = _shown.get(key)
			if last != null and frame - int(last[0]) < REPEAT_GAP and float(ep.worst) <= float(last[1]) * 1.2:
				ep.quiet = true
				_shown[key] = [frame, maxf(float(last[1]), float(ep.worst))]
				continue
			_shown[key] = [frame, float(ep.worst)]
			counts[f.kind] = int(counts.get(f.kind, 0)) + 1
			var line := "BODY: %-7s f%-6d %s  [%s]" % [f.kind, int(ep.start), f.text, ep.ctx]
			print(line)
			ep.line = line
			reported.append(ep)
			_shoot(ep)
			if ep.has("still"):
				print("BODY-STILL: ", ep.still)
	for key in episodes.keys():
		var ep: Dictionary = episodes[key]
		if frame - int(ep.last) > every * 3:
			if ep.reported and not ep.get("quiet", false):
				print("BODY-END: %-7s f%d-%d %s %s: worst %s" % [ep.kind, int(ep.start), int(ep.last), ep.who, ep.part, ep.worst_text])
				ep.end = int(ep.last)
			episodes.erase(key)


func summary() -> String:
	var parts := []
	for k in counts:
		parts.append("%s %d" % [k, counts[k]])
	return "BODY SUMMARY (%d frames, %d checks, %d figures; %.0f s joints, %.0f s through, %.0f s people, %.0f s skin): %s" % [frame, checks, _data.size(),
		_ms[0] / 1000.0, _ms[1] / 1000.0, _ms[2] / 1000.0, _ms[3] / 1000.0, ", ".join(parts) if not parts.is_empty() else "nothing"]


# ------------------------------------------------------------------- build ---

## What's worked out from a model once (its joints' ranges in its clips,
## its skin's sample and how that skin stretches in its clips), by model.
static var _cache := {}


func _build(f: Figure3D) -> Dictionary:
	var key := f._model_name
	if not _cache.has(key):
		_cache[key] = _build_model(f)
	var m: Dictionary = _cache[key]
	return {"done": false, "joints": m.joints, "skin": m.skin, "bones_needed": m.bones_needed, "s": f.stature()}


## The game's own clips, which a model borrows when it hasn't them: its
## joints' ranges and its skin's stretch are learnt over these too, so what
## the body check finds in a play-through is the staging's, not the clips'
## (tests/body_probe.gd looks at the clips themselves).
const GAME_CLIPS := ["idle", "walk", "run", "talk", "duel_idle", "play_card", "victory", "defeat", "look_up", "lift",
	"sit", "cheer", "wave", "fall"]


func _build_model(f: Figure3D) -> Dictionary:
	var sk := f._skel
	for c in GAME_CLIPS:
		f._ensure(c)
	var d := {"joints": [], "skin": {}, "bones_needed": []}
	var need := {}
	for j in JOINTS:
		var b := sk.find_bone(j[0])
		var p := sk.find_bone(j[1])
		if b < 0 or p < 0:
			continue
		var c := sk.find_bone(j[2]) if String(j[2]) != "" else -1
		var rb := sk.get_bone_global_rest(b)
		var rp := sk.get_bone_global_rest(p)
		var v: Vector3
		if c >= 0:
			v = sk.get_bone_global_rest(c).origin - rb.origin
		elif String(j[4]) == "wrist":
			v = rb.origin - sk.get_bone_global_rest(sk.get_bone_parent(b)).origin
		else:
			v = rb.origin - sk.get_bone_global_rest(sk.get_bone_parent(b)).origin
		if v.length() < 0.005:
			continue
		var rpb := rp.basis.orthonormalized()
		var rbb := rb.basis.orthonormalized()
		var jd := {"b": b, "p": p, "label": j[3], "kind": j[4],
			"a": (rpb.inverse() * v).normalized(),          # its rest line, in the parent's frame
			"c": (rbb.inverse() * v).normalized(),          # the same in its own frame
			"rr": (rpb.inverse() * rbb).get_rotation_quaternion(),
			"lim": (LIMITS[j[4]] as Dictionary).duplicate()}
		# a hinge bends one way: forward for an elbow, back for a knee, in
		# the model's own frame (its toes show which way it faces)
		if j[4] in ["elbow", "knee"]:
			var fwd := _forward(sk)
			jd.n = (rpb.inverse() * (fwd if j[4] == "elbow" else -fwd)).normalized()
		d.joints.append(jd)
		need[b] = true
		need[p] = true
	_learn_from_clips(f, d)
	for pt in ["Hips", "Spine2", "Head", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand",
			"LeftLeg", "RightLeg", "LeftUpLeg", "RightUpLeg", "Neck", "LeftShoulder", "RightShoulder",
			"LeftHandMiddle3", "LeftHandIndex3", "RightHandMiddle3", "RightHandIndex3", "LeftFoot", "RightFoot"]:
		var b := sk.find_bone(pt)
		if b >= 0:
			need[b] = true
	d.bones_needed = need.keys()
	d.skin = _build_skin(f)
	if not (d.skin as Dictionary).is_empty():
		_skin_baseline(f, d.skin)
	return d


## Which way the model faces at rest (its toes ahead of its ankles), flat.
func _forward(sk: Skeleton3D) -> Vector3:
	for side in ["Left", "Right"]:
		var ft := sk.find_bone(side + "Foot")
		var to := sk.find_bone(side + "ToeBase")
		if ft >= 0 and to >= 0:
			var v := sk.get_bone_global_rest(to).origin - sk.get_bone_global_rest(ft).origin
			v.y = 0.0
			if v.length() > 0.01:
				return v.normalized()
	return Vector3(0, 0, 1)


## The model's own clips, sampled: the furthest each joint goes in them (a
## limit is never under that) and which way each hinge bends in them.
func _learn_from_clips(f: Figure3D, d: Dictionary) -> void:
	var sk := f._skel
	if f.anim == null:
		return
	for jd in d.joints:
		jd.clip_max = {"twist": 0.0, "swing": 0.0, "back": 0.0, "side": 0.0}
		jd.n_sum = Vector3.ZERO
		jd.n_k = 0
	# (two passes: which way each hinge bends first, then how far each joint
	# goes, measured against that way)
	for pass_n in 2:
		for an in f.anim.get_animation_list():
			var a := f.anim.get_animation(an)
			if a == null:
				continue
			var tracks := {}
			for t in a.get_track_count():
				if a.track_get_type(t) != Animation.TYPE_ROTATION_3D:
					continue
				var bi := sk.find_bone(String(a.track_get_path(t).get_concatenated_subnames()))
				if bi >= 0:
					tracks[bi] = t
			if tracks.is_empty():
				continue
			var n := 12
			for i in n:
				var tm := a.length * float(i) / float(n)
				for jd in d.joints:
					var q := _clip_local(sk, a, tracks, int(jd.b), int(jd.p), tm)
					var m := _measure(jd, q)
					if pass_n == 0:
						if jd.has("n") and float(m.swing) > 25.0:
							jd.n_sum += m.perp
							jd.n_k += 1
						continue
					for k in ["twist", "swing", "back", "side"]:
						jd.clip_max[k] = maxf(float(jd.clip_max[k]), float(m[k]))
		if pass_n == 0:
			# a hinge's way from its clips, when they bend it enough to tell
			for jd in d.joints:
				if jd.has("n") and int(jd.n_k) >= 6 and (jd.n_sum as Vector3).length() > 0.5 * float(jd.n_k):
					jd.n_learned = true
					jd.n = (jd.n_sum as Vector3).normalized()
	for jd in d.joints:
		for k in ["twist", "swing", "back", "side"]:
			if (jd.lim as Dictionary).has(k):
				jd.lim[k] = maxf(float(jd.lim[k]), float(jd.clip_max[k]) + CLIP_MARGIN)


## A bone's turn against `p` in a clip at time `tm` (its own track and those
## between, or rest where a clip has none).
func _clip_local(sk: Skeleton3D, a: Animation, tracks: Dictionary, b: int, p: int, tm: float) -> Quaternion:
	var q := Quaternion.IDENTITY
	var cur := b
	while cur >= 0 and cur != p:
		var lq: Quaternion
		if tracks.has(cur):
			lq = a.rotation_track_interpolate(int(tracks[cur]), tm)
		else:
			lq = sk.get_bone_rest(cur).basis.get_rotation_quaternion()
		q = lq * q
		cur = sk.get_bone_parent(cur)
	if cur != p:
		return Quaternion.IDENTITY
	# (the rest's own turns of the bones between are in the product: q is
	# the bone's frame in the parent's)
	return q.normalized()


## How a joint stands, from its turn in its parent's frame `q`: twist about
## its own length, swing off its rest line, and for a hinge its bend the
## wrong way and out of its plane (degrees), and which way it bends (perp).
func _measure(jd: Dictionary, q: Quaternion) -> Dictionary:
	var a: Vector3 = jd.a
	var dv: Vector3 = (Basis(q) * (jd.c as Vector3)).normalized()
	var swing := rad_to_deg(a.angle_to(dv))
	var delta := (q * (jd.rr as Quaternion).inverse()).normalized()
	var twist := absf(rad_to_deg(Figure3D._twist_about(delta, a)))
	var perp := dv - a * a.dot(dv)
	var out := {"twist": twist, "swing": swing, "back": 0.0, "side": 0.0, "perp": Vector3.ZERO}
	if perp.length() > 0.02:
		perp = perp.normalized()
		out.perp = perp
		if jd.has("n"):
			var along := perp.dot(jd.n as Vector3)
			if along < 0.0:
				out.back = swing * -along
			out.side = swing * sqrt(maxf(0.0, 1.0 - along * along))
	return out


# ------------------------------------------------------------------ joints ---

func _check_joints(f: Figure3D, d: Dictionary, who: String, g: Dictionary) -> void:
	for jd in d.joints:
		var gp: Transform3D = g[jd.p]
		var gb: Transform3D = g[jd.b]
		var q := (gp.basis.orthonormalized().inverse() * gb.basis.orthonormalized()).get_rotation_quaternion()
		var m := _measure(jd, q)
		var lim: Dictionary = jd.lim
		var at: Vector3 = f._skel.global_transform * gb.origin
		for k in ["twist", "swing", "back", "side", "fold"]:
			if not lim.has(k):
				continue
			var val: float = float(m.swing) if k == "fold" else float(m[k])
			var over: float = val - float(lim[k])
			if over <= 0.0:
				continue
			var what: String = {"twist": "twisted %.0f deg (most %.0f)", "swing": "bent %.0f deg (most %.0f)",
				"back": "bent %.0f deg the wrong way (most %.0f)", "side": "bent %.0f deg sideways (most %.0f)",
				"fold": "folded %.0f deg (most %.0f)"}[k] % [val, float(lim[k])]
			_find("joint", who, "%s %s" % [jd.label, k], over, over > GROSS_DEG,
				"%s's %s %s, clip %s" % [who, jd.label, what, f._clip], at)


# ------------------------------------------------------------------ solids ---

## The set's meshes near the figures, as solids in the check's own space.
func _scan_solids() -> void:
	_scan_frame = frame
	var near: Array = []
	for f in _figs:
		if is_instance_valid(f) and f.is_inside_tree() and f.is_visible_in_tree():
			near.append(f.global_position)
	if near.is_empty():
		return
	var seen := {}
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		var id := mi.get_instance_id()
		seen[id] = true
		if _solids.has(id):
			continue
		if mi.skin != null or mi.skeleton != NodePath("") and mi.get_node_or_null(mi.skeleton) is Skeleton3D:
			continue   # a body
		if mi.mesh is QuadMesh or mi.mesh is PlaneMesh or mi.has_meta("qa_skip"):
			continue
		var bb := mi.global_transform * mi.get_aabb()
		var big := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
		var thin := minf(bb.size.x, minf(bb.size.y, bb.size.z))
		if big > MAX_MESH or thin < 0.01:
			continue
		var close := false
		for p in near:
			if bb.grow(2.5).has_point(p + Vector3(0, 0.9, 0)):
				close = true
				break
		if not close:
			continue
		if _under_paper(mi) or _is_light(mi):
			continue
		_make_solid(mi)
	# (12 November) the things drawn many at a time, each a solid of its own:
	# the dry-stone walls along the fields (AshfordVillage.lay_walls), which
	# Corin walked through coming down the hill to the tunnel's mouth and
	# nothing here saw. Not grass or pebbles: only copies a body could walk
	# into (MM_BIG across at the least, MM_THICK through).
	for n in root.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		var mm := mmi.multimesh
		if mm == null or mm.mesh == null or not mmi.is_visible_in_tree() or mmi.has_meta("qa_skip"):
			continue
		var mb := mm.mesh.get_aabb()
		if maxf(mb.size.x, maxf(mb.size.y, mb.size.z)) < MM_BIG * 0.5:
			continue
		var whole := mmi.global_transform * mmi.get_aabb()
		var any_near := false
		for p in near:
			if whole.grow(2.5).has_point(p + Vector3(0, 0.9, 0)):
				any_near = true
				break
		if not any_near:
			continue
		var cnt := mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
		for i in cnt:
			var key := "%d:%d" % [mmi.get_instance_id(), i]
			var ixf := mm.get_instance_transform(i)
			if cnt > 1 and ixf == Transform3D.IDENTITY:
				continue   # (a copy never placed: it sits at the multimesh's own origin)
			var bb := mmi.global_transform * (ixf * mb)
			var big := maxf(bb.size.x, maxf(bb.size.y, bb.size.z))
			var thin := minf(bb.size.x, minf(bb.size.y, bb.size.z))
			if big < MM_BIG or thin < MM_THICK or big > MAX_MESH:
				continue
			var close := false
			for p in near:
				if bb.grow(2.5).has_point(p + Vector3(0, 0.9, 0)):
					close = true
					break
			if not close:
				continue
			seen[key] = true
			if _solids.has(key):
				continue
			_make_solid(mmi, ixf, key)
			if OS.has_environment("BODY_DEBUG"):
				print("BODY-DEBUG multimesh solid ", mmi.get_path(), " #", i, " at ", bb.get_center())
	for id in _solids.keys():
		if not seen.has(id):
			PhysicsServer3D.free_rid(_solids[id].body)
			_solids.erase(id)


## A glow, a beam or a haze rather than a thing (the lane's pillar of light,
## a lantern's halo): see-through, added on or unlit, and drawn with no depth.
static func _is_light(mi: MeshInstance3D) -> bool:
	var mats: Array = [mi.material_override]
	for i in mi.mesh.get_surface_count():
		mats.append(mi.get_surface_override_material(i) if mi.get_surface_override_material(i) != null else mi.mesh.surface_get_material(i))
	var any := false
	var light := true
	for m in mats:
		if m == null:
			continue
		any = true
		if m is BaseMaterial3D:
			var b := m as BaseMaterial3D
			var see_through := b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and b.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			if not (see_through or b.blend_mode != BaseMaterial3D.BLEND_MODE_MIX or b.depth_draw_mode == BaseMaterial3D.DEPTH_DRAW_DISABLED):
				light = false
		elif m is ShaderMaterial and (m as ShaderMaterial).shader != null:
			var code := (m as ShaderMaterial).shader.code
			if not ("blend_add" in code or "depth_draw_never" in code or ("ALPHA" in code and not "discard" in code and not "ALPHA_SCISSOR" in code)):
				light = false
		else:
			light = false
	return any and light


func _under_paper(n: Node) -> bool:
	var cur := n.get_parent()
	while cur != null and cur != root:
		if cur is PaperDoll and not (cur is Figure3D):
			return true
		if cur is GPUParticles3D or cur is CPUParticles3D:
			return true
		cur = cur.get_parent()
	return false


## One copy in a MultiMeshInstance3D counts as a solid this big across at
## the least, and this thick (m).
const MM_BIG := 0.8
var _by_rid := {}   # a solid's body -> its key in _solids (a copy's isn't its node's id)
const MM_THICK := 0.15

func _make_solid(mi: GeometryInstance3D, inst := Transform3D(), key = null) -> void:
	var sc := mi.global_transform.basis.get_scale()
	var mesh: Mesh = (mi as MeshInstance3D).mesh if mi is MeshInstance3D else (mi as MultiMeshInstance3D).multimesh.mesh
	var faces := mesh.get_faces()
	if faces.is_empty():
		return
	for i in faces.size():
		faces[i] = (inst * faces[i]) * sc
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var body := PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_add_shape(body, shape.get_rid())
	PhysicsServer3D.body_set_collision_layer(body, LAYER)
	PhysicsServer3D.body_set_collision_mask(body, 0)
	PhysicsServer3D.body_set_space(body, _space)
	PhysicsServer3D.body_attach_object_instance_id(body, mi.get_instance_id())
	var fig_id := -1
	var cur := mi.get_parent()
	while cur != null and cur != root:
		if cur is Figure3D:
			fig_id = cur.get_instance_id()
			break
		cur = cur.get_parent()
	_by_rid[body] = key if key != null else mi.get_instance_id()
	_solids[key if key != null else mi.get_instance_id()] = {"mi": mi, "body": body, "shape": shape, "scale": sc, "xf": Transform3D(), "owner": fig_id, "faces": faces}


func _move_solids() -> void:
	for id in _solids.keys():
		var s: Dictionary = _solids[id]
		var mi = s.mi
		if not is_instance_valid(mi) or not (mi as Node3D).is_inside_tree():
			PhysicsServer3D.free_rid(s.body)
			_solids.erase(id)
			continue
		var xf: Transform3D = (mi as Node3D).global_transform
		var on: bool = (mi as Node3D).is_visible_in_tree()
		var t := Transform3D(xf.basis.orthonormalized(), xf.origin) if on else Transform3D(Basis(), Vector3(0, -9999, 0))
		if t != s.xf:
			s.xf = t
			PhysicsServer3D.body_set_state(s.body, PhysicsServer3D.BODY_STATE_TRANSFORM, t)


const DIRS := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]


## Is `p` inside one of the solids? [how deep (m, to the nearest of its
## inside faces the rays found), the mesh] or [] when it isn't.
func _inside(p: Vector3, skip: Array) -> Array:
	var ss := PhysicsServer3D.space_get_direct_state(_space)
	if ss == null:
		return []
	var votes := {}
	var nearest := {}
	for dir in DIRS:
		var q := PhysicsRayQueryParameters3D.create(p, p + dir * RAY, LAYER)
		q.hit_back_faces = true
		q.hit_from_inside = true
		var ex: Array[RID] = []
		var hit := {}
		# (a mesh to leave out is stepped past: up to three tries)
		for k in 3:
			q.exclude = ex
			hit = ss.intersect_ray(q)
			if hit.is_empty():
				break
			var oid := int(hit.collider_id)
			if oid in skip:
				ex.append(hit.rid)
				hit = {}
				continue
			break
		if hit.is_empty():
			continue
		# (the hit's normal is turned to face the ray whichever side was hit:
		# the face's own way, from its corners, says which side it was)
		if _face_dir(hit).dot(dir) > 0.0:   # the inside of a face: we're within its surface
			var oid2 := int(hit.collider_id)
			votes[oid2] = int(votes.get(oid2, 0)) + 1
			var dd := p.distance_to(hit.position)
			nearest[oid2] = minf(float(nearest.get(oid2, INF)), dd)
	for oid in votes:
		if int(votes[oid]) >= 4:
			return [float(nearest[oid]), instance_from_id(oid)]
	return []


## Which way a hit face of a solid faces (world; its winding's normal, out
## of the closed surface).
func _face_dir(hit: Dictionary) -> Vector3:
	var s = _solids.get(_by_rid.get(hit.rid, int(hit.collider_id)))
	if s == null:
		return Vector3.ZERO
	var fi := int(hit.get("face_index", -1))
	var faces: PackedVector3Array = s.faces
	if fi < 0 or fi * 3 + 2 >= faces.size():
		return Vector3.ZERO
	var a := faces[fi * 3]
	var b := faces[fi * 3 + 1]
	var c := faces[fi * 3 + 2]
	# (Godot's front faces wind clockwise)
	return ((s.xf as Transform3D).basis * (c - a).cross(b - a)).normalized()


## The points of a body tested against the set: [where, what it's called,
## how deep before it counts (m)].
func _body_points(f: Figure3D, d: Dictionary, g: Dictionary, xf: Transform3D) -> Array:
	var sk := f._skel
	var s: float = d.s
	var out: Array = []
	var bp := func(name: String):
		var b := sk.find_bone(name)
		return xf * (g[b] as Transform3D).origin if b >= 0 and g.has(b) else null
	for row in [["Hips", "hips", 0.03], ["Spine2", "chest", 0.03], ["LeftLeg", "left knee", 0.012], ["RightLeg", "right knee", 0.012]]:
		var p = bp.call(row[0])
		if p != null:
			out.append([p, row[1], row[2]])
	var hd = bp.call("Head")
	if hd != null:
		out.append([(hd as Vector3) + Vector3(0, 0.07 * s, 0), "head", 0.03])
	for side: String in ["Left", "Right"]:
		var lo := side.to_lower()
		var sh = bp.call(side + "Arm")
		var el = bp.call(side + "ForeArm")
		var wr = bp.call(side + "Hand")
		if sh == null or el == null or wr == null:
			continue
		out.append([((sh as Vector3) + (el as Vector3)) * 0.5, lo + " upper arm", 0.015])
		out.append([el, lo + " elbow", 0.012])
		out.append([((el as Vector3) + (wr as Vector3)) * 0.5, lo + " forearm", 0.012])
		out.append([wr, lo + " wrist", 0.01])
		# the hand's own way (its rest line turned as drawn: fingers jumbled
		# at the knuckles or none, the hand bone still says it)
		var hb := sk.find_bone(side + "Hand")
		var hdir := ((wr as Vector3) - (el as Vector3)).normalized()
		for jd in d.joints:
			if int(jd.b) == hb:
				hdir = (xf.basis * (g[hb] as Transform3D).basis.orthonormalized() * (jd.c as Vector3)).normalized()
		out.append([(wr as Vector3) + hdir * 0.055 * s, lo + " hand", 0.01])
		out.append([(wr as Vector3) + hdir * 0.095 * s, lo + " knuckles", 0.012])
		for fn in ["HandMiddle3", "HandIndex3"]:
			var tp = bp.call(side + fn)
			if tp != null and (tp as Vector3).distance_to(wr) > 0.12 * s:
				out.append([tp, lo + " fingers", 0.015])
				break
	return out


func _check_through(f: Figure3D, d: Dictionary, who: String, g: Dictionary, xf: Transform3D) -> void:
	if _solids.is_empty():
		return
	# (what they wear or carry as part of their figure isn't in their way)
	var own: Array = []
	for id in _solids:
		if int(_solids[id].owner) == f.get_instance_id():
			own.append(id)
	for row in _body_points(f, d, g, xf):
		var p: Vector3 = row[0]
		var r := _inside(p, own)
		if r.is_empty():
			continue
		var deep: float = r[0]
		if deep < float(row[2]):
			continue
		var mi = r[1]
		var what := _thing_name(mi)
		_find("through", who, "%s in %s" % [row[1], what], deep * 100.0, deep > 0.06,
			"%s's %s is %.1f cm inside %s, clip %s" % [who, row[1], deep * 100.0, what, f._clip], p)


func _thing_name(mi) -> String:
	if mi == null or not is_instance_valid(mi):
		return "something"
	var n := mi as Node
	var parts := []
	var cur := n
	for i in 3:
		if cur == null or cur == root:
			break
		parts.push_front(String(cur.name))
		cur = cur.get_parent()
	var out := "/".join(parts)
	# (a mesh made in code has no name of its own: say what and how big it
	# is, so the finding can be told from its neighbours)
	if String(n.name).begins_with("@") and n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var m := (n as MeshInstance3D).mesh
		var bb := (n as MeshInstance3D).global_transform * m.get_aabb()
		out += " (%s %.2f x %.2f x %.2f m at %s)" % [m.get_class(), bb.size.x, bb.size.y, bb.size.z, str(bb.get_center().snapped(Vector3.ONE * 0.01))]
	return out


# ------------------------------------------------------------------ people ---

func _check_people(f: Figure3D, d: Dictionary, who: String, g: Dictionary, xf: Transform3D) -> void:
	var hands: Array = []
	for row in _body_points(f, d, g, xf):
		var nm: String = row[1]
		if nm.ends_with("hand") or nm.ends_with("knuckles") or nm.ends_with("fingers") or nm.ends_with("wrist"):
			hands.append(row)
	if hands.is_empty():
		return
	if _segs_check != checks:
		_segs = {}
		_segs_check = checks
	for o in _figs:
		if o == f or not is_instance_valid(o) or not o.is_inside_tree() or not o.is_visible_in_tree():
			continue
		var od = _data.get(o.get_instance_id())
		if od == null or (od.skin as Dictionary).is_empty():
			continue
		var oc: Vector3 = o.global_position + Vector3(0, 0.9 * o.stature(), 0)
		var close := false
		for row in hands:
			if (row[0] as Vector3).distance_to(oc) < 1.2 * o.stature():
				close = true
				break
		if not close:
			continue
		var segs: Array = _segs.get(o.get_instance_id(), [])
		if segs.is_empty():
			var osk: Skeleton3D = o._skel
			var oxf := osk.global_transform
			for b in (od.skin.by_bone as Dictionary):
				var bpos := oxf * osk.get_bone_global_pose(b).origin
				var par := osk.get_bone_parent(b)
				var ppos := oxf * osk.get_bone_global_pose(par).origin if par >= 0 else bpos
				segs.append([b, ppos, bpos])
			_segs[o.get_instance_id()] = segs
		var rad: Dictionary = od.skin.radius
		var os: float = (o._skel as Skeleton3D).global_transform.basis.get_scale().x
		for row in hands:
			var p: Vector3 = row[0]
			# how deep in their body, by each bone's own thickness (its skin's
			# distance from it at rest): the deepest
			var deep := 0.0
			var where := -1
			for sg in segs:
				var r: float = float(rad.get(sg[0], 0.0)) * os
				if r < 0.02:
					continue
				var dd := r - _seg_dist(p, sg[1], sg[2])
				if dd > deep:
					deep = dd
					where = sg[0]
			if deep < 0.02:
				continue
			var oname := _who(o)
			var bname := _region(o._skel.get_bone_name(where))
			_find("person", who, "%s in %s" % [row[1], oname], deep * 100.0, deep > 0.06,
				"%s's %s is %.1f cm inside %s's %s, clip %s" % [who, row[1], deep * 100.0, oname, bname, f._clip], p)


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 1e-8:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Is `p` inside the other's skin? Their vertices on the bones near it,
## skinned; the nearest, and which side of it `p` is (by its normal):
## [how deep (m), the bone], or [].
func _skin_inside(o: Figure3D, sd: Dictionary, near_b: Array, p: Vector3) -> Array:
	var sk := o._skel
	var xf := sk.global_transform
	var bt := _bone_xfs(sk, xf, sd)
	var best := INF
	var best_i := -1
	var verts: PackedVector3Array = sd.verts
	for b in near_b:
		var idx: PackedInt32Array = sd.by_bone[b]
		for i in idx:
			var q := _skin_one(sd, i, bt)
			var dd := q.distance_squared_to(p)
			if dd < best:
				best = dd
				best_i = i
	if best_i < 0 or best > 0.1 * 0.1:
		return []
	var q := _skin_one(sd, best_i, bt)
	var dom: int = sd.dom[best_i]
	var nrm: Vector3 = ((bt[dom] as Transform3D).basis.orthonormalized() * (sd.norms as PackedVector3Array)[best_i]).normalized()
	var side := (p - q).dot(nrm)
	if side >= 0.0:
		return []
	return [-side, sk.get_bone_name(dom)]


# -------------------------------------------------------------------- skin ---

func _build_skin(f: Figure3D) -> Dictionary:
	var sk := f._skel
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var dom := PackedInt32Array()
	var binds := {}
	var tris := PackedInt32Array()
	for mi: MeshInstance3D in f.model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skeleton == NodePath():
			continue
		if not mi.is_visible_in_tree():
			continue
		var skin: Skin = mi.skin
		if skin == null:
			skin = sk.create_skin_from_rest_transforms()
		var bind_bone: Array = []
		var bind_x: Array = []
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = sk.find_bone(skin.get_bind_name(i))
			bind_bone.append(b)
			bind_x.append(skin.get_bind_pose(i))
		var local := Transform3D.IDENTITY
		var cur: Node = mi
		while cur != null and cur != sk:
			if cur is Node3D:
				local = (cur as Node3D).transform * local
			cur = cur.get_parent()
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ns = arr[Mesh.ARRAY_NORMAL]
			var bs = arr[Mesh.ARRAY_BONES]
			var ws = arr[Mesh.ARRAY_WEIGHTS]
			var ix = arr[Mesh.ARRAY_INDEX]
			if vs.is_empty() or bs == null or ws == null or ns == null:
				continue
			var per := int(bs.size() / vs.size())
			if per < 1:
				continue
			var base := verts.size()
			for vi in vs.size():
				verts.append(local * vs[vi])
				norms.append((local.basis * (ns as PackedVector3Array)[vi]).normalized())
				# the four heaviest
				var pairs: Array = []
				for k in per:
					var wv := float(ws[vi * per + k])
					if wv > 0.0:
						pairs.append([wv, int(bs[vi * per + k])])
				if pairs.size() > 1:
					pairs.sort_custom(func(x, y): return x[0] > y[0])
				var heavy := -1
				var heavy_w := -1.0
				for k in 4:
					if k < pairs.size():
						var bi: int = pairs[k][1]
						var b: int = bind_bone[bi] if bi < bind_bone.size() else -1
						bones.append(b)
						weights.append(float(pairs[k][0]))
						if b >= 0 and not binds.has(b):
							binds[b] = bind_x[bi]
						if b >= 0 and float(pairs[k][0]) > heavy_w:
							heavy_w = float(pairs[k][0])
							heavy = b
					else:
						bones.append(-1)
						weights.append(0.0)
				dom.append(heavy)
			if ix == null or (ix as PackedInt32Array).is_empty():
				for t in range(0, vs.size() - 2, 3):
					tris.append_array([base + t, base + t + 1, base + t + 2])
			else:
				for t in (ix as PackedInt32Array):
					tris.append(base + t)
	if verts.is_empty():
		return {}
	# grouped by their heaviest bone (for the person check)
	var by_bone := {}
	var tmp := {}
	for i in verts.size():
		var b := dom[i]
		if b < 0:
			continue
		if not tmp.has(b):
			tmp[b] = PackedInt32Array()
		(tmp[b] as PackedInt32Array).append(i)
	by_bone = tmp
	# how thick the body is round each bone (m): its vertices' distance from
	# its length at rest, the 70th in a hundred (for the person check)
	var radius := {}
	for b in by_bone:
		var par := sk.get_bone_parent(b)
		var p1 := sk.get_bone_global_rest(b).origin
		var p0 := sk.get_bone_global_rest(par).origin if par >= 0 else p1
		var ds: Array = []
		var idx: PackedInt32Array = by_bone[b]
		var step := maxi(1, idx.size() / 200)
		for k in range(0, idx.size(), step):
			ds.append(_seg_dist(verts[idx[k]], p0, p1))
		ds.sort()
		radius[b] = float(ds[int(ds.size() * 0.7)]) if not ds.is_empty() else 0.0
	# the triangles sampled for the skin check: most where the weights blend
	# (the joints, where a bad turn pulls the skin), some of the rest
	var nt := tris.size() / 3
	var joint_t := PackedInt32Array()
	var other_t := PackedInt32Array()
	for t in nt:
		var a := tris[t * 3]
		var b := tris[t * 3 + 1]
		var c := tris[t * 3 + 2]
		if dom[a] != dom[b] or dom[b] != dom[c] or weights[a * 4] < 0.88 or weights[b * 4] < 0.88:
			joint_t.append(t)
		else:
			other_t.append(t)
	var pick := PackedInt32Array()
	var want_j := mini(joint_t.size(), int(SKIN_TRIS * 0.8))
	var want_o := mini(other_t.size(), SKIN_TRIS - want_j)
	for k in want_j:
		pick.append(joint_t[int(float(k) * joint_t.size() / want_j)])
	for k in want_o:
		pick.append(other_t[int(float(k) * other_t.size() / want_o)])
	var s_tris := PackedInt32Array()
	var s_len := PackedFloat32Array()
	var s_n := PackedVector3Array()
	var s_dom := PackedInt32Array()
	var used := {}
	for t in pick:
		var a := tris[t * 3]
		var b := tris[t * 3 + 1]
		var c := tris[t * 3 + 2]
		var pa := verts[a]
		var pb := verts[b]
		var pc := verts[c]
		var nn := (pb - pa).cross(pc - pa)
		if nn.length() < 1e-10:
			continue
		s_tris.append_array([a, b, c])
		s_len.append_array([pa.distance_to(pb), pb.distance_to(pc), pc.distance_to(pa)])
		s_n.append(nn.normalized())
		# the triangle's bone: the heaviest over its three corners
		var tot := {}
		for v in [a, b, c]:
			for k in 4:
				var bb := bones[v * 4 + k]
				if bb >= 0:
					tot[bb] = float(tot.get(bb, 0.0)) + weights[v * 4 + k]
		var best := -1
		var bw := -1.0
		for bb in tot:
			if float(tot[bb]) > bw:
				bw = float(tot[bb])
				best = bb
		s_dom.append(best)
		used[a] = true
		used[b] = true
		used[c] = true
	var uv := PackedInt32Array()
	for i in used:
		uv.append(int(i))
	return {"verts": verts, "norms": norms, "bones": bones, "weights": weights, "dom": dom, "binds": binds,
		"by_bone": by_bone, "tris": s_tris, "len": s_len, "n": s_n, "tdom": s_dom, "uv": uv, "radius": radius}


## How each sampled triangle fares in the model's own clips (up to 16, four
## moments each, the poses worked out from the clips' tracks): the most it
## stretches, the least it's crushed to, and whether it turns inside out.
## Armpits and groins stretch in every clip (the skinning's way): only worse
## than that, or a triangle that never turns inside out doing so, counts.
func _skin_baseline(f: Figure3D, sd: Dictionary) -> void:
	var sk := f._skel
	var nt := (sd.tdom as PackedInt32Array).size()
	var st := PackedFloat32Array()
	var cr := PackedFloat32Array()
	var fo := PackedByteArray()
	st.resize(nt)
	cr.resize(nt)
	fo.resize(nt)
	for t in nt:
		st[t] = 1.0
		cr[t] = 1.0
		fo[t] = 0
	var clips: Array = Array(f.anim.get_animation_list())
	if clips.size() > 16:
		var keep: Array = []
		for c in clips:
			if c in GAME_CLIPS:
				keep.append(c)
		for c in clips:
			if keep.size() >= 16:
				break
			if not keep.has(c):
				keep.append(c)
		clips = keep
	var poses := 0
	for an in clips:
		var a := f.anim.get_animation(an)
		if a == null:
			continue
		var tracks := {}
		for t in a.get_track_count():
			var bi := sk.find_bone(String(a.track_get_path(t).get_concatenated_subnames()))
			if bi < 0:
				continue
			if not tracks.has(bi):
				tracks[bi] = [-1, -1, -1]
			match a.track_get_type(t):
				Animation.TYPE_POSITION_3D:
					tracks[bi][0] = t
				Animation.TYPE_ROTATION_3D:
					tracks[bi][1] = t
				Animation.TYPE_SCALE_3D:
					tracks[bi][2] = t
		for i in 4:
			var tm := a.length * (float(i) + 0.5) / 4.0
			var gl := _fk(sk, a, tracks, tm)
			var bt := {}
			for b in sd.binds:
				bt[b] = gl[b] * (sd.binds[b] as Transform3D)
			var res := _tri_state(sd, bt)
			poses += 1
			var rs: PackedFloat32Array = res[0]
			var rc: PackedFloat32Array = res[1]
			var rf: PackedByteArray = res[2]
			for t in nt:
				st[t] = maxf(st[t], rs[t])
				cr[t] = minf(cr[t], rc[t])
				if rf[t] == 1:
					fo[t] = 1
	sd.base_st = st
	sd.base_cr = cr
	sd.base_fold = fo
	sd.base_poses = poses


## The skeleton's poses (its own frame) in clip `a` at `tm`, from its tracks
## and the rest where it has none.
func _fk(sk: Skeleton3D, a: Animation, tracks: Dictionary, tm: float) -> Array:
	var n := sk.get_bone_count()
	var out: Array = []
	out.resize(n)
	for b in n:
		_fk_one(sk, a, tracks, tm, b, out)
	return out


func _fk_one(sk: Skeleton3D, a: Animation, tracks: Dictionary, tm: float, b: int, out: Array) -> Transform3D:
	if out[b] != null:
		return out[b]
	var rest := sk.get_bone_rest(b)
	var pos := rest.origin
	var rot := rest.basis.get_rotation_quaternion()
	var scl := rest.basis.get_scale()
	if tracks.has(b):
		var tr: Array = tracks[b]
		if int(tr[0]) >= 0:
			pos = a.position_track_interpolate(int(tr[0]), tm)
		if int(tr[1]) >= 0:
			rot = a.rotation_track_interpolate(int(tr[1]), tm)
		if int(tr[2]) >= 0:
			scl = a.scale_track_interpolate(int(tr[2]), tm)
	var local := Transform3D(Basis(rot) * Basis.from_scale(scl), pos)
	var par := sk.get_bone_parent(b)
	var g := local if par < 0 else _fk_one(sk, a, tracks, tm, par, out) * local
	out[b] = g
	return g


## Every sampled triangle in a pose (bone transforms `bt`): [its worst
## stretch, its worst crush, inside out (1) or not].
func _tri_state(sd: Dictionary, bt: Dictionary) -> Array:
	var pos := {}
	for i in (sd.uv as PackedInt32Array):
		pos[i] = _skin_one(sd, i, bt)
	var rot := {}
	for b in bt:
		rot[b] = (bt[b] as Transform3D).basis.orthonormalized()
	var tris: PackedInt32Array = sd.tris
	var lens: PackedFloat32Array = sd.len
	var ns: PackedVector3Array = sd.n
	var tdom: PackedInt32Array = sd.tdom
	var nt := tdom.size()
	var rs := PackedFloat32Array()
	var rc := PackedFloat32Array()
	var rf := PackedByteArray()
	rs.resize(nt)
	rc.resize(nt)
	rf.resize(nt)
	for t in nt:
		var a: Vector3 = pos[tris[t * 3]]
		var b: Vector3 = pos[tris[t * 3 + 1]]
		var c: Vector3 = pos[tris[t * 3 + 2]]
		var l3 := [a.distance_to(b), b.distance_to(c), c.distance_to(a)]
		var hi := 1.0
		var lo := 1.0
		for k in 3:
			var l0: float = lens[t * 3 + k]
			if l0 < 0.003:
				continue
			var r: float = float(l3[k]) / l0
			hi = maxf(hi, r)
			lo = minf(lo, r)
		rs[t] = hi
		rc[t] = lo
		rf[t] = 0
		var nn := (b - a).cross(c - a)
		var bone := tdom[t]
		if nn.length() > 1e-12 and rot.has(bone) and nn.normalized().dot((rot[bone] as Basis) * ns[t]) < FOLD_DOT:
			rf[t] = 1
	return [rs, rc, rf]


func _bone_xfs(sk: Skeleton3D, xf: Transform3D, sd: Dictionary) -> Dictionary:
	var bt := {}
	for b in sd.binds:
		bt[b] = xf * sk.get_bone_global_pose(b) * (sd.binds[b] as Transform3D)
	return bt


func _skin_one(sd: Dictionary, i: int, bt: Dictionary) -> Vector3:
	var bones: PackedInt32Array = sd.bones
	var weights: PackedFloat32Array = sd.weights
	var v: Vector3 = (sd.verts as PackedVector3Array)[i]
	var p := Vector3.ZERO
	var tot := 0.0
	for k in 4:
		var b := bones[i * 4 + k]
		var wv := weights[i * 4 + k]
		if b < 0 or wv <= 0.0 or not bt.has(b):
			continue
		p += (bt[b] as Transform3D) * v * wv
		tot += wv
	return p / tot if tot > 0.0 else v


## The skin's sampled triangles as drawn now, by region: {bone: [inside
## out, stretched, crushed, worst stretch, worst crush, a point]}, counting
## only what's worse than the model's own clips make it (_skin_baseline);
## `raw` counts everything (the probe, on the clips themselves).
func skin_state(f: Figure3D, sd: Dictionary, raw := false) -> Dictionary:
	var sk := f._skel
	var bt := _bone_xfs(sk, sk.global_transform, sd)
	var res := _tri_state(sd, bt)
	var rs: PackedFloat32Array = res[0]
	var rc: PackedFloat32Array = res[1]
	var rf: PackedByteArray = res[2]
	var tdom: PackedInt32Array = sd.tdom
	var tris: PackedInt32Array = sd.tris
	var has_base := sd.has("base_st") and not raw
	var out := {}
	for t in tdom.size():
		var st := rs[t]
		var cr := rc[t]
		var fold := rf[t] == 1
		var stretched := st >= STRETCH
		var crushed := cr <= CRUSH
		if has_base:
			stretched = stretched and st > float(sd.base_st[t]) * 1.3 + 0.2
			crushed = crushed and cr < float(sd.base_cr[t]) * 0.7
			fold = fold and int(sd.base_fold[t]) == 0
		if not fold and not stretched and not crushed:
			continue
		var bone := tdom[t]
		var p := (_skin_one(sd, tris[t * 3], bt) + _skin_one(sd, tris[t * 3 + 1], bt) + _skin_one(sd, tris[t * 3 + 2], bt)) / 3.0
		if not out.has(bone):
			out[bone] = [0, 0, 0, 1.0, 1.0, p]
		var row: Array = out[bone]
		if fold:
			row[0] += 1
		if stretched:
			row[1] += 1
			row[3] = maxf(row[3], st)
		if crushed:
			row[2] += 1
			row[4] = minf(row[4], cr)
		row[5] = p
	return out


func _check_skin(f: Figure3D, d: Dictionary, who: String, _xf: Transform3D) -> void:
	var sd: Dictionary = d.skin
	var st := skin_state(f, sd)
	for bone in st:
		var row: Array = st[bone]
		var bad: int = int(row[0]) + int(row[1]) + int(row[2])
		var allowed: int = SKIN_BAD
		if bad < allowed:
			continue
		var strong: int = int(row[0]) + (int(row[2]) if float(row[4]) < 0.25 else 0) + (int(row[1]) if float(row[3]) > 2.5 else 0)
		if strong < SKIN_STRONG:
			continue
		var region := _region(f._skel.get_bone_name(bone))
		var bits := []
		if int(row[0]) > 0:
			bits.append("%d inside out" % row[0])
		if int(row[1]) > 0:
			bits.append("%d stretched (x%.1f)" % [row[1], row[3]])
		if int(row[2]) > 0:
			bits.append("%d crushed (x%.2f)" % [row[2], row[4]])
		_find("skin", who, region, float(bad), bad >= allowed * 3,
			"%s's %s skin pulled out of shape: %s of the triangles checked, clip %s" % [who, region, ", ".join(bits), f._clip], row[5])


## A bone's name as Gary would say it.
static func _region(bn: String) -> String:
	var side := ""
	var b := bn
	if b.begins_with("Left"):
		side = "left "
		b = b.substr(4)
	elif b.begins_with("Right"):
		side = "right "
		b = b.substr(5)
	if b.begins_with("Hand") and b.length() > 4:
		return side + ("thumb" if "Thumb" in b else "fingers")
	var names := {"Hand": "hand", "ForeArm": "forearm", "Arm": "upper arm", "Shoulder": "shoulder", "UpLeg": "thigh",
		"Leg": "shin", "Foot": "foot", "ToeBase": "toes", "Hips": "hips", "Spine": "belly", "Spine1": "chest",
		"Spine2": "chest", "Neck": "neck", "Head": "head"}
	return side + String(names.get(b, bn))


# ------------------------------------------------------------------- items ---

## Things let go of: watched for a few seconds; one that stays where it was,
## out of every hand and resting on nothing, is hanging in the air.
func _check_hanging() -> void:
	for id in _was_held.keys():
		var e: Dictionary = _was_held[id]
		var n = e.node
		if not is_instance_valid(n) or not (n as Node3D).is_inside_tree():
			_was_held.erase(id)
			continue
		var still_held := false
		for f in _figs:
			if is_instance_valid(f) and (f.holding() == n or (not f._grip.is_empty() and f._grip.get("node") == n)):
				still_held = true
				break
		if still_held:
			e.at = -1
			continue
		if int(e.at) < 0:
			e.at = frame
			e.pos = (n as Node3D).global_position
		if frame - int(e.at) > 8 * 4:   # watched long enough
			_was_held.erase(id)
			continue
		var nd := n as Node3D
		var icam := nd.get_viewport().get_camera_3d()
		if not nd.is_visible_in_tree() or icam == null or not icam.is_position_in_frustum(nd.global_position):
			continue
		_cur_vp = nd.get_viewport()
		var p := nd.global_position
		var near_hand := false
		for f in _figs:
			if not is_instance_valid(f) or not f.is_visible_in_tree():
				continue
			for hb in ["LeftHand", "RightHand"]:
				if f.bone_pos(hb).distance_to(p) < 0.3 * f.stature():
					near_hand = true
		if near_hand:
			continue
		var moving := p.distance_to(e.get("pos", p)) > 0.01
		e.pos = p
		if moving:
			continue
		var own := [nd.get_instance_id()]
		for c in nd.find_children("*", "MeshInstance3D", true, false):
			own.append(c.get_instance_id())
		var under := _below(p, own)
		if under < 0.05 or under == INF:
			continue   # (on something, or nothing found under it to say)
		_find("hangs", String(e.who), String(nd.name), under * 100.0, false,
			"%s, let go of by %s, hangs %.0f cm over what's under it" % [String(nd.name), e.who, under * 100.0], p)


## How far down from `p` the nearest solid is (m; INF for none in 3 m).
func _below(p: Vector3, skip: Array) -> float:
	var ss := PhysicsServer3D.space_get_direct_state(_space)
	var q := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, -3, 0), LAYER)
	var ex: Array[RID] = []
	for k in 3:
		q.exclude = ex
		var hit := ss.intersect_ray(q)
		if hit.is_empty():
			break
		if int(hit.collider_id) in skip:
			ex.append(hit.rid)
			continue
		return p.y - (hit.position as Vector3).y
	# (the ground's in the game's own space)
	var gs := get_viewport().world_3d.direct_space_state if get_viewport().world_3d != null else null
	if gs != null:
		var q2 := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, -3, 0))
		var h2 := gs.intersect_ray(q2)
		if not h2.is_empty():
			return p.y - (h2.position as Vector3).y
	return INF


# ------------------------------------------------------------------ stills ---

func _shoot(ep: Dictionary) -> void:
	if out_dir == "" or DisplayServer.get_name() == "headless" or _shots >= max_shots:
		return
	_shots += 1
	var n := _shots
	var tag := "%03d_%s_%s" % [n, String(ep.who).replace(" ", "_"), ep.kind]
	ep.still = "glitch_%s.png" % tag
	if _sub == null:
		_sub = SubViewport.new()
		_sub.size = Vector2i(640, 480)
		_sub.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_sub_cam = Camera3D.new()
		_sub.add_child(_sub_cam)
		add_child(_sub)
	var vp: Viewport = ep.vp if ep.get("vp") != null and is_instance_valid(ep.vp) else get_viewport()
	_sub.world_3d = vp.find_world_3d()
	var at: Vector3 = ep.at
	var main_cam := vp.get_camera_3d()
	if main_cam != null:
		_sub_cam.environment = main_cam.environment
		_sub_cam.attributes = main_cam.attributes
		# closer in along the game camera's own line (what it sees, nearer:
		# nothing gets between), a little from above
		var back := main_cam.global_position - at
		var dist := clampf(back.length() * 0.45, 0.45, 0.9)
		var from := back.normalized() * dist + Vector3(0, 0.08, 0)
		_sub_cam.global_position = at + from
		if absf(from.normalized().dot(Vector3.UP)) < 0.98:
			_sub_cam.look_at(at, Vector3.UP)
		_sub_cam.fov = 40.0
		_sub_cam.near = 0.02
	_sub_cam.current = true
	DrawHold.hold()
	_sub.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(out_dir.path_join("glitch_%s.png" % tag))
	var img2 := _sub.get_texture().get_image()
	if img2 != null:
		img2.save_png(out_dir.path_join("glitch_%s_close.png" % tag))
	# and from the side (a hand in a box shows edge on)
	if main_cam != null:
		var back2 := main_cam.global_position - at
		back2.y = 0.0
		if back2.length() < 0.01:
			back2 = Vector3(0, 0, 1)
		var side := back2.normalized().rotated(Vector3.UP, deg_to_rad(75.0)) * 0.75 + Vector3(0, 0.15, 0)
		_sub_cam.global_position = at + side
		_sub_cam.look_at(at, Vector3.UP)
		_sub.render_target_update_mode = SubViewport.UPDATE_ONCE
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img3 := _sub.get_texture().get_image()
		if img3 != null:
			img3.save_png(out_dir.path_join("glitch_%s_side.png" % tag))
	DrawHold.release()
