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
##       res://tests/white_sky_look.tscn -- <dir> [night open torn mid wide back rim bowl held flash eyes close demand out fight] [-- --phone]
##
## (The second pass of 14 November: "open" the opening's wide shot, as it
## begins, on its way down and nearly home; "flash" the lightning behind the
## rim with the hunter black against it; "eyes" the pack's eyes open along
## the rim; "close" Bram near, his coat in a gust and the snow on him.
## "demand" (the same evening): the child picked up, then the hunter's arm
## put out for it, the mark's light and him turning it away, and the lead-in
## to the duel: its cards, his, and the Circle drawn in the snow. Slow: the
## pick-up is played.)
##
## (15 November) "fight": the three flashes of the fight before "The end of
## the duel", two stills of each. "out": the walk out after the Last Page
## (first light, the small hand taking its card and his line over it, the
## hunter watching and gone, the mark's light, the mark held on black,
## Morrowen's line and the title). Both play the pick-up first and draw only
## the frames they keep; five to seven minutes each. "hand" (not one of
## "all"): "out" as far as the hand going back down with its card.
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
var _tt := 0.0   # the "out" view's clock (a lambda keeps a copy of a local, not the local)
const ALL := ["night", "open", "torn", "mid", "wide", "back", "rim", "bowl", "held", "flash", "eyes", "close", "demand", "out", "fight"]
const DrawHold = preload("res://tests/draw_hold.gd")


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
	var names: Array = Array(OS.get_cmdline_user_args()).slice(1).filter(func(a): return ALL.has(String(a)) or String(a) == "hand")
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
	if names.has("demand"):
		# the child picked up and tucked in his coat, as the memory does it
		var kd4 := m._kneel_dir(Vector3.FORWARD)
		var bottom4 := m._kneel_spot(kd4)
		m._ad = kd4
		m._bottom = bottom4
		m._bram.position = bottom4
		if m._bram is Figure3D:
			(m._bram as Figure3D).snap_face(kd4)
		m._shaft_k = 0.0
		m._child_beacon(false)
		m._crater_k = 0.32
		m._raining = false
		_peek = false
		var rt4 := kd4.cross(Vector3.UP)
		m._shot(bottom4 - kd4 * 1.9 + rt4 * 1.45 + Vector3(0, 1.15, 0), m._baby.position + Vector3(0, 0.2, 0), 40.0)
		await m._lift_child()
		m._tuck()
		for k in 14:
			await get_tree().process_frame
		# the hunter on the rim, looking down at him
		var rim4 := c + kd4 * WhiteSky.RIM_AT
		rim4.y = WhiteSky.height(rim4.x, rim4.z)
		m._hunter.position = rim4
		m._hunter.look_at_dir(m._bram.position - rim4)
		m._hunter.visible = true
		m._hunter._set_fade(1.0)
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(0.72, 0.8, 1.0)
		lamp.light_energy = WhiteSky.RIM_LIGHT
		lamp.omni_range = 4.5
		lamp.position = Vector3(0.0, 2.0, 1.6)
		m._hunter.add_child(lamp)
		if m._bram is Figure3D:
			(m._bram as Figure3D).eyes_on(rim4 + Vector3(0, 2.0, 0))
		m._shot(bottom4 - kd4 * 2.0 + rt4 * 0.45 + Vector3(0, 1.2, 0), rim4 + Vector3(0, 1.9, 0), WhiteSky.RIM_LENS)
		await _shot("demand_0_before", 8)
		m._the_demand(rim4, bottom4, rt4)
		await _shot("demand_1_arm_coming", 13)
		await _shot("demand_1_arm_out", 9)
		await _shot("demand_2_the_mark", 12)
		await _shot("demand_3_turned_away", 22)
		for k in 6:
			await get_tree().process_frame
		m._to_the_duel(rim4, bottom4, rt4)
		await _shot("lead_1_its_cards", 10)
		await _shot("lead_2_his_cards", 12)
		await _shot("lead_3_the_circle", 12)
		await _shot("lead_4_closed", 14)
	if names.has("out"):
		await _out_view(c)
	elif names.has("hand"):
		await _out_view(c, true)   # (the walk out as far as the small hand has taken its card)
	if names.has("fight"):
		await _fight_view()
	print("WHITE SKY LOOK: done in ", out)
	get_tree().quit()


## One frame drawn and kept (the rest of an "out" run isn't drawn: far quicker).
func _key(nm: String) -> void:
	DrawHold.hold()
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DrawHold.release()
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%02d_%s.png" % [_n, nm]))
	print("white_sky_look: ", nm)


## "fight" (15 November): the three flashes of the fight before "The end of
## the duel", played as the memory plays them (the pick-up first, so the
## child's in his coat; the duel's screen built and warmed, as it is by then):
## two stills of each.
func _fight_view() -> void:
	DrawHold.start_keys()
	var kd := m._kneel_dir(Vector3.FORWARD)
	var bottom := m._kneel_spot(kd)
	m._ad = kd
	m._bottom = bottom
	m._bram.position = bottom
	if m._bram is Figure3D:
		(m._bram as Figure3D).snap_face(kd)
	m._shaft_k = 0.0
	m._child_beacon(false)
	m._raining = false
	_peek = false
	var rt := kd.cross(Vector3.UP)
	m._shot(bottom - kd * 1.9 + rt * 1.45 + Vector3(0, 1.15, 0), m._baby.position + Vector3(0, 0.2, 0), 40.0)
	await m._lift_child()
	m._tuck()
	for k in 14:
		await get_tree().process_frame
	m._prepare_duel()
	var waited := 0
	while not m._prep_done and waited < 400:
		await get_tree().process_frame
		waited += 1
	m._white.modulate.a = 1.0
	var done := [false]
	var run := func() -> void:
		await m._flashes()
		done[0] = true
	run.call()
	var seen := 0
	while not done[0]:
		await get_tree().process_frame
		if m.flashes > seen and m._white.modulate.a < 0.2:
			seen = m.flashes
			await _key("fight_%d_a" % seen)
			await get_tree().process_frame
			await _key("fight_%d_b" % seen)
	print("white_sky_look: %d flashes of the fight" % m.flashes)


