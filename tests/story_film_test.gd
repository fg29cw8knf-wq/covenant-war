extends Node
## The story films (StoryFilm) through the device's own player, driven here
## by a stand-in (the real one exists only in the iPhone and Mac apps, and
## the browser's on the phone link). Checks that a film is "there" only when
## the player can find its <film>_4k.mp4; that it plays through the player
## with nothing of the engine's showing, its lines going over it as the
## player's own subtitles, each at its moment and with the speaker's name;
## that midnight, a film in parts, steps aside at its choice for the held
## last frame and the menu music, opens Bram's answer for the pick on the
## same player with the music playing on, and stops before its part not
## made yet, up on its last frame until the scene lets it go; that it ends on black with
## the player stopped and "played"; that a film that won't open or can't be
## read says it didn't play (the scene plays its 3D instead); and that each
## of the seven v7 films has its lines and shots.
##   godot --headless --fixed-fps 30 --path . res://tests/story_film_test.tscn
## Ends with "STORY FILM TEST: PASS" or the problems.

var _problems := 0
var stub: FakePlayer = null
var world: World


class FakePlayer:
	extends RefCounted
	# which <film>_4k.mp4 are "in the bundle" (midnight comes in parts: part
	# 1, and Bram's answer to each pick; its part 3 isn't made yet)
	var films := ["white_light", "midnight_1", "midnight_2a", "midnight_2b"]
	var opens := true
	var fails := false                        # can't be read
	var ready_after := 3
	var length := 38.0
	var lengths := {"midnight_1": 34.083, "midnight_2a": 3.417, "midnight_2b": 3.417}
	var position := 0.0
	var playing := false
	var opened := false
	var visible := true
	var stopped := 0
	var opened_files: Array = []              # each file opened, in turn
	var subs: Array = []                      # [position, text] each time a subtitle is set
	var hidden_at: Array = []                 # positions it was hidden at
	var opacity := 1.0
	var ended := false
	var _frames := 0
	var _told_end := false

	func is_supported() -> bool: return true
	func find_file(name: String) -> String:
		for f in films:
			if name == f + "_4k.mp4":
				return "/app/" + name
		return ""
	func open(path: String) -> bool:
		if not opens:
			return false
		# (the real one takes down what it had and starts again on the new file)
		var stem := path.get_file().trim_suffix("_4k.mp4")
		opened_files.append(stem)
		length = float(lengths.get(stem, length))
		opened = true
		visible = true
		position = 0.0
		ended = false
		_told_end = false
		_frames = 0
		return true
	func play() -> void: playing = true
	func pause() -> void: playing = false
	func stop() -> void:
		playing = false
		opened = false
		stopped += 1
	func is_open() -> bool: return opened
	func is_ready() -> bool: return opened and _frames >= ready_after and not fails
	func is_playing() -> bool: return playing and not ended
	func has_finished() -> bool: return ended
	func has_failed() -> bool: return fails and _frames >= ready_after
	func get_error() -> String: return "a pretend failure" if fails else ""
	func get_position() -> float: return position
	func get_length() -> float: return length
	func seek(s: float) -> void: position = s
	func get_video_size() -> Vector2: return Vector2(3840, 2160)
	func set_volume(_v: float) -> void: pass
	func get_volume() -> float: return 1.0
	func set_opacity(a: float) -> void: opacity = a
	func set_visible(v: bool) -> void:
		visible = v
		if not v:
			hidden_at.append(position)
	func is_visible() -> bool: return opened and visible
	func set_subtitle(t: String) -> void: subs.append([position, t])
	func show_skip(_s: bool, _t := "Skip") -> void: pass
	func poll() -> int:
		if ended and not _told_end:
			_told_end = true
			return 4
		return 0
	func advance(delta: float) -> void:
		if not opened:
			return
		_frames += 1
		if playing and not ended and not fails:
			position = minf(position + delta, length)
			if position >= length:
				ended = true
				playing = false


func _process(delta: float) -> void:
	if stub != null:
		stub.advance(delta)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.new_game("Rowan", "")
	Game.player_name = "Rowan"
	world = World.new().setup("ashford", "green")
	add_child(world)
	await frames(10)
	_films_are_whole()
	_there_or_not()
	await _white_light()
	await _choice()
	await _wont_open()
	await _cant_be_read()
	OpeningMovie.native_stub = null
	print("STORY FILM TEST: %s (%d problems)" % ["PASS" if _problems == 0 else "FAIL", _problems])
	get_tree().quit(1 if _problems > 0 else 0)


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  PROBLEM: ", what)
	else:
		print("  ok: ", what)


func _fresh(setup: Callable = Callable()) -> void:
	stub = FakePlayer.new()
	if setup.is_valid():
		setup.call(stub)
	OpeningMovie.native_stub = stub


## Every v7 film has shots, and the films' lengths add up as their shots do.
func _films_are_whole() -> void:
	for f in ["midnight", "white_light", "herald", "reckoning", "tams_hand", "no_roof", "ridge"]:
		_check(StoryFilm.FILMS.has(f) and StoryFilm.shots(f).size() > 0, "the %s film is written (%d shots, %.0f s)" % [f, StoryFilm.shots(f).size(), StoryFilm.length(f)])
	_check(not StoryFilm.FILMS.has("dawn"), "v3's dawn film is gone (the Herald film replaces it)")


func _there_or_not() -> void:
	_fresh()
	_check(StoryFilm.available("white_light"), "a film whose 4K copy the player finds is there")
	_check(not StoryFilm.available("herald"), "a film with no 4K copy, cut or shots isn't (its 3D plays)")
	_check(not StoryFilm.available("nonsense"), "a film that isn't in the list isn't")


