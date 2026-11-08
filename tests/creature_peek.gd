extends Node
## Close stills of one creature or character model on its own, lit, from the
## front and three-quarters, at rest and part-way through chosen clips: for
## checking a new model Gary has made before it goes on the field (8 November:
## the Scrivener, Loomwarden, the Unspent Hour, the Weft Serpent, Kaethis).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/creature_peek.tscn -- <out_dir> <path under assets/models, e.g. creatures/scrivener> [clip,clip,...]
## (tests/model_peek.tscn is the older look at a character, by its res path.)
## Writes <id>_front.png, <id>_quarter.png, <id>_back.png and <id>_<clip>.png
## (each clip at 40% of its length, from the front). Also prints the clip list
## and the model's size, so a missing duel clip shows up here.

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out: String = a[0] if a.size() > 0 else "user://"
	var which: String = a[1] if a.size() > 1 else "creatures/cinderpup"
	var clips: PackedStringArray = (a[2] if a.size() > 2 else "attack,hit,ko,summon,victory,guard").split(",")
	var id := which.get_file()
	var path := "res://assets/models/%s.glb" % which
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("no model at " + path)
		get_tree().quit(1)
		return
	var world := Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.22)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.6, 0.75)
	e.ambient_light_energy = 0.7
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_hdr_threshold = 1.0
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.6
	sun.light_color = Color(1.0, 0.95, 0.88)
	sun.shadow_enabled = true
	world.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -120, 0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.7, 0.8, 1.0)
	world.add_child(fill)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12, 12)
	floor.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.25, 0.27, 0.3)
	floor.material_override = fm
	world.add_child(floor)
	var inst := scene.instantiate() as Node3D
	world.add_child(inst)
	DuelField3D._dress_model(inst)
	var aabb := DuelField3D._merged_aabb(inst)
	print("CREATURE PEEK %s: size %s, floor at %.3f, centre x %.3f z %.3f" % [id, aabb.size, aabb.position.y, aabb.get_center().x, aabb.get_center().z])
	var anim := DuelField3D._find_anim(inst)
	if anim != null:
		print("  clips: ", ", ".join(anim.get_animation_list()))
		for want in ["idle", "attack", "hit", "ko", "summon", "victory", "run", "guard", "rest"]:
			var real := DuelField3D._clip_in(anim, want)
			print("  %-8s -> %s" % [want, real if real != "" else "(none)"])
	var cam := Camera3D.new()
	world.add_child(cam)
	var h := maxf(aabb.size.y, maxf(aabb.size.x, aabb.size.z) * 0.8)
	var c := aabb.get_center()
	cam.fov = 35
	var dist := h * 2.3
	var views := {"front": Vector3(0, c.y + h * 0.15, c.z + dist), "quarter": Vector3(dist * 0.7, c.y + h * 0.35, c.z + dist * 0.7), "back": Vector3(0, c.y + h * 0.15, c.z - dist)}
	await _settle()
	if anim != null:
		var idle := DuelField3D._clip_in(anim, "idle")
		if idle != "":
			anim.play(idle)
			anim.seek(0.5, true)
			anim.pause()
	for v in views:
		cam.position = views[v]
		cam.look_at(Vector3(c.x, c.y, c.z))
		await _settle()
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, id, v])
	if anim != null:
		cam.position = views["quarter"]
		cam.look_at(Vector3(c.x, c.y, c.z))
		for want in clips:
			var real := DuelField3D._clip_in(anim, want)
			if real == "":
				continue
			anim.play(real)
			anim.seek(anim.get_animation(real).length * 0.4, true)
			anim.pause()
			await _settle()
			get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, id, want])
	print("CREATURE PEEK: saved")
	get_tree().quit()


func _settle() -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
