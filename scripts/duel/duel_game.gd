class_name DuelGame
extends RefCounted
## The rules engine for a Covenant duel under the v1 rules: three Totem slots
## a side, Life, Essence, Fate dice, Wards and Ascension. No UI code lives here.
##
## Controllers (a person's screen or the computer) answer:
##   choose_action(game, pi) -> Dictionary        (see perform() for the shapes)
##   choose_cards(game, pi, prompt, cards, min_n, max_n, context) -> Array
##   choose_totems(game, pi, prompt, totems, min_n, max_n) -> Array
##   choose_slot(game, pi, prompt, slots, context) -> int
##   choose_reroll(game, pi, info) -> bool
##   choose_scry(game, pi, card) -> bool          (true = leave it on top)
##
## An optional `presenter` is told about things worth animating. Every hook is
## optional; with no presenter a whole duel between two computer players runs
## instantly, which is how the balance tests play thousands of games.
##   fx_start, fx_turn(pi), fx_draw(pi, cards), fx_call(totem), fx_ascend(totem),
##   fx_rite(pi, card, target), fx_ward_set(pi, card), fx_ward_spring(pi, card, ctx),
##   fx_shift(pi), fx_attack(totem, move_index, target), fx_roll(pi, info),
##   fx_totem_hit(totem, amount, info), fx_life_hit(pi, amount, info),
##   fx_heal(totem, amount), fx_life_gain(pi, amount), fx_status(totem, status),
##   fx_ko(totem), fx_summon(pi, card), fx_gift(pi, gift), fx_message(text),
##   fx_game_over(winner, reason)

signal logged(text: String, who: int)
signal state_changed

const LIFE := "life"      # the attack target that means "their Life"
const NONE := "none"      # a move that needs no target

var players: Array = []
var current := 0
var first_player := 0
var turn := 0
var rng := RandomNumberGenerator.new()
var winner := -1          # -1 = still playing, 0/1 = that player, 2 = draw
var win_reason := ""
var over := false
var phase := "setup"      # setup, main, over
var presenter = null
var log_lines: Array = []

var _next_uid := 1
## Above 0, both duellists start on this Life instead of their attribute total (story tutorials).
var start_life := 0
## The Dominion Law this duel is fought under (a god's id, "ironvault" or ""). See DuelLaws.
var law := ""
## Ward card uids that lie face up (Ysolde's Unveiling, or the Unveil Gift).
var face_up := {}


# ------------------------------------------------------------------ setup ---

