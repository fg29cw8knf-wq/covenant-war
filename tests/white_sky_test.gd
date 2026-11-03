extends Node
## Plays the Night of the White Sky (WhiteSky) on its own, as a player would
## (holding to walk, tapping to pick up the child, tapping each line on after a
## moment) and takes a still every few seconds and at each beat, then checks
## it ran to the end: the duel was filmed, Grondmaw was called and the memory
## finished. Run (stills in <dir>):
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --rendering-method gl_compatibility --fixed-fps 10 res://tests/white_sky_test.tscn -- <dir> [every s] [skip]
##
## Forward+ (the Mac's look): --rendering-driver vulkan --rendering-method forward_plus,
## with VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json on a machine with no GPU.
## "skip" presses Skip a few seconds in, to check skipping; "duel" plays only
## the filmed duel and the end; "max=<s>" stops after that much game time (a
## look at the walk in Forward+, where a frame takes seconds).

var out_dir := "/tmp/white_sky"
var every := 4.0
var m: WhiteSky
var _shots := 0
var _t := 0.0
var _next_still := 0.5
var _phase := ""
var _line_t := 0.0
var _called := false
var _filmed := false
var _skip := false
var _hold_hint := 0.0
var _duel_only := false
var _max := 0.0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		every = float(args[1])
	_skip = args.has("skip")
	_duel_only = args.has("duel")
	for a in args:
		if String(a).begins_with("max="):
			_max = float(String(a).substr(4))
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size = Vector2i(1280, 720)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	m = WhiteSky.new()
	add_child(m)
	m.finished.connect(func() -> void: _phase = "done")
	_run()


func _run() -> void:
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	if _duel_only:
		m._ov = m._own_overlay()
		m._black.modulate.a = 0.0
		await m._duel()
		await m._close()
	else:
		await m.play()
	await _still("end")
	var ok := _phase == "done" and (_skip or (_filmed and _called))
	print("white_sky_test: %s (filmed %s, grondmaw called %s, %d stills, %.1f s of game time)" % [
		"PASS" if ok else "FAIL", str(_filmed), str(_called), _shots, _t])
	print("real time %.0f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	get_tree().quit(0 if ok else 1)


func _process(delta: float) -> void:
	_t += delta
	if m == null or m._done:
		return
	if _max > 0.0 and _t > _max:
		_max = 0.0
		await _still("max")
		print("white_sky_test: stopped at %.1f s (max)" % _t)
		get_tree().quit(0)
		return
	# walk while the walking hint is up, or any time he's on the way
	m._held = true
	# the lines: read for a moment, then tap
	var ov := m._ov
	if ov != null and ov._waiting:
		_line_t += delta
		if _line_t > 1.6:
			_line_t = 0.0
			ov._next.emit()
	else:
		_line_t = 0.0
	# the pick-up prompt: tap it after a beat
	if m._hint.modulate.a > 0.9 and m._hint.text.contains("pick up"):
		_hold_hint += delta
		if _hold_hint > 1.0:
			m._tapped = true
			_hold_hint = 0.0
	if is_instance_valid(m._screen) and m._screen.game != null and not _filmed:
		_filmed = true
		m._screen.game.logged.connect(func(t: String, who: int) -> void:
			print("  [duel %5.1fs] %s%s" % [_t, "    " if who == 1 else "", t])
			if who == 0 and t.contains("calls down") and t.contains("Grondmaw"):
				_called = true
				_still_later("grondmaw", 1.5)
				_still_later("grondmaw_b", 3.5))
		_still_later("duel_start", 2.0)
	if _skip and _t > 8.0 and not m._skipping:
		m.skip()
	if _t >= _next_still:
		_next_still = _t + every
		_still("t%05.1f" % _t)


func _still_later(label: String, secs: float) -> void:
	await get_tree().create_timer(secs, false).timeout
	_still(label)


func _still(label: String) -> void:
	await RenderingServer.frame_post_draw
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))
