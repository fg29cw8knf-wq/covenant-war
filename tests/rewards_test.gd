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
	await _new_game_checks()
	print("REWARDS TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)


## New Game has no cards; Bram's Spark deck, the Deck and Codex unlocks, a
## win with almost nothing, the save round trip and an old save in Ashford.
func _new_game_checks() -> void:
	const SPARK := ["brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask", "healing_draught",
		"bulwark", "essence_flask", "healing_draught", "essence_flask", "bulwark", "travellers_pack"]
	var gs = load("res://scripts/game/game_state.gd").new()
	gs.new_game("Sprout", "")
	gs.area = "ashford"
	_check(gs.v2.deck.is_empty() and gs.v2.collection.is_empty() and gs.v2.codex.is_empty(), "New Game starts with no cards")
	_check(not gs.unlocked("deck") and not gs.unlocked("codex"), "Deck and Codex start locked in Ashford")
	_check(not gs.deck.is_empty(), "the old-rules deck is still there for Solhaven's prototype duels")
	var heard := []
	gs.feature_unlocked.connect(func(f: String) -> void: heard.append(f))
	gs.give_first_deck(SPARK)
	_check(gs.v2.deck.size() == 12 and int(gs.v2.collection.get("essence_flask", 0)) == 4, "the Spark deck is the deck and in the collection")
	_check(gs.v2.codex.size() == 5 and gs.v2.bonded.has("brookfin") and gs.flag("first_deck"), "...Bonded, in the Codex, flag first_deck")
	_check(not gs.has_deck(), "...but it isn't a full deck to edit")
	_check(gs.unlock("deck") and gs.unlock("codex") and not gs.unlock("deck"), "unlock() is new once")
	_check(heard == ["deck", "codex"] and gs.unlocked("codex"), "unlocking tells the world (got %s)" % [heard])
	# a win with a nearly empty collection: the Codex fills and Resonance has a target
	var game := DuelGame.new()
	game.setup(["emberstorm", "veilwild"], ["You", "Rival"], [DuelAI.new(1.0, 7), DuelAI.new(0.2, 8)],
		[Lore.new_profile("You", "", 5), Lore.new_profile("Rival", "", 2)], 77)
	await game.run()
	var out: Dictionary = gs.record_win(game, 0, "village")
	_check(gs.v2.codex.size() > 5 and String(out.target) != "", "a win adds the cards seen and picks a Resonance target")
	# save and load (as JSON, without touching the save file)
	var data = JSON.parse_string(JSON.stringify(gs.save_data()))
	var gs2 = load("res://scripts/game/game_state.gd").new()
	gs2.load_data(data)
	_check(gs2.unlocked("deck") and gs2.flag("first_deck") and gs2.v2.deck.size() == 12, "features and the Spark deck survive a save")
	# the Prologue's deck choice keeps the Spark cards, the lessons and the unlocks
	gs.learn("Your pack:1", "Your pack", "Bram", "A line.")
	gs.new_game("Ash", "tidegrove", true)
	gs.set_flag("bram_deck")
	_check(gs.v2.deck.size() == 30 and gs.has_deck() and gs.learned("Your pack:1"), "Bram's deck replaces the Spark deck, lessons kept")
	_check(int(gs.v2.collection.get("travellers_pack", 0)) >= 1 and gs.unlocked("codex"), "the Spark cards stay in the collection")
	# an old save in Ashford from before this change: no cards, Deck and Codex locked
	var old: Dictionary = data.duplicate(true)
	old.version = 1
	old.v2.deck = DuelCards.card_list("emberstorm")
	old.flags = {"arrived_ashford": true}
	old.features = {}
	var gs3 = load("res://scripts/game/game_state.gd").new()
	gs3.load_data(old)
	_check(gs3.v2.deck.is_empty() and gs3.v2.collection.is_empty() and not gs3.unlocked("deck"), "an old Ashford save starts with no cards")
	for g in [gs, gs2, gs3]:
		g.free()


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)
