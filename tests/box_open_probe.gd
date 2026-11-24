extends Node
## Bram's card box taken and opened, still by still (24 November, Gary:
## "Opening box bram give you players hand distorts in a weird way to open
## it"): Ashford's own scene (_first_deck) played on the green, every line
## tapped on, a still every `every` frames from the moment the box is the
## player's until the deck is shown, from the game's own close shot.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 960x540 --fixed-fps 30 --path . res://tests/box_open_probe.tscn -- <dir> [every=2] [look=a|b|c|d] [oldlid]

const DrawHold = preload("res://tests/draw_hold.gd")

const MOST := 64

var out := "/tmp/box_open"
var every := 2
var world: World
var _frame := 0
var _n := 0
var _wait := 0
var _done := false
var _taken_at := -1


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Game.new_game("Sprout", "")
	for a: String in args:
		if a.begins_with("every="):
			every = int(a.substr(6))
		if a.begins_with("look="):
			Game.set_flag("look", a.substr(5))
	if args.has("oldlid"):
		world_script().lid_follows = true
		world_script().box_shot_side = false
	DirAccess.make_dir_recursive_absolute(out)
	for f in ["arrived_ashford", "ash_started", "p1_crate_down", "corin_met"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	Game.settings["first_steps"] = 2
	world = World.new().setup("ashford", "green")
	add_child(world)
	DrawHold.start_keys()   # (only the stills' frames are drawn)
	_run.call_deferred()


func world_script() -> GDScript:
	return load("res://scripts/world/areas/ashford.gd")


func _run() -> void:
	for k in 40:
		await get_tree().process_frame
	await world.area._first_deck(world)
	_done = true
	for k in 6:
		await get_tree().process_frame
	print("BOX OPEN PROBE: %d stills, the box taken at frame %d" % [_n, _taken_at])
	get_tree().quit()


func _process(_d: float) -> void:
	_frame += 1
	if world == null or world.hud == null or _done:
		return
	_wait += 1
	if _wait > 6:
		_wait = 0
		if world.hud.dialogue._waiting:
			world.hud.dialogue._advance.emit()
		var ov := Cine.overlay(world)
		if ov != null and ov._waiting:
			ov._next.emit()
	if world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	if world.has_meta("box_player"):
		if _taken_at < 0:
			_taken_at = _frame
		if (_frame - _taken_at) % every == 0 and _n < MOST:
			_shot()
		elif _n >= MOST and not _done:
			# (the deck's being shown, and waits for a tap: that's the end of it)
			_done = true
			print("BOX OPEN PROBE: %d stills, the box taken at frame %d" % [_n, _taken_at])
			get_tree().quit()


func _shot() -> void:
	DrawHold.hold()
	await RenderingServer.frame_post_draw
	DrawHold.release()
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%03d_f%04d.png" % [_n, _frame - _taken_at]))
