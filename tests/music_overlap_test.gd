extends Node
## Two pieces of music at once (11 November, Gary: "After first battle with
## Corin we have 2 different music playing at same time"). Plays the music
## calls of the Lantern Duel in their order, as the game makes them (Bram's
## theme, the duel's music, the pinch, the stop and the victory piece as it
## ends, the village's reel as the duel closes with the victory piece still
## going), and listens to Music's three players every frame: once a change's
## fade is over, only one piece may be audible. Then the quick changes that
## used to leave a track stopped or brought back by an old fade's last step.
##   godot --headless --fixed-fps 30 res://tests/music_overlap_test.tscn
## `old` plays it with the victory piece left alone (the fault, for the
## test's own check: it must fail).

var problems: Array = []
var old := false


func _ready() -> void:
	old = "old" in OS.get_cmdline_user_args()
	Game.settings["music"] = 0.8
	await _wait(0.2)
	# the green: the reel; Bram's theme as he gives the box
	Music.play(["ashford_festival"], 0.5, true)
	await _wait(2.0)
	Music.play(["bram_theme"], 2.0, true)
	await _wait(3.0)
	_one("Bram's theme")
	# the duel's music, then the pinch as someone's Life runs low
	Music.play(["arena_ashford", "duel_main", "duel_alt"])
	await _wait(2.0)
	_one("the duel")
	Music.stinger("summon_grondmaw")          # (a piece over the music: both are meant to sound)
	await _wait(0.5)
	Music.play(["duel_pinch"], 0.6)
	await _wait(1.5)
	if _loud().size() != 2:
		problems.append("a Summon's piece over the pinch: %s (wanted the pinch and the piece)" % str(_loud()))
	# the duel ends: the music stops, the victory piece plays on its own
	Music.stop(0.4)
	Music.stinger("victory", false)
	await _wait(1.0)
	_one("the victory piece")
	# ...and the player taps through: back on the green three seconds into
	# its twelve, the reel coming back
	await _wait(2.0)
	if old:
		Music._sting_solo = false
	Music.play(["ashford_festival"], 1.5, true)
	await _wait(2.2)
	_one("back on the green after the duel")
	if Music.current != "ashford_festival" or not Music._players[Music._active].playing:
		problems.append("the reel isn't playing after the duel")
	await _wait(4.0)
	_one("the green, six seconds after the duel")
	# two changes inside one fade: the second must be the one left playing
	Music.play(["bram_theme"], 2.0, true)
	await _wait(0.4)
	Music.play(["tam_mill"], 0.5, true)
	await _wait(3.0)
	_one("two changes inside one fade")
	if _loud() != ["tam_mill"]:
		problems.append("two changes inside one fade left %s playing (wanted tam_mill)" % str(_loud()))
	# a long stop, and a new piece before it's over: the new piece stays
	Music.stop(3.0)
	await _wait(0.5)
	Music.play(["nell_waltz"], 0.5, true)
	await _wait(0.3)
	Music.play(["ashford_festival"], 0.5, true)
	await _wait(4.0)
	if _loud() != ["ashford_festival"]:
		problems.append("a change during a long stop left %s playing (wanted the reel)" % str(_loud()))
	# a dip (a Summon's clip) and then a change: the old piece mustn't come back up
	Music.duck(2.0)
	await _wait(0.3)
	Music.play(["bram_theme"], 0.6, true)
	await _wait(3.5)
	if _loud() != ["bram_theme"]:
		problems.append("a change during a dip left %s playing (wanted Bram's theme)" % str(_loud()))
	print("MUSIC OVERLAP: problems: ", problems if not problems.is_empty() else "none")
	print("MUSIC OVERLAP: ", "ok" if problems.is_empty() else "FAILED")
	get_tree().quit(0 if problems.is_empty() else 1)


## What can be heard now: every player playing above -45 dB.
func _loud() -> Array:
	var out: Array = []
	for i in Music._players.size():
		var p: AudioStreamPlayer = Music._players[i]
		if p.playing and p.volume_db > -45.0:
			out.append(String(Music._names[i]))
	if Music._sting.playing and Music._sting.volume_db > -45.0:
		out.append("(piece)")
	return out


func _one(when: String) -> void:
	var l := _loud()
	print("MUSIC OVERLAP: %s: %s" % [when, str(l)])
	if l.size() != 1:
		problems.append("%s: %d pieces at once %s" % [when, l.size(), str(l)])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout
