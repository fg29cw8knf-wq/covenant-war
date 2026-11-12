class_name StoryFilm
extends CanvasLayer
## A story film: one of Gary's own films, played in place of the engine's 3D
## staging of the same stretch of a scene, as the finished opening movie
## replaced its shot-by-shot version (Gary, 23 October: "the cut scene after
## all the lanterns go up: can we make a proper movie from that like we did
## for the opening movie?"; 24 October: the cutscenes as videos built round
## one hero, Player A). Master Script v7 has seven (the Still to Make doc,
## the "Films for Player A" tab): midnight, white_light, herald, reckoning,
## tams_hand, no_roof and ridge; and since 8 November white_sky_duel, Bram's
## duel in the Night of the White Sky (since 12 November that duel is played,
## with white_sky_move_1 to _3 as the three moves' own shots, and the whole
## film is Bram's watch on the Thornwood road). Conversations,
## choices and the things the player does (the cart, the tunnel, the look
## back) stay in the game between them.
##
## A film plays, best first:
##   1. Gary's 4K film, `<film>_4k.mp4`, through the device's own player
##      (NativeVideoPlayer in the iPhone and Mac apps, the film loose in the
##      bundle from the films release; on the phone link the browser's own,
##      streaming films/<film>/ beside the page: WebVideoPlayer), as the
##      opening does. Its lines go over it as the player's own subtitles.
##   2. The whole cut as Ogg Theora, res://assets/movies/<film>.ogv.
##   3. Its shots one by one: each shot's clip res://assets/movies/<film>/<id>.ogv
##      (tools/movie_clips.py --film <film> makes them from Gary's clips), or
##      its painting res://assets/art/movie/<film>/<id>.png (.jpg), or, while
##      neither exists, an animatic card saying what the shot is.
## The engine's 3D scene stays the fallback: a film is only used once it's
## there (available()), or when "--story-films" is on the command line (the
## animatic, to check a scene runs with its films).
##
## A film is a list of steps (FILMS):
##   {"id": "mid_01", "len": 8.0, "see": "...", "lines": [{"at": 0.5, "who": "", "say": "..."}]}
##       a shot, `len` seconds of the film; "see" says what's in it (Gary's
##       brief, and the animatic's card), "player": true when Player A is in
##       it. Its lines are the game's subtitles, each `at` seconds into the
##       shot; a line with "vo" plays that recording (assets/audio/vo/, the
##       Herald's lines), any other its own if VoiceLines has one; "if":
##       [flag, pick] shows it only after that pick; "hold" keeps it up that long.
##   {"choice": [...], "flag": "..."}   the player's choice: the film pauses
##       (the 4K film steps aside for the game's buttons, over black); the
##       pick (0, 1, ...) is kept in that story flag
##   {"name": "<the question>"}          the name prompt (Game.player_name)
##   {"caption": "Dawn"}                 a caption over the picture
##   {"music": ["dawn_after"]}           music from here (Music.play); "stop" ends it
##   {"stinger": "the_marking"}          a stinger (Music.stinger)
## The 4K film and the whole cut have their own music and captions: those
## steps are for the shots alone. The shot lengths say where each shot starts
## in a whole film, so its lines come at their moments: when Gary's film is
## in, its shot lengths here are set to match it.
##
## A film Gary made in pieces is a list of parts instead of steps (5
## November, midnight: the film to the player's choice, then Bram's answer
## to the pick, then the rest):
##   {"file": "midnight_1", "steps": [...]}   a piece of film and its shots,
##       played best first as a whole film is: <file>_4k.mp4 through the
##       device's player, else assets/movies/<file>.ogv, else its shots;
##       "voiced": its own voices are in the film (no recordings over it)
##   {"file": {0: "midnight_2a", 1: "midnight_2b"}, "by": "mid_choice"}
##       one piece for each pick of that choice; "keep_music": the game's
##       music (the choice's) plays on under it, at the same place
##   {"file": "midnight_3", "optional": true}   not made yet: until it's
##       there the film stops before it ("stopped_at" in what play() returns),
##       holding its last frame, and the scene carries on in its 3D from
##       there and lets the film go (let_go)
##   {"choice": [...], "flag": "...", "hold": "midnight_choice", "music": "midnight_choice"}
##       the choice between pieces: the last frame held (the picture
##       assets/art/movie/<film>/<hold>.jpg) under the game's buttons, and the
##       menu music (Music: assets/audio/music/<music>.ogg) from the moment
##       the piece before ends, looping until the pick
## A piece after the first never shows black while it loads: the held frame
## stays up until its first picture is there, then it cuts straight in.

signal finished

