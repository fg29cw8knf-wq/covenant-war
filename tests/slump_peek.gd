extends SceneTree
## Someone beaten (Figure3D.slump), from the front, the three-quarter and the
## side, next to them standing in their idle, for checking the pose reads as
## defeated rather than scared (Corin after the Lantern Duel, 27 October).
##   xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
##       --script res://tests/slump_peek.gd -- <out_dir> [look, default corin] [amount, default 1]
var out := "/tmp/slump"
var look := "corin"
var amount := 1.0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: look = a[1]
	if a.size() > 2: amount = float(a[2])
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
	var body := Node3D.new()
	stage.add_child(body)
	var f = Figure3D.make(look, look)
	body.add_child(f)
	for i in 20:
		await process_frame
	var views := [["front", Vector3(0, 0.95, 5)], ["threeq", Vector3(3.5, 0.95, 3.5)], ["side", Vector3(5, 0.95, 0)]]
	for v in views:
		cam.position = v[1]
		cam.look_at(Vector3(0, 0.95, 0))
		await _shot("idle_" + v[0])
	if f is Figure3D:
		(f as Figure3D).slump(amount, 0.3)
	for i in 60:
		await process_frame
	for v in views:
		cam.position = v[1]
		cam.look_at(Vector3(0, 0.95, 0))
		await _shot("slump_" + v[0])
	quit()
