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
##   choose_response(game, pi, event, cards) -> DuelCard or null   (an answer on the rival's turn; optional)
##
## The turn: with DuelRules.phases off (the game's setting since 27 October;
## Gary: "let's go back to how we used to have it") the start-of-turn work
## runs (conditions, the Law, the draw, Essence), then the whole turn is one
## free Main, `phase` "main" throughout: calls, Ascension, Wards, Summons,
## Stances, Rites, Shifts and attacks in any order, "end" ends it, and the
## end-of-turn work follows. With phases on (Phase A of the deeper duel, 23
## October; the Duel Lab's "Turn phases" row) it runs Dawn (conditions, the
## Law) → Draw → Main (calls, Ascension, Wards, Summons, Stances, Rites,
## Shifts) → Clash (attacks) → a second Main (a Rite or a Shift) → Dusk;
## `phase` names the one it's in, a {type: "next"} action moves it on (a
## phase with nothing to do in it is skipped), and phase_problem(kind) says
## why an action can't be done now (never, with phases off). Either way an
## action is declared, may be answered (the response window, `_window`:
## Counter Rites and Wards from the hand, in chains), then resolves.
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
##   fx_game_over(winner, reason), fx_phase(pi, phase), fx_stance(totem),
##   fx_answer(pi, card, event, depth), fx_chain_done(chain),
##   fx_tribute(totem, card), fx_echo(pi, card), fx_search(pi, cards), fx_revive(pi, card),
##   fx_relic(totem, card), fx_reveal(totem), fx_bond(totem, partner),
##   fx_terrain(arena, why), fx_arena_rule(pi, rule, text), fx_continuous(pi, card, gone),
##   fx_favour(pi, full), fx_oath(pi, oath, state)

signal logged(text: String, who: int)
signal state_changed

const LIFE := "life"      # the attack target that means "their Life"
const NONE := "none"      # a move that needs no target
## The turn's phases, in order (Phase A; only with DuelRules.phases on).
const PHASES := ["dawn", "draw", "main", "clash", "main2", "dusk"]
const PHASE_NAMES := {"setup": "", "dawn": "Dawn", "draw": "Draw", "main": "Main", "clash": "Clash", "main2": "Main II", "dusk": "Dusk", "over": ""}
const STANCES := ["strike", "guard", "rest"]
const STANCE_NAMES := {"strike": "Strike", "guard": "Guard", "rest": "Rest"}
## The event a Ward's trigger answers to, for a Ward played from the hand.
const WARD_EVENTS := {"foe_attack": "attack", "foe_direct": "attack", "foe_call": "call", "foe_rite": "rite"}
## What an answer's event is called on a card and in a lesson.
const EVENT_TEXT := {"attack": "an enemy Totem attacks", "rite": "your opponent casts a Rite or calls down a Summon",
	"call": "your opponent calls a Totem", "ward": "your opponent sets a Ward", "ward_spring": "an enemy Ward springs"}

var players: Array = []
var current := 0
var first_player := 0
var turn := 0
var rng := RandomNumberGenerator.new()
var winner := -1          # -1 = still playing, 0/1 = that player, 2 = draw
var win_reason := ""
var over := false
var phase := "setup"      # setup, then PHASES as the turn moves (or "main" all turn with phases off), over
var _phase_free := false  # a story rule acting at Dawn (Wren's theft, Dawnmane) isn't held to the phase
var presenter = null
var log_lines: Array = []

var _next_uid := 1
## Above 0, both duellists start on this Life instead of their attribute total (story tutorials).
var start_life := 0
## Per-duellist starting Life, [player 0, player 1] (overrides start_life; story tutorials).
var start_lives: Array = []
## Tutorials: decks dealt in the order written instead of shuffled ([bool, bool]),
## who goes first (-1 = roll for it), Fate rolls queued per duellist, and a floor
## under a duellist's Life and Totems so the lesson can't be lost.
var stacked: Array = [false, false]
var first_forced := -1
var forced_rolls: Array = [[], []]
var life_floor: Array = [0, 0]
var totem_floor: Array = [0, 0]
## The Dominion Law this duel is fought under (a god's id, "ironvault" or ""). See DuelLaws.
var law := ""
## The Circle's ground (Phase D): the arena the duel is fought in (set by the
## screen from the spec, "" for none), and a Terrain Rite's while it holds.
var arena := ""
var terrain := {}            # {arena, left (turns), by (who cast it)}
## Whether the computer may swear Oaths (not in a story duel; Phase D).
var ai_oaths := true
## Each arena's standing rule, and what the screen says about it.
const ARENA_RULES := {
	"ashford": "The beginner's Circle: no rule.",
	"tidegrove": "At each Dawn, a Totem on the field is Soaked.",
	"emberforge": "A Ward that springs Burns the Totem it catches.",
	"ironstone": "Both duellists' Guard is 5 higher.",
	"veilwild": "Each duellist's first Totem is called veiled, at no extra cost.",
	"solhaven": "At your Dawn, if you have fewer Totems than your rival, gain 1 Essence.",
}
## The Oaths a duellist can swear (Phase D): at the start of a duel, and once
## more mid-duel. Kept, the win's Resonance is greater; broken, it costs Life.
const OATHS := {
	"swift": {"name": "Oath of the Swift End"},
	"faith": {"name": "Oath of the Faithful"},
	"unbowed": {"name": "Oath of the Unbowed"},
}
## Ward card uids that lie face up (Ysolde's Unveiling, or the Unveil Gift).
var face_up := {}
## A story duel's own rules (Master Script v3: every story duel has one rule
## that says who the opponent is), as {rule id: the side it binds}. Each rule
## is its own _rule_<id>() function under "story rules" below:
## "run_to_ground" (Hunter Dask, the Thornwood road), "showboat" (Corin, the
## Lantern Duel), "hold_the_gate" (Warden Hale at Solhaven's gate),
## "light_fingers" (Wren in the alley), "sunspire_mirror" (Ser Aldric on the
## Sunspire), "mirror_trial" (the Trial of Light: the mirrors set the board
## and watch; the other side must win within puzzle.turns of its own turns),
## and the side stories' wagers, in their own section further down:
## "licensed" (the Sergeant), "patter" (Fen), "scrapper" (Pip) and
## "discipline" (the Captain).
var story_rules := {}
## Both duellists start on this share of their usual Life (Hale's short duel
## at the gate is fought at half: "a test, not a fight").
var life_scale := 1.0
## Cards a story duellist keeps off their deck until a rule brings them out
## ([side] -> card ids): Aldric's Dawnmane, for when he's losing.
var kept_back: Array = [[], []]
## A fixed board instead of the usual start (the Trial of Light): first, life,
## essence_max (before the first turn's +1), board (per side, three slots of a
## card id, an [id, ascension...] stack or null), hand, deck (drawn in the
## order written) and turns (how many turns side `first` has to win in).
var puzzle := {}
## What the story rules remember during a duel (the mirror has swung, Wren's
## hand has been in your pocket...).
var rule_state := {}


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
		if i < stacked.size() and stacked[i]:
			p.deck.reverse()   # cards are drawn from the back: the list's first card comes first
		else:
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
		if start_lives.size() == 2 and int(start_lives[p.index]) > 0:
			p.max_life = int(start_lives[p.index])
		if life_scale != 1.0:
			p.max_life = maxi(10, int(round(p.max_life * life_scale / 10.0)) * 10)
		p.life = p.max_life
		p.fortune_left = mini(2, int(p.profile.get("fortune", 0)))
		if law == "hethrin" and blessed(p.index):
			p.guard_bonus = DuelLaws.ironworks_guard
		if law == "nocthra":
			p.extra_ward_slots = 1
	if law != "":
		_log("This duel is fought under %s: %s" % [DuelLaws.law_name(law), DuelLaws.describe(law)])
	if not puzzle.is_empty():
		_setup_puzzle()
		turn = 0
		current = first_player
		_changed()
		return
	# Both roll a d20; Swiftness adds its Fate modifier, so the swifter
	# duellist goes first more often (but not always).
	while first_forced >= 0:
		first_player = first_forced
		var hi := 15
		var lo := 6
		await _fx("fx_rolloff", [hi if first_player == 0 else lo, lo if first_player == 0 else hi])
		_log("Roll for first turn: %s goes first." % players[first_player].player_name)
		break
	while first_forced < 0:
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


## A fixed board (the Trial of Light): no roll for first turn and no opening
## hands; each side's Totems, hand, deck, Life and Essence are as written.
func _setup_puzzle() -> void:
	first_player = int(puzzle.get("first", 0))
	for p in players:
		var i: int = p.index
		p.deck.clear()
		p.hand.clear()
		var lives: Array = puzzle.get("life", [])
		if i < lives.size() and int(lives[i]) > 0:
			p.max_life = int(lives[i])
			p.life = p.max_life
		var em: Array = puzzle.get("essence_max", [])
		if i < em.size():
			p.essence_max = int(em[i])
		for id in (puzzle.get("hand", [[], []]) as Array)[i]:
			p.hand.append(_new_card(String(id), i))
		var dk: Array = (puzzle.get("deck", [[], []]) as Array)[i]
		for k in range(dk.size() - 1, -1, -1):
			p.deck.append(_new_card(String(dk[k]), i))   # the first written is drawn first
		var board: Array = (puzzle.get("board", [[], []]) as Array)[i]
		for s in mini(board.size(), DuelRules.SLOTS):
			var e = board[s]
			if e == null or (e is String and e == ""):
				continue
			var ids: Array = e if e is Array else [e]
			var t := _new_totem(_new_card(String(ids[0]), i), i, s, 0)
			for k in range(1, ids.size()):
				t.stack.append(_new_card(String(ids[k]), i))
			p.slots[s] = t
	if String(puzzle.get("log", "")) != "":
		_log(String(puzzle.log))


## A set board can hold a side's Essence where it is (puzzle.essence_fixed):
## it refills each turn but never grows.
func _essence_fixed(pi: int) -> bool:
	var f: Array = puzzle.get("essence_fixed", [])
	return pi < f.size() and bool(f[pi])


## A Totem for `pi`'s slot, carrying its owner's Tempering marks (Phase C).
func _new_totem(card: DuelCard, pi: int, slot: int, at_turn: int) -> DuelTotem:
	var p: DuelPlayer = players[pi]
	var t := DuelTotem.new(card, pi, slot, at_turn, p.attributes())
	t.temper = p.profile.get("temper", {})
	return t


func _new_card(id: String, owner: int) -> DuelCard:
	var c := DuelCard.new(_next_uid, id, owner)
	_next_uid += 1
	return c


# ------------------------------------------------------------------- turns ---

func _take_turn() -> void:
	turn += 1
	# (with phases off the turn is "main" from its first moment to its last:
	# the start-of-turn work below runs the same, with no phase of its own)
	phase = "dawn" if DuelRules.phases else "main"
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
		t.stance = "strike"   # a stance holds until its owner's next turn
	if p.essence_max < DuelRules.essence_cap and not _essence_fixed(p.index):
		p.essence_max += 1
	p.essence = p.essence_max
	if p.pending_essence > 0:
		p.essence += p.pending_essence
		_log("%s gains %d Essence held over." % [p.player_name, p.pending_essence], current)
		p.pending_essence = 0
	_log("Turn %d - %s" % [turn, p.player_name], -2)
	await _fx("fx_turn", [current])
	if DuelRules.phases:
		await _fx("fx_phase", [current, "dawn"])
	await _dawn_conditions(p)
	if over:
		return
	await _dawn_rekindle(p)
	if over:
		return
	await _dawn_relics_and_veils(p)
	if over:
		return
	await _dawn_arena(p)
	if over:
		return
	await _dawn_continuous(p)
	if over:
		return
	if DuelRules.phases:
		phase = "draw"
		_changed()
		await _fx("fx_phase", [current, "draw"])
	if turn > 1:
		var drawn := await _draw(p, 1)
		if over:
			return
		if not drawn.is_empty():
			await _fx("fx_draw", [current, drawn])
	_changed()
	if DuelRules.has_perk(p.attributes(), "insight") and not p.deck.is_empty():
		var keep: bool = await p.controller.choose_scry(self, current, p.deck[-1])
		if not keep:
			p.deck.insert(0, p.deck.pop_back())
			_log("%s sends the top card of their deck to the bottom." % p.player_name, current)
	await _possessed_strikes(p)
	if over:
		return
	await _rule_light_fingers(p)
	if over:
		return
	await _rule_dawnmane(p)
	if over:
		return

	await _enter_phase("main")
	var actions := 0
	while not over and not _rule_mirrors_watch(p):
		actions += 1
		if actions > DuelRules.MAX_ACTIONS_PER_TURN:
			break
		_changed()
		var action = await p.controller.choose_action(self, current)
		if over:
			return
		var kind := "end"
		if action is Dictionary and not action.is_empty():
			kind = String(action.get("type", "end"))
		if kind == "end" or kind == "next":
			var owed = _rule_showboat_owed(current)   # no ending the turn with a Showboat attack owed
			if owed != null:
				if DuelRules.phases and phase != "clash":
					await _enter_phase("clash")
				await perform(current, owed)
				continue
			if kind == "end":
				break
			var nxt := next_phase(current)   # ("end" with phases off: a stray "next" ends the turn)
			if nxt == "end":
				break
			await _enter_phase(nxt)
			continue
		await perform(current, action)
	if over:
		return
	await _enter_phase("dusk")
	await _dusk(p)
	await _oath_dusk(p)
	await _terrain_tick()
	_rule_mirror_trial_out(p)
	if over:
		return
	current = 1 - current


