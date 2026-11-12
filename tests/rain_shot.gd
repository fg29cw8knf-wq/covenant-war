extends Node
## A shower on Ashford's green, to look at (12 November: Weather): the green
## dry, then with the rain all the way in, as a Mac draws it (Gfx.level() 2)
## or, with "phone", as a phone does.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/rain_shot.tscn -- <dir> [phone]

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
	wx.force(40.0)
	await get_tree().create_timer(Weather.EASE_IN + 2.0).timeout
	print("RAIN SHOT: the shower at %.2f, the place sounds of %s" % [wx.amount, world.ambience()])
	await _still(out + "/2_rain.png")
	await get_tree().create_timer(0.7).timeout
	await _still(out + "/3_rain.png")
	print("RAIN SHOT: done")
	get_tree().quit()


func _still(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
