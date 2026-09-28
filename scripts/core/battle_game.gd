class_name BattleGame
extends RefCounted
## The rules engine for a Covenant duel. No UI code lives here.
##
## An optional `presenter` (the battle screen) is told about things worth
## animating. With no presenter and two AI controllers a whole duel runs
## instantly, which is how the automated tests play thousands of games.

signal logged(text: String, who: int)
signal state_changed

const PRIZE_COUNT := 4
const BENCH_MAX := 5
const START_HAND := 7
const MAX_TURNS := 300
const MAX_ACTIONS_PER_TURN := 80
const DAWNS_MERCY_HEAL := 80

var players: Array = []
var current := 0
var first_player := 0
var turn := 0
var rng := RandomNumberGenerator.new()
var winner := -1          # -1 = still playing, 0/1 = that player, 2 = draw
var win_reason := ""
var over := false
var phase := "setup"      # setup, main, between, over
var presenter = null
var log_lines: Array = []

var _next_card_uid := 1


# ------------------------------------------------------------------ setup ---

## decks: each entry is a deck id from SigilDB.DECKS or an Array of card ids.
## profiles: duellist profiles (Lore.new_profile); missing ones get defaults.
func setup(decks: Array, names: Array, controllers: Array, profiles: Array = [], seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	players.clear()
	for i in 2:
		var p := PlayerState.new(i, names[i])
		var spec = decks[i]
		var ids: Array = spec if spec is Array else SigilDB.card_list(spec)
		p.deck_id = spec if spec is String else "custom"
		p.profile = profiles[i] if i < profiles.size() and not profiles[i].is_empty() else Lore.new_profile(names[i])
		p.controller = controllers[i]
		for id in ids:
			p.deck.append(Card.new(_next_card_uid, id, i))
			_next_card_uid += 1
		_shuffle(p.deck)
		players.append(p)


func run() -> void:
	await _setup_phase()
	while not over:
		await _take_turn()
		if not over and turn >= MAX_TURNS:
			_finish(2, "The duel went on too long. It's a draw.")
	phase = "over"
	_changed()
	if presenter != null:
		await presenter.fx_game_over(winner, win_reason)


func _setup_phase() -> void:
	phase = "setup"
	_log("The duelling circle ignites.")
	var swift := [players[0].attribute("swiftness"), players[1].attribute("swiftness")]
	if swift[0] >= 8 and swift[1] < 8:
		first_player = 0
		_log("%s is swift enough to strike first." % players[0].player_name)
	elif swift[1] >= 8 and swift[0] < 8:
		first_player = 1
		_log("%s is swift enough to strike first." % players[1].player_name)
	else:
		var heads := await flip(0, "Coin toss - heads: %s go first" % players[0].player_name, false)
		first_player = 0 if heads else 1
	_log("%s will go first." % players[first_player].player_name)

	for p in players:
		while true:
			_draw(p, START_HAND)
			if not p.hand_basics().is_empty():
				break
			p.mulligans += 1
			_log("%s had no base Totems - reshuffling (mulligan)." % p.player_name, p.index)
			if presenter != null:
				await presenter.fx_message("%s: no base Totems - mulligan!" % p.player_name)
			p.deck.append_array(p.hand)
			p.hand.clear()
			_shuffle(p.deck)
	for p in players:
		var other: PlayerState = players[1 - p.index]
		if other.mulligans > 0:
			var n := _draw(p, other.mulligans).size()
			_log("%s drew %d extra card(s) from mulligans." % [p.player_name, n], p.index)
	_changed()

	for p in players:
		var choice: Dictionary = await p.controller.choose_setup(self, p.index)
		_apply_setup(p, choice)
	for p in players:
		for i in PRIZE_COUNT:
			if not p.deck.is_empty():
				p.prizes.append(p.deck.pop_back())
		var names := []
		for c in p.bench:
			names.append(c.card_name())
		_log("%s: Active %s%s." % [p.player_name, p.active.card_name(),
			(", Bench " + ", ".join(names)) if not names.is_empty() else ""], p.index)
	turn = 0
	current = first_player
	_changed()


func _apply_setup(p: PlayerState, choice: Dictionary) -> void:
	var act: Card = choice.get("active")
	if act == null or not p.hand.has(act) or not act.is_basic_creature():
		act = p.hand_basics()[0]
	p.hand.erase(act)
	p.active = _new_creature(act, p, 0)
	for c in choice.get("bench", []):
		if p.bench.size() >= BENCH_MAX:
			break
		if p.hand.has(c) and c.is_basic_creature():
			p.hand.erase(c)
			p.bench.append(_new_creature(c, p, 0))


func _new_creature(card: Card, p: PlayerState, t: int) -> Creature:
	return Creature.new(card, p.index, t, p.attributes())


# ------------------------------------------------------------------- turns ---

func _take_turn() -> void:
	turn += 1
	phase = "main"
	var p: PlayerState = players[current]
	p.energy_attached = 0
	p.energy_limit = 1
	p.supporter_played = false
	p.retreated = false
	p.free_retreat = false
	p.wrath = false
	_log("Turn %d - %s" % [turn, p.player_name], -2)
	if presenter != null:
		await presenter.fx_turn(current)
	if p.deck.is_empty():
		_finish(1 - current, "%s couldn't draw a card." % p.player_name)
		return
	var drawn := _draw(p, 1)
	if presenter != null and presenter.has_method("fx_draw"):
		await presenter.fx_draw(current, drawn)
	_changed()

	var actions := 0
	while not over:
		actions += 1
		if actions > MAX_ACTIONS_PER_TURN:
			break
		var action = await p.controller.choose_action(self, current)
		if action == null or action.is_empty() or action.type == "end":
			break
		var ok: bool = await perform(current, action)
		_changed()
		if over:
			return
		if ok and (action.type == "attack" or action.type == "summon"):
			break
	if over:
		return
	await _handle_knockouts()
	if over:
		return
	_end_turn_cleanup(p)
	await _checkup()
	if over:
		return
	await _handle_knockouts()
	if over:
		return
	current = 1 - current


func _end_turn_cleanup(p: PlayerState) -> void:
	var c := p.active
	if c != null and (c.special == "paralyzed" or c.special == "frozen") and c.special_turn < turn:
		_log("%s is no longer %s." % [c.card_name(), "Frozen" if c.special == "frozen" else "Paralyzed"], p.index)
		c.special = ""
	_changed()


func _checkup() -> void:
	phase = "between"
	for pi in [current, 1 - current]:
		var c: Creature = players[pi].active
		if c == null:
			continue
		if c.poisoned and not c.is_knocked_out():
			_log("%s takes 10 poison damage." % c.card_name(), pi)
			await _damage_creature(c, 10, "poison")
		if c.burned and not c.is_knocked_out():
			_log("%s takes 20 burn damage." % c.card_name(), pi)
			await _damage_creature(c, 20, "burn")
			if not c.is_knocked_out() and await flip(pi, "Burned - heads: it recovers"):
				c.burned = false
				_log("%s is no longer Burned." % c.card_name(), pi)
		if c.special == "asleep" and not c.is_knocked_out():
			if await flip(pi, "Asleep - heads: %s wakes up" % c.card_name()):
				c.special = ""
				_log("%s woke up!" % c.card_name(), pi)
			else:
				_log("%s is still Asleep." % c.card_name(), pi)
		_changed()


func _handle_knockouts() -> void:
	var kos := []
	for p in players:
		for c in p.in_play():
			if c.is_knocked_out():
				kos.append(c)
	if kos.is_empty():
		return
	for c in kos:
		var owner: PlayerState = players[c.owner]
		var taker: PlayerState = players[1 - c.owner]
		_log("%s %s was Knocked Out!" % [_poss(c.owner), c.card_name()], c.owner)
		if presenter != null:
			await presenter.fx_ko(c)
		_remove_from_play(owner, c)
		var prizes := 2 if c.tier() >= 5 else 1
		for i in prizes:
			if not taker.prizes.is_empty():
				var prize: Card = taker.prizes.pop_back()
				taker.hand.append(prize)
				_log("%s took a Prize card (%d left)." % [taker.player_name, taker.prizes.size()], taker.index)
				if presenter != null and presenter.has_method("fx_prize"):
					await presenter.fx_prize(taker.index, prize)
		_changed()

	var win0: bool = players[0].prizes.is_empty() or not players[1].has_creatures_in_play()
	var win1: bool = players[1].prizes.is_empty() or not players[0].has_creatures_in_play()
	if win0 and win1:
		_finish(2, "Both duellists met a win condition at once. It's a draw!")
		return
	for w in 2:
		if (w == 0 and win0) or (w == 1 and win1):
			if players[w].prizes.is_empty():
				_finish(w, "%s took all their Prize cards!" % players[w].player_name)
			else:
				_finish(w, "%s has no Totems left!" % players[1 - w].player_name)
			return

	for pi in [1 - current, current]:
		var p: PlayerState = players[pi]
		if p.active == null and not p.bench.is_empty():
			var choice = await p.controller.choose_promotion(self, pi)
			if choice == null or not p.bench.has(choice):
				choice = p.bench[0]
			p.bench.erase(choice)
			p.active = choice
			_log("%s sent out %s." % [p.player_name, choice.card_name()], pi)
			_changed()


func _remove_from_play(p: PlayerState, c: Creature) -> void:
	if p.active == c:
		p.active = null
	else:
		p.bench.erase(c)
	p.discard.append_array(c.all_cards())
	c.energy.clear()


func _finish(w: int, reason: String) -> void:
	if over:
		return
	over = true
	winner = w
	win_reason = reason
	phase = "over"
	_log(reason, -2)
	_changed()


# ---------------------------------------------------------------- actions ---
## {type:"bench", card}  {type:"evolve", card, target}  {type:"energy", card, target}
## {type:"trainer", card, target?}  {type:"retreat", target}  {type:"attack", index}
## {type:"summon", card}  {type:"gift", target?}  {type:"end"}

func perform(pi: int, action: Dictionary) -> bool:
	if pi != current or phase != "main":
		return false
	match action.get("type", ""):
		"bench":
			return await _act_bench(pi, action.card)
		"evolve":
			return await _act_evolve(pi, action.card, action.target)
		"energy":
			return await _act_energy(pi, action.card, action.target)
		"trainer":
			return await _act_trainer(pi, action.card, action.get("target"))
		"retreat":
			return await _act_retreat(pi, action.target)
		"attack":
			return await _act_attack(pi, int(action.index))
		"summon":
			return await _act_summon(pi, action.card)
		"gift":
			return await _act_gift(pi, action.get("target"))
	return false


# Validation - "" when allowed, otherwise the reason. ----------------------------

func bench_problem(pi: int, card: Card) -> String:
	var p: PlayerState = players[pi]
	if not p.hand.has(card) or not card.is_basic_creature():
		return "Only base Totems can be put on the Bench."
	if p.bench.size() >= BENCH_MAX:
		return "Your Bench is full."
	return ""


func evolve_targets(pi: int, card: Card) -> Array:
	var out := []
	for c in players[pi].in_play():
		if evolve_problem(pi, card, c) == "":
			out.append(c)
	return out


func evolve_problem(pi: int, card: Card, target: Creature) -> String:
	var p: PlayerState = players[pi]
	if not p.hand.has(card) or not card.is_evolution():
		return "That card can't awaken anything."
	if turn <= 2:
		return "You can't Awaken a Totem on your first turn."
	if target == null or not p.in_play().has(target):
		return "Choose one of your Totems."
	if target.top().id != card.def.get("awakens_from", ""):
		return "%s awakens from %s." % [card.card_name(), SigilDB.CARDS[card.def.awakens_from].name]
	if target.turn_played == turn:
		return "A Totem can't Awaken the turn it was played."
	if target.turn_evolved == turn:
		return "That Totem already Awakened this turn."
	return ""


func energy_problem(pi: int, card: Card, target: Creature = null) -> String:
	var p: PlayerState = players[pi]
	if not p.hand.has(card) or not card.is_energy():
		return "That isn't an Energy card."
	if p.energy_attached >= p.energy_limit:
		return "You've already attached Energy this turn."
	if target != null and not p.in_play().has(target):
		return "Choose one of your Totems."
	return ""


func trainer_problem(pi: int, card: Card) -> String:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	if not p.hand.has(card) or not card.is_trainer():
		return "That card can't be played like this."
	if card.is_supporter() and p.supporter_played:
		return "You can only play one Ally per turn."
	if card.is_supporter() and turn == 1:
		return "The first duellist can't call an Ally on turn 1."
	match card.def.op:
		"heal":
			if trainer_targets(pi, card).is_empty():
				return "None of your Totems are damaged."
		"cure_active":
			if p.active == null or (not p.active.has_condition() and p.active.damage == 0):
				return "Your Active Totem doesn't need it."
		"switch_own":
			if p.bench.is_empty():
				return "You have no Benched Totems."
		"search_basic", "search_evolution", "draw", "discard_draw":
			if p.deck.is_empty():
				return "Your deck is empty."
		"recycle_energy":
			if _energy_in(p.discard).is_empty():
				return "No Energy in your discard pile."
		"gust":
			if o.bench.is_empty():
				return "Your opponent has no Benched Totems."
		"remove_opp_energy":
			if o.active == null or o.active.energy.is_empty():
				return "Their Active Totem has no Energy."
		"revive_basic":
			if p.bench.size() >= BENCH_MAX:
				return "Your Bench is full."
			if _basic_creatures_in(p.discard).is_empty():
				return "No base Totems in your discard pile."
		"whisper":
			if o.hand.is_empty():
				return "Your opponent's hand is empty."
	return ""


func trainer_needs_target(card: Card) -> bool:
	return card.def.has("target")


func trainer_targets(pi: int, card: Card) -> Array:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	match card.def.get("target", ""):
		"own_damaged":
			var out := []
			for c in p.in_play():
				if c.damage > 0:
					out.append(c)
			return out
		"own_bench":
			return p.bench.duplicate()
		"opp_bench":
			return o.bench.duplicate()
	return []


func retreat_problem(pi: int) -> String:
	var p: PlayerState = players[pi]
	if p.active == null:
		return "No Active Totem."
	if p.retreated:
		return "You've already retreated this turn."
	if p.bench.is_empty():
		return "You have no Benched Totems to switch in."
	match p.active.special:
		"asleep":
			return "%s can't retreat while Asleep." % p.active.card_name()
		"paralyzed":
			return "%s can't retreat while Paralyzed." % p.active.card_name()
		"frozen":
			return "%s can't retreat while Frozen." % p.active.card_name()
	if p.active.energy_unit_count() < retreat_cost(pi):
		return "Retreating needs %d Energy." % retreat_cost(pi)
	return ""


func retreat_cost(pi: int) -> int:
	var p: PlayerState = players[pi]
	if p.active == null or p.free_retreat:
		return 0
	return p.active.retreat_cost()


func attack_problem(pi: int, index: int) -> String:
	var p: PlayerState = players[pi]
	if p.active == null:
		return "No Active Totem."
	var atks := p.active.attacks()
	if index < 0 or index >= atks.size():
		return "No such attack."
	if turn == 1:
		return "The first duellist can't attack on turn 1."
	match p.active.special:
		"asleep":
			return "%s is Asleep." % p.active.card_name()
		"paralyzed":
			return "%s is Paralyzed." % p.active.card_name()
		"frozen":
			return "%s is Frozen." % p.active.card_name()
	if not p.active.can_use(atks[index]):
		return "Not enough Energy."
	if players[1 - pi].active == null:
		return "No Defending Totem."
	return ""


func summon_cost(pi: int, card: Card) -> int:
	var cost: int = card.def.get("cost", []).size()
	var a: Dictionary = card.def.get("attuned", {})
	if not a.is_empty() and players[pi].attribute(card.def.get("affinity", "")) >= int(a.get("min", 99)):
		cost -= int(a.get("cost", 0))
	return maxi(0, cost)


func summon_problem(pi: int, card: Card) -> String:
	var p: PlayerState = players[pi]
	if not p.hand.has(card) or not card.is_summon():
		return "That isn't a Summon card."
	if turn == 1:
		return "You can't summon on the first turn of the duel."
	if players[1 - pi].active == null:
		return "There is nothing to strike."
	var units := 0
	for c in p.in_play():
		units += c.energy_unit_count()
	if units < summon_cost(pi, card):
		return "Summoning needs %d Energy from your Totems." % summon_cost(pi, card)
	return ""


func gift_problem(pi: int) -> String:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	var g := p.gift()
	if g == "":
		return "You have no Divine Gift."
	if p.gift_used:
		return "You've already used your Divine Gift this duel."
	match g:
		"dawns_mercy":
			if gift_targets(pi).is_empty():
				return "None of your Totems need healing."
		"wrath":
			if p.active == null:
				return "No Active Totem."
		"stillness":
			if o.active == null:
				return "No Defending Totem."
			if o.active.status_immune():
				return "The Defending Totem is Attuned and immune to Stillness."
		"whisper":
			if o.hand.is_empty():
				return "Your opponent's hand is empty."
		"recall":
			if p.discard.is_empty():
				return "Your discard pile is empty."
		"unbound":
			if p.deck.is_empty():
				return "Your deck is empty."
	return ""


func gift_targets(pi: int) -> Array:
	var p: PlayerState = players[pi]
	if p.gift() != "dawns_mercy":
		return []
	var out := []
	for c in p.in_play():
		if c.damage > 0 or c.has_condition():
			out.append(c)
	return out


func can_do_anything_but_end(pi: int) -> bool:
	var p: PlayerState = players[pi]
	for c in p.hand:
		if c.is_basic_creature() and bench_problem(pi, c) == "":
			return true
		if c.is_evolution() and not evolve_targets(pi, c).is_empty():
			return true
		if c.is_energy() and energy_problem(pi, c) == "":
			return true
		if c.is_trainer() and trainer_problem(pi, c) == "":
			return true
		if c.is_summon() and summon_problem(pi, c) == "":
			return true
	if retreat_problem(pi) == "" or gift_problem(pi) == "":
		return true
	if p.active != null:
		for i in p.active.attacks().size():
			if attack_problem(pi, i) == "":
				return true
	return false


# Action implementations --------------------------------------------------------

func _act_bench(pi: int, card: Card) -> bool:
	if bench_problem(pi, card) != "":
		return false
	var p: PlayerState = players[pi]
	p.hand.erase(card)
	var c := _new_creature(card, p, turn)
	p.bench.append(c)
	_log("%s put %s on the Bench." % [p.player_name, card.card_name()], pi)
	_changed()
	if presenter != null:
		await presenter.fx_enter(c)
	await _on_enter_play(pi, c)
	return true


func _act_evolve(pi: int, card: Card, target: Creature) -> bool:
	if evolve_problem(pi, card, target) != "":
		return false
	var p: PlayerState = players[pi]
	var old_name := target.card_name()
	p.hand.erase(card)
	target.stack.append(card)
	target.turn_evolved = turn
	target.clear_conditions()
	_log("%s %s Awakened into %s!" % [_poss(pi), old_name, card.card_name()], pi)
	_changed()
	if presenter != null:
		await presenter.fx_evolve(target)
	await _on_enter_play(pi, target)
	return true


## Attuned "draw" bonuses trigger when a Totem enters play or Awakens.
func _on_enter_play(pi: int, c: Creature) -> void:
	var n := c.attuned_value("draw")
	if n > 0:
		var got := _draw(players[pi], n).size()
		if got > 0:
			_log("%s is Attuned: %s drew %d card(s)." % [c.card_name(), players[pi].player_name, got], pi)
			_changed()
			if presenter != null:
				await presenter.fx_popup(c, "Attuned!", Color(1, 0.9, 0.5))


func _act_energy(pi: int, card: Card, target: Creature) -> bool:
	if target == null or energy_problem(pi, card, target) != "":
		return false
	var p: PlayerState = players[pi]
	p.hand.erase(card)
	target.energy.append(card)
	p.energy_attached += 1
	_log("%s attached %s to %s." % [p.player_name, card.card_name(), target.card_name()], pi)
	_changed()
	if presenter != null:
		await presenter.fx_energy(target, card)
	return true


func _act_trainer(pi: int, card: Card, target) -> bool:
	if trainer_problem(pi, card) != "":
		return false
	if trainer_needs_target(card) and (target == null or not trainer_targets(pi, card).has(target)):
		return false
	var p: PlayerState = players[pi]
	p.hand.erase(card)
	p.limbo.append(card)
	if card.is_supporter():
		p.supporter_played = true
	_log("%s played %s." % [p.player_name, card.card_name()], pi)
	_changed()
	if presenter != null:
		await presenter.fx_trainer(pi, card)
	await _resolve_trainer(pi, card, target)
	p.limbo.erase(card)
	p.discard.append(card)
	_changed()
	return true


func _resolve_trainer(pi: int, card: Card, target) -> void:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	var d := card.def
	match d.op:
		"heal":
			await _heal(target, int(d.amount))
		"cure_active":
			p.active.clear_conditions()
			_log("%s recovered from all Special Conditions." % p.active.card_name(), pi)
			await _heal(p.active, int(d.amount))
		"switch_own":
			_switch_active(p, target)
			_log("%s switched in %s." % [p.player_name, target.card_name()], pi)
			if presenter != null:
				await presenter.fx_switch(pi)
		"search_basic", "search_evolution":
			var want_basic: bool = d.op == "search_basic"
			var options := []
			for c in p.deck:
				if (want_basic and c.is_basic_creature()) or (not want_basic and c.is_evolution()):
					options.append(c)
			if options.is_empty():
				_log("%s found nothing." % p.player_name, pi)
				if presenter != null:
					await presenter.fx_message("No matching cards in the deck.")
			else:
				var pick: Array = await p.controller.choose_cards(self, pi,
					"Choose a %s to put into your hand" % ("base Totem" if want_basic else "Awakening card"),
					options, 1, 1, {"reason": d.op})
				pick = _sanitize_pick(pick, options, 1, 1)
				for c in pick:
					p.deck.erase(c)
					p.hand.append(c)
					_log("%s took %s from their deck." % [p.player_name, c.card_name()], pi)
			_shuffle(p.deck)
		"recycle_energy":
			var options := _energy_in(p.discard)
			var n := mini(int(d.count), options.size())
			var pick: Array = await p.controller.choose_cards(self, pi,
				"Choose up to %d Energy to return to your hand" % n, options, 1, n, {"reason": "recycle"})
			pick = _sanitize_pick(pick, options, 1, n)
			for c in pick:
				p.discard.erase(c)
				p.hand.append(c)
			_log("%s returned %d Energy to their hand." % [p.player_name, pick.size()], pi)
		"gust":
			_switch_active(o, target)
			_log("%s dragged out %s!" % [p.player_name, target.card_name()], pi)
			if presenter != null:
				await presenter.fx_switch(1 - pi)
		"remove_opp_energy":
			await _discard_opp_energy(pi, 1)
		"revive_basic":
			var options := _basic_creatures_in(p.discard)
			var pick: Array = await p.controller.choose_cards(self, pi,
				"Choose a base Totem to revive", options, 1, 1, {"reason": "revive"})
			pick = _sanitize_pick(pick, options, 1, 1)
			for c in pick:
				p.discard.erase(c)
				var cr := _new_creature(c, p, turn)
				var remaining := maxi(10, int(cr.max_hp() / 2.0 / 10.0) * 10)
				cr.damage = cr.max_hp() - remaining
				p.bench.append(cr)
				_log("%s revived %s!" % [p.player_name, c.card_name()], pi)
				_changed()
				if presenter != null:
					await presenter.fx_enter(cr)
		"draw":
			var n := _draw(p, int(d.count)).size()
			_log("%s drew %d cards." % [p.player_name, n], pi)
		"discard_draw":
			p.discard.append_array(p.hand)
			p.hand.clear()
			var n := _draw(p, int(d.count)).size()
			_log("%s discarded their hand and drew %d cards." % [p.player_name, n], pi)
		"whisper":
			await _whisper(pi)
	_changed()


func _act_retreat(pi: int, target: Creature) -> bool:
	if retreat_problem(pi) != "":
		return false
	var p: PlayerState = players[pi]
	if target == null or not p.bench.has(target):
		return false
	var cost := retreat_cost(pi)
	if cost > 0:
		var paid := await _choose_energy_discard(pi, [p.active], cost, "any",
			"Choose Energy to discard to retreat (%d needed)" % cost)
		for e in paid:
			p.active.energy.erase(e)
			p.discard.append(e)
	var old_name := p.active.card_name()
	_switch_active(p, target)
	p.retreated = true
	_log("%s %s retreated. %s is now Active." % [_poss(pi), old_name, target.card_name()], pi)
	_changed()
	if presenter != null:
		await presenter.fx_switch(pi)
	return true


func _act_attack(pi: int, index: int) -> bool:
	if attack_problem(pi, index) != "":
		return false
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	var att: Creature = p.active
	var atk: Dictionary = att.attacks()[index]
	var defn: Creature = o.active
	_log("%s %s used %s!" % [_poss(pi), att.card_name(), atk.name], pi)
	if presenter != null:
		await presenter.fx_attack(att, defn, atk)

	if att.special == "confused":
		if not await flip(pi, "Confused - heads: the attack works"):
			_log("%s is Confused and hurt itself!" % att.card_name(), pi)
			await _damage_creature(att, 30, "confusion")
			return true

	var effects: Array = atk.get("effects", [])
	var base := int(atk.get("damage", 0))
	var deals_damage := base > 0
	for e in effects:
		match e.op:
			"flip_plus":
				if await flip(pi, "Heads: +%d damage" % int(e.amount)):
					base += int(e.amount)
			"flip_times":
				deals_damage = true
				var heads := 0
				for i in int(e.coins):
					if await flip(pi, "Coin %d of %d" % [i + 1, int(e.coins)]):
						heads += 1
				base = heads * int(e.per)
			"plus_per_extra_energy":
				var extra := Creature.extra_of_type(att.energy_provided(), att.attack_cost(atk), e.type)
				base += mini(int(e.max), extra * int(e.per))
			"plus_per_defender_energy":
				base += int(e.per) * defn.energy_unit_count()
			"plus_if_defender_status":
				if defn.conditions().has(e.status):
					base += int(e.amount)
			"plus_if_defender_condition":
				if defn.has_condition():
					base += int(e.amount)

	if deals_damage:
		base += att.damage_bonus()
		if p.wrath:
			base += Lore.WRATH_BONUS
		var final := compute_damage(att.element(), defn, base)
		if defn.protected_turn == turn:
			_log("All damage to %s was prevented!" % defn.card_name(), 1 - pi)
			if presenter != null:
				await presenter.fx_popup(defn, "Protected!", Color(0.6, 0.85, 1.0))
		elif final > 0:
			await _damage_creature(defn, final, "attack")
		else:
			_log("%s took no damage." % defn.card_name(), 1 - pi)
			if presenter != null:
				await presenter.fx_popup(defn, "No damage", Color(0.8, 0.8, 0.8))

	await _apply_effects(pi, effects, att, defn)
	_changed()
	return true


## Post-damage effects shared by attacks and summons. `att` may be null (summons).
func _apply_effects(pi: int, effects: Array, att: Creature, defn: Creature) -> void:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	for e in effects:
		if over:
			break
		match e.op:
			"status":
				if defn != null and not defn.is_knocked_out():
					await _apply_status(defn, e.status)
			"flip_status":
				if defn != null and not defn.is_knocked_out():
					if await flip(pi, "Heads: %s" % e.status.capitalize()):
						await _apply_status(defn, e.status)
			"discard_energy_self":
				if att != null:
					var paid := await _choose_energy_discard(pi, [att], int(e.count), e.type,
						"Choose Energy to discard from %s" % att.card_name())
					for en in paid:
						att.energy.erase(en)
						p.discard.append(en)
					if not paid.is_empty():
						_log("%s discarded %d Energy." % [att.card_name(), paid.size()], pi)
					_changed()
			"heal_self":
				if att != null:
					await _heal(att, int(e.amount))
			"heal_own":
				var hurt := []
				for c in p.in_play():
					if c.damage > 0:
						hurt.append(c)
				if not hurt.is_empty():
					var t = await p.controller.choose_creature(self, pi,
						"Choose one of your Totems to heal (%d)" % int(e.amount), hurt, false, {"reason": "heal"})
					if t == null or not hurt.has(t):
						t = hurt[0]
					await _heal(t, int(e.amount))
			"self_damage":
				if att != null:
					_log("%s took %d recoil damage." % [att.card_name(), int(e.amount)], pi)
					await _damage_creature(att, int(e.amount), "recoil")
			"flip_self_damage_tails":
				if att != null and not await flip(pi, "Tails: %d damage to itself" % int(e.amount)):
					_log("%s took %d recoil damage." % [att.card_name(), int(e.amount)], pi)
					await _damage_creature(att, int(e.amount), "recoil")
			"bench_all_opp":
				for c in o.bench.duplicate():
					await _damage_creature(c, int(e.amount), "bench")
			"snipe_opp_bench":
				if not o.bench.is_empty():
					var t = await p.controller.choose_creature(self, pi,
						"Choose one of your opponent's Benched Totems (%d damage)" % int(e.amount),
						o.bench.duplicate(), false, {"reason": "snipe", "amount": int(e.amount)})
					if t == null or not o.bench.has(t):
						t = o.bench[0]
					await _damage_creature(t, int(e.amount), "snipe")
			"snipe_any":
				var opts := o.in_play()
				if not opts.is_empty():
					var t = await p.controller.choose_creature(self, pi,
						"Choose one of your opponent's Totems (%d damage)" % int(e.amount),
						opts, false, {"reason": "snipe", "amount": int(e.amount)})
					if t == null or not opts.has(t):
						t = opts[0]
					if t.protected_turn == turn:
						_log("All damage to %s was prevented!" % t.card_name(), 1 - pi)
					else:
						await _damage_creature(t, int(e.amount), "snipe")
			"summon_strike":
				if defn != null:
					var elem: String = e.get("element", "radiant")
					var dmg := compute_damage(elem, defn, int(e.amount))
					if defn.protected_turn == turn:
						_log("All damage to %s was prevented!" % defn.card_name(), 1 - pi)
					else:
						await _damage_creature(defn, dmg, "attack")
			"draw":
				var n := _draw(p, int(e.count)).size()
				_log("%s drew %d card(s)." % [p.player_name, n], pi)
				_changed()
			"flip_protect":
				if att != null and await flip(pi, "Heads: %s is protected next turn" % att.card_name()):
					att.protected_turn = turn + 1
					_log("%s braces itself!" % att.card_name(), pi)
					if presenter != null:
						await presenter.fx_popup(att, "Shielded!", Color(0.6, 0.85, 1.0))
			"brace":
				if att != null:
					att.brace_turn = turn + 1
					att.brace_amount = int(e.amount)
					_log("%s braces: -%d damage next turn." % [att.card_name(), int(e.amount)], pi)
					if presenter != null:
						await presenter.fx_popup(att, "Braced!", Color(0.8, 0.85, 0.95))
			"opp_switch":
				if defn != null and not defn.is_knocked_out():
					await _forced_switch(1 - pi)
			"flip_opp_switch":
				if defn != null and not defn.is_knocked_out() and not o.bench.is_empty():
					if await flip(pi, "Heads: opponent switches"):
						await _forced_switch(1 - pi)
			"self_switch":
				if att != null and not p.bench.is_empty() and not att.is_knocked_out():
					var opts: Array = p.bench.duplicate()
					var t = await p.controller.choose_creature(self, pi,
						"You may switch %s with a Benched Totem" % att.card_name(), opts, true,
						{"reason": "self_switch"})
					if t != null and p.bench.has(t):
						_switch_active(p, t)
						_log("%s switched in %s." % [p.player_name, t.card_name()], pi)
						if presenter != null:
							await presenter.fx_switch(pi)
			"discard_opp_energy":
				await _discard_opp_energy(pi, int(e.count))
			"discard_random_opp_hand":
				for i in int(e.count):
					if o.hand.is_empty():
						break
					var c: Card = o.hand[rng.randi_range(0, o.hand.size() - 1)]
					o.hand.erase(c)
					o.discard.append(c)
					_log("%s discarded %s from their hand." % [o.player_name, c.card_name()], 1 - pi)
				_changed()


func _act_summon(pi: int, card: Card) -> bool:
	if summon_problem(pi, card) != "":
		return false
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	var cost := summon_cost(pi, card)
	p.hand.erase(card)
	p.limbo.append(card)
	_log("%s calls down %s!" % [p.player_name, card.card_name()], pi)
	if cost > 0:
		var paid := await _choose_energy_discard(pi, p.in_play(), cost, "any",
			"Choose %d Energy from your Totems to pay for the summon" % cost)
		for e in paid:
			for c in p.in_play():
				if c.energy.has(e):
					c.energy.erase(e)
			p.discard.append(e)
	_changed()
	if presenter != null and presenter.has_method("fx_summon"):
		await presenter.fx_summon(pi, card)
	var effects: Array = card.def.get("effects", []).duplicate(true)
	for e in effects:
		if e.op == "summon_strike":
			e["element"] = card.def.element
	await _apply_effects(pi, effects, null, o.active)
	p.limbo.erase(card)
	p.discard.append(card)
	_changed()
	return true


func _act_gift(pi: int, target) -> bool:
	if gift_problem(pi) != "":
		return false
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	var g := p.gift()
	var source: String = "their own will" if p.patron() == "" else Lore.GODS[p.patron()].name
	p.gift_used = true
	_log("%s calls on %s: %s!" % [p.player_name, source, Lore.GIFTS[g].name], pi)
	if presenter != null and presenter.has_method("fx_gift"):
		await presenter.fx_gift(pi, p.patron())
	match g:
		"dawns_mercy":
			var opts := gift_targets(pi)
			if target == null or not opts.has(target):
				target = await p.controller.choose_creature(self, pi, "Dawn's Mercy: choose a Totem to heal",
					opts, false, {"reason": "heal"})
			if target == null or not opts.has(target):
				target = opts[0]
			target.clear_conditions()
			await _heal(target, mini(target.damage, DAWNS_MERCY_HEAL))
		"wrath":
			p.wrath = true
			if presenter != null:
				await presenter.fx_popup(p.active, "Wrath!", Color(1, 0.5, 0.3))
		"stillness":
			await _apply_status(o.active, "frozen")
		"tempest":
			p.free_retreat = true
			p.energy_limit += 1
		"whisper":
			await _whisper(pi)
		"foresight":
			p.foresight = true
			var seen := _draw(p, 2).size()
			_log("%s drew %d card(s)." % [p.player_name, seen], pi)
		"unbound":
			var got := _draw(p, 3).size()
			_log("%s drew %d card(s)." % [p.player_name, got], pi)
		"recall":
			var options: Array = p.discard.duplicate()
			var most := mini(2, options.size())
			var pick: Array = await p.controller.choose_cards(self, pi,
				"Rune of Recall: choose up to 2 cards to return to your hand", options, 1, most, {"reason": "recall"})
			pick = _sanitize_pick(pick, options, 1, most)
			for c in pick:
				p.discard.erase(c)
				p.hand.append(c)
				_log("%s recalled %s." % [p.player_name, c.card_name()], pi)
	_changed()
	return true


func _whisper(pi: int) -> void:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	if o.hand.is_empty():
		return
	var options: Array = o.hand.duplicate()
	var pick: Array = await p.controller.choose_cards(self, pi,
		"Your opponent's hand: choose a card to discard", options, 1, 1, {"reason": "whisper"})
	pick = _sanitize_pick(pick, options, 1, 1)
	for c in pick:
		o.hand.erase(c)
		o.discard.append(c)
		_log("%s discarded %s from %s hand." % [p.player_name, c.card_name(), _poss(1 - pi)], pi)
	_changed()


func _discard_opp_energy(pi: int, count: int) -> void:
	var p: PlayerState = players[pi]
	var o: PlayerState = players[1 - pi]
	for i in count:
		if o.active == null or o.active.energy.is_empty():
			return
		var options: Array = o.active.energy.duplicate()
		var pick: Array = await p.controller.choose_cards(self, pi,
			"Choose an Energy to discard from %s" % o.active.card_name(), options, 1, 1,
			{"reason": "remove_opp_energy", "creature": o.active})
		pick = _sanitize_pick(pick, options, 1, 1)
		for c in pick:
			o.active.energy.erase(c)
			o.discard.append(c)
			_log("%s discarded %s from %s." % [p.player_name, c.card_name(), o.active.card_name()], pi)
		_changed()


# ---------------------------------------------------------------- helpers ---

## Damage after weakness, divine protection, resistance and bracing.
func compute_damage(attack_element: String, defn: Creature, base: int) -> int:
	if base <= 0 or defn == null:
		return 0
	var d := float(base)
	if defn.weaknesses().has(attack_element):
		d = ceilf(d * Lore.WEAKNESS_MULT / 10.0) * 10.0
	if Lore.is_divine(defn.element()) and not Lore.is_divine(attack_element):
		d -= Lore.DIVINE_SHIELD
	if defn.resistance() != "" and defn.resistance() == attack_element:
		d -= Lore.RESISTANCE
	if defn.brace_turn == turn:
		d -= defn.brace_amount
	return maxi(0, int(d))


## Coin flip. Fortune (0-10) tilts it up to 60% heads; Foresight forces heads.
func flip(pi: int, label: String, allow_fortune: bool = true) -> bool:
	var p: PlayerState = players[pi]
	var heads := false
	if p.foresight and allow_fortune:
		p.foresight = false
		heads = true
		_log("Foresight guides the coin.", pi)
	else:
		var chance := 0.5
		if allow_fortune:
			chance += clampf(float(p.profile.get("fortune", 0)), 0.0, 10.0) * 0.01
		heads = rng.randf() < chance
	_log("Coin flip (%s): %s" % [label, "HEADS" if heads else "TAILS"], pi)
	if presenter != null:
		await presenter.fx_coin(pi, heads, label)
	return heads


func _damage_creature(c: Creature, amount: int, source: String) -> void:
	if amount <= 0:
		return
	c.damage += amount
	if source in ["attack", "snipe", "bench"]:
		_log("%s took %d damage." % [c.card_name(), amount], c.owner)
	_changed()
	if presenter != null:
		await presenter.fx_damage(c, amount)


func _heal(c: Creature, amount: int) -> void:
	var healed := mini(amount, c.damage)
	c.damage -= healed
	if healed > 0:
		_log("%s healed %d damage." % [c.card_name(), healed], c.owner)
		_changed()
		if presenter != null:
			await presenter.fx_heal(c, healed)


func _apply_status(c: Creature, status: String) -> void:
	if c.status_immune():
		_log("%s is Attuned and shrugs off the effect." % c.card_name(), c.owner)
		if presenter != null:
			await presenter.fx_popup(c, "Immune!", Color(0.9, 0.95, 1.0))
		return
	match status:
		"poisoned":
			c.poisoned = true
		"burned":
			c.burned = true
		_:
			c.special = status
			c.special_turn = turn
	_log("%s is now %s!" % [c.card_name(), status.capitalize()], c.owner)
	_changed()
	if presenter != null:
		await presenter.fx_popup(c, status.capitalize() + "!", Color(0.95, 0.75, 1.0))


func _switch_active(p: PlayerState, bench_creature: Creature) -> void:
	var idx := p.bench.find(bench_creature)
	if idx < 0:
		return
	var old := p.active
	if old != null:
		old.clear_conditions()
		p.bench[idx] = old
	else:
		p.bench.remove_at(idx)
	p.active = bench_creature
	_changed()


func _forced_switch(pi: int) -> void:
	var p: PlayerState = players[pi]
	if p.bench.is_empty():
		return
	var choice = await p.controller.choose_creature(self, pi,
		"Choose a Benched Totem to switch into the Active spot", p.bench.duplicate(), false,
		{"reason": "forced_switch"})
	if choice == null or not p.bench.has(choice):
		choice = p.bench[0]
	_switch_active(p, choice)
	_log("%s switched in %s." % [p.player_name, choice.card_name()], pi)
	if presenter != null:
		await presenter.fx_switch(pi)


## Picks energy to discard from `sources` totalling at least `units`.
func _choose_energy_discard(pi: int, sources: Array, units: int, type_filter: String, prompt: String) -> Array:
	var candidates := []
	for c in sources:
		for e in c.energy:
			if type_filter == "any" or e.provides().has(type_filter):
				candidates.append(e)
	if candidates.is_empty():
		return []
	var total := 0
	var all_same := true
	for e in candidates:
		total += e.energy_units()
		if e.id != candidates[0].id:
			all_same = false
	if total <= units:
		return candidates
	if all_same and sources.size() == 1:
		return auto_pick_energy(sources[0], candidates, units)
	var pick: Array = await players[pi].controller.choose_cards(self, pi, prompt, candidates,
		1, candidates.size(), {"reason": "discard_energy", "creature": sources[0], "units": units})
	var sum := 0
	var clean := []
	for e in pick:
		if candidates.has(e) and not clean.has(e):
			clean.append(e)
			sum += e.energy_units()
	if sum < units:
		return auto_pick_energy(sources[0], candidates, units)
	return clean


## Default choice of which energy to discard: keep what the attacks need.
func auto_pick_energy(c: Creature, candidates: Array, units: int) -> Array:
	var scored := []
	for e in candidates:
		var rest: Array = c.energy.duplicate()
		rest.erase(e)
		var provided := []
		for r in rest:
			provided.append_array(r.provides())
		var keep_value := 0
		if c.energy.has(e):
			for atk in c.attacks():
				if Creature.cost_payable(provided, c.attack_cost(atk)):
					keep_value += 10
		else:
			keep_value = 15
		var pref := keep_value * 10
		if not e.provides().has(c.element()):
			pref += 3
		scored.append([pref, e])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var out := []
	var sum := 0
	for s in scored:
		if sum >= units:
			break
		out.append(s[1])
		sum += s[1].energy_units()
	return out


func _sanitize_pick(pick, options: Array, min_n: int, max_n: int) -> Array:
	var out := []
	if pick is Array:
		for c in pick:
			if options.has(c) and not out.has(c) and out.size() < max_n:
				out.append(c)
	while out.size() < min_n and out.size() < options.size():
		for c in options:
			if not out.has(c):
				out.append(c)
				break
	return out


func _energy_in(cards: Array) -> Array:
	var out := []
	for c in cards:
		if c.is_energy():
			out.append(c)
	return out


func _basic_creatures_in(cards: Array) -> Array:
	var out := []
	for c in cards:
		if c.is_basic_creature():
			out.append(c)
	return out


func _draw(p: PlayerState, n: int) -> Array:
	var out := []
	for i in n:
		if p.deck.is_empty():
			break
		var c: Card = p.deck.pop_back()
		p.hand.append(c)
		out.append(c)
	return out


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _poss(pi: int) -> String:
	var n: String = players[pi].player_name
	if n == "You":
		return "Your"
	return n + "'s"


func _log(text: String, who: int = -1) -> void:
	log_lines.append(text)
	logged.emit(text, who)


func _changed() -> void:
	state_changed.emit()


func opponent(pi: int) -> PlayerState:
	return players[1 - pi]
