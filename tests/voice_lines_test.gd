extends Node
## The voice lines' bookkeeping (scripts/story/voice_lines.gd): a line's id
## is what tools/vo_sheet.py prints for it, a film's stand-in speaks with the
## person's voice, a line with no recording waits for a tap (-1), and a
## recorded one (stubbed) holds for its length and a breath.
##   godot --headless res://tests/voice_lines_test.tscn


func _ready() -> void:
	var problems := []
	# sha1 of the words, first eight hex digits: the same as Python's hashlib
	if VoiceLines.line_id("Nobody wins anything by default while I'm stood here.") != "c5ab712b":
		problems.append("line id: %s" % VoiceLines.line_id("Nobody wins anything by default while I'm stood here."))
	# the sheet trims and collapses spaces as the game does
	if VoiceLines.line_id("  Nobody wins anything   by default while I'm stood here.\n") != "c5ab712b":
		problems.append("line id of untidy words differs")
	if VoiceLines.speaker_of("") != "narrator" or VoiceLines.speaker_of("film_wren") != "wren" or VoiceLines.speaker_of("bram") != "bram":
		problems.append("speaker folders: %s %s %s" % [VoiceLines.speaker_of(""), VoiceLines.speaker_of("film_wren"), VoiceLines.speaker_of("bram")])
	var host := Node.new()
	add_child(host)
	if VoiceLines.play(host, "bram", "A line nobody has recorded.") != -1.0:
		problems.append("an unrecorded line should return -1")
	if VoiceLines.file_for("bram", "A line nobody has recorded.") != "":
		problems.append("an unrecorded line has a file")
	# the Herald's named recording is found in the vo folder's root
	if not VoiceLines.file_for("herald", "Hear the Covenant.", "herald_01").ends_with("herald_01.ogg"):
		problems.append("herald_01 not found: '%s'" % VoiceLines.file_for("herald", "Hear the Covenant.", "herald_01"))
	VoiceLines.stub = {VoiceLines.line_id("Stubbed words."): 2.0}
	var secs := VoiceLines.play(host, "bram", "Stubbed words.")
	if absf(secs - (2.0 + VoiceLines.TAIL)) > 0.001:
		problems.append("a stubbed line holds %.2f, not %.2f" % [secs, 2.0 + VoiceLines.TAIL])
	VoiceLines.stop(host)
	VoiceLines.stub = {}
	if problems.is_empty():
		print("VOICE LINES: ok")
	else:
		print("VOICE LINES: PROBLEMS ", problems)
	get_tree().quit(0 if problems.is_empty() else 1)
