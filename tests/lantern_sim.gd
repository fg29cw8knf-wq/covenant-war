extends Node
## Balance check for the Lantern Duel, set up exactly as the story plays it
## (decks dealt in order, the player first, 25 Life, the safety floor, Corin's
## Showboat rule), with the computer playing both sides:
##   godot --headless res://tests/lantern_sim.tscn -- [player ai] [corin ai] [games]
## Add "raw" to play it without the floor and with shuffled decks, to see how
## the decks themselves compare, or "rematch" to play Corin's rematch as the
## story does (shuffled, a roll for who goes first, no floor, Showboat, and
## Corin at the rematch's own strength unless one is given): it can be lost.
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var pa := float(a[0]) if a.size() > 0 and String(a[0]).is_valid_float() else 0.3
	var ca := float(a[1]) if a.size() > 1 and String(a[1]).is_valid_float() else -1.0
	var n := int(a[2]) if a.size() > 2 and String(a[2]).is_valid_int() else 200
	var raw := a.has("raw")
	var rematch := a.has("rematch")
	var area = load("res://scripts/world/areas/ashford.gd")
	var turns := []
	var wins := 0
	var showboat_ok := true
	for i in n:
		var g := DuelGame.new()
		var spec: Dictionary = area.duel_spec({"difficulty": 0.25, "rematch": rematch})
		var corin_ai := ca if ca >= 0.0 else float(spec.difficulty)
		g.stacked = spec.get("stacked", [false, false]) if not raw else [false, false]
		g.story_rules = spec.get("story_rules", {})
		g.setup(spec.decks, ["Sprout", "Corin"], [DuelAI.new(pa), DuelAI.new(corin_ai)], [Lore.new_profile("Sprout"), Lore.new_profile("Corin")], i)
		g.start_life = int(spec.life)
		if not raw:
			g.first_forced = int(spec.get("first", -1))
			g.life_floor = spec.get("life_floor", [0, 0])
			g.totem_floor = spec.get("totem_floor", [0, 0])
		# Showboat: every turn Corin ends with a Totem that could still attack is a broken rule
		g.logged.connect(func(text: String, _who: int) -> void:
			if text.begins_with("(Not allowed: Showboat"):
				showboat_ok = false)
		await g.run()
		turns.append(g.turn)
		if g.winner == 0:
			wins += 1
	turns.sort()
	var mode := "rematch" if rematch else ("raw" if raw else "as played")
	print("ai %.2f v %s %s: median turns %d (min %d, max %d), player wins %d%%%s" % [pa, str(ca) if ca >= 0.0 else "story", mode, turns[n / 2], turns[0], turns[-1],
		wins * 100 / n, "" if showboat_ok else "  (Showboat refused an action)"])
	get_tree().quit()
