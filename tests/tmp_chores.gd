extends Node
## TEMP: Tam's barrel and Tilly's moth (or the Lantern gift), drawing only the
## frames it keeps (fast under a software renderer).
##   xvfb-run ... godot --rendering-driver opengl3 --resolution 960x540 --fixed-fps 10 \
##       res://tests/tmp_chores.tscn -- <out_dir> <every_n_frames> [tam|tilly|gift]

var out_dir := "user://"
var every := 4
var world: World
var _frame := 0
var _wait := 0
var _shots := 0
var _filming := false
var _shooting := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out_dir = args[0]
	every = int(args[1])
	var which: Array = args.slice(2) if args.size() > 2 else ["tam", "tilly"]
	RenderingServer.render_loop_enabled = false
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	if "gift" in which:
		for f in ["ash_started", "ash_tam", "ash_tilly", "ash_nell", "ash_ready", "first_deck"]:
			Game.set_flag(f)
	world = World.new().setup("ashford", "green")
	add_child(world)
	for i in 30:
		await get_tree().process_frame
	if "gift" in which:
		# straight to after the duel: Tilly's run and the hand-over
		var c = world._npc_by_id("corin")
		world.player.global_position = c.body.global_position + Vector3(1.2, 0, 1.2)
		await _frames(4)
		_filming = true
		var steps: Array = [{"scene": "tilly_gift"},
			{"who": "tilly", "say": "For luck! You keep it. It glows better for you anyway.", "during": "tilly_hands_over", "at": "You keep it"},
			{"scene": "tilly_card"}]
		world.busy = true
		await world.run_steps(steps, null)
		await _frames(10)
		await _shot("gift_end")
		get_tree().quit()
		return
	for id in which:
		var n = world._npc_by_id(id)
		world.player.global_position = n.body.global_position + Vector3(0.0, 0, 1.6)
		world._focus = world._cam_focus_target()
		await _frames(6)
		await _shot("before_" + id)
		_filming = true
		await world._talk(n)
		_filming = false
		await _shot("talked_" + id)
	get_tree().quit()


func _process(_d: float) -> void:
	_frame += 1
	if world == null or world.hud == null:
		return
	if world.hud.dialogue._waiting:
		_wait += 1
		if _wait > 6:
			_wait = 0
			world.hud.dialogue._advance.emit()
	if world.hud.dialogue._choices.visible:
		world.hud.dialogue._chosen.emit(0)
	for r in get_tree().root.find_children("*", "DeckReveal", true, false):
		if (r as DeckReveal)._ready_to_close:
			(r as DeckReveal)._close()
	if _filming and _frame % every == 0:
		_shot("f%04d" % _frame)


func _shot(label: String) -> void:
	if _shooting:
		return
	_shooting = true
	RenderingServer.render_loop_enabled = true
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	RenderingServer.render_loop_enabled = false
	_shooting = false
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
