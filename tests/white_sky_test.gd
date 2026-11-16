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
##
## (15 November, evening) "knee_only" stops once his word to the child on
## his knee has been seen (with "page keys": a few minutes to look at it).
##
## (15 November: "i still feel something more is missing from the prologue")
## the three flashes of the fight before the caption; after the Last Page,
## the walk out (walked by the up key as the walk in is: out of the crater,
## the small hand closing on its light, the hunter watching from its rim and
## gone, the mark's light round him); the mark left up on black; the child's
## tune asked for (at the pick-up and at the small hand); and the title
## after Morrowen's last line. "duel" plays the duel, the walk out and the
## end. Skipped, the mark and the title still come.
## (The same day, later) the first move is a choice of two cards, both
## glowing: the first is taken by default; "serpent" taps the other. Either
## must be called and break the hound. And the Last Page as it was rebuilt:
## the calling before the Summon's video, the arrival after it, the pages
## flung out at the blow with Orlanthe still standing. "page" plays the duel
## to the Last Page's white and stops (the quick look at the summon).
##
## (And that evening's four) the hunter's arm put out for the child and Bram
## turning it away before "Not this one."; the lead-in (his cards up, the
## Circle drawn in the snow); the caption before the duel; and the Summon's
## video when the Last Page is played (asked for and begun: headless, a
## video is over in a frame).

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
var _reach_most := 0.0        # how far the hunter's arm came out (0..1)
var _turned_most := 0.0       # how far Bram turned the child away (degrees)
var _ring_drawn := 0.0        # how much of the Circle was drawn (0..1)
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
	_page_only = args.has("page")
	_duel_only = args.has("duel") or _page_only
	_serpent = args.has("serpent")
	_hurry = args.has("hurry")
	Haptics.count = 0
	for a in args:
		if String(a).begins_with("max="):
			_max = float(String(a).substr(4))
		if String(a).begins_with("skip_at="):
			_skip = true
			_skip_at = float(String(a).substr(8))
		# (15 November) "skip_out=<s>": Skip pressed that long into the walk out
		# (the Summon's video before it runs by the wall's clock, so its
		# place in the test's own time isn't known beforehand)
		if String(a).begins_with("skip_out="):
			_skip = true
			_skip_at = INF
			_skip_out = float(String(a).substr(9))
	DirAccess.make_dir_recursive_absolute(out_dir)
	get_window().size = Vector2i(1280, 720)
	get_tree().root.theme = UITheme.make()
	Game.settings["seen_white_sky"] = false
	# (the Summon's video as a new game has it: on, and not seen yet; this
	# machine's own Options may say otherwise)
	Game.settings[SummonVideo.SETTING] = "full"
	# ("novideo": Summon videos Off in Options. The calling and the arrival
	# are still played, one after the other.)
	if args.has("novideo"):
		Game.settings[SummonVideo.SETTING] = "off"
	Game.v2.erase("summon_seen")
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
		# (where he'd have knelt to the child, for the walk out to start from)
		m._ad = m._kneel_dir(Vector3.FORWARD)
		m._bottom = m._kneel_spot(m._ad)
		# (and the child in his coat, in his left arm, as the pick-up leaves it:
		# his word to it on his knee is filmed down at it)
		_carry(m)
		await m._duel()
		if _page_only:
			# ("page": the duel to the Last Page's white, for a look at the summon)
			await _still("page_end")
			print("white_sky_test: the Last Page: called %s, arrived %s, the pages flung out %s, Orlanthe standing at the blow %s (stopped at the white)" % [
				str(m.page_called), str(m.page_arrived), str(m.page_blown), str(m.page_stood)])
			get_tree().quit(0)
			return
		if not m._skipping:
			await m._walk_out()
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
		ok = _third_pass(false) and ok
		for want: String in wanted:
			if not names.has(want):
				print("white_sky_test: FAIL: the sound '%s' was never played" % want)
				ok = false
	if _skip:
		ok = _third_pass(true) and ok
		if not _duel_only:
			print("white_sky_test: (skipped) the duel built at %.1f s and warmed by %.1f s; the walk began at %.1f s" % [_built_t, _warm_t, _roam_t])
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
	_watch_third_pass()
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
			# ("serpent": the other of the first move's two cards, by a tap on it)
			var other: Control = null
			if ask == "call" and _serpent:
				for c in m._hand_lit:
					if is_instance_valid(c) and String(c.id) == String(WhiteSkyDuel.PLAY_CHOICE[1]):
						other = c
			if other != null:
				m._tap_at = other.get_global_rect().get_center()
				m._tapped = true
			else:
				m.play_move()
	elif not _asked.is_empty() and float(_asked[-1][2]) < 0.0:
		# (no longer asking, and the test didn't make the move: the stray tap did)
		_miss_failed.append(_asked[-1][0])
		_asked[-1][2] = _t
	if is_instance_valid(m._screen) and m._screen.game != null and not _filmed:
		_filmed = true
		m._screen.game.logged.connect(func(t: String, who: int) -> void:
			print("  [duel %5.1fs] %s%s" % [_t, "    " if who == 1 else "", t])
			if who == 0 and t.contains(" calls ") and not t.contains("calls down"):
				_first_call = t if _first_call == "" else _first_call
			if t.contains("Blazehound is knocked out"):
				_hound_broke = true
			if who == 0 and t.contains("calls down") and t.contains(WhiteSkyDuel.summon_name()):
				_called = true
				_still_later("summon", 1.5)
				_still_later("summon_b", 3.5))
		_still_later("duel_start", 2.0)
	if _skip and _t > _skip_at and not m._skipping:
		m.skip()
	if _skip_out >= 0.0 and m._out and not m._skipping:
		if _skip_out_from < 0.0:
			_skip_out_from = _t
		elif _t - _skip_out_from > _skip_out:
			m.skip()
	if _t >= _next_still:
		_next_still = _t + every
		_still("t%05.1f" % _t)


