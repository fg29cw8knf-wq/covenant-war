extends Node
## The opening movie through the device's own player (NativeVideoPlayer,
## addons/native_video), driven here by a stand-in, since the real player
## exists only in the iPhone and Mac apps. Checks that OpeningMovie prefers it
## when the 4K film is in the bundle (nothing of the engine's shown), follows
## its clock, shows its Skip on a tap and skips on the next, that E shows Skip
## and a second E skips, that Esc skips at once, that the fade-out takes the
## picture and the sound down together (not a cut) and stops the player, that
## the film's end ends the movie, and that without the film, when it won't
## open or can't be read, the Theora copy plays as before.
##   godot --headless --fixed-fps 30 res://tests/native_movie_test.tscn
## Ends with "NATIVE MOVIE TEST: PASS" or the problems.

var _problems := 0
var stub: FakePlayer = null
var _finished := false


## Stands in for NativeVideoPlayer: the same methods, with knobs for what the
## film does, and the taps a person would make.
class FakePlayer:
	extends RefCounted
	var file := "/app/opening_4k.mp4"   # "": the film isn't in the bundle
	var opens := true                   # open() succeeds
	var ready_after := 3                # frames before the file's read
	var fails_at := -1.0                # fails when it reaches this (-1: never)
	var length := 194.6
	var position := 0.0
	var playing := false
	var opened := false
	var stopped := 0
	var skip_shown := false
	var skip_text := ""
	var opacity := 1.0
	var volume := 1.0
	var opacities: Array = []
	var failed := false
	var ended := false
	var polls := 0
	var _frames := 0
	var _queue := 0
	var _told_end := false
	var _told_fail := false

	func is_supported() -> bool: return true
	func find_file(name: String) -> String: return file if name == "opening_4k.mp4" else ""
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
	func is_ready() -> bool: return opened and _frames >= ready_after and not failed
	func is_playing() -> bool: return playing and not ended and not failed
	func has_finished() -> bool: return ended
	func has_failed() -> bool: return failed
	func get_error() -> String: return "a pretend failure" if failed else ""
	func get_position() -> float: return position
	func get_length() -> float: return length
	func seek(s: float) -> void: position = s
	func get_video_size() -> Vector2: return Vector2(3840, 2160)
	func set_volume(v: float) -> void: volume = v
	func get_volume() -> float: return volume
	func set_opacity(a: float) -> void:
		opacity = a
		opacities.append(a)
	func set_visible(_v: bool) -> void: pass
	func is_visible() -> bool: return opened
	func set_subtitle(_t: String) -> void: pass
	func show_skip(show: bool, text := "Skip") -> void:
		skip_shown = show
		skip_text = text
	func tap() -> void: _queue |= 1
	func press_skip() -> void: _queue |= 2
	func poll() -> int:
		polls += 1
		var ev := _queue
		_queue = 0
		if ended and not _told_end:
			_told_end = true
			ev |= 4
		if failed and not _told_fail:
			_told_fail = true
			ev |= 8
		return ev
	## A frame passing (the test's _process).
	func advance(delta: float) -> void:
		if not opened:
			return
		_frames += 1
		if fails_at >= 0.0 and _frames >= ready_after and position >= fails_at and not failed:
			failed = true
			playing = false
		if playing and not ended and not failed:
			position = minf(position + delta, length)
			if position >= length:
				ended = true
				playing = false


func _process(delta: float) -> void:
	if stub != null:
		stub.advance(delta)


func _ready() -> void:
	await _tap_and_skip()
	await _keys()
	await _esc()
	await _runs_to_its_end()
	await _fails_midway()
	await _no_film()
	await _wont_open()
	await _cant_be_read()
	OpeningMovie.native_stub = null
	print("NATIVE MOVIE TEST: %s (%d problems)" % ["PASS" if _problems == 0 else "FAIL", _problems])
	get_tree().quit(1 if _problems > 0 else 0)


## A new stand-in and a new movie over it.
func _start(setup: Callable = Callable()) -> OpeningMovie:
	stub = FakePlayer.new()
	if setup.is_valid():
		setup.call(stub)
	OpeningMovie.native_stub = stub
	_finished = false
	var m := OpeningMovie.new()
	m.finished.connect(func() -> void: _finished = true)
	add_child(m)
	await frames(2)
	return m


func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func secs(t: float) -> void:
	var left := t
	while left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()


## Until the movie's gone (finished, faded, freed), or `limit` seconds pass.
func gone(m: OpeningMovie, limit := 5.0) -> bool:
	var left := limit
	while is_instance_valid(m) and left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()
	return not is_instance_valid(m)


