extends Node
## Reference stills of Ashford for Gary's films (Films for Player A: Your
## Step-by-Step): the green, the Great Lantern, the inn, the well and the
## lanes, each at night (as the Lantern Night is built) and by day, with no
## people, bars or subtitles, so the layout reads clearly.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##       --resolution 1280x720 res://tests/ashford_refs.tscn -- <out_dir> [night|day|both]

var out_dir := "user://"

const VIEWS := [
	["01_green_wide", Vector3(0, 26, 40), Vector3(0, 0, -6), 50.0],
	["02_great_lantern", Vector3(3.2, 1.7, 12.5), Vector3(0, 4.6, 0), 40.0],
	["03_inn", Vector3(-12, 4.5, 14), Vector3(-24, 3, 6), 50.0],
	["04_well_and_bench", Vector3(-1.0, 2.4, 11.0), Vector3(-5.5, 1.0, 3.5), 45.0],
	["05_lane_to_the_inn", Vector3(-2.0, 1.7, 9.0), Vector3(-24, 2.5, 6), 45.0],
	["06_north", Vector3(4, 5, 2), Vector3(-6, 3, -20), 50.0],
	["07_east", Vector3(-2, 4, 2), Vector3(20, 3, -8), 50.0],
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var which: String = args[1] if args.size() > 1 else "both"
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	var world := World.new().setup("ashford", "green")
	add_child(world)
	await _frames(30)
	world.hud.visible = false
	if world.player != null:
		world.player.visible = false
	var v: AshfordVillage = world.get_meta("village")
	for npc in world.get_children():
		if npc != world.player and npc is Node3D and npc.has_meta("npc"):
			(npc as Node3D).visible = false
	var times: Array = ["night", "day"] if which == "both" else [which]
	for t in times:
		if t == "day":
			v.set_time("day")
			await _frames(6)
		for vw in VIEWS:
			await world.cine_to(vw[1], vw[2], 0.05)
			if world.cam != null:
				world.cam.fov = vw[3]
			await _frames(10)
			await _shot("%s_%s" % [vw[0], t])
	print("ASHFORD REFS: done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/ashford_%s.png" % [out_dir, name])
	print("shot ", name)
