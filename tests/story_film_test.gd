extends Node
## The story films (StoryFilm) through the device's own player, driven here
## by a stand-in (the real one exists only in the iPhone and Mac apps, and
## the browser's on the phone link). Checks that a film is "there" only when
## the player can find its <film>_4k.mp4; that it plays through the player
## with nothing of the engine's showing, its lines going over it as the
## player's own subtitles, each at its moment and with the speaker's name;
## that a choice pauses it and hides it (the game's buttons over black) and
## it carries on after with the line for the pick; that it ends on black with
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
	var films := ["white_light", "midnight"]   # which <film>_4k.mp4 are "in the bundle"
	var opens := true
	var fails := false                        # can't be read
	var ready_after := 3
	var length := 38.0
	var position := 0.0
	var playing := false
	var opened := false
	var visible := true
	var stopped := 0
	var subs: Array = []                      # [position, text] each time a subtitle is set
	var hidden_at: Array = []                 # positions it was hidden at
	var ended := false
	var _frames := 0
	var _told_end := false

	func is_supported() -> bool: return true
	func find_file(name: String) -> String:
		for f in films:
			if name == f + "_4k.mp4":
				return "/app/" + name
		return ""
	func open(_path: String) -> bool:
		if not opens:
			return false
		opened = true
		position = 0.0
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
	func set_opacity(_a: float) -> void: pass
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


## Midnight: Bram's question pauses the film and hides it for the game's
## buttons; the answer picked decides his line after.
func _choice() -> void:
	_fresh(func(p: FakePlayer) -> void: p.length = 104.0)
	var ov := Cine.overlay(world)
	var picker := func() -> void:
		while not ov._choices.visible:
			await get_tree().process_frame
		await get_tree().create_timer(0.6).timeout
		ov._chosen.emit(1)
	picker.call()
	var r := await StoryFilm.play(world, "midnight")
	_check(bool(r.get("played", false)), "midnight: it says it played")
	_check(int(r.get("mid_choice", -1)) == 1 and int(Game.flag("mid_choice", -1)) == 1, "midnight: the pick is kept (%s)" % r.get("mid_choice", -1))
	_check(stub.hidden_at.size() == 1, "midnight: the film stepped aside once, for the choice")
	if stub.hidden_at.size() == 1:
		# the choice comes after mid_06: 7 + 7 + 5 + 6 + 10 + 6 = 41 s
		_check(absf(float(stub.hidden_at[0]) - 41.0) < 0.3, "midnight: at the choice's place in the film (%.2f s)" % float(stub.hidden_at[0]))
	var texts: Array = stub.subs.map(func(s): return String(s[1])).filter(func(t): return t != "")
	_check(texts.has("Bram: Write and tell them. See who writes back."), "midnight: Bram answers the pick made")
	_check(not texts.has("Bram: It shouldn't. It always seems to."), "midnight: and not the other")
	_check(texts.has("Screams finally break the silence."), "midnight: narration goes over it without its [i] tags")


func _wont_open() -> void:
	_fresh(func(p: FakePlayer) -> void: p.opens = false)
	var r := await StoryFilm.play(world, "white_light")
	_check(not bool(r.get("played", true)), "a film that won't open says it didn't play (the 3D plays instead)")


func _cant_be_read() -> void:
	_fresh(func(p: FakePlayer) -> void: p.fails = true)
	var r := await StoryFilm.play(world, "white_light")
	_check(not bool(r.get("played", true)), "a film that can't be read says it didn't play")
	_check(stub.stopped >= 1, "and the player is taken down")
