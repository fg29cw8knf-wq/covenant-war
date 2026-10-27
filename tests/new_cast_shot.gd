extends Node
## Stills of Gary's 27 October arrivals in Ashford: Corin's mam at the
## bakery door, the festival loaf on the bread stall in the evening, and Tam
## tearing a piece off it and handing it over (AshfordDay.tam_bread).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/new_cast_shot.tscn -- <out_dir> [stall | krell]
## (stall: the loaf on the stall only; krell: Krell on the green at dusk only)

var out_dir := "user://"
var world: World


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	for f in ["ash_started", "ash_won_lantern", "first_deck", "corin_met", "ash_tam", "ash_tilly", "ash_nell", "ash_evening"]:
		Game.set_flag(f)
	world = World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	world.hud.visible = false
	var v: AshfordVillage = world.get_meta("village")
	if "krell" in args:
		await _krell(v)
		return
	AshfordDay.stage(world)
	AshfordP1.dress(world)
	AshfordP1.crowd(world)
	await _frames(20)
	# Corin's mam at the bakery door, from a few steps off
	var mam := Cine.body(world, "corin_mam")
	if mam != null and not "stall" in OS.get_cmdline_user_args():
		var at := mam.global_position
		var out: Vector3 = AshfordP1.mam_spot(v).out
		Cine.shot(world, at + out * 3.2 + Vector3(0.8, 1.6, 0), at + Vector3(0, 1.1, 0), 40.0)
		await _frames(10)
		await _shot("corin_mam")
	else:
		print("NEW CAST SHOT: no Corin's mam")
	# the bread stall in the evening, Tam behind it and the loaf on its table
	var stall: Node3D = v.stalls[1]
	var tam := Cine.body(world, "tam")
	var tp := tam.global_position
	Cine.place(world, "player", tp + Vector3(0.2, 0, 2.6), tp)
	await _frames(6)
	Cine.shot(world, tp + Vector3(1.4, 1.9, 4.2), tp + Vector3(0.5, 0.9, 0), 44.0)
	await _frames(10)
	await _shot("stall_loaf")
	var loaf: Node3D = v.get_meta("festival_loaf") if v.has_meta("festival_loaf") else null
	if loaf != null:
		Cine.shot(world, loaf.global_position + Vector3(0.5, 0.55, 0.9), loaf.global_position + Vector3(0, 0.05, 0), 40.0)
		await _frames(10)
		await _shot("loaf_close")
	if "stall" in OS.get_cmdline_user_args():
		get_tree().quit()
		return
	# Tam's bread: placed in front of him, then the scene
	Cine.place(world, "player", tam.global_position + Vector3(0.0, 0, 1.3), tam.global_position)
	await _frames(6)
	var run := func() -> void: await AshfordDay.tam_bread(world)
	run.call()
	for i in 6:
		await get_tree().create_timer(0.45).timeout
		await _shot("bread_%d" % i)
	await get_tree().create_timer(1.5).timeout
	await _shot("bread_end")
	print("NEW CAST SHOT: done")
	get_tree().quit()


## Krell on the green at dusk, where the Reckoning puts her, from the
## Reckoning's own camera (AshfordNight.reckoning's krell_cam).
func _krell(v: AshfordVillage) -> void:
	v.set_daylight(0.16)
	var at: Vector3 = (world.area as Script).get_script_constant_map().get("KRELL_AT")
	Cine.spawn(world, "krell", "krell", at, "Krell")
	Cine.look(world, "krell", Vector3(-2, 0, 5))
	await _frames(20)
	Cine.shot(world, at + Vector3(-4.0, 1.5, -1.6), at + Vector3(0.5, 1.5, 0), 34.0)
	await _frames(10)
	await _shot("krell_dusk")
	Cine.shot(world, at + Vector3(-2.2, 2.0, 3.6), at + Vector3(0, 1.0, 0), 42.0)
	await _frames(10)
	await _shot("krell_dusk_wide")
	print("NEW CAST SHOT: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("NEW CAST SHOT: saved ", name)
