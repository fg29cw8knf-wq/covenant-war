extends Node
## Stills of the attic bed from the side and the foot at set moments of the
## opening (lying, sat up, on the edge, standing), for checking that the
## sleeper lies on the mattress, not in it, and gets up off its edge.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
##       res://tests/bed_check.tscn -- <out_dir> [t,t,t...]

var out := "/tmp/bed"
var times: Array = [8.6, 10.6, 12.4, 13.6]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		times = []
		for s in String(args[1]).split(","):
			times.append(float(s))
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	var world := World.new().setup("ashford", "green")
	add_child(world)
	var v: AshfordVillage = AshfordP1.village(world)
	var t := 0.0
	for want in times:
		while t < float(want) - 0.001:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
		var a := InnRooms.attic(v)
		var root: Node3D = a.root
		var bed: Vector3 = a.bed
		# the game's own shot first, then the side (from the south, level with
		# the mattress) and the foot (from the east, looking along the bed)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/t%04.1f_game.png" % [out, t])
		var shots := {
			"side": [bed + Vector3(0.0, 0.55, 3.2), bed + Vector3(0.0, 0.25, 0.0), 40.0],
			"foot": [bed + Vector3(3.0, 0.9, 0.3), bed + Vector3(-0.3, 0.3, 0.0), 40.0],
			"high": [root.to_global(Vector3(0.5, 2.6, 1.6)), bed + Vector3(0.0, 0.2, 0.0), 50.0],
		}
		for k in shots:
			var s: Array = shots[k]
			Cine.shot(world, s[0], s[1], s[2])
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/t%04.1f_%s.png" % [out, t, k])
		# (the opening's own camera moves carry on from wherever they were)
	print("BED CHECK: done in %s" % out)
	get_tree().quit()
