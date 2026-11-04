class_name WhiteSkyDuel
extends RefCounted
## Bram's duel in the Night of the White Sky (WhiteSky): the decks, the seed
## and the computer's skill, apart from WhiteSky so tests/white_sky_probe.gd
## can play it headless (a --script run has none of the game's autoloads).

## Bram's duel. Twenty years ago Bram had served a god for many years (Gary,
## 4 November: "a very powerful distinguished player", and "high tier cards,
## nothing low tier"), so the film cuts in with the duel already joined, on a
## set board (DuelGame.puzzle, as the Trial of Light is): Bram's Cragmaul and
## Ironclad Behemoth already Ascended and standing, Last Stand set, the Quarry
## Golem and Gilded Sentinels, Relics and Rites to hand, every card of his
## Crystal tier or above (Rites and Relics Glimmer and up), Grondmaw
## GRONDMAW_AT cards down his deck, and six Essence a turn; a god's champion
## pays no tribute to call a Crystal ("free_call"). Which god he served stays
## hidden (Master Script v7: his former master, a god of fate and destiny not
## yet in the game, comes out much later): no patron is named and no Divine
## Gift is played, and the film shows no names. Against him the hunter's pack,
## hounds and foxes of white smoke already on the field, Ascended too, and
## more coming (every Hound feeds the others' bite). Both played by the
## computer at SKILL, every attribute at its height. SEED decides the Fate
## rolls: tests/white_sky_probe.gd found one where Bram loses two of his
## Totems and breaks one of the pack before Grondmaw comes. LIFE_FLOOR keeps
## him standing until then.
const SEED := 2
const GRONDMAW_AT := 3
const SKILL := 1.0
const LIFE_FLOOR := [40, 0]
const TURN_MIN := 4
const TURN_MAX := 11
## The hunter strikes first; Bram answers.
const FIRST := 1
const LIFE := [600, 600]
const ESSENCE := [6, 6]
## Bram's side: the board (a stack is what the Totem rose from, then the one
## standing), his hand, his deck in the order it's drawn, his Wards set.
const BRAM_BOARD := [["boulderox", "cragmaul"], ["ironhide", "ironclad_behemoth"], null]
const BRAM_HAND := ["quarry_golem", "stone_heart", "stone_gaze", "iron_tithe"]
const BRAM_DECK := ["shieldwall_call", "gilded_sentinel", "bastion_banner", "grondmaw", "rune_break", "quarry_golem",
	"iron_brace", "counterweight", "gilded_sentinel", "stone_patience", "stone_heart", "iron_tithe", "shieldwall_call", "bastion_banner"]
const BRAM_WARDS := ["last_stand"]
## The hunter's pack.
const HUNTER_BOARD := [["cinderpup", "blazehound"], ["cinderpup", "blazehound", "infernal_warg"], ["dreamfox", "veilfox"]]
const HUNTER_HAND := ["river_hound", "pack_howl", "doom_sigil", "shieldhound"]
const HUNTER_DECK := ["call_of_kin", "sparkkit", "toxic_mist", "cinderpup", "siphon_rune", "dreamfox", "pack_howl",
	"thunderclap", "river_hound", "rite_of_ashes", "mirror_veil", "shieldhound", "cinderpup", "sparkkit"]
const HUNTER_WARDS := ["poison_trap"]


## The set board, for DuelGame.puzzle (DuelScreen spec.puzzle and the probe).
static func board() -> Dictionary:
	return {"first": FIRST, "life": LIFE.duplicate(), "essence_max": ESSENCE.duplicate(),
		"board": [BRAM_BOARD.duplicate(true), HUNTER_BOARD.duplicate(true)],
		"hand": [BRAM_HAND.duplicate(), HUNTER_HAND.duplicate()],
		"deck": [bram_deck(SEED, GRONDMAW_AT), HUNTER_DECK.duplicate()],
		"wards": [BRAM_WARDS.duplicate(), HUNTER_WARDS.duplicate()],
		"no_gift": true, "synergy": ["kin", "side", "react", "chain"]}


## The story rule: a god's champion calls his Crystals without tribute.
static func story_rules() -> Dictionary:
	return {"free_call": 0}


## How fast the filmed duel plays (DuelScreen.rate of the duel speed setting).
const FILM_SPEED := 3.0

## Bram's deck in the order it's drawn: BRAM_DECK with Grondmaw `pos`
## cards down (the seed shuffles nothing: a set board is written out).
static func bram_deck(_seed_value: int, pos: int) -> Array:
	var ids: Array = BRAM_DECK.duplicate()
	ids.erase("grondmaw")
	ids.insert(clampi(pos, 0, ids.size()), "grondmaw")
	return ids


static func hunter_deck(_seed_value: int) -> Array:
	return HUNTER_DECK.duplicate()


static func _shuffle(ids: Array, s: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = s
	for i in range(ids.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t


## Bram twenty years ago: every attribute at its height. (No patron named:
## his god stays a secret; at 9 the Unsworn's +1 takes each to 10.)
static func bram_profile() -> Dictionary:
	return Lore.new_profile("Bram", "", 9)


static func hunter_profile() -> Dictionary:
	return Lore.new_profile("The hunter", "", 9)


