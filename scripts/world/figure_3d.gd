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
## Solhaven's gate warden wears the Sun Guard's; Ned, the fiddler, has his own
## since 26 October, ned.glb). The player's is player_<look>.glb for the look chosen
## in the mirror (model_file()). Everyone else's model is characters/<their
## id or look>.glb (hob, krell, dask, hunter), picked up the moment it exists.
## (The third child look, "child", the blonde cut-out that was Tilly's and
## Pip's and the third child's on the green, plays Gary's boy, child_b, so no
## cartoon child stands among the 3D ones: Tilly has her own model, and Pip
## will when his comes, pip.glb.)
const MODELS := {"player": "player_a", "gate_warden": "sun_guard", "child": "child_b",
	# Master Script v7 (24 October): the hero is Player A in every scene and
	# film, and Gary's other three looks play people instead: Player B is
	# Dask, Player C is Wren, Player D is Ironvault's hunters and enforcers
	# (until their own models come). Tilly is the brown-skinned girl he made
	# (child_c); her first, blonde model is a girl in the crowd ("girl").
	"dask": "player_b", "wren": "player_c", "hunter": "player_d", "enforcer": "player_d",
	"tilly": "child_c", "girl": "tilly"}
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
## tools/rig_character.py measured them), not GAIT_SPEED's. (Corin's own
## walk and run since 20 October, from his single-clip files; Hob's since 19
## October; looks B, C and D, Gary's Player B, C and D models, since 20
## October, built by tools/rig_player.sh.)
const OWN_GAIT := {
	"player_a": {"walk": 1.71, "run": 4.33, "sneak": 0.87},
	"player_b": {"walk": 1.66, "run": 4.22, "sneak": 0.85},
	"player_c": {"walk": 1.62, "run": 4.10, "sneak": 0.83},
	"player_d": {"walk": 1.75, "run": 4.44, "sneak": 0.90},
	"corin": {"walk": 1.70, "run": 4.32},
	"bram": {"walk": 1.69, "run": 4.30},
	"hob": {"walk": 1.85, "run": 4.70, "sneak": 0.95},
	# Ned walks and runs on the player's clips, fitted to his height
	"ned": {"walk": 1.67, "run": 4.23, "sneak": 0.85},
	"tam": {"walk": 1.63, "run": 4.12},
	"tilly": {"walk": 1.00, "run": 2.54},
	"nell": {"walk": 1.11, "run": 2.81},
	# the crowd's looks (22 October: the farmer and the trader on Player B's
	# clips, the merchant on Tam's 34-joint library)
	"farmer": {"walk": 1.70, "run": 4.30, "sneak": 0.87},
	"merchant": {"walk": 1.43, "run": 3.63, "sneak": 0.92},
	"trader": {"walk": 1.77, "run": 4.48, "sneak": 0.90},
	# the elder and the two children (23 October, Gary's New Characters 04,
	# 05 and 06 on the player's clips; the children's short legs take the
	# same steps at a child's pace)
	"elder": {"walk": 1.66, "run": 4.20},
	"child_b": {"walk": 1.15, "run": 2.90},
	"child_c": {"walk": 0.70, "run": 1.77},
	# Gary's 27 October three: Corin's mam, Huntmaster Krell and the refugee
	# woman (the travel-worn woman), each on her own 21 clips
	"corin_mam": {"walk": 1.70, "run": 4.30},
	"krell": {"walk": 1.56, "run": 3.95},
	"refugee": {"walk": 1.58, "run": 4.00},
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
## Lying on a bed (lie_on): how far the body tips up from flat at the head
## end, onto the pillow, and how far the feet drop from standing square.
const LIE_HEAD_UP := deg_to_rad(13.0)
const LIE_FOOT_DROP := deg_to_rad(55.0)

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
## How they sit: "" on a seat's edge with the feet down (a bench), "long"
## with the legs out along it (sat up in bed), "lying" flat on their back.
var _seat_pose := ""
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
var _shoulder := 1.4     # their shoulder joints' height standing (m)
var _arm := 0.5          # shoulder to wrist, the arm straight (m)
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


## A model with its own normal map beside it (<model>_normal.png: the fine
## shape Gary's model was made with, its nostrils, eyelids and folds) wears
## it through assets/shaders/character_nm.gdshader in place of the model's
## StandardMaterial3D (its colour and metal-roughness textures kept). The
## shader works out the normal map's frame per pixel: on the Compatibility
## renderer (the phone link) a rigged model's tangents come out of Godot's
## skinning mangled, and StandardMaterial3D's normal map lit him in patches
## (29 October: Player A's head as Gary made it).
static var _nm_mats := {}


static func dress_normal_map(m: Node3D, model_name: String) -> void:
	var npath := DIR + model_name + "_normal.png"
	if not ResourceLoader.exists(npath):
		return
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		for si in mi.mesh.get_surface_count():
			var src := mi.get_active_material(si)
			if not (src is StandardMaterial3D):
				continue
			var key := "%s:%d" % [model_name, src.get_instance_id()]
			if not _nm_mats.has(key):
				var std := src as StandardMaterial3D
				var sm := ShaderMaterial.new()
				sm.shader = load("res://assets/shaders/character_nm.gdshader")
				sm.set_shader_parameter("albedo_tex", std.albedo_texture)
				sm.set_shader_parameter("mr_tex", std.roughness_texture if std.roughness_texture != null else std.metallic_texture)
				sm.set_shader_parameter("normal_tex", load(npath))
				sm.set_shader_parameter("metallic_k", std.metallic)
				sm.set_shader_parameter("roughness_k", std.roughness)
				_nm_mats[key] = sm
			mi.set_surface_override_material(si, _nm_mats[key])


## The model file (without .glb) that plays a look or id. The player's is
## Player A (Master Script v7: one hero, so the films can be made round him;
## DollArt.player_look() says "a" whatever an older save's "look" flag holds).
static func model_file(look: String) -> String:
	if look == "player":
		var l := "player_" + DollArt.player_look()
		if ResourceLoader.exists(DIR + l + ".glb"):
			return l
		return "player_a"
	return String(MODELS.get(look, look))


## True when this look has a 3D model to play it.
static func has_model(look: String) -> bool:
	return ResourceLoader.exists(DIR + model_file(look) + ".glb")


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
	_model_name = model_file(char_id)
	var path := DIR + _model_name + ".glb"
	model = (load(path) as PackedScene).instantiate()
	dress_normal_map(model, _model_name)
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
		var sa := _skel.find_bone("LeftArm")
		var fa := _skel.find_bone("LeftForeArm")
		var ha := _skel.find_bone("LeftHand")
		if sa >= 0 and fa >= 0 and ha >= 0:
			var a := _skel.get_bone_global_rest(sa).origin
			var e := _skel.get_bone_global_rest(fa).origin
			_shoulder = a.y
			_arm = a.distance_to(e) + e.distance_to(_skel.get_bone_global_rest(ha).origin)
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
	await get_tree().create_timer(maxf(0.05, a.length / maxf(speed, 0.01) - blend * 0.5), false).timeout
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
	await get_tree().create_timer(blend, false).timeout
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
	await get_tree().create_timer(maxf(0.05, left - 0.25), false).timeout
	if _action == clip:
		release(0.3)


## Plays `clip` once through to its end and holds its last pose, with its
## root motion taken off the body and given to them as a whole: the Hips'
## travel along the ground moves the node they stand in, and the way the
## Hips turn about the upright turns them, so when the clip lets go they're
## standing where and the way it ended instead of snapping back to the spot.
## `mirror` plays it left for right (getting out of a bed on the other side).
## `extra` (seconds into the clip -> a world offset) moves them besides: up
## onto a bed higher than the one the clip was made on, along it to the edge.
## Made for Hob's get_out_of_bed on Player A (27 October, Gary: getting out
## of bed looked weird, with the pose-built rise).
func play_rooted(clip: String, mirror := false, speed := 1.0, extra := Callable(), blend := 0.3) -> void:
	if not _ensure(clip):
		return
	var nm := "rooted_%s%s" % [clip, "_m" if mirror else ""]
	if not anim.has_animation(nm):
		var a := (anim.get_animation(clip) as Animation).duplicate(true) as Animation
		a.loop_mode = Animation.LOOP_NONE
		if mirror:
			for t in a.get_track_count():
				var p := a.track_get_path(t)
				var bone := String(p.get_concatenated_subnames())
				if bone == "":
					continue
				var other := bone
				if bone.begins_with("Left"):
					other = "Right" + bone.trim_prefix("Left")
				elif bone.begins_with("Right"):
					other = "Left" + bone.trim_prefix("Right")
				a.track_set_path(t, NodePath(String(p.get_concatenated_names()) + ":" + other))
				for k in a.track_get_key_count(t):
					match a.track_get_type(t):
						Animation.TYPE_ROTATION_3D:
							var q: Quaternion = a.track_get_key_value(t, k)
							a.track_set_key_value(t, k, Quaternion(q.x, -q.y, -q.z, q.w))
						Animation.TYPE_POSITION_3D:
							var v: Vector3 = a.track_get_key_value(t, k)
							a.track_set_key_value(t, k, Vector3(-v.x, v.y, v.z))
		# the Hips' ground travel and turn, into lists, and out of the clip
		var rt := PackedFloat32Array()
		var rd := PackedVector3Array()
		var yt := PackedFloat32Array()
		var yv := PackedFloat32Array()
		for t in a.get_track_count():
			if String(a.track_get_path(t).get_concatenated_subnames()) != "Hips":
				continue
			match a.track_get_type(t):
				Animation.TYPE_POSITION_3D:
					var v0: Vector3 = a.track_get_key_value(t, 0)
					for k in a.track_get_key_count(t):
						var v: Vector3 = a.track_get_key_value(t, k)
						rt.append(a.track_get_key_time(t, k))
						rd.append(Vector3(v.x - v0.x, 0.0, v.z - v0.z))
						a.track_set_key_value(t, k, Vector3(v0.x, v.y, v0.z))
				Animation.TYPE_ROTATION_3D:
					var last := 0.0
					for k in a.track_get_key_count(t):
						var q: Quaternion = a.track_get_key_value(t, k)
						# the turn about the upright, read off the line across the
						# hips (level whether they lie, sit or stand)
						var side := q * Vector3.RIGHT
						var th := atan2(-side.z, side.x)
						th = last + wrapf(th - last, -PI, PI)   # (no jumps of a whole turn)
						last = th
						yt.append(a.track_get_key_time(t, k))
						yv.append(th)
						a.track_set_key_value(t, k, Quaternion(Vector3.UP, -th) * q)
		a.set_meta("root_t", rt)
		a.set_meta("root_d", rd)
		a.set_meta("yaw_t", yt)
		a.set_meta("yaw_v", yv)
		if not anim.has_animation_library(""):
			anim.add_animation_library("", AnimationLibrary.new())
		anim.get_animation_library("").add_animation(nm, a)
	seat = -1.0
	_seat_pose = ""
	_action = nm
	_held = true
	var an := anim.get_animation(nm)
	var mover: Node3D = get_parent() as Node3D if get_parent() is Node3D else self
	var start := mover.global_position
	var yaw0 := _yaw
	var rt: PackedFloat32Array = an.get_meta("root_t")
	var rd: PackedVector3Array = an.get_meta("root_d")
	var yt: PackedFloat32Array = an.get_meta("yaw_t")
	var yv: PackedFloat32Array = an.get_meta("yaw_v")
	var at := func(t: float) -> void:
		var d := Vector3.ZERO
		if rt.size() > 0:
			var i := clampi(rt.bsearch(t), 1, maxi(1, rt.size() - 1))
			var u := clampf((t - rt[i - 1]) / maxf(rt[i] - rt[i - 1], 0.0001), 0.0, 1.0) if rt.size() > 1 else 0.0
			d = rd[i - 1].lerp(rd[mini(i, rd.size() - 1)], u)
		var th := 0.0
		if yt.size() > 0:
			var j := clampi(yt.bsearch(t), 1, maxi(1, yt.size() - 1))
			var w := clampf((t - yt[j - 1]) / maxf(yt[j] - yt[j - 1], 0.0001), 0.0, 1.0) if yt.size() > 1 else 0.0
			th = lerpf(yv[j - 1], yv[mini(j, yv.size() - 1)], w)
		_yaw = yaw0 + th
		_want_yaw = _yaw
		var off := Basis(Vector3.UP, yaw0) * d
		if extra.is_valid():
			off += extra.call(t)
		mover.global_position = start + off
	_play(nm, blend, speed)
	var t := 0.0
	while _action == nm and anim.current_animation == nm and t < an.length - 0.001:
		at.call(t)
		await get_tree().process_frame
		if anim.current_animation == nm:
			t = anim.current_animation_position
	if _action == nm:
		at.call(an.length)


## Beaten: the head drops, the back rounds and the shoulders fall forward,
## eased into over `blend` seconds and held (over their idle, so they still
## breathe) until release(). `amount` 1 is a hard loss. For Corin after the
## Lantern Duel (27 October, Gary: with the recoil and the near-standing
## `defeat` clip he looked "more scared than defeated").
const SLUMP := {"Spine": Vector3(4, 0, 0), "Spine1": Vector3(6, 0, 0), "Spine2": Vector3(7, 0, 0),
	"Neck": Vector3(9, 0, 0), "Head": Vector3(19, 0, 0),
	"LeftShoulder": Vector3(0, -7, -6), "RightShoulder": Vector3(0, 7, 6)}

func slump(amount := 1.0, blend := 1.0) -> void:
	if anim == null or not anim.has_animation("idle"):
		return
	var nm := "slump_%d" % roundi(amount * 100.0)
	if not anim.has_animation(nm):
		var a := (anim.get_animation("idle") as Animation).duplicate(true) as Animation
		var prefix := ""
		var done := {}
		for t in a.get_track_count():
			var bone := String(a.track_get_path(t).get_concatenated_subnames())
			if bone == "":
				continue
			prefix = String(a.track_get_path(t).get_concatenated_names())
			if a.track_get_type(t) != Animation.TYPE_ROTATION_3D or not SLUMP.has(bone):
				continue
			var e: Vector3 = SLUMP[bone] * amount
			var extra := Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z)))
			for k in a.track_get_key_count(t):
				a.track_set_key_value(t, k, extra * (a.track_get_key_value(t, k) as Quaternion))
			done[bone] = true
		# a bone the idle doesn't move: a track of its own, at rest plus the slump
		for bone: String in SLUMP:
			if done.has(bone) or _skel == null or _skel.find_bone(bone) < 0 or prefix == "":
				continue
			var e: Vector3 = SLUMP[bone] * amount
			var t := a.add_track(Animation.TYPE_ROTATION_3D)
			a.track_set_path(t, NodePath(prefix + ":" + bone))
			var q := Quaternion.from_euler(Vector3(deg_to_rad(e.x), deg_to_rad(e.y), deg_to_rad(e.z))) * _skel.get_bone_rest(_skel.find_bone(bone)).basis.get_rotation_quaternion()
			a.rotation_track_insert_key(t, 0.0, q)
			a.rotation_track_insert_key(t, a.length, q)
		a.loop_mode = Animation.LOOP_LINEAR
		if not anim.has_animation_library(""):
			anim.add_animation_library("", AnimationLibrary.new())
		anim.get_animation_library("").add_animation(nm, a)
	_action = nm
	_held = true
	_play(nm, blend)


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
	_seat_pose = ""
	_sit_as(height, blend)