## The child put straight into his coat, held in his left arm as WhiteSky's
## pick-up and _tuck leave it (the duel played on its own has no pick-up).
func _carry(ws: WhiteSky) -> void:
	if not (ws._bram is Figure3D) or not is_instance_valid(ws._baby):
		return
	var fig := ws._bram as Figure3D
	ws._baby.reparent(fig._pivot, false)
	ws._baby.basis = Basis(Vector3.UP, -PI * 0.5)
	# (where the pick-up leaves it, and his arm under it: 16 November)
	ws._baby.position = ws._tuck_point(fig)
	ws.hold_tucked(fig, 0.01)
	var glow := ws._baby.get_node_or_null("MarkGlow") as OmniLight3D
	if glow != null:
		glow.light_energy = 0.15


## A still of one of the new moments, once.
func _once(label: String, secs: float) -> void:
	if not _stilled.has(label):
		_stilled[label] = true
		_still_later(label, secs)


## What 15 November added, watched as it plays (the flashes of the fight,
## the walk out, the mark, the title) ...
var _skip_out := -1.0
var _skip_out_from := -1.0
## (15 November) the first move's choice of two cards: "serpent" taps the
## other one; what was called, and that the hound broke to it
var _serpent := false
var _page_only := false
var _first_call := ""
var _hound_broke := false
## (15 November, evening) when the shot down at the child came, and whether
## the child was still crying then
var _child_cry_at := -1.0
var _child_crying := false
var _pack_checked := false
var _knee_done := false
var _pack_left: Array = []
var _flash_seen := 0
var _fan_most := 0
var _long_buzz := false
var _out_from := -1.0
var _out_walked := 0.0
var _out_stood := 0.0
var _hunter_near := INF
var _seal_at := Vector2.ZERO
## (15 November, later) "Come on then, Sprout." over the start of the walk
## out: when it came up and when it was last up, whether it ever waited for
## a tap or took one, the press on the screen put in under it, and whether
## it was left up over a skip
var _sprout_from := -1.0
var _sprout_to := -1.0
var _sprout_caught := false
var _sprout_pressed := false
var _sprout_stuck := false
var _sprout_after_hand := false   # (it came once the small hand had taken its card)
## (15 November, later still) Bram's lines at the duel's beats (BEAT_LINES):
## when each was seen on the screen, and whether a move's prompt was ever up
## under one
var _beat_seen := {}
var _beat_under_prompt := false

