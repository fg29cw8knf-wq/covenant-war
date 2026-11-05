extends SceneTree
## Finds a seed for Bram's duel in the Night of the White Sky (the memory
## before the attic): Bram's deck of Kaethis's cards (5 November; his old
## Ironstone before), stacked so his Summon (WhiteSkyDuel.SUMMON, Orlanthe)
## is drawn early, against the faceless hunter's pale hounds (Veilwild
## without its Summon), both sides the computer, as WhiteSky plays it on
## screen. A good seed has Bram losing (two Totems of his knocked out, no
## fewer than he's broken of the pack, at least one) when he calls the Summon down,
## between TURN_MIN and TURN_MAX. Prints, per seed, the turn it comes, the
## Life on each side then and the Totems each side has lost.
## Run: godot --headless --path . --script res://tests/white_sky_probe.gd -- <first seed> <count> [pos] [log seed]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var first: int = int(args[0]) if args.size() > 0 else 1
	var count: int = int(args[1]) if args.size() > 1 else 40
	var pos: int = int(args[2]) if args.size() > 2 else WhiteSkyDuel.SUMMON_AT
	var log_seed: int = int(args[3]) if args.size() > 3 else -1
	var good := []
	var summon_name := WhiteSkyDuel.summon_name()
	for sd in range(first, first + count):
		var game := DuelGame.new()
		game.stacked = [true, true]
		game.puzzle = WhiteSkyDuel.board()
		# (5 November: the set board's deck is what's drawn, so [pos] goes there)
		game.puzzle.deck[0] = WhiteSkyDuel.bram_deck(sd, pos)
		game.story_rules = WhiteSkyDuel.story_rules()
		var profiles := [WhiteSkyDuel.bram_profile(), WhiteSkyDuel.hunter_profile()]
		game.setup([WhiteSkyDuel.bram_deck(sd, pos), WhiteSkyDuel.hunter_deck(sd)], ["Bram", "?"],
			[DuelAI.new(WhiteSkyDuel.SKILL), DuelAI.new(WhiteSkyDuel.SKILL)], profiles, sd)
		game.life_floor = WhiteSkyDuel.LIFE_FLOOR.duplicate()
		# as DuelScreen sets a filmed duel (spec.film)
		game.arena = ""
		game.skills = ["", ""]
		game.comeback = false
		game.arena_events = false
		game.ai_oaths = false
		game.place_god = ""
		var st := {"turn": -1, "life": [0, 0], "lost": 0, "kos_before": 0, "his_kos": 0}
		game.logged.connect(func(t, who):
			if game.turn > 24:
				game.over = true
			if sd == log_seed:
				print(("    " if who == 1 else "") + t)
			if st.turn < 0 and who == 0 and summon_name in t and "calls down" in t:
				st.turn = game.turn
				st.life = [game.players[0].life, game.players[1].life]
				st.kos_before = game.players[0].fallen.size()
				st.his_kos = game.players[1].fallen.size()
				game.over = true)
		await game.run()
		# (no Life is shown in the film: what reads as losing is his Totems falling)
		# (4 November: Bram a champion: he knocks the hunter's hounds out too,
		# but loses more than he takes)
		var ok: bool = st.turn >= WhiteSkyDuel.TURN_MIN and st.turn <= WhiteSkyDuel.TURN_MAX and st.kos_before >= 2 and st.his_kos >= 1 and st.kos_before >= st.his_kos
		if ok:
			good.append(sd)
		print("seed %d: summon turn %d | life bram %d hunter %d | Bram's Totems lost %d, the hunter's %d %s" % [
			sd, st.turn, st.life[0], st.life[1], st.kos_before, st.his_kos, "  <- good" if ok else ""])
	print("good seeds: ", good)
	quit()
