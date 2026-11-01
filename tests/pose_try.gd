extends SceneTree
## Tries bone turns on a standing character and takes a still from the front
## and the side: for finding the axes a pose needs (a stretch, a wave).
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --resolution 1000x600 \
##       --script res://tests/pose_try.gd -- <out_dir> <model> "Bone=x,y,z;Bone=x,y,z" [name]
var out := "/tmp/pose"
var model := "player_a"
var turns := ""
var nm := "try"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: model = a[1]
	if a.size() > 2: turns = a[2]
	if a.size() > 3: nm = a[3]
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
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 60, 0)
	sun.light_energy = 1.5
	stage.add_child(sun)
	var f := Figure3D.make(model) as Figure3D
	stage.add_child(f)
	f.snap_face(Vector3.BACK)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 32.0
	cam.current = true
	for k in 10:
		await process_frame
	f.hold("idle", 1.0, 0.0)
	await process_frame
	var pm := Figure3D.Posture.new()
	pm.name = "Try"
	for part in turns.split(";", false):
		var kv := part.split("=")
		var v := kv[1].split(",")
		var ev := Vector3(float(v[0]), float(v[1]), float(v[2]))
		var i := f._skel.find_bone(kv[0])
		if i < 0:
			print("no bone ", kv[0])
			continue
		pm.turns.append([i, Quaternion.from_euler(Vector3(deg_to_rad(ev.x), deg_to_rad(ev.y), deg_to_rad(ev.z)))])
	f._skel.add_child(pm)
	f._skel.move_child(pm, 0)
	await process_frame
	cam.position = Vector3(0, 1.0, 5.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	await _shot(nm + "_front")
	cam.position = Vector3(5.0, 1.0, 0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	await _shot(nm + "_side")
	quit()
