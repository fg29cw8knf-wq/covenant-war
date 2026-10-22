extends SceneTree
## Finds a seed for the showcase film: Emberstorm (stacked so Pyraxis is drawn
## early) against Tidegrove, both sides the computer at full difficulty, the
## same set-up tests/duel_film.gd plays on screen. Prints, per seed, the turn
## Pyraxis is called down, how long the duel runs and who wins.
## Run: godot --headless --script res://tests/film_probe.gd -- <first seed> <count> [pos] [rival deck] [log seed]

const DECK := "emberstorm"

static func stacked_deck(seed_value: int, pos: int) -> Array:
	var ids: Array = DuelCards.card_list(DECK)
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 7919 + 17
	for i in range(ids.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	ids.erase("pyraxis")
	# a Basic Totem first so the opening hand never reshuffles
	var basics := ids.filter(func(id): return DuelCards.CARDS[id].kind == "totem" and DuelCards.CARDS[id].get("tier", 1) == 1)
	ids.erase(basics[0])
	ids.insert(0, basics[0])
	ids.insert(pos, "pyraxis")
	return ids


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var first: int = int(args[0]) if args.size() > 0 else 1
	var count: int = int(args[1]) if args.size() > 1 else 10
	var pos: int = int(args[2]) if args.size() > 2 else 8
	var rival: String = args[3] if args.size() > 3 else "tidegrove"
	var log_seed: int = int(args[4]) if args.size() > 4 else -1
	for sd in range(first, first + count):
		var pa := Lore.new_profile("You", "pyrrhane", 4)
		var pb := Lore.new_profile("Wren", "oriel", 4)
		var game := DuelGame.new()
		game.stacked = [true, false]
		game.setup([stacked_deck(sd, pos), rival], ["You", "Wren"], [DuelAI.new(1.0), DuelAI.new(1.0)], [pa, pb], sd)
		var st := {"summon_turn": -1, "rival_summon": -1, "lines": 0}
		game.logged.connect(func(t, who):
			st.lines += 1
			if sd == log_seed:
				print(("    " if who == 1 else "") + t)
			if "Pyraxis" in t and st.summon_turn < 0 and who == 0:
				st.summon_turn = game.turn
			if "Thalassa" in t and "Deep Mother" in t and st.rival_summon < 0:
				st.rival_summon = game.turn)
		await game.run()
		print("seed %d: pyraxis turn %d | rival summon turn %d | turns %d | winner %s (%s)" % [
			sd, st.summon_turn, st.rival_summon, game.turn, str(game.winner), game.win_reason])
	quit()
