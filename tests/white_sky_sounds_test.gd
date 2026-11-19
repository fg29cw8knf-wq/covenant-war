extends Node
## Gary's own voice lines, sounds and end music for the Night of the White
## Sky (18 November): each of Bram's eight lines is found by its words and
## loads; each sound is found by its name with all its takes, loads, and is
## about as long as the moment it's for; his end music is there and isn't a
## loop. "list" prints each one's length, and how loud its loudest fifth of
## a second is beside the stand-in it replaces.
##   godot --headless res://tests/white_sky_sounds_test.tscn [-- list]
## Ends "WHITE SKY SOUNDS: ok" or the problems.

const LINES := [
	"Come on then, Sprout.", "Hold them off. Just a little longer.",
	"Get back from him.", "Not yet. Not yet.", "You'll not have him.",
	"Write it in my name, then.",
]
## (19 November) lines whose words changed, waiting for Gary's new recording:
## shown by "list", not counted as problems till they're made.
const TO_RECORD := [
	["bram", "Hush now, little one. I've got you."], ["bram", "Shh, little one. I've got you."],
	["bram", "Buy me some time. That's all I need."],
	["morrowen", "The child's death was already written in my book. The Last Page could save him... but only by writing another name in its place."],
	["morrowen", "He walked out of the Shardlands with the child in his coat, and the child's death in his own name."],
	["morrowen", "But a death that is moved is never paid in full. It gathers interest."],
	["morrowen", "Twenty years later, the Age came to its end... and every debt in my book came due."],
]
## Each sound: how many takes, and the shortest and longest it may be (s).
const SOUNDS := {
	"baby_coo": [3, 0.4, 2.0], "child_tune": [1, 5.0, WhiteSky.TUNE_SECS + 1.0], "mark_wake": [1, 1.5, 4.0],
	"circle_draw": [1, 1.5, 4.0], "ice_ring": [3, 1.5, 4.5], "ice_crack": [2, 0.4, 2.0], "ice_shatter": [1, 1.0, 3.0],
	"hunter_burn": [1, 1.5, 4.0], "light_wave": [1, 1.0, 3.5],
}


func _ready() -> void:
	var show := "list" in OS.get_cmdline_user_args()
	var bad := []
	for words: String in LINES:
		var path := VoiceLines.file_for("bram", words)
		if path == "":
			bad.append("Bram's \"%s\" has no recording (%s)" % [words, VoiceLines.line_id(words)])
			continue
		var s: AudioStream = load(path)
		if s == null:
			bad.append("%s doesn't load" % path)
		elif s.get_length() < 0.6 or s.get_length() > 6.0:
			bad.append("\"%s\" is %.1f s long" % [words, s.get_length()])
		elif show:
			print("  %-40s %s  %.2f s" % ["\"%s\"" % words, path.get_file(), s.get_length()])
	for pair: Array in TO_RECORD:
		var made := VoiceLines.file_for(String(pair[0]), String(pair[1])) != ""
		if show:
			print("  %-9s %s  %s" % [String(pair[0]), VoiceLines.line_id(String(pair[1])), "recorded" if made else "to record"])
	for nm: String in SOUNDS:
		var want: Array = SOUNDS[nm]
		for i in int(want[0]):
			var take := nm if i == 0 else "%s_%d" % [nm, i + 1]
			if not Sfx.has_file(take):
				bad.append("%s has no file" % take)
				continue
			var s := Sfx.get_stream(take)
			if s == null:
				bad.append("%s doesn't load" % take)
				continue
			if s.get_length() < float(want[1]) or s.get_length() > float(want[2]):
				bad.append("%s is %.2f s long (%.1f to %.1f wanted)" % [take, s.get_length(), float(want[1]), float(want[2])])
			if show:
				print("  %-14s %.2f s%s" % [take, s.get_length(), _stand_in(nm) if i == 0 else ""])
	# (the takes are what the game picks from)
	if Sfx.has_file("ice_ring_4") or Sfx.has_file("baby_coo_4"):
		bad.append("a fourth take the list above doesn't know of")
	if not Music.has("white_sky_end"):
		bad.append("the end music (white_sky_end) isn't there")
	else:
		var m: AudioStream = load(Music.path_for("white_sky_end"))
		var total := WhiteSky.FIN_HOLD + WhiteSky.FIN_PACK_SECS + WhiteSky.FIN_HUNTER_SECS + WhiteSky.FIN_LAST + 1.5
		if show:
			print("  white_sky_end  %.2f s (the end of the duel, from the blow to the white: %.2f s)" % [m.get_length(), total])
		if m.get_length() < 4.0 or m.get_length() > total + 1.0:
			bad.append("the end music is %.1f s long; the end of the duel is %.1f s" % [m.get_length(), total])
	if bad.is_empty():
		print("WHITE SKY SOUNDS: ok (%d lines, %d sounds, the end music)" % [LINES.size(), SOUNDS.size()])
	else:
		for b in bad:
			print("  problem: ", b)
		print("WHITE SKY SOUNDS: %d problems" % bad.size())
	get_tree().quit(0 if bad.is_empty() else 1)


## How loud the made-up stand-in for a sound was (the peak and the loudest
## fifth of a second of what Sfx._synth makes), for the list.
func _stand_in(nm: String) -> String:
	if not (nm in ["ice_ring", "ice_crack", "ice_shatter", "mark_wake", "circle_draw", "child_tune"]):
		return ""
	var w := Sfx._synth(nm)
	var n := w.data.size() / 2
	var win := int(Sfx.RATE * 0.2)
	var top := 0.0
	var best := 0.0
	var acc := 0.0
	var q: Array[float] = []
	for i in n:
		var v := w.data.decode_s16(i * 2) / 32768.0
		top = maxf(top, absf(v))
		acc += v * v
		q.append(v * v)
		if q.size() > win:
			acc -= q[q.size() - win - 1]
		if i >= win:
			best = maxf(best, acc / win)
	return "   (its stand-in: %.2f s, peak %.2f, loudest fifth of a second %.3f)" % [float(n) / Sfx.RATE, top, sqrt(best)]