## The native player is up and the engine's own movie isn't.
func _native_up(m: OpeningMovie, when: String) -> void:
	_check(m._native == stub, "%s: the native player is what's playing" % when)
	_check(stub.opened and stub.playing, "%s: the film is open and playing" % when)
	_check(m._cut, "%s: it counts as the finished cut (no shots after it)" % when)
	_check(not m._video.visible, "%s: the Theora player isn't showing" % when)
	_check(not m._stage.visible, "%s: the stage (title, lights) isn't showing" % when)
	_check(stub.volume == 1.0, "%s: its sound is at full volume" % when)


## The fade-out took the player down gently and stopped it.
func _faded(when: String) -> void:
	_check(_finished, "%s: the movie said it finished" % when)
	_check(stub.stopped == 1, "%s: the native player was stopped once (%d)" % [when, stub.stopped])
	_check(stub.opacity <= 0.001, "%s: its picture faded right out (%.3f)" % [when, stub.opacity])
	_check(stub.volume <= 0.001, "%s: its sound faded right out (%.3f)" % [when, stub.volume])
	var steps := stub.opacities.size()
	var down := true
	for i in range(1, steps):
		if float(stub.opacities[i]) > float(stub.opacities[i - 1]) + 0.001:
			down = false
	_check(steps >= 4 and down, "%s: the fade was a fade, not a cut (%d steps, falling: %s)" % [when, steps, down])


func _tap_and_skip() -> void:
	var m := await _start()
	await frames(6)
	_native_up(m, "tap and skip")
	await secs(1.5)
	_check(absf(m._clock - stub.position) < 0.2, "the movie clock follows the film (%.2f vs %.2f)" % [m._clock, stub.position])
	_check(not stub.skip_shown and not m._skip_up, "no Skip until a tap")
	stub.tap()
	await frames(3)
	_check(stub.skip_shown and m._skip_up, "a tap shows the player's own Skip")
	await secs(4.0)
	_check(not stub.skip_shown and not m._skip_up, "Skip goes away after 3.5 s")
	stub.tap()
	await frames(3)
	_check(stub.skip_shown, "Skip is back on the next tap")
	stub.press_skip()
	_check(await gone(m), "Skip ends the movie")
	_faded("tap and skip")


func _keys() -> void:
	var m := await _start()
	await frames(6)
	_native_up(m, "keys")
	await press(KEY_E)
	_check(stub.skip_shown and m._skip_up, "E shows Skip while the native player plays")
	await press(KEY_E)
	_check(await gone(m), "a second E skips")
	_faded("keys")


func _esc() -> void:
	var m := await _start()
	await frames(6)
	await press(KEY_ESCAPE)
	_check(await gone(m), "Esc skips at once")
	_faded("esc")


func _runs_to_its_end() -> void:
	var m := await _start(func(s: FakePlayer) -> void: s.length = 2.0)
	await frames(6)
	_native_up(m, "to the end")
	_check(await gone(m, 6.0), "the film's end ends the movie")
	_check(stub.ended, "the film did run to its end")
	_faded("to the end")


func _fails_midway() -> void:
	var m := await _start(func(s: FakePlayer) -> void: s.fails_at = 2.0)
	await frames(6)
	_native_up(m, "fails midway")
	_check(await gone(m, 6.0), "a failure in the middle of the film ends the movie (no second start)")
	_check(stub.stopped == 1 and _finished, "the player was stopped and the movie finished")


## Without the native film the Theora copy (or the shots) plays, as before.
func _theora_instead(m: OpeningMovie, when: String) -> void:
	_check(m._native == null, "%s: the native player isn't used" % when)
	_check(m._stage.visible or m._video.visible, "%s: the engine's own movie is showing" % when)
	m._finish()
	_check(await gone(m), "%s: the movie ends as before" % when)
	_check(_finished, "%s: it said it finished" % when)


func _no_film() -> void:
	var m := await _start(func(s: FakePlayer) -> void: s.file = "")
	await frames(4)
	_check(stub.stopped == 0 and not stub.opened, "no film in the bundle: the player was never opened")
	await _theora_instead(m, "no film")


func _wont_open() -> void:
	var m := await _start(func(s: FakePlayer) -> void: s.opens = false)
	await frames(4)
	await _theora_instead(m, "won't open")


func _cant_be_read() -> void:
	var m := await _start(func(s: FakePlayer) -> void:
		s.fails_at = 0.0
		s.ready_after = 2)
	await frames(8)
	_check(stub.stopped == 1, "can't be read: the native player was taken down")
	await _theora_instead(m, "can't be read")


func press(code: Key) -> void:
	key(code, true)
	await frames(2)
	key(code, false)
	await frames(2)


func key(code: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("PROBLEM: ", what)
