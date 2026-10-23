extends SceneTree
## Phase C of the deeper duel, on the rules engine alone: bonds (a move and
## a stat, live only while both stand), Relics (one each, their effects,
## gone with the Totem), veiled calls (+1 Essence, revealed when attacking,
## attacked or at Dawn, Reveals), the second Ascension stage (a turn after
## the first), Tempering, and whole duels where the computer uses all of it.
##   godot --headless --script res://tests/phase_c_test.gd

var fails := 0
var _uid := 7000


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
	await _bonds()
	await _relics()
	await _veiled()
	await _ascension()
	await _temper()
	await _whole_duels()
	print("PHASE C TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


func _card(id: String, owner: int) -> DuelCard:
	_uid += 1
	return DuelCard.new(_uid, id, owner)


func _game() -> DuelGame:
	var g := DuelGame.new()
	g.setup(["emberstorm", "tidegrove"], ["A", "B"], [Picker.new(), Picker.new()], [], 5)
	g.turn = 3
	g.current = 0
	g.phase = "main"
	for pl in g.players:
		pl.essence_max = 8
		pl.essence = 8
		pl.life = 150
		pl.max_life = 150
		pl.hand.clear()
	return g


func _put(g: DuelGame, pi: int, id: String, slot: int) -> DuelTotem:
	var t := g._new_totem(_card(id, pi), pi, slot, 1)
	g.players[pi].slots[slot] = t
	return t


func _bonds() -> void:
	var g := _game()
	var pup := _put(g, 0, "cinderpup", 0)
	var n0: int = pup.moves().size()
	var kit := _put(g, 0, "sparkkit", 1)
	g.refresh_bonds()
	_check(not pup.bond.is_empty() and not kit.bond.is_empty(), "Cinderpup and Sparkkit are bonded")
	_check(pup.moves().size() == n0 + 1 and pup.moves()[-1].has("bond"), "Cinderpup has the bond move")
	_check(String(pup.moves()[-1].name) == "Wildfire Dash", "it's Wildfire Dash (%s)" % pup.moves()[-1].name)
	g.phase = "clash"
	_check(g.move_problem(0, pup, pup.moves().size() - 1) == "", "the bond move can be used: %s" % g.move_problem(0, pup, pup.moves().size() - 1))
	g.players[0].slots[1] = null
	g.refresh_bonds()
	_check(pup.bond.is_empty() and pup.moves().size() == n0, "the partner gone, the bond goes with it")
	# a stat bond
	var wisp := _put(g, 0, "emberwisp", 1)
	var sal := _put(g, 0, "hearth_salamander", 2)
	var hp0: int = wisp.max_hp()
	g.refresh_bonds()
	_check(wisp.max_hp() == hp0 + 20 and not sal.bond.is_empty(), "Hearthlight: +20 HP for both (%d, was %d)" % [wisp.max_hp(), hp0])


func _relics() -> void:
	var g := _game()
	var pup := _put(g, 0, "cinderpup", 0)
	var collar := _card("ember_collar", 0)
	g.players[0].hand.append(collar)
	var b0: int = pup.damage_bonus(0)
	_check(g.relic_problem(0, collar, pup) == "", "the collar can go on the pup: %s" % g.relic_problem(0, collar, pup))
	await g.perform(0, {"type": "relic", "card": collar, "target": pup})
	_check(pup.relic == collar and pup.damage_bonus(0) == b0 + 10, "Ember Collar: +10 damage")
	var pearl := _card("tide_pearl", 0)
	g.players[0].hand.append(pearl)
	_check(g.relic_problem(0, pearl, pup) != "", "one Relic each")
	_check(g.players[0].total_card_count() == 30 + 3, "the Relic counts among its owner's cards (%d)" % g.players[0].total_card_count())
	# it falls: the Relic goes to the discard; a Spirit Lantern draws
	var lantern := _card("spirit_lantern", 0)
	var wisp := _put(g, 0, "emberwisp", 1)
	wisp.relic = lantern
	var hand_n: int = g.players[0].hand.size()
	wisp.damage = wisp.max_hp()
	pup.damage = pup.max_hp()
	await g._resolve_knockouts()
	_check(g.players[0].discard.has(collar) and g.players[0].discard.has(lantern), "fallen, their Relics go to the discard")
	_check(g.players[0].hand.size() >= hand_n + 2, "the Spirit Lantern draws two (hand %d, was %d)" % [g.players[0].hand.size(), hand_n])
	# Relic Hunt fetches one back
	var hunt := _card("relic_hunt", 0)
	g.players[0].hand.append(hunt)
	await g.perform(0, {"type": "rite", "card": hunt})
	_check(g.players[0].hand.has(collar) or g.players[0].hand.has(lantern), "Relic Hunt: a Relic back in the hand")
	# a dawn relic, and a keyword one
	g = _game()
	var t := _put(g, 0, "brookfin", 0)
	t.relic = _card("iron_brace", 0)
	await g._dawn_relics_and_veils(g.players[0])
	_check(t.shield >= 20, "Iron Brace: shielded at Dawn (%d)" % t.shield)
	var s2 := _put(g, 0, "mossling", 1)
	s2.relic = _card("stone_heart", 0)
	_check(s2.has_keyword("guardian"), "Stone Heart: a Guardian")
	var f := _put(g, 0, "dreamfox", 2)
	f.relic = _card("hunters_fang", 0)
	_check(String(f.moves()[-1].name) == "Rend", "Hunter's Fang: a new move")


func _veiled() -> void:
	var g := _game()
	var foe := _put(g, 1, "brookfin", 0)
	var fox := _card("dreamfox", 0)
	g.players[0].hand.append(fox)
	var ess: int = g.players[0].essence
	await g.perform(0, {"type": "call", "card": fox, "slot": 0, "veiled": true})
	var t = g.players[0].slots[0]
	_check(t != null and t.face_down, "called veiled: face down")
	_check(g.players[0].essence == ess - g.call_cost(0, fox) - 1, "for one more Essence")
	await g._dawn_relics_and_veils(g.players[0])
	_check(not t.face_down, "revealed at its owner's Dawn")
	_check(foe.has_status("sleep"), "Dreamfox's Reveal: the Totem across falls asleep")
	# revealed when it attacks
	g = _game()
	var wisp := _card("emberwisp", 0)
	g.players[0].hand.append(wisp)
	var across := _put(g, 1, "sparkkit", 1)
	await g.perform(0, {"type": "call", "card": wisp, "slot": 1, "veiled": true})
	var w = g.players[0].slots[1]
	g.turn += 2
	g.phase = "clash"
	var hp: int = across.hp_left()
	await g.perform(0, {"type": "attack", "attacker": w, "move": 0, "target": across})
	_check(not w.face_down, "revealed when it attacks")
	_check(hp - across.hp_left() >= 20, "Emberwisp's Reveal and its Spark both land (lost %d)" % (hp - across.hp_left()))


func _ascension() -> void:
	var g := _game()
	var hound := _put(g, 0, "cinderpup", 0)
	var blaze := _card("blazehound", 0)
	var warg := _card("infernal_warg", 0)
	g.players[0].hand.append_array([blaze, warg])
	await g.perform(0, {"type": "ascend", "card": blaze, "target": hound})
	_check(hound.id() == "blazehound", "Cinderpup ascends into Blazehound")
	_check(g.ascend_problem(0, warg) != "", "not into the Warg the same turn")
	g.turn += 2
	_check(g.ascend_problem(0, warg) == "", "the next turn, it can: %s" % g.ascend_problem(0, warg))
	await g.perform(0, {"type": "ascend", "card": warg, "target": hound})
	_check(hound.id() == "infernal_warg" and hound.stage() == 2, "the second stage: Infernal Warg")
	_check(DuelCards.CARDS.infernal_warg.has("stand_in"), "the Warg has a stand-in to show until its model comes")


func _temper() -> void:
	var g := _game()
	g.players[0].profile["temper"] = {"cinderpup": 3}
	var t := g._new_totem(_card("cinderpup", 0), 0, 0, 1)
	var plain := DuelTotem.new(_card("cinderpup", 0), 0, 1, 1, {})
	_check(t.max_hp() == plain.max_hp() + 20, "Tempered once: +20 Life")
	var fate_t: Dictionary = {}
	var fate_p: Dictionary = {}
	for m in t.moves():
		if m.has("fate"):
			fate_t = m
			break
	for m in plain.moves():
		if m.has("fate"):
			fate_p = m
			break
	_check(not fate_t.is_empty() and int(fate_t.fate[-2].to) == int(fate_p.fate[-2].to) - 2, "Tempered twice: the best band starts two lower")
	_check(t.moves().size() == plain.moves().size() + 1 and t.moves()[-1].get("tempered", false), "Tempered three times: a new move")
	_check(int(plain.moves()[1].fate[-2].to) == int(DuelCards.CARDS.cinderpup.moves[1].fate[-2].to), "the card's own data is untouched")


func _whole_duels() -> void:
	var refused := 0
	var totals := {"relics": 0, "veiled": 0, "bond_moves": 0, "ascensions": 0}
	for n in 16:
		var g := DuelGame.new()
		var decks := DuelCards.DECKS.keys()
		g.setup([decks[n % 4], decks[(n / 4) % 4]], ["P1", "P2"], [DuelAI.new(1.0, 170 + n), DuelAI.new(1.0, 210 + n)], [], 900 + n)
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
	_check(totals.relics > 0, "the computer gave Relics (%d)" % totals.relics)
	print("  16 duels: %s" % totals)
