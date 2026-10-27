extends Node
## Balance check for the afternoon's friendly games (Tam's, Nell's), set up as
## the story plays them (ashford.gd duel_spec: the player's deck with its
## Totems dealt first, theirs in its written order, 40 Life), with the
## computer playing both sides: a new player's plain play (0.3) against
## theirs at the story's strength. Prints the player's win rate and how many
## Totems each side had on the field at once, at most, on average.
##   godot --headless res://tests/friendly_sim.tscn -- [tam_friendly|nell_friendly] [player ai] [games] [player's skill]
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var id: String = a[0] if a.size() > 0 else "tam_friendly"
	var pa := float(a[1]) if a.size() > 1 and String(a[1]).is_valid_float() else 0.3
	var n := int(a[2]) if a.size() > 2 and String(a[2]).is_valid_int() else 200
	var skill: String = a[3] if a.size() > 3 else DuelSkills.DEFAULT
	var area = load("res://scripts/world/areas/ashford.gd")
	var wins := 0
	var turns := []
	var most := [0.0, 0.0]
	for i in n:
		var spec: Dictionary = area.duel_spec({"id": id})
		var g := DuelGame.new()
		g.stacked = spec.get("stacked", [false, false])
		g.setup(spec.decks, ["Sprout", String(spec.names[1])], [DuelAI.new(pa), DuelAI.new(float(spec.difficulty))],
			[Lore.new_profile("Sprout"), Lore.new_profile(String(spec.names[1]))], 1000 + i)
		g.start_life = int(spec.life)
		# (27 October: as the screen sets them up: the Circle and its events,
		# the comeback card, the rival's skill and the player's)
		g.arena = String(spec.get("arena", ""))
		g.skills = [skill, String(spec.get("rival_skill", ""))]
		var peak := [0, 0]
		g.state_changed.connect(func() -> void:
			for side in 2:
				peak[side] = maxi(peak[side], (g.players[side] as DuelPlayer).totems().size()))
		await g.run()
		turns.append(g.turn)
		most[0] += peak[0]
		most[1] += peak[1]
		if g.winner == 0:
			wins += 1
	turns.sort()
	print("FRIENDLY SIM %s (%s against %s): ai %.2f, %d games: player wins %d%%, median turns %d; Totems out at once, most: player %.1f, rival %.1f" % [
		id, skill, String(area.duel_spec({"id": id}).get("rival_skill", "")), pa, n, wins * 100 / n, turns[n / 2], most[0] / n, most[1] / n])
	get_tree().quit()