## Sat up on a bed `height` m off the ground with the legs out along it,
## the way they face: hips over the spot, feet a leg's length ahead.
func sit_long(height := 0.5, blend := 0.8) -> void:
	_seat_pose = "long"
	_sit_as(height, blend)


## Flat on their back on a bed `height` m off the ground: hips over the
## spot, head behind it (the way they face is the way their feet point).
## Blends from, and into, sit_long() and sit(): lie_on then sit_long is
## sitting up in bed; sit() facing the bed's side swings the legs over it.
func lie_on(height := 0.5, blend := 0.8) -> void:
	_seat_pose = "lying"
	_sit_as(height, blend)


func _sit_as(height: float, blend: float) -> void:
	seat = maxf(height, 0.0)
	_seat_at = global_position
	_seat_settle = 2
	_action = ""
	_held = false
	_play(_base(), blend)


## Moves them while they sit (swinging round to the bed's edge): the seat
## comes with them, so it's not taken for walking off. `face_dir` is the
## way to end up facing (a world direction), turned to over the move. What
## moves is their body (the node they stand in), as walking moves it.
## `lift` raises the hips on the way (m, most at the middle), clear of
## what they slide over.
func shift_seat(to: Vector3, face_dir: Vector3, secs := 0.9, lift := 0.0) -> void:
	var mover: Node3D = get_parent() as Node3D if get_parent() is Node3D else self
	var from := mover.global_position
	var y0 := _yaw
	face_dir.y = 0.0
	var y1 := y0
	if face_dir.length() > 0.001:
		y1 = y0 + wrapf(atan2(face_dir.x, face_dir.z) - y0, -PI, PI)
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		mover.global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * lift, 0)
		_seat_at = global_position
		_yaw = lerpf(y0, y1, k)
		_want_yaw = _yaw, 0.0, 1.0, secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


