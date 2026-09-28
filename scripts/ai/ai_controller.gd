class_name AIController
extends RefCounted
## Computer duellist. Each call looks at the board and picks one action with
## simple scoring rules: build a bench, Awaken, power up the Active Totem,
## use Rites and its Divine Gift well, then attack or summon for best value.

var delay := 0.0          # seconds to pause before each decision (so a human can follow)
var difficulty := 1.0     # 0..1, lower = more random mistakes


func _wait(mult: float = 1.0) -> void:
	if delay > 0.0:
		await Engine.get_main_loop().create_timer(delay * mult).timeout


# -------------------------------------------------------------- interface ---

func choose_setup(game: BattleGame, pi: int) -> Dictionary:
	var p: PlayerState = game.players[pi]
	var basics := p.hand_basics()
	basics.sort_custom(func(a, b): return _setup_score(p, a) > _setup_score(p, b))
	var bench := []
	for i in range(1, basics.size()):
		if bench.size() < BattleGame.BENCH_MAX:
			bench.append(basics[i])
	return {"active": basics[0], "bench": bench}


func choose_action(game: BattleGame, pi: int) -> Dictionary:
	await _wait()
	return _decide(game, pi)


func choose_creature(game: BattleGame, pi: int, _prompt: String, options: Array, cancellable: bool, context: Dictionary):
	await _wait(0.6)
	if options.is_empty():
		return null
	var reason: String = context.get("reason", "")
	var p: PlayerState = game.players[pi]
	if reason == "self_switch":
		var a := p.active
		var best_b = null
		var best_v := -INF
		for b in options:
			var v := _promotion_score(game, pi, b)
			if v > best_v:
				best_v = v
				best_b = b
		if a == null or best_b == null:
			return null
		if a.hp_left() <= a.max_hp() * 0.4 and best_v > _promotion_score(game, pi, a):
			return best_b
		return null if cancellable else options[0]
	var best = options[0]
	var best_s := -INF
	for c in options:
		var s := 0.0
		match reason:
			"snipe":
				var amt: int = context.get("amount", 10)
				if amt >= c.hp_left():
					s = 100 + c.stage() * 30 + c.energy_unit_count() * 10 + c.tier() * 10
				else:
					s = float(amt) / maxf(1.0, c.hp_left()) * 20.0 + c.stage() * 5 + c.energy_unit_count() * 5
			"forced_switch":
				s = _promotion_score(game, pi, c)
			"heal":
				s = c.damage + (20 if c == p.active else 0)
			_:
				s = c.hp_left()
		if s > best_s:
			best_s = s
			best = c
	return best


func choose_promotion(game: BattleGame, pi: int):
	await _wait(0.6)
	var p: PlayerState = game.players[pi]
	var best = p.bench[0]
	var best_s := -INF
	for c in p.bench:
		var s := _promotion_score(game, pi, c)
		if s > best_s:
			best_s = s
			best = c
	return best


func choose_cards(game: BattleGame, pi: int, _prompt: String, cards: Array, min_n: int, max_n: int, context: Dictionary) -> Array:
	await _wait(0.6)
	var p: PlayerState = game.players[pi]
	var reason: String = context.get("reason", "")
	if reason == "discard_energy":
		return _pick_energy_to_pay(game, pi, cards, int(context.units))
	var scored := []
	for c in cards:
		var s := 0.0
		match reason:
			"search_basic":
				s = float(c.def.hp) / 10.0
				if _hand_has_evolution_for(p, c.id):
					s += 50
				if _deck_has_evolution_for(p, c.id):
					s += 20
			"search_evolution":
				s = _evolution_value(game, pi, c)
			"recycle":
				s = 10.0 if _team_uses_type(p, c.def.element) else 1.0
			"remove_opp_energy":
				s = _energy_removal_value(context.creature, c)
			"revive":
				s = float(c.def.hp)
				if _hand_has_evolution_for(p, c.id):
					s += 40
			"whisper":
				s = _card_threat(c)
			"recall":
				s = _card_threat(c)
			_:
				s = 0.0
		scored.append([s, c])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out := []
	for sc in scored:
		if out.size() >= max_n:
			break
		out.append(sc[1])
	while out.size() < min_n and out.size() < cards.size():
		out.append(cards[out.size()])
	return out


