extends RefCounted
## Ashford — the player's home village, on the last night of the Age.
## Prologue P1 is played on foot, as Master Script v3 has it
## (docs/script/v3_prologue_p1.md): the words, the talk trees and the
## Lantern Duel are here; the staging (the attic and its mirror, the taproom,
## the crate, the last lantern on the top hook, Tam's barrel and letter,
## Nell's bench, Tilly's moth, the drum) is in ashford_p1.gd. From midnight
## on, the Prologue is a film made in the village itself (Cine and
## CineOverlay): the Sigilfall, the dawn and the Pale Herald, the taproom,
## the night Ashford burns and Bram's cellar. Then the trapdoor, and the
## Thornwood (thornwood.gd).
##
## Layout (metres): the Great Lantern stands at the centre of the green, the
## cottages ring it about 22 m out, the road runs past the south side and the
## camera looks north (towards -z). The village itself is AshfordVillage.

const NAME := "Ashford"
const SUBTITLE := "The Last Night of the Age"

const BOUNDS := Rect2(-24.0, -24.0, 48.0, 44.0)
const CAMERA_X_LIMIT := 13.0
## Where the camera may follow the player past CAMERA_X_LIMIT (in x/z), and
## which way it turns to look there (World._cam_yaw): the lane from the
## green's east side up to the field gate (AshfordDay.LANE), looked along
## from behind, between the cottages (from the south its roofs hid the
## player).
const CAMERA_REACH := [{"rect": Rect2(13.5, -20.5, 11.0, 10.8), "yaw": -0.5}]
## The village builds its own sky, moon, fog and lights.
const CUSTOM_ENV := true
## New Game opens in the inn's attic (intro(): AshfordP1.opening).
const INTRO := true
## A Prologue left part-way picks up where it was (resume()).
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

## The Lantern Duel's lesson, one step at a time, as memories of Bram (2
## November, Gary: "anytime you encounter something new in a duel or are
## about to do something new Bram's memory could pop up as a message teaching
## you how to do it, like you remembered what he taught you over the years";
## until then Bram coached it from his stool, if asked, in Master Script v3's
## "P1 · Bram during the Lantern Duel"). Each line waits for the player: an
## explanation until they tap, an instruction until they've done it, and
## nothing else can be touched meanwhile; the light shows where things are.
## See DuelTutor for the step format. The words are what he taught over the
## years, not what he sees now: nothing in them is about this afternoon's
## board that wouldn't hold in any duel. Only lines v3 marks "(… lights
## up)" have a focus. It teaches only what's on the table tonight (Totems,
## Rites, Essence, Life, attacking, one weakness, Fate and the card panel);
## Wards, the element chart, conditions and Ascension are taught the first
## time each matters, later on.
const LESSON := {
	"events": {
		"intro": [
			{"say": "(Bram's voice comes back to you, from a hundred evenings at the taproom table.)", "who": "", "keep": false},
			{"say": "Those cards are Sigils, Sprout. The gods' magic is always leaking into the world, a drop at a time, and where it lands it sets hard. Like frost on a window."},
			{"say": "Sparks are the smallest kind. That's the gods on a quiet day. When they fight, it doesn't drip. It pours."},
			# (25 October, Gary: say what's at stake, since other duels will
			# have more riding on them)
			{"say": "There's more to duelling than one afternoon's worth. Start with the basics. The rest comes as the cards do."},
			{"say": "Your Totems do the fighting. Bring the other duellist's Life down to nothing and you've won.", "focus": "life"},
			{"say": "Every duel has its stakes. Some are played for cards, some for coin, and some for a good deal worse. A friendly's played for nothing but pride, and the Lantern Duel's played for the Lantern."},
			{"say": "First thing, always: roll for who goes first. Highest starts.", "do": "die"},
		],
		"rival_call": [
			{"say": "A Cinderpup. That's fire. Mark what element every Totem is the moment it's called: it decides what hurts it."},
		],
		"weakness": [
			{"say": "See that? Water puts fire out. Hit a Totem where it's weak and it hurts a good deal more. The sign on every card says what it fears.", "learn": "weakness"},
		],
		"rival_fate": [
			{"say": "That's Fate. Some moves roll the die: high, and they hit hard; low, nothing. A fire deck's full of them.", "learn": "fate"},
		],
		"absorbed": [
			{"say": "And when the stone's up, the stone takes the lot. That's what you paid for."},
		],
		"ko_rival": [
			# (v7: so it doesn't clash with Tam's death the next evening)
			{"say": "Out it goes, back into its card. Nobody bleeds inside a Circle unless the stakes say so, and in a friendly they don't."},
		],
		"hit_mine": [
			{"say": "When they start throwing Rites at your Totem, it's because they can't beat it with teeth. Hold your nerve: a Totem's tougher than it looks."},
		],
	},
	"turns": [
		[
			{"say": "That's your hand. Five to start, and one more every turn after this.", "focus": "hand"},
			{"say": "Start with your Totem. Brookfin's a Spark of river water. Pick it up.", "do": "card:brookfin"},
			{"say": "That's the card up close: what it costs, what it is, what its moves do. You can look at any card like that, theirs or yours. Do it before you play it, every time.", "focus": "detail"},
			{"say": "Now call it into the Circle.", "do": "slot:1"},
			{"say": "That cost one Essence. You get another every turn, and what you don't spend is gone, so spend it.", "focus": "essence"},
			{"say": "Nobody attacks on the first turn, and a Totem that's just been called needs a moment to find its feet. That's a first turn done."},
			{"say": "End your turn.", "do": "end"},
		],
		[
			{"say": "You drew one. Every turn, like I said."},
			{"say": "Brookfin can fight now.", "do": "totem:brookfin"},
			{"say": "Splash costs nothing. Undertow costs one Essence, hits harder and mends Brookfin a little. The free move first, while the other side's fresh.", "do": "move:0"},
			{"say": "At the Cinderpup.", "do": "target:cinderpup"},
			{"say": "You've still two Essence. Not every card's a Totem. That Bulwark's a Rite: magic you cast once, then it's gone.", "focus": "card:bulwark"},
			{"say": "It throws a wall of stone round one of your Totems. The next hit it takes, the stone takes first, up to fifty of it."},
			{"say": "A fire deck goes straight for your Totem the moment it can. It always does. So the wall goes up before it comes.", "focus": "foe:cinderpup"},
			{"say": "Bulwark.", "do": "card:bulwark"},
			{"say": "Round Brookfin.", "do": "target:brookfin"},
			{"say": "That'll do. End it.", "do": "end"},
		],
		[
			{"say": "Their Totem's hurting. Undertow will finish it."},
			{"say": "Brookfin.", "do": "totem:brookfin"},
			{"say": "Undertow.", "do": "move:1"},
			{"say": "The Cinderpup.", "do": "target:cinderpup"},
			{"say": "Nothing stands across from Brookfin now. Next turn it goes straight at the duellist.", "focus": "life"},
			{"say": "End your turn.", "do": "end"},
		],
		[
			{"say": "Now. Brookfin.", "do": "totem:brookfin"},
			{"say": "Undertow.", "do": "move:1"},
			{"say": "Straight at them. Nothing's in the way.", "do": "target:life"},
		],
	],
}

## Corin's side of the lesson, one list per turn (DuelHuman.Scripted): he calls
## his pup across from Brookfin, tries his luck with a Fate move (the roll is set
## so the Bulwark holds), then throws a Rite. The duel is dealt in this order
## whether or not Bram coaches it (that's how it can't be lost).
const CORIN_SCRIPT := [
	[{"type": "call", "card": "cinderpup", "slot": "mirror"}],
	[{"type": "attack", "attacker": "cinderpup", "move": 1, "target": "brookfin", "roll": 12}],
	[{"type": "rite", "card": "firebrand", "target": "brookfin"}],
]

## Corin's barks, each on the moment v3 gives it (DuelScreen.story_bark).
const CORIN_BARK_ON := {
	"rival_first_fate": "Six. Give me a six.",
	"weakness_on_rival": "Water. Course you'd bring water.",
	"rival_ko_own": "Cinderpup! Get up!",
	"my_big_hit": "Lucky. That was lucky.",
	"rival_life_third": "That's... fine. That's fine.",
	"rival_falls": "No. No, no, no.",
}
## Corin's duel rule (v3, "DUEL · The Lantern Duel"), named as the duel starts
## and played by the rules engine (DuelGame story_rules "showboat").
const SHOWBOAT := ["Showboat", "Corin's Cinderpup always attacks the moment it can, whatever's in its way."]


## Who's in Ashford, where they stand and who answers (Master Script v7).
## Where people stand depends on the time of day (AshfordDay.spot: Tam's at
## his mill down the lane until the evening, Corin moves from the Lantern to
## the merchant carts to the mill-race wall, Tilly from her stall to the
## well). During the opening nobody answers; until the Lantern Duel is won,
## only Corin (he calls the player over the moment the crate's down).
static func npcs() -> Array:
	var opening: bool = in_opening()
	var morning: bool = not Game.flag("ash_won_lantern")
	var held := func(id: String) -> bool:
		return opening or (morning and id != "corin")
	# every talk ends with the camera back behind the player (some stage shots)
	var home := [{"scene": "p1_home"}]
	var out := [
		{"id": "bram", "look": "bram", "name": "Bram", "pos": AshfordDay.spot("bram"), "talk": _bram(), "muted": held.call("bram")},
		{"id": "corin", "look": "corin", "name": "Corin", "pos": AshfordDay.spot("corin"),
			"duel_flag": "ash_won_lantern", "duel_needs": "ash_started", "talk": _corin(), "muted": held.call("corin")},
		{"id": "tam", "look": "farmer", "name": "Tam", "pos": AshfordDay.spot("tam"), "talk": _tam(), "muted": held.call("tam")},
		{"id": "tilly", "look": "child", "name": "Tilly", "pos": AshfordDay.spot("tilly"), "talk": _tilly(), "muted": held.call("tilly")},
		{"id": "nell", "look": "elder", "name": "Old Nell", "pos": AshfordP1.BENCH, "talk": _nell(), "muted": held.call("nell")},
		{"id": "ned", "look": "fiddler", "name": "Ned", "pos": AshfordDay.spot("ned"), "talk": _ned(), "muted": held.call("ned")},
		# leaning on the stall fence with a cider, out on the green's east side
		{"id": "hob", "look": "hob", "name": "Hob", "pos": AshfordDay.spot("hob"), "talk": _hob(), "muted": held.call("hob")},
	]
	for n in out:
		n.talk = (n.talk as Array) + home
	return out


# ================================================================ scenery ===

static func build(root: Node3D) -> void:
	var w := root as World
	var v := AshfordVillage.new()
	v.name = "Village"
	# a world built ahead of time (World.prepare) builds the village a piece
	# a frame, and its music waits for the release
	v.spread = w != null and w.ahead
	root.add_child(v)
	if v.spread:
		await v.build_spread()
	root.set_meta("village", v)
	# (12 November) a shower over the green now and then (Weather)
	if w != null:
		var wx := Weather.new().setup(w, v)
		v.add_child(wx)
		root.set_meta("weather", wx)
		# ...and doves on the green by day, which go up when anyone runs at them (Birds)
		var doves := Birds.new().setup(w, v)
		v.add_child(doves)
		root.set_meta("birds", doves)
	# the festival reel: its intro once, then the loop (Music.LOOP_START), and
	# it carries on from where it was when a duel or a scene hands back
	w.music = ["ashford_festival"]
	if not Game.flag("ash_marked") and not w.held and not quiet_start():
		Music.play(w.music, 2.0, true)
	# Bram's stool, Nell's bench, the drum and the Great Lantern's hooks
	AshfordP1.dress(root as World)


static func village(w: Node) -> AshfordVillage:
	return w.get_meta("village") as AshfordVillage


## What's underfoot where the world's own rule (World.surface_at: boards
## indoors, dirt on the paths, grass elsewhere) is wrong: the cellar's flags,
## the smugglers' tunnel's earth, the mill's boards (12 November: footsteps).
static func surface_at(_w: World, at: Vector3) -> String:
	if at.y < World.INDOORS_BELOW:
		if at.distance_to(InnRooms.CELLAR_AT) < 14.0:
			return "stone"
		if at.x > AshfordNight.TUNNEL_AT.x - 14.0:
			return "dirt"
		return "wood"
	if at.distance_to(MillSet.AT) < 60.0:
		return "wood"
	# (a puddle a shower has left, with water enough in it: Weather)
	var wx := Weather.of(_w)
	if wx != null and wx.in_puddle(at):
		return "water"
	return ""


## A foot down in a puddle sends up a splash (World.stepped_at).
static func stepped_at(w: World, at: Vector3, surface: String) -> void:
	if surface == "water":
		var wx := Weather.of(w)
		if wx != null and wx.in_puddle(at):
			wx.splash(at)


## What Ashford sounds like where the camera is looking (12 November:
## World.ambience, for Ambience): the hearth in either taproom, a drip in
## the cellar and the tunnel, the race at the mill; out of doors a house on
## fire before anything, then the hour: birds and people by day, the first
## crickets as the sun goes, the whole village talking on the festival
## night, crickets and an owl on the dark night after, and nothing at all
## on the morning the fires are out. By day a shower changes the green's
## birds for rain (Weather); the attic has the wind under its eaves.
static func ambience_at(w: World, at: Vector3) -> String:
	if at.y < World.INDOORS_BELOW:
		var flat := func(c: Vector3) -> float: return Vector2(at.x - c.x, at.z - c.z).length()
		# (a shower that's falling outside is heard on the roof from the
		# taproom and the attic; the cellar is too far under the ground)
		var wet := Weather.of(w) != null and Weather.of(w).raining()
		if flat.call(InnRooms.TAPROOM_AT) < 13.0 or flat.call(InnRooms.EVE_AT) < 13.0:
			return "amb_fire_rain" if wet else "amb_fire"
		if flat.call(InnRooms.CELLAR_AT) < 13.0 or at.x > AshfordNight.TUNNEL_AT.x - 13.0:
			return "amb_cellar"
		return "amb_attic_rain" if wet else "amb_attic"   # (the wind under its eaves)
	if at.distance_to(MillSet.AT) < 80.0:
		return "amb_river"
	var v := village(w)
	if v == null:
		return ""
	for h: Dictionary in v.houses:
		if h.get("burning", false):
			return "amb_burning"
	if v.daylight > 0.6:
		var wx := Weather.of(w)
		return "amb_rain" if wx != null and wx.raining() else "amb_green_day"
	if v.daylight > 0.12:
		return "amb_dusk"
	match v.time_kind:
		"festival":
			return "amb_festival"
		"dawn":
			return ""
	return "amb_night"


# ================================================================== story ===

## P1 opens in the attic (intro(), AshfordP1.opening): nothing more to say
## on arrival.
static func arrival() -> Array:
	return []


## Master Script v7: Bram. The afternoon: where to go next (he sends the
## player to whoever's still to see). The evening: "Bram, by the Great
## Lantern", whose last question starts midnight (once Corin's been found on
## the mill-race wall: until then Bram sends the player to him).
static func _bram() -> Array:
	return [
		{"if": "ash_evening", "then": _bram_evening(), "else": [
			{"if": "!ash_tam", "then": [
				{"who": "bram", "say": "Tam's at the mill, Sprout. Down the lane past the last cottage, where the sign is. He won't ask, so you'll have to."},
			], "else": [
				{"if": "!ash_tilly", "then": [
					{"who": "bram", "say": "Tilly's been sat by the well with a face like a wet week. Go and see what's wrong."},
				], "else": [
					{"if": "!ash_nell", "then": [
						{"who": "bram", "say": "Nell's on her bench by the well. Sit with her a minute. She'll not ask twice."},
					], "else": [
						# the afternoon's jobs done: the sun goes down
						{"who": "bram", "say": "That's the jobs done, then. Look at that sky. Last sunset of the Age."},
						{"scene": "sunset"},
					]},
				]},
			]},
		]},
	]


static func _bram_evening() -> Array:
	return [
		# (2 November: Bram's own music while you talk, Gary's bram_theme when
		# it's in; nothing changes until then)
		{"theme": ["bram_theme"]},
		{"if": "bram_lantern", "then": [], "else": [
			{"set": "bram_lantern"},
			{"who": "bram", "say": "Look at them."},
			{"scene": "beat_bram"},
			{"who": "bram", "say": "Every roof on this green is written down in Morne's book, and not one soul here is thinking about it tonight."},
			{"who": "bram", "say": "That's what a festival's for. One night a year when nobody owes anybody anything."},
		]},
		# (8 November, Gary: "You can miss talk with Corin by talking to Bram
		# first in the evening. I don't want that to be possible: if you talk
		# to Bram first have him say Corin was looking for you over by the
		# mill." Until Corin's evening on the race wall is done, Bram sends
		# the player to him and midnight waits; after it, his hub as before.)
		{"if": "corin_pond", "then": [
			{"ask": ["Are you all right?", "Why do you keep looking at the sky?", "It's nearly midnight."], "ends": [2],
				"leave": "I'll have a last look round.", "then": [
				[{"who": "bram", "say": "I'm old, Sprout. Old men go quiet at parties. It's not a mood. It's a hobby."}],
				[
					{"who": "bram", "say": "Habit."},
					{"scene": "bram_stars"},
					{"who": "bram", "say": "The Shards had a bad night two weeks back. I like to know where the weather is."},
				],
				[
					{"who": "bram", "say": "So it is. Go on, then. Winner lights the Lantern. Make it a good one."},
					{"set": "ash_lantern_duel"},
					{"scene": "midnight"},
				],
			]},
		], "else": [
			{"if": "bram_sent_corin", "then": [
				{"who": "bram", "say": "He's still down at the mill race, Sprout. Go on. Midnight'll keep."},
			], "else": [
				{"set": "bram_sent_corin"},
				{"who": "bram", "say": "Corin came looking for you while they were lighting the lanterns. Wouldn't say what for. He's gone off down by the mill, sat on the race wall on his own."},
				{"who": "bram", "say": "Go and find him, Sprout. He's leaving soon enough, and he's too proud to come looking twice."},
			]},
			{"objective": AshfordDay.EVENING_CORIN},
		]},
		{"if": "ash_lantern_duel", "then": [], "else": [{"theme": "back"}]},
	]


## Master Script v7, Tam Hayes. The afternoon at his mill (his hub: the
## letter, the harvest, a friendly game, and the promise not to tell Nell);
## after that, another game whenever the player comes back. The evening
## behind the bread stall: the first loaf, and Nell's message.
static func _tam() -> Array:
	return [
		{"if": "ash_evening", "then": _tam_evening(), "else": [
			{"if": "ash_tam", "then": [
				{"who": "tam", "say": "Back again? She's still keen if you are."},
				{"choice": ["Deal me in.", "Later, Tam."], "then": [_tam_game(), []]},
			], "else": _tam_mill()},
		]},
	]


static func _tam_mill() -> Array:
	return [
		# (2 November: Tam's own music at the mill, Gary's tam_mill when it's in)
		{"theme": ["tam_mill"]},
		{"who": "tam", "say": "Ah, Sprout. Mind the flour dust on your boots. The draft's blowing hard through the timber seams today."},
		{"who": "tam", "say": "I was just... checking the alignment on the lower stone. Making sure we get a fine grind for the festival loaves before the sun drops."},
		{"ask": ["Is that a notice from Ironvault, Tam?", "How is the harvest coming along this year?", "Bram says you're always up for a game."],
			"follow": {0: ["Why haven't you asked Nell to help you read this?", [
				{"who": "tam", "say": "Nell's carried enough weight in this valley since the night the sky tore open twenty years back."},
				{"who": "tam", "say": "If she knows the mill is gone at midnight, she won't dance on the green tonight. I just want her to have one warm evening before the bailiffs come."},
			]]},
			"leave": "I won't say a word to Nell until the festival ends.", "then": [
			[
				{"set": "tam_letter_seen"},
				{"who": "tam", "say": "Aye. Handed it to me without a word. You know how it is for me with the ink, Sprout."},
				{"scene": "tam_letter_out"},
				{"who": "tam", "say": "Can you... tell me what the House has written down under my name?"},
				# the letter on screen, to read (a tap puts it down)
				{"scene": "tam_letter_read"},
				{"who": "player", "say": "It's a demand of foreclosure, Tam. It says the advance for the seed-barley falls due at midnight tonight."},
				{"who": "player", "say": "If four hundred crowns aren't paid in full, the millwheel and water rights revert to Ironvault."},
				{"scene": "letter_back"},
				{"who": "tam", "say": "Four hundred crowns? I took seventy crowns to buy seed."},
				{"who": "tam", "say": "How in the Seven Courts does seventy crowns turn into four hundred in three winters?"},
				{"scene": "tam_folds"},
				{"set": "tam_told"},
			],
			[
				{"who": "tam", "say": "The stream's been running cold and dark ever since the Sigilfall up in the Shardlands two weeks back."},
				{"who": "tam", "say": "Waterwheel grinds slow when the river magic goes sour."},
			],
			[
				# he looks at the letter in his hand, then folds it away
				{"scene": "tam_deck_out"},
				{"who": "tam", "say": "Aye. Go on, then. Take my mind off it."},
				{"who": "tam", "say": "Mind my River Hound. She bites the hand that calls her, some mornings."},
				{"choice": ["Deal me in.", "Later, Tam."], "then": [_tam_game(), []]},
			],
		]},
		{"who": "tam", "say": "Thank you, Sprout. You're a good lad."},
		{"who": "tam", "say": "Go on back up to the green. I hear you put Corin on his backside. He'll be telling everyone it was the wind."},
		{"set": "ash_tam"},
		{"theme": "back"},
		{"if": "tam_letter_seen", "then": [
			{"say": "[i](Tam's letter has gone into Morrowen's Ledger, with every account you open from now on. Open the menu and choose Ledger.)[/i]"},
		]},
	]


## Tam's friendly game (v7, Gary 24 October): his River Hound, so the player
## knows her before the night she fights for his life. No experience, no
## card; it can be lost, and played again.
static func _tam_game() -> Array:
	return [
		{"duel": {"v1": true, "id": "tam_friendly", "name": "Tam"},
			"win": [{"set": "beat_tam"}, {"who": "tam", "say": "Ha! Bram's been teaching you more than sums down there."},
				{"if": "told_loyal_hound", "then": [], "else": [
					{"set": "told_loyal_hound"},
					{"say": "[i](You've learned Tam's duel skill, Loyal Hound: the first time one of your Totems would be knocked out, it holds on. You'll choose which skill to take into a duel in the menu, under Deck, once you have a deck of your own to build: the Deck page opens the night after the festival.)[/i]"},
				]},
				{"if": "told_chain", "then": [], "else": [{"if": "learned:chain", "then": [
					{"set": "told_chain"},
					{"say": "[i](You've learned about chains: the third card you play in a turn costs 1 less, and a Combo card does more as the third card or later. It's in How to Duel, in the menu.)[/i]"},
				], "else": []}]}],
			"lose": [{"who": "tam", "say": "Forty years of mornings with that hound, Sprout. You'll get there."}]},
	]


static func _tam_evening() -> Array:
	return [
		{"if": "tam_dances", "then": [
			{"who": "tam", "say": "Not now, Sprout. I'm concentrating."},
		], "else": [
			{"if": "tam_bread", "then": [], "else": [
				{"set": "tam_bread"},
				{"scene": "tam_bread"},
				{"who": "tam", "say": "Here. First loaf off the stone. Don't tell Maudie, she thinks it's hers."},
				{"who": "tam", "say": "I used to carry you round this green on my shoulders, festival nights. You'd pull my ears to steer. Left for the cider, right for the cakes."},
				{"who": "tam", "say": "Bram never let me take you near the fiddler. Said you'd get ideas."},
			]},
			{"if": "nell_waiting", "then": [
				{"ask": ["About the letter, Tam...", "Nell says she's waiting, and she's no intention of waiting long."], "ends": [1],
					"leave": "Thanks for the bread.", "then": [
					_tam_letter_no(),
					[
						{"who": "tam", "say": "She said that?"},
						# he wipes his hands on his apron, twice
						{"scene": "tam_deck_out"},
						{"who": "tam", "say": "Hold the stall."},
						{"scene": "tam_to_nell"},
					],
				]},
			], "else": [
				{"ask": ["About the letter, Tam..."], "leave": "Thanks for the bread.", "then": [_tam_letter_no()]},
			]},
			{"if": "!tam_dances", "then": [
				{"who": "tam", "say": "Go on. Enjoy it. Nights like this are what the rest of the year's for."},
			]},
		]},
	]


