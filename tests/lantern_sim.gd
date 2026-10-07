extends SceneTree
## Balance check for the Lantern Duel decks:
##   godot --headless --script res://tests/lantern_sim.gd -- <life> <player ai> <corin ai> [swap]
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var life := int(a[0]) if a.size() > 0 else 80
	var pa := float(a[1]) if a.size() > 1 else 0.8
	var ca := float(a[2]) if a.size() > 2 else 0.25
	var swap := a.size() > 3
	var area = load("res://scripts/world/areas/ashford.gd")
	var turns := []
	var wins := 0
	var n := 80
	for i in n:
		var d0: Array = area.PLAYER_DECK.duplicate()
		var d1: Array = area.CORIN_DECK.duplicate()
		if swap:
			var t := d0; d0 = d1; d1 = t
		var g := DuelGame.new()
		g.setup([d0, d1], ["Sprout", "Corin"], [DuelAI.new(pa), DuelAI.new(ca)], [Lore.new_profile("Sprout"), Lore.new_profile("Corin")], i)
		g.start_life = life
		await g.run()
		turns.append(g.turn)
		if g.winner == 0:
			wins += 1
	turns.sort()
	print("life %d ai %.2f v %.2f swap %s: median turns %d (min %d, max %d), side-0 wins %d%%" % [life, pa, ca, swap, turns[n / 2], turns[0], turns[-1], wins * 100 / n])
	quit()