## The ground the duel is on now: a Terrain Rite's while it holds, else the
## arena; "" on a set board (the Trial) or when no arena was given.
func arena_now() -> String:
	if not puzzle.is_empty():
		return ""
	if not terrain.is_empty():
		return String(terrain.arena)
	return arena


func arena_rule_text() -> String:
	return String(ARENA_RULES.get(arena_now(), ""))


func _refresh_arena_guard() -> void:
	for p in players:
		p.arena_guard = DuelRules.arena_guard if arena_now() == "ironstone" else 0


## The arena's rule at the Dawn of `p`'s turn (Phase D).
func _dawn_arena(p: DuelPlayer) -> void:
	_refresh_arena_guard()
	match arena_now():
		"tidegrove":
			var all := []
			for pl in players:
				for t in pl.totems():
					if not t.has_status("soaked"):
						all.append(t)
			if not all.is_empty():
				var t: DuelTotem = all[rng.randi_range(0, all.size() - 1)]
				_log("The tide rises in the Circle: %s is Soaked." % t.card_name(), -1)
				await _fx("fx_arena_rule", [p.index, "tidegrove", "%s is Soaked" % t.card_name()])
				await _apply_status(t, "soaked", null, -1)
		"solhaven":
			if p.totems().size() < opponent(p.index).totems().size():
				p.essence += 1
				_log("The sun favours the outnumbered: %s gains 1 Essence." % p.player_name, p.index)
				await _fx("fx_arena_rule", [p.index, "solhaven", "+1 Essence"])


## A Terrain Rite's turns run down at each Dusk; when it's spent the ground
## goes back to the arena.
func _terrain_tick() -> void:
	if terrain.is_empty():
		return
	terrain.left = int(terrain.left) - 1
	if int(terrain.left) <= 0:
		var was := String(terrain.arena)
		terrain = {}
		_refresh_arena_guard()
		_log("The ground of %s fades; the Circle is itself again." % was.capitalize(), -1)
		await _fx("fx_terrain", [arena_now(), "fade"])


func _enter_phase(name: String) -> void:
	if not DuelRules.phases:
		phase = "main"   # one free Main all turn long: no phase to enter, nothing to show
		_changed()
		return
	phase = name
	_changed()
	await _fx("fx_phase", [current, name])


## Where a "next" action takes the turn from here: a phase with nothing to do
## in it is skipped, so the Clash only comes when a Totem can attack and the
## second Main only when a Rite or a Shift is possible. With phases off there
## is nowhere to go but the end of the turn.
func next_phase(pi: int) -> String:
	if not DuelRules.phases:
		return "end"
	match phase:
		"main":
			if clash_worth(pi):
				return "clash"
			return "main2" if main2_worth(pi) else "end"
		"clash":
			return "main2" if main2_worth(pi) else "end"
	return "end"


## A Totem of theirs could attack now (ignoring the phase).
func clash_worth(pi: int) -> bool:
	for t in players[pi].totems():
		if ready_problem(pi, t) != "":
			continue
		for i in t.moves().size():
			if move_problem(pi, t, i) == "":
				return true
	return false


## A Rite could be cast, a Shift made or the Gift called on (ignoring the phase).
func main2_worth(pi: int) -> bool:
	var p: DuelPlayer = players[pi]
	for c in p.hand:
		if c.is_rite() and rite_problem(pi, c) == "":
			return true
	if gift_problem(pi) == "":
		return true
	if shift_cost(pi) <= p.essence:
		for t in p.totems():
			for sl in p.slots.size():
				if sl != t.slot and shift_problem(pi, t, sl) == "":
					return true
	return false


## Why this kind of action can't be done in the phase the turn is in ("" if it
## can; always "" with phases off, when anything goes at any point in the turn).
func phase_problem(kind: String) -> String:
	if not DuelRules.phases:
		return ""
	match kind:
		"call":
			if phase != "main":
				return "Totems are called in the Main phase, before the Clash."
		"ascend":
			if phase != "main":
				return "Ascension happens in the Main phase, before the Clash."
		"ward":
			if phase != "main":
				return "Wards are set in the Main phase, before the Clash."
		"summon":
			if phase != "main":
				return "Summons are called down in the Main phase, before the Clash."
		"stance":
			if phase != "main":
				return "Stances are set in the Main phase, before the Clash."
		"relic":
			if phase != "main":
				return "Relics are given in the Main phase, before the Clash."
		"attack":
			if phase == "main":
				return "Attacks come in the Clash: move on to it when you're ready."
			if phase != "clash":
				return "Attacks happen in the Clash."
		"rite", "gift":
			if phase != "main" and phase != "main2":
				return "Rites are cast in a Main phase, not the Clash."
		"shift":
			if phase != "main" and phase != "main2":
				return "Shifting happens in a Main phase, not the Clash."
		"demigod":
			if phase != "main":
				return "A Demigod is called down in the Main phase, before the Clash."
		"oath":
			if phase != "main" and phase != "main2":
				return "Oaths are sworn in a Main phase, not the Clash."
	return ""


func phase_name() -> String:
	return String(PHASE_NAMES.get(phase, phase))


func _dawn_conditions(p: DuelPlayer) -> void:
	await _dawn_law(p)
	await _rule_patter(p)   # (a story rule: Fen's Patter, as his turn starts)
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
			await _damage_totem(t, DuelRules.burn_damage + int(standing(1 - p.index, "burn_bonus").get("burn_bonus", 0)), {"source": "burn"})
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
	_settle_oaths(w)


# ================================================================ actions ===

## Carries out an action. Shapes:
##   {type: "call", card, slot}          {type: "ascend", card, target}
##   {type: "rite", card, target?}       {type: "ward", card}
##   {type: "shift", totem, slot}        {type: "attack", attacker, move, target}
##   {type: "summon", card, target?}     {type: "gift", target?}
##   {type: "stance", totem, stance}      {type: "next"} moves the phase on (ends the turn with phases off), {type: "end"} ends the turn
## Returns false (and does nothing) if the action isn't allowed.
func perform(pi: int, action: Dictionary) -> bool:
	var problem := action_problem(pi, action)
	if problem != "":
		_log("(Not allowed: %s)" % problem, pi)
		return false
	match action.type:
		"call":
			await _act_call(pi, action.card, int(action.slot), action.get("tributes", []), false, bool(action.get("veiled", false)))
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
		"stance":
			await _act_stance(pi, action.totem, String(action.stance))
		"relic":
			await _act_relic(pi, action.card, action.target)
		"demigod":
			await _act_demigod(pi, action.get("target"))
		"oath":
			await _act_oath(pi, String(action.get("oath", "")))
	if not over:
		await _favour_after(pi, action)
	if not over:
		await _check_oaths()
	_changed()
	return true


func action_problem(pi: int, action: Dictionary) -> String:
	if over:
		return "The duel is over."
	if pi != current:
		return "It isn't your turn."
	var kind := String(action.get("type", ""))
	if kind == "next" or kind == "end":
		return ""
	var ph := phase_problem(kind) if not _phase_free else ""
	if ph != "":
		return ph
	var showboat := _rule_showboat(pi, action)
	if showboat != "":
		return showboat
	match kind:
		"call":
			var cp := call_problem(pi, action.get("card"), int(action.get("slot", -1)), action.get("tributes", []) if tributes_needed(action.get("card")) > 0 else null)
			if cp == "" and bool(action.get("veiled", false)) and not free_veil(pi) and call_cost(pi, action.get("card")) + 1 > players[pi].essence:
				return "Calling it veiled costs %d Essence." % (call_cost(pi, action.get("card")) + 1)
			return cp
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
		"stance":
			return stance_problem(pi, action.get("totem"), String(action.get("stance", "")))
		"relic":
			return relic_problem(pi, action.get("card"), action.get("target"))
		"demigod":
			return demigod_problem(pi, action.get("target"))
		"oath":
			return oath_problem(pi, String(action.get("oath", "")))
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
func card_cost(pi: int, card: DuelCard) -> int:
	# Iron Tithe on the other side (Phase D): Wards and Rites cost more, free ones too
	var tax := 0
	if card.is_ward() or card.is_rite():
		tax = int(standing(1 - pi, "foe_tax").get("foe_tax", 0))
	var c := card.cost()
	if c <= 0:
		return c + tax
	var el := card.element()
	var d := _rule_sunspire_mirror_discount(pi, card) + tax
	if law == "" and d == 0:
		return c
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


## How many of your Totems a Basic Totem costs to call besides its Essence
## (Phase B): none below DuelRules.tribute_tier, one from it, two from
## tribute_two_tier. A story rule's call (Wren's theft) pays none.
func tributes_needed(card: DuelCard) -> int:
	if card == null or not card.is_basic_totem() or _phase_free:
		return 0
	if card.tier() >= DuelRules.tribute_two_tier:
		return 2
	if card.tier() >= DuelRules.tribute_tier:
		return 1
	return 0


