extends Node
## The way to Tam's mill as a player sees it (29 October, Gary: "It's not
## clear for players how to get to Tam's mill"): the afternoon begun, the
## player free on the green with the HUD up, the game's own camera behind
## them. Stills with the player in a few places (by the Lantern facing away
## from the lane, at the lane's mouth, part way up it, at the gate), so the
## arrow at the screen's edge and the marker over the signpost and the gate
## can be looked at, and checks the way is set, points at the signpost from
## the green and at the gate from the lane, and goes once Tam's been seen.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/way_shot.tscn -- <out_dir> [phone]
## (phone: a 844x390 window, as an iPhone held sideways). Ends "WAY SHOT: ok".

var out_dir := "/tmp/way"
var problems: Array = []
var _n := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.has("phone"):
		get_window().size = Vector2i(844, 390)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "ash_won_lantern", "first_deck", "corin_met", "p1_crate_down"]:
		Game.set_flag(f)
	Game.set_flag("p1_stage", "done")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	var v: AshfordVillage = world.get_meta("village")
	AshfordP1.dress(world)
	AshfordDay.stage(world)
	world.busy = false
	world.cine = false
	world.hud.set_controls_visible(true)
	world.hud.dialogue.close()
	await _frames(10)
	var mouth: Vector3 = AshfordDay.LANE_MOUTH
	var gate: Vector3 = AshfordDay.LANE
	var spots := [
		["by_the_lantern_facing_west", Vector3(-1.5, 0, 3.5), Vector3(-12, 0, 3.5)],
		["by_the_lantern_facing_lane", Vector3(-1.5, 0, 3.5), mouth],
		["green_east_edge", Vector3(9.5, 0, -6.5), mouth],
		["lane_mouth", mouth + Vector3(-0.6, 0, 0.6), gate],
		["up_the_lane", mouth.lerp(gate, 0.55), gate],
	]
	for s in spots:
		var at: Vector3 = s[1]
		at.y = v.height(at.x, at.z)
		var look: Vector3 = s[2]
		AshfordP1.put(world, "player", at, look)
		await _frames(2)
		world._cam_yaw = world._cam_yaw_target()   # (it eases round over a second or two in play)
		await _frames(30)
		AshfordDay.show_way(world)
		await _frames(5)
		var wm = world.hud.way
		var want := gate if String(s[0]).begins_with("up_the_lane") or String(s[0]) == "lane_mouth" else mouth
		if wm.target == Vector3.INF:
			problems.append("%s: no way shown" % s[0])
		elif Vector2(wm.target.x - want.x, wm.target.z - want.z).length() > 0.5:
			problems.append("%s: the way points at %s, not %s" % [s[0], wm.target, want])
		await _shot(String(s[0]))
	# Tam seen: the way goes, the objective drops him
	Game.set_flag("ash_tam")
	AshfordDay.stage(world)
	await _frames(5)
	if world.hud.way.target != Vector3.INF:
		problems.append("the way is still shown once Tam's been seen")
	if String(Game.flag("objective", "")).contains("mill"):
		problems.append("the objective still sends them to the mill")
	await _shot("after_tam")
	print("WAY SHOT: ", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)])
	get_tree().quit(0 if problems.is_empty() else 1)


func _shot(label: String) -> void:
	_n += 1
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join("%02d_%s.png" % [_n, label]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
