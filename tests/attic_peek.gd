extends Node
## Stills of the attic opening as it plays (the dream, the sleeper, the
## get-up), one every `every` seconds of game time, for looking at.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
##       res://tests/attic_peek.tscn -- <out_dir> [seconds=18] [every=0.5]

var out := "/tmp/attic"
var secs := 18.0
var every := 0.5


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	for a in args.slice(1):
		if String(a).begins_with("seconds="):
			secs = float(String(a).substr(8))
		elif String(a).begins_with("every="):
			every = float(String(a).substr(6))
	DirAccess.make_dir_recursive_absolute(out)
	Game.new_game("Sprout", "")
	Game.settings["first_steps"] = 0
	var world := World.new().setup("ashford", "green")
	add_child(world)
	var t := 0.0
	var n := 0
	while t < secs:
		await get_tree().create_timer(every).timeout
		t += every
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/attic_%05.1f.png" % [out, t])
		n += 1
	print("ATTIC PEEK: %d stills in %s" % [n, out])
	get_tree().quit()
