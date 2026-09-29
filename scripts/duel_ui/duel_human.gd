class_name DuelHuman
extends RefCounted
## Connects the duel rules to the player's taps on the Duel screen. Each
## request puts the screen into an input mode and waits for `responded`.

signal responded(value)

var screen = null   # DuelScreen


func choose_action(_game: DuelGame, _pi: int) -> Dictionary:
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
