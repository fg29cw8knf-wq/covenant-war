extends SceneTree
## Bram's Riddles (DuelPuzzles) through the rules engine: each riddle's
## answer wins in its one turn, and a tempting wrong try doesn't.
##   godot --headless --script res://tests/puzzles_test.gd

var fails := 0

## Each riddle's answer, and a wrong try, as steps: ["shift", from, to],
## ["attack", from slot, move, "life", "none" or their slot], ["rite", card id,
## your slot / their slot ("foe:1") / null], ["call", card id, slot].
const LINES := {
	"open_lane": {
		"answer": [["shift", 0, 2], ["attack", 2, 1, "life"]],
		"wrong": [["attack", 0, 1, 0]],
	},
	"spill_over": {
		"answer": [["attack", 0, 1, 0]],
		"wrong": [["attack", 0, 0, 0]],
	},
	"guardian_first": {
		"answer": [["attack", 1, 0, 1], ["attack", 0, 1, 1], ["attack", 2, 1, "life"]],
		"wrong": [["attack", 0, 0, 1], ["attack", 1, 1, 1], ["attack", 2, 0, "life"]],
	},
	"where_its_weak": {
		"answer": [["attack", 0, 1, 1], ["attack", 1, 1, "life"]],
		"wrong": [["attack", 0, 1, 0], ["attack", 1, 1, 1]],
	},
	"bait_the_ward": {
		"answer": [["attack", 0, 0, "life"], ["attack", 1, 0, "life"]],
		"wrong": [["attack", 1, 0, "life"], ["attack", 0, 0, "life"]],
	},
	"every_last_drop": {
		"answer": [["rite", "essence_flask", null], ["rite", "forge_edge", 0], ["rite", "war_paint", 0], ["attack", 0, 1, "life"]],
		"wrong": [["attack", 0, 1, "life"]],
	},
	"last_light": {
		"answer": [["rite", "rallying_light", null], ["attack", 0, 0, "life"], ["attack", 1, 0, "life"]],
		"wrong": [["attack", 0, 0, "life"], ["attack", 1, 0, "life"]],
	},
	# 28 October: synergy
	"the_pack": {
		"answer": [["call", "river_hound", 1], ["attack", 0, 1, "life"]],
		"wrong": [["call", "shieldhound", 1], ["attack", 0, 0, "life"]],
	},
	"side_by_side": {
		"answer": [["shift", 0, 1], ["attack", 1, 0, "life"], ["attack", 2, 0, "life"]],
		"wrong": [["attack", 2, 1, "life"], ["attack", 0, 0, "life"]],
	},
	"steel_finds_the_wound": {
		"answer": [["rite", "jagged_shards", "foe:0"], ["attack", 0, 0, 0]],
		"wrong": [["attack", 0, 0, 0], ["rite", "jagged_shards", "foe:0"]],
	},
	"third_time": {
		"answer": [["rite", "essence_flask", null], ["rite", "war_paint", 0], ["rite", "forge_edge", 0], ["attack", 0, 1, "life"]],
		"wrong": [["rite", "forge_edge", 0], ["rite", "essence_flask", null], ["rite", "war_paint", 0], ["attack", 0, 1, "life"]],
	},
	"old_friends": {
		"answer": [["call", "brookfin", 1], ["attack", 0, 2, "none"]],
		"wrong": [["attack", 0, 0, 0]],
	},
	"whose_ground": {
		"answer": [["rite", "firebrand", "foe:0"], ["attack", 0, 0, "life"]],
		"wrong": [["attack", 0, 1, 0]],
	},
}


class Steps:
	extends RefCounted
	var steps: Array = []
	var i := 0
	var problems: Array = []

	func choose_action(g: DuelGame, pi: int) -> Dictionary:
		while i < steps.size():
			var st: Array = steps[i]
			i += 1
			var a := _action(g, pi, st)
			if a.is_empty():
				problems.append("step %s: nothing to do it with" % [st])
				continue
			var why := g.action_problem(pi, a)
			if why != "":
				problems.append("step %s: %s" % [st, why])
				continue
			return a
		return {"type": "end"}

	func _action(g: DuelGame, pi: int, st: Array) -> Dictionary:
		var me: DuelPlayer = g.players[pi]
		var foe: DuelPlayer = g.players[1 - pi]
		match String(st[0]):
			"shift":
				return {"type": "shift", "totem": me.slots[int(st[1])], "slot": int(st[2])}
			"attack":
				var t = me.slots[int(st[1])]
				if t == null:
					return {}
				var target = DuelGame.LIFE if st[3] is String and st[3] == "life" else (DuelGame.NONE if st[3] is String and st[3] == "none" else foe.slots[int(st[3])])
				return {"type": "attack", "attacker": t, "move": int(st[2]), "target": target}
			"call":
				for c in me.hand:
					if c.id == String(st[1]):
						return {"type": "call", "card": c, "slot": int(st[2])}
				return {}
			"rite":
				var card: DuelCard = null
				for c in me.hand:
					if c.id == String(st[1]):
						card = c
				if card == null:
					return {}
				var target = null
				if st[2] is String and String(st[2]).begins_with("foe:"):
					target = foe.slots[int(String(st[2]).split(":")[1])]
				elif st[2] != null:
					target = me.slots[int(st[2])]
				return {"type": "rite", "card": card, "target": target}
		return {}

	func choose_cards(_g, _pi, _p, cards: Array, min_n: int, _max_n, _c) -> Array: return cards.slice(0, maxi(1, min_n))
	func choose_totems(_g, _pi, _p, totems: Array, min_n: int, _max_n) -> Array: return totems.slice(0, min_n)
	func choose_slot(_g, _pi, _p, slots: Array, _c) -> int: return slots[0]
	func choose_reroll(_g, _pi, _i) -> bool: return false
	func choose_scry(_g, _pi, _c) -> bool: return true
	func choose_response(_g, _pi, _e, _cards) -> DuelCard: return null


func _initialize() -> void:
	_check(DuelPuzzles.count() == LINES.size(), "every riddle has its lines here (%d riddles)" % DuelPuzzles.count())
	for i in DuelPuzzles.count():
		var id := String(DuelPuzzles.get_puzzle(i).id)
		if not LINES.has(id):
			_check(false, "%s: no lines to test" % id)
			continue
		var won := await _play(i, LINES[id].answer)
		_check(won.won, "%s: the answer wins (%s)" % [id, won.why])
		var lost := await _play(i, LINES[id].wrong)
		_check(not lost.won, "%s: the wrong try doesn't (%s)" % [id, lost.why])
	print("PUZZLES TEST: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(0 if fails == 0 else 1)


func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  FAIL: ", what)


## Sets the riddle up as the duel screen does, plays `steps`, and says how it went.
func _play(i: int, steps: Array) -> Dictionary:
	var spec := DuelPuzzles.spec(i, "You")
	var me := Steps.new()
	me.steps = steps
	var g := DuelGame.new()
	g.setup(spec.decks, spec.names, [me, DuelAI.new(1.0, 3)], spec.profiles, 17)
	g.puzzle = spec.puzzle
	g.story_rules = spec.story_rules
	g.arena = ""
	g.comeback = false
	g.arena_events = false
	await g.run()
	var why := "%s; their Life %d; %s" % [g.win_reason, g.players[1].life, "; ".join(me.problems) if not me.problems.is_empty() else "every step taken"]
	return {"won": g.winner == 0, "why": why}