# ------------------------------------------------------------ main brain ---

func _decide(game: BattleGame, pi: int) -> Dictionary:
	var p: PlayerState = game.players[pi]
	var o: PlayerState = game.players[1 - pi]

	# 1. Card draw and search first.
	for card in p.hand:
		if card.is_trainer() and game.trainer_problem(pi, card) == "":
			if card.def.op in ["search_basic", "search_evolution", "draw", "discard_draw", "recycle_energy", "revive_basic"]:
				if _want_trainer(game, pi, card):
					return {"type": "trainer", "card": card}

	# 2. Fill the bench.
	for card in p.hand:
		if card.is_basic_creature() and game.bench_problem(pi, card) == "":
			return {"type": "bench", "card": card}

	# 3. Awaken (Active first).
	for card in p.hand:
		if card.is_evolution():
			var targets := game.evolve_targets(pi, card)
			if not targets.is_empty():
				targets.sort_custom(func(a, b): return _evolve_target_score(p, a) > _evolve_target_score(p, b))
				return {"type": "evolve", "card": card, "target": targets[0]}

	# 4. Healing.
	for card in p.hand:
		if not card.is_trainer() or game.trainer_problem(pi, card) != "":
			continue
		if card.def.op == "heal":
			var t = _best_heal_target(p)
			if t != null:
				return {"type": "trainer", "card": card, "target": t}
		elif card.def.op == "cure_active":
			var a := p.active
			if a.special != "" or a.poisoned or a.burned:
				return {"type": "trainer", "card": card}

	# 5. Divine Gift (some are best used before switching or attaching).
	var gift := _gift_decision(game, pi)
	if not gift.is_empty():
		return gift

	var can_attach := p.energy_attached < p.energy_limit and _hand_energy(p).size() > 0

	# 6. Get a better Totem into the Active spot.
	var sw := _switch_decision(game, pi, can_attach)
	if not sw.is_empty():
		return sw

	# 7. Attach energy.
	if can_attach:
		var att := _best_attachment(game, pi)
		if not att.is_empty():
			return att

	# 8. Disruption before attacking.
	for card in p.hand:
		if not card.is_trainer() or game.trainer_problem(pi, card) != "":
			continue
		if card.def.op == "remove_opp_energy":
			return {"type": "trainer", "card": card}
		if card.def.op == "whisper" and o.hand.size() >= 3:
			return {"type": "trainer", "card": card}
		if card.def.op == "gust":
			var t = _gust_target(game, pi)
			if t != null:
				return {"type": "trainer", "card": card, "target": t}

	# 9. Attack or summon, whichever is worth more.
	var best_i := -1
	var best_v := -INF
	if p.active != null and o.active != null:
		for i in p.active.attacks().size():
			if game.attack_problem(pi, i) != "":
				continue
			var v := _attack_value(game, pi, p.active, p.active.attacks()[i], o.active, p.active.energy_provided())
			v += randf_range(0.0, 6.0) * (1.0 - difficulty)
			if v > best_v:
				best_v = v
				best_i = i
	for card in p.hand:
		if card.is_summon() and game.summon_problem(pi, card) == "":
			var sv := _summon_value(game, pi, card)
			if sv > best_v + 10.0 and sv > 40.0:
				return {"type": "summon", "card": card}
	if best_i >= 0 and best_v > -40.0:
		return {"type": "attack", "index": best_i}
	return {"type": "end"}


