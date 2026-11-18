extends SceneTree
## Stills of people's surface detail (18 November: each character's normal
## map, tools/derive_creature_maps.py --people): each one standing in their
## idle, under a warm key light low from the side (so cloth, leather and
## stitching show their shape) and a cool rim, seen whole from three-quarters,
## close on the chest and belt, and close on the face, in one sheet a person.
##   flat      without their normal maps (the before)
## Forward+ through software Vulkan, as the Mac and the iPhone draw them:
##   VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" \
##       godot --rendering-driver vulkan --resolution 720x720 \
##       --script res://tests/cast_skin_shot.gd -- <out_dir> <id,id,...> [flat]
## Sheets are <out_dir>/<id>.png. Checks that each one wears its map (or
## doesn't, flat) on its atlas's surfaces and nowhere else.

var out := "/tmp"
var ids: Array = ["bram"]
var flat := false
var problems: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: ids = Array(a[1].split(","))
	flat = "flat" in a
	_run.call_deferred()


func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.13, 0.14, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.56, 0.62)
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.ssao_enabled = true
	env.environment = e
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-18, 62, 0)   # low and from the side: shape shows
	key.light_color = Color(1.0, 0.9, 0.78)
	key.light_energy = 1.5
	key.shadow_enabled = true
	stage.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-15, -150, 0)
	rim.light_color = Color(0.7, 0.8, 1.0)
	rim.light_energy = 0.6
	stage.add_child(rim)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	for id in ids:
		var p := "res://assets/models/characters/%s.glb" % id
		if not ResourceLoader.exists(p):
			problems.append("%s: no model" % id)
			continue
		var model := (load(p) as PackedScene).instantiate() as Node3D
		if not flat:
			Figure3D.dress_normal_map(model, id)
		stage.add_child(model)
		_check(model, id)
		var sk := model.find_child("Skeleton3D", true, false) as Skeleton3D
		var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap != null:
			for c in ["idle", "Idle", "breathing_idle"]:
				if ap.has_animation(c):
					ap.play(c)
					ap.seek(0.5, true)
					ap.pause()
					break
		for i in 3:
			await process_frame
		var head := Vector3(0, 1.55, 0)
		var chest := Vector3(0, 1.15, 0)
		if sk != null:
			for i in sk.get_bone_count():
				var n := sk.get_bone_name(i)
				if n.ends_with("Head") and not n.ends_with("HeadTop_End"):
					head = sk.global_transform * sk.get_bone_global_pose(i).origin
				elif n.ends_with("Spine1"):
					chest = sk.global_transform * sk.get_bone_global_pose(i).origin
		var tall := head.y + 0.12
		var face := head + Vector3(0, 0.07, 0.04)
		# whole (three-quarters), chest and belt, face
		var views := [
			[Vector3(tall * 0.62, tall * 0.55, tall * 1.25), Vector3(0, tall * 0.5, 0), 34.0],
			[chest + Vector3(0.45, 0.05, 0.75), chest + Vector3(0, -0.12, 0), 34.0],
			[face + Vector3(0.28, 0.02, 0.62), face, 22.0],
		]
		var cell := 720
		var sheet := Image.create(cell * 3, cell, false, Image.FORMAT_RGB8)
		for i in views.size():
			cam.fov = views[i][2]
			cam.global_position = views[i][0]
			cam.look_at(views[i][1])
			for f in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_viewport().get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			img.resize(cell, cell)
			sheet.blit_rect(img, Rect2i(0, 0, cell, cell), Vector2i(i * cell, 0))
		sheet.save_png("%s/%s.png" % [out, id])
		print("CAST SKIN: saved %s" % id)
		model.queue_free()
		await process_frame
	print("CAST SKIN: problems %s" % ("none" if problems.is_empty() else str(problems)))
	quit(1 if not problems.is_empty() else 0)


## Its normal map on every surface painted from its own atlas (none, flat),
## and on no other.
func _check(model: Node3D, id: String) -> void:
	var has_map := ResourceLoader.exists("res://assets/models/characters/%s_normal.png" % id)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for si in mi.mesh.get_surface_count():
			var m := mi.get_active_material(si)
			var worn := m is ShaderMaterial and (m as ShaderMaterial).shader.resource_path.ends_with("character_nm.gdshader")
			var own := true
			var std := mi.mesh.surface_get_material(si) as StandardMaterial3D
			if std != null and std.albedo_texture != null:
				own = std.albedo_texture.resource_path.get_file().begins_with(id + "_atlas")
			var want := has_map and own and not flat
			if worn != want:
				problems.append("%s surface %d: map %s, wanted %s" % [id, si, worn, want])