## Why this Totem can't be called ("" if it can). `tributes` null: whether
## it could be with some choice of tributes; an Array: with those.
func call_problem(pi: int, card: DuelCard, slot: int = -1, tributes = null) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_basic_totem():
		return "Only Basic Totems can be called."
	var need := tributes_needed(card)
	var c := call_cost(pi, card)
	if need > 0:
		if p.totems().size() < need:
			return "%s is a %s: it costs %s of your Totems on the field as well as its Essence." % [
				card.card_name(), Lore.TIER_NAMES[mini(card.tier(), Lore.TIER_NAMES.size() - 1)], "one" if need == 1 else "two"]
		if tributes is Array:
			if tributes.size() != need:
				return "Choose %d Totem%s of yours to give up." % [need, "" if need == 1 else "s"]
			var seen := {}
			for t in tributes:
				if not (t is DuelTotem) or t.owner != pi or not p.totems().has(t) or seen.has(t.uid):
					return "Choose your own Totems on the field to give up."
				seen[t.uid] = true
			if slot >= 0 and p.slots[slot] != null and not tributes.has(p.slots[slot]):
				return "That slot is taken."
		elif slot >= 0 and slot < p.slots.size() and p.slots[slot] != null and p.totems().size() < need:
			return "That slot is taken."
	else:
		if p.empty_slots().is_empty():
			return "All three of your slots are full."
		if slot >= 0 and (slot >= p.slots.size() or p.slots[slot] != null):
			return "That slot is taken."
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
			var ts := targetable(opponent(pi).totems())
			if card.def.has("needs_status"):
				# (Shatter: only a Totem with that condition)
				ts = ts.filter(func(t): return (t as DuelTotem).has_status(String(card.def.needs_status)))
			return ts
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
	if card.def.get("answer", false):
		return "An answer: play it on your opponent's turn, when %s." % answers_text(card)
	var ap := archetype_problem(pi, card)
	if ap != "":
		return ap
	if rite_cost(pi, card) > p.essence:
		return "Needs %d Essence." % rite_cost(pi, card)
	var tk: String = card.def.get("target", "none")
	if rite_needs_target(card):
		var ts := rite_targets(pi, card)
		if ts.is_empty():
			if card.def.has("needs_status"):
				return "No enemy Totem is %s." % String(DuelConditions.NAMES.get(card.def.needs_status, card.def.needs_status))
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
			"revive_hand":
				if _revivable(pi, 99).is_empty():
					return "There's no Basic Totem in your discard."
			"revive_field":
				if p.empty_slots().is_empty():
					return "All three of your slots are full."
				if _revivable(pi, int(e.get("max_tier", 2))).is_empty():
					return "There's no Basic Totem of tier %d or lower in your discard." % int(e.get("max_tier", 2))
			"call_legend_free":
				if p.life >= opponent(pi).life:
					return "Only while your Life is lower than your opponent's."
				if p.empty_slots().is_empty():
					return "All three of your slots are full."
				if _legends_in_hand(pi).is_empty():
					return "You hold no Legend Totem to call."
			"seek_kindred":
				if p.totems().is_empty():
					return "You need a Totem on the field to seek its kin."
				if _kindred(pi).is_empty():
					return "Your deck holds no Totem of your Totems' elements."
			"discard_to_top":
				if p.discard.is_empty():
					return "Your discard is empty."
			"relic_hunt":
				if not p.discard.any(func(c): return (c as DuelCard).kind() == "relic"):
					return "There's no Relic in your discard."
			"unbind":
				if opponent(pi).continuous.is_empty():
					return "Your rival has no standing Rite to unbind."
			"terrain":
				if not puzzle.is_empty():
					return "The mirrors' ground can't be turned."
			"burned_damage":
				if not opponent(pi).totems().any(func(t): return (t as DuelTotem).has_status("burn")):
					return "No enemy Totem is Burned."
			"reveal_twice":
				if not p.totems().any(func(t): return (t as DuelTotem).face_down):
					return "You have no veiled Totem."
			"veil_call_free":
				if p.empty_slots().is_empty():
					return "All three of your slots are full."
				if _veil_callable(pi, int(e.get("max_tier", 2))).is_empty():
					return "You hold no Basic Totem of tier %d or lower." % int(e.get("max_tier", 2))
			"pick_top":
				if p.deck.is_empty():
					return "Your deck is empty."
			"heal":
				if e.get("who", "") == "target" and target != null and target is DuelTotem \
						and target.damage == 0 and not target.has_condition():
					return "That Totem isn't hurt."
	var ashes := int(card.def.get("needs_ashes", 0))
	if ashes > 0 and ashes_element(pi, ashes) == "":
		return "Needs %d Totems of one element in your discard." % ashes
	return ""


func ward_problem(pi: int, card: DuelCard) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if not card.is_ward():
		return "That isn't a Ward."
	var ap := archetype_problem(pi, card)
	if ap != "":
		return ap
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
	if totem.stance == "rest":
		return "%s is resting and can't Shift." % totem.card_name()
	if slot < 0 or slot >= p.slots.size() or slot == totem.slot:
		return "Choose a different slot."
	if shift_cost(pi) > p.essence:
		return "Needs %d Essence." % shift_cost(pi)
	return ""


# ------------------------------------------------------------ relics (Phase C) ---

## Why this Relic can't go on that Totem ("" if it can). One each; it stays
## until the Totem falls.
func relic_problem(pi: int, card: DuelCard, target = null) -> String:
	var p: DuelPlayer = players[pi]
	if card == null or not p.hand.has(card):
		return "That card isn't in your hand."
	if card.kind() != "relic":
		return "That isn't a Relic."
	if relic_targets(pi).is_empty():
		return "None of your Totems is free to carry it." if not p.totems().is_empty() else "You have no Totem to give it to."
	if target != null and not relic_targets(pi).has(target):
		return "That Totem already carries a Relic." if target is DuelTotem and target.owner == pi else "Choose one of your Totems."
	if card_cost(pi, card) > p.essence:
		return "Needs %d Essence." % card_cost(pi, card)
	return ""


func relic_targets(pi: int) -> Array:
	return players[pi].totems().filter(func(t): return t.relic == null)


func _act_relic(pi: int, card: DuelCard, target: DuelTotem) -> void:
	var p: DuelPlayer = players[pi]
	if target == null:
		target = relic_targets(pi)[0]
	_spend(p, card_cost(pi, card))
	p.hand.erase(card)
	target.relic = card
	p.stats.relics += 1
	p.note_played(card.id)
	_log("%s gives %s the %s." % [p.player_name, target.card_name(), card.card_name()], pi)
	await _fx("fx_relic", [target, card])


## A Totem's Relic, when it leaves the field: to the discard (it fell or was
## given up), or back to the hand with it (swept back).
func _drop_relic(t: DuelTotem, to_hand: bool) -> void:
	if t.relic == null:
		return
	var p: DuelPlayer = players[t.owner]
	if to_hand:
		p.hand.append(t.relic)
	else:
		p.discard.append(t.relic)
	t.relic = null


## Why this Totem can't take that stance ("" if it can). Free, once a turn,
## in the Main phase (anywhere in the turn with phases off), and only for a
## Totem that could attack this turn (so not one that already has): a
## stance is what a ready Totem does with its turn instead of striking (one
## called this turn, asleep or stunned has no stance to take).
func stance_problem(pi: int, t, stance: String) -> String:
	if t == null or not (t is DuelTotem) or t.owner != pi or not players[pi].totems().has(t):
		return "Choose one of your Totems."
	if not STANCES.has(stance):
		return "Unknown stance."
	if t.stance == stance:
		return "%s is already set to %s." % [t.card_name(), STANCE_NAMES[stance]]
	if t.stance == "rest":
		return "%s is resting: it stays put this turn." % t.card_name()
	if t.stance_turn == turn:
		return "%s has taken its stance for this turn." % t.card_name()
	var was: String = t.stance
	t.stance = "strike"
	var ready := ready_problem(pi, t)
	t.stance = was
	if ready != "":
		return ready
	if stance == "rest" and t.has_status("enraged"):
		return "%s is enraged and won't rest." % t.card_name()
	return ""


func _act_stance(pi: int, t: DuelTotem, stance: String) -> void:
	var p: DuelPlayer = players[pi]
	t.stance = stance
	t.stance_turn = turn
	p.stats.stances += 1
	match stance:
		"guard":
			_log("%s takes a Guard stance: it turns half of every blow aside, and won't attack." % t.card_name(), pi)
		"rest":
			_log("%s rests." % t.card_name(), pi)
		_:
			_log("%s is set to Strike." % t.card_name(), pi)
	await _fx("fx_stance", [t])
	if stance == "rest":
		if t.damage > 0:
			await _heal(t, DuelRules.rest_heal)
		if DuelRules.rest_essence > 0:
			p.pending_essence += DuelRules.rest_essence
			_log("%s's rest gives %s %d Essence at their next turn." % [t.card_name(), p.player_name, DuelRules.rest_essence], pi)


## Why this Totem can't attack right now ("" if it can).
func ready_problem(pi: int, t) -> String:
	if t == null or not (t is DuelTotem) or t.owner != pi or not players[pi].totems().has(t):
		return "Choose one of your Totems."
	if t.attacked:
		return "%s has already attacked this turn." % t.card_name()
	if t.stance == "guard":
		return "%s is on Guard this turn." % t.card_name()
	if t.stance == "rest":
		return "%s is resting this turn." % t.card_name()
	if turn == 1:
		return "Nobody can attack on the first turn of the duel."
	if t.called_turn == turn and not t.has_keyword("swift") \
			and not (t.element() == "storm" and not standing(pi, "storm_swift").is_empty()):
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
	out = _rule_run_to_ground(pi, out)
	out = _rule_showboat_targets(pi, t, out)
	out = _rule_hold_the_gate(pi, out)
	return out


# ------------------------------------------------------------ story rules ---

## Run to Ground (Hunter Dask, on the Thornwood road): his hounds always go for
## the Totem with the least Life left, never past it at anything else.
## Run to Ground (Hunter Dask, v7): his hounds gain +2 Attack for every turn
## that passes, which in the game's tens is +10 to their blows for each full
## round gone by. (v3's rule, the hounds going for the weakest Totem, is
## kept only as `run_to_ground_v3`.)
func run_to_ground_bonus(pi: int) -> int:
	if not story_rules.has("run_to_ground") or int(story_rules.run_to_ground) != pi:
		return 0
	return 10 * maxi(0, (turn - 1) / 2)


func _rule_run_to_ground(pi: int, out: Array) -> Array:
	if not story_rules.has("run_to_ground_v3") or int(story_rules.run_to_ground_v3) != pi:
		return out
	var foes := out.filter(func(x): return x is DuelTotem)
	if foes.is_empty():
		return out
	var low: int = foes[0].hp_left()
	for f in foes:
		low = mini(low, (f as DuelTotem).hp_left())
	return foes.filter(func(f): return (f as DuelTotem).hp_left() == low)


## Hold the Gate (Warden Hale, at Solhaven's Golden Gate): while one of his
## Guardians stands, his Totems never go for your Life. He's there to hold,
## not to win.
func _rule_hold_the_gate(pi: int, out: Array) -> Array:
	if not story_rules.has("hold_the_gate") or int(story_rules.hold_the_gate) != pi:
		return out
	if not players[pi].has_guardian():
		return out
	var kept := out.filter(func(x): return not (x is String and x == LIFE))
	if kept.size() != out.size():
		rule_state["held"] = true   # (the gate held: Life was in reach, and left alone)
	return kept


## Light Fingers (Wren, in the alley): once a duel, from her second turn on,
## she takes a card out of your hand that she can play there and then, and
## plays it as her own. She picks the best one going.
func _rule_light_fingers(p: DuelPlayer) -> void:
	if not story_rules.has("light_fingers") or int(story_rules.light_fingers) != p.index:
		return
	if rule_state.get("light_fingers", false) or turn < 3:
		return
	var foe := opponent(p.index)
	var picks := foe.hand.duplicate()
	picks.sort_custom(func(a, b): return _steal_value(a) > _steal_value(b))
	for c in picks:
		var card: DuelCard = c
		# in her hand for a moment, to see whether she could play it now
		var at := foe.hand.find(card)
		foe.hand.remove_at(at)
		p.hand.append(card)
		card.owner = p.index
		var act := _stolen_play(p.index, card)
		if act.is_empty():
			p.hand.erase(card)
			foe.hand.insert(at, card)
			card.owner = foe.index
			continue
		rule_state["light_fingers"] = true
		rule_state["stolen"] = card.id
		_log("Light Fingers: %s takes %s from %s hand, and plays it as her own." % [p.player_name, card.card_name(), whose(foe.player_name, true)], p.index)
		await _fx("fx_light_fingers", [p.index, card])
		if over:
			return
		_phase_free = true   # at her Dawn, before the Main
		await perform(p.index, act)
		_phase_free = false
		return


## How much Wren wants a card from your hand.
func _steal_value(c: DuelCard) -> float:
	match c.kind():
		"totem":
			return 20.0 + c.cost() * 10.0 + c.tier() * 6.0 if c.is_basic_totem() else 0.0
		"summon":
			return 60.0 + c.cost() * 10.0
		"rite":
			return c.cost() * 10.0 + int(c.def.get("damage", 0)) * 0.2 + 2.0
		"ward":
			return c.cost() * 8.0 + 1.0
	return 0.0


## The play Wren makes with a card she's just taken ({} if she can't use it now).
func _stolen_play(pi: int, card: DuelCard) -> Dictionary:
	match card.kind():
		"totem":
			if card.is_basic_totem() and not players[pi].empty_slots().is_empty() and call_problem(pi, card) == "":
				return {"type": "call", "card": card, "slot": players[pi].empty_slots()[0]}   # (a story rule's call: no Tribute)
		"rite":
			if rite_needs_target(card):
				var ts := rite_targets(pi, card)
				if card.def.get("target", "") == "foe_totem":
					ts.sort_custom(func(a, b): return a.hp_left() < b.hp_left())
				else:
					ts.sort_custom(func(a, b): return a.damage > b.damage)
				for t in ts:
					if rite_problem(pi, card, t) == "":
						return {"type": "rite", "card": card, "target": t}
			elif rite_problem(pi, card) == "":
				return {"type": "rite", "card": card}
		"ward":
			if ward_problem(pi, card) == "":
				return {"type": "ward", "card": card}
		"summon":
			if summon_needs_target(card):
				var ts := targetable(opponent(pi).totems())
				ts.sort_custom(func(a, b): return a.hp_left() > b.hp_left())
				for t in ts:
					if summon_problem(pi, card, t) == "":
						return {"type": "summon", "card": card, "target": t}
			elif summon_problem(pi, card) == "" and not opponent(pi).totems().is_empty():
				return {"type": "summon", "card": card}
	return {}


