extends Node
## Stills for the look pass (5 November, Gary: "make the game look visually
## as amazing as possible"): Ashford by day, at sunset and at midnight, from
## close in (the inn's front, the well, the stall and the carts, a cottage, an
## oak's bark) and wide; the Thornwood; Solhaven's gate. Each still is saved
## as <out_dir>/<tag>_<name>.png, so a before and an after sit side by side.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 960x540 \
##       --fixed-fps 30 res://tests/look_shot.tscn -- <out_dir> <tag> [day] [dusk] [night] [taproom] [thornwood] [solhaven] [only=<name>,<name>] [nomaps] [nograde] [noprobes] [people]
## With none of day/dusk/night/thornwood/solhaven, all of them. `--print-fps`
## prints the frame rate; each view also prints its average frame time.

var out_dir := "user://"
var tag := "look"
var only := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		tag = args[1]
	if "nograde" in args:
		AshfordVillage.grading = false   # no colour grade per place and time
	if "nomaps" in args:
		LevelKit.maps = false   # Gary's models without their normal and roughness maps
	for a in args:
		if String(a).begins_with("only="):
			only = String(a).trim_prefix("only=")
	var parts := []
	if "noprobes" in args:
		AshfordVillage.room_probes = false   # the inn's rooms without their reflection probes
	for p in ["day", "dusk", "night", "taproom", "thornwood", "solhaven"]:
		if p in args:
			parts.append(p)
	if parts.is_empty():
		parts = ["day", "dusk", "night", "thornwood", "solhaven"]
	Game.new_game("Sprout", "emberstorm")
	Game.set_flag("arrived_ashford")
	Game.set_flag("arrived_solhaven")
	if parts.has("day") or parts.has("dusk") or parts.has("night"):
		await _ashford(parts)
	if parts.has("taproom"):
		await _taproom()
	if parts.has("thornwood"):
		await _thornwood()
	if parts.has("solhaven"):
		await _solhaven()
	print("LOOK SHOT: done")
	get_tree().quit()


func _ashford(parts: Array) -> void:
	# the village set on its own, without the world's people (their models
	# take more memory than this machine can spare alongside the other jobs);
	# `people` builds the whole walkable world instead
	var world: World = null
	var v: AshfordVillage
	var cam: Camera3D
	if "people" in OS.get_cmdline_user_args():
		world = World.new().setup("ashford", "green")
		add_child(world)
		await _frames(40)
		if world.hud != null:
			world.hud.visible = false
		v = world.get_meta("village")
		cam = world.cam
	else:
		v = AshfordVillage.new()
		add_child(v)
		cam = Camera3D.new()
		cam.near = 0.3
		cam.far = 400.0
		add_child(cam)
		cam.current = true
		await _frames(10)
	var inn := Vector3(-24.0, 0.0, 6.0)
	var views := [
		# the inn's front from the green, close: its plaster, beams and thatch
		["inn", inn + Vector3(10.5, 2.0, 3.5), inn + Vector3(2.5, 2.4, 0.0), 45.0],
		# the well and the blue stall from where Corin waits
		["well", Vector3(-1.5, 1.7, 8.5), Vector3(-6.0, 1.1, 3.0), 45.0],
		# the merchant carts on the west side, the barrel and the hay cart
		["carts", Vector3(-4.0, 1.8, -2.0), Vector3(-10.0, 1.0, -6.5), 45.0],
		["haycart", Vector3(4.0, 1.8, -0.5), Vector3(9.0, 0.9, -5.0), 45.0],
		# a cottage close, from the ring road
		["cottage", Vector3(9.0, 2.2, -9.0), Vector3(19.5, 2.4, -6.5), 45.0],
		# the green wide, the Great Lantern in the middle
		["green", Vector3(10.0, 5.0, 16.0), Vector3(-2.0, 3.0, -4.0), 50.0],
	]
	for when in [["day", 1.0], ["dusk", 0.3], ["night", 0.0]]:
		if not parts.has(when[0]):
			continue
		v.set_daylight(float(when[1]))
		await _frames(4)
		for vw in views:
			if only != "" and not (String(vw[0]) in only.split(",")):
				continue
			cam.fov = vw[3]
			if world != null:
				await world.cine_to(vw[1], vw[2], 0.05)
			else:
				cam.global_position = vw[1]
				cam.look_at(vw[2], Vector3.UP)
			await _frames(6)
			await _shot("%s_%s" % [when[0], vw[0]])
	(world if world != null else v).queue_free()
	if world == null:
		cam.queue_free()
	await _frames(4)


