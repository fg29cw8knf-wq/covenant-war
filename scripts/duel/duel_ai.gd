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
	var cands := _candidates(game, pi)
	if not game.showboat_due(pi).is_empty():
		cands = _rule_showboat_only(game, pi, cands)
		best_score = -INF   # the attack is owed, however it scores
	for cand in cands:
		var s: float = cand.score
		if difficulty < 1.0:
			s += rng.randf_range(-25.0, 25.0) * (1.0 - difficulty)
		if s > best_score:
			best_score = s
			best = cand.action
	if best.is_empty():
		return {"type": "next"}   # on to the next phase (the engine ends the turn when nothing's left)
	return best


## Showboat (a story duel's rule, DuelGame.showboat_due): only the attacks the
## rule allows, until every Totem that owes one has made it.
func _rule_showboat_only(game: DuelGame, pi: int, cands: Array) -> Array:
	return cands.filter(func(c): return game.action_problem(pi, c.action) == "")


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
		"unbind":
			for s in scored:
				s.v = _standing_value(game, 1 - pi, s.c)
			scored.sort_custom(func(a, b): return a.v > b.v)
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
	if context.get("reason", "") == "sidestep":
		var me: DuelPlayer = game.players[pi]
		var best: int = slots[0]
		var best_v := -INF
		for s in slots:
			var o = me.slots[s]
			var v := 10.0 if o == null else float(o.hp_left()) * 0.1 - _totem_value(game, pi, o) * 0.05
			if v > best_v:
				best_v = v
				best = s
		return best
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
					var need := game.tributes_needed(c)
					if need > 0:
						# a Tribute call (Phase B): give up the least of mine for it
						if game.call_problem(pi, c) == "":
							var mine: Array = p.totems().duplicate()
							mine.sort_custom(func(a, b): return _totem_value(game, pi, a) < _totem_value(game, pi, b))
							var tributes: Array = mine.slice(0, need)
							var slot: int = tributes[0].slot if p.empty_slots().is_empty() else _best_slot(game, pi, c)
							if game.call_problem(pi, c, slot, tributes) == "":
								var lost := 0.0
								for tr in tributes:
									lost += _totem_value(game, pi, tr) + 6.0
								out.append({"score": _call_score(game, pi, c, slot) + c.tier() * 6.0 - lost, "action": {"type": "call", "card": c, "slot": slot, "tributes": tributes}})
					elif game.call_problem(pi, c) == "":
						var slot := _best_slot(game, pi, c)
						var cs := _call_score(game, pi, c, slot)
						out.append({"score": cs, "action": {"type": "call", "card": c, "slot": slot}})
						# veiled (Phase C): worth the extra Essence when it has a Reveal to spring
						if game.free_veil(pi):
							# (Shadow Veil: the veil costs nothing, so a Reveal Totem always wears it)
							out.append({"score": cs + (_reveal_value(game, pi, c, slot) if c.def.has("reveal") else 1.0), "action": {"type": "call", "card": c, "slot": slot, "veiled": true}})
						elif c.def.has("reveal") and game.call_cost(pi, c) + 1 <= p.essence:
							out.append({"score": cs + _reveal_value(game, pi, c, slot) - ESSENCE_VALUE, "action": {"type": "call", "card": c, "slot": slot, "veiled": true}})
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
			"relic":
				if game.relic_problem(pi, c) == "":
					for tg in game.relic_targets(pi):
						out.append({"score": _relic_score(game, pi, c, tg), "action": {"type": "relic", "card": c, "target": tg}})
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

	# --- full Favour, spent on the god's Demigod, free (Phase D)
	if game.demigod_problem(pi) == "":
		var dc := DuelCard.new(-1, game.demigod_of(pi), pi)
		var free := game.summon_cost(pi, dc) * ESSENCE_VALUE * 0.6
		if game.summon_needs_target(dc):
			for tg in game.targetable(foe.totems()):
				out.append({"score": _summon_score(game, pi, dc, tg) + free, "action": {"type": "demigod", "target": tg}})
		else:
			out.append({"score": _summon_score(game, pi, dc, null) + free, "action": {"type": "demigod"}})

	# --- an Oath (Phase D): sometimes, at the start, the one it's likeliest to keep
	if game.ai_oaths and game.own_turns(pi) <= 1 and game.phase_problem("oath") == "":
		if _oath_roll < 0.0:
			_oath_roll = rng.randf()
		if _oath_roll < OATH_CHANCE:
			var pick := _oath_pick(game, pi)
			if pick != "" and game.oath_problem(pi, pick) == "":
				out.append({"score": 3.0, "action": {"type": "oath", "oath": pick}})

	# --- stances (Phase A): Guard a threatened Totem that has no attack worth
	# more, Rest a hurt one; a Totem that can't attack this turn anyway takes
	# whichever of the two it needs
	if game.phase_problem("stance") == "":
		for t in p.totems():
			if t.stance != "strike":
				continue
			var best_attack := _best_attack_value(game, pi, t)
			var incoming := _incoming(game, pi, t)
			var likely := 1.0 / maxf(1.0, float(p.totems().size()))   # they pick one Totem to hit
			var guard_v := 0.0
			if incoming > 0.0:
				guard_v = 0.5 * minf(incoming, float(t.hp_left())) * likely
				if incoming >= t.hp_left() + t.shield and incoming * 0.5 < t.hp_left() + t.shield:
					guard_v += _totem_value(game, pi, t) * 0.6 * likely
			var rest_v := 0.8 * minf(float(DuelRules.rest_heal), float(t.damage)) + DuelRules.rest_essence * 5.0
			if t.has_status("enraged"):
				rest_v = -INF
			for st in [["guard", guard_v], ["rest", rest_v]]:
				var v: float = st[1] - best_attack
				if v > 0.5 and game.stance_problem(pi, t, st[0]) == "":
					out.append({"score": v, "action": {"type": "stance", "totem": t, "stance": st[0]}})

	# --- shifting
	if true:
		var sh := _shift_option(game, pi, lethal)
		if not sh.is_empty():
			out.append(sh)
	# only what this phase of the turn allows (Phase A): the rest waits for its phase
	return out.filter(func(c): return game.phase_problem(String(c.action.get("type", ""))) == "")