## "out" (15 November): the walk out after the Last Page, played as the
## memory plays it (the pick-up first, so the child's in his coat): first
## light in the bowl, the climb, the small hand and its light, over the lip,
## the hunter watching from its rim and gone, the mark's light round him,
## the mark held on black, Morrowen's line under it and the title.
func _out_view(c: Vector3, hand_only := false) -> void:
	DrawHold.start_keys()
	var kd := m._kneel_dir(Vector3.FORWARD)
	var bottom := m._kneel_spot(kd)
	m._ad = kd
	m._bottom = bottom
	m._bram.position = bottom
	if m._bram is Figure3D:
		(m._bram as Figure3D).snap_face(kd)
	m._shaft_k = 0.0
	m._child_beacon(false)
	m._crater_k = 0.32
	m._raining = false
	_peek = false
	var rt := kd.cross(Vector3.UP)
	m._shot(bottom - kd * 1.9 + rt * 1.45 + Vector3(0, 1.15, 0), m._baby.position + Vector3(0, 0.2, 0), 40.0)
	await m._lift_child()
	m._tuck()
	for k in 14:
		await get_tree().process_frame
	m._white.modulate.a = 1.0
	var done := [false]
	var run := func() -> void:
		await m._walk_out()
		done[0] = true
	run.call()
	Input.action_press("move_up")
	_tt = 0.0
	var got := {}
	var at := {}
	var want := func(nm: String, when: bool, after := 0.0) -> bool:
		if got.has(nm) or not when:
			return false
		if not at.has(nm):
			at[nm] = _tt
		if _tt - float(at[nm]) < after:
			return false
		got[nm] = true
		return true
	while not done[0] and _tt < 90.0:
		await get_tree().process_frame
		_tt += 0.1
		if want.call("out_1_first_light", _tt > 3.4):
			await _key("out_1_first_light")
		if want.call("out_2_climbing", _tt > 3.4 and m._crater_dist() > 3.2 and m._hand_k < 0.01):
			await _key("out_2_climbing")
		# (15 November, later: the card coming down, the open hand, the take,
		# his line over it held in the fist, and down into his coat)
		if want.call("hand_1_card_coming", m._hand_k > 0.6 and m._mote_k > 0.35 and m._tiny_curl < 0.1):
			await _key("hand_1_card_coming")
		if want.call("hand_1b_card_nearer", m._hand_k > 0.9 and m._mote_k > 0.7 and m._tiny_curl < 0.1):
			await _key("hand_1b_card_nearer")
		if want.call("hand_2_open", m._tiny_rise > 0.97 and m._tiny_curl < 0.1, 0.1):
			await _key("hand_2_open")
		if want.call("hand_3_taken", m._tiny_curl > 0.97, 0.3):
			await _key("hand_3_taken")
		if want.call("hand_4_come_on_then", m.out_line_said and m._ov.passing, 0.9):
			await _key("hand_4_come_on_then")
		if want.call("hand_5_going_down", m.hand_caught and m._tiny_curl > 0.97 and m._tiny_rise < 0.62):
			await _key("hand_5_going_down")
			if hand_only:
				break
		if want.call("out_3_over_the_lip", m.hand_caught and m._hand_k < 0.02 and m._crater_dist() > 8.6):
			await _key("out_3_over_the_lip")
		if want.call("far_1_watching", m.walked_out, 1.4):
			await _key("far_1_watching")
		if want.call("far_2_going", m.hunter_gone, 0.5):
			await _key("far_2_going")
		if want.call("far_3_gone", m.hunter_gone, 1.6):
			await _key("far_3_gone")
		var marking: bool = m.hunter_gone and m._cam != null and absf(m._cam.fov - WhiteSky.MARK_LENS) < 0.01
		if want.call("mark_1_behind_him", marking, 0.5):
			await _key("mark_1_behind_him")
		if want.call("mark_2_its_light", marking, WhiteSky.MARK_PUSH - 0.2):
			await _key("mark_2_its_light")
		if want.call("mark_3_closing", marking, WhiteSky.MARK_PUSH + WhiteSky.MARK_DARK * 0.55):
			await _key("mark_3_closing")
	Input.action_release("move_up")
	print("white_sky_look: walked out %s, the small hand %s, the hunter gone %s, the mark held %s, the tune %d, %.1f s" % [
		str(m.walked_out), str(m.hand_caught), str(m.hunter_gone), str(m.mark_held), m.tune_played, _tt])
	if hand_only:
		return
	await _key("mark_4_held")
	var closed := [false]
	var end := func() -> void:
		await m._close()
		closed[0] = true
	end.call()
	var line_t := 0.0
	var title_t := 0.0
	_tt = 0.0
	while not closed[0] and _tt < 40.0:
		await get_tree().process_frame
		_tt += 0.1
		if m._ov != null and m._ov._waiting:
			line_t += 0.1
			if want.call("end_1_line", line_t > 0.8):
				await _key("end_1_line")
			if line_t > 1.6:
				line_t = 0.0
				m._ov._next.emit()
		if m.title_shown:
			title_t += 0.1
			if want.call("end_2_title", title_t > 2.8):
				await _key("end_2_title")
	print("white_sky_look: the title shown %s, closed %s" % [str(m.title_shown), str(closed[0])])
