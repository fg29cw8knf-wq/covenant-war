extends Node
## Stills of Tam's watermill (MillSet, Gary's watermill.glb and
## waterwheel.glb): the game's own arrival shot down the lane, the house and
## its wheel from across the race, the wheel close to (a second apart, so it
## can be seen turning), the axle into the wall, the door and its steps, and
## the evening with the race wall's lanterns lit. Ends "MILL SHOT: done".
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/mill_shot.tscn -- <out_dir>

var out_dir := "user://"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	world.hud.visible = false
	var v: AshfordVillage = world.get_meta("village")
	v.set_daylight(1.0)
	var m := MillSet.build(v)
	MillSet.enter(world)
	MillSet.lamps(v, false)
	var root: Node3D = m.root
	Cine.place(world, "player", m.arrive, m.tam)
	await _frames(10)
	print("MILL SHOT: wheel at ", m.wheel_at, " house model ", ResourceLoader.exists(MillSet.MILL_MODEL), " wheel model ", ResourceLoader.exists(MillSet.WHEEL_MODEL))
	var views := [
		["arrive", Vector3(-11.5, 4.4, 24.0), MillSet.ARRIVE + Vector3(0, 1.0, 0), 48.0],
		["mill_se", Vector3(9.0, 3.2, 13.0), Vector3(-1.2, 2.4, -1.0), 46.0],
		["mill_ne", Vector3(13.0, 3.0, -8.0), Vector3(-1.2, 2.2, -1.0), 46.0],
		["wheel", Vector3(8.0, 2.0, 2.0), Vector3(2.4, 1.4, -1.5), 38.0],
		["axle", Vector3(3.6, 1.6, 5.0), Vector3(1.6, 1.3, -1.5), 36.0],
		["door", Vector3(-1.6, 1.7, 10.0), Vector3(-1.8, 1.6, 2.8), 44.0],
		["tam_spot", Vector3(-3.0, 1.7, 9.0), MillSet.TAM + Vector3(0, 1.2, 0), 40.0],
	]
	for vw in views:
		Cine.shot(world, root.to_global(vw[1]), root.to_global(vw[2]), vw[3])
		await _frames(6)
		await _shot(vw[0])
	# the wheel turns: the same view a second later
	Cine.shot(world, root.to_global(views[3][1]), root.to_global(views[3][2]), 38.0)
	await _wait(1.0)
	await _shot("wheel_1s")
	# the evening: Corin's seat on the race wall, the lanterns lit
	v.set_daylight(0.0)
	MillSet.lamps(v, true)
	Cine.place(world, "player", m.arrive, m.corin)
	Cine.shot(world, root.to_global(Vector3(-11.5, 4.4, 24.0)), root.to_global(MillSet.ARRIVE + Vector3(0, 1.0, 0)), 48.0)
	await _frames(8)
	await _shot("evening")
	Cine.shot(world, root.to_global(Vector3(6.0, 2.4, 12.0)), root.to_global(Vector3(0.5, 1.6, 3.0)), 42.0)
	await _frames(6)
	await _shot("evening_wall")
	print("MILL SHOT: done")
	get_tree().quit()


func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