func stand(blend := 0.6) -> void:
	seat = -1.0
	_seat_pose = ""
	_action = ""
	_held = false
	if not _stick.is_empty():
		plant_stick(Vector3.INF, blend)
	_play(_base(), blend)


## The sitting version of a clip (built the first time it's asked for, for
## this seat), or the clip itself when they're standing or it can't be sat.
func _sat(clip: String) -> String:
	if seat >= 0.0 and clip in STANDING_ONLY:
		seat = -1.0   # (it stands them up)
	if seat < 0.0 or clip.begins_with("sat_") or _skel == null or anim == null or not anim.has_animation(clip):
		return clip
	var nm := "sat_%s_%d%s" % [clip, roundi(seat * 100.0), "" if _seat_pose == "" else "_" + _seat_pose]
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
	if _seat_pose == "lying":
		# on their back: the body tipped back about the hips, not quite flat
		# (the head and shoulders up on the pillow, LIE_HEAD_UP), the legs
		# straight and flat along the bed, the feet lolling the way they do
		# when someone's asleep rather than standing up off the mattress
		rot["Hips"] = Quaternion(Vector3.RIGHT, -PI * 0.5 + LIE_HEAD_UP)
		for side in ["Left", "Right"]:
			for b in ["UpLeg", "Leg", "Foot", "ToeBase"]:
				if _skel.find_bone(side + b) >= 0:
					rot[side + b] = Quaternion.IDENTITY
			if _skel.find_bone(side + "UpLeg") >= 0:
				rot[side + "UpLeg"] = Quaternion(Vector3.RIGHT, -LIE_HEAD_UP)
			if _skel.find_bone(side + "Foot") >= 0:
				rot[side + "Foot"] = Quaternion(Vector3.RIGHT, LIE_FOOT_DROP)
		return {"pos": pos, "rot": rot}
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
		if _seat_pose == "long":
			# legs out along the bed, the knees a touch up
			t_dir = Vector3(side_x, 0.1, sqrt(1.0 - 0.01 - side_x * side_x))
			s_dir = Vector3(0.0, -0.1, sqrt(0.99))
		var gu := Quaternion(thigh / lt, t_dir)
		var gk := Quaternion(shin / ls, s_dir)
		rot[side + "UpLeg"] = gu
		rot[side + "Leg"] = gu.inverse() * gk
		rot[side + "Foot"] = gk.inverse()   # flat
		rot[side + "ToeBase"] = Quaternion.IDENTITY
	return {"pos": pos, "rot": rot}


