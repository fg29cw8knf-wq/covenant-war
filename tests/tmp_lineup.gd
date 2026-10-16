extends SceneTree
## TEMP: the five 3D people in a row, for scale and clips.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --script res://tests/tmp_lineup.gd -- <out dir> <clip> [at] [light]

var out := "/tmp"
var clip := "idle"
var at := 0.4
var light := "neutral"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: clip = a[1]
	if a.size() > 2: at = float(a[2])
	if a.size() > 3: light = a[3]
	var root := Node3D.new()
	get_root().add_child(root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.11, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.7)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	root.add_child(sun)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.3, 0.22)
	floor.material_override = fm
	root.add_child(floor)
	# a 1 m grid of posts for scale
	for h in [1.0, 1.25, 1.8]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(7.5, 0.01, 0.01)
		bar.mesh = bm
		bar.position = Vector3(0.0, h, -0.6)
		root.add_child(bar)
	var ids := ["bram", "corin", "player", "tam", "tilly"]
	var figs := []
	for i in ids.size():
		var b := Node3D.new()
		root.add_child(b)
		b.position = Vector3(-3.0 + i * 1.5, 0, 0)
		var f := Figure3D.make(ids[i], ids[i])
		b.add_child(f)
		figs.append(f)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 1.3, 6.5)
	cam.look_at(Vector3(0, 0.95, 0))
	cam.fov = 40
	cam.current = true
	await process_frame
	await process_frame
	for f in figs:
		(f as Figure3D).snap_face(Vector3(0, 0, 1))
		if clip != "idle":
			(f as Figure3D).pose(clip, at)
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("%s/lineup_%s.png" % [out, clip])
	# side view
	cam.position = Vector3(6.5, 1.3, 0.8)
	cam.look_at(Vector3(0, 0.95, 0))
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("%s/lineup_%s_side.png" % [out, clip])
	# faces
	for i in [3, 4, 0]:
		var f: Figure3D = figs[i]
		var hp := f.bone_pos("Head")
		cam.position = hp + Vector3(0.15, 0.08, 0.75)
		cam.look_at(hp + Vector3(0, 0.05, 0))
		cam.fov = 30
		for k in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("%s/face_%s.png" % [out, ids[i]])
	print("LINEUP done")
	quit()
