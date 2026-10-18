extends RefCounted
## Ashford — the player's home village, on the last night of the Age.
## Prologue scenes P1 (The Last Night) to P4 (Ashford burns), from the
## Spoken Script. P1 is played on foot; from midnight on, the Prologue is a
## film made in the village itself (Cine and CineOverlay): the Sigilfall,
## the dawn and the Pale Herald, the taproom, the night Ashford burns and
## Bram's cellar. Then the trapdoor, and the Thornwood (thornwood.gd).
##
## Layout (metres): the Great Lantern stands at the centre of the green, the
## cottages ring it about 22 m out, the road runs past the south side and the
## camera looks north (towards -z). The village itself is AshfordVillage.

const NAME := "Ashford"
const SUBTITLE := "The Last Night of the Age"

const BOUNDS := Rect2(-24.0, -24.0, 48.0, 44.0)
const CAMERA_X_LIMIT := 13.0
## The village builds its own sky, moon, fog and lights.
const CUSTOM_ENV := true
## New Game opens on a flight over the festival before the player takes over (intro()).
const INTRO := true
## A Prologue left part-way through its film picks up where it was (resume()).
const RESUMES := true

const SPAWNS := {
	"green": Vector3(1.5, 0, 10.5),
	"inn": Vector3(-19.0, 0, 9.5),
}

const ENV := {}

## Bram's Spark deck: twelve old Sparks from the box at the inn, one Totem, so
## the first duel is a lesson. The player's is steady water (Brookfin beats
## Corin's fire); Corin's is brash fire. Both are dealt in the order written
## (no shuffle), so every lesson below has the card it needs. Bram hands the
## player's over before the duel, and it's theirs to keep.
const PLAYER_DECK := [
	"brookfin", "bulwark", "essence_flask", "healing_draught", "essence_flask",
	"healing_draught", "bulwark", "essence_flask",
	"healing_draught", "essence_flask", "bulwark", "travellers_pack",
]
const CORIN_DECK := [
	"cinderpup", "essence_flask", "healing_draught", "essence_flask", "travellers_pack", "essence_flask",
	"firebrand", "essence_flask", "healing_draught",
	"essence_flask", "healing_draught", "essence_flask",
]
## Both start on 25 Life, so Brookfin's Undertow to the Life ends the lesson.
const LANTERN_LIFE := 25

## Bram shows the player their pack right after handing them the deck: the
## Deck and the Codex open up, one gated step at a time (WorldHUD.pack_tour).
const PACK_TOUR := [
	{"say": "Before you go losing it: everything you carry lives in your pack. Tap it, up in the corner.", "do": "menu"},
	{"say": "Tap Deck.", "do": "tab:deck"},
	{"say": "That's the twelve you'll duel with tonight. Shuffled before every duel, and you draw from the top.", "focus": "deck_grid"},
	{"say": "Twelve's a beginner's deck. A proper one is thirty, and you build it yourself from what you find. Not tonight."},
	{"say": "Tap any card. It'll tell you everything about itself.", "do": "card"},
	{"say": "What it costs, its element, what every move does. Read before you play. Corin never does.", "focus": "detail"},
	{"say": "Close it.", "do": "close"},
	{"say": "Now the Codex.", "do": "tab:codex"},
	{"say": "Every card you find gets written in here: your own, and any you see played against you. It's short tonight. It won't stay short.", "focus": "codex_grid"},
	{"say": "Close your pack. Corin's waiting, and patience was never his Sigil.", "do": "resume"},
]

## Bram teaches the duel from his stool, one step at a time (Spoken Script, P1:
## the Lantern Duel). Each line waits for the player: an explanation until they
## tap, an instruction until they've done it, and nothing else can be touched
## meanwhile. See DuelTutor for the step format. It teaches only what's on
## the table tonight (Totems, Rites, Essence, Life, attacking, one weakness,
## Fate and the card panel); Wards, the element chart, conditions and
## Ascension are taught the first time each matters, later on.
const LESSON := {
	"events": {
		"intro": [
			{"say": "Right. Those cards are Sigils. The gods' magic is always leaking into the world, a drop at a time, and where it lands it sets hard. Like frost on a window."},
			{"say": "Yours are Sparks, the smallest kind. That's the gods on a quiet day, mind. When they fight, it doesn't drip. It pours."},
			{"say": "There's a lot to duelling. More than one night's worth. So tonight, just the basics. The rest you'll learn as more cards come your way."},
			{"say": "Your Totems do the fighting. Bring his Life down to nothing and you've won.", "focus": "life"},
			{"say": "Tap the die to roll for who goes first. Highest starts.", "do": "die"},
		],
		"rival_call": [
			{"say": "There's his Cinderpup. Fire, see the orb? Remember that.", "focus": "foe:cinderpup"},
		],
		"weakness": [
			{"say": "See that? Water puts fire out. Hit a Totem's weakness and it hurts a good deal more. The orb on each card tells you its element.", "focus": "foe:cinderpup"},
		],
		"rival_fate": [
			{"say": "That's Fate. Some moves roll the die: roll high, hit hard; roll low, nothing. Corin loves those. Corin loves anything that can go wrong loudly.", "focus": "die", "learn": "fate"},
		],
		"absorbed": [
			{"say": "And your Bulwark took the lot. Told you.", "focus": "totem:brookfin"},
		],
		"ko_rival": [
			{"say": "Out it goes, back into its card. Nobody bleeds inside a circle. That's the law."},
		],
		"hit_mine": [
			{"say": "He's throwing Rites now. That one got through, but Brookfin's tougher than it looks.", "focus": "totem:brookfin"},
		],
	},
	"turns": [
		[
			{"say": "Along the bottom, that's your hand. Five to start, and you draw one more every turn after this.", "focus": "hand"},
			{"say": "Brookfin's your Totem: a Spark of river water. Tap it.", "do": "card:brookfin"},
			{"say": "That panel on the right is the card up close: its cost, its element and what its moves do. Tap any card, yours or Corin's, whenever you want a closer look.", "focus": "detail"},
			{"say": "Now tap the glowing slot. That calls it into the circle.", "do": "slot:1"},
			{"say": "Calling it cost one Essence. That's the blue gems by your Life. You get one more every turn, so spend them. Nobody ever won a duel with savings.", "focus": "essence"},
			{"say": "Nobody attacks on the first turn, and a Totem called this turn needs a moment to find its feet. So that's you done."},
			{"say": "Tap End Turn.", "do": "end"},
		],
		[
			{"say": "You drew a card. One every turn, like I said.", "focus": "hand"},
			{"say": "Brookfin can fight now. Tap it.", "do": "totem:brookfin"},
			{"say": "Pick a move. Splash costs nothing. Undertow costs one Essence, hits harder and heals Brookfin a little. Start with Splash.", "do": "move:0"},
			{"say": "Now tap his Cinderpup.", "do": "target:cinderpup"},
			{"say": "You've still two Essence. Not every card's a Totem. That Bulwark's a Rite: a bit of magic you cast once, then it's gone.", "focus": "card:bulwark"},
			{"say": "Bulwark throws a wall of stone up round one of your own Totems. The next hit it takes, the stone takes first: up to fifty damage of it.", "focus": "card:bulwark"},
			{"say": "Corin's pup will go for Brookfin on his turn. He never waits. So the wall goes up now, before he swings.", "focus": "foe:cinderpup"},
			{"say": "Tap Bulwark.", "do": "card:bulwark"},
			{"say": "Now tap Brookfin, so the stone goes up round it.", "do": "target:brookfin"},
			{"say": "That'll do for this turn. End it.", "do": "end"},
		],
		[
			{"say": "His pup's hurting. Undertow will finish it."},
			{"say": "Tap Brookfin.", "do": "totem:brookfin"},
			{"say": "Undertow, this time.", "do": "move:1"},
			{"say": "And tap the Cinderpup.", "do": "target:cinderpup"},
			{"say": "Nothing stands across from Brookfin now. Next turn it can go straight at Corin's Life.", "focus": "life"},
			{"say": "End your turn.", "do": "end"},
		],
		[
			{"say": "Now. Tap Brookfin.", "do": "totem:brookfin"},
			{"say": "Undertow. Make it count.", "do": "move:1"},
			{"say": "Tap Corin's Life. There's nothing in the way.", "do": "target:life"},
		],
	],
}

## Corin's side of the lesson, one list per turn (DuelHuman.Scripted): he calls
## his pup across from Brookfin, tries his luck with a Fate move (the roll is set
## so the Bulwark holds), then throws a Rite.
const CORIN_SCRIPT := [
	[{"type": "call", "card": "cinderpup", "slot": "mirror"}],
	[{"type": "attack", "attacker": "cinderpup", "move": 1, "target": "brookfin", "roll": 12}],
	[{"type": "rite", "card": "firebrand", "target": "brookfin"}],
]

## Corin's barks during the Lantern Duel, shown in rotation when he attacks.
const CORIN_BARKS := ["Ha! Didn't see that coming, did you?", "That's a lucky draw, that's all.", "Cinderpup, do something!", "Fine. FINE. Good hit."]


static func npcs() -> Array:
	return [
		{"id": "bram", "look": "bram", "name": "Bram", "pos": Vector3(2.2, 0, 2.6), "talk": _bram()},
		{"id": "corin", "look": "corin", "name": "Corin", "pos": Vector3(-8.6, 0, -2.4),
			"duel_flag": "ash_lantern_duel", "talk": _corin()},
		{"id": "tam", "look": "farmer", "name": "Tam", "pos": Vector3(6.4, 0, -2.6), "talk": _tam()},
		{"id": "tilly", "look": "child", "name": "Tilly", "pos": Vector3(5.2, 0, 8.4), "talk": _tilly()},
		{"id": "nell", "look": "elder", "name": "Old Nell", "pos": Vector3(-3.9, 0, 6.6), "talk": _nell()},
		{"id": "seamus", "look": "fiddler", "name": "Seamus", "pos": Vector3(-1.6, 0, -6.4), "talk": _seamus()},
		# out in the open on the east of the green, clear of Tilly's stall
		{"id": "hob", "look": "hob", "name": "Hob", "pos": Vector3(10.8, 0, 1.6), "talk": _hob()},
	]


# ================================================================ scenery ===

static func build(root: Node3D) -> void:
	var v := AshfordVillage.new()
	v.name = "Village"
	root.add_child(v)
	root.set_meta("village", v)
	# the festival reel: its intro once, then the loop (Music.LOOP_START), and
	# it carries on from where it was when a duel or a scene hands back
	(root as World).music = ["ashford_festival"]
	if not Game.flag("ash_marked"):
		Music.play((root as World).music, 2.0, true)


static func village(w: Node) -> AshfordVillage:
	return w.get_meta("village") as AshfordVillage


# ================================================================== story ===

## P1, as built today: the player starts on the green, so Bram's taproom lines
## and the controls lesson play here. (The attic, the crate and the lantern
## hanging are still to build.)
static func arrival() -> Array:
	return [
		{"say": "[center][i]Nobody alive has seen an Age end. So Ashford has decided it ends with cider.[/i][/center]"},
		{"who": "bram", "say": "There you are, Sprout. Thought you'd sleep through the end of the world."},
		{"who": "bram", "say": "Once every two thousand years, an Age ends. Be a shame to be late for it."},
		{"choice": ["What happens when it ends?", "I'm up, I'm up."], "then": [
			[{"who": "bram", "say": "The gods fight over who sits the Throne next. We hang lanterns and drink to whoever wins. It's a better deal than it sounds."}],
			[{"who": "bram", "say": "Good. You can carry the next crate, then. Builds character."}],
		]},
		{"who": "bram", "say": "Corin's telling everyone he'll duel at the Sun Court one day. Solhaven. Gold roofs and golden knights."},
		{"choice": ["One day I will, too.", "Why would anyone want to?"], "then": [
			[{"set": "want_solhaven"}, {"who": "bram", "say": "Nobody from Ashford goes to Solhaven, Sprout. Solhaven would have to know where Ashford is first."}],
			[{"who": "bram", "say": "Because you're twenty and this is a small place."}],
		]},
		{"who": "bram", "say": "Here's how it goes. Tap the ground where you want to stand. Your legs know the rest."},
		{"who": "bram", "say": "And if you need to stop, the little square up in the corner stops the world. Save there. Nobody will think less of you."},
		{"who": "bram", "say": "Now the hard part. Half the village wants a hand with something, and you're the hand."},
		{"who": "bram", "say": "Tam's at the hay cart, Tilly's by the stall and Old Nell's at the well. Walk up to someone and a mark shows over their head. Tap Talk, and they'll talk."},
		{"who": "bram", "say": "Or go and shut Corin up first, if you must. He's by the well, telling people he's lighting the Great Lantern tonight. I'd like him to be wrong in front of a crowd."},
		{"who": "bram", "say": "Your choice. But folk here remember who turned up."},
		{"say": "[i]He glances up at the stars the way he'd watch a stranger's hands.[/i]"},
		{"who": "bram", "say": "Go on. Folk are waiting."},
		{"scene": "home"},
		{"objective": "Duel Corin by the well. Tam, Tilly and Old Nell could use a hand first."},
		{"set": "ash_started"},
	]


## All three chores done: Hob remembers at the river.
static func _chores_done() -> Array:
	return [{"if": "ash_tam", "then": [{"if": "ash_tilly", "then": [{"if": "ash_nell", "then": [{"set": "ash_ready"}]}]}]}]


static func _bram() -> Array:
	return [
		{"if": "ash_ready", "then": [
			{"who": "bram", "say": "Everyone sorted? Good. Corin's by the well, warming up his audience. Go and spoil the ending. Leave the how to me. Whoever wins lights the Great Lantern at midnight."},
		], "else": [
			{"who": "bram", "say": "Still folk wanting a hand, Sprout, if you've the time before midnight."},
			{"if": "!ash_tam", "then": [{"who": "bram", "say": "Tam's at the hay cart, losing an argument with a barrel."}]},
			{"if": "!ash_tilly", "then": [{"who": "bram", "say": "Tilly's at the stall with something to show you. She'll burst if you don't look."}]},
			{"if": "!ash_nell", "then": [{"who": "bram", "say": "And Old Nell's at the well. She'll want to tell you a story. Let her."}]},
		]},
		{"who": "bram", "say": "And Sprout. Stay where I can see you tonight. Humour an old man."},
	]


static func _tam() -> Array:
	return [
		{"if": "ash_tam", "then": [
			{"who": "tam", "say": "Whatever's owed can stay owed till morning. If you see my Nell, tell her I'm saving her a dance. Knees or no knees."},
		], "else": [
			{"who": "tam", "say": "Evening. Take the other end of this, would you? Bram wants the cider at the stall before the dancing starts, and my back wants a word with Bram."},
			{"scene": "tam_barrel"},
			{"say": "[i]You heave the last barrel into place. Tam wipes his hands on his shirt and nods up the lane, towards the mill.[/i]"},
			{"who": "tam", "say": "Ironvault's man came by this morning. Very polite about it. The mill's note falls due at the new moon."},
			{"who": "tam", "say": "Forty years I've ground Ashford's flour, and a banker I've never met owns the stones. Ah, well. Not tonight."},
			{"who": "tam", "say": "Solmaris kept the rain fair for two thousand years. Who knows what we get tomorrow. Fire, probably. Or frogs. Drink up while it's free."},
			{"set": "ash_tam"},
		]},
	] + _chores_done()


static func _tilly() -> Array:
	return [
		{"if": "ash_tilly", "then": [
			{"who": "tilly", "say": "It's still glowing! It never glows this long for me."},
		], "else": [
			{"if": "ash_tilly_seen", "then": [
				{"who": "tilly", "say": "You said not tonight. It's still glowing, though. Look!"},
				{"who": "tilly", "say": "Will you wake it now?"},
			], "else": [
				{"who": "tilly", "say": "Look! Look, look, look! A Lantern Moth! Da found it in the barley. It's only a Spark. But it's mine."},
				{"who": "tilly", "say": "Only Attuned can wake them. Corin says you're Attuned. He says he's more Attuned, but he says that about everything. Will you wake it?"},
			]},
			{"choice": ["Let me see it.", "Not tonight, Tilly."], "then": [
				[
					{"say": "[i]You touch the card.[/i]"},
					{"scene": "tilly_moth"},
					{"say": "[i]A moth made of lamplight. It circled Tilly's head twice and settled back into the paper, still glowing.[/i]"},
					{"who": "tilly", "say": "Again! Again! It never does that for Da. Corin can make it twitch, but it never flies for him."},
					{"set": "ash_tilly"},
				],
				[
					{"who": "tilly", "say": "Aww. That's all right. It glows brighter when you're near, though. Look!"},
					{"say": "[i]The card in her hands brightens as you lean in. Not a flicker. Steady, the way a candle burns when every door is shut.[/i]"},
					{"set": "ash_tilly_seen"},
				],
			]},
		]},
	] + _chores_done()


static func _nell() -> Array:
	return [
		{"if": "ash_nell", "then": [
			{"who": "nell", "say": "Lights in the sky, child. Mark an old woman's words."},
		], "else": [
			{"who": "nell", "say": "Sit with me a moment, child. My knees won't take the dancing. Don't tell Tam. He'll only try to carry me."},
			{"who": "nell", "say": "My gran's gran used to say the last Age began with lights in the sky. Gods squabbling over a chair, she said, and the sparks falling on us."},
			{"who": "nell", "say": "I've seen the sky do it once myself, years back. One light. Left a hole in the top field you could lose a cow in."},
			{"who": "nell", "say": "Stay close to Bram tonight, child. Old bones feel things."},
			{"set": "ash_nell"},
		]},
	] + _chores_done()


static func _seamus() -> Array:
	return [
		{"who": "seamus", "say": "Requests? I know the Lantern Reel, the Lantern Reel played slow, and the Lantern Reel played drunk. Two of those I can still play."},
		{"who": "seamus", "say": "They say this reel's as old as the Age. Somebody stood on this green and played it the last time the sky changed hands. I do wonder how his night went."},
	]


static func _hob() -> Array:
	return [
		{"who": "hob", "say": "Barley's in, roof's patched, cider's paid for. If the Age wants to end, it can end tonight. I'm free."},
		{"who": "hob", "say": "My cabbages came up early this year. Can't think why."},
	]


## Corin and the Lantern Duel. The player is Attuned (every Spark in the
## village sits up when they pass) but has never held a deck: Bram has kept
## them out of it. When Corin points that out, Bram walks over and hands
## the player their first deck, says what one is, shows them their pack, and
## the duel begins.
static func _corin() -> Array:
	return [
		{"if": "first_deck", "then": [
			{"who": "corin", "say": "Deck in your hand and everything. Come on, then, before you lose your nerve."},
		] + _lantern_duel(), "else": [
			# Bram sets off the moment Corin starts, so he's there to step in
			{"who": "corin", "say": "Oi! Ashford's other Attuned! Ready to lose? Or are you off helping old ladies first?",
				"during": "bram_sets_off"},
			{"who": "corin", "say": "Either way, I'm here, deciding which side of my face the crowd gets."},
			{"choice": ["Let's duel.", "Not yet."], "then": [
				[
					{"who": "corin", "say": "Lantern Duel. Winner lights the Great Lantern at midnight. Loser carries the drum home."},
					{"who": "corin", "say": "Only you've no deck, have you? Every Spark in Ashford sits up when you walk past, and Bram's never once let you hold one."},
					{"who": "corin", "say": "So I win by default. Again. Shame. I'd practised my face."},
					{"scene": "bram_comes"},
					{"who": "bram", "say": "Nobody wins anything by default while I'm stood here."},
					{"who": "bram", "say": "I've kept these out of your hands since you were small, Sprout. Reckon the last night of the Age is a fair night to stop."},
					{"choice": ["Why now?", "Mine? To keep?"], "then": [
						[{"who": "bram", "say": "Because tomorrow's a new Age, and I'd rather you met it with something in your hand."}],
						[{"who": "bram", "say": "To keep. Twelve Sparks from the old box at the inn. I picked every one."}],
					]},
					{"scene": "first_deck"},
					{"who": "bram", "say": "That's a deck. Shuffled, you draw from the top and play what you can."},
					{"who": "bram", "say": "Anyone can work a Sigil's magic, mind. A Rite, a bit of magic you cast once and then it's gone, answers Tam as quick as it answers you."},
					{"who": "bram", "say": "But calling a Totem up out of a card, so it stands and fights? That takes the Attuned. In Ashford, that's you, Corin, and an old innkeeper who should know better."},
					{"who": "corin", "say": "You? Since when?"},
					{"who": "bram", "say": "Since before you could spell it. Which, I'll grant, wasn't long ago."},
					{"scene": "pack_tour"},
				] + _lantern_duel(),
				[{"who": "corin", "say": "Go on, then. Hurry up. My audience is getting cold.", "during": "bram_goes_back"}],
			]},
		]},
	]