func _watch_third_pass() -> void:
	_fan_most = maxi(_fan_most, m._bram_fan.size())
	if int(Haptics.last[0]) == int(Haptics.LONG[0]):
		_long_buzz = true
	if m.flashes > _flash_seen:
		_flash_seen = m.flashes
		_still_later("flash_%d" % _flash_seen, 0.35)
	if m._out and is_instance_valid(m._bram):
		if _out_from < 0.0 and m._white.modulate.a < 0.5:
			_out_from = _t
			_still_later("out_first_light", 1.2)
		var ov: CineOverlay = m._ov
		if ov != null and ov.passing and ov._line.text.contains("Sprout"):
			if m._skipping:
				_sprout_stuck = true
			if _sprout_from < 0.0:
				_sprout_from = _t
				_sprout_after_hand = m.hand_caught
				_still_later("out_line", 0.6)
			_sprout_to = _t
			if ov._waiting or ov._catch.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				_sprout_caught = true
			# (a press on the screen under it, as a player setting off would
			# make: it's the walk's, and the line stays)
			if not _sprout_pressed and _t - _sprout_from > 0.7 and not m._skipping:
				_sprout_pressed = true
				for down: bool in [true, false]:
					var ev := InputEventMouseButton.new()
					ev.button_index = MOUSE_BUTTON_LEFT
					ev.pressed = down
					ev.position = get_viewport().get_visible_rect().size * Vector2(0.5, 0.2)
					get_viewport().push_input(ev)
		if m._roam:
			_out_walked = maxf(_out_walked, m._crater_dist())
			if is_instance_valid(m._hunter) and m._hunter.visible:
				_hunter_near = minf(_hunter_near, m._hunter.position.distance_to(m._bram.position))
		if m._hand_k > 0.9 and m._tiny_rise > 0.9 and m._tiny_curl < 0.2:
			_once("out_hand_open", 0.1)
		if m._tiny_curl > 0.9:
			_once("out_hand_closed", 0.5)
		if m.card_whitened:
			_once("out_card_white", 0.1)
		if m.walked_out:
			_once("out_hunter_watching", 1.5)
		if m.hunter_gone:
			_once("out_hunter_gone", 1.5)
			_once("out_mark_light", WhiteSky.OUT_GONE + WhiteSky.MARK_PUSH - 0.4)
	# (his lines at the duel's beats)
	var lov: CineOverlay = m._ov
	if lov != null and lov._line.modulate.a > 0.5:
		for key: String in WhiteSky.BEAT_LINES:
			if lov._line.text.contains(String(WhiteSky.BEAT_LINES[key].say)):
				if not _beat_seen.has(key):
					_beat_seen[key] = _t
					_still_later("line_" + key, 0.5)
				if key != "rise" and m._hint != null and m._hint.modulate.a > 0.5:
					_beat_under_prompt = true
	# (the Last Page: the calling, the arrival, the blow)
	if m.page_called:
		for pair in [["page_call_a", 0.5], ["page_call_b", 1.4], ["page_call_c", 2.2], ["page_call_d", 3.2]]:
			_once(String(pair[0]), float(pair[1]))
	if m.page_arrived:
		for pair in [["page_arrive_a", 0.4], ["page_arrive_b", 1.3], ["page_arrive_c", 2.2], ["page_arrive_d", 3.1]]:
			_once(String(pair[0]), float(pair[1]))
	if m.page_blown:
		_once("page_blow_a", 0.1)
		_once("page_blow_b", 0.4)
	# (15 November, evening) his word to the child, down into his coat; the
	# end of the duel: the pack wiped out, the hunter burned away, Orlanthe
	# back up its light
	# ("knee_only": stop once his word to the child has been seen, for a
	# quick look at it)
	if "knee_only" in OS.get_cmdline_user_args() and _stilled.has("knee_child_b") and not _knee_done:
		_knee_done = true
		get_tree().create_timer(2.0).timeout.connect(func() -> void: get_tree().quit(0))
	if m.to_child_shot:
		_once("knee_child_a", 0.4)
		_once("knee_child_b", 1.6)
		if _child_cry_at < 0.0 and m._cry != null:
			_child_cry_at = _t
			_child_crying = m._cry.playing
	if m.pack_wiped > 0:
		_once("fin_pack_a", 0.15)
		_once("fin_pack_b", 0.7)
		_once("fin_pack_c", 1.4)
	if m.cards_burned:
		_once("fin_hunter_a", 0.2)
		_once("fin_hunter_b", 0.9)
		_once("fin_hunter_c", 1.5)
		_once("fin_hunter_d", 2.1)
		_once("fin_hunter_e", 2.7)
	if m.page_departed:
		_once("fin_depart_a", 0.2)
		_once("fin_depart_b", 0.8)
		if not _pack_checked and is_instance_valid(m._screen) and m._screen.field != null:
			_pack_checked = true
			for i in m._screen.field.slots[1].size():
				var sl = m._screen.field.slots[1][i]
				if sl != null and String(sl.card_id) != "" and sl.model != null and is_instance_valid(sl.model) and sl.model.visible and not sl.dying:
					_pack_left.append(String(sl.card_id))
	if m.mark_held:
		_once("mark_held", 0.4)
	if m.title_shown:
		_once("title", 2.8)
	var held := SealMark.held(get_tree())
	if held != null:
		_seal_at = held.at


