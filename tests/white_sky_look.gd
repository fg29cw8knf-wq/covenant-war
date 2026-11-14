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
##       res://tests/white_sky_look.tscn -- <dir> [night open torn mid wide back rim bowl held flash eyes close] [-- --phone]
##
## (The second pass of 14 November: "open" the opening's wide shot, as it
## begins, on its way down and nearly home; "flash" the lightning behind the
## rim with the hunter black against it; "eyes" the pack's eyes open along
## the rim; "close" Bram near, his coat in a gust and the snow on him.)
##
## With no names, all of them. `-- --phone` (Gfx) draws the phone's Smooth
## picture; `-- --best` a Mac's "Best picture" (Gfx.Best); `--rendering-driver opengl3 --rendering-method gl_compatibility`
## the phone link's.

var out := "/tmp/ws_look"
var m: WhiteSky
var _peek := false
var _pos := Vector3.ZERO
var _look := Vector3.ZERO
var _fov := 50.0
var _n := 0
var _blow := false
const ALL := ["night", "open", "torn", "mid", "wide", "back", "rim", "bowl", "held", "flash", "eyes", "close"]


func _ready() -> void:
	process_priority = 100   # (after WhiteSky's own camera)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1280, 720)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	# (`-- --best`: a Mac's "Best picture", Gfx.Best, to set beside the same still without)
	Game.settings["best_picture"] = "--best" in OS.get_cmdline_user_args()
	Gfx.setup(get_tree())
	m = WhiteSky.new()
	m.prep_early = false
	add_child(m)
	_run.call_deferred()


func _process(_d: float) -> void:
	if _blow and m != null:
		m._gust_k = 1.0   # (a gust held at its height for a still)
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
	if names.has("open"):
		# the opening's wide shot (WhiteSky._open_k: 1, on its way, nearly home)
		_stand(0.0, -2.0)
		var op := m._bram.position
		var roam_pos := op + Vector3(0.75, 1.85, 3.0)
		var roam_look := op + Vector3(0.0, 1.35, -7.0)
		for k: float in [1.0, 0.62, 0.3]:
			var e := smoothstep(0.0, 1.0, k)
			_at(roam_pos.lerp(op + WhiteSky.OPEN_FROM, e), roam_look.lerp(op + WhiteSky.OPEN_LOOK, e), lerpf(50.0, WhiteSky.OPEN_LENS, e))
			await _shot("open_%03d" % int(k * 100.0), 20)
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
	if names.has("flash") or names.has("eyes"):
		var kd3 := m._kneel_dir(Vector3.FORWARD)
		var bottom3 := m._kneel_spot(kd3)
		m._ad = kd3
		m._bram.position = bottom3
		if m._bram is Figure3D:
			(m._bram as Figure3D).snap_face(kd3)
		m._shaft_k = 0.0
		m._child_beacon(false)
		m._crater_k = 0.32
		m._baby.visible = false   # (in his coat by now)
		var rt3 := kd3.cross(Vector3.UP)
		var rim3 := c + kd3 * WhiteSky.RIM_AT
		if names.has("flash"):
			# the lightning behind the rim, the hunter black against it (held
			# at its brightest for the still: WhiteSky._rim_flash)
			var w3 := bottom3 - kd3 * 5.6 + rt3 * 2.0 + Vector3(0, 1.0, 0)
			w3.y = maxf(w3.y, WhiteSky.height(w3.x, w3.z) + 0.4)
			_at(w3, bottom3 + kd3 * 1.8 + Vector3(0, 2.0, 0), 46.0)
			var form := rim3 + kd3 * WhiteSky.RIM_BACK
			form.y = WhiteSky.height(form.x, form.z)
			await _shot("flash_before", 14)
			m._cam_pos = w3   # (the bolt falls behind it as this camera sees it)
			m._rim_flash_on(form)
			m._rim_bolt.secs = 9.0
			m._rim_light(1.0)
			await _shot("flash", 1)
			m._rim_light(0.0)
			m._rim_bolt.queue_free()
			m._rim_sheet.queue_free()
			m._hunter.visible = false
		if names.has("eyes"):
			# the pack's eyes along the rim (the memory's own camera for it)
			m._hunter.position = Vector3(rim3.x, WhiteSky.height(rim3.x, rim3.z), rim3.z)
			m._hunter.look_at_dir(m._bram.position - m._hunter.position)
			m._hunter.visible = true
			m._hunter._set_fade(1.0)
			_peek = false
			m._rim_pack(rim3, bottom3, rt3)
			await _shot("eyes", 44)
			m._hunter.visible = false
		m._baby.visible = true
	if names.has("close"):
		# him, near: from behind, from his side and from over his shoulder (his
		# coat and hair in the wind, the snow lying on him)
		if m._weather != null:
			m._snow_on = 0.5   # (about what's on him by the crater)
			m._weather.set_shader_parameter("snow_k", 0.5)
		_stand(1.5, -15.0)
		var bp := m._bram.position
		var fw := (WhiteSky.CRATER - bp)
		fw.y = 0.0
		fw = fw.normalized()
		var sd := -fw.cross(Vector3.UP)
		_at(bp - fw * 2.3 + Vector3(0, 1.3, 0), bp + Vector3(0, 1.05, 0), 44.0)
		await _shot("close_behind", 24)
		_at(bp + sd * 2.4 - fw * 0.5 + Vector3(0, 1.3, 0), bp + Vector3(0, 1.05, 0), 44.0)
		await _shot("close_side", 10)
		# (and in a gust: WhiteSky._weather_step takes his coat's wind up with it)
		_blow = true
		await _shot("close_side_gust", 16)
		_at(bp - fw * 2.3 + Vector3(0, 1.3, 0), bp + Vector3(0, 1.05, 0), 44.0)
		await _shot("close_behind_gust", 8)
		_blow = false
		_at(bp - fw * 1.1 - sd * 0.5 + Vector3(0, 1.95, 0), bp + Vector3(0, 1.5, 0), 40.0)
		await _shot("close_shoulder", 10)
		# (and at its most, as after a long wander)
		if m._weather != null:
			m._weather.set_shader_parameter("snow_k", WhiteSky.SNOW_ON_MAX)
		await _shot("close_shoulder_most", 6)
		_at(bp - fw * 2.3 + Vector3(0, 1.3, 0), bp + Vector3(0, 1.05, 0), 44.0)
		await _shot("close_behind_most", 6)
	print("WHITE SKY LOOK: done in ", out)
	get_tree().quit()
