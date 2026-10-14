extends RefCounted
## Ashford — the player's home village, on the last night of the Age.
## Prologue scenes P1 (The Last Night) and P2 (Sigilfall) from the story bible.
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

const SPAWNS := {
	"green": Vector3(1.5, 0, 10.5),
	"inn": Vector3(-19.0, 0, 9.5),
}

const ENV := {}

## The village's old Spark cards: a handful each, one Totem apiece, so the
## first duel is a tutorial. The player's is steady water (Brookfin beats
## Corin's fire); Corin's is brash fire. Both are dealt in the order written
## (no shuffle), so every lesson below has the card it needs.
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
			{"say": "These are Sparks, the smallest kind. Ploughs turn them up all the time. Ashford's kept this lot in a box at the inn since before my grandad."},
			{"say": "That's the gods on a quiet day, mind. When they fight, it doesn't drip. It pours."},
			{"say": "Only the Attuned can wake one. In this village, that's you and Corin. Lucky us."},
			{"say": "A duel's how sensible folk settle things. Your Totems do the fighting. Bring his Life down to nothing and you've won.", "focus": "life"},
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
			{"say": "Tap Bulwark.", "do": "card:bulwark"},
			{"say": "Now tap Brookfin. The stone soaks up the next hit.", "do": "target:brookfin"},
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
		{"id": "hob", "look": "hob", "name": "Hob", "pos": Vector3(9.4, 0, 6.2), "talk": _hob()},
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
			{"who": "bram", "say": "Everyone sorted? Good. Corin's by the well, warming up his audience. Go and spoil the ending. Whoever wins lights the Great Lantern at midnight."},
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
					{"who": "tilly", "say": "Again! Again! It never does that for Da. It never does that for anyone."},
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


static func _corin() -> Array:
	return [
		{"who": "corin", "say": "Oi! Ashford's second-best Attuned! Ready to lose? Or are you off helping old ladies first? Either way, I'm here, deciding which side of my face the crowd gets."},
		{"choice": ["Let's duel.", "Not yet."], "then": [
			[
				{"who": "corin", "say": "Lantern Duel. The village's old Sparks, same as every year. Winner lights the Great Lantern at midnight. Loser carries the drum home."},
				{"who": "corin", "say": "Half of Ashford's watching. I told the other half to hurry. And no going easy on me. I'd know."},
				{"who": "bram", "say": "One Spark each. And nobody sets fire to a stall. I'm looking at you, Corin."},
				{"who": "corin", "say": "That was one stall."},
				{"who": "bram", "say": "Want me calling your turns from the stool, Sprout? No shame either way. A Totem in a slot, Essence to pay its way, nothing empty between him and your Life."},
				{"choice": ["Talk me through it, Bram.", "I know how to duel."], "then": [
					[{"who": "bram", "say": "Sensible. Listen for me."}],
					[{"set": "coach_off"}, {"who": "bram", "say": "Then I'll keep my mouth shut and my eyebrows ready."}],
				]},
				{"duel": {"v1": true, "id": "corin_lantern", "name": "Corin", "difficulty": 0.25},
					"win": [
						{"who": "corin", "say": "Fine. Fine! You were better. Tonight. Go on, light the thing. Next year it's mine."},
						{"set": "ash_won_lantern"},
					],
					"lose": [
						{"who": "corin", "say": "Ha! Second-best, I said. You nearly had me, though. Nearly. Come on. Best view of the Lantern's next to me."},
					]},
				{"say": "[i]Tilly squeezes through the crowd and presses something warm into your hand. Her Lantern Moth.[/i]"},
				{"who": "tilly", "say": "For luck! You keep it. It glows better for you anyway."},
				{"set": "has_lantern_moth"},
				{"set": "ash_lantern_duel"},
				{"scene": "midnight"},
			],
			[{"who": "corin", "say": "Go on, then. Hurry up. My audience is getting cold."}],
		]},
	]


