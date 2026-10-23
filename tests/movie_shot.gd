extends Node
## Plays the opening movie on its own clock and checks Morrowen's lines against the shots:
## the timeline of every line (start, end, the gap to the next, the shot it ends in),
## that each starts in its own shot, none overlaps the next or is cut off, all end
## before the title at 2:14, each plays its own recording with its own subtitle when
## its time comes, and the movie ends at 2:24. With a screen it saves stills half a
## second into every line, plus any clock times given (seconds or m:ss).
## It plays the shot-by-shot path whether or not the finished cut exists.
##   godot --headless --fixed-fps 20 res://tests/movie_shot.tscn                       # timeline and checks only
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 20 \
##       res://tests/movie_shot.tscn -- /tmp/movie 84.5 2:03.5 2:05.6 2:07.7     # plus stills
## With `cut` it plays the finished cut (assets/movies/opening.ogv) instead and
## checks that nothing of the engine's goes over it (no subtitle, music, voice
## or title) and that it runs to its own end, with a still at each time given:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##       res://tests/movie_shot.tscn -- /tmp/movie cut 0:20 1:30 3:04

const TITLE_LANDS := 134.0

var _out := ""
var _times: Array = []        # [clock time, label] still to take, in order
var _problems := 0
var _m: OpeningMovie
var _seen_line := 0
var _lines: Array = []
var _cuts := {}               # shot id -> [cut, end]


var _cut_mode := false
var _cut_problems := {}


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else ""
	if a.size() > 1 and a[1] == "cut":
		_cut_mode = true
		_play_cut(a.slice(2))
		return
	var cut := 0.0
	for s in OpeningMovie.SHOTS:
		_cuts[s.id] = [cut, cut + float(s.len)]
		cut += float(s.len)
	_check(absf(cut - 144.0) < 0.01, "the shots add up to 2:24 (%s)" % _ts(cut))
	_lines = OpeningMovie.schedule()
	_timeline()
	if _out != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_out)
		for l in _lines:
			_times.append([float(l.start) + 0.5, String(l.shot).replace("shot", "vo")])
		for t in a.slice(1):
			_times.append([_secs(t), "at"])
		_times.sort_custom(func(x, y): return x[0] < y[0])
	_m = OpeningMovie.new()
	_m.shots_only = true
	add_child(_m)
	_wait_end()


## The finished cut, start to end, with nothing of the engine's over it.
func _play_cut(times: Array) -> void:
	_check(ResourceLoader.exists(OpeningMovie.MOVIE), "the finished cut exists (%s)" % OpeningMovie.MOVIE)
	var length := 0.0
	if ResourceLoader.exists(OpeningMovie.MOVIE):
		var p := ProjectSettings.globalize_path(OpeningMovie.MOVIE)
		print("the cut: %s, %.1f MB" % [OpeningMovie.MOVIE, FileAccess.get_file_as_bytes(p).size() / 1048576.0])
	if _out != "" and DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(_out)
		for t in times:
			_times.append([_secs(t), "cut"])
		_times.sort_custom(func(x, y): return x[0] < y[0])
	_m = OpeningMovie.new()
	add_child(_m)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_m._cut, "the finished cut is what's playing")
	_check(_m._video.visible and _m._video.is_playing(), "the video is playing")
	var fr := OpeningMovie.cut_rect(_m._root.size)
	var vr := Rect2(_m._video.position, _m._video.size)
	_check(vr.size.is_equal_approx(fr.size) and vr.position.is_equal_approx(fr.position),
		"the cut is shown whole, as big as fits, centred (%s, frame %s)" % [vr, fr])
	# nothing of the picture is off the screen (Gary's title and words are in it)
	var screen := Rect2(Vector2.ZERO, _m._root.size)
	_check(screen.grow(0.5).encloses(vr), "the whole cut is on screen (%s in %s)" % [vr, screen])
	_check(absf(vr.size.x / vr.size.y - 16.0 / 9.0) < 0.01, "the cut keeps its 16:9 shape (%s)" % vr.size)
	var last := 0.0
	while is_instance_valid(_m) and not _m._done:
		await get_tree().process_frame
		if not is_instance_valid(_m):
			break
		last = maxf(last, _m._clock)
		_over("a subtitle", _m._sub.text != "")
		_over("the engine's music", _m._music.playing)
		_over("Morrowen's voice", _m._voice.playing)
		_over("the stage (title, lights, streak)", _m._stage.visible)
		if not _times.is_empty() and _m._clock >= _times[0][0]:
			var t: Array = _times.pop_front()
			_still(t[0], t[1])
	for what in _cut_problems:
		_check(false, "%s went over the cut at %s" % [what, _ts(_cut_problems[what])])
	print("the cut ran to %s" % _ts(last))
	_check(last > 185.0, "the cut played to its end, about 3:14 (%s)" % _ts(last))
	print("MOVIE SHOT (the cut): %s (%d problems)" % ["PASS" if _problems == 0 else "FAIL", _problems])
	get_tree().quit()


