extends SceneTree
## Dominion Law balance test. For each Law, plays AI-vs-AI duels between all
## the starter decks. A third of the duellists are sworn to the Law's god,
## so the Blessing gets measured; the rest get a random patron. Prints each
## starter deck's win rate under each Law beside its rate with no Law.
##
## Run: godot --headless --script res://tests/law_sim.gd -- [duels per law] [law ids...]

const PATRONS := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith",
	"vexa", "verdanthe", "maerith", "aster", "hethrin", "ysolde"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var games := 400
	if args.size() > 0:
		games = int(args[0])
	var laws: Array = Array(args.slice(1)) if args.size() > 1 else ([""] + DuelLaws.ids())
	var decks: Array = DuelCards.DECKS.keys()
	var t0 := Time.get_ticks_msec()
	print("%-10s %-14s %s   first  turns  blessed  errors" % ["law", "", "  ".join(decks.map(func(d): return d.substr(0, 9).rpad(9)))])
	for law in laws:
		var wins := {}
		var played := {}
		var first_wins := 0
		var decided := 0
		var turns := 0
		var bl_w := 0
		var bl_n := 0
		var errors := 0
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		for g in games:
			var a: String = decks[g % decks.size()]
			var b: String = decks[(g / decks.size()) % decks.size()]
			var pat := []
			for i in 2:
				if law != "" and law != "ironvault" and rng.randf() < 0.34:
					pat.append(law)
				else:
					pat.append(PATRONS[rng.randi() % PATRONS.size()])
			var game := DuelGame.new()
			game.law = law
			game.setup([a, b], ["A", "B"], [DuelAI.new(1.0, 300 + g), DuelAI.new(1.0, 700 + g)],
				[_profile("A", pat[0], a), _profile("B", pat[1], b)], 4000 + g)
			var before := game.card_totals()
			await game.run()
			if game.card_totals() != before:
				errors += 1
			turns += game.turn
			played[a] = int(played.get(a, 0)) + 1
			played[b] = int(played.get(b, 0)) + 1
			if game.winner != 0 and game.winner != 1:
				continue
			decided += 1
			var wd: String = a if game.winner == 0 else b
			wins[wd] = int(wins.get(wd, 0)) + 1
			if game.winner == game.first_player:
				first_wins += 1
			if law != "" and pat[0] != pat[1] and (pat[0] == law or pat[1] == law):
				bl_n += 1
				if pat[game.winner] == law:
					bl_w += 1
		var row := []
		for d in decks:
			row.append(("%3.0f%%" % (100.0 * int(wins.get(d, 0)) / maxf(1, played.get(d, 0)))).rpad(9))
		print("%-10s %-14s %s   %3.0f%%  %5.1f  %s  %d" % [law if law != "" else "(none)", DuelLaws.law_name(law), "  ".join(row),
			100.0 * first_wins / maxf(1, decided), float(turns) / games,
			("%3.0f%% (%d)" % [100.0 * bl_w / maxf(1, bl_n), bl_n]) if bl_n > 0 else "   -    ", errors])
	print("(%d duels per law, %.0fs)" % [games, (Time.get_ticks_msec() - t0) / 1000.0])
	quit()


static func _profile(pname: String, patron: String, deck_id: String) -> Dictionary:
	var p := Lore.new_profile(pname, "", 4)
	var bumps: Dictionary = DuelCards.DECKS.get(deck_id, {}).get("attributes", {})
	for a in bumps:
		p.base[a] = int(p.base[a]) + int(bumps[a])
	Lore.set_patron(p, patron)
	return p