## How often the computer swears an Oath at the start of a duel.
const OATH_CHANCE := 0.35
var _oath_roll := -1.0


## The Oath this duellist is likeliest to keep: Faith with a deck full of its
## god's element, the Unbowed with a deck that guards and heals, the Swift End
## with one that only hits.
func _oath_pick(game: DuelGame, pi: int) -> String:
	var p: DuelPlayer = game.players[pi]
	var el := game.favour_element(pi)
	var totems := 0
	var mine := 0
	var tough := 0
	var fast := 0
	for c in p.deck + p.hand:
		var dc: DuelCard = c
		if not dc.is_basic_totem():
			continue
		totems += 1
		if el != "" and dc.element() == el:
			mine += 1
		if dc.element() in ["earth", "metal", "tide", "verdant"]:
			tough += 1
		if dc.element() in ["fire", "storm"]:
			fast += 1
	if totems == 0:
		return ""
	if el != "" and mine * 2 >= totems:
		return "faith"
	if tough * 2 >= totems:
		return "unbowed"
	if fast * 2 >= totems and rng.randf() < 0.5:
		return "swift"
	return "unbowed"


## The best this Totem could do attacking this turn, by the attack scores
## (0 when it can't attack).
func _best_attack_value(game: DuelGame, pi: int, t: DuelTotem) -> float:
	if game.ready_problem(pi, t) != "":
		return 0.0
	var best := 0.0
	var lethal := _lethal_available(game, pi)
	for i in t.moves().size():
		if game.move_problem(pi, t, i) != "":
			continue
		for target in game.attack_targets(pi, t, i):
			best = maxf(best, _attack_score(game, pi, t, i, target, lethal))
	return best


