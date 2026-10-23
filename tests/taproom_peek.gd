extends Node
## Stills of the taproom scene (P1: Bram stacking the lanterns, the talk, the
## crate handed over), for staging it: New Game picked up at the taproom
## stage, a still every few frames, every line tapped on. Stops after the
## crate is in the player's arms (the walk to the door is the player's own).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 10 \
##       res://tests/taproom_peek.tscn -- <out_dir> [every_n_frames] [look=a|b|c|d]

var out_dir := "user://"
var every := 15
var world: World
var _frame := 0
var _n := 0
var _wait := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1 and String(args[1]).is_valid_int():
		every = int(args[1])
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.new_game("Sprout", "")
	Game.set_flag("p1_stage", "taproom")
	for a in args:
		if String(a).begins_with("look="):
			Game.set_flag("look", String(a).substr(5))
	world = World.new().setup("ashford", "green")
	add_child(world)


func _process(_d: float) -> void:
	_frame += 1
	if world == null or world.hud == null:
		return
	if world.hud.dialogue._waiting:
		_wait += 1
		if _wait > 8:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	if every > 0 and _frame % every == 0:
		_shot()
	if world.has_meta("p1_crate") and not world.busy:
		# the crate's in the player's arms and the walk is theirs: done
		_shot()
		print("TAPROOM PEEK: %d stills" % _n)
		get_tree().quit()


func _shot() -> void:
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_f%04d.png" % [_n, _frame]))
