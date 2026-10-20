extends SceneTree
## Renders a character model beside the cast, close up, and in every clip
## (five moments each) to PNGs, for checking a new or rebuilt model.
##   xvfb-run -a -s "-screen 0 800x800x24" godot --rendering-driver opengl3 --resolution 640x640 \
##       --script res://tests/model_sheet.gd -- <out_dir> [model id, default player_a] [clip,clip... | none]
## (a list of clips renders only those; "none" just the cast and the close-ups)
const CAST := ["player_a", "player_b", "player_c", "player_d", "bram", "corin", "tam", "tilly", "nell", "hob"]
const BENCH := 0.45   # a bench's seat (m)
var out := "/tmp/sheet"
var id := "player_a"
var only: Array = []
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: id = a[1]
	if a.size() > 2: only = Array(a[2].split(","))
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func _setup_stage() -> Node3D:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.45, 0.5)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.55, 0.6)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	stage.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_energy = 0.5
	stage.add_child(fill)
	var floor := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(20, 20)
	floor.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.35, 0.33, 0.3)
	floor.material_override = fm
	stage.add_child(floor)
	return stage

func _model(path: String) -> Node3D:
	var m: Node3D = (load(path) as PackedScene).instantiate()
	return m

func _shot(cam: Camera3D, name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out + "/" + name + ".png")

func _run() -> void:
	var stage := _setup_stage()
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.current = true
	# 1) the cast side by side, idle
	var cast := [id]
	for c in CAST:
		if c != id: cast.append(c)
	var models := []
	for i in cast.size():
		var m := _model("res://assets/models/characters/%s.glb" % cast[i])
		stage.add_child(m)
		m.position = Vector3((i - (cast.size() - 1) * 0.5) * 0.95, 0, 0)
		var ap := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap and ap.has_animation("idle"): ap.play("idle")
		models.append(m)
	cam.fov = 40
	cam.position = Vector3(0, 1.1, 7.4)
	cam.look_at(Vector3(0, 0.9, 0))
	await _shot(cam, "cast_front")
	cam.position = Vector3(6.4, 1.1, 2.9)
	cam.look_at(Vector3(0, 0.9, 0))
	await _shot(cam, "cast_side")
	for m in models: m.queue_free()
	# 2) the model alone, front, back, face and three-quarter
	var p := _model("res://assets/models/characters/%s.glb" % id)
	stage.add_child(p)
	var ap := p.find_child("AnimationPlayer", true, false) as AnimationPlayer
	ap.deterministic = true
	ap.play("idle")
	cam.fov = 30
	# the face close-up aims at their head, however tall they are
	var sk := p.find_child("Skeleton3D", true, false) as Skeleton3D
	var hy := 1.5
	if sk != null and sk.find_bone("Head") >= 0:
		hy = sk.get_bone_global_rest(sk.find_bone("Head")).origin.y + 0.08
	for v in [["front", Vector3(0, 1.0, 4.4), Vector3(0, 0.9, 0)], ["back", Vector3(0, 1.0, -4.4), Vector3(0, 0.9, 0)], ["face", Vector3(0.35, hy + 0.05, 1.2), Vector3(0.0, hy, 0)], ["threeq", Vector3(2.6, 1.3, 3.2), Vector3(0, 0.9, 0)]]:
		cam.position = v[1]
		cam.look_at(v[2])
		await _shot(cam, id + "_" + v[0])
	# 3) every clip at five moments, from the three-quarter view
	cam.fov = 34
	cam.position = Vector3(3.0, 1.4, 4.2)
	cam.look_at(Vector3(0, 0.85, 0.3))
	var clips := ap.get_animation_list()
	for c in clips:
		if not only.is_empty() and not only.has(String(c)): continue
		var an := ap.get_animation(c)
		for k in 5:
			ap.play(c)
			ap.seek(an.length * k / 4.0 * 0.999, true)
			ap.pause()
			await _shot(cam, "clip_%s_%d" % [c, k])
	p.queue_free()
	# 4) the cast sitting on a bench (Figure3D.sit), still and talking
	var bench := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(6.4, 0.06, 0.4)
	bench.mesh = bm
	bench.position = Vector3(0, BENCH - 0.03, -0.05)
	stage.add_child(bench)
	var figs := []
	for i in cast.size():
		var f := Figure3D.make("player" if cast[i] == "player_a" else cast[i], "" if cast[i] == "player_a" else cast[i]) as Figure3D
		stage.add_child(f)
		f.position = Vector3((i - (cast.size() - 1) * 0.5) * 0.95, 0, 0)
		f.snap_face(Vector3.BACK)
		f.sit(BENCH, 0.0)
		figs.append(f)
	for i in 20: await process_frame
	cam.fov = 40
	cam.position = Vector3(0, 1.0, 7.8)
	cam.look_at(Vector3(0, 0.7, 0))
	await _shot(cam, "seated_front")
	cam.position = Vector3(5.4, 1.3, 5.2)
	cam.look_at(Vector3(0, 0.6, 0))
	await _shot(cam, "seated_threeq")
	cam.fov = 30
	cam.position = Vector3(-(cast.size() - 1) * 0.5 - 2.6, 0.8, 1.6)
	cam.look_at(Vector3(-(cast.size() - 1) * 0.5, 0.6, 0.2))
	await _shot(cam, "seated_side_" + id)
	for f in figs: f.talking = true
	for i in 30: await process_frame
	cam.fov = 40
	cam.position = Vector3(0, 1.0, 7.8)
	cam.look_at(Vector3(0, 0.7, 0))
	await _shot(cam, "seated_talk")
	quit()
