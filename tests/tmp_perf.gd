extends Node
## TEMP: what Tam and Tilly's models cost in the village: triangles, draw
## calls and frame time with them there, hidden, and as cut-outs.

var world: World


func _ready() -> void:
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	world = World.new().setup("ashford", "green")
	add_child(world)
	for i in 40:
		await get_tree().process_frame
	world.cine = true
	world.cam.global_position = Vector3(1.0, 5.0, 17.0)
	world.cam.look_at(Vector3(4.0, 0.8, 2.0))
	var tam = world._npc_by_id("tam")
	var tilly = world._npc_by_id("tilly")
	await _measure("3D Tam+Tilly")
	tam.doll.visible = false
	tilly.doll.visible = false
	tam.doll.process_mode = Node.PROCESS_MODE_DISABLED
	tilly.doll.process_mode = Node.PROCESS_MODE_DISABLED
	await _measure("hidden")
	# back as cut-outs
	for n in [tam, tilly]:
		var d := PaperDoll.new().setup(n.def.look)
		n.body.add_child(d)
	await _measure("cut-outs")
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0] + "/perf_view.png")
	get_tree().quit()


func _measure(label: String) -> void:
	for i in 10:
		await get_tree().process_frame
	var prims := 0.0
	var calls := 0.0
	var t := 0.0
	var proc := 0.0
	var n := 40
	var t0 := Time.get_ticks_usec()
	for i in n:
		await get_tree().process_frame
		prims += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		calls += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
	t = (Time.get_ticks_usec() - t0) / 1000.0 / n
	print("PERF %-14s triangles %8.0f  draw calls %5.0f  frame %6.1f ms  process %5.2f ms" % [label, prims / n, calls / n, t, proc / n * 1000.0])
