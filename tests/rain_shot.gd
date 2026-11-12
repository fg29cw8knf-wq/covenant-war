extends Node
## A shower on Ashford's green, to look at (12 November: Weather): the green
## dry, then with the rain all the way in, as a Mac draws it (Gfx.level() 2)
## or, with "phone", as a phone does.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/rain_shot.tscn -- <dir> [phone] [bow | mist]
## "bow": a rainbow, from the walking camera and from down among the people;
## "mist": the morning after the fires, from the walking camera and the dawn's own two.

var world: World


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := String(args[0]) if args.size() > 0 else "/tmp/rain"
	DirAccess.make_dir_recursive_absolute(out)
	Gfx.force_level = 1 if "phone" in args else 2
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["first_steps"] = 2
	for f in ["arrived_ashford", "ash_started", "p1_crate_down", "corin_met", "first_deck"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	world = World.new().setup("ashford", "green")
	add_child(world)
	for k in 25:
		await get_tree().process_frame
	var wx := Weather.of(world)
	if wx == null:
		print("RAIN SHOT: PROBLEM: the village has no weather")
		get_tree().quit(1)
		return
	print("RAIN SHOT: may rain %s, the place sounds of %s" % [wx.may_rain(), world.ambience()])
	await _still(out + "/1_dry.png")
	if "bow" in args:
		# a rainbow, as a shower ends: from the walking camera, then from down among the people
		wx.force_bow()
		await get_tree().create_timer(Weather.BOW_IN + 1.0).timeout
		print("RAIN SHOT: the rainbow at %.2f" % wx.bow)
		await _still(out + "/4_bow_walking.png")
		var p := world.player.global_position
		await _from(p + Vector3(-9.0, 1.6, 9.0), p + Vector3(16.0, 13.0, -10.0), 46.0, out + "/5_bow_low.png")
		await _from(p + Vector3(-2.0, 1.5, 5.0), p + Vector3(6.0, 1.6, -7.0), 40.0, out + "/6_bow_foot.png")
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	if "mist" in args:
		# the morning after the fires: the mist on the green
		var v := world.get_meta("village") as AshfordVillage
		v.set_time("dawn")
		await get_tree().create_timer(1.5).timeout
		print("RAIN SHOT: mist wanted %.0f, the village dressed for %s" % [wx.mist, v.time_kind])
		await _still(out + "/7_mist_walking.png")
		await _from(Vector3(-18.0, 8.0, 31.0), Vector3(6.0, 3.0, -12.0), 46.0, out + "/8_mist_wide.png")
		await _from(Vector3(-2.2, 0.9, 16.6), Vector3(-4.6, 0.4, 13.0), 38.0, out + "/9_mist_low.png")
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	wx.force(40.0)
	await get_tree().create_timer(Weather.EASE_IN + 2.0).timeout
	print("RAIN SHOT: the shower at %.2f, the place sounds of %s" % [wx.amount, world.ambience()])
	await _still(out + "/2_rain.png")
	await get_tree().create_timer(0.7).timeout
	await _still(out + "/3_rain.png")
	print("RAIN SHOT: done")
	get_tree().quit()


## A still from a camera of the test's own (the world's stays where it is).
func _from(at: Vector3, look: Vector3, fov: float, path: String) -> void:
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = fov
	cam.far = 600.0
	cam.look_at_from_position(at, look)
	cam.make_current()
	for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		layer.visible = false
	for k in 3:
		await get_tree().process_frame
	await _still(path)
	cam.queue_free()
	world.cam.make_current()


func _still(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
