extends SceneTree
## Phase A of the deeper duel, on the rules engine alone: the turn's phases
## gate what can be done, Stances do what they say, the response window lets
## an answer be played on the rival's turn and answered back (last in, first
## out), a Ward from the hand plays once a duel, and the computer never asks
## for something its phase forbids over a whole duel.
##   godot --headless --script res://tests/phase_test.gd

var fails := 0


## A controller that answers with the first card it's given (or never).
class Answerer:
	extends RefCounted
	var answers := true
	var picks: Array = []   # card ids to answer with, in order; [] = the first offered
	func choose_action(_game: DuelGame, _pi: int) -> Dictionary:
		return {"type": "end"}
	func choose_response(_game: DuelGame, _pi: int, _event: Dictionary, cards: Array) -> DuelCard:
		if not answers or cards.is_empty():
			return null
		if picks.is_empty():
			return cards[0]
		for c in cards:
			if c.id == picks[0]:
				picks.pop_front()
				return c
		return null
	func choose_slot(_game: DuelGame, _pi: int, _prompt: String, slots: Array, _context: Dictionary) -> int:
		return slots[0]
	func choose_cards(_game: DuelGame, _pi: int, _prompt: String, cards: Array, min_n: int, _max_n: int, _context: Dictionary) -> Array:
		return cards.slice(0, min_n)
	func choose_totems(_game: DuelGame, _pi: int, _prompt: String, totems: Array, min_n: int, _max_n: int) -> Array:
		return totems.slice(0, min_n)
	func choose_reroll(_game: DuelGame, _pi: int, _info: Dictionary) -> bool:
		return false
	func choose_scry(_game: DuelGame, _pi: int, _card: DuelCard) -> bool:
		return true


