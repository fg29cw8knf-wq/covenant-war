extends SceneTree
## How far each creature moves in its attack clip, as a share of its size:
## the clip's bone tracks applied over the rest pose by hand (no frames run).
## (12 November, evening: picked the ones under 0.1 for DuelField3D.RIM_GLOW.)
##   godot --headless --script res://tests/motion_probe.gd
func _initialize() -> void:
	var dir := DirAccess.open("res://assets/models/creatures")
	var out := []
	for f in dir.get_files():
		if not f.ends_with(".glb"):
			continue
		var id := f.get_basename()
		var n: Node3D = (load("res://assets/models/creatures/" + f) as PackedScene).instantiate()
		var aps := n.find_children("*", "AnimationPlayer", true, false)
		var sks := n.find_children("*", "Skeleton3D", true, false)
		var anim: AnimationPlayer = aps[0] if not aps.is_empty() else null
		var sk: Skeleton3D = sks[0] if not sks.is_empty() else null
		var clip := ""
		if anim != null:
			for nm in ["attack", "bite", "pounce", "strike", "lunge"]:
				for ex in anim.get_animation_list():
					if clip == "" and String(ex).to_lower() == nm:
						clip = String(ex)
		# its size: the meshes' bounds, in the skeleton's space
		var aabb := AABB()
		var first := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var ab: AABB = (mi as MeshInstance3D).transform * (mi as MeshInstance3D).get_aabb()
			aabb = ab if first else aabb.merge(ab)
			first = false
		if anim == null or clip == "" or sk == null:
			out.append([id, -1.0, 0.0, "no rig/clip"])
			n.free()
			continue
		var a := anim.get_animation(clip)
		var nb := sk.get_bone_count()
		var ptrack := {}
		var rtrack := {}
		for tr in a.get_track_count():
			var path := String(a.track_get_path(tr))
			var bone := path.get_slice(":", 1)
			var bi := sk.find_bone(bone)
			if bi < 0:
				continue
			match a.track_get_type(tr):
				Animation.TYPE_POSITION_3D: ptrack[bi] = tr
				Animation.TYPE_ROTATION_3D: rtrack[bi] = tr
		var size := maxf(0.01, aabb.size.length())
		var base := []
		var maxd := PackedFloat32Array()
		maxd.resize(nb)
		var steps := 24
		for k in steps + 1:
			var tm := a.length * k / steps
			var glob := []
			glob.resize(nb)
			for b in nb:
				var rest := sk.get_bone_rest(b)
				var pos := rest.origin
				var rot := rest.basis.get_rotation_quaternion()
				if ptrack.has(b):
					pos = a.position_track_interpolate(ptrack[b], tm)
				if rtrack.has(b):
					rot = a.rotation_track_interpolate(rtrack[b], tm)
				var local := Transform3D(Basis(rot).scaled(rest.basis.get_scale()), pos)
				var par := sk.get_bone_parent(b)
				glob[b] = (glob[par] as Transform3D) * local if par >= 0 else local
			for b in nb:
				var p: Vector3 = (glob[b] as Transform3D).origin
				if k == 0:
					base.append(p)
				else:
					maxd[b] = maxf(maxd[b], p.distance_to(base[b]))
		var arr := Array(maxd)
		arr.sort()
		var p90: float = arr[int(arr.size() * 0.9)] if arr.size() > 0 else 0.0
		var mean := 0.0
		for v in arr:
			mean += v
		mean /= maxf(1, arr.size())
		out.append([id, p90 / size, mean / size, "%s %d bones %.2fs size %.2f" % [clip, nb, a.length, size]])
		n.free()
	out.sort_custom(func(x, y): return x[1] < y[1])
	for r in out:
		print("MOTION %-18s p90 %6.3f  mean %6.3f  %s" % r)
	quit()