static func _lantern_duel() -> Array:
	return [
		{"who": "corin", "say": "Finally. Half of Ashford's watching. I told the other half to hurry. And no going easy on me. I'd know."},
		{"who": "bram", "say": "One Totem each. And nobody sets fire to a stall. I'm looking at you, Corin."},
		{"who": "corin", "say": "That was one stall."},
		{"who": "bram", "say": "Want me calling your turns from the stool, Sprout? No shame either way. A Totem in a slot, Essence to pay its way, nothing empty between him and your Life."},
		{"choice": ["Talk me through it, Bram.", "I've watched enough duels."], "then": [
			[{"who": "bram", "say": "Sensible. Listen for me."}],
			[{"set": "coach_off"}, {"who": "bram", "say": "Then I'll keep my mouth shut and my eyebrows ready."}],
		]},
		{"duel": {"v1": true, "id": "corin_lantern", "name": "Corin", "difficulty": 0.25},
			"win": [
				{"who": "corin", "say": "Fine. Fine! You were better. Tonight. You're still second-best in my book. Go on, light the thing. Next year it's mine."},
				{"set": "ash_won_lantern"},
			],
			"lose": [
				{"who": "corin", "say": "Ha! Second-best, like I always say. You nearly had me, though. Nearly. Come on. Best view of the Lantern's next to me."},
			]},
		# she runs over and holds it out; it passes into your hands on her
		# words "You keep it", then the card shows: NEW SIGIL
		{"scene": "tilly_gift"},
		{"if": "ash_tilly", "then": [
			{"who": "tilly", "say": "For luck! You keep it. It glows better for you anyway.",
				"during": "tilly_hands_over", "at": "You keep it"},
		], "else": [
			{"who": "tilly", "say": "For luck! It's a Lantern Moth. If it wakes for anyone, it'll wake for you. You keep it.",
				"during": "tilly_hands_over", "at": "You keep it"},
		]},
		{"scene": "tilly_card"},
		{"who": "bram", "say": "In your pack with it, Sprout. It'll keep."},
		{"set": "ash_lantern_duel"},
		{"scene": "midnight"},
	]


## The duel spec World hands to Main for the Lantern Duel.
static func duel_spec(spec: Dictionary) -> Dictionary:
	var arena := "ashford" if DuelArt.arena("ashford") != null else "tidegrove"
	return {
		"decks": [PLAYER_DECK.duplicate(), CORIN_DECK.duplicate()],
		# the player has no name of their own until the Herald says it at dawn
		# (only Bram calls them Sprout), so the nameplate just says You
		"names": ["You" if Game.player_name == "Sprout" else Game.player_name, "Corin"],
		"profiles": [Lore.new_profile("You" if Game.player_name == "Sprout" else Game.player_name), Lore.new_profile("Corin")],
		"ai": [false, true],
		"difficulty": float(spec.get("difficulty", 0.3)),
		"arena": arena,
		"life": LANTERN_LIFE,
		"story": true,
		# dealt in order, the player first, and it can't be lost: a first duel
		# should teach, not punish. Declining Bram's help still keeps those.
		"stacked": [true, true],
		"first": 0,
		"life_floor": [1, 0],
		"totem_floor": [1, 0],
		"tutorial": {} if Game.flag("coach_off") else LESSON,
		"rival_script": CORIN_SCRIPT,
		"barks": CORIN_BARKS,
		"rewards": {"opponent": "village"},
	}


# ================================================================ scenes ===

static func scene(name: String, w: World) -> void:
	match name:
		"midnight":
			await _midnight(w)
			await _prologue_film(w, "dawn")
		"tam_barrel":
			await _tam_barrel(w)
		"tilly_moth":
			await _tilly_moth(w)
		"bram_sets_off":
			await _bram_sets_off(w)
		"bram_goes_back":
			await _bram_goes_back(w)
		"bram_comes":
			await _bram_comes(w)
		"first_deck":
			await _first_deck(w)
		"pack_tour":
			await _pack_tour(w)
		"tilly_gift":
			await _tilly_gift(w)
		"tilly_hands_over":
			await _tilly_hands_over(w)
		"tilly_card":
			await _tilly_card(w)
		"home":
			await w.cine_home(1.2)


## Coming back to a Prologue film part-way through: start on black.
static func starts_black() -> bool:
	return Game.flag("ash_lantern_duel") and not Game.flag("pro_tunnel_done")


## A Prologue film left part-way (the game was closed during it) picks up at
## the start of the part it was in. Called by World on arrival.
static func resume(w: World) -> void:
	if not Game.flag("ash_lantern_duel") or Game.flag("pro_tunnel_done"):
		return
	if not Game.flag("ash_marked"):
		await _midnight(w)
		await _prologue_film(w, "dawn")
		return
	var part := String(Game.flag("pro_part", "dawn"))
	await _prologue_film(w, part)


# ================================================================== intro ===

const INTRO_FROM := Vector3(-30.0, 15.0, 48.0)

## The first frame of New Game, set before the screen fades up.
static func intro_frame(w: World) -> void:
	w.cine = true
	w.cam.global_position = INTRO_FROM
	w.cam.look_at(Vector3(0, 3.0, 0), Vector3.UP)


## New Game's opening shot (after the movie): the camera comes in over the
## fields and rooftops of Ashford, past the Great Lantern still waiting to be
## lit, and down to the player on the green as Bram comes over. A tap speeds
## it up.
static func intro(w: World) -> void:
	var v := village(w)
	var p := w.player.global_position
	var bram = w._npc_by_id("bram")
	# a tap, click or key speeds it up (the touch pad is hidden during it)
	var watching := [true]
	var watch := func() -> void:
		while watching[0] and is_instance_valid(w) and w.is_inside_tree():
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("interact") or Input.is_action_pressed("ui_accept"):
				Engine.time_scale = 4.0
			await w.get_tree().process_frame
	watch.call()
	await w.cine_to(Vector3(-12.0, 8.5, 30.0), Vector3(0.0, 4.0, -2.0), 5.5)
	var top: Vector3 = v.great_lantern_top if v.great_lantern_top != Vector3.ZERO else Vector3(0, 8.0, 0)
	if bram != null:
		_walk(w, bram, p + Vector3(1.0, 0.0, -1.7), 3.6)
	await w.cine_to(Vector3(8.0, 5.2, 14.0), top - Vector3(0, 1.0, 0), 3.5)
	await w.cine_to(p + Vector3(3.2, 2.5, 4.4), p + Vector3(0.4, 1.25, -0.9), 2.4)
	if bram != null:
		bram.doll.look_toward(p, w.cam)
		w.player_doll.look_toward(bram.body.global_position, w.cam)
	await w.get_tree().create_timer(0.3).timeout
	watching[0] = false
	Engine.time_scale = 1.0


## Walks an NPC (or the player, with npc = null) to `to` over `secs`, facing the way they go.
static func _walk(w: World, npc, to: Vector3, secs: float) -> void:
	var body: Node3D = w.player if npc == null else npc.body
	var doll: PaperDoll = w.player_doll if npc == null else npc.doll
	var from := body.global_position
	to.y = from.y
	if from.distance_to(to) < 0.05:
		return
	doll.walking = true
	doll.face(to - from, w.cam)
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void: body.global_position = from.lerp(to, u), 0.0, 1.0, secs)
	await tw.finished
	doll.walking = false


# ================================================================ chores ===

## Tam's barrel: the player takes one end, Tam the other, and they carry the
## last cider barrel from the hay cart over to Tilly's stall.
static func _tam_barrel(w: World) -> void:
	var v := village(w)
	var tam = w._npc_by_id("tam")
	var b: Node3D = v.tam_barrel
	if b == null or tam == null:
		return
	var start := b.global_position - Vector3(0, AshfordVillage.BARREL_HALF, 0)   # on the ground
	var spot := v.barrel_spot
	var dir := spot - start
	dir.y = 0.0
	dir = dir.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	if side.dot(w.cam.global_transform.basis.x) < 0.0:
		side = -side   # the player takes the end nearer the camera's right
	var end := spot - dir * 0.75
	# ahead of them and off the player's side, so both faces come towards the
	# camera as they carry it (from behind, the hay cart was in the way)
	w.cine = true
	var cam_at := end + dir * 2.4 + side * 3.6 + Vector3(0, 1.9, 0)
	w.cine_to(cam_at, start.lerp(end, 0.3) + Vector3(0, 0.9, 0), 1.0)
	# each takes an end
	var held := BARREL_HOLD
	_walk(w, null, start + side * held, 0.8)
	await _walk(w, tam, start - side * held, 0.8)
	w.player_doll.look_toward(start, w.cam)
	tam.doll.look_toward(start, w.cam)
	await w.get_tree().create_timer(0.25).timeout
	# lift it onto its side, held between them: a 3D figure bends to it and
	# takes hold of its end with both hands (hand holds on the barrel, so
	# they go where it goes)
	var b0 := b.basis
	var lifted := Basis(dir, PI * 0.5)   # on its side, spanning the two of them
	var lift_c := start + Vector3(0, 0.95, 0)
	var holds := []
	for who in [[w.player_doll, 1.0], [tam.doll, -1.0]]:
		var f = who[0]
		if f is Figure3D:
			var e: Vector3 = side * float(who[1])
			var grips := []
			for fwd in [1.0, -1.0]:
				var g := Node3D.new()
				g.name = "BarrelGrip"
				b.add_child(g)
				# where the hand will be once it's lifted, in the barrel's own frame
				g.position = lifted.inverse() * (e * (AshfordVillage.BARREL_HALF - 0.05) + dir * 0.17 * fwd - Vector3(0, 0.07, 0))
				grips.append(g)
			# its left hand takes the grip on its left as it faces the barrel
			var left_fwd: bool = (-e).cross(Vector3.UP).dot(dir) < 0.0
			(f as Figure3D).pose("lift", 0.45, 0.35)
			(f as Figure3D).reach(grips[0] if left_fwd else grips[1], grips[1] if left_fwd else grips[0], 0.45)
			holds.append_array(grips)
	if not holds.is_empty():
		await w.get_tree().create_timer(0.3).timeout
	var tw := w.create_tween().set_parallel(true)
	tw.tween_property(b, "global_position", lift_c, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(u: float) -> void: b.basis = Basis(b0.get_rotation_quaternion().slerp(lifted.get_rotation_quaternion(), u)), 0.0, 1.0, 0.5)
	await tw.finished
	# carry it over, side by side, at a heavy barrel's walk
	var secs := maxf(2.2, start.distance_to(end) / BARREL_PACE)
	var pace := start.distance_to(end) / secs
	for f in [w.player_doll, tam.doll]:
		if f is Figure3D:
			(f as Figure3D).release(0.25)
			(f as Figure3D).pace = pace
	w.player_doll.walking = true
	tam.doll.walking = true
	w.player_doll.face(dir, w.cam)
	tam.doll.face(dir, w.cam)
	var pb: Node3D = w.player
	var tb: Node3D = tam.body
	var carry := w.create_tween()
	carry.tween_method(func(u: float) -> void:
		var c := start.lerp(end, u)
		var bob := absf(sin(u * secs * 5.2)) * 0.035
		b.global_position = c + Vector3(0, 0.95 + bob, 0)
		pb.global_position = c + side * held
		tb.global_position = c - side * held, 0.0, 1.0, secs)
	Cine.drift(w, cam_at, cam_at + dir * 0.4 - side * 0.3, start.lerp(end, 0.3) + Vector3(0, 0.9, 0), end + Vector3(0, 0.85, 0), secs)
	await carry.finished
	w.player_doll.walking = false
	tam.doll.walking = false
	for f in [w.player_doll, tam.doll]:
		if f is Figure3D:
			(f as Figure3D).pace = 0.0
	# heave it up onto its end beside the others (letting go as it lands)
	for f in [w.player_doll, tam.doll]:
		if f is Figure3D:
			(f as Figure3D).let_go(0.3)
	var up_basis := Basis(Vector3.UP, 0.4)
	var down := w.create_tween().set_parallel(true)
	down.tween_property(b, "global_position", spot + Vector3(0, AshfordVillage.BARREL_HALF + 0.25, 0), 0.35).set_trans(Tween.TRANS_SINE)
	down.tween_method(func(u: float) -> void: b.basis = Basis(lifted.get_rotation_quaternion().slerp(up_basis.get_rotation_quaternion(), u)), 0.0, 1.0, 0.35)
	await down.finished
	var thud := w.create_tween()
	thud.tween_property(b, "global_position", spot + Vector3(0, AshfordVillage.BARREL_HALF, 0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await thud.finished
	v.dust_puff(spot)
	w.shake(0.12)
	for g in holds:
		(g as Node).queue_free()
	tam.doll.look_toward(pb.global_position, w.cam)
	w.player_doll.look_toward(tb.global_position, w.cam)
	await w.get_tree().create_timer(0.4).timeout
	await w.cine_home(0.9)

## How far from the barrel's middle each of them walks carrying it (m), and
## how fast they go with it (m/s).
const BARREL_HOLD := 0.7
const BARREL_PACE := 1.7


## Tilly's Lantern Moth: at the player's touch it unfolds out of her card, a
## moth made of lamplight, circles her head twice and settles back into the card.
static func _tilly_moth(w: World) -> void:
	var v := village(w)
	var tilly = w._npc_by_id("tilly")
	if tilly == null:
		return
	var tp: Vector3 = tilly.body.global_position
	var pp: Vector3 = w.player.global_position
	# side on to the two of them, so nobody stands between the camera and the moth
	var axis := tp - pp
	axis.y = 0.0
	axis = axis.normalized() if axis.length() > 0.01 else Vector3.FORWARD
	var perp := axis.cross(Vector3.UP).normalized()
	var to_cam := w.cam.global_position - tp
	to_cam.y = 0.0
	if perp.dot(to_cam) < 0.0:
		perp = -perp
	var card := tp - axis * 0.3 + Vector3(0, TILLY_HANDS, 0)
	var head := tp + Vector3(0, TILLY_HEAD, 0)
	var between := (tp + pp) * 0.5
	# a 3D Tilly holds her card out to you in both hands, and the moth
	# circles her own head
	var tf = tilly.doll
	var held: Node3D = null
	if tf is Figure3D:
		(tf as Figure3D).snap_face(-axis)
		held = _moth_card(v)
		(tf as Figure3D).carry(held, TILLY_HOLD)
		_hands_on(tf, held, 0.4)
		card = (tf as Figure3D).to_world(TILLY_HOLD)
		head = Cine.head(w, "tilly") - Vector3(0, 0.06, 0)
	w.cine = true
	await w.cine_to(between + perp * 4.0 + axis * 0.6 + Vector3(0, 1.5, 0), tp - axis * 0.3 + Vector3(0, 1.05, 0), 1.0)
	# the card glows, then the moth unfolds out of it
	var glow: MeshInstance3D = v.glow_sprite(held if held != null else w, Vector3.ZERO if held != null else card, Color(1.0, 0.72, 0.32), 0.4, 0.7)
	var gt := w.create_tween()
	gt.tween_property(glow, "scale", Vector3.ONE * 1.1, 0.5).set_trans(Tween.TRANS_SINE)
	await gt.finished
	var moth := LanternMothFlight.new()
	w.add_child(moth)
	moth.global_position = card
	moth.scale = Vector3.ONE * 0.05
	var grow := w.create_tween()
	grow.tween_property(moth, "scale", Vector3.ONE * MOTH_SIZE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# up, twice round her head, and back down into the card
	var r := 0.72
	var a0 := atan2(-axis.z, -axis.x)   # starts on her near side, between her and you
	var flight := w.create_tween()
	flight.tween_method(func(u: float) -> void:
		var pos: Vector3
		var ring := head + Vector3(cos(a0) * r, 0.0, sin(a0) * r)
		if u < 0.15:
			var k := u / 0.15
			pos = card.lerp(ring, k * k * (3.0 - 2.0 * k)) + Vector3(0, sin(k * PI) * 0.3, 0)
		elif u < 0.85:
			var k2 := (u - 0.15) / 0.7
			var a := a0 + k2 * TAU * 2.0
			pos = head + Vector3(cos(a) * r, sin(k2 * TAU * 3.0) * 0.12, sin(a) * r)
		else:
			var k3 := (u - 0.85) / 0.15
			pos = ring.lerp(card, k3 * k3)
		moth.fly_to(pos), 0.0, 1.0, 6.5)
	await flight.finished
	var shrink := w.create_tween().set_parallel(true)
	shrink.tween_property(moth, "scale", Vector3.ONE * 0.05, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	shrink.tween_property(glow, "scale", Vector3.ONE * 1.8, 0.35)
	await shrink.finished
	moth.queue_free()
	var fade := w.create_tween()
	fade.tween_property(glow, "scale", Vector3.ONE * 0.7, 0.6).set_trans(Tween.TRANS_SINE)
	await fade.finished
	glow.queue_free()
	# she tucks it away again
	if held != null:
		(tf as Figure3D).let_go(0.35)
		var away := w.create_tween()
		away.tween_property(held, "scale", Vector3.ONE * 0.01, 0.35)
		away.tween_callback(held.queue_free)
	tilly.doll.look_toward(w.player.global_position, w.cam)
	await w.cine_home(0.9)

## Where Tilly holds her card, and her head, in metres above the ground
## (her painted cut-out, drawn full height).
const TILLY_HANDS := 0.85
const TILLY_HEAD := 1.45
## Where the 3D Tilly holds her card out, in her own frame (y up, z ahead).
const TILLY_HOLD := Vector3(0.0, 0.74, 0.25)
const TILLY_HOLD_OUT := Vector3(0.0, 0.84, 0.36)


## Tilly's Lantern Moth card: a little warm-lit card with a hand hold either
## side of it ("L" on the holder's left, "R" on its right).
static func _moth_card(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	n.name = "MothCard"
	var c := InnRooms.blank_card(v)
	var m := c.material_override as StandardMaterial3D
	m.albedo_color = Color(0.95, 0.86, 0.66)
	m.emission = Color(1.0, 0.7, 0.32)
	m.emission_energy_multiplier = 1.2
	c.rotation = Vector3(-PI * 0.3, 0, 0)   # tipped up towards whoever she shows it to
	n.add_child(c)
	for s in [["L", 1.0], ["R", -1.0]]:
		var g := Node3D.new()
		g.name = String(s[0])
		g.position = Vector3(0.05 * float(s[1]), -0.01, -0.01)
		n.add_child(g)
	return n


## Both of a 3D figure's hands on a holder's "L" and "R" holds.
static func _hands_on(f, holder: Node3D, secs := 0.3) -> void:
	if f is Figure3D and holder != null:
		(f as Figure3D).reach(holder.get_node("L"), holder.get_node("R"), secs)
## The moth's model is drawn tiny; this makes its wingspan about half a metre.
const MOTH_SIZE := 1.8


## The Lantern Moth in flight: Gary's model, wings beating, carrying its own
## warm light and a trail of sparks, turning to face the way it flies.
class LanternMothFlight:
	extends Node3D
	var model: Node3D
	var _last := Vector3.ZERO
	var _have_last := false

	func _ready() -> void:
		var path := "res://assets/models/creatures/lantern_moth.glb"
		if ResourceLoader.exists(path):
			model = load(path).instantiate()
		else:
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.05
			sm.height = 0.1
			mi.mesh = sm
			model = mi
		# the model stands upright facing +Z: tip it forward into flight
		model.rotation = Vector3(deg_to_rad(50.0), PI, 0.0)
		add_child(model)
		WingFlap.attach(model)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.74, 0.36)
		l.light_energy = 2.4
		l.omni_range = 3.5
		l.position = Vector3(0, 0.05, 0)
		add_child(l)
		var p := GPUParticles3D.new()
		p.amount = 36
		p.lifetime = 0.9
		p.local_coords = false
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 40.0
		pm.initial_velocity_min = 0.05
		pm.initial_velocity_max = 0.25
		pm.gravity = Vector3(0, -0.35, 0)
		pm.scale_min = 0.4
		pm.scale_max = 1.0
		var sc := Curve.new()
		sc.add_point(Vector2(0, 1))
		sc.add_point(Vector2(1, 0))
		var sct := CurveTexture.new()
		sct.curve = sc
		pm.scale_curve = sct
		p.process_material = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.035, 0.035)
		p.draw_pass_1 = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_color = Color(1.0, 0.78, 0.4)
		p.material_override = m
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(p)

	## Moves to `pos`, turning to face along the way it's going.
	func fly_to(pos: Vector3) -> void:
		if _have_last:
			var d := pos - _last
			var flat := Vector3(d.x, 0.0, d.z)
			if flat.length() > 0.0005:
				var want := Basis.looking_at(flat.normalized(), Vector3.UP).get_rotation_quaternion()
				var now := basis.get_rotation_quaternion()
				basis = Basis(now.slerp(want, 0.25)).scaled(scale)
		global_position = pos
		_last = pos
		_have_last = true



# ========================================================== the first deck ===

## The village's colours for the falling Sigils.
const SIGIL_COLS := [Color(1.0, 0.25, 0.12), Color(1.0, 0.55, 0.12), Color(1.0, 0.85, 0.35), Color(0.35, 0.7, 1.0),
	Color(0.65, 0.3, 1.0), Color(0.2, 1.0, 0.8), Color(0.45, 1.0, 0.3), Color(1.0, 0.35, 0.7)]


## A small leather card box with brass corners: Bram's Spark deck.
static func _card_box() -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.075, 0.1, 0.04)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.32, 0.18, 0.09)
	m.roughness = 0.75
	mi.material_override = m
	n.add_child(mi)
	var trim := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.078, 0.012, 0.042)
	trim.mesh = tb
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.75, 0.58, 0.25)
	tm.metallic = 0.8
	tm.roughness = 0.35
	trim.material_override = tm
	trim.position.y = 0.035
	n.add_child(trim)
	return n


