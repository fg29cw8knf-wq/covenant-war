extends Node
## Balance check for the Lantern Duel, set up exactly as the story plays it
## (decks dealt in order, the player first, 25 Life, the safety floor), with
## the computer playing both sides:
##   godot --headless res://tests/lantern_sim.tscn -- [player ai] [corin ai] [games]
## Add "raw" to play it without the floor and with shuffled decks, to see how
## the decks themselves compare.
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var pa := float(a[0]) if a.size() > 0 else 0.3
	var ca := float(a[1]) if a.size() > 1 else 0.25
	var n := int(a[2]) if a.size() > 2 else 200
	var raw := a.has("raw")
	var area = load("res://scripts/world/areas/ashford.gd")
	var turns := []
	var wins := 0
	for i in n:
		var g := DuelGame.new()
		var spec: Dictionary = area.duel_spec({"difficulty": ca})
		if not raw:
			g.stacked = spec.stacked
		g.setup(spec.decks, ["Sprout", "Corin"], [DuelAI.new(pa), DuelAI.new(ca)], [Lore.new_profile("Sprout"), Lore.new_profile("Corin")], i)
		g.start_life = int(spec.life)
		if not raw:
			g.first_forced = int(spec.first)
			g.life_floor = spec.life_floor
			g.totem_floor = spec.totem_floor
		await g.run()
		turns.append(g.turn)
		if g.winner == 0:
			wins += 1
	turns.sort()
	print("ai %.2f v %.2f %s: median turns %d (min %d, max %d), player wins %d%%" % [pa, ca, "raw" if raw else "as played", turns[n / 2], turns[0], turns[-1], wins * 100 / n])
	get_tree().quit()
