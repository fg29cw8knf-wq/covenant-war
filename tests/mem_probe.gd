extends Node
## What the game holds in the graphics memory and draws a frame (11 November,
## Gary: "Whole Game running slow keeps freezing"): the village by day, then
## a duel on top of it as the game has it (the village kept behind the duel),
## with the renderer's own counts each time: the textures' memory, the
## meshes', the whole of the video memory, and what's drawn a frame (objects,
## triangles, draw calls). Then every texture over 4 MB by its size and
## whether it's stored compressed for the graphics card, largest first.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 10 --path . res://tests/mem_probe.tscn -- [full] [duel] [list]
## "full" builds everything as a Mac does (Gfx.level() 2: all the grass, every
## prop), whatever it's drawn with here: the counts a Mac's frame has, bar its
## bounce light and fog, which this machine's renderer doesn't draw.

var world: World


func _ready() -> void:
	if "full" in OS.get_cmdline_user_args():
		Gfx.force_level = 2
	get_tree().root.theme = UITheme.make()
	Game.new_game("Sprout", "tidegrove")
	Game.settings["first_steps"] = 2
	for f in ["arrived_ashford", "ash_started", "p1_crate_down", "corin_met", "first_deck"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	_count("nothing loaded yet")
	world = World.new().setup("ashford", "green")
	add_child(world)
	for k in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_count("the village by day")
	if "list" in OS.get_cmdline_user_args():
		_list()
	if "duel" in OS.get_cmdline_user_args():
		world.process_mode = Node.PROCESS_MODE_DISABLED
		world.visible = false
		get_viewport().disable_3d = false
		SummonVideo.set_mode("off")
		var ds := DuelScreen.new().configure({"decks": ["emberstorm", "tidegrove"], "names": ["You", "Rival"],
			"profiles": [Lore.new_profile("You", "", 4), Lore.new_profile("Rival", "", 4)], "arena": "ashford",
			"ai": [true, true], "seed": 7, "speed": 3.0, "first": 0, "no_arena_events": true, "field3d": true})
		add_child(ds)
		var t := 0.0
		while t < 25.0:
			await get_tree().create_timer(1.0).timeout
			t += 1.0
			if ds.banner_waiting:
				ds.tap_banner()
		await RenderingServer.frame_post_draw
		_count("a duel over the village")
		if "list" in OS.get_cmdline_user_args():
			_list()
	print("MEM PROBE: done")
	get_tree().quit()


func _count(when: String) -> void:
	var mb := 1.0 / 1048576.0
	print("MEM PROBE: %s: textures %.0f MB, meshes and buffers %.0f MB, video memory in all %.0f MB; a frame draws %d objects, %d thousand triangles, %d draw calls; %d nodes, %d resources" % [when,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) * mb,
		Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) * mb,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) * mb,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))])


## Every texture the renderer holds over 4 MB.
func _list() -> void:
	var rows: Array = []
	var by_kind := {}
	if not RenderingServer.has_method("texture_debug_usage"):
		print("MEM PROBE:   (this build of the engine doesn't list its textures)")
		return
	for d in RenderingServer.call("texture_debug_usage"):
		var bytes := int(d.bytes)
		var fmt := int(d.format)
		var packed := fmt >= Image.FORMAT_DXT1
		var k := "compressed for the card" if packed else "not compressed"
		by_kind[k] = int(by_kind.get(k, 0)) + bytes
		if bytes >= 4 * 1048576:
			rows.append([bytes, "%5.1f MB  %dx%d  %s  %s" % [bytes / 1048576.0, int(d.width), int(d.height), k, String(d.path)]])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	for k in by_kind:
		print("MEM PROBE:   %s: %.0f MB" % [k, by_kind[k] / 1048576.0])
	for r in rows.slice(0, 60):
		print("MEM PROBE:   ", r[1])
	print("MEM PROBE:   (%d textures over 4 MB)" % rows.size())
