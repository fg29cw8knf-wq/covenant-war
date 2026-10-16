extends SceneTree
## Temporary: measures the new Ashford props (deleted before committing).

func _init() -> void:
	for id in ["mill_tower", "mill_sails", "oak_a"]:
		var scene: PackedScene = load("res://assets/models/ashford/%s.glb" % id)
		var inst: Node3D = scene.instantiate()
		print("== ", id)
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			print(" mesh ", mi.name, " aabb ", mi.get_aabb(), " xf ", mi.transform)
			var mesh: ArrayMesh = mi.mesh
			for s in mesh.get_surface_count():
				var m := mi.get_active_material(s)
				var info := ""
				if m is StandardMaterial3D:
					var sm: StandardMaterial3D = m
					info = "transp %d scissor %.2f cull %d tex %s rough %.2f" % [sm.transparency, sm.alpha_scissor_threshold, sm.cull_mode, sm.albedo_texture.resource_path if sm.albedo_texture else "none", sm.roughness]
				var d := RenderingServer.mesh_get_surface(mesh.get_rid(), s)
				var lods: Array = d.get("lods", [])
				var lod_s := []
				for l in lods:
					lod_s.append("%d@%.3f" % [(l.index_data as PackedByteArray).size() / (6 if d.get("vertex_count", 0) < 65536 else 12), l.edge_length])
				print("  surf ", s, " tris ", mesh.surface_get_array_index_len(s) / 3, " ", info, " lods ", lod_s)
			if id == "mill_tower":
				_tower(mesh)
			if id == "oak_a":
				_oak(mesh)
		inst.free()
	quit()


func _tower(mesh: ArrayMesh) -> void:
	var v: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# radius (max distance from the axis) in height bands, ignoring the hub (z > 1.95 near y 6.9)
	var bands := {}
	var hub_max_z := -9.0
	var hub_pts := []
	for p in v:
		var b := int(floor(p.y / 0.25))
		var r := Vector2(p.x, p.z).length()
		if p.z > 1.6 and p.y > 6.0 and p.y < 7.8 and absf(p.x) < 0.6:
			hub_pts.append(p)
			continue
		bands[b] = maxf(bands.get(b, 0.0), r)
	var keys := bands.keys()
	keys.sort()
	for k in keys:
		print("   y %.2f  r %.2f" % [k * 0.25, bands[k]])
	var hmin := Vector3(9, 9, 9)
	var hmax := Vector3(-9, -9, -9)
	for p in hub_pts:
		hmin = hmin.min(p)
		hmax = hmax.max(p)
	print("   hub/shaft bounds ", hmin, " - ", hmax)
	# door: the front at the bottom, vertices with z > 1.3, y < 3
	var door_top := 0.0
	for p in v:
		if p.z > 1.25 and absf(p.x) < 0.75 and p.y < 3.2 and p.y > door_top:
			door_top = p.y
	print("   door region top ", door_top)


func _oak(mesh: ArrayMesh) -> void:
	var v: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for h in [0.2, 0.6, 1.0, 1.5, 2.0, 2.5, 3.0]:
		var rmax := 0.0
		var n := 0
		var c := Vector2.ZERO
		for p in v:
			if absf(p.y - h) < 0.08 and Vector2(p.x, p.z).length() < 1.4:
				c += Vector2(p.x, p.z)
				n += 1
		if n > 0:
			c /= n
		for p in v:
			if absf(p.y - h) < 0.08 and Vector2(p.x, p.z).length() < 1.4:
				rmax = maxf(rmax, Vector2(p.x, p.z).distance_to(c))
		print("   trunk y %.1f centre %s r %.2f (%d verts)" % [h, c, rmax, n])
	var leaves: PackedVector3Array = mesh.surface_get_arrays(1)[Mesh.ARRAY_VERTEX]
	var lo := 99.0
	for p in leaves:
		lo = minf(lo, p.y)
	print("   lowest leaf ", lo)
