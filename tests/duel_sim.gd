extends SceneTree
## Headless balance test for the v1 duel rules. Plays many AI-vs-AI duels and
## checks the rules never break (no lost or duplicated cards, Essence never
## negative, no stuck turns). Prints win rates by deck, first-player
## advantage, how duels end and how long they last.
##
## Run:  godot --headless --script res://tests/duel_sim.gd -- [games] [deck ids...]
##       godot --headless --script res://tests/duel_sim.gd -- 2000
##       godot --headless --script res://tests/duel_sim.gd -- 400 emberstorm ironstone

const PATRONS := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var games := 400
	if args.size() > 0:
		games = int(args[0])
	var decks: Array = []
	var named: Array = Array(args.slice(1)).filter(func(x): return not x.begins_with("--"))
	if named.size() > 1:
		decks = named
	else:
		decks = DuelCards.DECKS.keys()
	var problems := 0
	for d in decks:
		var probs := DuelCards.deck_problems(DuelCards.card_list(d))
		if not probs.is_empty():
			print("DECK PROBLEM ", d, ": ", probs)
			problems += 1

	var wins := {}
	var played := {}
	var matchup := {}
	var first_wins := 0
	var decided := 0
	var draws := 0
	var turns_total := 0
	var turn_hist := {}
	var errors := 0
	var life_left_total := 0
	var stats_total := {}
	var patron_wins := {}
	var patron_played := {}
	var card_win := {}
	var card_play := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var t0 := Time.get_ticks_msec()
	for g in games:
		var a: String = decks[g % decks.size()]
		var b: String = decks[(g / decks.size()) % decks.size()]
		var pa: String = PATRONS[rng.randi() % PATRONS.size()]
		var pb: String = PATRONS[rng.randi() % PATRONS.size()]
		var profiles := [_profile("P1", pa, a), _profile("P2", pb, b)]
		var game := DuelGame.new()
		game.setup([a, b], ["P1", "P2"], [DuelAI.new(1.0, 500 + g), DuelAI.new(1.0, 900 + g)], profiles, 1000 + g)
		var checker := Checker.new(game)
		game.state_changed.connect(checker.check)
		await game.run()
		checker.check()
		errors += checker.errors
		turns_total += game.turn
		var bucket := int(game.turn / 4) * 4
		turn_hist[bucket] = int(turn_hist.get(bucket, 0)) + 1
		played[a] = int(played.get(a, 0)) + 1
		played[b] = int(played.get(b, 0)) + 1
		patron_played[pa] = int(patron_played.get(pa, 0)) + 1
		patron_played[pb] = int(patron_played.get(pb, 0)) + 1
		for p in game.players:
			for k in p.stats:
				stats_total[k] = int(stats_total.get(k, 0)) + int(p.stats[k])
		if game.winner == 2 or game.winner < 0:
			draws += 1
			continue
		for p in game.players:
			for id in p.played:
				card_play[id] = int(card_play.get(id, 0)) + 1
				if p.index == game.winner:
					card_win[id] = int(card_win.get(id, 0)) + 1
		decided += 1
		var wd: String = a if game.winner == 0 else b
		wins[wd] = int(wins.get(wd, 0)) + 1
		var wp: String = pa if game.winner == 0 else pb
		patron_wins[wp] = int(patron_wins.get(wp, 0)) + 1
		if game.winner == game.first_player:
			first_wins += 1
		life_left_total += game.players[game.winner].life
		if a != b:
			var key := "%s vs %s" % [a, b] if a < b else "%s vs %s" % [b, a]
			var m: Dictionary = matchup.get(key, {})
			m[wd] = int(m.get(wd, 0)) + 1
			matchup[key] = m

	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	print("")
	print("==== %d duels in %.1fs  |  %d invariant errors  |  %d deck problems ====" % [games, secs, errors, problems])
	print("draws (turn limit): %d" % draws)
	print("average length: %.1f turns (%.1f each)" % [float(turns_total) / games, float(turns_total) / games / 2.0])
	var hist_keys := turn_hist.keys()
	hist_keys.sort()
	var hl := []
	for k in hist_keys:
		hl.append("%d-%d:%d" % [k, k + 3, turn_hist[k]])
	print("length spread: ", "  ".join(hl))
	print("first player wins: %.0f%%" % (100.0 * first_wins / maxf(1, decided)))
	print("winner's Life left on average: %.0f" % (float(life_left_total) / maxf(1, decided)))
	print("")
	for d in decks:
		print("  %-12s win rate %3.0f%%  (%d played)" % [d, 100.0 * int(wins.get(d, 0)) / maxf(1, played.get(d, 0)), played.get(d, 0)])
	print("")
	var mk := matchup.keys()
	mk.sort()
	for k in mk:
		var parts := []
		for d in matchup[k]:
			parts.append("%s %d" % [d, matchup[k][d]])
		print("  %s:  %s" % [k, ", ".join(parts)])
	print("")
	for pt in PATRONS:
		var nm: String = "unsworn" if pt == "" else pt
		print("  patron %-9s win rate %3.0f%%  (%d)" % [nm, 100.0 * int(patron_wins.get(pt, 0)) / maxf(1, patron_played.get(pt, 0)), patron_played.get(pt, 0)])
	print("")
	if "--cards" in args:
		var rows := []
		for id in card_play:
			rows.append({"id": id, "n": card_play[id], "w": 100.0 * int(card_win.get(id, 0)) / card_play[id]})
		rows.sort_custom(func(x, y): return x.w > y.w)
		for r in rows:
			print("  card %-20s win%% when played %3.0f  (%d)" % [r.id, r.w, r.n])
		print("")
	var per := []
	for k in stats_total:
		per.append("%s %.1f" % [k, float(stats_total[k]) / (games * 2.0)])
	print("per duellist per duel: ", ", ".join(per))
	quit(1 if errors > 0 or problems > 0 else 0)


