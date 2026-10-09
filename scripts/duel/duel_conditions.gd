class_name DuelConditions
extends RefCounted
## The 24 conditions and 6 boons of the v2 duel rules ("Duel Rules v2",
## Conditions). A Totem carries at most one condition of each kind (Body,
## Mind, Soul); a new one replaces the old one of the same kind. Boons don't
## take a slot and survive Ascension.
##
## turns:  how many of its owner's turns it lasts (counted down at their
##         Dusk; a condition put on during its owner's own turn doesn't count
##         that turn). 0 = until cured, broken free or used up.
## roll:   true if its owner rolls to break free at each of their Dawns
##         (d20 + the Fate modifier for the kind's attribute, needs wake_roll).

const BODY := "body"
const MIND := "mind"
const SOUL := "soul"
const KINDS := [BODY, MIND, SOUL]
## The attribute whose Fate modifier helps a Totem break free of each kind.
const KIND_ATTR := {"body": "resolve", "mind": "insight", "soul": "presence"}
const KIND_NAMES := {"body": "Body", "mind": "Mind", "soul": "Soul"}

const DEFS := {
	# ------------------------------------------------------------- Body ---
	"burn": {"name": "Burned", "short": "BURN", "kind": "body", "turns": 2, "color": "ff9a4a"},
	"poison": {"name": "Poisoned", "short": "POISON", "kind": "body", "turns": 0, "color": "9be15d"},
	"corroded": {"name": "Corroded", "short": "CORRODE", "kind": "body", "turns": 0, "color": "c6d65a"},
	"bleed": {"name": "Bleeding", "short": "BLEED", "kind": "body", "turns": 3, "color": "e0454a"},
	"frozen": {"name": "Frozen", "short": "FROZEN", "kind": "body", "turns": 0, "roll": true, "color": "9fe3ff"},
	"shocked": {"name": "Shocked", "short": "SHOCK", "kind": "body", "turns": 2, "color": "ffe066"},
	"soaked": {"name": "Soaked", "short": "SOAKED", "kind": "body", "turns": 2, "color": "5aa9ff"},
	"rooted": {"name": "Rooted", "short": "ROOTED", "kind": "body", "turns": 2, "color": "7fc25a"},
	"petrified": {"name": "Petrified", "short": "STONE", "kind": "body", "turns": 2, "color": "b8a88a"},
	"staggered": {"name": "Staggered", "short": "STAGGER", "kind": "body", "turns": 0, "color": "d7e8e0"},
	"blinded": {"name": "Blinded", "short": "BLIND", "kind": "body", "turns": 2, "color": "fff3c4"},
	# ------------------------------------------------------------- Mind ---
	"sleep": {"name": "Asleep", "short": "SLEEP", "kind": "mind", "turns": 0, "roll": true, "color": "b9a4ff"},
	"stun": {"name": "Stunned", "short": "STUN", "kind": "mind", "turns": 1, "color": "ffd23f"},
	"confused": {"name": "Confused", "short": "CONFUSED", "kind": "mind", "turns": 2, "color": "f08fd0"},
	"charmed": {"name": "Charmed", "short": "CHARMED", "kind": "mind", "turns": 1, "color": "ff8fb3"},
	"terrified": {"name": "Terrified", "short": "TERROR", "kind": "mind", "turns": 2, "color": "8e7cc3"},
	"enraged": {"name": "Enraged", "short": "RAGE", "kind": "mind", "turns": 2, "color": "ff5a36"},
	"silenced": {"name": "Silenced", "short": "SILENCE", "kind": "mind", "turns": 2, "color": "a0a6b8"},
	# ------------------------------------------------------------- Soul ---
	"possessed": {"name": "Possessed", "short": "POSSESSED", "kind": "soul", "turns": 2, "roll": true, "color": "7b5cff"},
	"hexed": {"name": "Hexed", "short": "HEX", "kind": "soul", "turns": 3, "color": "a46bff"},
	"cursed": {"name": "Cursed", "short": "CURSE", "kind": "soul", "turns": 3, "color": "6e3b8f"},
	"marked": {"name": "Marked", "short": "MARKED", "kind": "soul", "turns": 2, "color": "ff6f61"},
	"drained": {"name": "Drained", "short": "DRAIN", "kind": "soul", "turns": 2, "color": "4fd1c5"},
	"doomed": {"name": "Doomed", "short": "DOOM", "kind": "soul", "turns": 0, "color": "2b2b2b"},
}

const BOONS := {
	"shielded": {"name": "Shielded", "short": "SHIELD", "color": "8fd3ff"},
	"empowered": {"name": "Empowered", "short": "POWER", "turns": 0, "color": "ffb347"},
	"regenerating": {"name": "Regenerating", "short": "REGEN", "turns": 3, "color": "7be38f"},
	"veiled": {"name": "Veiled", "short": "VEILED", "turns": 0, "color": "c9c3e6"},
	"blessed": {"name": "Blessed", "short": "BLESSED", "turns": 2, "color": "fff1a8"},
	"hastened": {"name": "Hastened", "short": "HASTE", "turns": 2, "color": "a8fff0"},
}

