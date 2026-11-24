extends Node
## The lantern crate taken up off its stand and walked off with, every frame
## looked at (18 November, the body sweep: "player's left hand is 6.5 cm
## inside Crate/crate/Wooden_Crate" for one frame as it comes into his arms,
## and his fingers 1.9 cm into it as he walks): how far each hand is from its
## handle's mark on every drawn pose, and the body check on every frame.
##   godot --headless --fixed-fps 30 --path . res://tests/crate_take_probe.tscn -- body_every=1

const BodyCheck = preload("res://tests/body_check.gd")


func _ready() -> void:
	Game.new_game("Sprout", "")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	for k in 30:
		await get_tree().process_frame
	if world.hud != null:
		world.hud.visible = false
	var v: AshfordVillage = AshfordP1.village(world)
	# (`back`, `side`: come at from behind it, or from its end)
	var way := Vector3(0, 0, 1.3)
	if OS.get_cmdline_user_args().has("back"):
		way = Vector3(0, 0, -1.3)
	elif OS.get_cmdline_user_args().has("side"):
		way = Vector3(1.3, 0, 0.2)
	var at := world.player.global_position + way
	var stand := AshfordP1._crate_stand(v, world, at, 0.0)
	var cr := AshfordP1.crate(v)
	world.add_child(cr)
	cr.global_position = at + Vector3(0, AshfordP1.CRATE_STAND_H, 0)
	for k in 10:
		await get_tree().process_frame
	var me := world.player_doll as Figure3D
	var bc: Node = BodyCheck.watch(world, "")
	var worst := [0.0, 0.0]
	var frame := [0]
	var jump := [0.0]
	var last := [Vector3.INF]
	var lh: Node3D = cr.get_node("L")
	var rh: Node3D = cr.get_node("R")
	var taken := [false]
	var series := OS.get_cmdline_user_args().has("series")
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("bend="):
			AshfordP1.CRATE_BEND = float(a.substr(5))
		if a.begins_with("over="):
			AshfordP1.CRATE_OVER = float(a.substr(5))
	me._skel.skeleton_updated.connect(func() -> void:
		frame[0] += 1
		if not taken[0]:
			return
		var marks := [lh, rh]
		if cr.global_basis.x.dot(me.to_world(Vector3(1, 0, 0)) - me.global_position) < 0.0:
			marks = [rh, lh]
		var k := 0
		var ds := [0.0, 0.0]
		for side in ["LeftHand", "RightHand"]:
			var d: float = me.bone_pos(side).distance_to((marks[k] as Node3D).global_position)
			worst[k] = maxf(worst[k], d)
			ds[k] = d
			k += 1
		if series:
			var sh: Vector3 = me.bone_pos("LeftArm")
			print("crate_take_probe:   f%d hands %.1f %.1f cm from their marks; the left mark %.1f cm from his shoulder (his arm %.1f); the crate %s in his frame, clip %s" % [frame[0], ds[0] * 100.0, ds[1] * 100.0,
				sh.distance_to((marks[0] as Node3D).global_position) * 100.0, me.arm_reach() * 100.0, str(me.to_own(cr.global_position).snappedf(0.01)), me._clip + " shoulder " + str(me.to_own(sh).snappedf(0.01)) + " mark " + str(me.to_own((marks[0] as Node3D).global_position).snappedf(0.01))])
		# (how far the crate moves against his chest in one frame once it's his)
		var rel: Vector3 = me._pivot.global_transform.affine_inverse() * cr.global_position
		if last[0] != Vector3.INF:
			jump[0] = maxf(jump[0], (rel - (last[0] as Vector3)).length())
		last[0] = rel)
	# shot=<dir>: stills from beside him (his hands on it, half way up, held)
	var shots := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("shot="):
			shots = a.substr(5)
			DirAccess.make_dir_recursive_absolute(shots)
	var cam: Camera3D = null
	if shots != "":
		cam = Camera3D.new()
		world.add_child(cam)
		cam.fov = 38.0
		var mid := at + Vector3(0, 1.0, 0) - way.normalized() * 0.25
		var beside := way.normalized().cross(Vector3.UP)
		cam.look_at_from_position(mid + beside * 2.6 + way.normalized() * 0.5 + Vector3(0, 0.25, 0), mid)
		# (24 November, Gary: "Player arm goes through crate before he picks it
		# up": view=front from past the crate looking back at him, view=top
		# from over it; the reach is photographed every third frame, 0_reach_NN)
		if OS.get_cmdline_user_args().has("view=front"):
			cam.look_at_from_position(mid + way.normalized() * 2.4 + beside * 0.5 + Vector3(0, 0.45, 0), mid - Vector3(0, 0.1, 0))
		elif OS.get_cmdline_user_args().has("view=top"):
			cam.look_at_from_position(mid + Vector3(0, 2.3, 0) - way.normalized() * 0.5 + beside * 0.3, mid - Vector3(0, 0.2, 0))
		cam.make_current()
		for layer: CanvasLayer in get_tree().root.find_children("*", "CanvasLayer", true, false):
			layer.visible = false
	var snap := func(nm: String) -> void:
		if shots == "":
			return
		cam.make_current()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shots.path_join(nm + ".png"))
	var done := [false]
	var go := func() -> void:
		await AshfordP1._take_crate(world, cr)
		done[0] = true
	go.call()
	# (from when it leaves its stand: the hands are on it by then)
	var y0 := cr.global_position.y
	var rk := 0
	while not done[0] and cr.global_position.y < y0 + 0.002:
		await get_tree().process_frame
		rk += 1
		if shots != "" and rk % 3 == 0 and rk < 120:
			await snap.call("0_reach_%02d" % (rk / 3))
	taken[0] = true
	await snap.call("1_hands_on_it")
	var half := false
	while not done[0]:
		await get_tree().process_frame
		if not half and cr.global_position.y > y0 + 0.07:
			half = true
			await snap.call("2_half_way_up")
	await snap.call("3_held")
	print("crate_take_probe: taken up: a hand at most %.1f and %.1f cm from its mark; the crate moved at most %.1f cm against him in a frame" % [worst[0] * 100.0, worst[1] * 100.0, jump[0] * 100.0])
	worst[0] = 0.0
	worst[1] = 0.0
	jump[0] = 0.0
	last[0] = Vector3.INF
	world.busy = false
	world.cine = false
	await Cine.path(world, "player", [world.player.global_position + Vector3(3.0, 0, 1.0), world.player.global_position + Vector3(3.0, 0, 4.0)], 1.0)
	print("crate_take_probe: walked off with: a hand at most %.1f and %.1f cm from its mark; the crate moved at most %.1f cm against him in a frame" % [worst[0] * 100.0, worst[1] * 100.0, jump[0] * 100.0])
	for k in 6:
		await get_tree().process_frame
	print(bc.call("summary"))
	get_tree().quit()
