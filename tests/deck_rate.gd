extends SceneTree
## A starter deck's win rate against all four starter decks, optionally with
## cards swapped. Duellists are Unsworn, so patrons don't hide the deck.
##
## Run: godot --headless --script res://tests/deck_rate.gd -- veilwild 100 -seekers_compass +puppet_rune

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var who: String = args[0] if args.size() > 0 else "veilwild"
	var n: int = int(args[1]) if args.size() > 1 else 100
	var cards := DuelCards.card_list(who)
	for a in args.slice(2):
		if a.begins_with("-"):
			cards.erase(a.substr(1))
		elif a.begins_with("+"):
			cards.append(a.substr(1))
	var probs := DuelCards.deck_problems(cards)
	if not probs.is_empty():
		print("DECK PROBLEM: ", probs)
	var row := []
	var wins_all := 0
	var games_all := 0
	for opp in DuelCards.DECKS:
		var wins := 0
		var games := 0
		for g in n:
			var seat := g % 2
			var specs := [cards, opp] if seat == 0 else [opp, cards]
			var prof := [_profile("A", who if seat == 0 else opp), _profile("B", opp if seat == 0 else who)]
			var game := DuelGame.new()
			var sd := 50000 + g * 7
			game.setup(specs, ["A", "B"], [DuelAI.new(1.0, sd), DuelAI.new(1.0, sd + 1)], prof, sd)
			await game.run()
			if game.winner == seat:
				wins += 1
			if game.winner in [0, 1]:
				games += 1
		row.append("%s %.0f%%" % [opp.substr(0, 4), 100.0 * wins / maxf(1, games)])
		wins_all += wins
		games_all += games
	print("%s %s: %.1f%%   %s" % [who, " ".join(args.slice(2)), 100.0 * wins_all / maxf(1, games_all), "  ".join(row)])
	quit()


static func _profile(pname: String, deck_id: String) -> Dictionary:
	var p := Lore.new_profile(pname, "", 4)
	var bumps: Dictionary = DuelCards.DECKS.get(deck_id, {}).get("attributes", {})
	for a in bumps:
		p.base[a] = int(p.base[a]) + int(bumps[a])
	Lore.set_patron(p, "")
	return p