func _gift_decision(game: BattleGame, pi: int) -> Dictionary:
	if game.gift_problem(pi) != "":
		return {}
	var p: PlayerState = game.players[pi]
	var o: PlayerState = game.players[1 - pi]
	match p.gift():
		"dawns_mercy":
			for c in game.gift_targets(pi):
				if c.damage >= c.max_hp() * 0.5 or (c == p.active and c.special in ["asleep", "paralyzed", "frozen"]):
					return {"type": "gift", "target": c}
		"wrath":
			if p.active != null and o.active != null and game.turn > 1:
				for i in p.active.attacks().size():
					if game.attack_problem(pi, i) != "" and not _payable_after_attach(p, p.active.attacks()[i]):
						continue
					var atk: Dictionary = p.active.attacks()[i]
					var dmg := _expected_damage(game, p.active, atk, o.active, p.active.energy_provided())
					var boosted := game.compute_damage(p.active.element(), o.active,
						int(atk.get("damage", 0)) + p.active.damage_bonus() + Lore.WRATH_BONUS)
					if dmg < o.active.hp_left() and boosted >= o.active.hp_left() and int(atk.get("damage", 0)) > 0:
						return {"type": "gift"}
		"stillness":
			if o.active != null and p.active != null and o.active.special == "" and not o.active.status_immune():
				for atk in o.active.attacks():
					if o.active.can_use(atk):
						var dmg := game.compute_damage(o.active.element(), p.active,
							int(atk.get("damage", 0)) + o.active.damage_bonus())
						if dmg >= p.active.hp_left():
							return {"type": "gift"}
		"tempest":
			var energies := _hand_energy(p).size()
			if energies >= 2 and p.energy_attached == 0 and game.turn > 2:
				return {"type": "gift"}
		"whisper":
			if o.hand.size() >= 4:
				return {"type": "gift"}
		"foresight":
			if p.active != null:
				for i in p.active.attacks().size():
					if game.attack_problem(pi, i) == "":
						for e in p.active.attacks()[i].get("effects", []):
							if String(e.op).begins_with("flip"):
								return {"type": "gift"}
			if p.hand.size() <= 2 and p.deck.size() > 8:
				return {"type": "gift"}
		"unbound":
			if p.hand.size() <= 2 and p.deck.size() > 8:
				return {"type": "gift"}
		"recall":
			if p.hand.size() <= 4:
				var good := 0
				for c in p.discard:
					if c.is_evolution() or c.is_summon() or c.tier() >= 3 or c.is_supporter():
						good += 1
				if good >= 2 or (good == 1 and p.hand.size() <= 2):
					return {"type": "gift"}
	return {}


func _want_trainer(game: BattleGame, pi: int, card: Card) -> bool:
	var p: PlayerState = game.players[pi]
	match card.def.op:
		"search_basic":
			var have := p.bench.size() + p.hand_basics().size()
			if have >= BattleGame.BENCH_MAX or not _deck_has(p, func(c): return c.is_basic_creature()):
				return false
			return have < 3 or _hand_has_unmatched_evolution(p)
		"search_evolution":
			for c in p.deck:
				if c.is_evolution() and _evolution_value(game, pi, c) >= 50:
					return true
			return false
		"draw":
			return p.deck.size() > 6 and p.hand.size() <= 9
		"discard_draw":
			var useful := 0
			for c in p.hand:
				if c != card and (c.is_evolution() or c.is_energy() or c.is_summon()):
					useful += 1
			return p.deck.size() > 10 and (p.hand.size() - 1 <= 3 or (useful == 0 and p.hand.size() <= 5))
		"recycle_energy":
			return _hand_energy(p).size() <= 1
		"revive_basic":
			return p.bench.size() < 4
	return false