## ... and checked at the end (`skipped`: only what a skipped memory still shows).
func _third_pass(skipped: bool) -> bool:
	var fails: Array = []
	var held := SealMark.held(get_tree())
	print("white_sky_test: the end: the mark held on black %s (at %.2f, %.2f), the title shown %s" % [str(held != null), _seal_at.x, _seal_at.y, str(m.title_shown)])
	if not m.mark_held or held == null or held.k < 0.9:
		fails.append("the mark wasn't left up on the black")
	elif absf(_seal_at.x - 0.5) > 0.21 or _seal_at.y < 0.2 or _seal_at.y > 0.44:
		fails.append("the held mark is at (%.2f, %.2f), where the title or a caption goes" % [_seal_at.x, _seal_at.y])
	if not m.title_shown:
		fails.append("the title wasn't shown")
	elif TitleScreen.has_art() and not m.title_backdrop:
		fails.append("the title came up without the title screen's painting behind it")
	if not skipped:
		# (15 November, evening) his word to the child was filmed down at the
		# child, crying as he began it; and the end of the duel played out
		print("white_sky_test: \"%s\": the shot down at the child %s, the child crying as it began %s" % [
			String(WhiteSky.BEAT_LINES.knee.say), str(m.to_child_shot), str(_child_crying)])
		if not m.to_child_shot:
			fails.append("his word to the child wasn't filmed down at the child")
		elif m._cry != null and not _child_crying:
			fails.append("the child had stopped crying before he spoke to it")
		print("white_sky_test: the end of the duel: %d of the pack wiped out by the light, the hunter's cards burned %s, the hunter burned away %s, Orlanthe gone back up %s, done %s" % [
			m.pack_wiped, str(m.cards_burned), str(m.hunter_burned), str(m.page_departed), str(m.finale_done)])
		if m.pack_wiped < 1 or not m.cards_burned or not m.hunter_burned or not m.page_departed or not m.finale_done:
			fails.append("the end of the duel: %d wiped out, cards burned %s, hunter burned %s, Orlanthe up %s, done %s" % [
				m.pack_wiped, str(m.cards_burned), str(m.hunter_burned), str(m.page_departed), str(m.finale_done)])
		for id in _pack_left:
			fails.append("one of the pack (%s) still stood as Orlanthe went back up" % id)
		var want_id := String(WhiteSkyDuel.PLAY_CHOICE[1 if _serpent else 0])
		var want_name := String(DuelCards.CARDS[want_id].name)
		print("white_sky_test: the first move: %d cards offered, '%s' picked; the duel: \"%s\", the hound broken %s" % [m.call_offered, m.call_picked, _first_call, str(_hound_broke)])
		if m.call_offered != WhiteSkyDuel.PLAY_CHOICE.size() or m.call_picked != want_id or not _first_call.contains(want_name) or not _hound_broke:
			fails.append("the first move's choice: %d offered, '%s' picked (wanted '%s'), \"%s\", the hound broken %s" % [m.call_offered, m.call_picked, want_id, _first_call, str(_hound_broke)])
		print("white_sky_test: the Last Page: called %s, arrived %s, the pages flung out %s, Orlanthe standing at the blow %s" % [
			str(m.page_called), str(m.page_arrived), str(m.page_blown), str(m.page_stood)])
		if not (m.page_called and m.page_arrived and m.page_blown and m.page_stood):
			fails.append("the Last Page: called %s, arrived %s, the pages flung out %s, Orlanthe standing at the blow %s" % [
				str(m.page_called), str(m.page_arrived), str(m.page_blown), str(m.page_stood)])
		if not _duel_only:
			print("white_sky_test: %d flashes of the fight before the caption" % m.flashes)
			if m.flashes != 3:
				fails.append("the flashes of the fight: %d, not 3" % m.flashes)
		print("white_sky_test: the walk out: walked to %.1f m from the crater's middle (the walk ends at %.1f), never nearer the hunter than %.1f m; the small hand %s; the hunter gone %s; the child's tune asked for %d times" % [
			_out_walked, WhiteSky.OUT_AT, _hunter_near, str(m.hand_caught), str(m.hunter_gone), m.tune_played])
		if not m.walked_out or _out_walked < WhiteSky.OUT_AT - 0.3:
			fails.append("the walk out wasn't walked (%s, %.1f m)" % [str(m.walked_out), _out_walked])
		# ("Come on then, Sprout.": said, up for its reading time through a
		# press on the screen, holding nothing)
		var read := CineOverlay.READ_BASE + String(WhiteSky.COME_ON.say).length() * CineOverlay.READ_PER_CHAR
		print("white_sky_test: \"%s\": said %s, up for %.1f s (its reading time %.1f); a press under it %s; it waited for or took a tap %s" % [
			String(WhiteSky.COME_ON.say), str(m.out_line_said), _sprout_to - _sprout_from, read, str(_sprout_pressed), str(_sprout_caught)])
		if not m.out_line_said or _sprout_from < 0.0:
			fails.append("\"%s\" was never said on the walk out" % String(WhiteSky.COME_ON.say))
		elif not _sprout_pressed or _sprout_to - _sprout_from < read - 0.2:
			fails.append("\"%s\" was up for %.1f s of its %.1f (pressed under it: %s)" % [String(WhiteSky.COME_ON.say), _sprout_to - _sprout_from, read, str(_sprout_pressed)])
		if _sprout_caught:
			fails.append("\"%s\" waited for a tap, or took one from the walk" % String(WhiteSky.COME_ON.say))
		if _sprout_from >= 0.0 and not _sprout_after_hand:
			fails.append("\"%s\" came before the small hand had taken its card" % String(WhiteSky.COME_ON.say))
		# (his three lines at the duel's beats: each said, in its order, each
		# seen, and never with a move's prompt up under it)
		var seen: Array = []
		for key: String in WhiteSky.BEAT_LINES:
			seen.append("%s %s" % [key, ("at %.1f s" % float(_beat_seen[key])) if _beat_seen.has(key) else "never"])
		print("white_sky_test: his lines at the duel's beats: said %s; seen: %s; a prompt up under one %s" % [str(m.beat_lines_said), ", ".join(seen), str(_beat_under_prompt)])
		if m.beat_lines_said != WhiteSky.BEAT_LINES.keys() or _beat_seen.size() != WhiteSky.BEAT_LINES.size():
			fails.append("his lines at the duel's beats: said %s, seen %s" % [str(m.beat_lines_said), str(_beat_seen.keys())])
		if _beat_under_prompt:
			fails.append("a move was asked for while one of his lines at a beat was still up")
		if _hunter_near < WhiteSky.HUNTER_KEEP - 0.3:
			fails.append("he came within %.1f m of the hunter on the walk out" % _hunter_near)
		if not m.hand_caught:
			fails.append("the small hand never closed on its light")
		elif not m.card_whitened:
			fails.append("the card in the small hand never turned white")
		elif m._mote_white > 0.01 and is_instance_valid(m._mote):
			fails.append("the card in the small hand was still white as it went into his coat")
		if not m.hunter_gone or (is_instance_valid(m._hunter) and m._hunter.visible):
			fails.append("the hunter was still on its rim at the end")
		if m.tune_played < (1 if _duel_only else 2):
			fails.append("the child's tune was asked for %d times" % m.tune_played)
		if not Sfx.heard.any(func(h): return String(h[1]) == "child_tune"):
			fails.append("the sound 'child_tune' was never played")
	if _sprout_stuck or (m._ov != null and m._ov.passing):
		fails.append("\"%s\" was left up over a skip, or at the end" % String(WhiteSky.COME_ON.say))
	for f in fails:
		print("white_sky_test: FAIL: ", f)
	return fails.is_empty()