## The biggest blow a rival Totem could land on this one next turn.
func _incoming(game: DuelGame, pi: int, t: DuelTotem) -> float:
	var total := 0.0
	for f in game.players[1 - pi].totems():
		if f.has_status("sleep") or f.has_status("stun") or f.has_status("frozen") or f.has_status("petrified"):
			continue
		var best := 0.0
		for i in f.moves().size():
			var mv: Dictionary = f.move(i)
			if not (f.move_target(i) in ["foe", "foe_totem", "all_foes"]):
				continue
			var base := float(mv.get("damage", 0))
			if mv.has("fate"):
				base = 0.0
				for b in mv.fate:
					base += float(b.get("damage", 0))
				base /= maxf(1.0, mv.fate.size())
			var amt := float(game.attack_amount(f, i, int(base), t))
			best = maxf(best, amt)
		total = maxf(total, best)
	return total


## What an Essence is worth right now: a lot when it unlocks a call or a Rite
## in the hand, a little otherwise.
func _essence_now_value(game: DuelGame, pi: int) -> float:
	var p: DuelPlayer = game.players[pi]
	for c in p.hand:
		var cost: int = c.cost()
		if c.is_basic_totem():
			if p.empty_slots().is_empty():
				continue
			cost = game.call_cost(pi, c)
		elif c.is_rite() and c.def.get("answer", false):
			continue
		if cost == p.essence + 1:
			return 18.0
	return 3.0


## An answer on the rival's turn (Phase A): the card worth playing against
## this event, or null to let it be. Essence left over from my turn is lost at
## my next Dawn anyway, so only the card itself is weighed against the harm
## it prevents or the gain it brings.
func choose_response(game: DuelGame, pi: int, event: Dictionary, cards: Array) -> DuelCard:
	var best: DuelCard = null
	var best_v := 12.0
	for c in cards:
		if game.answer_problem(pi, c, event) != "":
			continue
		var v := _answer_value(game, pi, c, event) - _keep_value(game, pi, c) * 0.5
		if difficulty < 1.0:
			v += rng.randf_range(-20.0, 20.0) * (1.0 - difficulty)
		if v > best_v:
			best_v = v
			best = c
	return best


func _answer_value(game: DuelGame, pi: int, c: DuelCard, event: Dictionary) -> float:
	var kind := String(event.get("type", ""))
	var v := 0.0
	# what the action would do to me
	var harm := 0.0
	var ko_value := 0.0
	var target = event.get("target")
	if kind == "attack":
		var att: DuelTotem = event.get("attacker")
		var mv: Dictionary = event.get("move", {})
		var base := float(mv.get("damage", 0))
		if mv.has("fate"):
			base = 0.0
			for b in mv.fate:
				base += float(b.get("damage", 0))
			base /= maxf(1.0, mv.fate.size())
		if target is DuelTotem:
			var amt := float(game.attack_amount(att, int(event.get("index", 0)), int(base), target))
			harm = minf(amt, float(target.hp_left() + target.shield))
			if amt >= target.hp_left() + target.shield:
				ko_value = _totem_value(game, pi, target)
		elif target is String and target == DuelGame.LIFE:
			var p: DuelPlayer = game.players[pi]
			harm = maxf(0.0, float(game.attack_amount(att, int(event.get("index", 0)), int(base), null)) - p.guard())
			if harm >= p.life:
				ko_value = 500.0
	elif kind == "rite":
		var rc: DuelCard = event.get("card")
		if rc != null:
			harm = 12.0 + rc.cost() * 8.0 + float(rc.def.get("damage", 0)) * 0.8
			if bool(event.get("answer", false)):
				harm = 30.0   # their answer to my action: cancelling it keeps my action
	elif kind == "ward_spring":
		var w: DuelCard = event.get("card")
		if w != null:
			harm = 20.0 + w.tier() * 8.0
			if (w.def.get("effects", []) as Array).any(func(e): return e.op in ["negate", "cancel_rite", "bounce_called"]):
				harm += 25.0
	if c.is_ward():
		# a Ward from the hand: its own effects, as a set one springing now
		for e in c.def.effects:
			match e.op:
				"negate", "cancel_rite": v += harm + ko_value
				"shield_target": v += minf(float(e.amount), harm)
				"damage_attacker": v += float(e.amount) * 0.6
				"status_attacker":
					if event.get("attacker") is DuelTotem:
						v += _status_value(game, event.get("attacker"), e.status) * 0.8
		return v
	for e in c.def.get("effects", []):
		match e.op:
			"negate": v += harm + ko_value
			"halve": v += harm * 0.5 + (ko_value if harm * 0.5 < (target.hp_left() + target.shield if target is DuelTotem else INF) else 0.0)
			"redirect_guardian":
				var g := game._guardian_of(pi, target)
				if g != null:
					v += harm + ko_value - minf(harm, float(g.hp_left())) * 0.5
					if harm >= g.hp_left() + g.shield:
						v -= _totem_value(game, pi, g)
			"sidestep":
				if target is DuelTotem:
					var p: DuelPlayer = game.players[pi]
					var best_other := -INF
					for sl in p.slots.size():
						if sl == target.slot:
							continue
						var o = p.slots[sl]
						var there := 0.0 if o == null else -(minf(harm, float(o.hp_left())) * 0.7 + (_totem_value(game, pi, o) if harm >= o.hp_left() + o.shield else 0.0))
						best_other = maxf(best_other, there)
					v += harm + ko_value + best_other
			"bounce_rite": v += harm
			"essence": v += float(e.amount) * 4.0
			"essence_next": v += float(e.amount) * 5.0
			"draw": v += 12.0 * int(e.get("count", 1))
			"cancel_ward": v += harm
	return v