## decks: each entry is a deck id from DuelCards.DECKS or an Array of card ids.
## profiles: duellist profiles (Lore.new_profile); missing ones get defaults.
func setup(decks: Array, names: Array, controllers: Array, profiles: Array = [], seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	players.clear()
	for i in 2:
		var p := DuelPlayer.new(i, names[i])
		var spec = decks[i]
		var ids: Array = spec if spec is Array else DuelCards.card_list(spec)
		p.deck_id = spec if spec is String else "custom"
		p.profile = profiles[i] if i < profiles.size() and not profiles[i].is_empty() else Lore.new_profile(names[i])
		p.controller = controllers[i]
		for id in ids:
			p.deck.append(DuelCard.new(_next_uid, id, i))
			_next_uid += 1
		_shuffle(p.deck)
		players.append(p)


func run() -> void:
	await _setup_phase()
	await _fx("fx_start", [])
	while not over:
		await _take_turn()
		if not over and turn >= DuelRules.max_turns:
			_finish(2, "The duel went on too long. It's a draw.")
	phase = "over"
	_changed()
	await _fx("fx_game_over", [winner, win_reason])


func _setup_phase() -> void:
	phase = "setup"
	_log("The duelling circle ignites.")
	for p in players:
		p.max_life = start_life if start_life > 0 else DuelRules.life_for(p.attributes())
		p.life = p.max_life
		p.fortune_left = mini(2, int(p.profile.get("fortune", 0)))
		if law == "hethrin" and blessed(p.index):
			p.guard_bonus = DuelLaws.ironworks_guard
		if law == "nocthra":
			p.extra_ward_slots = 1
	if law != "":
		_log("This duel is fought under %s: %s" % [DuelLaws.law_name(law), DuelLaws.describe(law)])
	# Both roll a d20; Swiftness adds its Fate modifier, so the swifter
	# duellist goes first more often (but not always).
	while true:
		var m0 := DuelRules.fate_mod(players[0].attribute("swiftness"))
		var m1 := DuelRules.fate_mod(players[1].attribute("swiftness"))
		var r0 := rng.randi_range(1, 20)
		var r1 := rng.randi_range(1, 20)
		await _fx("fx_rolloff", [r0 + m0, r1 + m1])
		if r0 + m0 != r1 + m1:
			first_player = 0 if r0 + m0 > r1 + m1 else 1
			_log("Roll for first turn: %s %d, %s %d. %s goes first." % [players[0].player_name, r0 + m0,
				players[1].player_name, r1 + m1, players[first_player].player_name])
			break
	for p in players:
		var n: int = DuelRules.start_hand
		if DuelRules.has_perk(p.attributes(), "intellect"):
			n += DuelRules.intellect_hand_bonus
		if p.index != first_player:
			n += DuelRules.second_player_bonus_cards
		for attempt in 12:
			_draw_raw(p, n)
			if not p.hand_basics().is_empty():
				break
			_log("%s had no Basic Totem - reshuffling." % p.player_name, p.index)
			p.deck.append_array(p.hand)
			p.hand.clear()
			_shuffle(p.deck)
	turn = 0
	current = first_player
	_changed()


# ------------------------------------------------------------------- turns ---

func _take_turn() -> void:
	turn += 1
	phase = "main"
	var p: DuelPlayer = players[current]
	p.shifts = 0
	p.free_shift = false
	p.totems_called = 0
	p.wrath = false
	p.fate_bonus = 0
	p.guard_double = false
	for t in p.totems():
		t.attacked = false
		t.buff = 0
	if p.essence_max < DuelRules.essence_cap:
		p.essence_max += 1
	p.essence = p.essence_max
	if p.pending_essence > 0:
		p.essence += p.pending_essence
		_log("%s gains %d drained Essence." % [p.player_name, p.pending_essence], current)
		p.pending_essence = 0
	_log("Turn %d - %s" % [turn, p.player_name], -2)
	await _fx("fx_turn", [current])
	if turn > 1:
		var drawn := await _draw(p, 1)
		if over:
			return
		if not drawn.is_empty():
			await _fx("fx_draw", [current, drawn])
	_changed()
	await _dawn_conditions(p)
	if over:
		return
	if DuelRules.has_perk(p.attributes(), "insight") and not p.deck.is_empty():
		var keep: bool = await p.controller.choose_scry(self, current, p.deck[-1])
		if not keep:
			p.deck.insert(0, p.deck.pop_back())
			_log("%s sends the top card of their deck to the bottom." % p.player_name, current)
	await _possessed_strikes(p)
	if over:
		return

	var actions := 0
	while not over:
		actions += 1
		if actions > DuelRules.MAX_ACTIONS_PER_TURN:
			break
		_changed()
		var action = await p.controller.choose_action(self, current)
		if over:
			return
		if action == null or action.is_empty() or action.type == "end":
			break
		await perform(current, action)
	if over:
		return
	await _dusk(p)
	current = 1 - current


func _dawn_conditions(p: DuelPlayer) -> void:
	await _dawn_law(p)
	if over:
		return
	for t in p.totems():
		if t.is_knocked_out():
			continue
		if t.boons.has("veiled"):
			t.remove_boon("veiled")
			_log("%s steps out of the veil." % t.card_name(), p.index)
		if t.boons.has("regenerating"):
			await _heal(t, DuelRules.regen_heal)
		if t.has_status("burn"):
			_log("%s burns." % t.card_name(), p.index)
			await _damage_totem(t, DuelRules.burn_damage, {"source": "burn"})
		if t.has_status("poison") and not t.is_knocked_out():
			_log("%s suffers from poison." % t.card_name(), p.index)
			await _damage_totem(t, DuelLaws.plague_poison if law == "vexa" else DuelRules.poison_damage, {"source": "poison"})
		if t.has_status("drained") and not t.is_knocked_out():
			var dc: Dictionary = t.condition_of("drained")
			if p.essence > 0:
				p.essence -= 1
			var drainer := int(dc.get("src_owner", 1 - p.index))
			if drainer < 0:
				drainer = 1 - p.index
			if drainer != p.index:
				players[drainer].pending_essence += 1
			_log("%s is drained: %s loses 1 Essence." % [t.card_name(), p.player_name], p.index)
		if t.has_status("doomed") and not t.is_knocked_out():
			var dd: Dictionary = t.condition_of("doomed")
			dd.dawns = int(dd.get("dawns", 0)) + 1
			if int(dd.dawns) >= DuelRules.doom_dawns:
				_log("Doom claims %s!" % t.card_name(), p.index)
				t.damage = t.max_hp()
				await _fx("fx_totem_hit", [t, 0, {"source": "doom"}])
			else:
				_log("%s is Doomed: %d Dawn%s left." % [t.card_name(), DuelRules.doom_dawns - int(dd.dawns),
					"" if DuelRules.doom_dawns - int(dd.dawns) == 1 else "s"], p.index)
		if t.is_knocked_out():
			continue
		# breaking free: Sleep, Frozen and Possessed
		for id in t.conditions():
			if not DuelConditions.breaks_free(id):
				continue
			var kind := DuelConditions.kind_of(id)
			var mod := DuelRules.fate_mod(int(t.attrs.get(DuelConditions.KIND_ATTR[kind], 0)))
			var r := rng.randi_range(1, 20)
			var need := DuelRules.wake_roll
			if id == "sleep" and law == "vaelith" and not blessed(p.index):
				need = DuelLaws.winter_wake
			if id == "frozen":
				need = DuelRules.frozen_roll
			var ok := r + mod >= need or r == 20
			var verb: String = {"sleep": ["wakes", "sleeps on"], "frozen": ["thaws", "stays frozen"],
				"possessed": ["breaks free", "stays possessed"]}.get(id, ["breaks free", "is held"])[0 if ok else 1]
			await _fx("fx_roll", [p.index, {"label": "%s tries to break free" % t.card_name(), "roll": r, "mod": mod,
				"total": r + mod, "index": 1 if ok else 0, "bands": [], "text": verb}])
			_log("%s rolls %d%s and %s." % [t.card_name(), r, (" +%d" % mod) if mod > 0 else "", verb], p.index)
			if ok:
				t.remove_status(id)
				await _fx("fx_status", [t, ""])
	await _resolve_knockouts()


## The Law's own effects at the start of a duellist's turn.
func _dawn_law(p: DuelPlayer) -> void:
	match law:
		"solmaris":
			var worst: DuelTotem = null
			for t in p.totems():
				if t.damage > 0 and (worst == null or t.damage > worst.damage):
					worst = t
			if worst != null:
				await _heal(worst, DuelLaws.dawnlight_blessed_heal if blessed(p.index) else DuelLaws.dawnlight_heal)
		"maerith":
			var mine := p.totems().size()
			var theirs := opponent(p.index).totems().size()
			if mine < theirs or (mine == theirs and blessed(p.index)):
				_log("The High Tide brings %s an extra card." % p.player_name, p.index)
				var drawn := await _draw(p, 1)
				if not drawn.is_empty():
					await _fx("fx_draw", [p.index, drawn])
		"oriel":
			if not p.deck.is_empty():
				var keep: bool = await p.controller.choose_scry(self, p.index, p.deck[-1])
				if not keep:
					p.deck.insert(0, p.deck.pop_back())
					_log("%s sends the top card of their deck to the bottom." % p.player_name, p.index)
			if blessed(p.index) and not opponent(p.index).deck.is_empty():
				_log("Oriel shows %s the top of their opponent's deck: %s." % [p.player_name,
					opponent(p.index).deck[-1].card_name()], p.index)
		"aldrith":
			if blessed(p.index) and not p.rite_recalled:
				var rites := p.discard.filter(func(c): return c.is_rite())
				if not rites.is_empty():
					var chosen: Array = await p.controller.choose_cards(self, p.index,
						"Runebound Blessing: return a Rite to your hand?", rites, 0, 1, {"reason": "recall"})
					for c in chosen.slice(0, 1):
						if p.discard.has(c):
							p.discard.erase(c)
							p.hand.append(c)
							p.rite_recalled = true
							_log("%s returns %s to their hand." % [p.player_name, c.card_name()], p.index)


func _dusk(p: DuelPlayer) -> void:
	if p.hand.size() > DuelRules.hand_limit:
		var n := p.hand.size() - DuelRules.hand_limit
		var chosen: Array = await p.controller.choose_cards(self, p.index,
			"Your hand is full. Discard %d card%s." % [n, "" if n == 1 else "s"], p.hand.duplicate(), n, n, {"reason": "hand_limit"})
		for c in chosen:
			if p.hand.has(c):
				p.hand.erase(c)
				p.discard.append(c)
		while p.hand.size() > DuelRules.hand_limit:
			p.discard.append(p.hand.pop_back())
	if law == "pyrrhane":
		for t in p.totems():
			if blessed(p.index) and t.element() == "fire":
				continue
			await _damage_totem(t, DuelLaws.forge_heat, {"source": "heat"})
		await _resolve_knockouts()
		if over:
			return
	for t in p.totems():
		_count_down(t)
		t.buff = 0
	p.wrath = false
	_changed()


## At its owner's Dusk every timed condition and boon ticks down one turn
## (one put on during this very turn doesn't count it).
func _count_down(t: DuelTotem) -> void:
	for k in t.conds.keys():
		var c: Dictionary = t.conds[k]
		if int(c.left) <= 0 or int(c.applied) == turn:
			continue
		c.left = int(c.left) - 1
		if int(c.left) <= 0:
			t.conds.erase(k)
			_log("%s is no longer %s." % [t.card_name(), DuelConditions.display_name(c.id)], t.owner)
	for b in t.boons.keys():
		var bd: Dictionary = t.boons[b]
		if int(bd.left) <= 0 or int(bd.applied) == turn:
			continue
		bd.left = int(bd.left) - 1
		if int(bd.left) <= 0:
			t.boons.erase(b)


func _finish(w: int, reason: String) -> void:
	if over:
		return
	over = true
	winner = w
	win_reason = reason
	phase = "over"
	_log(reason, -2)


# ================================================================ actions ===

## Carries out an action. Shapes:
##   {type: "call", card, slot}          {type: "ascend", card, target}
##   {type: "rite", card, target?}       {type: "ward", card}
##   {type: "shift", totem, slot}        {type: "attack", attacker, move, target}
##   {type: "summon", card, target?}     {type: "gift", target?}
## Returns false (and does nothing) if the action isn't allowed.
func perform(pi: int, action: Dictionary) -> bool:
	var problem := action_problem(pi, action)
	if problem != "":
		_log("(Not allowed: %s)" % problem, pi)
		return false
	match action.type:
		"call":
			await _act_call(pi, action.card, int(action.slot))
		"ascend":
			await _act_ascend(pi, action.card, action.target)
		"rite":
			await _act_rite(pi, action.card, action.get("target"))
		"ward":
			await _act_ward(pi, action.card)
		"shift":
			await _act_shift(pi, action.totem, int(action.slot))
		"attack":
			await _act_attack(pi, action.attacker, int(action.move), action.target)
		"summon":
			await _act_summon(pi, action.card, action.get("target"))
		"gift":
			await _act_gift(pi, action.get("target"))
	_changed()
	return true


func action_problem(pi: int, action: Dictionary) -> String:
	if over:
		return "The duel is over."
	if pi != current:
		return "It isn't your turn."
	match action.get("type", ""):
		"call":
			return call_problem(pi, action.get("card"), int(action.get("slot", -1)))
		"ascend":
			return ascend_problem(pi, action.get("card"), action.get("target"))
		"rite":
			return rite_problem(pi, action.get("card"), action.get("target"))
		"ward":
			return ward_problem(pi, action.get("card"))
		"shift":
			return shift_problem(pi, action.get("totem"), int(action.get("slot", -1)))
		"attack":
			return move_problem(pi, action.get("attacker"), int(action.get("move", 0)), action.get("target"), true)
		"summon":
			return summon_problem(pi, action.get("card"), action.get("target"))
		"gift":
			return gift_problem(pi, action.get("target"))
	return "Unknown action."


# --------------------------------------------------------------- queries ---

func opponent(pi: int) -> DuelPlayer:
	return players[1 - pi]


func call_cost(pi: int, card: DuelCard) -> int:
	var p: DuelPlayer = players[pi]
	var c := card_cost(pi, card)
	if p.totems_called == 0 and DuelRules.has_perk(p.attributes(), "presence"):
		c = maxi(0, c - DuelRules.presence_discount)
	return c


func summon_cost(pi: int, card: DuelCard) -> int:
	return card_cost(pi, card)


## A card's Essence cost under this duel's Law (never below 1 for a card
## that costs anything).
func card_cost(_pi: int, card: DuelCard) -> int:
	var c := card.cost()
	if c <= 0 or law == "":
		return c
	var el := card.element()
	var d := 0
	match law:
		"pyrrhane":
			if el == "fire": d -= 1
		"verdanthe":
			if el == "verdant": d -= 1
		"aldrith":
			if card.is_rite(): d -= 1
		"hethrin":
			if el == "metal": d -= 1
			if card.is_ward(): d += 1
	return maxi(1, c + d)


## True if this duellist is sworn to the god whose Law this duel follows.
func blessed(pi: int) -> bool:
	return law != "" and law != "ironvault" and players[pi].patron() == law


func call_problem(pi: int, card: DuelCard, slot: int = -1) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_basic_totem():
		return "Only Basic Totems can be called."
	if p.empty_slots().is_empty():
		return "All three of your slots are full."
	if slot >= 0 and (slot >= p.slots.size() or p.slots[slot] != null):
		return "That slot is taken."
	var c := call_cost(pi, card)
	if c > p.essence:
		return "Needs %d Essence." % c
	return ""


func ascend_targets(pi: int, card: DuelCard) -> Array:
	var out := []
	if card == null or not card.is_ascension():
		return out
	for t in players[pi].totems():
		if t.id() == card.def.ascends_from and t.called_turn < turn and t.ascended_turn != turn \
				and not t.has_status("possessed"):
			out.append(t)
	return out


## Essence to Ascend this Totem (a Hexed Totem pays 1 more).
func ascend_cost(card: DuelCard, target = null) -> int:
	var c := card_cost(card.owner, card)
	if target is DuelTotem and target.has_status("hexed"):
		c += 1
	return c


func ascend_problem(pi: int, card: DuelCard, target = null) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_ascension():
		return "That isn't an Ascension."
	var targets := ascend_targets(pi, card)
	if targets.is_empty():
		var any := false
		for t in p.totems():
			if t.id() == card.def.ascends_from:
				any = true
		if any:
			return "%s must be in play since your last turn." % DuelCards.CARDS[card.def.ascends_from].name
		return "Needs %s in play." % DuelCards.CARDS[card.def.ascends_from].name
	if target != null and not targets.has(target):
		return "That Totem can't Ascend into %s." % card.card_name()
	var tg = target if target != null else targets[0]
	if ascend_cost(card, tg) > p.essence:
		return "Needs %d Essence." % ascend_cost(card, tg)
	return ""


func rite_targets(pi: int, card: DuelCard) -> Array:
	match card.def.get("target", "none"):
		"ally":
			return players[pi].totems()
		"foe_totem":
			return targetable(opponent(pi).totems())
	return []


## Enemy Totems that can be singled out (Veiled ones can't).
func targetable(totems: Array) -> Array:
	return totems.filter(func(t): return not t.boons.has("veiled"))


func rite_needs_target(card: DuelCard) -> bool:
	var t: String = card.def.get("target", "none")
	return t == "ally" or t == "foe_totem"


func rite_problem(pi: int, card: DuelCard, target = null) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_rite():
		return "That isn't a Rite."
	if card_cost(pi, card) > p.essence:
		return "Needs %d Essence." % card_cost(pi, card)
	var tk: String = card.def.get("target", "none")
	if rite_needs_target(card):
		var ts := rite_targets(pi, card)
		if ts.is_empty():
			return "There's no Totem to target." if tk == "foe_totem" else "You have no Totem to target."
		if target != null and not ts.has(target):
			return "Not a valid target."
	if tk == "all_foes" and opponent(pi).totems().is_empty():
		return "Your opponent has no Totems."
	for e in card.def.get("effects", []):
		match e.op:
			"move_foe":
				if opponent(pi).empty_slots().is_empty():
					return "Their slots are all full."
			"search_totem":
				var any := false
				for c in p.deck:
					if c.is_basic_totem():
						any = true
						break
				if not any:
					return "There are no Basic Totems left in your deck."
			"heal":
				if e.get("who", "") == "target" and target != null and target is DuelTotem \
						and target.damage == 0 and not target.has_condition():
					return "That Totem isn't hurt."
	return ""


func ward_problem(pi: int, card: DuelCard) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_ward():
		return "That isn't a Ward."
	if p.wards.size() >= p.ward_slots():
		return "Your Ward slots are full."
	if card_cost(pi, card) > p.essence:
		return "Needs %d Essence." % card_cost(pi, card)
	return ""


func shift_cost(pi: int) -> int:
	var p: DuelPlayer = players[pi]
	if p.free_shift or DuelRules.has_perk(p.attributes(), "swiftness") or law == "ixara":
		return 0
	return DuelRules.shift_cost + (1 if law == "vaelith" else 0)


func shift_problem(pi: int, totem, slot: int) -> String:
	var p: DuelPlayer = players[pi]
	var allowed := 2 if DuelRules.has_perk(p.attributes(), "swiftness") else 1
	if law == "ixara" and blessed(pi):
		allowed += 1
	if p.shifts >= allowed:
		return "You've already shifted this turn."
	if totem == null or not (totem is DuelTotem) or totem.owner != pi or not p.totems().has(totem):
		return "Choose one of your Totems."
	for id in ["frozen", "rooted", "enraged", "possessed"]:
		if totem.has_status(id):
			return "%s is %s and can't Shift." % [totem.card_name(), DuelConditions.display_name(id)]
	if slot < 0 or slot >= p.slots.size() or slot == totem.slot:
		return "Choose a different slot."
	if shift_cost(pi) > p.essence:
		return "Needs %d Essence." % shift_cost(pi)
	return ""


## Why this Totem can't attack right now ("" if it can).
func ready_problem(pi: int, t) -> String:
	if t == null or not (t is DuelTotem) or t.owner != pi or not players[pi].totems().has(t):
		return "Choose one of your Totems."
	if t.attacked:
		return "%s has already attacked this turn." % t.card_name()
	if turn == 1:
		return "Nobody can attack on the first turn of the duel."
	if t.called_turn == turn and not t.has_keyword("swift"):
		return "%s was called this turn. It can attack next turn." % t.card_name()
	if t.asleep:
		return "%s is asleep." % t.card_name()
	if t.stunned:
		return "%s is stunned." % t.card_name()
	if t.has_status("frozen"):
		return "%s is frozen solid." % t.card_name()
	if t.has_status("petrified"):
		return "%s is turned to stone." % t.card_name()
	if t.has_status("possessed"):
		return "%s is possessed and won't obey you." % t.card_name()
	return ""


func can_hit_life(pi: int, t: DuelTotem) -> bool:
	var foe := opponent(pi)
	if foe.has_guardian():
		return false
	if t.has_keyword("burrow"):
		return true
	return foe.slots[t.slot] == null


## Everything this move could be aimed at: DuelTotems, LIFE or NONE.
func attack_targets(pi: int, t: DuelTotem, i: int) -> Array:
	var foe := opponent(pi)
	var out: Array = []
	match t.move_target(i):
		"foe":
			out = targetable(foe.totems())
			if can_hit_life(pi, t):
				out.append(LIFE)
		"foe_totem":
			out = targetable(foe.totems())
		"ally":
			return [] if t.has_status("enraged") else players[pi].totems()
		"all_foes":
			return [NONE] if not foe.totems().is_empty() else []
		_:
			return [] if t.has_status("enraged") else [NONE]
	return _restrict_targets(pi, t, out)


## Rooted, Charmed, Terrified and Enraged narrow what a Totem may single out.
func _restrict_targets(pi: int, t: DuelTotem, out: Array) -> Array:
	var foe := opponent(pi)
	if t.has_status("rooted"):
		out = out.filter(func(x): return (x is String and x == LIFE) or (x is DuelTotem and x.slot == t.slot))
	if t.has_status("charmed"):
		var cc: Dictionary = t.condition_of("charmed")
		if int(cc.get("src_owner", foe.index)) == foe.index:
			out = []   # it won't lift a claw against the side that charmed it
	if t.has_status("terrified"):
		var tc: Dictionary = t.condition_of("terrified")
		var src := int(tc.get("src_uid", -1))
		out = out.filter(func(x): return not (x is DuelTotem and x.uid == src))
	if t.has_status("enraged"):
		var foes := out.filter(func(x): return x is DuelTotem)
		if not foes.is_empty():
			var top := 0
			for f in foes:
				top = maxi(top, f.hp_left())
			out = foes.filter(func(f): return f.hp_left() == top)
	return out


func move_problem(pi: int, t, i: int, target = null, check_target: bool = false) -> String:
	var r := ready_problem(pi, t)
	if r != "":
		return r
	if i < 0 or i >= t.moves().size():
		return "Unknown move."
	if t.has_status("silenced") and int(t.move(i).get("cost", 0)) > 0:
		return "%s is silenced and can only Strike." % t.card_name()
	var c: int = t.move_cost(i)
	if c > players[pi].essence:
		return "Needs %d Essence." % c
	var ts := attack_targets(pi, t, i)
	if ts.is_empty():
		match t.move_target(i):
			"foe_totem", "all_foes":
				return "There's no enemy Totem to hit."
		return "No target."
	if check_target:
		if target == null:
			target = NONE
		if not ts.has(target):
			if target is String and target == LIFE:
				if opponent(pi).has_guardian():
					return "A Guardian protects their Life."
				return "Their Life is only open when the slot opposite is empty."
			return "Not a valid target."
	return ""


func summon_problem(pi: int, card: DuelCard, target = null) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_summon():
		return "That isn't a Summon."
	if summon_cost(pi, card) > p.essence:
		return "Needs %d Essence." % summon_cost(pi, card)
	var tk: String = card.def.move.get("target", "foe_totem")
	if tk == "foe_totem":
		var ts := targetable(opponent(pi).totems())
		if ts.is_empty():
			return "There's no enemy Totem to strike."
		if target != null and not ts.has(target):
			return "Not a valid target."
	return ""


func summon_needs_target(card: DuelCard) -> bool:
	return card.def.move.get("target", "foe_totem") == "foe_totem"


func gift_problem(pi: int, target = null) -> String:
	var p: DuelPlayer = players[pi]
	if p.gift_used:
		return "You've already used your Divine Gift this duel."
	if law == "ironvault":
		return "Ironvault's Ledger Law forbids Divine Gifts."
	var foe := opponent(pi)
	match p.gift():
		"dawns_mercy":
			var hurt := []
			for t in p.totems():
				if t.damage > 0 or t.has_condition():
					hurt.append(t)
			if hurt.is_empty():
				return "None of your Totems need healing."
			if target != null and not hurt.has(target):
				return "Choose a hurt Totem."
		"stillness":
			if foe.totems().is_empty():
				return "Your opponent has no Totems."
		"whisper":
			if foe.hand.is_empty() and foe.wards.is_empty():
				return "Your opponent has no cards in hand."
		"recall":
			if _recallable(p).is_empty():
				return "Your discard pile is empty."
		"contagion":
			if foe.totems().is_empty():
				return "Your opponent has no Totems."
		"undertow":
			if foe.totems().is_empty():
				return "Your opponent has no Totems."
		"regrowth":
			if not p.totems().any(func(t): return t.damage > 0 or not t.cond("body").is_empty()):
				return "None of your Totems need healing."
		"star_chart":
			if p.deck.is_empty():
				return "Your deck is empty."
		"forged_guard":
			if p.guard() <= 0:
				return "You have no Guard to double."
		"unveil":
			if foe.wards.is_empty():
				return "Your opponent has no Wards."
			if law == "nocthra" and blessed(foe.index):
				return "Nocthra's Blessing hides their Wards."
	return ""


func gift_targets(pi: int) -> Array:
	var p: DuelPlayer = players[pi]
	if p.gift() == "dawns_mercy":
		var out := []
		for t in p.totems():
			if t.damage > 0 or t.has_condition():
				out.append(t)
		return out
	return []


func _recallable(p: DuelPlayer) -> Array:
	var out := []
	for c in p.discard:
		if not c.is_summon():
			out.append(c)
	return out


## True if the current player has anything left to do besides ending the turn.
func can_do_anything_but_end(pi: int) -> bool:
	var p: DuelPlayer = players[pi]
	for c in p.hand:
		match c.kind():
			"totem":
				if c.is_basic_totem() and call_problem(pi, c) == "":
					return true
				if c.is_ascension() and ascend_problem(pi, c) == "":
					return true
			"rite":
				if rite_problem(pi, c) == "":
					return true
			"ward":
				if ward_problem(pi, c) == "":
					return true
			"summon":
				if summon_problem(pi, c) == "":
					return true
	for t in p.totems():
		for i in t.moves().size():
			if move_problem(pi, t, i) == "":
				return true
	return false


# ------------------------------------------------------------- calling ---

func _act_call(pi: int, card: DuelCard, slot: int) -> void:
	var p: DuelPlayer = players[pi]
	if slot < 0:
		slot = p.empty_slots()[0]
	var c := call_cost(pi, card)
	_spend(p, c)
	p.hand.erase(card)
	var t := DuelTotem.new(card, pi, slot, turn, p.attributes())
	if p.free_shift:
		t.hasted = true   # Ixara's Tempest
	if law == "verdanthe" and blessed(pi):
		t.bonus_hp += DuelLaws.spring_hp_bonus
	p.slots[slot] = t
	p.totems_called += 1
	p.stats.totems_called += 1
	p.note_played(card.id)
	_log("%s calls %s." % [p.player_name, card.card_name()], pi)
	await _fx("fx_call", [t])
	if t.has_keyword("channel"):
		p.essence += 1
		_log("%s channels 1 Essence." % t.card_name(), pi)
	var n := t.attuned_value("draw")
	if n > 0:
		var drawn := await _draw(p, n)
		if not drawn.is_empty():
			await _fx("fx_draw", [pi, drawn])
	await _spring_wards(1 - pi, "foe_call", {"called": t})
	await _resolve_knockouts()


func _act_ascend(pi: int, card: DuelCard, target: DuelTotem) -> void:
	var p: DuelPlayer = players[pi]
	if target == null:
		target = ascend_targets(pi, card)[0]
	_spend(p, ascend_cost(card, target))
	p.hand.erase(card)
	var from := target.card_name()
	target.stack.append(card)
	target.ascended_turn = turn
	target.clear_conditions()
	p.stats.ascensions += 1
	p.note_played(card.id)
	_log("%s ascends into %s!" % [from, card.card_name()], pi)
	await _fx("fx_ascend", [target])


func _act_ward(pi: int, card: DuelCard) -> void:
	var p: DuelPlayer = players[pi]
	_spend(p, card_cost(pi, card))
	p.hand.erase(card)
	p.wards.append(card)
	p.note_played(card.id)
	if law == "ysolde" and not blessed(pi):
		face_up[card.uid] = true
		_log("%s sets %s face up, as the Unveiling demands." % [p.player_name, card.card_name()], pi)
	else:
		_log("%s sets a Ward face down." % p.player_name, pi)
	await _fx("fx_ward_set", [pi, card])


func _act_shift(pi: int, t: DuelTotem, slot: int) -> void:
	var p: DuelPlayer = players[pi]
	_spend(p, shift_cost(pi))
	p.shifts += 1
	var other: DuelTotem = p.slots[slot]
	var from := t.slot
	p.slots[from] = other
	if other != null:
		other.slot = from
	p.slots[slot] = t
	t.slot = slot
	if other != null:
		_log("%s swaps %s and %s." % [p.player_name, t.card_name(), other.card_name()], pi)
	else:
		_log("%s shifts %s to another slot." % [p.player_name, t.card_name()], pi)
	await _fx("fx_shift", [pi])
	if t.has_status("confused"):
		t.remove_status("confused")
		_log("%s shakes off its confusion." % t.card_name(), pi)
	await _bleed(t)
	await _resolve_knockouts()


# ----------------------------------------------------------------- rites ---

func _act_rite(pi: int, card: DuelCard, target) -> void:
	var p: DuelPlayer = players[pi]
	_spend(p, card_cost(pi, card))
	p.hand.erase(card)
	p.stats.rites += 1
	p.note_played(card.id)
	var tname := ""
	if target is DuelTotem:
		tname = " on %s" % target.card_name()
	_log("%s casts %s%s." % [p.player_name, card.card_name(), tname], pi)
	await _fx("fx_rite", [pi, card, target])
	var res := await _spring_wards(1 - pi, "foe_rite", {"card": card})
	if res.cancel_rite:
		_log("%s is cancelled!" % card.card_name(), pi)
		p.discard.append(card)
		return
	var d := card.def
	var dmg := int(d.get("damage", 0))
	var dealt := 0
	var effects: Array = d.get("effects", [])
	if d.get("target", "none") == "all_foes":
		for f in opponent(pi).totems():
			if dmg > 0:
				dealt += await _damage_totem(f, _scaled(dmg, f, card.element()), {"spill": true, "element": card.element()})
			for e in effects:
				if e.op == "status":
					await _apply_status(f, e.status, null, pi)
		effects = effects.filter(func(e): return e.op != "status")
	elif target is DuelTotem and dmg > 0:
		dealt = await _damage_totem(target, _scaled(dmg, target, card.element()), {"spill": true, "element": card.element()})
	await _apply_effects(pi, null, target, effects, dealt, true)
	p.discard.append(card)
	await _resolve_knockouts()


# ---------------------------------------------------------------- attacks ---

## The damage a move would do to `defn` (null = Life), before shields and Guard.
func attack_amount(att: DuelTotem, i: int, base: int, defn, effects: Array = []) -> int:
	if base <= 0:
		return 0
	var amt := base + att.damage_bonus(i)
	if players[att.owner].wrath:
		amt += DuelRules.wrath_bonus
	if att.has_status("terrified"):
		amt = _half(amt)
	if att.has_status("staggered"):
		amt = _half(amt)
	if defn is DuelTotem:
		for e in effects:
			if e.op == "bonus_if_status" and defn.conditions().has(e.status):
				amt += int(e.amount)
		amt = _scaled(amt, defn, att.element())
	return amt


## Applies the weakness multiplier (rounded to the nearest 10), then the
## defender's conditions: Corroded, Marked and Soaked add to the hit and
## Petrified halves it.
func _scaled(amount: int, defn: DuelTotem, element: String) -> int:
	if amount <= 0 or defn == null:
		return amount
	if defn.weak_to(element):
		amount = int(round(amount * DuelRules.weakness_mult / 10.0)) * 10
	if defn.has_status("corroded"):
		amount += DuelRules.corroded_bonus
	if defn.has_status("marked"):
		amount += DuelRules.marked_bonus
	if defn.has_status("enraged"):
		amount += DuelRules.enraged_exposed
	if defn.has_status("soaked") and (element == "storm" or element == "frost"):
		amount += DuelRules.soaked_bonus
	if defn.has_status("petrified"):
		amount = _half(amount)
	return amount


## Half, rounded up to the next 10.
static func _half(amount: int) -> int:
	return int(ceil(amount / 20.0)) * 10


func _act_attack(pi: int, t: DuelTotem, i: int, target) -> void:
	var p: DuelPlayer = players[pi]
	var foe := opponent(pi)
	var mv := t.move(i)
	_spend(p, t.move_cost(i))
	t.attacked = true
	if t.boons.has("veiled"):
		t.remove_boon("veiled")
	if target == null:
		target = NONE
	# Confused: it may lash out at its own side instead
	if t.has_status("confused"):
		var cr := rng.randi_range(1, 20)
		if cr <= DuelRules.confuse_fail:
			_log("%s is confused (rolled %d) and strikes its own side!" % [t.card_name(), cr], pi)
			await _fx("fx_roll", [pi, {"label": "%s is confused" % t.card_name(), "roll": cr, "mod": 0, "total": cr,
				"index": 0, "bands": [], "text": "hits its own side"}])
			await _strike_own_side(t, -1)
			await _after_attack(t)
			return
	for fail_id in ["shocked", "blinded"]:
		if t.has_status(fail_id):
			var limit := DuelRules.shock_fail if fail_id == "shocked" else DuelRules.blind_fail
			var fr := rng.randi_range(1, 20)
			if fr <= limit:
				_log("%s is %s (rolled %d): the attack %s." % [t.card_name(), DuelConditions.display_name(fail_id).to_lower(), fr,
					"fails" if fail_id == "shocked" else "misses"], pi)
				await _fx("fx_roll", [pi, {"label": "%s is %s" % [t.card_name(), DuelConditions.display_name(fail_id)],
					"roll": fr, "mod": 0, "total": fr, "index": 0, "bands": [], "text": "fails" if fail_id == "shocked" else "misses"}])
				await _after_attack(t)
				return
	var what := ""
	if target is DuelTotem:
		what = " on %s" % target.card_name()
	elif target is String and target == LIFE:
		what = " straight at %s Life" % whose(foe.player_name, true)
	_log("%s uses %s%s." % [t.card_name(), mv.name, what], pi)
	await _fx("fx_attack", [t, i, target])

	# the defender's Wards
	var tk := t.move_target(i)
	var hostile := tk == "foe" or tk == "foe_totem" or tk == "all_foes"
	var res := {"fired": false, "negated": false, "blocked_life": false, "cancel_rite": false, "reduce_life": 0}
	if hostile:
		var ctx := {"attacker": t, "target": target, "move": mv}
		if target is String and target == LIFE:
			res = await _spring_wards(1 - pi, "foe_direct", ctx)
		if not res.fired:
			res = await _spring_wards(1 - pi, "foe_attack", ctx)
	if over:
		return
	if res.negated or t.is_knocked_out():
		if res.negated:
			_log("The attack is cancelled.", pi)
		await _after_attack(t)
		return

	var base := int(mv.get("damage", 0))
	var effects: Array = mv.get("effects", [])
	if mv.has("fate"):
		var band := await _fate_roll(pi, t.affinity(), mv.fate, "%s: %s" % [t.card_name(), mv.name])
		base = int(band.get("damage", 0))
		effects = band.get("effects", [])
		if base == 0 and band.get("text", "") == "Miss":
			_log("%s misses!" % t.card_name(), pi)
	var pierce := effects.any(func(e): return e.op == "pierce")
	var dealt := 0

	if target is String and target == LIFE:
		var amt := attack_amount(t, i, base, null) - int(res.reduce_life)
		if amt > 0:
			if res.blocked_life:
				_log("The Ward blocks the hit on %s Life." % whose(foe.player_name, true), pi)
			else:
				dealt = await _hit_life(1 - pi, amt, {"attacker": t, "pierce": pierce})
	elif tk == "all_foes":
		for f in foe.totems():
			var amt := attack_amount(t, i, base, f, effects)
			if amt > 0:
				dealt += await _damage_totem(f, amt, {"attacker": t, "spill": true, "pierce": pierce, "element": t.element()})
			for e in effects:
				if e.op == "status":
					await _apply_status(f, e.status, t)
		effects = effects.filter(func(e): return e.op != "status")
	elif target is DuelTotem and target.owner != pi:
		var amt := attack_amount(t, i, base, target, effects)
		if amt > 0:
			dealt = await _damage_totem(target, amt, {"attacker": t, "spill": true, "pierce": pierce, "element": t.element()})
			if target.has_keyword("thorns") and not t.is_knocked_out():
				_log("%s is pricked by thorns." % t.card_name(), pi)
				await _damage_totem(t, DuelRules.thorns_damage, {"source": "thorns", "attacker": target})
	if over:
		return
	await _apply_effects(pi, t, target, effects, dealt)
	await _after_attack(t)


## What every attack leaves behind: Staggered and Empowered are used up, and
## a Bleeding Totem bleeds.
func _after_attack(t: DuelTotem) -> void:
	if t.has_status("staggered"):
		t.remove_status("staggered")
	if t.boons.has("empowered"):
		t.remove_boon("empowered")
	await _bleed(t)
	await _resolve_knockouts()


func _bleed(t: DuelTotem) -> void:
	if t != null and not t.is_knocked_out() and t.has_status("bleed"):
		_log("%s bleeds." % t.card_name(), t.owner)
		await _damage_totem(t, DuelRules.bleed_damage, {"source": "bleed"})


## A Totem turned against its own side makes its free Strike at one of its
## owner's other Totems, or its owner's Life if it stands alone. `chooser`
## picks the target (-1: chosen at random, as when Confused).
func _strike_own_side(t: DuelTotem, chooser: int) -> void:
	var owner: DuelPlayer = players[t.owner]
	var mv := t.move(0)
	var base := int(mv.get("damage", 0))
	var tk: String = mv.get("target", "foe")
	if base <= 0 or not (tk == "foe" or tk == "foe_totem" or tk == "all_foes"):
		_log("%s stands dazed." % t.card_name(), t.owner)
		return
	var others: Array = owner.totems().filter(func(x): return x != t and not x.is_knocked_out())
	var target = LIFE
	if not others.is_empty():
		if chooser < 0:
			target = others[rng.randi_range(0, others.size() - 1)]
		else:
			var picked: Array = await players[chooser].controller.choose_totems(self, chooser,
				"Choose which of their Totems the possessed %s strikes." % t.card_name(), others, 1, 1)
			target = picked[0] if not picked.is_empty() and others.has(picked[0]) else others[0]
	await _fx("fx_attack", [t, 0, target])
	if target is DuelTotem:
		var amt := attack_amount(t, 0, base, target, mv.get("effects", []))
		await _damage_totem(target, amt, {"attacker": t, "spill": false, "element": t.element()})
		for e in mv.get("effects", []):
			if e.op == "status":
				await _apply_status(target, e.status, t)
	else:
		await _hit_life(t.owner, attack_amount(t, 0, base, null), {"attacker": t})
	await _resolve_knockouts()


## At the start of their owner's turn, Possessed Totems strike where their
## possessor tells them to.
func _possessed_strikes(p: DuelPlayer) -> void:
	for t in p.totems():
		if over:
			return
		if t.is_knocked_out() or not t.has_status("possessed"):
			continue
		var c: Dictionary = t.condition_of("possessed")
		var who := int(c.get("src_owner", 1 - p.index))
		if who < 0 or who == p.index:
			who = 1 - p.index
		_log("The possessed %s turns on its own side!" % t.card_name(), p.index)
		await _strike_own_side(t, who)
		await _bleed(t)
		await _resolve_knockouts()


func _act_summon(pi: int, card: DuelCard, target) -> void:
	var p: DuelPlayer = players[pi]
	_spend(p, summon_cost(pi, card))
	p.hand.erase(card)
	p.stats.summons += 1
	p.note_played(card.id)
	var mv: Dictionary = card.def.move
	_log("%s calls down %s!" % [p.player_name, card.card_name()], pi)
	var res := await _spring_wards(1 - pi, "foe_rite", {"card": card})
	if res.cancel_rite:
		_log("%s is sealed away before it can strike!" % card.card_name(), pi)
		p.spent.append(card)
		return
	await _fx("fx_summon", [pi, card])
	var base := int(mv.get("damage", 0))
	var effects: Array = mv.get("effects", [])
	var pierce := effects.any(func(e): return e.op == "pierce")
	var dealt := 0
	if mv.get("target", "foe_totem") == "all_foes":
		for f in opponent(pi).totems():
			if base > 0:
				dealt += await _damage_totem(f, _scaled(base, f, card.element()), {"spill": true, "pierce": pierce, "element": card.element()})
			for e in effects:
				if e.op == "status":
					await _apply_status(f, e.status, null, pi)
		effects = effects.filter(func(e): return e.op != "status")
	elif target is DuelTotem:
		if base > 0:
			dealt = await _damage_totem(target, _scaled(base, target, card.element()), {"spill": true, "pierce": pierce, "element": card.element()})
		if effects.any(func(e): return e.op == "stun_others"):
			for f in opponent(pi).totems():
				if f != target:
					await _apply_status(f, "stun", null, pi)
	await _apply_effects(pi, null, target, effects, dealt)
	p.spent.append(card)
	_log("%s returns to the heavens." % card.card_name(), pi)
	await _resolve_knockouts()


# ------------------------------------------------------------------ gifts ---

func _act_gift(pi: int, target) -> void:
	var p: DuelPlayer = players[pi]
	var foe := opponent(pi)
	var g := p.gift()
	p.gift_used = true
	_log("%s calls on %s!" % [p.player_name, Lore.GIFTS[g].name], pi)
	await _fx("fx_gift", [pi, g])
	match g:
		"dawns_mercy":
			if target == null:
				target = gift_targets(pi)[0]
			await _heal(target, DuelRules.mercy_heal)
			target.clear_conditions()
			await _fx("fx_status", [target, ""])
		"wrath":
			p.wrath = true
		"stillness":
			var chosen: Array = await p.controller.choose_totems(self, pi, "Choose up to two enemy Totems to Stun.",
				foe.totems(), 1, 2)
			for t in chosen.slice(0, 2):
				await _apply_status(t, "stun", null, pi)
		"tempest":
			p.essence += DuelRules.tempest_essence
			p.free_shift = true
		"whisper":
			if not foe.wards.is_empty() and not (law == "nocthra" and blessed(foe.index)):
				var names := []
				for w in foe.wards:
					names.append(w.card_name())
				_log("Their Wards are revealed: %s." % ", ".join(names), pi)
			if not foe.hand.is_empty():
				var n := mini(2, foe.hand.size())
				var chosen: Array = await p.controller.choose_cards(self, pi, "Choose %d card%s to discard from their hand." % [n, "" if n == 1 else "s"],
					foe.hand.duplicate(), n, n, {"reason": "whisper", "wards": foe.wards.duplicate()})
				for c in chosen:
					if foe.hand.has(c):
						foe.hand.erase(c)
						foe.discard.append(c)
						_log("%s discards %s." % [foe.player_name, c.card_name()], pi)
		"foresight":
			var drawn := await _draw(p, 2)
			if not drawn.is_empty():
				await _fx("fx_draw", [pi, drawn])
			p.foresight = true
		"recall":
			var chosen: Array = await p.controller.choose_cards(self, pi, "Return up to two cards to your hand.",
				_recallable(p), 0, 2, {"reason": "recall"})
			for c in chosen.slice(0, 2):
				if p.discard.has(c):
					p.discard.erase(c)
					p.hand.append(c)
					_log("%s returns %s to their hand." % [p.player_name, c.card_name()], pi)
		"unbound":
			var drawn := await _draw(p, 2)
			if not drawn.is_empty():
				await _fx("fx_draw", [pi, drawn])
		"contagion":
			for t in foe.totems():
				await _damage_totem(t, 10, {"spill": true, "element": "venom"})
				await _apply_status(t, "poison", null, pi)
		"regrowth":
			for t in p.totems():
				await _heal(t, 40)
				t.clear_conditions("body")
		"undertow":
			for t in foe.totems():
				await _undertow(t)
		"star_chart":
			var top: Array = p.deck.slice(maxi(0, p.deck.size() - 5))
			top.reverse()
			var chosen: Array = await p.controller.choose_cards(self, pi, "Choose two cards to draw.", top, mini(2, top.size()), mini(2, top.size()),
				{"reason": "star_chart"})
			for c in chosen.slice(0, 2):
				if p.deck.has(c):
					p.deck.erase(c)
					p.hand.append(c)
					_log("%s draws %s from the stars." % [p.player_name, c.card_name()], pi)
			p.fate_bonus = 2
			_log("The stars align: +2 on %s Fate rolls this turn." % whose(p.player_name, true), pi)
		"forged_guard":
			p.guard_double = true
			for t in p.totems():
				t.shield += 30
			_log("%s Guard is doubled to %d until their next Dawn." % [whose(p.player_name), p.guard()], pi)
		"unveil":
			var names := []
			for w in foe.wards:
				face_up[w.uid] = true
				names.append(w.card_name())
			_log("Every Ward is unveiled: %s." % ", ".join(names), pi)
			var chosen: Array = await p.controller.choose_cards(self, pi, "Choose a Ward to burn away.", foe.wards.duplicate(), 1, 1,
				{"reason": "unveil"})
			for w in chosen.slice(0, 1):
				if foe.wards.has(w):
					foe.wards.erase(w)
					foe.discard.append(w)
					_log("%s burns away." % w.card_name(), pi)
	await _resolve_knockouts()


## Maerith's Undertow: the Basic goes back to its owner's hand and any
## Ascension cards on it are discarded.
func _undertow(t: DuelTotem) -> void:
	var owner: DuelPlayer = players[t.owner]
	if not owner.totems().has(t):
		return
	owner.slots[t.slot] = null
	owner.hand.append(t.stack[0])
	for c in t.stack.slice(1):
		owner.discard.append(c)
	_log("%s is dragged back to %s hand." % [t.stack[0].card_name(), whose(owner.player_name, true)], t.owner)
	await _fx("fx_ko", [t])


# ================================================================ effects ===

func _apply_effects(pi: int, source: DuelTotem, target, effects: Array, dealt: int, from_rite := false) -> void:
	var p: DuelPlayer = players[pi]
	var foe := opponent(pi)
	var heal_bonus := DuelLaws.spring_heal_bonus if from_rite and law == "verdanthe" else 0
	for e in effects:
		if over:
			return
		match e.op:
			"status":
				if target is DuelTotem:
					await _apply_status(target, e.status, source, pi)
			"boon":
				var who: Array = []
				match e.get("who", "target"):
					"self":
						who = [source] if source != null else []
					"allies":
						who = p.totems()
					_:
						who = [target] if target is DuelTotem else []
				for w in who:
					await _give_boon(w, e.boon)
			"heal":
				match e.get("who", "self"):
					"self":
						if source != null:
							await _heal(source, int(e.amount))
					"target":
						if target is DuelTotem:
							await _heal(target, int(e.amount) + heal_bonus)
					"allies":
						for t in p.totems():
							await _heal(t, int(e.amount) + heal_bonus)
			"cure":
				if target is DuelTotem:
					target.clear_conditions(e.get("kind", "all"))
					await _fx("fx_status", [target, ""])
			"splash_random":
				var others := []
				for f in foe.totems():
					if f != target and not f.is_knocked_out():
						others.append(f)
				if not others.is_empty():
					var f: DuelTotem = others[rng.randi_range(0, others.size() - 1)]
					await _damage_totem(f, int(e.amount), {"attacker": source, "spill": true})
			"self_damage":
				if source != null:
					await _damage_totem(source, int(e.amount), {"source": "recoil"})
			"shield":
				var who = source if e.get("who", "self") == "self" else target
				if who is DuelTotem:
					who.shield += int(e.amount)
					_log("%s is shielded (%d)." % [who.card_name(), who.shield], who.owner)
			"discard_random":
				for n in int(e.get("count", 1)):
					if foe.hand.is_empty():
						break
					var c: DuelCard = foe.hand[rng.randi_range(0, foe.hand.size() - 1)]
					foe.hand.erase(c)
					foe.discard.append(c)
					_log("%s discards %s." % [foe.player_name, c.card_name()], foe.index)
			"draw":
				var drawn := await _draw(p, int(e.count))
				if not drawn.is_empty():
					await _fx("fx_draw", [pi, drawn])
			"essence":
				p.essence += int(e.amount)
				_log("%s gains %d Essence." % [p.player_name, e.amount], pi)
			"essence_max":
				p.essence_max = mini(DuelRules.essence_cap + 2, p.essence_max + int(e.amount))
				p.essence += int(e.amount)
				_log("%s Essence limit rises to %d." % [whose(p.player_name), p.essence_max], pi)
			"life":
				await _gain_life(pi, int(e.amount))
			"drain":
				if dealt > 0:
					await _gain_life(pi, dealt)
			"buff":
				if target is DuelTotem:
					target.buff += int(e.amount)
					_log("%s deals %d more damage this turn." % [target.card_name(), e.amount], pi)
			"search_totem":
				var options := []
				var seen := {}
				for c in p.deck:
					if c.is_basic_totem() and not seen.has(c.id):
						seen[c.id] = true
						options.append(c)
				if not options.is_empty():
					var chosen: Array = await p.controller.choose_cards(self, pi, "Choose a Totem to put in your hand.",
						options, 1, 1, {"reason": "search"})
					for c in chosen:
						if p.deck.has(c):
							p.deck.erase(c)
							p.hand.append(c)
							_log("%s finds %s." % [p.player_name, c.card_name()], pi)
					_shuffle(p.deck)
			"move_foe":
				if target is DuelTotem and not foe.empty_slots().is_empty():
					var slot: int = await p.controller.choose_slot(self, pi, "Choose where to move %s." % target.card_name(),
						foe.empty_slots(), {"reason": "move_foe", "totem": target})
					if not foe.empty_slots().has(slot):
						slot = foe.empty_slots()[0]
					foe.slots[target.slot] = null
					foe.slots[slot] = target
					target.slot = slot
					_log("%s is lured to another slot." % target.card_name(), pi)
					await _fx("fx_shift", [foe.index])
			"bounce":
				if target is DuelTotem:
					await _bounce(target)


## Puts a condition on a Totem. `source` is the Totem that caused it (for
## Charmed and Terrified) and `src_owner` the duellist behind it.
func _apply_status(t: DuelTotem, status: String, source = null, src_owner: int = -1) -> void:
	if t == null or t.is_knocked_out() or not DuelConditions.is_condition(status):
		return
	if t.boons.has("blessed"):
		_log("%s is Blessed and shrugs off being %s." % [t.card_name(), DuelConditions.display_name(status)], t.owner)
		return
	if t.is_boss and status in DuelConditions.BOSS_IMMUNE:
		_log("%s can't be %s." % [t.card_name(), DuelConditions.display_name(status)], t.owner)
		return
	if status == "burn" and t.has_status("soaked"):
		_log("%s is too wet to burn." % t.card_name(), t.owner)
		return
	if status == "poison" and law == "vexa" and blessed(t.owner):
		_log("Vexa's Blessing keeps %s from the plague." % t.card_name(), t.owner)
		return
	var src_uid := -1
	if source is DuelTotem:
		src_uid = source.uid
		if src_owner < 0:
			src_owner = source.owner
	t.set_status(status, turn, src_uid, src_owner)
	_log("%s is %s." % [t.card_name(), DuelConditions.display_name(status)], t.owner)
	await _fx("fx_status", [t, status])


func _give_boon(t: DuelTotem, boon: String) -> void:
	if t == null or t.is_knocked_out() or not DuelConditions.is_boon(boon):
		return
	t.add_boon(boon, turn)
	_log("%s is %s." % [t.card_name(), DuelConditions.display_name(boon)], t.owner)
	await _fx("fx_status", [t, boon])


func _bounce(t: DuelTotem) -> void:
	var owner: DuelPlayer = players[t.owner]
	if not owner.totems().has(t):
		return
	owner.slots[t.slot] = null
	for c in t.stack:
		owner.hand.append(c)
	_log("%s is swept back to %s hand." % [t.card_name(), whose(owner.player_name, true)], t.owner)
	await _fx("fx_ko", [t])


## Deals damage to a Totem. info: attacker (DuelTotem), spill (bool: overflow
## goes into its owner's Life), pierce (spill-over ignores Guard), source.
## Returns the damage actually taken.
func _damage_totem(t: DuelTotem, amount: int, info: Dictionary = {}) -> int:
	if t == null or amount <= 0 or t.is_knocked_out():
		return 0
	var absorbed := mini(t.shield, amount)
	if absorbed > 0:
		t.shield -= absorbed
		amount -= absorbed
		_log("%s's shield absorbs %d." % [t.card_name(), absorbed], t.owner)
	var before := t.hp_left()
	if amount > 0:
		t.damage += amount
		var att = info.get("attacker")
		if att != null:
			t.last_hit_by = att
		var src: String = info.get("source", "")
		if t.asleep and not src in ["burn", "poison", "bleed", "curse", "doom"]:
			t.remove_status("sleep")
			_log("%s wakes up." % t.card_name(), t.owner)
		if t.has_status("frozen") and info.get("element", "") == "fire":
			t.remove_status("frozen")
			_log("The fire thaws %s." % t.card_name(), t.owner)
		_log("%s takes %d damage." % [t.card_name(), amount], t.owner)
	await _fx("fx_totem_hit", [t, amount, info.merged({"absorbed": absorbed})])
	var overflow := amount - before
	if overflow > 0 and info.get("spill", false):
		_log("%d spills over." % overflow, t.owner)
		await _hit_life(t.owner, overflow, {"spill": true, "pierce": info.get("pierce", false),
			"attacker": info.get("attacker")})
	return mini(amount, before)


## A hit on a duellist's Life, reduced by their Guard. Returns the Life lost.
func _hit_life(pi: int, amount: int, info: Dictionary = {}) -> int:
	var p: DuelPlayer = players[pi]
	if amount <= 0 or over:
		return 0
	var amt := amount
	if not info.get("pierce", false) and not info.get("no_guard", false):
		amt = amount - p.guard()
		if amt < DuelRules.guard_min_hit:
			amt = mini(amount, DuelRules.guard_min_hit)
	p.life -= amt
	if info.get("attacker") != null or info.get("spill", false):
		players[1 - pi].stats.life_damage_dealt += amt
	_log("%s loses %d Life (%d left)." % [p.player_name, amt, maxi(0, p.life)], pi)
	await _fx("fx_life_hit", [pi, amt, info])
	await _check_life(pi)
	return amt


func _check_life(pi: int) -> void:
	var p: DuelPlayer = players[pi]
	if p.life > 0 or over:
		return
	await _spring_wards(pi, "lethal", {})
	if p.life <= 0:
		_finish(1 - pi, "%s Life ran out. %s!" % [whose(p.player_name), "You win" if players[1 - pi].player_name == "You" else players[1 - pi].player_name + " wins"])


func _heal(t: DuelTotem, amount: int) -> void:
	if t == null or t.is_knocked_out():
		return
	if t.has_status("cursed"):
		_log("The curse turns %s's healing into harm!" % t.card_name(), t.owner)
		await _damage_totem(t, amount, {"source": "curse"})
		return
	var h := mini(amount, t.damage)
	if h <= 0:
		return
	t.damage -= h
	_log("%s heals %d." % [t.card_name(), h], t.owner)
	await _fx("fx_heal", [t, h])


func _gain_life(pi: int, amount: int) -> void:
	var p: DuelPlayer = players[pi]
	var g := mini(amount, p.max_life - p.life)
	if g <= 0:
		return
	p.life += g
	_log("%s gains %d Life." % [p.player_name, g], pi)
	await _fx("fx_life_gain", [pi, g])


func _resolve_knockouts() -> void:
	for guard_loop in 12:
		var found := false
		for pi in [current, 1 - current]:
			var p: DuelPlayer = players[pi]
			for t in p.totems():
				if not t.is_knocked_out():
					continue
				found = true
				p.slots[t.slot] = null
				p.fallen.append(t.stage())
				for c in t.stack:
					p.discard.append(c)
				_log("%s is knocked out!" % t.card_name(), pi)
				var killer = t.last_hit_by
				if killer != null and killer.owner != pi:
					players[killer.owner].stats.kos += 1
				await _fx("fx_ko", [t])
				if killer != null and killer.owner != pi and killer.has_keyword("harvest") \
						and killer.owner == current and not killer.is_knocked_out():
					players[killer.owner].essence += 1
					_log("%s harvests 1 Essence." % killer.card_name(), killer.owner)
				var alive_killer = killer if killer != null and killer.owner != pi and not killer.is_knocked_out() \
					and players[killer.owner].totems().has(killer) else null
				await _spring_wards(pi, "ally_ko", {"attacker": alive_killer, "fallen": t})
				if over:
					return
		if not found:
			return


# ================================================================== wards ===

## Springs the first matching Ward of `owner_pi` (only on their opponent's turn).
func _spring_wards(owner_pi: int, trigger: String, ctx: Dictionary) -> Dictionary:
	var res := {"fired": false, "negated": false, "blocked_life": false, "cancel_rite": false, "reduce_life": 0}
	if owner_pi == current:
		return res
	if over and trigger != "lethal":
		return res
	var p: DuelPlayer = players[owner_pi]
	for w in p.wards.duplicate():
		if w.def.trigger != trigger or not _ward_applies(w, ctx):
			continue
		p.wards.erase(w)
		p.discard.append(w)
		res.fired = true
		p.stats.wards_sprung += 1
		_log("%s Ward springs: %s!" % [whose(p.player_name), w.card_name()], owner_pi)
		await _fx("fx_ward_spring", [owner_pi, w, ctx])
		for e in w.def.effects:
			match e.op:
				"negate":
					res.negated = true
				"damage_attacker":
					await _damage_totem(ctx.get("attacker"), int(e.amount), {"source": "ward"})
				"status_attacker":
					await _apply_status(ctx.get("attacker"), e.status, null, owner_pi)
				"status_called":
					await _apply_status(ctx.get("called"), e.status, null, owner_pi)
				"damage_called":
					await _damage_totem(ctx.get("called"), int(e.amount), {"source": "ward"})
				"bounce_called":
					await _bounce(ctx.get("called"))
				"block_life":
					res.blocked_life = true
				"shield_target":
					var tg = ctx.get("target")
					if tg is DuelTotem:
						tg.shield += int(e.amount)
						_log("%s is shielded (%d)." % [tg.card_name(), tg.shield], tg.owner)
					elif tg is String and tg == LIFE:
						res.reduce_life = int(e.amount)
				"cancel_rite":
					res.cancel_rite = true
				"survive":
					p.life = int(e.life)
					_log("%s refuses to fall!" % p.player_name, owner_pi)
					await _fx("fx_life_gain", [owner_pi, 0])
		break
	return res


func _ward_applies(w: DuelCard, ctx: Dictionary) -> bool:
	for e in w.def.effects:
		match e.op:
			"damage_attacker", "status_attacker":
				var a = ctx.get("attacker")
				if a == null or not (a is DuelTotem) or a.is_knocked_out():
					return false
			"damage_called", "bounce_called", "status_called":
				var c = ctx.get("called")
				if c == null or not (c is DuelTotem) or c.is_knocked_out():
					return false
	return true


# =================================================================== dice ===

## Rolls a d20 for a Fate move and returns the band it lands in.
func _fate_roll(pi: int, affinity: String, bands: Array, label: String) -> Dictionary:
	var p: DuelPlayer = players[pi]
	var mod := fate_mod(pi, affinity)
	var forced := false
	var roll := 0
	if p.foresight:
		roll = 20
		forced = true
		p.foresight = false
	else:
		roll = rng.randi_range(1, 20)
		if roll == 19 and law == "aster" and blessed(pi):
			roll = 20
	var info := band_for(bands, roll, mod)
	info["label"] = label
	info["bands"] = bands
	info["forced"] = forced
	p.stats.fate_rolls += 1
	await _fx("fx_roll", [pi, info])
	if p.fortune_left > 0 and not forced and int(info.index) < bands.size() - 1:
		var again: bool = await p.controller.choose_reroll(self, pi, info)
		if again:
			p.fortune_left -= 1
			roll = rng.randi_range(1, 20)
			info = band_for(bands, roll, mod)
			info["label"] = label + " (Fortune re-roll)"
			info["bands"] = bands
			info["rerolled"] = true
			await _fx("fx_roll", [pi, info])
	var band: Dictionary = bands[info.index]
	_log("Fate: rolled %d%s = %d. %s" % [info.roll, (" +%d" % mod) if mod > 0 else "", info.total,
		DuelCards.outcome_text(int(band.get("damage", 0)), band.get("effects", []), "foe", band.get("text", ""))], pi)
	return band


## "Wren's", or "Your" for a duellist called You ("your" mid-sentence).
static func whose(player_name: String, mid_sentence := false) -> String:
	if player_name == "You":
		return "your" if mid_sentence else "Your"
	return "%s's" % player_name


## A duellist's Fate modifier for a card with this affinity.
func fate_mod(pi: int, affinity: String) -> int:
	var p: DuelPlayer = players[pi]
	var m := DuelRules.fate_mod(p.attribute(affinity)) if affinity != "" else 0
	if DuelRules.has_perk(p.attributes(), "insight"):
		m += 1
	if law == "aster":
		m += 1
	return m + p.fate_bonus


## Which band a roll lands in. A natural 1 is always the lowest band and a
## natural 20 always the highest.
static func band_for(bands: Array, roll: int, mod: int) -> Dictionary:
	var total := roll + mod
	var idx := bands.size() - 1
	if roll == 1:
		idx = 0
	elif roll < 20:
		for i in bands.size():
			if total <= int(bands[i].to):
				idx = i
				break
	return {"roll": roll, "mod": mod, "total": total, "index": idx}


## The chance (0-1) of each band, for the AI and for the card's hint text.
static func band_odds(bands: Array, mod: int) -> Array:
	var odds := []
	for b in bands:
		odds.append(0.0)
	for r in range(1, 21):
		var i: int = band_for(bands, r, mod).index
		odds[i] += 0.05
	return odds


# ================================================================ helpers ===

func _spend(p: DuelPlayer, n: int) -> void:
	p.essence -= n
	p.stats.essence_spent += n


func _draw_raw(p: DuelPlayer, n: int) -> Array:
	var out := []
	for i in n:
		if p.deck.is_empty():
			break
		var c: DuelCard = p.deck.pop_back()
		p.hand.append(c)
		out.append(c)
	return out


## Draws n cards; drawing from an empty deck costs Life instead.
func _draw(p: DuelPlayer, n: int) -> Array:
	var out := []
	for i in n:
		if p.deck.is_empty():
			_log("%s deck is empty!" % whose(p.player_name), p.index)
			await _hit_life(p.index, DuelRules.fatigue, {"no_guard": true, "source": "fatigue"})
			if over:
				break
			continue
		var c: DuelCard = p.deck.pop_back()
		p.hand.append(c)
		out.append(c)
	return out


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _fx(method: String, args: Array) -> Variant:
	if presenter != null and presenter.has_method(method):
		return await Callable(presenter, method).callv(args)
	return null


func _log(text: String, who: int = -1) -> void:
	log_lines.append(text)
	logged.emit(text, who)


func _changed() -> void:
	state_changed.emit()


## The total number of cards each duellist owns (for the tests).
func card_totals() -> Array:
	return [players[0].total_card_count(), players[1].total_card_count()]