## What each film replaces, and what the scene around it still does, is in
## the scene's own script: midnight, white_light and herald in
## scripts/world/areas/ashford.gd (_midnight_film, _white_light_film,
## _herald_film), reckoning, tams_hand and no_roof in
## scripts/world/areas/ashford_night.gd, ridge in
## scripts/world/areas/thornwood.gd, white_sky_duel in
## scripts/world/thornwood_shelter.gd (after_lesson) and white_sky_move_1 to
## _3 in scripts/story/white_sky.gd (_move_film). The lines are the 3D scene's own, word
## for word; Master Script v7 (docs/script/v7_prologue.md) has them in order.
const FILMS := {
	# (5 November: Gary's film comes in parts, cut at the player's choice.
	# Part 1 runs from the bell to Bram's "Wonder who'll be sitting up there
	# tomorrow." (34.08 s); its last frame is held under the game's buttons
	# while the menu music, his soundtrack's own continuation, loops; 2A or 2B
	# is Bram's answer to the pick (3.42 s, voice and ambience only, the
	# music carrying on under it); part 3, the lanterns to the cart, isn't
	# made yet, and until it is the game's 3D takes over at the lanterns
	# going up (Ashford._midnight_3d from "lanterns"). The shot lengths are
	# the real film's, its cuts found frame by frame; each line is set where
	# it's spoken.)
	"midnight": {
		"title": "Midnight",
		"parts": [
			{"file": "midnight_1", "voiced": true, "steps": [
				{"id": "mid_01", "len": 4.5, "see": "Midnight on the packed green, every face turned up to the unlit Great Lantern; the chapel tower, its bell swinging.",
					"lines": [{"at": 0.6, "who": "", "say": "Midnight. The chapel bell counts twelve, and all of Ashford counts with it."}]},
				{"id": "mid_02", "len": 5.5, "player": true, "see": "From behind: he climbs the Lantern's steps with a lit taper and touches it to the wick. The Great Lantern burns with a rich, golden flame, and the whole green roars."},
				{"id": "mid_03", "len": 3.5, "see": "Little Tilly steps back from the Lantern, her face glowing gold. Behind her, Tam dances with Nell, badly; Ned's fiddle."},
				{"id": "mid_04", "len": 4.583, "player": true, "see": "Corin beside him, both of them watching the crowd; he says it without looking over.",
					"lines": [{"at": 0.5, "who": "corin", "say": "It's a good village, this. Don't tell anyone I said so.", "hold": 3.7}]},
				{"id": "mid_05", "len": 7.542, "see": "Bram, looking up at the paper lanterns being readied, their candles lit one by one.",
					"lines": [{"at": 0.5, "who": "bram", "say": "Folk think we send them up for the gods. We don't. A lantern's for whoever's out in the dark, so they know which way is home.", "hold": 7.1}]},
				{"id": "mid_06", "len": 8.458, "see": "Bram's face, the Lantern behind him, his eyes going up to the stars.",
					"lines": [{"at": 1.9, "who": "bram", "say": "Two thousand years. Wonder who'll be sitting up there tomorrow.", "hold": 6.3}]},
			]},
			{"choice": ["Does it matter to us?", "Whoever it is owes us a better year."], "flag": "mid_choice",
				"hold": "midnight_choice", "music": "midnight_choice"},
			{"file": {0: "midnight_2a", 1: "midnight_2b"}, "by": "mid_choice", "voiced": true, "keep_music": true, "steps": [
				{"id": "mid_07", "len": 3.417, "see": "Bram, close, the ghost of a laugh.",
					"lines": [{"at": 0.6, "who": "bram", "say": "It shouldn't. It always seems to.", "if": ["mid_choice", 0], "hold": 2.7},
						{"at": 0.9, "who": "bram", "say": "Write and tell them. See who writes back.", "if": ["mid_choice", 1], "hold": 2.4}]},
			]},
			{"file": "midnight_3", "optional": true, "steps": [
				{"music": "stop"},
				{"id": "mid_08", "len": 10.0, "player": true, "see": "Hundreds of paper lanterns rise over Ashford. Then the wind simply stops. Every lantern freezes mid-air; the fiddle trails off; the village goes dead silent, every face turned up, his among them."},
				{"id": "mid_09", "len": 5.0, "see": "Corin, looking up, then at Bram.",
					"lines": [{"at": 0.4, "who": "corin", "say": "Bram. Is it meant to do that?"}]},
				{"music": ["sigilfall"]},
				{"id": "mid_10", "len": 8.0, "see": "With a deafening, glass-shattering crack the sky tears open. A blinding white light bleeds down from the Empyrean, and the midnight green goes as stark and pale as bone. For a breath the children cheer."},
				{"id": "mid_11", "len": 6.0, "see": "The first strike lands in the top field. The earth bucks; the shockwave shatters the merchant carts lining the green.",
					"lines": [{"at": 3.4, "who": "", "say": "[i]Screams finally break the silence.[/i]", "hold": 2.2}]},
				{"id": "mid_12", "len": 4.0, "see": "Bram, shouting over the noise, pointing him at the inn.",
					"lines": [{"at": 0.3, "who": "bram", "say": "Inside! Everyone inside! Sprout, the inn. Now!", "hold": 2.6}]},
				{"id": "mid_13", "len": 8.0, "player": true, "see": "Everyone runs for their doors. Corin grabs Tilly's hand and runs her up the lane past Tam's cart. He runs for the inn (from behind); strikes land all round him, and one knocks him flat."},
				{"id": "mid_14", "len": 6.0, "see": "A blast on the far side of the cart throws it over onto Corin; an iron-banded wheel pins him in the mud. Tilly screams.",
					"lines": [{"at": 2.4, "who": "tilly", "say": "Corin! CORIN!", "hold": 1.8}]},
				{"id": "mid_15", "len": 4.0, "player": true, "see": "He gets up in the dust and falling debris, sees Corin under the wheel, and turns back. (The game takes over: Find Corin, and the cart.)"},
			]},
		],
	},
	"white_light": {
		"title": "The White Light",
		"steps": [
			{"stinger": "the_marking"},
			{"id": "wl_01", "len": 9.0, "see": "By the cart, one light falls differently: white, slow, silent. Time slows. It passes Bram across the green. It passes Corin."},
			{"id": "wl_02", "len": 6.0, "player": true, "see": "His open palm, and the white streak settling into it: a card with nothing on it. Every other light in the sky goes out at once."},
			{"id": "wl_03", "len": 4.0, "player": true, "see": "Close: under his collarbone the ash-grey broken seal he has hidden all his life blazes with white fire. He doubles over."},
			{"id": "wl_04", "len": 7.0, "see": "Corin, staring at the card, then down at his own empty hand.",
				"lines": [{"at": 0.4, "who": "corin", "say": "It came to you."}, {"at": 3.6, "who": "corin", "say": "It just came to you."}]},
			{"id": "wl_05", "len": 7.0, "player": true, "see": "Bram shoves through the screaming crowd, his face pale with terror, throws his heavy wool coat over him and closes his fingers over the card.",
				"lines": [{"at": 3.4, "who": "bram", "say": "Close your fist. Don't look at it. Hide it. Now."}]},
			{"id": "wl_06", "len": 5.0, "player": true, "see": "The card's glow dies between their hands. His vision swims, and he goes down into the mud. Black."},
		],
	},
	"herald": {
		"title": "The Pale Herald",
		"steps": [
			{"music": ["dawn_after"]},
			{"id": "her_01", "len": 8.0, "see": "Dawn over Ashford: frost on the green, burnt-out paper lanterns lying everywhere like dead moths, the merchant carts in pieces."},
			{"id": "her_02", "len": 6.0, "see": "Tilly and a small boy picking fallen Sparks out of the furrows, squabbling over them like conkers."},
			{"id": "her_03", "len": 7.0, "see": "Hob with a fan of glowing cards in his big hands, showing Bram.",
				"lines": [{"at": 0.5, "who": "hob", "say": "Lost half the barley. Found nine cards in the cabbages. Can't tell if that's a good trade."}]},
			{"id": "her_04", "len": 6.0, "see": "The temperature drops. No sound of arrival: it is simply there, hovering inches above the crushed grass, a towering, shifting mass of grey burial cloth and rusted iron chains. The village draws back into a wide, terrified ring."},
			{"id": "her_05", "len": 6.0, "player": true, "see": "Bram's hand comes down on his shoulder (from behind the pair).",
				"lines": [{"at": 1.4, "who": "bram", "say": "A Pale Herald. Morrowen's own. Head down. Hand in your pocket."}]},
			{"id": "her_06", "len": 16.0, "see": "The Herald's empty hood; the pale light in its mist on Ashford's frightened faces.",
				"lines": [{"at": 0.3, "who": "herald", "say": "The Age is turned. The Turning year begins. I am the witness. I record the current holders of the seven Dominion Seats, subject to open challenge. Let the blood of the contenders be counted.", "vo": "herald_21"}]},
			{"id": "her_07", "len": 6.0, "see": "In its mist, a knight kneeling in a sun chapel (Ser Aldric Vane).",
				"lines": [{"at": 0.3, "who": "herald", "say": "Solhaven, for Solmaris: Ser Aldric Vane.", "vo": "herald_03"}]},
			{"id": "her_08", "len": 6.0, "player": true, "see": "A grey scholar's face in the mist (Magister Tobias Crane); at the name, Bram's hand tightens on his shoulder.",
				"lines": [{"at": 0.3, "who": "herald", "say": "Glyphmere, for Aldrith: Magister Tobias Crane.", "vo": "herald_09"}]},
			{"id": "her_09", "len": 5.0, "see": "Five more faces in the mist, too quick to hold: a scarred warlord, a young king on an ice throne, a grinning captain, a silk mask in the dark, a blindfolded priestess. The camera stays on Ashford's faces."},
			{"id": "her_10", "len": 6.0, "player": true, "see": "A suffocating heat in his chest: the mark on his collarbone blazes bright white through his shirt. Every head turns. The Herald stops mid-word, and its hood snaps down onto him."},
			{"id": "her_11", "len": 17.0, "see": "The hood, facing him; its grinding voice stutters, as if the old laws are rewriting themselves.",
				"lines": [{"at": 0.3, "who": "herald", "say": "The Covenant updates. An eighth Seat is forged. The holder of the Last Seal claims this position. Unmarked by any god, until challenged and broken... they are witnessed. I name the Unsworn.", "vo": "herald_22"}]},
			{"id": "her_12", "len": 5.0, "see": "It dissolves into a thick grey mist, and the mist goes."},
			{"id": "her_13", "len": 7.0, "player": true, "see": "The silence on the green. Tam looks at the ground. Nell quietly pulls Tilly away; the villagers step back from him. Bram steps firmly into the empty space between him and the village. (The game takes over: the Hero note, and Bram.)"},
		],
	},
	"reckoning": {
		"title": "The Reckoning",
		"steps": [
			{"music": ["ashford_burns"]},
			{"id": "rk_01", "len": 8.0, "see": "Dusk on the green. Hoofbeats: Huntmaster Krell rides in on a heavy warhorse, her bailiffs behind her with torches, a hound of shadow at her stirrup."},
			{"id": "rk_02", "len": 17.0, "see": "Krell in the saddle, a ledger open in her hand, reading the terms to the gathered village.",
				"lines": [{"at": 0.4, "who": "krell", "say": "Good evening. I hold the foreclosure notes for twenty-two properties in this valley."},
					{"at": 5.0, "who": "krell", "say": "By the authority of Caldus Morne and the House of Ironvault, the terms are as follows. Every roof but the inn's is forfeit tonight."},
					{"at": 11.0, "who": "krell", "say": "Alternatively, you may surrender one card, the white one, and the notes are burned. I will wait five minutes."}]},
			# (3 November, Gary: the gate and the crowns, kept back from the
			# Night of the White Sky for this moment: "every roof but the inn's")
			{"id": "rk_02b", "len": 8.0, "see": "A flash of white, then twenty years ago: Ashford's gate at dawn, snow on the ground. Bram, never his face, snow on his heavy coat and a baby asleep inside it, sets a heavy purse on a trestle. Aurex Morne's clerk counts out four thousand gold crowns, stacks them, and seals a single page. A flash of white, back to Krell.",
				"lines": [{"at": 4.6, "who": "clerk", "say": "Four thousand crowns. Paid in full, and sealed."}]},
			{"music": "stop"},
			{"id": "rk_03", "len": 4.0, "see": "Nobody speaks. The silence stretches across the frightened faces, Nell's among them."},
			{"id": "rk_04", "len": 12.0, "see": "Tam steps forward, between her horse and the path up to the inn, and slaps his note down on a rain barrel.",
				"lines": [{"at": 2.0, "who": "tam", "say": "The note says midnight. Take the mill, Huntmaster. It's yours. But you leave the people out of this."},
					{"at": 7.4, "who": "tam", "say": "The one you're looking for, the Unsworn, they fled over the northern ridge hours ago."}]},
			{"id": "rk_05", "len": 15.0, "see": "Krell looks down at the note, then at Tam, and leans from the saddle with a cold, almost sympathetic smile, her eyes on where he's planted his boots.",
				"lines": [{"at": 1.6, "who": "krell", "say": "A brave lie, Miller. But you're a terrible card player."},
					{"at": 5.4, "who": "krell", "say": "You put your body between my hounds and the inn before you even opened your mouth."},
					{"at": 9.6, "who": "krell", "say": "Guards, search every building. Collect every note. If they don't have the coin, take the property."}]},
			{"id": "rk_06", "len": 6.0, "see": "Tam reaches into his coat: not for another note. A worn deck. The crowd gasps.",
				"lines": [{"at": 1.2, "who": "tam", "say": "I challenge the debt, Huntmaster! Under the Covenant, you cannot refuse a drawn hand."}]},
			{"id": "rk_07", "len": 11.0, "see": "Krell, unhurried, closing her ledger. (The game takes over: the cellar.)",
				"lines": [{"at": 0.3, "who": "krell", "say": "Fair enough, Miller. The law states I cannot refuse a duel. But if you wish to go ahead with this, I have the right to set the stakes."},
					{"at": 6.0, "who": "krell", "say": "And to deter anyone else from trying it... we fight to the death. Draw your Essence."}]},
		],
	},
	"tams_hand": {
		"title": "Tam's Hand",
		"steps": [
			{"music": ["sigilfall"]},
			{"id": "th_01", "len": 6.0, "see": "The duelling Circle glows gold on the green between them. Tam calls his River Hound out of its card, blue and shining, as she was in your friendly game; Krell's hound of shadow waits."},
			{"id": "th_02", "len": 4.0, "see": "The shadow hound tears through the River Hound, and she bursts into blue light."},
			{"id": "th_03", "len": 5.0, "see": "The feedback shatters Tam's Ward. He clutches his chest and goes down, his life drawn out of him by the duel. No blood."},
			{"id": "th_04", "len": 5.0, "see": "Nell screams, and drops to her knees.",
				"lines": [{"at": 0.6, "who": "nell", "say": "Tam!", "hold": 2.0}]},
			{"music": "stop"},
			{"id": "th_05", "len": 13.0, "see": "Krell, giving her orders without looking at him.",
				"lines": [{"at": 0.4, "who": "krell", "say": "The debt is settled. Search every building. Start with the inn. Keep the houses intact; they're worth more standing."},
					{"at": 7.0, "who": "krell", "say": "If anyone interferes, subdue them. I want the white card, not a heap of ashes."}]},
		],
	},
	"no_roof": {
		"title": "No Roof Burns",
		"steps": [
			{"id": "nr_01", "len": 12.0, "see": "From a distant ridge, the moonlit green: two enforcers draw cards. One summons a controlled line of fire that stops the villagers passing and touches no house; the other binds a resisting villager in glowing strands and forces them to their knees. Behind them, soldiers search the houses."},
		],
	},
	# (8 November, Gary: "Can we make the battle more movie like or give me
	# images and prompt and I'll make it a movie": Bram's duel in the Night of
	# the White Sky, WhiteSky._duel, as his own film. It opens from the white
	# of the hunter's cards and ends on the white of the book opening, which
	# the game takes to black for Morrowen's last line. No lines over it;
	# Bram's face never seen; nobody sees who won. Each shot is a beat of the
	# duel as two computers played it then, in its order, the reference stills
	# Claude rendered of each beat sent with the brief. 12 November: the duel
	# in the snow is played now, in three moves, so this film isn't shown
	# there any more: it plays whole on the Thornwood road, Bram awake by the
	# door after his lesson (ThornwoodShelter.after_lesson), and the snow
	# has white_sky_move_1 to _3 below.)
	"white_sky_duel": {
		"title": "The Night of the White Sky: Bram's Duel",
		"steps": [
			{"id": "wsd_01", "len": 4.5, "see": "Out of the white: the Circle in the Shardlands, a ring of trampled snow among towering crystals of blue ice, the torn sky white overhead, snow driving across it. From high behind him: Bram, the child a bulge in his coat under his left arm, cards in his right hand; across the Circle the hunter, seven and a half feet tall, its hood empty; between them, on his side the Scrivener and the Loomwarden, on its side the pack, a Blazehound, the Infernal Warg and a Veilfox, made of pale smoke and Sigil light."},
			{"id": "wsd_02", "len": 3.5, "see": "The hunter, close, on a long lens from Bram's side of the Circle: one long grey hand turns over a card of white light."},
			{"id": "wsd_03", "len": 4.0, "see": "The Scrivener, Bram's: a tall faceless scribe in parchment robes, its quill of starlight raised. A black sigil of doom closes round it like a noose of ink, and it looks up from its writing."},
			{"id": "wsd_04", "len": 3.5, "see": "Bram from behind, his right hand up with a card: the Unspent Hour, a winged hourglass of glass and starlit sand, darts out of the light over his shoulder."},
			{"id": "wsd_05", "len": 4.0, "see": "The Unspent Hour turns its glass on the Infernal Warg, the biggest of the pack, and the Warg reels; but a trap springs in the snow under it and a green mist of poison clings to its glass."},
			{"id": "wsd_06", "len": 4.0, "see": "The Scrivener writes a line of silver script in the air at the Blazehound, and the Loomwarden, a many-armed weaver of grey thread inside a loom of bone-white wood, pulls its silver threads taut through it: the hound bursts into smoke."},
			{"id": "wsd_07", "len": 2.5, "see": "Where it stood, a River Hound of white smoke comes up out of the snow."},
			{"id": "wsd_08", "len": 4.5, "see": "The pack turns on the Scrivener: the Veilfox's mirage, the Warg's charge of pale fire, the River Hound's bite; steam bursts off it, and it staggers, blinded."},
			{"id": "wsd_09", "len": 3.5, "see": "The hunter's hand lifts to call more of its kin; Bram's face-down Ward flips over at his feet and lines of silver script close over the hunter's card. It comes to nothing."},
			{"id": "wsd_10", "len": 4.0, "see": "The Unspent Hour and the Loomwarden break the Infernal Warg: it bursts into smoke and white sparks. A Shieldhound rises in its place."},
			{"id": "wsd_11", "len": 4.0, "see": "The River Hound's bite takes the Scrivener: it comes apart into pages that blow away on the wind, and the blow carries on into Bram. Over his shoulder: he staggers, his arm going round the child in his coat."},
			{"id": "wsd_12", "len": 3.0, "see": "The hounds drag the Unspent Hour down; its glass cracks and its sand pours out."},
			{"id": "wsd_13", "len": 4.5, "see": "The Weft Serpent rises out of the snow into the gap, a vast serpent woven of grey and silver thread, rearing over the pack; the Glyph Warden takes the other gap, runes lighting across it."},
			{"id": "wsd_14", "len": 3.5, "see": "Wide, high over Bram's back: the hunter's poison mist rolls over his side of the Circle and his Totems sicken in it. The Circle nearly lost."},
			{"id": "wsd_15", "len": 6.0, "see": "The Last Page: the sky over the Circle goes still, the stars draw together into a closed book, and Orlanthe comes down out of it, a hooded figure the size of a hill in robes of folded parchment, faceless, the book in one hand. Low behind Bram, up past the hunter at it."},
			{"id": "wsd_16", "len": 4.0, "see": "The clasp comes undone. The book opens, and white light pours out of it over the Circle, the pack and the hunter, until there is nothing but white. (End on the white: the game takes it to black.)"},
		],
	},
	# (12 November, Gary: "Your film's shots as the payoff after each of the
	# player's three moves, with the full film shown later once they know the
	# rules.") Bram's duel is played now: three moves, each waited for
	# (WhiteSky._ask_move). These are his film's shots for each, cut as three
	# short films that play over the duel as it plays the move out
	# (WhiteSky._move_film), each used once it's there:
	# white_sky_move_1_4k.mp4 and so on, or assets/movies/white_sky_move_1.ogv,
	# or a clip or painting for each shot. No lines over them; Bram's face
	# never seen. The whole film, white_sky_duel above, plays on the Thornwood
	# road, the night of Bram's lesson (Thornwood: his watch at the door).
	"white_sky_move_1": {
		"title": "Bram's Duel: the Unspent Hour",
		"steps": [
			{"id": "wsm_1a", "len": 3.5, "see": "Bram from behind, the child a bulge in his coat under his left arm, his right hand up with a card: the Unspent Hour, a winged hourglass of glass and starlit sand, darts out of the light over his shoulder into the gap where the Scrivener stood."},
		],
	},
	"white_sky_move_2": {
		"title": "Bram's Duel: the glass turned",
		"steps": [
			{"id": "wsm_2a", "len": 4.0, "see": "The Unspent Hour turns its glass on the Blazehound across from it: the sand runs upward, and the hound of pale smoke bursts into white sparks."},
			{"id": "wsm_2b", "len": 4.5, "see": "The pack's answer: the Veilfox's mirage and the Infernal Warg's charge of pale fire bring the Loomwarden down, its threads snapping. Over Bram's shoulder: he staggers, his arm going round the child in his coat."},
		],
	},
	"white_sky_move_3": {
		"title": "Bram's Duel: the Last Page",
		"steps": [
			{"id": "wsm_3a", "len": 6.0, "see": "The Last Page: the sky over the Circle goes still, the stars draw together into a closed book, and Orlanthe comes down out of it, a hooded figure the size of a hill in robes of folded parchment, faceless, the book in one hand. Low behind Bram, up past the hunter at it."},
			{"id": "wsm_3b", "len": 4.0, "see": "The clasp comes undone. The book opens, and white light pours out of it over the Circle, the pack and the hunter, until there is nothing but white. (End on the white: the game takes it to black.)"},
		],
	},
	"ridge": {
		"title": "Solhaven",
		"steps": [
			{"music": ["solhaven_dawn", "menu_theme"]},
			{"id": "sol_01", "len": 7.0, "player": true, "see": "From behind him and Bram: they crest the Thornwood's last ridge at dawn; the plains below, and far off Solhaven's white towers, catching the first sun in Solmaris's light."},
			{"id": "sol_02", "len": 6.0, "see": "Bram, turning to him.",
				"lines": [{"at": 0.3, "who": "bram", "say": "Go through Dask's cards when we stop. Swap in what's nastier than what you've got. That's most of duelling."}]},
			{"id": "sol_03", "len": 5.0, "see": "Solhaven, as close as the eye can get it.",
				"lines": [{"at": 0.4, "who": "bram", "say": "There she is. Solhaven."}]},
			{"id": "sol_04", "len": 4.0, "see": "Bram's face. He doesn't sound pleased."},
		],
	},
}

