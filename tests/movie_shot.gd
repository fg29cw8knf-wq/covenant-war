extends Node
## Plays the opening movie on its own clock and checks Morrowen's lines against the shots:
## the timeline of every line (start, end, the gap to the next, the shot it ends in),
## that each starts in its own shot, none overlaps the next or is cut off, all end
## before the title at 2:14, each plays its own recording with its own subtitle when
## its time comes, and the movie ends at 2:24. With a screen it saves stills half a
## second into every line, plus any clock times given (seconds or m:ss).
##   godot --headless --fixed-fps 20 res://tests/movie_shot.tscn                       # timeline and checks only
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 20 \
##       res://tests/movie_shot.tscn -- /tmp/movie 84.5 2:03.5 2:05.6 2:07.7     # plus stills

const TITLE_LANDS := 134.0

var _out := ""
var _times: Array = []        # [clock time, label] still to take, in order
var _problems := 0
var _m: OpeningMovie
var _seen_line := 0
var _lines: Array = []
var _cuts := {}               # shot id -> [cut, end]


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else ""
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
	add_child(_m)
	_wait_end()


func _process(_delta: float) -> void:
	if not is_instance_valid(_m) or _m._done:
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