## A walking stick that's part of a model, bound to the right hand alone
## (tools/stick_weights.py): where its foot is in that hand bone's own frame
## (from the model's bind pose: Nell's carved stick). stick_foot() gives it
## where it is now.
const STICKS := {"nell": Vector3(-0.0625, -0.8806, -0.0928)}


## Their walking stick stood upright with its foot on `foot` (world), the
## hand on its top (29 October, Gary: "Nells stick goes through the bench
## before you sit with her": sat, her arm lay as her rest pose has it and
## the stick, rigid in her hand, ran down through the seat). Each frame,
## after the clip, the hand is turned so the stick hangs straight down from
## it and the arm bends to put its foot there, eased in over `secs`.
## Vector3.INF lets it go. (Standing up lets it go.)
func plant_stick(foot: Vector3, secs := 0.4) -> void:
	if foot == Vector3.INF:
		if _stick.is_empty():
			return
		var tw0 := create_tween()
		var from: float = _stick.k
		tw0.tween_method(func(k: float) -> void:
			if not _stick.is_empty():
				_stick.k = k, from, 0.0, maxf(secs, 0.01))
		tw0.tween_callback(func() -> void: _stick = {})
		return
	if not STICKS.has(_model_name):
		return
	_stick = {"foot": foot, "k": 0.0 if _stick.is_empty() else float(_stick.k)}
	if _skel != null and not _skel.has_node("HandsOff"):
		hands_off(_solids)
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		if not _stick.is_empty():
			_stick.k = k, float(_stick.k), 1.0, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)


var _stick := {}


func _plant_stick() -> void:
	if _stick.is_empty() or float(_stick.k) <= 0.001:
		return
	var h := _skel.find_bone("RightHand")
	var local: Vector3 = STICKS.get(_model_name, Vector3.ZERO)
	if h < 0 or local == Vector3.ZERO:
		return
	var k: float = _stick.k
	var xb := _skel.global_transform.basis.orthonormalized()
	var gp := _skel.get_bone_global_pose(h)
	var hand_w := xb * gp.basis.orthonormalized()
	var now := (hand_w * local).normalized()
	var q := Quaternion.IDENTITY.slerp(Quaternion(now, Vector3.DOWN), k)
	var want_w := Basis(q) * hand_w
	var par := _skel.get_bone_parent(h)
	var pb := _skel.get_bone_global_pose(par).basis.orthonormalized() if par >= 0 else Basis()
	_skel.set_bone_pose_rotation(h, (pb.inverse() * (xb.inverse() * want_w)).orthonormalized().get_rotation_quaternion())
	var foot_now := _skel.global_transform * (_skel.get_bone_global_pose(h) * local)
	_move_wrist("Right", ((_stick.foot as Vector3) - foot_now) * k)


## Where the foot of their walking stick is now (world), or their right
## hand's place if they have none.
func stick_foot() -> Vector3:
	var h := _skel.find_bone("RightHand") if _skel != null else -1
	if h < 0:
		return global_position
	var gp := _skel.global_transform * _skel.get_bone_global_pose(h)
	return gp * STICKS.get(_model_name, Vector3.ZERO)


