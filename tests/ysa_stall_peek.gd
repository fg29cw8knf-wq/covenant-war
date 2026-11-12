extends Node
## Stills of Gary's 12 November Solhaven pieces in their places: Ysa (her own
## model) sitting on the road outside the Golden Gate with Tobin asleep across
## her lap, as the gate film stages them (Films._gate_people), close and wide;
## and Tamsin's card stall (solhaven/card_stall.glb) in the Sun Square, Tamsin
## (the square's own) in front of it for scale.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/ysa_stall_peek.tscn -- <out_dir> [gate]     (gate: only the gate's stills)

const Films := preload("res://scripts/world/solhaven/films.gd")
var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	var world := World.new().setup("solhaven", "road")
	add_child(world)
	await _frames(40)
	world.hud.visible = false
	Films._gate_people(world)
	await _frames(30)
	Cine.overlay(world).visible = false   # (the arrival's subtitles, over the stills)
	var y := Cine.body(world, "gate_ysa")
	var f = Cine.fig(world, "gate_ysa")
	print("YSA STALL PEEK: Ysa is ", "her own model" if f is Figure3D and (f as Figure3D)._model_name == "ysa" else "NOT her model: %s" % [f])
	var at := y.global_position
	Cine.shot(world, at + Vector3(0.4, 1.3, 3.2), at + Vector3(0, 0.6, 0), 40.0)
	await _frames(12)
	await _shot("ysa_gate")
	Cine.shot(world, at + Vector3(-0.9, 1.15, 1.5), at + Vector3(0, 0.95, 0), 34.0)
	await _frames(12)
	await _shot("ysa_close")
	# the pair from above and from his feet: his head in her lap
	Cine.shot(world, at + Vector3(0.6, 2.6, 1.2), at + Vector3(0.3, 0.2, 0.2), 40.0)
	await _frames(12)
	await _shot("ysa_tobin_above")
	var tob := Cine.body(world, "gate_tobin").global_position
	Cine.shot(world, tob + (tob - at).normalized() * 1.6 + Vector3(0, 0.9, 0), at + Vector3(0, 0.45, 0), 40.0)
	await _frames(12)
	await _shot("ysa_tobin_feet")
	Cine.shot(world, at + Vector3(3.5, 2.6, 7.5), at + Vector3(2.0, 1.0, -2.0), 50.0)
	await _frames(12)
	await _shot("gate_wide")
	# the film's own shot of her ("a woman with a sleeping boy across her lap")
	Cine.shot(world, at + Vector3(2.4, 1.3, 1.6), at + Vector3(0, 0.8, 0), 34.0)
	await _frames(12)
	await _shot("ysa_film")
	# the guards in front of the gate, from the road
	Cine.shot(world, Vector3(1.8, 1.6, 36.4), Vector3(0, 3.0, 25.0), 44.0)
	await _frames(12)
	await _shot("gate_guards")
	if args.size() > 1 and args[1] == "gate":
		print("YSA STALL PEEK: done")
		get_tree().quit()
		return
	# the square: the stall, Tamsin in front of it, the player beside her
	var w2 := World.new().setup("solhaven", "inn")
	world.queue_free()
	add_child(w2)
	await _frames(40)
	w2.hud.visible = false
	Cine.overlay(w2).visible = false
	var stall := Vector3(12.8, 0, 6.0)
	# (Tamsin is the square's own, in front of her stall: Solhaven's people)
	var p := Cine.body(w2, "player")
	if p != null:
		p.global_position = Vector3(10.6, 0, 7.6)
		Cine.look(w2, "player", stall)
	await _frames(20)
	Cine.shot(w2, stall + Vector3(-6.5, 1.9, 2.4), stall + Vector3(0, 1.1, 0), 45.0)
	await _frames(12)
	await _shot("stall_square")
	Cine.shot(w2, stall + Vector3(-3.0, 1.6, -2.6), stall + Vector3(0, 1.0, 0.3), 45.0)
	await _frames(12)
	await _shot("stall_side")
	# the sign on its hanging board, close
	var sign := w2.find_child("StallSign", true, false) as Node3D
	print("YSA STALL PEEK: the stall's sign is ", "up" if sign != null else "MISSING")
	if sign != null:
		var sp := sign.global_position
		var out := sign.global_transform.basis.z.normalized()
		Cine.shot(w2, sp + out * 1.4 + Vector3(0, -0.1, 0), sp, 30.0)
		await _frames(12)
		await _shot("stall_sign")
		Cine.shot(w2, sp + out * 4.0 + Vector3(-1.0, -0.3, 1.2), sp + Vector3(0, -0.4, 0), 40.0)
		await _frames(12)
		await _shot("stall_sign_far")
	print("YSA STALL PEEK: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("YSA STALL PEEK: saved ", name)
