class_name DuelAI
extends RefCounted
## The computer duellist for the v1 rules. Each decision scores every legal
## action in "damage points" and takes the best one; the turn ends when
## nothing left is worth doing. Deterministic apart from Fate dice unless
## `difficulty` is below 1, which adds noise (mistakes) to every score.

var difficulty := 1.0
var rng := RandomNumberGenerator.new()

## How much one point of Essence is worth when it's spent on something else.
const ESSENCE_VALUE := 6.0


func _init(p_difficulty: float = 1.0, seed_value: int = -1) -> void:
	difficulty = p_difficulty
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


# ============================================================== interface ===

var _game_ref: DuelGame = null


func choose_action(game: DuelGame, pi: int) -> Dictionary:
	_game_ref = game
	var best := {}
	var best_score := 0.5
	for cand in _candidates(game, pi):
		var s: float = cand.score
		if difficulty < 1.0:
			s += rng.randf_range(-25.0, 25.0) * (1.0 - difficulty)
		if s > best_score:
			best_score = s
			best = cand.action
	if best.is_empty():
		return {"type": "end"}
	return best


func choose_cards(game: DuelGame, pi: int, _prompt: String, cards: Array, min_n: int, max_n: int, context: Dictionary) -> Array:
	var reason: String = context.get("reason", "")
	var scored := []
	for c in cards:
		scored.append({"c": c, "v": _keep_value(game, pi, c)})
	match reason:
		"hand_limit":
			scored.sort_custom(func(a, b): return a.v < b.v)   # throw away the weakest
		"whisper":
			scored.sort_custom(func(a, b): return a.c.cost() > b.c.cost())
		"search":
			var p: DuelPlayer = game.players[pi]
			for s in scored:
				var cst: int = s.c.cost()
				s.v = 40.0 - absf(cst - (p.essence_max + 1)) * 8.0 + cst * 2.0
			scored.sort_custom(func(a, b): return a.v > b.v)
		_:
			scored.sort_custom(func(a, b): return a.v > b.v)
	var n := clampi(max_n, min_n, scored.size())
	var out := []
	for i in n:
		out.append(scored[i].c)
	return out


func choose_totems(game: DuelGame, pi: int, _prompt: String, totems: Array, min_n: int, max_n: int) -> Array:
	var scored := []
	for t in totems:
		scored.append({"t": t, "v": _threat(game, 1 - pi, t)})
	scored.sort_custom(func(a, b): return a.v > b.v)
	var out := []
	for i in clampi(max_n, min_n, scored.size()):
		out.append(scored[i].t)
	return out


func choose_slot(game: DuelGame, pi: int, _prompt: String, slots: Array, context: Dictionary) -> int:
	if context.get("reason", "") == "move_foe":
		# Put their Totem where it opens the best lane for my ready Totems.
		var me: DuelPlayer = game.players[pi]
		var best: int = slots[0]
		var best_v := -INF
		for s in slots:
			var v := 0.0
			var mine = me.slots[s]
			if mine != null:
				v -= 10.0   # it will now block my Totem in that lane
			var t: DuelTotem = context.get("totem")
			if t != null and me.slots[t.slot] != null:
				v += 20.0   # the lane it leaves opens for my Totem
			if v > best_v:
				best_v = v
				best = s
		return best
	return slots[0]


func choose_reroll(_game: DuelGame, _pi: int, info: Dictionary) -> bool:
	var bands: Array = info.bands
	var i := int(info.index)
	if i == 0:
		return true
	var avg := 0.0
	for b in bands:
		avg += int(b.get("damage", 0))
	avg /= maxf(1.0, bands.size())
	return int(bands[i].get("damage", 0)) < avg * 0.8


func choose_scry(game: DuelGame, pi: int, card: DuelCard) -> bool:
	var p: DuelPlayer = game.players[pi]
	if card.is_basic_totem() and not p.empty_slots().is_empty():
		return true
	return card.cost() <= p.essence_max + 2


# ============================================================ candidates ===

