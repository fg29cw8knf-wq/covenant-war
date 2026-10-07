extends Node
## Plays Ashford by itself and saves screenshots: the village at the start,
## the errands, Corin's Lantern Duel (simulated) and the whole midnight scene.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --resolution 1280x720 --fixed-fps 8 \
##       res://tests/ashford_test.tscn -- <out_dir> [every_n_frames]

var out_dir := "user://"
var every := 24
var world: World
var _shots := 0
var _wait := 0
var _frame := 0
var _filming := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		every = int(args[1])
	Game.new_game("Sprout", "emberstorm")
	if "midnight" in args or "still" in args:
		Game.set_flag("arrived_ashford")
	world = World.new().setup("ashford", "green")
	add_child(world)
	world.story_next.connect(func(what: String) -> void:
		print("story_next: ", what)
		await _frames(4)
		await _shot("end")
		get_tree().quit())
	await _frames(30)
	if "still" in args:
		await _shot("still_spawn")
		_teleport(Vector3(-2.0, 0, 4.0))
		await _frames(12)
		await _shot("still_green")
		get_tree().quit()
		return
	if "midnight" in args:
		for f in ["ash_started", "ash_tom", "ash_mae", "ash_nell", "ash_ready"]:
			Game.set_flag(f)
		world._refresh_markers()
		var c = world._npc_by_id("corin")
		_teleport(c.body.global_position + Vector3(1.2, 0, 1.2))
		await _frames(6)
		_filming = true
		world._talk(c)
		return
	await _shot("arrival")
	# let the arrival dialogue play out
	await _frames(120)
	await _shot("after_arrival")
	# walk round the errands
	for id in ["tom", "mae", "nell"]:
		var n = world._npc_by_id(id)
		_teleport(n.body.global_position + Vector3(0.0, 0, 1.6))
		await _frames(8)
		await world._talk(n)
		await _shot("talked_" + id)
	print("ready flag: ", Game.flag("ash_ready"))
	# the Lantern Duel and midnight
	var corin = world._npc_by_id("corin")
	_teleport(corin.body.global_position + Vector3(1.2, 0, 1.2))
	await _frames(8)
	await _shot("corin")
	_filming = true
	world._talk(corin)


func _process(_d: float) -> void:
	_frame += 1
	# tap through dialogue automatically
	if world != null and world.hud != null and world.hud.dialogue._waiting:
		_wait += 1
		if _wait > 12:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world != null and world.hud != null and world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	if _filming and _frame % every == 0:
		_shot("mid_%03d" % _shots)


func _teleport(p: Vector3) -> void:
	world.player.global_position = p
	world._focus = world._cam_focus_target()


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_shots += 1
	img.save_png(out_dir.path_join("%02d_%s.png" % [_shots, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
