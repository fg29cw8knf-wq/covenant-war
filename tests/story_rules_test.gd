extends SceneTree
## The story duels' own rules, checked on the rules engine alone (no screen):
## Run to Ground (Dask's hounds always attack the Totem with the least Life
## left), and that it binds only the side it's given to.
##   godot --headless --script res://tests/story_rules_test.gd

var fails := 0


func _initialize() -> void:
	_solhaven_wagers()   # (the side stories' rules: at the end of the file)
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


## Solhaven's four sworn wagers (scripts/world/areas/solhaven/solhaven_side.gd):
## Licensed, Patter, Scrapper and Discipline, each binding only its side, and
## a hundred-odd whole duels under each with the opponent's own deck.
func _solhaven_wagers() -> void:
	var side = load("res://scripts/world/areas/solhaven/solhaven_side.gd")
	for id in side.DECKS:
		var probs := DuelCards.deck_problems(side.deck_cards(id))
		_check(probs.is_empty(), "%s is a legal deck (%s)" % [id, probs])
	# Licensed: his Rites cost nothing while you have more Totems than he does
	var g := DuelGame.new()
	g.setup(["tidegrove", side.deck_cards("dawn_watch")], ["You", "The Sergeant"], [DuelAI.new(), DuelAI.new()])
	g.story_rules = {"licensed": 1}
	var edge := DuelCard.new(500, "forge_edge", 1)
	var flare := DuelCard.new(501, "blinding_flare", 1)
	var bastion := DuelCard.new(502, "iron_bastion", 1)
	_check(g.rite_cost(1, edge) == 1, "Licensed: level on Totems, his Rite costs what it says (%d)" % g.rite_cost(1, edge))
	g.players[0].slots[0] = DuelTotem.new(DuelCard.new(510, "brookfin", 0), 0, 0, 1, {})
	_check(g.rite_cost(1, edge) == 0 and g.rite_cost(1, flare) == 0, "Licensed: you have more Totems, his Rites are free")
	g.players[1].essence = 0
	g.players[1].hand.append(flare)
	_check(not g.rite_problem(1, flare).begins_with("Needs"), "Licensed: he can cast one with no Essence (%s)" % g.rite_problem(1, flare))
	g.players[1].hand.erase(flare)
	_check(g.card_cost(1, bastion) == 1, "Licensed: his Wards still cost what they say")
	_check(g.rite_cost(0, DuelCard.new(503, "forge_edge", 0)) == 1, "Licensed doesn't bind you")
	g.players[1].slots[0] = DuelTotem.new(DuelCard.new(511, "shieldhound", 1), 1, 0, 1, {})
	_check(g.rite_cost(1, edge) == 1, "Licensed: level again, his Rite costs what it says")
	# Patter: his Wards lie face up, and once a turn he swaps one from his hand
	g = DuelGame.new()
	g.setup(["tidegrove", side.deck_cards("painted_hand")], ["You", "Fen"], [DuelAI.new(), DuelAI.new()])
	g.story_rules = {"patter": 1}
	g.turn = 2
	g.current = 1
	var fen: DuelPlayer = g.players[1]
	fen.hand.clear()
	fen.essence = 6
	var veil := DuelCard.new(600, "mirror_veil", 1)
	var rune := DuelCard.new(601, "counter_rune", 1)
	fen.hand.append(veil)
	g._act_ward(1, veil)
	_check(g.face_up.has(600), "Patter: Fen's Ward lies face up")
	fen.hand.append(rune)
	g._rule_patter(fen)
	_check(fen.wards.size() == 1 and fen.wards[0] == rune and fen.hand.has(veil), "Patter: he swaps the Ward for the one in his hand")
	_check(g.face_up.has(601) and not g.face_up.has(600), "Patter: the new one's face up, the old one's back in his hand")
	fen.hand.erase(veil)
	g._rule_patter(fen)
	_check(fen.wards[0] == rune, "Patter: no other Ward in his hand, no swap")
	g.current = 0
	var mine := DuelCard.new(602, "mirror_veil", 0)
	g.players[0].hand.append(mine)
	g.players[0].essence = 6
	g._act_ward(0, mine)
	_check(not g.face_up.has(602), "Patter doesn't turn your Wards face up")
	# Scrapper: his Totems hit 10 harder while his Life is below yours
	g = DuelGame.new()
	g.setup(["tidegrove", side.deck_cards("street_sparks")], ["You", "Pip"], [DuelAI.new(), DuelAI.new()])
	g.story_rules = {"scrapper": 1}
	g.players[0].life = 100
	var pup := DuelTotem.new(DuelCard.new(700, "cinderpup", 1), 1, 0, 1, {})
	var fin := DuelTotem.new(DuelCard.new(701, "brookfin", 0), 0, 0, 1, {})
	g.players[1].life = g.players[0].life
	_check(g.attack_amount(pup, 0, 10, null) == 10, "Scrapper: level on Life, his Nip does 10")
	g.players[1].life = g.players[0].life - 30
	_check(g.attack_amount(pup, 0, 10, null) == 20, "Scrapper: behind, his Nip does 20 (%d)" % g.attack_amount(pup, 0, 10, null))
	g.players[0].life = g.players[1].life - 40
	_check(g.attack_amount(fin, 0, 10, null) == 10, "Scrapper doesn't help you when you're behind")
	# Discipline: her Totems can't be Burned, Poisoned or Frozen
	g = DuelGame.new()
	g.setup(["emberstorm", side.deck_cards("sun_guard")], ["You", "The Captain"], [DuelAI.new(), DuelAI.new()])
	g.story_rules = {"discipline": 1}
	var hers := DuelTotem.new(DuelCard.new(800, "shieldhound", 1), 1, 0, 1, {})
	var yours := DuelTotem.new(DuelCard.new(801, "cinderpup", 0), 0, 0, 1, {})
	g.players[1].slots[0] = hers
	g.players[0].slots[0] = yours
	for st in ["burn", "poison", "frozen"]:
		g._apply_status(hers, st)
		_check(not hers.has_status(st), "Discipline: hers can't be %s" % st)
	g._apply_status(hers, "stun")
	_check(hers.has_status("stun"), "Discipline: other conditions still land on hers")
	g._apply_status(yours, "burn")
	_check(yours.has_status("burn"), "Discipline doesn't protect yours")
	# whole duels under each rule, with the opponent's deck
	var rules := {"licensed": "dawn_watch", "patter": "painted_hand", "scrapper": "street_sparks", "discipline": "sun_guard"}
	for rule in rules:
		var errs := 0
		var won := [0, 0]
		for k in 30:
			var d := DuelGame.new()
			d.setup([["tidegrove", "emberstorm", "ironstone", "veilwild"][k % 4], side.deck_cards(rules[rule])], ["You", "Them"],
				[DuelAI.new(), DuelAI.new()], [], 1000 + k)
			d.story_rules = {rule: 1}
			d.run()
			if not d.over:
				errs += 1
			elif d.winner in [0, 1]:
				won[d.winner] += 1
		_check(errs == 0, "%s: %d duels didn't finish" % [rule, errs])
		print("STORY RULES: 30 duels under %s (%s): starter decks %d, them %d" % [rule, rules[rule], won[0], won[1]])