func _candidates(game: DuelGame, pi: int) -> Array:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var out := []
	var lethal := _lethal_available(game, pi)

	# --- attacks
	for t in p.totems():
		if game.ready_problem(pi, t) != "":
			continue
		for i in t.moves().size():
			if game.move_problem(pi, t, i) != "":
				continue
			for target in game.attack_targets(pi, t, i):
				var s := _attack_score(game, pi, t, i, target, lethal)
				if s > -INF:
					out.append({"score": s, "action": {"type": "attack", "attacker": t, "move": i, "target": target}})

	# --- cards in hand
	for c in p.hand:
		match c.kind():
			"totem":
				if c.is_basic_totem():
					if game.call_problem(pi, c) == "":
						var slot := _best_slot(game, pi, c)
						out.append({"score": _call_score(game, pi, c, slot), "action": {"type": "call", "card": c, "slot": slot}})
				else:
					for tg in game.ascend_targets(pi, c):
						if game.ascend_problem(pi, c, tg) == "":
							out.append({"score": _ascend_score(game, pi, c, tg), "action": {"type": "ascend", "card": c, "target": tg}})
			"rite":
				if game.rite_problem(pi, c) != "":
					continue
				if game.rite_needs_target(c):
					for tg in game.rite_targets(pi, c):
						if game.rite_problem(pi, c, tg) == "":
							out.append({"score": _rite_score(game, pi, c, tg), "action": {"type": "rite", "card": c, "target": tg}})
				else:
					out.append({"score": _rite_score(game, pi, c, null), "action": {"type": "rite", "card": c}})
			"ward":
				if game.ward_problem(pi, c) == "":
					out.append({"score": _ward_score(game, pi, c), "action": {"type": "ward", "card": c}})
			"summon":
				if game.summon_problem(pi, c) != "":
					continue
				if game.summon_needs_target(c):
					for tg in foe.totems():
						out.append({"score": _summon_score(game, pi, c, tg), "action": {"type": "summon", "card": c, "target": tg}})
				else:
					out.append({"score": _summon_score(game, pi, c, null), "action": {"type": "summon", "card": c}})

	# --- the Divine Gift
	if game.gift_problem(pi) == "":
		var g := _gift_option(game, pi)
		if not g.is_empty():
			out.append(g)

	# --- shifting
	if true:
		var sh := _shift_option(game, pi, lethal)
		if not sh.is_empty():
			out.append(sh)
	return out


# ================================================================ scoring ===

func _attack_score(game: DuelGame, pi: int, t: DuelTotem, i: int, target, lethal: bool) -> float:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var mv := t.move(i)
	var cost := t.move_cost(i)
	var s := 0.0
	var outcomes := _outcomes(game, pi, t, i)   # [{p, damage, effects}]
	var tk := t.move_target(i)
	if tk == "ally":
		if not (target is DuelTotem):
			return -INF
		for o in outcomes:
			for e in o.effects:
				if e.op == "heal":
					s += o.p * minf(float(e.amount), float(target.damage))
		if s < 10.0:
			return -INF
		return s - cost * ESSENCE_VALUE
	if tk == "none":
		for o in outcomes:
			for e in o.effects:
				if e.op == "shield":
					s += o.p * float(e.amount) * (0.6 if t.damage > 0 or _threatened(game, pi, t) else 0.2)
		return s - cost * ESSENCE_VALUE
	if target is String and target == DuelGame.LIFE:
		var guard := foe.guard()
		for o in outcomes:
			var amt := game.attack_amount(t, i, int(o.damage), null)
			if amt > 0:
				amt = maxi(mini(amt, DuelRules.guard_min_hit), amt - guard)
			s += o.p * amt
		if _ward_risk(game, pi, "foe_direct") or _ward_risk(game, pi, "foe_attack"):
			s *= 0.8
		s *= 1.1 + (0.6 if foe.life < 120 else 0.0)
		if lethal:
			s += 500.0
		if s <= 0.0:
			return -INF
		return s - cost * ESSENCE_VALUE
	if tk == "all_foes":
		for f in foe.totems():
			s += _hit_value(game, pi, t, i, f, outcomes)
		if _ward_risk(game, pi, "foe_attack"):
			s *= 0.85
		return s - cost * ESSENCE_VALUE
	if target is DuelTotem:
		s = _hit_value(game, pi, t, i, target, outcomes)
		if target.has_keyword("thorns"):
			s -= DuelRules.thorns_damage * 0.6
		if _ward_risk(game, pi, "foe_attack"):
			s *= 0.85
		if lethal:
			s *= 0.3   # finish them instead
		# a Totem with nothing better to do should still swing
		return s - cost * ESSENCE_VALUE
	return -INF


