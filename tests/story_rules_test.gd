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
	_hold_the_gate()
	_light_fingers()
	_sunspire_mirror()
	_mirror_trial()
	_whole_duels("hold_the_gate", "gate_watch", {"life_scale": 0.5})
	_whole_duels("light_fingers", "pickpocket", {})
	_whole_duels("sunspire_mirror", "golden_oath", {"kept_back": [[], ["dawnmane"]]})
	print("STORY RULES: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


## Hold the Gate (Warden Hale): while his Guardian stands his Totems never go
## for your Life, even with nothing in the way; once it's down, they may. It
## binds only him. The duel is fought at half Life.
func _hold_the_gate() -> void:
	var g := DuelGame.new()
	g.setup(["emberstorm", "gate_watch"], ["You", "Warden Hale"], [DuelAI.new(), DuelAI.new()])
	g.story_rules = {"hold_the_gate": 1}
	g.life_scale = 0.5
	g._setup_phase()
	var full := DuelRules.life_for(g.players[0].attributes())
	_check(g.players[0].max_life == int(round(full * 0.5 / 10.0)) * 10 and g.players[0].life == g.players[0].max_life,
		"half Life for you (%d of %d)" % [g.players[0].max_life, full])
	_check(g.players[1].max_life * 2 <= DuelRules.life_for(g.players[1].attributes()) + 10, "half Life for Hale too (%d)" % g.players[1].max_life)
	g.turn = 3
	for side in 2:
		g.players[side].slots = [null, null, null]
	var guard := DuelTotem.new(DuelCard.new(900, "brassback", 1), 1, 0, 1, {})
	var hound := DuelTotem.new(DuelCard.new(901, "shieldhound", 1), 1, 2, 1, {})
	g.players[1].slots[0] = guard
	g.players[1].slots[2] = hound
	var ts := g.attack_targets(1, hound, 0)
	_check(ts.is_empty(), "with his Guardian up and nothing of yours out, his hound has no target (got %s)" % _names(ts))
	var pup := DuelTotem.new(DuelCard.new(902, "cinderpup", 0), 0, 1, 1, {})
	g.players[0].slots[1] = pup
	ts = g.attack_targets(1, hound, 0)
	_check(ts.size() == 1 and ts[0] == pup, "with his Guardian up it goes for your Totem, never your Life (got %s)" % _names(ts))
	g.players[1].slots[0] = null
	ts = g.attack_targets(1, hound, 0)
	_check(ts.has(DuelGame.LIFE), "with his Guardian down your Life is open to him (got %s)" % _names(ts))
	# it doesn't bind you: your pup still goes at his Life past nothing
	g.players[1].slots = [null, null, null]
	ts = g.attack_targets(0, pup, 0)
	_check(ts.has(DuelGame.LIFE), "your Totem may still go for his Life (got %s)" % _names(ts))


## Light Fingers (Wren): from her second turn, once a duel, she takes a card
## she can play out of your hand and plays it as her own.
func _light_fingers() -> void:
	var g := DuelGame.new()
	g.setup(["emberstorm", "pickpocket"], ["You", "Wren"], [DuelAI.new(), DuelAI.new()], [], 5)
	g.story_rules = {"light_fingers": 1}
	g._setup_phase()
	var you: DuelPlayer = g.players[0]
	var wren: DuelPlayer = g.players[1]
	you.hand.clear()
	wren.hand.clear()
	wren.slots = [null, null, null]
	for id in ["essence_flask", "ashen_drake", "cinderpup"]:
		you.hand.append(DuelCard.new(800 + you.hand.size(), id, 0))
	wren.essence = 2
	g.current = 1
	g.turn = 2
	g._rule_light_fingers(wren)
	_check(you.hand.size() == 3 and not g.rule_state.get("light_fingers", false), "not on her first turn")
	g.turn = 4
	g._rule_light_fingers(wren)
	# the drake costs 4, so she can't play it: she takes the pup and calls it
	_check(g.rule_state.get("light_fingers", false) and String(g.rule_state.get("stolen", "")) == "cinderpup",
		"she takes the best card she can play now (took %s)" % g.rule_state.get("stolen", "nothing"))
	var called := false
	for t in wren.totems():
		if t.id() == "cinderpup" and t.owner == 1:
			called = true
	_check(called, "and calls it as her own")
	_check(you.hand.size() == 2 and you.hand.all(func(c): return c.id != "cinderpup"), "it's gone from your hand")
	wren.essence = 9
	g.turn = 6
	g._rule_light_fingers(wren)
	_check(you.hand.size() == 2, "only once a duel")
	# with nothing she can play, she waits
	var g2 := DuelGame.new()
	g2.setup(["emberstorm", "pickpocket"], ["You", "Wren"], [DuelAI.new(), DuelAI.new()], [], 6)
	g2.story_rules = {"light_fingers": 1}
	g2._setup_phase()
	g2.players[0].hand = [DuelCard.new(850, "ashen_drake", 0)]
	g2.players[1].essence = 1
	g2.current = 1
	g2.turn = 4
	g2._rule_light_fingers(g2.players[1])
	_check(g2.players[0].hand.size() == 1 and not g2.rule_state.get("light_fingers", false), "nothing she can play: she waits")


## The Sunspire's Mirror (Ser Aldric): at half Life the mirror swings to his
## side; his Radiant cards cost one less, Dawnmane (kept back) comes to his
## hand and he calls it down the moment he can. Yours cost what they cost.
func _sunspire_mirror() -> void:
	var g := DuelGame.new()
	g.setup(["emberstorm", "golden_oath"], ["You", "Ser Aldric Vane"], [DuelAI.new(), DuelAI.new()], [], 9)
	g.story_rules = {"sunspire_mirror": 1}
	g.kept_back = [[], ["dawnmane"]]
	g._setup_phase()
	var ald: DuelPlayer = g.players[1]
	var seraph := DuelCard.new(700, "sunlance_seraph", 1)
	var lion := DuelCard.new(701, "sunmane_lion", 0)
	var pup := DuelCard.new(702, "cinderpup", 1)
	_check(g.card_cost(1, seraph) == 5, "before: the Seraph costs 5 (%d)" % g.card_cost(1, seraph))
	_check(not ald.hand.any(func(c): return c.id == "dawnmane") and not ald.deck.any(func(c): return c.id == "dawnmane"), "Dawnmane is kept back, out of his deck")
	g.current = 0
	g._hit_life(1, ald.life - ald.max_life / 2 - 10, {"no_guard": true})
	_check(not g.rule_state.get("mirror", false), "above half: nothing yet (Life %d of %d)" % [ald.life, ald.max_life])
	g._hit_life(1, 20, {"no_guard": true})
	_check(g.rule_state.get("mirror", false), "at half: the mirror swings (Life %d of %d)" % [ald.life, ald.max_life])
	_check(g.card_cost(1, seraph) == 4, "his Radiant cards cost one less (Seraph %d)" % g.card_cost(1, seraph))
	_check(g.card_cost(1, pup) == 1, "his other cards don't (Cinderpup %d)" % g.card_cost(1, pup))
	_check(g.card_cost(0, lion) == 3, "yours don't (Sunmane Lion %d)" % g.card_cost(0, lion))
	var dm: DuelCard = null
	for c in ald.hand:
		if c.id == "dawnmane":
			dm = c
	_check(dm != null and g.summon_cost(1, dm) == 6, "Dawnmane comes to his hand, at 6")
	# his turn: he lays it on the stone as soon as he can pay for it
	var foe_t := DuelTotem.new(DuelCard.new(703, "cinderpup", 0), 0, 0, 1, {})
	g.players[0].slots[0] = foe_t
	g.current = 1
	ald.essence = 5
	g._rule_dawnmane(ald)
	_check(not g.rule_state.get("woken", false), "not with 5 Essence")
	ald.essence = 6
	g._rule_dawnmane(ald)
	_check(g.rule_state.get("woken", false) and ald.spent.any(func(c): return c.id == "dawnmane"), "with 6 he calls it down")
	_check(foe_t.damage >= 50 or foe_t.is_knocked_out() or g.players[0].slots[0] == null, "Dawn's Roar hits your Totems")


## The Trial of Light's engine: a set board, the mirrors only watch, and the
## other side has three turns.
func _mirror_trial() -> void:
	var Duels = load("res://scripts/world/solhaven/duels.gd")
	var spec: Dictionary = Duels.trial_spec("ironstone")
	var g := DuelGame.new()
	g.setup(spec.decks, spec.names, [DuelAI.new(), DuelAI.new()], spec.profiles, 3)
	g.story_rules = spec.story_rules
	g.puzzle = spec.puzzle
	g._setup_phase()
	_check(g.players[1].life == int(Duels.TRIALS.ironstone.life) and g.players[1].slots[1] != null and g.players[1].slots[1].id() == "gilded_sentinel", "the mirrors' board and Life are set (%d)" % g.players[1].life)
	_check(g.players[0].hand.size() == 2 and g.players[0].hand[0].id == "grondmaw", "your hand is set: the Summon and a Ward")
	_check(g.players[0].slots[0] != null and g.players[0].slots[2] != null, "your Totems are set")
	_check(g.first_player == 0 and g.players[0].essence_max == 6, "you go first, with the Summon's cost in Essence")
	# an AI side that only ends its turns: the mirrors win after three
	var g2 := DuelGame.new()
	g2.setup(spec.decks, spec.names, [Ender.new(), DuelAI.new()], spec.profiles, 3)
	g2.story_rules = spec.story_rules
	g2.puzzle = spec.puzzle
	g2.run()
	_check(g2.over and g2.winner == 1 and g2.turn == 5, "three turns of doing nothing: the mirrors begin again (winner %d, turn %d)" % [g2.winner, g2.turn])
	_check(g2.players[0].life == 100, "the mirrors never strike (your Life %d)" % g2.players[0].life)


## A few hundred whole duels under each rule never break.
func _whole_duels(rule: String, deck: String, extra: Dictionary) -> void:
	var errs := 0
	var won := [0, 0]
	var fired := 0
	for k in 120:
		var d := DuelGame.new()
		d.setup([["tidegrove", "emberstorm", "ironstone", "veilwild"][k % 4], deck], ["You", "Them"], [DuelAI.new(), DuelAI.new()], [], 1000 + k)
		d.story_rules = {rule: 1}
		d.life_scale = float(extra.get("life_scale", 1.0))
		d.kept_back = (extra.get("kept_back", [[], []]) as Array).duplicate(true)
		d.run()
		if not d.over:
			errs += 1
		elif d.winner in [0, 1]:
			won[d.winner] += 1
		if not d.rule_state.is_empty():
			fired += 1
		var totals := d.card_totals()
		if rule != "light_fingers" and rule != "sunspire_mirror" and totals[0] != 30:
			errs += 1
	_check(errs == 0, "%s: %d duels broke" % [rule, errs])
	print("STORY RULES: 120 duels under %s: you %d, them %d; the rule came into play in %d" % [rule, won[0], won[1], fired])


class Ender:
	extends RefCounted
	func choose_action(_g, _pi) -> Dictionary: return {"type": "end"}
	func choose_cards(_g, _pi, _p, cards: Array, min_n: int, _max_n, _c) -> Array: return cards.slice(0, min_n)
	func choose_totems(_g, _pi, _p, totems: Array, min_n: int, _max_n) -> Array: return totems.slice(0, min_n)
	func choose_slot(_g, _pi, _p, slots: Array, _c) -> int: return slots[0]
	func choose_reroll(_g, _pi, _i) -> bool: return false
	func choose_scry(_g, _pi, _c) -> bool: return true


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