## Gary's 4K film for a story film, as the apps carry it (the films release)
## and the phone link streams it (films/<film>/).
const NATIVE_SUFFIX := "_4k.mp4"

var film := ""
var _w: World
var _root: Control
var _video: VideoStreamPlayer
var _stage: OpeningMovie.ShotView
var _voice: AudioStreamPlayer
var _done := false
var _cut := false
var _picks := {}       # flag -> pick, and "name" -> the name given
var _played := true    # false: nothing of the film could play (the 3D scene plays instead)
var _native = null     # the device's (or browser's) own player, while the 4K film plays
var _sub_line := 0     # the 4K film's subtitle now up (a newer line replaces it)
var _np = null         # the device's player for this film: one, its parts opened on it in turn
var _hold: TextureRect # a part's last frame, held at a choice (and until the next part's first picture)
var _voiced := false   # the part playing now has its own voices in it (no recordings over them)
var _keep_music := false   # the part playing now goes under the game's music (the choice's)
var _choice_music := ""    # the music a choice started, playing on until something stops it
## The part the film stopped before, not made yet ("": it played to its end).
var stopped_at := ""


## Is this film there to play: the 4K film, the whole cut, or a clip or
## painting for every shot? (A film in parts: its first part.)
static func available(p_film: String) -> bool:
	if not FILMS.has(p_film):
		return false
	if "--story-films" in OS.get_cmdline_user_args():
		return true
	var first := first_file(p_film)
	if native_path(first) != "":
		return true
	if Packs.in_build(p_film) and not Packs.has(p_film):
		return true   # (the phone link: its pack is there to fetch, so the film is)
	if ResourceLoader.exists(cut_path(first)):
		return true
	var parts: Array = FILMS[p_film].get("parts", [])
	var steps: Array = parts[0].get("steps", []) if not parts.is_empty() else FILMS[p_film].get("steps", [])
	var shots := 0
	for st in steps:
		if not st.has("id"):
			continue
		shots += 1
		if clip_path(p_film, String(st.id)) == "" and still_path(p_film, String(st.id)) == "":
			return false
	return shots > 0