## How far in front of the seat their feet are, sitting on its edge (m):
## the thigh along the seat, the shins down from the knees, a little
## forward. Standing up, that's where they stand.
func seat_feet_ahead() -> float:
	if _skel == null:
		return 0.42 * stature()
	var up := _skel.find_bone("LeftUpLeg")
	var kn := _skel.find_bone("LeftLeg")
	var ft := _skel.find_bone("LeftFoot")
	if up < 0 or kn < 0 or ft < 0:
		return 0.42 * stature()
	var thigh := _skel.get_bone_global_rest(up).origin.distance_to(_skel.get_bone_global_rest(kn).origin)
	var shin := _skel.get_bone_global_rest(kn).origin.distance_to(_skel.get_bone_global_rest(ft).origin)
	return (thigh * 0.95 + shin * sin(deg_to_rad(8.0))) * _skel.global_transform.basis.get_scale().y


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


## A hand turned to face its palm one way (palm()), after the arms are
## solved: the IK puts the hand where it's wanted but leaves it turned as
## the clip has it, so Bram's rag hand on the counter was palm up from his
## talking clip. Runs after every reach (the hands' IK is moved before it).
class HandTurn:
	extends SkeletonModifier3D
	var fig: Figure3D

	func _process_modification_with_delta(_delta: float) -> void:
		if is_instance_valid(fig):
			fig._turn_hands()


var _palms := {}   # "left"/"right": [palm direction (world), influence]


## Turns a hand so its palm faces `dir` (a world direction: Vector3.DOWN for
## a hand flat on a counter), the fingers pointing on the way the forearm
## goes, blended in over `secs`; Vector3.ZERO gives the hand back to the clip.
## `own_frame`: `dir` is in their own frame (x to their left, y up, z ahead)
## and turns as they turn (a palm facing in to hold a box from its side).
## `flat` (0..1) straightens the fingers too (towards their rest, which is straight), so a
## hand laid on a counter lies flat on it instead of curling over its edge
## (29 October, Gary: Bram "isn't rubbing the counter, he is waving his hand
## above it").
func palm(side: String, dir: Vector3, secs := 0.3, flat := 0.0, own_frame := false) -> void:
	if _skel == null:
		return
	if not _skel.has_node("HandTurn"):
		var ht := HandTurn.new()
		ht.name = "HandTurn"
		ht.fig = self
		_skel.add_child(ht)
	_skel.move_child(_skel.get_node("HandTurn"), -1)
	if _skel.has_node("HandsOff"):
		_skel.move_child(_skel.get_node("HandsOff"), -1)   # (solids come last)
	var cur: Array = _palms.get(side, [dir, 0.0, flat, own_frame])
	while cur.size() < 4:
		cur.append(0.0 if cur.size() == 2 else false)
	if dir != Vector3.ZERO:
		cur[0] = dir.normalized()
		cur[2] = flat
		cur[3] = own_frame
	_palms[side] = cur
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		if _palms.has(side):
			_palms[side][1] = k, float(cur[1]), 1.0 if dir != Vector3.ZERO else 0.0, maxf(secs, 0.01))
	if dir == Vector3.ZERO:
		tw.tween_callback(func() -> void: _palms.erase(side))


func _turn_hands() -> void:
	for side in _palms:
		var pd: Vector3 = _palms[side][0]
		var k: float = _palms[side][1]
		if (_palms[side] as Array).size() > 3 and bool(_palms[side][3]):
			pd = (global_transform.basis * (Basis(Vector3.UP, _yaw) * pd)).normalized()
		if k <= 0.001:
			continue
		var pre := "Left" if side == "left" else "Right"
		var h := _skel.find_bone(pre + "Hand")
		var m := _skel.find_bone(pre + "HandMiddle1")
		var i := _skel.find_bone(pre + "HandIndex1")
		var p := _skel.find_bone(pre + "HandPinky1")
		if p < 0:
			p = _skel.find_bone(pre + "HandRing1")
		if h < 0 or m < 0 or i < 0 or p < 0:
			continue
		# the hand's own frame as it was made (every rest is square to the
		# world): the fingers' way, and the palm's (index to pinky across)
		var r0 := _skel.get_bone_global_rest(h).origin
		var f_b := (_skel.get_bone_global_rest(m).origin - r0).normalized()
		var across := _skel.get_bone_global_rest(i).origin - _skel.get_bone_global_rest(p).origin
		var p_b := across.cross(f_b) if side == "right" else f_b.cross(across)
		p_b = (p_b - f_b * p_b.dot(f_b)).normalized()
		var gp := _skel.get_bone_global_pose(h)
		var f_now := (gp.basis * f_b).normalized()
		# wanted, in the skeleton's frame: the palm as asked, the fingers on
		# along the forearm, laid flat across the palm's way
		var to_sk := _skel.global_transform.basis.inverse()
		var p_t := (to_sk * pd).normalized()
		var f_t := f_now - p_t * f_now.dot(p_t)
		if f_t.length() < 0.05:
			continue
		f_t = f_t.normalized()
		var mb := Basis(f_b, p_b, f_b.cross(p_b)).orthonormalized()
		var mt := Basis(f_t, p_t, f_t.cross(p_t)).orthonormalized()
		var want := (mt * mb.transposed()).orthonormalized()
		var q := gp.basis.orthonormalized().get_rotation_quaternion().slerp(want.get_rotation_quaternion(), clampf(k, 0.0, 1.0))
		var par := _skel.get_bone_parent(h)
		var pb := _skel.get_bone_global_pose(par).basis.orthonormalized() if par >= 0 else Basis()
		_skel.set_bone_pose_rotation(h, (pb.inverse() * Basis(q)).get_rotation_quaternion())
		# a flat hand: the fingers back to their rest, straight (the thumb too,
		# a little, so it lies along the side of the hand)
		var flat: float = float(_palms[side][2]) if (_palms[side] as Array).size() > 2 else 0.0
		if flat > 0.0:
			for fn in ["Index", "Middle", "Ring", "Pinky", "Thumb"]:
				for j in [1, 2, 3]:
					var fb := _skel.find_bone(pre + "Hand" + fn + str(j))
					if fb < 0:
						continue
					var rr := _skel.get_bone_rest(fb).basis.get_rotation_quaternion()
					var cr := _skel.get_bone_pose_rotation(fb)
					_skel.set_bone_pose_rotation(fb, cr.slerp(rr, clampf(k * flat * (0.6 if fn == "Thumb" else 1.0), 0.0, 1.0)))


