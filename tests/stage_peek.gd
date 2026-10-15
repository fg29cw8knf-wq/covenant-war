extends Node
## Scratch views of Ashford for staging cutscenes: from above and from given
## camera spots, with every NPC where it stands.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 \
##       res://tests/stage_peek.tscn -- <out_dir> [name px py pz lx ly lz]...

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	get_window().size = Vector2i(1600, 900)
	var t0 := Time.get_ticks_msec()
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	print("built in ", Time.get_ticks_msec() - t0)
	var t1 := Time.get_ticks_msec()
	await _frames(40)
	print("40 frames in ", Time.get_ticks_msec() - t1)
	world.hud.visible = false
	var views := [["top", Vector3(0, 46, 14), Vector3(0, 0, 0)], ["player_view", Vector3(1.5, 8.2, 22.0), Vector3(1.5, 1.1, 10.5)]]
	var i := 1
	while i + 6 < args.size():
		views.append([args[i], Vector3(float(args[i + 1]), float(args[i + 2]), float(args[i + 3])), Vector3(float(args[i + 4]), float(args[i + 5]), float(args[i + 6]))])
		i += 7
	for vw in views:
		await world.cine_to(vw[1], vw[2], 0.05)
		await _frames(20)
		await _shot(vw[0])
	get_tree().quit()


func _frames(n: int) -> void:
	for k in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/peek_%s.png" % [out_dir, name])
