extends SceneTree
## Prints the full log of one AI-vs-AI duel.
## Run: godot --headless --script res://tests/duel_log.gd -- deckA deckB [seed]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var a: String = args[0] if args.size() > 0 else "emberstorm"
	var b: String = args[1] if args.size() > 1 else "veilwild"
	var sd: int = int(args[2]) if args.size() > 2 else 1
	var pa := Lore.new_profile("A", "", 4)
	var pb := Lore.new_profile("B", "", 4)
	var game := DuelGame.new()
	game.setup([a, b], [a, b], [DuelAI.new(1.0, sd), DuelAI.new(1.0, sd + 1)], [pa, pb], sd)
	game.logged.connect(func(t, who): print(("    " if who == 1 else "") + t))
	await game.run()
	quit()