## What the second pass of 14 November added, watched as it plays ...
func _watch_second_pass() -> void:
	if not is_instance_valid(m._bram):
		return   # (the memory's over, or skipped: the duel's screen has gone, and him with it)
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
	if m.demanded and m._dir_f == null and is_instance_valid(m._hunter):
		_once("demand_arm", 1.5)
		_reach_most = maxf(_reach_most, m._hunter.reaching())
	if m.shielded and m._dir_f == null:
		_once("demand_mark", 0.0)
		_once("demand_turned", WhiteSky.DEMAND_TURN + 0.2)
		if m._bram is Figure3D and not m.led_in and m._bram_fan.is_empty():
			var f: Vector3 = (m._bram as Figure3D).facing()
			_turned_most = maxf(_turned_most, rad_to_deg(absf(Vector2(f.x, f.z).angle_to(Vector2(m._ad.x, m._ad.z)))))
	if not m._bram_fan.is_empty():
		_once("lead_cards", 0.9)
	if m.led_in and m._dir_f == null:
		_once("lead_circle", WhiteSky.LEAD_RING_SECS * 0.6)
		_once("lead_circle_b", WhiteSky.LEAD_RING_SECS + 0.6)
		if m._ground_mat != null:
			var sw = m._ground_mat.get_shader_parameter("ring_sweep")
			if sw != null:
				_ring_drawn = maxf(_ring_drawn, float(sw))
	if m.later_shown:
		_once("later", 1.6)
	if m._summon_clip:
		_once("summon_video", 0.6)
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
		# (that evening's: what comes before "Not this one.", the lead-in, the caption)
		print("white_sky_test: before his line: the hunter's arm out %.2f, Bram turned the child %.0f degrees away; the lead-in: %d of his cards up, the Circle drawn %.2f; the caption before the duel %s" % [
			_reach_most, _turned_most, _fan_most, _ring_drawn, str(m.later_shown)])
		if not m.demanded or _reach_most < 0.9:
			fails.append("the hunter's arm didn't come out for the child (%.2f)" % _reach_most)
		if not m.shielded or _turned_most < WhiteSky.SHIELD_TURN * 0.7:
			fails.append("Bram didn't turn the child away (%.0f degrees)" % _turned_most)
		if not m.led_in or _fan_most != WhiteSky.LEAD_CARDS or _ring_drawn < 0.95:
			fails.append("the lead-in: %d of his cards, the Circle drawn %.2f" % [_fan_most, _ring_drawn])
		if not m.later_shown:
			fails.append("no caption before the duel")
	print("white_sky_test: the Summon's video: wanted %s, begun %d" % [str(m._clip_wanted), m.summon_clips])
	if SummonVideo.has_clip(WhiteSkyDuel.SUMMON, "full") and SummonVideo.mode() != "off" and (not m._clip_wanted or m.summon_clips < 1):
		fails.append("the Summon's video didn't play at the Last Page (wanted %s, begun %d)" % [str(m._clip_wanted), m.summon_clips])
	print("white_sky_test: his knee: down %s, up %s; his head on it at %s from where he stands (the shots take it at %s); the child came down %.2f m" % [
		str(m.knelt), str(m.rose), str(_knee_head), str(WhiteSky.HEAD_KNELT), _knee_drop])
	if not m.knelt or not m.rose or m._kneeling:
		fails.append("Bram's knee: down %s, up %s, still down at the end %s" % [str(m.knelt), str(m.rose), str(m._kneeling)])
	if _knee_head != Vector3.INF and (_knee_head - WhiteSky.HEAD_KNELT).length() > 0.22:
		fails.append("his head on his knee is at %s, %.2f m from where the shots take it to be" % [str(_knee_head), (_knee_head - WhiteSky.HEAD_KNELT).length()])
	print("white_sky_test: %d shards of ice burst; %d buzzes of the phone asked for (the last %s)" % [m.shattered, Haptics.count, str(Haptics.last)])
	if m.shattered < 3:
		fails.append("the ice didn't break on the Last Page (%d)" % m.shattered)
	# (15 November: the last is the small hand's tap on the walk out now; the
	# Last Page's long one is watched for as it goes by)
	if Haptics.count < 5 or not _long_buzz or int(Haptics.last[0]) != int(Haptics.TAP[0]):
		fails.append("the phone's buzzes: %d asked for, the Last Page's long one %s, the last %s (wanted the small hand's, %s)" % [Haptics.count, str(_long_buzz), str(Haptics.last), str(Haptics.TAP)])
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
