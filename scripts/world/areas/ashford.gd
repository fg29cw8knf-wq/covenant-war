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

## The village's old Spark cards, split between the two young Attuned.
## The player's half is steady (earth and water); Corin's is brash (fire).
const PLAYER_DECK := [
	"pebblit", "pebblit", "pebblit", "brookfin", "brookfin", "brookfin",
	"mossling", "mossling", "mossling", "cinderpup", "cinderpup", "cinderpup",
	"sparkkit", "sparkkit", "sparkkit", "lantern_moth", "lantern_moth", "lantern_moth",
	"shellguard", "shellguard",
	"essence_flask", "essence_flask", "essence_flask", "healing_draught", "healing_draught", "healing_draught",
	"travellers_pack", "travellers_pack", "bulwark", "bulwark",
]
const CORIN_DECK := [
	"sparkkit", "sparkkit", "sparkkit", "emberwisp", "emberwisp", "emberwisp",
	"cinderpup", "cinderpup", "cinderpup", "hearth_salamander", "hearth_salamander",
	"pebblit", "pebblit", "pebblit", "lantern_moth", "lantern_moth", "blightrat", "blightrat",
	"burrowmole", "burrowmole",
	"essence_flask", "essence_flask", "essence_flask", "healing_draught", "healing_draught",
	"travellers_pack", "travellers_pack", "firebrand", "firebrand", "firebrand",
]


