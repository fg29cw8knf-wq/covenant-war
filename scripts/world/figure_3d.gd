class_name Figure3D
extends PaperDoll
## A character played by their 3D model (assets/models/characters/<model>.glb)
## instead of the painted cut-out. It answers the same calls as PaperDoll
## (walking, face, look_toward, set_marker), so the world and the cutscenes
## don't care which they've got, and adds the model's own clips:
##
##   fig.gait = "run"                 walking now runs
##   fig.talking = true               talks (hand gestures) while standing
##   await fig.act("lift")            plays a clip once, then back to standing
##   fig.hold("look_up")              plays a clip and stays in its last pose
##   fig.lie_down() / fig.get_up()    flat on the ground (under a cart, struck down)
##   fig.reach(l, r) / fig.let_go()   hands on things (a barrel, a card, a hand)
##   fig.sit(0.45) / fig.stand()      sat on a bench that high (talking, acting, all sitting)
##
## The models share one skeleton's bone names, every bone's rest square to
## the world, so a clip one of them lacks is borrowed from another. A
## borrowed clip is fitted to whoever borrows it: its hip height is scaled
## to theirs (Tilly is a child, so Bram's hips would lift her off the
## ground) and the tracks for bones they haven't got (Bram's apron, fingers
## Tam's and Nell's hands don't have: theirs are a thumb and the fingers as
## one) are dropped.
##
## The player (player_a, Gary's young man, since 17 October) carries his own
## motion-captured clips (idle, walk, run, sneak, cheer, wave, jump, sit,
## fight_stance, punch, punch_combo, kick, roundhouse, flying_kick,
## sword_swing, kata, hit_react, death, dance, roll, strafe_left) and the
## game's (talk, duel_idle, play_card, victory, defeat, fall, look_up, lift)
## fitted to his body by tools/rig_character.py. Corin, Tam, Tilly and Old
## Nell (since 18 October) are built the same way by tools/rig_villager.sh,
## each with their own clips and the game's. The game's clips are the first
## player model's, kept in clips/shared.glb, and Bram's lift.

const DIR := "res://assets/models/characters/"
## Model files that aren't named after who they play (Ned the fiddler's is
## Gary's seamus.glb, from before he was renamed). Everyone else's model is
## characters/<their id or look>.glb (hob, krell, dask, hunter), picked up
## the moment it exists.
const MODELS := {"player": "player_a", "ned": "seamus"}
## Clips that repeat until something else is asked for.
const LOOPS := ["idle", "walk", "run", "sneak", "talk", "duel_idle", "cheer", "fight_stance", "dance"]
## Where to borrow a clip from when a model doesn't have it: the shared
## clips first (the first player model's), then Bram's, Corin's, and last
## the player's motion-captured ones (a punch, a roll...).
const DONORS := ["clips/shared", "bram", "corin", "player_a"]
## How fast each gait carries a grown-up, for matching the feet to the
## ground (m/s); shorter legs (Tilly's) take quicker steps.
const GAIT_SPEED := {"walk": 1.45, "run": 4.2}
## Models whose own walking clips go at their own pace (m/s, as
## tools/rig_character.py measured them), not GAIT_SPEED's. (Corin walks
## and runs as the player does, fitted to his legs.)
const OWN_GAIT := {
	"player_a": {"walk": 1.71, "run": 4.33, "sneak": 0.87},
	"corin": {"walk": 1.68, "run": 4.35},
	"tam": {"walk": 1.63, "run": 4.12},
	"tilly": {"walk": 1.00, "run": 2.54},
	"nell": {"walk": 1.11, "run": 2.81},
}
## A grown-up's hip height (m), the measure for the above.
const ADULT_HIPS := 0.884
const TURN_RATE := 9.0
const MAX_TURN := 10.0     # rad/s at most (a half turn in a third of a second)
## Clips that can't be done sitting down: asking for one stands them up.
const STANDING_ONLY := ["walk", "run", "sneak", "strafe_left", "jump", "sit", "fall", "death", "roll", "flying_kick", "lift"]
## The bones sitting takes over from a clip (the rest go on as the clip has them).
const SIT_BONES := ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "RightUpLeg", "RightLeg", "RightFoot", "RightToeBase"]
## How far a grown-up's hip joints sit above the seat (m).
const SEAT_PAD := 0.1