# ================================================================ scoring ===

func _attack_score(game: DuelGame, pi: int, t: DuelTotem, i: int, target, lethal: bool) -> float:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var mv := t.move(i)
	var cost := t.move_cost(i)
	var s := 0.0
	var outcomes := _outcomes(game, pi, t, i)   # [{p, damage, effects}]
	var tk := t.move_target(i)
	var odds := _attack_odds(t)
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
		s *= odds
		if lethal:
			s += 500.0 * odds
		if s <= 0.0:
			return -INF
		return s - cost * ESSENCE_VALUE
	if tk == "all_foes":
		for f in foe.totems():
			s += _hit_value(game, pi, t, i, f, outcomes)
		if _ward_risk(game, pi, "foe_attack"):
			s *= 0.85
		return s * odds - cost * ESSENCE_VALUE
	if target is DuelTotem:
		s = _hit_value(game, pi, t, i, target, outcomes)
		if target.has_keyword("thorns"):
			s -= DuelRules.thorns_damage * 0.6
		if _ward_risk(game, pi, "foe_attack"):
			s *= 0.85
		s *= odds
		if lethal:
			s *= 0.3   # finish them instead
		# a Totem with nothing better to do should still swing
		return s - cost * ESSENCE_VALUE
	return -INF


## Expected value of hitting one enemy Totem with this move.
func _hit_value(game: DuelGame, pi: int, t: DuelTotem, i: int, f: DuelTotem, outcomes: Array) -> float:
	if f.stance == "guard":
		return _hit_value_plain(game, pi, t, i, f, outcomes) * 0.5
	return _hit_value_plain(game, pi, t, i, f, outcomes)


func _hit_value_plain(game: DuelGame, pi: int, t: DuelTotem, i: int, f: DuelTotem, outcomes: Array) -> float:
	var foe: DuelPlayer = game.players[1 - pi]
	if f.face_down:
		# a veiled Totem (Phase C): the computer can't see under the card either,
		# so it weighs the blow alone, and a little for finding out what's there
		var avg := 0.0
		for o in outcomes:
			avg += o.p * float(o.damage + t.damage_bonus(i))
		return avg * 0.7 + 6.0
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
	if f == null or f.boons.has("blessed") or f.has_status(status):
		return 0.0
	if f.is_boss and status in DuelConditions.BOSS_IMMUNE:
		return 0.0
	if status == "burn" and f.has_status("soaked"):
		return 0.0
	var thr := _threat(game, f.owner, f)
	var v := 0.0
	match status:
		"burn": v = DuelRules.burn_damage * 1.4
		"poison": v = DuelRules.poison_damage * 2.5
		"corroded": v = DuelRules.corroded_bonus * 2.5
		"bleed": v = DuelRules.bleed_damage * 2.0
		"frozen": v = thr * 1.4
		"shocked": v = thr * 0.7
		"soaked": v = 10.0
		"rooted": v = 12.0 + thr * 0.2
		"petrified": v = thr * 1.0 - 20.0
		"staggered": v = thr * 0.5
		"blinded": v = thr * 0.8
		"sleep": v = thr * 1.0
		"stun": v = thr * 0.8
		"confused": v = thr * 0.7 + 10.0
		"charmed": v = thr * 0.8
		"terrified": v = thr * 0.6
		"enraged": v = 14.0 - thr * 0.1
		"silenced": v = maxf(0.0, thr - _strike_threat(f)) * 0.9
		"possessed": v = thr * 1.0 + 25.0
		"hexed": v = 12.0
		"cursed": v = 12.0
		"marked": v = DuelRules.marked_bonus * 1.0
		"drained": v = 18.0
		"doomed": v = _totem_value(game, f.owner, f) * 0.7
	# replacing a condition of the same kind loses the old one
	var old: Dictionary = f.cond(DuelConditions.kind_of(status))
	if not old.is_empty():
		v -= _status_value_plain(game, f, old.id) * 0.8
	return maxf(0.0, v)


