extends Node
## Midnight in parts (5 November), the Theora way: part 1 to Bram's
## question, its last frame held under the game's buttons with the menu
## music, the pick, Bram's answer for it (2A or 2B), then the hand-off to the
## 3D at the sky lanterns going up. Waits at the choice as a player would
## (`wait` seconds), saves a still every `every` frames, and measures every
## frame's brightness, to find any black frame at the three joins (part 1 to
## the held frame, the held frame to the answer, the answer to the 3D). Ends
## a few seconds into the 3D.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 640x360 \
##       --fixed-fps 4 --path . res://tests/midnight_parts_test.tscn -- <out_dir> <pick 0|1> [every=4] [wait=3] [after=6]
## Ends with "MIDNIGHT PARTS TEST: PASS" or the problems.

var out_dir := "user://"
var pick := 0
var every := 8
var wait := 3.0
var after := 6.0
var world: World
var _frame := 0
var _time := 0.0
var _shots := 0
var _problems := 0
var _film_seen := false
var _film_gone_at := -1.0
var _choice_at := -1.0
var _picked_at := -1.0
var _line_secs := 0.0
var _lum: Array = []     # [time, brightness, what's up] each frame
var _music_at_pick := ""
var _music_in_3d := ""
var _held_ok := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	out_dir = args[0] if args.size() > 0 else "user://"
	pick = int(args[1]) if args.size() > 1 else 0
	for a in args:
		var s := String(a)
		if s.begins_with("every="):
			every = int(s.substr(6))
		elif s.begins_with("wait="):
			wait = float(s.substr(5))
		elif s.begins_with("after="):
			after = float(s.substr(6))
	DirAccess.make_dir_recursive_absolute(out_dir)
	# the evening done, as tests/film_test.gd's "midnight" has it: the world
	# starts midnight by itself on arrival
	Game.new_game("Sprout", "")
	for f in ["arrived_ashford", "ash_started", "ash_tam", "ash_tilly", "ash_nell", "ash_ready",
			"first_deck", "ash_lantern_duel", "ash_won_lantern", "has_lantern_moth", "moth_given", "ash_evening"]:
		Game.set_flag(f)
	Game.player_name = "Rowan"
	world = World.new().setup("ashford", "green")
	add_child(world)
	print("MIDNIGHT PARTS: pick %d, wait %.1f s at the choice" % [pick, wait])


func _film() -> StoryFilm:
	if world == null:
		return null
	for c in world.get_children():
		if c is StoryFilm and not (c as StoryFilm).is_queued_for_deletion():
			return c
	return null


func _process(d: float) -> void:
	_frame += 1
	_time += d
	if world == null or not world.has_meta("cine_overlay"):
		return
	var ov: CineOverlay = world.get_meta("cine_overlay")
	var f := _film()
	if f != null and not _film_seen:
		_film_seen = true
		print("MIDNIGHT PARTS: the film starts at %.2f s" % _time)
	if f == null and _film_seen and _film_gone_at < 0.0:
		_film_gone_at = _time
		_music_in_3d = Music.current
		print("MIDNIGHT PARTS: the film is gone at %.2f s (music: %s)" % [_time, Music.current])
	# the choice: wait as a player would, then pick
	if ov._choices.visible and ov._choices.get_child_count() > 0:
		if _choice_at < 0.0:
			_choice_at = _time
			_held_ok = f != null and f._hold.visible and f._hold.texture != null
			print("MIDNIGHT PARTS: the choice at %.2f s (held frame %s, music %s)" % [_time, _held_ok, Music.current])
			_shot("choice")
		elif _time - _choice_at >= wait:
			_music_at_pick = Music.current
			_picked_at = _time
			print("MIDNIGHT PARTS: picked %d at %.2f s" % [pick, _time])
			ov._chosen.emit(pick)
	# lines that wait for a tap (the 3D's) go on after their reading time;
	# the film's own are timed and go by themselves
	if ov._waiting:
		_line_secs += d
		var plain := ov._line.get_parsed_text()
		if f == null and _line_secs > CineOverlay.READ_BASE + plain.length() * CineOverlay.READ_PER_CHAR:
			_line_secs = 0.0
			ov._next.emit()
	else:
		_line_secs = 0.0
	if "trace" in OS.get_cmdline_user_args() and f != null and _frame % 4 == 0 and (_picked_at > 0.0 or f._video.stream_position > 33.0):
		print("  trace %.2f s: %s at %.3f of %.3f, playing %s, paused %s, held %s, stopped_at '%s'" % [_time,
			f._video.stream.resource_path.get_file() if f._video.stream != null else "-", f._video.stream_position,
			f._video.get_stream_length(), f._video.is_playing(), f._video.paused, f._hold.visible, f.stopped_at])
	# (most of part 1 is drawn only for its stills, for speed: every frame
	# is drawn and measured from its last two seconds on)
	var early := f != null and _picked_at < 0.0 and not f._hold.visible and f._video.visible \
		and f._video.stream_position < 32.0
	var still := every > 0 and _frame % every == 0 and _film_seen
	RenderingServer.render_loop_enabled = still or not early
	if _film_seen and not early:
		_measure(f)
	if still:
		_shot("t%06.2f" % _time)
	if _film_gone_at >= 0.0 and _time - _film_gone_at > after:
		_finish()


