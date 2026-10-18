class_name DuelHuman
extends RefCounted
## Connects the duel rules to the player's taps on the Duel screen. Each
## request puts the screen into an input mode and waits for `responded`.

signal responded(value)

var screen = null   # DuelScreen


func choose_action(_game: DuelGame, _pi: int) -> Dictionary:
	if screen.tutor != null:
		await screen.tutor.at_main()   # the tutorial's next lesson, before the player can act
		await screen.lessons_at_main()   # and anything new on the table (an Ascension)
	screen.begin_main()
	var r = await responded
	return r


func choose_cards(_game: DuelGame, _pi: int, prompt: String, cards: Array, min_n: int, max_n: int, context: Dictionary) -> Array:
	screen.begin_pick_cards(prompt, cards, min_n, max_n, context)
	var r = await responded
	return r


func choose_totems(_game: DuelGame, _pi: int, prompt: String, totems: Array, min_n: int, max_n: int) -> Array:
	screen.begin_pick_cards(prompt, totems, min_n, max_n, {})
	var r = await responded
	return r


func choose_slot(_game: DuelGame, _pi: int, prompt: String, slots: Array, context: Dictionary) -> int:
	screen.begin_pick_slot(prompt, slots, context)
	var r = await responded
	return r


func choose_reroll(_game: DuelGame, _pi: int, info: Dictionary) -> bool:
	screen.begin_reroll(info)
	var r = await responded
	return r


func choose_scry(_game: DuelGame, _pi: int, card: DuelCard) -> bool:
	screen.begin_scry(card)
	var r = await responded
	return r


## The computer duellist, slowed down so a person can follow what it does.
class Paced:
	extends RefCounted
	var ai: DuelAI
	var screen = null

	func _init(difficulty: float = 1.0) -> void:
		ai = DuelAI.new(difficulty)

	func _pause(sec: float) -> void:
		if screen != null:
			await screen.pause(sec)

	func choose_action(game: DuelGame, pi: int) -> Dictionary:
		await _pause(0.5)
		var a := ai.choose_action(game, pi)
		if screen != null and a.get("type", "") != "end":
			await screen.preview_ai_action(pi, a)
		return a

	func choose_cards(game: DuelGame, pi: int, prompt: String, cards: Array, min_n: int, max_n: int, context: Dictionary) -> Array:
		await _pause(0.4)
		return ai.choose_cards(game, pi, prompt, cards, min_n, max_n, context)

	func choose_totems(game: DuelGame, pi: int, prompt: String, totems: Array, min_n: int, max_n: int) -> Array:
		await _pause(0.4)
		return ai.choose_totems(game, pi, prompt, totems, min_n, max_n)

	func choose_slot(game: DuelGame, pi: int, prompt: String, slots: Array, context: Dictionary) -> int:
		await _pause(0.3)
		return ai.choose_slot(game, pi, prompt, slots, context)

	func choose_reroll(game: DuelGame, pi: int, info: Dictionary) -> bool:
		await _pause(0.3)
		return ai.choose_reroll(game, pi, info)

	func choose_scry(game: DuelGame, pi: int, card: DuelCard) -> bool:
		return ai.choose_scry(game, pi, card)


## A tutorial rival: plays the turns it's given, in order, then falls back to
## the computer duellist. Each turn is a list of actions by card id:
##   {"type": "call", "card": "cinderpup", "slot": "mirror"}      (mirror = across from the player's Totem)
##   {"type": "attack", "attacker": "cinderpup", "move": 1, "target": "brookfin" | "life", "roll": 12}
##   {"type": "rite", "card": "firebrand", "target": "brookfin"}
## A step that can't be done (the card isn't in hand, say) is skipped.
class Scripted:
	extends Paced
	var turns: Array = []
	var _queue: Array = []
	var _turn_seen := -1
	var _scripted := 0

	func _init(script_turns: Array, difficulty: float = 0.25) -> void:
		super(difficulty)
		turns = script_turns

	func choose_action(game: DuelGame, pi: int) -> Dictionary:
		if game.turn != _turn_seen:
			_turn_seen = game.turn
			_queue = (turns[_scripted] as Array).duplicate() if _scripted < turns.size() else []
			_scripted += 1
		if _scripted > turns.size():
			return await super.choose_action(game, pi)
		while not _queue.is_empty():
			var a := _resolve(game, pi, _queue.pop_front())
			if a.is_empty() or game.action_problem(pi, a) != "":
				continue
			if a.has("_roll"):
				(game.forced_rolls[pi] as Array).append(int(a._roll))   # the Fate roll this lesson needs
				a.erase("_roll")
			await _pause(0.6)
			if screen != null:
				await screen.preview_ai_action(pi, a)
			return a
		# a story rule may still owe an attack (Showboat): make it before ending
		var owed := game.showboat_attack(pi)
		if not owed.is_empty():
			await _pause(0.6)
			if screen != null:
				await screen.preview_ai_action(pi, owed)
			return owed
		await _pause(0.4)
		return {"type": "end"}

	static func _resolve(game: DuelGame, pi: int, step: Dictionary) -> Dictionary:
		var me: DuelPlayer = game.players[pi]
		var foe: DuelPlayer = game.players[1 - pi]
		match String(step.get("type", "")):
			"call":
				var c := _in_hand(me, String(step.card))
				if c == null:
					return {}
				var slot := -1
				if String(step.get("slot", "")) == "mirror":
					for t in foe.totems():
						if me.slots[t.slot] == null:
							slot = t.slot
							break
				if slot < 0:
					slot = me.empty_slots()[0] if not me.empty_slots().is_empty() else -1
				return {"type": "call", "card": c, "slot": slot}
			"attack":
				var att := _totem(me, String(step.attacker))
				if att == null:
					return {}
				var tg = DuelGame.LIFE if String(step.target) == "life" else _totem(foe, String(step.target))
				if tg == null:
					return {}
				var act := {"type": "attack", "attacker": att, "move": int(step.get("move", 0)), "target": tg}
				if step.has("roll"):
					act["_roll"] = int(step.roll)
				return act
			"rite":
				var c := _in_hand(me, String(step.card))
				if c == null:
					return {}
				var a := {"type": "rite", "card": c}
				if step.has("target"):
					var tg = _totem(foe, String(step.target))
					if tg == null:
						tg = _totem(me, String(step.target))
					if tg == null:
						return {}
					a["target"] = tg
				return a
		return {}

	static func _in_hand(p: DuelPlayer, id: String) -> DuelCard:
		for c in p.hand:
			if c.id == id:
				return c
		return null

	static func _totem(p: DuelPlayer, id: String) -> DuelTotem:
		for t in p.totems():
			if t.id() == id:
				return t
		return null
