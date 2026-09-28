extends Node
## Visual test for the walkable world. Run with a real renderer:
##   xvfb-run -a -s "-screen 0 2560x1600x24" godot --rendering-driver opengl3 \
##       res://tests/world_test.tscn -- <out_dir> [WxH ...]
## Saves screenshots of Solhaven from a few spots and with dialogue open.

var out_dir := "user://"
var sizes: Array = [Vector2i(1600, 900)]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		sizes.clear()
		for a in args.slice(1):
			var p: PackedStringArray = a.split("x")
			sizes.append(Vector2i(int(p[0]), int(p[1])))
	Game.new_game("Ash", "emberstorm")
	Game.set_flag("arrived_solhaven")  # skip the arrival scene
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	for s in sizes:
		get_window().size = s
		await _frames(20)
		await _shot(world, "gate", s)
		_teleport(world, Vector3(1.5, 0, 0.5))
		await _frames(40)
		await _shot(world, "fountain", s)
		_teleport(world, Vector3(-7.5, 0, -6.0))
		await _frames(40)
		await _shot(world, "circle", s)
		_teleport(world, Vector3(9.0, 0, 1.2))
		await _frames(40)
		await _shot(world, "inn", s)
		# dialogue box over the scene
		world.busy = true
		world.hud.set_controls_visible(false)
		world.hud.dialogue.say("Bram", DollArt.portrait("bram"), "There you are. I've taken rooms at the Gilded Hearth. Solhaven prices, mind. Robbery with a smile.")
		await _frames(150)
		await _shot(world, "dialogue", s)
		world.hud.dialogue.close()
		world.hud.set_controls_visible(true)
		world.busy = false
		_teleport(world, Vector3(0, 0, 12.5))
		await _frames(30)
	get_tree().quit()


func _teleport(world: World, p: Vector3) -> void:
	world.player.global_position = p
	world._focus = world._cam_focus_target()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(world: World, label: String, s: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/world_%s_%dx%d.png" % [out_dir, label, s.x, s.y]
	img.save_png(path)
	print("saved ", path, " ", img.get_size())
