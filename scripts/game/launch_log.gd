class_name LaunchLog
extends RefCounted
## Where a launch got to, kept in the settings so the next launch can say where
## the last one stopped. Gary's iPhone stuck on its first launch of a build
## (22 October: "the first time launching the game it sticks, I have to close
## and reopen it"), and nobody could see where: Main marks each step it reaches
## (the notice, the title, Ashford built under the title, its shaders warmed)
## with the time since the app started and the slowest frame on the way, and
## the Options page shows the last launch's marks ("Last launch: ..."), so what
## a phone did can be read off it and told to a session.

const MARKS := "launch_marks"
const LAST := "last_launch"


## At start-up: the launch before this one becomes "last_launch", and a new
## record begins.
static func start() -> void:
	var prev: Array = Game.settings.get(MARKS, [])
	if not prev.is_empty():
		Game.settings[LAST] = prev
	Game.settings[MARKS] = []
	mark("start")


## A step reached, with the seconds since the app started; saved at once, so
## a launch that's killed still leaves its last mark behind.
static func mark(what: String) -> void:
	var marks: Array = Game.settings.get(MARKS, [])
	marks.append("%s %.1fs" % [what, Time.get_ticks_msec() / 1000.0])
	Game.settings[MARKS] = marks
	Game.save_settings()


## The last launch's marks as one line for the Options page, or "" if there
## was none. A launch that never reached the title with Ashford warmed under
## it ("ready") is said to have stopped.
static func last() -> String:
	var marks: Array = Game.settings.get(LAST, [])
	if marks.is_empty():
		return ""
	var ok := false
	for m in marks:
		if String(m).begins_with("ready"):
			ok = true
	return ("%s" if ok else "stopped after: %s") % " · ".join(PackedStringArray(marks))


## Watches the frames while something runs: `report()` is the slowest one, in ms.
class FrameWatch:
	extends Node
	var worst := 0.0

	func _process(delta: float) -> void:
		worst = maxf(worst, delta)

	func report() -> int:
		queue_free()
		return roundi(worst * 1000.0)
