extends SceneTree
## Phase E of the deeper duel, on the rules engine alone: the seven ways
## (which way a deck leans to, the sample decks legal), every way's card
## refused without one of its Totems on the field and doing what it says
## with one, the cards the story hands out (`DuelArchetypes.glimpse`), the
## computer's plan, and whole duels between the seven ways' decks.
##   godot --headless --script res://tests/phase_e_test.gd

var fails := 0
var _uid := 9000


class Picker:
	extends RefCounted
	var answer: DuelCard = null
	func choose_action(_g, _pi) -> Dictionary: return {"type": "end"}
	func choose_cards(_g, _pi, _p, cards: Array, min_n: int, _max_n, _c) -> Array: return cards.slice(0, maxi(1, min_n))
	func choose_totems(_g, _pi, _p, totems: Array, min_n: int, _max_n) -> Array: return totems.slice(0, min_n)
	func choose_slot(_g, _pi, _p, slots: Array, _c) -> int: return slots[0]
	func choose_reroll(_g, _pi, _i) -> bool: return false
	func choose_scry(_g, _pi, _c) -> bool: return true
	func choose_response(_g, _pi, _e, cards: Array) -> DuelCard:
		if answer != null and cards.has(answer):
			var a := answer
			answer = null
			return a
		return null


func _initialize() -> void:
	_ways()
	await _burn_gamble()
	await _outlast_heal()
	await _guard_counter()
	await _veil_reveal()
	await _dawn_blessing()
	await _frost_stillness()
	await _stars_shadow()
	_glimpse()
	await _whole_duels()
	print("PHASE E TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
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
	g.first_player = 0
	g.phase = "main"
	for pl in g.players:
		pl.essence_max = 8
		pl.essence = 8
		pl.life = 150
		pl.max_life = 200
		pl.hand.clear()
	return g


func _put(g: DuelGame, pi: int, id: String, slot: int) -> DuelTotem:
	var t := g._new_totem(_card(id, pi), pi, slot, 1)
	g.players[pi].slots[slot] = t
	return t


func _hand(g: DuelGame, pi: int, id: String) -> DuelCard:
	var c := _card(id, pi)
	g.players[pi].hand.append(c)
	return c


func _ways() -> void:
	var want := {"emberstorm": "burn_gamble", "tidegrove": "outlast_heal", "ironstone": "guard_counter", "veilwild": "veil_reveal"}
	for d in want:
		var w := DuelArchetypes.of_cards(DuelCards.card_list(d))
		_check(w == want[d], "%s leans to %s (%s)" % [d, want[d], w])
		_check(DuelArchetypes.ARCHETYPES[want[d]].deck == d, "%s's way names it" % d)
	for d in DuelArchetypes.DECKS:
		var probs := DuelCards.deck_problems(DuelCards.card_list(d))
		_check(probs.is_empty(), "%s is a legal deck: %s" % [d, probs])
		var w := DuelArchetypes.of_cards(DuelCards.card_list(d))
		_check(w == String(DuelArchetypes.DECKS[d].archetype), "%s leans to its own way (%s)" % [d, w])
	_check(DuelArchetypes.ARCHETYPES.size() == 7, "seven ways")
	var n := 0
	for id in DuelCards.CARDS:
		if DuelCards.CARDS[id].has("archetype"):
			n += 1
			_check(DuelArchetypes.ARCHETYPES.has(String(DuelCards.CARDS[id].archetype)), "%s's way exists" % id)
			_check(DuelArchetypes.chapter_of(id) > 0, "%s reaches the player in some chapter" % id)
	_check(n == 21, "21 way cards (%d)" % n)
	for id in ["dawnling", "hallowed_hound", "rimecub", "runeowl", "starling", "duskstalker"]:
		_check(ResourceLoader.exists("res://assets/models/creatures/%s.glb" % String(DuelCards.CARDS[id].stand_in)), "%s has a stand-in model" % id)
		_check(DuelCards.CARDS[id].has("stand_in_tint"), "%s has a stand-in colour" % id)


func _burn_gamble() -> void:
	var g := _game()
	var st := _hand(g, 0, "stoke_the_coals")
	var f1 := _put(g, 1, "brookfin", 0)
	await g._apply_status(f1, "burn", null, 0)
	_check(g.rite_problem(0, st).find("needs a Fire or Storm Totem") >= 0, "Stoke the Coals needs a Fire or Storm Totem: %s" % g.rite_problem(0, st))
	_put(g, 0, "mossling", 0)
	_check(g.rite_problem(0, st) != "", "...a Verdant one isn't enough")
	_put(g, 0, "cinderpup", 1)
	_check(g.rite_problem(0, st) == "", "with Cinderpup: %s" % g.rite_problem(0, st))
	await g.perform(0, {"type": "rite", "card": st})
	_check(f1.damage == 20 or f1.is_knocked_out(), "each Burned enemy Totem takes 20 (%d)" % f1.damage)
	var ld := _hand(g, 0, "loaded_dice")
	var h0: int = g.players[0].hand.size()
	await g.perform(0, {"type": "rite", "card": ld})
	_check(g.players[0].fate_bonus == 3, "Loaded Dice: Fate +3 (%d)" % g.players[0].fate_bonus)
	_check(g.players[0].hand.size() == h0, "...and draws a card (it replaced itself)")
	# Wildfire Pact: Burn bites harder at the rival's Dawn
	var wp := _hand(g, 0, "wildfire_pact")
	await g.perform(0, {"type": "rite", "card": wp})
	var d0 := f1.damage
	await g._dawn_conditions(g.players[1])
	_check(f1.damage - d0 == DuelRules.burn_damage + 10 or f1.is_knocked_out(), "Wildfire Pact: Burn deals %d (was %d)" % [f1.damage - d0, DuelRules.burn_damage])


func _outlast_heal() -> void:
	var g := _game()
	var a := _put(g, 0, "brookfin", 0)
	var b := _put(g, 0, "mossling", 1)
	a.damage = 30
	var dr := _hand(g, 0, "deep_roots")
	await g.perform(0, {"type": "rite", "card": dr})
	_check(a.damage == 10 and b.shield >= 10 and a.shield == 0, "Deep Roots heals 20 and shields the unhurt (damage %d, shields %d/%d)" % [a.damage, a.shield, b.shield])
	var tr := _hand(g, 0, "tidal_reserve")
	await g.perform(0, {"type": "rite", "card": tr})
	var l0: int = g.players[0].life
	await g._heal(a, 10)
	_check(g.players[0].life == l0 + 5, "Tidal Reserve: a heal gives 5 Life (%d)" % (g.players[0].life - l0))
	var sw := _hand(g, 0, "still_waters")
	var h0: int = g.players[0].hand.size()
	await g.perform(0, {"type": "rite", "card": sw})
	_check(g.players[0].hand.size() == h0 - 1 + 2, "Still Waters: a card for each unhurt Totem (hand %d -> %d)" % [h0, g.players[0].hand.size()])


func _guard_counter() -> void:
	var g := _game()
	var wall := _put(g, 1, "pebblit", 0)
	var att := _put(g, 0, "blazehound", 0)
	att.called_turn = 1
	var cw := _hand(g, 1, "counterweight")
	(g.players[1].controller as Picker).answer = cw
	g.phase = "clash"
	var mi := -1
	for i in att.moves().size():
		if not att.moves()[i].has("fate") and int(att.moves()[i].get("damage", 0)) >= 30 and g.move_problem(0, att, i) == "":
			mi = i
			break
	var want: int = g.attack_amount(att, mi, int(att.moves()[mi].damage), wall) if mi >= 0 else 0
	if mi >= 0:
		await g.perform(0, {"type": "attack", "attacker": att, "move": mi, "target": wall})
		_check(g.players[1].discard.has(cw), "Counterweight was played in answer")
		_check(wall.damage == maxi(0, want - 20) or wall.is_knocked_out(), "Counterweight: the blow lands 20 lighter (%d of %d)" % [wall.damage, want])
		_check(att.damage >= 20, "...and the attacker takes 20 (%d)" % att.damage)
	else:
		_check(false, "Blazehound has a plain move")
	# Stone Patience: twice your Guard
	g = _game()
	_put(g, 0, "pebblit", 0)
	var foe := _put(g, 1, "elderbark", 0)
	var sp := _hand(g, 0, "stone_patience")
	var gd: int = g.players[0].guard()
	await g.perform(0, {"type": "rite", "card": sp, "target": foe})
	_check(foe.damage == gd * 2 or foe.is_knocked_out(), "Stone Patience: twice the Guard (%d, Guard %d)" % [foe.damage, gd])
	# Bastion Banner: Guarding Totems take 10 less
	g = _game()
	var gt := _put(g, 0, "pebblit", 0)
	g.players[0].continuous.append(_card("bastion_banner", 0))
	gt.stance = "guard"
	await g._damage_totem(gt, 40, {})
	_check(gt.damage == 10, "Bastion Banner: 40 on a Guarding Totem lands as %d (half, then 10 less)" % gt.damage)


func _veil_reveal() -> void:
	var g := _game()
	var wisp := _put(g, 0, "emberwisp", 0)
	wisp.face_down = true
	_put(g, 0, "veilfox", 1)   # (the Psychic Totem the way needs)
	var across := _put(g, 1, "elderbark", 0)
	var um := _hand(g, 0, "unmasking")
	_check(g.rite_problem(0, um) == "", "Unmasking with a veiled Emberwisp: %s" % g.rite_problem(0, um))
	await g.perform(0, {"type": "rite", "card": um})
	_check(not wisp.face_down, "Unmasking turns it face up")
	_check(across.damage >= 40, "...and its Reveal happens twice (%d damage across)" % across.damage)
	# Whispering Shroud: a reveal draws a card
	g = _game()
	var fox := _put(g, 0, "dreamfox", 0)
	fox.face_down = true
	g.players[0].continuous.append(_card("whispering_shroud", 0))
	var h0: int = g.players[0].hand.size()
	await g._reveal(fox, "test")
	_check(g.players[0].hand.size() == h0 + 1, "Whispering Shroud: a reveal draws a card")
	# Venom Mask: a Basic called veiled and free
	g = _game()
	_put(g, 0, "blightrat", 0)
	var vm := _hand(g, 0, "venom_mask")
	var asp := _hand(g, 0, "mirewidow")
	var e0: int = g.players[0].essence
	await g.perform(0, {"type": "rite", "card": vm})
	var called = g.players[0].slots[1]
	_check(called != null and called.face_down and not g.players[0].hand.has(asp), "Venom Mask calls it face down")
	_check(g.players[0].essence == e0 - g.rite_cost(0, vm), "...for nothing but the Mask")


func _dawn_blessing() -> void:
	var g := _game()
	var d := _put(g, 0, "dawnling", 0)
	d.damage = 20
	var sv := _hand(g, 0, "sunward_vow")
	await g.perform(0, {"type": "rite", "card": sv})
	_check(d.has_boon("blessed") and d.damage == 10, "Sunward Vow: Blessed and healed 10 (damage %d)" % d.damage)
	g.players[0].continuous.append(_card("lantern_vigil", 0))
	var moth := _put(g, 0, "lantern_moth", 1)
	var l0: int = g.players[0].life
	var h0: int = g.players[0].hand.size()
	moth.damage = moth.max_hp()
	await g._resolve_knockouts()
	_check(g.players[0].life == l0 + 20 and g.players[0].hand.size() == h0 + 1, "Lantern Vigil: a fall gives 20 Life and a card (%d, %d)" % [g.players[0].life - l0, g.players[0].hand.size() - h0])
	var ks := _hand(g, 0, "kindled_soul")
	await g.perform(0, {"type": "rite", "card": ks})
	_check(g.players[0].slots[1] != null, "Kindled Soul calls a fallen Totem back")


func _frost_stillness() -> void:
	var g := _game()
	var cub := _put(g, 0, "rimecub", 0)
	var foe := _put(g, 1, "elderbark", 0)
	var sh := _hand(g, 0, "shatter")
	_check(g.rite_problem(0, sh) != "", "Shatter needs a Frozen enemy: %s" % g.rite_problem(0, sh))
	await g._apply_status(foe, "frozen", null, 0)
	_check(foe.has_status("frozen"), "(the test freezes Elderbark)")
	var base: int = g.attack_amount(cub, 0, 20, foe)
	g.players[0].continuous.append(_card("deep_winter", 0))
	_check(g.attack_amount(cub, 0, 20, foe) == base + 20, "Deep Winter: a Frozen Totem takes 20 more (%d -> %d)" % [base, g.attack_amount(cub, 0, 20, foe)])
	_check(g.rite_problem(0, sh, foe) == "", "Shatter on a Frozen Totem: %s" % g.rite_problem(0, sh, foe))
	await g.perform(0, {"type": "rite", "card": sh, "target": foe})
	_check(foe.damage >= 50 or foe.is_knocked_out(), "Shatter: 50 (%d)" % foe.damage)
	var gw := _hand(g, 1, "glacial_ward")
	g.current = 1
	_check(g.ward_problem(1, gw) != "", "Glacial Ward can't be set without a Frost or Mystic Totem")


func _stars_shadow() -> void:
	var g := _game()
	_put(g, 0, "starling", 0)
	for i in 5:
		g.players[0].deck.append(_card("sparkkit", 0))
	var co := _hand(g, 0, "constellation")
	var h0: int = g.players[0].hand.size()
	await g.perform(0, {"type": "rite", "card": co})
	_check(g.players[0].hand.size() == h0, "Constellation: one of the top three to the hand")
	var m0: int = g.fate_mod(1, "")
	g.players[0].continuous.append(_card("eclipse", 0))
	_check(g.fate_mod(1, "") == m0 - 2, "Eclipse: the rival's Fate rolls 2 lower (%d -> %d)" % [m0, g.fate_mod(1, "")])
	var foe := _put(g, 1, "brookfin", 0)
	var ss := _hand(g, 0, "shadow_step")
	await g.perform(0, {"type": "rite", "card": ss, "target": foe})
	_check(foe.has_status("blinded"), "Shadow Step blinds it")


func _glimpse() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var codex := {}
	var g1 := DuelArchetypes.glimpse(codex, 1, 20, rng)
	_check(g1 != "" and DuelArchetypes.chapter_of(g1) == 1, "the first chapter hands out a first-chapter card (%s)" % g1)
	for i in 200:
		var g := DuelArchetypes.glimpse(codex, 1, 20, rng)
		if g == "":
			break
		codex[g] = "seen"
	_check(DuelArchetypes.glimpse(codex, 1, 20, rng) == "", "...until there are none left in it")
	var g3 := DuelArchetypes.glimpse(codex, 3, 20, rng)
	_check(g3 != "" and DuelArchetypes.chapter_of(g3) >= 2, "a later chapter opens more (%s)" % g3)
	var low := DuelArchetypes.glimpse({}, 1, 1, rng)
	_check(low == "" or int(DuelCards.CARDS[low].tier) <= DuelRewards.tier_cap(1), "only what the Rank answers (%s)" % low)


func _whole_duels() -> void:
	var refused := 0
	var decks: Array = DuelArchetypes.DECKS.keys()
	var played := {}
	for n in 21:
		var g := DuelGame.new()
		var a: String = decks[n % decks.size()]
		var b: String = decks[(n + 1 + n / decks.size()) % decks.size()]
		g.setup([a, b], ["P1", "P2"], [DuelAI.new(1.0, 470 + n), DuelAI.new(1.0, 510 + n)], [], 2900 + n)
		g.arena = ["ashford", "tidegrove", "emberforge", "ironstone", "veilwild", "solhaven"][n % 6]
		await g.run()
		_check(g.over, "duel %d ends" % n)
		for line in g.log_lines:
			if String(line).begins_with("(Not allowed"):
				refused += 1
				if refused <= 3:
					print("  refused: ", line)
		for p in g.players:
			_check(p.total_card_count() == DuelRules.deck_size, "duel %d: %s keeps %d cards (has %d)" % [n, p.player_name, DuelRules.deck_size, p.total_card_count()])
			for id in p.played:
				if DuelCards.CARDS[id].has("archetype"):
					played[id] = int(played.get(id, 0)) + int(p.played[id])
	_check(refused == 0, "the computer asked for %d things it may not do" % refused)
	_check(played.size() >= 10, "the computer played %d of the ways' cards: %s" % [played.size(), played.keys()])
	print("  21 duels: way cards played %s" % played)
