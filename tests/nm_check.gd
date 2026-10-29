extends SceneTree
## The character normal-map shader (assets/shaders/character_nm.gdshader)
## against StandardMaterial3D with the same normal map on the unskinned mesh
## (which the Compatibility renderer draws right): each of the four ways its
## frame's axes can run, the face from three sides, and how far each is from
## StandardMaterial3D's picture; and the rigged model with the shader, from
## the same sides, for looking at.
##   xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 --resolution 512x512 \
##       --script res://tests/nm_check.gd -- <out_dir> <static.glb> <rigged.glb> <normal.png>
var out := "/tmp/nm"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.2, 0.22, 0.27)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.62, 0.6, 0.6)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	stage.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-25, 25, 0)
	key.light_energy = 1.25
	stage.add_child(key)
	var cam := Camera3D.new()
	cam.fov = 22.0
	stage.add_child(cam)
	cam.current = true
	var face := Vector3(0.0101, 1.5763, 0.012)
	var views := [Vector3(0, 0, 0.75), Vector3(0.5, 0.0, 0.55), Vector3(-0.5, 0.0, 0.55)]
	var ref: Node3D = (load(a[1]) as PackedScene).instantiate()
	stage.add_child(ref)
	var shots := {}
	shots["ref"] = await _views(cam, face, views)
	var mi: MeshInstance3D = ref.find_children("*", "MeshInstance3D", true, false)[0]
	var std := mi.mesh.surface_get_material(0) as StandardMaterial3D
	var sm := ShaderMaterial.new()
	sm.shader = load("res://assets/shaders/character_nm.gdshader")
	sm.set_shader_parameter("albedo_tex", std.albedo_texture)
	sm.set_shader_parameter("mr_tex", std.roughness_texture)
	sm.set_shader_parameter("normal_tex", load(a[3]))
	mi.material_override = sm
	var best := ""
	var best_d := INF
	for st in [1.0, -1.0]:
		for sb in [1.0, -1.0]:
			sm.set_shader_parameter("sign_t", st)
			sm.set_shader_parameter("sign_b", sb)
			var imgs: Array = await _views(cam, face, views)
			var d := 0.0
			for i in imgs.size():
				d += _diff(imgs[i], shots["ref"][i])
			var nm := "t%+d b%+d" % [int(st), int(sb)]
			print("NM CHECK: %s  mean difference %.2f" % [nm, d / imgs.size()])
			shots[nm] = imgs
			if d < best_d:
				best_d = d
				best = nm
	print("NM CHECK: best ", best)
	ref.queue_free()
	await process_frame
	# the rigged model with the shader at the best signs
	var rig: Node3D = (load(a[2]) as PackedScene).instantiate()
	stage.add_child(rig)
	var rmi: MeshInstance3D = rig.find_children("*", "MeshInstance3D", true, false)[0]
	var rsm := sm.duplicate() as ShaderMaterial
	rsm.set_shader_parameter("sign_t", 1.0 if best.contains("t+1") else -1.0)
	rsm.set_shader_parameter("sign_b", 1.0 if best.contains("b+1") else -1.0)
	rmi.material_override = rsm
	shots["rigged"] = await _views(cam, face, views)
	var rows := ["ref", best, "rigged"]
	var sheet := Image.create(512 * views.size(), 512 * rows.size(), false, Image.FORMAT_RGB8)
	for r in rows.size():
		for i in views.size():
			sheet.blit_rect(shots[rows[r]][i], Rect2i(0, 0, 512, 512), Vector2i(i * 512, r * 512))
	sheet.save_png(out + "/nm_check.png")
	print("NM CHECK: rigged vs reference %.2f" % ((_diff(shots["rigged"][0], shots["ref"][0]) + _diff(shots["rigged"][1], shots["ref"][1]) + _diff(shots["rigged"][2], shots["ref"][2])) / 3.0))
	quit()

func _views(cam: Camera3D, face: Vector3, views: Array) -> Array:
	var res := []
	for v in views:
		cam.global_position = face + v
		cam.look_at(face)
		for k in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.resize(512, 512)
		res.append(img)
	return res

func _diff(x: Image, y: Image) -> float:
	var d := 0.0
	var n := 0
	for yy in range(0, 512, 4):
		for xx in range(0, 512, 4):
			var c1 := x.get_pixel(xx, yy)
			var c2 := y.get_pixel(xx, yy)
			d += absf(c1.r - c2.r) + absf(c1.g - c2.g) + absf(c1.b - c2.b)
			n += 1
	return d / n * 255.0
