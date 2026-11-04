extends SceneTree
## A figure going down on one knee (Figure3D.kneel) and up again, with his
## hands reaching to a bundle on the ground, on a plain stage: stills from
## the side and from behind every 0.3 s (4 November, the Night of the White
## Sky's pick-up of the child).
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --resolution 1000x600 \
##       --script res://tests/kneel_peek.gd -- <out_dir> [model, default bram_coat]
var out := "/tmp/kneel"
var model := "bram_coat"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: model = a[1]
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
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 35.0
	cam.current = true
	var f := Figure3D.make(model, model) as Figure3D
	stage.add_child(f)
	f.snap_face(Vector3.FORWARD)
	# the bundle: a small box on the ground half a metre ahead
	var bundle := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, 0.2, 0.5)
	bundle.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.6, 0.5)
	bundle.material_override = mat
	bundle.position = Vector3(0, 0.1, -0.5)
	stage.add_child(bundle)
	var l := Node3D.new()
	var r := Node3D.new()
	bundle.add_child(l)
	bundle.add_child(r)
	l.position = Vector3(0.0, -0.04, 0.15)
	r.position = Vector3(0.0, -0.05, -0.12)
	for k in 10:
		await process_frame
	var n := [0]
	var shots := func(tag: String) -> void:
		cam.global_position = Vector3(2.6, 1.3, -0.3)
		cam.look_at(Vector3(0, 0.7, -0.2), Vector3.UP)
		await _shot("%02d_%s_side" % [n[0], tag])
		cam.global_position = Vector3(0.9, 2.0, 2.4)
		cam.look_at(Vector3(0, 0.6, -0.3), Vector3.UP)
		await _shot("%02d_%s_back" % [n[0], tag])
		n[0] += 1
	await shots.call("stand")
	f.kneel(1.0)
	await create_timer(0.4).timeout
	f.reach(l, r, 0.7)
	for k in 5:
		await create_timer(0.3).timeout
		await shots.call("down")
	# up with it
	bundle.reparent(f._pivot, true)
	var p0 := bundle.position
	var p1 := f.hold_point(0.38, 0.5)
	f.rise(1.3)
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		bundle.position = p0.lerp(p1, smoothstep(0.0, 1.0, u)), 0.0, 1.0, 1.3)
	for k in 5:
		await create_timer(0.3).timeout
		await shots.call("up")
	print("KNEEL PEEK: %d stills in %s" % [n[0] * 2, out])
	quit()
