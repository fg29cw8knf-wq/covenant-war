extends SceneTree
## A face close up, front-on and from three-quarters each side and from a
## little below and above, at rest and in a clip, under a soft key light, for
## checking a model's face (29 October, Gary: Player A's "face still look
## weird around the nose area").
##   xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 640x640 \
##       --script res://tests/face_close.gd -- <out.png> <id> [clip] [glb path]
var out := "/tmp/face.png"
var id := "player_a"
var clip := "idle"
var path := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: id = a[1]
	if a.size() > 2: clip = a[2]
	if a.size() > 3: path = a[3]
	_run.call_deferred()

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.22, 0.27)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.6, 0.6)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-25, 25, 0)
	key.light_energy = 1.25
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, -40, 0)
	fill.light_energy = 0.35
	stage.add_child(fill)
	var model: Node3D
	var p := path if path != "" else "res://assets/models/characters/%s.glb" % id
	model = (load(p) as PackedScene).instantiate()
	if path == "":
		Figure3D.dress_normal_map(model, id)
	stage.add_child(model)
	var sk := model.find_child("Skeleton3D", true, false) as Skeleton3D
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if clip != "rest" and ap != null and ap.has_animation(clip):
		ap.play(clip)
		ap.seek(0.4, true)
		ap.pause()
	for i in 4:
		await process_frame
	var hb := sk.find_bone("Head") if sk != null else -1
	if sk != null and hb < 0:
		for i in sk.get_bone_count():
			if sk.get_bone_name(i).ends_with("Head"):
				hb = i
	# (a model with no skeleton: where Player A's head bone stands)
	var head := sk.global_transform * sk.get_bone_global_pose(hb).origin if sk != null else Vector3(0.0101, 1.5063, -0.038)
	var face := head + Vector3(0, 0.07, 0.05)
	var cam := Camera3D.new()
	cam.fov = 22.0
	stage.add_child(cam)
	cam.current = true
	var views := [Vector3(0, 0, 0.75), Vector3(0.5, 0.0, 0.55), Vector3(-0.5, 0.0, 0.55), Vector3(0, -0.28, 0.7), Vector3(0, 0.3, 0.7), Vector3(0.74, 0.0, 0.0)]
	var cell := 512
	var sheet := Image.create(cell * 3, cell * 2, false, Image.FORMAT_RGB8)
	for i in views.size():
		cam.global_position = face + views[i]
		cam.look_at(face)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.resize(cell, cell)
		sheet.blit_rect(img, Rect2i(0, 0, cell, cell), Vector2i((i % 3) * cell, (i / 3) * cell))
	sheet.save_png(out)
	print("FACE: ", out)
	quit()
