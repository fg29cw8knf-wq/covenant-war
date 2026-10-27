extends Node
## Stills of Gary's 27 October people in Solhaven's light: the refugee woman
## (the travel-worn woman) where the refugees wait inside the Golden Gate,
## and Huntmaster Krell beside her, full length and close.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/new_cast_solhaven.tscn -- <out_dir>

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	world.hud.visible = false
	var at := Vector3(5.6, 0, 33.6)   # (where the gate film's refugee stands)
	Cine.spawn(world, "refugee", "refugee", at, "Refugee")
	Cine.spawn(world, "krell", "krell", at + Vector3(1.4, 0, 0.3), "Krell")
	await _frames(20)
	var r := Cine.body(world, "refugee")
	var k := Cine.body(world, "krell")
	Cine.look(world, "refugee", at + Vector3(0, 0, -4))
	Cine.look(world, "krell", at + Vector3(0, 0, -4))
	await _frames(10)
	var mid := (r.global_position + k.global_position) * 0.5
	Cine.shot(world, mid + Vector3(0.3, 1.4, -4.2), mid + Vector3(0, 0.95, 0), 40.0)
	await _frames(12)
	await _shot("pair")
	Cine.shot(world, r.global_position + Vector3(0.1, 1.55, -1.3), r.global_position + Vector3(0, 1.45, 0), 36.0)
	await _frames(12)
	await _shot("refugee_close")
	Cine.shot(world, k.global_position + Vector3(0.1, 1.7, -1.4), k.global_position + Vector3(0, 1.58, 0), 36.0)
	await _frames(12)
	await _shot("krell_close")
	print("NEW CAST SOLHAVEN: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("NEW CAST SOLHAVEN: saved ", name)
