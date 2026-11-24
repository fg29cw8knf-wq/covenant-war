class_name PerfLog
extends Node
## The game's own record of how fast it ran, kept while it's played (24
## November, Gary: "Game taking a very long time to start", "running slow when
## Morrowen is talking", "really glitchy through Bram's battle", "sluggish and
## slow to respond to movement after Bram's bit"). Nothing here has a graphics
## card, so the frame rate on his Mac has never been seen from here, and the
## one-minute speed test (SpeedTest) has to be gone and run. This needs
## nothing run: every part of the game says where it is (PerfLog.at), and for
## each part the log keeps how long was spent there, the frame rate over it,
## the slowest second, every catch (a frame over CATCH s) and what size the
## frame-rate guard had the 3D at. It's written to user://speed_log.txt as the
## game goes (so a game that's closed, or dies, leaves it behind), the session
## before it is kept beside it (speed_log_last.txt), and Options has "Copy the
## speed log": pasted to a session, it says which part was slow, how slow, and
## on what machine.
##
##   PerfLog.at("snow: the walk")     # where the game is, from now
##   PerfLog.report()                 # the log so far, as text
##
## It costs a handful of sums a frame and one small file every SAVE_EVERY s.

const FILE := "user://speed_log.txt"
const LAST := "user://speed_log_last.txt"
## A frame longer than this is a catch (s), and is listed with where it came.
const CATCH := 0.12
const CATCHES_KEPT := 40
const SAVE_EVERY := 15.0

static var _me: PerfLog = null
static var place := "starting"
## place -> {secs, frames, low, worst, catches, size, loads}; `order`: as met.
static var parts := {}
static var order: Array = []
static var catches: Array = []     # ["<place>: <ms> ms at <s> s", ...], the last CATCHES_KEPT
static var started_usec := 0

var _last_usec := 0
var _sec_t := 0.0
var _sec_frames := 0
var _save_t := 0.0
## (frames straight after a change of place are that place being made:
## counted as its load, not as its frame rate)
var _settle := 0


## Starts the log (Gfx.setup, once): the session before becomes LAST.
static func start(tree: SceneTree) -> void:
	if _me != null and is_instance_valid(_me):
		return
	if tree == null or OS.has_feature("web"):
		return
	started_usec = Time.get_ticks_usec()
	if FileAccess.file_exists(FILE):
		var was := FileAccess.get_file_as_string(FILE)
		var f := FileAccess.open(LAST, FileAccess.WRITE)
		if f != null:
			f.store_string(was)
			f.close()
	_me = PerfLog.new()
	_me.name = "PerfLog"
	_me.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child.call_deferred(_me)


## Where the game is from now on ("snow: the walk", "attic", "duel").
static func at(where: String) -> void:
	if where == "" or where == place:
		return
	place = where
	Gfx.Guard.place(where)   # (each place has its own size for the 3D: the frame-rate guard's)
	if _me != null and is_instance_valid(_me):
		_me._settle = 3


static func _part(where: String) -> Dictionary:
	if not parts.has(where):
		parts[where] = {"secs": 0.0, "frames": 0, "low": INF, "worst": 0.0, "catches": 0, "size": 0.0, "load": 0.0}
		order.append(where)
	return parts[where]


func _process(_delta: float) -> void:
	# (by the clock: slow motion and a test's set frame rate aren't the machine)
	var now := Time.get_ticks_usec()
	var real := (now - _last_usec) / 1000000.0 if _last_usec > 0 else 0.0
	_last_usec = now
	if real <= 0.0 or real > 30.0:
		return
	# (not while the window's in the background, where macOS slows it on purpose)
	if DisplayServer.get_name() != "headless" and not DisplayServer.window_is_focused():
		_sec_t = 0.0
		_sec_frames = 0
		return
	var p := _part(place)
	if _settle > 0:
		_settle -= 1
		p.load += real
		return
	p.secs += real
	p.frames += 1
	p.worst = maxf(float(p.worst), real)
	p.size += Gfx.Guard.scale_now() * real
	if real > CATCH:
		p.catches += 1
		catches.append("%s: %d ms at %d s" % [place, roundi(real * 1000.0), roundi((now - started_usec) / 1000000.0)])
		if catches.size() > CATCHES_KEPT:
			catches.pop_front()
	_sec_t += real
	_sec_frames += 1
	if _sec_t >= 1.0:
		p.low = minf(float(p.low), _sec_frames / _sec_t)
		_sec_t = 0.0
		_sec_frames = 0
	_save_t += real
	if _save_t >= SAVE_EVERY:
		_save_t = 0.0
		save()


