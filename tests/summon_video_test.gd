extends Node
## The rule for Gary's Summon clips (SummonVideo): the first time a card is
## summoned in a save its full clip plays, every time after the short one;
## "3-second intro" always the short, "Full video" always the full, "Off"
## none; a card with no clip plays none.
##   godot --headless res://tests/summon_video_test.tscn
var problems: Array = []


func _ready() -> void:
	Game.new_game("Sprout", "emberstorm")
	SummonVideo.stub_clips = ["pyraxis"]
	SummonVideo.set_mode("full")
	_check(SummonVideo.pick("pyraxis") == "full", "the first time plays the full clip (%s)" % SummonVideo.pick("pyraxis"))
	_check(SummonVideo.pick("cinderpup") == "", "a card with no clip plays none (%s)" % SummonVideo.pick("cinderpup"))
	var holder := Control.new()
	add_child(holder)
	await SummonVideo.play(holder, "pyraxis")
	_check(SummonVideo.seen("pyraxis"), "it's marked seen in the save")
	_check(SummonVideo.pick("pyraxis") == "short", "the second time plays the short one (%s)" % SummonVideo.pick("pyraxis"))
	SummonVideo.set_mode("short")
	SummonVideo.stub_clips = ["pyraxis", "thalassa"]
	_check(SummonVideo.pick("thalassa") == "short", "Short plays the short one first time too (%s)" % SummonVideo.pick("thalassa"))
	# (12 November) Full video: the whole clip every time, seen before or not
	SummonVideo.set_mode("always")
	_check(SummonVideo.seen("pyraxis") and SummonVideo.pick("pyraxis") == "full", "Full video plays the whole clip of one already seen (%s)" % SummonVideo.pick("pyraxis"))
	_check(SummonVideo.pick("thalassa") == "full", "Full video plays the whole clip the first time too (%s)" % SummonVideo.pick("thalassa"))
	for m: String in SummonVideo.MODES:
		_check(SummonVideo.MODE_NAMES.has(m) and SummonVideo.MODE_WORDS.has(m), "the choice '%s' has a name and a line saying what it does" % m)
	SummonVideo.set_mode("off")
	_check(SummonVideo.pick("pyraxis") == "", "Off plays none (%s)" % SummonVideo.pick("pyraxis"))
	SummonVideo.set_mode("nonsense")
	_check(SummonVideo.mode() == "full", "an unknown setting reads as Full once")
	SummonVideo.set_mode("full")
	SummonVideo.stub_clips = []
	print("SUMMON VIDEO TEST: %s" % ("ok" if problems.is_empty() else "; ".join(problems)))
	get_tree().quit(0 if problems.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	print("  %s %s" % ["ok" if ok else "PROBLEM:", what])
	if not ok:
		problems.append(what)