## The Sunspire's Mirror (Ser Aldric, on the Sunspire's roof): the first time
## his Life is at half or less, the great mirror swings on its chains to put
## the sun on his side of the Circle. For the rest of the duel his Radiant
## cards cost one less, and what he kept back for when he's losing (Dawnmane)
## comes to his hand.
func _rule_sunspire_mirror_check(pi: int) -> void:
	if not story_rules.has("sunspire_mirror") or int(story_rules.sunspire_mirror) != pi:
		return
	var p: DuelPlayer = players[pi]
	if over or rule_state.get("mirror", false) or p.life <= 0 or p.life * 2 > p.max_life:
		return
	rule_state["mirror"] = true
	_log("The great mirror swings to %s side of the Circle. %s Radiant cards cost one less." % [whose(p.player_name, true), whose(p.player_name)], pi)
	for id in kept_back[pi]:
		p.hand.append(_new_card(String(id), pi))
	kept_back[pi] = []
	await _fx("fx_mirror", [pi])


## One less for a Radiant card once the mirror is on its owner's side.
func _rule_sunspire_mirror_discount(pi: int, card: DuelCard) -> int:
	if not story_rules.has("sunspire_mirror") or int(story_rules.sunspire_mirror) != pi:
		return 0
	if rule_state.get("mirror", false) and card.element() == "radiant":
		return -1
	return 0


## What he kept back, he calls down the moment he can pay for it: Aldric lays
## Dawnmane on the stone without a word.
func _rule_dawnmane(p: DuelPlayer) -> void:
	if not story_rules.has("sunspire_mirror") or int(story_rules.sunspire_mirror) != p.index:
		return
	if not rule_state.get("mirror", false) or rule_state.get("woken", false):
		return
	for c in p.hand:
		var card: DuelCard = c
		if not (card.is_summon() and card.element() == "radiant"):
			continue
		var act := _stolen_play(p.index, card)   # (the same choice of target)
		if act.is_empty():
			return
		rule_state["woken"] = true
		_phase_free = true   # at his Dawn, before the Main
		await perform(p.index, act)
		_phase_free = false
		return


## The Trial of Light: the mirrors (the side this binds) set the board and
## only watch.
func _rule_mirrors_watch(p: DuelPlayer) -> bool:
	return story_rules.has("mirror_trial") and int(story_rules.mirror_trial) == p.index


## ...and the other side has puzzle.turns of its own turns to win in. A
## mistake resets the board: the duel ends at the last of them.
func _rule_mirror_trial_out(p: DuelPlayer) -> void:
	if not story_rules.has("mirror_trial") or int(story_rules.mirror_trial) == p.index or over:
		return
	var n := int(rule_state.get("trial_turns", 0)) + 1
	rule_state["trial_turns"] = n
	if n >= int(puzzle.get("turns", 3)):
		_finish(int(story_rules.mirror_trial), "The mirrors go dark. They begin again.")


func move_problem(pi: int, t, i: int, target = null, check_target: bool = false) -> String:
	var r := ready_problem(pi, t)
	if r != "":
		return r
	if i < 0 or i >= t.moves().size():
		return "Unknown move."
	if t.move(i).has("bond") and t.bond.is_empty():
		return "The bond move needs its partner beside it."
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
	if p.gift_used and not p.favour_ready:
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
## Something worth doing in the phase the turn is in (a stance or a Shift
## doesn't count: those are always there).
func can_do_anything_but_end(pi: int) -> bool:
	var p: DuelPlayer = players[pi]
	for c in p.hand:
		match c.kind():
			"totem":
				if c.is_basic_totem() and phase_problem("call") == "" and call_problem(pi, c) == "":
					return true
				if c.is_ascension() and phase_problem("ascend") == "" and ascend_problem(pi, c) == "":
					return true
			"rite":
				if phase_problem("rite") == "" and rite_problem(pi, c) == "":
					return true
			"ward":
				if phase_problem("ward") == "" and ward_problem(pi, c) == "":
					return true
			"summon":
				if phase_problem("summon") == "" and summon_problem(pi, c) == "":
					return true
			"relic":
				if phase_problem("relic") == "" and relic_problem(pi, c) == "":
					return true
	if phase_problem("attack") == "":
		for t in p.totems():
			for i in t.moves().size():
				if move_problem(pi, t, i) == "":
					return true
	return false


# ------------------------------------------------- story rule: Showboat ---
# Corin's rule in the Lantern Duel (story_rules["showboat"] = his side): "his
# Cinderpup always attacks the moment it can, whatever's in its way". While a
# Totem on that side could attack, nothing else may be done first and the
# turn can't end; it goes at the Totem across from it, or straight at the
# Life when nothing stands there.

## The Totems on `pi`'s side that owe an attack right now ([] when none, or
## when Showboat isn't theirs).
func showboat_due(pi: int, any_phase := false) -> Array:
	if int(story_rules.get("showboat", -1)) != pi or over or pi != current:
		return []
	# (with phases on the attack is owed in the Clash; with them off, from the
	# turn's first moment, as the rule was written)
	if DuelRules.phases and phase != "clash" and not any_phase:
		return []
	var out := []
	for t in players[pi].totems():
		for i in t.moves().size():
			if t.move_target(i) in ["foe", "foe_totem", "all_foes"] and move_problem(pi, t, i) == "":
				out.append(t)
				break
	return out


## The attack a Showboat Totem makes when its side would rather end the turn:
## its first move it can make, at whatever's in its way. {} when none is owed.
func showboat_attack(pi: int) -> Dictionary:
	for t in showboat_due(pi, true):
		for i in (t as DuelTotem).moves().size():
			if not (t.move_target(i) in ["foe", "foe_totem", "all_foes"]) or move_problem(pi, t, i) != "":
				continue
			var ts := attack_targets(pi, t, i)
			if not ts.is_empty():
				return {"type": "attack", "attacker": t, "move": i, "target": ts[0]}
	return {}


func _rule_showboat(pi: int, action: Dictionary) -> String:
	var due := showboat_due(pi)
	if due.is_empty():
		return ""
	if String(action.get("type", "")) == "attack" and due.has(action.get("attacker")):
		return ""
	return "Showboat: %s attacks the moment it can." % (due[0] as DuelTotem).card_name()


## Whatever's in its way: the Totem across, or else the Life.
func _rule_showboat_targets(pi: int, t: DuelTotem, out: Array) -> Array:
	if int(story_rules.get("showboat", -1)) != pi:
		return out
	var across = opponent(pi).slots[t.slot]
	if across != null and out.has(across):
		return [across]
	if out.has(LIFE):
		return [LIFE]
	return out


func _rule_showboat_owed(pi: int):
	var a := showboat_attack(pi)
	return a if not a.is_empty() else null


# ------------------------------------------------------------- calling ---

func _act_call(pi: int, card: DuelCard, slot: int, tributes: Array = [], free := false, veiled := false) -> void:
	var p: DuelPlayer = players[pi]
	var veil_free := free_veil(pi)
	if arena_now() == "veilwild" and p.stats.totems_called == 0 and not free:
		veiled = true   # the veilwild veils each duellist's first call, free
		veil_free = true
	var c := 0 if free else call_cost(pi, card) + (1 if veiled and not veil_free else 0)
	_spend(p, c)
	p.hand.erase(card)
	p.discard.erase(card)
	# the Totems given up for it (Phase B): to the discard, their light into the new one
	for tr in tributes:
		if not (tr is DuelTotem) or not p.totems().has(tr):
			continue
		p.slots[tr.slot] = null
		for sc in tr.stack:
			p.discard.append(sc)
		_drop_relic(tr, false)
		p.stats.tributes += 1
		_log("%s gives itself up for %s." % [tr.card_name(), card.card_name()], pi)
		await _fx("fx_tribute", [tr, card])
		if slot < 0 or p.slots[slot] != null:
			slot = tr.slot
	if slot < 0 or p.slots[slot] != null:
		slot = p.empty_slots()[0]
	var t := _new_totem(card, pi, slot, turn)
	t.face_down = veiled
	if p.free_shift:
		t.hasted = true   # Ixara's Tempest
	if law == "verdanthe" and blessed(pi):
		t.bonus_hp += DuelLaws.spring_hp_bonus
	p.slots[slot] = t
	p.totems_called += 1
	p.stats.totems_called += 1
	p.note_played(card.id)
	if veiled:
		p.stats.veiled += 1
		_log("%s calls a Totem face down." % p.player_name, pi)
	else:
		_log("%s calls %s%s." % [p.player_name, card.card_name(), " without paying for it" if free else ""], pi)
	await _fx("fx_call", [t])
	if t.has_keyword("channel"):
		p.essence += 1
		_log("%s channels 1 Essence." % t.card_name(), pi)
	var n := t.attuned_value("draw")
	if n > 0:
		var drawn := await _draw(p, n)
		if not drawn.is_empty():
			await _fx("fx_draw", [pi, drawn])
	await _window(pi, {"type": "call", "called": t})
	if over:
		return
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
	elif int(story_rules.get("patter", -1)) == pi:
		face_up[card.uid] = true   # Patter: he can't keep a secret
		_log("%s sets %s face up." % [p.player_name, card.card_name()], pi)
	else:
		_log("%s sets a Ward face down." % p.player_name, pi)
	await _fx("fx_ward_set", [pi, card])
	await _window(pi, {"type": "ward", "card": card})


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
	var licensed := card.cost() > 0 and rule_licensed(pi)
	_spend(p, rite_cost(pi, card))
	p.hand.erase(card)
	p.stats.rites += 1
	p.note_played(card.id)
	var tname := ""
	if target is DuelTotem:
		tname = " on %s" % target.card_name()
	_log("%s casts %s%s." % [p.player_name, card.card_name(), tname], pi)
	if licensed:
		_log("Licensed: it costs %s nothing." % p.player_name, pi)
		await _fx("fx_rule", [pi, "licensed"])
	await _fx("fx_rite", [pi, card, target])
	var ans := await _window(pi, {"type": "rite", "card": card, "target": target, "by": pi})
	if over:
		return
	if ans.bounced:
		_log("%s is swept back into %s hand, undone." % [card.card_name(), whose(p.player_name, true)], pi)
		p.hand.append(card)
		return
	if ans.negated:
		_log("%s is cancelled!" % card.card_name(), pi)
		p.discard.append(card)
		return
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
	if bool(d.get("continuous", false)):
		await _stand_continuous(pi, card)
	else:
		p.discard.append(card)
	await _resolve_knockouts()


# ------------------------------------------------- continuous rites (Phase D) ---

## A Continuous Rite takes its place on its side; with the slots full, the
## oldest goes to the discard.
func _stand_continuous(pi: int, card: DuelCard) -> void:
	var p: DuelPlayer = players[pi]
	if p.continuous.size() >= DuelRules.continuous_slots:
		await _remove_continuous(pi, p.continuous[0], "replaced")
	p.continuous.append(card)
	p.stats.continuous += 1
	_log("%s stands on %s side of the Circle." % [card.card_name(), whose(p.player_name, true)], pi)
	await _fx("fx_continuous", [pi, card, false])


func _remove_continuous(pi: int, card: DuelCard, why: String) -> void:
	var p: DuelPlayer = players[pi]
	if not p.continuous.has(card):
		return
	p.continuous.erase(card)
	p.discard.append(card)
	_log("%s is %s." % [card.card_name(), why], pi)
	await _fx("fx_continuous", [pi, card, true])


## Whether a standing Rite on `pi`'s side does this ({} if none does).
func standing(pi: int, key: String) -> Dictionary:
	for c in players[pi].continuous:
		var st: Dictionary = (c as DuelCard).def.get("standing", {})
		if st.has(key):
			return st
	return {}


## A way's card (Phase E) works only with one of its Totems on your side.
func archetype_problem(pi: int, card: DuelCard) -> String:
	var a := String(card.def.get("archetype", ""))
	if a == "" or DuelArchetypes.has_need(self, pi, a):
		return ""
	return "%s needs %s of yours on the field." % [card.card_name(), DuelArchetypes.need_text(a)]


