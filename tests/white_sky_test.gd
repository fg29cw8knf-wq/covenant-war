extends Node
## Plays the Night of the White Sky (WhiteSky) on its own, as a player would
## (walking on with the up key, tapping to pick up the child, tapping each
## line on after a moment) and takes a still every few seconds and at each beat, then checks
## it ran to the end: the duel was played (12 November: the player's three
## moves each waited for, a tap off the glowing card or the ringed hound
## doing nothing, then made), Bram's Summon (WhiteSkyDuel.SUMMON, Orlanthe)
## was called and the memory finished; and when the first card was played.
## Run (stills in <dir>):
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 \
##       --rendering-method gl_compatibility --fixed-fps 10 res://tests/white_sky_test.tscn -- <dir> [every s] [skip]
##
## Forward+ (the Mac's look): --rendering-driver vulkan --rendering-method forward_plus,
## with VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json on a machine with no GPU.
## "keys" draws only the stills' frames (much faster); "body" runs the body
## check (tests/body_check.gd) over it, its stills in <dir>/body.
## "skip" presses Skip a few seconds in, to check skipping; "duel" plays only
## the filmed duel and the end; "skip_at=<s>" presses Skip then (32: in the
## crater, the duel built and waiting behind it); "max=<s>" stops after that much game time (a
## look at the walk in Forward+, where a frame takes seconds).
##
## (14 November, the second pass) it also checks: the opening's wide shot (the
## camera starts high over him and comes down behind him; "hurry" steers him
## from the first frame instead, and it must then come in quickly), a gust on
## the walk that slows him, the snow gathering on him, the lightning and the
## pack's eyes on the rim, Bram down on his knee when his second Totem falls
## (the child going down with him) and up as the Last Page is played, the ice
## breaking, the phone's buzzes asked for (Haptics.count) and the ice's
## sounds.

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
var _skip_at := 8.0
## (11 November) when the duel was built and warmed, against when the walk
## began and the pick-up prompt came up: it's built under the opening's black
## now ("late" builds it at the prompt, as it was until then).
var _late := false
var _built_t := -1.0
var _warm_t := -1.0
var _roam_t := -1.0
var _prompt_t := -1.0
var _stood_t := -1.0
## (12 November) the player's three moves: when each was asked for and made,
## and that a tap somewhere else didn't make it
var _asked: Array = []        # [move, asked at, made at]
var _move_lines := 0          # Bram's lines at the moves, seen (12 November)
var _line_was := false
var _ask_hold := 0.0
var _missed := false          # the tap off the mark has been tried for this move
var _miss_failed: Array = []
## (14 November, the second pass)
var _hurry := false
var _open_top := 0.0          # the highest the opening's camera stood over him (m)
var _open_from := -1.0        # when the wide shot began, and when it was down
var _open_down := -1.0
var _gust_slow := INF         # his slowest pace in a gust at its height (m/s)
var _snow_at_rim := -1.0
var _knee_head := Vector3.INF # his head from where he stands, down on his knee
var _knee_drop := 0.0         # how far the child came down with him (m)
var _baby_y := INF
var _stilled := {}            # the new moments a still has been asked for
const DrawHold = preload("res://tests/draw_hold.gd")
var _keys := false
var _body = null


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		every = float(args[1])
	_skip = args.has("skip")
	_duel_only = args.has("duel")
	_hurry = args.has("hurry")
	Haptics.count = 0
	for a in args:
		if String(a).begins_with("max="):
			_max = float(String(a).substr(4))
		if String(a).begins_with("skip_at="):
			_skip = true
			_skip_at = float(String(a).substr(8))
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size = Vector2i(1280, 720)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	Sfx.listen = true
	m = WhiteSky.new()
	_late = args.has("late")
	m.prep_early = not _late
	add_child(m)
	m.finished.connect(func() -> void: _phase = "done")
	# keys: draw only the stills' frames (much faster); body: the body check
	# (tests/body_check.gd), its stills in <dir>/body
	_keys = args.has("keys")
	if _keys:
		DrawHold.start_keys()
	if args.has("body"):
		_body = preload("res://tests/body_check.gd").watch(m, out_dir.path_join("body"))
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
	# (14 November: the duel's blows slow the clock; it must never be left slow)
	if Engine.time_scale < 0.99:
		print("white_sky_test: FAIL: the clock was left slow (%.2f)" % Engine.time_scale)
		ok = false
	if not _skip:
		var moves: Array = _asked.map(func(a): return a[0])
		print("white_sky_test: the player's moves: %s" % ", ".join(_asked.map(func(a): return "%s asked at %.1f s, made at %.1f s" % [a[0], a[1], a[2]])))
		if moves != WhiteSkyDuel.PLAY_GATES:
			print("white_sky_test: FAIL: the moves waited for were %s, not %s" % [moves, WhiteSkyDuel.PLAY_GATES])
			ok = false
		if not _miss_failed.is_empty():
			print("white_sky_test: FAIL: a tap away from it made the move: %s" % [_miss_failed])
			ok = false
		if not _duel_only and not _asked.is_empty():
			print("white_sky_test: the first card was played %.0f s in (%.1f min)" % [float(_asked[0][2]), float(_asked[0][2]) / 60.0])
		# (12 November) a sound at each of the three moves, and the Totems' voices
		var names: Array = Sfx.heard.map(func(h): return String(h[1]))
		var steps: Array = Sfx.heard.filter(func(h): return String(h[1]).begins_with("step_"))
		print("white_sky_test: heard: %s" % ", ".join(Sfx.heard.filter(func(h): return not String(h[1]).begins_with("step_")).map(func(h): return "%s@%d" % [h[1], h[0]])))
		print("white_sky_test: %d of Bram's breaths shown in the cold" % Breath.count)
		if not _duel_only and Breath.count < 3:
			print("white_sky_test: FAIL: Bram's breath didn't show on the walk (%d)" % Breath.count)
			ok = false
		print("white_sky_test: %d footsteps heard, the first at frame %s, the last at %s" % [steps.size(),
			str(steps[0][0]) if not steps.is_empty() else "-", str(steps[-1][0]) if not steps.is_empty() else "-"])
		var wanted := ["card_draw", "card_lift", "cry_astral", "ward_set", "cry_hound", "hound_whine", "page_turn", "cry_orlanthe"]
		if not _duel_only:
			wanted.append("step_snow")   # (his boots in the snow, on the walk)
		print("white_sky_test: %d of Bram's lines at the moves" % _move_lines)
		if _move_lines != WhiteSky.MOVE_LINES.size():
			print("white_sky_test: FAIL: Bram's lines at the moves: %d, not %d" % [_move_lines, WhiteSky.MOVE_LINES.size()])
			ok = false
		# (14 November, the second pass: the ice's sounds)
		wanted.append_array(["ice_ring", "ice_crack", "ice_shatter"])
		ok = _second_pass() and ok
		for want: String in wanted:
			if not names.has(want):
				print("white_sky_test: FAIL: the sound '%s' was never played" % want)
				ok = false
	if not _duel_only and not _skip:
		print("white_sky_test: the duel built at %.1f s and warmed by %.1f s; the walk began at %.1f s, the pick-up prompt at %.1f s, the child in his arms by %.1f s (%s)" % [
			_built_t, _warm_t, _roam_t, _prompt_t, _stood_t, "built at the prompt, the before" if _late else "built under the opening's black"])
		if not _late and (_built_t < 0.0 or _warm_t < 0.0 or _warm_t > _roam_t):
			print("white_sky_test: FAIL: the duel wasn't built and warmed before the walk began")
			ok = false
		if not _late and _stood_t - _prompt_t > 6.0:
			print("white_sky_test: FAIL: the pick-up took %.1f s from the prompt" % (_stood_t - _prompt_t))
			ok = false
	print("white_sky_test: %s (filmed %s, summon called %s, %d stills, %.1f s of game time)" % [
		"PASS" if ok else "FAIL", str(_filmed), str(_called), _shots, _t])
	if _body != null:
		print(_body.summary())
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
	if _built_t < 0.0 and is_instance_valid(m._prep):
		_built_t = _t
	if _warm_t < 0.0 and m._prep_done:
		_warm_t = _t
	if _roam_t < 0.0 and m._roam:
		_roam_t = _t
	if _prompt_t < 0.0 and m._hint != null and m._hint.modulate.a > 0.9 and m._hint.text.contains("pick up"):
		_prompt_t = _t
	# (in his arms: the bundle his, lifted off the snow to his chest)
	if _stood_t < 0.0 and _prompt_t >= 0.0 and m._baby != null and m._bram != null and m._baby.get_parent() != m._set and m._baby.global_position.y - m._bram.global_position.y > 0.9:
		_stood_t = _t
	_watch_second_pass()
	# walk on, the way the camera looks (the pad's up, as a key), whenever the
	# walk is his (4 November: he walks about freely, no longer held forward)
	# (14 November: left alone until the opening's wide shot has come down,
	# unless "hurry")
	if m._roam and (_hurry or m._open_k <= 0.0):
		Input.action_press("move_up")
	else:
		Input.action_release("move_up")
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
	if m._move_line_on and not _line_was:
		_move_lines += 1
	_line_was = m._move_line_on
	# the player's three moves: a tap off the mark first (nothing happens),
	# then the move, a second after it's asked for
	var ask := m.asking()
	if ask != "":
		if _asked.is_empty() or _asked[-1][0] != ask:
			_asked.append([ask, _t, -1.0])
			_ask_hold = 0.0
			_missed = false
			_still_later("ask_" + ask, 1.4)
		if m._hint.modulate.a > 0.9:
			_ask_hold += delta
		if _ask_hold > 0.6 and not _missed:
			_missed = true
			m._tap_at = Vector2(6, 6)
			m._tapped = true
		if _ask_hold > 2.0:
			_asked[-1][2] = _t
			_ask_hold = 0.0
			m.play_move()
	elif not _asked.is_empty() and float(_asked[-1][2]) < 0.0:
		# (no longer asking, and the test didn't make the move: the stray tap did)
		_miss_failed.append(_asked[-1][0])
		_asked[-1][2] = _t
	if is_instance_valid(m._screen) and m._screen.game != null and not _filmed:
		_filmed = true
		m._screen.game.logged.connect(func(t: String, who: int) -> void:
			print("  [duel %5.1fs] %s%s" % [_t, "    " if who == 1 else "", t])
			if who == 0 and t.contains("calls down") and t.contains(WhiteSkyDuel.summon_name()):
				_called = true
				_still_later("summon", 1.5)
				_still_later("summon_b", 3.5))
		_still_later("duel_start", 2.0)
	if _skip and _t > _skip_at and not m._skipping:
		m.skip()
	if _t >= _next_still:
		_next_still = _t + every
		_still("t%05.1f" % _t)


