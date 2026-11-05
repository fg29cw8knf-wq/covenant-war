extends SceneTree
## Checks crowns (5 November): the purse, what a won story duel pays by its
## kind (none in the Prologue), the forty-crown choices in Solhaven's side
## stories (greyed with too few, paying takes them), Tamsin's stall (three
## sealed caches a day from the cards in reach, prices by tier, buying, the
## day's restock, dearer after the Trial, the crier's free cache), and saves,
## old ones with no purse included. Then the numbers: what a player has by the
## Golden Knight.
##
## Run: godot --headless --script res://tests/crowns_test.gd

const SIDE := "res://scripts/world/areas/solhaven/solhaven_side.gd"

var fails := 0


func _initialize() -> void:
	await process_frame   # (the autoloads up: the side stories read Game)
	var gs = load("res://scripts/game/game_state.gd").new()
	gs.new_game("Tester", "emberstorm")
	var v: Dictionary = gs.v2

	# --- the purse
	_check(gs.crowns() == 0, "a new game has an empty purse")
	var said := [0]
	gs.crowns_gained.connect(func(n, _why) -> void: said[0] += n)
	gs.add_crowns(12, "test")
	_check(gs.crowns() == 12 and said[0] == 12, "crowns go into the purse, and the HUD is told")
	_check(not gs.spend_crowns(13) and gs.crowns() == 12, "spending more than's there takes nothing")
	_check(gs.spend_crowns(5) and gs.crowns() == 7, "spending takes them")
	_check(not gs.spend_crowns(-3) and gs.crowns() == 7, "a negative spend does nothing")
	gs.add_crowns(0, "nothing")
	gs.add_crowns(-4)
	_check(gs.crowns() == 7, "adding nothing or less changes nothing")

	# --- what a won duel pays, by its kind
	for k in DuelRewards.CROWNS:
		var r: Array = DuelRewards.CROWNS[k]
		_check(int(r[0]) <= int(r[1]), "%s pays %d to %d" % [k, r[0], r[1]])
	_check(DuelRewards.CROWNS.lesson == [0, 0], "a lesson pays nothing")
	_check(DuelRewards.CROWNS.early == [3, 5] and DuelRewards.CROWNS.normal == [6, 10] and DuelRewards.CROWNS.big == [15, 25],
		"early story 3-5, normal 6-10, big moments 15-25")
	_check(DuelRewards.duel_crowns("big", "kingdom", null, 0) == 15 and DuelRewards.duel_crowns("", "village", null, 0) == 3,
		"without a game, the least; with no kind named, the opponent's (a village duellist: early)")
	var game: DuelGame = await _won_duel()
	_check(game != null, "a won duel to pay for")
	var before: int = gs.crowns()
	var out: Dictionary = gs.record_win(game, 0, "kingdom", false, false, "normal")
	_check(int(out.crowns) == 0 and gs.crowns() == before, "no crowns in the Prologue (before Dask is beaten)")
	gs.set_flag("beat_hunter")
	for k in ["lesson", "early", "normal", "big"]:
		before = gs.crowns()
		out = gs.record_win(game, 0, "kingdom", false, false, k)
		var r: Array = DuelRewards.CROWNS[k]
		_check(int(out.crowns) >= int(r[0]) and int(out.crowns) <= int(r[1]) and gs.crowns() == before + int(out.crowns),
			"a won %s duel pays %d (%d to %d)" % [k, int(out.crowns), r[0], r[1]])
	before = gs.crowns()
	out = gs.record_win(game, 0, "champion")
	_check(int(out.crowns) >= 15, "a Champion with no kind named pays a big moment's (%d)" % int(out.crowns))
	# Clean and Quick each move it half the way up
	var w: DuelPlayer = game.players[0]
	var clean := w.life * 2 >= w.max_life
	var quick := DuelRewards.turns_taken(game, 0) <= DuelRewards.QUICK_TURNS
	var want := 6 + (2 if clean else 0) + (2 if quick else 0)
	_check(DuelRewards.duel_crowns("normal", "", game, 0) == want, "a normal win, %s and %s, pays %d" % ["clean" if clean else "not clean", "quick" if quick else "not quick", want])
	# the story's duels name their kind
	var duels = load("res://scripts/world/solhaven/duels.gd")
	var side = load(SIDE)
	var game_node = root.get_node("Game")   # (the autoload: the story reads it)
	game_node.new_game("Tester", "emberstorm")
	_check(String(duels.hale_spec().rewards.crowns) == "early", "Hale at the gate: early story")
	_check(String(duels.wren_spec().rewards.crowns) == "normal", "Wren in the alley: normal")
	_check(String(duels.trial_spec().rewards.crowns) == "normal", "the Trial of Light: normal")
	_check(String(duels.aldric_spec().rewards.crowns) == "big", "Ser Aldric, the Golden Knight: a big moment")
	_check(String(side.duel_spec("pip").rewards.crowns) == "normal", "a side story's sworn wager: normal")

	# --- the forty-crown choices
	game_node.v2["crowns"] = 12
	var opt = side._pay_option("I'll pay it.")
	_check(opt is Dictionary and bool(opt.off) and String(opt.text) == "I'll pay it. (40 crowns — you have 12)", "with 12 in the purse the Temple's price is greyed: %s" % [opt])
	opt = side._pay_option("Pay his fine.")
	_check(opt is Dictionary and String(opt.text) == "Pay his fine. (40 crowns — you have 12)", "and so is the Sergeant's fine")
	game_node.v2["crowns"] = 47
	opt = side._pay_option("I'll pay it.")
	_check(opt is String and String(opt) == "I'll pay it. (40 crowns)", "with 47 it's offered as before: %s" % [opt])
	side._pay()
	_check(game_node.crowns() == 7, "paying takes forty (7 left)")
	# the dialogue box greys it, and it can't be picked
	var box = load("res://scripts/ui/dialogue_box.gd").new()   # (loaded now: it reads Game)
	root.add_child(box)
	await process_frame
	var picked := [-1]
	var ask := func() -> void: picked[0] = await box.choose(["Swear.", {"text": "I'll pay it. (40 crowns — you have 7)", "off": true}, "Don't."])
	ask.call()
	await process_frame
	var b0 := box._choices.get_child(0) as Button
	var b1 := box._choices.get_child(1) as Button
	_check(b1.disabled and not b0.disabled and b1.text.ends_with("you have 7)"), "the dialogue box shows the greyed answer, disabled")
	_check(b1.focus_mode == Control.FOCUS_NONE, "and the arrows pass it by")
	b0.pressed.emit()
	await process_frame
	_check(picked[0] == 0, "the other answers still answer")
	box.queue_free()

	# --- Tamsin's stall
	var day := "2026-11-05"
	v.rank = 3   # (Glimmers answer)
	var caches: Array = gs.stall_caches(day)
	_check(caches.size() == DuelRewards.CACHES_A_DAY, "three caches on the counter (%d)" % caches.size())
	var reach := DuelArchetypes.in_reach(1, 3)
	var ids := []
	for c in caches:
		var id := String(c.id)
		ids.append(id)
		var d: Dictionary = DuelCards.CARDS[id]
		_check(reach.has(id), "%s is one a won duel could hand out by now" % id)
		_check(d.kind != "summon" and not DuelCards.is_ascension(id) and not DuelRewards.pvp_only(d), "%s isn't a Summon, an Ascension or a PvP prize" % id)
		_check(int(d.tier) < 4, "no Relic before the first Seal (%s is a %s)" % [id, Lore.TIER_NAMES[int(d.tier)]])
		_check(not bool(c.sold), "%s is sealed" % id)
	_check(ids.size() == _uniq(ids).size(), "three different cards")
	_check(gs.stall_caches(day) == caches, "the same counter all day")
	# every card the counter could ever hold is one it may sell
	for ch in [1, 2, 3]:
		for rk in [1, 3, 6, 10]:
			var rng := RandomNumberGenerator.new()
			rng.seed = ch * 100 + rk
			for id in DuelArchetypes.sealed_caches({}, ch, rk, 40, rng):
				var d: Dictionary = DuelCards.CARDS[id]
				if d.kind == "summon" or DuelCards.is_ascension(id) or DuelRewards.pvp_only(d) or int(d.tier) > DuelRewards.tier_cap(rk) or (int(d.tier) >= 4 and ch < 2):
					_check(false, "chapter %d, Rank %d: %s shouldn't be on the counter" % [ch, rk, id])
	# prices by tier, dearer after the Trial
	_check(DuelRewards.CACHE_PRICE[1] == 8 and DuelRewards.CACHE_PRICE[2] == 15 and DuelRewards.CACHE_PRICE[3] == 30, "Spark 8, Glimmer 15, Crystal 30")
	for i in caches.size():
		_check(gs.cache_price(i, day) == DuelRewards.CACHE_PRICE[int(DuelCards.CARDS[caches[i].id].tier)], "%s is priced by its tier (%d)" % [caches[i].id, gs.cache_price(i, day)])
	gs.set_flag("c6_done")
	_check(DuelRewards.cache_price("cinderpup", true) == 12 and DuelRewards.cache_price("frostbind", true) == 23, "after the Trial everything's half as much again (a Spark 12, a Glimmer 23)")
	_check(gs.cache_price(0, day) == DuelRewards.cache_price(String(caches[0].id), true), "and the counter's prices go up")
	gs.set_flag("c6_done", false)
	# buying
	gs.v2["crowns"] = 0
	var price: int = gs.cache_price(0, day)
	_check(gs.buy_cache(0, false, day) == "" and not bool(caches[0].sold), "an empty purse buys nothing")
	gs.add_crowns(price + 3)
	var got_id: String = gs.buy_cache(0, false, day)
	_check(got_id == String(caches[0].id), "buying the first cache gives its card (%s)" % got_id)
	_check(gs.crowns() == 3, "and takes its price (%d)" % price)
	_check(int(v.collection.get(got_id, 0)) >= 1 and v.codex.has(got_id), "the card is owned, and in the Codex")
	_check(bool(caches[0].sold) and gs.buy_cache(0, false, day) == "", "a sold cache can't be bought again")
	# the crier's cache: one from the same counter, free
	var free_id: String = gs.buy_cache(1, true, day)
	_check(free_id == String(caches[1].id) and gs.crowns() == 3, "the crier's cache is free (%s)" % free_id)
	gs.buy_cache(2, true, day)
	gs.stall_one_more(day)
	caches = gs.stall_caches(day)
	_check(caches.size() == 4 and not bool(caches[3].sold) and not ids.has(String(caches[3].id)), "a sold-out counter gets one more for the crier")
	# the next day: a fresh counter
	var next: Array = gs.stall_caches("2026-11-06")
	var none_sold := true
	for c in next:
		none_sold = none_sold and not bool(c.sold)
	_check(next.size() == 3 and none_sold, "the next day, three fresh caches")

	# --- saves
	var gs2 = load("res://scripts/game/game_state.gd").new()
	gs2.load_data(JSON.parse_string(JSON.stringify(gs.save_data())))
	_check(gs2.crowns() == gs.crowns(), "the purse survives a save (%d)" % gs2.crowns())
	_check(gs2.stall_caches("2026-11-06") == gs.stall_caches("2026-11-06"), "and so does the day's counter")
	var old: Dictionary = gs.save_data()
	(old.v2 as Dictionary).erase("crowns")
	(old.v2 as Dictionary).erase("stall")
	old.flags["paid_temple"] = true
	gs2.load_data(JSON.parse_string(JSON.stringify(old)))
	_check(gs2.crowns() == 0, "an old save starts with an empty purse")
	_check(gs2.stall_caches(day).size() == 3, "and finds Tamsin's counter stocked")
	_check(bool(gs2.flag("paid_temple")), "an old save's paid flag still stands")
	gs.free()
	gs2.free()

	_numbers()
	print("crowns_test: %s (%d failed)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(1 if fails > 0 else 0)


## The crowns a player has by the Golden Knight (Ser Aldric, C6), and what
## they buy at Tamsin's.
func _numbers() -> void:
	var kinds := {"Hale (the gate)": "early", "Wren (the alley)": "normal", "the Trial of Light": "normal"}
	var lo := 0
	var hi := 0
	for k in kinds:
		var r: Array = DuelRewards.CROWNS[kinds[k]]
		lo += int(r[0])
		hi += int(r[1])
		print("  %s: %s, %d to %d crowns" % [k, kinds[k], r[0], r[1]])
	# the Trial of Light is a set board won in three turns at full Life: always Clean and Quick
	var trial := int(DuelRewards.CROWNS.normal[1])
	lo += trial - int(DuelRewards.CROWNS.normal[0])
	var big: Array = DuelRewards.CROWNS.big
	var side: Array = DuelRewards.CROWNS.normal
	print("  by the Golden Knight's duel (the main story): %d to %d crowns; beating him: +%d to %d, so %d to %d" % [lo, hi, big[0], big[1], lo + int(big[0]), hi + int(big[1])])
	print("  each side story's wager won: +%d to %d (the Sergeant, Fen and Pip can come before him: up to +%d)" % [side[0], side[1], 3 * int(side[1])])
	print("  Tamsin's prices: Spark %d, Glimmer %d, Crystal %d (after the Trial %d, %d, %d)" % [
		DuelRewards.cache_price("cinderpup"), DuelRewards.cache_price("frostbind"), DuelRewards.CACHE_PRICE[3],
		DuelRewards.cache_price("cinderpup", true), DuelRewards.cache_price("frostbind", true), int(ceil(DuelRewards.CACHE_PRICE[3] * DuelRewards.DEARER))])
	_check(lo >= 15 and hi <= 40, "the story alone doesn't reach forty crowns before the Golden Knight (%d to %d)" % [lo, hi])


func _uniq(a: Array) -> Array:
	var out := []
	for x in a:
		if not out.has(x):
			out.append(x)
	return out


## A real duel the player has won (the AI plays both sides).
func _won_duel() -> DuelGame:
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