## The value of a condition ignoring what it would replace.
func _status_value_plain(game: DuelGame, f: DuelTotem, status: String) -> float:
	var held: Dictionary = f.cond(DuelConditions.kind_of(status))
	f.conds.erase(DuelConditions.kind_of(status))
	var v := _status_value(game, f, status)
	if not held.is_empty():
		f.conds[DuelConditions.kind_of(status)] = held
	return v


## The damage of its free Strike, roughly.
func _strike_threat(t: DuelTotem) -> float:
	if t.moves().is_empty():
		return 0.0
	return float(t.move(0).get("damage", 0)) + t.damage_bonus(0)


## The chance an attack by this Totem lands at all.
func _attack_odds(t: DuelTotem) -> float:
	var ok := 1.0
	if t.has_status("shocked"):
		ok *= 1.0 - DuelRules.shock_fail / 20.0
	if t.has_status("blinded"):
		ok *= 1.0 - DuelRules.blind_fail / 20.0
	if t.has_status("confused"):
		ok *= 1.0 - DuelRules.confuse_fail / 20.0
	return ok


func _boon_value(game: DuelGame, pi: int, t: DuelTotem, boon: String) -> float:
	if t == null or t.has_boon(boon):
		return 0.0
	match boon:
		"shielded":
			return DuelRules.shielded_amount * (0.6 if _threatened(game, pi, t) else 0.25)
		"empowered":
			return DuelRules.empowered_bonus * (1.0 if game.ready_problem(pi, t) == "" else 0.6)
		"regenerating":
			return minf(float(t.damage) + 10.0, DuelRules.regen_heal * 3.0) * 0.6
		"veiled":
			return 14.0 if _threatened(game, pi, t) else 5.0
		"blessed":
			return 10.0
		"hastened":
			return 8.0
	return 0.0


## Roughly how much damage this Totem will deal on its owner's next turn.
func _threat(_game: DuelGame, _owner: int, t: DuelTotem) -> float:
	var best := 0.0
	if t.has_status("possessed") or t.has_status("petrified"):
		return 0.0
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
	# a bond waiting for it (Phase C)
	var b := DuelCards.bond_of(c.id)
	if not b.is_empty():
		for t in p.totems():
			if String(t.stack[0].id) == String(b.partner):
				v += 14.0
				break
	return v - game.call_cost(pi, c) * ESSENCE_VALUE * 0.5


## What a veiled Totem's Reveal will do when it turns up (Phase C).
func _reveal_value(game: DuelGame, pi: int, c: DuelCard, slot: int) -> float:
	var rv: Dictionary = c.def.get("reveal", {})
	var across = game.players[1 - pi].slots[slot]
	match String(rv.get("op", "")):
		"status_across":
			return _status_value(game, across, String(rv.status)) if across != null else 4.0
		"damage_across":
			return minf(float(rv.amount), float(across.hp_left())) + 4.0 if across != null else 4.0
		"draw":
			return 12.0
		"heal_allies":
			var v := 0.0
			for t in game.players[pi].totems():
				v += minf(float(rv.amount), float(t.damage)) * 0.8
			return v
	return 0.0