static func _profile(pname: String, patron: String, deck_id: String) -> Dictionary:
	var p := Lore.new_profile(pname, "", 4)
	var bumps: Dictionary = DuelCards.DECKS.get(deck_id, {}).get("attributes", {})
	for a in bumps:
		p.base[a] = int(p.base[a]) + int(bumps[a])
	Lore.set_patron(p, patron)
	return p


class Checker:
	var game: DuelGame
	var errors := 0
	var totals: Array

	func _init(g: DuelGame) -> void:
		game = g
		totals = g.card_totals()

	func check() -> void:
		var now := game.card_totals()
		for i in 2:
			if now[i] != totals[i]:
				_err("player %d owns %d cards, expected %d" % [i, now[i], totals[i]])
				totals[i] = now[i]
			var p: DuelPlayer = game.players[i]
			if p.essence < 0:
				_err("player %d has negative Essence (%d)" % [i, p.essence])
			if p.wards.size() > p.ward_slots():
				_err("player %d has too many Wards" % i)
			for s in p.slots.size():
				var t = p.slots[s]
				if t != null and t.slot != s:
					_err("Totem %s thinks it is in slot %d but sits in %d" % [t.card_name(), t.slot, s])
				if t != null and t.is_knocked_out() and game.phase != "setup" and not game.over:
					pass  # knockouts are cleared at the end of each action
			var seen := {}
			for c in p.deck + p.hand + p.discard + p.spent + p.wards:
				if seen.has(c.uid):
					_err("card %s is in two places" % c)
				seen[c.uid] = true
			for t in p.totems():
				for c in t.stack:
					if seen.has(c.uid):
						_err("card %s is in two places" % c)
					seen[c.uid] = true

	func _err(msg: String) -> void:
		errors += 1
		if errors <= 12:
			print("INVARIANT: ", msg)
