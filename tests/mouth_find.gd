extends SceneTree
## Where a model's mouth is, from its mesh: the vertices the Head bone moves,
## in the Head bone's own rest frame; the chin (the lowest point of the
## face's front), the nose (the point furthest forward) and the lips (the
## front-most point a third of the way from the chin up to the nose), for
## AshfordP1.MOUTH (8 November: the spoon to the mouth).
##   godot --headless --path . --script res://tests/mouth_find.gd -- [model ...]
var models := ["player_a", "player_b", "player_c", "player_d", "bram", "corin"]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		models = a
	_run.call_deferred()


func _run() -> void:
	for m in models:
		var path := "res://assets/models/characters/%s.glb" % m
		if not ResourceLoader.exists(path):
			print("%s: no model" % m)
			continue
		var model: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(model)
		await process_frame
		var sk := model.find_child("Skeleton3D", true, false) as Skeleton3D
		if sk == null:
			print("%s: no skeleton" % m)
			model.queue_free()
			continue
		var hb := sk.find_bone("Head")
		if hb < 0:
			print("%s: no Head bone" % m)
			model.queue_free()
			continue
		var head_rest := sk.get_bone_global_rest(hb)
		var inv := head_rest.affine_inverse()
		# the bone's forward: the skeleton's +z (models face +z here), in the head's frame
		var pts: PackedVector3Array = []
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := mi.mesh
			if mesh == null:
				continue
			# the mesh in the skeleton's frame (skinned meshes sit at the skeleton)
			var to_sk := sk.global_transform.affine_inverse() * mi.global_transform
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var bones = arr[Mesh.ARRAY_BONES]
				var weights = arr[Mesh.ARRAY_WEIGHTS]
				if bones == null or weights == null:
					continue
				var per := int(bones.size() / verts.size())
				for i in verts.size():
					var wh := 0.0
					for k in per:
						if int(bones[i * per + k]) == hb:
							wh += float(weights[i * per + k])
					if wh > 0.6:
						pts.append(inv * (to_sk * verts[i]))
		if pts.is_empty():
			print("%s: no vertices on the Head bone" % m)
			model.queue_free()
			continue
		# in the head's frame: up and forward as the rest basis has them; the
		# skeleton's up and forward brought in
		var up := (inv.basis * Vector3.UP).normalized()
		var fwd := (inv.basis * Vector3.FORWARD).normalized()
		var fwd2 := (inv.basis * Vector3.BACK).normalized()
		# which way the face is: the side with the most spread forward
		var best_f := fwd
		var top := -INF
		var bottom := INF
		for p in pts:
			top = maxf(top, p.dot(up))
			bottom = minf(bottom, p.dot(up))
		var reach_a := -INF
		var reach_b := -INF
		for p in pts:
			reach_a = maxf(reach_a, p.dot(fwd))
			reach_b = maxf(reach_b, p.dot(fwd2))
		if reach_b > reach_a:
			best_f = fwd2
		# the nose: furthest forward near the middle
		var nose := Vector3.ZERO
		var nose_f := -INF
		var side := best_f.cross(up).normalized()
		for p in pts:
			if absf(p.dot(side)) < 0.012 and p.dot(best_f) > nose_f:
				nose_f = p.dot(best_f)
				nose = p
		# the chin: lowest point of the front half (forward of the head's middle)
		var chin := Vector3.ZERO
		var chin_y := INF
		for p in pts:
			if absf(p.dot(side)) < 0.015 and p.dot(best_f) > nose_f * 0.3 and p.dot(up) < chin_y:
				chin_y = p.dot(up)
				chin = p
		# the lips: a third of the way up from the chin to the nose, the front-most point there
		var lip_y := chin.dot(up) + (nose.dot(up) - chin.dot(up)) * 0.38
		var lips := Vector3.ZERO
		var lips_f := -INF
		for p in pts:
			if absf(p.dot(side)) < 0.012 and absf(p.dot(up) - lip_y) < 0.006 and p.dot(best_f) > lips_f:
				lips_f = p.dot(best_f)
				lips = p
		print("%s: Head rest at %s; head vertices %d, top %.3f bottom %.3f over the bone" % [m, head_rest.origin.snapped(Vector3(0.001, 0.001, 0.001)), pts.size(), top, bottom])
		print("   nose %s  chin %s  lips %s  (head's own frame)" % [nose.snapped(Vector3(0.001, 0.001, 0.001)), chin.snapped(Vector3(0.001, 0.001, 0.001)), lips.snapped(Vector3(0.001, 0.001, 0.001))])
		# and in the skeleton's frame, relative to the bone (up/forward plain)
		var lw := head_rest * lips - head_rest.origin
		var nw := head_rest * nose - head_rest.origin
		var cw := head_rest * chin - head_rest.origin
		print("   from the Head bone (skeleton frame): lips %s  nose %s  chin %s" % [lw.snapped(Vector3(0.001, 0.001, 0.001)), nw.snapped(Vector3(0.001, 0.001, 0.001)), cw.snapped(Vector3(0.001, 0.001, 0.001))])
		model.queue_free()
		await process_frame
	print("MOUTH FIND: done")
	quit()
