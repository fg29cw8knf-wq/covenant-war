extends SceneTree
## Phase B of the deeper duel, on the rules engine alone: Tribute calls, the
## Echoes in the discard, Loyal, Rekindling, Riposte and Galvanise, the six
## new Rites, and whole duels where the computer pays tributes and uses its
## discard without ever asking for something it may not do.
##   godot --headless --script res://tests/phase_b_test.gd

var fails := 0


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
	await _tributes()
	await _discard()
	await _rites()
	await _whole_duels()
	print("PHASE B TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


var _uid := 5000


func _card(id: String, owner: int) -> DuelCard:
	_uid += 1
	return DuelCard.new(_uid, id, owner)


func _game() -> DuelGame:
	var g := DuelGame.new()
	g.setup(["emberstorm", "tidegrove"], ["A", "B"], [Picker.new(), Picker.new()], [], 3)
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
	var t := DuelTotem.new(_card(id, pi), pi, slot, 1, {})
	g.players[pi].slots[slot] = t
	return t


func _tributes() -> void:
	var g := _game()
	var drake := _card("ashen_drake", 0)
	var seraph := _card("sunlance_seraph", 0)
	g.players[0].hand.append_array([drake, seraph])
	_check(g.tributes_needed(drake) == 1, "a Legend (tier 3) needs one tribute")
	_check(g.tributes_needed(seraph) == 2, "a tier 5 needs two")
	_check(g.tributes_needed(_card("cinderpup", 0)) == 0, "a Spark needs none")
	_check(g.call_problem(0, drake) != "", "no Totem of yours on the field: the drake can't be called (%s)" % g.call_problem(0, drake))
	var pup := _put(g, 0, "cinderpup", 0)
	var wisp := _put(g, 0, "emberwisp", 1)
	var kit := _put(g, 0, "sparkkit", 2)
	_check(g.call_problem(0, drake) == "", "with Totems on the field, it can be: %s" % g.call_problem(0, drake))
	_check(g.call_problem(0, drake, 0, []) != "", "but not without naming the tribute")
	_check(g.call_problem(0, drake, 1, [pup]) != "", "a full slot that isn't the tribute's is taken")
	_check(g.call_problem(0, drake, 0, [pup]) == "", "the tribute's own slot is free for it: %s" % g.call_problem(0, drake, 0, [pup]))
	var ess: int = g.players[0].essence
	await g.perform(0, {"type": "call", "card": drake, "slot": 0, "tributes": [pup]})
	var t0 = g.players[0].slots[0]
	_check(t0 != null and t0.id() == "ashen_drake", "the drake stands where the pup was")
	_check(g.players[0].discard.has(pup.top()), "the pup is in the discard")
	_check(g.players[0].essence == ess - g.call_cost(0, drake), "its Essence is paid too")
	_check(g.players[0].stats.tributes == 1, "one tribute counted")
	_check(g.call_problem(0, seraph, 1, [wisp]) != "", "the seraph wants two")
	_check(g.call_problem(0, seraph, 1, [wisp, kit]) == "" or g.call_cost(0, seraph) > g.players[0].essence, "two given, it can come: %s" % g.call_problem(0, seraph, 1, [wisp, kit]))
	_check(g.players[0].total_card_count() == 30 + 5, "no card lost or doubled (%d, want 35: the deck and five made for the test)" % g.players[0].total_card_count())


func _discard() -> void:
	# an Echo: the pup in the discard answers the next fall
	var g := _game()
	var foe := _put(g, 1, "brookfin", 1)
	var fall := _put(g, 0, "emberwisp", 1)
	g.players[0].discard.append(_card("cinderpup", 0))
	var hp := foe.hp_left()
	fall.last_hit_by = foe
	fall.damage = fall.max_hp()
	await g._resolve_knockouts()
	_check(hp - foe.hp_left() == 10, "Cinderpup's Echo: 10 to the Totem that felled it (took %d)" % (hp - foe.hp_left()))
	var fall2 := _put(g, 0, "sparkkit", 1)
	fall2.last_hit_by = foe
	fall2.damage = fall2.max_hp()
	hp = foe.hp_left()
	await g._resolve_knockouts()
	_check(hp == foe.hp_left(), "an Echo answers once a duel")
	# Loyal: the hound calls itself into the empty slot, free
	g = _game()
	foe = _put(g, 1, "brookfin", 1)
	var hound := _card("shieldhound", 0)
	g.players[0].hand.append(hound)
	fall = _put(g, 0, "pebblit", 2)
	fall.last_hit_by = foe
	fall.damage = fall.max_hp()
	var ess: int = g.players[0].essence
	await g._resolve_knockouts()
	var s2 = g.players[0].slots[2]
	_check(s2 != null and s2.id() == "shieldhound", "Loyal: the Shieldhound takes the empty slot")
	_check(g.players[0].essence == ess, "free")
	# Rekindling: back at Dawn with half its HP, once
	g = _game()
	var sal := _card("hearth_salamander", 0)
	g.players[0].discard.append(sal)
	await g._dawn_rekindle(g.players[0])
	var back: DuelTotem = null
	for t in g.players[0].totems():
		if t.id() == "hearth_salamander":
			back = t
	_check(back != null and back.hp_left() == back.max_hp() / 2, "Rekindling: the Salamander is back with half its HP (%s)" % [back])
	back.damage = back.max_hp()
	await g._resolve_knockouts()
	await g._dawn_rekindle(g.players[0])
	var again: bool = g.players[0].totems().any(func(t): return t.id() == "hearth_salamander")
	_check(not again, "once a duel")
	# Riposte and Galvanise
	g = _game()
	var att := _put(g, 0, "cinderpup", 1)
	var fox := _put(g, 1, "veilfox", 1)
	await g._damage_totem(fox, 10, {"attacker": att})
	_check(att.has_status("confused"), "Riposte: the attacker is Confused")
	var caller := _put(g, 1, "stormcaller", 0)
	await g._damage_totem(caller, 10, {"attacker": att})
	_check(caller.has_boon("empowered"), "Galvanise: it becomes Empowered")


func _rites() -> void:
	var g := _game()
	var dawn := _card("second_dawn", 0)
	g.players[0].hand.append(dawn)
	_check(g.rite_problem(0, dawn) != "", "Second Dawn needs a Totem in the discard")
	var pup := _card("cinderpup", 0)
	g.players[0].discard.append(pup)
	await g.perform(0, {"type": "rite", "card": dawn})
	_check(g.players[0].hand.has(pup), "Second Dawn: the pup is back in the hand")
	# Rekindle: to the field at half
	var rk := _card("rekindle", 0)
	g.players[0].hand.append(rk)
	var wisp := _card("emberwisp", 0)
	g.players[0].discard.append(wisp)
	await g.perform(0, {"type": "rite", "card": rk})
	var w: DuelTotem = null
	for t in g.players[0].totems():
		if t.id() == "emberwisp":
			w = t
	_check(w != null and w.hp_left() == w.max_hp() / 2, "Rekindle: the wisp stands again at half (%s)" % [w])
	# the Rite of Ashes needs three of one element
	var ashes := _card("rite_of_ashes", 0)
	g.players[0].hand.append(ashes)
	var foe := _put(g, 1, "brookfin", 1)
	_check(g.rite_problem(0, ashes) != "", "the Rite of Ashes needs three of one element")
	for id in ["cinderpup", "blazehound", "emberwisp"]:
		g.players[0].discard.append(_card(id, 0))
	_check(g.rite_problem(0, ashes) == "", "with three Fire Totems in the discard it works: %s" % g.rite_problem(0, ashes))
	var hp := foe.hp_left()
	await g.perform(0, {"type": "rite", "card": ashes})
	_check(hp - foe.hp_left() >= 40, "it deals 40 to each enemy Totem (took %d)" % (hp - foe.hp_left()))
	# Kindred Seek: a Totem of an element on the field
	g = _game()
	_put(g, 0, "cinderpup", 0)
	var seek := _card("kindred_seek", 0)
	g.players[0].hand.append(seek)
	var before: int = g.players[0].hand.size()
	await g.perform(0, {"type": "rite", "card": seek})
	var found: DuelCard = g.players[0].hand[-1] if g.players[0].hand.size() >= before else null
	_check(found != null and found.is_totem() and found.element() == "fire", "Kindred Seek: a Fire Totem from the deck (%s)" % [found])
	# Memory Thread: a card from the discard on top of the deck
	var thread := _card("memory_thread", 0)
	g.players[0].hand.append(thread)
	var gone := _card("thunderclap", 0)
	g.players[0].discard.clear()
	g.players[0].discard.append(gone)
	await g.perform(0, {"type": "rite", "card": thread})
	_check(g.players[0].deck[-1] == gone, "Memory Thread: the discarded card is on top of the deck")
	# Hour of Need: a Legend free, while behind
	g = _game()
	var hour := _card("hour_of_need", 0)
	var drake := _card("ashen_drake", 0)
	g.players[0].hand.append_array([hour, drake])
	_check(g.rite_problem(0, hour) != "", "Hour of Need: not while ahead or level")
	g.players[0].life = 60
	_check(g.rite_problem(0, hour) == "", "behind, it works: %s" % g.rite_problem(0, hour))
	var ess: int = g.players[0].essence
	await g.perform(0, {"type": "rite", "card": hour})
	var d: bool = g.players[0].totems().any(func(t): return t.id() == "ashen_drake")
	_check(d, "the drake is called, without a tribute")
	_check(g.players[0].essence == ess - g.rite_cost(0, hour), "and without its Essence")


func _whole_duels() -> void:
	var refused := 0
	var totals := {"tributes": 0, "echoes": 0, "revivals": 0}
	for n in 16:
		var g := DuelGame.new()
		var decks := DuelCards.DECKS.keys()
		g.setup([decks[n % 4], decks[(n / 4) % 4]], ["P1", "P2"], [DuelAI.new(1.0, 70 + n), DuelAI.new(1.0, 110 + n)], [], 500 + n)
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
	_check(totals.tributes > 0, "the computer paid tributes (%d)" % totals.tributes)
	print("  16 duels: %s" % totals)
