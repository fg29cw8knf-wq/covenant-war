extends Node
## What a frame of the village is made of (12 November, Gary's Mac has an M1
## chip): every mesh standing in the built village, largest first, with its
## triangles, how many times it stands, whether it has simpler copies for
## far off (LODs), whether it casts a shadow and how far off it stops being
## drawn. Built as a Mac builds it (Gfx.level() 2) whatever it's drawn with.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/tri_probe.tscn -- [place] [spawn] [cam=x,y,z,x,y,z] [shot=<file.png>]

var world: World


func _ready() -> void:
	Gfx.force_level = 2
	var args := OS.get_cmdline_user_args()
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["first_steps"] = 2
	for f in ["arrived_ashford", "ash_started", "p1_crate_down", "corin_met", "first_deck"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	var names: Array = (args as Array).filter(func(a): return not String(a).contains("="))
	world = World.new().setup(names[0] if names.size() > 0 else "ashford", names[1] if names.size() > 1 else "green")
	add_child(world)
	for k in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var rows := {}
	var total := 0
	var todo: Array = [world]
	while not todo.is_empty():
		var n: Node = todo.pop_back()
		todo.append_array(n.get_children())
		var mesh: Mesh = null
		var count := 1
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			mesh = (n as MultiMeshInstance3D).multimesh.mesh
			count = (n as MultiMeshInstance3D).multimesh.visible_instance_count
			if count < 0:
				count = (n as MultiMeshInstance3D).multimesh.instance_count
		if mesh == null or not (n as Node3D).is_visible_in_tree():
			continue
		var tris := 0
		var lods := 0
		for s in mesh.get_surface_count():
			var d: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(), s)
			var ic := int(d.get("index_count", 0))
			tris += (ic if ic > 0 else int(d.get("vertex_count", 0))) / 3
			lods = maxi(lods, (d.get("lods", []) as Array).size())
		var gi := n as GeometryInstance3D
		var key := mesh.resource_path if mesh.resource_path != "" else "%s (%s)" % [mesh.get_class(), _where(n)]
		key = key.get_slice("::", 0)
		if not rows.has(key):
			rows[key] = {"tris": 0, "n": 0, "each": tris, "lods": lods, "shadow": 0, "far": 0.0}
		var r: Dictionary = rows[key]
		r.tris += tris * count
		r.n += count
		r.each = maxi(int(r.each), tris)
		r.lods = maxi(int(r.lods), lods)
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			r.shadow += count
		r.far = maxf(float(r.far), gi.visibility_range_end)
		total += tris * count
	var list: Array = rows.keys()
	list.sort_custom(func(a, b): return int(rows[a].tris) > int(rows[b].tris))
	print("TRI PROBE: %d thousand triangles stand in %s (%d kinds of mesh)" % [total / 1000, world.area_id if "area_id" in world else "the place", list.size()])
	for k: String in list.slice(0, 45):
		var r: Dictionary = rows[k]
		print("TRI PROBE: %7d k  x%-6d each %7d  lods %d  shadows %-6d  far %-5s %s" % [int(r.tris) / 1000, int(r.n), int(r.each), int(r.lods), int(r.shadow),
			("%.0f" % float(r.far)) if float(r.far) > 0.0 else "-", k.trim_prefix("res://assets/")])
	print("TRI PROBE: a frame draws %d objects, %d thousand triangles, %d draw calls" % [
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	# shot=<file>: the picture as it stands now (two runs compare like for like:
	# the same frame, so the same wind); cam=x,y,z,x,y,z looks from the first
	# point at the second, with everything drawn over the 3D taken away
	for a: String in args:
		if a.begins_with("cam="):
			var v: PackedStringArray = a.substr(4).split(",")
			var cam := Camera3D.new()
			world.add_child(cam)
			cam.far = 400.0
			cam.look_at_from_position(Vector3(float(v[0]), float(v[1]), float(v[2])), Vector3(float(v[3]), float(v[4]), float(v[5])))
			cam.make_current()
			for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
				layer.visible = false
			for c: Control in get_tree().root.find_children("*", "Control", true, false):
				if not (c.get_parent() is Control):
					c.visible = false
			world.process_mode = Node.PROCESS_MODE_DISABLED   # (no film moves the camera or the light on)
			var env := world.find_children("*", "WorldEnvironment", true, false)
			print("TRI PROBE: %d environment(s); 3D %s" % [env.size(), "off" if get_viewport().disable_3d else "on"])
			get_viewport().disable_3d = false
			# (the wood is dark until a film lights one of its parts: by morning light)
			for set_node in world.find_children("*", "Node3D", true, false):
				if set_node.has_method("set_scene"):
					set_node.call("set_scene", "morning")
			for k in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			print("TRI PROBE: from the camera asked for, a frame draws %d objects, %d thousand triangles, %d draw calls" % [
				int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	for a: String in args:
		if a.begins_with("shot="):
			get_viewport().get_texture().get_image().save_png(a.substr(5))
	print("TRI PROBE: done")
	get_tree().quit()


func _where(n: Node) -> String:
	var p := n.get_parent()
	var names := [String(n.name)]
	while p != null and p != world and names.size() < 3:
		names.push_front(String(p.name))
		p = p.get_parent()
	return "/".join(names)