func _notification(what: int) -> void:
	# (as the window's closed, and as a phone puts the game away)
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save()


static func save() -> void:
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(report())
		f.close()


## The machine, in a line or two: what it is, what it's drawing on and at
## what size, and how the picture's set.
static func machine() -> String:
	var mem: Dictionary = OS.get_memory_info()
	var gb := float(mem.get("physical", 0)) / 1073741824.0
	var free := float(mem.get("available", mem.get("free", 0))) / 1073741824.0
	var screen := DisplayServer.screen_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	var win := DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else Vector2i.ZERO
	var out := "%s %s · %s (%d cores) · %s · memory %.0f GB (%.1f free)" % [OS.get_name(), OS.get_version(), OS.get_processor_name(),
		OS.get_processor_count(), RenderingServer.get_video_adapter_name(), gb, free]
	out += "\nscreen %dx%d, window %dx%d, %s" % [screen.x, screen.y, win.x, win.y, RenderingServer.get_current_rendering_method()]
	out += " · smoothing %s · Best picture %s · 3D at %d%%%s" % ["on" if Gfx.Guard.on() else "off", "on" if Gfx.Best.on() else "off",
		roundi(Gfx.Guard.scale_now() * 100.0), ", no bounce light" if Gfx.Guard.lean else ""]
	var tex := float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)) / 1048576.0
	var vid := float(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)) / 1048576.0
	out += "\npictures held %d MB, graphics memory %d MB, the game's own %d MB" % [roundi(tex), roundi(vid), roundi(OS.get_static_memory_usage() / 1048576.0)]
	return out


## The whole log as text: the build, the machine, the launch, then a line a
## part of the game in the order they were met, and the catches.
static func report() -> String:
	var lines: Array = []
	lines.append("The Covenant War speed log · build %s · %s" % [Packs.build_label(), Time.get_datetime_string_from_system(false, true)])
	lines.append(machine())
	var marks: Array = Game.settings.get(LaunchLog.MARKS, [])
	if not marks.is_empty():
		lines.append("launch: " + " · ".join(PackedStringArray(marks)))
	lines.append("")
	for where in order:
		var p: Dictionary = parts[where]
		if float(p.secs) < 0.5:
			continue
		var fps := float(p.frames) / maxf(0.001, float(p.secs))
		var low := float(p.low) if float(p.low) < INF else fps
		var line := "%s: %d s at %d fps (slowest second %d), 3D at %d%%" % [where, roundi(float(p.secs)), roundi(fps), roundi(low),
			roundi(float(p.size) / maxf(0.001, float(p.secs)) * 100.0)]
		if int(p.catches) > 0:
			line += ", %d catches (longest %d ms)" % [int(p.catches), roundi(float(p.worst) * 1000.0)]
		if float(p.load) > 0.25:
			line += ", %.1f s to come up" % float(p.load)
		lines.append(line)
	if not catches.is_empty():
		lines.append("")
		lines.append("catches: " + " · ".join(PackedStringArray(catches)))
	return "\n".join(PackedStringArray(lines)) + "\n"


## This session's log and the one before it, and the speed test's last result
## if there is one: what "Copy the speed log" puts on the clipboard.
static func everything() -> String:
	var out := report()
	if FileAccess.file_exists(LAST):
		out += "\n--- the time before ---\n" + FileAccess.get_file_as_string(LAST)
	if FileAccess.file_exists(SpeedTest.FILE):
		out += "\n--- the speed test ---\n" + FileAccess.get_file_as_string(SpeedTest.FILE)
	return out