static func _tam_letter_no() -> Array:
	return [
		{"who": "tam", "say": "Not tonight. You promised."},
		{"scene": "beat_tam"},
		{"who": "tam", "say": "Look at her. Not tonight."},
	]


## Master Script v7, Nell by the well: her hub (the bank's letter she knows
## about, the night Bram came, and her friendly game: a deck built on Wards).
## The evening: she sends the player to fetch Tam for a dance.
static func _nell() -> Array:
	return [
		{"if": "ash_evening", "then": [
			{"if": "tam_dances", "then": [
				{"who": "nell", "say": "Hush. He's nearly in time."},
			], "else": [
				{"who": "nell", "say": "Forty years I've watched that man pretend he can't dance. Go and tell him I'm waiting, and that I've no intention of waiting long."},
				{"set": "nell_waiting"},
			]},
		], "else": [
			{"if": "ash_nell", "then": [
				{"who": "nell", "say": "Bench is still here. So am I."},
				{"choice": ["Deal me in.", "Later, Nell."], "then": [_nell_game(), []]},
			], "else": [
				# (2 November: Nell's own music, Gary's nell_waltz when it's in)
				{"theme": ["nell_waltz"]},
				{"scene": "nell_face"},
				{"ask": ["Are you waiting for the lantern lighting, Nell?", "Bram says not to underestimate you."],
					"follow": {0: ["How long have you and Tam lived in Ashford?", [
						{"who": "nell", "say": "Long enough to remember the night Bram walked out of the Shardlands with you tucked inside his coat."},
						{"who": "nell", "say": "The sky was burning white, and he paid for the inn with gold that smelled of ash. I've never asked him where he found you."},
					]]},
					"leave": "Step away from the well.", "then": [
					[
						{"who": "nell", "say": "I'm waiting for Tam to come up from the mill. He thinks I don't know about the bank's letter."},
						{"who": "nell", "say": "A man's pride is a heavy thing to carry on festival night."},
					],
					[
						{"who": "nell", "say": "My knees gave up dancing years ago. My hands never did."},
						{"scene": "nell_pats"},
						{"who": "nell", "say": "Sit down, love. Let's see what that old fox has been teaching you in his cellar."},
						{"choice": ["Deal me in.", "Later, Nell."], "then": [_nell_game(), []]},
					],
				]},
				{"set": "ash_nell"},
				{"theme": "back"},
			]},
		]},
	]


## Nell's friendly game, sat beside her on the bench: Wards, face down till
## they bite. No experience, no card; it can be lost, and played again.
static func _nell_game() -> Array:
	return [
		{"scene": "nell_sit"},
		{"duel": {"v1": true, "id": "nell_friendly", "name": "Old Nell"},
			"win": [{"set": "beat_nell"}, {"who": "nell", "say": "Hm. Tam owes me a ribbon. I told him you would."},
				{"if": "told_old_wards", "then": [], "else": [
					{"set": "told_old_wards"},
					{"say": "[i](You've learned Nell's duel skill, Old Wards: your first Ward costs no Essence. You'll choose which skill to take into a duel in the menu, under Deck, once that page opens, the night after the festival.)[/i]"},
				]},
				{"if": "told_ground", "then": [], "else": [{"if": "learned:ground", "then": [
					{"set": "told_ground"},
					{"say": "[i](You've learned about the gods' grace: every card answers to a god. On its god's ground, or when that god is Pleased with you, it's Graced; on its rival's, or when it's Displeased with you, Shunned. It's in How to Duel, in the menu.)[/i]"},
				], "else": []}]}],
			"lose": [{"who": "nell", "say": "There. Now you know what a long life's for."}]},
		{"scene": "nell_stand"},
	]


## Master Script v7, Tilly by the well (the afternoon: her moth wakes for the
## player and circles her head), and her thanks in the evening (she gives it
## to them: NEW SIGIL).
static func _tilly() -> Array:
	return [
		{"if": "ash_evening", "then": [
			{"if": "tilly_thanks", "then": [
				{"who": "tilly", "say": "Every day. You promised."},
			], "else": [
				{"set": "tilly_thanks"},
				# (2 November: Tilly's own music, Gary's tilly_moth when it's in)
				{"theme": ["tilly_moth"]},
				# she comes at a run, the moth card held up in both hands; it's grey again
				{"scene": "tilly_gift"},
				# (1 November, Gary: "it flew! I told everyone" needed rewriting)
				{"who": "tilly", "say": "It flew for you this afternoon! I told everyone, and nobody believed me."},
				{"who": "tilly", "say": "So I tried and tried to make it fly again, and it wouldn't. Not even a flutter."},
				{"who": "tilly", "say": "Father says a Spark goes grey for good if it's kept away from the one it likes. So."},
				# she holds the card out, arms straight, not looking at it
				{"who": "tilly", "say": "You keep it. I'll come and visit it.", "during": "tilly_hands_over", "at": "You keep it"},
				{"scene": "tilly_card"},
				{"choice": ["I'll look after it.", "Are you sure, Tilly?"], "then": [
					[{"who": "tilly", "say": "Every day. You promised. Everyone heard."}],
					[{"who": "tilly", "say": "No. Take it quick before I'm sure."}],
				]},
				{"theme": "back"},
			]},
		], "else": [
			{"if": "ash_tilly", "then": [
				{"who": "tilly", "say": "It's gone grey again. It always goes grey again."},
			], "else": [
				{"theme": ["tilly_moth"]},
				{"scene": "tilly_face"},
				{"ask": ["Is your moth card not working, Tilly?"], "then": [[
					{"who": "tilly", "say": "It won't wake up. Father bought it from a merchant last winter, but the wings just stay flat."},
					{"who": "tilly", "say": "Even Tam couldn't summon it, and he calls down a River Hound every morning!"},
					{"scene": "moth_for_tilly"},
					{"who": "tilly", "say": "It flew! Why does it only fly for you?"},
					# (1 November, Gary: a thought, not speech: in brackets and
					# italics; "You don't know. Anyone in Ashford..." read as
					# "you don't know anyone in Ashford")
					{"who": "player", "say": "[i](You don't know why. Anyone in Ashford can wake a common Spark, but the magic in this valley has always leaned towards you, without you ever asking.)[/i]"},
					{"who": "player", "say": "[i](A quiet, frightening habit, and one you learned to hide a long time ago.)[/i]"},
					{"standing": {"tilly": 1}, "why": "You woke her Lantern Moth."},
					# (the game's own note says "Tilly will remember that"; the gods
					# aren't mentioned here any more: they mean nothing to the
					# player yet, and Nell's game teaches that the gods keep
					# score too)
					{"say": "[i](What people think of you is kept in the menu, under Standing.)[/i]"},
					{"set": "ash_tilly"},
				]]},
				{"theme": "back"},
			]},
		]},
	]


## Ned the fiddler.
static func _ned() -> Array:
	return [
		{"who": "ned", "say": "This reel's as old as the Age, they say. Somebody stood on this green and played it the last time the sky changed hands."},
		{"who": "ned", "say": "I do wonder how his night went."},
	]


## Hob (background, v7): on the stall fence with a cider, three dirt-crusted
## Spark cards fanned in one big hand.
static func _hob() -> Array:
	return [
		{"who": "hob", "say": "Barley's in. Roof's patched. If the Age wants to end, it can end tonight."},
		{"who": "hob", "say": "Ploughed these three up with the cabbages. Can't think why."},
	]


## Master Script v7, "The Lantern Pole (Corin & Bram)": Corin calls the
## player over the moment the crate's down; as he does, Bram gets up off his
## stool with a worn card box in his hand and heads over. Corin's hub (his
## letter, and what a Notary does; walking away from Ashford); then "I would,
## but I don't have a deck", Bram's hand on the player's shoulder, his offer
## to talk them through it, the deck, and the Lantern Duel. Afterwards he's
## by the merchant carts; in the evening, on the mill-race wall.
static func _corin() -> Array:
	return [
		{"if": "ash_evening", "then": _corin_evening(), "else": [
			{"if": "ash_won_lantern", "then": [
				{"who": "corin", "say": "Signed cards, a copper each. For you, two. You know why."},
			], "else": [
				{"if": "first_deck", "then": [
					# (back after leaving the duel part-way)
					{"who": "corin", "say": "Deck in hand and everything. Come on, before you think better of it."},
				] + _the_duel(), "else": _corin_morning()},
			]},
		]},
	]


static func _corin_morning() -> Array:
	return [
		{"set": "corin_met"},
		# he comes over twirling a brass-bound card between his knuckles
		{"scene": "corin_calls"},
		{"who": "corin", "say": "Well, look who finally came down! I was starting to think Bram locked you in the attic so you wouldn't embarrass yourself in front of everyone during the Lantern Duel.",
			"during": "bram_sets_off"},
		{"ask": ["What's that letter tucked into your coat?", "You really think you can just walk away from Ashford tonight?"],
			"follow": {0: ["What exactly does an Ironvault Notary do?", [
				{"who": "corin", "say": "They calculate the interest on the world, Sprout. They sit in warm rooms while the rest of Veyl freezes, deciding whose fields get watered and whose roofs get taken."},
				{"who": "corin", "say": "It's better to hold the pen than the plough."},
			]]},
			# (8 November, Gary: "Let's settle the Lantern Duel" from the
			# player, who knows he has no cards, made no sense before "I
			# would, but I don't have a deck." Now the player only asks, and
			# it's Corin who throws down the challenge.)
			"leave": "You were serious about the Lantern Duel?", "then": [
			[
				{"set": "corin_letter"},
				{"who": "corin", "say": "My ticket out of this mud-hole! A clerkship offer from the Ironvault Notary Guild."},
				{"scene": "corin_glances"},
				{"who": "corin", "say": "I put your name down for an apprenticeship too."},
			],
			[
				{"who": "corin", "say": "The Turning year starts at midnight. Every Seat in Veyl is up for grabs! I'm not staying in a village dying on credit."},
			],
		]},
		# (said whether or not they asked: the questions can run out first)
		{"who": "corin", "say": "Last Lantern Night before I'm off to the city, and I'm not going out on a win over Hob and his cabbage-patch Sparks. You and me, in front of the whole green. Deck out, Sprout."},
		{"who": "player", "say": "I would, but I don't have a deck."},
		# a heavy hand lands on the player's shoulder: Bram, pulling a worn
		# leather deck-box from his coat
		{"scene": "bram_comes"},
		# (25 October, Gary: "You do now." on its own; then he hands the box
		# over, the player reaches out and takes it, and the next line starts
		# "You've seen enough duels"; and a line of Gary's as he gives it)
		{"theme": ["bram_theme"]},
		{"who": "bram", "say": "You do now."},
		{"scene": "box_out"},
		{"who": "bram", "say": "I've always told you, when you were ready, I'd let you start using cards. I suppose the end of an Age is as good a time as any. So let's start you with this lot."},
		# the player takes it: YOUR FIRST DECK
		{"scene": "first_deck"},
		# (2 November, Gary: no coaching offer; "all the years I've been
		# teaching you about duels, you know how to do them, just remember
		# what I taught you", and what he taught comes back in the duel
		# itself as memories of him, DuelTutor)
		{"who": "bram", "say": "All the years I've been teaching you about duels, Sprout: you know how to do them. You've sat at my elbow through more of them than Corin's had hot dinners."},
		{"who": "bram", "say": "Just remember what I taught you. It'll come back to you when you need it."},
		{"say": "[i](Whenever a duel shows you something new, what Bram taught you about it over the years comes back to you. Everything you remember is kept in the menu, under How to Duel.)[/i]"},
	] + _the_duel()


## The Lantern Duel itself (v7: the tutorial; Corin's rule is Showboat). It
## can't be lost; leaving it part-way is the only way not to win, and then
## Morrowen takes the story back and it's played again.
static func _the_duel() -> Array:
	return [
		{"duel": {"v1": true, "id": "corin_lantern", "name": "Corin", "difficulty": 0.25},
			"win": _after_the_duel(),
			"lose": [
				{"who": "morrowen", "say": "No. That isn't how it went.", "vo": "morrowen_loss_01"},   # (recorded already, for the lost duels)
				{"goto_duel": "_the_duel"},
			]},
	]


## After the Lantern Duel (v7): Corin yields and goes off to the merchant
## carts; Bram's lines (Gary's, 24 October); the How to Duel tab; the
## afternoon's objectives.
static func _after_the_duel() -> Array:
	return [
		{"set": "ash_won_lantern"},
		{"scene": "box_away"},
		{"scene": "after_lantern"},
		{"who": "corin", "say": "Alright, I yield! You win this year, Sprout. I'll be over by the merchant carts if anyone wants a signed card before I leave for the city!"},
		{"scene": "corin_off"},
		{"scene": "bram_pleased"},
		{"who": "bram", "say": "Not bad, Sprout. You've remembered more of what I taught you than I expected."},
		{"who": "bram", "say": "Now you've got a deck in your hands, you might find a few folk around the village willing to give you a friendly game."},
		{"who": "bram", "say": "Tam's always up for a duel when the mill isn't keeping him busy. And don't underestimate old Nell. She's been playing cards since before I knew which end of a deck to hold."},
		# 29 October (Gary: "It's not clear for players how to get to Tam's
		# mill"): where the mill is, in Bram's words
		{"who": "bram", "say": "Tam'll be down at the mill this time of day. Take the lane by the signpost, off the east side of the green, and on through the field gate. You can't miss the wheel."},
		{"scene": "bram_smile"},
		{"who": "bram", "say": "Go on, get some practice in. No harm in learning a few tricks before tonight's festivities."},
		{"say": "[i](Everything you remembered of Bram's teaching is kept in the menu, under How to Duel.)[/i]"},
		# duel skills (27 October): the first the player hears of them
		{"if": "told_skills", "then": [], "else": [
			{"set": "told_skills"},
			{"say": "[i](Duel skills: every duellist has one, shown on their plate. It works once a duel, by itself. Yours is Second Wind, and you learn others by beating people at cards: Corin's Showman is yours now. The menu's Deck page, where you choose your skill, opens once you have a deck of your own to build, the night after the festival. Until then you duel with Second Wind.)[/i]"},
		]},
		{"scene": "afternoon"},
	]


## Corin at the millpond (v7, Gary's note "Corin's betrayal must be
## heartbreaking"): away from the noise, on the mill-race wall, his new coat
## off and folded beside him. His hub; then his button.
static func _corin_evening() -> Array:
	return [
		{"if": "corin_pond", "then": [
			{"who": "corin", "say": "Go on. Bram'll be looking for you."},
		], "else": [
			{"set": "corin_pond"},
			{"who": "corin", "say": "Don't. I'm not sulking. I'm resting my pride."},
			{"who": "corin", "say": "You know the worst bit? You didn't even look surprised when you won."},
			{"ask": ["You were showing off for the crowd.", "Why Ironvault, Corin? Really.", "Remember the millpond?"], "leave": "I should find Bram.", "then": [
				[{"who": "corin", "say": "I was showing off for the crowd [i]beautifully[/i]. There's a difference. You'll understand when you're famous."}],
				[
					# the card stops
					{"scene": "beat"},
					{"who": "corin", "say": "Mam's note falls due in the spring. Two years clerking for the House and they write it off."},
					{"who": "corin", "say": "That's the clerkship, Sprout. Not the warm rooms."},
					{"who": "corin", "say": "Don't tell her. She thinks I want to go."},
					{"set": "corin_truth"},
				],
				[
					{"who": "corin", "say": "We were eight. I went through the ice and you came in after me without even taking your boots off. Bram tanned you for ruining them."},
					{"who": "corin", "say": "Never said thank you. So. There."},
					{"scene": "beat"},
					{"who": "corin", "say": "Don't make it a thing."},
				],
			]},
			{"who": "corin", "say": "Wait—"},
			{"scene": "corin_button"},
			{"who": "corin", "say": "Here. Best button in Ashford. When I'm rich and horrible in the city, you can sell it and buy a cow."},
			{"say": "[i](Corin's button has gone into your Items. Things people give you are kept in the menu, under Items.)[/i]"},
			{"choice": ["I'll miss you, you know.", "You'll hate the city."], "then": [
				[{"who": "corin", "say": "Course you will. I'm wonderful."}, {"scene": "beat"}, {"who": "corin", "say": "...Me too. Shut up."}],
				[{"who": "corin", "say": "I'll hate it in a warm room, with dinner. You'll hate it here, in the cold, with Bram."}],
			]},
		]},
	]


# ================================================================ duels ===

## Tam's deck (twelve Sparks): his River Hound, the only Totem he keeps,
## and the Rites any miller keeps. Dealt in this order, so she's always in
## his opening hand. (27 October, Gary: "is Tam's battle easy enough to win?
## The player only had one Totem and Tam has more than one": his Shellguard
## is gone, so it's one Totem against one, and he plays her well; a new
## player's plain play wins about four games in five, tests/friendly_sim.)
const TAM_DECK := [
	"river_hound", "essence_flask", "healing_draught", "essence_flask", "travellers_pack", "essence_flask",
	"healing_draught", "bulwark", "essence_flask", "healing_draught", "travellers_pack", "essence_flask",
]
## Nell's: one patient Totem and three Wards, face down till they bite
## (until 27 October two Totems and four Wards, against the player's one
## Totem: a new player never won; then about half the time, decided by who
## ran out of cards first). Since 1 November (Gary: "Nell seems unbeatable as
## getting hurt 30 each turn") her game is a gentle one (FRIENDLY "gentle",
## DuelGame.friendly): no Life lost to an empty deck until both are empty,
## then 10 a turn each; no Guard two turns running; and she starts on 50
## Life to the player's 60. A new player's plain play wins about 4 in 5, in
## about 15 turns (tests/friendly_sim).
const NELL_DECK := [
	"shellguard", "iron_bastion", "essence_flask", "healing_draught", "essence_flask", "ambush_snare",
	"essence_flask", "healing_draught", "iron_bastion", "travellers_pack", "healing_draught", "essence_flask",
]
## The friendly games (Gary, 24 October): no experience, no card, can be lost,
## and played again as often as the player likes until the sun goes down.
## Each has a duel skill of their own (27 October), which the player learns
## by beating them (DuelSkills.LEARNED_BY), and says more as it goes.
const FRIENDLY := {
	"tam_friendly": {"name": "Tam", "deck": TAM_DECK, "difficulty": 0.75, "skill": "loyal_hound",
		# (28 October: Tam taught the chain and the combo in his own words;
		# since 2 November every new thing in any story duel comes back as a
		# memory of Bram, DuelTutor, so his game teaches as the rest do)
		"bark_on": {
			"my_chain": "There's the rhythm. One, two, three.",
			"rival_first_fate": "Come on, girl. Bite.",
			"rival_ko_own": "Steady, girl. Back you come.",
			"rival_skill": "Told you. She doesn't let go.",
			"my_big_hit": "Ha! Where'd you learn that one?",
			"rival_kos_mine": "Sorry, Sprout. She's quicker than she looks.",
			"my_skill": "Oho. Bram's been teaching you tricks.",
			"my_comeback": "There it is. There's the Ashford in you.",
			"arena_event": "Mind the lanterns, now.",
			"my_lethal": "Go on, then. Finish it.",
			"rival_falls": "Ha! Good. That's good, Sprout.",
		}},
	"nell_friendly": {"name": "Old Nell", "deck": NELL_DECK, "difficulty": 0.3, "skill": "old_wards", "life": 50, "gentle": true,
		# (28 October: Nell said whose ground the green is, in her own words,
		# four lines from 1 November; since 2 November the grounds come back
		# as a memory of Bram the first time a card's played on anyone's
		# ground, DuelScreen._ground_lesson)
		"bark_on": {
			"rival_graced": "Hers, that one. The Lantern Keeper's. She looks after her own on festival night.",
			# Bram isn't at her bench to explain a Ward, so she does
			"rival_ward_springs": "That's a Ward, love. Face down till it bites.",
			"rival_skill": "Old Wards, love. They don't cost what new ones do.",
			"my_big_hit": "Oh, my.",
			"my_skill": "Clever. Who taught you that?",
			"rival_life_third": "Don't fuss. I'm old, not done.",
			"arena_event": "Pretty, aren't they? The lanterns.",
			"rival_comeback": "Not yet, love. I've a little left.",
			"rival_falls": "There. Well played, love.",
		}},
}
const FRIENDLY_LIFE := 60


## The duel spec World hands to Main for the Lantern Duel and the friendly games.
static func duel_spec(spec: Dictionary) -> Dictionary:
	var arena := "ashford" if DuelArt.arena("ashford") != null else "tidegrove"
	var me := Game.player_name
	var id := String(spec.get("id", ""))
	if FRIENDLY.has(id):
		return _friendly_spec(id, me, arena)
	var corin := Lore.new_profile("Corin")
	corin["plate"] = "Ashford"   # (for the name plate: Corin is no Unsworn)
	var out := {
		"decks": [PLAYER_DECK.duplicate(), CORIN_DECK.duplicate()],
		"names": [me, "Corin"],
		"profiles": [Lore.new_profile(me), corin],
		"plates": ["", "Ashford"],
		"ai": [false, true],
		"difficulty": float(spec.get("difficulty", 0.3)),
		"arena": arena,
		"life": LANTERN_LIFE,
		"story": true,
		"rule": SHOWBOAT,
		"story_rules": {"showboat": 1},
		"bark_on": CORIN_BARK_ON,
		"rewards": {"opponent": "village"},
		# v7: no experience until Dask
		"practice": true,
		"practice_line": "The Lantern Duel is the village's game: nothing is won but the Lantern.",
	}
	# dealt in order, the player first, and it can't be lost: a first duel
	# should teach, not punish. Every step is gated (the memories of Bram);
	# Corin plays his script, so he never reaches the player's Life.
	out["stacked"] = [true, true]
	out["first"] = 0
	out["life_floor"] = [1, 0]
	out["totem_floor"] = [1, 0]
	# (2 November: always the lesson, as memories of Bram; until then a
	# player who'd "watched enough duels" got none)
	out["tutorial"] = LESSON
	out["rival_script"] = CORIN_SCRIPT
	return out


## A friendly game with Tam or Nell: the player's own deck (its Totems dealt
## first, so there's one in the opening hand), theirs in its written order.
static func _friendly_spec(id: String, me: String, arena: String) -> Dictionary:
	var f: Dictionary = FRIENDLY[id]
	var mine: Array = PLAYER_DECK.duplicate()
	if not Game.v2.is_empty() and Game.v2.get("deck", []) is Array and not (Game.v2.deck as Array).is_empty():
		mine = (Game.v2.deck as Array).duplicate()
	var totems: Array = []
	var rest: Array = []
	for c in mine:
		if String(DuelCards.CARDS.get(String(c), {}).get("kind", "")) == "totem":
			totems.append(c)
		else:
			rest.append(c)
	rest.shuffle()
	var prof := Lore.new_profile(String(f.name))
	prof["plate"] = "Ashford"
	return {
		"decks": [totems + rest, (f.deck as Array).duplicate()],
		"names": [me, String(f.name)],
		"profiles": [Lore.new_profile(me), prof],
		"plates": ["", "Ashford"],
		"ai": [false, true],
		"difficulty": float(f.difficulty),
		"arena": arena,
		"life": FRIENDLY_LIFE,
		"lives": [FRIENDLY_LIFE, int(f.get("life", FRIENDLY_LIFE))],
		"story": true,
		"stacked": [true, true],
		"rival_skill": String(f.get("skill", "")),
		"bark_on": f.bark_on,
		# (2 November) each new thing taught once, as a memory of Bram, and
		# the game keeps its skills while it does
		"lessons": true,
		"skills_on": true,
		"lesson_group": "Tam's game" if id == "tam_friendly" else "Nell's game",
		"rewards": {"opponent": "village"},
		"practice": true,
		"practice_line": "A friendly game: no experience is won or lost.",
		# (1 November, Gary: "Nell seems unbeatable as getting hurt 30 each
		# turn": Nell's game is played gently, DuelGame.friendly: no Life
		# lost to an empty deck, no Guard two turns running)
		"friendly": bool(f.get("gentle", false)),
	}


