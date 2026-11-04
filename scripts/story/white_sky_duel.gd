class_name WhiteSkyDuel
extends RefCounted
## Bram's duel in the Night of the White Sky (WhiteSky): the decks, the seed
## and the computer's skill, apart from WhiteSky so tests/white_sky_probe.gd
## can play it headless (a --script run has none of the game's autoloads).

## Bram's duel. Twenty years ago Bram had served a god for many years (Gary,
## 4 November: "he is a very powerful distinguished player"), so he plays like
## a champion: no Sparks to speak of, his Earth and Metal at their strongest,
## already Ascended (Cragmaul, the Ironclad Behemoth), the Quarry Golem and
## Gilded Sentinels, Relics and the hardest Wards, Grondmaw GRONDMAW_AT cards
## down, and every attribute at its height. Which god he served stays hidden
## (Master Script v7: his former master comes out much later): no patron is
## named and no Divine Gift is played, and the film shows no names. The
## hunter is stronger still: a pack of hounds and foxes of white smoke
## (HUNTER_CARDS: every Hound feeds the others' bite) and the same height. Both played by the
## computer at SKILL. SEED is the one tests/white_sky_probe.gd found (seed 7,
## Grondmaw on turn 11): both
## sides lose Totems, Bram two or more, before Grondmaw comes. LIFE_FLOOR
## keeps him standing until then.
const SEED := 7
const GRONDMAW_AT := 9
const SKILL := 1.0
const LIFE_FLOOR := [40, 0]
const TURN_MIN := 4
const TURN_MAX := 11
## How fast the filmed duel plays (DuelScreen.rate of the duel speed setting).
const FILM_SPEED := 3.0

## The deck Bram carried as a god's man.
const BRAM_CARDS := {"pebblit": 2, "brassback": 2, "boulderox": 2, "ironhide": 2,
	"cragmaul": 2, "ironclad_behemoth": 2, "quarry_golem": 2, "gilded_sentinel": 2,
	"stone_heart": 1, "iron_brace": 1, "last_stand": 1, "iron_bastion": 2,
	"iron_tithe": 1, "shieldwall_call": 1, "stone_gaze": 1, "bastion_banner": 1,
	"rune_break": 1, "counterweight": 1, "forge_edge": 1, "stone_patience": 1}


## Bram's deck, shuffled by `seed_value`, a Basic Totem first (so the
## opening hand never reshuffles) and Grondmaw `pos` cards down.
static func bram_deck(seed_value: int, pos: int) -> Array:
	var ids: Array = []
	for id in BRAM_CARDS:
		for i in int(BRAM_CARDS[id]):
			ids.append(id)
	_shuffle(ids, seed_value * 7919 + 17)
	var basics := ids.filter(func(id): return DuelCards.CARDS[id].kind == "totem" and int(DuelCards.CARDS[id].get("tier", 1)) == 1)
	ids.erase(basics[0])
	ids.insert(0, basics[0])
	ids.insert(clampi(pos, 1, ids.size()), "grondmaw")
	return ids


## The hunter's pack: hounds and foxes of white smoke (every Hound the duel
## has, the Foxes, the Hounds' own Rites, and the cruellest of the rest).
const HUNTER_CARDS := {"cinderpup": 2, "blazehound": 3, "infernal_warg": 2, "river_hound": 2,
	"shieldhound": 2, "dreamfox": 2, "veilfox": 2, "ninefold_fox": 1, "sparkkit": 2,
	"pack_howl": 2, "call_of_kin": 1, "doom_sigil": 1, "toxic_mist": 1, "siphon_rune": 1,
	"poison_trap": 1, "mirror_veil": 1, "last_stand": 1, "rite_of_ashes": 1, "thunderclap": 1}


static func hunter_deck(seed_value: int) -> Array:
	var ids: Array = []
	for id in HUNTER_CARDS:
		if DuelCards.CARDS.has(id):
			for i in int(HUNTER_CARDS[id]):
				ids.append(id)
	_shuffle(ids, seed_value * 104729 + 3)
	var basics := ids.filter(func(id): return DuelCards.CARDS[id].kind == "totem" and int(DuelCards.CARDS[id].get("tier", 1)) == 1)
	ids.erase(basics[0])
	ids.insert(0, basics[0])
	return ids


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


