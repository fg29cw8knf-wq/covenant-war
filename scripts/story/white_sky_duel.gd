class_name WhiteSkyDuel
extends RefCounted
## Bram's duel in the Night of the White Sky (WhiteSky): the decks, the seed
## and the computer's skill, apart from WhiteSky so tests/white_sky_probe.gd
## can play it headless (a --script run has none of the game's autoloads).

## Bram's duel. Twenty years ago Bram had served a god for forty years (Gary,
## 4 November: "a very powerful distinguished player", and "high tier cards,
## nothing low tier"; 5 November: "top tier totems that will be under his own
## god ... cards in league with his god or its allies"), so the film cuts in
## with the duel already joined, on a set board (DuelGame.puzzle, as the
## Trial of Light is). His god is Kaethis, the Hand Before (Lore.GODS; Gary's
## yes, 6 November), and every card is Kaethis's or its allies': the Scrivener and
## the Loomwarden standing, Last Stand set, the Unspent Hour, Cut Thread and
## two Relics to hand, Aldrith's Glyph Warden and Counter Runes in the deck,
## every card of his Crystal tier or above (Rites, Relics and Wards Glimmer
## and up), Orlanthe, the Last Page, SUMMON_AT cards down his deck, and six
## Essence a turn; a god's champion pays no tribute to call a Crystal
## ("free_call"). Which god he served stays hidden (Master Script v7: his
## former master, a god of fate and destiny, comes out much later): no patron
## is named and no Divine Gift is played, and the film shows no names.
## Against him the hunter's pack, hounds and foxes of white smoke already on
## the field, Ascended too, and more coming (every Hound feeds the others'
## bite). Both played by the computer at SKILL, every attribute at its
## height. SEED decides the Fate rolls: tests/white_sky_probe.gd found one
## where Bram loses two of his Totems and breaks two of the pack before
## Orlanthe comes (seed 13, 5 November: the hunter Dooms the Scrivener at
## once; Bram's Loomwarden and Unspent Hour break the Blazehound and the
## Infernal Warg; the Scrivener and the Unspent Hour fall on the hunter's
## third turn; he calls the Weft Serpent and the Glyph Warden into the gaps;
## the Last Page on his fourth turn, the duel's 8th). LIFE_FLOOR keeps him
## standing until then.
const SEED := 13
## The Summon he calls at the end (the white is its blow), and how far down
## his deck it lies.
const SUMMON := "orlanthe"
const SUMMON_AT := 3
const SKILL := 1.0
const LIFE_FLOOR := [40, 0]
const TURN_MIN := 4
const TURN_MAX := 11
## The hunter strikes first; Bram answers.
const FIRST := 1
const LIFE := [600, 600]
const ESSENCE := [6, 6]
## Bram's side: the board (a stack is what the Totem rose from, then the one
## standing), his hand, his deck in the order it's drawn, his Wards set.
## (5 November: Kaethis's cards in place of his old Ironstone's; the Basics
## standing from the first frame, nothing stacked under them)
const BRAM_BOARD := [["scrivener"], ["loomwarden"], null]
const BRAM_HAND := ["unspent_hour", "cut_thread", "hourglass_no_sand", "knotted_cord"]
## (the Weft Serpent drawn third, so all five of his Totems are seen before
## the white: tests/white_sky_probe.gd)
const BRAM_DECK := ["already_written", "glyph_warden", "weft_serpent", "orlanthe", "doom_sigil", "foreordained", "cut_thread",
	"counter_rune", "hushed_counter", "scrivener", "knotted_cord", "glyph_warden", "foreordained", "null_sigil"]
const BRAM_WARDS := ["last_stand"]
## The hunter's pack.
const HUNTER_BOARD := [["cinderpup", "blazehound"], ["cinderpup", "blazehound", "infernal_warg"], ["dreamfox", "veilfox"]]
const HUNTER_HAND := ["river_hound", "pack_howl", "doom_sigil", "shieldhound"]
const HUNTER_DECK := ["call_of_kin", "sparkkit", "toxic_mist", "cinderpup", "siphon_rune", "dreamfox", "pack_howl",
	"thunderclap", "river_hound", "rite_of_ashes", "mirror_veil", "shieldhound", "cinderpup", "sparkkit"]
const HUNTER_WARDS := ["poison_trap"]


