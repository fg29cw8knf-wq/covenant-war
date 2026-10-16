extends SceneTree
## Temporary: where the oaks and the mill end up (deleted before committing).

func _initialize() -> void:
	var v := AshfordVillage.new()
	root.add_child(v)
	await process_frame
	var m := v.mill_root.position
	var lo := INF
	var hi := -INF
	for k in 24:
		var a := TAU * k / 24.0
		var p := Vector2(m.x, m.z) + Vector2(cos(a), sin(a)) * AshfordVillage.MILL_BASE_RADIUS
		lo = minf(lo, v.ground_y(p.x, p.y))
		hi = maxf(hi, v.ground_y(p.x, p.y))
	print("mill at ", m, " foot ground %.3f..%.3f" % [lo, hi])
	print("sails hub ", v.mill_sails.global_position, " fire point ", v.mill_fire_point())
	print("oaks: ", v.oaks.size())
	for o: Node3D in v.oaks:
		var p := o.position
		print("  %s at (%.1f, %.1f, %.1f) r %.1f scale %s" % [o.name, p.x, p.y, p.z, Vector2(p.x, p.z).length(), o.scale])
	var n := 0
	for c in v.get_children():
		if c is MultiMeshInstance3D and (c as MultiMeshInstance3D).material_override == v.mats.leaf:
			n += (c as MultiMeshInstance3D).multimesh.instance_count
	print("drawn trees: ", n)
	var t := ThornwoodSet.new()
	root.add_child(t)
	await process_frame
	m = t.mill_root.position
	lo = INF
	hi = -INF
	for k in 24:
		var a := TAU * k / 24.0
		var p := Vector2(m.x, m.z) + Vector2(cos(a), sin(a)) * AshfordVillage.MILL_BASE_RADIUS
		lo = minf(lo, t.ground_y(p.x, p.y))
		hi = maxf(hi, t.ground_y(p.x, p.y))
	print("thornwood mill at ", m, " foot ground %.3f..%.3f" % [lo, hi])
	quit()
