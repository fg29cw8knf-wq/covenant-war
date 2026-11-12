extends Node
## Stills of Gary's 12 November Solhaven pieces in their places: Ysa (her own
## model) sitting on the road outside the Golden Gate with Tobin asleep across
## her lap, as the gate film stages them (Films._gate_people), close and wide;
## and Tamsin's card stall (solhaven/card_stall.glb) in the Sun Square, Tamsin
## (the square's own) in front of it for scale.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/ysa_stall_peek.tscn -- <out_dir>

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
	Cine.shot(world, at + Vector3(3.5, 2.6, 7.5), at + Vector3(2.0, 1.0, -2.0), 50.0)
	await _frames(12)
	await _shot("gate_wide")
	# the square: the stall, Tamsin in front of it, the player beside her
	var w2 := World.new().setup("solhaven", "inn")
	world.queue_free()
	add_child(w2)
	await _frames(40)
	w2.hud.visible = false
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
	print("YSA STALL PEEK: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("YSA STALL PEEK: saved ", name)
