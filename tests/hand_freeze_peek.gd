extends SceneTree
## A figure's hands, each from four sides, with the figure frozen at a
## moment of a clip (11 November, Gary: "In the opening bit of the game
## brams left hand is deformed"; the hunter's right hand before the duel):
## any model by its name, idle, walking, the bind pose itself ("rest"), or
## with its finger and thumb bones left as the model has them ("nofingers":
## the clip's tracks for every bone below the hand taken off).
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 640x480 --path . --script res://tests/hand_freeze_peek.gd -- <out_dir> <model> [idle|walk|rest|<clip>] [at seconds, default 0.6] [nofingers] [whole]
var out := "/tmp/handfreeze"
var model := "bram_coat"
var clip := "idle"
var at := 0.6


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: model = a[1]
	if a.size() > 2: clip = a[2]
	if a.size() > 3 and String(a[3]).is_valid_float(): at = float(a[3])
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.75)
	e.ambient_light_energy = 0.9
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 60, 0)
	sun.light_energy = 1.3
	stage.add_child(sun)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 26.0
	cam.current = true
	var f := Figure3D.make(model, model) as Figure3D
	stage.add_child(f)
	f.snap_face(Vector3.BACK)
	for k in 10:
		await process_frame
	var sk: Skeleton3D = f._skel
	if clip == "rest":
		f.anim.stop()
		f.set_process(false)
		for c in sk.get_children():
			if c is SkeletonModifier3D:
				(c as SkeletonModifier3D).active = false
		sk.reset_bone_poses()
	else:
		if clip == "walk":
			f.walking = true
		elif clip != "idle":
			f.hold(clip)
		await create_timer(at).timeout
		if "nofingers" in a:
			# the clip's hold on everything below each hand taken off, and
			# those bones put back as the model has them
			for side in ["Left", "Right"]:
				var hb := sk.find_bone(side + "Hand")
				for b in sk.get_bone_count():
					var p := sk.get_bone_parent(b)
					var under := false
					while p >= 0:
						if p == hb:
							under = true
							break
						p = sk.get_bone_parent(p)
					if under:
						sk.set_bone_pose_rotation(b, sk.get_bone_rest(b).basis.get_rotation_quaternion())
			f.anim.pause()
		else:
			f.anim.pause()
		f.set_process(false)
	await process_frame
	# what each finger bone is turned by from the model's own rest, in degrees
	for side in ["Left", "Right"]:
		var hb := sk.find_bone(side + "Hand")
		var row := []
		for b in sk.get_bone_count():
			if sk.get_bone_parent(b) == hb or (sk.get_bone_parent(b) >= 0 and sk.get_bone_parent(sk.get_bone_parent(b)) == hb):
				var d := rad_to_deg(sk.get_bone_pose_rotation(b).angle_to(sk.get_bone_rest(b).basis.get_rotation_quaternion()))
				row.append("%s %.0f" % [sk.get_bone_name(b).replace(side + "Hand", ""), d])
		var hr := rad_to_deg(sk.get_bone_pose_rotation(hb).angle_to(sk.get_bone_rest(hb).basis.get_rotation_quaternion()))
		print("HAND FREEZE: %s %s %s: wrist %.0f from rest; fingers from rest: %s" % [model, clip, side, hr, ", ".join(row)])
	if "whole" in a:
		cam.fov = 30.0
		for v in [["front", Vector3(0, 0.2, 3.6)], ["back", Vector3(0, 0.6, -3.6)], ["left", Vector3(3.6, 0.2, 0)], ["right", Vector3(-3.6, 0.2, 0)]]:
			cam.global_position = Vector3(0, 1.0, 0) + (v[1] as Vector3)
			cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
			await _shot("%s_%s_whole_%s" % [model, clip, v[0]])
	for side in ["Left", "Right"]:
		var hb := sk.find_bone(side + "Hand")
		var hp := sk.global_transform * sk.get_bone_global_pose(hb).origin
		# the hand's middle: half way to the furthest bone below it
		var far := hp
		for b in sk.get_bone_count():
			var p := sk.get_bone_parent(b)
			var under := false
			while p >= 0:
				if p == hb:
					under = true
					break
				p = sk.get_bone_parent(p)
			if under:
				var bp := sk.global_transform * sk.get_bone_global_pose(b).origin
				if bp.distance_to(hp) > far.distance_to(hp):
					far = bp
		var mid := hp.lerp(far, 0.6)
		var sx := 1.0 if side == "Left" else -1.0
		for v in [["front", Vector3(0.1 * sx, 0.15, 0.8)], ["back", Vector3(0.1 * sx, 0.3, -0.8)], ["out", Vector3(0.8 * sx, 0.15, 0.1)], ["above", Vector3(0.05 * sx, 0.8, 0.12)]]:
			cam.global_position = mid + (v[1] as Vector3)
			cam.look_at(mid, Vector3.UP)
			await _shot("%s_%s_%s_%s" % [model, clip, side.to_lower(), v[0]])
	print("HAND FREEZE: stills in %s" % out)
	quit()