## Expected value of hitting one enemy Totem with this move.
func _hit_value(game: DuelGame, pi: int, t: DuelTotem, i: int, f: DuelTotem, outcomes: Array) -> float:
	var foe: DuelPlayer = game.players[1 - pi]
	var hp := f.hp_left() + f.shield
	var s := 0.0
	var worth := _totem_value(game, 1 - pi, f)
	for o in outcomes:
		var amt := game.attack_amount(t, i, int(o.damage), f, o.effects)
		var v := float(mini(amt, hp))
		if amt >= hp and hp > 0:
			v += worth
			var spill := amt - hp
			if spill > 0:
				v += maxf(0.0, spill - foe.guard()) * 0.9
		for e in o.effects:
			if e.op == "status" and amt < hp:
				v += _status_value(game, f, e.status)
			elif e.op == "splash_random":
				v += float(e.amount) * 0.8
			elif e.op == "discard_random":
				v += 12.0
			elif e.op == "self_damage":
				v -= float(e.amount) * 0.5
			elif e.op == "heal" and e.get("who", "") == "self":
				v += minf(float(e.amount), float(t.damage)) * 0.6
		s += o.p * v
	return s


func _outcomes(_game: DuelGame, pi: int, t: DuelTotem, i: int) -> Array:
	var mv := t.move(i)
	if not mv.has("fate"):
		return [{"p": 1.0, "damage": int(mv.get("damage", 0)), "effects": mv.get("effects", [])}]
	var mod := _game_ref.fate_mod(pi, t.affinity()) if _game_ref != null else DuelRules.fate_mod(int(t.attrs.get(t.affinity(), 0)))
	var odds := DuelGame.band_odds(mv.fate, mod)
	var out := []
	for b in mv.fate.size():
		out.append({"p": odds[b], "damage": int(mv.fate[b].get("damage", 0)), "effects": mv.fate[b].get("effects", [])})
	return out


func _status_value(game: DuelGame, f: DuelTotem, status: String) -> float:
	match status:
		"burn":
			return 0.0 if f.burn_turns > 0 else DuelRules.burn_damage * 1.4
		"poison":
			return 0.0 if f.poisoned else DuelRules.poison_damage * 2.5
		"stun":
			return 0.0 if f.stunned else _threat(game, f.owner, f) * 0.8
		"sleep":
			return 0.0 if f.asleep else _threat(game, f.owner, f) * 1.0
	return 0.0


## Roughly how much damage this Totem will deal on its owner's next turn.
func _threat(_game: DuelGame, _owner: int, t: DuelTotem) -> float:
	var best := 0.0
	for i in t.moves().size():
		var mv := t.move(i)
		var d := float(mv.get("damage", 0))
		if mv.has("fate"):
			var odds := DuelGame.band_odds(mv.fate, DuelRules.fate_mod(int(t.attrs.get(t.affinity(), 0))))
			d = 0.0
			for b in mv.fate.size():
				d += odds[b] * int(mv.fate[b].get("damage", 0))
		if mv.get("target", "foe") == "all_foes":
			d *= 1.8
		d += t.damage_bonus(i)
		best = maxf(best, d)
	return best


