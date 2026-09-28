extends SceneTree
## Headless test: plays many AI-vs-AI duels and checks the rules never break.
## Run:  godot --headless --script res://tests/sim.gd -- [games] [deck ids...]
## With no decks given, every deck in SigilDB.DECKS plays every other one,
## and both duellists get a patron god (rotating through all seven + Unsworn).

const PATRONS := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var games := 200
	if args.size() > 0:
		games = int(args[0])
	var decks: Array = []
	if args.size() > 2:
		decks = args.slice(1)
	else:
		decks = SigilDB.DECKS.keys()
	for d in decks:
		var probs := SigilDB.deck_problems(SigilDB.card_list(d))
		if not probs.is_empty():
			print("DECK PROBLEM ", d, ": ", probs)

	var wins := {}
	var played := {}
	var patron_wins := {}
	var patron_played := {}
	var first_wins := 0
	var turns_total := 0
	var reasons := {}
	var errors := 0
	var draws := 0
	var matchup := {}
	var gifts_used := 0
	var summons := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for g in games:
		var a: String = decks[g % decks.size()]
		var b: String = decks[(g / decks.size()) % decks.size()]
		var pa: String = PATRONS[rng.randi() % PATRONS.size()]
		var pb: String = PATRONS[rng.randi() % PATRONS.size()]
		var profiles := [_profile("P1", pa, a), _profile("P2", pb, b)]
		var game := BattleGame.new()
		game.setup([a, b], ["P1", "P2"], [AIController.new(), AIController.new()], profiles, 1000 + g)
		var checker := Checker.new(game)
		game.state_changed.connect(checker.check)
		await game.run()
		errors += checker.errors
		turns_total += game.turn
		for line in game.log_lines:
			if " calls on " in line:
				gifts_used += 1
			if " calls down " in line:
				summons += 1
		var r: String = game.win_reason
		reasons[r] = int(reasons.get(r, 0)) + 1
		played[a] = int(played.get(a, 0)) + 1
		played[b] = int(played.get(b, 0)) + 1
		var pk := [pa if pa != "" else "unsworn", pb if pb != "" else "unsworn"]
		patron_played[pk[0]] = int(patron_played.get(pk[0], 0)) + 1
		patron_played[pk[1]] = int(patron_played.get(pk[1], 0)) + 1
		if game.winner == 2:
			draws += 1
		elif game.winner >= 0:
			var wd: String = [a, b][game.winner]
			var ld: String = [a, b][1 - game.winner]
			wins[wd] = int(wins.get(wd, 0)) + 1
			patron_wins[pk[game.winner]] = int(patron_wins.get(pk[game.winner], 0)) + 1
			if game.winner == game.first_player:
				first_wins += 1
			if wd != ld:
				var k := wd + " > " + ld
				matchup[k] = int(matchup.get(k, 0)) + 1
		if checker.errors > 0:
			print("Game ", g, " (", a, " v ", b, ") errors: ", checker.messages)
	print("=== %d duels, avg %.1f turns, %d draws, %d invariant errors, first player won %.0f%%, %d gifts, %d summons ===" % [
		games, float(turns_total) / games, draws, errors, 100.0 * first_wins / max(1, games - draws), gifts_used, summons])
	for d in decks:
		print("  %-18s win rate %3.0f%%  (%d duels)" % [d, 100.0 * wins.get(d, 0) / max(1, played.get(d, 0)), played.get(d, 0)])
	for p in patron_played:
		print("  patron %-10s win rate %3.0f%%  (%d)" % [p, 100.0 * patron_wins.get(p, 0) / max(1, patron_played[p]), patron_played[p]])
	var rk := reasons.keys()
	rk.sort()
	for k in rk:
		print("  ending: ", k, " x", reasons[k])
	quit(1 if errors > 0 else 0)


func _profile(n: String, patron: String, deck_id: String) -> Dictionary:
	var p := Lore.new_profile(n, patron)
	var bonus: Dictionary = SigilDB.DECKS[deck_id].get("attributes", {})
	for k in bonus:
		Lore.add_attribute(p, k, int(bonus[k]))
	return p


class Checker:
	var game: BattleGame
	var errors := 0
	var messages := []

	func _init(g) -> void:
		game = g

	func check() -> void:
		for p in game.players:
			var n: int = p.total_card_count()
			if n != 40:
				_err("player %d has %d cards" % [p.index, n])
			if p.bench.size() > BattleGame.BENCH_MAX:
				_err("bench overflow")
			if p.energy_attached > p.energy_limit:
				_err("too much energy attached this turn")
			var uids := {}
			for zone in [p.deck, p.hand, p.discard, p.prizes, p.limbo]:
				for c in zone:
					if uids.has(c.uid):
						_err("duplicate card " + c.id)
					uids[c.uid] = true
			for cr in p.in_play():
				if cr.damage < 0:
					_err("negative damage")
				if cr.stack.is_empty() or not cr.top().is_creature():
					_err("bad stack")
				for e in cr.energy:
					if not e.is_energy():
						_err("non-energy attached")
				for c in cr.all_cards():
					if uids.has(c.uid):
						_err("duplicate card in play " + c.id)
					uids[c.uid] = true
				if cr.special != "" and cr.status_immune():
					_err("immune totem has a condition: " + cr.special)

	func _err(m: String) -> void:
		errors += 1
		if messages.size() < 5:
			messages.append("t%d: %s" % [game.turn, m])