## The film's steps in order; a film in parts, its parts' steps one after
## another with its choices between (its shots, for the animatic and the tools).
static func steps_of(p_film: String) -> Array:
	var f: Dictionary = FILMS.get(p_film, {})
	if not f.has("parts"):
		return f.get("steps", [])
	var out: Array = []
	for part in f.parts:
		if part.has("steps"):
			out.append_array(part.steps)
		else:
			out.append(part)   # (a choice, or the name)
	return out


## The file name a film's first piece goes by (the film's own when it's whole).
static func first_file(p_film: String) -> String:
	for part in FILMS.get(p_film, {}).get("parts", []):
		if part.has("file"):
			return String(part.file if part.file is String else part.file.values()[0])
	return p_film


## Is a part's piece of film there to play: its 4K film, its Theora copy (on
## the phone link, in the film's pack, fetched to look), or a clip or
## painting for each shot?
func _part_there(file: String, steps: Array) -> bool:
	var p = _native_player()
	if p != null and String(p.find_file(file + NATIVE_SUFFIX)) != "":
		return true
	if Packs.in_build(film) and not Packs.has(film):
		await Packs.need(film)
	return ResourceLoader.exists(cut_path(file)) or _shots_there(steps)


## The device's (or browser's) own player for this film, made once: each of
## its parts is opened on it in turn. Null where there's none.
func _native_player():
	if _np == null:
		_np = OpeningMovie.native_player()
	return _np


