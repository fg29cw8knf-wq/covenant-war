extends SceneTree
## Side and front views of a character's head, at rest and in a few clips,
## one still each, for checking how a clip carries the head (chin up or down,
## the neck stretched). Several models can be given, for comparing them.
##   xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 480x480 \
##       --script res://tests/head_peek.gd -- <out_dir> <id[,id...]> [clip,clip...]
## (a model id can be a path to a .glb: res://... or an absolute path in the project)
var out := "/tmp/head"
var ids: Array = ["player_a"]
var clips: Array = ["idle", "talk", "walk"]

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: ids = Array(a[1].split(","))
	if a.size() > 2: clips = Array(a[2].split(","))
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
	e.ambient_light_color = Color(0.6, 0.6, 0.64)
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 25, 0)
	sun.light_energy = 1.4
	stage.add_child(sun)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 22
	for id in ids:
		var path := String(id) if String(id).ends_with(".glb") else "res://assets/models/characters/%s.glb" % id
		var tag := String(id).get_file().get_basename()
		var p: Node3D = (load(path) as PackedScene).instantiate()
		Figure3D.dress_normal_map(p, tag)
		stage.add_child(p)
		var sk := p.find_child("Skeleton3D", true, false) as Skeleton3D
		var hy := sk.get_bone_global_rest(sk.find_bone("Head")).origin.y + 0.05
		var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var views := [["side", Vector3(1.6, hy, 0.0)], ["front", Vector3(0.0, hy, 1.6)]]
		for v in views:
			cam.position = v[1]
			cam.look_at(Vector3(0, hy - 0.08, 0.0))
			await _shot("%s_rest_%s" % [tag, v[0]])
		for c in clips:
			if ap == null or not ap.has_animation(c):
				continue
			ap.play(c)
			ap.seek(minf(0.6, ap.get_animation(c).length * 0.3), true)
			ap.pause()
			# the hips move in some clips: keep the head in frame
			var hb := sk.find_bone("Head")
			var hp := (sk.global_transform * sk.get_bone_global_pose(hb)).origin
			for v in views:
				var off: Vector3 = v[1] - Vector3(0, hy, 0)
				cam.position = Vector3(hp.x, hp.y + 0.05, hp.z) + off
				cam.look_at(Vector3(hp.x, hp.y - 0.03, hp.z))
				await _shot("%s_%s_%s" % [tag, c, v[0]])
		p.queue_free()
		await process_frame
	quit()
