extends SceneTree
## A player's hands, close up, through the idle and the walk, on a plain
## stage: stills of the right hand and the left for checking the fingers (4
## November, Gary: "Players right hand the baby finger looks deformed").
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --resolution 1000x600 \
##       --script res://tests/hand_peek.gd -- <out_dir> [look, default a] [clip, default idle]
var out := "/tmp/hands"
var look := "a"
var clip := "idle"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: look = a[1]
	if a.size() > 2: clip = a[2]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _shot(name: String) -> void:
	for k in 3:
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
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 22.0
	cam.current = true
	var model := "player_a" if look == "a" else "player_" + look
	var f := Figure3D.make(model, model) as Figure3D
	stage.add_child(f)
	f.snap_face(Vector3.BACK)
	for k in 10:
		await process_frame
	var sk: Skeleton3D = f._skel
	if clip == "rest":
		# the bind pose itself: no clip, no modifiers
		f.anim.stop()
		f.set_process(false)
		for c in sk.get_children():
			if c is SkeletonModifier3D:
				(c as SkeletonModifier3D).active = false
		sk.reset_bone_poses()
	elif clip != "idle":
		f.walking = clip == "walk"
		if not f.walking:
			f.hold(clip)
	var n := 0
	for k in 4:
		await create_timer(0.45).timeout
		for side in ["Right", "Left"]:
			var hb := sk.find_bone(side + "Hand")
			var hp := sk.global_transform * sk.get_bone_global_pose(hb).origin
			var fwd := Vector3.BACK
			# from in front and a little above, looking at the hand
			cam.global_position = hp + fwd * 0.55 + Vector3(0.0, 0.25, 0.0) + Vector3(-0.15 if side == "Right" else 0.15, 0, 0)
			cam.look_at(hp, Vector3.UP)
			await _shot("%s_%s_%d_front" % [look, side.to_lower(), n])
			cam.global_position = hp + Vector3(-0.5 if side == "Right" else 0.5, 0.1, 0.25)
			cam.look_at(hp, Vector3.UP)
			await _shot("%s_%s_%d_side" % [look, side.to_lower(), n])
		n += 1
	print("HAND PEEK: %d stills in %s" % [n * 4, out])
	quit()