func _switch_decision(game: BattleGame, pi: int, can_attach: bool) -> Dictionary:
	var p: PlayerState = game.players[pi]
	var o: PlayerState = game.players[1 - pi]
	if p.active == null or o.active == null or p.bench.is_empty():
		return {}
	var extra := _best_extra_types(p) if can_attach else []
	var now := _best_attack_value_with(game, pi, p.active, extra)
	if p.active.special == "confused":
		now *= 0.5
	var stuck: bool = p.active.special in ["asleep", "paralyzed", "frozen"]
	var best_b = null
	var best_bv := -INF
	for b in p.bench:
		var v := _best_attack_value_with(game, pi, b, extra)
		if v > best_bv:
			best_bv = v
			best_b = b
	if best_b == null:
		return {}
	var charm = null
	for card in p.hand:
		if card.is_trainer() and card.def.op == "switch_own":
			charm = card
	if charm != null and (stuck or p.active.special == "confused") and best_bv > 10:
		return {"type": "trainer", "card": charm, "target": best_b}
	if game.retreat_problem(pi) == "" and not stuck:
		var penalty := game.retreat_cost(pi) * 12.0
		if best_bv - penalty > now + 25.0 and best_bv > 15.0:
			return {"type": "retreat", "target": best_b}
	if charm != null and best_bv > now + 40.0:
		return {"type": "trainer", "card": charm, "target": best_b}
	return {}


func _best_attachment(game: BattleGame, pi: int) -> Dictionary:
	var p: PlayerState = game.players[pi]
	var seen := {}
	var best := {}
	var best_s := -INF
	for e in _hand_energy(p):
		if seen.has(e.id):
			continue
		seen[e.id] = true
		for c in p.in_play():
			var s := _attach_score(game, pi, c, e)
			if s > best_s:
				best_s = s
				best = {"type": "energy", "card": e, "target": c}
	if best_s <= 0.0:
		return {}
	return best


func _attach_score(game: BattleGame, pi: int, c: Creature, e: Card) -> float:
	var p: PlayerState = game.players[pi]
	var before := c.energy_provided()
	var after := before.duplicate()
	after.append_array(e.provides())
	var s := 0.0
	var atk_sets := [c.attacks()]
	for h in p.hand:
		if h.is_evolution() and h.def.get("awakens_from", "") == c.top().id:
			atk_sets.append(h.def.attacks)
	for i in atk_sets.size():
		var weight := 1.0 if i == 0 else 0.8
		for atk in atk_sets[i]:
			var cost: Array = c.attack_cost(atk) if i == 0 else atk.cost
			var mb := Creature.missing_for_cost(before, cost)
			var ma := Creature.missing_for_cost(after, cost)
			if ma < mb:
				s += weight * (10.0 * (mb - ma) + float(atk.damage) / 5.0)
				if ma == 0:
					s += weight * (25.0 + float(atk.damage) / 2.0)
	# summons in hand want energy on the board
	for h in p.hand:
		if h.is_summon():
			s += 4.0
	if c == p.active:
		s *= 1.5
		if s > 0 and game.turn > 1:
			s += 15
	elif e.provides().has(c.element()):
		s += 2.0
	if s <= 0.0:
		s = 1.0 if (c == p.active and c.energy_unit_count() < c.retreat_cost()) else 0.5
		if e.provides().has(c.element()):
			s += 0.5
	s += c.stage() * 2.0 + c.tier()
	return s


func _gust_target(game: BattleGame, pi: int):
	var p: PlayerState = game.players[pi]
	var o: PlayerState = game.players[1 - pi]
	if p.active == null or p.active.special in ["asleep", "paralyzed", "frozen"]:
		return null
	var best = null
	var best_s := 0.0
	for b in o.bench:
		for atk in p.active.attacks():
			if not p.active.can_use(atk):
				continue
			var dmg := _expected_damage(game, p.active, atk, b, p.active.energy_provided())
			if dmg >= b.hp_left():
				var s: float = 100.0 + b.stage() * 30 + b.energy_unit_count() * 10 + b.tier() * 10
				if s > best_s:
					best_s = s
					best = b
	return best


