class_name Prologue
extends RefCounted
## The Prologue's gifts and its two duels on the Thornwood road (Master
## Script v3, P5): the practice round with Bram on the second morning, and
## Dask's sworn wager on the second night. The Prologue itself is a film in
## the game's own 3D (scripts/world/areas/ashford.gd and thornwood.gd).

## Hob's nine Sparks, from his cabbages (skimmed across the river).
const HOB_SPARKS := ["mossling", "mossling", "sparkkit", "sparkkit", "emberwisp", "shellguard", "bloomsprite", "burrowmole", "somnowl"]

## Dask's duel rule, as the duel's banner shows it.
## (Master Script v7: +2 Attack for every turn that passes, in the game's tens.)
const RUN_TO_GROUND := ["Run to Ground", "Dask's hounds hit 10 harder for every round that passes."]


## Hob's nine Sparks join the collection (once): at the river, the night
## Ashford burns.
static func hob_sparks() -> void:
	if Game.flag("hob_gift"):
		return
	Game.set_flag("hob_gift")
	_give(HOB_SPARKS)


## What the Prologue gives besides Bram's deck, once the deck is chosen at the
## campfire: Tilly's Lantern Moth if an old save hasn't had it yet, and Hob's
## Sparks if they somehow weren't given at the river.
static func prologue_gifts() -> void:
	if Game.flag("has_lantern_moth") and not Game.flag("moth_given"):
		Game.set_flag("moth_given")
		_give(["lantern_moth"])
	# (v7: Hob keeps his cabbage Sparks; nothing is skimmed across a river)


static func _give(ids: Array) -> void:
	var v: Dictionary = Game.v2
	for id in ids:
		if not DuelCards.CARDS.has(id):
			continue
		v.collection[id] = int(v.collection.get(id, 0)) + 1
		v.bonded[id] = true
		if not v.codex.has(id):
			v.codex[id] = "seen"


## The practice round on the second morning: Bram, with one of his own old
## decks (whichever of his four the player didn't take). It can be lost; the
## story goes on either way. Bram explains each new thing the first time it
## appears (spec.lessons), as he would at any duel he's at.
## The deck Bram picks against the player's by the fire (Gary, 23 October:
## "after you pick your deck from Bram he should pick one to battle you
## with"): the one that shows the player's deck its weakness, by the
## element chart (Lore.ELEMENTS), so the lesson lands. Fire is put out by
## Tide (Ironstone beats Emberstorm harder still, by the chart, but
## tests/fire_sim.tscn had a learner losing three in four to it); Tide and
## Verdant are poisoned (Venom); Earth is worn down by Tide and Verdant; and
## Veilwild's tricks, which nothing of his beats outright, meet the deck
## that gives them no time.
const BRAM_PICKS := {"emberstorm": "tidegrove", "tidegrove": "veilwild", "ironstone": "tidegrove", "veilwild": "emberstorm"}
## What he says of his pick, by the player's deck.
const BRAM_PICK_LINES := {
	"emberstorm": "Tidegrove, against yours. Fire hates water. Better you learn that from me by a fire than from a stranger on a road.",
	"tidegrove": "Veilwild, against yours. Poison in the water, and your Totems asleep while it works. You'd best see it coming once.",
	"ironstone": "Tidegrove, against yours. Water wears stone down. It only takes patience, and I've more of that than you.",
	"veilwild": "Emberstorm, against yours. Tricks need time. Emberstorm doesn't give you any.",
}


## How hard he plays each pairing (the computer's strength, 0..1):
## tests/fire_sim.tscn plays a learner (0.3) against him: about one win in
## three for the others, and Emberstorm against Tidegrove two in three at
## 0.3, so that one is firmer.
const BRAM_STRENGTH := {"emberstorm": 0.4, "tidegrove": 0.3, "ironstone": 0.3, "veilwild": 0.25}


static func bram_pick(mine: String) -> String:
	return String(BRAM_PICKS.get(mine, "ironstone" if mine != "ironstone" else "tidegrove"))