var model: Node3D
var anim: AnimationPlayer
var _model_name := ""     # the file it's played by (player_a for the player)
var gait := "walk"
var talking := false
## Metres a second the character is being moved at (cutscenes set it so the
## walk cycle keeps pace; 0 = the clip's own pace).
var pace := 0.0
## The height of the seat they're sitting on (m), -1 standing: sit(), stand().
var seat := -1.0
var _seat_at := Vector3.ZERO   # where they sat down
var _seat_settle := 0
var _clip := ""          # what's playing
var _action := ""        # a one-shot or held clip, over the walk/idle choice
var _held := false
var _yaw := 0.0
var _want_yaw := 0.0
var _turned := false
var _lying := 0.0        # 0 standing .. 1 flat on the ground
var _lie_target := 0.0
var _lie_yaw := 0.0
var _pivot: Node3D
var _hand_glow: Node3D
var _skel: Skeleton3D
var _hips := ADULT_HIPS  # their hip height standing (m)
var _top := 1.6          # their head bone standing (m), for the marker over it
var _ik := {}            # "left"/"right": the TwoBoneIK3D holding that hand
var _pose_n := 0

static var _donor_cache := {}

## Whether the characters who have a model use it. Bram, Corin and the
## player became 3D on 15 October, Tam and Tilly on 16 October, Old Nell on
## 18 October (when Corin, Tam and Tilly got Gary's new models too); the
## rest (Hob, Ned, the crowd, Krell and her hunters) stay cut-outs until
## their models exist. false puts everyone back to cut-outs.
const USE_MODELS := true


## The figure for a look: its 3D model when there is one, the cut-out otherwise.
static func make(look: String, id := "") -> PaperDoll:
	var k := model_key(look, id) if USE_MODELS else ""
	if k != "":
		return Figure3D.new().setup(k)
	return PaperDoll.new().setup(look)


## True when this look has a 3D model to play it.
static func has_model(look: String) -> bool:
	return ResourceLoader.exists(DIR + String(MODELS.get(look, look)) + ".glb")


## Which model plays someone: their own (by id: "tam", "krell", "dask"), else
## their look's ("hunter"), else "" for the cut-out.
static func model_key(look: String, id := "") -> String:
	for k in [id, look]:
		if String(k) != "" and has_model(String(k)):
			return String(k)
	return ""


func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	add_child(_pivot)
	_model_name = String(MODELS.get(char_id, char_id))
	var path := DIR + _model_name + ".glb"
	model = (load(path) as PackedScene).instantiate()
	_pivot.add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# skinned meshes move a long way from their rest bounds when they lie down
		mi.extra_cull_margin = 2.0
	# how tall they stand: the walk's pace, the marker over their head and
	# their shadow go by it (Tilly is a head shorter than anyone)
	_skel = model.find_child("Skeleton3D", true, false) as Skeleton3D
	if _skel != null:
		var hb := _skel.find_bone("Hips")
		if hb >= 0:
			_hips = _skel.get_bone_rest(hb).origin.y
		var hd := _skel.find_bone("Head")
		if hd >= 0:
			_top = _skel.get_bone_global_rest(hd).origin.y
	anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null:
		# bones a clip doesn't move go back to standing: without this, a
		# borrowed clip that moves a bone the model's own clips never do
		# (the fall's drop to the ground) leaves it there for good
		anim.deterministic = true
		for c in LOOPS:
			if anim.has_animation(c):
				anim.get_animation(c).loop_mode = Animation.LOOP_LINEAR
		_play("idle", 0.0)
		anim.seek(randf() * 1.5, true)   # nobody breathes in step
	# a soft round shadow, as the cut-outs have, to sit them on the grass
	_shadow = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9) * clampf(_hips / ADULT_HIPS, 0.6, 1.2)
	_shadow.mesh = q
	_shadow.rotation_degrees.x = -90
	_shadow.position.y = 0.03
	_shadow.material_override = _get_shadow_mat()
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)
	_marker = Sprite3D.new()
	_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_marker.shaded = false
	_marker.no_depth_test = true
	_marker.render_priority = 10
	_marker.pixel_size = 0.0045
	_marker.position.y = _marker_y()
	_marker.visible = false
	add_child(_marker)


