extends SceneTree
## Renders any .glb file (a path on disk, not only res://) from four sides,
## framed on its bounds, for a first look at a model as it arrives:
##   xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 \
##       --script res://tests/glb_peek.gd -- <out.png> <model.glb> [clip] [time]
## A clip name poses it at that clip's time (seconds) first.
var out := "/tmp/peek.png"
var path := ""
var clip := ""
var at := 0.0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: path = a[1]
	if a.size() > 2: clip = a[2]
	if a.size() > 3: at = float(a[3])
	_run.call_deferred()


func _aabb(n: Node, xf: Transform3D, box: Array) -> void:
	if n is Node3D:
		xf = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var b: AABB = xf * (n as MeshInstance3D).mesh.get_aabb()
		box[0] = b if box[0] == null else (box[0] as AABB).merge(b)
	for c in n.get_children():
		_aabb(c, xf, box)


func _run() -> void:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(path, st) != OK:
		push_error("can't read " + path)
		quit(1)
		return
	var model: Node3D = doc.generate_scene(st)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.6, 0.62)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.5
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -150, 0)
	fill.light_energy = 0.6
	stage.add_child(fill)
	stage.add_child(model)
	var ap := model.find_children("*", "AnimationPlayer", true, false)
	if ap.size() > 0:
		var p := ap[0] as AnimationPlayer
		print("CLIPS ", p.get_animation_list())
		if clip != "" and p.has_animation(clip):
			p.play(clip)
			p.seek(at, true)
			p.pause()
	await process_frame
	await process_frame
	var box := [null]
	_aabb(model, Transform3D.IDENTITY, box)
	var b: AABB = box[0]
	print("AABB ", b)
	var c := b.get_center()
	var r := b.size.length() * 0.5
	var cam := Camera3D.new()
	cam.fov = 35.0
	stage.add_child(cam)
	var tiles: Array[Image] = []
	for ang in [0.0, 90.0, 180.0, 40.0]:
		var dir := Vector3(sin(deg_to_rad(ang)), 0.25, cos(deg_to_rad(ang))).normalized()
		cam.global_position = c + dir * (r / tan(deg_to_rad(cam.fov * 0.5))) * 1.05
		cam.look_at(c, Vector3.UP)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		tiles.append(root.get_texture().get_image())
	var w := tiles[0].get_width()
	var h := tiles[0].get_height()
	var sheet := Image.create(w * 2, h * 2, false, tiles[0].get_format())
	for i in 4:
		sheet.blit_rect(tiles[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	sheet.save_png(out)
	print("WROTE ", out)
	quit()