## Where the device's own player finds the 4K film ("": no player here, or
## no such film: the app's bundle hasn't got it, or the site's list of films
## says it isn't there).
static func native_path(p_film: String) -> String:
	var p = OpeningMovie.native_player()
	if p == null:
		return ""
	return String(p.find_file(p_film + NATIVE_SUFFIX))


static func cut_path(p_film: String) -> String:
	return "res://assets/movies/%s.ogv" % p_film


## The shot's clip: the look's own (<id>_<look>.ogv) when there is one, else <id>.ogv.
static func clip_path(p_film: String, id: String) -> String:
	var look := String(Game.flag("look", "a"))
	for name in ["%s_%s" % [id, look], id]:
		var p := "res://assets/movies/%s/%s.ogv" % [p_film, name]
		if ResourceLoader.exists(p):
			return p
	return ""


static func still_path(p_film: String, id: String) -> String:
	for ext in ["png", "jpg", "webp"]:
		var p := "res://assets/art/movie/%s/%s.%s" % [p_film, id, ext]
		if ResourceLoader.exists(p):
			return p
	return ""


## The shots of a film, in order (tools/movie_clips.py reads them).
static func shots(p_film: String) -> Array:
	return steps_of(p_film).filter(func(st): return st.has("id"))


## How long the film runs, by its shots.
static func length(p_film: String) -> float:
	var t := 0.0
	for st in shots(p_film):
		t += float(st.len)
	return t


