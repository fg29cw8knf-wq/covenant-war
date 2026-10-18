class_name Standing
extends RefCounted
## How the gods and the people of Veyl feel about the player.
##
## Every value runs from -10 to +10 and starts at 0. Most of it comes from
## choices the story already records as flags (FLAG_EFFECTS), so a save made
## before this existed picks it up too. Anything else is a direct nudge kept in
## Game.standing (Game.shift_standing, or a {"standing": {"tam": 1}} step in a
## dialogue). A story step can test it with {"if": "standing:solmaris>=2"}.
##
## Swearing to a god adds PATRON_BONUS to that god.

const LOW := -10
const HIGH := 10
const PATRON_BONUS := 4

## The people who can hold an opinion of the player, once met.
## look: the paper-doll / portrait id. role: one line under the name.
const PEOPLE := {
	"bram": {"name": "Bram", "role": "Your guardian. Keeper of the Crooked Lantern.", "look": "bram"},
	"corin": {"name": "Corin", "role": "Ashford's self-declared best duellist.", "look": "corin"},
	"tam": {"name": "Tam", "role": "Ashford farmer. Generous with the cider.", "look": "farmer"},
	"tilly": {"name": "Tilly", "role": "Tam's daughter. Owner of one Lantern Moth.", "look": "child"},
	"nell": {"name": "Old Nell", "role": "Ashford's oldest memory.", "look": "elder"},
	"ned": {"name": "Ned", "role": "Fiddler. Knows one reel, three ways.", "look": "fiddler"},
	"hob": {"name": "Hob", "role": "Miller. Grows suspiciously early cabbages.", "look": "hob"},
	"hale": {"name": "Warden Hale", "role": "Keeps Solhaven's Golden Gate.", "look": "guard"},
	"wren": {"name": "Wren", "role": "A thief who goes where the money is.", "look": "wren"},
	"refugees": {"name": "The refugees", "role": "Families from the burned villages, at Solhaven's gate.", "look": "farmer"},
	"aldric": {"name": "Ser Aldric Vane", "role": "Solhaven's Champion.", "look": "aldric"},
}

## Old ids a person's standing was once kept under (Ned the fiddler was
## Seamus before Master Script v3), still read as theirs from old saves.
const OLD_IDS := {"ned": ["seamus"]}

## Choices the story already remembers, and what they mean to whom.
## value: only when the flag holds that value (for flags that store a word).
const FLAG_EFFECTS := [
	{"flag": "ash_tam", "who": "tam", "by": 1, "why": "You gave Tam a hand with the cider barrel."},
	{"flag": "ash_tilly", "who": "tilly", "by": 2, "why": "You woke Tilly's Lantern Moth for her."},
	{"flag": "ash_nell", "who": "nell", "by": 1, "why": "You sat with Old Nell while the village danced."},
	{"flag": "ash_won_lantern", "who": "corin", "by": 1, "why": "You beat Corin in the Lantern Duel, fair and square."},
	{"flag": "let_refugees_in", "who": "refugees", "by": 3, "why": "You got the refugees through Solhaven's gate."},
	{"flag": "beat_wren", "who": "wren", "by": 1, "why": "You beat Wren, and she keeps her deals."},
	{"flag": "solmaris_favour", "value": "unsure", "who": "solmaris", "by": 1, "why": "You told Solmaris you'd think about kneeling."},
	{"flag": "solmaris_favour", "value": "defiant", "who": "solmaris", "by": -2, "why": "You told Solmaris you kneel to no one."},
]


## The player's standing with a god or a person.
static func value(who: String) -> int:
	var v := int(Game.standing.get(who, 0))
	for old in OLD_IDS.get(who, []):
		v += int(Game.standing.get(old, 0))
	for e in FLAG_EFFECTS:
		if e.who == who and _flag_matches(e):
			v += int(e.by)
	if String(Game.profile.get("patron", "")) == who:
		v += PATRON_BONUS
	return clampi(v, LOW, HIGH)


## Why they feel that way: the story moments that moved it, oldest first.
static func reasons(who: String) -> Array:
	var out := []
	for e in FLAG_EFFECTS:
		if e.who == who and _flag_matches(e):
			out.append(String(e.why))
	for r in Game.standing_log:
		var rw := String(r.get("who", ""))
		if (rw == who or (OLD_IDS.get(who, []) as Array).has(rw)) and String(r.get("why", "")) != "":
			out.append(String(r.why))
	if String(Game.profile.get("patron", "")) == who:
		out.append("You swore yourself to %s." % Lore.GODS[who].name)
	return out


static func _flag_matches(e: Dictionary) -> bool:
	var f = Game.flags.get(e.flag, null)
	if f == null or (f is bool and not f):
		return false
	if e.has("value"):
		return String(f) == String(e.value)
	return true


## The FLAG_EFFECTS entry a newly set flag triggers, or {} (for the
## "Tilly will remember that." line).
static func effect_of(flag: String, v) -> Dictionary:
	for e in FLAG_EFFECTS:
		if e.flag != flag:
			continue
		if e.has("value") and String(v) != String(e.value):
			continue
		return e
	return {}


static func is_god(who: String) -> bool:
	return Lore.GODS.has(who)


static func display_name(who: String) -> String:
	if is_god(who):
		return Lore.GODS[who].name
	return String(PEOPLE.get(who, {}).get("name", who.capitalize()))


## One word for where things stand.
static func level_name(who: String) -> String:
	var v := value(who)
	if is_god(who):
		if v <= -6: return "Hostile"
		if v <= -2: return "Displeased"
		if v <= 1: return "Watching"
		if v <= 5: return "Pleased"
		if v <= 9: return "Favoured"
		return "Chosen"
	if v <= -6: return "Hostile"
	if v <= -2: return "Wary"
	if v <= 1: return "Acquainted"
	if v <= 5: return "Friendly"
	if v <= 9: return "Trusted"
	return "Devoted"


## The people the player has met, in the order of PEOPLE.
static func people_met() -> Array:
	var out := []
	for id in PEOPLE:
		if Game.flag("met_" + id) or value(id) != 0:
			out.append(id)
	return out


## For story conditions: "standing:tilly>=2", "standing:solmaris<0".
static func check(cond: String) -> bool:
	var body := cond.trim_prefix("standing:")
	for op in [">=", "<=", ">", "<", "=="]:
		var i := body.find(op)
		if i > 0:
			var who := body.substr(0, i)
			var n := int(body.substr(i + op.length()))
			var v := value(who)
			match op:
				">=": return v >= n
				"<=": return v <= n
				">": return v > n
				"<": return v < n
				"==": return v == n
	return false