## Things their hands can't go into (29 October, Gary: when Bram talks
## behind the bar "his hands are still going onto the wood of the bar, need
## to make that a solid object"): boxes in the world (AABBs, square to the
## world). Each frame, after the clip, the hands' reaches and their turning,
## a hand (the wrist, the middle of the hand and the fingertips) found inside
## one is moved out of it the shortest way (up onto its top, or back out of
## a side), the arm bending to put it there and the hand keeping its turn,
## so a gesture that would have gone into the counter stops on it. Eased in
## and out over a few frames, so nothing jumps. [] takes them away.
func hands_off(boxes: Array) -> void:
	_solids = boxes.duplicate()
	if _skel == null:
		return
	if not _skel.has_node("HandsOff"):
		var ho := HandsOff.new()
		ho.name = "HandsOff"
		ho.fig = self
		_skel.add_child(ho)
	_skel.move_child(_skel.get_node("HandsOff"), -1)


var _solids: Array = []
var _push := {"left": Vector3.ZERO, "right": Vector3.ZERO}
## How far a hand's skin stands off its bones (m): what's kept clear of a solid.
const SKIN := 0.025


class HandsOff:
	extends SkeletonModifier3D
	var fig: Figure3D

	func _process_modification_with_delta(delta: float) -> void:
		if is_instance_valid(fig):
			fig._hands_off(delta)


## A palm held down at a height (world y): the wrist is moved, after
## everything else, so the middle of the palm is there (Bram's on the rag's
## wad: the reach alone left it a hand's depth over it once the hand was
## turned palm down). NAN lets it go.
func press(side: String, y: float) -> void:
	if is_nan(y):
		_press.erase(side)
	else:
		_press[side] = y
	if not is_nan(y) and _skel != null and not _skel.has_node("HandsOff"):
		hands_off(_solids)


var _press := {}
## Where the middle of each palm was, as last drawn (world).
var palm_seen := {}


func _palm_point(pre: String) -> Vector3:
	var xf := _skel.global_transform
	var h := _skel.find_bone(pre + "Hand")
	var w := xf * _skel.get_bone_global_pose(h).origin
	var m := _skel.find_bone(pre + "HandMiddle1")
	if m < 0:
		return w
	return (w + xf * _skel.get_bone_global_pose(m).origin) * 0.5


func _hands_off(delta: float) -> void:
	for side in _press:
		var pre := "Left" if side == "left" else "Right"
		if _skel.find_bone(pre + "Hand") < 0:
			continue
		var dy: float = float(_press[side]) - _palm_point(pre).y
		if absf(dy) > 0.002:
			_move_wrist(pre, Vector3(0, dy, 0))
	for side in ["left", "right"]:
		var pre := "Left" if side == "left" else "Right"
		if _skel.find_bone(pre + "Hand") >= 0:
			palm_seen[side] = _palm_point(pre)
	if _solids.is_empty():
		_push = {"left": Vector3.ZERO, "right": Vector3.ZERO}
	else:
		_keep_out_of_solids(delta)
	_plant_stick()
	_apply_grip()
	_place_held()


func _keep_out_of_solids(delta: float) -> void:
	var xf := _skel.global_transform
	for side in ["left", "right"]:
		var pre := "Left" if side == "left" else "Right"
		var h := _skel.find_bone(pre + "Hand")
		var fa := _skel.find_bone(pre + "ForeArm")
		if h < 0 or fa < 0:
			continue
		var w := xf * _skel.get_bone_global_pose(h).origin
		var e := xf * _skel.get_bone_global_pose(fa).origin
		var pts := [w]
		var tip := -1
		for fn in ["HandMiddle3", "HandMiddle2", "HandMiddle1", "HandIndex3", "HandIndex1"]:
			tip = _skel.find_bone(pre + fn)
			if tip >= 0:
				break
		if tip >= 0:
			var tp := xf * _skel.get_bone_global_pose(tip).origin
			var par := _skel.get_bone_parent(tip)
			var pp := xf * _skel.get_bone_global_pose(par).origin
			tp += (tp - pp).normalized() * 0.02 * stature()   # (past the last joint: the fingertip)
			pts.append(tp)
			pts.append((w + tp) * 0.5)
			# and every knuckle (a curled hand's lowest point is one of them)
			for fn in ["HandIndex1", "HandIndex2", "HandMiddle1", "HandMiddle2", "HandMiddle3", "HandRing1", "HandPinky1", "HandPinky2", "HandThumb2", "HandThumb3"]:
				var fb := _skel.find_bone(pre + fn)
				if fb >= 0:
					pts.append(xf * _skel.get_bone_global_pose(fb).origin)
		else:
			var hd := (w - e).normalized()
			pts.append(w + hd * 0.16 * stature())
			pts.append(w + hd * 0.08 * stature())
		if _press.has(side):
			# a palm held down on something (a rag on the counter): only its
			# wrist and palm are kept out, a little closer; its curled
			# fingers are round what it holds
			pts = [w, _palm_point(pre)]
		var need := Vector3.ZERO
		for b in _solids:
			var box: AABB = (b as AABB).grow(SKIN * (0.6 if _press.has(side) else 1.0))
			var inside := false
			for p in pts:
				if box.has_point(p):
					inside = true
					break
			if not inside:
				continue
			# the way out: up onto the top when the wrist is up at its top (a
			# hand coming down on the counter stops on it), else out of the
			# nearest side (a hand hanging beside it); one way for all three
			# points, so it never ends up between two ways and still in it
			var ways := [Vector3.UP] if w.y > box.end.y - 0.12 else [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]
			var best := Vector3.ZERO
			var best_len := INF
			for d in ways:
				var face: float = (box.end if (d.x + d.y + d.z) > 0.0 else box.position).dot(d.abs()) * (d.x + d.y + d.z)
				var push := 0.0
				for p in pts:
					if box.has_point(p):
						push = maxf(push, face - (p as Vector3).dot(d))
				if push < best_len:
					best_len = push
					best = d * push
			if best.length() > need.length():
				need = best
		var cur: Vector3 = _push[side]
		# in quickly (a frame or two), out more gently; a new way out at once
		if need.length() > 0.001 and cur.length() > 0.001 and need.normalized().dot(cur.normalized()) < 0.9:
			cur = need
		var rate := 30.0 if need.length() > cur.length() else 8.0
		cur = cur.lerp(need, 1.0 - exp(-delta * rate)) if delta > 0.0 else need
		if need.length() - cur.length() > 0.012:
			cur = need   # (never left more than a finger's width in it)
		_push[side] = cur
		if cur.length() > 0.001:
			_move_wrist(pre, cur)
			palm_seen[side] = _palm_point(pre)


