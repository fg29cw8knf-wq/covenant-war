class_name HumanController
extends RefCounted
## Connects the rules engine to the player's taps on the duel screen.
## Each request puts the screen into an input mode and waits for `responded`.

signal responded(value)

var screen = null   # BattleScreen


func choose_setup(_game: BattleGame, _pi: int) -> Dictionary:
	screen.begin_setup()
	var r = await responded
	return r


func choose_action(_game: BattleGame, _pi: int) -> Dictionary:
	screen.begin_main()
	var r = await responded
	return r


func choose_creature(_game: BattleGame, _pi: int, prompt: String, options: Array, cancellable: bool, _context: Dictionary):
	screen.begin_pick_creature(prompt, options, cancellable)
	var r = await responded
	return r


func choose_promotion(game: BattleGame, pi: int):
	screen.begin_pick_creature("Your Active Totem is gone. Choose a new one from your Bench.",
		game.players[pi].bench.duplicate(), false)
	var r = await responded
	return r


func choose_cards(_game: BattleGame, _pi: int, prompt: String, cards: Array, min_n: int, max_n: int, context: Dictionary) -> Array:
	screen.begin_pick_cards(prompt, cards, min_n, max_n, context)
	var r = await responded
	return r
