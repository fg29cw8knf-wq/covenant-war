class_name WhiteSkyDuel
extends RefCounted
## Bram's duel in the Night of the White Sky (WhiteSky): the decks, the seed
## and the computer's skill, apart from WhiteSky so tests/white_sky_probe.gd
## can play it headless (a --script run has none of the game's autoloads).

## Bram's duel: his old Ironstone (the Guardians that wall off Life: the deck
## of a man protecting something), stacked with Grondmaw GRONDMAW_AT cards
## down, against the hunter's pale hounds (Veilwild without its Summon), both
## played by the computer at SKILL. SEED is the one tests/white_sky_probe.gd
## found (3 November: seed 30, Grondmaw on turn 9): two of Bram's Totems are
## knocked out before Grondmaw comes, which is what reads as losing with no
## Life on the screen. LIFE_FLOOR keeps him standing until then.
const SEED := 30
const GRONDMAW_AT := 9
const SKILL := 1.0
const LIFE_FLOOR := [40, 0]
const TURN_MIN := 4
const TURN_MAX := 10
## How fast the filmed duel plays (DuelScreen.rate of the duel speed setting).
const FILM_SPEED := 2.5

## Bram's old Ironstone, shuffled by `seed_value`, a Basic Totem first (so the
## opening hand never reshuffles) and Grondmaw `pos` cards down.
static func bram_deck(seed_value: int, pos: int) -> Array:
	var ids: Array = DuelCards.card_list("ironstone")
	_shuffle(ids, seed_value * 7919 + 17)
	ids.erase("grondmaw")
	var basics := ids.filter(func(id): return DuelCards.CARDS[id].kind == "totem" and int(DuelCards.CARDS[id].get("tier", 1)) == 1)
	ids.erase(basics[0])
	ids.insert(0, basics[0])
	ids.insert(clampi(pos, 1, ids.size()), "grondmaw")
	return ids


## The hunter's pale hounds: Veilwild without its Summon.
static func hunter_deck(seed_value: int) -> Array:
	var ids: Array = DuelCards.card_list("veilwild")
	ids.erase("somnara")
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


## Bram twenty years ago: a seasoned duellist of the Shards, Unsworn.
static func bram_profile() -> Dictionary:
	return Lore.new_profile("Bram", "", 6)


static func hunter_profile() -> Dictionary:
	return Lore.new_profile("The hunter", "", 6)