# ------------------------------------------------------------- evaluation ---

func _expected_damage(game: BattleGame, att: Creature, atk: Dictionary, defn: Creature, provided: Array) -> int:
	var base := float(atk.get("damage", 0))
	var deals := base > 0
	for e in atk.get("effects", []):
		match e.op:
			"flip_plus":
				base += float(e.amount) * 0.5
			"flip_times":
				deals = true
				base = float(e.coins) * 0.5 * float(e.per)
			"plus_per_extra_energy":
				base += mini(int(e.max), Creature.extra_of_type(provided, att.attack_cost(atk), e.type) * int(e.per))
			"plus_per_defender_energy":
				base += float(e.per) * defn.energy_unit_count()
			"plus_if_defender_status":
				if defn.conditions().has(e.status):
					base += float(e.amount)
			"plus_if_defender_condition":
				if defn.has_condition():
					base += float(e.amount)
	if not deals:
		return 0
	base += att.damage_bonus()
	if game.players[att.owner].wrath and att == game.players[att.owner].active:
		base += Lore.WRATH_BONUS
	return game.compute_damage(att.element(), defn, int(base))


func _attack_value(game: BattleGame, pi: int, att: Creature, atk: Dictionary, defn: Creature, provided: Array) -> float:
	var p: PlayerState = game.players[pi]
	var o: PlayerState = game.players[1 - pi]
	if not Creature.cost_payable(provided, att.attack_cost(atk)):
		return -INF
	var dmg := _expected_damage(game, att, atk, defn, provided)
	if defn.protected_turn == game.turn:
		dmg = 0
	var ko := 0.0
	if dmg >= defn.hp_left() and dmg > 0:
		ko = 1.0
	for e in atk.get("effects", []):
		if e.op == "flip_plus" and ko == 0.0:
			var hi := game.compute_damage(att.element(), defn, int(atk.damage) + int(e.amount) + att.damage_bonus())
			if hi >= defn.hp_left():
				ko = 0.5
	var v := _ko_value(p, defn, ko)
	v += mini(dmg, defn.hp_left())
	var survive := 1.0 - ko
	for e in atk.get("effects", []):
		match e.op:
			"status", "flip_status":
				var prob := 1.0 if e.op == "status" else 0.5
				var st: String = e.status
				if defn.conditions().has(st) or defn.status_immune():
					continue
				var sv := 0.0
				match st:
					"asleep": sv = 22.0
					"paralyzed": sv = 28.0
					"confused": sv = 15.0
					"poisoned": sv = 20.0
					"burned": sv = 20.0
				v += sv * prob * survive
			"discard_energy_self":
				v -= 7.0 * int(e.count)
			"heal_self":
				v += mini(int(e.amount), att.damage) * 0.6
			"heal_own":
				var most := 0
				for c in p.in_play():
					most = maxi(most, c.damage)
				v += mini(int(e.amount), most) * 0.7
			"self_damage":
				v -= int(e.amount) * 0.7
				if int(e.amount) >= att.hp_left():
					v -= 90.0
			"flip_self_damage_tails":
				v -= int(e.amount) * 0.35
				if int(e.amount) >= att.hp_left():
					v -= 45.0
			"bench_all_opp":
				for b in o.bench:
					v += mini(int(e.amount), b.hp_left())
					if int(e.amount) >= b.hp_left():
						v += 50.0
			"snipe_opp_bench", "snipe_any":
				var amt := int(e.amount)
				var pool: Array = o.bench if e.op == "snipe_opp_bench" else o.in_play()
				var best := 0.0
				for b in pool:
					var bv := float(mini(amt, b.hp_left()))
					if amt >= b.hp_left():
						bv += 80.0 + b.stage() * 20
					best = maxf(best, bv)
				v += best
			"draw":
				v += int(e.count) * (7.0 if p.hand.size() < 6 else 2.0)
				if p.deck.size() < 8:
					v -= 20.0
			"flip_protect":
				v += 18.0
			"brace":
				v += 12.0
			"opp_switch":
				v += 8.0 * survive
			"flip_opp_switch":
				v += 4.0 * survive
			"self_switch":
				v += 3.0
			"discard_opp_energy":
				v += 15.0 * survive if defn.energy_unit_count() > 0 else 0.0
			"discard_random_opp_hand":
				v += 10.0 if o.hand.size() > 0 else 0.0
	return v