## Where the marker floats: a hand's breadth over their head.
func _marker_y() -> float:
	var y := _top + 0.55
	if seat >= 0.0:
		y -= maxf(0.0, _hips - seat - SEAT_PAD * stature())
	return y


func _apply_texture() -> void:
	pass


## Turns (smoothly) to face along a world direction. The camera doesn't
## matter for a model, but the call matches the cut-out's.
func face(dir: Vector3, _cam: Camera3D) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	_want_yaw = atan2(dir.x, dir.z)
	if not _turned:
		_turned = true
		_yaw = _want_yaw


func look_toward(point: Vector3, cam: Camera3D) -> void:
	face(point - global_position, cam)


## Faces a direction at once, with no turn.
func snap_face(dir: Vector3) -> void:
	face(dir, null)
	_yaw = _want_yaw
	_pivot.rotation.y = _yaw


## The way the character is facing, flat on the ground.
func facing() -> Vector3:
	return Vector3(sin(_yaw), 0.0, cos(_yaw))


## Plays `clip` once and waits for it, then goes back to standing (or walking).
## `from`/`to` play part of it (fractions of its length).
func act(clip: String, speed := 1.0, blend := 0.2) -> void:
	if not _ensure(clip):
		return
	clip = _sat(clip)
	_action = clip
	_held = false
	_play(clip, blend, speed)
	var a := anim.get_animation(clip)
	await get_tree().create_timer(maxf(0.05, a.length / maxf(speed, 0.01) - blend * 0.5)).timeout
	if _action == clip and not _held:
		_action = ""


## Plays `clip` and stays in its final pose until release().
func hold(clip: String, speed := 1.0, blend := 0.25) -> void:
	if not _ensure(clip):
		return
	clip = _sat(clip)
	_action = clip
	_held = true
	_play(clip, blend, speed)


## Holds a clip at one moment (fraction 0..1 of its length), easing into it
## over `blend` seconds. (It plays up to that moment and stops there: a
## paused player never finishes blending, so the old pose would stay.)
func pose(clip: String, at: float, blend := 0.2) -> void:
	if not _ensure(clip):
		return
	clip = _sat(clip)
	_action = clip
	_held = true
	_pose_n += 1
	var n := _pose_n
	var t := anim.get_animation(clip).length * clampf(at, 0.0, 1.0)
	_play(clip, blend)
	anim.seek(maxf(0.0, t - blend), true)
	await get_tree().create_timer(blend).timeout
	if n == _pose_n and _action == clip and anim.current_animation == clip:
		anim.pause()
		anim.seek(t, true)


## Carries on with a clip held by pose() from `from` (a fraction of its
## length) to its end, then back to standing; returns when it's done (a fall
## held down while someone's pinned, then its own getting up).
func resume(from := -1.0, speed := 1.0) -> void:
	if anim == null or _action == "" or not anim.has_animation(_action):
		return
	var clip := _action
	_pose_n += 1   # (a pose() still easing in mustn't pause it again)
	var a := anim.get_animation(clip)
	anim.speed_scale = speed
	anim.play(clip)
	if from >= 0.0:
		anim.seek(a.length * clampf(from, 0.0, 1.0), true)
	var left := (a.length - anim.current_animation_position) / maxf(speed, 0.01)
	await get_tree().create_timer(maxf(0.05, left - 0.25)).timeout
	if _action == clip:
		release(0.3)


## Back to standing, walking or talking.
func release(blend := 0.3) -> void:
	_action = ""
	_held = false
	_play(_base(), blend)


