extends SceneTree
## The Trial of Light's four set boards (scripts/world/solhaven/duels.gd), one
## for each of Bram's decks: its answer wins inside three turns, and no line
## that doesn't call the Summon down on the first turn ever does. Plays the
## answer, then thousands of random lines through the real rules engine.
##   godot --headless --script res://tests/trial_puzzle_test.gd [-- <random lines per deck>]

var Duels: GDScript

var fails := 0

## The answer for each board, turn by turn (the player's turns 1, 3, 5):
## "summon", "attack:<slot>:<move>:<target>" (target: "life" or a mirror slot).
const ANSWERS := {
	"emberstorm": [["summon"], ["attack:2:1:life", "attack:0:1:life"], ["attack:2:1:life", "attack:0:1:life"]],
	"tidegrove": [["summon"], ["attack:0:1:1", "attack:2:1:life"], ["attack:0:1:life", "attack:2:1:life"]],
	"ironstone": [["summon:1"], ["attack:0:1:life", "attack:2:1:life"], ["attack:0:1:life", "attack:2:1:life"]],
	"veilwild": [["summon"], ["attack:0:1:0", "attack:2:1:2"], ["attack:0:1:life", "attack:2:1:life"]],
}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 3000
	Duels = load("res://scripts/world/solhaven/duels.gd")
	for deck in Duels.TRIALS:
		_answer(deck)
		_random_lines(deck, n)
	print("TRIAL PUZZLE: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _new_game(deck: String, ctrl) -> DuelGame:
	var spec: Dictionary = Duels.trial_spec(deck)
	var g := DuelGame.new()
	g.setup(spec.decks, spec.names, [ctrl, Passive.new()], spec.profiles, 7)
	g.story_rules = spec.story_rules
	g.puzzle = spec.puzzle
	return g


func _answer(deck: String) -> void:
	var c := Scripted.new()
	c.turns = ANSWERS[deck]
	var g := _new_game(deck, c)
	c.game = g
	g.run()
	var left: int = g.players[1].life
	_check(g.over and g.winner == 0, "%s: the answer wins (winner %d, the mirrors' Life %d, turn %d, %s)" % [deck, g.winner, left, g.turn, c.problems])
	_check(c.problems.is_empty(), "%s: every step of the answer was allowed (%s)" % [deck, c.problems])


func _random_lines(deck: String, n: int) -> void:
	var wins_t1 := 0
	var tries_t1 := 0
	var wins_other := 0
	var example := ""
	for k in n:
		var c := RandomPlayer.new()
		c.rng.seed = k * 7919 + 13
		c.keen = k % 2 == 1   # every other line plays to hurt: attacks first, paid moves, the Summon whenever
		var g := _new_game(deck, c)
		c.game = g
		g.run()
		if not g.over:
			_check(false, "%s: line %d never finished" % [deck, k])
			continue
		if c.summon_turn == 1:
			tries_t1 += 1
			if g.winner == 0:
				wins_t1 += 1
		elif g.winner == 0:
			wins_other += 1
			if example == "":
				example = "summoned on turn %d: %s" % [c.summon_turn, " / ".join(c.log)]
				if "log" in OS.get_cmdline_user_args():
					print("\n".join(g.log_lines))
	print("TRIAL PUZZLE %s: %d random lines; Summon on turn 1 in %d of them, %d won; other lines won %d" % [deck, n, tries_t1, wins_t1, wins_other])
	_check(wins_other == 0, "%s: no line wins without the Summon on the first turn (%s)" % [deck, example])


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("TRIAL PUZZLE FAIL: ", what)


## The mirrors: they only watch (and never need to choose anything).
class Passive:
	extends RefCounted
	func choose_action(_g, _pi) -> Dictionary: return {"type": "end"}
	func choose_cards(_g, _pi, _p, cards: Array, min_n: int, _max_n, _c) -> Array: return cards.slice(0, min_n)
	func choose_totems(_g, _pi, _p, totems: Array, min_n: int, _max_n) -> Array: return totems.slice(0, min_n)
	func choose_slot(_g, _pi, _p, slots: Array, _c) -> int: return slots[0]
	func choose_reroll(_g, _pi, _i) -> bool: return false
	func choose_scry(_g, _pi, _c) -> bool: return true


## Plays the written answer.
class Scripted:
	extends Passive
	var game: DuelGame
	var turns: Array = []
	var problems: Array = []
	var _turn := -1
	var _step := 0
	var _last_game_turn := -1

	func choose_action(g, pi) -> Dictionary:
		if g.turn != _last_game_turn:
			_last_game_turn = g.turn
			_turn += 1
			_step = 0
		if _turn >= turns.size() or _step >= (turns[_turn] as Array).size():
			return {"type": "end"}
		var s := String(turns[_turn][_step])
		_step += 1
		var a := _action(g, pi, s)
		var why: String = g.action_problem(pi, a) if not a.is_empty() else "no such action"
		if why != "":
			problems.append("%s: %s" % [s, why])
			return {"type": "end"}
		return a

	func _action(g: DuelGame, pi: int, s: String) -> Dictionary:
		var p: DuelPlayer = g.players[pi]
		var bits := s.split(":")
		match bits[0]:
			"summon":
				for c in p.hand:
					if c.is_summon():
						var tg = null
						if bits.size() > 1:
							tg = g.players[1 - pi].slots[int(bits[1])]
						return {"type": "summon", "card": c, "target": tg}
			"attack":
				var t: DuelTotem = p.slots[int(bits[1])]
				if t == null:
					return {}
				var target = DuelGame.LIFE if bits[3] == "life" else g.players[1 - pi].slots[int(bits[3])]
				return {"type": "attack", "attacker": t, "move": int(bits[2]), "target": target}
		return {}


## Plays at random among everything allowed, ending its turn now and then.
class RandomPlayer:
	extends Passive
	var game: DuelGame
	var rng := RandomNumberGenerator.new()
	var summon_turn := 0
	var log: Array = []
	var keen := false

	func choose_action(g, pi) -> Dictionary:
		var opts := _options(g, pi)
		if keen:
			opts = _keen(opts)
		if opts.is_empty() or (not keen and rng.randf() < 0.12):
			log.append("end")
			return {"type": "end"}
		var a: Dictionary = opts[rng.randi_range(0, opts.size() - 1)]
		if a.type == "summon" and summon_turn == 0:
			summon_turn = int((g.turn + 1) / 2.0)
		log.append("t%d %s %s" % [g.turn, a.type, (a.get("card") as DuelCard).id if a.has("card") else (a.get("attacker") as DuelTotem).id() if a.has("attacker") else ""])
		return a

	## Only what can do damage: attacks (paid moves twice as likely), the
	## Summon, now and then a Shift (to stand opposite an empty slot).
	func _keen(opts: Array) -> Array:
		var out := []
		for a in opts:
			match a.type:
				"attack":
					out.append(a)
					if int(a.move) > 0:
						out.append(a)
				"summon":
					if rng.randf() < 0.5:
						out.append(a)
				"shift":
					if rng.randf() < 0.1:
						out.append(a)
		return out

	func _options(g: DuelGame, pi: int) -> Array:
		var p: DuelPlayer = g.players[pi]
		var foe: DuelPlayer = g.players[1 - pi]
		var out := []
		var cands := []
		for c in p.hand:
			match c.kind():
				"totem":
					if c.is_basic_totem():
						for s in p.empty_slots():
							cands.append({"type": "call", "card": c, "slot": s})
					else:
						for t in g.ascend_targets(pi, c):
							cands.append({"type": "ascend", "card": c, "target": t})
				"rite":
					if g.rite_needs_target(c):
						for t in g.rite_targets(pi, c):
							cands.append({"type": "rite", "card": c, "target": t})
					else:
						cands.append({"type": "rite", "card": c})
				"ward":
					cands.append({"type": "ward", "card": c})
				"summon":
					if g.summon_needs_target(c):
						for t in foe.totems():
							cands.append({"type": "summon", "card": c, "target": t})
					else:
						cands.append({"type": "summon", "card": c})
		for t in p.totems():
			for i in t.moves().size():
				for tg in g.attack_targets(pi, t, i):
					cands.append({"type": "attack", "attacker": t, "move": i, "target": tg})
			for s in DuelRules.SLOTS:
				cands.append({"type": "shift", "totem": t, "slot": s})
		cands.append({"type": "gift"})
		for a in cands:
			if g.action_problem(pi, a) == "":
				out.append(a)
		return out
