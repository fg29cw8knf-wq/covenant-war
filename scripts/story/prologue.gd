class_name Prologue
extends RefCounted
## The Prologue's gifts and its two duels on the Thornwood road (Master
## Script v3, P5): the practice round with Bram on the second morning, and
## Dask's sworn wager on the second night. The Prologue itself is a film in
## the game's own 3D (scripts/world/areas/ashford.gd and thornwood.gd).

## Hob's nine Sparks, from his cabbages (skimmed across the river).
const HOB_SPARKS := ["mossling", "mossling", "sparkkit", "sparkkit", "emberwisp", "shellguard", "bloomsprite", "burrowmole", "somnowl"]

## Dask's duel rule, as the duel's banner shows it.
const RUN_TO_GROUND := ["Run to Ground", "Dask's hounds always attack the Totem with the least Life left."]


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
	hob_sparks()


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
static func practice_duel_spec(mine: String) -> Dictionary:
	var spare := "ironstone" if mine != "ironstone" else "tidegrove"
	var deck: Array = Game.v2.get("deck", []) if not Game.v2.get("deck", []).is_empty() else DuelCards.card_list(mine)
	var bram := Lore.new_profile("Bram", "", 3)
	return {
		"decks": [deck.duplicate(), DuelCards.card_list(spare)],
		"names": [Game.player_name, "Bram"],
		"profiles": [Game.profile, bram],
		"ai": [false, true],
		"difficulty": 0.35,
		"arena": "tidegrove",
		"story": true,
		"lessons": true,   # Bram explains the first condition, Ward or Ascension, once
		"rewards": {"opponent": "village"},
		"title": "A practice round · Bram",
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
		"story": true,
		"retry": true,
		"lessons": true,
		"story_rules": {"run_to_ground": 1},
		"rule": RUN_TO_GROUND,
		"bark_on": {
			"rival_first_fate": "Come on. Come on.",
			"rival_poisons": "Poison's slow. I can wait.",
			"rival_ward_springs": "Didn't see the trap? Nobody does.",
			"my_lethal": "Don't. Don't do that.",
		},
		"win_line": "Mam. Mam, it's —",
		"rewards": {"opponent": "rival"},
		"title": "The Road · Dask",
	}
