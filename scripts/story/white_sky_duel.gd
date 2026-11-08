class_name WhiteSkyDuel
extends RefCounted
## Bram's duel in the Night of the White Sky (WhiteSky): the decks, the seed
## and the computer's skill, apart from WhiteSky so tests/white_sky_probe.gd
## can play it headless (a --script run has none of the game's autoloads).

## Bram's duel. Twenty years ago Bram had served a god for forty years (Gary,
## 4 November: "a very powerful distinguished player", and "high tier cards,
## nothing low tier"; 5 November: "top tier totems that will be under his own
## god ... cards in league with his god or its allies"), so the film cuts in
## with the duel already joined, on a set board (DuelGame.puzzle, as the
## Trial of Light is). His god is Kaethis, the Hand Before (Lore.GODS; Gary's
## yes, 6 November), and every card is Kaethis's or its allies': the Scrivener and
## the Loomwarden standing, Last Stand set, the Unspent Hour, Cut Thread and
## two Relics to hand, Aldrith's Glyph Warden and Counter Runes in the deck,
## every card of his Crystal tier or above (Rites, Relics and Wards Glimmer
## and up), Orlanthe, the Last Page, SUMMON_AT cards down his deck, and six
## Essence a turn; a god's champion pays no tribute to call a Crystal
## ("free_call"). Which god he served stays hidden (Master Script v7: his
## former master, a god of fate and destiny, comes out much later): no patron
## is named and no Divine Gift is played, and the film shows no names.
## Against him the hunter's pack, hounds and foxes of white smoke already on
## the field, Ascended too, and more coming (every Hound feeds the others'
## bite). Both played by the computer at SKILL, every attribute at its
## height. SEED decides the Fate rolls: tests/white_sky_probe.gd found one
## where Bram loses two of his Totems and breaks two of the pack before
## Orlanthe comes (seed 13, 5 November: the hunter Dooms the Scrivener at
## once; Bram's Loomwarden and Unspent Hour break the Blazehound and the
## Infernal Warg; the Scrivener and the Unspent Hour fall on the hunter's
## third turn; he calls the Weft Serpent and the Glyph Warden into the gaps;
## the Last Page on his fourth turn, the duel's 8th). LIFE_FLOOR keeps him
## standing until then.
const SEED := 13
## The Summon he calls at the end (the white is its blow), and how far down
## his deck it lies.
const SUMMON := "orlanthe"
const SUMMON_AT := 3
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
## (5 November: Kaethis's cards in place of his old Ironstone's; the Basics
## standing from the first frame, nothing stacked under them)
const BRAM_BOARD := [["scrivener"], ["loomwarden"], null]
const BRAM_HAND := ["unspent_hour", "cut_thread", "hourglass_no_sand", "knotted_cord"]
## (the Weft Serpent drawn third, so all five of his Totems are seen before
## the white: tests/white_sky_probe.gd)
const BRAM_DECK := ["already_written", "glyph_warden", "weft_serpent", "orlanthe", "doom_sigil", "foreordained", "cut_thread",
	"counter_rune", "hushed_counter", "scrivener", "knotted_cord", "glyph_warden", "foreordained", "null_sigil"]
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
		"deck": [bram_deck(SEED, SUMMON_AT), HUNTER_DECK.duplicate()],
		"wards": [BRAM_WARDS.duplicate(), HUNTER_WARDS.duplicate()],
		"no_gift": true, "synergy": ["kin", "side", "react", "chain"]}


## The story rule: a god's champion calls his Crystals without tribute.
static func story_rules() -> Dictionary:
	return {"free_call": 0}


## How fast the filmed duel plays (DuelScreen.rate of the duel speed setting).
## (3.0 until 8 November: directed as a film, its beats need a moment each.)
const FILM_SPEED := 2.2

## Bram's deck in the order it's drawn: BRAM_DECK with the Summon `pos`
## cards down (the seed shuffles nothing: a set board is written out).
static func bram_deck(_seed_value: int, pos: int) -> Array:
	var ids: Array = BRAM_DECK.duplicate()
	ids.erase(SUMMON)
	ids.insert(clampi(pos, 0, ids.size()), SUMMON)
	return ids


## The Summon's name as the duel's log says it (the film and its probe
## watch the log for it being called down).
static func summon_name() -> String:
	return String(DuelCards.CARDS[SUMMON].name)


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