# ================================================================ scenes ===

static func scene(name: String, w: World) -> void:
	# the afternoon and the evening (Master Script v7)
	if await AshfordDay.scene(name, w):
		return
	match name:
		"midnight":
			await _midnight(w)   # (it clears the green behind its fade: AshfordP1.undress)
			await _prologue_film(w, "awakening")
		"bram_sets_off":
			await _bram_sets_off(w)
		"bram_goes_back":
			await _bram_goes_back(w)
		"bram_comes":
			await _bram_comes(w)
		"box_out":
			await _box_out_scene(w)
		"first_deck":
			await _first_deck(w)
		"box_away":
			_box_away(w)
		"coach_on":
			Game.set_flag("coach_off", false)
		"tilly_gift":
			await AshfordP1.drum_down(w)
			await _tilly_gift(w)
		"tilly_hands_over":
			await _tilly_hands_over(w)
		"tilly_card":
			await _tilly_card(w)
		"p1_home":
			# the camera back behind the player after a talk that staged its own
			# shots (not at the mill: that visit hands the camera back itself;
			# nor once midnight has begun)
			if w.cine and not Game.flag("ash_lantern_duel") and not AshfordDay.at_mill(w.player.global_position):
				await AshfordP1.home(w, 0.8)
		"home":
			await w.cine_home(1.2)
		_:
			await AshfordP1.scene(name, w)


## Is the opening (attic to top hook) under way, a game closed part-way
## through it? (p1_stage is set from its first moment to "done".)
static func in_opening() -> bool:
	var s := String(Game.flag("p1_stage", ""))
	return s != "" and s != "done" and not Game.flag("ash_started")


## The game starts in the attic with Morrowen's voice over the night sky
## (1 November, Gary: "don't have the Ashford background music going while
## she is talking"): the village's music waits until the dream is over
## (AshfordP1._attic starts it as he wakes).
static func quiet_start() -> bool:
	if Game.flag("arrived_ashford") or Game.flag("ash_started"):
		return false
	var s := String(Game.flag("p1_stage", ""))
	return (s == "" or s == "attic") and AshfordP1.DREAM_SECS > 0.0


## Coming back to a Prologue film part-way through, or into the opening
## (New Game, or a game closed during it): start on black.
static func starts_black() -> bool:
	if not Game.flag("arrived_ashford") and not Game.flag("ash_started"):
		return true   # New Game: black, then the caption
	if in_opening():
		return true
	return Game.flag("ash_lantern_duel") and not Game.flag("pro_tunnel_done")


## Called by World on arrival: the opening, if a game was closed during it;
## the green as the script has it until the Lantern Duel; or a Prologue film
## left part-way (the game was closed during it) picks up at the start of the
## part it was in.
static func resume(w: World) -> void:
	if not Game.flag("ash_lantern_duel"):
		# (8 November, Gary: "I like Corin walking over while you put lantern
		# down but then he disappears and walks over again". On a New Game
		# World plays the opening through intro() and then calls this; the
		# opening has set ash_started by then, so the staging below put Corin
		# back on his morning spot by the drum in the middle of his walk over,
		# and his talk walked him across the green a second time; Bram could
		# be snapped onto his stool by pose() too. The probes came in through
		# a saved game, where this runs before the opening and moves nobody.
		# Straight after the opening, everyone is where it left them.)
		var opened := w.has_meta("p1_opened")
		if not opened:
			AshfordP1.pose(w)
		# the light and everyone's places for the time of day (Master Script v7)
		AshfordDay.stage(w, not opened)
		if in_opening():
			await AshfordP1.opening(w)
		AshfordDay.watch(w)
		return
	if Game.flag("pro_tunnel_done"):
		return
	if not Game.flag("ash_marked"):
		await _midnight(w)
		await _prologue_film(w, "awakening")
		return
	var part := String(Game.flag("pro_part", "awakening"))
	await _prologue_film(w, part)


# ================================================================== intro ===

## The first frame of New Game, set before the screen fades up: black (the
## festival drum carrying over from the movie).
static func intro_frame(w: World) -> void:
	w.cine = true
	Cine.overlay(w).black(true)


## A world built ahead of time (World.prepare, under the title screen):
## the opening's rooms are built and shown to the camera now, so their
## shaders compile here rather than on the attic's first frames.
static func warm(w: World) -> void:
	if Game.flag("arrived_ashford"):
		return
	await AshfordP1.warm(w)


## New Game, after the opening movie: P1 from the attic (AshfordP1.opening).
## (The old flight over Ashford is gone: v3 cuts from the movie's title to
## black and the caption, straight into the attic. The village is seen
## through the attic window and when the player steps out of the inn.)
static func intro(w: World) -> void:
	AshfordP1.pose(w)
	await AshfordP1.opening(w)


# ================================================================ chores ===

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


## A worn leather card box with brass corners: Bram's Spark deck, held in
## both hands (the "L" and "R" nodes on its sides are the hands' targets).
## Gary's model takes its place when it exists (assets/models/ashford/
## card_box.glb, since 27 October: sized by its width, its lid on its hinge).
const CARD_BOX_MODEL := "res://assets/models/ashford/card_box.glb"
## The worn deck box (Bram's, from his Shard days): a small oak case with a
## lid, brass at its corners and a clasp, the old sigil worked into the lid.
## Width, height and depth (m), held upright, lid up.
const CARD_BOX_SIZE := Vector3(0.16, 0.11, 0.095)
## Where it's held: in front of the chest, in the figure's own frame (a
## cut-out's, and the fallback; a 3D figure holds it at its own
## Figure3D.hold_point(), within its arms' reach: _box_hold).
const BOX_HOLD := Vector3(0.0, 1.02, 0.27)
## How far it's held out to be taken: a little forward and up of the hold.
const BOX_OUT := Vector3(0.0, 0.03, 0.05)
## How far back on the player's palms the box sits, from the palms' middles
## towards the wrists (m): the heel of the hand under its back half, the
## fingers curling up in front of it (5 November, Gary: "Players fingers
## still go through box when we see player holding box when Bram hands it
## over": centred on the palm, its front half sat under Player A's curled
## fingers, which came up through it; Figure3D.attach's `ahead`).
const BOX_BACK := 0.045
## Where the box sits on the player's palms (6 November, Gary: "Bram's card
## box now goes through player's arm while he's holding it": set back the
## same 4.5 cm on every hand, its back half hung out over the wrists and the
## forearms came up through it; the four looks' hands aren't one length,
## Player A's palm a good deal shorter than the rest). Now it's worked out
## for each hand (_box_back): its back face a little ahead of the wrist, at
## the heel of the hand (BOX_HEEL), so it rests from the heel to the finger
## roots with nothing of the forearm under it, and the fingers in front of
## it; lifted BOX_RISE over the palm, so it rests on the pads of the hand
## and clear of fingers kept as modelled. (BOX_BACK stays the cut-outs'.)
const BOX_HEEL := 0.012
## The right elbow's hint while that hand's under the box (their own frame,
## from the shoulder's height): lower than the left's, so the forearm runs
## back from the wrist below the box's bottom (6 November: level with the
## hand it came up into the box's back corner on the longer-handed looks).
const BOX_RIGHT_ELBOW := Vector3(-0.46, -0.5, 0.1)
## And while that hand lifts the lid (the note at lid_follow): down beside
## the ribs, under the hand.
const LID_ELBOW := Vector3(-0.36, -0.52, 0.02)
## The way that hand's fingers point over the lid (their own frame, for the
## right hand: across to their left and ahead, as the forearm comes).
const LID_FINGERS := Vector3(0.8, 0.0, 0.6)
const LID_EASE_OFF := 0.028
const LID_SLANT_OVER := 0.012
const BOX_RIGHT_BACK := 0.02
## How much further under the box the right palm's mark sits than the
## left's (m): reaching from its lower elbow the right hand lands a little
## high of its mark, and its palm came 1 to 2 cm up into the box's bottom on
## looks B, C and D (8 November, measured on the skin).
const BOX_RIGHT_UNDER := 0.04
const BOX_RISE := 0.006
## How each look's hands differ under the box (6 November, Gary: "Bram's
## card box now goes through player's arm while he's holding it"), by
## Figure3D's model name: `thumb`, how far across the box sits off the left
## palm so the left thumb is clear of its side (Player A's thumbs are kept as
## he modelled them, standing up off the palm, and came up through the box's
## side and lid); `bottom`, how far over the palm's middle (Figure3D.
## palm_frame's origin, a skin's width off the bones) the box's bottom sits:
## the highest point of the hand's own skin under it, measured on the mesh
## as drawn by tests/box_hold_probe.gd (8 November, Gary: "Left hand still
## goes through box as you're holding it when you open it to reveal cards":
## the palms as modelled are thicker than a skin's width, their heels and
## the mounds of the thumb standing 2 to 3 cm over that middle, so a box set
## BOX_RISE over it sat in the flesh; `sink`, the old way round, is gone);
## `heel`, more room ahead of the wrist. `carry` (9 November): which hand the
## box sits on, "left" unless it says (carry_side); `one_hand`: the other
## hand isn't put under it as it's taken, only to the lid. `tilt` (degrees,
## negative: its front up): the box pitched off the palm, `bottom` then where
## its bottom is over the palm's middle (_box_lift); `level`, where it is
## while the box is still level in the giver's hand (clear of the highest of
## the palm under it), the tip coming as it's brought in. `lid_over` and
## `lid_back`: where the other hand's palm is put to lift the lid, over its
## top (m, else the bottom's and a centimetre) and in from its far edge
## (Player A's left is a claw: its palm is held 13 cm up so the curled
## fingers come down onto the lid, not through it into the box).
## Player A's is his right hand, as modelled, the other to the lid (9
## November, Gary: "Players hand distort really bad when Bram hands you
## box"): his left hand is modelled as a loose claw, its fingers standing
## 10 to 12 cm up off the palm and the thumb lying across it, and the rig
## Tripo3D gave it can't open it cleanly: the finger joints sit 3 to 4 cm
## back in the palm from the knuckles, the palm itself is weighted to the
## thumb's bones and the thumb to the fingers'. Opened flat under the box
## (Figure3D.OPEN_FLAT, 70 and -60 degrees) its skin stretched to 3.7 times
## its length, 132 triangles over 1.6 times, the palm twisted and the
## wristband's charm torn; re-weighted and opened about the true knuckle
## line it still tore where the curled fingers meet the thumb
## (tools/hand_weights.py). His right hand is near flat as modelled (its
## fingers curl 4 cm up at most), so the box sits on that, nothing opened,
## and the left's curled fingers hook the lid up. The right palm is cupped
## (its middle 2.4 cm up, the thumb's ridge 3.2 and the curled fingertips 3.7
## under where the box goes), so a box laid flat on the highest of it stood
## 1 to 3 cm clear of the palm and looked to float: tipped 6 degrees, front
## up, it rests along the thumb's ridge and the curl of the fingers, the
## fingertips up in front of it (tests/box_hold_probe.gd prints the profile).
const BOX_FIT := {"player_a": {"bottom": 0.027, "tilt": -6.0, "level": 0.034, "carry": "right", "one_hand": true, "lid_over": 0.13, "lid_back": 0.06}, "player_b": {"bottom": 0.032, "thumb": 0.05},
	"player_c": {"bottom": 0.025, "thumb": 0.06}, "player_d": {"bottom": 0.022, "thumb": 0.03},
	# (Bram's, holding it out on his palm: where the drawn box's half-height
	# had it, which looked right on 6 November's stills)
	"bram": {"bottom": 0.027}}
## How far off the left palm's middle the box sits towards the right hand
## while both hands are under it (m): its middle between the two hands, so it
## doesn't shift across as it's taken.
const BOX_ASIDE := 0.042
## How far apart the giver and the taker stand when it changes hands (m,
## between their middles): near enough that it's held out within one man's
## reach and taken within the other's (until 28 October Bram stood 1.5 m
## off, held it out at arm's length, and the player's arms stretched for it:
## "the player's hand is deformed when he reached to take it").
const BOX_GIVE_GAP := 0.64
const BOX_LID := 0.024   # the lid's own height, of CARD_BOX_SIZE.y
## Where Bram's apron pocket is, in his own frame (the box comes out of it).
const BOX_POCKET := Vector3(-0.15, 0.95, 0.16)


## The box's own size (m): Gary's model's, as _card_box sized it (width
## CARD_BOX_SIZE.x; its height and depth its own: 6.3 cm tall and 12.4 cm
## deep, where the drawn box is 11 by 9.5), or the drawn box's. 8 November,
## Gary: "Left hand still goes through box as you're holding it when you
## open it to reveal cards": every place the hands were put under and round
## the box went by CARD_BOX_SIZE, so on his model the box hung 2.3 cm over
## the palm and reached 1.4 cm further back over the wrist and further out
## over the fingers than the hands were set for.
static func box_size(box) -> Vector3:
	if box != null and is_instance_valid(box) and (box as Node).has_meta("size"):
		return (box as Node).get_meta("size")
	return CARD_BOX_SIZE


## How far back from the middle of `f`'s carrying palm (carry_side) the box
## sits (m, towards the wrist; negative: ahead of it): its back face BOX_HEEL
## ahead of the wrist (Figure3D.palm_frame's middle is its own distance along
## the hand on each model). `size`: the box's (box_size).
static func _box_back(f, size := CARD_BOX_SIZE) -> float:
	if not (f is Figure3D):
		return BOX_BACK
	var fig := f as Figure3D
	var cs := carry_side(f)
	var fr := fig.palm_frame(cs)
	var wrist := fig.bone_pos("LeftHand" if cs == "left" else "RightHand")
	# (the palm's middle stands a skin's width off the bones: along the hand
	# is the rest of the way)
	var skin := Figure3D.SKIN * 0.6 * fig.stature()
	var along := sqrt(maxf(0.0, fr.origin.distance_squared_to(wrist) - skin * skin))
	return along - size.z * 0.5 - BOX_HEEL - float(_box_fit(f).get("heel", 0.0))


## How far over the carrying palm's middle (Figure3D.palm_frame) the box's
## own middle sits (m): half its height over where its bottom sits
## (_box_bottom), and for a box tipped on the palm (_box_tilt) its bottom
## that much higher or lower where its middle is, `back` behind the palm's.
static func _box_lift(f, size := CARD_BOX_SIZE, back := 0.0, k := 1.0) -> float:
	var t := _box_tilt(f) * k
	return size.y * 0.5 / cos(t) + lerpf(_box_level_bottom(f), _box_bottom(f), k) + tan(-t) * -back


## Where the box's bottom is over the palm while it's still level (BOX_FIT
## `level`, else `bottom`).
static func _box_level_bottom(f) -> float:
	return float(_box_fit(f).get("level", _box_bottom(f)))


## How far the box is pitched on the carrying palm (radians, negative: its
## front up; BOX_FIT `tilt`, degrees), for Figure3D.attach.
static func _box_tilt(f) -> float:
	return deg_to_rad(float(_box_fit(f).get("tilt", 0.0)))


## How far over the palm's middle the box's bottom sits (m): the look's
## `bottom` (BOX_FIT), else BOX_RISE. The right palm, and the palm marks at
## the hand-over, keep the same distance under it, so it doesn't shift when
## the left hand takes it.
static func _box_bottom(f) -> float:
	return float(_box_fit(f).get("bottom", BOX_RISE))


static func _box_fit(f) -> Dictionary:
	return BOX_FIT.get((f as Figure3D)._model_name, {}) if f is Figure3D else {}


## The hand the box sits on ("left" or "right"; BOX_FIT `carry`), and the
## other one (it goes to the lid).
static func carry_side(f) -> String:
	return String(_box_fit(f).get("carry", "left"))


static func other_side(f) -> String:
	return "right" if carry_side(f) == "left" else "left"


## 1 for a box carried on the left hand, -1 on the right: every mark's x
## below is to their left as for the left hand, and a box carried on the
## right is the same hold mirrored.
static func _box_mirror(f) -> float:
	return 1.0 if carry_side(f) == "left" else -1.0


## The other hand stays out from under the box as it's taken (BOX_FIT
## `one_hand`).
static func _box_one_hand(f) -> bool:
	return bool(_box_fit(f).get("one_hand", false))


## How far the box sits off the middle of the carrying palm towards the
## other hand (m): `both` while both hands are under it (or the carrying hand
## comes in beside the giver's), else on the one hand alone.
static func _box_aside(f, both := true) -> float:
	var th := float(_box_fit(f).get("thumb", 0.0))
	return maxf(BOX_ASIDE if both else 0.0, th)


## Where the carrying palm's mark sits under the box as it's taken (the
## grip's frame, the box's bottom middle: x across to their left, z ahead).
static func _box_carry_at(f, back: float) -> Vector3:
	return Vector3(_box_aside(f) * _box_mirror(f), 0.0, back)


## Where the other palm sits under the box's other half (the box's frame):
## as far to the other side of its middle as the carrying palm is, a little
## further back (BOX_RIGHT_BACK).
static func _box_other_at(f, back: float, size := CARD_BOX_SIZE) -> Vector3:
	return Vector3(-minf(_box_aside(f) + 0.005, 0.05) * _box_mirror(f), -size.y * 0.5 - _box_bottom(f) - BOX_RIGHT_UNDER, back - BOX_RIGHT_BACK)


## Where Bram's right hand holds the box out on its palm, in his own frame:
## in front of his right side, a little under the shoulders, two thirds of
## an arm ahead (`out`: further, to be taken).
static func _present_point(f: Figure3D, out := false) -> Vector3:
	return f.hold_point(0.74 if out else 0.6, 0.5) + Vector3(-0.08, 0.0, 0.0)


## The card box: Gary's model when card_box.glb exists, else drawn (27
## October, Gary: the box "still looks not very good when he hands it to
## you": it was a plain brown block with a gold band; now an oak case with a
## lid on hinges that opens when the deck comes out, brass corners and clasp,
## and the sigil on the lid). Its origin is its middle; "L" and "R" are where
## the hands take it, "Lid" the lid's hinge (AshfordP1 opens it).
static func _card_box() -> Node3D:
	var n := Node3D.new()
	var W := CARD_BOX_SIZE.x
	var H := CARD_BOX_SIZE.y
	var D := CARD_BOX_SIZE.z
	if ResourceLoader.exists(CARD_BOX_MODEL):
		# Gary's (27 October): a worn oak box with brass, its lid on a hinge
		# along the back edge ("Hinged_Oak_Lid", its origin on the hinge, -105
		# degrees about its X to open, as he made it to match). Sized by its
		# width to the drawn one's, its middle on the origin; the lid is named
		# "Lid" for open_box_lid, and the Spark deck lies inside
		var inst: Node3D = (load(CARD_BOX_MODEL) as PackedScene).instantiate()
		n.add_child(inst)
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
			var b := _local_to(inst, mi) * mi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		if not first and box.size.x > 0.001:
			inst.scale = Vector3.ONE * (W / box.size.x)
			inst.position = -box.get_center() * inst.scale.x
			# (its own size, for the hands: box_size)
			n.set_meta("size", box.size * inst.scale.x)
		var glid := inst.find_child("*Lid*", true, false) as Node3D
		if glid != null:
			glid.name = "Lid"
			# the deck in it, under the lid: card backs up, the Spark deck's blue
			var backs := StandardMaterial3D.new()
			backs.albedo_color = Color(0.12, 0.16, 0.34)
			backs.roughness = 0.5
			var deck := MeshInstance3D.new()
			deck.name = "Deck"
			var dm := BoxMesh.new()
			var inner_y := glid.position.y   # (the rim, where the lid sits)
			dm.size = Vector3(box.size.x * 0.72, inner_y * 0.62, box.size.z * 0.62)
			deck.mesh = dm
			deck.material_override = backs
			deck.position = Vector3(box.get_center().x, inner_y * 0.62 * 0.5 + inner_y * 0.18, box.get_center().z)
			inst.add_child(deck)
			# the top card's back, the game's own (29 October: the plain blue
			# top caught the sun in the green and read as a white sheet)
			backs.roughness = 0.85
			if ResourceLoader.exists("res://assets/art/card_back.jpg"):
				var top := MeshInstance3D.new()
				top.name = "TopCard"
				var qm := QuadMesh.new()
				# the card lies with its long side along the box
				qm.size = Vector2(minf(dm.size.z, dm.size.x * 0.714), minf(dm.size.x, dm.size.z * 1.4))
				top.mesh = qm
				var cm := StandardMaterial3D.new()
				cm.albedo_texture = load("res://assets/art/card_back.jpg")
				cm.roughness = 0.8
				top.material_override = cm
				top.rotation = Vector3(-PI * 0.5, PI * 0.5, 0)
				top.position = deck.position + Vector3(0, dm.size.y * 0.5 + 0.0004 / maxf(inst.scale.x, 0.0001), 0)
				inst.add_child(top)
	else:
		var grain := NoiseTexture2D.new()
		grain.width = 64
		grain.height = 64
		var nz := FastNoiseLite.new()
		nz.frequency = 0.035
		nz.fractal_octaves = 3
		grain.noise = nz
		var oak := StandardMaterial3D.new()
		oak.albedo_color = Color(0.46, 0.29, 0.16)
		oak.albedo_texture = grain
		oak.uv1_scale = Vector3(0.6, 4.0, 1.0)   # (the grain long, along the box)
		oak.roughness = 0.62
		var oak_dark := oak.duplicate() as StandardMaterial3D
		oak_dark.albedo_color = Color(0.36, 0.22, 0.12)
		var brass := StandardMaterial3D.new()
		brass.albedo_color = Color(0.78, 0.6, 0.28)
		brass.metallic = 0.85
		brass.roughness = 0.32
		var sigil := StandardMaterial3D.new()
		sigil.albedo_color = Color(0.95, 0.78, 0.4)
		sigil.metallic = 0.6
		sigil.roughness = 0.3
		sigil.emission_enabled = true
		sigil.emission = Color(1.0, 0.72, 0.3)
		sigil.emission_energy_multiplier = 0.35
		var part := func(parent: Node3D, size: Vector3, at: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = size
			mi.mesh = bm
			mi.material_override = mat
			mi.position = at
			mi.rotation = rot
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mi)
			return mi
		var body_h := H - BOX_LID
		# the case: four sides and a floor round a dark inside, the deck in it
		var top := -H * 0.5 + body_h
		var t := 0.008   # the oak's thickness
		part.call(n, Vector3(W, t, D), Vector3(0, -H * 0.5 + t * 0.5, 0), oak)
		for sz in [-1.0, 1.0]:
			part.call(n, Vector3(W, body_h, t), Vector3(0, -H * 0.5 + body_h * 0.5, sz * (D - t) * 0.5), oak)
		for sx in [-1.0, 1.0]:
			part.call(n, Vector3(t, body_h, D - t * 2.0), Vector3(sx * (W - t) * 0.5, -H * 0.5 + body_h * 0.5, 0), oak)
		var inside := StandardMaterial3D.new()
		inside.albedo_color = Color(0.12, 0.07, 0.05)
		part.call(n, Vector3(W - t * 2.0, 0.002, D - t * 2.0), Vector3(0, -H * 0.5 + t + 0.001, 0), inside)
		# the deck in it, card backs up (the Spark deck's deep blue)
		var backs := StandardMaterial3D.new()
		backs.albedo_color = Color(0.12, 0.16, 0.34)
		backs.roughness = 0.5
		part.call(n, Vector3(W - t * 2.0 - 0.02, body_h - t - 0.012, D - t * 2.0 - 0.012), Vector3(0, -H * 0.5 + t + (body_h - t - 0.012) * 0.5, 0), backs)
		# brass round the case's rim and up its four corners
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				part.call(n, Vector3(0.007, body_h + 0.002, 0.007), Vector3(sx * (W * 0.5 - 0.002), -H * 0.5 + body_h * 0.5, sz * (D * 0.5 - 0.002)), brass)
		for sz in [-1.0, 1.0]:
			part.call(n, Vector3(W + 0.002, 0.005, 0.004), Vector3(0, top - 0.0025, sz * (D * 0.5 - 0.001)), brass)
		for sx in [-1.0, 1.0]:
			part.call(n, Vector3(0.004, 0.005, D + 0.002), Vector3(sx * (W * 0.5 - 0.001), top - 0.0025, 0), brass)
		# the clasp on its front (the side away from whoever holds it)
		part.call(n, Vector3(0.022, 0.03, 0.005), Vector3(0, -H * 0.5 + body_h - 0.006, D * 0.5 + 0.003), brass)
		# the lid, on hinges along its back edge
		var lid := Node3D.new()
		lid.name = "Lid"
		lid.position = Vector3(0, -H * 0.5 + body_h, -D * 0.5)
		n.add_child(lid)
		part.call(lid, Vector3(W + 0.006, BOX_LID, D + 0.006), Vector3(0, BOX_LID * 0.5, D * 0.5), oak_dark)
		for sz in [-1.0, 1.0]:
			part.call(lid, Vector3(W + 0.008, 0.005, 0.004), Vector3(0, 0.0025, D * 0.5 + sz * (D * 0.5 + 0.002)), brass)
		for sx in [-1.0, 1.0]:
			part.call(lid, Vector3(0.004, 0.005, D + 0.008), Vector3(sx * (W * 0.5 + 0.002), 0.0025, D * 0.5), brass)
		for sx in [-1.0, 1.0]:
			part.call(lid, Vector3(0.022, 0.012, 0.006), Vector3(sx * W * 0.3, 0.004, -0.002), brass)
		# the sigil worked into the lid: a ring, and a four-pointed star in it
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.019
		tm.outer_radius = 0.023
		tm.rings = 24
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = sigil
		ring.scale = Vector3(1, 0.25, 1)
		ring.position = Vector3(0, BOX_LID + 0.0005, D * 0.5)
		lid.add_child(ring)
		for a in [0.0, PI * 0.5]:
			part.call(lid, Vector3(0.036, 0.0015, 0.005), Vector3(0, BOX_LID + 0.0008, D * 0.5), sigil, Vector3(0, a + PI * 0.25, 0))
		part.call(lid, Vector3(0.01, 0.002, 0.01), Vector3(0, BOX_LID + 0.001, D * 0.5), sigil, Vector3(0, PI * 0.25, 0))
	# the hands take it by its sides, a little under halfway up
	for side in [["L", 1.0], ["R", -1.0]]:
		var h := Node3D.new()
		h.name = side[0]
		h.position = Vector3(float(side[1]) * (W * 0.5 + 0.02), -H * 0.1, 0.0)
		n.add_child(h)
	n.set_meta("card_box", true)
	return n