## A still of one of the new moments, once.
func _once(label: String, secs: float) -> void:
	if not _stilled.has(label):
		_stilled[label] = true
		_still_later(label, secs)


## What the second pass of 14 November added, watched as it plays ...
func _watch_second_pass() -> void:
	if m._roam and m._open_k > 0.0:
		_once("open_a", 1.2)
		_once("open_b", 3.6)
	if m._gust_k > 0.5:
		_once("gust", 0.9)
	if m.rim_flashed:
		_once("rim_flash", 0.0)
		_once("rim_flash_b", 0.15)
	if m.rim_eyes >= WhiteSky.RIM_EYES * 2:
		_once("rim_eyes", 0.5)
	if m.knelt:
		_once("knee", WhiteSky.KNEE_AFTER + 0.2)
		_once("knee_b", WhiteSky.KNEE_AFTER + WhiteSky.KNEE_DOWN + 0.5)
	if m.rose:
		_once("rise", 0.45)
	if m.shattered > 0:
		_once("shatter", 0.2)
		_once("shatter_b", 0.5)
	if not is_instance_valid(m._bram):
		return   # (skipped: the duel's screen has gone, and him with it)
	if m._roam and m._open_k > 0.0:
		if _open_from < 0.0:
			_open_from = _t
		_open_top = maxf(_open_top, m._cam_pos.y - m._bram.position.y)
	elif _open_from >= 0.0 and _open_down < 0.0:
		_open_down = _t
	if m._roam and m._gust_k > 0.97:
		_gust_slow = minf(_gust_slow, m._vel.length())
	if _snow_at_rim < 0.0 and _open_down >= 0.0 and not m._roam:
		_snow_at_rim = m._snow_on
	if m._dir_f != null and is_instance_valid(m._baby) and m._baby.is_inside_tree():
		if not m.knelt:
			_baby_y = m._baby.global_position.y
		elif _baby_y != INF:
			_knee_drop = maxf(_knee_drop, _baby_y - m._baby.global_position.y)
	if m._kneeling and m.knelt and not m.rose and is_instance_valid(m._bram) and m._bram is Figure3D and m._asking != "":
		# (settled on his knee: the Last Page is being waited for)
		_knee_head = (m._bram as Figure3D).bone_pos("Head") - m._bram.global_position