## The evening's taproom (InnRooms.eve): the bar, the shelves of pewter,
## copper and bottles behind it, lit as the film lights it inside.
func _taproom() -> void:
	var v := AshfordVillage.new()
	add_child(v)
	await _frames(6)
	var e: Dictionary = InnRooms.eve(v)
	InnRooms.inside(v)
	var o := InnRooms.EVE_AT
	var cam := Camera3D.new()
	cam.near = 0.05
	add_child(cam)
	cam.current = true
	cam.fov = 50.0
	cam.global_position = o + Vector3(1.2, 1.65, 1.6)
	cam.look_at(o + Vector3(-4.3, 1.35, -0.6), Vector3.UP)
	await _frames(12)
	await _shot("taproom_bar")
	cam.fov = 32.0
	cam.global_position = o + Vector3(-1.6, 1.5, 0.4)
	cam.look_at(o + Vector3(-4.4, 1.5, -0.9), Vector3.UP)
	await _frames(6)
	await _shot("taproom_shelves")
	v.queue_free()
	cam.queue_free()
	await _frames(4)


## The Thornwood set (as tests/props_shot.gd stages it): the riverbank at
## night looking up at the crest, and the camp's clearing by morning.
func _thornwood() -> void:
	var v := ThornwoodSet.new()
	add_child(v)
	var cam := Camera3D.new()
	cam.near = 0.2
	cam.far = 600.0
	add_child(cam)
	cam.current = true
	await _frames(10)
	v.set_scene("river")
	var fb: Vector3 = ThornwoodSet.SPOTS.far_bank
	fb.y = v.height(fb.x, fb.z)
	var crest := ThornwoodSet.CREST + Vector3(0, v.height(ThornwoodSet.CREST.x, ThornwoodSet.CREST.z) + 4.0, 0)
	cam.fov = 42.0
	cam.global_position = fb + Vector3(-2.6, 3.4, 11.0)
	cam.look_at(crest + Vector3(0, 1.0, 0), Vector3.UP)
	await _frames(8)
	await _shot("thorn_river")
	v.set_scene("morning")
	var camp: Vector3 = ThornwoodSet.SPOTS.camp
	camp.y = v.height(camp.x, camp.z)
	cam.fov = 45.0
	cam.global_position = camp + Vector3(5.0, 2.0, 6.0)
	cam.look_at(camp + Vector3(0, 1.0, 0), Vector3.UP)
	await _frames(8)
	await _shot("thorn_morning")
	v.queue_free()
	cam.queue_free()
	await _frames(4)


func _solhaven() -> void:
	var world := World.new().setup("solhaven", "gate")
	add_child(world)
	await _frames(40)
	if world.hud != null:
		world.hud.visible = false
	var v: Node3D = world.get_meta("solhaven_set")
	var g: Vector3 = v.SPOTS.gate
	var road: Vector3 = v.SPOTS.road
	world.cam.fov = 45.0
	await world.cine_to(road + Vector3(-5.0, 1.7, 12.0), g + Vector3(0, 6.0, 0), 0.05)
	await _frames(20)
	await _shot("sol_road")
	await world.cine_to(g + Vector3(1.5, 1.7, 9.0), g + Vector3(0, 3.5, 0), 0.05)
	await _frames(20)
	await _shot("sol_arch")
	world.queue_free()
	await _frames(4)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	var t0 := Time.get_ticks_usec()
	for i in 4:
		await get_tree().process_frame
	var ms := (Time.get_ticks_usec() - t0) / 4000.0
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out_dir, tag, name])
	print("saved %s_%s.png  (%.1f ms a frame)" % [tag, name, ms])