## Lies flat (face down by default) over `secs`: struck down, pinned.
func lie_down(secs := 0.4, face_up := false) -> void:
	_lie_target = 1.0
	_lie_yaw = PI if face_up else 0.0
	var tw := create_tween()
	tw.tween_property(self, "_lying", 1.0, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


func get_up(secs := 0.7) -> void:
	_lie_target = 0.0
	var tw := create_tween()
	tw.tween_property(self, "_lying", 0.0, secs).set_trans(Tween.TRANS_SINE)
	await tw.finished


## Sits them on a seat `height` m off the ground (Nell's bench, a stool), the
## way they face: their hips go over the spot they stand on, thighs along the
## seat and shins over its edge, feet on the ground if they reach it (Tilly's
## swing). Everything they do sitting (idle, talking, act, hold, pose) keeps
## them sitting, with the clip's body, head and arms, until stand(); walking,
## or being moved off the spot (staged somewhere else), stands them up.
func sit(height := 0.45, blend := 0.8) -> void:
	seat = maxf(height, 0.0)
	_seat_at = global_position
	_seat_settle = 2
	_action = ""
	_held = false
	_play(_base(), blend)


func stand(blend := 0.6) -> void:
	seat = -1.0
	_action = ""
	_held = false
	_play(_base(), blend)


## The sitting version of a clip (built the first time it's asked for, for
## this seat), or the clip itself when they're standing or it can't be sat.
func _sat(clip: String) -> String:
	if seat >= 0.0 and clip in STANDING_ONLY:
		seat = -1.0   # (it stands them up)
	if seat < 0.0 or clip.begins_with("sat_") or _skel == null or anim == null or not anim.has_animation(clip):
		return clip
	var nm := "sat_%s_%d" % [clip, roundi(seat * 100.0)]
	if anim.has_animation(nm):
		return nm
	var a := (anim.get_animation(clip) as Animation).duplicate(true) as Animation
	var prefix := ""
	for t in range(a.get_track_count() - 1, -1, -1):
		var p := a.track_get_path(t)
		var bone := String(p.get_concatenated_subnames())
		if bone == "":
			continue
		prefix = String(p.get_concatenated_names())
		if bone in SIT_BONES:
			a.remove_track(t)
	var pose := _seated_pose()
	for kind in ["pos", "rot"]:
		for bone: String in pose[kind]:
			var t := a.add_track(Animation.TYPE_POSITION_3D if kind == "pos" else Animation.TYPE_ROTATION_3D)
			a.track_set_path(t, NodePath(prefix + ":" + bone))
			for at in [0.0, a.length]:
				if kind == "pos":
					a.position_track_insert_key(t, at, pose.pos[bone])
				else:
					a.rotation_track_insert_key(t, at, pose.rot[bone])
	if not anim.has_animation_library(""):
		anim.add_animation_library("", AnimationLibrary.new())
	anim.get_animation_library("").add_animation(nm, a)
	return nm


## The hips and legs sitting on the seat: {"pos": {bone: position},
## "rot": {bone: turn}} (the models' bones all rest square to the world, so
## a turn here is the bone's turn from standing straight).
func _seated_pose() -> Dictionary:
	var rot := {}
	var hb := _skel.find_bone("Hips")
	var rest := _skel.get_bone_rest(hb).origin
	var hips_y := seat + SEAT_PAD * stature()
	var pos := {"Hips": Vector3(rest.x, hips_y - (_skel.get_bone_global_rest(hb).origin.y - rest.y), rest.z)}
	rot["Hips"] = Quaternion.IDENTITY
	for side in ["Left", "Right"]:
		var up := _skel.find_bone(side + "UpLeg")
		var kn := _skel.find_bone(side + "Leg")
		var ft := _skel.find_bone(side + "Foot")
		if up < 0 or kn < 0 or ft < 0:
			continue
		var pu := _skel.get_bone_global_rest(up).origin
		var pk := _skel.get_bone_global_rest(kn).origin
		var pf := _skel.get_bone_global_rest(ft).origin
		var thigh := pk - pu
		var shin := pf - pk
		var lt := thigh.length()
		var ls := shin.length()
		var tilt := deg_to_rad(8.0)   # shins a little forward of the knees
		var hip_joint := hips_y + (pu.y - _skel.get_bone_global_rest(hb).origin.y)
		# the thighs slope down (or up) just enough to put the feet on the
		# ground; if that would be too steep (a child on a grown-up's bench)
		# they stay level and the feet swing
		var drop := maxf((hip_joint - ls * cos(tilt) - pf.y) / lt, -0.6)
		if drop > 0.6:
			drop = 0.1
		var side_x := thigh.x / lt * 0.6
		var t_dir := Vector3(side_x, -drop, sqrt(maxf(0.0, 1.0 - drop * drop - side_x * side_x)))
		var s_dir := Vector3(0.0, -cos(tilt), sin(tilt))
		var gu := Quaternion(thigh / lt, t_dir)
		var gk := Quaternion(shin / ls, s_dir)
		rot[side + "UpLeg"] = gu
		rot[side + "Leg"] = gu.inverse() * gk
		rot[side + "Foot"] = gk.inverse()   # flat
		rot[side + "ToeBase"] = Quaternion.IDENTITY
	return {"pos": pos, "rot": rot}


## A light in the character's hand (the blank card, a taper, the mark).
## Pass null to take it away. Returns the node so it can be animated.
func hand_light(node: Node3D, right := true) -> Node3D:
	if _hand_glow != null:
		_hand_glow.queue_free()
		_hand_glow = null
	if node == null:
		return null
	var sk := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		add_child(node)
		node.position = Vector3(0.25, 1.0, 0.25)
		_hand_glow = node
		return node
	var ba := BoneAttachment3D.new()
	ba.bone_name = "RightHand" if right else "LeftHand"
	sk.add_child(ba)
	ba.add_child(node)
	_hand_glow = ba
	return node


## The world position of a bone (head, hands), for aiming cameras and lights.
func bone_pos(bone: String) -> Vector3:
	var sk := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		return global_position + Vector3(0, 1.5, 0)
	var i := sk.find_bone(bone)
	if i < 0:
		return global_position + Vector3(0, 1.5, 0)
	return sk.global_transform * sk.get_bone_global_pose(i).origin


func _process(delta: float) -> void:
	_t += delta
	# turn towards where we're facing (easing in, but never faster than a
	# person turns: a half turn takes a third of a second, not a frame or two)
	var d := wrapf(_want_yaw - _yaw, -PI, PI)
	_yaw += clampf(d * minf(1.0, delta * TURN_RATE), -delta * MAX_TURN, delta * MAX_TURN)
	_pivot.rotation = Vector3.ZERO
	_pivot.position = Vector3.ZERO
	if _lying > 0.001:
		# tip over forwards (or backwards) about the feet, flat on the ground
		var tip := _lying * PI * 0.5
		var b := Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, tip if _lie_yaw == 0.0 else -tip)
		_pivot.basis = b
		_pivot.position = Vector3(0, 0.12 * _lying, 0)
	else:
		_pivot.rotation.y = _yaw
	if anim == null:
		return
	if seat >= 0.0 and _seat_settle > 0:
		_seat_settle -= 1   # (placed on the seat just after sitting: that's the seat)
		_seat_at = global_position
	elif seat >= 0.0 and (walking or global_position.distance_to(_seat_at) > 0.3):
		stand(0.0 if not walking else 0.3)   # walked off, or put somewhere else
	if _action == "":
		var want := _base()
		if want != _clip:
			_play(want, 0.25)
		var natural := _gait_pace(_clip)
		if natural > 0.0:
			anim.speed_scale = clampf(pace / natural, 0.5, 1.8) if pace > 0.0 else 1.0
	if _marker != null and _marker.visible:
		_marker.position.y = _marker_y() + sin(_t * 3.0) * 0.06