## What each one does, in the words printed on the duel screen's help.
const TEXT := {
	"burn": "Takes %d damage at its owner's Dawn.",
	"poison": "Takes %d damage at its owner's Dawn until cured.",
	"corroded": "Every hit on it deals %d more, until cured.",
	"bleed": "Takes %d damage every time it attacks or Shifts.",
	"frozen": "Can't attack or Shift. Breaks free on %d or more; a Fire hit thaws it.",
	"shocked": "Each of its attacks fails on a roll of 1 to %d.",
	"soaked": "Takes %d more from Storm and Frost, and can't be Burned.",
	"rooted": "Can't Shift, and can attack only the slot opposite.",
	"petrified": "Can't attack, but takes half damage.",
	"staggered": "Its next attack deals half damage.",
	"blinded": "Each of its attacks misses on a roll of 1 to %d.",
	"sleep": "Can't attack. Wakes when an attack or Rite damages it.",
	"stun": "Skips its next attack.",
	"confused": "Each attack: on 1 to %d it Strikes its own side instead.",
	"charmed": "Can't attack the side that charmed it.",
	"terrified": "Deals half damage, and can't attack what frightened it.",
	"enraged": "Deals %d more and takes %d more; can only single out the enemy with the most HP, and can't Shift.",
	"silenced": "Can only use its free Strike.",
	"possessed": "Won't obey its owner: the opponent aims its Strike each turn.",
	"hexed": "Its stronger moves and its Ascension cost 1 more Essence.",
	"cursed": "Healing it receives deals that much damage instead.",
	"marked": "Every hit on it deals %d more.",
	"drained": "Its owner loses 1 Essence at each Dawn, and the drainer gains 1.",
	"doomed": "Knocked out at its owner's third Dawn unless cured or Ascended.",
	"shielded": "The next hit on it deals %d less.",
	"empowered": "Its next attack deals %d more.",
	"regenerating": "Heals %d at its owner's Dawn.",
	"veiled": "Can't be targeted until it attacks or its owner's next Dawn.",
	"blessed": "Can't gain new conditions.",
	"hastened": "Its stronger moves cost 1 less Essence.",
}

## id -> display name, for conditions and boons together.
const NAMES := {
	"burn": "Burned", "poison": "Poisoned", "corroded": "Corroded", "bleed": "Bleeding", "frozen": "Frozen",
	"shocked": "Shocked", "soaked": "Soaked", "rooted": "Rooted", "petrified": "Petrified",
	"staggered": "Staggered", "blinded": "Blinded", "sleep": "Asleep", "stun": "Stunned",
	"confused": "Confused", "charmed": "Charmed", "terrified": "Terrified", "enraged": "Enraged",
	"silenced": "Silenced", "possessed": "Possessed", "hexed": "Hexed", "cursed": "Cursed",
	"marked": "Marked", "drained": "Drained", "doomed": "Doomed",
	"shielded": "Shielded", "empowered": "Empowered", "regenerating": "Regenerating",
	"veiled": "Veiled", "blessed": "Blessed", "hastened": "Hastened",
}

## Conditions no boss can be given.
const BOSS_IMMUNE := ["possessed", "charmed", "doomed"]


static func is_condition(id: String) -> bool:
	return DEFS.has(id)


static func is_boon(id: String) -> bool:
	return BOONS.has(id)


static func kind_of(id: String) -> String:
	return DEFS.get(id, {}).get("kind", "")


static func display_name(id: String) -> String:
	return NAMES.get(id, id.capitalize())


static func short_name(id: String) -> String:
	if DEFS.has(id):
		return DEFS[id].short
	if BOONS.has(id):
		return BOONS[id].short
	return id.to_upper()


static func color(id: String) -> Color:
	if DEFS.has(id):
		return Color(DEFS[id].color)
	if BOONS.has(id):
		return Color(BOONS[id].color)
	return Color.WHITE


static func turns(id: String) -> int:
	if DEFS.has(id):
		return int(DEFS[id].get("turns", 0))
	return int(BOONS.get(id, {}).get("turns", 0))


static func breaks_free(id: String) -> bool:
	return bool(DEFS.get(id, {}).get("roll", false))


## The printed explanation, with this game's numbers filled in.
static func describe(id: String) -> String:
	var t: String = TEXT.get(id, "")
	if not t.contains("%d"):
		return t
	match id:
		"burn": return t % DuelRules.burn_damage
		"poison": return t % DuelRules.poison_damage
		"corroded": return t % DuelRules.corroded_bonus
		"bleed": return t % DuelRules.bleed_damage
		"shocked": return t % DuelRules.shock_fail
		"soaked": return t % DuelRules.soaked_bonus
		"blinded": return t % DuelRules.blind_fail
		"confused": return t % DuelRules.confuse_fail
		"enraged": return t % [DuelRules.enraged_bonus, DuelRules.enraged_exposed]
		"frozen": return t % DuelRules.frozen_roll
		"marked": return t % DuelRules.marked_bonus
		"shielded": return t % DuelRules.shielded_amount
		"empowered": return t % DuelRules.empowered_bonus
		"regenerating": return t % DuelRules.regen_heal
	return t