## Plays the film over the world, under its movie bars and subtitles
## (CineOverlay), and returns the picks made: {flag: pick, "name": name},
## with "played": false if nothing of it could play (the 4K film wouldn't
## open and there's no other copy), when the scene plays its 3D version
## instead. It ends on black: the scene fades the world back in itself.
## A film in parts that stops before one not made yet returns
## "stopped_at": <that part's file> and "film": itself, still up on its last
## frame: the scene stages its 3D from that moment behind it, then lets it
## go (let_go), so the picture goes straight into the 3D with no black.
static func play(w: World, p_film: String) -> Dictionary:
	if native_path(first_file(p_film)) == "":
		await Packs.need(p_film)   # (streamed on the phone link: no pack to fetch first)
	var f := StoryFilm.new()
	f.film = p_film
	f._w = w
	w.add_child(f)
	await f.finished
	var picks := f._picks.duplicate()
	picks["played"] = f._played
	if f.stopped_at != "" and f._played:
		picks["stopped_at"] = f.stopped_at
		picks["film"] = f
		# (whoever forgets to let it go: it goes by itself a moment later)
		var wf: WeakRef = weakref(f)
		w.get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
			var still_up = wf.get_ref()
			if still_up is StoryFilm and not (still_up as StoryFilm).is_queued_for_deletion() and not (still_up as StoryFilm)._letting_go:
				push_warning("StoryFilm: %s was never let go; it fades by itself" % p_film)
				(still_up as StoryFilm)._fade_out(0.4))
	else:
		f.queue_free()
	return picks


## The film a scene took over from (play() returned "stopped_at"): its last
## frame dissolves into what's behind it over `secs` (the scene's 3D, its
## camera already on the next shot), and the film is gone. Nothing to do
## for a film that played to its end.
static func let_go(r: Dictionary, secs := 0.4) -> void:
	var f = r.get("film", null)
	if f is StoryFilm and is_instance_valid(f):
		await (f as StoryFilm)._fade_out(secs)


var _letting_go := false


func _fade_out(secs: float) -> void:
	if _letting_go:
		return
	_letting_go = true
	_native_sub("")
	if _native != null:
		_root.visible = false   # (under the device's player: it dissolves straight into what's behind)
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		_root.modulate.a = k
		if _native != null:
			_native.set_opacity(k), 1.0, 0.0, maxf(secs, 0.01))
	await tw.finished
	if _native != null:
		_native.stop()
		_native = null
	_video.stop()
	queue_free()


func _ready() -> void:
	layer = 12   # over the 3D world, under the movie bars and subtitles (14)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(black)
	_video = VideoStreamPlayer.new()
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_root.add_child(_video)
	_stage = OpeningMovie.ShotView.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stage)
	# a part's last frame, over the picture (the cut's player may show black
	# or its first frame again once it ends)
	_hold = TextureRect.new()
	_hold.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hold.stretch_mode = TextureRect.STRETCH_SCALE
	_hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hold.visible = false
	_root.add_child(_hold)
	_video.finished.connect(_held_on_end)
	_root.resized.connect(_fit)
	_fit()
	_voice = AudioStreamPlayer.new()
	add_child(_voice)
	Cine.call_by(_w, "herald", "The Pale Herald")   # (the subtitles' name for it)
	_run.call_deferred()


## The picture sits whole between the movie bars: as big as fits there,
## centred, black either side on a wide phone.
func _fit() -> void:
	var s := _root.size
	var bar := s.y * CineOverlay.BAR
	var room := Vector2(s.x, s.y - bar * 2.0)
	var fr := OpeningMovie.cut_rect(room)
	fr.position.y += bar
	_video.position = fr.position
	_video.size = fr.size
	_stage.position = fr.position
	_stage.size = fr.size
	if _hold_full:
		fr = OpeningMovie.cut_rect(s)
	_hold.position = fr.position
	_hold.size = fr.size


var _hold_full := false   # the held frame fills the view, as the device's player shows a film


## The held frame as the device's (or browser's) player shows a film: whole
## in the full view, over where the movie bars go, and the bars off (on);
## or back between the bars, with them (off: once that player covers the
## view again, or the cut takes over).
func _hold_whole(on: bool, ov: CineOverlay) -> void:
	if on == _hold_full:
		return
	_hold_full = on
	_fit()
	if on:
		_bars_were = ov._bars_on
		if _bars_were:
			ov.bars(false, 0.0)
	elif _bars_were:
		ov.bars(true, 0.0)


var _bars_were := false


func _run() -> void:
	var ov := Cine.overlay(_w)
	ov.black(false)
	if FILMS.get(film, {}).has("parts"):
		await _play_parts(ov)
		if stopped_at == "" or not _played:
			ov.black(true)
		# (stopped: its last frame stays up for the scene to take over from)
		_done = true
		finished.emit()
		return
	var steps: Array = FILMS.get(film, {}).get("steps", [])
	var how := "4K"
	if await _play_native(steps):
		pass
	else:
		how = "cut" if ResourceLoader.exists(cut_path(film)) else "shots"
		if Packs.in_build(film) and not Packs.has(film):
			await Packs.need(film)   # (the 4K stream failed: the Theora copy after all)
		if ResourceLoader.exists(cut_path(film)):
			await _play_cut(steps)
		elif "--story-films" in OS.get_cmdline_user_args() or _shots_there(steps):
			await _play_shots(steps)
		else:
			_played = false
			how = "nothing to play"
	if OS.is_debug_build():
		print("story film: %s (%s)" % [film, how])
	# it ends on black: the overlay's, under which the scene carries on
	ov.black(true)
	_done = true
	finished.emit()


func _shots_there(steps: Array) -> bool:
	var n := 0
	for st in steps:
		if st.has("id"):
			n += 1
			if clip_path(film, String(st.id)) == "" and still_path(film, String(st.id)) == "":
				return false
	return n > 0


# ------------------------------------------------------------- in parts ---

## A film in parts: each piece in turn, best first, with the choices between
## them over the held frame and their music. A part not made yet
## ("optional") stops the film there, on the last frame (stopped_at).
func _play_parts(ov: CineOverlay) -> void:
	var hows: Array = []
	var first := true
	for part in FILMS[film].parts:
		if not is_inside_tree():
			return
		if not part.has("file"):
			await _between(part, ov)
			continue
		var file := _part_file(part)
		var steps: Array = part.get("steps", [])
		if part.get("optional", false):
			var there: bool = await _part_there(file, steps)
			if not there:
				stopped_at = file
				break
		_voiced = bool(part.get("voiced", false))
		_keep_music = bool(part.get("keep_music", false))
		var how := await _play_part(file, steps, first)
		hows.append("%s: %s" % [file, how])
		if first and how == "nothing":
			_played = false
			break
		first = false
	_voiced = false
	_keep_music = false
	if stopped_at == "" and _native != null:
		_native_sub("")
		_voice.stop()
		_native.stop()
		_native = null
	if OS.is_debug_build():
		print("story film: %s (%s)%s" % [film, ", ".join(hows), ("; stops before %s, not made yet" % stopped_at) if stopped_at != "" else ""])


## The piece of film a part plays: its own, or the one for the pick made.
func _part_file(part: Dictionary) -> String:
	if part.file is String:
		return part.file
	var by := String(part.get("by", ""))
	var pick: int = int(_picks.get(by, Game.flag(by, 0)))
	return String(part.file.get(pick, part.file.values()[0]))