func _totem_value(game: DuelGame, owner: int, t: DuelTotem) -> float:
	var v := 12.0 + t.tier() * 8.0 + t.stage() * 14.0 + t.max_hp() * 0.15 + _threat(game, owner, t) * 0.6
	if t.has_keyword("guardian"):
		v += 15.0
	return v


func _threatened(game: DuelGame, pi: int, t: DuelTotem) -> bool:
	return not game.players[1 - pi].totems().is_empty() and t.hp_left() < 80


## True if the opponent has face-down Wards that might answer this.
func _ward_risk(game: DuelGame, pi: int, _trigger: String) -> bool:
	return not game.players[1 - pi].wards.is_empty()


## Can every ready Totem, hitting Life, finish the opponent this turn?
func _lethal_available(game: DuelGame, pi: int) -> bool:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	if foe.has_guardian():
		return false
	var total := 0
	var essence := p.essence
	for t in p.totems():
		if game.ready_problem(pi, t) != "":
			continue
		if not game.can_hit_life(pi, t):
			continue
		var best := 0
		var best_cost := 0
		for i in t.moves().size():
			var mv: Dictionary = t.move(i)
			if mv.has("fate") or mv.get("target", "foe") != "foe":
				continue
			var c: int = t.move_cost(i)
			if c > essence:
				continue
			var amt: int = game.attack_amount(t, i, int(mv.get("damage", 0)), null)
			amt = maxi(mini(amt, DuelRules.guard_min_hit), amt - foe.guard())
			if amt > best:
				best = amt
				best_cost = c
		essence -= best_cost
		total += best
	return total >= foe.life


func _best_slot(game: DuelGame, pi: int, _card: DuelCard) -> int:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var best: int = p.empty_slots()[0]
	var best_v := -INF
	for s in p.empty_slots():
		var v := 0.0
		var opp = foe.slots[s]
		if opp != null:
			v += 10.0 + _threat(game, 1 - pi, opp) * 0.5   # block their path to my Life
		elif not foe.has_guardian():
			v += 6.0                                      # opens a path to their Life
		if v > best_v:
			best_v = v
			best = s
	return best


func _call_score(game: DuelGame, pi: int, c: DuelCard, _slot: int) -> float:
	var p: DuelPlayer = game.players[pi]
	var d := c.def
	var v := 26.0 + float(d.hp) * 0.2 + c.cost() * 7.0
	var best_move := 0.0
	for m in d.get("moves", []):
		best_move = maxf(best_move, float(m.get("damage", 0)))
	v += best_move * 0.25
	var kw: Array = d.get("keywords", [])
	if kw.has("guardian") and not game.players[1 - pi].totems().is_empty():
		v += 10.0
	if kw.has("swift"):
		v += 6.0
	if kw.has("channel"):
		v += 5.0
	if p.totems().is_empty():
		v += 40.0
	return v - game.call_cost(pi, c) * ESSENCE_VALUE * 0.5


func _ascend_score(game: DuelGame, pi: int, c: DuelCard, t: DuelTotem) -> float:
	var d := c.def
	var hp_gain := float(d.hp) - float(t.def().hp)
	var v := 30.0 + hp_gain * 0.4 + int(d.get("stage", 1)) * 10.0
	if t.has_condition():
		v += 12.0
	if not t.attacked and game.ready_problem(pi, t) == "":
		v += 8.0    # better moves this very turn
	return v - c.cost() * ESSENCE_VALUE * 0.5


