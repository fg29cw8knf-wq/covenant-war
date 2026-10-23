extends Node
## The rule for Gary's Summon clips (SummonVideo): the first time a card is
## summoned in a save its full clip plays, every time after the short one;
## "Short" always the short, "Off" none; a card with no clip plays none.
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
	SummonVideo.set_mode("off")
	_check(SummonVideo.pick("pyraxis") == "", "Off plays none (%s)" % SummonVideo.pick("pyraxis"))
	SummonVideo.set_mode("nonsense")
	_check(SummonVideo.mode() == "full", "an unknown setting reads as Full")
	SummonVideo.set_mode("full")
	SummonVideo.stub_clips = []
	print("SUMMON VIDEO TEST: %s" % ("ok" if problems.is_empty() else "; ".join(problems)))
	get_tree().quit(0 if problems.is_empty() else 1)


func _check(ok: bool, what: String) -> void:
	print("  %s %s" % ["ok" if ok else "PROBLEM:", what])
	if not ok:
		problems.append(what)