# ------------------------------------------------------------- held things ---

## Something held for real (29 October, Gary: Bram's card box "is still not
## in brams hand is floating between them can't you add mechanics so it
## actually fixes it"): every frame, once the hands are where they end up
## (the clip, the reaches, the turns, the solids), the thing is put where
## the hands are, so it can't be anywhere but in them:
##   "palm":    resting on one hand's palm (`side`), its up the way the palm
##              faces, `lift` over the palm's skin (half its height), its
##              front the way they face, turned `turn` about its up;
##   "between": between the two palms, its x from the right palm to the
##              left, its up the world's, `lift` up from their middle.
## Until 29 October a held thing was put at a point in front of them and
## the hands reached for it, and where an arm fell short of the point it
## hung in the air. detach() lets it go where it is.
## `gap` (between): how far apart the palms are kept, its width (the arms
## are bent to put each palm on its side, whatever the reach left them).
func attach(node: Node3D, mode := "palm", side := "right", lift := 0.0, turn := 0.0, gap := 0.0) -> void:
	_in_hands = {"node": node, "mode": mode, "side": side, "lift": lift, "turn": turn, "gap": gap}
	if _skel != null and not _skel.has_node("HandsOff"):
		hands_off(_solids)


func detach(node: Node3D = null) -> void:
	if node == null or (_in_hands.has("node") and _in_hands.node == node):
		_in_hands = {}


## What they hold for real (attach()), or null.
func holding() -> Node3D:
	if _in_hands.has("node") and is_instance_valid(_in_hands.node):
		return _in_hands.node
	return null


var _in_hands := {}
## Hands on the two sides of something they don't hold yet (grip()).
var _grip := {}


## Puts their palms on the two sides of `node` (its x axis, `gap` apart),
## without moving it, eased in over `secs`: taking a box someone else still
## holds, the hands land on it rather than about it. null lets go.
func grip(node: Node3D, gap := 0.0, secs := 0.3) -> void:
	if node == null:
		_grip = {}
		return
	_grip = {"node": node, "gap": gap, "k": 0.0}
	if _skel != null and not _skel.has_node("HandsOff"):
		hands_off(_solids)
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		if not _grip.is_empty():
			_grip.k = k, 0.0, 1.0, maxf(secs, 0.01)).set_trans(Tween.TRANS_SINE)


func _apply_grip() -> void:
	if _grip.is_empty():
		return
	var n = _grip.node
	if not is_instance_valid(n) or not (n as Node3D).is_inside_tree():
		_grip = {}
		return
	var xf := (n as Node3D).global_transform
	var half: float = float(_grip.gap) * 0.5
	var k: float = _grip.k
	# (their left hand to the side on their left)
	var a := xf * Vector3(half, 0, 0)
	var b := xf * Vector3(-half, 0, 0)
	var l := palm_frame("left").origin
	if l.distance_to(a) > l.distance_to(b):
		var t := a
		a = b
		b = t
	_move_wrist("Left", (a - l) * k)
	_move_wrist("Right", (b - palm_frame("right").origin) * k)
## How the held thing was last put (the tests read it: the skeleton's poses
## are put back once it's drawn, so the hands can't be read afterwards).
var last_hold := {}


func _place_held() -> void:
	if _in_hands.is_empty():
		return
	var n = _in_hands.node
	if not is_instance_valid(n) or not (n as Node3D).is_inside_tree():
		_in_hands = {}
		return
	var node := n as Node3D
	var lift: float = _in_hands.lift
	if String(_in_hands.mode) == "between":
		var l := palm_frame("left")
		var r := palm_frame("right")
		var x := l.origin - r.origin
		if x.length() < 0.01:
			return
		var gap: float = float(_in_hands.get("gap", 0.0))
		if gap > 0.0:
			# each palm onto its side of it: the arms bend to put them there
			var mid := (l.origin + r.origin) * 0.5
			var xn := x.normalized()
			_move_wrist("Left", mid + xn * gap * 0.5 - l.origin)
			_move_wrist("Right", mid - xn * gap * 0.5 - r.origin)
			l = palm_frame("left")
			r = palm_frame("right")
			x = l.origin - r.origin
		last_hold = {"apart": x.length(), "left": l.origin, "right": r.origin}
		x = x.normalized()
		var up := (Vector3.UP - x * Vector3.UP.dot(x)).normalized()
		node.global_transform = Transform3D(Basis(x, up, x.cross(up)).orthonormalized(), (l.origin + r.origin) * 0.5 + up * lift)
	else:
		# on the palm, its up the palm's way out, its front the way they
		# face (not the fingers': they point in across the body), turned
		var f := palm_frame(String(_in_hands.side))
		var up := f.basis.y
		var ahead := global_transform.basis * (Basis(Vector3.UP, _yaw) * Vector3.BACK)
		var z := ahead - up * ahead.dot(up)
		if z.length() < 0.05:
			z = f.basis.z
		z = z.normalized()
		var b := Basis(up.cross(z), up, z) * Basis(Vector3.UP, float(_in_hands.turn))
		node.global_transform = Transform3D(b.orthonormalized(), f.origin + up * lift)
		last_hold = {"palm": f.origin, "up": up}


