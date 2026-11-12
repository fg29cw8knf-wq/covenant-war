extends Node
## Every character model through the clips it plays, checked the way the
## body check (tests/body_check.gd) checks the story: each joint against a
## body's limits, and the skin (skinned on the CPU) for triangles turned
## inside out, stretched or crushed. What it finds is the model's or the
## clip's own fault, before any scene stages it (12 November). First the
## rest pose, which must come out clean (the skinning sum checked).
##
##   godot --headless --path . res://tests/body_probe.tscn -- [model ...] [clips=idle,walk] [n=6]
##
## (clips=stretch_20: the attic's waking stretch, Figure3D.stretch(), built
## from the idle as the game builds it)
##
## Prints a line a model and clip with anything found ("PROBE:"), and ends
## with each model's worst ("PROBE WORST:").

const BC := preload("res://tests/body_check.gd")
## The game's own clips (borrowed by those without them) besides the model's.
const GAME_CLIPS := ["idle", "walk", "run", "talk", "duel_idle", "play_card", "victory", "defeat", "look_up", "lift",
	"sit", "cheer", "wave", "fall"]

var bc
var _want := false
var _got := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var models: Array = []
	var clips: Array = []
	var n := 6
	for a in OS.get_cmdline_user_args():
		var s := String(a)
		if s.begins_with("clips="):
			clips = Array(s.substr(6).split(","))
		elif s.begins_with("n="):
			n = int(s.substr(2))
		else:
			models.append(s)
	if models.is_empty():
		for fn in DirAccess.get_files_at(Figure3D.DIR):
			if fn.ends_with(".glb"):
				models.append(fn.get_basename())
	bc = BC.new()
	bc.root = self
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(0, 1.2, 4)
	var worst_all: Array = []
	for mname in models:
		var f := Figure3D.new().setup(mname) as Figure3D
		add_child(f)
		await _frames(3)
		if f._skel == null or f.anim == null:
			print("PROBE: %s has no skeleton" % mname)
			f.queue_free()
			continue
		var d: Dictionary = bc._build(f)
		f._skel.skeleton_updated.connect(_on_skel.bind(f, d))
		var worst := {"joint": 0.0, "joint_at": "", "skin": 0, "skin_at": ""}
		# the rest pose: the skin must be as modelled
		f._skel.reset_bone_poses()
		var st: Dictionary = bc.skin_state(f, d.skin, true)
		var bad := 0
		for b in st:
			bad += int(st[b][0]) + int(st[b][1]) + int(st[b][2])
		print("PROBE: %s rest: %d bad triangles of %d checked%s" % [mname, bad, (d.skin.tdom as PackedInt32Array).size(),
			"" if bad == 0 else " (THE SKINNING SUM IS WRONG?)"])
		var hinge := []
		for jd in d.joints:
			if jd.has("n"):
				hinge.append("%s %s" % [jd.label, "from its clips" if jd.get("n_learned", false) else "by the toes"])
		print("PROBE: %s hinges: %s" % [mname, ", ".join(hinge)])
		if "ranges" in OS.get_cmdline_user_args():
			var fwd: Vector3 = bc._forward(f._skel)
			for jd in d.joints:
				var extra := ""
				if jd.has("n"):
					var rp := f._skel.get_bone_global_rest(jd.p).basis.orthonormalized()
					var prior: Vector3 = rp.inverse() * (fwd if jd.kind == "elbow" else -fwd)
					extra = " hinge way %s (by the toes %s, agree %.2f)" % [str((jd.n as Vector3).snapped(Vector3.ONE * 0.01)), str(prior.snapped(Vector3.ONE * 0.01)), (jd.n as Vector3).dot(prior.normalized())]
				print("PROBE: %s %s: clips reach %s; limits %s%s" % [mname, jd.label, str(jd.clip_max), str(jd.lim), extra])
		var list: Array = clips.duplicate() if not clips.is_empty() else (Array(f.anim.get_animation_list()) + GAME_CLIPS)
		var seen := {}
		for clip in list:
			if seen.has(clip) or String(clip).begins_with("RESET"):
				continue
			seen[clip] = true
			# (the waking stretch is built from the idle when first asked for:
			# stretch_N is N tenths of a second long)
			if String(clip).begins_with("stretch_") and not f.anim.has_animation(clip):
				f.stretch(int(String(clip).substr(8)) / 10.0)
				await _frames(2)
			if not f._ensure(clip):
				continue
			var lines: Array = []
			for i in n:
				var at := (float(i) + 0.5) / float(n)
				f.pose(clip, at, 0.0)
				await _frames(2)
				_got = {}
				_want = true
				await _frames(2)
				_want = false
				if _got.is_empty():
					# (a clip held still with nothing else moving the skeleton: no
					# update comes, and what's stored is what's drawn)
					_want = true
					_on_skel(f, d)
					_want = false
				if _got.is_empty():
					if "debug" in OS.get_cmdline_user_args():
						print("PROBE: (no pose read for %s %s at %.2f: clip now %s, anim %s)" % [mname, clip, at, f._clip, f.anim.current_animation])
					continue
				for row in _got.joints:
					lines.append("t%.2f %s" % [at, row[0]])
					if float(row[1]) > float(worst.joint):
						worst.joint = float(row[1])
						worst.joint_at = "%s t%.2f %s" % [clip, at, row[0]]
				for row in _got.skin:
					lines.append("t%.2f %s" % [at, row[0]])
					if int(row[1]) > int(worst.skin):
						worst.skin = int(row[1])
						worst.skin_at = "%s t%.2f %s" % [clip, at, row[0]]
			if not lines.is_empty():
				print("PROBE: %s %s: %s" % [mname, clip, "; ".join(lines.slice(0, 8)) + (" (+%d more)" % (lines.size() - 8) if lines.size() > 8 else "")])
		worst_all.append("%s: joint %.0f deg over (%s); skin %d bad (%s)" % [mname, worst.joint, worst.joint_at, worst.skin, worst.skin_at])
		f.queue_free()
		await _frames(2)
	for l in worst_all:
		print("PROBE WORST: ", l)
	get_tree().quit()


func _on_skel(f: Figure3D, d: Dictionary) -> void:
	if not _want or not _got.is_empty():
		return
	var sk := f._skel
	var joints: Array = []
	for jd in d.joints:
		var gp := sk.get_bone_global_pose(jd.p)
		var gb := sk.get_bone_global_pose(jd.b)
		var q := (gp.basis.orthonormalized().inverse() * gb.basis.orthonormalized()).get_rotation_quaternion()
		var m: Dictionary = bc._measure(jd, q)
		var base: Dictionary = BC.LIMITS[jd.kind]
		for k in ["twist", "swing", "back", "side", "fold"]:
			if not base.has(k):
				continue
			var val: float = float(m.swing) if k == "fold" else float(m[k])
			if val > float(base[k]):
				joints.append(["%s %s %.0f (body %.0f)" % [jd.label, k, val, float(base[k])], val - float(base[k])])
	var skin: Array = []
	var st: Dictionary = bc.skin_state(f, d.skin, true)
	for b in st:
		var row: Array = st[b]
		var bad: int = int(row[0]) + int(row[1]) + int(row[2])
		if bad >= 2:
			skin.append(["%s skin %d bad (%d in-out, %d stretch x%.1f, %d crush x%.2f)" % [BC._region(sk.get_bone_name(b)), bad,
				row[0], row[1], row[3], row[2], row[4]], bad])
	_got = {"joints": joints, "skin": skin}


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
