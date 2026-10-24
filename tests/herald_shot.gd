extends Node3D
## Stills of the Pale Herald by itself, for its look (v7's shroud of grey
## burial cloth and rusted chains, or v3's rider), in a plain dawn light.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 960x540 res://tests/herald_shot.tscn -- <out_dir> [shroud|rider]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://"
	var form: String = args[1] if args.size() > 1 else "shroud"
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.55, 0.52)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.52, 0.5)
	e.ambient_light_energy = 0.8
	e.fog_enabled = true
	e.fog_light_color = Color(0.7, 0.66, 0.64)
	e.fog_density = 0.02
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.82, 0.66)
	sun.light_energy = 1.1
	sun.rotation = Vector3(-0.35, -0.9, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.25, 0.3, 0.18)
	ground.material_override = gm
	add_child(ground)
	# a man's height beside it, for scale
	var man := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.25
	cm.height = 1.78
	man.mesh = cm
	man.position = Vector3(2.2, 0.89, 1.4)
	add_child(man)
	var h := PaleHerald.new()
	h.form = form
	add_child(h)
	h.snap_dir(Vector3(-1, 0, 0.3))
	var cam := Camera3D.new()
	add_child(cam)
	var shots := [[Vector3(-5.5, 1.7, 3.2), Vector3(0, 1.9, 0), 40.0], [Vector3(-2.2, 2.9, 1.2), Vector3(0, 3.2, 0), 34.0], [Vector3(-1.0, 0.6, 3.6), Vector3(0, 0.7, 0), 40.0]]
	for i in shots.size():
		var s: Array = shots[i]
		cam.position = s[0]
		cam.look_at(s[1], Vector3.UP)
		cam.fov = s[2]
		cam.make_current()
		for k in 30:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_dir.path_join("herald_%s_%d.png" % [form, i]))
	print("HERALD SHOT: done")
	get_tree().quit()