func _rite_score(game: DuelGame, pi: int, c: DuelCard, target) -> float:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var d := c.def
	var v := 0.0
	var dmg := int(d.get("damage", 0))
	if dmg > 0:
		if d.get("target", "") == "all_foes":
			for f in foe.totems():
				var amt := game._scaled(dmg, f, c.element())
				v += minf(amt, f.hp_left())
				if amt >= f.hp_left() + f.shield:
					v += _totem_value(game, 1 - pi, f)
		elif target is DuelTotem:
			var amt := game._scaled(dmg, target, c.element())
			v += minf(amt, target.hp_left())
			if amt >= target.hp_left() + target.shield:
				v += _totem_value(game, 1 - pi, target)
	for e in d.get("effects", []):
		match e.op:
			"essence":
				v += _flask_value(game, pi, int(e.amount))
			"essence_max":
				v += maxf(0.0, (DuelRules.essence_cap - p.essence_max) * 6.0)
			"heal":
				if target is DuelTotem:
					v += minf(float(e.amount), float(target.damage)) * 0.8
			"cure":
				if target is DuelTotem and target.has_condition():
					v += 18.0
			"draw":
				v += 14.0 * int(e.count) * (1.4 if p.hand.size() <= 3 else 1.0)
			"search_totem":
				v += 30.0 if p.hand_basics().is_empty() else 12.0
			"move_foe":
				if target is DuelTotem and not foe.has_guardian():
					var mine = p.slots[target.slot]
					if mine != null and game.ready_problem(pi, mine) == "":
						v += _threat(game, pi, mine) * 0.9
			"bounce":
				if target is DuelTotem:
					v += _totem_value(game, 1 - pi, target) * 0.8 + target.stack.size() * 8.0
			"life":
				v += minf(float(e.amount), float(p.max_life - p.life)) * 0.7
			"shield":
				if target is DuelTotem:
					v += float(e.amount) * (0.5 if _threatened(game, pi, target) else 0.2)
			"buff":
				if target is DuelTotem and game.ready_problem(pi, target) == "":
					v += float(e.amount) * 1.1
			"status":
				if d.get("target", "") == "all_foes":
					for f in foe.totems():
						v += _status_value(game, f, e.status)
				elif target is DuelTotem:
					v += _status_value(game, target, e.status)
			"drain":
				if target is DuelTotem:
					v += minf(float(dmg), float(p.max_life - p.life)) * 0.5
	if _ward_risk(game, pi, "foe_rite"):
		v *= 0.9
	return v - c.cost() * ESSENCE_VALUE


func _flask_value(game: DuelGame, pi: int, amount: int) -> float:
	# Worth it only if the extra Essence lets me play something I otherwise can't.
	var p: DuelPlayer = game.players[pi]
	for c in p.hand:
		if c.kind() == "rite" and c.def.get("effects", []).any(func(e): return e.op == "essence"):
			continue
		var cost: int = c.cost()
		if c.is_basic_totem():
			cost = game.call_cost(pi, c)
			if p.empty_slots().is_empty():
				continue
		if cost > p.essence and cost <= p.essence + amount:
			return 30.0
	return -5.0


func _ward_score(game: DuelGame, pi: int, c: DuelCard) -> float:
	var foe: DuelPlayer = game.players[1 - pi]
	var v := 16.0
	match c.def.trigger:
		"foe_call":
			v += 4.0 if foe.hand.size() >= 2 else -6.0
		"foe_direct":
			v += 6.0 if not game.players[pi].has_guardian() else -8.0
		"ally_ko":
			v += 4.0 if not game.players[pi].totems().is_empty() else -8.0
		"foe_attack":
			v += 6.0 if not foe.totems().is_empty() else 0.0
	return v - c.cost() * ESSENCE_VALUE * 0.4


func _summon_score(game: DuelGame, pi: int, c: DuelCard, target) -> float:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var mv: Dictionary = c.def.move
	var dmg := int(mv.get("damage", 0))
	var v := 0.0
	if mv.get("target", "") == "all_foes":
		for f in foe.totems():
			var amt := game._scaled(dmg, f, c.element())
			v += minf(amt, f.hp_left())
			if amt >= f.hp_left() + f.shield:
				v += _totem_value(game, 1 - pi, f)
			for e in mv.get("effects", []):
				if e.op == "status" and amt < f.hp_left():
					v += _status_value(game, f, e.status)
	elif target is DuelTotem:
		var amt := game._scaled(dmg, target, c.element())
		v += minf(amt, target.hp_left())
		if amt >= target.hp_left() + target.shield:
			v += _totem_value(game, 1 - pi, target) + maxf(0.0, amt - target.hp_left())
		if mv.get("effects", []).any(func(e): return e.op == "stun_others"):
			for f in foe.totems():
				if f != target:
					v += _status_value(game, f, "stun")
	for e in mv.get("effects", []):
		match e.op:
			"heal":
				for t in p.totems():
					v += minf(float(e.amount), float(t.damage)) * 0.7
			"life":
				v += minf(float(e.amount), float(p.max_life - p.life)) * 0.6
	return v - game.summon_cost(pi, c) * ESSENCE_VALUE * 0.6


