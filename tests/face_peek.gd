extends SceneTree
## A close look at a character's face: the real model in its rest pose and
## in its idle, and the bare mesh (one grey material, no texture) so the
## geometry of the eyes and mouth can be read on its own.
##   xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
##       --script res://tests/face_peek.gd -- <out_dir> <model id> [clip]
var out := "/tmp/face"
var id := "bram"
var clip := "idle"

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: id = a[1]
	if a.size() > 2: clip = a[2]
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
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.ambient_light_energy = 0.6
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 25, 0)
	sun.light_energy = 1.6
	stage.add_child(sun)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	cam.fov = 18
	var p: Node3D = (load("res://assets/models/characters/%s.glb" % id) as PackedScene).instantiate()
	stage.add_child(p)
	var sk := p.find_child("Skeleton3D", true, false) as Skeleton3D
	var hy := 1.6
	if sk != null and sk.find_bone("Head") >= 0:
		hy = sk.get_bone_global_rest(sk.find_bone("Head")).origin.y + 0.1
	var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for v in [["rest_front", Vector3(0, hy, 1.4)], ["rest_threeq", Vector3(0.6, hy + 0.05, 1.25)]]:
		cam.position = v[1]
		cam.look_at(Vector3(0, hy - 0.02, 0.05))
		await _shot(v[0])
	# the bare geometry
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.75, 0.72, 0.68)
	grey.roughness = 0.8
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = grey
	for v in [["mesh_front", Vector3(0, hy, 1.4)], ["mesh_threeq", Vector3(0.6, hy + 0.05, 1.25)]]:
		cam.position = v[1]
		cam.look_at(Vector3(0, hy - 0.02, 0.05))
		await _shot(v[0])
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = null
	if ap and ap.has_animation(clip):
		ap.play(clip)
		ap.seek(0.6, true)
		for v in [["clip_front", Vector3(0, hy, 1.4)], ["clip_threeq", Vector3(0.6, hy + 0.05, 1.25)]]:
			cam.position = v[1]
			cam.look_at(Vector3(0, hy - 0.02, 0.05))
			await _shot(v[0])
	quit()
