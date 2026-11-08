extends SceneTree
## Bram in his coat (the Night of the White Sky) walking at the memory's pace,
## from behind (as the game films him), from the side and from the front
## quarter, at six moments of a stride, against a plumb line; with options to
## try the taproom Bram's own walk on him, or to leave his posture off
## (6 November, Gary: "Bram still walks very weird at start of game").
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 800x500 --path . --script res://tests/coat_walk_peek.gd -- <out_dir> <tag> [donor=bram] [noposture] [pace=1.3]
var out := "/tmp/coat_walk"
var tag := "now"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: tag = a[1]
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
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.ambient_light_energy = 0.8
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 60, 0)
	sun.light_energy = 1.4
	stage.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	var ck := NoiseTexture2D.new()
	ck.noise = FastNoiseLite.new()
	ck.width = 256
	ck.height = 256
	fm.albedo_texture = ck
	fm.uv1_scale = Vector3(8, 8, 8)
	floor_mi.material_override = fm
	stage.add_child(floor_mi)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 34.0
	cam.current = true
	var f := Figure3D.make("bram_coat", "bram_coat") as Figure3D
	stage.add_child(f)
	f.snap_face(Vector3.FORWARD)
	for k in 6:
		await process_frame
	if a.has("noposture") and f._skel.has_node("Posture"):
		f._skel.get_node("Posture").free()
	for s in a:
		if String(s).begins_with("posture="):
			# posture=Spine:6,0,0;Neck:-4,0,0 in place of POSTURE's
			if f._skel.has_node("Posture"):
				f._skel.get_node("Posture").free()
			var pq := Figure3D.Posture.new()
			pq.name = "Posture"
			for part in String(s).substr(8).split(";"):
				var kv := part.split(":")
				var ev := kv[1].split(",")
				pq.turns.append([f._skel.find_bone(kv[0]), Quaternion.from_euler(Vector3(deg_to_rad(float(ev[0])), deg_to_rad(float(ev[1])), deg_to_rad(float(ev[2]))))])
			f._skel.add_child(pq)
			f._skel.move_child(pq, 0)
	for s in a:
		if String(s).begins_with("donor="):
			var d := Figure3D._donor_clip(String(s).substr(6), "walk")
			if not d.is_empty():
				var clip := (d.clip as Animation).duplicate(true)
				f._fit(clip, float(d.hips))
				clip.loop_mode = Animation.LOOP_LINEAR
				f.anim.get_animation_library("").remove_animation("walk")
				f.anim.get_animation_library("").add_animation("walk", clip)
				print("walk from ", String(s).substr(6))
	var pace := 1.3
	for s in a:
		if String(s).begins_with("pace="):
			pace = float(String(s).substr(5))
	f.walking = true
	f.pace = pace
	# walk along -z at the pace; the cameras ride with him
	var t := 0.0
	var dt := 1.0 / 30.0
	var n := 0
	var len := f.anim.get_animation("walk").length / maxf(0.01, f.anim.speed_scale) if f.anim.has_animation("walk") else 1.0
	for k in 6:
		var until := t + 0.16
		while t < until:
			await process_frame
			t += dt
			f.position.z -= pace * dt
		var p := f.position
		cam.global_position = p + Vector3(0.0, 1.35, 3.3)
		cam.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
		await _shot("%s_back_%d" % [tag, k])
		cam.global_position = p + Vector3(3.4, 1.05, 0.0)
		cam.look_at(p + Vector3(0, 0.95, 0), Vector3.UP)
		await _shot("%s_side_%d" % [tag, k])
		n += 1
	print("COAT WALK PEEK: done in ", out, " (speed_scale ", f.anim.speed_scale, ")")
	quit()
