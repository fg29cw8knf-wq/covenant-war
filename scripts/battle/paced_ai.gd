class_name PacedAI
extends RefCounted
## The computer opponent, slowed down so a person can follow what it does.

var ai := AIController.new()
var screen = null   # anything with a `pause(seconds)` coroutine


func _pause(sec: float) -> void:
	if screen != null:
		await screen.pause(sec)


func choose_setup(game: BattleGame, pi: int) -> Dictionary:
	await _pause(0.4)
	return await ai.choose_setup(game, pi)


func choose_action(game: BattleGame, pi: int) -> Dictionary:
	await _pause(0.55)
	return await ai.choose_action(game, pi)


func choose_creature(game: BattleGame, pi: int, prompt: String, options: Array, cancellable: bool, context: Dictionary):
	await _pause(0.4)
	return await ai.choose_creature(game, pi, prompt, options, cancellable, context)


func choose_promotion(game: BattleGame, pi: int):
	await _pause(0.5)
	return await ai.choose_promotion(game, pi)


func choose_cards(game: BattleGame, pi: int, prompt: String, cards: Array, min_n: int, max_n: int, context: Dictionary) -> Array:
	await _pause(0.4)
	return await ai.choose_cards(game, pi, prompt, cards, min_n, max_n, context)
