extends SceneTree
## Checks Shards (3 November): the wallet, forging a card from the Codex, who
## can be forged, a won duel's spill, Sigilfall shards and their daily cap,
## side quests paying once, spare copies with nothing left to feed turning
## into Shards, and a save keeping it all. Then a pacing check: how much
## Shards add to a chapter's card income on top of duels (Gary: "make sure
## cards aren't got too quickly"; the aim is about a fifth to a third more,
## never more).
##
## Run: godot --headless --script res://tests/shards_test.gd

var fails := 0


func _initialize() -> void:
	var gs = load("res://scripts/game/game_state.gd").new()
	gs.new_game("Tester", "emberstorm")
	var v: Dictionary = gs.v2

	# --- the wallet
	_check(gs.shards() == 0, "a new game has no Shards")
	gs.add_shards(25)
	_check(gs.shards() == 25, "Shards go into the wallet")

	# --- forging: only what's needed, a copy when the bank is full, no Rank XP
	var id := "cinderpup"
	var cost := DuelRewards.card_cost(id)
	var owned := int(v.collection.get(id, 0))
	var xp := int(v.xp)
	_check(gs.can_forge(id), "a card of your own can be forged")
	var r: Dictionary = gs.forge(id)
	_check(int(r.poured) == 25 and String(r.made) == "" and int(v.banked[id]) == 25, "25 Shards poured into a %d-cost card bank 25 (got %s)" % [cost, r])
	gs.add_shards(100)
	r = gs.forge(id)
	_check(String(r.made) == id and int(r.poured) == cost - 25, "the next forge pours only what's needed and crystallises a copy")
	_check(int(v.collection[id]) == owned + 1, "the copy is in the collection")
	_check(gs.shards() == 125 - cost, "the rest stays in the wallet (%d)" % gs.shards())
	_check(int(v.xp) == xp, "forging gives no Rank experience")
	_check(not v.banked.has(id), "the bank is empty again")

	# --- who can be forged: the same cards a win can build towards
	_check(not gs.can_forge("frostbind"), "a card never seen can't be forged")
	v.codex["frostbind"] = "seen"
	_check(not gs.can_forge("frostbind"), "a Glimmer doesn't answer at Rank 1, so it can't be forged")
	v.rank = 3
	_check(gs.can_forge("frostbind"), "...and can be at Rank 3")
	v.rank = 1
	for sid in DuelCards.CARDS:
		if DuelCards.CARDS[sid].kind == "summon":
			v.codex[sid] = "champion"
			_check(not gs.can_forge(sid), "a Summon (%s) can't be forged" % sid)
			break
	# the PvP-only flag (no card carries it yet): the rule's own words
	var fake := {"kind": "totem", "tier": 1, "pvp_only": true}
	_check(DuelRewards.pvp_only(fake) and not DuelRewards.pvp_only(DuelCards.CARDS[id]), "a card marked pvp_only is a PvP prize (eligible() refuses it); ordinary cards aren't")

	# --- a won duel spills a tenth of its Resonance (never in the Prologue)
	_check(DuelRewards.shard_spill(0) == 0 and DuelRewards.shard_spill(4) == 1 and DuelRewards.shard_spill(37) == 4, "the spill is a tenth, rounded, at least 1")
	var game: DuelGame = await _won_duel(gs)
	var before: int = gs.shards()
	var out: Dictionary = gs.record_win(game, 0, "kingdom")
	_check(int(out.shards) == 0 and gs.shards() == before, "no spill in the Prologue (before Dask is beaten)")
	gs.set_flag("beat_hunter")
	game = await _won_duel(gs)
	before = gs.shards()
	out = gs.record_win(game, 0, "kingdom")
	var want := DuelRewards.shard_spill(int(out.resonance.total))
	_check(int(out.shards) == want and gs.shards() == before + want, "a won duel after the Prologue spills %d Shards (%d Resonance)" % [want, int(out.resonance.total)])

	# --- Sigilfall shards: once a spot a day, a daily cap, back the next day
	var got := [0]
	gs.shards_gained.connect(func(n, _why) -> void: got[0] += n)
	var day := "2026-11-03"
	before = gs.shards()
	_check(gs.collect_sigilfall("solhaven:a", 3, day) == 3, "a Sigilfall shard gives its Shards")
	_check(gs.collect_sigilfall("solhaven:a", 3, day) == 0, "...once a day")
	_check(not gs.sigilfall_here("solhaven:a", day), "and it's gone for the day")
	var total := 3
	for i in 10:
		total += gs.collect_sigilfall("solhaven:s%d" % i, 3, day)
	_check(total == DuelRewards.SIGILFALL_DAILY_CAP, "a day's Sigilfall shards stop at the cap (%d, got %d)" % [DuelRewards.SIGILFALL_DAILY_CAP, total])
	_check(not gs.sigilfall_here("solhaven:s9", day), "with the cap reached none is left that day")
	_check(gs.sigilfall_here("solhaven:a", "2026-11-04") and gs.collect_sigilfall("solhaven:a", 3, "2026-11-04") == 3, "they come back the next day")
	_check(got[0] == total + 3, "each pick-up is announced (shards_gained)")
	# the spots in the world each hold 2 to 5
	var spots_all: Dictionary = _spots()
	for area in spots_all:
		for s in spots_all[area]:
			_check(int(s[2]) >= 2 and int(s[2]) <= 5, "%s:%s holds 2 to 5" % [area, s[0]])

	# --- side quests: Shards once, when they're finished
	before = gs.shards()
	gs.set_flag("side_fen", "pending")
	_check(gs.shards() == before, "a side quest part-way gives nothing")
	gs.set_flag("side_fen", "won")
	_check(gs.shards() == before + int(DuelRewards.QUEST_SHARDS.side_fen), "finishing it gives its Shards")
	gs.set_flag("side_fen", "beaten")
	_check(gs.shards() == before + int(DuelRewards.QUEST_SHARDS.side_fen), "...only once")
	gs.set_flag("side_pip", "seen")
	_check(gs.shards() == before + int(DuelRewards.QUEST_SHARDS.side_fen), "Pip's errand only seen gives nothing")
	for q in DuelRewards.QUEST_SHARDS:
		var n := int(DuelRewards.QUEST_SHARDS[q])
		_check(n >= 15 and n <= 40, "%s gives 15 to 40 (%d)" % [q, n])

	# --- spare copies with nothing left to feed turn into Shards
	var t := "cinderpup"
	v.collection[t] = 8
	v.deck = [t, t, t]
	v.stage[t] = 9           # every Ascension already manifested
	_check(DuelRewards.next_ascension(t, 9) == "", "nothing left for Cinderpup to manifest")
	v["temper"] = {t: 2}
	_check(not gs.spare_is_shards(t), "not yet fully Tempered: a spare still Tempers")
	gs.reabsorb(t, 1)
	_check(gs.temper_of(t) == 3 and gs.spare_is_shards(t), "Tempered three times now")
	before = gs.shards()
	var spare: int = gs.spare_copies(t)
	gs.reabsorb(t, 2)
	_check(gs.shards() == before + 2 * DuelRewards.copy_shards(t), "two spares give %d Shards each" % DuelRewards.copy_shards(t))
	_check(gs.spare_copies(t) == spare - 2, "and leave the collection")
	_check(DuelRewards.copy_shards(t) == int(ceil(DuelRewards.card_cost(t) / 10.0)), "a spare is worth a tenth of its cost")

	# --- a save keeps it all
	var gs2 = load("res://scripts/game/game_state.gd").new()
	gs2.load_data(JSON.parse_string(JSON.stringify(gs.save_data())))
	_check(gs2.shards() == gs.shards(), "the wallet survives a save (%d)" % gs2.shards())
	_check(not gs2.sigilfall_here("solhaven:a", "2026-11-04"), "the day's Sigilfall pick-ups survive a save")
	_check(gs2.v2.get("quest_shards", {}).has("side_fen"), "a paid side quest stays paid after a save")
	# an old save without Shards loads with none
	var old: Dictionary = gs.save_data()
	(old.v2 as Dictionary).erase("shards")
	gs2.load_data(JSON.parse_string(JSON.stringify(old)))
	_check(gs2.shards() == 0, "an old save starts with no Shards")
	gs.free()
	gs2.free()

	_pacing()
	print("shards_test: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)


## How much Shards add to a chapter's cards, on top of what duels make.
## A chapter, as Chapter 1 runs: 12 story wins (2 village duellists, 5 of a
## kingdom's, 3 named rivals, a Champion and a boss), about three Totems
## knocked out each, and the usual bonuses on about a third of the wins; its
## five side stories; and the Sigilfall shards over the days it's played.
func _pacing() -> void:
	var wins := {"village": 2, "kingdom": 5, "rival": 3, "champion": 1, "boss": 1}
	var res := 0.0
	var spill := 0
	for k in wins:
		for i in int(wins[k]):
			var r := int(round((int(DuelRewards.BASE[k]) + 3 * DuelRewards.KO_BASIC) * 1.3))
			res += r
			spill += DuelRewards.shard_spill(r)
	var quests := 0
	for q in DuelRewards.QUEST_SHARDS:
		quests += int(DuelRewards.QUEST_SHARDS[q])
	var spots := 0
	for s in _spots().solhaven:
		spots += int(s[2])
	var a_day := mini(spots, DuelRewards.SIGILFALL_DAILY_CAP)
	var avg_cost := (DuelRewards.TIER_COST[1] + DuelRewards.TIER_COST[2] + DuelRewards.TIER_COST[3]) / 3.0
	print("  pacing: a chapter's 12 wins make %d Resonance, about %.1f cards (average cost %d)" % [res, res / avg_cost, avg_cost])
	for p in [["just the story (no side stories, the Sigilfalls on 1 day)", 0, 1],
			["a usual player (every side story, 3 days)", quests, 3],
			["a keen player (every side story, the Sigilfalls every day for a week)", quests, 7]]:
		var sh: int = spill + int(p[1]) + a_day * int(p[2])
		var pct := 100.0 * sh / res
		print("  %s: +%d Shards (%d spilled, %d side stories, %d Sigilfalls) = +%.1f cards, %.0f%% more" % [
			p[0], sh, spill, int(p[1]), a_day * int(p[2]), sh / avg_cost, pct])
		if String(p[0]).begins_with("a usual"):
			_check(pct >= 18.0 and pct <= 32.0, "a usual player's Shards add 20 to 30%% to a chapter's cards (%.0f%%)" % pct)
		if String(p[0]).begins_with("a keen"):
			_check(pct <= 45.0, "even a keen player's add under half (%.0f%%)" % pct)


## The world's Sigilfall spots (loaded when asked, after the autoloads are up).
func _spots() -> Dictionary:
	return load("res://scripts/world/sigil_shards.gd").SPOTS


## A real duel the player has won (the AI plays both sides).
func _won_duel(gs) -> DuelGame:
	for g in 40:
		var game := DuelGame.new()
		game.setup(["emberstorm", "veilwild"], ["You", "Rival"], [DuelAI.new(1.0, g), DuelAI.new(0.3, g + 50)],
			[Lore.new_profile("You", "", 5), Lore.new_profile("Rival", "", 3)], 700 + g)
		await game.run()
		if game.winner == 0:
			return game
	return null


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
	print("  [%s] %s" % ["ok" if ok else "FAIL", what])