## The set board, for DuelGame.puzzle (DuelScreen spec.puzzle and the probe).
static func board() -> Dictionary:
	return {"first": FIRST, "life": LIFE.duplicate(), "essence_max": ESSENCE.duplicate(),
		"board": [BRAM_BOARD.duplicate(true), HUNTER_BOARD.duplicate(true)],
		"hand": [BRAM_HAND.duplicate(), HUNTER_HAND.duplicate()],
		"deck": [bram_deck(SEED, SUMMON_AT), HUNTER_DECK.duplicate()],
		"wards": [BRAM_WARDS.duplicate(), HUNTER_WARDS.duplicate()],
		"no_gift": true, "synergy": ["kin", "side", "react", "chain"]}


## The story rule: a god's champion calls his Crystals without tribute.
static func story_rules() -> Dictionary:
	return {"free_call": 0}


## How fast the filmed duel plays (DuelScreen.rate of the duel speed setting).
## (3.0 until 8 November: directed as a film, its beats need a moment each.)
const FILM_SPEED := 2.2

## Bram's deck in the order it's drawn: BRAM_DECK with the Summon `pos`
## cards down (the seed shuffles nothing: a set board is written out).
static func bram_deck(_seed_value: int, pos: int) -> Array:
	var ids: Array = BRAM_DECK.duplicate()
	ids.erase(SUMMON)
	ids.insert(clampi(pos, 0, ids.size()), SUMMON)
	return ids


## The Summon's name as the duel's log says it (the film and its probe
## watch the log for it being called down).
static func summon_name() -> String:
	return String(DuelCards.CARDS[SUMMON].name)


static func hunter_deck(_seed_value: int) -> Array:
	return HUNTER_DECK.duplicate()


