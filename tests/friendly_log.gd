extends Node
## Prints the full log of one of the afternoon's friendly games (Tam's or
## Nell's), set up as the story plays it (ashford.gd duel_spec), the player's
## side played by the computer at a new player's strength.
##   godot --headless res://tests/friendly_log.tscn -- [nell_friendly|tam_friendly] [seed] [player ai]
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var id: String = a[0] if a.size() > 0 else "nell_friendly"
	var sd := int(a[1]) if a.size() > 1 else 1
	var pa := float(a[2]) if a.size() > 2 else 0.3
	var area = load("res://scripts/world/areas/ashford.gd")
	var spec: Dictionary = area.duel_spec({"id": id})
	var g := DuelGame.new()
	g.stacked = spec.get("stacked", [false, false])
	g.setup(spec.decks, ["Sprout", String(spec.names[1])], [DuelAI.new(pa, sd), DuelAI.new(float(spec.difficulty), sd + 1)],
		[Lore.new_profile("Sprout"), Lore.new_profile(String(spec.names[1]))], 1000 + sd)
	g.start_life = int(spec.life)
	g.start_lives = spec.get("lives", [])
	g.arena = String(spec.get("arena", ""))
	g.friendly = bool(spec.get("friendly", false))
	g.skills = [DuelSkills.DEFAULT, String(spec.get("rival_skill", ""))]
	g.logged.connect(func(t, who): print(("    " if who == 1 else "") + str(t)))
	await g.run()
	print("WINNER ", g.winner, " turns ", g.turn)
	get_tree().quit()
