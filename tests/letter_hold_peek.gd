extends SceneTree
## The player reading Tam's letter as AshfordP1.tam_letter_read holds it, on a
## plain stage (9 November: with Figure3D.OPEN_FLAT gone for Player A, his
## hands at its sides are as he modelled them, no longer opened): the hands'
## skin against the letter (tests/hand_skin.gd), and stills from in front,
## both sides and over the shoulder.
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 800x600 --path . --script res://tests/letter_hold_peek.gd -- <out_dir> [a|b|c|d]
## Ends "LETTER HOLD: <n> vertices in the letter".
var out := "/tmp/letterhold"
var look := "a"


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	if a.size() > 1: look = a[1]
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _shot(name: String) -> void:
	for k in 3:
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
	e.ambient_light_color = Color(0.6, 0.6, 0.65)
	e.ambient_light_energy = 0.7
	env.environment = e
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 60, 0)
	sun.light_energy = 1.5
	stage.add_child(sun)
	var cam := Camera3D.new()
	stage.add_child(cam)
	cam.fov = 30.0
	cam.current = true
	var body := Node3D.new()
	stage.add_child(body)
	var model: String = "player" if look == "a" else ("player_" + look)
	var f := Figure3D.make(model, model) as Figure3D
	body.add_child(f)
	f.snap_face(Vector3.BACK)
	for k in 10:
		await process_frame
	# the letter as the game makes it (AshfordP1.letter), held as tam_letter_read holds it
	var l := Node3D.new()
	l.name = "Letter"
	var paper := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.14, 0.095, 0.006)
	paper.mesh = bm
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.88, 0.82, 0.68)
	paper.material_override = pm
	l.add_child(paper)
	for s in [["L", 1.0], ["R", -1.0]]:
		var g := Node3D.new()
		g.name = String(s[0])
		g.position = Vector3(0.065 * float(s[1]), -0.01, -0.01)
		l.add_child(g)
	f.carry(l, Vector3(0.0, 1.22, 0.3))
	l.rotation = Vector3(-0.5, 0.0, 0.0)
	f.palm("left", Vector3.RIGHT * -1.0, 0.0, 1.0, true, Vector3(0.0, 0.85, -0.5))
	f.palm("right", Vector3.RIGHT, 0.0, 1.0, true, Vector3(0.0, 0.85, -0.5))
	f.reach(l.get_node("L"), l.get_node("R"), 0.0)
	await create_timer(0.8).timeout
	var hs = load("res://tests/hand_skin.gd").new()
	hs.setup(f)
	var res := [0, 0.0]
	var once := [false]
	var cb := func() -> void:
		if once[0]:
			return
		once[0] = true
		var bx := l.global_transform.affine_inverse()
		for side in ["left", "right"]:
			var r: Array = hs.in_box(side, bx, Vector3(0.07, 0.0475, 0.003), 0.0)
			print("  %s hand: %d vertices in the letter (deepest %.1f cm)" % [side, r[1], float(r[0]) * 100.0])
			res[0] += int(r[1])
			res[1] = maxf(float(res[1]), float(r[0]))
	f._skel.skeleton_updated.connect(cb)
	while not once[0]:
		await process_frame
	var at := l.global_position
	var fwd := f.facing()
	var side := fwd.cross(Vector3.UP)
	var views := {"front": at + fwd * 0.7 + Vector3(0, 0.05, 0), "right": at + side * 0.6, "left": at - side * 0.6,
		"reader": at - fwd * 0.45 + Vector3(0, 0.35, 0) + side * 0.12}
	for k in views:
		cam.global_position = views[k]
		cam.look_at(at, Vector3.UP)
		await _shot("%s_letter_%s" % [look, k])
	print("LETTER HOLD: %d vertices in the letter (deepest %.1f cm)" % [res[0], float(res[1]) * 100.0])
	quit()