## The ground (m/s) a walking clip covers at its own speed on this body; 0
## for a clip that isn't a gait.
## A hand's target is found by its path from the hand: when the thing held is
## handed on (re-parented: the drum from Corin to you, the crate put down),
## the old path finds nothing and the arm would drop to the clip in one frame.
## The path follows the node instead, wherever it now is: checked by
## KeepTargets just before the hands are solved each frame.
class KeepTargets:
	extends SkeletonModifier3D
	var fig: Figure3D

	func _process_modification_with_delta(_delta: float) -> void:
		if is_instance_valid(fig):
			fig._keep_targets()


func _keep_targets() -> void:
	for side in _ik:
		var ik = _ik[side]
		if ik == null or not is_instance_valid(ik) or not (ik as TwoBoneIK3D).active or not ik.has_meta("target"):
			continue
		var t = ik.get_meta("target")
		if is_instance_valid(t) and t is Node3D and (t as Node3D).is_inside_tree():
			var p: NodePath = (ik as TwoBoneIK3D).get_path_to(t)
			if p != (ik as TwoBoneIK3D).get_target_node(0):
				(ik as TwoBoneIK3D).set_target_node(0, p)


func _gait_pace(clip: String) -> float:
	var own: Dictionary = OWN_GAIT.get(_model_name, {})
	if own.has(clip):
		return float(own[clip])
	return float(GAIT_SPEED.get(clip, 0.0)) * _hips / ADULT_HIPS


