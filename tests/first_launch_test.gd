extends Node
## The game opened for the first time, and opened again (12 November, Gary:
## "The opening movie moves to before the title screen on first launch,
## skippable. New Game then goes straight to the snow."). The game's own main
## scene is started as the game starts it (so the notice and the movie come),
## with a watcher left on the tree's root that does what a player would: the
## notice tapped on, the opening movie skipped, New Game pressed. Checked:
##   first launch (seen_opening false): the notice, then the movie BEFORE any
##     title, then the title; New Game goes to the snow (WhiteSky) with no
##     movie after it;
##   "again" (seen_opening true): the notice, then the title, no movie at
##     all; New Game goes to the snow.
##   godot --headless --path . res://tests/first_launch_test.tscn [-- again]
## Ends "FIRST LAUNCH: ok" or the problems.


func _ready() -> void:
	var again := "again" in OS.get_cmdline_user_args()
	Game.settings["seen_opening"] = again
	Game.settings["seen_white_sky"] = false
	if FileAccess.file_exists(Game.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.SAVE_PATH))
	var w := Watcher.new()
	w.again = again
	get_tree().root.add_child.call_deferred(w)
	get_tree().change_scene_to_file.call_deferred("res://scenes/main.tscn")


class Watcher:
	extends Node
	var again := false
	var seen: Array = []          # what came up, in order
	var problems: Array = []
	var _t := 0.0
	var _pressed := false
	var _movie_after_new := false
	var _done := false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _note(what: String) -> void:
		if seen.is_empty() or seen[-1] != what:
			seen.append(what)
			print("  [%.1f] %s" % [_t, what])

	func _process(delta: float) -> void:
		_t += delta
		if _done:
			return
		var root := get_tree().root
		var notice := root.find_children("*", "NoticeScreen", true, false)
		var movie := root.find_children("*", "OpeningMovie", true, false)
		var title := root.find_children("*", "TitleScreen", true, false)
		var snow := root.find_children("*", "WhiteSky", true, false)
		if not notice.is_empty():
			_note("notice")
			(notice[0] as NoticeScreen)._finish()
		if not movie.is_empty():
			_note("movie")
			if _pressed:
				_movie_after_new = true
			(movie[0] as OpeningMovie)._finish()
		if not title.is_empty() and movie.is_empty() and notice.is_empty():
			_note("title")
			if not _pressed and _t > 1.0:
				# (a moment on the title, as a player takes; then New Game)
				var main := get_tree().current_scene
				if main != null and main.has_method("_on_new_game") and _held(2.0):
					_pressed = true
					_note("New Game pressed")
					main.call("_on_new_game")
		if not snow.is_empty():
			_note("the snow")
			_finish()
		if _t > 240.0:
			problems.append("nothing more after %s" % [seen])
			_finish()

	var _hold_from := -1.0

	func _held(secs: float) -> bool:
		if _hold_from < 0.0:
			_hold_from = _t
		return _t - _hold_from >= secs

	func _finish() -> void:
		_done = true
		var want: Array = ["notice", "title", "New Game pressed", "the snow"] if again else ["notice", "movie", "title", "New Game pressed", "the snow"]
		if seen != want:
			problems.append("came up as %s, not %s" % [seen, want])
		if _movie_after_new:
			problems.append("the movie played after New Game")
		if not again and not bool(Game.settings.get("seen_opening", false)):
			problems.append("the movie wasn't marked as seen")
		print("FIRST LAUNCH%s: %s" % [" (again)" if again else "", "ok" if problems.is_empty() else "%d problems: %s" % [problems.size(), "; ".join(problems)]])
		get_tree().quit(0 if problems.is_empty() else 1)
