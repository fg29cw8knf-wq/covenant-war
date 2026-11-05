extends SceneTree
## The card box in hands, close up, on a plain stage: Bram holding it out on
## his right palm as _box_out_scene has it (`bram`), the player with it on
## both palms as _first_deck takes it (`between`), and on the flat of the
## left hand alone, as it's held to open (`palm`). Stills from in front, the side and
## above the hands, for checking fingers against the box (2 November, Gary:
## "Bram's fingers go through the box while it's in his hand"; "players hands
## go all deformed when it takes the box then holding the box").
##   xvfb-run -a -s "-screen 0 1100x700x24" godot --rendering-driver opengl3 --resolution 1000x600 \
##       --script res://tests/box_hands_peek.gd -- <out_dir> [look, default a]
var Ashford = null   # (ashford.gd, loaded once the engine's up)
var out := "/tmp/boxhands"
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


func _wait(secs: float) -> void:
	await create_timer(secs).timeout


func _run() -> void:
	print("run")
	Ashford = load("res://scripts/world/areas/ashford.gd")
	print("ashford loaded")
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
	for who in ["bram", "player"]:
		var body := Node3D.new()
		stage.add_child(body)
		var model: String = who if (who == "bram" or look == "a") else ("player_" + look)
		var f := Figure3D.make(model, model) as Figure3D
		body.add_child(f)
		f.snap_face(Vector3.BACK)
		for k in 10:
			await process_frame
		print("figure ready: ", who)
		var box: Node3D = Ashford._card_box()
		stage.add_child(box)
		print("box ready")
		var modes: Array = ["present"] if who == "bram" else ["between", "palm"]
		for mode in modes:
			f.let_go(0.0)
			f.detach()
			match mode:
				"present":
					var hand := Node3D.new()
					f.carry(hand, Ashford._present_point(f, true))
					f.palm("right", Vector3.UP, 0.0, 1.0)
					f.reach(null, hand, 0.0)
					await _wait(0.5)
					f.attach(box, "palm", "right", Ashford.CARD_BOX_SIZE.y * 0.5 + 0.004, PI)
				"between":
					# (both hands under it, palms up, as _first_deck takes it since 2 November)
					var grip := Node3D.new()
					f.carry(grip, f.hold_point(0.5, 0.62) + Vector3(0.0, -Ashford.CARD_BOX_SIZE.y * 0.5 - 0.012, 0.0))
					for sd in [["L", 1.0], ["R", -1.0]]:
						var mk := Node3D.new()
						mk.name = sd[0]
						mk.position = Vector3(float(sd[1]) * 0.042, 0.0, Ashford.BOX_BACK)
						grip.add_child(mk)
					f.palm("left", Vector3.UP, 0.0, 1.0, true, Vector3.BACK)
					f.palm("right", Vector3.UP, 0.0, 1.0, true, Vector3.BACK)
					f.reach(grip.get_node("L"), grip.get_node("R"), 0.0)
					await _wait(0.5)
					f.attach(box, "palm", "left", Ashford.CARD_BOX_SIZE.y * 0.5 + 0.004, 0.0, 0.0, -Ashford.BOX_BACK)   # (set back on the palms, BOX_BACK, since 5 November)
					# (the right hand under the box's other half, wherever the left palm puts it)
					var rmark := Node3D.new()
					rmark.name = "RightUnder"
					box.add_child(rmark)
					rmark.position = Vector3(-0.042, -Ashford.CARD_BOX_SIZE.y * 0.5 - 0.012, Ashford.BOX_BACK)
					f.reach(grip.get_node("L"), rmark, 0.1)
				"palm":
					var lh := Node3D.new()
					f.carry(lh, f.hold_point(0.5, 0.62) + Vector3(0.0, -Ashford.CARD_BOX_SIZE.y * 0.5 - 0.035, 0.01 + Ashford.BOX_BACK))
					f.palm("left", Vector3.UP, 0.0, 1.0)
					f.palm("right", Vector3.ZERO, 0.0)
					f.reach(lh, null, 0.0)
					await _wait(0.5)
					f.attach(box, "palm", "left", Ashford.CARD_BOX_SIZE.y * 0.5 + 0.004, 0.0, 0.0, -Ashford.BOX_BACK)
			await _wait(0.8)
			print("held: ", mode)
			var at: Vector3 = box.global_position
			var fwd := f.facing()
			var side := fwd.cross(Vector3.UP)
			var views := {"front": at + fwd * 0.9 + Vector3(0, 0.15, 0), "side": at + side * 0.9 + Vector3(0, 0.1, 0),
				"other": at - side * 0.9 + Vector3(0, 0.1, 0), "above": at + fwd * 0.5 + Vector3(0, 0.7, 0), "low": at + fwd * 0.8 - Vector3(0, 0.35, 0)}
			for k in views:
				cam.global_position = views[k]
				cam.look_at(at, Vector3.UP)
				await _shot("%s_%s_%s" % [who, mode, k])
			f.detach(box)
		f.let_go(0.0)
		box.queue_free()
		body.queue_free()
	print("BOX HANDS PEEK: done in ", out)
	quit()
