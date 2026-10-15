class_name Prologue
extends RefCounted
## The Sigilfall: the night the player's life changes, their first deck and
## their first duel on the road to Solhaven. Lines follow the Spoken Script
## (P3 to P5); the garden escape is told rather than played until it's built.


static func play(story: StoryScreen, main) -> void:
	await story.fade(1.0, 0.01)
	await story.scene("sigilfall", [
		{"text": "For two thousand years, Solmaris has sat the Throne of Ages. On the last night of her Age, the sky over the village of Ashford tore open."},
		{"text": "Lights fell like rain. People called it a Sigilfall: magic from the war of the gods, leaking into our world and crystallising as cards."},
	])
	await story.scene("card", [
		{"text": "One of them landed at your feet. A card with nothing on it. Warm as a heartbeat."},
		{"text": "When you picked it up, a mark burned itself into the back of your hand."},
	])
	await play_after_marking(story, main, false)


## From the heralds onward: what follows the marking played in Ashford
## (Spoken Script P3 to P5).
static func play_after_marking(story: StoryScreen, main, faded := true) -> void:
	if faded:
		await story.fade(1.0, 0.01)
	var gore: bool = String(Game.settings.get("violence", "full")) == "full"
	# --- P3 · Dawn: the Pale Herald
	await story.scene("heralds", [
		{"text": "Dawn comes anyway. Smoke lies over the hills, and children pick fallen Sparks out of the furrows and squabble over them like conkers."},
		{"who": "hob", "name": "Hob", "text": "Lost half the barley and the mill roof. Found nine cards in the cabbages. Can't tell if that's a good trade."},
		{"text": "A mist comes down the road against the wind. In it walks a grey horse that leaves no prints. Its rider's hood is empty."},
		{"who": "bram", "name": "Bram", "text": "A Pale Herald. Morrowen's own. Keep your head down and your hand in your pocket."},
		{"who": "herald", "name": "The Pale Herald", "text": "Hear the Covenant."},
		{"who": "herald", "name": "The Pale Herald", "text": "The Age of Solmaris is ending. By the Covenant, the Turning begins. For one year, every Seat in Veyl may be challenged by anyone."},
		{"who": "herald", "name": "The Pale Herald", "text": "Solhaven, for Solmaris the Radiant: Ser Aldric Vane."},
		{"who": "herald", "name": "The Pale Herald", "text": "Pyreholt, for Pyrrhane the Burning Crown: Warlord Vorn."},
		{"who": "herald", "name": "The Pale Herald", "text": "Hrimmark, for Vaelith the Frost Queen: Eiran, its King."},
		{"who": "herald", "name": "The Pale Herald", "text": "Stormreach, for Ixara the Storm Herald: Rook, of the Gale's Debt."},
		{"who": "herald", "name": "The Pale Herald", "text": "Umbravel, for Nocthra the Veiled Mother: Silk."},
		{"who": "herald", "name": "The Pale Herald", "text": "Somnara, for Oriel the Dreaming Eye: Sister Maelis."},
		{"who": "herald", "name": "The Pale Herald", "text": "Glyphmere, for Aldrith the Runeweaver: Magister Tobias Crane."},
		{"who": "herald", "name": "The Pale Herald", "text": "And one more. Bound to no god, holding no Seat. Marked by the Covenant itself."},
		{"text": "The mark on your hand blazes straight through your pocket. Every head in Ashford turns. Last of all, slowly, the empty hood."},
	])
	await story.scene("heralds", [{"text": "Nobody has told the Herald your name. The empty hood speaks it anyway. What does it say?"}])
	var nm := await story.ask_name("Ash")
	Game.player_name = nm
	await story.scene("heralds", [
		{"who": "herald", "name": "The Pale Herald", "text": "{name}."},
		{"who": "herald", "name": "The Pale Herald", "text": "The Unsworn."},
		{"who": "herald", "name": "The Pale Herald", "text": "Present your mark at the Sun Court of Solhaven before the new moon, or forfeit it."},
		{"text": "The Herald rides back into the mist, and the mist goes with it. Nobody speaks. Then Tilly waves."},
		{"text": "That afternoon. The taproom, shutters closed. Bram turns the blank card over in the lamplight."},
		{"who": "bram", "name": "Bram", "text": "Thirty years duelling, and I never saw a Sigil with nothing on it."},
		{"choice": ["What does it do?", "Can I give it back?"], "then": [
			[{"who": "bram", "name": "Bram", "text": "Nothing I can see. That's what worries me."}],
			[{"who": "bram", "name": "Bram", "text": "To who? The sky?"}],
		]},
		{"who": "bram", "name": "Bram", "text": "Heard of one, once. In a story nobody believed."},
		{"choice": ["What story?", "And the Sun Court?"], "then": [
			[{"who": "bram", "name": "Bram", "text": "An old one. Eat something."}],
			[{"if": "want_solhaven",
				"then": [{"who": "bram", "name": "Bram", "text": "You wanted Solhaven. The sky was listening. Eat something."}],
				"else": [{"who": "bram", "name": "Bram", "text": "You asked why anyone would want Solhaven. Now you'll find out. Eat something."}]}],
		]},
		{"text": "He hands the card back and doesn't look at it again."},
	])
	# --- P4 · That night: Ashford burns
	var death := "The hound's jaws close on his throat. Blood runs between the cobbles. Nell says his name. Just once. The way she'd call him in for supper." if gore \
		else "The hound drags him down out of sight. Nell says his name. Just once. The way she'd call him in for supper."
	await story.scene("fire", [
		{"text": "Hoofbeats on the road. Riders in black and gold, torches high, and beside them hounds made of metal, with lantern-light where their eyes should be."},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Evening, Ashford. Nice lanterns."},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Ironvault holds the note on every roof in this village. Mill, inn, barns, the lot. One card settles it. Every debt, gone."},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Where is the Unsworn?"},
		{"text": "Silence. Nell looks at the ground. Hob looks at Nell. Nobody points."},
		{"text": "It is Tam who moves. Forty years of flour, a note he could never pay, and a pitchfork. Krell clicks her fingers, and a Shieldhound brings him down."},
		{"text": death},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Anyone else? No? Then burn the note."},
		{"text": "Behind the inn's woodpile, Bram pulls you into the dark."},
		{"who": "bram", "name": "Bram", "text": "Listen to me. They can't just take it off you. A Sigil taken by force turns to dust. The Covenant sees to that."},
		{"who": "bram", "name": "Bram", "text": "They need you to stake it in a sworn duel and lose. Or they need you dead."},
		{"choice": ["Then I'll duel them.", "What do we do?"], "then": [
			[{"who": "bram", "name": "Bram", "text": "Them and their dogs? Not tonight. Not ever, if I can help it."}],
			[{"who": "bram", "name": "Bram", "text": "We go. Quiet, and now. Stay behind me."}],
		]},
		{"text": "Lantern beams sweep the back gardens. You go hedge to hedge behind Bram while the hunters shout to each other over the roofs. Nothing here. Check the barns. Huntmaster wants the innkeeper alive."},
		{"text": "The Crooked Lantern is burning. Bram stops at the back door."},
		{"who": "bram", "name": "Bram", "text": "My decks are in the cellar. I'm not leaving them to Ironvault."},
		{"choice": ["I'm coming with you.", "Bram, the roof's coming down!"], "then": [
			[{"who": "bram", "name": "Bram", "text": "Course you are. Stubborn. Wonder where you got that."}],
			[{"who": "bram", "name": "Bram", "text": "Then we'd best be quick."}],
		]},
		{"text": "The cellar. Smoke under the door. Bram heaves open an iron-bound chest: four card boxes, worn soft at the corners."},
		{"who": "bram", "name": "Bram", "text": "My old decks. One for every kind of fight I ever had. Pick the one that feels like yours."},
	])
	var deck := await story.choose_starter()
	Game.new_game(nm, deck, true)
	Game.set_flag("bram_deck")
	prologue_gifts()
	var tails := {
		"emberstorm": "Emberstorm. Hits first and hits hardest. I won a duke's bet with that one.",
		"tidegrove": "Tidegrove. Patient. Heals what the others break, then drowns them. Nobody ever thanked me for a win with it.",
		"ironstone": "Ironstone. Takes a beating and gives it back twice as hard. The one I'd pick, if I'm honest about myself.",
		"veilwild": "Veilwild. Tricks and dreams. Wins duels nobody thinks it can. Including me, most nights.",
	}
	await story.scene("fire", [
		{"who": "bram", "name": "Bram", "text": String(tails.get(deck, "That one. Good."))},
		{"who": "bram", "name": "Bram", "text": "Good. That one was always going to be yours."},
		{"text": "He pulls a rug aside: a trapdoor, and an old smugglers' tunnel."},
		{"who": "bram", "name": "Bram", "text": "Every inn worth its beer has one of these."},
		{"text": "The riverbank below the hill. Above, Ashford burns. On the far bank the villagers huddle together, safe. Corin is with them, soot on his face, holding Tilly's hand."},
		{"who": "corin", "name": "Corin", "text": "Go! I'll look after the green!"},
		{"choice": ["Come with us!", "We'll come back!"], "then": [
			[{"who": "corin", "name": "Corin", "text": "Somebody's got to stay! Go on! Go!"}],
			[{"who": "corin", "name": "Corin", "text": "You'd better! You owe me next year's Lantern Duel!"}],
		]},
		{"if": "hob_gift", "then": [
			{"who": "hob", "name": "Hob", "text": "Wait! Found these in the cabbages this morning. Came up with my cabbages, so they're yours. The cabbages I'm keeping."},
			{"text": "He skims a bundle across the shallows: nine Spark cards, still damp, tied with barley straw."},
		]},
		{"text": "Nell stands apart from the others, looking back at the mill. She does not wave."},
		{"text": "Up the hill, the roof of the Crooked Lantern falls in. Bram watches until it is finished."},
		{"who": "bram", "name": "Bram", "text": "We'll come back, Sprout. I swear it on the Lantern."},
	])
	# --- P5 · The Thornwood road
	await story.scene("camp", [
		{"text": "The Thornwood road, east. The first night: a campfire in a clearing. Bram is roasting something that was probably a rabbit."},
		{"who": "bram", "name": "Bram", "text": "Tam ground my flour from the day I opened the inn. Never once weighed it in his own favour. And he went at Ironvault's huntmaster with a hay fork."},
		{"who": "bram", "name": "Bram", "text": "I took you out the back door instead. I'd do it again tomorrow. Doesn't mean I sleep."},
		{"who": "bram", "name": "Bram", "text": "Lords used to hire me to settle their quarrels, you know. Duel for a field, duel for a dowry, duel for a bridge. Good money."},
		{"choice": ["Why did you stop?", "Were you any good?"], "then": [
			[{"who": "bram", "name": "Bram", "text": "...Someone paid me for a job I shouldn't have taken. Then I stopped."}],
			[{"who": "bram", "name": "Bram", "text": "Sprout, I was the best you never heard of. That's the best kind."}],
		]},
		{"who": "bram", "name": "Bram", "text": "Before you sleep. Two things we didn't get to at the Lantern. First: Wards. Corin's never owned one.", "learn": "wards:1", "group": "Wards"},
		{"who": "bram", "name": "Bram", "text": "Some of the cards in that box are Wards. You set one face down for next to nothing, and it waits. When the right thing happens, a Totem called, a Rite cast, a hit coming in, it springs by itself and does its work. He can't read it, so he can't plan round it. Set them early.", "learn": "wards:2", "group": "Wards"},
		{"who": "bram", "name": "Bram", "text": "Second: the rest of the elements. Twelve of them, and every one hurts something and fears something. Water beats fire, you've seen that. Here's the lot.", "learn": "elements:1", "group": "The elements"},
		{"chart": "elements"},
		{"who": "bram", "name": "Bram", "text": "Hit a weakness and it takes half again as much. You won't hold all that in your head tonight. It's in your pack, under How to Duel, with everything else I've told you.", "learn": "elements:2", "group": "The elements"},
		{"who": "bram", "name": "Bram", "text": "Fancy a practice round before we sleep? I'll go easy. Mostly."},
	])
	var practice: int = await story.box.choose(["Let's duel.", "Let's sleep."])
	story.box.close()
	if practice == 0:
		await story.fade(1.0, 0.5)
		var won_practice: bool = await main.run_duel(practice_duel_spec(deck))
		await story.fade(0.0, 0.5)
		if won_practice:
			await story.scene("camp", [{"who": "bram", "name": "Bram", "text": "Hm! Not bad. Not bad at all."}])
		else:
			await story.scene("camp", [{"who": "bram", "name": "Bram", "text": "Mostly easy, I said."}])
	else:
		await story.scene("camp", [{"who": "bram", "name": "Bram", "text": "Wise. You'll need it."}])
	await story.scene("road", [
		{"text": "The second night. The road narrows between thorn trees, and the fireflies go out."},
		{"who": "bram", "name": "Bram", "text": "Stay close."},
		{"text": "A wiry figure steps out of the trees, a bronze mask over his mouth and a Shieldhound clanking at his heel."},
		{"who": "hunter", "name": "Hunter Dask", "text": "The Unsworn's card. Hand it over, and the old man lives."},
		{"who": "bram", "name": "Bram", "text": "Covenant law, boy. Stake it in a sworn duel, or walk away."},
		{"who": "hunter", "name": "Hunter Dask", "text": "Fine. Swear it, Unsworn. Your card against my whole deck."},
		{"text": "You swear, and the air closes around the words like a lock. Your card against his deck. (Lose a story duel and you simply fight it again.)"},
	])
	await story.fade(1.0, 0.5)
	var won := false
	while not won:
		won = await main.run_duel(road_duel_spec())
	Game.set_flag("beat_hunter")
	# the wager: Dask's whole deck
	for id in DuelCards.card_list("dask_hounds"):
		Game.v2.collection[id] = int(Game.v2.collection.get(id, 0)) + 1
		if not Game.v2.codex.has(id):
			Game.v2.codex[id] = "seen"
	await story.fade(0.0, 0.5)
	await story.scene("road", [
		{"who": "hunter", "name": "Hunter Dask", "text": "Take them, then. This isn't over. Caldus Morne pays well for that card, Unsworn."},
		{"text": "He throws his deck at your feet and is gone into the trees. Thirty cards: hounds, traps and poison, yours by the Covenant."},
		{"who": "bram", "name": "Bram", "text": "Morne."},
		{"text": "He says nothing else that night. At dawn, white towers catch the first sun across the plains."},
		{"who": "bram", "name": "Bram", "text": "There she is. Solhaven. Gold on the outside. We'll see about the inside."},
	])
	await story.fade(1.0, 0.8)


