extends SceneTree
## Checks the v2 rewards: Resonance from real duels, crystallising cards,
## Rank and its cap, the Codex, and Attunement manifesting Ascension cards.
## Then projects Rank through the story's planned duels.
##
## Run: godot --headless --script res://tests/rewards_test.gd

var fails := 0


func _initialize() -> void:
	var gs = load("res://scripts/game/game_state.gd").new()
	gs.new_game("Tester", "emberstorm")
	_check(gs.rank() == 1, "starts at Rank 1")
	_check(gs.card_answers("ashen_drake"), "Bram's Crystal cards are Bonded and answer at Rank 1")
	_check(not gs.card_answers("frostbind"), "an unbonded Glimmer doesn't answer at Rank 1")

	# play real duels until the player has won 12
	var wins := 0
	var g := 0
	var made := []
	var total_res := 0
	while wins < 12 and g < 60:
		g += 1
		var game := DuelGame.new()
		game.setup(["emberstorm", "veilwild"], ["You", "Rival"], [DuelAI.new(1.0, g), DuelAI.new(0.4, g + 50)],
			[Lore.new_profile("You", "", 5), Lore.new_profile("Rival", "", 3)], 900 + g)
		await game.run()
		if game.winner != 0:
			continue
		wins += 1
		var out: Dictionary = gs.record_win(game, 0, "kingdom")
		total_res += int(out.resonance.total)
		made.append_array(out.made)
		if wins == 1:
			_check(gs.v2.codex.has("dreamfox") or gs.v2.codex.has("blightrat"), "the rival's cards enter the Codex")
			_check(String(out.target) != "", "a Resonance target is picked")
			print("  first win: %d Resonance (%s) into %s" % [out.resonance.total,
				", ".join(out.resonance.lines.map(func(l): return l.text)), out.target])
	print("  %d wins, %d Resonance, cards made: %s, Rank %d (%d xp), cap %d" % [wins, total_res, made, gs.rank(),
		gs.v2.xp, gs.rank_cap()])
	_check(not made.is_empty(), "Resonance crystallises at least one card in 12 wins")
	_check(gs.rank() <= gs.rank_cap(), "Rank never passes its cap")
	_check(gs.rank() > 1, "Rank rises")

	# a Glimmer target is eligible only once seen, and only at Rank 3+
	gs.v2.codex["frostbind"] = "seen"
	_check(DuelRewards.eligible("frostbind", 3, gs.v2.codex), "a seen Glimmer is eligible at Rank 3")
	_check(not DuelRewards.eligible("frostbind", 2, gs.v2.codex), "...but not at Rank 2")
	gs.v2.codex["doom_sigil"] = "seen"
	_check(not DuelRewards.eligible("doom_sigil", 12, gs.v2.codex), "a Relic seen from a nobody isn't eligible")
	gs.v2.codex["doom_sigil"] = "champion"
	_check(DuelRewards.eligible("doom_sigil", 12, gs.v2.codex), "a Relic seen from a Champion is")

	# Attunement: three spare Cinderpups manifest a Blazehound
	gs.v2.collection["cinderpup"] = 6     # 3 in the deck, 3 spare
	var before := int(gs.v2.collection.get("blazehound", 0))
	_check(gs.spare_copies("cinderpup") == 3, "3 spare Cinderpups")
	var got: String = gs.reabsorb("cinderpup", 3)
	_check(got == "blazehound", "3 spare Cinderpups manifest a Blazehound (got '%s')" % got)
	_check(int(gs.v2.collection.get("blazehound", 0)) == before + 1, "the Blazehound is added to the collection")
	_check(DuelRewards.next_ascension("cinderpup", 1) == "", "Cinderpup has no Exalted card yet")
	_check(gs.spare_copies("cinderpup") == 0, "the last copies are kept")

	# the pool pays at half value
	gs.v2.pool = 20
	gs.v2.collection["brookfin"] = 1
	var rs0 := int(gs.v2.collection.get("riptide_serpent", 0))
	var got1: String = gs.pour_pool("brookfin", 12)
	_check(got1 == "riptide_serpent" and int(gs.v2.collection.get("riptide_serpent", 0)) == rs0 + 1,
		"12 pool points count as 6 in Brookfin's store and manifest a Riptide Serpent (got '%s')" % got1)
	var rs_before := int(gs.v2.collection.get("riptide_serpent", 0))
	var got2: String = gs.pour_pool("brookfin", 0)
	_check(got2 == "" and int(gs.v2.pool) == 8, "pouring nothing changes nothing")

	# Rank projection through the story's planned duels (opponent kind, wins)
	var plan := [["Prologue", [["village", 2], ["kingdom", 1]], 0],
		["Chapter 1, Solhaven", [["kingdom", 8], ["rival", 2], ["champion", 1]], 1]]
	for k in 6:
		plan.append(["Kingdom %d" % (k + 1), [["kingdom", 10], ["rival", 2], ["champion", 2]], 1])
	var rank := 1
	var xp := 0
	var seals := 0
	for ch in plan:
		for row in ch[1]:
			for n in int(row[1]):
				var res := int(round((DuelRewards.BASE[row[0]] + 15) * 1.25 * (1.25 if n % 2 == 0 else 1.0)))
				xp += res
				while rank < DuelRewards.rank_cap(seals) and xp >= DuelRewards.xp_to_next(rank):
					xp -= DuelRewards.xp_to_next(rank)
					rank += 1
		seals += int(ch[2])
		print("  after %-22s Rank %2d  (cap %2d)" % [ch[0], rank, DuelRewards.rank_cap(seals)])
	print("REWARDS TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)