func _over(what: String, bad: bool) -> void:
	if bad and not _cut_problems.has(what):
		_cut_problems[what] = _m._clock


func _process(_delta: float) -> void:
	if _cut_mode or not is_instance_valid(_m) or _m._done:
		return
	# each line as it starts: on time, its own recording, its own words up
	if _m._next_line > _seen_line:
		var l: Dictionary = _lines[_seen_line]
		_seen_line = _m._next_line
		var late := _m._clock - float(l.start)
		var stream := _m._voice.stream
		_check(late >= 0.0 and late < 0.06, "%s starts on time (%.3f s late)" % [l.shot, late])
		_check(stream != null and stream.resource_path == l.path, "%s plays %s" % [l.shot, l.path.get_file()])
		_check(_m._sub.text == l.text, "%s's subtitle is its words" % l.shot)
	if not _times.is_empty() and _m._clock >= _times[0][0]:
		var t: Array = _times.pop_front()
		_still(t[0], t[1])


func _still(t: float, label: String) -> void:
	await RenderingServer.frame_post_draw
	var name := "movie_%s_%s.png" % [_ts(t).replace(":", "m"), label]
	get_viewport().get_texture().get_image().save_png(_out.path_join(name))
	print("saved ", name)


func _wait_end() -> void:
	while is_instance_valid(_m) and not _m._done:
		await get_tree().process_frame
	var ended_at := _m._clock if is_instance_valid(_m) else -1.0
	_check(_seen_line == _lines.size(), "every line was spoken (%d of %d)" % [_seen_line, _lines.size()])
	_check(ended_at >= 143.9 and ended_at < 144.2, "the movie ends at 2:24 (%s)" % _ts(ended_at))
	print("MOVIE SHOT: %s (%d problems)" % ["PASS" if _problems == 0 else "FAIL", _problems])
	get_tree().quit()


## Every line against the shots, and the checks that need only the timetable.
func _timeline() -> void:
	print("line      cut       start   +at     length  end       gap   ends in")
	for i in _lines.size():
		var l: Dictionary = _lines[i]
		var c: Array = _cuts[l.shot]
		var nxt: float = _lines[i + 1].start if i + 1 < _lines.size() else TITLE_LANDS
		print("%-8s  %-8s  %-8s +%.2f  %6.3f  %-8s  %5.2f  %s" % [String(l.shot).replace("shot", "vo"), _ts(c[0]),
			_ts(l.start), float(l.start) - float(c[0]), float(l.end) - float(l.start), _ts(l.end), nxt - float(l.end), _shot_at(l.end - 0.001)])
		_check(l.path != "", "%s has its recording" % l.shot)
		_check(l.start >= c[0] and l.start < c[1], "%s starts in its own shot" % l.shot)
		_check(l.end <= nxt, "%s ends before %s" % [l.shot, "the next line" if i + 1 < _lines.size() else "the title (2:14)"])
	# the effects timed to the words
	for s in OpeningMovie.SHOTS:
		if s.has("white_word"):
			print("%s: the eighth light ignites at %s, on \"marked\"" % [s.id, _ts(_start_of(s.id) + float(s.white_word))])
		if s.has("streak"):
			print("%s: the white streak sets off at %s and lands at %s (the cut is at %s)" % [s.id,
				_ts(_start_of(s.id) + float(s.streak[0])), _ts(_start_of(s.id) + float(s.streak[1])), _ts(_cuts[s.id][1])])
			_check(_start_of(s.id) + float(s.streak[1]) < _cuts[s.id][1] - 0.2, "the streak lands before the cut")


func _start_of(id: String) -> float:
	for l in _lines:
		if l.shot == id:
			return l.start
	return 0.0


func _shot_at(t: float) -> String:
	for id in _cuts:
		if t >= _cuts[id][0] and t < _cuts[id][1]:
			return id
	return "-"


func _check(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("PROBLEM: ", what)


static func _ts(t: float) -> String:
	return "%d:%06.3f" % [int(t) / 60, fmod(t, 60.0)]


static func _secs(s: String) -> float:
	if ":" in s:
		return int(s.get_slice(":", 0)) * 60 + float(s.get_slice(":", 1))
	return float(s)
