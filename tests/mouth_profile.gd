extends Node
## Each model's face in profile, measured off its skin as it's drawn (18
## November: Figure3D.MOUTHS). The figure stands as it was made; its skin's
## points are worked out as the renderer does (held_child_probe.skinned) and
## put in the Head bone's frame as drawn, in metres: for every 3 mm up the
## face, how far forward the furthest point within 5 mm of its middle line
## is. Down from the nose's tip (the furthest forward) the line runs in under
## the nose, out to the upper lip, in to where the lips meet, out to the
## lower lip, in under it and out to the chin. Printed in centimetres, with
## the bone's own scale (MOUTHS is in the bone's units: metres over that).
##   godot --headless --path . res://tests/mouth_profile.tscn -- [model ...]

const Probe = preload("res://tests/held_child_probe.gd")


func _ready() -> void:
	var names: Array = Array(OS.get_cmdline_user_args())
	if names.is_empty():
		names = Figure3D.MOUTHS.keys()
	for nm: String in names:
		var fig: Figure3D = Figure3D.new().setup(nm) as Figure3D
		add_child(fig)
		for k in 3:
			await get_tree().process_frame
		var sk: Skeleton3D = fig._skel
		if fig.anim != null:
			fig.anim.stop()
		sk.reset_bone_poses()
		for k in 2:
			await get_tree().process_frame
		var hb := sk.find_bone("Head")
		var head := sk.global_transform * sk.get_bone_global_pose(hb)
		var at := Transform3D(head.basis.orthonormalized(), head.origin).affine_inverse()
		var prof := {}
		var wide := {}
		for mi: MeshInstance3D in fig.model.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh == null or mi.skin == null:
				continue
			for p: Vector3 in Probe.skinned(mi, false, 0):
				var h := at * p
				if h.y < -0.09 or h.y > 0.12 or h.z < 0.0:
					continue
				var b := int(floor(h.y / 0.003))
				if absf(h.x) < 0.005:
					prof[b] = maxf(float(prof.get(b, -1.0)), h.z)
		var keys := prof.keys()
		keys.sort()
		keys.reverse()
		var line := ""
		for b: int in keys:
			line += "%+.1f:%.1f  " % [b * 0.3, float(prof[b]) * 100.0]
		print("MOUTH PROFILE %s (bone scale %.2f): y:z cm, top down:  %s" % [nm, head.basis.get_scale().y, line])
		fig.queue_free()
		await get_tree().process_frame
	get_tree().quit()
