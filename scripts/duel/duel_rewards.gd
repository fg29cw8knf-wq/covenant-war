class_name DuelRewards
extends RefCounted
## What a won duel is worth ("Duel Rules v2": Resonance, Attunement, Sigil
## Rank). No UI here: the duel screen shows the result and Game keeps the
## player's progress.

# --- Resonance -----------------------------------------------------------------
## Base Resonance by who was beaten.
const BASE := {"village": 10, "kingdom": 20, "rival": 40, "champion": 80, "boss": 100}
const KO_BASIC := 5
const KO_ASCENDED := 10
const CLEAN_MULT := 1.25       # half your starting Life or more left
const QUICK_MULT := 1.25       # won in 10 of your own turns or fewer
const QUICK_TURNS := 10
const THICK_MULT := 1.5        # a temple, a Sigilfall crater or the Convocation
const AD_MULT := 2.0           # the once-a-day rewarded ad

## Resonance needed to crystallise a card, by tier (1 Spark .. 4 Relic).
const TIER_COST := [0, 30, 80, 160, 320]
## Duels never make cards above Relic.
const MAX_RESONANCE_TIER := 4

# --- Attunement ------------------------------------------------------------------
## Points one spare copy gives its own Totem's store, by tier.
const COPY_POINTS := [0, 2, 2, 3, 6]
const ASCEND_POINTS := 6       # to manifest the Ascended card
const EXALT_POINTS := 12       # then the Exalted card
const POOL_RATE := 0.5         # pool points count half in any store

# --- Sigil Rank -------------------------------------------------------------------
const MAX_RANK := 20
const START_CAP := 4
const CAP_PER_SEAL := 2
const POINTS_PER_RANK := 2
## The Rank needed for each tier to answer you (index = tier).
const TIER_RANK := [0, 1, 3, 6, 10, 13, 16, 20]


## The breakdown of a won duel's Resonance. `opponent` is a BASE key;
## `thick` and `ad` are the multipliers that apply.
static func resonance(game: DuelGame, winner: int, opponent: String = "kingdom", thick := false, ad := false) -> Dictionary:
	var lines := []
	var base: int = BASE.get(opponent, 20)
	lines.append({"text": "Beat a %s" % _opponent_word(opponent), "add": base})
	var kos := 0
	var loser: DuelPlayer = game.players[1 - winner]
	for st in loser.fallen:
		kos += KO_ASCENDED if int(st) > 0 else KO_BASIC
	if kos > 0:
		lines.append({"text": "%d Totem%s knocked out" % [loser.fallen.size(), "" if loser.fallen.size() == 1 else "s"], "add": kos})
	var total := float(base + kos)
	var w: DuelPlayer = game.players[winner]
	if w.life * 2 >= w.max_life:
		total *= CLEAN_MULT
		lines.append({"text": "Clean win", "mult": CLEAN_MULT})
	if turns_taken(game, winner) <= QUICK_TURNS:
		total *= QUICK_MULT
		lines.append({"text": "Quick win", "mult": QUICK_MULT})
	if thick:
		total *= THICK_MULT
		lines.append({"text": "Thick magic", "mult": THICK_MULT})
	if ad:
		total *= AD_MULT
		lines.append({"text": "Doubled", "mult": AD_MULT})
	return {"total": int(round(total)), "lines": lines}


## How many turns the duellist had.
static func turns_taken(game: DuelGame, pi: int) -> int:
	var t := game.turn
	if pi == game.first_player:
		return int(ceil(t / 2.0))
	return int(floor(t / 2.0))


static func _opponent_word(opponent: String) -> String:
	match opponent:
		"village": return "village duellist"
		"kingdom": return "kingdom duellist"
		"rival": return "named rival"
		"champion": return "Champion"
		"boss": return "boss"
	return "duellist"


# --- costs and caps -----------------------------------------------------------------

static func card_cost(id: String) -> int:
	var tier := int(DuelCards.CARDS.get(id, {}).get("tier", 1))
	return TIER_COST[clampi(tier, 1, MAX_RESONANCE_TIER)]


## Can Resonance be poured into this card at this Rank? Relics only once a
## Champion or a boss has been seen playing one.
static func eligible(id: String, rank: int, codex: Dictionary) -> bool:
	if not DuelCards.CARDS.has(id) or not codex.has(id):
		return false
	var d: Dictionary = DuelCards.CARDS[id]
	var tier := int(d.get("tier", 1))
	if tier > MAX_RESONANCE_TIER or tier > tier_cap(rank):
		return false
	if d.kind == "summon" or DuelCards.is_ascension(id):
		return false   # Summons come from the story; Ascensions from Attunement
	if tier == 4 and String(codex[id]) != "champion":
		return false
	return true


## The highest tier that answers a duellist of this Rank.
static func tier_cap(rank: int) -> int:
	var cap := 1
	for tier in range(1, TIER_RANK.size()):
		if rank >= TIER_RANK[tier]:
			cap = tier
	return cap


## Rank XP needed to go from `rank` to rank + 1.
static func xp_to_next(rank: int) -> int:
	return 40 + 30 * (rank - 1)


static func rank_cap(seals: int, convocation_won := false) -> int:
	if convocation_won:
		return MAX_RANK
	return mini(MAX_RANK - 2, START_CAP + CAP_PER_SEAL * seals)


# --- Attunement ------------------------------------------------------------------

## The Ascension card a Totem manifests next ("" if none is left).
static func next_ascension(base_id: String, stage_done: int) -> String:
	var want := base_id
	for i in stage_done + 1:
		var found := ""
		for id in DuelCards.CARDS:
			var d: Dictionary = DuelCards.CARDS[id]
			if d.kind == "totem" and d.get("ascends_from", "") == want:
				found = id
				break
		if found == "":
			return ""
		want = found
	return want


static func copy_points(id: String) -> int:
	var tier := int(DuelCards.CARDS.get(id, {}).get("tier", 1))
	return COPY_POINTS[clampi(tier, 1, 4)]


static func store_needed(stage_done: int) -> int:
	return ASCEND_POINTS if stage_done == 0 else EXALT_POINTS
