extends SceneTree
## Numbers for a walk (6 November, Bram's coat walk in the Night of the White
## Sky): over a few strides at a pace, how far the back leans from upright
## (Hips to Neck, forward +), how the head and chest are pitched against the
## model's own rest (down +), how far each upper arm stands out from the body
## (0 hanging straight down), and how far apart the feet pass (m).
##   godot --headless --fixed-fps 30 --path . --script res://tests/gait_probe.gd -- <model> [pace] [noposture] [donor=bram]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var model := a[0] if a.size() > 0 else "bram_coat"
	var pace := float(a[1]) if a.size() > 1 and a[1].is_valid_float() else 1.3
	var f := Figure3D.make(model, model) as Figure3D
	root.add_child(f)
	f.snap_face(Vector3.FORWARD)
	for k in 4:
		await process_frame
	if a.has("noposture") and f._skel.has_node("Posture"):
		f._skel.get_node("Posture").free()
	for s in a:
		if String(s).begins_with("posture="):
			# posture=Spine:6,0,0;Neck:-4,0,0 in place of POSTURE's
			if f._skel.has_node("Posture"):
				f._skel.get_node("Posture").free()
			var pm := Figure3D.Posture.new()
			pm.name = "Posture"
			for part in String(s).substr(8).split(";"):
				var kv := part.split(":")
				var e := kv[1].split(",")
				pm.turns.append([f._skel.find_bone(kv[0]), Quaternion.from_euler(Vector3(deg_to_rad(float(e[0])), deg_to_rad(float(e[1])), deg_to_rad(float(e[2]))))])
			f._skel.add_child(pm)
			f._skel.move_child(pm, 0)
	for s in a:
		if String(s).begins_with("donor="):
			var d := Figure3D._donor_clip(String(s).substr(6), "walk")
			var clip := (d.clip as Animation).duplicate(true)
			f._fit(clip, float(d.hips))
			clip.loop_mode = Animation.LOOP_LINEAR
			f.anim.get_animation_library("").remove_animation("walk")
			f.anim.get_animation_library("").add_animation("walk", clip)
	var sk := f._skel
	var stats := {}
	var add := func(k: String, v: float) -> void:
		if not stats.has(k):
			stats[k] = []
		(stats[k] as Array).append(v)
	# (sampled as the skeleton finishes its update: the modifiers' pose, the
	# posture and any reach included; bone_pos between frames gives the clip's)
	var pos := func(bone: String) -> Vector3:
		return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bone)).origin
	var phase := ["stand"]
	var last_foot := ["", Vector3.ZERO]
	var sample := func() -> void:
		var fw := f.facing()
		var rt := fw.cross(Vector3.UP)
		var ph: String = phase[0]
		var v: Vector3 = pos.call("Neck") - pos.call("Hips")
		add.call(ph + " lean (fwd +)", rad_to_deg(atan2(v.dot(fw), v.y)))
		var hv: Vector3 = pos.call("HeadTop_End") - pos.call("Neck") if sk.find_bone("HeadTop_End") >= 0 else pos.call("Head") - pos.call("Neck")
		add.call(ph + " neck+head (fwd +)", rad_to_deg(atan2(hv.dot(fw), hv.y)))
		var hi := sk.find_bone("Head")
		var hq := sk.get_bone_global_pose(hi).basis.orthonormalized() * sk.get_bone_global_rest(hi).basis.orthonormalized().inverse()
		var hf := hq * Vector3(0, 0, 1)
		add.call(ph + " face pitch (down +)", rad_to_deg(atan2(-hf.y, hf.z)))
		var c: Vector3 = pos.call("Spine2") - pos.call("Spine")
		add.call(ph + " chest (fwd +)", rad_to_deg(atan2(c.dot(fw), c.y)))
		for side in ["Left", "Right"]:
			var u: Vector3 = pos.call(side + "ForeArm") - pos.call(side + "Arm")
			var outward := rt if side == "Right" else -rt
			add.call(ph + " arm out " + side, rad_to_deg(atan2(u.dot(outward), -u.y)))
			add.call(ph + " arm fwd " + side, rad_to_deg(atan2(u.dot(fw), -u.y)))
			var w: Vector3 = pos.call(side + "Hand") - pos.call(side + "ForeArm")
			add.call(ph + " forearm fwd " + side, rad_to_deg(atan2(w.dot(fw), -w.y)))
		var lf: Vector3 = pos.call("LeftFoot")
		var rf: Vector3 = pos.call("RightFoot")
		add.call(ph + " feet apart", absf((lf - rf).dot(rt)))
		# the planted foot (the lower) should stay put on the ground: how fast it slides (m/s)
		var low: Vector3 = lf if lf.y < rf.y else rf
		var key := "L" if lf.y < rf.y else "R"
		if ph == "walk" and last_foot[0] == key:
			var d: Vector3 = low - (last_foot[1] as Vector3)
			add.call(ph + " planted foot slide", Vector2(d.x, d.z).length() * 30.0)
		last_foot[0] = key
		last_foot[1] = low
	var on := [false]
	sk.skeleton_updated.connect(func() -> void:
		if on[0]:
			sample.call())
	for ph in ["stand", "walk"]:
		phase[0] = ph
		if ph == "walk":
			f.walking = true
			f.pace = pace
			for k in 10:
				await process_frame
		on[0] = true
		for k in 75:
			await process_frame
			if ph == "walk":
				f.position += f.facing() * pace / 30.0
		on[0] = false
	var keys := stats.keys()
	keys.sort()
	print("GAIT ", model, " pace ", pace, " ", a, " hips ", f._hips, " natural ", f._gait_pace("walk"), " speed_scale ", f.anim.speed_scale)
	for k in keys:
		var arr: Array = stats[k]
		var mn := 1e9
		var mx := -1e9
		var sum := 0.0
		for x in arr:
			mn = minf(mn, x)
			mx = maxf(mx, x)
			sum += x
		var srt := arr.duplicate()
		srt.sort()
		print("  %-26s mean %7.2f  median %7.2f  min %7.2f  max %7.2f" % [k, sum / arr.size(), srt[srt.size() / 2], mn, mx])
	quit()
