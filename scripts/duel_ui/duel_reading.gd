class_name DuelReading
extends RefCounted
## How long the words in a duel stay up (29 October, Gary: "The text in the
## battles goes by very quickly not enough to read what it says needs to be a
## fraction longer"). One setting, Reading time (Options, and the duel's own
## Menu; Game.settings.duel_reading):
##
##   Normal (the new default)  every timed word in a duel stays up 1.6 times
##                             as long as it did, and never less than a
##                             reader needs for its words: 0.9 s and 0.3 s a
##                             word (at most 5 s; a longer line is in How to
##                             Duel or the log to read again)
##   Slow                      2.2 times as long, 1.3 s and 0.42 s a word
##
## It covers the banners, a move's name as it's used, the damage and
## condition words, the toasts, the rival's barks, a Fate roll's result, a
## Rite's or Ward's card held up in the middle, Light Fingers, the crowd,
## an answer, a skill's note. The pure animation waits (a creature lunging,
## a card flying) are as they were, so the duel keeps its pace. Faster
## battle speeds still shorten the words, but by less than the animation
## (the square root of the speed), so even at Fastest they can be read.

const LEVELS := {
	"normal": {"name": "Normal", "mult": 1.6, "base": 0.9, "per_word": 0.3, "cap": 5.0},
	"slow": {"name": "Slow", "mult": 2.2, "base": 1.3, "per_word": 0.42, "cap": 7.5},
}
const ORDER := ["normal", "slow"]


static func key() -> String:
	var k := String(Game.settings.get("duel_reading", "normal"))
	return k if LEVELS.has(k) else "normal"


static func level() -> Dictionary:
	return LEVELS[key()]


static func label() -> String:
	return String(level().name)


static func set_level(k: String) -> void:
	if LEVELS.has(k):
		Game.settings["duel_reading"] = k
		Game.save_settings()


## The next setting along (the duel Menu's button cycles them).
static func next_key() -> String:
	return ORDER[(ORDER.find(key()) + 1) % ORDER.size()]


static func mult() -> float:
	return float(level().mult)


## The words in a line: the runs with a letter in them ("TURN 5" is one,
## "-40" none).
static func words(text: String) -> int:
	var n := 0
	for w in text.replace("\n", " ").split(" ", false):
		for ch in w:
			if ch.to_lower() != ch.to_upper():
				n += 1
				break
	return n


## The least time a reader needs for a line, in seconds.
static func floor_secs(text: String) -> float:
	var lv := level()
	return minf(float(lv.base) + float(lv.per_word) * words(text), float(lv.cap))


## How long a timed line stays up, in seconds, for something that doesn't
## follow the battle speed (a toast, a bark, a note): its old hold made
## longer, and never less than the reader needs.
static func secs(hold: float, text: String) -> float:
	return maxf(hold * mult(), floor_secs(text))