## One piece of the film, best first: its 4K film through the device's
## player, its Theora copy, or its shots (a later part with none of them
## plays its animatic, so the story still goes on). Returns how it played.
func _play_part(file: String, steps: Array, first: bool) -> String:
	_cut = false
	if await _play_native(steps, file, first):
		return "4K"
	if Packs.in_build(film) and not Packs.has(film):
		await Packs.need(film)   # (the 4K stream failed: the Theora copy after all)
	if ResourceLoader.exists(cut_path(file)):
		await _play_cut(steps, file)
		return "cut"
	if "--story-films" in OS.get_cmdline_user_args() or _shots_there(steps) or not first:
		if not first and not _shots_there(steps):
			push_warning("StoryFilm: %s has no film yet; its animatic plays" % file)
		await _play_shots(steps)
		return "shots"
	return "nothing"


# --------------------------------------------------- the 4K film (native) ---

## Gary's 4K film through the device's own player (or the browser's), as the
## opening plays: it draws over the whole game view, so the lines go over it
## as its own subtitles and a choice has it step aside. Returns false if
## there's no player or film, or it can't be read before anything is seen
## (the Theora copy or the shots play instead).
func _play_native(steps: Array, file := "", first := true) -> bool:
	if file == "":
		file = film
	var p = _native_player()
	if p == null:
		return false
	var path: String = p.find_file(file + NATIVE_SUFFIX)
	if path == "":
		return false
	if not p.open(path):
		push_warning("StoryFilm: %s won't open (%s)" % [path, p.get_error()])
		_native = null
		return false
	if not first:
		# a later part waits unseen over the held frame until its first
		# picture is there, then cuts straight in (open() puts the player up
		# black until it has read the file)
		p.set_visible(false)
	p.set_volume(1.0)
	p.play()
	var waited := 0.0
	while not p.is_ready() and not p.has_failed() and waited < OpeningMovie.NATIVE_READY_SECS and is_inside_tree():
		await get_tree().process_frame
		waited += get_process_delta_time()
	if p.has_failed() or not p.is_ready():
		push_warning("StoryFilm: %s can't be played (%s)" % [path, p.get_error()])
		p.stop()
		_native = null
		return false
	if not first:
		waited = 0.0
		while p.get_position() <= 0.0 and not p.has_failed() and waited < 1.0 and is_inside_tree():
			await get_tree().process_frame
			waited += get_process_delta_time()
		p.set_visible(true)
		_hold_whole(false, Cine.overlay(_w))   # (the bars back, under the player)
	_native = p
	_cut = true
	_stage.visible = false
	_video.visible = false
	_hold.visible = false   # (under the player now)
	_part_music()
	if OS.is_debug_build() or OS.has_feature("web"):
		print("story film: %s through the %s player (%s, %.1f s)" % [file, "browser's" if p is WebVideoPlayer else "native", path, p.get_length()])
	var ov := Cine.overlay(_w)
	var at := 0.0
	var ended := [false]
	var watch := func() -> float:
		var ev: int = p.poll()
		if ev & (OpeningMovie.NV_FINISHED | OpeningMovie.NV_FAILED):
			ended[0] = true
		return maxf(0.0, p.get_position())
	for st in steps:
		if not is_inside_tree() or ended[0]:
			break
		if st.has("id"):
			var length := float(st.len)
			var start := at
			await _lines_over(st.get("lines", []), length, func() -> float:
				var c: float = watch.call()
				return length if ended[0] else c - start)
			at += length
		elif st.has("choice") or st.has("name"):
			# the film pauses and steps aside: the game's buttons over black
			p.pause()
			_native_sub("")
			p.set_visible(false)
			await _between(st, ov)
			p.set_visible(true)
			p.play()
	# the rest of the film, to its end
	while is_inside_tree() and not ended[0]:
		watch.call()
		await get_tree().process_frame
	_native_sub("")
	if file != film:
		# a part: the player stays up on its last frame, for what comes next
		# (a choice holds it, the next part opens on it, or the scene takes over)
		return true
	_voice.stop()
	p.stop()
	_native = null
	return true


## The game's music as a part of the film starts: the film has its own, so
## it stops (a choice's menu music over the first second of what follows),
## unless the part goes under it ("keep_music").
func _part_music() -> void:
	if _keep_music:
		return
	if _choice_music != "" and Music.current == _choice_music:
		Music.stop(1.0)
	else:
		Music.stop(0.8)   # (the film has its own)
	_choice_music = ""


## A line as the 4K film's own subtitle ("" takes it down): the speaker's
## name and the line, as the game's subtitles have them.
func _native_sub(text: String, who := "", hold := -1.0) -> void:
	if _native == null:
		return
	_sub_line += 1
	if text == "":
		_native.set_subtitle("")
		return
	var nm := ""
	if who != "":
		nm = String(_w.get_meta("extra_names", {}).get(who, "")) if _w.has_meta("extra_names") else ""
		if nm == "":
			nm = _w._speaker(who)
	var plain := _w._fmt(text)
	var tags := RegEx.create_from_string("\\[/?[a-z]+[^\\]]*\\]")
	plain = tags.sub(plain, "", true)
	_native.set_subtitle(("%s: %s" % [nm, plain]) if nm != "" else plain)
	var speed := maxf(0.4, float(Game.settings.get("text_speed", 1.0)))
	var secs := hold if hold > 0.0 else (CineOverlay.READ_BASE + plain.length() * CineOverlay.READ_PER_CHAR) / speed
	var this_line := _sub_line
	get_tree().create_timer(secs, false).timeout.connect(func() -> void:
		if _sub_line == this_line and _native != null:
			_native.set_subtitle(""))


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _native != null:
		_native.stop()   # (never leave the device's player over the game)


# ---------------------------------------------------------------- shots ---

func _play_shots(steps: Array) -> void:
	var n := 0
	var ov := Cine.overlay(_w)
	_hold.visible = false
	_hold_whole(false, ov)
	for st in steps:
		if not is_inside_tree():
			return
		if st.has("id"):
			n += 1
			await _shot(st, n)
		else:
			await _between(st, ov)


## One shot: its clip, or its painting moved by the engine, or an animatic
## card; its lines at their moments.
func _shot(st: Dictionary, n: int) -> void:
	var id := String(st.id)
	var length := float(st.len)
	var clip := clip_path(film, id)
	var still := still_path(film, id)
	if clip != "":
		_video.stream = load(clip)
		_video.visible = true
		_stage.visible = false
		_video.play()
	else:
		_video.stop()
		_video.visible = false
		_stage.visible = true
		var tex: Texture2D = load(still) if still != "" else null
		_stage.show_shot({"id": id, "len": length, "see": String(st.get("see", "")), "move": st.get("move", "in"), "fx": st.get("fx", "")}, tex, n)
	await _lines_over(st.get("lines", []), length, func() -> float:
		return _video.stream_position if clip != "" else -1.0)
	if clip != "":
		# a clip a little longer than its length is held on its last frame
		# by the next shot's cut, never cut short
		while _video.is_playing() and is_inside_tree():
			await get_tree().process_frame


