extends SceneTree
## Phase D of the deeper duel, on the rules engine alone: each arena's rule,
## Terrain Rites (three turns, then the Circle is itself again), Continuous
## Rites (they stand, two a side, the oldest pushed out, Unbind; each standing
## effect), Favour (the god's element and way, the Unsworn at half pace, the
## Law's god double; full: the Gift again or the Demigod, free), Oaths (sworn,
## broken for Life, kept for Resonance; once at the start and once mid-duel),
## and whole duels where the computer uses all of it.
##   godot --headless --script res://tests/phase_d_test.gd

var fails := 0
var _uid := 8000


class Picker:
	extends RefCounted
	func choose_action(_g, _pi) -> Dictionary: return {"type": "end"}
	func choose_cards(_g, _pi, _p, cards: Array, min_n: int, _max_n, _c) -> Array: return cards.slice(0, maxi(1, min_n))
	func choose_totems(_g, _pi, _p, totems: Array, min_n: int, _max_n) -> Array: return totems.slice(0, min_n)
	func choose_slot(_g, _pi, _p, slots: Array, _c) -> int: return slots[0]
	func choose_reroll(_g, _pi, _i) -> bool: return false
	func choose_scry(_g, _pi, _c) -> bool: return true
	func choose_response(_g, _pi, _e, _cards) -> DuelCard: return null


