extends Node3D
## Loads one character GLB, lists its clips, and screenshots a few of them from a
## game-like camera. Run with xvfb:
##   godot --rendering-driver opengl3 --rendering-method gl_compatibility res://tests/model_peek.tscn -- <out_dir> <res path>

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	var path: String = args[1] if args.size() > 1 else "res://assets/models/characters/bram.glb"
	var scene: PackedScene = load(path)
	var m: Node3D = scene.instantiate()
	add_child(m)
	var aabb := AABB()
	for mi in m.find_children("*", "MeshInstance3D", true):
		aabb = aabb.merge(mi.get_aabb() if aabb.size != Vector3.ZERO else mi.get_aabb()) if aabb.size != Vector3.ZERO else mi.get_aabb()
	print("MODEL: ", path, " bounds ", aabb)
	var ap: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	var clips := ap.get_animation_list() if ap else PackedStringArray()
	print("CLIPS: ", clips)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("1a2030")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.55, 0.7)
	e.ambient_light_energy = 1.2
	env.environment = e
	add_child(env)
	var cam := Camera3D.new()
	add_child(cam)
	var h := aabb.size.y
	# three-quarter view like the village camera, then a face close-up
	var views := [["full", Vector3(1.6, h * 0.65, 2.6), Vector3(0, h * 0.5, 0)],
		["face", Vector3(0.35, h * 0.92, 0.75), Vector3(0, h * 0.9, 0)]]
	var want := ["idle", "walk", "talk", "duel_idle", "play_card"]
	for v in views:
		cam.position = v[1]
		cam.look_at(v[2])
		for c in want:
			if ap and ap.has_animation(c):
				ap.play(c)
				ap.seek(ap.get_animation(c).length * 0.4, true)
			await get_tree().process_frame
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, v[0], c])
			if v[0] == "face":
				break
	print("MODEL PEEK: done")
	get_tree().quit()