## Basic Totems in `pi`'s hand Venom Mask could call (tier `max_tier` or lower,
## no Tribute).
func _veil_callable(pi: int, max_tier: int) -> Array:
	return players[pi].hand.filter(func(c): return (c as DuelCard).is_basic_totem() and (c as DuelCard).tier() <= max_tier and tributes_needed(c) == 0)


## Shadow Veil: the first Totem each turn may be called veiled at no extra cost.
func free_veil(pi: int) -> bool:
	return not standing(pi, "free_veil").is_empty() and players[pi].totems_called == 0


# ---------------------------------------------------------- favour (Phase D) ---

## The element that fills `pi`'s Favour: their god's ("" for the Unsworn, who
## fill it from any element, at half pace).
func favour_element(pi: int) -> String:
	var g: String = (players[pi] as DuelPlayer).patron()
	if g == "" or not Lore.GODS.has(g):
		return ""
	return String(Lore.GODS[g].element)


## Each god's way, by the god's attribute: the actions that fill Favour as
## well as the god's element does (Phase D).
## (In half points a time: the rarer the action, the more it fills.)
const WAYS := {"presence": {"call": 3, "summon": 4}, "might": {"attack": 2}, "resolve": {"stance": 6, "ward": 6},
	"swiftness": {"shift": 2, "attack": 1}, "cunning": {"ward": 6, "rite": 4}, "insight": {"rite": 2, "ascend": 4},
	"intellect": {"rite": 5, "relic": 6}}
const WAY_WORDS := {"call": "calling Totems", "summon": "Summons", "attack": "attacking", "stance": "taking stances",
	"ward": "setting Wards", "shift": "shifting", "rite": "casting Rites", "ascend": "Ascending", "relic": "giving Relics"}


func favour_way(pi: int) -> Dictionary:
	var g: String = (players[pi] as DuelPlayer).patron()
	if g == "" or not Lore.GODS.has(g):
		return {}
	return WAYS.get(String(Lore.GODS[g].get("attribute", "")), {})


## How Favour fills for `pi`, in words.
func favour_text(pi: int) -> String:
	var el := favour_element(pi)
	if el == "":
		return "Favour fills a little with every card you play and every attack, from any element."
	var ways := []
	for w in favour_way(pi).keys():
		ways.append(String(WAY_WORDS.get(w, w)))
	return "Favour fills when you play %s cards, attack with %s Totems, or follow %s's way: %s.%s" % [
		el.capitalize(), el.capitalize(), Lore.GODS[(players[pi] as DuelPlayer).patron()].name, " and ".join(ways),
		" Under %s's own Law, twice as fast." % Lore.GODS[(players[pi] as DuelPlayer).patron()].name if law == (players[pi] as DuelPlayer).patron() else ""]


## The Demigod Summon of `pi`'s god (by its element), "" if it has none.
func demigod_of(pi: int) -> String:
	var el := favour_element(pi)
	if el == "":
		return ""
	for id in DuelCards.CARDS:
		var d: Dictionary = DuelCards.CARDS[id]
		if d.kind == "summon" and String(d.get("element", "")) == el:
			return id
	return ""


## What full Favour opens, in words.
func favour_offer_text(pi: int) -> String:
	var dg := demigod_of(pi)
	var gift_word := "Unbound Will, stronger" if players[pi].patron() == "" else "a second %s" % Lore.GIFTS[players[pi].gift()].name
	if dg != "":
		return "%s, or %s free" % [gift_word, DuelCards.CARDS[dg].name]
	return gift_word


## After an action: playing your god's element fills your Favour (the Law's
## own god's, double; the Unsworn, from anything at half pace).
func _favour_after(pi: int, action: Dictionary) -> void:
	var p: DuelPlayer = players[pi]
	if p.favour_ready or not puzzle.is_empty():
		return
	var el := ""
	var kind := String(action.get("type", ""))
	match kind:
		"call", "ascend", "rite", "summon", "relic", "ward":
			var c = action.get("card")
			if c is DuelCard:
				el = (c as DuelCard).element()
		"attack":
			var t = action.get("attacker")
			if t is DuelTotem:
				el = (t as DuelTotem).element()
	var want := favour_element(pi)
	var gain := 0
	if want == "":
		gain = 1 if el != "" and el != "any" else 0   # (the Unsworn: anything, at half pace)
	else:
		if el == want:
			gain += 2
		gain += int(favour_way(pi).get(kind, 0))
		if law == p.patron():
			gain *= 2   # (the Law's own god: twice as fast)
	await _add_favour(p, gain)


func _add_favour(p: DuelPlayer, half_points: int) -> void:
	if p.favour_ready or half_points <= 0:
		return
	p.favour2 = mini(DuelRules.favour_max * 2, p.favour2 + half_points)
	if p.favour2 >= DuelRules.favour_max * 2:
		p.favour_ready = true
		p.stats.favour_fills += 1
		_log("%s Favour is full: %s." % [whose(p.player_name), favour_offer_text(p.index)], p.index)
		await _fx("fx_favour", [p.index, true])


func _spend_favour(p: DuelPlayer) -> void:
	p.favour2 = 0
	p.favour_ready = false


func demigod_problem(pi: int, target = null) -> String:
	var p: DuelPlayer = players[pi]
	if not p.favour_ready:
		return "Your Favour isn't full."
	var id := demigod_of(pi)
	if id == "":
		return "Your god has no Demigod to send." if p.patron() != "" else "The Unsworn have no Demigod."
	if String(DuelCards.CARDS[id].move.get("target", "foe_totem")) == "foe_totem":
		var ts := targetable(opponent(pi).totems())
		if ts.is_empty():
			return "There's no enemy Totem to strike."
		if target != null and not ts.has(target):
			return "Not a valid target."
	return ""


## Full Favour, spent on the god's Demigod: it comes down free, from no card
## (nothing to answer, no Ward to spring), strikes and goes back.
func _act_demigod(pi: int, target) -> void:
	var p: DuelPlayer = players[pi]
	var id := demigod_of(pi)
	_spend_favour(p)
	p.stats.demigods += 1
	var card := DuelCard.new(-100 - pi * 10 - int(p.stats.demigods), id, pi)   # (from no deck: on no pile)
	_log("%s Favour brings %s down from the heavens!" % [whose(p.player_name), card.card_name()], pi)
	await _summon_strike(pi, card, target)
	_log("%s returns to the heavens." % card.card_name(), pi)
	await _resolve_knockouts()


# ----------------------------------------------------------- oaths (Phase D) ---

## An Oath's words.
func oath_text(id: String, pi: int = -1) -> String:
	match id:
		"swift":
			return "Win by your %s turn." % ["", "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth"][clampi(DuelRules.oath_turns, 1, 12)]
		"faith":
			var el := favour_element(pi) if pi >= 0 else ""
			return "Win with a %s Totem on your side of the field." % el.capitalize() if el != "" else "Win with a Totem of your god's element on your side of the field."
		"unbowed":
			return "Never let your Life fall under half."
	return ""


func own_turns(pi: int) -> int:
	return DuelRewards.turns_taken(self, pi)


func oath_problem(pi: int, id: String) -> String:
	if not OATHS.has(id):
		return "There's no such Oath."
	if not puzzle.is_empty():
		return "The mirrors take no Oaths."
	var p: DuelPlayer = players[pi]
	if p.oath_state == "sworn":
		return "You're already bound by an Oath."
	var start := own_turns(pi) <= 1
	if start and p.oath_start_used:
		return "You've sworn your Oath for the start of the duel."
	if not start and p.oath_mid_used:
		return "You've sworn your Oath for this duel."
	match id:
		"faith":
			if favour_element(pi) == "":
				return "The Unsworn have no god's element to swear by."
		"swift":
			if own_turns(pi) >= DuelRules.oath_turns:
				return "It's too late in the duel for that Oath."
		"unbowed":
			if p.life * 2 < p.max_life:
				return "Your Life is already under half."
	return ""


func _act_oath(pi: int, id: String) -> void:
	var p: DuelPlayer = players[pi]
	if own_turns(pi) <= 1:
		p.oath_start_used = true
	else:
		p.oath_mid_used = true
	p.oath = id
	p.oath_state = "sworn"
	p.stats.oaths += 1
	_log("%s swears the %s: %s" % [p.player_name, OATHS[id].name, oath_text(id, pi)], pi)
	await _fx("fx_oath", [pi, id, "sworn"])
	await _add_favour(p, DuelRules.oath_favour * 2)


## Oaths that can break at any moment (the Unbowed's Life).
func _check_oaths() -> void:
	for p in players:
		if over:
			return
		if p.oath_state == "sworn" and p.oath == "unbowed" and p.life * 2 < p.max_life:
			await _break_oath(p)


## The Swift End breaks at the Dusk of the turn it named, if the duel goes on.
func _oath_dusk(p: DuelPlayer) -> void:
	if over:
		return
	await _check_oaths()
	if not over and p.oath_state == "sworn" and p.oath == "swift" and own_turns(p.index) >= DuelRules.oath_turns:
		await _break_oath(p)


func _break_oath(p: DuelPlayer) -> void:
	p.oath_state = "broken"
	p.stats.oaths_broken += 1
	_log("%s breaks the %s, and it costs %d Life." % [p.player_name, OATHS[p.oath].name, DuelRules.oath_life_cost], p.index)
	await _fx("fx_oath", [p.index, p.oath, "broken"])
	await _hit_life(p.index, DuelRules.oath_life_cost, {"no_guard": true, "source": "oath"})


## At the end: the winner's Oath is kept or broken (the loser's no longer matters).
func _settle_oaths(w: int) -> void:
	if w < 0 or w > 1:
		return
	var p: DuelPlayer = players[w]
	if p.oath_state != "sworn":
		return
	var kept := true
	match p.oath:
		"swift":
			kept = own_turns(w) <= DuelRules.oath_turns
		"faith":
			kept = p.totems().any(func(t): return (t as DuelTotem).element() == favour_element(w))
		"unbowed":
			kept = p.life * 2 >= p.max_life
	p.oath_state = "kept" if kept else "broken"
	p.stats["oaths_kept" if kept else "oaths_broken"] += 1
	_log("%s %s the %s." % [p.player_name, "keeps" if kept else "breaks", OATHS[p.oath].name], w)


## Standing Rites that act at their owner's Dawn.
func _dawn_continuous(p: DuelPlayer) -> void:
	var st := standing(p.index, "dawn_heal")
	if not st.is_empty():
		for t in p.totems():
			if t.damage > 0:
				await _heal(t, int(st.dawn_heal))


# ---------------------------------------------------------------- attacks ---