## The picture's brightness this frame (the 3D, the film or the held frame
## under the bars), and what was up.
func _measure(f: StoryFilm) -> void:
	var what := "3d"
	if f != null:
		what = "hold" if f._hold.visible else ("cut" if f._video.visible else "film")
		if f._letting_go:
			what = "dissolve"
	var t := _time
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	# the middle of the picture, between the bars
	var w := img.get_width()
	var h := img.get_height()
	var sum := 0.0
	var n := 0
	for y in range(int(h * 0.2), int(h * 0.8), 6):
		for x in range(0, w, 6):
			sum += img.get_pixel(x, y).get_luminance()
			n += 1
	_lum.append([t, sum / maxf(1.0, n), what])


func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	_shots += 1
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%03d_%s.png" % [_shots, label]))


func _check(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  PROBLEM: ", what)
	else:
		print("  ok: ", what)


var _finished := false


func _finish() -> void:
	if _finished:
		return
	_finished = true
	await _shot("end")
	# the brightness through each join: the darkest frame in the second
	# either side, against the picture's own
	var f := FileAccess.open(out_dir.path_join("brightness.csv"), FileAccess.WRITE)
	for e in _lum:
		f.store_line("%.3f,%.4f,%s" % [e[0], e[1], e[2]])
	f.close()
	var joins := {"part 1 to the held frame": _choice_at, "the held frame to the answer": _picked_at, "the answer to the 3D": _film_gone_at - 0.4}
	for j in joins:
		var t0: float = joins[j]
		var lo := 9.0
		var lo_t := 0.0
		var around: Array = []
		for e in _lum:
			if absf(float(e[0]) - t0) <= 1.0:
				around.append(float(e[1]))
				if float(e[1]) < lo:
					lo = float(e[1])
					lo_t = float(e[0])
		var med := 0.0
		if not around.is_empty():
			around.sort()
			med = around[around.size() / 2]
		_check(t0 > 0.0 and lo > maxf(0.015, med * 0.35), "%s at %.2f s: darkest frame %.3f at %.2f s, the picture round it %.3f (no black frame)" % [j, t0, lo, lo_t, med])
	_check(_held_ok, "the held frame is up under the buttons")
	_check(_music_at_pick == "midnight_choice", "the menu music plays at the choice (%s)" % _music_at_pick)
	_check(_music_in_3d == "midnight_choice", "and plays on into the 3D, not restarted (%s)" % _music_in_3d)
	_check(int(Game.flag("mid_choice", -1)) == pick, "the pick is kept (%s)" % Game.flag("mid_choice", -1))
	_check((world.get_meta("village") as AshfordVillage).lantern_t >= 0.0, "the 3D took over at the sky lanterns (they're released)")
	print("MIDNIGHT PARTS TEST: %s (%d problems)" % ["PASS" if _problems == 0 else "FAIL", _problems])
	get_tree().quit(1 if _problems > 0 else 0)
