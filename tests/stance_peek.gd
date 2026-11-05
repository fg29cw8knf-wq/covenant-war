extends SceneTree
## How a model carries itself: standing and walking, from the side and from
## behind, on a plain stage, with a plumb line drawn up from its feet so a
## rounded back or a head pushed forward shows against it (5 November, Gary:
## "Bram looks hunched over. Have him stand up straight": Figure3D.POSTURE).
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --resolution 1000x600 \
##       --script res://tests/stance_peek.gd -- <out_dir> [model, default bram_coat] [tag]
var out := "/tmp/stance"
var model := "bram_coat"
var tag := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: model = a[1]
	if a.size() > 2: tag = a[2]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _shot(name: String) -> void:
	for k in 2:
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
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(6, 6)
	floor_mi.mesh = pm
	stage.add_child(floor_mi)
	# a plumb line a little behind where he stands, seen from the side
	var line := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.01, 2.2, 0.01)
	line.mesh = lm
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.2, 0.2)
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = red
	line.position = Vector3(0, 1.1, 0.0)
	stage.add_child(line)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 32.0
	cam.current = true
	var f := Figure3D.make(model, model) as Figure3D
	stage.add_child(f)
	f.snap_face(Vector3.FORWARD)
	for k in 12:
		await process_frame
	var pre := model + ("_" + tag if tag != "" else "")
	var shots := func(nm: String) -> void:
		cam.global_position = Vector3(3.4, 1.1, 0.0)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		await _shot("%s_%s_side" % [pre, nm])
		cam.global_position = Vector3(0.0, 1.4, 3.6)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		await _shot("%s_%s_back" % [pre, nm])
		cam.global_position = Vector3(2.4, 1.6, 2.6)
		cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
		await _shot("%s_%s_quarter" % [pre, nm])
	await shots.call("stand")
	f.walking = true
	f.pace = 1.3
	for k in 3:
		await create_timer(0.35).timeout
		await shots.call("walk%d" % k)
	print("STANCE PEEK: done in ", out)
	quit()
