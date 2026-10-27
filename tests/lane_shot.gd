extends Node
## Stills of the lane down to Tam's mill as the afternoon has it (the sign
## at its mouth, the glow while Tam's still to see, the hedges either side,
## the cottages it leaves between): the village from above, the lane's mouth
## from the green, the player's own view from the green's edge looking up it,
## and from its far end looking back. Ends "LANE SHOT: done".
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/lane_shot.tscn -- <out_dir>

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	# the afternoon: the sign up and lit, Tam down at his mill
	for f in ["ash_started", "ash_won_lantern", "first_deck", "corin_met"]:
		Game.set_flag(f)
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	world.hud.visible = false
	var v: AshfordVillage = world.get_meta("village")
	v.set_daylight(1.0)
	AshfordDay.stage(world)
	await _frames(10)
	var mouth: Vector3 = AshfordDay.LANE_MOUTH
	var end: Vector3 = AshfordDay.LANE
	var sign: Node3D = AshfordP1.meta(v, "lane_sign")
	print("LANE SHOT: mouth ", mouth, " end ", end, " sign ", sign.global_position if sign != null else "none")
	Cine.place(world, "player", mouth + (Vector3.ZERO - mouth).normalized() * 3.0, end)
	var views := [
		["above", Vector3(mouth.x + 2.0, 42.0, mouth.z + 0.1), mouth, 50.0],
		["above_wide", Vector3(0, 70.0, 0.1), Vector3.ZERO, 55.0],
		["from_green", Vector3(0, 2.0, 2.0), mouth + Vector3(0, 1.0, 0), 44.0],
		["mouth", mouth + (Vector3.ZERO - mouth).normalized() * 6.0 + Vector3(0, 1.8, 0), end + Vector3(0, 1.0, 0), 44.0],
		["up_the_lane", mouth + Vector3(0, 1.7, 0), end + Vector3(0, 1.2, 0), 44.0],
		["looking_back", end + Vector3(0, 1.7, 0), mouth + Vector3(0, 1.0, 0), 50.0],
	]
	for vw in views:
		Cine.shot(world, vw[1], vw[2], vw[3])
		await _frames(8)
		await _shot(vw[0])
	# a plan of the lane, square from above: 24 m across, centred on (12, -19),
	# north up (for marking where things stand: x right, z up the picture)
	var plan := Camera3D.new()
	plan.projection = Camera3D.PROJECTION_ORTHOGONAL
	plan.size = float(OS.get_environment("PLAN_SIZE")) if OS.get_environment("PLAN_SIZE") != "" else 24.0
	plan.far = 200.0
	world.add_child(plan)
	var pc := Vector3(float(OS.get_environment("PLAN_X")), 0, float(OS.get_environment("PLAN_Z"))) if OS.get_environment("PLAN_X") != "" else Vector3(12.0, 0, -19.0)
	plan.global_position = pc + Vector3(0, 60.0, 0)
	plan.rotation = Vector3(-PI * 0.5, 0, 0)
	plan.current = true
	for i in 6:
		await get_tree().process_frame
	await _shot("plan")
	print("LANE SHOT: plan 24 m square centred (12, -19), x right, -z up")
	print("LANE SHOT: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