func _ko_value(p: PlayerState, defn: Creature, ko: float) -> float:
	if ko <= 0.0:
		return 0.0
	var v := ko * (100.0 + defn.stage() * 30 + defn.energy_unit_count() * 10 + defn.tier() * 15)
	var prizes := 2 if defn.tier() >= 5 else 1
	if p.prizes.size() <= prizes:
		v += 500.0 * ko
	return v


func _summon_value(game: BattleGame, pi: int, card: Card) -> float:
	var p: PlayerState = game.players[pi]
	var o: PlayerState = game.players[1 - pi]
	var v := 0.0
	for e in card.def.get("effects", []):
		match e.op:
			"summon_strike":
				if o.active != null:
					var dmg := game.compute_damage(card.def.element, o.active, int(e.amount))
					var ko := 1.0 if dmg >= o.active.hp_left() else 0.0
					v += _ko_value(p, o.active, ko) + mini(dmg, o.active.hp_left())
			"bench_all_opp":
				for b in o.bench:
					v += mini(int(e.amount), b.hp_left())
					if int(e.amount) >= b.hp_left():
						v += 50.0
	v -= game.summon_cost(pi, card) * 6.0
	return v


func _payable_after_attach(p: PlayerState, atk: Dictionary) -> bool:
	if p.active == null:
		return false
	var provided := p.active.energy_provided()
	if p.energy_attached < p.energy_limit:
		provided.append_array(_best_extra_types(p))
	return Creature.cost_payable(provided, p.active.attack_cost(atk))


func _best_attack_value_with(game: BattleGame, pi: int, c: Creature, extra_types: Array) -> float:
	var o: PlayerState = game.players[1 - pi]
	if o.active == null:
		return 0.0
	var provided := c.energy_provided()
	provided.append_array(extra_types)
	var best := -10.0
	for atk in c.attacks():
		var v := _attack_value(game, pi, c, atk, o.active, provided)
		best = maxf(best, v)
	best += c.hp_left() * 0.05
	return best


func _best_extra_types(p: PlayerState) -> Array:
	var hand := _hand_energy(p)
	if hand.is_empty():
		return []
	if p.active != null:
		for e in hand:
			if e.provides().has(p.active.element()):
				return e.provides()
	return hand[0].provides()


func _promotion_score(game: BattleGame, pi: int, c: Creature) -> float:
	var o: PlayerState = game.players[1 - pi]
	var s := c.hp_left() * 0.5 + c.energy_unit_count() * 8 + c.stage() * 10 + c.tier() * 5
	if o.active != null:
		for atk in c.attacks():
			if c.can_use(atk):
				s = maxf(s, s + 40 + _expected_damage(game, c, atk, o.active, c.energy_provided()))
	return s


func _setup_score(p: PlayerState, card: Card) -> float:
	var s := float(card.def.hp)
	var cheapest := 99
	for atk in card.def.attacks:
		cheapest = mini(cheapest, atk.cost.size())
	if cheapest <= 1:
		s += 15
	if _hand_has_evolution_for(p, card.id):
		s -= 10
	s -= int(card.def.retreat) * 3
	return s


func _evolve_target_score(p: PlayerState, c: Creature) -> float:
	var s := c.energy_unit_count() * 10.0 + c.damage * 0.2
	if c == p.active:
		s += 25
	return s