## The damage a move would do to `defn` (null = Life), before shields and Guard.
func attack_amount(att: DuelTotem, i: int, base: int, defn, effects: Array = []) -> int:
	if base <= 0:
		return 0
	var amt := base + att.damage_bonus(i)
	var ed := standing(att.owner, "element_damage")
	if not ed.is_empty() and att.element() == String(ed.element):
		amt += int(ed.amount)
	if defn is DuelTotem and (defn as DuelTotem).has_status("frozen"):
		amt += int(standing(att.owner, "frozen_extra").get("frozen_extra", 0))   # (Deep Winter)
	if players[att.owner].wrath:
		amt += DuelRules.wrath_bonus
	if rule_scrapper(att.owner):
		amt += SCRAPPER_BONUS
	amt += run_to_ground_bonus(att.owner)
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
	if mv.has("bond"):
		p.stats.bond_moves += 1
	_spend(p, t.move_cost(i))
	t.attacked = true
	if t.boons.has("veiled"):
		t.remove_boon("veiled")
	if t.face_down:
		await _reveal(t, "attacks")
	if target is DuelTotem and target.face_down:
		await _reveal(target, "attacked")
	if over or t.is_knocked_out():
		await _after_attack(t)
		return
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

	# the response window: the defender's answers, before anything lands
	var tk := t.move_target(i)
	var hostile := tk == "foe" or tk == "foe_totem" or tk == "all_foes"
	var halved := false
	var blunt := 0   # (Counterweight, Phase E)
	if hostile:
		var ans := await _window(pi, {"type": "attack", "attacker": t, "move": mv, "index": i, "target": target})
		if over:
			return
		if ans.negated or t.is_knocked_out():
			_log("The attack is cancelled.", pi)
			await _after_attack(t)
			return
		halved = ans.halved
		blunt = int(ans.get("blunt", 0))
		if t.is_knocked_out():
			await _after_attack(t)
			return
		if not _same_target(ans.target, target):
			target = ans.target
			if target is String and target == NONE:
				_log("%s strikes at empty air." % t.card_name(), pi)
				await _after_attack(t)
				return
			if target is DuelTotem:
				_log("The blow falls on %s instead." % target.card_name(), pi)
	# the defender's Wards
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
	if base > 0 and hostile and rule_scrapper(pi):
		_log("%s is behind, and scrapping: +%d." % [p.player_name, SCRAPPER_BONUS], pi)
		await _fx("fx_rule", [pi, "scrapper"])

	if target is String and target == LIFE:
		var amt := attack_amount(t, i, base, null) - int(res.reduce_life)
		if halved:
			amt = _half(amt)
		amt -= blunt
		if amt > 0:
			if res.blocked_life:
				_log("The Ward blocks the hit on %s Life." % whose(foe.player_name, true), pi)
			else:
				dealt = await _hit_life(1 - pi, amt, {"attacker": t, "pierce": pierce})
	elif tk == "all_foes":
		for f in foe.totems():
			var amt := attack_amount(t, i, base, f, effects)
			if halved:
				amt = _half(amt)
			amt -= blunt
			if amt > 0:
				dealt += await _damage_totem(f, amt, {"attacker": t, "spill": true, "pierce": pierce, "element": t.element()})
			for e in effects:
				if e.op == "status":
					await _apply_status(f, e.status, t)
		effects = effects.filter(func(e): return e.op != "status")
	elif target is DuelTotem and target.owner != pi:
		var amt := attack_amount(t, i, base, target, effects)
		if halved:
			amt = _half(amt)
		amt -= blunt
		if amt > 0:
			dealt = await _damage_totem(target, amt, {"attacker": t, "spill": true, "pierce": pierce, "element": t.element()})
			if target.has_keyword("thorns") and not t.is_knocked_out():
				_log("%s is pricked by thorns." % t.card_name(), pi)
				await _damage_totem(t, DuelRules.thorns_damage, {"source": "thorns", "attacker": target})
			var hedge := standing(target.owner, "thorn_all")
			if not hedge.is_empty() and not t.is_knocked_out():
				_log("The hedge tears at %s." % t.card_name(), pi)
				await _damage_totem(t, int(hedge.amount), {"source": "thorns"})
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
	var ans := await _window(pi, {"type": "rite", "card": card, "target": target, "by": pi, "summon": true})
	if over:
		return
	if ans.bounced:
		_log("%s is turned back before it can descend." % card.card_name(), pi)
		p.hand.append(card)
		return
	if ans.negated:
		_log("%s is sealed away before it can strike!" % card.card_name(), pi)
		p.spent.append(card)
		return
	var res := await _spring_wards(1 - pi, "foe_rite", {"card": card})
	if res.cancel_rite:
		_log("%s is sealed away before it can strike!" % card.card_name(), pi)
		p.spent.append(card)
		return
	await _summon_strike(pi, card, target)
	p.spent.append(card)
	_log("%s returns to the heavens." % card.card_name(), pi)
	await _resolve_knockouts()


## A Summon's descent and its one great blow.
func _summon_strike(pi: int, card: DuelCard, target) -> void:
	var mv: Dictionary = card.def.move
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


# ------------------------------------------------------------------ gifts ---

