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
##
## The three models share one skeleton, so a clip one of them lacks is
## borrowed from another (Corin borrows the player's fall, the player
## borrows Bram's lift).

const DIR := "res://assets/models/characters/"
## Model files that aren't named after who they play. Everyone else's model
## is characters/<their id or look>.glb (tam, tilly, nell, hob, seamus, krell,
## dask, hunter), picked up the moment it exists.
const MODELS := {"player": "player_a"}
## Clips that repeat until something else is asked for.
const LOOPS := ["idle", "walk", "run", "talk", "duel_idle", "cheer"]
## Where to borrow a clip from when a model doesn't have it.
const DONORS := ["player_a", "bram", "corin"]
## How fast each gait carries them, for matching the feet to the ground (m/s).
const GAIT_SPEED := {"walk": 1.45, "run": 4.2}
const TURN_RATE := 9.0

var model: Node3D
var anim: AnimationPlayer
var gait := "walk"
var talking := false
## Metres a second the character is being moved at (cutscenes set it so the
## walk cycle keeps pace; 0 = the clip's own pace).
var pace := 0.0
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

static var _donor_cache := {}

## Whether the characters who have a model use it (decided 15 October: Bram,
## Corin and the player in 3D everywhere; the rest stay cut-outs until their
## models exist). false puts everyone back to cut-outs.
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
	var path := DIR + String(MODELS.get(char_id, char_id)) + ".glb"
	model = (load(path) as PackedScene).instantiate()
	_pivot.add_child(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# skinned meshes move a long way from their rest bounds when they lie down
		mi.extra_cull_margin = 2.0
	anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null:
		for c in LOOPS:
			if anim.has_animation(c):
				anim.get_animation(c).loop_mode = Animation.LOOP_LINEAR
		_play("idle", 0.0)
		anim.seek(randf() * 1.5, true)   # nobody breathes in step
	# a soft round shadow, as the cut-outs have, to sit them on the grass
	_shadow = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
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
	_marker.position.y = 2.15
	_marker.visible = false
	add_child(_marker)


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
	_action = clip
	_held = true
	_play(clip, blend, speed)


## Holds a clip at one moment (fraction 0..1 of its length).
func pose(clip: String, at: float) -> void:
	if not _ensure(clip):
		return
	_action = clip
	_held = true
	_play(clip, 0.15, 0.0)
	anim.seek(anim.get_animation(clip).length * clampf(at, 0.0, 1.0), true)


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
	# turn towards where we're facing
	var d := wrapf(_want_yaw - _yaw, -PI, PI)
	_yaw += d * minf(1.0, delta * TURN_RATE)
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
	if _action == "":
		var want := _base()
		if want != _clip:
			_play(want, 0.25)
		if (_clip == "walk" or _clip == "run") and pace > 0.0:
			anim.speed_scale = clampf(pace / float(GAIT_SPEED[_clip]), 0.5, 1.8)
		elif _clip == "walk" or _clip == "run":
			anim.speed_scale = 1.0
	if _marker != null and _marker.visible:
		_marker.position.y = 2.15 + sin(_t * 3.0) * 0.06


func _base() -> String:
	if walking:
		return gait if anim != null and anim.has_animation(gait) else "walk"
	if talking and anim != null and anim.has_animation("talk"):
		return "talk"
	return "idle"


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
		var a := _donor_clip(donor, clip)
		if a != null:
			if not anim.has_animation_library(""):
				anim.add_animation_library("", AnimationLibrary.new())
			anim.get_animation_library("").add_animation(clip, a)
			return true
	return false


static func _donor_clip(donor: String, clip: String) -> Animation:
	var key := donor + ":" + clip
	if _donor_cache.has(key):
		return _donor_cache[key]
	var path := DIR + donor + ".glb"
	var a: Animation = null
	if ResourceLoader.exists(path):
		var inst: Node = (load(path) as PackedScene).instantiate()
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap != null and ap.has_animation(clip):
			a = ap.get_animation(clip).duplicate(true)
		inst.free()
	_donor_cache[key] = a
	return a
