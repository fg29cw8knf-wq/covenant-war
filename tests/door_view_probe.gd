extends Node
## The street as the taproom's doorway shows it (InnRooms.view_of, a picture
## taken once) beside the same view drawn live, by day: for checking the
## doorway's picture is the day's (4 November, Gary: "it shows it as night
## outside but then you walk out into day").
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/door_view_probe.tscn -- <out_dir>
var out := "/tmp/doorview"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	var world := World.new().setup("ashford", "green")
	add_child(world)
	# the opening runs by itself (World's intro): wait for the taproom's
	# picture to have been taken, as the game takes it
	var v: AshfordVillage = null
	var t := 0.0
	while t < 60.0:
		await get_tree().process_frame
		t += get_process_delta_time()
		v = AshfordP1.village(world)
		if v != null and v.has_meta("eve"):
			break
	for k in 6:
		await get_tree().process_frame
	var e: Dictionary = InnRooms.eve(v)
	print("picture taken with daylight %.2f after %.1f s" % [v.daylight, t])
	# the doorway's picture: the quad's texture
	var root: Node3D = e.root
	for n in root.get_children():
		if n is SubViewport:
			await RenderingServer.frame_post_draw
			(n as SubViewport).get_texture().get_image().save_png(out + "/doorway_picture.png")
	# the same view, live
	var front := InnRooms.inn_front(v)
	var eye: Vector3 = front.door + front.out * 0.6 + Vector3(0, 1.6, 0)
	world.cam.global_position = eye
	world.cam.look_at(eye + front.out * 10.0 + Vector3(0, -0.4, 0), Vector3.UP)
	world.cine = true
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/doorway_live.png")
	print("DOOR VIEW PROBE: saved in %s (daylight %.2f)" % [out, v.daylight])
	get_tree().quit()