func _gift_option(game: DuelGame, pi: int) -> Dictionary:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var v := 0.0
	var target = null
	match p.gift():
		"dawns_mercy":
			for t in game.gift_targets(pi):
				var h := minf(DuelRules.mercy_heal, t.damage) + (15.0 if t.has_condition() else 0.0)
				if h > v:
					v = h
					target = t
			v = v if v >= 60.0 else 0.0
		"wrath":
			var ready := 0
			for t in p.totems():
				if game.ready_problem(pi, t) == "":
					ready += 1
			v = DuelRules.wrath_bonus * ready * 1.1 if ready >= 2 else 0.0
		"stillness":
			var threats := []
			for t in foe.totems():
				threats.append(_threat(game, 1 - pi, t))
			threats.sort()
			threats.reverse()
			v = 0.0
			for i in mini(2, threats.size()):
				v += threats[i]
			v = v if v >= 60.0 else 0.0
		"tempest":
			v = _flask_value(game, pi, DuelRules.tempest_essence) * 1.5
		"whisper":
			v = 22.0 + foe.wards.size() * 5.0 if foe.hand.size() >= 3 else 0.0
		"foresight":
			v = 34.0 if p.hand.size() <= 3 else 0.0
		"recall":
			var good := 0
			for c in p.discard:
				if not c.is_summon() and c.cost() >= 2:
					good += 1
			v = 36.0 if good >= 2 and p.hand.size() <= 4 else 0.0
		"unbound":
			v = 45.0 if p.hand.size() <= 2 else 0.0
	if v <= 0.0:
		return {}
	var action := {"type": "gift"}
	if target != null:
		action["target"] = target
	return {"score": v, "action": action}


func _shift_option(game: DuelGame, pi: int, _lethal: bool) -> Dictionary:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var cost := game.shift_cost(pi)
	if cost > p.essence:
		return {}
	var best := {}
	var best_v := 0.0
	for t in p.totems():
		for s in p.slots.size():
			if s == t.slot or game.shift_problem(pi, t, s) != "":
				continue
			var v := 0.0
			# offence: a ready Totem moving into an open lane
			if game.ready_problem(pi, t) == "" and not foe.has_guardian() and not t.has_keyword("burrow"):
				if foe.slots[s] == null and foe.slots[t.slot] != null:
					v += _threat(game, pi, t) * 0.7
			# defence: leaving a slot that faces an enemy opens my Life to it
			var here = foe.slots[t.slot]
			var there = foe.slots[s]
			if here != null and p.slots[s] == null:
				v -= _threat(game, 1 - pi, here) * 0.6
			if there != null and p.slots[s] == null:
				v += _threat(game, 1 - pi, there) * 0.6
			v -= cost * ESSENCE_VALUE
			if v > best_v:
				best_v = v
				best = {"score": v, "action": {"type": "shift", "totem": t, "slot": s}}
	return best


func _keep_value(game: DuelGame, pi: int, c: DuelCard) -> float:
	var p: DuelPlayer = game.players[pi]
	var v := 10.0 + c.tier() * 5.0
	if c.is_basic_totem():
		v += 10.0 if p.totems().size() < 3 else 0.0
	if c.is_ascension():
		var has_base := false
		for t in p.totems():
			if t.id() == c.def.ascends_from:
				has_base = true
		v += 15.0 if has_base else -5.0
	if c.is_summon():
		v += 25.0
	return v
