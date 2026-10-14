extends Node
## Stills of Ashford's buildings: the green, the cottages, the Crooked Lantern
## and the north-west roof on fire.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 \
##       res://tests/village_shot.tscn -- <out_dir>

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	get_window().size = Vector2i(1600, 900)
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(40)
	world.hud.visible = false
	await _shot("spawn")
	var v: AshfordVillage = world.get_meta("village")
	var views := [
		["wide", Vector3(0, 26, 40), Vector3(0, 0, -6)],
		["inn", Vector3(-12, 4.5, 14), Vector3(-24, 3, 6)],
		["north", Vector3(4, 5, 2), Vector3(-6, 3, -20)],
		["east", Vector3(-2, 4, 2), Vector3(20, 3, -8)],
	]
	for vw in views:
		await world.cine_to(vw[1], vw[2], 0.05)
		await _frames(20)
		await _shot(vw[0])
	v.ignite_roof()
	var bh: Node3D = v.burning_house
	await world.cine_to(bh.global_position + Vector3(10, 7, 12), bh.global_position + Vector3(0, 3, 0), 0.05)
	await _frames(90)
	await _shot("fire")
	print("VILLAGE SHOT: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/village_%s.png" % [out_dir, name])