## A Relic on this Totem: what it adds, on one that will last (Phase C).
func _relic_score(game: DuelGame, pi: int, c: DuelCard, t: DuelTotem) -> float:
	var r: Dictionary = c.def.get("relic", {})
	var last := clampf(float(t.hp_left()) / 100.0, 0.4, 1.6)   # a hardy Totem keeps it longer
	var v := 0.0
	if r.has("damage"):
		v += float(r.damage) * 1.8 * (1.0 if game.ready_problem(pi, t) == "" or t.stance == "strike" else 0.6)
	if r.has("hp"):
		v += float(r.hp) * 0.45
	if r.has("dawn_heal"):
		v += float(r.dawn_heal) * 0.9
	if r.has("dawn_shield"):
		v += float(r.dawn_shield) * 1.0
	if r.has("fall_draw"):
		v += 10.0 * int(r.fall_draw) / last
	if r.has("move"):
		v += 16.0
	if r.has("keyword"):
		match String(r.keyword):
			"guardian":
				v += 22.0 if not game.players[pi].has_guardian() else 2.0
			"thorns", "riposte", "galvanise":
				v += 12.0
			_:
				v += 8.0
	return v * last - c.cost() * ESSENCE_VALUE


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
					if target.has_status("cursed") and e.get("who", "target") == "target":
						v -= float(e.amount)
					else:
						v += minf(float(e.amount), float(target.damage)) * 0.8
			"cure":
				if target is DuelTotem:
					var kind: String = e.get("kind", "all")
					for k in target.conds:
						if kind == "all" or kind == k:
							v += 18.0 + (20.0 if target.conds[k].id in ["doomed", "possessed", "frozen"] else 0.0)
			"boon":
				if e.get("who", "target") == "allies":
					for t in p.totems():
						v += _boon_value(game, pi, t, e.boon)
				elif target is DuelTotem:
					v += _boon_value(game, pi, target, e.boon)
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
			"revive_hand":
				var best := 0.0
				for rc in game._revivable(pi, 99):
					best = maxf(best, _keep_value(game, pi, rc))
				v += best * 0.8 + (10.0 if p.hand_basics().is_empty() else 0.0)
			"revive_field":
				var best := 0.0
				for rc in game._revivable(pi, int(e.get("max_tier", 2))):
					best = maxf(best, 10.0 + rc.tier() * 8.0 + float(rc.def.hp) * 0.15 * DuelRules.revive_hp + rc.cost() * ESSENCE_VALUE)
				v += best + (25.0 if p.totems().is_empty() else 0.0)
			"call_legend_free":
				var best := 0.0
				for lc in game._legends_in_hand(pi):
					best = maxf(best, _call_score(game, pi, lc, -1) + game.call_cost(pi, lc) * ESSENCE_VALUE * 0.5 + lc.tier() * 8.0)
				v += best
			"seek_kindred":
				v += 16.0 + (14.0 if p.hand_basics().is_empty() else 0.0)
			"discard_to_top":
				var best := 0.0
				for dc in p.discard:
					best = maxf(best, _keep_value(game, pi, dc))
				v += best * 0.35
			"terrain":
				var now := game.arena_now()
				var gain := _arena_value(game, pi, String(e.arena)) - _arena_value(game, pi, now)
				v += gain * DuelRules.terrain_turns * 0.5 if String(e.arena) != now else -15.0
			"unbind":
				var best := 0.0
				for sc in foe.continuous:
					best = maxf(best, _standing_value(game, 1 - pi, sc))
				v += best
	if bool(d.get("continuous", false)):
		v += _standing_value(game, pi, c)
		if p.continuous.size() >= DuelRules.continuous_slots:
			v -= _standing_value(game, pi, p.continuous[0])
		for sc in p.continuous:
			if (sc as DuelCard).id == c.id:
				v -= 12.0   # (a second of the same adds less)
	if _ward_risk(game, pi, "foe_rite"):
		v *= 0.9
	return v - c.cost() * ESSENCE_VALUE


