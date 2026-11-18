extends Node3D
## A prop model from four sides in plain daylight, framed on its bounds: the
## check on what tools/rebake_glb.py or tools/slim_glb.py made (18 November:
## Gary's tunnel mouth and thorn bush).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver vulkan --resolution 900x700 \
##       res://tests/prop_peek.tscn -- <out prefix> <model> [yaws: 0,45,180,270] [pitch: 18] [flat]
##
## <model> is a res:// path (the game's own import of it: its compressed
## pictures, its far-off meshes) or a .glb anywhere on disk (Gary's file as
## it came, for the comparison; a model with its pictures beside it,
## <stem>_atlas.png and so on, gets them put on by hand). "flat" leaves the
## normal and roughness maps off. Stills: <out prefix>_<yaw>.png. Prints the
## model's size and how many triangles it has.

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 2:
		print("PROP PEEK: <out prefix> <model> [yaws] [pitch] [flat]")
		get_tree().quit(1)
		return
	var out: String = a[0]
	var path: String = a[1]
	var yaws: PackedStringArray = (a[2] if a.size() > 2 and a[2] != "flat" else "0,45,180,270").split(",")
	var pitch := float(a[3]) if a.size() > 3 and a[3] != "flat" else 18.0
	var flat := a.has("flat")
	var m: Node3D
	if path.begins_with("res://"):
		m = (load(path) as PackedScene).instantiate()
		if flat:
			for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
				for si in mi.mesh.get_surface_count():
					var mat := mi.mesh.surface_get_material(si).duplicate() as BaseMaterial3D
					mat.normal_enabled = false
					mat.roughness_texture = null
					mat.metallic_texture = null
					mat.roughness = 0.9
					mat.metallic = 0.0
					mi.set_surface_override_material(si, mat)
	else:
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(path, st) != OK:
			print("PROP PEEK: couldn't read ", path)
			get_tree().quit(1)
			return
		m = doc.generate_scene(st)
		var stem := path.get_basename()
		if FileAccess.file_exists(stem + "_atlas.png"):
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = _tex(stem + "_atlas.png")
			if not flat and FileAccess.file_exists(stem + "_normal.png"):
				mat.normal_enabled = true
				mat.normal_texture = _tex(stem + "_normal.png")
			if not flat and FileAccess.file_exists(stem + "_mr.png"):
				var t := _tex(stem + "_mr.png")
				mat.roughness_texture = t
				mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
				mat.roughness = 1.0
				mat.metallic_texture = t
				mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
				mat.metallic = 1.0
			for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
				for si in mi.mesh.get_surface_count():
					mi.set_surface_override_material(si, mat)
	add_child(m)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.32, 0.34, 0.38)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -140, 0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.7, 0.8, 1.0)
	add_child(fill)
	var bb := AABB()
	var first := true
	var tris := 0
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		bb = b if first else bb.merge(b)
		first = false
		for si in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(si)
			var idx = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	print("PROP PEEK: %s: size %s, %d triangles" % [path.get_file(), bb.size, tris])
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * maxf(bb.size.x, bb.size.z) * 6.0
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.3, 0.3, 0.3)
	gm.roughness = 1.0
	ground.material_override = gm
	ground.position = Vector3(bb.get_center().x, bb.position.y - 0.001, bb.get_center().z)
	add_child(ground)
	var cam := Camera3D.new()
	cam.fov = 35.0
	add_child(cam)
	cam.current = true
	var c := bb.get_center()
	var dist := bb.size.length() * 0.5 / sin(deg_to_rad(cam.fov * 0.5)) * 1.05
	cam.near = dist * 0.01
	cam.far = dist * 10.0
	for ys in yaws:
		var yaw := deg_to_rad(float(ys))
		var p := deg_to_rad(pitch)
		cam.position = c + Vector3(sin(yaw) * cos(p), sin(p), cos(yaw) * cos(p)) * dist
		cam.look_at(c)
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [out, ys])
	print("PROP PEEK: done")
	get_tree().quit()


func _tex(p: String) -> ImageTexture:
	var im := Image.load_from_file(p)
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)
