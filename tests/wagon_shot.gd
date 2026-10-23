extends Node
## Stills of Bram's wagon in Solhaven's stable yard (Gary's covered wagon
## since 23 October, at its real size, Turnip in its shafts): from the yard
## with the shafts, from the tail, and the tail again at night with the
## Lantern's lamp lit.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 \
##       res://tests/wagon_shot.tscn -- <out_dir>

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
	var wg: Vector3 = v.wagon.global_position
	print("wagon at %s, Turnip at %s" % [wg, v.turnip.global_position])
	var views := [
		["yard", wg + Vector3(-7.5, 2.2, -7.0), wg + Vector3(0, 1.3, -1.0)],
		["side", wg + Vector3(-8.5, 1.7, 1.5), wg + Vector3(0, 1.4, 0)],
		["tail", wg + Vector3(-3.0, 1.9, 6.5), wg + Vector3(0, 1.4, 0.5)],
	]
	for vw in views:
		await world.cine_to(vw[1], vw[2], 0.05)
		await _frames(20)
		await _shot(vw[0])
	v.set_scene("night")
	v.light_wagon_lamp(true)
	await world.cine_to(wg + Vector3(-3.0, 1.9, 6.5), wg + Vector3(0, 1.4, 0.5), 0.05)
	await _frames(20)
	await _shot("tail_night")
	print("WAGON SHOT: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/wagon_%s.png" % [out_dir, name])
	print("saved wagon_%s.png" % name)
