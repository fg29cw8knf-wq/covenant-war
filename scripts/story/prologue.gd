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


## From the heralds onward: what follows the marking played in Ashford.
static func play_after_marking(story: StoryScreen, main, faded := true) -> void:
	if faded:
		await story.fade(1.0, 0.01)
	await story.scene("heralds", [
		{"text": "At dawn, the heralds of Morrowen, witness of the Covenant, rode into every town in Veyl."},
		{"text": "They named the Champions of the Trial of Ages. Seven gods. Seven Champions. Then they read an eighth name, with no god behind it."},
	])
	await story.scene("heralds", [{"text": "What name did they read?"}])
	var nm := await story.ask_name("Ash")
	Game.player_name = nm
	await story.scene("fire", [
		{"text": "They read yours, {name}. The Unsworn."},
		{"text": "By nightfall, hunters from Ironvault came looking for the blank card. Ashford burned."},
		{"who": "bram", "name": "Bram", "text": "Up, {name}! Out the back, now! No, leave it. Leave all of it."},
		{"who": "bram", "name": "Bram", "text": "Here. My old decks. You'll need one where we're going. Pick the one that feels like yours."},
	])
	var deck := await story.choose_starter()
	Game.new_game(nm, deck)
	await story.scene("road", [
		{"who": "bram", "name": "Bram", "text": "Good choice. Now stay close. Solhaven's three days east, and those hunters won't give up."},
		{"text": "On the second night, one of them caught up with you on the road."},
		{"who": "hunter", "name": "Ironvault Hunter", "text": "The blank card. Hand it over, and the old man lives."},
		{"who": "bram", "name": "Bram", "text": "Covenant law, friend. Nobody takes a Sigil by force. Duel for it, or walk away."},
		{"who": "hunter", "name": "Ironvault Hunter", "text": "Fine. I'll take it the legal way."},
	])
	await story.fade(1.0, 0.5)
	var won: bool = await main.run_duel({"deck": "ironvault_hunter", "name": "Ironvault Hunter", "look": "hunter",
		"patron": "", "attrs": {"cunning": 1}, "title": "Road Duel", "tutorial": true})
	if won:
		Game.set_flag("beat_hunter")
		await story.fade(0.0, 0.5)
		await story.scene("road", [
			{"who": "hunter", "name": "Ironvault Hunter", "text": "...This isn't over. Caldus Morne pays well for that card, Unsworn."},
			{"who": "bram", "name": "Bram", "text": "Ha! Not bad for your first real duel. Come on. Solhaven by morning."},
		])
	else:
		await story.fade(0.0, 0.5)
		await story.scene("road", [
			{"who": "bram", "name": "Bram", "text": "Step aside, {name}. I'm old, not dead."},
			{"text": "Bram's cards moved faster than you could follow. The hunter fled into the dark."},
			{"who": "bram", "name": "Bram", "text": "You'll get there. Solhaven by morning. We'll practise on the way."},
		])
	await story.fade(1.0, 0.8)
