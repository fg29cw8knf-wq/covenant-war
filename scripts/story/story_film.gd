class_name StoryFilm
extends CanvasLayer
## A story film: one of Gary's own films, played in place of the engine's 3D
## staging of the same stretch of a scene, as the finished opening movie
## replaced its shot-by-shot version (Gary, 23 October: "the cut scene after
## all the lanterns go up: can we make a proper movie from that like we did
## for the opening movie?"; 24 October: the cutscenes as videos built round
## one hero, Player A). Master Script v7 has seven (the Still to Make doc,
## the "Films for Player A" tab): midnight, white_light, herald, reckoning,
## tams_hand, no_roof and ridge. Conversations, choices and the things the
## player does (the cart, the tunnel, the look back) stay in the game
## between them.
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

signal finished

## What each film replaces, and what the scene around it still does, is in
## the scene's own script: midnight, white_light and herald in
## scripts/world/areas/ashford.gd (_midnight_film, _white_light_film,
## _herald_film), reckoning, tams_hand and no_roof in
## scripts/world/areas/ashford_night.gd, ridge in
## scripts/world/areas/thornwood.gd. The lines are the 3D scene's own, word
## for word; Master Script v7 (docs/script/v7_prologue.md) has them in order.
const FILMS := {
	"midnight": {
		"title": "Midnight",
		"steps": [
			{"id": "mid_01", "len": 7.0, "see": "Midnight on the packed green, every face turned up to the unlit Great Lantern; the chapel tower, its bell swinging.",
				"lines": [{"at": 0.6, "who": "", "say": "Midnight. The chapel bell counts twelve, and all of Ashford counts with it."}]},
			{"id": "mid_02", "len": 7.0, "player": true, "see": "From behind: he climbs the Lantern's steps with a lit taper and touches it to the wick. The Great Lantern burns with a rich, golden flame, and the whole green roars."},
			{"id": "mid_03", "len": 5.0, "see": "Little Tilly steps back from the Lantern, her face glowing gold. Behind her, Tam dances with Nell, badly; Ned's fiddle."},
			{"id": "mid_04", "len": 6.0, "player": true, "see": "Corin beside him, both of them watching the crowd; he says it without looking over.",
				"lines": [{"at": 0.8, "who": "corin", "say": "It's a good village, this. Don't tell anyone I said so."}]},
			{"id": "mid_05", "len": 10.0, "see": "Bram, looking up at the paper lanterns being readied, their candles lit one by one.",
				"lines": [{"at": 0.5, "who": "bram", "say": "Folk think we send them up for the gods. We don't. A lantern's for whoever's out in the dark, so they know which way is home."}]},
			{"id": "mid_06", "len": 6.0, "see": "Bram's face, the Lantern behind him, his eyes going up to the stars.",
				"lines": [{"at": 0.4, "who": "bram", "say": "Two thousand years. Wonder who'll be sitting up there tomorrow."}]},
			{"choice": ["Does it matter to us?", "Whoever it is owes us a better year."], "flag": "mid_choice"},
			{"id": "mid_07", "len": 5.0, "see": "Bram, close, the ghost of a laugh.",
				"lines": [{"at": 0.3, "who": "bram", "say": "It shouldn't. It always seems to.", "if": ["mid_choice", 0]},
					{"at": 0.8, "who": "bram", "say": "Write and tell them. See who writes back.", "if": ["mid_choice", 1]}]},
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


## Is this film there to play: the 4K film, the whole cut, or a clip or
## painting for every shot?
static func available(p_film: String) -> bool:
	if not FILMS.has(p_film):
		return false
	if "--story-films" in OS.get_cmdline_user_args():
		return true
	if native_path(p_film) != "":
		return true
	if Packs.in_build(p_film) and not Packs.has(p_film):
		return true   # (the phone link: its pack is there to fetch, so the film is)
	if ResourceLoader.exists(cut_path(p_film)):
		return true
	var steps: Array = FILMS.get(p_film, {}).get("steps", [])
	var shots := 0
	for st in steps:
		if not st.has("id"):
			continue
		shots += 1
		if clip_path(p_film, String(st.id)) == "" and still_path(p_film, String(st.id)) == "":
			return false
	return shots > 0


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
	return FILMS.get(p_film, {}).get("steps", []).filter(func(st): return st.has("id"))


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
static func play(w: World, p_film: String) -> Dictionary:
	if native_path(p_film) == "":
		await Packs.need(p_film)   # (streamed on the phone link: no pack to fetch first)
	var f := StoryFilm.new()
	f.film = p_film
	f._w = w
	w.add_child(f)
	await f.finished
	var picks := f._picks.duplicate()
	picks["played"] = f._played
	f.queue_free()
	return picks


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


func _run() -> void:
	var ov := Cine.overlay(_w)
	ov.black(false)
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


# --------------------------------------------------- the 4K film (native) ---

## Gary's 4K film through the device's own player (or the browser's), as the
## opening plays: it draws over the whole game view, so the lines go over it
## as its own subtitles and a choice has it step aside. Returns false if
## there's no player or film, or it can't be read before anything is seen
## (the Theora copy or the shots play instead).
func _play_native(steps: Array) -> bool:
	var p = OpeningMovie.native_player()
	if p == null:
		return false
	var path: String = p.find_file(film + NATIVE_SUFFIX)
	if path == "":
		return false
	if not p.open(path):
		push_warning("StoryFilm: %s won't open (%s)" % [path, p.get_error()])
		return false
	p.set_volume(1.0)
	p.play()
	var waited := 0.0
	while not p.is_ready() and not p.has_failed() and waited < OpeningMovie.NATIVE_READY_SECS and is_inside_tree():
		await get_tree().process_frame
		waited += get_process_delta_time()
	if p.has_failed() or not p.is_ready():
		push_warning("StoryFilm: %s can't be played (%s)" % [path, p.get_error()])
		p.stop()
		return false
	_native = p
	_cut = true
	_stage.visible = false
	_video.visible = false
	Music.stop(0.8)   # (the film has its own)
	if OS.is_debug_build() or OS.has_feature("web"):
		print("story film: %s through the %s player (%s, %.1f s)" % [film, "browser's" if p is WebVideoPlayer else "native", path, p.get_length()])
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
	_voice.stop()
	p.stop()
	_native = null
	return true


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
	# its recording: named ("vo", the Herald's), or by the words' id (VoiceLines)
	var path := VoiceLines.file_for(who, text, String(ln.get("vo", "")))
	if path != "":
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
func _play_cut(steps: Array) -> void:
	var stream := load(cut_path(film)) as VideoStream
	if stream == null:
		await _play_shots(steps)
		return
	_cut = true
	_stage.visible = false
	_video.stream = stream
	_video.visible = true
	_video.play()
	Music.stop(0.8)   # (the cut has its own)
	await get_tree().process_frame
	if not _video.is_playing():
		push_warning("StoryFilm: %s won't play; playing the shots instead" % cut_path(film))
		_video.visible = false
		await _play_shots(steps)
		return
	var ov := Cine.overlay(_w)
	var at := 0.0
	for st in steps:
		if not is_inside_tree():
			return
		if st.has("id"):
			var length := float(st.len)
			var start := at
			await _lines_over(st.get("lines", []), length, func() -> float:
				return maxf(0.0, _video.stream_position - start))
			at += length
		else:
			if st.has("music") or st.has("stinger") or st.has("caption"):
				continue   # (the cut has its own music)
			await _between(st, ov)
	while _video.is_playing() and is_inside_tree():
		await get_tree().process_frame