## ... and checked at the end.
func _second_pass() -> bool:
	var ok := true
	var fails: Array = []
	if not _duel_only:
		print("white_sky_test: the opening's camera stood %.1f m over him and was down behind him %.1f s after the walk was his%s" % [
			_open_top, _open_down - _open_from, " (steered from the first frame)" if _hurry else ""])
		if _open_top < 9.0:
			fails.append("the opening's wide shot didn't start high over him (%.1f m)" % _open_top)
		var limit := WhiteSky.OPEN_HURRY + 0.5 if _hurry else WhiteSky.OPEN_HANG + WhiteSky.OPEN_SECS + 0.5
		if _open_down < 0.0 or _open_down - _open_from > limit:
			fails.append("the opening's camera took %.1f s to come down (at most %.1f)" % [_open_down - _open_from, limit])
		print("white_sky_test: %d gusts on the walk, his pace down to %.2f m/s in one (%.2f without); the snow on him %.2f by the rim" % [
			m.gusts, _gust_slow, WhiteSky.WALK_SPEED, _snow_at_rim])
		if m.gusts < 1 or _gust_slow > WhiteSky.WALK_SPEED * 0.75:
			fails.append("no gust slowed him on the walk")
		if m._weather == null or _snow_at_rim < 0.15:
			fails.append("no snow gathered on him (weather %s, %.2f)" % [str(m._weather != null), _snow_at_rim])
		print("white_sky_test: the rim: lightning %s, %d pairs of eyes" % [str(m.rim_flashed), m.rim_eyes])
		if not m.rim_flashed or m.rim_eyes != WhiteSky.RIM_EYES * 2:
			fails.append("the hunter's arrival: lightning %s, %d pairs of eyes (wanted %d)" % [str(m.rim_flashed), m.rim_eyes, WhiteSky.RIM_EYES * 2])
		if _knee_drop < 0.25:
			fails.append("the child didn't go down on the knee with him (%.2f m)" % _knee_drop)
	print("white_sky_test: his knee: down %s, up %s; his head on it at %s from where he stands (the shots take it at %s); the child came down %.2f m" % [
		str(m.knelt), str(m.rose), str(_knee_head), str(WhiteSky.HEAD_KNELT), _knee_drop])
	if not m.knelt or not m.rose or m._kneeling:
		fails.append("Bram's knee: down %s, up %s, still down at the end %s" % [str(m.knelt), str(m.rose), str(m._kneeling)])
	if _knee_head != Vector3.INF and (_knee_head - WhiteSky.HEAD_KNELT).length() > 0.22:
		fails.append("his head on his knee is at %s, %.2f m from where the shots take it to be" % [str(_knee_head), (_knee_head - WhiteSky.HEAD_KNELT).length()])
	print("white_sky_test: %d shards of ice burst; %d buzzes of the phone asked for (the last %s)" % [m.shattered, Haptics.count, str(Haptics.last)])
	if m.shattered < 3:
		fails.append("the ice didn't break on the Last Page (%d)" % m.shattered)
	if Haptics.count < 4 or int(Haptics.last[0]) != int(Haptics.LONG[0]):
		fails.append("the phone's buzzes: %d asked for, the last %s (wanted the Last Page's, %s)" % [Haptics.count, str(Haptics.last), str(Haptics.LONG)])
	for f in fails:
		print("white_sky_test: FAIL: ", f)
		ok = false
	return ok


func _still_later(label: String, secs: float) -> void:
	await get_tree().create_timer(secs, false).timeout
	_still(label)


func _still(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return   # (nothing's drawn headless: frame_post_draw never comes, and the run would wait on it for ever)
	if _keys:
		DrawHold.hold()
		await get_tree().process_frame
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if _keys:
		DrawHold.release()
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))
