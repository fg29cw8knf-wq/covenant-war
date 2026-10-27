extends SceneTree
## A character whole, from the front and the left side, in its rest pose and
## then a moment into each clip named, for checking a rig or its weights.
##   xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
##       --script res://tests/pose_peek.gd -- <out_dir> <model id> [clip,clip...] [seconds into each, default 0.5]
var out := "/tmp/pose"
var id := "player_a"
var clips: Array = ["idle"]
var at := 0.5

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: id = a[1]
	if a.size() > 2: clips = Array(a[2].split(","))
	if a.size() > 3: at = float(a[3])
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.ambient_light_energy = 0.6
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 25, 0)
	sun.light_energy = 1.6
	stage.add_child(sun)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.1
	var p: Node3D = (load("res://assets/models/characters/%s.glb" % id) as PackedScene).instantiate()
	stage.add_child(p)
	var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var views := [["front", Vector3(0, 0.95, 5)], ["side", Vector3(5, 0.95, 0)], ["threeq", Vector3(3.5, 0.95, 3.5)]]
	for v in views:
		cam.position = v[1]
		cam.look_at(Vector3(0, 0.95, 0))
		await _shot("rest_" + v[0])
	for c in clips:
		if ap == null or not ap.has_animation(c):
			continue
		ap.play(c)
		ap.seek(at, true)
		ap.pause()
		for v in views:
			cam.position = v[1]
			cam.look_at(Vector3(0, 0.95, 0))
			await _shot(c + "_" + v[0])
	quit()
