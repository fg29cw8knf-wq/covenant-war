extends Node
## The Night of the White Sky's 8 November changes, looked at (Gary: "Think
## there needs to be more of a pause or action before hooded figure shows
## up"; "Can we make the battle more movie like or give me images and prompt
## and I'll make it a movie"):
##   duel     the filmed duel as the director cuts it: a still a moment into
##            every shot, named for the beat that chose it; every frame Bram's
##            head is checked against the real camera (in the picture with the
##            camera in front of his shoulders: his face seen), and the cuts,
##            the beats and the times are printed (the reference stills for
##            Gary's film of it come from here)
##   rim      from the tuck to the white: the stillness, the sound, the
##            figure taking form on the rim and walking to the edge (a still
##            every `every` s)
##   glimpse  the walk past the glimpse: the hush, the eyes drawn, the figure
##            in the gust (a still every `every` s)
##   refs     reference pictures: Bram in his coat from behind, the hunter
##            full length, the bundle in the crater, the ice field under the
##            torn sky
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --resolution 1280x720 --fixed-fps 10 --path . res://tests/white_sky_film_peek.tscn -- <dir> <duel|rim|glimpse|refs> [every=s] [nostills]

var out := "/tmp/ws_film"
var what := "duel"
var every := 0.5
var stills := true
var m: WhiteSky
var _n := 0
var _peek := false
var _peek_pos := Vector3.ZERO
var _peek_look := Vector3.ZERO


func _ready() -> void:
	process_priority = 100   # (after WhiteSky's own camera)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	if a.size() > 1:
		what = a[1]
	for s in a:
		if String(s).begins_with("every="):
			every = float(String(s).substr(6))
	stills = not a.has("nostills") and DisplayServer.get_name() != "headless"
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1280, 720)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	m = WhiteSky.new()
	add_child(m)
	_run.call_deferred()


func _process(_d: float) -> void:
	if _peek and m != null and m._cam != null:
		m._cam_mode = "peek"
		m._cam.global_position = _peek_pos
		m._cam.look_at(_peek_look, Vector3.UP)
	# the lines: read for a moment, then on
	var ov := m._ov if m != null else null
	if ov != null and ov._waiting:
		_line_t += _d
		if _line_t > 1.4:
			_line_t = 0.0
			ov._next.emit()
	else:
		_line_t = 0.0


var _line_t := 0.0


func _shot(nm: String) -> void:
	if not stills:
		return
	await RenderingServer.frame_post_draw
	_n += 1
	get_viewport().get_texture().get_image().save_png(out.path_join("%03d_%s.png" % [_n, nm]))


func _run() -> void:
	await get_tree().process_frame
	m._ov = m._own_overlay()
	m._black.modulate.a = 0.0
	for k in 4:
		await get_tree().process_frame
	match what:
		"duel":
			await _duel()
		"rim":
			await _rim()
		"glimpse":
			await _glimpse()
		"refs":
			await _refs()
	print("WHITE SKY FILM PEEK: done ", what, " in ", out)
	get_tree().quit()


# --- the duel --------------------------------------------------------------------
var _beats: Array = []

