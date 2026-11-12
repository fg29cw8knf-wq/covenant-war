extends Node
## A shower on Ashford's green, to look at (12 November: Weather): the green
## dry, then with the rain all the way in, as a Mac draws it (Gfx.level() 2)
## or, with "phone", as a phone does.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/rain_shot.tscn -- <dir> [phone] [bow | mist | puddles | breath | splash | flies | leaves | birds]
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
	if "puddles" in args:
		# just after a shower: the puddles on the paths, full
		wx.wet = 1.0
		for k in 3:
			await get_tree().process_frame
		print("RAIN SHOT: %d puddles, showing %s, as solid as %.2f" % [_count_puddles(wx), wx._puddles.visible, wx._puddle_mat.albedo_color.a])
		await _still(out + "/10_puddles_walking.png")
		var pp := world.player.global_position
		await _from(pp + Vector3(0.5, 1.5, 7.0), pp + Vector3(0.0, 0.2, -3.0), 42.0, out + "/11_puddles_low.png")
		await _from(pp + Vector3(0.0, 9.0, 3.0), pp + Vector3(0.0, 0.0, -4.0), 50.0, out + "/12_puddles_above.png")
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	if "splash" in args:
		# a foot down in a puddle: the drops and the ring, from close by
		wx.set_process(false)
		wx.wet = 1.0
		wx._puddles.visible = true
		wx._puddle_mat.albedo_color.a = Weather.PUDDLE_SEEN
		var sv := world.get_meta("village") as AshfordVillage
		var widest: Array = wx._puddle_at[0]
		for row: Array in wx._puddle_at:
			if float(row[1]) > float(widest[1]):
				widest = row
		var c: Vector2 = widest[0]
		var mid := Vector3(c.x, sv.ground_y(c.x, c.y), c.y)
		var cam := Camera3D.new()
		world.add_child(cam)
		cam.fov = 30.0
		cam.look_at_from_position(mid + Vector3(0.4, 1.3, 2.6), mid + Vector3(0, 0.1, 0))
		cam.make_current()
		for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
		for k in 3:
			await get_tree().process_frame
		wx.splash(mid)
		for n in 5:
			await get_tree().process_frame
			await _still(out + "/14_splash_%d.png" % (n + 1))
		# and from the walking camera: the player stood in it
		cam.queue_free()
		world.cam.make_current()
		for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			layer.visible = true
		world.player.global_position = mid
		await get_tree().create_timer(1.5).timeout
		wx.splash(mid + Vector3(0.12, 0, 0.05))
		await get_tree().process_frame
		await get_tree().process_frame
		await _still(out + "/15_splash_walking.png")
		print("RAIN SHOT: %d splashes" % wx.splashes)
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	if "flies" in args:
		# the festival night: fireflies over the green
		var fv := world.get_meta("village") as AshfordVillage
		fv.set_daylight(0.0)
		await get_tree().create_timer(2.0).timeout
		print("RAIN SHOT: the village dressed for %s at daylight %.2f; fireflies wanted %.0f, %d of them from %d spots, the place sounds of %s" % [fv.time_kind, fv.daylight, wx.flies, wx._flies.amount, wx.fly_spots.size(), world.ambience()])
		await _still(out + "/16_flies_walking.png")
		await get_tree().create_timer(1.5).timeout
		await _still(out + "/17_flies_walking.png")
		var fp := world.player.global_position
		await _from(fp + Vector3(-3.0, 1.5, 7.0), fp + Vector3(2.0, 1.0, -6.0), 44.0, out + "/18_flies_low.png")
		await _from(Vector3(-16.0, 7.0, 30.0), Vector3(4.0, 1.0, 2.0), 46.0, out + "/19_flies_wide.png")
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	if "birds" in args:
		# a flock on the ground by the player, from the walking camera and
		# from close by; going up from him; and coming down again
		wx.set_process(false)
		var birds := Birds.of(world)
		var bvil := world.get_meta("village") as AshfordVillage
		await get_tree().create_timer(1.2).timeout
		var flock: Birds.Flock = null
		for f: Birds.Flock in birds.flocks:
			if f.state == "ground" and (flock == null or f.at.distance_to(world.player.global_position) < flock.at.distance_to(world.player.global_position)):
				flock = f
		if flock == null:
			print("RAIN SHOT: PROBLEM: no flock down on the green")
			get_tree().quit(1)
			return
		print("RAIN SHOT: %d flocks; the nearest, of %d, %.1f m from the player at %s" % [birds.flocks.size(), flock.birds.size(), flock.at.distance_to(world.player.global_position), flock.at])
		var stand := flock.at + Vector3(1.5, 0, 5.2)
		world.player.global_position = Vector3(stand.x, bvil.ground_y(stand.x, stand.z), stand.z)
		await get_tree().create_timer(1.5).timeout
		print("RAIN SHOT: the player put %.1f m from it; the flock is '%s'" % [flock.at.distance_to(world.player.global_position), flock.state])
		await _still(out + "/22_birds_walking.png")
		await _from(flock.at + Vector3(0.6, 0.55, 2.3), flock.at + Vector3(0, 0.12, 0), 34.0, out + "/23_birds_close.png")
		for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			layer.visible = true
		birds.send_up(flock, world.player.global_position)
		var at_t := 0.0
		for n in 5:
			var wait: float = [0.3, 0.4, 0.5, 0.6, 0.8][n]
			await get_tree().create_timer(wait).timeout
			at_t += wait
			await _still(out + "/24_birds_up_%d.png" % (n + 1))
		print("RAIN SHOT: gone up %.1f s ago: the flock is '%s', the first bird %.1f m up" % [at_t, flock.state, (flock.birds[0] as Node3D).global_position.y - flock.at.y])
		await get_tree().create_timer(1.5).timeout
		flock.back_in = 0.05
		await get_tree().create_timer(0.3).timeout
		print("RAIN SHOT: due back: the flock is '%s', coming down %.1f m from the player" % [flock.state, flock.at.distance_to(world.player.global_position)])
		for n in 4:
			await get_tree().create_timer([1.1, 0.7, 0.7, 1.2][n]).timeout
			await _still(out + "/25_birds_down_%d.png" % (n + 1))
		print("RAIN SHOT: the flock is '%s'" % flock.state)
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	if "leaves" in args:
		# a few falls of leaves by the player, from the walking camera; then
		# one from close by, to see what a leaf looks like
		wx.set_process(false)
		var lat := world.cam_ground()
		print("RAIN SHOT: the air goes %s at the spot on screen %s" % [wx.leaf_wind(lat), lat])
		for k in 3:
			wx.leaves_at(lat)
		for n in 4:
			await get_tree().create_timer(1.6).timeout
			await _still(out + "/20_leaves_walking_%d.png" % (n + 1))
		var lp := world.player.global_position
		var cam2 := Camera3D.new()
		world.add_child(cam2)
		cam2.fov = 40.0
		cam2.look_at_from_position(lp + Vector3(1.0, 1.7, 6.0), lp + Vector3(0, 1.6, 0))
		cam2.make_current()
		for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
		for k in 3:
			wx.leaves_at(lp)
		for n in 3:
			await get_tree().create_timer(2.0).timeout
			await _still(out + "/21_leaves_close_%d.png" % (n + 1))
		print("RAIN SHOT: %d falls of leaves" % wx.leaf_falls)
		print("RAIN SHOT: done")
		get_tree().quit()
		return
	if "breath" in args:
		# the morning after the fires: breath showing, close on the player
		var bv := world.get_meta("village") as AshfordVillage
		bv.set_time("dawn")
		var bp := world.player.global_position
		var f := (world.player_doll as Figure3D).facing()
		var cam := Camera3D.new()
		world.add_child(cam)
		cam.fov = 24.0
		cam.look_at_from_position(bp + f.cross(Vector3.UP) * 2.2 + f * 0.5 + Vector3(0, 1.6, 0), bp + f * 0.3 + Vector3(0, 1.58, 0))
		cam.make_current()
		for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
		var was := Breath.count
		await get_tree().create_timer(4.0).timeout
		print("RAIN SHOT: %d breaths let out on the green in 4 s" % (Breath.count - was))
		# the player's own, as it leaves and hangs
		var m: Array = (world.player_doll as Figure3D).mouth()
		print("RAIN SHOT: the player's mouth is %.2f m up, facing %s (the body faces %s)" % [(m[0] as Vector3).y - bp.y, m[1], f])
		wx._breath._puff(world.player_doll as Figure3D)
		for n in 4:
			await get_tree().create_timer(0.3).timeout
			await _still(out + "/13_breath_%d.png" % (n + 1))
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


func _count_puddles(wx: Weather) -> int:
	var n := 0
	for mm: MultiMeshInstance3D in wx._puddles.find_children("*", "MultiMeshInstance3D", true, false):
		n += mm.multimesh.instance_count
	return n


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
