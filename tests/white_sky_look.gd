extends Node
## Stills of the Night of the White Sky's look, without playing it (14
## November, Gary: "make the bram bit at the beginning look visually better
## and smoother - I want best looking graphics and scenery"): the walk under
## the night sky, the same with the sky torn, half way to the crater, a wide
## view of the Shardlands, the rim and the bowl. A handful of frames, so a
## change to the set (ShardSet, WhiteSky._build_set) can be looked at in a
## couple of minutes on a machine with no graphics card.
##
##   VK_ICD_FILENAMES=<lvp_icd.json> xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver vulkan \
##       --rendering-method forward_plus --resolution 1280x720 --fixed-fps 10 --path . \
##       res://tests/white_sky_look.tscn -- <dir> [night torn mid wide back rim bowl held] [-- --phone]
##
## With no names, all of them. `-- --phone` (Gfx) draws the phone's Smooth
## picture; `--rendering-driver opengl3 --rendering-method gl_compatibility`
## the phone link's.

var out := "/tmp/ws_look"
var m: WhiteSky
var _peek := false
var _pos := Vector3.ZERO
var _look := Vector3.ZERO
var _fov := 50.0
var _n := 0
const ALL := ["night", "torn", "mid", "wide", "back", "rim", "bowl", "held"]


func _ready() -> void:
	process_priority = 100   # (after WhiteSky's own camera)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1280, 720)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	m = WhiteSky.new()
	m.prep_early = false
	add_child(m)
	_run.call_deferred()


func _process(_d: float) -> void:
	if _peek and m != null and m._cam != null:
		m._cam_mode = "peek"
		m._cam_pos = _pos
		m._cam_look = _look
		m._cam.fov = _fov
		m._apply_cam()


func _at(pos: Vector3, look: Vector3, fov := 50.0) -> void:
	_peek = true
	_pos = pos
	_look = look
	_fov = fov


func _shot(nm: String, settle := 8) -> void:
	for k in settle:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	print("white_sky_look: ", nm)


## Bram stood at (x, z) facing the crater, and the walk's camera behind him.
func _stand(x: float, z: float) -> void:
	var p := Vector3(x, WhiteSky.height(x, z), z)
	m._flat = Vector3(x, 0, z)
	m._bram.position = p
	var f := (WhiteSky.CRATER - p)
	f.y = 0.0
	f = f.normalized()
	WhiteSky._face(m._bram, f)
	if m._bram is Figure3D:
		(m._bram as Figure3D).snap_face(f)
	var r := -f.cross(Vector3.UP)
	_at(p - f * 3.0 - r * 0.75 + Vector3(0, 1.85, 0), p + f * 7.0 + Vector3(0, 1.35, 0))


## The sky torn (WhiteSky.tear_now), and the Sigils coming down.
func _tear() -> void:
	m.tear_now()
	m._rain_cards(true)


func _run() -> void:
	var names: Array = Array(OS.get_cmdline_user_args()).slice(1).filter(func(a): return ALL.has(String(a)))
	if names.is_empty():
		names = ALL.duplicate()
	await get_tree().process_frame
	m._ov = m._own_overlay()
	m._black.modulate.a = 0.0
	m._cam_mode = "peek"
	var c := WhiteSky.CRATER
	if names.has("night"):
		_stand(0.0, -2.0)
		await _shot("night", 30)
	_tear()
	if names.has("torn"):
		_stand(0.0, -2.0)
		await _shot("torn", 30)
	if names.has("mid"):
		_stand(1.5, -15.0)
		# (prints, as if someone had walked across ahead of him: the walk's
		# camera keeps his own behind it)
		for i in 12:
			var x := -1.5 + 0.7 * i
			var z := -19.0 + (0.11 if i % 2 == 0 else -0.11) - 0.12 * i
			m._prints.step(Vector3(x, WhiteSky.height(x, z), z), Vector3.UP, Vector3(1, 0, -0.17))
		await _shot("mid", 20)
	if names.has("wide"):
		_stand(-6.0, -9.0)
		_at(Vector3(-16.0, 4.5, 6.0), c + Vector3(0, 6.0, 0), 58.0)
		await _shot("wide", 12)
	if names.has("back"):
		# looking back the way he came, along the light: the drifts lit square on
		_stand(0.0, -12.0)
		_at(Vector3(2.0, 1.7, -22.0), Vector3(0.0, 1.0, -6.0), 46.0)
		await _shot("back", 12)
	if names.has("rim"):
		var b := c + Vector3(0, 0, WhiteSky.RIM_AT)
		_stand(b.x, b.z)
		var ad := Vector3.FORWARD
		var rt := ad.cross(Vector3.UP)
		m._child_beacon(true)
		m._shaft_k = 0.0
		_at(m._bram.position - ad * 2.6 + rt * 1.3 + Vector3(0, 3.4, 0), m._baby.position + Vector3(0, 0.3, 0), 44.0)
		await _shot("rim", 14)
	if names.has("bowl"):
		var kd := m._kneel_dir(Vector3.FORWARD)
		var bottom := m._kneel_spot(kd)
		m._bram.position = bottom
		if m._bram is Figure3D:
			(m._bram as Figure3D).snap_face(kd)
		m._child_beacon(true)
		m._shaft_k = 0.0
		_at(bottom - kd * 1.9 + kd.cross(Vector3.UP) * 1.45 + Vector3(0, 1.15, 0), m._baby.position + Vector3(0, 0.2, 0), 40.0)
		await _shot("bowl", 14)
	if names.has("held"):
		# the hush before the hunter: wide and low behind him in the bowl
		var kd2 := m._kneel_dir(Vector3.FORWARD)
		var bottom2 := m._kneel_spot(kd2)
		m._bram.position = bottom2
		m._shaft_k = 0.0
		m._child_beacon(false)
		m._crater_k = 0.32
		var rt2 := kd2.cross(Vector3.UP)
		var rim := c + kd2 * WhiteSky.RIM_AT
		var rim_look := Vector3(rim.x, WhiteSky.height(rim.x, rim.z) + 1.1, rim.z)
		var w0 := bottom2 - kd2 * 6.2 + rt2 * 2.2 + Vector3(0, 0.9, 0)
		w0.y = maxf(w0.y, WhiteSky.height(w0.x, w0.z) + 0.4)
		_at(w0, bottom2 + kd2 * 1.4 + Vector3(0, 1.9, 0), 46.0)
		await _shot("held", 14)
	print("WHITE SKY LOOK: done in ", out)
	get_tree().quit()