func _base() -> String:
	if walking:
		return gait if anim != null and anim.has_animation(gait) else "walk"
	if talking and anim != null and anim.has_animation("talk"):
		return _sat("talk")
	return _sat("idle")


func _play(clip: String, blend := 0.2, speed := 1.0) -> void:
	if anim == null or not anim.has_animation(clip):
		return
	_clip = clip
	anim.speed_scale = speed if speed > 0.0 else 1.0
	anim.play(clip, blend)
	if speed == 0.0:
		anim.pause()


## Makes sure the model has `clip`, borrowing it from another model if needed.
func _ensure(clip: String) -> bool:
	if anim == null:
		return false
	if anim.has_animation(clip):
		return true
	for donor in DONORS:
		var d := _donor_clip(donor, clip)
		if not d.is_empty():
			var a := (d.clip as Animation).duplicate(true)
			_fit(a, float(d.hips))
			if not anim.has_animation_library(""):
				anim.add_animation_library("", AnimationLibrary.new())
			anim.get_animation_library("").add_animation(clip, a)
			return true
	return false


## Fits a borrowed clip to this body: bone positions (the hips' height, a
## fall's drop) scale with how tall they stand, and tracks for bones this
## model hasn't got are dropped. Turns carry over as they are, so a child
## bends like a grown-up, only smaller.
func _fit(a: Animation, donor_hips: float) -> void:
	if _skel == null:
		return
	var k := _hips / maxf(donor_hips, 0.01)
	for t in range(a.get_track_count() - 1, -1, -1):
		var bone := String(a.track_get_path(t).get_concatenated_subnames())
		if bone != "" and _skel.find_bone(bone) < 0:
			a.remove_track(t)
			continue
		if a.track_get_type(t) == Animation.TYPE_POSITION_3D and absf(k - 1.0) > 0.005:
			for i in a.track_get_key_count(t):
				a.track_set_key_value(t, i, (a.track_get_key_value(t, i) as Vector3) * k)


## A donor's clip and its hip height ({} when it hasn't that clip).
static func _donor_clip(donor: String, clip: String) -> Dictionary:
	var key := donor + ":" + clip
	if _donor_cache.has(key):
		return _donor_cache[key]
	var path := DIR + donor + ".glb"
	var out := {}
	if ResourceLoader.exists(path):
		var inst: Node = (load(path) as PackedScene).instantiate()
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var sk := inst.find_child("Skeleton3D", true, false) as Skeleton3D
		if ap != null and ap.has_animation(clip):
			var hips := ADULT_HIPS
			if sk != null and sk.find_bone("Hips") >= 0:
				hips = sk.get_bone_rest(sk.find_bone("Hips")).origin.y
			out = {"clip": ap.get_animation(clip).duplicate(true), "hips": hips}
		inst.free()
	_donor_cache[key] = out
	return out