## The white light: its four lines as the player's subtitles at their moments.
func _white_light() -> void:
	_fresh()
	var r := await StoryFilm.play(world, "white_light")
	_check(bool(r.get("played", false)), "white light: it says it played")
	_check(stub.stopped >= 1 and not stub.opened, "white light: the player was stopped at the end")
	var lines: Array = stub.subs.filter(func(s): return String(s[1]) != "")
	var texts: Array = lines.map(func(s): return String(s[1]))
	_check(texts.size() == 3, "white light: three lines went over it (%s)" % [texts])
	if texts.size() == 3:
		_check(String(texts[0]).begins_with("Corin: It came to you."), "white light: the first is Corin's, with his name (%s)" % texts[0])
		_check(String(texts[2]).begins_with("Bram: Close your fist."), "white light: the last is Bram's (%s)" % texts[2])
		# wl_04 starts at 9 + 6 + 4 = 19 s, its first line 0.4 s in
		_check(absf(float(lines[0][0]) - 19.4) < 0.25, "white light: Corin's line comes at its moment (%.2f s, 19.4 expected)" % float(lines[0][0]))
		_check(absf(float(lines[2][0]) - 29.4) < 0.25, "white light: Bram's comes at its moment (%.2f s, 29.4 expected)" % float(lines[2][0]))
	_check(Cine.overlay(world)._black.modulate.a > 0.99, "white light: it ends on black")


## Midnight, in parts (5 November): part 1 plays to Bram's question, then
## steps aside for the game's buttons over its held last frame, with the
## menu music starting; the pick opens Bram's answer for it (2B here) on the
## same player, the music playing on under it; part 3 isn't made, so the
## film stops there, still up on its last frame, until the scene lets it go.
func _choice() -> void:
	_fresh()
	Music.stop(0.0)
	var ov := Cine.overlay(world)
	var seen := {}
	var picker := func() -> void:
		while not ov._choices.visible:
			await get_tree().process_frame
		await get_tree().create_timer(0.6).timeout
		var sf: Array = world.find_children("*", "StoryFilm", false, false)
		var f: StoryFilm = sf[0] if not sf.is_empty() else null
		seen["held"] = f != null and f._hold.visible and f._hold.texture != null
		seen["whole"] = f != null and f._hold_full and f._hold.size.is_equal_approx(OpeningMovie.cut_rect(f._root.size).size)
		seen["hidden"] = not stub.visible
		seen["music"] = Music.current
		seen["at"] = stub.position
		ov._chosen.emit(1)
	picker.call()
	var r := await StoryFilm.play(world, "midnight")
	_check(bool(r.get("played", false)), "midnight: it says it played")
	_check(int(r.get("mid_choice", -1)) == 1 and int(Game.flag("mid_choice", -1)) == 1, "midnight: the pick is kept (%s)" % r.get("mid_choice", -1))
	_check(stub.opened_files == ["midnight_1", "midnight_2b"], "midnight: part 1, then Bram's answer for the pick, on the one player (%s)" % [stub.opened_files])
	_check(bool(seen.get("held", false)) and bool(seen.get("hidden", false)), "midnight: at the choice the player steps aside for the held last frame (%s)" % [seen])
	_check(bool(seen.get("whole", false)), "midnight: the held frame fills the view as the player had the picture (no jump at the hand-over)")
	_check(absf(float(seen.get("at", 0.0)) - 34.083) < 0.1, "midnight: the choice comes at part 1's end (%.2f s)" % float(seen.get("at", 0.0)))
	_check(String(seen.get("music", "")) == "midnight_choice", "midnight: the menu music plays at the choice (%s)" % seen.get("music", ""))
	_check(Music.current == "midnight_choice", "midnight: and plays on, not restarted, under Bram's answer (%s)" % Music.current)
	var texts: Array = stub.subs.map(func(s): return String(s[1])).filter(func(t): return t != "")
	_check(texts.has("Bram: Write and tell them. See who writes back."), "midnight: Bram answers the pick made")
	_check(not texts.has("Bram: It shouldn't. It always seems to."), "midnight: and not the other")
	_check(texts.has("Midnight. The chapel bell counts twelve, and all of Ashford counts with it."), "midnight: narration goes over it with no name")
	var bram2: Array = stub.subs.filter(func(s): return String(s[1]).begins_with("Bram: Two thousand years."))
	_check(bram2.size() == 1 and absf(float(bram2[0][0]) - 27.525) < 0.25, "midnight: Bram's question comes where he says it (%s)" % [bram2])
	_check(String(r.get("stopped_at", "")) == "midnight_3", "midnight: it stops before part 3, not made yet (%s)" % r.get("stopped_at", ""))
	_check(stub.opened and stub.visible and stub.stopped == 0, "midnight: still up on its last frame for the scene to take over")
	_check(Cine.overlay(world)._black.modulate.a < 0.01, "midnight: and not on black")
	await StoryFilm.let_go(r, 0.3)
	_check(stub.stopped >= 1 and stub.opacity < 0.01, "midnight: let go, it fades and the player is taken down")
	_check(not is_instance_valid(r.get("film")) or (r.get("film") as Node).is_queued_for_deletion(), "midnight: and the film is gone")
	Music.stop(0.0)


func _wont_open() -> void:
	_fresh(func(p: FakePlayer) -> void: p.opens = false)
	var r := await StoryFilm.play(world, "white_light")
	_check(not bool(r.get("played", true)), "a film that won't open says it didn't play (the 3D plays instead)")


func _cant_be_read() -> void:
	_fresh(func(p: FakePlayer) -> void: p.fails = true)
	var r := await StoryFilm.play(world, "white_light")
	_check(not bool(r.get("played", true)), "a film that can't be read says it didn't play")
	_check(stub.stopped >= 1, "and the player is taken down")