## A palm, as drawn this frame (world): its origin on the palm's skin at its
## middle, its y the way the palm faces, its z the way the fingers point,
## its x across the hand. A hand without finger bones gives the hand bone's
## own turn, from a little past the wrist.
func palm_frame(side: String) -> Transform3D:
	var pre := "Left" if side == "left" else "Right"
	var xf := _skel.global_transform
	var h := _skel.find_bone(pre + "Hand")
	if h < 0:
		return Transform3D(global_transform.basis, global_position + Vector3(0, 1.0, 0))
	var gp := _skel.get_bone_global_pose(h)
	var m := _skel.find_bone(pre + "HandMiddle1")
	var i := _skel.find_bone(pre + "HandIndex1")
	var p := _skel.find_bone(pre + "HandPinky1")
	if p < 0:
		p = _skel.find_bone(pre + "HandRing1")
	if m < 0 or i < 0 or p < 0:
		var fb := (gp.basis * Vector3.DOWN)
		var o := xf * (gp.origin + fb * 0.06 * stature())
		return Transform3D((xf.basis * gp.basis).orthonormalized(), o)
	var r0 := _skel.get_bone_global_rest(h).origin
	var f_b := _skel.get_bone_global_rest(m).origin - r0
	var plen := f_b.length()
	f_b = f_b.normalized()
	var across := _skel.get_bone_global_rest(i).origin - _skel.get_bone_global_rest(p).origin
	var p_b := across.cross(f_b) if side == "right" else f_b.cross(across)
	p_b = (p_b - f_b * p_b.dot(f_b)).normalized()
	var fw := (xf.basis * (gp.basis * f_b)).normalized()
	var nw := (xf.basis * (gp.basis * p_b)).normalized()
	nw = (nw - fw * nw.dot(fw)).normalized()
	var o := xf * (gp.origin + gp.basis * (f_b * plen * 0.6)) + nw * SKIN * 0.6 * stature()
	return Transform3D(Basis(nw.cross(fw), nw, fw).orthonormalized(), o)


## Moves a hand by `by` (world) with its arm: the upper arm and forearm turn
## (two-bone, the elbow kept bending the way it was), the hand keeps its turn.
func _move_wrist(pre: String, by: Vector3) -> void:
	var a := _skel.find_bone(pre + "Arm")
	var f := _skel.find_bone(pre + "ForeArm")
	var h := _skel.find_bone(pre + "Hand")
	if a < 0 or f < 0 or h < 0:
		return
	var d := _skel.global_transform.basis.inverse() * by
	var ga := _skel.get_bone_global_pose(a)
	var gf := _skel.get_bone_global_pose(f)
	var gh := _skel.get_bone_global_pose(h)
	var S := ga.origin
	var E := gf.origin
	var W := gh.origin
	var l1 := S.distance_to(E)
	var l2 := E.distance_to(W)
	var T := W + d
	var st := T - S
	if st.length() < 0.001 or l1 < 0.001 or l2 < 0.001:
		return
	var dist := clampf(st.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := st.normalized()
	var bend := (E - S) - dir * (E - S).dot(dir)
	if bend.length() < 0.0001:
		bend = Vector3.DOWN - dir * Vector3.DOWN.dot(dir)
	bend = bend.normalized()
	var x := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var E2 := S + dir * x + bend * sqrt(maxf(0.0, l1 * l1 - x * x))
	var q1 := Quaternion((E - S).normalized(), (E2 - S).normalized())
	var W1 := S + q1 * (W - S)
	var q2 := Quaternion((W1 - E2).normalized(), (S + dir * dist - E2).normalized())
	var ba := Basis(q1) * ga.basis.orthonormalized()
	var bf := Basis(q2) * Basis(q1) * gf.basis.orthonormalized()
	var pa := _skel.get_bone_parent(a)
	var bp := _skel.get_bone_global_pose(pa).basis.orthonormalized() if pa >= 0 else Basis()
	_skel.set_bone_pose_rotation(a, (bp.inverse() * ba).orthonormalized().get_rotation_quaternion())
	_skel.set_bone_pose_rotation(f, (ba.inverse() * bf).orthonormalized().get_rotation_quaternion())
	_skel.set_bone_pose_rotation(h, (bf.inverse() * gh.basis.orthonormalized()).orthonormalized().get_rotation_quaternion())


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


## Where something small is held in both hands in front of them (a card
## box, a card), in their own frame: a little under the shoulders and a
## forearm's length ahead, so the elbows stay bent whoever holds it. Fixed
## heights from the feet don't do: Bram's arms are short for his height, and
## the box held at a grown-up's waist hung a hand's length beyond his
## reach (Gary, 28 October: "Bram's card box is just floating, it's not in
## his hands"). `ahead` and `below` are fractions of the arm's length.
func hold_point(ahead := 0.45, below := 0.55) -> Vector3:
	return Vector3(0.0, _shoulder - _arm * below, _arm * ahead)


## How far their hands reach from the shoulder (m), the arm straight.
func arm_reach() -> float:
	return _arm


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
		if _skel.has_node("HandTurn"):
			_skel.move_child(_skel.get_node("HandTurn"), -1)   # (after the hands)
		if _skel.has_node("HandsOff"):
			_skel.move_child(_skel.get_node("HandsOff"), -1)   # (and solids after that)
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