static func _shuffle(ids: Array, s: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = s
	for i in range(ids.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t


## Bram twenty years ago: every attribute at its height. (No patron named:
## his god stays a secret; at 9 the Unsworn's +1 takes each to 10.)
static func bram_profile() -> Dictionary:
	return Lore.new_profile("Bram", "", 9)


static func hunter_profile() -> Dictionary:
	return Lore.new_profile("The hunter", "", 9)


# ==================================================== the duel as it's played ===
## (12 November, Gary: "Bram's duel becomes played, not watched ... three gated
## moves as Bram (call a Totem, attack, play the Last Page), with no costs or
## numbers, and it can't be lost. The first card is played about two minutes
## in, not ten.") The same duel, cut into already joined and already going
## badly, and written out move by move (PLAY_TURNS) instead of left to two
## computers and a seed: the real rules play it, so every blow and every
## Totem is the game's own, but nothing in it is chance and nothing is chosen
## that could lose it.
##   The hunter strikes first: the Infernal Warg's charge breaks the
##     Scrivener, already hurt (PLAY_BRAM_HURT).
##   1. Bram calls the Unspent Hour into the gap (the player's first move:
##      "call"). It's Swift: it can strike the turn it's called.
##   2. It turns its glass on the Blazehound across from it and breaks it
##      (the second: "attack").
##   The pack answers: the Veilfox and the Warg bring the Loomwarden down.
##   3. He draws the Last Page and calls it down (the third: "last_page");
##      as its blow lands the screen burns white (WhiteSky).
## No Wards are set and neither side holds anything that answers a play, so
## nothing interrupts a move. Each of the player's three is a step with a
## "gate": the Staged controller waits at it for whoever is playing (the
## game's tap; nobody in the probe). tests/white_sky_play_probe.gd plays it
## headless and checks every step happens as written.
const PLAY_LIFE := [600, 600]
const PLAY_ESSENCE := [8, 8]
const PLAY_BRAM_BOARD := [["scrivener"], ["loomwarden"], null]
const PLAY_BRAM_HURT := [110, 100, 0]
## (the Last Page is the second card he draws: there on his second turn. The
## cards beside the one to play are ones with paintings: his hand is shown
## as paintings alone.)
const PLAY_BRAM_HAND := ["unspent_hour", "weft_serpent"]
const PLAY_BRAM_DECK := ["counter_rune", "orlanthe", "last_stand", "scrivener", "loomwarden", "glyph_warden"]
const PLAY_HUNTER_BOARD := [["cinderpup", "blazehound"], ["cinderpup", "blazehound", "infernal_warg"], ["dreamfox", "veilfox"]]
const PLAY_HUNTER_HURT := [40, 0, 0]
const PLAY_HUNTER_DECK := ["cinderpup", "dreamfox", "sparkkit", "cinderpup", "dreamfox", "sparkkit"]
## The turns, [Bram's, the hunter's], each a list of steps (DuelHuman.Scripted's,
## and "summon"); a step with a "gate" is one of the player's three moves.
const PLAY_TURNS := [
	[
		[{"type": "call", "card": "unspent_hour", "gate": "call"},
			{"type": "attack", "attacker": "unspent_hour", "move": 1, "target": "blazehound", "gate": "attack"}],
		[{"type": "summon", "card": "orlanthe", "target": "infernal_warg", "gate": "last_page"}],
	],
	[
		[{"type": "attack", "attacker": "infernal_warg", "move": 1, "target": "scrivener"}],
		[{"type": "attack", "attacker": "veilfox", "move": 1, "target": "loomwarden"},
			{"type": "attack", "attacker": "infernal_warg", "move": 1, "target": "loomwarden"}],
	],
]
## The player's three moves, in order.
const PLAY_GATES := ["call", "attack", "last_page"]


## The played duel's set board (DuelGame.puzzle).
static func play_board() -> Dictionary:
	return {"first": FIRST, "attack_first": true, "life": PLAY_LIFE.duplicate(), "essence_max": PLAY_ESSENCE.duplicate(),
		"board": [PLAY_BRAM_BOARD.duplicate(true), PLAY_HUNTER_BOARD.duplicate(true)],
		"damage": [PLAY_BRAM_HURT.duplicate(), PLAY_HUNTER_HURT.duplicate()],
		"hand": [PLAY_BRAM_HAND.duplicate(), []],
		"deck": [PLAY_BRAM_DECK.duplicate(), PLAY_HUNTER_DECK.duplicate()],
		"wards": [[], []], "no_gift": true, "synergy": []}


## The two sides' players for the played duel: [Bram's, the hunter's].
static func play_controllers() -> Array:
	var bram := Staged.new(PLAY_TURNS[0])
	bram.hold = true   # (after the Last Page nothing more is played: the white is coming)
	return [bram, Staged.new(PLAY_TURNS[1])]


## A side of the played duel: its turns as written, nothing else. A step
## with a "gate" waits for `ask` (called with the gate's name and the action
## about to be made; awaited) before it's made: the player's tap. A step that
## can't be made is skipped and noted in `skipped`; with its turns all
## played it only ends its turn, or with `hold` waits where it is until the
## duel is ended from outside. It answers nothing and rerolls nothing.
class Staged:
	extends DuelHuman.Scripted
	var ask := Callable()
	var hold := false
	var skipped: Array = []
	var made: Array = []      # the gates passed, in order

	func _init(script_turns: Array) -> void:
		super(script_turns, 1.0)

	func choose_action(game: DuelGame, pi: int) -> Dictionary:
		if game.turn != _turn_seen:
			_turn_seen = game.turn
			_queue = (turns[_scripted] as Array).duplicate() if _scripted < turns.size() else []
			_scripted += 1
		while not _queue.is_empty():
			var step: Dictionary = _queue[0]
			var a := _step(game, pi, step)
			if DuelRules.phases and not a.is_empty() and game.phase_problem(String(a.type)) != "":
				if game.next_phase(pi) != "end":
					return {"type": "next"}
				_queue.pop_front()
				skipped.append("%s: %s" % [step, game.phase_problem(String(a.type))])
				continue
			_queue.pop_front()
			if a.is_empty():
				skipped.append("%s: nothing to do it with" % [step])
				continue
			var why := game.action_problem(pi, a)
			if why != "":
				skipped.append("%s: %s" % [step, why])
				continue
			if step.has("gate"):
				if ask.is_valid():
					await ask.call(String(step.gate), a)
				made.append(String(step.gate))
			else:
				await _pause(THINK_ACTION)
				if screen != null:
					await screen.preview_ai_action(pi, a)
			return a
		if hold and _scripted >= turns.size():
			while not game.over:
				await Engine.get_main_loop().process_frame
		return {"type": "end"}

	func choose_response(_game: DuelGame, _pi: int, _event: Dictionary, _cards: Array) -> DuelCard:
		return null

	func choose_reroll(_game: DuelGame, _pi: int, _info: Dictionary) -> bool:
		return false

	func choose_scry(_game: DuelGame, _pi: int, _card: DuelCard) -> bool:
		return true

	static func _step(game: DuelGame, pi: int, step: Dictionary) -> Dictionary:
		if String(step.get("type", "")) != "summon":
			return _resolve(game, pi, step)
		var c := _in_hand(game.players[pi], String(step.card))
		if c == null:
			return {}
		var a := {"type": "summon", "card": c}
		if step.has("target"):
			var tg = _totem(game.players[1 - pi], String(step.target))
			if tg == null:
				# (the one written has fallen: any of the pack still standing)
				var left: Array = game.targetable(game.players[1 - pi].totems())
				if left.is_empty():
					return {}
				tg = left[0]
			a["target"] = tg
		return a

