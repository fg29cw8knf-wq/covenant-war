extends Node
## Stills of the Golden Gate of Solhaven (Gary's model since 22 October, at
## its real 24 m; its doors his since 23 October): from the road where Bram
## and the player stop, wide from further down it, under the arch, and from
## inside the square; then with the doors open.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 \
##       res://tests/gate_shot.tscn -- <out_dir>

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	get_window().size = Vector2i(1600, 900)
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	Game.set_flag("arrived_solhaven")
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	if world.hud != null:
		world.hud.visible = false
	var v: Node3D = world.get_meta("solhaven_set")
	var g: Vector3 = v.SPOTS.gate
	var road: Vector3 = v.SPOTS.road
	print("gate at %s, road at %s, doors %d" % [g, road, v.gate_doors.size()])
	var views := [
		["road", road + Vector3(-5.0, 1.7, 12.0), g + Vector3(0, 6.0, 0)],
		["road_wide", road + Vector3(0, 9.0, 42.0), g + Vector3(0, 7.0, 0)],
		["arch", g + Vector3(1.5, 1.7, 9.0), g + Vector3(0, 3.5, 0)],
		["square", g + Vector3(-9.0, 2.5, -24.0), g + Vector3(0, 6.0, 0)],
	]
	for vw in views:
		await world.cine_to(vw[1], vw[2], 0.05)
		await _frames(20)
		await _shot(vw[0])
	await v.open_gate(true, 0.2)
	await _frames(10)
	await world.cine_to(g + Vector3(1.5, 1.7, 9.0), g + Vector3(0, 3.5, 0), 0.05)
	await _frames(20)
	await _shot("arch_open")
	await world.cine_to(g + Vector3(-9.0, 2.5, -24.0), g + Vector3(0, 6.0, 0), 0.05)
	await _frames(20)
	await _shot("square_open")
	print("GATE SHOT: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/gate_%s.png" % [out_dir, name])
	print("saved gate_%s.png" % name)
