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

const SPAWNS := {
	"green": Vector3(1.5, 0, 10.5),
	"inn": Vector3(-19.0, 0, 9.5),
}

const ENV := {}

## The village's old Spark cards: a handful each, one Totem apiece, so the
## first duel is a tutorial. The player's is steady water (Brookfin beats
## Corin's fire); Corin's is brash fire.
const PLAYER_DECK := [
	"brookfin",
	"essence_flask", "essence_flask", "essence_flask", "healing_draught", "healing_draught",
	"bulwark", "bulwark", "travellers_pack", "travellers_pack", "essence_flask", "healing_draught",
]
const CORIN_DECK := [
	"cinderpup",
	"essence_flask", "essence_flask", "essence_flask", "healing_draught", "healing_draught",
	"firebrand", "firebrand", "travellers_pack", "travellers_pack", "essence_flask", "healing_draught",
]

## Bram coaches from his stool; each line appears as the duel reaches that step
## (Spoken Script, P1: the tutorial). "weakness" fires the first time one of
## the player's attacks hits a weakness.
const COACH := [
	{"at": "start", "who": "Bram", "say": "Draw. Five cards to start. Those Sparks are older than the pair of you put together, so be gentle."},
	{"at": "call", "who": "Bram", "say": "Call a Totem into a slot. It's the card's magic, given a body. It fights for you. Inside a circle, nobody bleeds. That's the law."},
	{"at": "essence", "who": "Bram", "say": "Everything costs Essence, and you get more each turn. Spend it. Nobody ever won a duel with savings."},
	{"at": "attack", "who": "Bram", "say": "Now attack. Hit his Totems, or if the slot across from yours is empty, hit him straight. His Life hits zero, you've won. Don't gloat."},
	{"at": "weakness", "who": "Bram", "say": "See that? His pup's fire, your Brookfin's water. Water wins, and it hits half again as hard. The orb on the card tells you what's what."},
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
	Music.play(["ashford_festival", "duel_alt"], 2.0, true)


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
					{"say": "[i]You touch the card. A moth made of lamplight unfolds from it, circles Tilly's head twice and settles back into the paper, still glowing.[/i]"},
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
		"life": 60,
		"story": true,
		"tutorial": true,
		"coach": [] if Game.flag("coach_off") else COACH,
		"barks": CORIN_BARKS,
		"rewards": {"opponent": "village"},
	}


# ================================================================ scenes ===

static func scene(name: String, w: World) -> void:
	match name:
		"midnight":
			await _midnight(w)


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
	await w.cine_to(Vector3(7.5, 2.0, 10.5), Vector3(0.0, 7.5, 0.0), 2.0)
	await hud.dialogue.say("", null, "[i]Midnight. The chapel bell counts twelve, and all of Ashford counts with it.[/i]")
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
