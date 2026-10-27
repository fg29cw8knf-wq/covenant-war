extends SceneTree
## The 27 October additions on the rules engine alone (Gary: "add all the go
## battles"): each duel skill working once and only once, the comeback card
## (Rallying Light) at a quarter Life, the Circle's events every few turns,
## the damage preview, and whole duels with all of it on.
##   godot --headless --script res://tests/skills_test.gd

var fails := 0
var _uid := 9000


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
	await _loyal_hound()
	await _old_wards()
	await _showman()
	await _quick_start()
	await _lucky_charm()
	await _keen_eye()
	await _second_wind_and_comeback()
	await _arena_events()
	_preview()
	await _whole_duels()
	print("SKILLS TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


func _card(id: String, owner: int) -> DuelCard:
	_uid += 1
	return DuelCard.new(_uid, id, owner)


func _game(skills := ["", ""]) -> DuelGame:
	var g := DuelGame.new()
	g.setup(["emberstorm", "tidegrove"], ["A", "B"], [Picker.new(), Picker.new()], [], 5)
	g.turn = 3
	g.current = 0
	g.phase = "main"
	g.skills = skills
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


func _loyal_hound() -> void:
	var g := _game(["", "loyal_hound"])
	var fin := _put(g, 1, "brookfin", 0)
	await g._damage_totem(fin, 200, {"spill": true})
	_check(not fin.is_knocked_out() and fin.hp_left() == DuelSkills.LOYAL_HOLD, "Loyal Hound: Brookfin holds on with 10 HP (%d)" % fin.hp_left())
	_check(g.players[1].life == 150, "Loyal Hound: nothing spills over onto Life (%d)" % g.players[1].life)
	_check(g.skill_used(1) and not g.has_skill(1, "loyal_hound"), "Loyal Hound is spent")
	await g._damage_totem(fin, 50, {})
	_check(fin.is_knocked_out(), "the second time, it falls")
	var g2 := _game(["loyal_hound", ""])
	var mine := _put(g2, 1, "brookfin", 0)
	await g2._damage_totem(mine, 200, {})
	_check(mine.is_knocked_out(), "the skill works for its own side only")


func _old_wards() -> void:
	var g := _game(["", "old_wards"])
	var w := _card("iron_bastion", 1)
	var w2 := _card("iron_bastion", 1)
	g.players[1].hand.append_array([w, w2])
	var full := g.card_cost(0, _card("iron_bastion", 0))
	_check(full > 0, "a Ward costs something without the skill (%d)" % full)
	_check(g.card_cost(1, w) == 0, "Old Wards: the first Ward costs nothing")
	g.current = 1
	var before: int = g.players[1].essence
	await g._act_ward(1, w)
	_check(g.players[1].essence == before, "Old Wards: setting it spent no Essence (%d, %d)" % [before, g.players[1].essence])
	_check(g.card_cost(1, w2) == full, "the second Ward costs its full price (%d)" % g.card_cost(1, w2))


func _showman() -> void:
	var g := _game(["showman", ""])
	var pup := _put(g, 0, "cinderpup", 0)
	var fin := _put(g, 1, "brookfin", 0)
	var plain := _game()
	var pup2 := _put(plain, 0, "cinderpup", 0)
	var fin2 := _put(plain, 1, "brookfin", 0)
	var a := g.attack_amount(pup, 0, 10, fin)
	var b := plain.attack_amount(pup2, 0, 10, fin2)
	_check(a == b + DuelSkills.SHOWMAN_BONUS, "Showman: the first attack deals 20 more (%d against %d)" % [a, b])
	await g._act_attack(0, pup, 0, fin)
	_check(g.skill_used(0), "Showman is spent by the attack")
	_check(fin.damage == a, "the hit landed with the bonus (%d)" % fin.damage)
	_check(g.attack_amount(pup, 0, 10, fin) == b, "the next attack is plain")


func _quick_start() -> void:
	var g := _game(["quick_start", ""])
	g.turn = 0
	g.players[0].essence_max = 2
	await g._take_turn()
	_check(g.players[0].essence == 4, "Quick Start: the first turn has 1 more Essence (%d of %d)" % [g.players[0].essence, g.players[0].essence_max])
	_check(g.skill_used(0), "Quick Start is spent")
	g.current = 0
	await g._take_turn()
	_check(g.players[0].essence == g.players[0].essence_max, "the next turn is plain (%d of %d)" % [g.players[0].essence, g.players[0].essence_max])


func _lucky_charm() -> void:
	var g := _game(["lucky_charm", ""])
	var t := _put(g, 0, "cinderpup", 0)
	var bands: Array = t.move(1).fate
	await g._fate_roll(0, t.affinity(), bands, "test")
	_check(g.skill_used(0), "Lucky Charm is spent on the first Fate roll")
	var lows := 0
	for n in 200:
		var h := _game(["lucky_charm", ""])
		h.rng.seed = 100 + n
		var ht := _put(h, 0, "cinderpup", 0)
		var band: Dictionary = await h._fate_roll(0, ht.affinity(), bands, "test")
		if int(band.get("damage", 0)) <= 20:
			lows += 1
	# a single d20 lands on 20 damage or a miss (9 or under) nearly half the
	# time; the better of two, about a fifth
	_check(lows < 70, "Lucky Charm's rolls run high (%d of 200 low)" % lows)


func _keen_eye() -> void:
	var g := _game(["keen_eye", ""])
	var w := _card("ambush_snare", 1)
	g.players[1].hand.append(w)
	g.current = 1
	await g._act_ward(1, w)
	_check(g.face_up.has(w.uid), "Keen Eye: the rival's first Ward is set face up")
	var w2 := _card("iron_bastion", 1)
	g.players[1].hand.append(w2)
	await g._act_ward(1, w2)
	_check(not g.face_up.has(w2.uid), "the second is face down")


func _second_wind_and_comeback() -> void:
	var g := _game(["second_wind", ""])
	var pup := _put(g, 0, "cinderpup", 0)
	pup.damage = 40
	await g._hit_life(0, 60, {"no_guard": true})
	_check(pup.damage == 40, "Second Wind waits for half Life (%d left)" % g.players[0].life)
	await g._hit_life(0, 20, {"no_guard": true})
	_check(g.players[0].life == 70 and pup.damage == 10, "Second Wind: at half Life the Totems heal 30 (damage %d)" % pup.damage)
	_check(g.players[0].hand.is_empty(), "no comeback card above a quarter")
	await g._hit_life(0, 40, {"no_guard": true})
	var got: Array = g.players[0].hand.filter(func(c): return c.id == DuelGame.COMEBACK_CARD)
	_check(got.size() == 1, "at a quarter Life the god sends Rallying Light (%d left)" % g.players[0].life)
	await g._hit_life(0, 10, {"no_guard": true})
	got = g.players[0].hand.filter(func(c): return c.id == DuelGame.COMEBACK_CARD)
	_check(got.size() == 1, "only once a duel")
	# playing it: Totems heal 30 and are Empowered, and a card is drawn
	pup.damage = 40
	var deck_before: int = g.players[0].deck.size()
	_check(g.rite_problem(0, got[0]) == "", "it can be cast: %s" % g.rite_problem(0, got[0]))
	await g._act_rite(0, got[0], null)
	_check(pup.damage == 10 and pup.has_boon("empowered"), "Rallying Light heals and Empowers (damage %d)" % pup.damage)
	_check(g.players[0].deck.size() == deck_before - 1, "...and draws a card")
	var off := _game()
	off.comeback = false
	await off._hit_life(0, 130, {"no_guard": true})
	_check(off.players[0].hand.is_empty(), "no comeback card when it's off (a lesson, a puzzle)")


func _arena_events() -> void:
	var g := _game()
	g.arena = "ashford"
	g.turn = 3
	_check(g.arena_event_in() == 2, "two turns to the first event (%d)" % g.arena_event_in())
	g.turn = 5
	_check(g.arena_event_now(), "the first at turn 5")
	g.turn = 6
	_check(g.arena_event_in() == DuelRules.arena_event_every - 1, "then every %d (%d)" % [DuelRules.arena_event_every, g.arena_event_in()])
	g.turn = 5 + DuelRules.arena_event_every
	_check(g.arena_event_now(), "turn %d" % g.turn)
	var pup := _put(g, 0, "cinderpup", 0)
	var fin := _put(g, 1, "brookfin", 0)
	pup.damage = 30
	await g._arena_event(g.players[0])
	_check(pup.has_boon("empowered") and fin.has_boon("empowered"), "Ashford: every Totem is Empowered")
	_check(pup.damage == 10 and fin.damage == 0, "Ashford: the Fire Totem heals 20")
	for a in ["tidegrove", "emberforge", "ironstone", "veilwild", "solhaven"]:
		var h := _game()
		h.arena = a
		h.turn = 5
		var hp := _put(h, 0, "cinderpup", 0)
		var hf := _put(h, 1, "brookfin", 0)
		hf.damage = 40
		h.players[1].life = 50
		var hand0: int = h.players[0].hand.size()
		await h._arena_event(h.players[0])
		match a:
			"tidegrove":
				_check(hp.has_status("soaked") and hf.has_status("soaked") and hf.damage == 10, "Tidegrove: all Soaked, Tide heals 30")
			"emberforge":
				_check(hp.has_boon("empowered") and hf.damage == 50, "Emberforge: Fire Empowered, the rest take 10")
			"ironstone":
				_check(hp.shield == 20 and hf.shield == 20, "Ironstone: every Totem shielded 20")
			"veilwild":
				_check(h.players[0].hand.size() == hand0 + 1, "Veilwild: both draw")
			"solhaven":
				_check(h.players[1].life > 50 and h.players[0].life == 150, "Solhaven: the one behind gains Life (%d)" % h.players[1].life)
	var none := _game()
	none.arena = "ashford"
	none.arena_events = false
	none.turn = 5
	_check(not none.arena_event_now(), "no events when they're off")
	var set := _game()
	set.arena = "ashford"
	set.puzzle = {"first": 0}
	set.turn = 5
	_check(not set.arena_event_now(), "none on a set board")


func _preview() -> void:
	var g := _game()
	var pup := _put(g, 0, "cinderpup", 0)
	var fin := _put(g, 1, "brookfin", 0)
	var nip := g.preview_attack(0, pup, 0, fin)
	_check(int(nip.lo) == int(nip.hi) and int(nip.hi) == g.attack_amount(pup, 0, 10, fin), "a plain move: one number (%s)" % nip)
	_check(not nip.ko and float(nip.ko_chance) == 0.0, "Nip doesn't knock Brookfin out")
	var bite := g.preview_attack(0, pup, 1, fin)
	_check(int(bite.lo) == 0 and int(bite.hi) >= 70 and bite.fate, "a Fate move: a range (%s)" % bite)
	_check(float(bite.ko_chance) > 0.0 and float(bite.ko_chance) < 1.0, "it might knock it out (%.2f)" % float(bite.ko_chance))
	fin.damage = 65
	var fin_ko := g.preview_attack(0, pup, 0, fin)
	_check(fin_ko.ko, "a sure knockout says so")
	g.players[1].life = 20
	fin.damage = 69
	var spill := g.preview_attack(0, pup, 1, fin)
	_check(float(spill.lethal_chance) > 0.0, "spill-over that could finish the duel is seen (%s)" % spill)
	g.players[1].slots[0] = null
	var life := g.preview_attack(0, pup, 0, DuelGame.LIFE)
	_check(int(life.hi) == g._life_after_guard(1, g.attack_amount(pup, 0, 10, null)), "a hit on Life counts the Guard (%s)" % life)


func _whole_duels() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var seen := {"comeback": 0, "event": 0, "skill": 0}   # (a lambda can't change the locals it sees)
	for n in 24:
		var decks: Array = DuelCards.DECKS.keys()
		var a: String = decks[n % decks.size()]
		var b: String = decks[(n * 3 + 1) % decks.size()]
		var g := DuelGame.new()
		g.setup([a, b], ["A", "B"], [DuelAI.new(1.0, 40 + n), DuelAI.new(0.8, 80 + n)], [], 300 + n)
		g.arena = ["ashford", "tidegrove", "emberforge", "ironstone", "veilwild", "solhaven"][n % 6]
		g.skills = [DuelSkills.random(rng), DuelSkills.random(rng)]
		g.logged.connect(func(t: String, _w: int) -> void:
			if t.contains("sends") and t.contains("Rallying Light"):
				seen.comeback += 1
			if DuelGame.ARENA_EVENTS.values().any(func(e): return t.begins_with(String(e.name) + "!")):
				seen.event += 1
			if t.contains(" skill, "):
				seen.skill += 1)
		await g.run()
		_check(g.over, "duel %d ends" % n)
		for p in g.players:
			_check(p.total_card_count() == DuelRules.deck_size, "duel %d: %s keeps %d cards (has %d)" % [n, p.player_name, DuelRules.deck_size, p.total_card_count()])
	print("  24 duels: %d comeback cards, %d Circle events, %d skills used" % [seen.comeback, seen.event, seen.skill])
	_check(seen.comeback > 0 and seen.event > 0 and seen.skill > 0, "all three happen in real duels")
