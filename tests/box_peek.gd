extends SceneTree
## Bram's card box on its own, shut and open, close up from the front, the
## three-quarter and above (ashford.gd _card_box: Gary's card_box.glb when
## it's there, else the drawn oak case), for checking how it looks.
##   xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
##       --script res://tests/box_peek.gd -- <out_dir>
var out := "/tmp/box"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.3, 0.33, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.58, 0.55)
	e.ambient_light_energy = 0.5
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.5
	stage.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	stage.add_child(cam)
	cam.current = true
	var area = load("res://scripts/world/areas/ashford.gd")
	var box: Node3D = area._card_box()
	stage.add_child(box)
	var views := [["front", Vector3(0, 0.05, 0.42)], ["threeq", Vector3(0.3, 0.18, 0.3)], ["above", Vector3(0.0, 0.4, 0.15)]]
	for v in views:
		cam.position = v[1]
		cam.look_at(Vector3.ZERO)
		await _shot("shut_" + v[0])
	var lid := box.find_child("Lid", true, false) as Node3D   # (Gary's model: inside it)
	if lid != null:
		lid.rotation.x = deg_to_rad(-105.0)
	for v in views:
		cam.position = v[1]
		cam.look_at(Vector3.ZERO)
		await _shot("open_" + v[0])
	quit()
