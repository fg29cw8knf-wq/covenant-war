extends SceneTree
## Patron and Blessing strength. For each god, one duellist is sworn to that
## god and the other to a random patron (never the same). Plays the duels on
## open ground and again under that god's own Law: the first number is the
## patron's strength (attribute + Gift), the difference is the Blessing.
##
## Run: godot --headless --script res://tests/patron_sim.gd -- [duels per god] [gods...]

const PATRONS := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith",
	"vexa", "verdanthe", "maerith", "aster", "hethrin", "ysolde"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var n: int = int(args[0]) if args.size() > 0 else 200
	var gods: Array = Array(args.slice(1)) if args.size() > 1 else PATRONS
	var decks: Array = DuelCards.DECKS.keys()
	print("%-10s  open ground   own Law   Blessing" % "patron")
	for god in gods:
		var rates := []
		for law in ["", god]:
			if god == "" and law == "":
				pass
			var wins := 0
			var games := 0
			var rng := RandomNumberGenerator.new()
			rng.seed = 31
			for g in n:
				var a: String = decks[rng.randi() % decks.size()]
				var b: String = decks[rng.randi() % decks.size()]
				var other: String = god
				while other == god:
					other = PATRONS[rng.randi() % PATRONS.size()]
				var seat := g % 2
				var pats := [god, other] if seat == 0 else [other, god]
				var ds := [a, b]
				var game := DuelGame.new()
				game.law = law
				game.setup(ds, ["A", "B"], [DuelAI.new(1.0, 600 + g), DuelAI.new(1.0, 800 + g)],
					[_profile("A", pats[0], ds[0]), _profile("B", pats[1], ds[1])], 12000 + g)
				await game.run()
				if game.winner in [0, 1]:
					games += 1
					if game.winner == seat:
						wins += 1
			rates.append(100.0 * wins / maxf(1, games))
		var nm: String = "unsworn" if god == "" else god
		if god == "":
			print("%-10s  %5.0f%%" % [nm, rates[0]])
		else:
			print("%-10s  %5.0f%%      %5.0f%%     %+4.0f" % [nm, rates[0], rates[1], rates[1] - rates[0]])
	quit()


static func _profile(pname: String, patron: String, deck_id: String) -> Dictionary:
	var p := Lore.new_profile(pname, "", 4)
	var bumps: Dictionary = DuelCards.DECKS.get(deck_id, {}).get("attributes", {})
	for a in bumps:
		p.base[a] = int(p.base[a]) + int(bumps[a])
	Lore.set_patron(p, patron)
	return p