func _duel() -> void:
	var t0 := m._t
	var face_frames := [0]
	var frames := [0]
	var cuts: Array = []
	var last_cut := -1.0
	var done := [false]
	var beat_names := {}
	m._white.modulate.a = 1.0
	var run := func() -> void:
		await m._duel()
		done[0] = true
	run.call()
	while m._screen == null or m._screen.game == null:
		await get_tree().process_frame
	m._screen.game.beat.connect(func(meth: String, args: Array) -> void:
		var who := ""
		if not args.is_empty() and args[0] is DuelTotem:
			who = "%s(%d)" % [(args[0] as DuelTotem).id(), (args[0] as DuelTotem).owner]
		elif not args.is_empty() and (args[0] is int):
			who = str(args[0])
		if meth != "fx_draw" and meth != "fx_phase" and meth != "fx_roll" and meth != "fx_rule":
			print("  [beat %5.1fs] %s %s" % [m._t - t0, meth, who])
		_last_beat = "%s_%s" % [meth.trim_prefix("fx_"), who.replace("(", "").replace(")", "")])
	m._screen.game.logged.connect(func(tx: String, w: int) -> void:
		print("  [log  %5.1fs] %s%s" % [m._t - t0, "    " if w == 1 else "", tx]))
	var next_timed := m._t + 1.0
	while not done[0]:
		await get_tree().process_frame
		frames[0] += 1
		if every >= 1.0 and m._t >= next_timed:
			# (every half second once the Last Page is called)
			next_timed = m._t + (0.5 if m._climax else every)
			_later_still("%05.1f_%s" % [m._t - t0, "climax" if m._climax else "t"], 0.0)
		var f := m._dir_f
		if f != null and is_instance_valid(f) and f.cam != null:
			if _face_in(f):
				face_frames[0] += 1
				if face_frames[0] <= 5:
					print("  FACE SEEN at %.1f s (cam %s)" % [m._t - t0, str(f.cam.global_position)])
			if m._cut_at != last_cut:
				last_cut = m._cut_at
				cuts.append(m._t - t0)
				var label := "%05.1f_%s" % [m._t - t0, _last_beat]
				_later_still(label, 0.55)
	print("DUEL FILM: %.1f s, %d frames, %d cuts (every %.1f s on average), Bram's face in the picture %d frames" % [
		m._t - t0, frames[0], cuts.size(), (m._t - t0) / maxf(1.0, float(cuts.size())), face_frames[0]])
	await m._close()


var _last_beat := "start"


func _later_still(label: String, secs: float) -> void:
	await get_tree().create_timer(secs, false).timeout
	await _shot(label)


## Bram's head in the field camera's picture with the camera anywhere but
## behind his shoulders (the real camera, its real lens, this frame).
func _face_in(f: DuelField3D) -> bool:
	var b := m._bram
	if b == null or not is_instance_valid(b) or b.get_parent() != f.world:
		return false
	var head := b.global_position + Vector3(0, 1.68, 0)
	if b is Figure3D:
		head = (b as Figure3D).bone_pos("Head")
	var fwd := Vector3.FORWARD
	if b is PaperDoll:
		fwd = (b as PaperDoll).facing()
		fwd.y = 0.0
		fwd = fwd.normalized()
	var cam := f.cam
	var to_cam := cam.global_position - head
	if to_cam.normalized().dot(fwd) < -0.3:
		return false
	if cam.is_position_behind(head):
		return false
	var p := cam.unproject_position(head)
	var vs := f.vp.size if f.vp != null else Vector2i(1280, 720)
	return p.x > -20 and p.y > -20 and p.x < vs.x + 20 and p.y < vs.y + 20


# --- the rim --------------------------------------------------------------------
func _rim() -> void:
	# straight to the crater's lip, as the walk ends
	var near := WhiteSky.CRATER + Vector3(0, 0, WhiteSky.RIM_AT - 0.2)
	m._flat = Vector3(near.x, 0, near.z)
	m._bram.position = Vector3(near.x, WhiteSky.height(near.x, near.z), near.z)
	m._sky.set_shader_parameter("tear_open", 1.25)
	m._tear_light.light_energy = 0.55
	m._rain_cards(true)
	if m._wind != null:
		m._wind.play()
	var go := [false]
	var tap := func() -> void:
		while not go[0]:
			await get_tree().process_frame
			if m._hint.modulate.a > 0.9:
				await get_tree().create_timer(0.5, false).timeout
				m._tapped = true
				return
	tap.call()
	await m._crater()
	go[0] = true
	var done := [false]
	var run := func() -> void:
		await m._the_hunter()
		done[0] = true
	run.call()
	var t := 0.0
	while not done[0]:
		await _shot("rim_%04.1f" % t)
		await get_tree().create_timer(every, false).timeout
		t += every
	print("RIM: %.1f s from the tuck to the white" % t)