## Puts a prop in someone's hand (a 3D figure's right hand; beside a cut-out).
static func _hold(w: World, who: String, node: Node3D) -> Node3D:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		(f as Figure3D).hand_light(node)
		node.position = Vector3(0.0, 0.06, 0.04)
		return node
	var b := Cine.body(w, who)
	if b != null:
		b.add_child(node)
		node.position = Vector3(0.32, 0.95, 0.15)
	return node


static func _drop(w: World, who: String) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		(f as Figure3D).hand_light(null)


## Bram's brisk walk over to the Lantern Duel (m/s), and how far off the
## pair he waits, listening, until Corin says the player has no deck.
const BRAM_PACE := 2.0
const BRAM_HANG_BACK := 2.6
## How far from the Great Lantern's centre a walk keeps (its base and steps).
const LANTERN_CLEAR := 2.3


## Where Bram ends up: beside the player, on his side of them, facing Corin.
static func _bram_stop(w: World) -> Vector3:
	var p := w.player.global_position
	var c := Cine.body(w, "corin").global_position
	var d := p - c
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.BACK
	var perp := d.cross(Vector3.UP).normalized()
	if perp.dot(Cine.body(w, "bram").global_position - p) < 0.0:
		perp = -perp
	return p + perp * 1.5 + d * 0.4


