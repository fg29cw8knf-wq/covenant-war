extends SceneTree
## Measures how strong each condition and boon card is. For every probe card
## and every starter deck, swaps two of the deck's filler cards for the probe
## (one if it's Tier 4+) and plays the variant against all four starter
## decks. Prints the variant's win rate beside the same deck with no swap,
## so the difference is what the card is worth.
##
## Run: godot --headless --script res://tests/condition_probe.gd -- [duels per deck] [probe ids...]

const FILLER := {
	"emberstorm": ["travellers_pack", "essence_flask"],
	"tidegrove": ["travellers_pack", "travellers_pack"],
	"ironstone": ["essence_flask", "lure_bell"],
	"veilwild": ["seekers_compass", "essence_flask"],
}

const PROBES := ["frostbind", "gust_shove", "corrosive_spit", "jagged_shards", "drowning_rain",
	"strangling_roots", "stone_gaze", "blinding_flare", "goading_ember", "confounding_chime",
	"heart_lure", "dread_howl", "silence_rune", "puppet_rune", "hex_mark", "grave_curse",
	"hunters_mark", "soul_siphon", "doom_sigil", "mind_fog", "clarity_tonic", "cleansing_bell",
	"war_paint", "verdant_balm", "shadow_cloak", "sanctify", "quicken", "static_field", "frost_snare",
	"firebrand", "bulwark"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var n := 120
	if args.size() > 0:
		n = int(args[0])
	var probes: Array = Array(args.slice(1)) if args.size() > 1 else PROBES
	var decks: Array = DuelCards.DECKS.keys()
	var t0 := Time.get_ticks_msec()
	var base := {}
	for d in decks:
		base[d] = await _rate(DuelCards.card_list(d), d, decks, n)
	print("baseline: ", ", ".join(decks.map(func(d): return "%s %.0f%%" % [d, base[d] * 100])))
	for probe in probes:
		var row := []
		var total := 0.0
		for d in decks:
			var cards := DuelCards.card_list(d)
			var tier := int(DuelCards.CARDS[probe].get("tier", 1))
			var swaps: int = 1 if tier >= 4 else 2
			for k in swaps:
				var f: String = FILLER[d][k]
				if cards.has(f):
					cards.erase(f)
					cards.append(probe)
			var probs := DuelCards.deck_problems(cards)
			if not probs.is_empty():
				row.append("%s: %s" % [d, probs[0]])
				continue
			var r: float = await _rate(cards, d, decks, n)
			total += r - base[d]
			row.append("%s %+.0f" % [d.substr(0, 4), (r - base[d]) * 100])
		print("%-18s avg %+5.1f   %s" % [probe, total / decks.size() * 100, "  ".join(row)])
	print("(%d duels per deck per probe, %.0fs)" % [n * decks.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	quit()


## The win rate of `cards` (built on deck `who`) against every starter deck.
func _rate(cards: Array, who: String, decks: Array, n: int) -> float:
	var wins := 0
	var games := 0
	for opp in decks:
		for g in n:
			var seat := g % 2
			var specs := [cards, opp] if seat == 0 else [opp, cards]
			var profiles := [_profile("A", who if seat == 0 else opp), _profile("B", opp if seat == 0 else who)]
			var game := DuelGame.new()
			var sd := 7000 + g * 13 + decks.find(opp) * 1000
			game.setup(specs, ["A", "B"], [DuelAI.new(1.0, sd), DuelAI.new(1.0, sd + 1)], profiles, sd)
			await game.run()
			if game.winner == seat:
				wins += 1
			if game.winner == 0 or game.winner == 1:
				games += 1
	return float(wins) / maxf(1, games)


static func _profile(pname: String, deck_id: String) -> Dictionary:
	var p := Lore.new_profile(pname, "", 4)
	var bumps: Dictionary = DuelCards.DECKS.get(deck_id, {}).get("attributes", {})
	for a in bumps:
		p.base[a] = int(p.base[a]) + int(bumps[a])
	Lore.set_patron(p, "")
	return p