# --- the glimpse ------------------------------------------------------------------
func _glimpse() -> void:
	var at := WhiteSky.CRATER + Vector3(0, 0, WhiteSky.GLIMPSE_AT + 2.0)
	m._flat = Vector3(at.x, 0, at.z)
	m._bram.position = Vector3(at.x, WhiteSky.height(at.x, at.z), at.z)
	m._sky.set_shader_parameter("tear_open", 1.25)
	m._tear_light.light_energy = 0.55
	m._rain_cards(true)
	if m._wind != null:
		m._wind.play()
	m._cam_mode = "roam"
	m._cam_pos = Vector3.ZERO
	m._roam = true
	Input.action_press("move_up")
	var walk := func() -> void:
		await m._walk()
	walk.call()
	var t := 0.0
	while t < 11.0 and m._roam:
		await _shot("glimpse_%04.1f" % t)
		await get_tree().create_timer(every, false).timeout
		t += every
	Input.action_release("move_up")


# --- references ---------------------------------------------------------------
func _refs() -> void:
	m._sky.set_shader_parameter("tear_open", 1.25)
	m._tear_light.light_energy = 0.55
	m._env.fog_light_color = Color(0.22, 0.2, 0.34)
	var b := Vector3(0, 0, -6)
	m._flat = b
	m._bram.position = Vector3(b.x, WhiteSky.height(b.x, b.z), b.z)
	m._bram.visible = true
	for k in 6:
		await get_tree().process_frame
	var bp := m._bram.global_position
	_peek_at(bp + Vector3(0.9, 1.6, 3.4), bp + Vector3(0, 1.1, 0))
	await _settle()
	await _shot("ref_bram_back")
	_peek_at(bp + Vector3(-1.0, 1.1, 4.6), bp + Vector3(0, 1.0, 0))
	await _settle()
	await _shot("ref_bram_back_full")
	m._bram.visible = false
	# the hunter, full length, seen from the front (it has no face)
	var hp := Vector3(3.0, 0, -10.0)
	hp.y = WhiteSky.height(hp.x, hp.z)
	m._hunter.position = hp
	m._hunter.look_at_dir(Vector3.BACK)
	m._hunter.visible = true
	m._hunter._set_fade(1.0)
	_peek_at(hp + Vector3(0.0, 1.3, 6.2), hp + Vector3(0, 1.2, 0))
	await _settle()
	await _shot("ref_hunter_front")
	_peek_at(hp + Vector3(4.2, 1.0, 3.6), hp + Vector3(0, 1.25, 0))
	await _settle()
	await _shot("ref_hunter_side")
	m._hunter.raise_cards()
	await get_tree().create_timer(1.4, false).timeout
	_peek_at(hp + Vector3(0.8, 1.8, 5.4), hp + Vector3(0, 1.7, 0))
	await _settle()
	await _shot("ref_hunter_cards")
	m._hunter.visible = false
	# the bundle in the crater (close, without the beacon's glare), then the
	# crater from its rim with the beacon over it
	var bb := m._baby.global_position
	_peek_at(bb + Vector3(0.9, 0.8, 1.0), bb + Vector3(0, 0.05, 0), 30.0)
	await _settle()
	await _shot("ref_bundle")
	m._child_beacon(true)
	_peek_at(bb + Vector3(0.0, 4.0, 8.6), bb + Vector3(0, 0.0, 0), 40.0)
	await _settle()
	await _shot("ref_crater")
	# the ice field under the torn sky
	_peek_at(Vector3(4.0, 3.0, 2.0), Vector3(-2.0, 3.5, -30.0), 50.0)
	await _settle()
	await _shot("ref_ice_field")
	_peek_at(Vector3(-6.0, 1.4, -12.0), Vector3(4.0, 4.0, -40.0), 50.0)
	await _settle()
	await _shot("ref_ice_field_low")


func _peek_at(pos: Vector3, look: Vector3, fov := 34.0) -> void:
	_peek = true
	_peek_pos = pos
	_peek_look = look
	if m != null and m._cam != null:
		m._cam.fov = fov   # (the memory's camera keeps the 75 degrees it's made with until the walk sets its own)


func _settle() -> void:
	for k in 4:
		await get_tree().process_frame