static func npcs() -> Array:
	return [
		{"id": "bram", "look": "bram", "name": "Bram", "pos": Vector3(2.2, 0, 2.6), "talk": _bram()},
		{"id": "corin", "look": "corin", "name": "Corin", "pos": Vector3(-8.6, 0, -2.4),
			"duel_flag": "ash_lantern_duel", "duel_needs": "ash_ready", "talk": _corin()},
		{"id": "tom", "look": "farmer", "name": "Tom Hayes", "pos": Vector3(6.4, 0, -2.6), "talk": _tom()},
		{"id": "mae", "look": "child", "name": "Mae", "pos": Vector3(5.2, 0, 8.4), "talk": _mae()},
		{"id": "nell", "look": "elder", "name": "Old Nell", "pos": Vector3(-3.9, 0, 6.6), "talk": _nell()},
		{"id": "seamus", "look": "fiddler", "name": "Seamus", "pos": Vector3(-1.6, 0, -6.4), "talk": _seamus()},
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

static func arrival() -> Array:
	return [
		{"say": "[center][i]The last night of the Age. In two thousand years, nobody in Ashford has seen one end.[/i][/center]"},
		{"who": "bram", "say": "There you are, Sprout. An Age ends once every two thousand years. Let's not be late for it."},
		{"who": "bram", "say": "Lanterns are up, the cider's out and half the village wants a hand with something. See Tom at the hay cart, little Mae by the stall and Old Nell at the well."},
		{"who": "bram", "say": "Then come back to me. Corin's been boasting about the Lantern Duel all week, and somebody has to shut him up."},
		{"set": "ash_started"},
	]


static func _errands_done() -> Array:
	return [{"if": "ash_tom", "then": [{"if": "ash_mae", "then": [{"if": "ash_nell", "then": [{"set": "ash_ready"}]}]}]}]


static func _bram() -> Array:
	return [
		{"if": "ash_lantern_duel", "then": [
			{"who": "bram", "say": "Nearly midnight. Stay close tonight, Sprout."},
		], "else": [
			{"if": "ash_ready", "then": [
				{"who": "bram", "say": "Everyone sorted? Good. Then go and find Corin by the well. Win, and you light the Great Lantern at midnight."},
				{"who": "bram", "say": "Remember what I taught you: one Totem in each of your three slots, Essence to pay for them, and keep something between your rival and your Life."},
			], "else": [
				{"who": "bram", "say": "Still folk wanting a hand, Sprout."},
				{"if": "!ash_tom", "then": [{"who": "bram", "say": "Tom's by the hay cart, fighting with his barrels."}]},
				{"if": "!ash_mae", "then": [{"who": "bram", "say": "Little Mae's at the stall with something to show you. She won't stop until she has."}]},
				{"if": "!ash_nell", "then": [{"who": "bram", "say": "And Old Nell's at the well. Mind, she'll want to tell you a story."}]},
			]},
		]},
	]


static func _tom() -> Array:
	return [
		{"if": "ash_tom", "then": [
			{"who": "tom", "say": "Cider's flowing, barrels are where they should be. A good night, this."},
		], "else": [
			{"who": "tom", "say": "Evening, Sprout. Grab the other end of this, would you? Bram wants the cider by the stall before the dancing starts."},
			{"say": "[i]You heave the last barrel into place. Tom wipes his hands on his shirt.[/i]"},
			{"who": "tom", "say": "Solmaris kept the rain fair for two thousand years. Who knows what we get tomorrow. Drink up while it's free, that's what I say."},
			{"set": "ash_tom"},
		]},
	] + _errands_done()


static func _mae() -> Array:
	return [
		{"if": "ash_mae", "then": [
			{"who": "mae", "say": "It's still glowing! Look!"},
		], "else": [
			{"who": "mae", "say": "Sprout! Sprout, look! A Lantern Moth! Da found it in the barley. It's only a Spark, but it's mine."},
			{"who": "mae", "say": "Only Attuned can wake them. Corin says you're Attuned. Are you? Will you wake it?"},
			{"choice": ["Maybe after the duel.", "Not tonight, Mae."], "then": [
				[{"who": "mae", "say": "Promise? It glows brighter when you're near. Look!"}],
				[{"who": "mae", "say": "Aww. It glows when you're near, though. Look!"}],
			]},
			{"say": "[i]The little card in her hands flickers like a candle as you lean closer.[/i]"},
			{"set": "ash_mae"},
		]},
	] + _errands_done()


static func _nell() -> Array:
	return [
		{"if": "ash_nell", "then": [
			{"who": "nell", "say": "Lights in the sky, child. Mark my words."},
		], "else": [
			{"who": "nell", "say": "Sit with me a moment, child. My knees won't take the dancing."},
			{"who": "nell", "say": "My gran's gran used to say the last Age began with lights in the sky. Gods squabbling over a chair, she said, and the sparks falling on us."},
			{"who": "nell", "say": "She said it should have gone to the Burning Crown, too. Then the great sundial ran slow. Nonsense, probably."},
			{"who": "nell", "say": "Stay close to Bram tonight. Old bones feel things."},
			{"set": "ash_nell"},
		]},
	] + _errands_done()


static func _seamus() -> Array:
	return [
		{"who": "seamus", "say": "Any requests? No? Then it's the Lantern Reel again, and you'll like it."},
	]


static func _corin() -> Array:
	return [
		{"if": "ash_lantern_duel", "then": [
			{"who": "corin", "say": "Midnight any second now. Look at all those lanterns!"},
		], "else": [
			{"if": "!ash_ready", "then": [
				{"who": "corin", "say": "Oi, Sprout! Ready to lose? Bram says you've jobs to do first. Hurry up, I want my audience warmed up."},
			], "else": [
				{"who": "corin", "say": "Lantern Duel, Sprout. The village's old Spark cards, same as every year. Winner lights the Great Lantern at midnight."},
				{"who": "corin", "say": "Half of Ashford's watching. Try not to cry."},
				{"who": "bram", "say": "Quick reminder. Tap a Totem in your hand to call it into a slot, and pay its cost in Essence. You get more Essence every turn."},
				{"who": "bram", "say": "Tap one of your Totems to see its moves, then pick a target. When Corin's slots are empty, you can strike his Life directly. First to zero Life loses."},
				{"duel": {"v1": true, "id": "corin_lantern", "name": "Corin", "difficulty": 0.25},
					"win": [
						{"who": "corin", "say": "Fine! Fine. Go on, light the thing. Next year it's mine."},
						{"set": "ash_won_lantern"},
						{"say": "[i]By tradition the winner keeps one of the village Sparks. You pick the Lantern Moth.[/i]"},
						{"set": "has_lantern_moth"},
					],
					"lose": [
						{"who": "corin", "say": "Ha! Told you. Watch and learn, Sprout. Watch and learn."},
					]},
				{"set": "ash_lantern_duel"},
				{"scene": "midnight"},
			]},
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
		"life": 80,
		"story": true,
	}


# ================================================================ scenes ===

static func scene(name: String, w: World) -> void:
	match name:
		"midnight":
			await _midnight(w)


## P1's end and P2: the Great Lantern, the sky lanterns, the Sigilfall and the marking.
static func _midnight(w: World) -> void:
	var v := village(w)
	var hud := w.hud
	w.cine = true
	hud.set_controls_visible(false)
	var p := w.player.global_position
	for n in w.npcs:
		n.doll.set_marker("")
	await w.cine_to(Vector3(7.5, 2.0, 10.5), Vector3(0.0, 7.5, 0.0), 2.0)
	await hud.dialogue.say("", null, "[i]Midnight. The bell in the chapel tower rings twelve.[/i]")
	if Game.flag("ash_won_lantern"):
		await hud.dialogue.say("", null, "[i]You touch a taper to the Great Lantern. It roars into light, and the whole village cheers.[/i]")
	else:
		await hud.dialogue.say("", null, "[i]Corin lights the Great Lantern with a flourish, and the whole village cheers.[/i]")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Two thousand years. Wonder who'll be sitting up there tomorrow.")
	hud.dialogue.close()
	# the sky lanterns go up
	v.release_lanterns()
	await w.cine_to(Vector3(16.0, 2.2, 16.0), Vector3(0.0, 14.0, -10.0), 5.0)
	await w.get_tree().create_timer(3.5).timeout
	await hud.dialogue.say("", null, "[i]Hundreds of paper lanterns rise over Ashford. And then they stop, and hang in the air, perfectly still.[/i]")
	hud.dialogue.close()
	# the sky tears
	await w.cine_to(Vector3(6.0, 3.0, 20.0), Vector3(34.0, 22.0, -40.0), 3.0)
	v.start_sigilfall()
	Music.play(["sigilfall"], 0.5, true)
	await w.flash(Color(0.9, 0.92, 1.0), 0.25, 1.2)
	await w.get_tree().create_timer(2.5).timeout
	await hud.dialogue.say("Corin", DollArt.portrait("corin"), "Bram... what is that?")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Inside. All of you. Now!")
	hud.dialogue.close()
	v.first_impact()
	w.shake(0.6)
	await w.cine_to(Vector3(-6.0, 3.5, 12.0), Vector3(-24.0, 6.0, -26.0), 2.0)
	v.ignite_roof()
	await w.get_tree().create_timer(2.5).timeout
	await hud.dialogue.say("", null, "[i]Light rains down in every colour. Where it lands, the thatch catches.[/i]")
	await hud.dialogue.say("", null, "[i]Then one light falls slower than the rest. White. Silent. Coming straight for you.[/i]")
	hud.dialogue.close()
	# the white light and the marking
	Music.stinger("the_marking")
	var hand := p + Vector3(0, 1.3, 0.2)
	await w.cine_to(p + Vector3(3.5, 2.2, 6.5), p + Vector3(0, 2.8, 0), 1.5)
	v.send_white_light(hand, 6.0)
	await v.phase_done
	v.lights_out()
	v.hide_white_light()
	await w.flash(Color(1, 1, 1), 0.08, 1.6)
	await hud.dialogue.say("", null, "[i]You catch it: a card with nothing on it, warm as a heartbeat.[/i]")
	await hud.dialogue.say("", null, "[i]A white mark burns itself into the back of your hand. Every other light in the sky goes out at once.[/i]")
	await hud.dialogue.say("Bram", DollArt.portrait("bram"), "Put that in your pocket, Sprout. Don't show anyone. Not anyone.")
	hud.dialogue.close()
	Game.set_flag("ash_marked")
	await hud.fade(1.0, 1.5)
	w.story_next.emit("prologue_heralds")
