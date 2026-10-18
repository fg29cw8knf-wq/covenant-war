extends SceneTree
## The story duels' own rules, checked on the rules engine alone (no screen):
## Run to Ground (Dask's hounds always attack the Totem with the least Life
## left), and that it binds only the side it's given to.
##   godot --headless --script res://tests/story_rules_test.gd

var fails := 0


func _initialize() -> void:
	var g := DuelGame.new()
	g.setup(["tidegrove", "dask_hounds"], ["You", "Dask"], [DuelAI.new(), DuelAI.new()])
	g.story_rules = {"run_to_ground": 1}
	g.turn = 3
	# three of yours, at 60, 20 and 40 Life left; one of his
	var mine: Array = []
	for i in 3:
		var t := DuelTotem.new(DuelCard.new(100 + i, "brookfin", 0), 0, i, 1, {})
		g.players[0].slots[i] = t
		mine.append(t)
	mine[0].damage = mine[0].max_hp() - 60
	mine[1].damage = mine[1].max_hp() - 20
	mine[2].damage = mine[2].max_hp() - 40
	var hound := DuelTotem.new(DuelCard.new(200, "shieldhound", 1), 1, 1, 1, {})
	g.players[1].slots[1] = hound
	var ts := g.attack_targets(1, hound, 0)
	_check(ts.size() == 1 and ts[0] == mine[1], "his hound may only go for the one with 20 Life left (got %s)" % [_names(ts)])
	# the weakest goes down: now the one with 40
	g.players[0].slots[1] = null
	ts = g.attack_targets(1, hound, 0)
	_check(ts.size() == 1 and ts[0] == mine[2], "then the one with 40 (got %s)" % [_names(ts)])
	# two level: either
	mine[0].damage = mine[0].max_hp() - 40
	ts = g.attack_targets(1, hound, 0)
	_check(ts.size() == 2, "two at the same Life: either (got %s)" % [_names(ts)])
	# none of yours left: his Life-hitting move goes at your Life
	g.players[0].slots[0] = null
	g.players[0].slots[2] = null
	ts = g.attack_targets(1, hound, 0)
	_check(ts.has(DuelGame.LIFE) or ts.is_empty(), "nothing to run down: as usual (got %s)" % [_names(ts)])
	# the rule doesn't bind you
	var you := DuelTotem.new(DuelCard.new(300, "brookfin", 0), 0, 0, 1, {})
	g.players[0].slots[0] = you
	var pup := DuelTotem.new(DuelCard.new(301, "pebblit", 1), 1, 0, 1, {})
	g.players[1].slots[0] = pup
	pup.damage = 5
	ts = g.attack_targets(0, you, 0)
	_check(ts.size() == 2, "your Totem may pick either of his (got %s)" % [_names(ts)])
	# and a few hundred whole duels under it never break
	var errs := 0
	var won := [0, 0]
	for k in 120:
		var d := DuelGame.new()
		d.setup(["tidegrove" if k % 2 == 0 else "emberstorm", "dask_hounds"], ["You", "Dask"], [DuelAI.new(), DuelAI.new()], [], k)
		d.story_rules = {"run_to_ground": 1}
		d.run()
		if not d.over:
			errs += 1
		elif d.winner in [0, 1]:
			won[d.winner] += 1
	_check(errs == 0, "%d duels didn't finish" % errs)
	print("STORY RULES: 120 duels under Run to Ground: you %d, Dask %d" % [won[0], won[1]])
	print("STORY RULES: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _names(ts: Array) -> String:
	var out := []
	for t in ts:
		out.append(String(t) if t is String else "%s(%d)" % [(t as DuelTotem).card_name(), (t as DuelTotem).hp_left()])
	return ", ".join(out)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("STORY RULES FAIL: ", what)