## Tilly's Lantern Moth (always) and Hob's nine cabbage Sparks (if the player
## carried Tam's barrel, woke Tilly's moth and sat with Nell) join the v2
## collection once Bram's deck is chosen.
static func prologue_gifts() -> void:
	var v: Dictionary = Game.v2
	var gifts: Array = []
	if Game.flag("has_lantern_moth") and not Game.flag("moth_given"):
		gifts.append("lantern_moth")
	if Game.flag("ash_tam") and Game.flag("ash_tilly") and Game.flag("ash_nell"):
		Game.set_flag("hob_gift")
		gifts += ["mossling", "mossling", "sparkkit", "sparkkit", "emberwisp", "shellguard", "bloomsprite", "burrowmole", "somnowl"]
	for id in gifts:
		if not DuelCards.CARDS.has(id):
			continue
		v.collection[id] = int(v.collection.get(id, 0)) + 1
		v.bonded[id] = true
		if not v.codex.has(id):
			v.codex[id] = "seen"


## Bram's spare deck for the campfire round: whichever of his four the player
## didn't pick, on the v2 rules.
static func practice_duel_spec(mine: String) -> Dictionary:
	var spare := "ironstone" if mine != "ironstone" else "tidegrove"
	var deck: Array = Game.v2.get("deck", []) if not Game.v2.get("deck", []).is_empty() else DuelCards.card_list(mine)
	var bram := Lore.new_profile("Bram", "", 3)
	return {
		"decks": [deck.duplicate(), DuelCards.card_list(spare)],
		"names": [Game.player_name, "Bram"],
		"profiles": [Game.profile, bram],
		"ai": [false, true],
		"difficulty": 0.35,
		"arena": "tidegrove",
		"story": true,
		"lessons": true,   # Bram explains the first condition, Ward or Ascension, once
		"barks": ["Don't look at my face. Look at the cards.", "Hm.", "That's one way to do it.", "I taught you that. I'm having it back."],
		"rewards": {"opponent": "village"},
		"title": "A practice round · Bram",
	}


## Dask's road duel, on the v2 rules: a sworn wager. Bram explains each new
## thing (a Ward, a condition, an Ascension) from the roadside the first time
## it appears, the same gated way as the Lantern Duel (spec.lessons).
static func road_duel_spec() -> Dictionary:
	var me: String = Game.starter if DuelCards.DECKS.has(Game.starter) else "emberstorm"
	var deck: Array = Game.v2.get("deck", []) if not Game.v2.get("deck", []).is_empty() else DuelCards.card_list(me)
	var dask := Lore.new_profile("Hunter Dask", "", 4)
	Lore.add_attribute(dask, "cunning", 1)
	return {
		"decks": [deck.duplicate(), DuelCards.card_list("dask_hounds")],
		"names": [Game.player_name, "Hunter Dask"],
		"profiles": [Game.profile, dask],
		"ai": [false, true],
		"difficulty": 0.5,
		"arena": "ironstone",
		"story": true,
		"lessons": true,
		"barks": ["Roll, little Unsworn. Let's see your luck.", "Poison's slow. I'm patient.", "Didn't see the trap? Nobody does.", "Krell's going to love this."],
		"rewards": {"opponent": "rival"},
		"title": "Road Duel · a sworn wager",
	}