## The way from one spot to another round the Great Lantern (straight when
## it isn't in the way), as points for Cine.path.
static func _round_lantern(w: World, from: Vector3, to: Vector3, depth := 0) -> Array:
	var v := village(w)
	if v == null:
		return [to]
	var o := Vector2(v.great_lantern_top.x, v.great_lantern_top.z)
	var a := Vector2(from.x, from.z)
	var ab := Vector2(to.x, to.z) - a
	var t := clampf((o - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var q := a + ab * t
	if q.distance_to(o) >= LANTERN_CLEAR or depth > 2:
		return [to]
	var out := q - o
	if out.length() < 0.01:
		out = Vector2(-ab.y, ab.x)
	var p2 := o + out.normalized() * (LANTERN_CLEAR + 0.25)
	var p := Vector3(p2.x, from.y, p2.y)
	return _round_lantern(w, from, p, depth + 1) + _round_lantern(w, p, to, depth + 1)


## The moment the player starts talking to Corin, Bram leaves his spot and
## heads over at a brisk walk, round the Great Lantern, to stand just off
## the pair, listening. He's there to step in when Corin says "no deck".
static func _bram_sets_off(w: World) -> void:
	var bram := Cine.body(w, "bram")
	if bram == null or Cine.body(w, "corin") == null:
		return
	if not w.has_meta("bram_post"):
		w.set_meta("bram_post", bram.global_position)
	var stop := _bram_stop(w)
	w.set_meta("bram_stop", stop)
	var from := bram.global_position
	var back := from - stop
	back.y = 0.0
	if back.length() <= BRAM_HANG_BACK:
		Cine.look(w, "bram", w.player.global_position)
		return
	var near := stop + back.normalized() * BRAM_HANG_BACK
	await Cine.path(w, "bram", _round_lantern(w, from, near), BRAM_PACE)
	# still his own walk (not taken over by the scene): turn to listen
	if Cine.fig(w, "bram") != null and not Cine.fig(w, "bram").walking:
		Cine.look(w, "bram", w.player.global_position)


## "Not yet": Bram goes back to where he was.
static func _bram_goes_back(w: World) -> void:
	var bram := Cine.body(w, "bram")
	if bram == null or not w.has_meta("bram_post"):
		return
	var post: Vector3 = w.get_meta("bram_post")
	w.remove_meta("bram_stop")
	await Cine.path(w, "bram", _round_lantern(w, bram.global_position, post), 1.5)


## Bram steps in beside the player with a card box in his hand (he set off
## when the conversation started, so he's only a few steps away).
static func _bram_comes(w: World) -> void:
	var p := w.player.global_position
	var corin := Cine.body(w, "corin")
	var bram := Cine.body(w, "bram")
	if bram == null or corin == null:
		return
	var c := corin.global_position
	var stop: Vector3 = w.get_meta("bram_stop") if w.has_meta("bram_stop") else _bram_stop(w)
	w.set_meta("bram_stop", stop)
	var d := p - c
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.BACK
	var perp := d.cross(Vector3.UP).normalized()
	if perp.dot(stop - p) < 0.0:
		perp = -perp
	w.cine = true
	var mid := (p + c + stop) / 3.0
	var side := -perp
	Cine.move(w, mid + side * 5.6 + d * 2.2 + Vector3(0, 2.4, 0), mid + Vector3(0, 1.2, 0), 0.8)
	_hold(w, "bram", _card_box())
	Cine.look(w, "corin", bram.global_position)
	Cine.look(w, "player", bram.global_position)
	await Cine.path(w, "bram", _round_lantern(w, bram.global_position, stop), BRAM_PACE)
	Cine.look(w, "bram", p)
	Cine.look(w, "player", stop)
	await Cine.wait(w, 0.15)


## Bram holds out the box, the player takes it, and it's theirs: the Spark
## deck, Deck and Codex open up in the pack.
static func _first_deck(w: World) -> void:
	var stop: Vector3 = w.get_meta("bram_stop", Cine.body(w, "bram").global_position)
	var p := w.player.global_position
	var mid := (p + stop) * 0.5
	var d := stop - p
	d.y = 0.0
	var perp := d.normalized().cross(Vector3.UP)
	Cine.shot(w, mid + perp * 2.6 + Vector3(0, 1.55, 0), mid + Vector3(0, 1.15, 0), 34.0)
	var f = Cine.fig(w, "bram")
	if f is Figure3D:
		(f as Figure3D).pose("play_card", 0.45)
	await Cine.wait(w, 0.7)
	_drop(w, "bram")
	var box := _hold(w, "player", _card_box())
	var pf = Cine.fig(w, "player")
	if pf is Figure3D:
		(pf as Figure3D).pose("play_card", 0.35)
	if f is Figure3D:
		(f as Figure3D).release()
	await Cine.wait(w, 0.6)
	await Cine.reveal(w, PLAYER_DECK, "YOUR FIRST DECK", "Bram's Spark deck · twelve cards")
	_give_first_deck()
	if pf is Figure3D:
		(pf as Figure3D).release()
	_drop(w, "player")
	if is_instance_valid(box):
		box.queue_free()
	w.hud.toast("New in your pack: Deck and Codex")
	await Cine.wait(w, 0.3)


## The Spark deck becomes the player's, and their pack opens up.
static func _give_first_deck() -> void:
	if Game.has_method("give_first_deck"):
		Game.call("give_first_deck", PLAYER_DECK)
	else:
		var v: Dictionary = Game.v2
		if v.is_empty():
			v = Game.new_v2("")
			Game.v2 = v
		v.deck = PLAYER_DECK.duplicate()
		for id in PLAYER_DECK:
			v.collection[id] = int(v.collection.get(id, 0)) + 1
			v.bonded[id] = true
			v.codex[id] = "seen"
	for feature in ["deck", "codex"]:
		if Game.has_method("unlock"):
			Game.call("unlock", feature)
	Game.set_flag("first_deck")
	Game.save_game()


## Bram shows the player round their pack, one gated step at a time.
static func _pack_tour(w: World) -> void:
	await w.cine_home(0.6)
	if w.hud.has_method("pack_tour"):
		await w.hud.call("pack_tour", PACK_TOUR)


## After the duel, Tilly comes running through the crowd with her Lantern
## Moth glowing in her hands, stops in front of the player and holds it out.
## It passes over while she speaks (_tilly_hands_over, on "You keep it"),
## then the card shows (_tilly_card).
static func _tilly_gift(w: World) -> void:
	var tilly := Cine.body(w, "tilly")
	if tilly == null:
		return
	var p := w.player.global_position
	var from := tilly.global_position
	var d := from - p
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.BACK
	var stop := p + d * 1.05
	w.cine = true
	var side := d.cross(Vector3.UP).normalized()
	Cine.shot(w, p - d * 2.4 + side * 1.6 + Vector3(0, 1.9, 0), stop + Vector3(0, 0.9, 0), 38.0)
	Cine.look(w, "player", from)
	# her card glowing in her hands as she runs (a 3D Tilly holds it in both)
	var v := village(w)
	var tf = Cine.fig(w, "tilly")
	var glow: Node3D
	if tf is Figure3D:
		glow = _moth_card(v)
		v.glow_sprite(glow, Vector3.ZERO, Color(1.0, 0.72, 0.32), 0.45, 0.8)
		(tf as Figure3D).carry(glow, TILLY_HOLD)
		_hands_on(tf, glow, 0.2)
	else:
		glow = v.glow_sprite(tilly, Vector3(0.0, TILLY_HANDS, 0.2), Color(1.0, 0.72, 0.32), 0.45, 0.8)
	await Cine.path(w, "tilly", [stop], 3.4, "run")
	Cine.look(w, "tilly", p)
	await Cine.hop(w, "tilly", 0.12)
	# side on, to see the card cross from her hands to yours (her painted
	# cut-out is drawn full height, so that needs a wider shot than her model)
	var mid := (p + stop) * 0.5
	if tf is Figure3D:
		Cine.shot(w, mid + side * 3.3 + Vector3(0, 1.3, 0), mid + Vector3(0, 1.0, 0), 38.0)
	else:
		Cine.shot(w, mid + side * 4.6 + Vector3(0, 1.45, 0), mid + Vector3(0, 1.15, 0), 38.0)
	# she holds it out to you, arms up and forward
	var out := w.create_tween()
	if tf is Figure3D:
		out.tween_property(glow, "position", TILLY_HOLD_OUT, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		out.tween_property(glow, "global_position", glow.global_position - d * 0.22 + Vector3(0, 0.12, 0), 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await out.finished
	w.set_meta("tilly_glow", glow)
	w.set_meta("tilly_handed", false)
	await Cine.wait(w, 0.2)


## On Tilly's words "You keep it" (played while her line is up), the light
## passes from her hands into the player's, and they take it.
static func _tilly_hands_over(w: World) -> void:
	var glow = w.get_meta("tilly_glow", null)
	if glow == null or not is_instance_valid(glow) or w.get_meta("tilly_handed", true):
		return
	var tilly := Cine.body(w, "tilly")
	var p := w.player.global_position
	var d := (tilly.global_position - p) if tilly != null else Vector3.BACK
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.BACK
	var pf = Cine.fig(w, "player")
	var tf = Cine.fig(w, "tilly")
	# it leaves her hands (a 3D Tilly lets go as it rises out of them), and
	# turns as it crosses so its face ends up towards you
	var g3 := (glow as Node3D).get_parent() != w and tf is Figure3D
	if g3:
		(glow as Node3D).reparent(w)
		(tf as Figure3D).let_go(0.5)
	# a little arc, brightening as it crosses
	var from: Vector3 = glow.global_position
	var to := p + Vector3(0, 1.05, 0) + d * 0.3
	var s0: Vector3 = glow.scale
	var b0: Basis = (glow as Node3D).global_basis
	var gt := w.create_tween()
	gt.tween_method(func(u: float) -> void:
		if is_instance_valid(glow):
			glow.global_position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 0.12, 0)
			if g3:
				glow.global_basis = Basis(Vector3.UP, PI * u) * b0
			glow.scale = s0 * (1.0 + sin(u * PI) * 0.35), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	# you reach out and take it
	if pf is Figure3D:
		if g3:
			await Cine.wait(w, 0.35)
			_hands_on(pf, glow, 0.4)
		else:
			(pf as Figure3D).pose("play_card", 0.3)
	await gt.finished
	w.set_meta("tilly_handed", true)


## The card in the player's hands shows on screen: NEW SIGIL, Tilly's
## Lantern Moth. (If her line was tapped past before the card got there,
## it lands first.)
static func _tilly_card(w: World) -> void:
	var glow = w.get_meta("tilly_glow", null)
	var waited := 0.0
	while glow != null and is_instance_valid(glow) and not w.get_meta("tilly_handed", true) and waited < 3.0:
		await w.get_tree().process_frame
		waited += w.get_process_delta_time()
	var pf = Cine.fig(w, "player")
	var tf = Cine.fig(w, "tilly")
	if tf is Figure3D:
		(tf as Figure3D).let_go(0.3)   # (if it never left her hands)
	# a 3D player keeps it in their hands through the reveal
	var in_hands: bool = pf is Figure3D and (pf as Figure3D).reaching()
	if glow != null and is_instance_valid(glow) and not in_hands:
		await Cine.wait(w, 0.25)
		glow.queue_free()
	w.remove_meta("tilly_glow")
	w.set_meta("tilly_handed", true)
	await Cine.reveal(w, ["lantern_moth"], "NEW SIGIL", "Tilly's Lantern Moth")
	if pf is Figure3D:
		(pf as Figure3D).release()
		if in_hands:
			(pf as Figure3D).let_go(0.3)
			if glow != null and is_instance_valid(glow):
				var away := w.create_tween()
				away.tween_property(glow, "scale", Vector3.ONE * 0.01, 0.3)
				away.tween_callback(glow.queue_free)
	_give_card("lantern_moth")
	Game.set_flag("has_lantern_moth")
	Game.set_flag("moth_given")


## Puts a card in the player's v2 collection (owned, and in the Codex).
static func _give_card(id: String) -> void:
	var v: Dictionary = Game.v2
	if v.is_empty() or not DuelCards.CARDS.has(id):
		return
	v.collection[id] = int(v.collection.get(id, 0)) + 1
	v.bonded[id] = true
	v.codex[id] = "seen"


# =============================================================== the film ===
## From midnight on, the Prologue is a film: everyone moves to their marks,
## the camera tells it, and the words are subtitles between the bars.

## Where everyone stands round the Great Lantern at midnight.
const MID := {
	"player": Vector3(-0.8, 0, 4.6), "bram": Vector3(1.5, 0, 5.0), "corin": Vector3(-2.6, 0, 4.0),
	"tilly": Vector3(3.8, 0, 0.9), "tam": Vector3(5.4, 0, -0.8), "nell": Vector3(-4.2, 0, 1.6),
	"hob": Vector3(6.2, 0, 1.6), "ned": Vector3(-5.2, 0, -0.4),
}
## The rest of Ashford, round the green (cut-outs until there are villagers).
## They stand on the far side of the Lantern and round its flanks, so the
## camera (on the near side, behind Bram, Corin and you) sees their faces.
const CROWD := [["v1", "farmer", Vector3(-2.4, 0, -3.0)], ["v2", "merchant", Vector3(0.9, 0, -3.6)],
	["v3", "refugee", Vector3(3.5, 0, -2.8)], ["v4", "trader", Vector3(-4.6, 0, -2.2)],
	["v5", "child_b", Vector3(0.6, 0, -2.4)], ["v6", "elder", Vector3(5.8, 0, -2.6)],
	["v7", "farmer", Vector3(-6.6, 0, 0.2)], ["v8", "merchant", Vector3(2.2, 0, -5.0)],
	["v9", "child_c", Vector3(2.4, 0, -2.0)], ["v10", "trader", Vector3(-1.0, 0, -5.2)]]


## Everyone to their marks for a scene, at once (behind a fade).
static func _stage(w: World, marks: Dictionary, look_at = null) -> void:
	for who in marks:
		var at: Vector3 = marks[who]
		# anyone still down in the taproom or the cellar (built well below the
		# village) comes up onto the ground first, so place() sets them on it
		var sb := Cine.body(w, String(who))
		if sb != null and sb.global_position.y < Cine.ground(w, at) - 5.0:
			sb.global_position = Vector3(at.x, Cine.ground(w, at), at.z)
		var face_to = look_at
		if face_to == null:
			face_to = Vector3.ZERO
		Cine.place(w, String(who), at, face_to)
		var f = Cine.fig(w, String(who))
		if f is Figure3D:
			(f as Figure3D).release(0.0)
			(f as Figure3D).talking = false
		if f != null:
			f.walking = false
			f.visible = true
	for n in w.npcs:
		n.doll.set_marker("")


## The crowd round the green (made once, then moved where they're wanted).
## The night the riders come, they stand bunched on the near side of the
## green, facing the road.
const CROWD_NIGHT := [Vector3(-3.1, 0, 8.1), Vector3(-0.7, 0, 8.5), Vector3(2.1, 0, 8.9), Vector3(-5.2, 0, 8.6),
	Vector3(-1.6, 0, 7.1), Vector3(-6.4, 0, 10.6), Vector3(-8.5, 0, 4.9), Vector3(2.8, 0, 10.4),
	Vector3(-5.8, 0, 1.9), Vector3(0.8, 0, 9.9)]


static func _crowd(w: World, at := [], face_to := Vector3.ZERO) -> void:
	for i in CROWD.size():
		var c: Array = CROWD[i]
		var id: String = c[0]
		var pos: Vector3 = at[i] if i < at.size() else c[2]
		if Cine.body(w, id) == null:
			Cine.spawn(w, id, c[1], pos)
		Cine.place(w, id, pos, face_to)


static func _clear_crowd(w: World) -> void:
	for c in CROWD:
		Cine.despawn(w, String(c[0]))


## Plays the Prologue's film from `part` to the end, saving at each part so a
## closed game picks it up again there.
static func _prologue_film(w: World, part: String) -> void:
	var parts := ["dawn", "taproom", "burning", "cellar"]
	var i0 := maxi(0, parts.find(part))
	for i in range(i0, parts.size()):
		Game.set_flag("pro_part", parts[i])
		Game.save_game()
		match parts[i]:
			"dawn":
				await _dawn(w)
			"taproom":
				await _taproom(w)
			"burning":
				await _burning(w)
			"cellar":
				await _cellar(w)
	Game.set_flag("pro_tunnel_done")
	Game.save_game()
	w.story_next.emit("thornwood")


# ------------------------------------------------------- P2 · midnight ---

## Midnight (Master Script v3, P2): the player lights the Great Lantern, Tam
## dances with Nell, badly; the sky lanterns go up and stop, the sky tears,
## the Sigils fall. Corin is pinned under Tam's cart and dragged clear; one
## white light comes down to the player, and leaves them a blank card and a
## mark on their hand.
static func _midnight(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.6)
	_stage(w, MID)
	_crowd(w)
	var top: Vector3 = v.great_lantern_top if v.great_lantern_top != Vector3.ZERO else Vector3(0, 8.0, 0)
	# the bell, and everyone waiting under the Lantern
	Cine.shot(w, Vector3(3.2, 1.0, 12.5), top * 0.55, 34.0)
	Cine.fade(w, 0.0, 1.2)
	Cine.drift(w, Vector3(3.2, 1.0, 12.5), Vector3(2.2, 1.3, 10.0), top * 0.55, top * 0.62, 7.0)
	_bell(w, 12)
	await Cine.say(w, "", "Midnight. The chapel bell counts twelve, and all of Ashford counts with it.")
	await Cine.wait(w, 1.0)
	# you walk up with a lit taper and light it (the Lantern Duel can't be lost)
	var lighter := "player"
	var at: Vector3 = Vector3(-0.3, 0, 1.85)
	var taper := _taper(v)
	_hold(w, lighter, taper)
	# from the west side of the green: you walk up to the Lantern's steps
	Cine.shot(w, Vector3(-3.6, 1.35, 2.6), Vector3(-0.4, 1.3, 2.8), 40.0)
	await Cine.walk(w, lighter, at, 1.2)
	Cine.look(w, lighter, Vector3.ZERO)
	Cine.shot(w, at + Vector3(1.2, 0.5, 2.0), top - Vector3(0, 1.2, 0), 46.0)
	var lf = Cine.fig(w, lighter)
	if lf is Figure3D:
		(lf as Figure3D).act("play_card", 0.8)
	await Cine.wait(w, 0.9)
	v.light_great_lantern()
	w.shake(0.15)
	_drop(w, lighter)
	await Cine.wait(w, 0.5)
	Cine.drift(w, Vector3(-3.8, 2.2, 7.6), Vector3(-3.2, 2.5, 6.6), Vector3(0, 3.0, 0.6), Vector3(0, 3.4, 0.6), 3.5, 44.0)
	for c in CROWD:
		Cine.hop(w, String(c[0]), 0.22)
	for who in ["tilly", "hob", "tam"]:
		Cine.act(w, who, "cheer")   # a cut-out (Hob) hops
	for who in ["bram", "corin"]:
		Cine.act(w, who, "cheer")
	await Cine.wait(w, 2.6)
	Cine.walk(w, lighter, MID[lighter], 1.3)
	# Tam is dancing with Nell, badly
	var dance := _dance_spot()
	Cine.place(w, "tam", dance[0], dance[1])
	Cine.place(w, "nell", dance[1], dance[0])
	for who in ["tam", "nell"]:
		var df = Cine.fig(w, who)
		if df is Figure3D:
			(df as Figure3D).hold("dance")
	var dmid: Vector3 = (dance[0] + dance[1]) * 0.5
	Cine.shot(w, dmid + Vector3(-2.0, 1.45, 3.6), dmid + Vector3(0, 1.0, 0), 36.0)
	if not (Cine.fig(w, "nell") is Figure3D):
		for k in 3:   # a cut-out Nell bobs along
			await Cine.hop(w, "nell", 0.08)
			await Cine.wait(w, 0.35)
	else:
		await Cine.wait(w, 2.4)
	# by the lantern's new light: Corin beside you, watching the crowd
	Cine.look(w, "corin", dmid)
	Cine.look(w, "player", dmid)
	Cine.two_shot(w, "corin", "player", 3.6, 1.55, -1.0, 34.0)
	await Cine.say(w, "corin", "It's a good village, this. Don't tell anyone I said so.")
	Cine.over_shoulder(w, "player", "bram", 1.0, 30.0)
	Cine.look(w, "bram", top)
	await Cine.say(w, "bram", "Folk think we send them up for the gods. We don't. A lantern's for whoever's out in the dark, so they know which way is home.")
	await Cine.say(w, "bram", "Two thousand years. Wonder who'll be sitting up there tomorrow.")
	Cine.look(w, "bram", Cine.body(w, "player").global_position)
	var pick := await Cine.choose(w, ["Does it matter to us?", "Whoever it is owes us a better year."])
	if pick == 0:
		await Cine.say(w, "bram", "It shouldn't. It always seems to.")
	else:
		# a short laugh, then
		var bf0 = Cine.fig(w, "bram")
		if bf0 is Figure3D:
			(bf0 as Figure3D).talking = true
		await Cine.wait(w, 0.5)
		await Cine.say(w, "bram", "Write and tell them. See who writes back.")
	# the sky lanterns go up, and stop; the fiddle trails off
	v.release_lanterns()
	for who in ["tam", "nell"]:
		var df = Cine.fig(w, who)
		if df is Figure3D:
			(df as Figure3D).release(0.6)
	for who in ["bram", "corin", "player", "tam", "tilly", "nell"]:
		Cine.look(w, who, top)
	Cine.shot(w, Vector3(1.0, 0.6, 9.0), Vector3(0.0, 6.0, -2.0), 52.0)
	await Cine.drift(w, Vector3(1.0, 0.6, 9.0), Vector3(-2.0, 5.5, 14.0), Vector3(0.0, 6.0, -2.0), Vector3(4.0, 22.0, -18.0), 7.0, 52.0)
	Music.stop(3.0)
	await Cine.drift(w, Vector3(-2.0, 5.5, 14.0), Vector3(-3.0, 7.0, 16.0), Vector3(4.0, 22.0, -18.0), Vector3(8.0, 30.0, -24.0), 4.0)
	# heads up, and they stay up (the clip looks up and comes back down)
	for who in ["bram", "corin", "player", "tam", "tilly", "nell"]:
		var f = Cine.fig(w, who)
		if f is Figure3D:
			(f as Figure3D).pose("look_up", 0.5, 0.9)
	# from under the Lantern, their faces turned up to the sky
	Cine.shot(w, Vector3(-0.5, 0.95, 1.7), Vector3(-0.6, 1.75, 4.6), 44.0)
	await Cine.wait(w, 1.8)
	Cine.shot(w, Vector3(4.0, 1.2, 8.8), Vector3(8.0, 40.0, -30.0), 50.0)
	await Cine.wait(w, 2.2)
	await Cine.say(w, "corin", "Bram. Is it meant to do that?")
	# the sky tears
	Cine.shot(w, Vector3(6.0, 3.0, 20.0), Vector3(34.0, 22.0, -40.0), 50.0)
	await Cine.wait(w, 0.6)
	v.start_sigilfall()
	Music.play(["sigilfall"], 0.5, true)
	_sfx(w, "sigil_strike")
	await w.flash(Color(0.9, 0.92, 1.0), 0.25, 1.2)
	Cine.drift(w, Vector3(6.0, 3.0, 20.0), Vector3(4.0, 2.2, 16.0), Vector3(34.0, 22.0, -40.0), Vector3(20.0, 16.0, -40.0), 4.0)
	await Cine.wait(w, 1.6)
	# for a breath the children cheer
	var kids_cam := Vector3(1.8, 0.9, 1.7)
	Cine.shot(w, kids_cam, Vector3(1.5, 1.0, -2.3), 40.0)
	for id in ["v5", "v9"]:
		Cine.look(w, id, kids_cam)
		Cine.hop(w, id, 0.3)
	await Cine.wait(w, 0.5)
	for id in ["v5", "v9"]:
		Cine.hop(w, id, 0.3)
	await Cine.wait(w, 0.9)
	# the first one comes down in the top field
	Cine.shot(w, Vector3(-6.0, 3.5, 12.0), Vector3(-24.0, 6.0, -26.0), 46.0)
	v.first_impact()
	w.shake(0.6)
	_sfx(w, "sigil_strike")
	await Cine.wait(w, 1.4)
	# and one on the mill
	var mill_top := v.mill_fire_point() if v.mill_root != null else Vector3(62, 40, -88)
	Cine.shot(w, AshfordVillage.MILL_VIEW_FROM, mill_top, 22.0)
	await v.strike(mill_top + Vector3(0, 0.6, 0), Color(1.0, 0.55, 0.12), 0.5)
	v.fire_mill()
	w.shake(0.25)
	await Cine.wait(w, 1.4)
	# Nell, and the mill burning up the hill behind her
	var np0 := Cine.body(w, "nell").global_position
	var dm := mill_top - np0
	dm.y = 0.0
	dm = dm.normalized()
	var sd := dm.cross(Vector3.UP)
	Cine.look(w, "nell", mill_top)
	# her face, the fire in her eyes (the mill is behind the camera)
	Cine.shot(w, np0 + dm * 2.8 + sd * 1.6 + Vector3(0, 1.45, 0), np0 + Vector3(0, 1.45, 0), 34.0)
	await Cine.say(w, "nell", "The mill! The mill's on fire!", 2.2)
	for who in ["bram", "corin", "player", "tam", "tilly", "nell"]:
		var f = Cine.fig(w, who)
		if f is Figure3D:
			(f as Figure3D).release()
	Cine.look(w, "bram", Cine.body(w, "player").global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 28.0)
	w.shake(0.2)
	await Cine.say(w, "bram", "Inside! Everyone inside! Sprout, the inn. Now!", 2.6)
	await _the_run(w)
	await _the_cart(w)
	await _the_white_light(w)


## Where Tam and Nell dance at midnight, on the open east side of the green,
## clear of the crowd: [Tam, Nell].
static func _dance_spot() -> Array:
	return [Vector3(5.0, 0, 3.4), Vector3(5.8, 0, 3.9)]


## Cine.drift, but handing back its tween so a cut can stop it.
static func _drift_tween(w: World, pos_a: Vector3, pos_b: Vector3, look_a: Vector3, look_b: Vector3, secs: float, fov := -1.0) -> Tween:
	w.cine = true
	if fov > 0.0:
		w.cam.fov = fov
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		w.cam.global_position = pos_a.lerp(pos_b, u)
		w.cam.look_at(look_a.lerp(look_b, u), Vector3.UP), 0.0, 1.0, maxf(secs, 0.01))
	return tw


## The bell at midnight: six tolls as it counts twelve.
static func _bell(w: World, times: int) -> void:
	for i in times:
		_sfx(w, "bell_toll")
		await Cine.wait(w, 1.15)


## A lit taper: a little flame on a stick.
static func _taper(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	var stick := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.008
	cm.bottom_radius = 0.01
	cm.height = 0.45
	stick.mesh = cm
	stick.material_override = v.mats.beam_v
	stick.position = Vector3(0, 0.18, 0)
	n.add_child(stick)
	var g := v.glow_sprite(n, Vector3(0, 0.43, 0), Color(1.0, 0.62, 0.25), 0.22, 1.2)
	g.name = "Flame"
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = 1.4
	l.omni_range = 4.0
	l.position = Vector3(0, 0.45, 0)
	n.add_child(l)
	return n


## Sound effects for the film (a placeholder is synthesised until the file exists).
static func _sfx(w: World, sound: String, pitch := 1.0) -> void:
	var s: Sfx
	if w.has_meta("film_sfx") and is_instance_valid(w.get_meta("film_sfx")):
		s = w.get_meta("film_sfx")
	else:
		s = Sfx.new()
		w.add_child(s)
		w.set_meta("film_sfx", s)
	s.play(sound, pitch)


## Panic on the green. The player runs for the inn and a strike knocks them
## flat; Corin grabs Tilly and runs her for home, past Tam's cart.
static func _the_run(w: World) -> void:
	var v := village(w)
	# everyone scatters for their doors
	# (Nell and the child on the south-west side go round behind the camera
	# that follows you, not through it)
	var doors := {"v1": Vector3(-14, 0, 14), "v2": Vector3(4, 0, 18), "v3": Vector3(16, 0, 12), "v4": Vector3(-17, 0, 8),
		"v5": [Vector3(2, 0, 12), Vector3(-6, 0, 16)], "v6": Vector3(18, 0, -2), "v7": Vector3(-18, 0, 0), "v8": Vector3(14, 0, -10),
		"v9": Vector3(-12, 0, -10), "v10": Vector3(6, 0, 18), "nell": [Vector3(0, 0, 13), Vector3(-10, 0, 12)], "hob": Vector3(16, 0, 6),
		"ned": Vector3(-15, 0, -6), "tam": Vector3(12, 0, -16)}
	for who in doors:
		var way: Array = doors[who] if doors[who] is Array else [doors[who]]
		Cine.path(w, String(who), way, 3.0 + randf() * 1.2, "run")
	# Corin grabs Tilly and runs her up the lane towards the mill, past the cart
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	var lane_a := cc + fd * 2.6 - al * 3.5
	var lane_b := cc + fd * 2.6 + al * 0.1
	w.set_meta("corin_pinned_at", lane_b)
	_corin_and_tilly(w, lane_a, lane_b)
	# the player runs west for the inn
	var run_a := Vector3(-4.6, 0, 6.0)
	var run_b := Vector3(-8.2, 0, 6.8)
	Cine.shot(w, Vector3(3.6, 2.0, 8.8), Vector3(-3.0, 1.2, 5.0), 44.0)
	Cine.follow(w, "player", Vector3(4.6, 2.0, 2.6), Vector3(-2.0, 1.1, 0.0), 2.4, 3.0)
	_strike_later(w, Vector3(-6.8, 0, 9.6), SIGIL_COLS[3], 0.55)
	_strike_later(w, Vector3(-3.0, 0, 1.2), SIGIL_COLS[1], 1.1)
	await Cine.path(w, "player", [run_a, run_b], 4.4, "run")
	await v.strike(Vector3(-9.6, 0, 5.4), SIGIL_COLS[4], 0.25)
	w.shake(0.5)
	_sfx(w, "sigil_strike")
	var pf = Cine.fig(w, "player")
	if pf is Figure3D:
		(pf as Figure3D).act("fall")
	await Cine.wait(w, 0.9)


static func _strike_later(w: World, at: Vector3, col: Color, after: float) -> void:
	await Cine.wait(w, after)
	await village(w).strike(at, col, 0.35)
	_sfx(w, "sigil_strike", randf_range(0.9, 1.2))
	w.shake(0.2)


static func _corin_and_tilly(w: World, lane_a: Vector3, lane_b: Vector3) -> void:
	var tilly := Cine.body(w, "tilly")
	var corin := Cine.body(w, "corin")
	# he comes up on her far side from the lane, takes her hand, and they run
	# side by side (she on his right as they go, in step with him)
	var run_dir := lane_b - lane_a
	run_dir.y = 0.0
	run_dir = run_dir.normalized()
	var beside := run_dir.cross(Vector3.UP).normalized() * 0.62   # his right, as he runs
	await Cine.path(w, "corin", [tilly.global_position - beside], 4.6, "run")
	if Cine.fig(w, "tilly") is Figure3D and Cine.fig(w, "corin") is Figure3D:
		Cine.look(w, "corin", lane_a)
		Cine.look(w, "tilly", lane_a + beside)
		Cine.hold_hands(w, "corin", "tilly", 0.15)
	var gap := tilly.global_position - corin.global_position
	gap.y = 0.0
	# in step with him to the cart; when it goes over she runs on (the cart
	# lets go of their hands, _the_cart)
	Cine.path(w, "tilly", [lane_a + gap, lane_b + gap, lane_b + run_dir * 1.6 + gap], 3.6, "run")
	await Cine.path(w, "corin", [lane_a, lane_b], 3.6, "run")


## The cart: a strike lands beside it, it goes over on Corin, and Tilly
## screams for him. The player gets up and runs back; Bram is there too, and
## between them they heave it up off his leg.
static func _the_cart(w: World) -> void:
	var v := village(w)
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	# wait for Corin to come level with the cart
	var corin := Cine.body(w, "corin")
	var pin: Vector3 = w.get_meta("corin_pinned_at", cc + fd * 2.6)
	Cine.shot(w, cc + fd * 7.5 - al * 4.0 + Vector3(0, 2.2, 0), cc + fd * 1.5 + Vector3(0, 1.0, 0), 44.0)
	var guard := 0.0
	while corin.global_position.distance_to(pin) > 0.4 and guard < 4.0:
		guard += w.get_process_delta_time()
		await w.get_tree().process_frame
	# the blast on the far side throws the cart over on him
	var hit := cc - fd * 1.8 + al * 0.3
	v.strike(hit, SIGIL_COLS[0], 0.25, false)
	Cine.let_go_hands(w, "corin", "tilly", 0.12)
	await Cine.wait(w, 0.28)
	w.shake(0.7)
	_sfx(w, "sigil_strike")
	Cine.look(w, "corin", Cine.body(w, "tilly").global_position)
	v.tip_cart(1.0, 0.55)
	await Cine.wait(w, 0.3)
	var cf = Cine.fig(w, "corin")
	Cine.place(w, "corin", cc + fd * 2.7, cc + fd * 9.0)
	if cf is Figure3D:
		(cf as Figure3D).lie_down(0.3)
	await Cine.wait(w, 0.3)
	v.dust_puff(cc + fd * 2.8)
	v.dust_puff(cc + fd * 3.4 + al * 0.8)
	_sfx(w, "cart_crash")
	await Cine.hop(w, "tilly", 0.25)
	# from behind Tilly (where her run ends): Corin under the cart, beyond her
	var tb := Cine.body(w, "tilly")
	Cine.place(w, "tilly", cc + fd * 2.6 + al * 1.7 + Vector3(0.5, 0, 0.6), corin.global_position)
	var to_c := corin.global_position - tb.global_position
	to_c.y = 0.0
	to_c = to_c.normalized() if to_c.length() > 0.1 else -fd
	var aside := to_c.cross(Vector3.UP)
	Cine.shot(w, tb.global_position - to_c * 4.0 + aside * 1.6 + Vector3(0, 2.1, 0), corin.global_position + Vector3(0, 0.45, 0), 40.0)
	Cine.place(w, "tilly", tb.global_position, corin.global_position)
	await Cine.say(w, "tilly", "Corin! CORIN!", 1.6)
	# the player, getting up in the west, turns, and runs back
	var pf = Cine.fig(w, "player")
	Cine.shot(w, w.player.global_position + Vector3(-3.0, 1.4, 3.0), w.player.global_position + Vector3(0, 1.0, 0), 40.0)
	await Cine.wait(w, 1.0)
	if pf is Figure3D:
		(pf as Figure3D).release(0.2)
	Cine.look(w, "player", cc)
	await Cine.wait(w, 0.4)
	# they take hold of the top edge of the fallen cart, either side of him
	var lift_p := cc + fd * 4.05 + al * 1.05
	var lift_b := cc + fd * 4.05 - al * 1.05
	Cine.path(w, "bram", [cc + fd * 6.0 - al * 2.5, lift_b], 4.2, "run")
	Cine.follow(w, "player", Vector3(-3.5, 2.6, 4.0), Vector3(1.5, 1.0, -1.0), 3.0, 2.2)
	await Cine.path(w, "player", [Vector3(-1.0, 0, 6.0), cc + fd * 6.5 + al * 2.0, lift_p], 5.4, "run")
	Cine.place(w, "player", lift_p, cc)
	await Cine.wait(w, 0.3)
	# Tilly steps back out of their way
	Cine.place(w, "tilly", cc + fd * 3.0 + al * 3.1, corin.global_position)
	# under the cart: from the open side, the cart, Corin and the two of them
	Cine.shot(w, cc + fd * 7.6 + al * 0.6 + Vector3(0, 1.6, 0), cc + fd * 3.3 + Vector3(0, 0.8, 0), 40.0)
	await Cine.say(w, "corin", "My leg. It's stuck, I can't, I can't get it —")
	Cine.place(w, "bram", lift_b, cc)
	await Cine.say(w, "bram", "Other side. On three. One, two —", 2.6)
	# the heave
	for who in ["bram", "player"]:
		var f = Cine.fig(w, who)
		if f is Figure3D:
			(f as Figure3D).hold("lift", 0.9)
	await Cine.wait(w, 0.5)
	w.shake(0.12)
	await v.tip_cart(0.8, 1.1, Tween.TRANS_SINE, Tween.EASE_OUT)
	# Corin drags himself clear
	var drag := w.create_tween()
	drag.tween_property(corin, "global_position", corin.global_position + fd * 1.1, 0.9).set_trans(Tween.TRANS_SINE)
	await drag.finished
	await v.tip_cart(1.0, 0.22, Tween.TRANS_QUAD, Tween.EASE_IN)
	v.dust_puff(cc + fd * 3.0)
	w.shake(0.3)
	_sfx(w, "cart_crash")
	for who in ["bram", "player"]:
		var f = Cine.fig(w, who)
		if f is Figure3D:
			(f as Figure3D).release()
	if cf is Figure3D:
		await (cf as Figure3D).get_up(0.9)
	Cine.look(w, "corin", w.player.global_position)
	Cine.place(w, "tilly", corin.global_position - al * 1.1 - fd * 0.45, corin.global_position)
	# the two of them, the cart behind: he limps a step towards you
	var mid := (corin.global_position + w.player.global_position) * 0.5
	Cine.shot(w, mid + fd * 3.4 + al * 1.0 + Vector3(0, 1.5, 0), mid + Vector3(0, 1.2, 0), 36.0)
	var to_p := w.player.global_position - corin.global_position
	to_p.y = 0.0
	await _limp(w, "corin", corin.global_position + to_p.normalized() * minf(0.8, to_p.length() - 0.9), 1.4)
	Cine.look(w, "corin", w.player.global_position)
	await Cine.say(w, "corin", "I'm all right. I'm all right.")
	# he isn't: his hands are shaking
	if cf is Figure3D:
		(cf as Figure3D).pose("play_card", 0.3, 0.4)
	var hands: Vector3 = (cf as Figure3D).bone_pos("RightHand") if cf is Figure3D else corin.global_position + Vector3(0, 1.0, 0)
	var cdir := corin.global_position.direction_to(w.player.global_position)
	cdir.y = 0.0
	Cine.shot(w, hands + cdir * 1.1 + cdir.cross(Vector3.UP) * 0.5 + Vector3(0, 0.25, 0), hands + Vector3(0, -0.05, 0), 30.0)
	await _tremble(w, "corin", 2.2, 0.02)
	if cf is Figure3D:
		(cf as Figure3D).release(0.4)


## A few limping steps to `to` over `secs`: a dip on every other step.
static func _limp(w: World, who: String, to: Vector3, secs: float) -> void:
	var b := Cine.body(w, who)
	var f = Cine.fig(w, who)
	if b == null:
		return
	var from := b.global_position
	to.y = from.y
	if from.distance_to(to) < 0.05:
		return
	if f != null:
		f.face(to - from, w.cam)
		f.walking = true
		if f is Figure3D:
			(f as Figure3D).pace = from.distance_to(to) / secs
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		if is_instance_valid(b):
			var at := from.lerp(to, u)
			at.y = Cine.ground(w, at) - absf(sin(u * PI * 2.0)) * 0.06
			b.global_position = at, 0.0, 1.0, secs)
	await tw.finished
	if f != null and is_instance_valid(f):
		f.walking = false
		if f is Figure3D:
			(f as Figure3D).pace = 0.0


## Someone shaking (hands that won't keep still): the whole figure trembles,
## very slightly, for `secs`.
static func _tremble(w: World, who: String, secs: float, amp := 0.015) -> void:
	var f = Cine.fig(w, who)
	if f == null or not (f is Node3D):
		await Cine.wait(w, secs)
		return
	var n: Node3D = f
	var base := n.rotation
	var t := 0.0
	while t < secs and is_instance_valid(n):
		t += w.get_process_delta_time()
		n.rotation = base + Vector3(sin(t * 61.0) * amp * 0.6, 0.0, sin(t * 47.0 + 1.3) * amp)
		await w.get_tree().process_frame
	if is_instance_valid(n):
		n.rotation = base


## The white light: slow, silent, it passes Bram, passes Corin and stops at the
## player. A blank card in their hand, a white mark on its back, and every
## other light in the sky goes out.
static func _the_white_light(w: World) -> void:
	var v := village(w)
	Music.stop(1.5)
	Music.stinger("the_marking", false)
	var p := w.player.global_position
	var pf = Cine.fig(w, "player")
	var bram_h := Cine.head(w, "bram")
	var corin_h := Cine.head(w, "corin")
	var hand := p + ((pf as Figure3D).facing() if pf is Figure3D else Vector3.FORWARD) * 0.42 + Vector3(0, 1.22, 0)
	# the cart lies on its side behind them: cameras stay on the open side
	var open := v.cart_fall_dir()
	var along := v.cart_along()
	var pfwd: Vector3 = (pf as Figure3D).facing() if pf is Figure3D else Vector3.FORWARD
	var pside := pfwd.cross(Vector3.UP).normalized()
	var curve := Curve3D.new()
	curve.add_point(p + Vector3(-6.0, 26.0, -10.0))
	curve.add_point(p + Vector3(-3.0, 9.0, -5.0))
	curve.add_point(bram_h + Vector3(0.0, 0.7, 0.0) + (bram_h - p).normalized() * 0.6)
	curve.add_point(corin_h + Vector3(0.0, 0.6, 0.0) + (corin_h - p).normalized() * 0.5)
	curve.add_point(hand + Vector3(0, 0.5, 0))
	curve.add_point(hand)
	curve.bake_interval = 0.1
	var wl := v.white_light
	wl.visible = true
	var length := curve.get_baked_length()
	var watchers := ["bram", "corin", "player", "tilly"]
	# Tilly steps in behind Corin, out of the camera's way
	var cb := Cine.body(w, "corin")
	if Cine.body(w, "tilly") != null and cb != null:
		var away := cb.global_position - (p + Vector3(3.5, 0.0, 6.0))
		away.y = 0.0
		away = away.normalized()
		Cine.place(w, "tilly", cb.global_position + away * 0.9 + away.cross(Vector3.UP) * 0.5, cb.global_position)
	Cine.shot(w, p + Vector3(3.5, 1.4, 6.0), p + Vector3(-2.0, 7.0, -4.0), 46.0)
	var track := [true]   # the camera watches the light until the next shot takes over
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		var e := u * u * (3.0 - 2.0 * u) * 0.35 + u * 0.65
		var at := curve.sample_baked(e * length, true)
		wl.global_position = at
		for who in watchers:
			var f = Cine.fig(w, who)
			if f != null:
				f.look_toward(at, w.cam)
		if track[0]:
			w.cam.look_at(at, Vector3.UP), 0.0, 1.0, 9.5)
	await Cine.wait(w, 3.0)
	track[0] = false
	Cine.move(w, p + Vector3(2.6, 1.3, 3.2), (bram_h + corin_h) * 0.5, 2.5, 40.0)
	await Cine.wait(w, 3.4)
	if pf is Figure3D:
		(pf as Figure3D).pose("play_card", 0.42)
	Cine.move(w, hand + pfwd * 1.1 + pside * 0.55 + Vector3(0, 0.3, 0), hand - pfwd * 0.25 + Vector3(0, 0.12, 0), 2.6, 38.0)
	await tw.finished
	# it settles in your hand
	v.lights_out()
	v.hide_white_light()
	_sfx(w, "gift")
	await w.flash(Color(1, 1, 1), 0.08, 1.6)
	var holder := Node3D.new()
	var card := InnRooms.blank_card(v)
	card.rotation = Vector3(-PI * 0.35, 0, 0)
	holder.add_child(card)
	var g := v.glow_sprite(holder, Vector3(0, 0.02, 0), Color(0.85, 0.92, 1.0), 0.5, 1.4)
	var cl := OmniLight3D.new()
	cl.light_color = Color(0.85, 0.9, 1.0)
	cl.light_energy = 1.8
	cl.omni_range = 4.0
	holder.add_child(cl)
	_hold(w, "player", holder)
	w.set_meta("blank_card_glow", g)
	Cine.shot(w, hand + pfwd * 0.7 + pside * 0.35 + Vector3(0, 0.22, 0), hand - pfwd * 0.1 + Vector3(0, 0.02, 0), 34.0)
	await Cine.wait(w, 1.1)
	# and a white mark burns itself into the back of your hand
	var mark := v.glow_sprite(holder, Vector3(0.0, -0.04, -0.05), Color(0.95, 0.97, 1.0), 0.06, 2.2)
	mark.scale = Vector3.ONE * 0.01
	var mt := w.create_tween()
	mt.tween_property(mark, "scale", Vector3.ONE * 0.18, 0.22).set_trans(Tween.TRANS_QUAD)
	mt.tween_property(mark, "scale", Vector3.ONE * 0.06, 0.9).set_trans(Tween.TRANS_SINE)
	_sfx(w, "sigil_strike", 1.7)
	w.flash(Color(0.95, 0.97, 1.0), 0.04, 0.6)
	await Cine.wait(w, 1.5)
	var mid := (Cine.body(w, "corin").global_position + p) * 0.5
	Cine.shot(w, mid + open * 3.4 + along * 1.0 + Vector3(0, 1.5, 0), mid + Vector3(0, 1.2, 0), 36.0)
	Cine.look(w, "corin", p)
	await Cine.say(w, "corin", "It came to you.")
	# he looks down at his own empty hand
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		(cf as Figure3D).pose("play_card", 0.42, 0.5)
		await Cine.wait(w, 0.5)
		var ch: Vector3 = (cf as Figure3D).bone_pos("RightHand")
		var cfw: Vector3 = (cf as Figure3D).facing()
		var crt := cfw.cross(Vector3.UP)   # his right
		Cine.shot(w, ch + crt * 1.5 + cfw * 0.45 + Vector3(0, 0.3, 0), (ch + Cine.head(w, "corin")) * 0.5, 32.0)
	await Cine.wait(w, 1.8)
	await Cine.say(w, "corin", "It just came to you.")
	if cf is Figure3D:
		(cf as Figure3D).release(0.5)
	# Bram crosses to you and closes your fingers over the card; its glow dies
	# between them, and his hand is shaking too
	var bram := Cine.body(w, "bram")
	var to_p := p - bram.global_position
	to_p.y = 0.0
	await Cine.walk(w, "bram", p - to_p.normalized() * 0.62, 1.4)
	Cine.look(w, "bram", p)
	Cine.look(w, "player", bram.global_position)
	var mb := (bram.global_position + p) * 0.5
	Cine.shot(w, mb + open * 2.8 + along * 0.6 + Vector3(0, 1.55, 0), mb + Vector3(0, 1.35, 0), 32.0)
	var bfig = Cine.fig(w, "bram")
	if bfig is Figure3D:
		(bfig as Figure3D).reach(holder, null, 0.6)   # his left hand, over your right
	await Cine.wait(w, 0.7)
	var cardp: Vector3 = holder.global_position
	var pside2 := (cardp - bram.global_position).cross(Vector3.UP).normalized()
	Cine.shot(w, cardp + pside2 * 0.75 + Vector3(0, 0.3, 0) - to_p.normalized() * 0.15, cardp, 28.0)
	var gt := w.create_tween().set_parallel(true)
	gt.tween_property(cl, "light_energy", 0.0, 1.6)
	gt.tween_property(g, "scale", Vector3.ONE * 0.02, 1.6)
	gt.tween_property(mark, "scale", Vector3.ONE * 0.02, 1.6)
	await _tremble(w, "bram", 2.0, 0.012)
	Cine.shot(w, mb + open * 2.8 + along * 0.6 + Vector3(0, 1.55, 0), mb + Vector3(0, 1.35, 0), 32.0)
	await Cine.say(w, "bram", "Put that away. Don't show anyone. Not anyone.")
	if bfig is Figure3D:
		(bfig as Figure3D).let_go(0.4)
	_drop(w, "player")
	if pf is Figure3D:
		(pf as Figure3D).release()
	Game.set_flag("ash_marked")
	await Cine.fade(w, 1.0, 1.6)


# ------------------------------------------------------- P3 · dawn ---

## Where everyone stands on the green at dawn, looking up the road. Bram is
## at the player's right shoulder, close enough to put a hand on it.
const DAWN := {
	"player": Vector3(0.6, 0, 11.0), "bram": Vector3(0.42, 0, 11.68), "corin": Vector3(-1.0, 0, 10.4),
	"tilly": Vector3(-3.2, 0, 13.0), "nell": Vector3(-2.2, 0, 9.4), "tam": Vector3(3.2, 0, 9.6),
	"hob": Vector3(2.4, 0, 15.8), "ned": Vector3(-4.6, 0, 10.6),
}
## Where the Herald stops, and the road it comes down.
const HERALD_AT := Vector3(9.0, 0, 13.4)
const HERALD_ROAD := [Vector3(44.0, 0, 11.6), Vector3(30.0, 0, 13.4), Vector3(18.0, 0, 14.4), Vector3(9.0, 0, 13.4)]
## The Champions of the Turning, as the Herald's lantern shows them (v3: it
## reads out only Aldric and Crane; the other five are faces with a name
## under each, too quick to hold). [id, the Seat's god, the name written].
## Gary's portrait in assets/art/champions/<id>.png (or .jpg / .webp) is used
## when it exists; until then the Seat's sign stands in for the face, with the
## name under it.
const CHAMPIONS := [
	["aldric", "solmaris", "Ser Aldric Vane"],
	["vorn", "pyrrhane", "Warlord Vorn"],
	["eiran", "vaelith", "King Eiran"],
	["rook", "ixara", "Captain Rook"],
	["silk", "nocthra", "Silk"],
	["maelis", "oriel", "Sister Maelis"],
	["crane", "aldrith", "Magister Tobias Crane"],
]
## Everyone on the green who kneels when the Herald comes.
const KNEELERS := ["nell", "tam", "hob", "ned", "corin", "tilly", "kid"]


## Dawn (v3, P3): smoke over the hills, the mill a black shell, children
## picking Sparks out of the furrows, Hob's cabbages. A mist comes down the
## road against the wind with a Pale Herald in it; the village kneels, Bram's
## hand on your shoulder bringing you down. It reads the Covenant and two
## Champions, its lantern shows the other five, and then it names the player.
static func _dawn(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	v.set_time("dawn")
	v.set_cart_tip(1.0)
	if v.burning_house != null and v.fires.is_empty():
		v.ignite_roof()
		v.fire_mill()
		v.set_time("dawn")
	_char_mill(v)
	_clear_crowd(w)
	_stage(w, DAWN, HERALD_ROAD[1])
	Cine.place(w, "tilly", DAWN.tilly, Vector3(-4.6, 0, 13.6))
	Cine.spawn(w, "kid", "child_b", Vector3(-5.4, 0, 12.6))
	Cine.place(w, "kid", Vector3(-5.4, 0, 12.6), Vector3(-4.6, 0, 13.6))
	Music.play(["dawn_after"], 2.0, true)
	await Cine.caption(w, "Dawn")
	# the morning after, smoke over the hills
	Cine.shot(w, Vector3(-30.0, 14.0, 40.0), Vector3(8.0, 4.0, -16.0), 46.0)
	Cine.fade(w, 0.0, 1.6)
	await Cine.drift(w, Vector3(-30.0, 14.0, 40.0), Vector3(-18.0, 8.0, 31.0), Vector3(8.0, 4.0, -16.0), Vector3(6.0, 3.0, -12.0), 6.0)
	# the mill, a black shell
	if v.mill_root != null:
		# from down the lane, against the sunrise
		var mb := v.mill_root.global_position
		var ml := Vector3(mb.x, v.height(mb.x, mb.z) + 9.0, mb.z)
		var m0 := mb + Vector3(-26.0, 0, 29.0)
		var m1 := mb + Vector3(-24.0, 0, 26.5)
		m0.y = v.height(m0.x, m0.z) + 6.0
		m1.y = v.height(m1.x, m1.z) + 5.8
		Cine.drift(w, m0, m1, ml, ml + Vector3(0, -0.5, 0), 3.0, 28.0)
		await Cine.wait(w, 2.8)
	# children picking Sparks out of the furrows like conkers
	var glints: Array = []
	for i in 6:
		var gp := Vector3(-6.0 + i * 0.7 + randf_range(-0.2, 0.2), 0.06, 13.2 + randf_range(-0.8, 0.8))
		glints.append(v.glow_sprite(v, gp, SIGIL_COLS[i % SIGIL_COLS.size()], 0.35, 0.9))
	Cine.shot(w, Vector3(-2.2, 0.9, 16.6), Vector3(-4.6, 0.4, 13.0), 38.0)
	for k in 3:
		await Cine.wait(w, 0.7)
		var gl: MeshInstance3D = glints.pop_back()
		var who := "tilly" if k % 2 == 0 else "kid"
		Cine.hop(w, who, 0.16)
		var t := w.create_tween()
		t.tween_property(gl, "scale", Vector3.ONE * 0.02, 0.3)
		t.tween_callback(gl.queue_free)
	await Cine.wait(w, 0.8)
	for gl in glints:
		(gl as Node).queue_free()
	# Hob, with his cabbage crop of cards
	var fan := Node3D.new()
	for i in 4:
		var c := InnRooms.blank_card(v)
		c.rotation = Vector3(0, 0, (i - 1.5) * 0.25)
		c.position = Vector3((i - 1.5) * 0.03, 0, 0)
		(c.material_override as StandardMaterial3D).emission = SIGIL_COLS[(i + 2) % SIGIL_COLS.size()]
		fan.add_child(c)
	var hob := Cine.body(w, "hob")
	hob.add_child(fan)
	fan.position = Vector3(0.0, 1.25, 0.35)
	fan.scale = Vector3.ONE * 2.2
	Cine.look(w, "hob", Cine.body(w, "bram").global_position)
	var hp := hob.global_position
	Cine.shot(w, hp + Vector3(0.7, 1.45, -2.9), hp + Vector3(0, 1.2, 0), 34.0)
	await Cine.say(w, "hob", "Lost half the barley and the mill roof. Found nine cards in the cabbages. Can't tell if that's a good trade.")
	fan.queue_free()
	# the mist, coming down the road against the wind
	var herald := PaleHerald.new()
	herald.name = "PaleHerald"
	w.add_child(herald)
	Cine.call_by(w, "herald", "The Pale Herald")
	var road: Array = HERALD_ROAD.duplicate()
	for i in road.size():
		var rp: Vector3 = road[i]
		road[i] = Vector3(rp.x, v.height(rp.x, rp.z), rp.z)
	herald.global_position = road[0]
	herald.snap_dir(road[1] - road[0])
	herald.walking = true
	var mist := _mist_bank(v, herald)
	for who in ["bram", "corin", "player", "nell", "tam", "hob"]:
		Cine.look(w, who, road[1])
	# from the road, up the rise it comes over
	var rc := Vector3(21.0, 0, 14.2)
	rc.y = v.height(rc.x, rc.z) + 1.7
	Cine.shot(w, rc, road[0] + Vector3(0, 2.5, 0), 30.0)
	var walk := _herald_walk(w, herald, road, 2.4)
	await Cine.wait(w, 3.0)
	# the village kneels without being told
	Cine.shot(w, Vector3(5.6, 1.5, 11.2), Vector3(-1.0, 0.9, 11.6), 44.0)
	for who in KNEELERS:
		Cine.look(w, who, road[2])
		_kneel(w, who)
		await Cine.wait(w, 0.22)
	await Cine.wait(w, 0.6)
	# and Bram's hand on your shoulder brings you down with them
	var shoulder := _shoulder_point(w, "player")
	var bf = Cine.fig(w, "bram")
	var pp := w.player.global_position
	Cine.shot(w, pp + Vector3(2.4, 1.15, -0.6), pp + Vector3(0.0, 1.05, 0.35), 34.0)
	if bf is Figure3D:
		(bf as Figure3D).reach(shoulder, null, 0.5)   # his left hand, on your right shoulder
	await Cine.wait(w, 0.6)
	_kneel(w, "bram", 0.9)
	_kneel(w, "player", 0.9)
	await Cine.wait(w, 1.0)
	await Cine.say(w, "bram", "A Pale Herald. Morrowen's own. Head down. Hand in your pocket.")
	Cine.shot(w, HERALD_AT + Vector3(-5.5, 1.0, 3.5), HERALD_AT + Vector3(0, 2.4, 0), 40.0)
	while is_instance_valid(walk) and not walk.get_meta("done", false):
		await w.get_tree().process_frame
	herald.walking = false
	herald.look_dir(Vector3(-1, 0, -0.15))
	for who in ["bram", "corin", "player", "nell", "tam", "hob", "tilly", "kid", "ned"]:
		Cine.look(w, who, HERALD_AT)
	await Cine.wait(w, 1.2)
	# the Covenant
	Cine.shot(w, HERALD_AT + Vector3(-3.6, 0.9, 2.4), herald.hood_pos() + Vector3(0, -0.15, 0), 36.0)
	await _herald_say(w, 1, "Hear the Covenant.")
	var cov := _drift_tween(w, Vector3(-1.6, 2.1, 12.8), Vector3(0.6, 2.2, 13.0), HERALD_AT + Vector3(1.0, 2.6, 0), HERALD_AT + Vector3(1.6, 2.7, 0), 14.0, 40.0)
	await _herald_say(w, 2, "The Age of Solmaris is ending. By the Covenant, the Turning begins. For one year, any Seat in Veyl may be challenged by anyone.")
	cov.kill()
	# Solhaven: the lantern shows a knight kneeling in a sun chapel
	herald.lantern_flare(1.0)
	var vis := _vision(w, herald, 0)
	var vc := vis.global_position
	Cine.shot(w, vc + Vector3(-5.6, -2.9, -0.9), vc + Vector3(0.6, -0.75, 0.0), 40.0)
	await _herald_say(w, 3, "Solhaven, for Solmaris: Ser Aldric Vane.")
	await _vision_out(w, vis)
	# then five more faces, a name under each, too quick to hold; the camera
	# stays mostly on Ashford's faces, lit by them
	var faces := [
		[Vector3(-4.0, 1.7, 15.6), Vector3(4.0, 2.6, 12.0)],                             # from behind the village, the faces above the Herald
		[DAWN.nell + Vector3(1.9, 0.75, 1.2), DAWN.nell + Vector3(0.0, 0.85, 0.0)],      # Nell
		[DAWN.tam + Vector3(1.8, 0.75, -1.1), DAWN.tam + Vector3(0.0, 0.85, 0.0)],       # Tam
		[DAWN.corin + Vector3(1.9, 0.8, 0.9), (DAWN.corin + DAWN.player) * 0.5 + Vector3(0, 0.85, 0)],   # Corin and you
		[DAWN.hob + Vector3(2.0, 0.8, -1.0), DAWN.hob + Vector3(0.0, 0.85, 0.0)],        # Hob
	]
	var flick := Cine.light(w, HERALD_AT + Vector3(-2.0, 3.0, 0.0), Color(0.8, 0.86, 1.0), 0.0, 22.0)
	for i in 5:
		var sh: Array = faces[i]
		Cine.shot(w, sh[0], sh[1], 34.0 if i > 0 else 40.0)
		var fv := _vision(w, herald, i + 1, 0.12)
		var god: String = CHAMPIONS[i + 1][1]
		flick.light_color = Lore.color(String(Lore.GODS[god].element), 1).lerp(Color(0.85, 0.9, 1.0), 0.5)
		var ft := w.create_tween()
		ft.tween_property(flick, "light_energy", 2.2, 0.12)
		ft.tween_property(flick, "light_energy", 0.4, 0.6)
		await Cine.wait(w, 0.75)
		_vision_out(w, fv, 0.18)
	var fo := w.create_tween()
	fo.tween_property(flick, "light_energy", 0.0, 0.3)
	fo.tween_callback(flick.queue_free)
	# Glyphmere: and at the name, Bram's hand tightens on your shoulder
	Cine.shot(w, HERALD_AT + Vector3(-3.6, 0.9, 2.4), herald.hood_pos() + Vector3(0, -0.15, 0), 36.0)
	var cv := _vision(w, herald, 6)
	_hand_tightens(w, shoulder, 1.7)
	await _herald_say(w, 9, "Glyphmere, for Aldrith: Magister Tobias Crane.")
	await _vision_out(w, cv)
	herald.lantern_flare(0.0)
	Cine.shot(w, HERALD_AT + Vector3(-4.0, 1.1, 3.0), herald.hood_pos(), 34.0)
	var eighth := _vision(w, herald, -1, 0.35)
	await _herald_say(w, 10, "And one more. Bound to no god. Holding no Seat. Marked by the Covenant itself.")
	_vision_out(w, eighth, 0.6)
	# the mark blazes through your pocket; every head turns
	var blaze := Node3D.new()
	var bg := v.glow_sprite(blaze, Vector3.ZERO, Color(0.9, 0.95, 1.0), 1.6, 2.0)
	var bl := OmniLight3D.new()
	bl.light_color = Color(0.85, 0.9, 1.0)
	bl.light_energy = 6.0
	bl.omni_range = 9.0
	blaze.add_child(bl)
	w.player.add_child(blaze)
	blaze.position = Vector3(0.22, 0.6, 0.1)
	_sfx(w, "gift")
	await w.flash(Color(0.9, 0.95, 1.0), 0.05, 0.9)
	w.shake(0.2)
	var p := w.player.global_position
	Cine.shot(w, p + Vector3(5.0, 2.2, -4.0), p + Vector3(-0.5, 0.9, 1.0), 40.0)
	for who in ["bram", "corin", "nell", "tam", "hob", "tilly", "kid", "ned"]:
		await Cine.wait(w, 0.18)
		Cine.look(w, who, p)
	await Cine.wait(w, 1.0)
	# last of all, slowly, the empty hood
	Cine.shot(w, herald.hood_pos() + Vector3(-1.6, -0.2, 1.4), herald.hood_pos(), 30.0)
	await Cine.wait(w, 0.4)
	herald.turn_hood(p + Vector3(0, 1.0, 0))
	await Cine.wait(w, 2.2)
	var nm := await Cine.overlay(w).ask_name("Nobody has told the Herald your name. The empty hood speaks it anyway. What does it say?", "Ash")
	Game.player_name = nm
	await _herald_say(w, 11, "{name}.")
	await _herald_say(w, 12, "The Unsworn.")
	Cine.shot(w, HERALD_AT + Vector3(-3.6, 0.9, 2.4), herald.hood_pos() + Vector3(0, -0.15, 0), 36.0)
	await _herald_say(w, 13, "Present your mark at the Sun Court of Solhaven before the new moon, or forfeit it.")
	# it rides back into the mist, and the mist goes with it
	var bt := w.create_tween().set_parallel(true)
	bt.tween_property(bl, "light_energy", 0.0, 1.5)
	bt.tween_property(bg, "scale", Vector3.ONE * 0.05, 1.5)
	herald.turn_hood(HERALD_ROAD[0])
	var back: Array = road.duplicate()
	back.reverse()
	Cine.shot(w, Vector3(0.5, 1.8, 15.5), HERALD_AT + Vector3(8.0, 1.8, -1.0), 38.0)
	_herald_walk(w, herald, back, 2.2)
	var ft2 := w.create_tween().set_parallel(true)
	ft2.tween_property(herald, "fade", 0.0, 6.0).set_delay(1.5)
	_fade_mist(w, mist, 6.5)
	await Cine.wait(w, 5.0)
	# nobody speaks; Tilly, uncertain, gets up and waves at the place where it was
	if bf is Figure3D:
		(bf as Figure3D).let_go(0.5)
	Cine.shot(w, Vector3(-2.0, 1.0, 16.4), Cine.body(w, "tilly").global_position + Vector3(0, 0.9, 0), 36.0)
	await Cine.wait(w, 0.8)
	_stand(w, "tilly")
	await Cine.wait(w, 0.9)
	Cine.look(w, "tilly", HERALD_AT + Vector3(10, 0, 0))
	# (a cut-out hops instead)
	if Cine.fig(w, "tilly") is Figure3D:
		Cine.act(w, "tilly", "wave", 0.8)
		await Cine.wait(w, 2.6)
	else:
		Cine.hop(w, "tilly", 0.22)
		await Cine.wait(w, 0.5)
		await Cine.hop(w, "tilly", 0.22)
		await Cine.wait(w, 1.4)
	await Cine.fade(w, 1.0, 1.2)
	herald.queue_free()
	if is_instance_valid(mist):
		mist.queue_free()
	if is_instance_valid(blaze):
		blaze.queue_free()
	for who in KNEELERS + ["bram", "player"]:
		_stand(w, who, 0.01)
	_free_tracker(shoulder)
	Cine.despawn(w, "kid")


## At Crane's name (`after` seconds into it): close on Bram's hand on your
## shoulder, and it tightens.
static func _hand_tightens(w: World, shoulder: Node3D, after: float) -> void:
	await Cine.wait(w, after)
	if not is_instance_valid(shoulder):
		return
	var sp: Vector3 = shoulder.global_position
	var to_cam := Vector3(1.0, 0.0, -0.75).normalized()
	Cine.shot(w, sp + to_cam * 1.15 + Vector3(0, 0.3, 0), sp + Vector3(-0.1, 0.05, 0.15), 30.0)
	await Cine.wait(w, 0.35)
	_tremble(w, "bram", 0.6, 0.012)


## Kneeling: the 3D cast go down low, heads bowed (the way down of the sit
## clip, held: there is no kneel among the shared clips); a cut-out sinks a
## little, as far as a kneeling figure would.
const KNEEL := ["sit", 0.3]


static func _kneel(w: World, who: String, secs := 0.6) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		(f as Figure3D).pose(String(KNEEL[0]), float(KNEEL[1]), secs)
	elif f != null and not (f as Node3D).has_meta("knelt"):
		var n: Node3D = f
		n.set_meta("knelt", n.position.y)
		w.create_tween().tween_property(n, "position:y", n.position.y - 0.42, secs)


static func _stand(w: World, who: String, secs := 0.6) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		(f as Figure3D).release(secs)
	elif f != null and (f as Node3D).has_meta("knelt"):
		var n: Node3D = f
		w.create_tween().tween_property(n, "position:y", float(n.get_meta("knelt")), maxf(0.01, secs))
		n.remove_meta("knelt")


## A point on top of someone's right shoulder that stays there as they move
## and kneel (for a hand to rest on). _free_tracker() lets it go.
static func _shoulder_point(w: World, who: String) -> Node3D:
	var n := Node3D.new()
	w.add_child(n)
	var f = Cine.fig(w, who)
	var b := Cine.body(w, who)
	var track := func() -> void:
		while is_instance_valid(n) and is_instance_valid(b):
			if f is Figure3D:
				var fwd: Vector3 = (f as Figure3D).facing()
				n.global_position = (f as Figure3D).bone_pos("RightArm") + Vector3(0, 0.07, 0) - fwd * 0.02
			else:
				n.global_position = b.global_position + Vector3(0, 1.45, 0)
			await w.get_tree().process_frame
	track.call()
	return n


static func _free_tracker(n: Node3D) -> void:
	if is_instance_valid(n):
		n.queue_free()


## One of the Herald's lines; its recorded voice plays with it once Gary
## records it: assets/audio/vo/herald_NN.ogg (or .wav / .mp3), numbered as
## in his list (01, 02, 03, 09, 10, 12, 13; 11 is the player's name and has
## no recording).
static func _herald_say(w: World, n: int, text: String, skip_text := false) -> void:
	if skip_text:
		return
	var hold := -1.0
	for ext in ["ogg", "wav", "mp3"]:
		var path := "res://assets/audio/vo/herald_%02d.%s" % [n, ext]
		if ResourceLoader.exists(path):
			var ap := AudioStreamPlayer.new()
			ap.stream = load(path)
			w.add_child(ap)
			ap.play()
			ap.finished.connect(ap.queue_free)
			hold = ap.stream.get_length() + 0.5
			break
	await Cine.say(w, "herald", text, hold)


## A Champion's face shown by the Herald's lantern: pale, flickering, hanging
## in the mist above it towards the village, with the name written under it.
## i indexes CHAMPIONS; -1 is the eighth, an empty pale frame. Fades in over
## `secs`; _vision_out() takes it away.
const VISION_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform float fade = 0.0;
uniform float empty = 0.0;
uniform vec3 tint : source_color = vec3(0.78, 0.86, 1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec4 c4 = texture(tex, UV);
	float l = mix(dot(c4.rgb, vec3(0.3, 0.55, 0.15)) * c4.a, 0.0, empty);
	vec2 d = (UV - 0.5) * 2.0;
	float edge = clamp(1.0 - pow(length(d * vec2(0.95, 0.8)), 2.6), 0.0, 1.0);
	float frame = empty * smoothstep(0.86, 0.9, max(abs(d.x), abs(d.y))) * (1.0 - smoothstep(0.94, 0.98, max(abs(d.x), abs(d.y))));
	float flick = 0.86 + 0.14 * sin(TIME * 23.0 + UV.y * 40.0);
	ALBEDO = tint * (pow(l, 0.85) * 1.5 + frame) * flick;
	ALPHA = fade * max(edge * (0.2 + l * 0.8) * (1.0 - empty), frame);
}
"""


static func _vision(w: World, herald: PaleHerald, i: int, secs := 0.35) -> Node3D:
	var root := Node3D.new()
	w.add_child(root)
	root.global_position = herald.lantern_pos() + Vector3(-1.5, 0.7, 0.0)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.5, 1.9)
	q.mesh = qm
	var m := ShaderMaterial.new()
	m.shader = Shader.new()
	m.shader.code = VISION_SHADER
	if i >= 0:
		var tex := _champion_tex(i)
		m.set_shader_parameter("tex", tex)
		if tex != null:
			qm.size = Vector2(1.5, 1.5 * float(tex.get_height()) / maxf(1.0, float(tex.get_width())))
	else:
		m.set_shader_parameter("empty", 1.0)
	q.material_override = m
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(q)
	if i >= 0:
		var lb := Label3D.new()
		lb.text = String(CHAMPIONS[i][2])
		lb.font = CardFace.font("display")
		lb.font_size = 72
		lb.pixel_size = 0.0028
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.modulate = Color(0.86, 0.9, 1.0, 0.0)
		lb.outline_modulate = Color(0.0, 0.02, 0.06, 0.0)
		lb.outline_size = 10
		lb.position = Vector3(0, -1.12, 0)
		root.add_child(lb)
		root.set_meta("label", lb)
	root.set_meta("mat", m)
	var tw := w.create_tween().set_parallel(true)
	tw.tween_method(func(a: float) -> void: m.set_shader_parameter("fade", a), 0.0, 1.0, secs)
	if root.has_meta("label"):
		var lb2: Label3D = root.get_meta("label")
		tw.tween_property(lb2, "modulate:a", 0.95, secs)
		tw.tween_property(lb2, "outline_modulate:a", 0.8, secs)
	return root


static func _vision_out(w: World, root: Node3D, secs := 0.5) -> void:
	if not is_instance_valid(root):
		return
	var m: ShaderMaterial = root.get_meta("mat")
	var tw := w.create_tween().set_parallel(true)
	tw.tween_method(func(a: float) -> void: m.set_shader_parameter("fade", a), 1.0, 0.0, secs)
	if root.has_meta("label"):
		var lb: Label3D = root.get_meta("label")
		tw.tween_property(lb, "modulate:a", 0.0, secs)
		tw.tween_property(lb, "outline_modulate:a", 0.0, secs)
	await tw.finished
	if is_instance_valid(root):
		root.queue_free()


## A Champion's picture for the Herald's lantern: Gary's portrait when there is
## one, else the sign of the Seat's god.
static func _champion_tex(i: int) -> Texture2D:
	var id: String = CHAMPIONS[i][0]
	for ext in ["png", "jpg", "webp"]:
		var p := "res://assets/art/champions/%s.%s" % [id, ext]
		if ResourceLoader.exists(p):
			return load(p)
	return Glyphs.tex(String(Lore.GODS[String(CHAMPIONS[i][1])].element), 256)


## The mill after the night: a black shell (its timbers charred).
static func _char_mill(v: AshfordVillage) -> void:
	if v.mill_root == null or v.mill_root.has_meta("charred"):
		return
	v.mill_root.set_meta("charred", true)
	var soot := StandardMaterial3D.new()
	soot.albedo_color = Color(0.02, 0.015, 0.012, 0.82)
	soot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soot.roughness = 1.0
	for mi in v.mill_root.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = soot


## Walks the Herald down a road (each point in turn). The returned node has
## meta "done" set when it gets there.
static func _herald_walk(w: World, h: PaleHerald, road: Array, speed: float) -> Node:
	var marker := Node.new()
	w.add_child(marker)
	_herald_walk_go(w, h, road, speed, marker)
	return marker


static func _herald_walk_go(w: World, h: PaleHerald, road: Array, speed: float, marker: Node) -> void:
	h.walking = true
	for i in range(1, road.size()):
		var a := h.global_position
		var b: Vector3 = road[i]
		h.look_dir(b - a)
		var tw := w.create_tween()
		tw.tween_property(h, "global_position", b, a.distance_to(b) / speed)
		await tw.finished
		if not is_instance_valid(h):
			break
	if is_instance_valid(h):
		h.walking = false
	marker.set_meta("done", true)
	marker.queue_free.call_deferred()


## A bank of mist that travels with the Herald.
static func _mist_bank(v: AshfordVillage, herald: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "MistBank"
	herald.add_child(root)
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	for i in [10, 16, 22][v.quality]:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		var s := randf_range(5.0, 11.0)
		q.size = Vector2(s * 1.6, s)
		mi.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		m.albedo_texture = gt
		m.albedo_color = Color(0.92, 0.9, 0.9, randf_range(0.16, 0.3))
		m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		# thins out close to the camera, so a shot inside it isn't a white-out
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = 2.5
		m.distance_fade_max_distance = 9.0
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# round it and behind it (it faces along +Z), not between it and the village
		mi.position = Vector3(randf_range(-5.0, 5.0), s * 0.3, randf_range(-9.0, 1.5))
		root.add_child(mi)
	return root


static func _fade_mist(w: World, mist: Node3D, secs: float) -> void:
	if mist == null:
		return
	var tw := w.create_tween().set_parallel(true)
	for mi in mist.get_children():
		var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
		tw.tween_property(m, "albedo_color:a", 0.0, secs)


# ---------------------------------------------------- P3 · the taproom ---

## That afternoon (v3, P3), shutters closed: Bram turns the blank card over
## in the lamplight the way he'd check a coin, says he's frightened of it,
## says Solhaven before the new moon, and hands it back.
static func _taproom(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	var r := InnRooms.taproom(v)
	InnRooms.inside(v)
	Cine.place(w, "bram", r.bram, r.table)
	Cine.place(w, "player", r.player, r.table)
	for n in w.npcs:
		if n.def.id != "bram":
			n.doll.visible = false
	Music.stop(1.0)
	await Cine.caption(w, "That afternoon")
	var card: MeshInstance3D = r.card
	var table: Vector3 = r.table
	# close on the card on the table, then Bram's hand takes it up
	Cine.shot(w, card.global_position + Vector3(0.45, 0.32, 0.4), card.global_position, 26.0)
	Cine.fade(w, 0.0, 1.4)
	await Cine.wait(w, 2.2)
	var bf = Cine.fig(w, "bram")
	var held := Node3D.new()
	card.get_parent().remove_child(card)
	held.add_child(card)
	card.position = Vector3.ZERO
	card.rotation = Vector3(0, 0, 0)
	_hold(w, "bram", held)
	if bf is Figure3D:
		(bf as Figure3D).pose("play_card", 0.4)
	Cine.shot(w, table + Vector3(1.9, 1.5, 0.2), Cine.head(w, "bram") + Vector3(0, -0.25, 0), 30.0)
	await Cine.wait(w, 1.6)
	await Cine.say(w, "bram", "Thirty years with cards, and I never saw one with nothing on it.")
	Cine.over_shoulder(w, "bram", "player", 1.0, 30.0)
	var a := await Cine.choose(w, ["What does it do?", "You know what it is."])
	if a == 0:
		Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
		await Cine.say(w, "bram", "Nothing I can see. That's what frightens me.")
	else:
		# he doesn't look up from the card
		Cine.look(w, "bram", card.global_position if is_instance_valid(card) else table)
		Cine.shot(w, table + Vector3(1.9, 1.5, 0.2), Cine.head(w, "bram") + Vector3(0, -0.25, 0), 30.0)
		await Cine.say(w, "bram", "I know I'm frightened of it. That'll have to do for today.")
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "Solhaven, then. Before the new moon.")
	if Game.flag("want_solhaven"):
		await Cine.say(w, "bram", "You always wanted the Sun Court. I'd have given a lot for you to want something else.")
	else:
		await Cine.say(w, "bram", "You never wanted Solhaven. Seems Solhaven wants you.")
	Cine.over_shoulder(w, "bram", "player", 1.0, 30.0)
	var b := await Cine.choose(w, ["Come with me.", "I can go alone."])
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	if b == 0:
		await Cine.say(w, "bram", "As if you'd get past the end of the lane without me.")
	else:
		await Cine.say(w, "bram", "No.")
		await Cine.wait(w, 0.9)
		await Cine.say(w, "bram", "No.")
	await Cine.say(w, "bram", "We go in the morning. Eat something.")
	# he hands it back, and doesn't look at it again
	Cine.two_shot(w, "bram", "player", 2.8, 1.35, 1.0, 34.0)
	if bf is Figure3D:
		(bf as Figure3D).pose("play_card", 0.55)
	await Cine.wait(w, 0.6)
	_drop(w, "bram")
	var pcard := Node3D.new()
	var c2 := InnRooms.blank_card(v)
	pcard.add_child(c2)
	_hold(w, "player", pcard)
	if bf is Figure3D:
		(bf as Figure3D).release()
	await Cine.wait(w, 0.5)
	await Cine.walk(w, "bram", r.bar, 1.1)
	Cine.look(w, "bram", r.bar + Vector3(0, 0, -2.0))
	await Cine.wait(w, 1.4)
	_drop(w, "player")
	await Cine.fade(w, 1.0, 1.2)
	InnRooms.outside(v)
	for n in w.npcs:
		n.doll.visible = true


# ---------------------------------------------- P4 · that night: Ashford burns ---

## Where everyone stands that night: the village on the green, the player and
## Bram at the back, by the inn.
const NIGHT := {
	"player": Vector3(-11.6, 0, 7.6), "bram": Vector3(-12.4, 0, 8.3), "corin": Vector3(-3.2, 0, 6.0),
	"tilly": Vector3(-3.9, 0, 6.6), "nell": Vector3(0.2, 0, 5.2), "tam": Vector3(1.6, 0, 4.8),
	"hob": Vector3(-1.4, 0, 4.4), "ned": Vector3(-5.4, 0, 4.6),
}
const KRELL_AT := Vector3(6.2, 0, 6.4)
## The woodpile behind the inn, and the way through the back gardens to its back door.
const WOODPILE := Vector3(-21.4, 0, 13.0)
const GARDENS := [Vector3(-25.0, 0, 17.5), Vector3(-30.5, 0, 14.5), Vector3(-31.5, 0, 9.0)]
const BACK_DOOR := Vector3(-30.2, 0, 5.6)


## That night (v3, P4): riders in black and gold come onto the green, torches
## high, metal hounds beside them, and at their head Huntmaster Krell with a
## ledger open in her hand. She reads Ashford its terms: every roof but one,
## or a single card. Nobody points. She offers Tam the mill, and Tam lies for
## the player, and the hound takes him. Then "Burn the inn", and Bram gets
## the player out behind the woodpile and through the back gardens to the
## back door of the burning Crooked Lantern.
static func _burning(w: World) -> void:
	var v := village(w)
	var gore: bool = String(Game.settings.get("violence", "full")) == "full"
	var told: bool = Game.flag("tam_told")
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	v.set_time("burning")
	v.set_cart_tip(1.0)
	_char_mill(v)
	_clear_crowd(w)
	_crowd(w, CROWD_NIGHT, Vector3(14, 0, 8))
	_stage(w, NIGHT, Vector3(14.0, 0, 8.0))
	Music.play(["ashford_burns", "sigilfall"], 1.0, false)
	await Cine.caption(w, "That night")
	# riders onto the green, torches high, the hounds beside them
	var hunters := ["h1", "h2", "h3", "h4", "h5", "h6"]
	var line := [Vector3(9.5, 0, 3.4), Vector3(10.2, 0, 5.4), Vector3(10.4, 0, 7.6), Vector3(10.0, 0, 9.8), Vector3(9.2, 0, 11.8), Vector3(11.6, 0, 6.6)]
	for i in hunters.size():
		var start := Vector3(46.0 + i * 3.0, 0, 10.0 + (i % 3) * 1.2)
		Cine.spawn(w, hunters[i], "hunter", start, "Hunter")
		_torch(v, Cine.body(w, hunters[i]))
	Cine.spawn(w, "krell", "krell", Vector3(42.0, 0, 11.0), "Krell")
	Cine.beast(w, "hound1", "shieldhound", Vector3(44.0, 0, 13.0), Color(1.0, 0.8, 0.35, 1.0))
	Cine.beast(w, "hound2", "shieldhound", Vector3(45.0, 0, 8.0), Color(1.0, 0.8, 0.35, 1.0))
	var ledger := _ledger(w, "krell")
	Cine.shot(w, Vector3(3.0, 2.0, 12.5), Vector3(36.0, 1.5, 10.5), 32.0)
	Cine.fade(w, 0.0, 1.0)
	for i in hunters.size():
		Cine.path(w, hunters[i], [Vector3(20.0, 0, 11.0 + (i % 3)), line[i]], 6.5, "run")
	Cine.path(w, "hound1", [Vector3(20.0, 0, 13.0), KRELL_AT + Vector3(1.0, 0, 1.8)], 7.0)
	Cine.path(w, "hound2", [Vector3(20.0, 0, 8.0), KRELL_AT + Vector3(1.2, 0, -1.6)], 7.0)
	await Cine.path(w, "krell", [Vector3(20.0, 0, 10.0), KRELL_AT], 6.2, "run")
	for i in hunters.size():
		Cine.look(w, hunters[i], Vector3(-2, 0, 5))
	Cine.look(w, "krell", Vector3(-2, 0, 5))
	# you and Bram watch from the dark of the inn yard
	var pp: Vector3 = Cine.body(w, "player").global_position
	Cine.shot(w, pp + Vector3(-1.6, 1.55, 1.3), KRELL_AT + Vector3(0, 1.2, 0), 30.0)
	await Cine.wait(w, 1.6)
	# Krell reads Ashford its terms
	var krell_cam := KRELL_AT + Vector3(-4.2, 1.5, 2.2)
	Cine.shot(w, krell_cam, KRELL_AT + Vector3(0.5, 1.5, 0), 34.0)
	await Cine.say(w, "krell", "Good evening. Sabine Krell, for Ironvault. I'll be brief; it's late.")
	if not told:
		# Tam's face changes at "fell due at midnight"
		_cut_later(w, 1.3, Cine.body(w, "tam").global_position + Vector3(1.6, 1.5, 0.7), Cine.head(w, "tam"), 30.0)
	await Cine.say(w, "krell", "Every note in Ashford fell due at midnight. The mill. Eleven farms. Every roof in this village but one. Under the terms, Ironvault may take possession of all of it, tonight.")
	Cine.shot(w, krell_cam, KRELL_AT + Vector3(0.5, 1.5, 0), 34.0)
	await Cine.say(w, "krell", "Or I can burn the notes. Every one. For a single card.")
	Cine.shot(w, KRELL_AT + Vector3(-4.2, 1.7, 2.0), KRELL_AT + Vector3(0, 1.4, 0), 30.0)
	await Cine.say(w, "krell", "Where is the Unsworn?")
	# silence: Nell looks at the ground, Hob looks at Nell, nobody points
	Music.stop(1.0)
	Cine.shot(w, KRELL_AT + Vector3(-1.2, 1.7, 0.6), Vector3(-1.4, 1.2, 6.2), 42.0)
	await Cine.wait(w, 1.6)
	# Tam, Nell and Hob in one shot, from Krell's side of the green
	var np := Cine.body(w, "nell").global_position
	Cine.shot(w, np + Vector3(4.4, 1.7, -3.6), np + Vector3(-0.4, 1.1, -0.4), 34.0)
	Cine.look(w, "nell", np + Vector3(-1.5, 0, 0.6))
	var nf = Cine.fig(w, "nell")
	if nf is Figure3D:
		(nf as Figure3D).pose("defeat", 0.3, 0.6)   # her head goes down
	await Cine.wait(w, 1.3)
	Cine.look(w, "hob", np)
	await Cine.wait(w, 1.7)
	Cine.shot(w, Vector3(-11.0, 2.4, 10.4), Vector3(4.0, 1.2, 5.6), 30.0)
	await Cine.wait(w, 1.2)
	# Krell turns a page
	Cine.shot(w, KRELL_AT + Vector3(-3.4, 1.6, 1.4), KRELL_AT + Vector3(0, 1.3, 0), 28.0)
	await _turn_page(w, ledger)
	Cine.look(w, "krell", Cine.body(w, "tam").global_position)
	await Cine.say(w, "krell", "Mr Hayes. The mill, its stones and its house. Eleven hundred crowns. You would be clear.")
	# Tam looks at the dark of the inn yard, at you
	var tb := Cine.body(w, "tam")
	var tam_cam := tb.global_position + Vector3(0.4, 1.5, -2.2)   # his face side-on, whichever way he looks
	Cine.shot(w, tam_cam, Cine.head(w, "tam"), 28.0)
	await Cine.wait(w, 0.4)
	Cine.look(w, "tam", pp)
	if told:
		# once; his face doesn't change at all
		await Cine.wait(w, 0.9)
		Cine.look(w, "tam", KRELL_AT)
		await Cine.wait(w, 0.7)
	else:
		# you watch him understand, and then you watch him decide
		await Cine.wait(w, 1.0)
		Cine.shot(w, pp + Vector3(-0.8, 1.6, 0.9), tb.global_position + Vector3(0, 1.4, 0), 18.0)
		await Cine.wait(w, 1.8)
		Cine.look(w, "tam", KRELL_AT)
		Cine.shot(w, tb.global_position + Vector3(1.6, 1.5, 0.7), Cine.head(w, "tam"), 28.0)
		await Cine.wait(w, 1.4)
	# he steps forward, cap in his hands
	var cap := _cap_in_hands(w, "tam")
	Cine.shot(w, Vector3(0.4, 1.6, 7.6), (tb.global_position + KRELL_AT) * 0.5 + Vector3(0, 1.2, 0), 38.0)
	await Cine.walk(w, "tam", tb.global_position + (KRELL_AT - tb.global_position).normalized() * 1.4, 1.0)
	# his lie, to her face (the camera beside her)
	Cine.shot(w, tb.global_position + Vector3(1.6, 1.5, 0.7), Cine.head(w, "tam"), 28.0)
	await Cine.say(w, "tam", "They left at noon. Took the Solhaven road. Bram and the youngster both.")
	# she looks at him for a long moment
	Cine.shot(w, KRELL_AT + Vector3(-3.4, 1.65, 1.4), KRELL_AT + Vector3(0, 1.45, 0), 26.0)
	await Cine.wait(w, 2.2)
	await Cine.say(w, "krell", "No. They didn't.")
	# she closes the ledger; a Shieldhound moves
	await _close_ledger(w, ledger)
	var tam_at: Vector3 = tb.global_position
	var to_tam := tam_at - KRELL_AT
	to_tam.y = 0.0
	Cine.shot(w, KRELL_AT + Vector3(-1.0, 1.0, 3.6), (KRELL_AT + tam_at) * 0.5 + Vector3(0, 0.8, 0), 40.0)
	Cine.beast_play(w, "hound1", "attack", 1.3)
	Cine.path(w, "hound1", [tam_at - to_tam.normalized() * 0.5], 9.0)
	var tf = Cine.fig(w, "tam")
	var fall_at := tam_at + to_tam.normalized() * 0.3
	if gore:
		# Full: quick and brutal, at the throat
		await Cine.wait(w, 0.42)
		_sfx(w, "hit_heavy", 0.8)
		if tf is Figure3D:
			(tf as Figure3D).let_go(0.05)
			(tf as Figure3D).lie_down(0.35, true)
		_drop_cap(w, cap, fall_at + Vector3(0.5, 0.0, 0.6))
		await Cine.wait(w, 0.35)
	else:
		# Reduced: the camera is on Nell before it reaches him
		await Cine.wait(w, 0.2)
	# from behind Nell, as she watches
	var to_k := tam_at - np
	to_k.y = 0.0
	to_k = to_k.normalized()
	Cine.shot(w, np - to_k * 3.1 + to_k.cross(Vector3.UP) * 1.4 + Vector3(0, 1.6, 0), np + to_k * 1.7 + Vector3(0, 0.9, 0), 32.0)
	if nf is Figure3D:
		(nf as Figure3D).release(0.3)
	Cine.place(w, "nell", np, tam_at)
	if not gore:
		if tf is Figure3D:
			(tf as Figure3D).let_go(0.05)
			(tf as Figure3D).lie_down(0.01, true)
		_drop_cap(w, cap, fall_at + Vector3(0.5, 0.0, 0.6))
	Cine.place(w, "hound1", KRELL_AT + Vector3(-1.2, 0, 1.0), tam_at)
	await Cine.wait(w, 1.8)
	# back: Full, his blood between the cobbles and his cap where he fell;
	# Reduced, he is still
	if gore:
		_blood(v, fall_at + Vector3(0, 0.04, 0))
	Cine.shot(w, fall_at + Vector3(-2.2, 1.3, 2.0), fall_at + Vector3(0.2, 0.1, 0.2), 34.0)
	await Cine.wait(w, 2.0)
	Cine.shot(w, tam_at + to_k * 1.4 - to_k.cross(Vector3.UP) * 1.0 + Vector3(0, 1.3, 0), Cine.head(w, "nell") + Vector3(0, -0.1, 0), 22.0)
	await Cine.say(w, "nell", "Tam.", 3.0)
	await Cine.wait(w, 0.8)
	Cine.shot(w, KRELL_AT + Vector3(-4.0, 1.6, 3.0), KRELL_AT + Vector3(0, 1.4, 0), 34.0)
	await Cine.say(w, "krell", "Burn the inn. If they're inside, they'll come out.")
	# the hunters go for the inn with their torches; Bram pulls you into the dark
	Music.play(["ashford_burns", "sigilfall"], 0.5, true)
	var inn_i := v.inn_index()
	var inn_at: Vector3 = (v.houses[inn_i].root as Node3D).global_position if inn_i >= 0 else Vector3(-24, 0, 6)
	var throw_from := [inn_at + Vector3(7.5, 0, -3.5), inn_at + Vector3(8.5, 0, -1.0), inn_at + Vector3(8.0, 0, 1.5)]
	for k in 3:
		Cine.path(w, hunters[k], [Vector3(-2.0, 0, 1.0 + k), throw_from[k]], 5.0, "run")
	# the rest go to search the barns on the east side (clear of the
	# villagers, Tam, and Gary's sacks behind the hay cart)
	var barns := [Vector3(14.0, 0, 14.0), Vector3(14.5, 0, 9.0), Vector3(15.0, 0, 3.0)]
	for k in range(3, hunters.size()):
		Cine.path(w, hunters[k], [barns[(k - 3) % barns.size()]], 3.0, "run")
	_woodpile(v, WOODPILE + Vector3(1.4, 0, -1.4))
	Cine.path(w, "bram", [WOODPILE + Vector3(-0.6, 0, 0.5)], 4.4, "run")
	var wy := v.height(WOODPILE.x, WOODPILE.z)
	Cine.shot(w, WOODPILE + Vector3(-2.2, wy + 1.5, 3.2), WOODPILE + Vector3(0.2, wy + 1.1, -0.2), 40.0)
	await Cine.path(w, "player", [WOODPILE + Vector3(0.4, 0, -0.1)], 4.6, "run")
	# the torches go into the inn's thatch, and the wind takes it to the next roof
	Cine.shot(w, inn_at + Vector3(14.0, 4.0, -9.0), inn_at + Vector3(0, 4.0, 0), 44.0)
	for k in 3:
		_throw_torch(w, Cine.body(w, hunters[k]).global_position + Vector3(0, 1.4, 0), inn_at + Vector3(randf_range(-2.5, 2.5), 5.2, randf_range(-1.5, 1.5)), inn_i)
		await Cine.wait(w, 0.35)
	await Cine.wait(w, 2.2)
	var next_roof: int = -1
	for hi in v.houses_near(inn_at):
		if hi != inn_i:
			next_roof = hi
			break
	if next_roof >= 0:
		v.burn_house(next_roof)
	await Cine.wait(w, 1.0)
	# behind the woodpile
	Cine.look(w, "bram", w.player.global_position)
	Cine.look(w, "player", Cine.body(w, "bram").global_position)
	Cine.over_shoulder(w, "player", "bram", 1.0, 30.0)
	await Cine.say(w, "bram", "Listen to me. That card won't stay with anyone who takes it. They can't just have it off you.")
	await Cine.say(w, "bram", "They need you to stake it in a sworn duel and lose. Or they need you dead.")
	var c1 := await Cine.choose(w, ["Then I'll duel them.", "They killed Tam."])
	if c1 == 0:
		await Cine.say(w, "bram", "Them and their dogs? Not tonight. Not while I've breath.")
	else:
		await Cine.say(w, "bram", "I saw.")
		await Cine.wait(w, 1.0)
		await Cine.say(w, "bram", "Later. Now we go. Quiet, and stay behind me.")
	# through the back gardens, hedge to hedge, out of the lantern beams
	await _gardens(w, hunters)
	# the Crooked Lantern is burning; Bram stops at the back door
	Cine.shot(w, BACK_DOOR + Vector3(-6.0, 1.6, 4.0), BACK_DOOR + Vector3(2.0, 3.0, 0.0), 44.0)
	await Cine.path(w, "bram", [BACK_DOOR + Vector3(-0.6, 0, 0.5)], 3.6, "run")
	await Cine.path(w, "player", [BACK_DOOR + Vector3(-1.4, 0, 1.4)], 3.6, "run")
	Cine.look(w, "bram", BACK_DOOR + Vector3(2, 0, 0))
	await Cine.wait(w, 0.8)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 30.0)
	await Cine.say(w, "bram", "My decks are in the cellar. I'm not leaving them to Ironvault.")
	var c2 := await Cine.choose(w, ["I'm coming with you.", "Bram, the roof!"])
	await Cine.say(w, "bram", "Course you are." if c2 == 0 else "Then don't stand there watching it.")
	Cine.path(w, "bram", [BACK_DOOR + Vector3(1.5, 0, 0)], 2.4, "run")
	await Cine.wait(w, 0.4)
	await Cine.fade(w, 1.0, 0.8)
	if tf is Figure3D:
		(tf as Figure3D).get_up(0.01)
	if is_instance_valid(cap):
		cap.queue_free()
	for id in hunters + ["krell", "hound1", "hound2"]:
		Cine.despawn(w, id)


## Cuts the camera to a shot `after` seconds from now (while a line is up).
static func _cut_later(w: World, after: float, pos: Vector3, look: Vector3, fov: float) -> void:
	var ov := Cine.overlay(w)
	var line := ov._line_no + 1   # the line about to be said
	await Cine.wait(w, after)
	if ov._line_no == line and ov._waiting:
		Cine.shot(w, pos, look, fov)


## Krell's ledger, open in her hand (a 3D Krell holds it; a cut-out's is only
## heard: its page turning, and its closing).
static func _ledger(w: World, who: String) -> Node3D:
	var f = Cine.fig(w, who)
	if not (f is Figure3D):
		return null
	var v := village(w)
	var book := Node3D.new()
	var cover := StandardMaterial3D.new()
	cover.albedo_color = Color(0.12, 0.08, 0.06)
	cover.roughness = 0.7
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.86, 0.82, 0.72)
	for side in [-1, 1]:
		var leaf := Node3D.new()
		leaf.name = "L" if side < 0 else "R"
		book.add_child(leaf)
		v.box(leaf, Vector3(0.11, 0.006, 0.16), Vector3(0.055 * side, 0, 0), cover)
		v.box(leaf, Vector3(0.1, 0.008, 0.15), Vector3(0.052 * side, 0.006, 0), paper)
	(f as Figure3D).carry(book, Vector3(0.0, 1.05, 0.3))
	book.rotation = Vector3(-0.7, 0, 0)
	return book


static func _turn_page(w: World, book: Node3D) -> void:
	_sfx(w, "card_flip", 0.6)
	if book == null or not is_instance_valid(book):
		await Cine.wait(w, 0.6)
		return
	var v := village(w)
	var page := Node3D.new()
	book.add_child(page)
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.9, 0.86, 0.76)
	v.box(page, Vector3(0.1, 0.004, 0.15), Vector3(0.05, 0.012, 0), paper)
	var tw := w.create_tween()
	tw.tween_property(page, "rotation:z", PI, 0.6).set_trans(Tween.TRANS_SINE)
	await tw.finished
	page.queue_free()


static func _close_ledger(w: World, book: Node3D) -> void:
	_sfx(w, "card_flip", 0.4)
	if book == null or not is_instance_valid(book):
		await Cine.wait(w, 0.5)
		return
	var leaf: Node3D = book.get_node("R")
	var tw := w.create_tween()
	tw.tween_property(leaf, "rotation:z", PI * 0.98, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


## Tam's cap, held in front of him in both hands.
static func _cap_in_hands(w: World, who: String) -> Node3D:
	var f = Cine.fig(w, who)
	var cap := Node3D.new()
	var felt := StandardMaterial3D.new()
	felt.albedo_color = Color(0.22, 0.2, 0.17)
	felt.roughness = 1.0
	var crown := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.085
	cm.bottom_radius = 0.1
	cm.height = 0.07
	crown.mesh = cm
	crown.material_override = felt
	cap.add_child(crown)
	var peak := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.075
	pm.bottom_radius = 0.075
	pm.height = 0.01
	peak.mesh = pm
	peak.material_override = felt
	peak.position = Vector3(0, -0.03, 0.06)
	peak.scale = Vector3(1.0, 1.0, 0.6)
	cap.add_child(peak)
	if f is Figure3D:
		(f as Figure3D).carry(cap, Vector3(0.0, 1.0, 0.28))
		cap.rotation = Vector3(-1.2, 0, 0)
		var grips := []
		for x in [0.09, -0.09]:
			var g := Node3D.new()
			g.position = Vector3(x, 0.0, 0.0)
			cap.add_child(g)
			grips.append(g)
		(f as Figure3D).reach(grips[0], grips[1], 0.4)
	else:
		Cine.body(w, who).add_child(cap)
		cap.position = Vector3(0.0, 1.0, 0.3)
	return cap


## The cap falls where he fell.
static func _drop_cap(w: World, cap: Node3D, at: Vector3) -> void:
	if cap == null or not is_instance_valid(cap):
		return
	cap.reparent(w)
	for c in cap.get_children():
		if not (c is MeshInstance3D):
			c.queue_free()
	at.y = Cine.ground(w, at) + 0.03
	var tw := w.create_tween().set_parallel(true)
	tw.tween_property(cap, "global_position", at, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(cap, "rotation", Vector3(0.15, randf() * TAU, 0.1), 0.4)


## The hunters' lantern beams sweep the back gardens while Bram and the
## player go hedge to hedge behind them; a hound comes by; they freeze.
static func _gardens(w: World, hunters: Array) -> void:
	var v := village(w)
	var beams: Array = []
	for k in 2:
		var hid: String = hunters[k + 2]
		var hp := Vector3(-14.0 - k * 4.0, 0, 18.5 + k * 3.0)
		Cine.place(w, hid, hp, Vector3(-28, 0, 14))
		var sl := SpotLight3D.new()
		sl.light_color = Color(1.0, 0.78, 0.45)
		sl.light_energy = 9.0
		sl.spot_range = 26.0
		sl.spot_angle = 14.0
		sl.shadow_enabled = v.quality > 0
		sl.light_volumetric_fog_energy = 3.0
		Cine.body(w, hid).add_child(sl)
		sl.position = Vector3(0.3, 1.5, 0.2)
		beams.append(sl)
	# hedges to hide behind, between each hiding place and the hunters
	var cover: Array = []
	var hunt := Vector3(-16.0, 0, 20.0)
	for g in GARDENS:
		var to_h: Vector3 = hunt - (g as Vector3)
		to_h.y = 0.0
		to_h = to_h.normalized()
		cover.append(v.hedge((g as Vector3) + to_h * 1.1, atan2(to_h.x, to_h.z), 4.2, 1.3))
	# the houses burning down the lane throw their light this far (a low
	# directional light: the phone and web renderers cap lamps per mesh)
	var glow := DirectionalLight3D.new()
	glow.light_color = Color(1.0, 0.52, 0.24)
	glow.light_energy = 0.55
	glow.shadow_enabled = false
	v.add_child(glow)
	glow.look_at_from_position(Vector3(-10.0, 9.0, 8.0), Vector3(-28.0, 0.0, 15.0), Vector3.UP)
	var t0 := Time.get_ticks_msec()
	var sweeping := [true]
	var sweep := func() -> void:
		while sweeping[0] and is_instance_valid(w):
			var tt := (Time.get_ticks_msec() - t0) / 1000.0
			for k in beams.size():
				var sl: SpotLight3D = beams[k]
				if is_instance_valid(sl):
					var aim := Vector3(-28.0 + sin(tt * 0.7 + k * 2.0) * 7.0, 0.0, 12.0 + cos(tt * 0.55 + k) * 5.0)
					sl.look_at(aim, Vector3.UP)
			await w.get_tree().process_frame
	sweep.call()
	Cine.shot(w, Vector3(-17.5, 4.5, 24.0), Vector3(-27.0, 0.8, 14.5), 46.0)
	Cine.path(w, "bram", [GARDENS[0]], 2.6, "run")
	await Cine.path(w, "player", [GARDENS[0] + Vector3(0.9, 0, 0.6)], 2.6, "run")
	await Cine.say(w, "h3", "Voss! Check the barns!", 1.8)
	Cine.path(w, "bram", [GARDENS[1]], 2.6, "run")
	await Cine.path(w, "player", [GARDENS[1] + Vector3(0.8, 0, 0.6)], 2.6, "run")
	# a hound comes along the lane; they freeze
	Cine.beast(w, "hound3", "shieldhound", Vector3(-22.0, 0, 26.0), Color(1.0, 0.8, 0.35, 1.0))
	# behind the two of them, crouched at the hedge, as the hound goes by
	var g1: Vector3 = GARDENS[1]
	g1.y = v.height(g1.x, g1.z)   # the gardens sit up the slope behind the inn
	var to_h1 := hunt - g1
	to_h1.y = 0.0
	to_h1 = to_h1.normalized()
	Cine.shot(w, g1 - to_h1 * 1.7 + to_h1.cross(Vector3.UP) * 0.7 + Vector3(0, 1.35, 0), Vector3(-27.0, v.height(-27.0, 21.5) + 0.6, 21.5), 44.0)
	await Cine.path(w, "hound3", [Vector3(-27.0, 0, 21.5), Vector3(-34.0, 0, 20.0)], 2.2)
	# and from the hunters' side: two heads just over the hedge, the beams going over
	var hc := g1 + to_h1 * 4.2
	hc.y = v.height(hc.x, hc.z) + 1.3
	Cine.shot(w, hc, g1 + Vector3(0, 1.0, 0), 38.0)
	await Cine.say(w, "h4", "Nothing here.", 1.4)
	await Cine.say(w, "h3", "Huntmaster wants the innkeeper alive.", 2.2)
	await Cine.wait(w, 0.5)
	await Cine.say(w, "h4", "Did you hear that?", 1.8)
	await Cine.wait(w, 1.2)
	Cine.despawn(w, "hound3")
	Cine.path(w, "bram", [GARDENS[2]], 2.8, "run")
	await Cine.path(w, "player", [GARDENS[2] + Vector3(0.8, 0, 0.5)], 2.8, "run")
	sweeping[0] = false
	for sl in beams:
		if is_instance_valid(sl):
			(sl as Node).queue_free()
	glow.queue_free()


## A torch in a hunter's hand: a flame and its light.
static func _torch(v: AshfordVillage, body: Node3D) -> void:
	if body == null:
		return
	var n := Node3D.new()
	body.add_child(n)
	n.position = Vector3(0.38, 1.55, 0.12)
	var f := GPUParticles3D.new()
	f.amount = 10
	f.lifetime = 0.5
	f.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, 1.0, 0)
	pm.scale_min = 0.14
	pm.scale_max = 0.24
	f.process_material = pm
	var q := QuadMesh.new(); q.size = Vector2(0.9, 1.4)
	f.draw_pass_1 = q
	f.material_override = v.mats.flame
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(f)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 1.8
	l.omni_range = 6.0
	n.add_child(l)
	v.flicker_lights.append([l, 1.8])


## A torch thrown into a thatch roof, which catches.
static func _throw_torch(w: World, from: Vector3, to: Vector3, house_i: int) -> void:
	var v := village(w)
	var g := v.glow_sprite(v, from, Color(1.0, 0.55, 0.2), 0.6, 1.2)
	var tw := w.create_tween()
	tw.tween_method(func(u: float) -> void:
		g.global_position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 4.0, 0), 0.0, 1.0, 0.9)
	await tw.finished
	g.queue_free()
	v.burn_house(house_i)


## Blood between the cobbles (Violence: Full).
static func _blood(v: AshfordVillage, at: Vector3) -> void:
	var dm := QuadMesh.new(); dm.size = Vector2(1.6, 1.1); dm.orientation = PlaneMesh.FACE_Y
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.01, 0.01, 0.92)
	m.roughness = 0.15
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var g := Gradient.new(); g.set_color(0, Color(1, 1, 1, 1)); g.add_point(0.6, Color(1, 1, 1, 0.9)); g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill = GradientTexture2D.FILL_RADIAL; gt.fill_from = Vector2(0.5, 0.5); gt.fill_to = Vector2(0.5, 0.0)
	m.albedo_texture = gt
	var mi := v.add_mesh(v, dm, m, Transform3D(Basis(Vector3.UP, 0.4), at), false)
	mi.scale = Vector3.ONE * 0.2
	v.create_tween().tween_property(mi, "scale", Vector3.ONE, 3.0)


## The woodpile behind the inn: split logs stacked against the wall.
static func _woodpile(v: AshfordVillage, at: Vector3) -> void:
	if v.has_meta("woodpile"):
		return
	v.set_meta("woodpile", true)
	var n := Node3D.new()
	v.add_child(n)
	n.global_position = at
	for row in 4:
		for k in 7 - row:
			var lg := v.cyl(n, 0.13, 0.13, 1.1, Vector3(-0.85 + k * 0.27 + row * 0.13, 0.13 + row * 0.24, 0), v.mats.bark, 8, Vector3(PI * 0.5, 0, 0))
			lg.rotation.y = randf_range(-0.05, 0.05)


# ---------------------------------------------------- P4 · the cellar ---

## The cellar (v3, P4), smoke curling under the door: Bram heaves open his
## iron-bound chest, sweeps four worn card boxes into a sack, and drags a rug
## aside: a trapdoor, and below it a tunnel shored with old timber. (The
## decks are opened at the campfire, in the Thornwood.)
static func _cellar(w: World) -> void:
	var v := village(w)
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.01)
	var r := InnRooms.cellar(v)
	InnRooms.inside(v)
	for n in w.npcs:
		if n.def.id != "bram":
			n.doll.visible = false
	Cine.place(w, "bram", r.stairs, r.chest)
	Cine.place(w, "player", r.stairs + Vector3(0.3, 0, 0.9), r.chest)
	Cine.shot(w, r.stairs + Vector3(-2.6, 1.7, -2.8), r.stairs + Vector3(0, 1.0, 0), 44.0)
	Cine.fade(w, 0.0, 1.0)
	await Cine.path(w, "bram", [r.bram], 1.8)
	Cine.walk(w, "player", r.player, 1.6)
	Cine.look(w, "bram", r.chest)
	# he heaves the lid open: four card boxes, worn soft at the corners
	var bf = Cine.fig(w, "bram")
	Cine.shot(w, r.chest + Vector3(1.6, 1.4, 1.6), r.chest + Vector3(0, 0.5, 0), 36.0)
	if bf is Figure3D:
		(bf as Figure3D).act("lift", 1.1)
	await Cine.wait(w, 0.6)
	var lid: Node3D = r.lid
	var lt := w.create_tween().set_parallel(true)
	lt.tween_property(lid, "rotation:x", -1.9, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lt.tween_property(r.box_light, "light_energy", 1.2, 1.0)
	await lt.finished
	w.shake(0.08)
	Cine.shot(w, r.chest + Vector3(0.3, 1.25, 0.8), r.chest + Vector3(0, 0.6, 0), 32.0)
	await Cine.wait(w, 1.0)
	# and sweeps them into a sack
	var sack := _sack(v)
	var bp := Cine.body(w, "bram").global_position
	var side: Vector3 = (bp - (r.chest as Vector3))
	side.y = 0.0
	sack.global_position = (r.chest as Vector3) + side.normalized().cross(Vector3.UP) * 0.85 + Vector3(0, 0.0, 0)
	var perp := side.normalized().cross(Vector3.UP)
	Cine.shot(w, (r.chest as Vector3) - perp * 1.6 + side.normalized() * 0.5 + Vector3(0, 1.25, 0), (r.chest as Vector3) + perp * 0.35 + Vector3(0, 0.4, 0), 38.0)
	if bf is Figure3D:
		(bf as Figure3D).pose("lift", 0.35, 0.3)
	for b in r.boxes:
		var box: Node3D = b
		var tw := w.create_tween()
		var from := box.global_position
		var to := sack.global_position + Vector3(0, 0.35, 0)
		tw.tween_method(func(u: float) -> void:
			if is_instance_valid(box):
				box.global_position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 0.25, 0), 0.0, 1.0, 0.32)
		tw.tween_callback(func() -> void:
			if is_instance_valid(box):
				box.visible = false)
		_sfx(w, "card_fly", 0.8)
		await Cine.wait(w, 0.22)
	await Cine.wait(w, 0.4)
	if bf is Figure3D:
		(bf as Figure3D).release(0.3)
		sack.reparent(bf, true)
		(bf as Figure3D).carry(sack, Vector3(0.32, 0.5, 0.05))
		sack.rotation = Vector3.ZERO
	# the rug pulled aside, the trapdoor up, and a tunnel shored with old timber
	var trap: Vector3 = r.trap
	Cine.walk(w, "bram", trap + Vector3(0.9, 0, -0.2), 1.6)
	Cine.shot(w, trap + Vector3(1.8, 1.5, 1.6), trap, 38.0)
	await Cine.wait(w, 1.0)
	Cine.look(w, "bram", trap)
	var rug: Node3D = r.rug
	var rt := w.create_tween()
	rt.tween_property(rug, "position", rug.position + Vector3(-1.4, 0, 0.4), 0.7).set_trans(Tween.TRANS_SINE)
	await rt.finished
	(r.hole as Node3D).visible = true
	var td: Node3D = r.trapdoor
	var tt := w.create_tween()
	tt.tween_property(td, "rotation:x", -1.75, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tt.finished
	_tunnel_timbers(v, trap)
	w.shake(0.06)
	Cine.shot(w, trap + Vector3(2.0, 1.6, 1.9), trap + Vector3(0.3, 0.45, 0.0), 46.0)
	await Cine.wait(w, 1.2)
	Cine.look(w, "bram", w.player.global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 32.0)
	await Cine.say(w, "bram", "Dug this the year I came. Never told you. Never told anyone.")
	await Cine.fade(w, 1.0, 1.0)
	if is_instance_valid(sack):
		sack.queue_free()
	InnRooms.outside(v)
	for n in w.npcs:
		n.doll.visible = true


## Bram's sack: rough cloth, tied at the neck.
static func _sack(v: AshfordVillage) -> Node3D:
	var n := Node3D.new()
	v.add_child(n)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color(0.5, 0.41, 0.28)
	cloth.roughness = 1.0
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.5
	body.mesh = sm
	body.material_override = cloth
	body.position = Vector3(0, 0.24, 0)
	body.scale = Vector3(1.0, 1.0, 0.85)
	n.add_child(body)
	var neck := MeshInstance3D.new()
	var nm := CylinderMesh.new()
	nm.top_radius = 0.06
	nm.bottom_radius = 0.035
	nm.height = 0.12
	neck.mesh = nm
	neck.material_override = cloth
	neck.position = Vector3(0, 0.52, 0)
	n.add_child(neck)
	return n


## Under the trapdoor: the tunnel's mouth framed in old timber, and the top of
## a ladder going down into the dark.
static func _tunnel_timbers(v: AshfordVillage, trap: Vector3) -> void:
	if v.has_meta("tunnel_timbers"):
		return
	v.set_meta("tunnel_timbers", true)
	var n := Node3D.new()
	v.add_child(n)
	n.global_position = trap
	for z in [-0.48, 0.48]:
		v.box(n, Vector3(1.08, 0.07, 0.12), Vector3(0, 0.035, z), v.mats.beam)
	for x in [-0.48, 0.48]:
		v.box(n, Vector3(0.12, 0.07, 0.84), Vector3(x, 0.035, 0), v.mats.beam)
	for x in [-0.2, 0.2]:
		var rail := v.box(n, Vector3(0.05, 0.9, 0.05), Vector3(x, 0.12, 0.36), v.mats.beam_v)
		rail.rotation.x = -0.25
	for k in 2:
		v.box(n, Vector3(0.42, 0.035, 0.035), Vector3(0, 0.1 + k * 0.24, 0.34 + k * 0.06), v.mats.wood_h)