# ------------------------------------------------------------------ hands ---

## Puts their hands on things: each hand goes to its target (a Node3D, and
## follows it if it moves; null leaves that hand to the clip), blending in
## over `secs`, elbows out and down. Holding a barrel by its rims, a card
## held out in both hands, a hand held. let_go() gives the arms back.
func reach(left: Node3D, right: Node3D, secs := 0.3) -> void:
	_reach("left", left, secs)
	_reach("right", right, secs)


func let_go(secs := 0.3) -> void:
	_reach("left", null, secs)
	_reach("right", null, secs)


## Something held in front of them that turns as they turn (a card held out
## in both hands, a pitchfork levelled, a hand to hold): `at` is in their
## own frame, x to their left, y up, z ahead. reach() puts the hands on it.
func carry(node: Node3D, at: Vector3) -> Node3D:
	if node.get_parent() != null:
		node.reparent(_pivot, false)
	else:
		_pivot.add_child(node)
	node.position = at
	return node


## Their own frame turned into the world: a point `at` (x to their left, y
## up, z ahead) where it is now.
func to_world(at: Vector3) -> Vector3:
	return global_transform * (Basis(Vector3.UP, _yaw) * at)


## How tall they stand, as a fraction of a grown-up (Tilly about 0.7).
func stature() -> float:
	return _hips / ADULT_HIPS


## Is a hand reaching for something?
func reaching(side := "") -> bool:
	for s in (["left", "right"] if side == "" else [side]):
		var ik = _ik.get(s)
		if ik != null and is_instance_valid(ik) and (ik as TwoBoneIK3D).active:
			return true
	return false


func _reach(side: String, target: Node3D, secs: float) -> void:
	if _skel == null or not is_inside_tree():
		return
	var ik: TwoBoneIK3D = _ik.get(side)
	if ik != null and not is_instance_valid(ik):
		ik = null
	if ik != null and ik.has_meta("tween"):
		var old = ik.get_meta("tween")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	if target == null:
		if ik != null and ik.active:
			var off := create_tween()
			off.tween_property(ik, "influence", 0.0, maxf(secs, 0.01))
			off.tween_callback(func() -> void: ik.active = false)
			ik.set_meta("tween", off)
		return
	var pre := "Left" if side == "left" else "Right"
	if ik == null:
		if not _skel.has_node("KeepTargets"):
			var kt := KeepTargets.new()
			kt.name = "KeepTargets"
			kt.fig = self
			_skel.add_child(kt)
			_skel.move_child(kt, 0)   # (before the hands: modifiers run in order)
		ik = TwoBoneIK3D.new()
		ik.name = pre + "Reach"
		ik.setting_count = 1
		ik.set_root_bone_name(0, pre + "Arm")
		ik.set_middle_bone_name(0, pre + "ForeArm")
		ik.set_end_bone_name(0, pre + "Hand")
		# reach with the palm, not the wrist
		ik.set_extend_end_bone(0, true)
		ik.set_end_bone_direction(0, SkeletonModifier3D.BONE_DIRECTION_FROM_PARENT)
		ik.set_end_bone_length(0, 0.075 * _hips / ADULT_HIPS)
		ik.influence = 0.0
		_skel.add_child(ik)
		# the elbow bends towards this: out to their side, down and back
		var pole := Node3D.new()
		pole.name = pre + "Elbow"
		var s := _hips / ADULT_HIPS
		pole.position = Vector3((0.55 if side == "left" else -0.55) * s, 0.75 * s, -0.55 * s)
		_pivot.add_child(pole)
		ik.set_pole_node(0, ik.get_path_to(pole))
		_ik[side] = ik
	ik.set_target_node(0, ik.get_path_to(target))
	ik.set_meta("target", target)   # (followed if it's moved elsewhere: _keep_targets)
	ik.active = true
	var on := create_tween()
	on.tween_property(ik, "influence", 1.0, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)
	ik.set_meta("tween", on)