## `node`'s transform in `root`'s space, walking up its parents (before
## either is in the tree).
static func _local_to(root: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


## The way a figure's body faces (its turn about the upright), as carry() turns what it holds.
static func _yaw_of(f: Figure3D) -> float:
	return f._yaw


## Opens (or shuts) the card box's lid on its hinges over `secs`.
static func open_box_lid(w: World, box: Node3D, open := true, secs := 0.45) -> void:
	if box == null or not is_instance_valid(box):
		return
	var lid := box.get_node_or_null("Lid") as Node3D
	if lid == null:
		lid = box.find_child("Lid", true, false) as Node3D   # (Gary's model: inside it)
	if lid == null:
		return
	var tw := w.create_tween()
	tw.tween_property(lid, "rotation:x", deg_to_rad(-105.0) if open else 0.0, secs).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


## The card box in someone's two hands, in front of their chest (it used to
## sit on the lantern-hand point with the fingers through it: Gary, 23
## October, "his arm goes through it"). A cut-out gets it beside them.
static func _hold_box(w: World, who: String, box: Node3D) -> Node3D:
	# one box at a time: the one he's holding already goes (until 25
	# October a second box given to him while he carried one left the first
	# floating at his chest, and he handed over a third: Gary, "it duplicates")
	_clear_boxes(w, who)
	var f = Cine.fig(w, who)
	if f is Figure3D:
		var fig := f as Figure3D
		fig.carry(box, _box_hold(fig))
		fig.reach(box.get_node("L"), box.get_node("R"), 0.35)
		w.set_meta("box_" + who, box)
		return box
	var b := Cine.body(w, who)
	if b != null:
		b.add_child(box)
		box.position = Vector3(0.32, 0.95, 0.15)
		w.set_meta("box_" + who, box)
	return box


## Where someone holds the card box, in their own frame: within their arms'
## reach (Figure3D.hold_point), or BOX_HOLD for a cut-out.
static func _box_hold(f) -> Vector3:
	if f is Figure3D:
		return (f as Figure3D).hold_point()
	return BOX_HOLD


## Holds the box out towards someone (the hands go with it); `back` brings it in.
static func _box_out(w: World, who: String, out := true, secs := 0.5) -> void:
	var box = w.get_meta("box_" + who, null)
	if box == null or not is_instance_valid(box):
		return
	var hand = w.get_meta("box_hand_" + who, null)
	if hand != null and is_instance_valid(hand) and Cine.fig(w, who) is Figure3D:
		# (on his palm: the hand goes out, and the box with it)
		var ht := w.create_tween()
		ht.tween_property(hand, "position", _present_point(Cine.fig(w, who), out), secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await ht.finished
		return
	var tw := w.create_tween()
	tw.tween_property(box, "position", _box_hold(Cine.fig(w, who)) + (BOX_OUT if out else Vector3.ZERO), secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


## Takes the box out of someone's hands (and away).
static func _drop_box(w: World, who: String) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		var fig := f as Figure3D
		fig.detach()
		fig.let_go(0.3)
		fig.palm("left", Vector3.ZERO, 0.3)
		fig.palm("right", Vector3.ZERO, 0.3)
		fig.elbow("left", Vector3.INF, 0.3)
		fig.elbow("right", Vector3.INF, 0.3)
	_free_box_hand(w, who)
	_clear_boxes(w, who)


## The marks a figure's hands were following for the box, gone.
static func _free_box_hand(w: World, who: String) -> void:
	for k in ["box_hand_" + who, "box_grip_" + who]:
		if w.has_meta(k):
			var n = w.get_meta(k)
			if n != null and is_instance_valid(n):
				(n as Node).queue_free()
			w.remove_meta(k)


## Every card box someone carries goes (the one on record, and any left
## behind in their hands by an earlier hand-over).
static func _clear_boxes(w: World, who: String) -> void:
	if w.has_meta("box_" + who):
		var box = w.get_meta("box_" + who)
		if box != null and is_instance_valid(box):
			box.queue_free()
		w.remove_meta("box_" + who)
	var f = Cine.fig(w, who)
	var b := Cine.body(w, who)
	for host in [f, b]:
		if host == null or not is_instance_valid(host):
			continue
		for n in (host as Node).find_children("*", "Node3D", true, false):
			if n.has_meta("card_box") and is_instance_valid(n) and not n.is_queued_for_deletion():
				n.queue_free()


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


## Where Bram ends up: beside the player, on his side of them, facing Corin,
## near enough to put a hand on their shoulder (until 28 October he stood
## 1.5 m off and his arm stretched across the gap).
const BRAM_BESIDE := 0.8


static func _bram_stop(w: World) -> Vector3:
	var p := w.player.global_position
	var c := Cine.body(w, "corin").global_position
	var d := p - c
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.BACK
	var perp := d.cross(Vector3.UP).normalized()
	if perp.dot(Cine.body(w, "bram").global_position - p) < 0.0:
		perp = -perp
	return p + perp * BRAM_BESIDE + d * 0.15


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


## The moment Corin spots the player, Bram gets up off his stool by the
## Lantern, the worn card box in his apron pocket, and heads over at a brisk walk,
## round the Great Lantern, to stand just off the pair, listening. He's there
## to step in when Corin says "no deck".
static func _bram_sets_off(w: World) -> void:
	var bram := Cine.body(w, "bram")
	if bram == null or Cine.body(w, "corin") == null:
		return
	var stop := _bram_stop(w)
	w.set_meta("bram_stop", stop)
	# the Spark deck's twelve cards fan out on screen in a minute: their
	# paintings start loading now, so it opens without a stall
	CardFace.warm_art(PLAYER_DECK + ["lantern_moth"])
	await AshfordP1.bram_stand(w)
	# (the box stays in his apron pocket until "You do now." (29 October):
	# carried over in both hands it hung in front of him, not in them)
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


## "Not yet": Bram goes back to his stool.
static func _bram_goes_back(w: World) -> void:
	if Cine.body(w, "bram") == null or not w.has_meta("bram_stop"):
		return
	w.remove_meta("bram_stop")
	await AshfordP1.bram_to_stool(w)


## Bram steps in beside the player, the card box in his apron pocket (he set off
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
	var look := mid + Vector3(0, 1.2, 0)
	# a cut (a glide here swung half round them, through Corin and the drum)
	Cine.shot(w, AshfordP1.clear_cam(w, [mid + side * 5.6 + d * 2.2 + Vector3(0, 2.4, 0), mid - side * 5.6 + d * 2.2 + Vector3(0, 2.4, 0),
		mid + side * 4.6 + d * 3.2 + Vector3(0, 3.4, 0), mid + d * 5.0 + Vector3(0, 3.2, 0)], look, ["player", "bram", "corin"]), look)
	Cine.look(w, "corin", bram.global_position)
	Cine.look(w, "player", bram.global_position)
	await Cine.path(w, "bram", _round_lantern(w, bram.global_position, stop), BRAM_PACE)
	# beside them, facing Corin as they do, so his near hand finds their
	# near shoulder (28 October: he turned to face them from 1.5 m away and
	# his arm stretched out at nothing; they turn to each other for the box)
	Cine.look(w, "bram", c)
	Cine.look(w, "player", c)
	await Cine.wait(w, 0.15)
	# v7: "A heavy hand lands on the protagonist's shoulder." (the hand
	# nearer them; it comes off when he holds the box out)
	var bf = Cine.fig(w, "bram")
	if bf is Figure3D:
		var sh := _shoulder_point(w, "player", bram.global_position)
		w.set_meta("bram_shoulder", sh)
		var ahead := c - bram.global_position
		ahead.y = 0.0
		var right: Vector3 = ahead.normalized().cross(Vector3.UP)
		_drop_box(w, "bram")
		if right.dot(sh.global_position - bram.global_position) > 0.0:
			(bf as Figure3D).reach(null, sh, 0.35)
		else:
			(bf as Figure3D).reach(sh, null, 0.35)
		await Cine.wait(w, 0.4)


## "You do now.": his hand comes off the player's shoulder, the worn deck
## box comes out of his coat and he holds it out in both hands (25 October,
## Gary: the box is handed over on "You do now", the player takes it, and
## only then does Bram go on). The two-shot it's taken in stays for
## _first_deck.
static func _box_out_scene(w: World) -> void:
	var stop: Vector3 = w.get_meta("bram_stop", Cine.body(w, "bram").global_position)
	var p := w.player.global_position
	var mid := (p + stop) * 0.5
	var d := stop - p
	d.y = 0.0
	var perp := d.normalized().cross(Vector3.UP)
	var look := mid + Vector3(0, 1.15, 0)
	Cine.shot(w, AshfordP1.clear_cam(w, [mid + perp * 2.6 + Vector3(0, 1.55, 0), mid - perp * 2.6 + Vector3(0, 1.55, 0),
		mid + perp * 2.2 + Vector3(0, 2.3, 0), mid - perp * 2.2 + Vector3(0, 2.3, 0)], look, ["player", "bram"]), look, 34.0)
	var f = Cine.fig(w, "bram")
	if w.has_meta("bram_shoulder"):
		_free_tracker(w.get_meta("bram_shoulder"))
		w.remove_meta("bram_shoulder")
		if f is Figure3D:
			(f as Figure3D).let_go(0.25)
		await Cine.wait(w, 0.3)
	# the two turn to each other for it
	var bram_body := Cine.body(w, "bram")
	if bram_body != null:
		Cine.look(w, "bram", w.player.global_position)
		Cine.look(w, "player", bram_body.global_position)
	if AshfordP1.meta(w, "box_bram") == null:
		var bfig = Cine.fig(w, "bram")
		if bfig is Figure3D:
			# out of his apron pocket at his hip on the flat of his right
			# hand, and up and out to the player on it (29 October, Gary: the
			# box "is still not in brams hand is floating between them":
			# it's on his palm now, put there by the hand itself every frame,
			# Figure3D.attach, so it can't be anywhere else; its clasp to him,
			# so it's the right way round in the player's hands)
			var fig := bfig as Figure3D
			_clear_boxes(w, "bram")
			_free_box_hand(w, "bram")
			var box := _card_box()
			w.add_child(box)
			w.set_meta("box_bram", box)
			var hand := Node3D.new()
			hand.name = "BoxHand"
			fig.carry(hand, BOX_POCKET)
			w.set_meta("box_hand_bram", hand)
			# (2 November, Gary: "Bram's fingers go through the box while it's
			# in his hand": the hand was turned palm up with the fingers left
			# curled as his clip has them, up through the box; flat now, the
			# box on the open hand, the fingers out under its far side)
			fig.palm("right", Vector3.UP, 0.3, 1.0)
			fig.reach(null, hand, 0.35)
			box.visible = false
			await Cine.wait(w, 0.35)
			fig.attach(box, "palm", "right", box_size(box).y * 0.5 + _box_bottom(fig), PI)
			await w.get_tree().process_frame
			box.visible = true
			var up := w.create_tween()
			up.tween_property(hand, "position", _present_point(fig), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await up.finished
		else:
			_hold_box(w, "bram", _card_box())
	await _box_out(w, "bram", true, 0.5)
	await Cine.wait(w, 0.2)


## The player reaches out and takes the box from his hands, and it's theirs:
## the Spark deck, its twelve cards fanned out across the screen. (v3 opens
## the Deck and Codex later, when the player chooses a deck at the campfire,
## so they stay shut here.)
static func _first_deck(w: World) -> void:
	var f = Cine.fig(w, "bram")
	if AshfordP1.meta(w, "box_bram") == null:
		# (a game picked up here, or the scene before skipped: out it comes now)
		await _box_out_scene(w)
	var pf = Cine.fig(w, "player")
	var box: Node3D = w.get_meta("box_bram", null)
	if box != null and is_instance_valid(box) and pf is Figure3D:
		var me := pf as Figure3D
		# a step in towards him, so the box he holds out is within their
		# reach, hands coming up as they go
		await _step_to_take(w, "player", "bram")
		# (2 November, Gary: the player's "hands go all deformed when it
		# takes the box then holding the box": they took it by its sides,
		# palms in, and with the hands that close together the forearms
		# pointed in at it and the hands folded back at the wrists. Now it's
		# taken the way anyone takes a small box held out to them: both
		# hands slide in under it, palms up, flat, fingers forward, side by
		# side, and it's lifted off his hand onto them.) The hands' marks
		# hang from a carried frame (BoxGrip): where they go, the box goes.
		# (how far back on the palms the box sits, for these hands: _box_back;
		# the box's own size, box_size: 8 November)
		var size := box_size(box)
		var back := _box_back(me, size)
		# (9 November: which hand carries it, BOX_FIT `carry`; every mark's x
		# goes by `sx`, so a box on the right hand is the same hold mirrored.
		# Player A's is on his right, his left a claw as modelled; that left
		# hand isn't put under it, `one_hand`, and lifts the lid)
		var cs := carry_side(me)
		var os := other_side(me)
		var sx := _box_mirror(me)
		var one := _box_one_hand(me)
		# (both hands' reaches at once, by which carries)
		var both_reach := func(carry_t: Node3D, other_t: Node3D, secs: float) -> void:
			if cs == "left":
				me.reach(carry_t, other_t, secs)
			else:
				me.reach(other_t, carry_t, secs)
		var grip := Node3D.new()
		grip.name = "BoxGrip"
		me.carry(grip, Vector3.ZERO)
		grip.global_position = box.global_position + Vector3(0, -size.y * 0.5 - _box_level_bottom(me), 0)
		grip.rotation = Vector3.ZERO
		for sd in [["L", 1.0], ["R", -1.0]]:
			var mk := Node3D.new()
			mk.name = sd[0]
			# (a hand's half-width in from the middle, each under its half, the
			# palms' middles a little ahead of the box's: it sits back on them,
			# _box_back)
			# ("L" the carrying hand's, "R" the other's, whichever side)
			mk.position = _box_carry_at(me, back) if sd[0] == "L" else _box_other_at(me, back, size) * Vector3(1, 0, 1) + Vector3(0, -BOX_RIGHT_UNDER, 0)
			grip.add_child(mk)
		w.set_meta("box_grip_player", grip)
		me.palm(cs, Vector3.UP, 0.4, 1.0, true, Vector3.BACK)
		if not one:
			me.palm(os, Vector3.UP, 0.4, 1.0, true, Vector3.BACK)
		# the elbows out to the sides and a touch forward, at the ribs, for as
		# long as the box is held (4 November, Gary: "when you take box from
		# Bram arms go into body": with the hands side by side under the box
		# in front of the belly, the elbows' usual hint, out and back, bent
		# them back past the flanks and the forearms ran in through the sides
		# of the body to the hands); _drop_box gives them back
		me.elbow(cs, Vector3(0.46 * sx, me._shoulder - 0.38, 0.14), 0.4)
		if not one:
			me.elbow(os, BOX_RIGHT_ELBOW * Vector3(sx, 1, 1) + Vector3(0, me._shoulder, 0), 0.4)
		# in from below and in front, so the hands don't come through his
		var way_l := Node3D.new()
		var way_r := Node3D.new()
		for way in [way_l, way_r]:
			grip.add_child(way)
		way_l.position = (grip.get_node("L") as Node3D).position + Vector3(0.03 * sx, -0.1, -0.14)
		way_r.position = (grip.get_node("R") as Node3D).position + Vector3(-0.03 * sx, -0.1, -0.14)
		both_reach.call(way_l, null if one else way_r, 0.3)
		var under := w.create_tween().set_parallel(true)
		under.tween_property(way_l, "position", (grip.get_node("L") as Node3D).position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		under.tween_property(way_r, "position", (grip.get_node("R") as Node3D).position, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await under.finished
		both_reach.call(grip.get_node("L"), null if one else grip.get_node("R"), 0.1)
		way_l.queue_free()
		way_r.queue_free()
		await Cine.wait(w, 0.15)
		# and it's theirs: on the flat of their left hand (Figure3D.attach:
		# the hand puts it where the hand is), the right hand under its
		# other half; his hand comes away from under it
		if f is Figure3D:
			(f as Figure3D).detach(box)
			(f as Figure3D).let_go(0.35)
			(f as Figure3D).palm("right", Vector3.ZERO, 0.35)
		_free_box_hand(w, "bram")
		w.remove_meta("box_bram")
		w.set_meta("box_player", box)
		me.attach(box, "palm", cs, _box_lift(me, size, back, 0.0), 0.0, 0.0, -back, -_box_aside(me) * sx)
		# (the right hand under the box's other half, wherever the left palm
		# puts the box: its mark hangs from the box, as far ahead of its
		# middle as the left palm's is)
		var rmark := Node3D.new()
		rmark.name = "RightUnder"
		box.add_child(rmark)
		# (its palm a little further back than the left's, so its wrist is
		# clear behind the box's back edge: the forearm rises steeply from the
		# wrist to the elbow, and from under the box it came up through its
		# back corner on the longer-handed looks, B's and D's, 6 November)
		rmark.position = _box_other_at(me, back, size)
		both_reach.call(grip.get_node("L"), null if one else rmark, 0.1)
		# in to them, a little up: the hands' marks come in, and the box with
		# the left hand
		# (a box carried on one hand comes in a hand's width to that side)
		var hold := me.hold_point(0.5, 0.62) + Vector3((0.0 if not one else 0.06 * sx), -size.y * 0.5 - _box_bottom(me), 0.0)
		var bring := w.create_tween()
		bring.tween_property(grip, "position", hold, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# (and settling to its tip on the hand, BOX_FIT `tilt`, as it comes:
		# Bram held it level)
		if _box_tilt(me) != 0.0:
			var a0 := _box_aside(me)
			bring.parallel().tween_method(func(k: float) -> void:
				me.attach(box, "palm", cs, _box_lift(me, size, back, k), 0.0, 0.0, -back, -a0 * sx, _box_tilt(me) * k), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
		await bring.finished
		# to open it (29 October, Gary: "his hands are in the way when he
		# opens it"): the box stays on the flat of the left hand, the right
		# hand comes out from under it, up over the side and along to the
		# front of the lid, lifting it as it swings up on its hinge, and a
		# close shot from in front and above, looking into it. (1 November,
		# Gary: "players hand goes through it": each hand went to its next
		# place in a straight line, through the box; the right goes out and
		# up round its side.)
		var lh := Node3D.new()
		lh.name = "LeftWay"
		grip.add_child(lh)
		lh.position = (grip.get_node("L") as Node3D).position
		# (the left hand to the box's middle under it, so it's balanced on
		# one hand once the right lets go; the palm's middle a little ahead,
		# _box_back, so the box keeps its place)
		# (the hand slides across under it and the box stays put: Figure3D's
		# `aside`, how far the box sits off the palm, goes as the hand goes;
		# Player A's stays off it, his thumb clear: BOX_FIT)
		var aside0 := _box_aside(me)
		var aside1 := _box_aside(me, false)
		var lh0 := lh.position
		both_reach.call(lh, null if one else rmark, 0.1)
		var half := size.x * 0.5
		var centre_under := w.create_tween()
		centre_under.tween_method(func(k: float) -> void:
			var a := lerpf(aside0, aside1, k)
			lh.position = lh0 + Vector3((a - aside0) * sx, 0.0, 0.0)
			me.attach(box, "palm", cs, _box_lift(me, size, back), 0.0, 0.0, -back, -a * sx, _box_tilt(me)), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		await centre_under.finished
		_into_box_shot(w, box)
		var lid := box.get_node_or_null("Lid") as Node3D
		if lid == null:
			lid = box.find_child("Lid", true, false) as Node3D
		var edge := Node3D.new()
		edge.name = "LidEdge"
		box.add_child(edge)
		# (the hand's own thickness over the lid, as under the box, _box_bottom,
		# and a finger's width more: the fingertips curl over the edge as it
		# swings up)
		# (and LID_SLANT_OVER more since 11 November: with the fingers on the
		# slant the thumb lies back across the lid, under the palm's level)
		var lid_over := float(_box_fit(me).get("lid_over", _box_bottom(me) + 0.01)) + LID_SLANT_OVER
		edge.position = Vector3(0.0, size.y * 0.5 + lid_over, size.z * 0.5 - float(_box_fit(me).get("lid_back", 0.0)))
		if lid != null:
			edge.reparent(lid, true)
		# the right hand up off the box's side, over its top and along to the
		# lid's front edge
		var rh := Node3D.new()
		rh.name = "RightWay"
		w.add_child(rh)
		# (a hand that wasn't under it comes from where it hangs)
		rh.global_position = rmark.global_position if not one else me.palm_frame(os).origin
		both_reach.call(lh, rh, 0.1 if not one else 0.3)
		# (a forearm's width out from the box's side on the way up, so the wrist
		# clears its top edge: 6 November)
		var side_out := box.to_global(Vector3((-half - 0.09) * sx, -size.y * 0.3, 0.0))
		var side_up := box.to_global(Vector3((-half - 0.08) * sx, size.y * 0.5 + maxf(0.1, lid_over), 0.0))
		var over_edge := edge.global_position + Vector3(0, 0.08, 0)
		# (down from under it first, then out, so the fingers don't come up
		# through its bottom edge on the way; and the right elbow up and out
		# while the hand's over the lid, so the forearm comes down to it from
		# above instead of across the box's top: 6 November)
		var under_out := box.to_global(Vector3((-half - 0.02) * sx, -size.y * 0.5 - 0.06, 0.0))
		me.elbow(os, Vector3(-0.44 * sx, me._shoulder - 0.2, 0.1), 0.4)
		# (down off it first, and a touch forward: going down and out at once,
		# the fingers curled up in front of it scraped its front face, 6
		# November)
		var drop := box.to_global(rmark.position + Vector3(0.0, -0.05, 0.015))
		var round_over := w.create_tween()
		if not one:
			round_over.tween_property(rh, "global_position", drop, 0.12).set_trans(Tween.TRANS_SINE)
			round_over.tween_property(rh, "global_position", under_out, 0.1).set_trans(Tween.TRANS_SINE)
		# (and turned palm down to go over the lid only once it's out from
		# under: turned under the box, its fingers swung up into it; flat, so
		# the fingers lie along the lid rather than curl down into it: 8
		# November, Player A's open only when a flat hand's asked for,
		# Figure3D.OPEN_FLAT)
		# (its fingers kept pointing ahead as it turns: left to point along the
		# forearm they pointed in at the box and, Player A's being long,
		# swept through its side on the way up, 8 November)
		round_over.tween_callback(func() -> void: me.palm(os, Vector3.DOWN, 0.25, 1.0, true, Vector3.BACK))
		round_over.tween_property(rh, "global_position", side_out, 0.14 if not one else 0.3).set_trans(Tween.TRANS_SINE)
		round_over.tween_property(rh, "global_position", side_up, 0.18).set_trans(Tween.TRANS_SINE)
		round_over.tween_property(rh, "global_position", over_edge, 0.18).set_trans(Tween.TRANS_SINE)
		# (11 November, Gary: "When player opens box from Bram his hand is
		# twisted in an unnatural way". Over the lid the fingers pointed
		# straight ahead, to its front edge, on the end of a forearm that
		# comes in across the body from an elbow out at the side: the hand
		# turned a right angle sideways at the wrist, and 27 degrees further
		# than a wrist goes as the lid came up. Clear of the box's side and
		# over its top, the fingers come round to lie the way the forearm
		# comes, LID_FINGERS: across the lid's front edge on the slant, the
		# wrist straight.)
		round_over.parallel().tween_method(func(u: float) -> void:
			me.palm(os, Vector3.DOWN, 0.01, 1.0, true, Vector3.BACK.lerp(LID_FINGERS * Vector3(sx, 1, 1), u)), 0.0, 1.0, 0.3).set_trans(Tween.TRANS_SINE)
		round_over.tween_property(rh, "global_position", edge.global_position, 0.12).set_trans(Tween.TRANS_SINE)
		await round_over.finished
		both_reach.call(lh, edge, 0.08)
		rh.queue_free()
		await Cine.wait(w, 0.15)
		# the lid up, and the deck comes out of it: the hand on its edge turns
		# with it, palm to the lid's face and fingers along it to the edge (8
		# November: held palm down as the lid came up past level, the palm
		# lay through the lid)
		# (11 November, Gary: "When player opens box from Bram his hand is
		# twisted in an unnatural way". The elbow stayed up and out, where it
		# had gone to bring the forearm down onto the lid, while the hand
		# followed the lid up past sixty degrees: the hand bent back over a
		# right angle on the end of a forearm still pointing down. An elbow
		# drops as a hand lifts a lid: down beside the ribs, the forearm
		# coming up to the hand, the wrist all but straight.)
		me.elbow(os, LID_ELBOW * Vector3(sx, 1, 1) + Vector3(0, me._shoulder, 0), 0.5)
		# (which way the lid's own x lies against their left)
		var lid_x := 1.0
		if lid != null and is_instance_valid(lid):
			lid_x = 1.0 if lid.global_transform.basis.x.dot(me.to_world(Vector3(1, 0, 0)) - me.to_world(Vector3.ZERO)) >= 0.0 else -1.0
		var lid_follow := w.create_tween()
		# (and the hand eased three centimetres further off the lid's face as it
		# comes up, lying nearer flat to it: the thumb, lying back across the
		# lid now the fingers are on the slant, sank a centimetre into the
		# lid's face at the top of its swing)
		var edge_y := edge.position.y
		lid_follow.tween_method(func(_u: float) -> void:
			if is_instance_valid(edge):
				edge.position.y = edge_y + LID_EASE_OFF * _u
			if lid != null and is_instance_valid(lid) and lid.is_inside_tree():
				# (the hand pitched a little nose-up off the lid's face, so the
				# fingertips ride clear of its edge as it swings: Player A's
				# long fingers hooked a centimetre into it)
				var ly := lid.global_transform.basis.y
				var lz := lid.global_transform.basis.z
				# (the fingers kept on the slant across it, as they came:
				# LID_FINGERS in the lid's own frame, which was theirs when
				# the hand came down on it)
				var lx := lid.global_transform.basis.x
				me.palm(os, (-ly + lz * lerpf(0.4, 0.12, _u)).normalized(), 0.01, 1.0, false, (lx * LID_FINGERS.x * sx * lid_x + lz * LID_FINGERS.z).normalized()), 0.0, 1.0, 0.6)
		await open_box_lid(w, box, true, 0.6)
		var away := Node3D.new()
		away.name = "RightAway"
		w.add_child(away)
		away.global_position = edge.global_position + Vector3(0, 0.12, 0)
		both_reach.call(lh, away, 0.3)
		me.elbow(os, BOX_RIGHT_ELBOW * Vector3(sx, 1, 1) + Vector3(0, me._shoulder, 0), 0.4)
		w.set_meta("box_right_away", away)
		me.palm(os, Vector3.ZERO, 0.35)
		await Cine.wait(w, 0.35)
	else:
		_drop_box(w, "bram")
		box = _hold_box(w, "player", _card_box())
	if f is Figure3D:
		(f as Figure3D).release()
	await Cine.wait(w, 0.6)
	await Cine.reveal(w, PLAYER_DECK, "YOUR FIRST DECK", "Bram's Spark deck · twelve cards")
	_give_first_deck()
	# (1 November, Gary: the box "disappears while text is still going on",
	# and the camera stayed on the close shot of the empty hands through
	# Bram's next lines): the lid shut, the box kept on the flat of the left
	# hand, held at the waist, the right hand down, and back to the two of
	# them. It goes into their pack when the duel starts (_box_away).
	if box != null and is_instance_valid(box):
		await open_box_lid(w, box, false, 0.35)
	if w.has_meta("box_right_away"):
		var ra = w.get_meta("box_right_away")
		if ra != null and is_instance_valid(ra):
			# the right hand out past the box's side and down before it's let
			# go to hang (6 November: let go from over the lid, it dropped
			# straight down through the box's side to the hip)
			if box != null and is_instance_valid(box):
				var by := w.create_tween()
				var bs := box_size(box)
				var bsx := _box_mirror(Cine.fig(w, "player"))
				by.tween_property(ra, "global_position", box.to_global(Vector3((-bs.x * 0.5 - 0.12) * bsx, bs.y * 0.5 + 0.1, 0.0)), 0.2).set_trans(Tween.TRANS_SINE)
				by.tween_property(ra, "global_position", box.to_global(Vector3((-bs.x * 0.5 - 0.12) * bsx, -0.02, -0.05)), 0.2).set_trans(Tween.TRANS_SINE)
				await by.finished
			(ra as Node).queue_free()
		w.remove_meta("box_right_away")
	if pf is Figure3D:
		var me2 := pf as Figure3D
		var gw = AshfordP1.meta(w, "box_grip_player")
		var lh2: Node3D = (gw as Node3D).get_node_or_null("LeftWay") if gw != null and is_instance_valid(gw) else null
		if lh2 != null:
			if carry_side(me2) == "left":
				me2.reach(lh2, null, 0.4)
			else:
				me2.reach(null, lh2, 0.4)
			me2.palm(other_side(me2), Vector3.ZERO, 0.3)
			var low := w.create_tween()
			# (held out from the belly, not against it: the forearms stay
			# clear of the body, 4 November)
			low.tween_property(gw, "position", me2.hold_point(0.52, 0.78), 0.5).set_trans(Tween.TRANS_SINE)
	_two_shot_after_box(w)
	await Cine.wait(w, 0.4)


## Back to the two of them, Bram and the player, after the close shot into
## the box (the lines that follow are spoken in it).
static func _two_shot_after_box(w: World) -> void:
	var bb := Cine.body(w, "bram")
	if bb == null:
		return
	var p := w.player.global_position
	var stop := bb.global_position
	var mid := (p + stop) * 0.5
	var d := stop - p
	d.y = 0.0
	var perp := d.normalized().cross(Vector3.UP)
	var look := mid + Vector3(0, 1.3, 0)
	Cine.shot(w, AshfordP1.clear_cam(w, [mid + perp * 2.8 + Vector3(0, 1.6, 0), mid - perp * 2.8 + Vector3(0, 1.6, 0),
		mid + perp * 2.4 + Vector3(0, 2.2, 0), mid - perp * 2.4 + Vector3(0, 2.2, 0)], look, ["player", "bram"]), look, 36.0)


## The card box goes into the player's pack as the duel starts (off the
## screen then): their hands come free.
static func _box_away(w: World) -> void:
	if w.has_meta("box_player") or w.has_meta("box_grip_player"):
		_drop_box(w, "player")
		var pf = Cine.fig(w, "player")
		if pf is Figure3D:
			(pf as Figure3D).release(0.0)


## A close shot of the box in the player's hands as they open it: from
## beside them, a little ahead and above it, looking down into it (the lid
## opens towards them, so the deck shows), whichever side has nobody in
## the way.
static func _into_box_shot(w: World, box: Node3D) -> void:
	var me = Cine.fig(w, "player")
	if not (me is Figure3D) or not is_instance_valid(box):
		return
	var at := box.global_position
	var fwd := (me as Figure3D).to_world(Vector3(0, 0, 1)) - (me as Figure3D).to_world(Vector3.ZERO)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var left := Vector3.UP.cross(fwd).normalized()
	var look := at + Vector3(0, 0.02, 0)
	# (Bram stands in front of them: the shot is from their left, the side
	# the box sits on its hand, a little ahead and over it)
	Cine.shot(w, AshfordP1.clear_cam(w, [at + left * 0.6 - fwd * 0.1 + Vector3(0, 0.62, 0), at + left * 0.62 + fwd * 0.2 + Vector3(0, 0.48, 0),
		at - left * 0.62 + fwd * 0.05 + Vector3(0, 0.55, 0), at + left * 0.8 + fwd * 0.05 + Vector3(0, 0.7, 0)], look, ["player", "bram"]), look, 36.0)


## `who` steps in towards `to` (facing them) until they stand BOX_GIVE_GAP
## apart, if they're further off than that: someone taking a thing from
## another's hands comes near enough to reach it.
static func _step_to_take(w: World, who: String, to: String) -> void:
	var a := Cine.body(w, who)
	var b := Cine.body(w, to)
	if a == null or b == null:
		return
	var d := b.global_position - a.global_position
	d.y = 0.0
	var dist := d.length()
	if dist > BOX_GIVE_GAP + 0.04:
		var at := a.global_position + d.normalized() * (dist - BOX_GIVE_GAP)
		await Cine.path(w, who, [at], 0.9)
	Cine.look(w, who, b.global_position)


## The Spark deck becomes the player's (Deck and Codex stay shut: see _first_deck).
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
	Game.set_flag("first_deck")
	Game.save_game()


## After the duel, Tilly comes running through the crowd with her Lantern
## Moth glowing in her hands, stops in front of the player and holds it out.
## It passes over while she speaks (_tilly_hands_over, on "You keep it"),
## then the card shows (_tilly_card).
static func _tilly_gift(w: World) -> void:
	var tilly := Cine.body(w, "tilly")
	if tilly == null:
		return
	AshfordP1.tilly_card_away(w)
	var p := w.player.global_position
	var from := tilly.global_position
	var d := from - p
	d.y = 0.0
	d = d.normalized() if d.length() > 0.01 else Vector3.BACK
	var stop := p + d * 1.05
	w.cine = true
	var side := d.cross(Vector3.UP).normalized()
	var look := stop + Vector3(0, 0.9, 0)
	Cine.shot(w, AshfordP1.clear_cam(w, [p - d * 2.4 + side * 1.6 + Vector3(0, 1.9, 0), p - d * 2.4 - side * 1.6 + Vector3(0, 1.9, 0),
		p - d * 2.8 + Vector3(0, 2.8, 0)], look, ["player", "tilly"]), look, 38.0)
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
	var back := 3.3 if tf is Figure3D else 4.6
	var up := 1.3 if tf is Figure3D else 1.45
	var at := mid + Vector3(0, 1.0 if tf is Figure3D else 1.15, 0)
	Cine.shot(w, AshfordP1.clear_cam(w, [mid + side * back + Vector3(0, up, 0), mid - side * back + Vector3(0, up, 0),
		mid + side * back * 0.85 + Vector3(0, up + 0.9, 0), mid - side * back * 0.85 + Vector3(0, up + 0.9, 0)], at, ["player", "tilly"]), at, 38.0)
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
	var glow = AshfordP1.meta(w, "tilly_glow")
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
		# her hands stay where they held it and come down slowly (re-parenting
		# the card took her hands' targets with it: her arms dropped at once)
		var keep_l := Node3D.new()
		var keep_r := Node3D.new()
		var piv: Node3D = (glow as Node3D).get_parent()
		piv.add_child(keep_l)
		piv.add_child(keep_r)
		keep_l.global_transform = (glow as Node3D).get_node("L").global_transform
		keep_r.global_transform = (glow as Node3D).get_node("R").global_transform
		(tf as Figure3D).reach(keep_l, keep_r, 0.0)
		(glow as Node3D).reparent(w)
		(tf as Figure3D).let_go(0.5)
		var drop := w.create_tween()
		drop.tween_interval(0.6)
		drop.tween_callback(func() -> void:
			keep_l.queue_free()
			keep_r.queue_free())
	# an eased arc across, brightening as it crosses, a slow half turn so
	# its face ends up towards you (it slid over on a straight line, which
	# read as blocky: Gary, 23 October)
	var from: Vector3 = glow.global_position
	var to := p + Vector3(0, 1.05, 0) + d * 0.3
	var s0: Vector3 = glow.scale
	var b0: Basis = (glow as Node3D).global_basis
	var gt := w.create_tween()
	gt.tween_method(func(u: float) -> void:
		if is_instance_valid(glow):
			var e := smoothstep(0.0, 1.0, u)
			glow.global_position = from.lerp(to, e) + Vector3(0, sin(e * PI) * 0.16, 0)
			if g3:
				glow.global_basis = Basis(Vector3.UP, PI * e) * b0
			glow.scale = s0 * (1.0 + sin(e * PI) * 0.35), 0.0, 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	# your hands come up to meet it as it comes
	if pf is Figure3D:
		if g3:
			await Cine.wait(w, 0.3)
			_hands_on(pf, glow, 0.6)
		else:
			(pf as Figure3D).pose("play_card", 0.3)
	await gt.finished
	w.set_meta("tilly_handed", true)


## The card in the player's hands shows on screen: NEW SIGIL, Tilly's
## Lantern Moth. (If her line was tapped past before the card got there,
## it lands first.)
static func _tilly_card(w: World) -> void:
	var glow = AshfordP1.meta(w, "tilly_glow")
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
	["v9", "girl", Vector3(2.4, 0, -2.0)], ["v10", "trader", Vector3(-1.0, 0, -5.2)]]


## Everyone to their marks for a scene, at once (behind a fade).
static func _stage(w: World, marks: Dictionary, look_at = null) -> void:
	for who in marks:
		var at: Vector3 = marks[who]
		# anyone still down in the taproom or the cellar (built well below the
		# village) comes up onto the ground first, so place() sets them on it
		# (or still down at the mill set, far out past the village)
		var sb := Cine.body(w, String(who))
		if sb != null and (sb.global_position.y < Cine.ground(w, at) - 5.0 or AshfordDay.at_mill(sb.global_position)):
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
## (all on the inn's side of the green, west of where Tam stands: the
## Reckoning's cameras look across it at Krell, and a villager standing by
## one filled the picture)
const CROWD_NIGHT := [Vector3(-3.1, 0, 8.1), Vector3(-0.7, 0, 8.5), Vector3(-3.4, 0, 5.8), Vector3(-5.2, 0, 8.6),
	Vector3(-1.6, 0, 7.1), Vector3(-6.4, 0, 10.6), Vector3(-8.5, 0, 4.9), Vector3(-7.0, 0, 6.5),
	Vector3(-5.8, 0, 1.9), Vector3(-0.9, 0, 10.1)]


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
## The Prologue's parts after midnight (Master Script v7): the awakening in
## the attic, the dawn and the Pale Herald, That Day in the cellar, the
## Reckoning at dusk (and the tunnel), and the look back from the hill. A
## game saved in one of v3's parts picks up at the nearest v7 one.
const FILM_PARTS := ["awakening", "dawn", "that_day", "reckoning", "look_back"]
const OLD_PARTS := {"taproom": "that_day", "burning": "reckoning", "cellar": "reckoning"}


static func _prologue_film(w: World, part: String) -> void:
	var parts := FILM_PARTS
	part = String(OLD_PARTS.get(part, part))
	var i0 := maxi(0, parts.find(part))
	for i in range(i0, parts.size()):
		Game.set_flag("pro_part", parts[i])
		Game.save_game()
		match parts[i]:
			"awakening":
				await AshfordNight.awakening(w)
			"dawn":
				await _dawn(w)
			"that_day":
				await AshfordNight.that_day(w)
			"reckoning":
				await AshfordNight.reckoning(w)
			"look_back":
				await AshfordNight.look_back(w)
		if not is_instance_valid(w) or not w.is_inside_tree():
			return
	Game.set_flag("pro_tunnel_done")
	Game.save_game()
	w.story_next.emit("thornwood")


# ------------------------------------------------------- P2 · midnight ---

## Midnight as Gary's own film (StoryFilm "midnight": lighting the Lantern
## to Find Corin), when it's there. It plays over the green staged as the 3D
## version stages it, and leaves the world as the 3D version leaves it for
## the cart: the Lantern lit, the sky lanterns hanging, the sky torn and the
## Sigils falling, everyone gone for their doors but Corin, pinned under the
## cart with Tilly by him, and the player back on his feet in the west.
## False if the film couldn't play (the 3D version plays instead).
## (5 November: Gary's film so far runs to Bram's answer to the player's
## choice, its third part still to make: until it's there the film stops
## before it, and the 3D carries on from the sky lanterns going up, its
## camera already on them as the film's last frame dissolves into it.)
static func _midnight_film(w: World) -> bool:
	var v := village(w)
	var r := await StoryFilm.play(w, "midnight")
	if not r.get("played", true):
		return false
	if String(r.get("stopped_at", "")) != "":
		await _midnight_3d(w, "lanterns", r)
		return true
	v.light_great_lantern()
	v.release_lanterns()
	v.lantern_t = 1000.0   # (they're up, and hanging)
	v.start_sigilfall()
	v.tear = 0.999
	v.first_impact()
	for who in RUN_DOORS:
		var way = RUN_DOORS[who]
		Cine.place(w, String(who), way[way.size() - 1] if way is Array else way)
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	v.set_cart_tip(1.0)
	var corin_at := cc + fd * CART_PIN
	Cine.place(w, "corin", corin_at, cc)
	var cf = Cine.fig(w, "corin")
	if cf is Figure3D:
		(cf as Figure3D).pose("fall", CORIN_DOWN, 0.0)
	Cine.place(w, "tilly", cc + fd * (CART_PIN + 0.1) + al * 1.7 + Vector3(0.5, 0, 0.6), corin_at)
	Cine.place(w, "player", RUN_END, cc)
	Music.play(["sigilfall"], 0.5, true)
	Cine.shot(w, RUN_END + Vector3(-3.0, 1.4, 3.0), RUN_END + Vector3(0, 1.0, 0), 40.0)
	await Cine.fade(w, 0.0, 0.6)
	return true


## The white light as Gary's own film (StoryFilm "white_light": after the
## cart, to black), when it's there. It leaves the world as the 3D version
## does: every other light in the sky out, the player marked, on black.
## False if the film couldn't play.
static func _white_light_film(w: World) -> bool:
	var v := village(w)
	Music.stop(1.0)
	var r := await StoryFilm.play(w, "white_light")
	if not r.get("played", true):
		return false
	v.lights_out()
	v.hide_white_light()
	Game.set_flag("ash_marked")
	await Cine.say(w, "", "[i](The white card is in your Items. It can't be played, and it can't be put down.)[/i]")
	return true


## The Pale Herald as Gary's own film (StoryFilm "herald": dawn, up to it
## dissolving and Bram stepping between), when it's there. It leaves the
## green as the 3D version does (the village stepped back from the player,
## Tam looking at the ground, Bram between them), and the hub follows.
## False if the film couldn't play.
static func _herald_film(w: World) -> bool:
	var r := await StoryFilm.play(w, "herald")
	if not r.get("played", true):
		return false
	var p := w.player.global_position
	for d in [["nell", 1.6], ["tilly", 1.8], ["hob", 1.4], ["ned", 1.4], ["kid", 1.6]]:
		var b := Cine.body(w, String(d[0]))
		if b == null:
			continue
		var away := b.global_position - p
		away.y = 0.0
		Cine.place(w, String(d[0]), b.global_position + away.normalized() * float(d[1]))
	var tf = Cine.fig(w, "tam")
	if tf is Figure3D:
		(tf as Figure3D).pose("defeat", 0.3, 0.0)
	var nell_at := Cine.body(w, "nell").global_position
	var village_dir := nell_at - p
	village_dir.y = 0.0
	village_dir = village_dir.normalized()
	var between := p + village_dir * 1.1
	Cine.place(w, "bram", between, nell_at)
	Cine.shot(w, p - village_dir * 2.6 + village_dir.cross(Vector3.UP) * 1.2 + Vector3(0, 1.6, 0), between + Vector3(0, 1.3, 0), 38.0)
	Music.play(["dawn_after"], 1.0, true)
	await Cine.fade(w, 0.0, 0.8)
	return true


## Midnight (Master Script v7, P2, with v3's lines kept): the player lights
## the Great Lantern, Tam dances with Nell, badly; the sky lanterns go up and
## stop, the sky tears, the shockwave shatters the carts; Corin is pinned
## under Tam's cart (Find Corin) and heaved clear; one white light comes down
## to the player, and leaves them a blank card and the mark blazing on their
## collarbone. Each film (midnight, white_light) plays in place of its 3D
## stretch when it's there.
static func _midnight(w: World) -> void:
	await Cine.begin(w)
	await Cine.fade(w, 1.0, 0.6)
	# the evening's extras go and everyone's hands are emptied, behind the
	# black (in view, the dancers would vanish and poses snap)
	AshfordP1.undress(w)
	_stage(w, MID)
	_crowd(w)
	var filmed := false
	if StoryFilm.available("midnight"):
		filmed = await _midnight_film(w)
	if not filmed:
		await _midnight_3d(w)
	await _the_heave(w)
	filmed = false
	if StoryFilm.available("white_light"):
		filmed = await _white_light_film(w)
	if not filmed:
		await _the_white_light(w)


## Midnight in the engine's 3D, from the bell to the player getting up after
## the cart's gone over on Corin (what the midnight film shows). From
## "lanterns": from the sky lanterns going up, after Gary's film of the
## stretch before it (part 1, the choice, Bram's answer: `film`, what
## StoryFilm.play returned, still up on its last frame, is let go into it).
static func _midnight_3d(w: World, from := "start", film := {}) -> void:
	var v := village(w)
	var top: Vector3 = v.great_lantern_top if v.great_lantern_top != Vector3.ZERO else Vector3(0, 8.0, 0)
	if from == "lanterns":
		_at_the_lanterns(w)
	else:
		await _midnight_to_answer(w, v, top)
	await _midnight_lanterns_on(w, v, top, film)


## The green as the 3D has it when Bram has answered, staged at once behind
## the film's last frame: the Lantern lit, Tam and Nell dancing on the east
## side (Hob stepped clear of them), the player back on their mark by Corin
## and Bram, Bram's eyes on the player. The taper was dropped long since.
static func _at_the_lanterns(w: World) -> void:
	var v := village(w)
	# lit half a minute ago, settled (light_great_lantern's flare and sparks
	# would go off in the hand-off)
	if v.great_lantern_light != null:
		v.great_lantern_light.visible = true
		v.great_lantern_light.light_energy = 6.0
		v.great_lantern_glow.visible = true
		v.great_lantern_glow.scale = Vector3.ONE * 1.6
		if v.festival_light != null:
			v.festival_light.light_energy = 1.2
		v.flicker_lights.append([v.great_lantern_light, 7.0])
	Cine.place(w, "player", MID["player"], Cine.body(w, "corin").global_position)
	var dance := _dance_spot()
	Cine.place(w, "tam", dance[0], dance[1])
	Cine.place(w, "nell", dance[1], dance[0])
	for who in ["tam", "nell"]:
		var df = Cine.fig(w, who)
		if df is Figure3D:
			(df as Figure3D).hold("dance")
	var dmid: Vector3 = (dance[0] + dance[1]) * 0.5
	Cine.place(w, "hob", Vector3(8.6, 0, 4.6), dmid)
	Cine.look(w, "corin", dmid)
	Cine.look(w, "bram", Cine.body(w, "player").global_position)


## Midnight in the 3D from the bell to Bram's answer to the player's choice.
static func _midnight_to_answer(w: World, v: AshfordVillage, top: Vector3) -> void:
	# (1 November, Gary: "make the movie start from the lantern lighting"):
	# it opens on the taper at the Lantern's steps, the bell counting twelve
	# over it, rather than on the crowd waiting and the long walk up to it.
	# You light it (the Lantern Duel can't be lost).
	var lighter := "player"
	var at: Vector3 = Vector3(-0.3, 0, 1.85)
	at.y = v.height(at.x, at.z)
	Cine.place(w, lighter, at, Vector3(0, at.y, 0))
	var taper := _taper(v)
	_hold(w, lighter, taper)
	var lf = Cine.fig(w, lighter)
	# low beside them, the taper's flame and their face, the Lantern's hood
	# high over them
	var face := at + Vector3(0, 1.55, 0)
	Cine.shot(w, at + Vector3(1.05, 1.05, 1.35), face + Vector3(0, 0.25, 0), 40.0)
	Cine.fade(w, 0.0, 1.0)
	_bell(w, 12)
	if lf is Figure3D:
		(lf as Figure3D).pose("play_card", 0.3, 0.8)
	Cine.drift(w, at + Vector3(1.05, 1.05, 1.35), at + Vector3(0.7, 0.8, 1.6), face + Vector3(0, 0.25, 0), top - Vector3(0, 0.9, 0), 6.0, 42.0)
	await Cine.say(w, "", "Midnight. The chapel bell counts twelve, and all of Ashford counts with it.")
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
	# Hob steps off to the side, out of the shot: on his mark he stood right
	# behind Tam, and Tam's arms swung across his face (and clear of where the
	# camera stands for Nell and the burning mill)
	Cine.place(w, "hob", Vector3(8.6, 0, 4.6), dmid)
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


## Midnight in the 3D from the sky lanterns going up to the cart over
## Corin. After Gary's film (`film`, StoryFilm.play's answer, up on its last
## frame) the camera is on the lanterns before the picture dissolves into it.
static func _midnight_lanterns_on(w: World, v: AshfordVillage, top: Vector3, film := {}) -> void:
	# the sky lanterns go up, and stop; the fiddle trails off
	v.release_lanterns()
	for who in ["tam", "nell"]:
		var df = Cine.fig(w, who)
		if df is Figure3D:
			(df as Figure3D).release(0.6)
	for who in ["bram", "corin", "player", "tam", "tilly", "nell"]:
		Cine.look(w, who, top)
	Cine.shot(w, Vector3(1.0, 0.6, 9.0), Vector3(0.0, 6.0, -2.0), 52.0)
	if not film.is_empty():
		StoryFilm.let_go(film, 0.4)   # (the film's last frame into this, as they rise)
	# (the menu music of Gary's film, when it played, carries on under them
	# and goes here, as the 3D's own music does)
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
	# the lanterns hang dead still in the sky; no wind moves them. Then a
	# hairline of light runs across the stars (1 November, Gary: Corin
	# asked "is it meant to do that?" before anything had happened: the
	# lanterns had only stopped, too far up to see)
	Cine.shot(w, Vector3(4.0, 1.2, 8.8), Vector3(8.0, 40.0, -30.0), 50.0)
	await Cine.wait(w, 1.4)
	Cine.drift(w, Vector3(4.0, 1.2, 8.8), Vector3(4.6, 1.3, 9.6), Vector3(14.0, 30.0, -34.0), Vector3(30.0, 24.0, -40.0), 3.6, 48.0)
	v.tear_target = 0.14
	_sfx(w, "sigil_strike", 0.45)
	w.shake(0.08)
	await Cine.wait(w, 2.4)
	# his face, from in front and a little below, the sky behind the camera
	# lighting it (from fixed sides of him the shot could fall behind his
	# head)
	var corin_face := Cine.head(w, "corin")
	var face_cams: Array = []
	var cfig = Cine.fig(w, "corin")
	if cfig is Figure3D:
		var cf := cfig as Figure3D
		var hy := corin_face.y - cf.global_position.y
		for x in [0.45, -0.45, 0.85, -0.85]:
			face_cams.append(cf.to_world(Vector3(x, hy - 0.4, 1.3)))
	face_cams += [corin_face + Vector3(1.1, -0.35, 1.2), corin_face + Vector3(-1.1, -0.35, 1.2),
		corin_face + Vector3(1.2, -0.3, -1.1), corin_face + Vector3(-1.2, -0.3, -1.1)]
	Cine.shot(w, AshfordP1.clear_cam(w, face_cams, corin_face, ["corin", "player", "bram", "tilly"]),
		corin_face + Vector3(0, 0.1, 0), 34.0)
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
	# for a breath the children cheer (from across the green, the Lantern's
	# foot behind them: from beside it, its base filled half the shot and hid
	# the boy)
	var kids_cam := Vector3(4.5, 1.2, -6.0)
	Cine.shot(w, kids_cam, Vector3(1.5, 1.0, -2.2), 30.0)
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
	# (v7: no mill on fire: the earth bucks, and the shockwave shatters the
	# merchant carts lining the green)
	w.shake(0.7)
	_sfx(w, "sigil_strike", 0.7)
	v.shatter_carts()
	await w.flash(Color(0.95, 0.96, 1.0), 0.1, 0.9)
	Cine.shot(w, Vector3(-4.0, 1.8, 11.0), Vector3(2.0, 0.8, 2.0), 46.0)
	await Cine.say(w, "", "[i]Screams finally break the silence.[/i]", 2.0)
	for who in ["bram", "corin", "player", "tam", "tilly", "nell"]:
		var f = Cine.fig(w, who)
		if f is Figure3D:
			(f as Figure3D).release()
	Cine.look(w, "bram", Cine.body(w, "player").global_position)
	Cine.over_shoulder(w, "player", "bram", -1.0, 28.0)
	w.shake(0.2)
	await Cine.say(w, "bram", "Inside! Everyone inside! Sprout, the inn. Now!", 2.6)
	await _the_run(w)
	await _the_cart_falls(w)


## Where Tam and Nell dance at midnight, on the open east side of the green,
## clear of the crowd: [Tam, Nell].
static func _dance_spot() -> Array:
	return [Vector3(5.0, 0, 3.4), Vector3(5.8, 0, 3.9)]


## Cine.drift, but handing back its tween so a cut can stop it.
static func _drift_tween(w: World, pos_a: Vector3, pos_b: Vector3, look_a: Vector3, look_b: Vector3, secs: float, fov := -1.0) -> Tween:
	return Cine.drift_tween(w, pos_a, pos_b, look_a, look_b, secs, fov)


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
## Where everyone runs when the sky tears: their doors (Nell and the child
## on the south-west side go round behind the camera that follows the
## player, not through it).
const RUN_DOORS := {"v1": Vector3(-14, 0, 14), "v2": Vector3(4, 0, 18), "v3": Vector3(16, 0, 12), "v4": Vector3(-17, 0, 8),
	"v5": [Vector3(2, 0, 12), Vector3(-6, 0, 16)], "v6": Vector3(18, 0, -2), "v7": Vector3(-18, 0, 0), "v8": Vector3(14, 0, -10),
	"v9": Vector3(-12, 0, -10), "v10": Vector3(6, 0, 18), "nell": [Vector3(0, 0, 13), Vector3(-10, 0, 12)], "hob": Vector3(16, 0, 6),
	"ned": Vector3(-15, 0, -6), "tam": Vector3(12, 0, -16)}
## Where the player's run for the inn ends, knocked flat.
const RUN_END := Vector3(-8.2, 0, 6.8)


static func _the_run(w: World) -> void:
	var v := village(w)
	# everyone scatters for their doors
	var doors := RUN_DOORS
	for who in doors:
		var way: Array = doors[who] if doors[who] is Array else [doors[who]]
		Cine.path(w, String(who), way, 3.0 + randf() * 1.2, "run")
	# Corin grabs Tilly and runs her up the lane towards the mill, past the cart
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	var lane_a := cc + fd * (CART_PIN - 0.1) - al * 3.5
	var lane_b := cc + fd * (CART_PIN - 0.1) + al * 0.1
	w.set_meta("corin_pinned_at", lane_b)
	_corin_and_tilly(w, lane_a, lane_b)
	# the player runs west for the inn
	var run_a := Vector3(-4.6, 0, 6.0)
	var run_b := RUN_END
	Cine.shot(w, Vector3(3.6, 2.0, 8.8), Vector3(-3.0, 1.2, 5.0), 44.0)
	Cine.follow(w, "player", Vector3(4.6, 2.0, 2.6), Vector3(-2.0, 1.1, 0.0), 2.4, 3.0)
	_strike_later(w, Vector3(-6.8, 0, 9.6), SIGIL_COLS[3], 0.55)
	_strike_later(w, Vector3(-3.0, 0, 1.2), SIGIL_COLS[1], 1.1)
	await Cine.path(w, "player", [run_a, run_b], 4.4, "run")
	await v.strike(Vector3(-9.6, 0, 5.4), SIGIL_COLS[4], 0.25)
	w.shake(0.5)
	_sfx(w, "sigil_strike")
	# the run eases out into the fall over a longer blend, the body
	# settling on the ground (it snapped from a stride into the clip's
	# first frame: Gary, 23 October, "very blocky")
	var pf = Cine.fig(w, "player")
	if pf is Figure3D:
		(pf as Figure3D).act("fall", 1.0, 0.4)
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


## In the fall clip (5.5 s: down on his back by 1.4 s, getting up from 2.8 s):
## where Corin is held while he's pinned, and where his getting up starts.
const CORIN_DOWN := 0.26
const CORIN_UP := 0.51
## How far from the hay cart's middle Corin lies pinned (his hips), out on
## the side it falls to: his legs under the bed's side, his body out under
## the hay's edge (at AshfordVillage.HAY_CART_SCALE: 2.7 at the model's own
## size, 6 November).
const CART_PIN := 2.15
## The heave (6 November): where the hands take the cart, in the hay cart
## model's own metres (x across, y up, z along; the tail board's slats
## face back at z -1.15 to -1.3 between x -0.9 and 0.9, y 1.1 to 2.0, the
## wheel it goes over on at x -1.25): on the tail board by its bottom edge,
## which lies just off the grass when the cart's over, a shoulder's width
## apart along it. (At z -1.33 they had been a hand's breadth off the
## wood, in the air behind it.)
const HEAVE_GRIPS := [Vector3(-0.72, 1.3, -1.22), Vector3(-0.72, 1.68, -1.22)]
## How far behind the grips (along the cart) the player crouches.
const HEAVE_STAND := 0.26
## The crouch and the stand, as moments of the sit clip (its first second
## is the way down): down low with the hands on the edge, and up with it.
const HEAVE_LOW := 0.3
const HEAVE_HIGH := 0.08
## How far the heave brings the cart back up (a share of its fall: 0.3 is
## about 26 degrees, enough to free his leg), and the PULL's last heave.
const HEAVE_TIP := 0.3
const HEAVE_PULL := 1.25
## Where Tilly waits for the PULL: this far beyond Corin's head, out from
## the cart, and how far down into the sit clip she crouches to take his
## hands and drag him clear.
const TILLY_AT_HEAD := 0.42
const TILLY_CROUCH := 0.3
## Where the player goes from the tail board when it's over, to Corin
## (out from the cart's middle, along it): round the tail onto the open side.
const HEAVE_TO := Vector2(3.9, -1.45)


## Which of the two grips is on the player's left (0 or 1).
static func _heave_left(f: Figure3D, grips: Array) -> int:
	var left := Vector3.UP.cross(f.facing())
	var a: Vector3 = (grips[0] as Node3D).global_position
	var b: Vector3 = (grips[1] as Node3D).global_position
	return 0 if (a - b).dot(left) > 0.0 else 1


## Every frame of the heave: the cart's lift as shown eases after the
## meter's (`st.qte`, or `st.lift` once it's closed), each press a strain
## (down a touch into the legs, then up), the body rising out of the crouch
## as the cart comes up, a tremor in the arms while they hold it; the cart
## tipped back by it, and the hands, on the grips on the cart, go with it.
static func _heave_drive(w: World, v: AshfordVillage, me, st: Dictionary) -> void:
	var mf: Figure3D = me if me is Figure3D else null
	var sit_len := 0.0
	if mf != null and mf.anim != null and mf.anim.has_animation("sit"):
		sit_len = mf.anim.get_animation("sit").length
	await Cine.wait(w, 0.5)   # (the crouch's blend)
	var t := 0.0
	while st.run and is_instance_valid(w) and w.is_inside_tree():
		var dt := w.get_process_delta_time()
		t += dt
		var q = st.qte
		if q != null and is_instance_valid(q):
			st["lift"] = (q as CartHeave).lift
		var target: float = st.lift
		if target > float(st.last) + 0.01:
			st["pulse"] = 1.0   # a press: a strain
		st["last"] = target
		st["shown"] = lerpf(float(st.shown), target, minf(1.0, dt * 7.0))
		st["pulse"] = maxf(0.0, float(st.pulse) - dt * 3.0)
		var strain := sin(float(st.pulse) * PI)
		var shown: float = st.shown
		v.set_cart_tip(1.0 - HEAVE_TIP * shown)
		if mf != null and is_instance_valid(mf) and sit_len > 0.0 and mf.anim.assigned_animation == "sit":
			var k := lerpf(HEAVE_LOW, HEAVE_HIGH, clampf(shown, 0.0, 1.1)) + 0.03 * strain
			mf.anim.seek(sit_len * clampf(k, 0.02, 0.4), true)
			# the effort: a fine tremor through them while they hold it up
			mf.rotation.z = sin(t * 53.0) * 0.006 * clampf(shown * 1.5, 0.0, 1.0)
		await w.get_tree().process_frame
	if mf != null and is_instance_valid(mf):
		mf.rotation.z = 0.0


## The cart goes over: a strike lands beside it, it comes down on Corin, and
## Tilly screams for him; the player gets up in the west and turns back (the
## end of what the midnight film shows; _the_heave goes on from here).
static func _the_cart_falls(w: World) -> void:
	var v := village(w)
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	# wait for Corin to come level with the cart
	var corin := Cine.body(w, "corin")
	var pin: Vector3 = w.get_meta("corin_pinned_at", cc + fd * (CART_PIN - 0.1))
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
	# he turns to the blast, and it throws him down on his back, his legs
	# under the cart as it comes over (the fall clip, held down: a body
	# tipped over stiff, as it used to be, looked like a plank falling)
	Cine.look(w, "corin", cc)
	v.tip_cart(1.0, 0.55)
	await Cine.wait(w, 0.3)
	var cf = Cine.fig(w, "corin")
	Cine.place(w, "corin", cc + fd * CART_PIN)
	if cf is Figure3D:
		(cf as Figure3D).pose("fall", CORIN_DOWN, 0.45)
	else:
		Cine.place(w, "corin", cc + fd * CART_PIN, cc)
	await Cine.wait(w, 0.3)
	v.dust_puff(cc + fd * (CART_PIN + 0.1))
	v.dust_puff(cc + fd * (CART_PIN + 0.6) + al * 0.8)
	_sfx(w, "cart_crash")
	await Cine.hop(w, "tilly", 0.25)
	# from behind Tilly (where her run ends): Corin under the cart, beyond her
	var tb := Cine.body(w, "tilly")
	Cine.place(w, "tilly", cc + fd * (CART_PIN + 0.1) + al * 1.7 + Vector3(0.5, 0, 0.6), corin.global_position)
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


## The cart, from "Find Corin" (after its fall, the 3D version's or the
## midnight film's): the player runs to its tail, crouches and takes the
## bottom edge of its tail board in both hands, Corin's cry, and the heave
## (CartHeave: v7 has him alone, Bram across the green), the cart coming up
## in their hands a heave at a time; on the PULL they stand up with it,
## Tilly drags Corin clear by his hands, and they let it drop as the sky
## lets go a second pulse. Corin on his feet, shaking.
## (6 November, Gary: "When you're doing the heave pull with the cart the
## players aren't doing anything": they had stood a stride off the hay with
## their arms at their sides while the cart rocked a little on its own.)
## The first of `tries` where someone can stand clear of the hay cart as it
## lies now: each of its meshes' bounds in its own frame (so a cart on its
## side is measured as it lies, not by a box square to the world round it),
## grown by a body's half-width, tested at a child's hips and chest. Its
## spilt hay reaches further than its bed. The last of them if none is.
static func _clear_of_cart(v: AshfordVillage, tries: Array) -> Vector3:
	if tries.is_empty():
		return Vector3.ZERO
	if v.hay_cart == null:
		return tries[0]
	var meshes: Array = []
	for mi in v.hay_cart.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh != null and m.is_visible_in_tree():
			meshes.append(m)
	for p in tries:
		var q: Vector3 = p
		var clear := true
		for m in meshes:
			var mm := m as MeshInstance3D
			var inv := mm.global_transform.affine_inverse()
			var grow := 0.25 / maxf(mm.global_transform.basis.get_scale().x, 0.01)
			var bb := mm.get_aabb().grow(grow)
			for h in [0.5, 0.9]:
				if bb.has_point(inv * Vector3(q.x, q.y + h, q.z)):
					clear = false
		if clear:
			return q
	return tries[tries.size() - 1]


static func _the_heave(w: World) -> void:
	var v := village(w)
	var cc := v.cart_centre()
	var fd := v.cart_fall_dir()
	var al := v.cart_along()
	var corin := Cine.body(w, "corin")
	var cf = Cine.fig(w, "corin")
	var me = Cine.fig(w, "player")
	# where the hands go: the bottom edge of the tail board, either side of
	# the middle of its width, on the cart (so they go up with it)
	var grips: Array = []
	for g in HEAVE_GRIPS:
		var n := Node3D.new()
		n.name = "HeaveGrip%d" % grips.size()
		if v.hay_cart != null:
			v.hay_cart.add_child(n)
			n.position = g
		else:
			w.add_child(n)
			n.global_position = cc + fd * 2.0 - al * 1.2 + Vector3(0, 0.45, 0)
		grips.append(n)
	var gmid: Vector3 = ((grips[0] as Node3D).global_position + (grips[1] as Node3D).global_position) * 0.5
	# where they crouch to it: behind the tail, facing along the cart
	var lift_p := gmid - al * HEAVE_STAND
	lift_p.y = Cine.ground(w, lift_p)
	# "The ground is buckling. Find Corin." The player runs to the cart's
	# tail (v7: alone; Bram is across the green)
	w.hud.set_objective("The ground is buckling. Find Corin.")
	Cine.follow(w, "player", Vector3(-3.5, 2.6, 4.0), Vector3(1.5, 1.0, -1.0), 3.0, 2.2)
	await Cine.path(w, "player", [Vector3(-1.0, 0, 6.0), cc + fd * 5.0 - al * 2.6, lift_p], 5.4, "run")
	Cine.place(w, "player", lift_p, lift_p + al)
	w.hud.set_objective("")
	# Tilly steps back out of the way, to Corin's head (beyond it, facing him
	# and the cart: there to take his hands when it comes up)
	var t_at := cc + fd * (CART_PIN + 1.5) + al * 0.9
	if cf is Figure3D:
		var hd := (cf as Figure3D).bone_pos("Head")
		t_at = Vector3(hd.x, 0.0, hd.z) + fd * TILLY_AT_HEAD
	Cine.place(w, "tilly", t_at, corin.global_position)
	# under the cart: from the open side, the cart's tail, the player at it and Corin
	Cine.shot(w, cc + fd * 6.4 - al * 1.4 + Vector3(0, 1.5, 0), cc + fd * 1.9 - al * 0.55 + Vector3(0, 0.55, 0), 44.0)
	# down into a crouch, the hands onto the edge, under it
	if me is Figure3D:
		var mf := me as Figure3D
		mf.pose("sit", HEAVE_LOW, 0.5)
		mf.reach(grips[_heave_left(mf, grips)], grips[1 - _heave_left(mf, grips)], 0.5)
	await Cine.say(w, "corin", "Sprout! My leg—it's caught on the axle! I can't shift it, it's crushing the bone!")
	# the heave: mash to lift it, then pull him clear at the right moment;
	# each heave a strain up out of the crouch, the cart coming up with the
	# hands (_heave_drive)
	var qte := CartHeave.open(Cine.overlay(w)._root, WorldCoach.of(w.hud).device())
	var st := {"lift": 0.0, "shown": 0.0, "last": 0.0, "pulse": 0.0, "run": true, "qte": qte}
	_heave_drive(w, v, me, st)
	await qte.done
	# the PULL: they stand right up with it, the cart up off him, and Tilly
	# drags him clear by his hands; then it drops as the sky lets go a second,
	# blinding pulse
	st["qte"] = null
	_sfx(w, "cart_crash", 1.4)
	var up := w.create_tween()
	up.tween_method(func(k: float) -> void: st["lift"] = k, 1.0, HEAVE_PULL, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await Cine.wait(w, 0.3)
	var tf = Cine.fig(w, "tilly")
	var tb := Cine.body(w, "tilly")
	var wrists: Array = []
	if tf is Figure3D and cf is Figure3D:
		# (under his arms, at his shoulders: lying back, his hands are on
		# his chest, beyond her)
		for bone in ["LeftArm", "RightArm"]:
			var wn := Node3D.new()
			w.add_child(wn)
			wn.global_position = (cf as Figure3D).bone_pos(bone) + fd * 0.04
			wrists.append(wn)
		Cine.look(w, "tilly", corin.global_position)
		# down on her haunches to take them
		(tf as Figure3D).pose("sit", TILLY_CROUCH, 0.25)
		(tf as Figure3D).reach(wrists[0], wrists[1], 0.25)
		await Cine.wait(w, 0.3)
	var drag := w.create_tween()
	drag.set_parallel(true)
	drag.tween_property(corin, "global_position", corin.global_position + fd * 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	if tb != null:
		drag.tween_property(tb, "global_position", tb.global_position + fd * 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	for wn in wrists:
		drag.tween_property(wn, "global_position", (wn as Node3D).global_position + fd * 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	await drag.finished
	if tf is Figure3D:
		(tf as Figure3D).let_go(0.3)
		(tf as Figure3D).release(0.5)
	for wn in wrists:
		(wn as Node).queue_free()
	# they let go, and it comes down where he was
	st["run"] = false
	if me is Figure3D:
		(me as Figure3D).let_go(0.15)
	await v.tip_cart(1.0, 0.22, Tween.TRANS_QUAD, Tween.EASE_IN)
	for g in grips:
		(g as Node).queue_free()
	v.dust_puff(cc + fd * (CART_PIN + 0.3))
	_sfx(w, "cart_crash")
	if me is Figure3D:
		(me as Figure3D).release(0.5)
	_sfx(w, "sigil_strike", 0.8)
	w.shake(0.5)
	await w.flash(Color(1, 1, 1), 0.06, 1.0)
	# the player comes round the cart's tail to him, out on the open side
	# (from the tail board, the way to him straight on lay through the cart)
	Cine.path(w, "player", [cc + fd * HEAVE_TO.x + al * HEAVE_TO.y], 1.2)
	if cf is Figure3D:
		await (cf as Figure3D).resume(CORIN_UP, 1.5)   # the fall's own getting up
	Cine.look(w, "corin", w.player.global_position)
	# Tilly by him, on the open side: her old place, a step along the cart
	# from him, was in its spilt hay once it had come down (12 November, the
	# body check: her body 18 to 30 cm inside the hay cart all through "I'm
	# all right"), so the first of these places clear of the cart
	var ca := corin.global_position
	Cine.place(w, "tilly", _clear_of_cart(v, [ca + al * 1.0 + fd * 0.3, ca + fd * 1.0 + al * 0.5,
		ca + fd * 1.0 - al * 0.5, ca - al * 1.0 + fd * 0.3, ca + fd * 1.5]), ca)
	var mid := (corin.global_position + w.player.global_position) * 0.5
	Cine.shot(w, mid + fd * 3.4 + al * 1.0 + Vector3(0, 1.5, 0), mid + Vector3(0, 1.2, 0), 36.0)
	var to_p := w.player.global_position - corin.global_position
	to_p.y = 0.0
	await _limp(w, "corin", corin.global_position + to_p.normalized() * minf(0.6, to_p.length() - 0.9), 1.6)
	Cine.look(w, "corin", w.player.global_position)
	await Cine.say(w, "corin", "I'm all right. I'm all right.")
	# he isn't: he can hardly stand on it, and his hands are shaking
	if cf is Figure3D:
		(cf as Figure3D).pose("play_card", 0.3, 0.4)
	var hands: Vector3 = (cf as Figure3D).bone_pos("RightHand") if cf is Figure3D else corin.global_position + Vector3(0, 1.0, 0)
	var cdir := corin.global_position.direction_to(w.player.global_position)
	cdir.y = 0.0
	Cine.shot(w, hands + cdir * 1.1 + cdir.cross(Vector3.UP) * 0.5 + Vector3(0, 0.25, 0), hands + Vector3(0, -0.05, 0), 30.0)
	await _tremble(w, "corin", 1.8, 0.02)
	if cf is Figure3D:
		(cf as Figure3D).release(0.4)
	# Bram is across the green, in the crowd (he comes through it to the player
	# when the white light has landed)
	var bram_from := cc + fd * 9.0 - al * 4.5
	Cine.place(w, "bram", bram_from, w.player.global_position)


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


## A hand on someone's sleeve: `who`'s hand on their side to the forearm
## of `of` on theirs, a third of the way down from the elbow and on the
## outside of the sleeve towards them, following the arm as it moves (the
## mark rides on the forearm's bone), the palm to the arm. Returns what
## carries the mark, for _sleeve_let_go.
static func _sleeve_hold(w: World, who: String, of: String) -> Node3D:
	var hf = Cine.fig(w, who)
	var of_f = Cine.fig(w, of)
	if not (hf is Figure3D and of_f is Figure3D):
		return null
	var h := hf as Figure3D
	var o := of_f as Figure3D
	if o._skel == null:
		return null
	var to_h := h.global_position - o.global_position
	to_h.y = 0.0
	if to_h.length() < 0.05:
		return null
	to_h = to_h.normalized()
	# his arm nearer her and her hand nearer it, by where the bones are (his
	# facing() can lag a turn still under way)
	var mid := h.bone_pos("Spine2")
	var his := "Right" if o.bone_pos("RightForeArm").distance_to(mid) < o.bone_pos("LeftForeArm").distance_to(mid) else "Left"
	var fa := o._skel.find_bone(his + "ForeArm")
	var hb := o._skel.find_bone(his + "Hand")
	if fa < 0 or hb < 0:
		return null
	var att := BoneAttachment3D.new()
	att.name = "SleeveHold"
	o._skel.add_child(att)
	att.bone_name = his + "ForeArm"
	var mark := Node3D.new()
	att.add_child(mark)
	await Cine.wait(w, 0.05)   # (the attachment on the bone as drawn)
	if not is_instance_valid(att):
		return null
	var along: Vector3 = o._skel.get_bone_rest(hb).origin * 0.35
	var out_way := att.global_basis.orthonormalized().inverse() * (to_h * 0.045 * o.stature())
	mark.position = along + out_way / maxf(att.global_basis.get_scale().x, 0.01)
	var at := mark.global_position
	var hers := "right" if h.bone_pos("RightArm").distance_to(at) < h.bone_pos("LeftArm").distance_to(at) else "left"
	if hers == "right":
		h.reach(null, mark, 0.45)
	else:
		h.reach(mark, null, 0.45)
	h.palm(hers, -to_h, 0.45, 0.3)
	return att


static func _sleeve_let_go(w: World, who: String, att: Node3D) -> void:
	var hf = Cine.fig(w, who)
	if hf is Figure3D:
		(hf as Figure3D).let_go(0.4)
		(hf as Figure3D).palm("left", Vector3.ZERO, 0.4)
		(hf as Figure3D).palm("right", Vector3.ZERO, 0.4)
	await Cine.wait(w, 0.5)
	if att != null and is_instance_valid(att):
		att.queue_free()


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
		# (behind him was in the hay cart's spilt hay, lying on its side
		# beside him: 12 November, the body check found her body 18 to 30 cm
		# in it all through the white light; the first place behind or
		# beside him that's clear of it)
		var cbp := cb.global_position
		var sd := away.cross(Vector3.UP)
		# (close enough to hold his sleeve, a child's arm away: half a metre,
		# on the side away from you first; further out only if the cart's there)
		if (cbp + sd - p).length() < (cbp - sd - p).length():
			sd = -sd
		Cine.place(w, "tilly", _clear_of_cart(v, [cbp + away * 0.3 + sd * 0.42, cbp + sd * 0.52,
			cbp + away * 0.3 - sd * 0.42, cbp + away * 0.52, cbp - sd * 0.52,
			cbp + away * 0.9 + sd * 0.5, cbp + away * 0.9 - sd * 0.5,
			cbp + away * 0.4 + sd * 1.0, cbp + away * 0.4 - sd * 1.0, cbp + sd * 1.1, cbp - sd * 1.1,
			cbp - away * 0.5 + sd * 1.0, cbp - away * 0.5 - sd * 1.0]), cbp)
	# and holds on to his sleeve as it comes down (12 November, Gary's yes: a
	# frightened child's hand on the arm of the one beside her)
	var sleeve := await _sleeve_hold(w, "tilly", "corin")
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
	_sleeve_let_go(w, "tilly", sleeve)   # (it's over: she lets go)
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
	# an instant later, a searing agony under the collarbone: the ash-grey
	# broken seal he's hidden all his life blazes with white fire (v7)
	SealMark.show_on(w, true)
	if pf is Figure3D:
		(pf as Figure3D).pose("defeat", 0.3, 0.25)
	var neck: Vector3 = (pf as Figure3D).bone_pos("Neck") if pf is Figure3D else p + Vector3(0, 1.45, 0)
	Cine.shot(w, neck + pfwd * 0.75 + pside * 0.25 + Vector3(0, 0.02, 0), neck + Vector3(0, -0.08, 0) + pfwd * 0.05, 30.0)
	SealMark.blaze(w, 1.0, 0.2)
	_sfx(w, "sigil_strike", 1.7)
	w.flash(Color(0.95, 0.97, 1.0), 0.04, 0.6)
	w.shake(0.2)
	await Cine.wait(w, 1.6)
	if pf is Figure3D:
		(pf as Figure3D).pose("play_card", 0.42, 0.4)
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
	# Bram shoves his way through the screaming crowd, his face pale with
	# terror, throws his heavy wool coat over you and closes your fingers over
	# the card; its glow dies between them (v7)
	var bram := Cine.body(w, "bram")
	var to_p := p - bram.global_position
	to_p.y = 0.0
	Cine.shot(w, p + open * 4.5 + along * -1.5 + Vector3(0, 1.7, 0), (p + bram.global_position) * 0.5 + Vector3(0, 1.2, 0), 40.0)
	await Cine.path(w, "bram", [p - to_p.normalized() * 0.62], 3.6, "run")
	Cine.look(w, "bram", p)
	Cine.look(w, "player", bram.global_position)
	var mb := (bram.global_position + p) * 0.5
	Cine.shot(w, mb + open * 2.8 + along * 0.6 + Vector3(0, 1.55, 0), mb + Vector3(0, 1.35, 0), 32.0)
	var bfig = Cine.fig(w, "bram")
	# his coat off his back and round your shoulders, his hands on them a
	# moment, then his left hand down over your right
	var coat := _bram_coat(v)
	coat.visible = false
	if bfig is Figure3D and pf is Figure3D:
		var sl := _shoulder_point(w, "player", bram.global_position)
		(bfig as Figure3D).reach(null, sl, 0.35)
		await Cine.wait(w, 0.3)
		_free_tracker(sl)
	_coat_on(w, "player", coat)
	coat.visible = true
	var drape := coat.scale
	coat.scale = drape * Vector3(1.12, 0.9, 1.12)
	var ct := w.create_tween()
	ct.tween_property(coat, "scale", drape, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if bfig is Figure3D:
		(bfig as Figure3D).reach(holder, null, 0.6)   # his left hand, over your right
	await Cine.say(w, "bram", "Close your fist. Don't look at it. Hide it. Now.")
	var cardp: Vector3 = holder.global_position
	var pside2 := (cardp - bram.global_position).cross(Vector3.UP).normalized()
	Cine.shot(w, cardp + pside2 * 0.75 + Vector3(0, 0.3, 0) - to_p.normalized() * 0.15, cardp, 28.0)
	var gt := w.create_tween().set_parallel(true)
	gt.tween_property(cl, "light_energy", 0.0, 1.2)
	gt.tween_property(g, "scale", Vector3.ONE * 0.02, 1.2)
	await _tremble(w, "bram", 1.4, 0.012)
	# shoved deep into the coat; and the moment it's hidden, the pressure:
	# his vision swims, and he goes down into the mud
	if bfig is Figure3D:
		(bfig as Figure3D).let_go(0.4)
	_drop(w, "player")
	SealMark.blaze(w, 0.0, 1.2)
	Cine.shot(w, mb + open * 2.2 + Vector3(0, 0.9, 0), p + Vector3(0, 0.6, 0), 40.0)
	if pf is Figure3D:
		(pf as Figure3D).release(0.2)
		(pf as Figure3D).act("fall", 0.8, 0.4)
	w.flash(Color(1, 1, 1), 0.3, 0.8)
	await Cine.wait(w, 0.5)
	await Cine.fade(w, 1.0, 1.4)
	if is_instance_valid(coat):
		coat.queue_free()
	SealMark.show_on(w, false)
	Game.set_flag("ash_marked")
	await Cine.say(w, "", "[i](The white card is in your Items. It can't be played, and it can't be put down.)[/i]")


## Bram's heavy wool coat, thrown round the player's shoulders at midnight.
## (1 November, Gary: "when Bram says close your fist the player deforms with
## something around it": it was a plain cone of cloth dropped over the
## player's head from above, like a lampshade, and it hid the arms that
## reach out of it for the card.) Now a coat: worn brown wool hanging from
## the shoulders to the knee in folds, open at the front where the arms come
## out, a turned-down collar at the neck. Its origin is the middle of the
## shoulders; put it on with _coat_on, which sits it on the chest bone so it
## goes where they go.
static func _bram_coat(v: AshfordVillage) -> Node3D:
	var c := Node3D.new()
	c.name = "BramsCoat"
	v.add_child(c)
	var wool := StandardMaterial3D.new()
	wool.albedo_color = Color(0.27, 0.2, 0.15)
	wool.roughness = 1.0
	wool.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lining := StandardMaterial3D.new()
	lining.albedo_color = Color(0.36, 0.14, 0.1)
	lining.roughness = 0.9
	# rings from the shoulders down: [y, half width, half depth]
	var rings := [[0.06, 0.13, 0.1], [0.0, 0.24, 0.15], [-0.08, 0.27, 0.17], [-0.3, 0.27, 0.18], [-0.55, 0.3, 0.21], [-0.8, 0.33, 0.24], [-0.95, 0.35, 0.26]]
	var seg := 26
	var open := 0.62   # the opening at the front (radians each side of ahead)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pt := func(ri: int, k: int) -> Vector3:
		var r: Array = rings[ri]
		var a := open + (TAU - 2.0 * open) * float(k) / seg
		# folds, deeper towards the hem
		var fold := 1.0 + 0.06 * sin(a * 9.0 + ri) * clampf(-float(r[0]) * 1.4, 0.0, 1.0)
		return Vector3(sin(a) * float(r[1]) * fold, float(r[0]), cos(a) * float(r[2]) * fold)
	for ri in rings.size() - 1:
		for k in seg:
			var a0: Vector3 = pt.call(ri, k)
			var a1: Vector3 = pt.call(ri, k + 1)
			var b0: Vector3 = pt.call(ri + 1, k)
			var b1: Vector3 = pt.call(ri + 1, k + 1)
			var u0 := float(k) / seg
			var u1 := float(k + 1) / seg
			var v0 := float(ri) / (rings.size() - 1)
			var v1 := float(ri + 1) / (rings.size() - 1)
			for tri in [[a0, Vector2(u0, v0), b0, Vector2(u0, v1), a1, Vector2(u1, v0)], [a1, Vector2(u1, v0), b0, Vector2(u0, v1), b1, Vector2(u1, v1)]]:
				st.set_uv(tri[1]); st.add_vertex(tri[0])
				st.set_uv(tri[3]); st.add_vertex(tri[2])
				st.set_uv(tri[5]); st.add_vertex(tri[4])
	st.generate_normals()
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = wool
	c.add_child(m)
	# the collar, turned down round the back of the neck
	var collar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.17
	cm.height = 0.07
	cm.radial_segments = 16
	cm.cap_top = false
	cm.cap_bottom = false
	collar.mesh = cm
	collar.material_override = lining
	collar.position = Vector3(0, 0.07, -0.02)
	collar.scale = Vector3(1.0, 1.0, 0.75)
	c.add_child(collar)
	return c


## The coat round someone's shoulders, on their chest bone (Spine2), so it
## moves with them; falls back to their body if there's no such bone.
static func _coat_on(w: World, who: String, coat: Node3D) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		var fig := f as Figure3D
		var at := Vector3(0, 0.13 * fig.stature(), -0.02)
		var ba := AshfordP1.attach(fig, "Spine2", coat, at, Vector3.ZERO)
		if ba != null:
			coat.scale = Vector3.ONE * fig.stature()
			return
	var b := Cine.body(w, who)
	if b != null:
		coat.reparent(b, false)
		coat.position = Vector3(0, 1.42, 0)


# ------------------------------------------------------- P3 · dawn ---

## Where everyone stands on the green at dawn, looking up the road. Bram is
## behind the player's right shoulder, close enough to put a hand on it with
## his arm bent (8 November: at 0.9 m his left shoulder was 0.56 m from the
## player's right one, the length of his arm, and his arm stuck out straight
## to it; 0.41 m now), and far enough that the two of them on one knee don't
## run into each other.
const DAWN := {
	"player": Vector3(0.6, 0, 11.0), "bram": Vector3(0.37, 0, 11.71), "corin": Vector3(-1.0, 0, 10.4),
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
	_clear_crowd(w)
	_stage(w, DAWN, HERALD_ROAD[1])
	Cine.place(w, "tilly", DAWN.tilly, Vector3(-4.6, 0, 13.6))
	Cine.spawn(w, "kid", "child_b", Vector3(-5.4, 0, 12.6))
	Cine.place(w, "kid", Vector3(-5.4, 0, 12.6), Vector3(-4.6, 0, 13.6))
	# (Gary's film has its own music; the 3D has the morning-after theme)
	var with_film := StoryFilm.available("herald")
	if not with_film:
		Music.play(["dawn_after"], 2.0, true)
		# the Herald, its mist and a vision built and drawn now, behind the
		# black, not after Hob's line (8 November, Gary: "it takes a while to
		# load" there)
		await _warm_herald(w)
	await Cine.caption(w, "Dawn")
	var left := {}
	var filmed := false
	if with_film:
		filmed = await _herald_film(w)
	if not filmed:
		if with_film:
			Music.play(["dawn_after"], 2.0, true)
		left = await _herald_3d(w)
	await _dawn_hub(w, left)


## Dawn and the Pale Herald in the engine's 3D, up to Bram stepping between
## the player and the village (what the herald film shows). Hands back what
## the hub takes down after: the Herald, its mist, the mark's blaze and the
## tracker on the player's shoulder.
static func _herald_3d(w: World) -> Dictionary:
	var v := village(w)
	# the morning after, smoke over the hills
	Cine.shot(w, Vector3(-30.0, 14.0, 40.0), Vector3(8.0, 4.0, -16.0), 46.0)
	Cine.fade(w, 0.0, 1.6)
	await Cine.drift(w, Vector3(-30.0, 14.0, 40.0), Vector3(-18.0, 8.0, 31.0), Vector3(8.0, 4.0, -16.0), Vector3(6.0, 3.0, -12.0), 6.0)
	# (v7: no mill burned in the night)
	if false and v.mill_root != null:
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
	await Cine.say(w, "hob", "Lost half the barley. Found nine cards in the cabbages. Can't tell if that's a good trade.")
	fan.queue_free()
	# the temperature drops; there is no sound of arrival. It is simply,
	# suddenly there, hovering inches above the crushed grass: a towering,
	# shifting mass of grey burial cloth and rusted iron chains (v7)
	# (1 November, Gary: "the Herald moving also needs reanimating so it
	# looks like a movie": it had simply appeared, faded in on its mark.)
	# Now the cold comes first: the mist rolls down the road from the east
	# against the wind, the grass bowing and the lanterns guttering; heads
	# turn to it one by one; the Herald comes out of it, hovering over the
	# road, chains dragging, and glides down past the last cottages to its
	# mark, the village going down on its knees as it passes, Bram's hand
	# bringing the player down with him.
	# (8 November: the Herald and its mist were built here, after Hob's line,
	# and the first frame to draw them compiled their shaders: _warm_herald
	# built and drew them in the black before the caption, and they're taken
	# from there.)
	var herald := _herald_ready(w)
	Cine.call_by(w, "herald", "The Pale Herald")
	var road := _herald_road(v)
	var hat: Vector3 = road[road.size() - 1]
	var mist: Node3D = herald.get_meta("mist")
	var shoulder := _shoulder_point(w, "player", Vector3.INF, "right", "bram", "left")
	var bf = Cine.fig(w, "bram")
	var pp := w.player.global_position
	# the cold: the green from the west, everyone still, breath showing
	Cine.drift(w, Vector3(-4.0, 1.5, 13.6), Vector3(-3.4, 1.55, 13.0), Vector3(4.0, 1.2, 11.6), Vector3(6.0, 1.3, 12.2), 3.4, 44.0)
	await Cine.wait(w, 1.0)
	# heads turn to the road, one after another
	for who in ["hob", "tam", "nell", "corin", "bram", "player", "tilly", "kid", "ned"]:
		Cine.look(w, who, road[1])
		await Cine.wait(w, 0.18)
	await Cine.wait(w, 1.0)
	# down the road from behind them, long: the mist coming, the shape in it
	var road_cam := Vector3(4.6, 1.75, 12.4)
	var walk := _herald_walk(w, herald, road.slice(1), 1.25)
	var appear := w.create_tween()
	appear.tween_property(herald, "fade", 1.0, 3.0)
	_sfx(w, "ward_set", 0.5)
	Cine.drift(w, road_cam, road_cam + Vector3(0.6, -0.15, 0.2), (road[1] as Vector3) + Vector3(0, 2.0, 0), (road[2] as Vector3) + Vector3(0, 2.1, 0), 6.0, 30.0)
	await Cine.wait(w, 5.2)
	# low by the last cottage as it passes, its chains dragging on the road
	var low := (road[2] as Vector3) + Vector3(-1.8, 0.45, 3.2)
	var watch := [true]
	var cam_watch := func() -> void:
		var tok := Cine.take_camera(w)
		w.cam.global_position = low
		w.cam.fov = 36.0
		while watch[0] and is_instance_valid(herald) and Cine.has_camera(w, tok):
			w.cam.look_at(herald.global_position + Vector3(0, 1.7, 0), Vector3.UP)
			await w.get_tree().process_frame
	cam_watch.call()
	await Cine.wait(w, 3.0)
	watch[0] = false
	# the village goes down on its knees as it comes past them
	Cine.drift(w, Vector3(3.6, 1.4, 8.4), Vector3(3.2, 1.45, 8.9), Vector3(-1.0, 0.9, 11.4), Vector3(-0.6, 0.85, 11.6), 4.5, 42.0)
	for who in ["hob", "tam", "ned", "nell", "corin", "tilly", "kid"]:
		Cine.look(w, who, herald.global_position)
		_kneel(w, who, 0.7)
		await Cine.wait(w, 0.32)
	for k in 30:
		if not is_instance_valid(walk) or walk.has_meta("done"):
			break
		await Cine.wait(w, 0.15)
	if is_instance_valid(herald):
		herald.global_position = hat
		herald.look_dir(Vector3(-1, 0, -0.15))
	for who in ["bram", "corin", "player", "nell", "tam", "hob", "tilly", "kid", "ned"]:
		Cine.look(w, who, hat)
	# Bram's hand on your shoulder, and the two of you go down together
	Cine.drift(w, pp + Vector3(2.4, 1.15, -0.6), pp + Vector3(2.2, 0.95, -0.5), pp + Vector3(0.0, 1.05, 0.35), pp + Vector3(0.0, 0.8, 0.35), 2.0, 34.0)
	if bf is Figure3D:
		(bf as Figure3D).reach(shoulder, null, 0.5)   # his left hand, on your right shoulder
		# (palm flat on top of it, the fingers forward over its front: the
		# point is where the palm's middle goes, 8 November)
		var pfig = w.player_doll
		(bf as Figure3D).palm("left", Vector3.DOWN, 0.5, 0.5, false, (pfig as Figure3D).facing() if pfig is Figure3D else Vector3.RIGHT)
	await Cine.wait(w, 0.5)
	_kneel(w, "bram", 0.8)
	_kneel(w, "player", 0.9)
	await Cine.wait(w, 0.8)
	await Cine.say(w, "bram", "A Pale Herald. Morrowen's own. Head down. Hand in your pocket.")
	# the Covenant
	Cine.shot(w, HERALD_AT + Vector3(-3.6, 0.9, 2.4), herald.hood_pos() + Vector3(0, -0.15, 0), 36.0)
	var cov := _drift_tween(w, Vector3(-1.6, 2.1, 12.8), Vector3(0.6, 2.2, 13.0), HERALD_AT + Vector3(1.0, 2.6, 0), HERALD_AT + Vector3(1.6, 2.7, 0), 14.0, 40.0)
	await _herald_say(w, 21, "The Age is turned. The Turning year begins. I am the witness. I record the current holders of the seven Dominion Seats, subject to open challenge. Let the blood of the contenders be counted.")
	cov.kill()
	# it begins to list the current Champions: Solhaven's knight in a sun chapel
	herald.lantern_flare(1.0)
	var vis := _vision(w, herald, 0)
	var vc := vis.global_position
	Cine.shot(w, vc + Vector3(-5.6, -2.9, -0.9), vc + Vector3(0.6, -0.75, 0.0), 40.0)
	await _herald_say(w, 3, "Solhaven, for Solmaris: Ser Aldric Vane.")
	await _vision_out(w, vis)
	# Glyphmere: and at the name, Bram's hand tightens on your shoulder
	Cine.shot(w, HERALD_AT + Vector3(-3.6, 0.9, 2.4), herald.hood_pos() + Vector3(0, -0.15, 0), 36.0)
	var cv := _vision(w, herald, 6)
	_hand_tightens(w, shoulder, 1.7)
	await _herald_say(w, 9, "Glyphmere, for Aldrith: Magister Tobias Crane.")
	await _vision_out(w, cv)
	# then the other five, too quick to hold; the camera on Ashford's faces
	# (at face height: at 0.85 m they showed chests and legs)
	# (1 November: they're on their knees now, faces a good half metre lower)
	var faces := [
		[Vector3(-4.0, 1.7, 15.6), Vector3(4.0, 2.6, 12.0)],
		[DAWN.nell + Vector3(1.6, 1.05, -1.3), DAWN.nell + Vector3(0.0, 0.97, 0.0)],
		[DAWN.tam + Vector3(1.8, 1.15, -1.1), DAWN.tam + Vector3(0.0, 1.1, 0.0)],
		[(DAWN.corin + DAWN.player) * 0.5 + Vector3(2.06, 1.15, -0.94), (DAWN.corin + DAWN.player) * 0.5 + Vector3(0, 1.05, 0)],
		[DAWN.hob + Vector3(2.0, 1.2, -1.0), DAWN.hob + Vector3(0.0, 1.15, 0.0)],
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
		await Cine.wait(w, 0.7)
		_vision_out(w, fv, 0.18)
		# the heat rising in your chest as the last face goes
		if i == 4:
			break
	var fo := w.create_tween()
	fo.tween_property(flick, "light_energy", 0.0, 0.3)
	fo.tween_callback(flick.queue_free)
	herald.lantern_flare(0.0)
	# a suffocating heat in your chest; the Last Seal in your coat hums; the
	# mark on your collarbone blazes bright white. The Herald stops mid-word.
	var p := w.player.global_position
	SealMark.show_on(w, true)
	SealMark.blaze(w, 1.0, 0.3)
	var blaze := Node3D.new()
	var bg := v.glow_sprite(blaze, Vector3.ZERO, Color(0.9, 0.95, 1.0), 1.6, 2.0)
	var bl := OmniLight3D.new()
	bl.light_color = Color(0.85, 0.9, 1.0)
	bl.light_energy = 6.0
	bl.omni_range = 9.0
	blaze.add_child(bl)
	w.player.add_child(blaze)
	blaze.position = Vector3(0.1, 0.95, 0.15)   # (on their knees)
	_sfx(w, "gift")
	await w.flash(Color(0.9, 0.95, 1.0), 0.05, 0.9)
	w.shake(0.2)
	Cine.shot(w, p + Vector3(5.0, 2.2, -4.0), p + Vector3(-0.5, 0.9, 1.0), 40.0)
	for who in ["bram", "corin", "nell", "tam", "hob", "tilly", "kid", "ned"]:
		await Cine.wait(w, 0.16)
		Cine.look(w, who, p)
	await Cine.wait(w, 1.2)
	# silence; and the featureless hood snaps down onto you
	# (from further off than it was: at two metres the hood filled the
	# screen, its edges cut off, for the whole of its next speech)
	Cine.shot(w, herald.hood_pos() + Vector3(-2.9, -0.55, 2.5), herald.hood_pos() + Vector3(0, -0.35, 0), 34.0)
	await Cine.wait(w, 1.4)
	herald.turn_hood(p + Vector3(0, 1.0, 0))
	_sfx(w, "ward_spring", 0.6)
	w.shake(0.1)
	await Cine.wait(w, 1.6)
	# its grinding voice stutters, as if the old laws are rewriting themselves
	await _herald_say(w, 22, "The Covenant updates. An eighth Seat is forged. The holder of the Last Seal claims this position. Unmarked by any god, until challenged and broken... they are witnessed. I name the Unsworn.")
	# it dissolves into a thick grey mist
	var bt := w.create_tween().set_parallel(true)
	bt.tween_property(bl, "light_energy", 0.0, 1.5)
	bt.tween_property(bg, "scale", Vector3.ONE * 0.05, 1.5)
	SealMark.blaze(w, 0.0, 1.5)
	Cine.shot(w, Vector3(0.5, 1.8, 15.5), HERALD_AT + Vector3(0.0, 1.8, -1.0), 38.0)
	var ft2 := w.create_tween().set_parallel(true)
	ft2.tween_property(herald, "fade", 0.0, 3.0).set_delay(0.3)
	_fade_mist(w, mist, 4.0)
	await Cine.wait(w, 3.4)
	# the silence on the green. Tam looks at the ground. Nell quietly pulls
	# Tilly away. They are stepping away from you, for pure, primal survival.
	# (Bram's hand comes off their shoulder first, and the point it rested on
	# goes as soon as it's off: left alive to the hub's end, with his arm
	# given back, it was one thing more for the walk to trip on)
	_shoulder_leave(shoulder)
	await Cine.wait(w, 0.45)
	if bf is Figure3D:
		(bf as Figure3D).let_go(0.5)
		(bf as Figure3D).palm("left", Vector3.ZERO, 0.5)
	Cine.shot(w, p + Vector3(-1.6, 1.7, 4.8), p + Vector3(0.4, 1.1, -2.0), 40.0)
	var tf = Cine.fig(w, "tam")
	if tf is Figure3D:
		(tf as Figure3D).pose("defeat", 0.3, 0.6)
	await Cine.wait(w, 0.55)
	_free_tracker(shoulder)
	shoulder = null
	# up off their knees, slowly, and back: each away from the player along
	# their own line, one after another, so nobody walks into anybody (1
	# November, Gary: "characters going through each other and items"),
	# each walk finding its way round what's solid and who's standing
	for who in ["bram", "player"]:
		_stand(w, who, 0.6)
	var away := func(who: String, by: float) -> void:
		var b := Cine.body(w, who)
		if b == null:
			return
		_stand(w, who, 0.5)
		await Cine.wait(w, 0.45)
		var d := b.global_position - p
		d.y = 0.0
		var to := Cine.off_blockers(w, b.global_position + d.normalized() * by)
		Cine.path(w, who, [to], 0.9)
	for d in [["corin", 0.0], ["tam", 0.0], ["nell", 1.6], ["tilly", 1.8], ["hob", 1.4], ["ned", 1.4], ["kid", 1.6]]:
		if float(d[1]) > 0.0:
			away.call(String(d[0]), float(d[1]))
		else:
			_stand(w, String(d[0]), 0.6)
		await Cine.wait(w, 0.22)
	await Cine.wait(w, 1.4)
	# Bram steps firmly into the empty space between you and the village: a
	# step out to the side of you first (he stood at your shoulder), then in
	var bp := Cine.body(w, "bram").global_position
	var village_dir := (Cine.body(w, "nell").global_position - p)
	village_dir.y = 0.0
	var between := p + village_dir.normalized() * 1.1
	var aside := p + (bp - p).normalized() * 0.9
	await Cine.path(w, "bram", [aside, between], 1.3)
	Cine.look(w, "bram", Cine.body(w, "nell").global_position)
	Cine.shot(w, p - village_dir.normalized() * 2.6 + village_dir.normalized().cross(Vector3.UP) * 1.2 + Vector3(0, 1.6, 0), between + Vector3(0, 1.3, 0), 38.0)
	await Cine.wait(w, 1.4)
	return {"herald": herald, "mist": mist, "blaze": blaze, "shoulder": shoulder}


## After the Herald (the 3D version or the film): the Hero note, and Bram's
## dawn hub; then the green is put back as it was.
static func _dawn_hub(w: World, left: Dictionary) -> void:
	var p := w.player.global_position
	var tf = Cine.fig(w, "tam")
	await Cine.say(w, "", "[i](You are the Unsworn: bound to no god, +1 to every attribute. See Hero in the menu.)[/i]")
	Game.set_flag("named_unsworn")
	# Bram, at dawn: his hub
	Cine.look(w, "bram", p)
	Cine.look(w, "player", Cine.body(w, "bram").global_position)
	Cine.over_shoulder(w, "player", "bram", 1.0, 30.0)
	await Cine.ask(w, ["What was that thing, Bram?", "Why are they looking at me like that?"], func(q: int) -> void:
		if q == 0:
			await Cine.say(w, "bram", "The Covenant's shadow. The Pale Herald. It's the thing the gods send to enforce the rules they wrote for themselves.")
			await Cine.say(w, "bram", "It doesn't judge, and it doesn't fight. It just records who dies, who owes what, and who holds a Champion's mark.")
		else:
			await Cine.say(w, "bram", "Because a Champion's mark brings duels, armies, and gods to your doorstep. And Ashford doesn't even have a wall.")
			await Cine.say(w, "bram", "They've kept you a secret for twenty years. That silence just ended."), "We can't stay here. I'm putting everyone in danger.")
	await Cine.say(w, "bram", "No. We can't. Come back inside. We have to pack.")
	await Cine.say(w, "bram", "Not in daylight, though. That thing tore through every Ward I've laid on this valley in twenty years. Anything with the Sight could pick you out from the ridge right now.")
	await Cine.say(w, "bram", "I need the day to put them back over the tunnel. We go after dark.")
	await Cine.fade(w, 1.0, 1.2)
	if tf is Figure3D:
		(tf as Figure3D).release(0.0)
	SealMark.show_on(w, false)
	for k in ["herald", "mist", "blaze"]:
		var n = left.get(k)
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	for who in KNEELERS + ["bram", "player"]:
		_stand(w, who, 0.01)
	if left.get("shoulder") != null:
		_free_tracker(left.shoulder)
	_faces.clear()
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


## Kneeling: the 3D cast go down on one knee, heads bowed (Figure3D.kneel
## with `upright`, KNEEL_LEAN how far they bend over it. 8 November, Gary:
## "when it cuts to Bram he is crouched and distorted": until then they held
## the way down of the sit clip, a squat with the back bent, Bram's arm out
## straight from it to the shoulder); a cut-out crouches, squashed down onto
## its feet as far as a kneeling figure would go (sunk into the ground
## instead, it stood waist deep in the grass).
const KNEEL_LEAN := 0.45
const CUTOUT_KNEEL := 0.76


static func _kneel(w: World, who: String, secs := 0.6) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		# (`upright`: at the kneel's right height, the planted foot flat on
		# the grass; without it the knee joint was 2 to 5 cm under the grass
		# and the planted foot's toes 15 to 30 cm, everyone's)
		(f as Figure3D).kneel(secs, KNEEL_LEAN, false, true)
	elif f != null and not (f as Node3D).has_meta("knelt"):
		var n: Node3D = f
		n.set_meta("knelt", true)
		w.create_tween().tween_property(n, "scale:y", CUTOUT_KNEEL, secs)


static func _stand(w: World, who: String, secs := 0.6) -> void:
	var f = Cine.fig(w, who)
	if f is Figure3D:
		(f as Figure3D).release(secs)
	elif f != null and (f as Node3D).has_meta("knelt"):
		var n: Node3D = f
		w.create_tween().tween_property(n, "scale:y", 1.0, maxf(0.01, secs))
		n.remove_meta("knelt")


## A point on top of someone's shoulder for a hand to rest on, that stays
## there as they move and kneel (_free_tracker() lets it go): SHOULDER_TOP
## over the Arm joint, which is the top of the shoulder as Player A's mesh
## has it (10 cm over the joint) plus half a palm's thickness, so the palm's
## skin rests on the shoulder's (8 November, Gary: "When Bram puts his hand
## on player shoulder it goes through it": at 7 cm the middle of the palm was
## 3 cm inside the shoulder); and SHOULDER_BACK back of the joint. `side`
## says which shoulder ("left"/"right"); else the one nearer whoever reaches,
## from `from` (Bram beside the player reaches for the near one); else the
## right. `reacher` (and which of their hands, `hand`) is whose hand rests
## on it: a reach puts the end of the forearm on the point, and the hand
## then turned palm down swings the palm off it by up to a palm's length
## (onto the side of the shoulder, into it); so each frame the middle of
## that palm as drawn (_palm_watch: read as the skeleton finishes its frame,
## since between frames a bone has only the clip's pose, the reach and the
## turn of the hand put on and taken off within the frame; read between
## frames it was the clip's hand at his knee, and the point climbed away
## from the shoulder to its limit) is measured against the point, and the
## point is moved by the difference, until the palm lies on the shoulder;
## never further from the reacher's own shoulder than SHOULDER_REACH of
## their arm, so a shoulder just out of reach doesn't draw the point away
## and the arm out straight after it. The joint is read as drawn too (the
## player's posture tilts the shoulder bones). SHOULDER_OUT: a little out
## from the joint, over the top of the shoulder's ball rather than the slope
## up to the neck (the hand's inner edge went into the slope). The hand
## comes to the point from above and outside it (SHOULDER_FROM, blended in
## there and glided onto the shoulder over SHOULDER_GLIDE seconds: blended
## in straight from his side, it swept up through the player's arm), and
## goes the same way when _shoulder_leave() is called before the hand is
## let go.
const SHOULDER_TOP := 0.12
const SHOULDER_OUT := 0.02
const SHOULDER_BACK := 0.02
const SHOULDER_CORR_MAX := 0.2
const SHOULDER_REACH := 0.96
const SHOULDER_FROM := Vector3(0.14, 0.08, 0.0)   # (out from the body, up)
const SHOULDER_GLIDE := 0.45


## Where the middle of `f`'s palm (`hand` "left"/"right") is drawn each
## frame, under [0] (Vector3.INF until its reach is fully on, or when it's
## off): read as the skeleton finishes its frame, the reach and the hand's
## turn included. _palm_unwatch() stops it.
static func _palm_watch(f: Figure3D, hand: String) -> Array:
	var seen := [Vector3.INF, null, null]
	if f == null or f._skel == null:
		return seen
	var pre := "Right" if hand == "right" else "Left"
	var sk: Skeleton3D = f._skel
	var watch := func() -> void:
		if not is_instance_valid(f) or f._skel == null:
			return
		var ik = f._ik.get(hand)
		if ik != null and is_instance_valid(ik) and (ik as TwoBoneIK3D).active and (ik as TwoBoneIK3D).influence > 0.95:
			seen[0] = f._palm_point(pre)
		else:
			seen[0] = Vector3.INF
	sk.skeleton_updated.connect(watch)
	seen[1] = sk
	seen[2] = watch
	return seen


static func _palm_unwatch(seen: Array) -> void:
	if seen.size() > 2 and seen[1] is Skeleton3D and is_instance_valid(seen[1]) and seen[2] is Callable:
		var sk: Skeleton3D = seen[1]
		if sk.skeleton_updated.is_connected(seen[2]):
			sk.skeleton_updated.disconnect(seen[2])
	seen[0] = Vector3.INF


static func _shoulder_point(w: World, who: String, from := Vector3.INF, side := "", reacher := "", hand := "right") -> Node3D:
	var n := Node3D.new()
	w.add_child(n)
	var f = Cine.fig(w, who)
	var b := Cine.body(w, who)
	var rf = Cine.fig(w, reacher) if reacher != "" else null
	var bone := "RightArm"
	if side != "":
		bone = "LeftArm" if side == "left" else "RightArm"
	elif f is Figure3D and from != Vector3.INF:
		var fl := (f as Figure3D).bone_pos("LeftArm")
		var fr := (f as Figure3D).bone_pos("RightArm")
		if Vector2(fl.x - from.x, fl.z - from.z).length() < Vector2(fr.x - from.x, fr.z - from.z).length():
			bone = "LeftArm"
	# the joint as drawn (read as the skeleton finishes its frame)
	var joint := [Vector3.INF]
	var joint_watch = null
	if f is Figure3D and (f as Figure3D)._skel != null:
		var sk: Skeleton3D = (f as Figure3D)._skel
		var bi := sk.find_bone(bone)
		if bi >= 0:
			joint_watch = func() -> void:
				if is_instance_valid(sk):
					joint[0] = sk.global_transform * sk.get_bone_global_pose(bi).origin
			sk.skeleton_updated.connect(joint_watch)
	# and the reacher's palm as drawn
	var seen: Array = _palm_watch(rf as Figure3D, hand) if rf is Figure3D else [Vector3.INF]
	var corr := [Vector3.ZERO]
	var away := [1.0]   # how far the point still stands off the shoulder (1: SHOULDER_FROM; 0: on it)
	var track := func() -> void:
		while is_instance_valid(n) and is_instance_valid(b):
			var want: Vector3
			var out := Vector3.ZERO
			if f is Figure3D:
				var fwd: Vector3 = (f as Figure3D).facing()
				var at: Vector3 = joint[0] if joint[0] != Vector3.INF else (f as Figure3D).bone_pos(bone)
				out = at - b.global_position
				out.y = 0.0
				out = out.normalized() if out.length() > 0.01 else Vector3.ZERO
				want = at + Vector3(0, SHOULDER_TOP, 0) + out * SHOULDER_OUT - fwd * SHOULDER_BACK
			else:
				want = b.global_position + Vector3(0, 1.45, 0)
			var dt := w.get_process_delta_time()
			if n.has_meta("leave"):
				away[0] = move_toward(away[0], 1.0, dt / SHOULDER_GLIDE)
			elif seen[0] != Vector3.INF:
				away[0] = move_toward(away[0], 0.0, dt / SHOULDER_GLIDE)
			var off: Vector3 = (out * SHOULDER_FROM.x + Vector3.UP * SHOULDER_FROM.y) * (0.5 - 0.5 * cos(away[0] * PI))
			if seen[0] != Vector3.INF and away[0] < 0.001:
				corr[0] = ((corr[0] as Vector3) + (want - (seen[0] as Vector3)) * 0.7).limit_length(SHOULDER_CORR_MAX)
			elif rf != null and seen[0] == Vector3.INF:
				corr[0] = (corr[0] as Vector3).lerp(Vector3.ZERO, 0.2)
			var at_p: Vector3 = want + corr[0] + off
			if rf is Figure3D and is_instance_valid(rf):
				var sh: Vector3 = (rf as Figure3D).bone_pos(("Right" if hand == "right" else "Left") + "Arm")
				var most: float = (rf as Figure3D).arm_reach() * SHOULDER_REACH
				if at_p.distance_to(sh) > most:
					at_p = sh + (at_p - sh).normalized() * most
			n.global_position = at_p
			await w.get_tree().process_frame
		if joint_watch is Callable and f is Figure3D and is_instance_valid(f) and (f as Figure3D)._skel != null:
			var sk2: Skeleton3D = (f as Figure3D)._skel
			if sk2.skeleton_updated.is_connected(joint_watch):
				sk2.skeleton_updated.disconnect(joint_watch)
		_palm_unwatch(seen)
	track.call()
	return n


static func _free_tracker(n: Node3D) -> void:
	if is_instance_valid(n):
		n.queue_free()


## The hand is about to come off the shoulder: the point glides back up and
## out to where the hand came from (SHOULDER_FROM, SHOULDER_GLIDE seconds),
## the hand with it, so the arm goes back to its clip from clear of the
## body. Wait that long, then let go.
static func _shoulder_leave(n: Node3D) -> void:
	if is_instance_valid(n):
		n.set_meta("leave", true)


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
	await Cine.say(w, "herald", text, hold, hold > 0.0)


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
	m.shader = vision_shader()
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


## One shader for all the visions (each its own copy would be compiled again,
## a stall on a phone as each face comes up).
static var _vision_sh: Shader = null


static func vision_shader() -> Shader:
	if _vision_sh == null:
		_vision_sh = Shader.new()
		_vision_sh.code = VISION_SHADER
	return _vision_sh


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


## The Champions' pictures, held from the dawn's warm-up to its hub's end
## (loaded once, in the black, not one by one as the lantern shows them).
static var _faces: Array = []


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


## The Herald's road down to its mark, on the ground.
static func _herald_road(v: AshfordVillage) -> Array:
	var road: Array = []
	for rp in HERALD_ROAD:
		var q: Vector3 = rp
		q.y = v.height(q.x, q.z)
		road.append(q)
	return road


## The Herald on its road at the far end, faded right out, with its bank of
## mist (under its meta "mist"): built here, or taken from the warm-up
## (_warm_herald) when that made one.
static func _herald_ready(w: World) -> PaleHerald:
	var v := village(w)
	var herald: PaleHerald = null
	if w.has_meta("herald_warm"):
		var hw = w.get_meta("herald_warm")
		if hw is PaleHerald and is_instance_valid(hw) and (hw as Node).is_inside_tree():
			herald = hw
		w.remove_meta("herald_warm")
	if herald == null:
		herald = PaleHerald.new()
		herald.name = "PaleHerald"
		herald.form = "shroud"
		w.add_child(herald)
	var road := _herald_road(v)
	herald.global_position = road[1]
	herald.snap_dir((road[2] as Vector3) - (road[1] as Vector3))
	herald.fade = 0.0
	if not herald.has_meta("mist") or not is_instance_valid(herald.get_meta("mist")):
		herald.set_meta("mist", _mist_bank(v, herald))
	return herald


## Everything the Herald's coming draws for the first time, built and drawn
## while the screen is black at the start of the dawn (8 November, Gary:
## "Dawn, after Hob's line, it takes a while to load": the Herald was built
## after his line, and its burial cloth's shader, its mist's, its bank of
## mist's and the visions' were compiled on the frame each was first drawn,
## which held the picture for seconds the first time on a Mac). The Herald
## stands on its road at fade 0 (not a pixel of it drawn) under the world's
## "herald_warm" for _herald_ready to take; a vision with every Champion's
## name under it is shown to the camera a moment and taken away; the
## Champions' pictures are loaded and kept (_champion_tex). Done only when the
## 3D Herald is to play (Gary's film has nothing to warm).
static func _warm_herald(w: World) -> void:
	var herald := _herald_ready(w)
	w.set_meta("herald_warm", herald)
	_faces.clear()
	for i in CHAMPIONS.size():
		_faces.append(_champion_tex(i))   # (held, so the loads aren't done again at the lantern)
	var road := _herald_road(village(w))
	Cine.shot(w, Vector3(4.6, 1.75, 12.4), (road[1] as Vector3) + Vector3(0, 2.0, 0), 30.0)
	var vis := _vision(w, herald, -1, 0.01)
	var names := Label3D.new()
	var all := PackedStringArray()
	for c in CHAMPIONS:
		all.append(String(c[2]))
	names.text = " ".join(all)
	names.font = CardFace.font("display")
	names.font_size = 72
	names.pixel_size = 0.0028
	names.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	names.no_depth_test = true
	names.outline_size = 10
	names.modulate = Color(0.86, 0.9, 1.0, 0.01)
	names.outline_modulate = Color(0.0, 0.02, 0.06, 0.01)
	names.position = Vector3(0, -1.12, 0)
	vis.add_child(names)
	for k in 3:
		if not is_instance_valid(w) or not w.is_inside_tree():
			return
		await w.get_tree().process_frame
	_vision_out(w, vis, 0.01)


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
## Where Krell sits her horse: in front of Tilly's red stall (until 24
## October she stood in it, behind its counter).
const KRELL_AT := Vector3(5.4, 0, 7.8)
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
			# his own fall, backwards (not his standing pose tipped over stiff)
			(tf as Figure3D).let_go(0.05)
			_tam_down(tf as Figure3D, 0.15)
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
			_tam_down(tf as Figure3D, 0.0)   # (the camera's on Nell: he's down when it comes back)
		_drop_cap(w, cap, fall_at + Vector3(0.5, 0.0, 0.6))
	Cine.place(w, "hound1", KRELL_AT + Vector3(-1.2, 0, 1.0), tam_at)
	await Cine.wait(w, 1.8)
	# back: he is still, his cap where he fell (no blood: v7)
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


## Tam goes down, on his back: his own death clip, played (or, with blend 0,
## already over: the camera was away), and held there; tipped over flat if a
## model hasn't got one.
static func _tam_down(f: Figure3D, blend: float) -> void:
	if f.anim != null and f.anim.has_animation("death"):
		if blend > 0.0:
			f.hold("death", 1.3, maxf(blend, 0.35))
		else:
			f.pose("death", 1.0, 0.01)
	else:
		f.lie_down(0.35 if blend > 0.0 else 0.01, true)


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