func _act_gift(pi: int, target) -> void:
	var p: DuelPlayer = players[pi]
	var foe := opponent(pi)
	var g := p.gift()
	var by_favour := p.gift_used   # (the Gift is spent: this one is the Favour's, Phase D)
	p.gift_used = true
	if by_favour:
		_spend_favour(p)
		_log("Favour opens the way again.", pi)
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
			# (full Favour makes Unbound Will stronger: three cards and an Essence)
			var drawn := await _draw(p, 3 if by_favour else 2)
			if not drawn.is_empty():
				await _fx("fx_draw", [pi, drawn])
			if by_favour:
				p.essence += 1
				_log("%s Unbound Will runs strong: 1 Essence more." % whose(p.player_name), pi)
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
	_drop_relic(t, false)
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
			"revive_hand":
				var opts := _revivable(pi, 99)
				if not opts.is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Bring a Totem back from your discard to your hand.", opts, 1, 1, {"reason": "revive"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					p.discard.erase(c)
					p.hand.append(c)
					p.stats.revivals += 1
					_log("%s takes %s back from the discard." % [p.player_name, c.card_name()], pi)
					await _fx("fx_revive", [pi, c])
			"revive_field":
				var opts := _revivable(pi, int(e.get("max_tier", 2)))
				if not opts.is_empty() and not p.empty_slots().is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Bring a Totem back to the field.", opts, 1, 1, {"reason": "revive_field"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					var slots := p.empty_slots()
					var sl: int = slots[0]
					if slots.size() > 1:
						sl = await p.controller.choose_slot(self, pi, "Where does %s come back?" % c.card_name(), slots, {"reason": "revive"})
						if not slots.has(sl):
							sl = slots[0]
					await _revive_to_field(pi, c, sl, "%s rises again from the discard." % c.card_name())
			"call_legend_free":
				var opts := _legends_in_hand(pi)
				if not opts.is_empty() and not p.empty_slots().is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Call a Legend, free.", opts, 1, 1, {"reason": "legend"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					var slots := p.empty_slots()
					var sl: int = slots[0]
					if slots.size() > 1:
						sl = await p.controller.choose_slot(self, pi, "Where does %s stand?" % c.card_name(), slots, {"reason": "legend"})
						if not slots.has(sl):
							sl = slots[0]
					await _act_call(pi, c, sl, [], true)
			"seek_kindred":
				var opts := _kindred(pi)
				if not opts.is_empty():
					await _fx("fx_search", [pi, opts])
					var pick: Array = await p.controller.choose_cards(self, pi, "Search your deck for a Totem of your Totems' elements.", opts, 1, 1, {"reason": "search"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					p.deck.erase(c)
					p.hand.append(c)
					_shuffle(p.deck)
					_log("%s finds %s, and shuffles the deck." % [p.player_name, c.card_name()], pi)
					await _fx("fx_draw", [pi, [c]])
			"discard_to_top":
				if not p.discard.is_empty():
					var opts: Array = p.discard.duplicate()
					var pick: Array = await p.controller.choose_cards(self, pi, "Put a card from your discard on top of your deck.", opts, 1, 1, {"reason": "to_top"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					p.discard.erase(c)
					p.deck.append(c)   # (the top of the deck is the end of the list)
					_log("%s puts %s on top of the deck." % [p.player_name, c.card_name()], pi)
			"terrain":
				var was := arena_now()
				terrain = {"arena": String(e.arena), "left": DuelRules.terrain_turns, "by": pi}
				_refresh_arena_guard()
				p.stats.terrains += 1
				_log("The ground turns: %s for %d turns." % [String(e.arena).capitalize(), DuelRules.terrain_turns], pi)
				await _fx("fx_terrain", [String(e.arena), "rite" if was != String(e.arena) else "renew"])
			"burned_damage":
				for f in foe.totems():
					if (f as DuelTotem).has_status("burn"):
						await _damage_totem(f, int(e.amount), {"spill": true, "element": "fire", "source": "rite"})
			"fate_bonus":
				p.fate_bonus += int(e.amount)
				_log("%s Fate rolls are %d higher this turn." % [whose(p.player_name), int(e.amount)], pi)
			"shield_unhurt":
				for t in p.totems():
					if (t as DuelTotem).damage == 0:
						t.shield += int(e.amount)
						_log("%s is shielded." % t.card_name(), pi)
			"draw_full":
				var n := 0
				for t in p.totems():
					if (t as DuelTotem).damage == 0:
						n += 1
				n = mini(n, int(e.get("max", 2)))
				if n > 0:
					var drawn := await _draw(p, n)
					if not drawn.is_empty():
						await _fx("fx_draw", [pi, drawn])
			"guard_strike":
				if target is DuelTotem:
					var amt := p.guard() * int(e.get("mult", 2))
					_log("%s patience breaks: %d damage." % [whose(p.player_name), amt], pi)
					await _damage_totem(target, amt, {"spill": true, "element": "earth"})
			"reveal_twice":
				for t in p.totems():
					if (t as DuelTotem).face_down:
						await _reveal(t, "rite")
						await _reveal_effect(t)   # (the second time)
			"veil_call_free":
				var opts: Array = _veil_callable(pi, int(e.get("max_tier", 2)))
				if not opts.is_empty() and not p.empty_slots().is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Call one face down, free.", opts, 1, 1, {"reason": "veil_call"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					var slots: Array = p.empty_slots()
					var slot: int = await p.controller.choose_slot(self, pi, "Where does it go?", slots, {"reason": "call", "card": c})
					if not slots.has(slot):
						slot = slots[0]
					await _act_call(pi, c, slot, [], true, true)
			"pick_top":
				var top: Array = p.deck.slice(maxi(0, p.deck.size() - int(e.get("count", 3))))
				top.reverse()
				if not top.is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Put one in your hand.", top, 1, 1, {"reason": "search"})
					var c: DuelCard = pick[0] if not pick.is_empty() and top.has(pick[0]) else top[0]
					p.deck.erase(c)
					p.hand.append(c)
					_log("%s reads the stars and takes %s." % [p.player_name, c.card_name()], pi)
			"unbind":
				var opts: Array = opponent(pi).continuous.duplicate()
				if not opts.is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Unbind one of their standing Rites.", opts, 1, 1, {"reason": "unbind"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					await _remove_continuous(1 - pi, c, "unbound")
			"relic_hunt":
				var opts: Array = p.discard.filter(func(c): return (c as DuelCard).kind() == "relic")
				if not opts.is_empty():
					var pick: Array = await p.controller.choose_cards(self, pi, "Take a Relic back from your discard.", opts, 1, 1, {"reason": "revive"})
					var c: DuelCard = pick[0] if not pick.is_empty() and opts.has(pick[0]) else opts[0]
					p.discard.erase(c)
					p.hand.append(c)
					_log("%s takes the %s back." % [p.player_name, c.card_name()], pi)
					await _fx("fx_draw", [pi, [c]])
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
	if rule_discipline(t, status):
		_log("%s holds its discipline: it can't be %s." % [t.card_name(), DuelConditions.display_name(status)], t.owner)
		await _fx("fx_rule", [t.owner, "discipline"])
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
	_drop_relic(t, true)
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
	var guarded := 0
	if t.stance == "guard" and amount > 0 and not String(info.get("source", "")) in ["burn", "poison", "bleed", "curse", "doom", "recoil", "heat"]:
		guarded = amount - _half(amount)
		guarded = mini(amount, guarded + int(standing(t.owner, "guard_less").get("guard_less", 0)))   # (Bastion Banner)
		amount -= guarded
		if guarded > 0:
			_log("%s guards: %d turned aside." % [t.card_name(), guarded], t.owner)
	var before := t.hp_left()
	if int(totem_floor[t.owner]) > 0:
		amount = mini(amount, maxi(0, before - int(totem_floor[t.owner])))
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
	await _fx("fx_totem_hit", [t, amount, info.merged({"absorbed": absorbed, "guarded": guarded})])
	if amount > 0 and info.get("attacker") != null and String(info.get("source", "")) == "":
		await _on_hit(t, info.get("attacker"))
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
	if int(life_floor[pi]) > 0 and p.life < int(life_floor[pi]):
		p.life = int(life_floor[pi])
	if info.get("attacker") != null or info.get("spill", false):
		players[1 - pi].stats.life_damage_dealt += amt
	_log("%s loses %d Life (%d left)." % [p.player_name, amt, maxi(0, p.life)], pi)
	await _fx("fx_life_hit", [pi, amt, info])
	await _rule_sunspire_mirror_check(pi)
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
	var hl := int(standing(t.owner, "heal_life").get("heal_life", 0))
	if hl > 0:
		# (Tidal Reserve)
		var po: DuelPlayer = players[t.owner]
		var gain := mini(hl, po.max_life - po.life)
		if gain > 0:
			po.life += gain
			_log("The reserve fills: %s gains %d Life." % [po.player_name, gain], t.owner)
			await _fx("fx_life_gain", [t.owner, gain])


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
				if not t.is_knocked_out() or not p.totems().has(t):
					continue   # (one already taken off the field by a knockout resolved inside this one: a Loyal call, an Echo)
				found = true
				p.slots[t.slot] = null
				p.fallen.append(t.stage())
				for c in t.stack:
					p.discard.append(c)
				var fall_draw: int = int(t.relic_def().get("fall_draw", 0))
				_drop_relic(t, false)
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
				await _after_fall(pi, t, alive_killer)
				if over:
					return
				if fall_draw > 0:
					var drawn := await _draw(p, fall_draw)
					_log("%s's lantern lights the way: %s draws %d." % [t.card_name(), p.player_name, drawn.size()], pi)
					if not drawn.is_empty():
						await _fx("fx_draw", [pi, drawn])
		if not found:
			return


# ======================================================== the discard ===
# Phase B: what a duellist's fallen Totems still do.

## A Totem of `pi`'s has fallen: a Loyal Totem in the hand calls itself into
## the empty slot, free; then each Echo in the discard (not the fallen
## Totem's own cards) answers, once a duel each.
func _after_fall(pi: int, fallen: DuelTotem, killer) -> void:
	var p: DuelPlayer = players[pi]
	var fl := int(standing(pi, "fall_life").get("fall_life", 0))
	if fl > 0 and not over:
		# (Lantern Vigil)
		var gain := mini(fl, p.max_life - p.life)
		if gain > 0:
			p.life += gain
			await _fx("fx_life_gain", [pi, gain])
		var dr := await _draw(p, 1)
		_log("A lantern is lit for %s: %s gains %d Life and draws a card." % [fallen.card_name(), p.player_name, gain], pi)
		if not dr.is_empty():
			await _fx("fx_draw", [pi, dr])
	if p.slots[fallen.slot] == null:
		for c in p.hand.duplicate():
			if (c as DuelCard).is_basic_totem() and (c.def.get("keywords", []) as Array).has("loyal"):
				_log("%s answers the fall: it calls itself to the empty slot!" % c.card_name(), pi)
				await _act_call(pi, c, fallen.slot, [], true)
				break
	for c in p.discard.duplicate():
		if over:
			return
		var card: DuelCard = c
		if not card.is_totem() or not card.def.has("echo") or fallen.stack.has(card):
			continue
		var key := "echo:%d" % card.uid
		if p.once_used.has(key):
			continue
		var e: Dictionary = card.def.echo
		if String(e.get("when", "ally_falls")) != "ally_falls":
			continue
		if e.op in ["damage_attacker", "status_attacker"] and killer == null:
			continue
		p.once_used.append(key)
		p.stats.echoes += 1
		_log("%s Echo, from the discard: %s." % [whose(card.card_name()), DuelCards.echo_text(card.def).trim_suffix(".")], pi)
		await _fx("fx_echo", [pi, card])
		match String(e.op):
			"damage_attacker":
				await _damage_totem(killer, int(e.amount), {"source": "echo"})
			"status_attacker":
				await _apply_status(killer, String(e.status), null, pi)
			"heal_weakest":
				var w: DuelTotem = null
				for t in p.totems():
					if t.damage > 0 and (w == null or t.hp_left() < w.hp_left()):
						w = t
				if w != null:
					await _heal(w, int(e.amount))
			"shield_one":
				var best: DuelTotem = null
				for t in p.totems():
					if best == null or t.hp_left() < best.hp_left():
						best = t
				if best != null:
					best.shield += int(e.amount)
					_log("%s is shielded (%d)." % [best.card_name(), best.shield], pi)
			"essence_next":
				p.pending_essence += int(e.amount)


## At its owner's Dawn: Relics that mend or shield do it, and every Totem
## called veiled is revealed (Phase C).
func _dawn_relics_and_veils(p: DuelPlayer) -> void:
	for t in p.totems():
		var rd: Dictionary = t.relic_def()
		if int(rd.get("dawn_heal", 0)) > 0 and t.damage > 0:
			await _heal(t, int(rd.dawn_heal))
		if int(rd.get("dawn_shield", 0)) > 0:
			t.shield = maxi(t.shield, int(rd.dawn_shield))
			_log("%s's %s shields it (%d)." % [t.card_name(), t.relic.card_name(), t.shield], p.index)
	for t in p.totems():
		if t.face_down:
			await _reveal(t, "dawn")


## A veiled Totem turns face up (it attacks, it's attacked, or its owner's
## Dawn comes); a Reveal on its card happens now.
func _reveal(t: DuelTotem, why: String) -> void:
	if not t.face_down:
		return
	t.face_down = false
	var p: DuelPlayer = players[t.owner]
	_log("%s's veiled Totem is revealed: %s!" % [p.player_name, t.card_name()], t.owner)
	await _fx("fx_reveal", [t])
	if not standing(t.owner, "reveal_draw").is_empty():
		# (Whispering Shroud)
		var dr := await _draw(p, 1)
		if not dr.is_empty():
			await _fx("fx_draw", [t.owner, dr])
	await _reveal_effect(t)


## A revealed Totem's Reveal, if it has one.
func _reveal_effect(t: DuelTotem) -> void:
	var p: DuelPlayer = players[t.owner]
	var rv: Dictionary = t.def().get("reveal", {})
	if rv.is_empty() or t.is_knocked_out():
		return
	var foe := opponent(t.owner)
	var across = foe.slots[t.slot]
	match String(rv.get("op", "")):
		"status_across":
			if across != null:
				await _apply_status(across, String(rv.status), t, t.owner)
		"damage_across":
			if across != null:
				await _damage_totem(across, int(rv.amount), {"source": "reveal", "attacker": t, "element": t.element()})
		"draw":
			var drawn := await _draw(p, int(rv.get("count", 1)))
			if not drawn.is_empty():
				await _fx("fx_draw", [t.owner, drawn])
		"heal_allies":
			for a in p.totems():
				await _heal(a, int(rv.amount))
	await _resolve_knockouts()


## At its owner's Dawn, a Rekindling Totem in the discard comes back to an
## empty slot with half its HP, once a duel.
func _dawn_rekindle(p: DuelPlayer) -> void:
	if p.empty_slots().is_empty():
		return
	for c in p.discard.duplicate():
		var card: DuelCard = c
		if not card.is_basic_totem() or not (card.def.get("keywords", []) as Array).has("rekindle"):
			continue
		var key := "rekindle:%d" % card.uid
		if p.once_used.has(key):
			continue
		p.once_used.append(key)
		await _revive_to_field(p.index, card, p.empty_slots()[0], "%s rekindles from the ashes!" % card.card_name())
		return


## A Totem card from the discard back into a slot, with DuelRules.revive_hp of
## its HP (Rekindle, the Rekindling keyword).
func _revive_to_field(pi: int, card: DuelCard, slot: int, line: String) -> void:
	var p: DuelPlayer = players[pi]
	p.discard.erase(card)
	var t := _new_totem(card, pi, slot, turn)
	t.damage = t.max_hp() - maxi(10, int(round(t.max_hp() * DuelRules.revive_hp / 10.0)) * 10)
	p.slots[slot] = t
	p.stats.revivals += 1
	_log(line, pi)
	await _fx("fx_revive", [pi, card])
	await _fx("fx_call", [t])


## A Totem hit by an attack that's still standing: Riposte confuses the
## attacker, Galvanise empowers it.
func _on_hit(t: DuelTotem, attacker) -> void:
	if t.is_knocked_out():
		return
	if t.has_keyword("riposte") and attacker is DuelTotem and not attacker.is_knocked_out() and attacker.owner != t.owner:
		_log("%s ripostes!" % t.card_name(), t.owner)
		await _apply_status(attacker, "confused", t, t.owner)
	if t.has_keyword("galvanise") and not t.has_boon("empowered"):
		_log("The blow galvanises %s." % t.card_name(), t.owner)
		await _give_boon(t, "empowered")


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
		if trigger != "lethal":
			var ans := await _window(owner_pi, {"type": "ward_spring", "card": w, "ctx": ctx, "by": owner_pi})
			if over:
				return res
			if ans.negated:
				_log("%s fizzles: its spring is cancelled." % w.card_name(), owner_pi)
				break
		await _apply_ward_effects(w, owner_pi, ctx, res)
		break
	return res


## What a Ward does when it springs (from its slot, or played from the hand
## in answer).
func _apply_ward_effects(w: DuelCard, owner_pi: int, ctx: Dictionary, res: Dictionary) -> void:
	var p: DuelPlayer = players[owner_pi]
	if arena_now() == "emberforge":
		var caught = ctx.get("attacker") if ctx.get("attacker") is DuelTotem else ctx.get("called")
		if caught is DuelTotem and not caught.is_knocked_out():
			_log("The forge's heat catches %s as the Ward springs." % caught.card_name(), owner_pi)
			await _apply_status(caught, "burn", null, owner_pi)
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


# ============================================================ answers ===
# Phase A: a Rite marked "answer" is played only on the rival's turn, in
# answer to what they do (its "answers": attack, rite, call, ward,
# ward_spring); a Ward marked "from_hand" can be played from the hand in
# answer to its trigger, once a duel. The response window opens after an
# action is declared and before it resolves.

## The cards in `pi`'s hand that answer this event; with `affordable_only`
## false, those they can't pay for too (the screen shows them greyed).
func answers_for(pi: int, event: Dictionary, affordable_only := true) -> Array:
	var out := []
	for c in players[pi].hand:
		if not answer_fits(c, event):
			continue
		if affordable_only and answer_problem(pi, c, event) != "":
			continue
		out.append(c)
	return out


## Whether this card is an answer to this kind of event at all.
func answer_fits(c: DuelCard, event: Dictionary) -> bool:
	var kind := String(event.get("type", ""))
	if c.is_rite() and bool(c.def.get("answer", false)):
		return (c.def.get("answers", []) as Array).has(kind)
	if c.is_ward() and bool(c.def.get("from_hand", false)):
		return String(WARD_EVENTS.get(c.def.trigger, "")) == kind
	return false


## Why this card can't answer this event right now ("" if it can).
func answer_problem(pi: int, c: DuelCard, event: Dictionary) -> String:
	var p: DuelPlayer = players[pi]
	if c == null or not p.hand.has(c):
		return "That card isn't in your hand."
	if not answer_fits(c, event):
		return "%s doesn't answer this." % c.card_name()
	var ap := archetype_problem(pi, c)
	if ap != "":
		return ap
	var cost := card_cost(pi, c) if c.is_ward() else rite_cost(pi, c)
	if c.is_ward():
		if p.hand_wards_used.has(c.id):
			return "%s has been played from the hand once this duel already." % c.card_name()
		if c.def.trigger == "foe_direct" and not (event.get("target") is String and event.get("target") == LIFE):
			return "%s answers an attack on your Life." % c.card_name()
	if cost > p.essence:
		return "Needs %d Essence." % cost
	for e in c.def.get("effects", []):
		match e.op:
			"redirect_guardian":
				if _guardian_of(pi, event.get("target")) == null:
					return "You need a Guardian standing, apart from the one attacked."
				if not (event.get("target") is DuelTotem):
					return "It turns a blow at one of your Totems."
			"sidestep":
				var tg = event.get("target")
				if not (tg is DuelTotem) or tg.owner != pi:
					return "It answers an attack on one of your Totems."
				for id in ["frozen", "rooted", "possessed"]:
					if tg.has_status(id):
						return "%s is %s and can't move." % [tg.card_name(), DuelConditions.display_name(id)]
			"cancel_ward":
				if String(event.get("type", "")) != "ward_spring":
					return "It answers a Ward as it springs."
	return ""


## "an enemy Totem attacks, or your opponent casts a Rite": when a card answers.
static func answers_text(c: DuelCard) -> String:
	var kinds: Array = c.def.get("answers", [])
	if c.is_ward():
		kinds = [WARD_EVENTS.get(c.def.trigger, "")]
	var parts := []
	for k in kinds:
		parts.append(String(EVENT_TEXT.get(k, k)))
	return " or ".join(parts)


## Basic Totem cards in `pi`'s discard of this tier or lower (for a revival).
func _revivable(pi: int, max_tier: int) -> Array:
	var out := []
	for c in players[pi].discard:
		if (c as DuelCard).is_basic_totem() and c.tier() <= max_tier:
			out.append(c)
	return out


## Legend-tier Basic Totems (3 and 4) in `pi`'s hand.
func _legends_in_hand(pi: int) -> Array:
	var out := []
	for c in players[pi].hand:
		if (c as DuelCard).is_basic_totem() and c.tier() >= 3 and c.tier() <= 4:
			out.append(c)
	return out


## Totem cards in `pi`'s deck that share an element with a Totem of theirs on the field.
func _kindred(pi: int) -> Array:
	var els := {}
	for t in players[pi].totems():
		els[t.element()] = true
	var out := []
	for c in players[pi].deck:
		if (c as DuelCard).is_totem() and els.has(c.element()):
			out.append(c)
	return out


## The element `n` Totem cards in `pi`'s discard share ("" if none does).
func ashes_element(pi: int, n: int) -> String:
	var counts := {}
	for c in players[pi].discard:
		if (c as DuelCard).is_totem():
			counts[c.element()] = int(counts.get(c.element(), 0)) + 1
	for el in counts:
		if int(counts[el]) >= n:
			return String(el)
	return ""


## A Guardian of `pi`'s that isn't `target`, standing.
func _guardian_of(pi: int, target) -> DuelTotem:
	for t in players[pi].totems():
		if t.has_keyword("guardian") and not (target is DuelTotem and t == target) and not t.is_knocked_out():
			return t
	return null


## Two attack targets (a Totem, LIFE or NONE) the same (a String and an
## Object can't be compared with ==).
static func _same_target(a, b) -> bool:
	if a is String and b is String:
		return a == b
	if a is Object and b is Object:
		return a == b
	return false


## The response window. The rival of whoever acted is asked first; an answer
## can be answered by the other side, and so on, up to DuelRules.chain_max
## answers; both sides passing in a row closes the window. The chain then
## resolves last-in first-out: an answer that's cancelled does nothing, and
## the action stands or falls by what's left. Returns what became of the
## action: negated, halved, target (moved by a sidestep or to a Guardian),
## bounced (a Rite back to its hand).
func _window(actor: int, event: Dictionary) -> Dictionary:
	var res := {"negated": false, "halved": false, "target": event.get("target"), "bounced": false, "chain": []}
	if over:
		return res
	var chain: Array = []
	var asked := 1 - actor
	var passes := 0
	while chain.size() < DuelRules.chain_max and passes < 2:
		if chain.is_empty() and asked == actor:
			break   # nobody answered: nothing for the actor to answer back
		var top: Dictionary = event if chain.is_empty() else _link_event(chain[-1], chain.size() - 1)
		var pick = null
		var ctrl = players[asked].controller
		if ctrl != null and ctrl.has_method("choose_response"):
			var cards := answers_for(asked, top, false)
			if not cards.is_empty():
				pick = await ctrl.choose_response(self, asked, top, cards)
				if over:
					return res
		if pick != null and pick is DuelCard and answer_problem(asked, pick, top) == "":
			var link := {"card": pick, "pi": asked, "answers": chain.size() - 1, "cancelled": false}
			_play_answer(asked, pick)
			chain.append(link)
			_log("%s answers with %s!" % [players[asked].player_name, pick.card_name()], asked)
			await _fx("fx_answer", [asked, pick, top, chain.size()])
			passes = 0
		else:
			passes += 1
		asked = 1 - asked
	if chain.is_empty():
		return res
	for i in range(chain.size() - 1, -1, -1):
		var link: Dictionary = chain[i]
		var p: DuelPlayer = players[link.pi]
		p.answering.erase(link.card)
		if link.cancelled:
			if link.get("bounce", false):
				p.hand.append(link.card)
				_log("%s is swept back into %s hand." % [link.card.card_name(), whose(p.player_name, true)], link.pi)
			else:
				p.discard.append(link.card)
				_log("%s fizzles." % link.card.card_name(), link.pi)
			continue
		await _resolve_answer(link, chain, event, res)
		if over:
			return res
	res.chain = chain
	await _fx("fx_chain_done", [chain, res])
	await _resolve_knockouts()
	return res


## An answer, as an event the other side may answer.
func _link_event(link: Dictionary, index: int) -> Dictionary:
	var c: DuelCard = link.card
	return {"type": "rite" if c.is_rite() else "ward_spring", "card": c, "by": link.pi, "answer": true, "link": index}


func _play_answer(pi: int, c: DuelCard) -> void:
	var p: DuelPlayer = players[pi]
	_spend(p, card_cost(pi, c) if c.is_ward() else rite_cost(pi, c))
	p.hand.erase(c)
	p.answering.append(c)   # on the chain until it resolves
	if c.is_ward():
		p.hand_wards_used.append(c.id)
	p.stats.answers += 1
	p.note_played(c.id)


func _resolve_answer(link: Dictionary, chain: Array, event: Dictionary, res: Dictionary) -> void:
	var c: DuelCard = link.card
	var pi: int = link.pi
	var p: DuelPlayer = players[pi]
	var target_link = chain[int(link.answers)] if int(link.answers) >= 0 else null
	if c.is_ward():
		# a Ward from the hand springs now, on the action or on the answer it answers
		var wres := {"fired": true, "negated": false, "blocked_life": false, "cancel_rite": false, "reduce_life": 0}
		if target_link != null:
			if c.def.effects.any(func(e): return e.op in ["cancel_rite", "negate"]):
				target_link.cancelled = true
				_log("%s cancels %s." % [c.card_name(), target_link.card.card_name()], pi)
		else:
			var ctx := {"attacker": event.get("attacker"), "target": res.target, "move": event.get("move"),
				"called": event.get("called"), "card": event.get("card")}
			await _apply_ward_effects(c, pi, ctx, wres)
			if wres.negated or (wres.cancel_rite and String(event.get("type", "")) == "rite"):
				res.negated = true
			if int(wres.reduce_life) > 0:
				res["reduce_life"] = int(res.get("reduce_life", 0)) + int(wres.reduce_life)
		p.stats.wards_sprung += 1
		p.discard.append(c)
		return
	for e in c.def.get("effects", []):
		if over:
			return
		match e.op:
			"negate":
				if target_link != null:
					target_link.cancelled = true
					_log("%s cancels %s." % [c.card_name(), target_link.card.card_name()], pi)
				else:
					res.negated = true
			"halve":
				res.halved = true
				_log("%s: the blow will land at half its strength." % c.card_name(), pi)
			"blunt":
				res["blunt"] = int(res.get("blunt", 0)) + int(e.amount)
				_log("%s: the blow will land %d lighter." % [c.card_name(), int(e.amount)], pi)
				var att = event.get("attacker")
				if att is DuelTotem and not (att as DuelTotem).is_knocked_out():
					await _damage_totem(att, int(e.amount), {"source": "recoil"})
			"redirect_guardian":
				var g := _guardian_of(pi, res.target)
				if g != null:
					res.target = g
			"bounce_rite":
				if target_link != null:
					target_link.cancelled = true
					target_link["bounce"] = true
				else:
					res.bounced = true
			"sidestep":
				var tg = res.target
				if tg is DuelTotem and tg.owner == pi and p.totems().has(tg):
					var from: int = tg.slot
					var slots := []
					for sl in p.slots.size():
						if sl != from:
							slots.append(sl)
					var to: int = slots[0]
					if p.controller != null and p.controller.has_method("choose_slot"):
						to = await p.controller.choose_slot(self, pi, "Where does %s step to?" % tg.card_name(), slots, {"reason": "sidestep", "totem": tg})
					if not slots.has(to):
						to = slots[0]
					var other = p.slots[to]
					p.slots[from] = other
					if other != null:
						other.slot = from
					p.slots[to] = tg
					tg.slot = to
					_log("%s steps aside." % tg.card_name(), pi)
					await _fx("fx_shift", [pi])
					res.target = other if other != null else NONE
			"essence":
				p.essence += int(e.amount)
				_log("%s gains %d Essence." % [p.player_name, e.amount], pi)
			"essence_next":
				p.pending_essence += int(e.amount)
				_log("%s will gain %d Essence at their next turn." % [p.player_name, e.amount], pi)
			"draw":
				var drawn := await _draw(p, int(e.get("count", 1)))
				if not drawn.is_empty():
					await _fx("fx_draw", [pi, drawn])
			"cancel_ward":
				if target_link != null:
					target_link.cancelled = true
				else:
					res.negated = true
	p.discard.append(c)


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
	var queued := false
	var roll := 0
	if p.foresight:
		roll = 20
		forced = true
		p.foresight = false
	elif not (forced_rolls[pi] as Array).is_empty():
		roll = int((forced_rolls[pi] as Array).pop_front())
		queued = true
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
	if p.fortune_left > 0 and not forced and not queued and int(info.index) < bands.size() - 1:
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
	m -= int(standing(1 - pi, "foe_fate_minus").get("foe_fate_minus", 0))   # (Eclipse, on the other side)
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
	refresh_bonds()
	state_changed.emit()


## Each Totem's bond (DuelCards.BONDS, by the Basic at the bottom of its
## stack): live while its partner stands on the same side. A bond that has
## just formed is announced.
func refresh_bonds() -> void:
	for p in players:
		var roots := {}
		for t in p.totems():
			roots[String(t.stack[0].id)] = t
		for t in p.totems():
			var b := DuelCards.bond_of(String(t.stack[0].id))
			var partner = roots.get(String(b.get("partner", "")), null) if not b.is_empty() else null
			if partner != null and partner != t and not t.face_down and not partner.face_down:
				if t.bond.is_empty():
					t.bond = b
					_log("%s and %s are bonded: %s." % [t.card_name(), partner.card_name(), String(b.name)], p.index)
					if presenter != null and presenter.has_method("fx_bond"):
						presenter.fx_bond(t, partner)   # (not awaited: a flourish)
			else:
				t.bond = {}


## The total number of cards each duellist owns (for the tests).
func card_totals() -> Array:
	return [players[0].total_card_count(), players[1].total_card_count()]

# ------------------------------- story rules: Solhaven's sworn wagers ---
# The side stories' wager duels (scripts/world/areas/solhaven/solhaven_side.gd),
# each in story_rules as {rule id: the side it binds}: "licensed" (the
# Sergeant), "patter" (Fen), "scrapper" (Pip) and "discipline" (the Captain of
# the Sun Guard). When one of them changes something on the board the
# presenter hears fx_rule(side, rule id).

## What a Rite costs `pi` to cast: its card_cost(), or nothing under the
## Sergeant's licence.
func rite_cost(pi: int, card: DuelCard) -> int:
	var c := card_cost(pi, card)
	return 0 if c > 0 and rule_licensed(pi) else c


## Licensed (the Sergeant of the Dawn Watch, under the dyers' bridge): his
## Rites cost nothing while you have more Totems than he does. The Temple's
## rules favour the Temple.
func rule_licensed(pi: int) -> bool:
	return int(story_rules.get("licensed", -1)) == pi \
		and opponent(pi).totems().size() > players[pi].totems().size()


## Patter (Fen, at the fountain): his Wards lie face up (_act_ward), and once
## a turn, as his turn starts, he swaps the Ward that has been showing longest
## for a different Ward from his hand. He talks too much to keep a secret.
func _rule_patter(p: DuelPlayer) -> void:
	if int(story_rules.get("patter", -1)) != p.index or p.wards.is_empty():
		return
	var shown: DuelCard = p.wards[0]
	var fresh := p.hand.filter(func(c): return c.is_ward() and c.id != shown.id)
	if fresh.is_empty():
		return
	var w: DuelCard = fresh[rng.randi_range(0, fresh.size() - 1)]
	p.hand.erase(w)
	p.wards.erase(shown)
	p.wards.append(w)   # the newest now; the next one along has been showing longest
	p.hand.append(shown)
	face_up.erase(shown.uid)
	face_up[w.uid] = true
	p.note_played(w.id)
	_log("%s takes back %s and sets %s face up instead." % [p.player_name, shown.card_name(), w.card_name()], p.index)
	await _fx("fx_rule", [p.index, "patter"])
	await _fx("fx_ward_set", [p.index, w])


## Scrapper (Pip, on the fountain steps): his Totems hit 10 harder while he's
## behind (his Life below yours).
const SCRAPPER_BONUS := 10


func rule_scrapper(pi: int) -> bool:
	return int(story_rules.get("scrapper", -1)) == pi and players[pi].life < opponent(pi).life


## Discipline (the Captain of the Sun Guard, in the barracks yard): her
## Totems can't be Burned, Poisoned or Frozen. She plays by the book because
## the book is all she has.
const DISCIPLINE_IMMUNE := ["burn", "poison", "frozen"]


func rule_discipline(t: DuelTotem, status: String) -> bool:
	return t != null and int(story_rules.get("discipline", -1)) == t.owner and status in DISCIPLINE_IMMUNE