## Shows the lines of a shot (or a stretch of the cut) at their moments, and
## waits out `length` seconds. `clock` gives the picture's own time when it
## has one (-1: count the seconds ourselves).
func _lines_over(lines: Array, length: float, clock: Callable) -> void:
	var pending: Array = []
	for ln in lines:
		var cond: Array = ln.get("if", [])
		if cond.size() == 2 and _picks.get(String(cond[0]), Game.flag(String(cond[0]), -1)) != cond[1]:
			continue
		pending.append(ln)
	pending.sort_custom(func(a, b): return float(a.at) < float(b.at))
	var t := 0.0
	while t < length and is_inside_tree():
		await get_tree().process_frame
		var c: float = clock.call()
		t = maxf(t, c) if c >= 0.0 else t + get_process_delta_time()
		while not pending.is_empty() and float(pending[0].at) <= t:
			_say(pending.pop_front())


## A line as the game's subtitle (or the 4K film's own), with its voice when
## it has one.
func _say(ln: Dictionary) -> void:
	var who := String(ln.get("who", ""))
	var text := String(ln.get("say", ""))
	var hold := float(ln.get("hold", -1.0))
	# its recording: named ("vo", the Herald's), or by the words' id (VoiceLines);
	# none over a piece of film with its own voices in it ("voiced")
	var path := "" if _voiced and _cut else VoiceLines.file_for(who, text, String(ln.get("vo", "")))
	if path != "":
		# one voice at a time: a line that comes while the last is still being
		# said waits for it, and its words with it (27 October: the Herald's
		# herald_21 runs a second past its shot, and herald_03 cut its end off)
		while _voice.playing and is_inside_tree():
			await get_tree().process_frame
		if not is_inside_tree():
			return
		_voice.stream = load(path)
		_voice.play()
		if hold < 0.0:
			hold = _voice.stream.get_length() + 0.5
	if _native != null:
		_native_sub(text, who, hold)
		return
	Cine.say(_w, who, text, hold, true)   # (timed, not awaited: the picture keeps its time)


## A choice, the name, a caption or the music, between shots.
func _between(st: Dictionary, ov: CineOverlay) -> void:
	if st.has("choice"):
		_video.paused = true
		# the film's last frame held under the buttons (a film in parts), and
		# its menu music from this moment, looping until the pick and playing
		# on after it, at the same place, under the part that follows
		var held := still_path(film, String(st.hold)) if st.has("hold") else ""
		if held != "":
			_hold.texture = load(held)
			_hold.visible = true
		if st.has("music") and Music.has(String(st.music)):
			Music.play([String(st.music)], 0.05, true)
			_choice_music = String(st.music)
		if _native != null:
			_native_sub("")
			if held != "":
				# the held frame where the device's player has the picture (the
				# whole view, over the movie bars), and the player steps aside
				# once the bars are off: nothing on screen moves
				_hold_whole(true, ov)
				await get_tree().process_frame
				await get_tree().process_frame
			_native.set_visible(false)   # (the game's held frame is the same picture)
		var pick := await ov.choose(st.choice)
		var flag := String(st.get("flag", ""))
		if flag != "":
			_picks[flag] = pick
			Game.set_flag(flag, pick)
		_video.paused = false
	elif st.has("name"):
		_video.paused = true
		var nm := await ov.ask_name(String(st.name), "Ash")
		Game.player_name = nm
		_picks["name"] = nm
		_video.paused = false
	elif st.has("caption"):
		await ov.caption(String(st.caption), "", 2.6, true)
	elif st.has("music"):
		if st.music is String:
			Music.stop(2.0)
		else:
			Music.play(st.music, 2.0, true)
	elif st.has("stinger"):
		Music.stinger(String(st.stinger), false)


# ------------------------------------------------------------------ cut ---

## The whole cut: the shots' lengths say when each shot starts in it, so the
## lines come at their moments; a choice or the name pauses it there.
func _play_cut(steps: Array, file := "") -> void:
	if file == "":
		file = film
	var stream := load(cut_path(file)) as VideoStream
	if stream == null:
		await _play_shots(steps)
		return
	_cut = true
	_stage.visible = false
	_hold_whole(false, Cine.overlay(_w))   # (a held frame the device's player left: back between the bars)
	_video.stream = stream
	_video.visible = true
	_video.play()
	_part_music()   # (the cut has its own)
	await get_tree().process_frame
	if not _video.is_playing():
		push_warning("StoryFilm: %s won't play; playing the shots instead" % cut_path(file))
		_video.visible = false
		await _play_shots(steps)
		return
	if _hold.visible:
		# the held frame (a choice's) stays over it until its first picture
		# has been drawn, then it cuts straight in
		while _video.is_playing() and _video.stream_position <= 0.0 and is_inside_tree():
			await get_tree().process_frame
		await get_tree().process_frame
		_hold.visible = false
	var ov := Cine.overlay(_w)
	var at := 0.0
	for st in steps:
		if not is_inside_tree():
			return
		if st.has("id"):
			var length := float(st.len)
			var start := at
			await _lines_over(st.get("lines", []), length, func() -> float:
				# (once the player has finished its clock is back at 0: the
				# shot is over, and the rest with it)
				return maxf(0.0, _video.stream_position - start) if _video.is_playing() else length)
			at += length
		else:
			if st.has("music") or st.has("stinger") or st.has("caption"):
				continue   # (the cut has its own music)
			await _between(st, ov)
	# to its end (by its clock too: with no sound device the player never
	# says it has finished, and runs on past its end on the last frame)
	while _video.is_playing() and _video.stream_position < _video.get_stream_length() - 0.02 and is_inside_tree():
		await get_tree().process_frame
	if file != film:
		# a part: its last frame stays up, for the choice after it or the
		# scene taking over (the player itself may go to black once it's over)
		_freeze_frame()
		_video.stop()
		_video.visible = false


## The cut's picture now, kept up as the held frame (once a part ends).
func _freeze_frame() -> void:
	if _hold.visible or not _video.visible:
		return
	var t := _video.get_video_texture()
	var img: Image = t.get_image() if t != null else null
	if img != null and not img.is_empty():
		_hold.texture = ImageTexture.create_from_image(img)
		_hold.visible = true


## The cut's player says it's done: its last frame is kept up at once (a
## part's end, before anything can show black).
func _held_on_end() -> void:
	if _cut and FILMS.get(film, {}).has("parts"):
		_freeze_frame()