func _best_heal_target(p: PlayerState):
	var best = null
	var best_s := 0.0
	for c in p.in_play():
		if c.damage < 20:
			continue
		var s := float(mini(30, c.damage))
		if c == p.active:
			s *= 1.5
		if c.damage >= 30 or c.hp_left() <= 30:
			if s > best_s:
				best_s = s
				best = c
	return best


func _evolution_value(game: BattleGame, pi: int, card: Card) -> float:
	var p: PlayerState = game.players[pi]
	var from: String = card.def.get("awakens_from", "")
	for h in p.hand:
		if h.id == card.id:
			return 5.0
	var s := 0.0
	for c in p.in_play():
		if c.top().id == from:
			s = maxf(s, 80.0 + (20.0 if c == p.active else 0.0))
	for h in p.hand:
		if h.id == from:
			s = maxf(s, 50.0)
	return s


func _energy_removal_value(target: Creature, e: Card) -> float:
	if target == null:
		return 0.0
	var rest := target.energy.duplicate()
	rest.erase(e)
	var provided := []
	for r in rest:
		provided.append_array(r.provides())
	var loss := 0.0
	for atk in target.attacks():
		if target.can_use(atk) and not Creature.cost_payable(provided, target.attack_cost(atk)):
			loss += 10 + float(atk.damage)
	return loss + e.energy_units() * 5


## How dangerous a card in hand is (for discarding the opponent's best card).
func _card_threat(c: Card) -> float:
	if c.is_summon():
		return 100.0
	if c.is_evolution():
		return 60.0 + c.tier() * 5
	if c.is_basic_creature():
		return 30.0 + c.tier() * 5
	if c.is_supporter():
		return 35.0
	if c.is_trainer():
		return 25.0
	return 15.0


func _pick_energy_to_pay(game: BattleGame, pi: int, cards: Array, units: int) -> Array:
	var p: PlayerState = game.players[pi]
	# pay from Benched Totems first, and from energy the Active doesn't need
	var scored := []
	for e in cards:
		var s := 0.0
		if p.active != null and p.active.energy.has(e):
			s += 20.0
			var rest := p.active.energy.duplicate()
			rest.erase(e)
			var provided := []
			for r in rest:
				provided.append_array(r.provides())
			for atk in p.active.attacks():
				if p.active.can_use(atk) and not Creature.cost_payable(provided, p.active.attack_cost(atk)):
					s += 30.0
		scored.append([s, e])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	var out := []
	var sum := 0
	for sc in scored:
		if sum >= units:
			break
		out.append(sc[1])
		sum += sc[1].energy_units()
	return out


# --------------------------------------------------------------- queries ---

func _hand_energy(p: PlayerState) -> Array:
	var out := []
	for c in p.hand:
		if c.is_energy():
			out.append(c)
	return out


func _deck_has(p: PlayerState, pred: Callable) -> bool:
	for c in p.deck:
		if pred.call(c):
			return true
	return false


func _hand_has_evolution_for(p: PlayerState, basic_id: String) -> bool:
	for c in p.hand:
		if c.is_evolution() and c.def.get("awakens_from", "") == basic_id:
			return true
	return false


func _deck_has_evolution_for(p: PlayerState, basic_id: String) -> bool:
	for c in p.deck:
		if c.is_evolution() and c.def.get("awakens_from", "") == basic_id:
			return true
	return false


func _hand_has_unmatched_evolution(p: PlayerState) -> bool:
	for c in p.hand:
		if not c.is_evolution():
			continue
		var from: String = c.def.awakens_from
		var found := false
		for cr in p.in_play():
			if cr.top().id == from:
				found = true
		for h in p.hand:
			if h.id == from:
				found = true
		if not found:
			return true
	return false


func _team_uses_type(p: PlayerState, t: String) -> bool:
	for c in p.in_play():
		if c.element() == t:
			return true
		for atk in c.attacks():
			if atk.cost.has(t):
				return true
	return false