## The duel spec World hands to Main for the Lantern Duel.
static func duel_spec(spec: Dictionary) -> Dictionary:
	var arena := "ashford" if DuelArt.arena("ashford") != null else "tidegrove"
	return {
		"decks": [PLAYER_DECK.duplicate(), CORIN_DECK.duplicate()],
		"names": [Game.player_name, "Corin"],
		"profiles": [Lore.new_profile(Game.player_name), Lore.new_profile("Corin")],
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
		"tam_barrel":
			await _tam_barrel(w)
		"tilly_moth":
			await _tilly_moth(w)
		"home":
			await w.cine_home(1.2)


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
	var fast := func(_pos: Vector2) -> void: Engine.time_scale = 4.0
	w.hud.tapped.connect(fast)
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
	if w.hud.tapped.is_connected(fast):
		w.hud.tapped.disconnect(fast)
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
	# from behind the two of them, looking on towards the stall where it's going
	w.cine = true
	w.cine_to(start - dir * 3.8 + Vector3(0, 2.4, 0), spot + Vector3(0, 0.9, 0), 1.0)
	# each takes an end
	_walk(w, null, start + side * 0.8, 0.8)
	await _walk(w, tam, start - side * 0.8, 0.8)
	w.player_doll.look_toward(start, w.cam)
	tam.doll.look_toward(start, w.cam)
	await w.get_tree().create_timer(0.25).timeout
	# lift it onto its side, held between them
	var b0 := b.basis
	var lifted := Basis(dir, PI * 0.5)   # on its side, spanning the two of them
	var tw := w.create_tween().set_parallel(true)
	tw.tween_property(b, "global_position", start + Vector3(0, 0.95, 0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(u: float) -> void: b.basis = Basis(b0.get_rotation_quaternion().slerp(lifted.get_rotation_quaternion(), u)), 0.0, 1.0, 0.5)
	await tw.finished
	# carry it over, side by side
	var end := spot - dir * 0.75
	var secs := maxf(2.2, start.distance_to(end) / 3.0)
	w.player_doll.walking = true
	tam.doll.walking = true
	w.player_doll.face(dir, w.cam)
	tam.doll.face(dir, w.cam)
	var pb: Node3D = w.player
	var tb: Node3D = tam.body
	var carry := w.create_tween()
	carry.tween_method(func(u: float) -> void:
		var c := start.lerp(end, u)
		var bob := absf(sin(u * secs * 6.0)) * 0.05
		b.global_position = c + Vector3(0, 0.95 + bob, 0)
		pb.global_position = c + side * 0.8
		tb.global_position = c - side * 0.8, 0.0, 1.0, secs)
	await carry.finished
	w.player_doll.walking = false
	tam.doll.walking = false
	# heave it up onto its end beside the others
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
	tam.doll.look_toward(pb.global_position, w.cam)
	w.player_doll.look_toward(tb.global_position, w.cam)
	await w.get_tree().create_timer(0.4).timeout
	await w.cine_home(0.9)


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
	w.cine = true
	await w.cine_to(between + perp * 4.6 + axis * 0.6 + Vector3(0, 1.7, 0), tp - axis * 0.3 + Vector3(0, 1.2, 0), 1.0)
	# the card glows, then the moth unfolds out of it
	var glow: MeshInstance3D = v.glow_sprite(w, card, Color(1.0, 0.72, 0.32), 0.4, 0.7)
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
	tilly.doll.look_toward(w.player.global_position, w.cam)
	await w.cine_home(0.9)

## Where Tilly holds her card, and her head, in metres above the ground.
const TILLY_HANDS := 0.85
const TILLY_HEAD := 1.45
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


## P1's end and P2: the Great Lantern, the sky lanterns, the Sigilfall and the marking.
## (The run across the green and the cart are played as a cutscene until they're built.)
static func _midnight(w: World) -> void:
	var v := village(w)
	var hud := w.hud
	w.cine = true
	hud.set_controls_visible(false)
	hud.set_objective("")
	var p := w.player.global_position
	for n in w.npcs:
		n.doll.set_marker("")
	var lantern_top: Vector3 = v.great_lantern_top if v.great_lantern_top != Vector3.ZERO else Vector3(0, 8.0, 0)
	await w.cine_to(Vector3(7.5, 2.0, 10.5), lantern_top - Vector3(0, 0.6, 0), 2.0)
	await hud.dialogue.say("", null, "[i]Midnight. The chapel bell counts twelve, and all of Ashford counts with it.[/i]")
	v.light_great_lantern()
	w.shake(0.15)
	if Game.flag("ash_won_lantern"):
		await hud.dialogue.say("", null, "[i]You touch the taper to the Great Lantern. It catches with a roar, and the whole village roars back.[/i]")
	else:
		await hud.dialogue.say("", null, "[i]Corin lights the Great Lantern with a bow nobody asked for, and the whole village cheers him anyway.[/i]")
	await hud.dialogue.say("Corin", DollArt.portrait("corin"), "It's a good village, this. Don't tell anyone I said so. I've a reputation.")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Folk will tell you we send them up for the gods. We don't. A lantern's for whoever is out in the dark, so they know which way is home.")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Two thousand years. Wonder who'll be sitting up there tomorrow.")
	var pick := await hud.dialogue.choose(["Does it matter to us?", "Whoever it is, I hope they like lanterns."])
	if pick == 0:
		await hud.dialogue.say("Bram", DollArt.portrait("bram"), "It shouldn't. It always seems to.")
	else:
		await hud.dialogue.say("Bram", DollArt.portrait("bram"), "From your mouth to their ears.")
	hud.dialogue.close()
	# the sky lanterns go up
	v.release_lanterns()
	await w.cine_to(Vector3(16.0, 2.2, 16.0), Vector3(0.0, 14.0, -10.0), 5.0)
	await w.get_tree().create_timer(3.5).timeout
	await hud.dialogue.say("", null, "[i]Hundreds of paper lanterns rise over Ashford. And then they stop. Every one of them. They hang in the air as if the night has taken hold of them.[/i]")
	hud.dialogue.close()
	# the sky tears
	await w.cine_to(Vector3(6.0, 3.0, 20.0), Vector3(34.0, 22.0, -40.0), 3.0)
	v.start_sigilfall()
	Music.play(["sigilfall"], 0.5, true)
	await w.flash(Color(0.9, 0.92, 1.0), 0.25, 1.2)
	await w.get_tree().create_timer(2.5).timeout
	await hud.dialogue.say("Corin", DollArt.portrait("corin"), "Bram... is it meant to do that?")
	hud.dialogue.close()
	v.first_impact()
	w.shake(0.6)
	await w.cine_to(Vector3(-6.0, 3.5, 12.0), Vector3(-24.0, 6.0, -26.0), 2.0)
	v.ignite_roof()
	await w.get_tree().create_timer(2.0).timeout
	await hud.dialogue.say("Old Nell", DollArt.portrait("elder"), "Fire! The mill's on fire!")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Inside! All of you, inside! Sprout, to the inn. Now!")
	await hud.dialogue.say("", null, "[i]You run. Light hammers down around you in every colour there is, and where it lands the thatch catches.[/i]")
	await hud.dialogue.say("", null, "[i]By the well, a hay cart has gone over. Corin is pinned under it.[/i]")
	await hud.dialogue.say("Corin", DollArt.portrait("corin"), "Help! My leg's stuck. I can't...")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Get the other side. On three. One, two...")
	await hud.dialogue.say("", null, "[i]You heave together. The cart comes up a hand's width, then another, and Corin drags himself clear.[/i]")
	await hud.dialogue.say("Corin", DollArt.portrait("corin"), "I'm all right. I'm all right. That was... I'm all right.")
	hud.dialogue.close()
	# the white light and the marking
	Music.stinger("the_marking")
	var hand := p + Vector3(0, 1.3, 0.2)
	await w.cine_to(p + Vector3(3.5, 2.2, 6.5), p + Vector3(0, 2.8, 0), 1.5)
	await hud.dialogue.say("", null, "[i]One light falls differently. White. Slow. Silent. It passes Bram. It passes Corin. It stops at you.[/i]")
	hud.dialogue.close()
	v.send_white_light(hand, 6.0)
	await v.phase_done
	v.lights_out()
	v.hide_white_light()
	await w.flash(Color(1, 1, 1), 0.08, 1.6)
	await hud.dialogue.say("", null, "[i]You put out your hand, and it settles there. A card with nothing on it. Warm as a heartbeat.[/i]")
	await hud.dialogue.say("", null, "[i]A white mark burns itself into the back of your hand. Every other light in the sky goes out at once.[/i]")
	await hud.dialogue.say("Corin", DollArt.portrait("corin"), "It came to you. It just... came to you.")
	await hud.dialogue.say("", null, "[i]Bram takes your wrist, sees the mark, and folds your fingers shut over the card.[/i]")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Put that in your pocket, Sprout. Don't show anyone. Not anyone.")
	hud.dialogue.close()
	Game.set_flag("ash_marked")
	await hud.fade(1.0, 1.5)
	w.story_next.emit("prologue_heralds")