func _initialize() -> void:
	# the turn's phases are off in the game since 27 October (Gary: "let's go
	# back to how we used to have it"); the Lab can turn them on, so the phase
	# rules are checked with them on, and the rest both ways
	DuelRules.phases = true
	_phases()
	for on in [false, true]:
		DuelRules.phases = on
		print("  (turn phases %s)" % ("on" if on else "off"))
		_stances()
		_answers()
		await _whole_duels()
	DuelRules.phases = false
	print("PHASE TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


## A board mid-duel: it's turn 3, player 0 to act, one Totem each.
func _board(p0 = null, p1 = null) -> Dictionary:
	var g := DuelGame.new()
	var a = p0 if p0 != null else Answerer.new()
	var b = p1 if p1 != null else Answerer.new()
	g.setup(["emberstorm", "tidegrove"], ["A", "B"], [a, b], [], 3)
	g.turn = 3
	g.current = 0
	for pl in g.players:
		pl.essence_max = 5
		pl.essence = 5
		pl.life = 150
		pl.max_life = 150
	var mine := DuelTotem.new(DuelCard.new(900, "cinderpup", 0), 0, 1, 1, {})
	var theirs := DuelTotem.new(DuelCard.new(901, "brookfin", 1), 1, 1, 1, {})
	g.players[0].slots[1] = mine
	g.players[1].slots[1] = theirs
	return {"g": g, "mine": mine, "theirs": theirs}


func _give(g: DuelGame, pi: int, id: String) -> DuelCard:
	var c := DuelCard.new(950 + g.players[pi].hand.size() + pi * 20, id, pi)
	g.players[pi].hand.append(c)
	return c


func _phases() -> void:
	var b := _board()
	var g: DuelGame = b.g
	var mine: DuelTotem = b.mine
	var theirs: DuelTotem = b.theirs
	var pup := _give(g, 0, "cinderpup")
	var brand := _give(g, 0, "firebrand")
	var snare := _give(g, 0, "ambush_snare")
	g.phase = "main"
	var attack := {"type": "attack", "attacker": mine, "move": 0, "target": theirs}
	_check(g.action_problem(0, attack) != "", "no attacking in the Main phase")
	_check(g.action_problem(0, {"type": "call", "card": pup, "slot": 0}) == "", "a call is allowed in the Main phase")
	_check(g.action_problem(0, {"type": "ward", "card": snare}) == "", "a Ward is set in the Main phase")
	_check(g.action_problem(0, {"type": "rite", "card": brand, "target": theirs}) == "", "a Rite is cast in the Main phase")
	_check(g.action_problem(0, {"type": "stance", "totem": mine, "stance": "guard"}) == "", "a stance is set in the Main phase")
	_check(g.next_phase(0) == "clash", "from Main, with a Totem ready, next is the Clash (got %s)" % g.next_phase(0))
	g.phase = "clash"
	_check(g.action_problem(0, attack) == "", "attacking in the Clash: %s" % g.action_problem(0, attack))
	_check(g.action_problem(0, {"type": "call", "card": pup, "slot": 0}) != "", "no calling in the Clash")
	_check(g.action_problem(0, {"type": "rite", "card": brand, "target": theirs}) != "", "no Rites in the Clash")
	_check(g.action_problem(0, {"type": "stance", "totem": mine, "stance": "guard"}) != "", "no stances in the Clash")
	_check(g.next_phase(0) == "main2", "from the Clash, with a Rite in hand, next is the second Main (got %s)" % g.next_phase(0))
	g.phase = "main2"
	_check(g.action_problem(0, {"type": "rite", "card": brand, "target": theirs}) == "", "a Rite in the second Main")
	_check(g.action_problem(0, {"type": "shift", "totem": mine, "slot": 0}) == "", "a Shift in the second Main")
	_check(g.action_problem(0, {"type": "call", "card": pup, "slot": 0}) != "", "no calling in the second Main")
	_check(g.action_problem(0, attack) != "", "no attacking in the second Main")
	_check(g.next_phase(0) == "end", "from the second Main, next ends the turn")
	# a Totem that can't attack: the Clash is skipped
	g.phase = "main"
	mine.attacked = true
	g.players[0].hand.clear()
	g.players[0].essence = 0
	g.players[0].gift_used = true
	_check(g.next_phase(0) == "end", "with nothing to attack with and nothing to cast, next ends the turn (got %s)" % g.next_phase(0))


func _stances() -> void:
	var b := _board()
	var g: DuelGame = b.g
	var mine: DuelTotem = b.mine
	g.phase = "main"
	_check(mine.stance == "strike", "a Totem starts in Strike")
	await g.perform(0, {"type": "stance", "totem": mine, "stance": "guard"})
	_check(mine.stance == "guard", "Guard is set")
	_check(g.ready_problem(0, mine) != "", "a guarding Totem can't attack")
	var before := mine.hp_left()
	await g._damage_totem(mine, 40, {"attacker": b.theirs})
	_check(before - mine.hp_left() == 20, "Guard halves a 40 blow to 20 (took %d)" % (before - mine.hp_left()))
	await g._damage_totem(mine, 10, {"source": "burn"})
	_check(before - mine.hp_left() == 30, "Guard doesn't halve a burn (took %d in all)" % (before - mine.hp_left()))
	# one stance a turn: no going back to Strike now; a new turn, and Rest mends and pays
	_check(g.stance_problem(0, mine, "strike") != "", "a stance holds for the turn")
	g.turn += 2
	mine.stance = "strike"
	var ess: int = g.players[0].essence
	var dmg := mine.damage
	await g.perform(0, {"type": "stance", "totem": mine, "stance": "rest"})
	_check(mine.stance == "rest", "Rest is set")
	_check(dmg - mine.damage == DuelRules.rest_heal, "Rest mends %d (mended %d)" % [DuelRules.rest_heal, dmg - mine.damage])
	_check(g.players[0].essence == ess and g.players[0].pending_essence == DuelRules.rest_essence, "Rest gives %d Essence at the next turn" % DuelRules.rest_essence)
	_check(g.stance_problem(0, mine, "strike") != "", "a resting Totem stays put")
	_check(g.shift_problem(0, mine, 0) != "", "a resting Totem can't Shift")
	_check(g.ready_problem(0, mine) != "", "a resting Totem can't attack")
	# a new turn puts every stance back to Strike
	g.current = 0
	var c0 = g.players[0].controller
	g.players[0].controller = Answerer.new()
	await g._take_turn()
	_check(mine.stance == "strike", "the stance is back to Strike at the owner's next turn (is %s)" % mine.stance)
	g.players[0].controller = c0


func _answers() -> void:
	# 1. an answer that cancels the attack
	var b := _board()
	var g: DuelGame = b.g
	var sigil := _give(g, 1, "null_sigil")
	g.phase = "clash"
	var hp: int = b.theirs.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.theirs.hp_left() == hp, "Null Sigil cancels the attack (Brookfin lost %d)" % (hp - b.theirs.hp_left()))
	_check(g.players[1].discard.has(sigil), "the answer is spent")
	_check(g.players[1].essence == 2, "its cost is paid (Essence %d)" % g.players[1].essence)
	_check(g.players[1].stats.answers == 1, "it counts as an answer")

	# 2. a chain: the answer is answered, last in first out
	b = _board()
	g = b.g
	sigil = _give(g, 1, "null_sigil")
	var glyph := _give(g, 0, "undertow_glyph")
	g.phase = "clash"
	hp = b.theirs.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.theirs.hp_left() < hp, "the attack lands once Undertow Glyph has swept Null Sigil away")
	_check(g.players[1].hand.has(sigil), "the swept answer is back in its hand")
	_check(g.players[0].discard.has(glyph), "Undertow Glyph is spent")

	# 3. the chain is capped
	b = _board()
	g = b.g
	var keep := DuelRules.chain_max
	DuelRules.chain_max = 1
	_give(g, 1, "null_sigil")
	_give(g, 0, "undertow_glyph")
	g.phase = "clash"
	hp = b.theirs.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.theirs.hp_left() == hp, "with one answer allowed, Null Sigil stands and the attack is cancelled")
	DuelRules.chain_max = keep

	# 4. a Ward from the hand, once a duel
	b = _board()
	g = b.g
	var reflex := _give(g, 1, "lightning_reflex")
	g.phase = "clash"
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.mine.has_status("shocked"), "Lightning Reflex from the hand shocks the attacker")
	_check(g.players[1].hand_wards_used.has("lightning_reflex"), "the hand Ward is marked used")
	var reflex2 := _give(g, 1, "lightning_reflex")
	_check(g.answer_problem(1, reflex2, {"type": "attack", "attacker": b.mine, "target": b.theirs}) != "", "a second Lightning Reflex can't be played from the hand this duel")
	_check(g.ward_problem(1, reflex2) == "", "it can still be set as a Ward")

	# 5. an answer Rite can't be cast on one's own turn
	b = _board()
	g = b.g
	var shroud := _give(g, 0, "ashen_shroud")
	g.phase = "main"
	_check(g.rite_problem(0, shroud) != "", "an answer isn't cast on its owner's turn")
	if DuelRules.phases:   # (with phases off the Totem's attack is something to do in the Main)
		_check(not g.can_do_anything_but_end(0) or g.players[0].hand.size() > 1, "an answer in hand isn't 'something to do'")

	# 6. halving, and a sidestep onto an empty slot
	b = _board()
	g = b.g
	_give(g, 1, "ashen_shroud")
	g.phase = "clash"
	hp = b.theirs.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(hp - b.theirs.hp_left() == 10, "Ashen Shroud halves Nip's 10 to 10 (the smallest blow) (took %d)" % (hp - b.theirs.hp_left()))
	b = _board()
	g = b.g
	_give(g, 1, "quicksilver_step")
	g.phase = "clash"
	hp = b.theirs.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.theirs.hp_left() == hp, "Quicksilver Step: the Totem steps aside and the blow finds air (lost %d)" % (hp - b.theirs.hp_left()))
	_check(b.theirs.slot != 1, "it stands in another slot now")

	# 7. Root Toll on a call, Whisper of Pages on a Ward set
	b = _board()
	g = b.g
	_give(g, 1, "root_toll")
	var pup := _give(g, 0, "cinderpup")
	g.phase = "main"
	var ess: int = g.players[1].essence
	await g.perform(0, {"type": "call", "card": pup, "slot": 0})
	_check(g.players[1].essence == ess + 1 and g.players[1].pending_essence == 1, "Root Toll: 1 Essence now and 1 at the next turn")
	_give(g, 1, "whisper_of_pages")
	var snare := _give(g, 0, "ambush_snare")
	var hand_n: int = g.players[1].hand.size()
	await g.perform(0, {"type": "ward", "card": snare})
	_check(g.players[1].hand.size() == hand_n, "Whisper of Pages: the answer leaves the hand and a card is drawn (hand %d, was %d)" % [g.players[1].hand.size(), hand_n])

	# 8. Rune Break cancels a Ward as it springs
	b = _board()
	g = b.g
	var veil := DuelCard.new(990, "mirror_veil", 1)
	g.players[1].wards.append(veil)
	_give(g, 0, "rune_break")
	g.phase = "clash"
	hp = b.theirs.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.theirs.hp_left() < hp, "Rune Break: Mirror Veil fizzles and the attack lands")
	_check(g.players[1].discard.has(veil), "the Ward is still spent")

	# 9. the Guardian takes the blow
	b = _board()
	g = b.g
	var hound := DuelTotem.new(DuelCard.new(991, "brassback", 1), 1, 0, 1, {})
	g.players[1].slots[0] = hound
	_give(g, 1, "shieldwall_call")
	g.phase = "clash"
	hp = b.theirs.hp_left()
	var hhp := hound.hp_left()
	await g.perform(0, {"type": "attack", "attacker": b.mine, "move": 0, "target": b.theirs})
	_check(b.theirs.hp_left() == hp and hound.hp_left() < hhp, "Shieldwall Call: the Brassback takes the blow")


## Whole duels between two computer players: every action the computer asks
## for is allowed (no "Not allowed" in the log), every duel ends, the cards
## all come back.
func _whole_duels() -> void:
	var refused := 0
	var answers := 0
	var stances := 0
	for n in 12:
		var g := DuelGame.new()
		var decks := DuelCards.DECKS.keys()
		g.setup([decks[n % 4], decks[(n / 4 + 1) % 4]], ["P1", "P2"], [DuelAI.new(1.0, 50 + n), DuelAI.new(1.0, 90 + n)], [], 300 + n)
		await g.run()
		_check(g.over, "duel %d ends" % n)
		for line in g.log_lines:
			if String(line).begins_with("(Not allowed"):
				refused += 1
		for p in g.players:
			answers += int(p.stats.answers)
			stances += int(p.stats.stances)
			_check(p.total_card_count() == DuelRules.deck_size, "duel %d: %s keeps %d cards (has %d)" % [n, p.player_name, DuelRules.deck_size, p.total_card_count()])
	_check(refused == 0, "the computer asked for %d things its phase forbade" % refused)
	_check(stances > 0, "the computer set stances (%d)" % stances)
	print("  12 duels: %d answers played, %d stances set" % [answers, stances])