## Bram's duel by the fire (v3's practice round, moved to the campfire 23
## October, straight after the deck choice and the pack tour; not optional,
## and it can be lost): the second gated lesson duel. Bram plays the deck
## that shows the player's its weakness (bram_pick), and teaches, once each
## the first time it matters, the tiers, Rites, Shift, the Fate bands and
## everything the Lantern Duel left (spec.lessons, DuelTutor.lesson).
static func practice_duel_spec(mine: String) -> Dictionary:
	var spare := bram_pick(mine)
	var deck: Array = Game.v2.get("deck", []) if not Game.v2.get("deck", []).is_empty() else DuelCards.card_list(mine)
	var bram := Lore.new_profile("Bram", "", 3)
	return {
		"decks": [deck.duplicate(), DuelCards.card_list(spare)],
		"names": [Game.player_name, "Bram"],
		"profiles": [Game.profile, bram],
		"ai": [false, true],
		"difficulty": float(BRAM_STRENGTH.get(mine, 0.3)),
		"arena": "tidegrove",
		# (28 October) a shelter in the woods is no god's Circle: no card is
		# Graced or Shunned for the ground (the Tidegrove look is only a look)
		"place_god": "-",
		"story": true,
		"lessons": true,   # Bram explains each new thing once: tiers, Rites, Shift, Fate bands, conditions, Wards, Ascension
		"rewards": {"opponent": "village"},
		# v7: no experience until Dask; and two glimpses of Bram's past
		"practice": true,
		"practice_line": "Bram's lesson: no experience is won or lost.",
		"bark_on": {
			# 28 October (synergy): what he says when the ways cards work together show
			"rival_kin": "Two of a kind, on my side. Watch what they do for each other.",
			"rival_reaction": "Fire and water don't sit quietly together. Remember that.",
			"rival_ward_springs": "I watched a Ward like that take a man's whole line, once. A pass above Glyphmere, snow to the knees. He never saw it. No. That's not a story for tonight. Again.",
			"my_ascends": "I raised a Cinderpup once into something you'd not believe. Gave it to a girl in a town that was burning, so she'd have something to hold. Eat your bread.",
		},
		"title": "The shelter · Bram",
	}


## The Road (v3 P5): Dask's sworn wager, his whole deck against the blank card.
## Duel rule Run to Ground (DuelGame._rule_run_to_ground); his barks are tied
## to what happens on the board; losing it is played again after his line for
## winning and Morrowen's (spec.retry, StoryLoss). Bram coaches from the
## roadside, one line as each new thing first appears (spec.lessons).
static func road_duel_spec() -> Dictionary:
	var me: String = Game.starter if DuelCards.DECKS.has(Game.starter) else "emberstorm"
	var deck: Array = Game.v2.get("deck", []) if not Game.v2.get("deck", []).is_empty() else DuelCards.card_list(me)
	var dask := Lore.new_profile("Dask", "", 4)
	Lore.add_attribute(dask, "cunning", 1)
	return {
		"decks": [deck.duplicate(), DuelCards.card_list("dask_hounds")],
		"names": [Game.player_name, "Dask"],
		"profiles": [Game.profile, dask],
		"ai": [false, true],
		"difficulty": 0.5,
		"arena": "ironstone",
		"place_god": "-",   # (28 October: a road, nobody's ground)
		"story": true,
		"retry": true,
		"lessons": true,
		"story_rules": {"run_to_ground": 1},
		"rule": RUN_TO_GROUND,
		"bark_on": {
			"rival_kin": "My pack hunts together. Always has.",
			"rival_reaction": "Steel finds the wound. Every time.",
			"my_reaction": "Huh. Where'd a farm kid learn that?",
			"rival_first_fate": "Come on. Come on.",
			"rival_poisons": "Poison's slow. I can wait.",
			"rival_ward_springs": "Didn't see the trap? Nobody does.",
			"my_lethal": "Don't. Don't do that.",
		},
		"win_line": "Mam. Mam, it's —",
		"rewards": {"opponent": "rival"},
		"title": "The Road · Dask",
	}
