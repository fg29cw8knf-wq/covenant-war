class_name DuelBarks
extends RefCounted
## What a rival says out loud when something big happens (27 October, Gary:
## "add all the go battles": opponents react to big plays). A story duel
## gives its rival's own lines (spec.bark_on, DuelScreen.story_bark); a
## Lab rival, or any duel without its own, says one of these. Each event is
## said once a duel; a list means one line picked from it.
##
## The events: rival_first_fate, rival_ko_own (one of theirs falls),
## rival_kos_mine (they knock one of yours out), my_big_hit (60 or more on
## their Life), rival_life_third, my_lead, my_lethal (you have the win on
## the board), my_skill and rival_skill (a duel skill works), my_comeback
## and rival_comeback (Rallying Light), arena_event (the Circle joins in),
## rival_falls (the finishing blow, as it lands).

const GENERIC := {
	"rival_first_fate": ["Come on.", "Let's see it.", "Roll kind."],
	"rival_ko_own": ["Hm. That one cost me.", "Fine. I've others.", "You'll pay for that one."],
	"rival_kos_mine": ["One down.", "That's how it's done.", "Stay down."],
	"my_big_hit": ["That one hurt.", "Lucky.", "All right. That one landed."],
	"rival_life_third": ["Not over yet.", "I've been lower than this."],
	"my_lead": ["Don't get comfortable.", "Enjoy it while it lasts."],
	"my_lethal": ["...Go on, then.", "Well? Finish it."],
	"my_skill": ["So that's your trick.", "Clever. I'll remember that."],
	"rival_skill": ["Didn't see that coming, did you?", "A trick of mine."],
	"my_comeback": ["Your god's still with you, then.", "Don't think that saves you."],
	"rival_comeback": ["Not yet. Not yet.", "I'm not finished."],
	"arena_event": ["Listen to the Circle.", "Here it comes."],
	"rival_falls": ["Well fought.", "...Well. That's that."],
}


## One line for `event` from `lines` (a String, or a list to pick from).
static func pick(lines: Dictionary, event: String) -> String:
	var l = lines.get(event, "")
	if l is Array:
		return String(l[randi() % (l as Array).size()]) if not (l as Array).is_empty() else ""
	return String(l)