## Roughly how much a turn on this ground is worth to `pi` (Phase D).
func _arena_value(game: DuelGame, pi: int, a: String) -> float:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	match a:
		"tidegrove":
			return (foe.totems().size() - p.totems().size()) * 4.0
		"emberforge":
			return (p.wards.size() - foe.wards.size()) * 8.0
		"ironstone":
			return 6.0 if p.life < foe.life else -2.0
		"solhaven":
			return 8.0 if p.totems().size() < foe.totems().size() else (-6.0 if foe.totems().size() < p.totems().size() else 0.0)
	return 0.0


## What a Continuous Rite standing on `pi`'s side is worth to them, roughly a
## few turns' use of it.
func _standing_value(game: DuelGame, pi: int, c: DuelCard) -> float:
	var p: DuelPlayer = game.players[pi]
	var foe: DuelPlayer = game.players[1 - pi]
	var st: Dictionary = c.def.get("standing", {})
	var v := 6.0
	if st.has("element_damage"):
		for t in p.totems():
			if t.element() == String(st.element):
				v += float(st.amount) * 1.6
		for h in p.hand:
			if (h as DuelCard).is_totem() and (h as DuelCard).element() == String(st.element):
				v += 4.0
	elif st.has("dawn_heal"):
		for t in p.totems():
			v += minf(float(st.dawn_heal), float(t.damage)) * 1.2 + 4.0
	elif st.has("foe_ward_tax"):
		v += 6.0 + foe.wards.size() * 3.0
	elif st.has("thorn_all"):
		v += float(st.amount) * 0.8 * foe.totems().size()
	elif st.has("storm_swift"):
		for h in p.hand:
			if (h as DuelCard).is_basic_totem() and (h as DuelCard).element() == "storm":
				v += 10.0
	elif st.has("free_veil"):
		for h in p.hand:
			if (h as DuelCard).is_basic_totem():
				v += 10.0 if (h as DuelCard).def.has("reveal") else 2.0
	return v


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
			if not p.hand_basics().is_empty() and not p.empty_slots().is_empty():
				v += 15.0
		"whisper":
			v = 22.0 + foe.wards.size() * 5.0 if foe.hand.size() >= 3 else 0.0
		"foresight":
			v = 26.0 if p.hand.size() <= 3 else 0.0
		"recall":
			var good := 0
			for c in p.discard:
				if not c.is_summon() and c.cost() >= 2:
					good += 1
			v = 36.0 if good >= 2 and p.hand.size() <= 4 else 0.0
		"unbound":
			v = 32.0 if p.hand.size() <= 2 else 0.0
		"contagion":
			v = 0.0
			for t in foe.totems():
				v += 10.0 + _status_value(game, t, "poison")
			v = v if v >= 50.0 else 0.0
		"regrowth":
			v = 0.0
			for t in p.totems():
				v += minf(40.0, float(t.damage)) + (15.0 if not t.cond("body").is_empty() else 0.0)
			v = v if v >= 55.0 else 0.0
		"undertow":
			v = 0.0
			for t in foe.totems():
				v += _totem_value(game, 1 - pi, t) * 0.6 + (t.stack.size() - 1) * 18.0 - t.damage * 0.3
			v = v if v >= 70.0 else 0.0
		"star_chart":
			v = 22.0 + (14.0 if p.hand.size() <= 3 else 0.0)
			for t in p.totems():
				for i in t.moves().size():
					if t.move(i).has("fate") and game.move_problem(pi, t, i) == "":
						v += 8.0
		"forged_guard":
			var attackers := 0
			for t in foe.totems():
				attackers += 1
			v = p.guard() * attackers * 2.0 + p.totems().size() * 30.0 * (0.6 if attackers > 0 else 0.2)
			v = v if v >= 40.0 else 0.0
		"unveil":
			v = 26.0 + foe.wards.size() * 6.0
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
		if game.tributes_needed(c) > p.totems().size():
			v -= 8.0   # can't be paid for yet
	if c.is_ascension():
		var has_base := false
		for t in p.totems():
			if t.id() == c.def.ascends_from:
				has_base = true
		v += 15.0 if has_base else -5.0
	if c.is_summon():
		v += 25.0
	return v
