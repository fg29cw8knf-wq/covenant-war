extends Node
## Balance check for Bram's duel by the fire (Prologue.practice_duel_spec:
## Bram plays the deck that shows the player's its weakness, at 0.35), with
## the computer playing both sides, for each of the four starter decks:
##   godot --headless res://tests/fire_sim.tscn -- [player ai] [bram ai] [games]
## The player's side at 0.3 stands for a player who has just learned the
## game; it should win more often than not, and never nearly always.
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var pa := float(a[0]) if a.size() > 0 and String(a[0]).is_valid_float() else 0.3
	var ba := float(a[1]) if a.size() > 1 and String(a[1]).is_valid_float() else -1.0
	var n := int(a[2]) if a.size() > 2 and String(a[2]).is_valid_int() else 200
	for mine in DuelCards.DECKS.keys():
		var spec: Dictionary = Prologue.practice_duel_spec(String(mine))
		var bram_ai := ba if ba >= 0.0 else float(spec.difficulty)
		var wins := 0
		var turns := []
		for i in n:
			var g := DuelGame.new()
			g.setup(spec.decks, ["Sprout", "Bram"], [DuelAI.new(pa), DuelAI.new(bram_ai)], [Lore.new_profile("Sprout"), Lore.new_profile("Bram")], i)
			await g.run()
			turns.append(g.turn)
			if g.winner == 0:
				wins += 1
		turns.sort()
		print("FIRE SIM %-10s v %-10s  ai %.2f v %.2f: player wins %d%%, median turns %d (min %d, max %d)" % [mine, Prologue.bram_pick(String(mine)), pa, bram_ai, wins * 100 / n, turns[n / 2], turns[0], turns[-1]])
	get_tree().quit()
