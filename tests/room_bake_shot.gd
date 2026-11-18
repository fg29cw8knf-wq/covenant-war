extends Node
## Stills of the inn's rooms with their baked bounced light (18 November,
## BakedLight): the attic on its frosty morning and in the grey before
## sunrise (the awakening), and the taproom in the evening, each from a few
## places in the room, with the checks that the baked light is on (or off).
##   flat     no baked light (the before: BakedLight.enabled off)
##   phone    the iPhone's Smooth level (Gfx level 1) instead of the Mac's
##   fill=F bounce=B   the attic's fill and bounce lights scaled under baked
##            light (InnRooms.baked_fill, baked_bounce)
## Forward+ through software Vulkan, as the Mac and the iPhone draw them:
##   VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a -s "-screen 0 1280x720x24" \
##       godot --rendering-driver vulkan --resolution 960x540 \
##       res://tests/room_bake_shot.tscn -- <out_dir> [flat] [attic] [eve]
## Stills are <out_dir>/<room>_<state>_<view>.png.

var out := "/tmp"
var problems: Array = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp"
	var flat := "flat" in args
	Gfx.force_level = 1 if "phone" in args else 2
	for a in args:
		if a.begins_with("fill="):
			InnRooms.baked_fill = float(a.substr(5))
		elif a.begins_with("bounce="):
			InnRooms.baked_bounce = float(a.substr(7))
	BakedLight.enabled = not flat
	var rooms: Array = []
	for r in ["attic", "eve"]:
		if r in args:
			rooms.append(r)
	if rooms.is_empty():
		rooms = ["attic", "eve"]
	var v := AshfordVillage.new()
	add_child(v)
	var cam := Camera3D.new()
	cam.near = 0.05
	add_child(cam)
	cam.current = true
	await _frames(10)
	InnRooms.inside(v)
	if "attic" in rooms:
		var a := InnRooms.attic(v)
		var o: Vector3 = (a.root as Node3D).global_position
		var views := [
			["bed", o + Vector3(2.2, 1.6, 1.7), o + Vector3(-0.8, 0.5, -1.7), 55.0],
			["window", o + Vector3(1.6, 1.5, -0.4), o + Vector3(-2.8, 1.2, 0.3), 55.0],
			["gable", o + Vector3(-1.8, 1.5, 1.2), o + Vector3(2.8, 1.1, -0.8), 55.0],
		]
		_check(a.root, "attic", "morning", flat)
		await _views(cam, views, "attic_morning")
		InnRooms.attic_awakening(a)
		_check(a.root, "attic", "awakening", flat)
		await _views(cam, views, "attic_awakening")
	if "eve" in rooms:
		var e := InnRooms.eve(v)
		var o: Vector3 = InnRooms.EVE_AT
		var views := [
			["bar", o + Vector3(1.2, 1.65, 1.6), o + Vector3(-4.3, 1.35, -0.6), 50.0],
			["room", o + Vector3(-3.6, 1.7, 2.4), o + Vector3(3.0, 1.0, -2.2), 55.0],
			["hearth", o + Vector3(0.5, 1.6, -0.5), o + Vector3(3.8, 0.9, 2.5), 55.0],
		]
		_check(e.root, "eve", "evening", flat)
		await _views(cam, views, "eve_evening")
	print("ROOM BAKE: problems %s" % ("none" if problems.is_empty() else str(problems)))
	get_tree().quit(1 if not problems.is_empty() else 0)


func _check(root: Node3D, room: String, state: String, flat: bool) -> void:
	var on := BakedLight.on(root)
	var want := not flat and ResourceLoader.exists(BakedLight.DIR + "%s/%s.lmbake" % [room, state])
	if on != want:
		problems.append("%s %s: baked light %s, wanted %s" % [room, state, on, want])
	print("ROOM BAKE: %s %s baked light %s" % [room, state, on])


func _views(cam: Camera3D, views: Array, tag: String) -> void:
	for vw in views:
		cam.fov = vw[3]
		cam.global_position = vw[1]
		cam.look_at(vw[2], Vector3.UP)
		await _frames(8)
		get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, vw[0]])


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
