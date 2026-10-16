extends Node
## Stills of the windmill and the oaks: the New Game flight over the rooftops,
## the lane up to the mill, the mill close to (scale, grounding, sails), the
## oaks round the village, the film's mill-fire shot, dawn, and the Thornwood
## riverbank looking back up at the mill on the burning crest.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/props_shot.tscn -- <out_dir> [thornwood]

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if "thornwood" in args:
		await _thornwood()
	else:
		await _ashford()
	print("PROPS SHOT: done")
	get_tree().quit()


func _ashford() -> void:
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(40)
	world.hud.visible = false
	var v: AshfordVillage = world.get_meta("village")
	var mill := v.mill_root.global_position
	var front := v.mill_root.global_transform.basis.z
	var side := v.mill_root.global_transform.basis.x
	var lane_eye := Vector3(6.0, 0.0, -14.0)
	lane_eye.y = v.height(lane_eye.x, lane_eye.z) + 1.6
	var lane_end := Vector3(12.0, 0.0, -23.5)   # as far up the lane as the player can go
	lane_end.y = v.height(lane_end.x, lane_end.z) + 1.6
	var views := [
		# New Game's flight: its first frame, and on over the rooftops
		["intro_0", world.area.INTRO_FROM, Vector3(0, 3.0, 0), World.CAM_FOV],
		["intro_1", Vector3(-12.0, 8.5, 30.0), Vector3(0.0, 4.0, -2.0), World.CAM_FOV],
		# standing on the green at the foot of the lane, looking up it to the mill
		["lane", lane_eye, mill + Vector3(0, 5.0, 0), 50.0],
		["lane_end", lane_end, mill + Vector3(0, 5.0, 0), 50.0],
		# the mill up close: the door side, and side on (the sails clear the cap)
		["mill_front", mill + front * 15.0 + side * 6.0 + Vector3(0, 2.5, 0), mill + Vector3(0, 4.4, 0), 50.0],
		["mill_side", mill + side * 15.0 + front * 3.0 + Vector3(0, 5.0, 0), mill + Vector3(0, 5.5, 1.0), 50.0],
		["mill_base", mill + front * 6.0 - side * 4.0 + Vector3(0, 1.0, 0), mill + Vector3(0, 1.0, 0), 50.0],
		# the oaks: round the back of the village and from the green
		["oaks_west", Vector3(-8.0, 3.0, 8.0), Vector3(-34.0, 4.0, 18.0), 50.0],
		["oaks_wide", Vector3(0, 26, 40), Vector3(0, 0, -6), World.CAM_FOV],
		["oaks_north", Vector3(4.0, 2.4, -16.0), Vector3(-6.0, 4.0, -40.0), 50.0],
		# the player's own camera at the north corners of the green
		["play_nw", Vector3(-13.0, 8.2, -7.5), Vector3(-13.0, 1.1, -19.0), World.CAM_FOV],
		["play_ne", Vector3(13.0, 8.2, -7.5), Vector3(13.0, 1.1, -19.0), World.CAM_FOV],
	]
	# two of the oaks close to, from the village side, at head height
	for i in [0, 3]:
		if i < v.oaks.size():
			var o: Node3D = v.oaks[i]
			var back := -Vector3(o.position.x, 0, o.position.z).normalized()
			var eye := o.position + back * 15.0
			eye.y = v.height(eye.x, eye.z) + 1.7
			views.append(["oak_close_%d" % i, eye, o.position + Vector3(0, 4.0, 0), 50.0])
	var at := {}
	for vw in views:
		at[vw[0]] = vw
		Cine.shot(world, vw[1], vw[2], vw[3])
		await _frames(5)
		await _shot(vw[0])
	# the sails turn: the same view a second later
	Cine.shot(world, at.mill_front[1], at.mill_front[2], 50.0)
	await _wait(1.0)
	await _shot("mill_front_1s")
	# the film's "and one on the mill" shot, as ashford.gd frames it
	var top: Vector3 = v.mill_fire_point() if v.has_method("mill_fire_point") else v.mill_root.to_global(Vector3(0, 10.2, 0))
	Cine.shot(world, Vector3(4.0, 2.0, 8.0), top, 22.0)
	await _frames(6)
	await _shot("fire_aim")
	await v.strike(top + Vector3(0, 0.6, 0), Color(1.0, 0.55, 0.12), 0.5)
	v.fire_mill()
	await _wait(1.4)
	await _shot("fire_film")
	await _wait(4.0)
	await _shot("fire_film_later")
	Cine.shot(world, at.mill_front[1], at.mill_front[2], 50.0)
	await _wait(1.0)
	await _shot("fire_close")
	# the morning after (the sails have stopped)
	v.set_time("dawn")
	Cine.shot(world, Vector3(-30.0, 14.0, 40.0), Vector3(8.0, 4.0, -16.0), 46.0)
	await _wait(1.0)
	await _shot("dawn")
	Cine.shot(world, at.lane_end[1], at.lane_end[2], 50.0)
	await _frames(8)
	await _shot("dawn_lane")
	Cine.shot(world, at.oaks_west[1], at.oaks_west[2], 50.0)
	await _frames(8)
	await _shot("dawn_oaks")
	Cine.shot(world, at.mill_front[1], at.mill_front[2], 50.0)
	await _frames(8)
	await _shot("dawn_mill")


func _thornwood() -> void:
	var v := ThornwoodSet.new()
	add_child(v)
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	await _frames(10)
	v.burn_crest()
	var fb: Vector3 = ThornwoodSet.SPOTS.far_bank
	fb.y = v.height(fb.x, fb.z)
	var crest := ThornwoodSet.CREST + Vector3(0, v.height(ThornwoodSet.CREST.x, ThornwoodSet.CREST.z) + 4.0, 0)
	var mill := v.mill_root.global_position
	var nell := fb + Vector3(4.6, 0, -0.6)
	var views := [
		# the river film's opening: from behind the villagers up to the crest
		["river", fb + Vector3(-2.6, 3.4, 11.0), crest + Vector3(0, 1.0, 0), 42.0],
		# Nell looking back at the mill
		["nell_mill", nell + Vector3(1.6, 1.4, 3.6), crest + Vector3(14.0, 0, 0), 34.0],
		# the mill itself, from the riverbank
		["bank_mill", fb + Vector3(0, 1.7, 0), mill + Vector3(0, 5.0, 0), 22.0],
	]
	for vw in views:
		cam.global_position = vw[1]
		cam.look_at(vw[2], Vector3.UP)
		cam.fov = vw[3]
		await _wait(1.5)
		await _shot("thorn_" + vw[0])


func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