func _initialize() -> void:
	await _arenas()
	await _terrain()
	await _continuous()
	await _favour()
	await _oaths()
	await _whole_duels()
	print("PHASE D TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


func _card(id: String, owner: int) -> DuelCard:
	_uid += 1
	return DuelCard.new(_uid, id, owner)


func _game(patrons: Array = ["", ""]) -> DuelGame:
	var g := DuelGame.new()
	g.setup(["emberstorm", "tidegrove"], ["A", "B"], [Picker.new(), Picker.new()], [], 5)
	g.turn = 3
	g.current = 0
	g.first_player = 0
	g.phase = "main"
	for i in 2:
		var pl: DuelPlayer = g.players[i]
		pl.essence_max = 8
		pl.essence = 8
		pl.life = 150
		pl.max_life = 150
		pl.hand.clear()
		var prof := pl.profile.duplicate()
		prof["patron"] = patrons[i]
		pl.profile = prof
	return g


func _put(g: DuelGame, pi: int, id: String, slot: int) -> DuelTotem:
	var t := g._new_totem(_card(id, pi), pi, slot, 1)
	g.players[pi].slots[slot] = t
	return t


func _hand(g: DuelGame, pi: int, id: String) -> DuelCard:
	var c := _card(id, pi)
	g.players[pi].hand.append(c)
	return c


func _arenas() -> void:
	# the tidegrove: a Totem on the field is Soaked at each Dawn
	var g := _game()
	g.arena = "tidegrove"
	var a := _put(g, 0, "cinderpup", 0)
	var b := _put(g, 1, "brookfin", 0)
	await g._dawn_arena(g.players[0])
	_check(a.has_status("soaked") or b.has_status("soaked"), "the tidegrove Soaks a Totem at Dawn")
	# ironstone: Guard 5 higher, both sides
	g = _game()
	var g0: int = g.players[0].guard()
	g.arena = "ironstone"
	await g._dawn_arena(g.players[0])
	_check(g.players[0].guard() == g0 + DuelRules.arena_guard and g.players[1].arena_guard == DuelRules.arena_guard, "ironstone: Guard %d -> %d" % [g0, g.players[0].guard()])
	# solhaven: the outnumbered gain 1 Essence
	g = _game()
	g.arena = "solhaven"
	_put(g, 0, "cinderpup", 0)
	_put(g, 1, "brookfin", 0)
	_put(g, 1, "mossling", 1)
	var e0: int = g.players[0].essence
	await g._dawn_arena(g.players[0])
	_check(g.players[0].essence == e0 + 1, "solhaven: fewer Totems, 1 Essence (%d -> %d)" % [e0, g.players[0].essence])
	await g._dawn_arena(g.players[1])
	_check(g.players[1].essence == 8, "solhaven: more Totems, nothing")
	# the emberforge: a Ward that springs Burns the Totem it catches
	g = _game()
	g.arena = "emberforge"
	var att := _put(g, 0, "sparkkit", 0)
	var w := _card("ambush_snare", 1)
	var res := {"fired": true, "negated": false, "blocked_life": false, "cancel_rite": false, "reduce_life": 0}
	await g._apply_ward_effects(w, 1, {"attacker": att, "called": att}, res)
	_check(att.has_status("burn") or att.is_knocked_out(), "the emberforge Burns the Totem a Ward catches")
	# the veilwild: the first call is veiled, free
	g = _game()
	g.arena = "veilwild"
	var pup := _hand(g, 0, "cinderpup")
	var cost: int = g.call_cost(0, pup)
	await g.perform(0, {"type": "call", "card": pup, "slot": 0})
	var t0: DuelTotem = g.players[0].slots[0]
	_check(t0 != null and t0.face_down, "the veilwild veils the first call")
	_check(g.players[0].essence == 8 - cost, "...at no extra cost (%d spent)" % (8 - g.players[0].essence))
	var kit := _hand(g, 0, "sparkkit")
	await g.perform(0, {"type": "call", "card": kit, "slot": 1})
	_check(g.players[0].slots[1] != null and not g.players[0].slots[1].face_down, "the second call isn't veiled")
	# the mirrors' board has no ground
	g = _game()
	g.arena = "tidegrove"
	g.puzzle = {"x": 1}
	_check(g.arena_now() == "", "the Trial's board has no arena rule")


func _terrain() -> void:
	var g := _game()
	g.arena = "solhaven"
	var r := _hand(g, 0, "forge_ground")
	var n0: int = g.players[0].total_card_count()
	await g.perform(0, {"type": "rite", "card": r})
	_check(g.arena_now() == "emberforge", "Forge Ground turns the Circle to the emberforge (%s)" % g.arena_now())
	_check(int(g.terrain.get("left", 0)) == DuelRules.terrain_turns, "for %d turns" % DuelRules.terrain_turns)
	_check(g.players[0].discard.has(r) and g.players[0].total_card_count() == n0, "the Terrain Rite goes to the discard")
	_check(g.arena_rule_text().begins_with("A Ward that springs"), "the rule is the emberforge's: %s" % g.arena_rule_text())
	for i in DuelRules.terrain_turns - 1:
		await g._terrain_tick()
	_check(g.arena_now() == "emberforge", "still the emberforge before the last turn")
	await g._terrain_tick()
	_check(g.arena_now() == "solhaven" and g.terrain.is_empty(), "then the Circle is itself again (%s)" % g.arena_now())
	# Iron Ground: the Guard follows the ground
	var ig := _hand(g, 1, "iron_ground")
	g.current = 1
	var gd: int = g.players[0].guard()
	await g.perform(1, {"type": "rite", "card": ig})
	_check(g.players[0].guard() == gd + DuelRules.arena_guard, "Iron Ground raises the Guard at once")
	for i in DuelRules.terrain_turns:
		await g._terrain_tick()
	_check(g.players[0].guard() == gd, "and it falls again when the ground fades")


func _continuous() -> void:
	var g := _game()
	var pup := _put(g, 0, "cinderpup", 0)
	var kit := _put(g, 0, "sparkkit", 1)
	var foe := _put(g, 1, "brookfin", 0)
	var base_fire: int = g.attack_amount(pup, 0, 20, foe)
	var base_storm: int = g.attack_amount(kit, 0, 20, foe)
	var n0: int = g.players[0].total_card_count()
	var kb := _hand(g, 0, "kindled_banner")
	await g.perform(0, {"type": "rite", "card": kb})
	_check(g.players[0].continuous.has(kb) and not g.players[0].discard.has(kb), "Kindled Banner stands, not in the discard")
	_check(g.players[0].total_card_count() == n0 + 1, "a standing Rite still counts as one of the deck's cards")
	_check(g.attack_amount(pup, 0, 20, foe) == base_fire + 10, "the Banner: a Fire Totem hits 10 harder (%d -> %d)" % [base_fire, g.attack_amount(pup, 0, 20, foe)])
	_check(g.attack_amount(kit, 0, 20, foe) == base_storm, "...and a Storm one doesn't")
	# Tidewell heals at Dawn
	var tw := _hand(g, 0, "tidewell")
	await g.perform(0, {"type": "rite", "card": tw})
	pup.damage = 30
	await g._dawn_continuous(g.players[0])
	_check(pup.damage == 20, "Tidewell heals 10 at Dawn (damage %d)" % pup.damage)
	# a third pushes the oldest out
	var it := _hand(g, 0, "iron_tithe")
	await g.perform(0, {"type": "rite", "card": it})
	_check(g.players[0].continuous.size() == DuelRules.continuous_slots and not g.players[0].continuous.has(kb) and g.players[0].discard.has(kb),
		"a third standing Rite sends the oldest to the discard (%s)" % [g.players[0].continuous])
	# Iron Tithe: the rival's Wards and Rites cost 1 more
	var snare := _card("ambush_snare", 1)
	_check(g.card_cost(1, snare) == snare.cost() + 1, "Iron Tithe: the rival's Ward costs %d (was %d)" % [g.card_cost(1, snare), snare.cost()])
	_check(g.card_cost(0, _card("ambush_snare", 0)) == snare.cost(), "...but not their own")
	var fb := _card("firebrand", 1)
	_check(g.card_cost(1, fb) == fb.cost() + 1, "Iron Tithe: and their Rites (%d, was %d)" % [g.card_cost(1, fb), fb.cost()])
	var mt := _card("memory_thread", 1)
	_check(g.card_cost(1, mt) == 1, "...a free one too (%d)" % g.card_cost(1, mt))
	# Unbind
	g.current = 1
	var ub := _hand(g, 1, "unbind")
	var before: int = g.players[0].continuous.size()
	var c0: int = g.players[0].total_card_count()
	await g.perform(1, {"type": "rite", "card": ub})
	_check(g.players[0].continuous.size() == before - 1 and g.players[0].total_card_count() == c0, "Unbind sends one standing Rite to its owner's discard")
	var ub2 := _hand(g, 1, "unbind")
	g.players[0].continuous.clear()
	_check(g.rite_problem(1, ub2) != "", "Unbind with nothing standing can't be cast")
	# Thorn Hedge: an attacker takes 10
	g = _game()
	var hedge := _card("thorn_hedge", 1)
	g.players[1].continuous.append(hedge)
	var att := _put(g, 0, "cinderpup", 0)
	var tgt := _put(g, 1, "elderbark", 0)
	att.called_turn = 1
	g.phase = "clash"
	var mi := -1
	for i in att.moves().size():
		if not att.moves()[i].has("fate") and int(att.moves()[i].get("damage", 0)) > 0 and g.move_problem(0, att, i) == "":
			mi = i
			break
	if mi >= 0:
		await g.perform(0, {"type": "attack", "attacker": att, "move": mi, "target": tgt})
		_check(att.damage >= 10, "Thorn Hedge tears at the attacker (damage %d)" % att.damage)
	else:
		_check(false, "Cinderpup has a plain move to test the hedge with")
	# Storm Spire: Storm Totems attack the turn they're called
	g = _game()
	g.players[0].continuous.append(_card("storm_spire", 0))
	var s1 := _put(g, 0, "sparkkit", 0)
	var f1 := _put(g, 0, "cinderpup", 1)
	s1.called_turn = g.turn
	f1.called_turn = g.turn
	_check(g.ready_problem(0, s1) == "", "Storm Spire: a Storm Totem can attack the turn it's called (%s)" % g.ready_problem(0, s1))
	_check(g.ready_problem(0, f1) != "", "...a Fire one can't")
	# Shadow Veil: the first call each turn veiled at no extra cost
	g = _game()
	g.players[0].continuous.append(_card("shadow_veil", 0))
	var dc := _hand(g, 0, "dreamfox")
	g.players[0].essence = g.call_cost(0, dc)
	_check(g.action_problem(0, {"type": "call", "card": dc, "slot": 0, "veiled": true}) == "", "Shadow Veil: veiled for the plain cost")
	await g.perform(0, {"type": "call", "card": dc, "slot": 0, "veiled": true})
	_check(g.players[0].slots[0] != null and g.players[0].slots[0].face_down and g.players[0].essence == 0, "it's called face down for the plain cost")
	_check(not g.free_veil(0), "only the first call each turn")


func _favour() -> void:
	# sworn to Pyrrhane: Fire cards and attacks fill it
	var g := _game(["pyrrhane", ""])
	var pup := _hand(g, 0, "cinderpup")
	await g.perform(0, {"type": "call", "card": pup, "slot": 0})
	_check(g.players[0].favour2 == 2, "a Fire call fills a point of Pyrrhane's Favour (%d half points)" % g.players[0].favour2)
	var kit := _hand(g, 0, "sparkkit")
	await g.perform(0, {"type": "call", "card": kit, "slot": 1})
	_check(g.players[0].favour2 == 2, "a Storm call doesn't (%d)" % g.players[0].favour2)
	# the Unsworn: anything, at half pace
	g.current = 1
	var bf := _hand(g, 1, "brookfin")
	await g.perform(1, {"type": "call", "card": bf, "slot": 0})
	_check(g.players[1].favour2 == 1, "the Unsworn fill half a point from anything (%d)" % g.players[1].favour2)
	# the Law's own god: double
	g = _game(["pyrrhane", ""])
	g.law = "pyrrhane"
	var p2 := _hand(g, 0, "cinderpup")
	await g.perform(0, {"type": "call", "card": p2, "slot": 0})
	_check(g.players[0].favour2 == 4, "under Pyrrhane's Law, twice as fast (%d)" % g.players[0].favour2)
	# full: the Gift again
	g = _game(["pyrrhane", ""])
	g.players[0].favour2 = DuelRules.favour_max * 2 - 2
	g.players[0].gift_used = true
	_check(g.gift_problem(0) != "", "the Gift spent, it can't be used again")
	var p3 := _hand(g, 0, "cinderpup")
	await g.perform(0, {"type": "call", "card": p3, "slot": 0})
	_check(g.players[0].favour_ready and g.players[0].stats.favour_fills == 1, "full Favour")
	_check(g.gift_problem(0) == "", "full Favour opens the Gift again: %s" % g.gift_problem(0))
	await g.perform(0, {"type": "gift"})
	_check(not g.players[0].favour_ready and g.players[0].favour2 == 0 and g.players[0].wrath, "the second Gift (Wrath) empties it")
	# full: the Demigod, free
	g = _game(["pyrrhane", ""])
	_check(g.demigod_of(0) == "pyraxis", "Pyrrhane's Demigod is Pyraxis (%s)" % g.demigod_of(0))
	g.players[0].favour_ready = true
	g.players[0].favour2 = DuelRules.favour_max * 2
	var foe := _put(g, 1, "mossling", 0)
	var n0: int = g.players[0].total_card_count()
	var e0: int = g.players[0].essence
	await g.perform(0, {"type": "demigod"})
	_check(foe.damage > 0 or foe.is_knocked_out() or g.players[1].slots[0] == null, "the Demigod strikes")
	_check(g.players[0].total_card_count() == n0 and g.players[0].essence == e0, "from no card and for no Essence")
	_check(not g.players[0].favour_ready and g.players[0].stats.demigods == 1, "and it empties the Favour")
	# the Unsworn: Unbound Will, stronger
	g = _game(["", ""])
	for i in 6:
		g.players[0].deck.append(_card("cinderpup", 0))
	g.players[0].gift_used = true
	g.players[0].favour_ready = true
	var h0: int = g.players[0].hand.size()
	await g.perform(0, {"type": "gift"})
	_check(g.players[0].hand.size() == h0 + 3 and g.players[0].essence == 9, "full Favour: Unbound Will draws 3 and gives 1 Essence (hand %d, Essence %d)" % [g.players[0].hand.size() - h0, g.players[0].essence])
	_check(g.demigod_problem(0) != "", "the Unsworn have no Demigod")


func _oaths() -> void:
	var g := _game(["", ""])
	g.turn = 1
	_check(g.oath_problem(0, "faith") != "", "the Unsworn can't swear by a god's element")
	await g.perform(0, {"type": "oath", "oath": "unbowed"})
	var p: DuelPlayer = g.players[0]
	_check(p.oath == "unbowed" and p.oath_state == "sworn" and p.oath_start_used, "the Oath of the Unbowed is sworn at the start")
	_check(p.favour2 == DuelRules.oath_favour * 2, "it gives a Favour head start (%d)" % p.favour2)
	_check(g.oath_problem(0, "swift") != "", "one Oath at a time")
	p.life = 70
	await g._check_oaths()
	_check(p.oath_state == "broken" and p.life == 70 - DuelRules.oath_life_cost, "Life under half breaks it, and it costs %d Life (%d)" % [DuelRules.oath_life_cost, p.life])
	_check(g.oath_problem(0, "swift") != "", "the start's Oath is spent on the first turn")
	g.turn = 5
	_check(g.oath_problem(0, "swift") == "", "once more mid-duel: %s" % g.oath_problem(0, "swift"))
	await g.perform(0, {"type": "oath", "oath": "swift"})
	_check(p.oath_mid_used and p.oath_state == "sworn", "the Swift End sworn mid-duel")
	g.turn = DuelRules.oath_turns * 2 - 1
	var life0: int = p.life
	await g._oath_dusk(p)
	_check(p.oath_state == "broken" and p.life == life0 - DuelRules.oath_life_cost, "the Swift End breaks at the Dusk of the turn it named")
	g.turn = 21
	_check(g.oath_problem(0, "unbowed") != "", "no third Oath")
	# Faith, kept at the win, and the Resonance for it
	g = _game(["pyrrhane", ""])
	g.turn = 1
	await g.perform(0, {"type": "oath", "oath": "faith"})
	_put(g, 0, "cinderpup", 0)
	g._finish(0, "A wins.")
	_check(g.players[0].oath_state == "kept" and g.players[0].stats.oaths_kept == 1, "the Oath of the Faithful is kept with a Fire Totem on the field")
	var rs := DuelRewards.resonance(g, 0)
	_check((rs.lines as Array).any(func(l): return String(l.text) == "Oath kept"), "a kept Oath adds to the Resonance")
	g = _game(["pyrrhane", ""])
	g.turn = 1
	await g.perform(0, {"type": "oath", "oath": "faith"})
	_put(g, 0, "sparkkit", 0)
	g._finish(0, "A wins.")
	_check(g.players[0].oath_state == "broken", "...and broken with none")


func _whole_duels() -> void:
	var refused := 0
	var totals := {"terrains": 0, "continuous": 0, "favour_fills": 0, "demigods": 0, "oaths": 0}
	var arenas := ["ashford", "tidegrove", "emberforge", "ironstone", "veilwild", "solhaven"]
	var patrons := ["", "solmaris", "pyrrhane", "vaelith", "ixara", "nocthra", "oriel", "aldrith"]
	for n in 24:
		var g := DuelGame.new()
		var decks := DuelCards.DECKS.keys()
		var profs := []
		for i in 2:
			var pr := Lore.new_profile("P%d" % (i + 1), "", 4)
			pr["patron"] = patrons[(n * 3 + i * 5) % patrons.size()]
			profs.append(pr)
		g.setup([decks[n % 4], decks[(n / 4) % 4]], ["P1", "P2"], [DuelAI.new(1.0, 370 + n), DuelAI.new(1.0, 410 + n)], profs, 1900 + n)
		g.arena = arenas[n % arenas.size()]
		await g.run()
		_check(g.over, "duel %d ends" % n)
		for line in g.log_lines:
			if String(line).begins_with("(Not allowed"):
				refused += 1
				if refused <= 3:
					print("  refused: ", line)
		for p in g.players:
			for k in totals:
				totals[k] += int(p.stats[k])
			_check(p.total_card_count() == DuelRules.deck_size, "duel %d: %s keeps %d cards (has %d)" % [n, p.player_name, DuelRules.deck_size, p.total_card_count()])
	_check(refused == 0, "the computer asked for %d things it may not do" % refused)
	_check(totals.continuous > 0, "the computer cast Continuous Rites (%d)" % totals.continuous)
	_check(totals.terrains > 0, "the computer turned the ground (%d)" % totals.terrains)
	_check(totals.favour_fills > 0, "Favour filled (%d)" % totals.favour_fills)
	_check(totals.oaths > 0, "the computer swore Oaths (%d)" % totals.oaths)
	print("  24 duels: %s" % totals)
