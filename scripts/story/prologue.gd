class_name Prologue
extends RefCounted
## The Sigilfall: the night the player's life changes, their first deck and
## their first duel on the road to Solhaven.


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
## (Master Script v2, P3 to P5).
static func play_after_marking(story: StoryScreen, main, faded := true) -> void:
	if faded:
		await story.fade(1.0, 0.01)
	var gore: bool = String(Game.settings.get("violence", "full")) == "full"
	# --- P3 · The Turning
	await story.scene("heralds", [
		{"text": "Dawn. Smoke over the hills. Children pick stray Spark cards out of the furrows and squabble over them."},
		{"who": "hob", "name": "Hob", "text": "Lost half the barley and the mill roof. Found nine cards in the cabbages. Don't know if that's a good trade."},
		{"text": "A mist rolls down the road against the wind. In it walks a grey horse whose hooves leave no prints. Its rider's hood is empty."},
		{"who": "bram", "name": "Bram", "text": "A Pale Herald. Morrowen's own. Keep your head down and your hand in your pocket."},
		{"who": "herald", "name": "The Pale Herald", "text": "Hear the Covenant."},
		{"who": "herald", "name": "The Pale Herald", "text": "The Age of Solmaris is ending. By the Covenant, the Turning begins. For one year, every Seat in Veyl may be challenged by anyone."},
		{"who": "herald", "name": "The Pale Herald", "text": "Solhaven, for Solmaris the Radiant: Ser Aldric Vane. Pyreholt, for Pyrrhane the Burning Crown: Warlord Vorn. Hrimmark, for Vaelith the Frost Queen: Eiran, its King."},
		{"who": "herald", "name": "The Pale Herald", "text": "Stormreach, for Ixara the Storm Herald: Rook, of the Gale's Debt. Umbravel, for Nocthra the Veiled Mother: Silk. Somnara, for Oriel the Dreaming Eye: Sister Maelis. Glyphmere, for Aldrith the Runeweaver: Magister Tobias Crane."},
		{"who": "herald", "name": "The Pale Herald", "text": "And one more. Bound to no god, holding no Seat. Marked by the Covenant itself."},
		{"text": "The mark on your hand blazes through your pocket. Every head turns. The empty hood turns slowly towards you."},
	])
	await story.scene("heralds", [{"text": "The herald speaks your name. What is it?"}])
	var nm := await story.ask_name("Ash")
	Game.player_name = nm
	await story.scene("heralds", [
		{"who": "herald", "name": "The Pale Herald", "text": "{name}. The Unsworn."},
		{"who": "herald", "name": "The Pale Herald", "text": "Present your mark at the Sun Court of Solhaven before the new moon, or forfeit it."},
		{"text": "The herald rides back into the mist, and the mist goes with it. Nobody speaks. Then Tilly waves."},
		{"who": "bram", "name": "Bram", "text": "Thirty years duelling, and I never saw a Sigil with nothing on it. Heard of one, once. In a story nobody believed."},
	])
	# --- P4 · Ashford Burns
	var death := "The hound's jaws close on his throat. Blood runs between the cobbles, and Nell screams." if gore \
		else "The hound drags him down out of sight, and Nell screams."
	await story.scene("fire", [
		{"text": "That night: hoofbeats, torches, and riders in black and gold, with metal hounds padding beside them."},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Evening, Ashford. Nice lanterns. Ironvault holds the note on every roof in this village. One card settles it. All your debts, gone."},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Where is the Unsworn?"},
		{"text": "Silence. Nobody points. Tam the miller swings a pitchfork at the nearest hunter. Krell clicks her fingers, and a Shieldhound brings him down."},
		{"text": death},
		{"who": "krell", "name": "Huntmaster Krell", "text": "Anyone else? No? Then burn the note."},
		{"who": "bram", "name": "Bram", "text": "Listen to me. They can't just take it off you. A Sigil taken by force turns to dust; the Covenant sees to that."},
		{"who": "bram", "name": "Bram", "text": "They need you to stake it in a sworn duel and lose. Or they need you dead. So we go. Quiet, and now."},
		{"text": "The Crooked Lantern is burning. In the cellar, Bram heaves open an iron-bound chest of worn card boxes."},
		{"who": "bram", "name": "Bram", "text": "My old decks. One for every kind of fight I ever had. Pick the one that feels like yours."},
	])
	var deck := await story.choose_starter()
	Game.new_game(nm, deck, true)
	await story.scene("fire", [
		{"who": "bram", "name": "Bram", "text": "Good. That one was always going to be yours. Now, every inn worth its beer has a smugglers' tunnel."},
		{"text": "On the far bank of the river, the villagers huddle together, safe. Corin is with them, soot on his face, holding Tilly's hand."},
		{"who": "corin", "name": "Corin", "text": "Go! I'll look after the green! And you'd better come back. You owe me a rematch!"},
		{"who": "bram", "name": "Bram", "text": "We'll come back, Sprout. I swear it on the Lantern."},
	])
	# --- P5 · The Road East
	await story.scene("road", [
		{"text": "Two nights on the Thornwood road. On the second, the fireflies go out."},
		{"text": "A wiry figure steps out of the trees, a bronze mask over his mouth and a Shieldhound clanking at his side."},
		{"who": "hunter", "name": "Hunter Dask", "text": "The blank card. Hand it over, and the old man lives."},
		{"who": "bram", "name": "Bram", "text": "Covenant law, boy. Stake it in a sworn duel, or walk away."},
		{"who": "hunter", "name": "Hunter Dask", "text": "Fine. Swear it, Unsworn: your card against my whole deck."},
		{"text": "You swear. The blank card goes up as your stake; his whole deck goes up as his. A losing story duel is simply fought again."},
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
		{"text": "He throws his deck at your feet and vanishes into the trees. Thirty cards: hounds, traps and poison, yours by the Covenant."},
		{"who": "bram", "name": "Bram", "text": "Morne."},
		{"text": "He says nothing else that night. At dawn, white towers catch the first sun across the plains."},
		{"who": "bram", "name": "Bram", "text": "There she is. Solhaven. Gold on the outside. We'll see about the inside."},
	])
	await story.fade(1.0, 0.8)


## Dask's road duel, on the v2 rules: a sworn wager.
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
		"rewards": {"opponent": "rival"},
		"title": "Road Duel · a sworn wager",
	}
