extends SceneTree
## Full-length side views of characters standing and walking, side by side,
## for checking how they carry themselves (1 November, Gary: "Player A looks
## a bit hunched over"). One still per clip moment.
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --resolution 1000x600 \
##       --script res://tests/posture_peek.gd -- <out_dir> [ids, default player_a,player_b,corin,bram] [clips, default idle,walk,talk] [moments, default 0.15,0.45,0.75]
var out := "/tmp/posture"
var ids: Array = ["player_a", "player_b", "corin", "bram"]
var clips: Array = ["idle", "walk", "talk"]
var marks: Array = [0.15, 0.45, 0.75]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: ids = Array(a[1].split(","))
	if a.size() > 2: clips = Array(a[2].split(","))
	if a.size() > 3: marks = Array(a[3].split(",")).map(func(x): return float(x))
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
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	floor_mi.mesh = pm
	stage.add_child(floor_mi)
	var figs: Array = []
	for i in ids.size():
		var f := Figure3D.make(String(ids[i])) as Figure3D
		stage.add_child(f)
		f.position = Vector3(i * 0.9 - (ids.size() - 1) * 0.45, 0, 0)
		f.snap_face(Vector3.RIGHT * -1.0)
		figs.append(f)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.position = Vector3(0, 0.95, 6.5)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	cam.fov = 32.0
	cam.current = true
	for k in 10:
		await process_frame
	for clip in clips:
		for f in figs:
			(f as Figure3D).hold(String(clip), 1.0, 0.0)
		for m in marks.size():
			for k in 2:
				await process_frame
			for f in figs:
				var fg := f as Figure3D
				if fg.anim != null and fg.anim.current_animation_length > 0.0:
					fg.anim.seek(fg.anim.current_animation_length * float(marks[m]), true)
			await _shot("%s_%d" % [clip, m])
	quit()
