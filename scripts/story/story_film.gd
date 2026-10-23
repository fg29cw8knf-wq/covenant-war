class_name StoryFilm
extends CanvasLayer
## A story film made of Gary's own clips, played in place of the engine's 3D
## staging of the same scene (as the finished opening movie replaced its
## shot-by-shot version). Midnight (P2) and Dawn (P3) first (Gary, 23
## October: "the cut scene after all the lanterns go up: can we make a proper
## movie from that like we did for the opening movie? Same for the scene the
## next morning").
##
## A film is a list of steps (FILMS): shots, and between them the things a
## film can't carry on its own (a choice, the name prompt, a caption):
##   {"id": "mid_01", "len": 8.0, "see": "...", "lines": [{"at": 0.5, "who": "", "say": "..."}]}
##       a shot: its clip res://assets/movies/<film>/<id>.ogv (made from
##       Gary's clip by tools/movie_clips.py --film <film>), or its painting
##       res://assets/art/movie/<film>/<id>.png (.jpg), or, while neither
##       exists, an animatic card saying what the shot is. A shot that
##       shows the player can have one clip per look (<id>_a.ogv ... _d),
##       used for the look chosen in the mirror. Its lines are the game's
##       subtitles (CineOverlay), each at its moment; a line with "vo"
##       plays that voice file from res://assets/audio/vo/ (the Herald's
##       lines, Gary's recordings) and stays up as long as it does.
##   {"choice": [...], "flag": "..."}   the player's choice, over the last
##       frame; the pick (0, 1, ...) is kept in that story flag
##   {"name": "<the question>"}          the name prompt (Game.player_name)
##   {"caption": "Dawn"}                 a caption over the picture
##   {"music": ["dawn_after"]}           music from here (Music.play); "stop" ends it
##   {"stinger": "the_marking"}          a stinger (Music.stinger)
## The whole cut, res://assets/movies/<film>.ogv, is played instead when it
## exists (every shot's clip in one, with its music, as Gary made the opening):
## the lines still go over it at their moments, and a choice pauses it.
##
## The engine's 3D scene stays as the fallback: a film is only used once it's
## all there (available()), or when "--story-films" is on the command line.

signal finished

## What the film replaces, and what the scene around it must still do, is in
## scripts/world/areas/ashford.gd (_midnight_film, _dawn_film).
const FILMS := {
	"midnight": {
		"title": "Midnight",
		"steps": [
			{"id": "mid_01", "len": 8.0, "see": "The green at night, packed, every face turned up to the unlit Great Lantern; the chapel tower; the bell swinging.",
				"lines": [{"at": 0.6, "who": "", "say": "Midnight. The chapel bell counts twelve, and all of Ashford counts with it.", "vo": "mid_01"}]},
			{"id": "mid_02", "len": 7.0, "see": "From behind: the player climbs the Lantern's steps with a lit taper and touches it to the wick. The Great Lantern catches with a roar, and the whole village roars back.", "player": true},
			{"id": "mid_03", "len": 6.0, "see": "Tam dancing with Nell, badly, in the Lantern's gold light; Ned's fiddle; paper lanterns bobbing in the crowd."},
			{"id": "mid_04", "len": 7.0, "see": "Corin beside the player, both watching the crowd; he says it without looking over.",
				"lines": [{"at": 0.8, "who": "corin", "say": "It's a good village, this. Don't tell anyone I said so."}]},
			{"id": "mid_05", "len": 10.0, "see": "Bram, looking up at the first paper lanterns being readied, their candles lit one by one.",
				"lines": [{"at": 0.5, "who": "bram", "say": "Folk think we send them up for the gods. We don't. A lantern's for whoever's out in the dark, so they know which way is home."}]},
			{"id": "mid_06", "len": 6.0, "see": "Bram's face, the Lantern behind him, his eyes going up to the stars.",
				"lines": [{"at": 0.4, "who": "bram", "say": "Two thousand years. Wonder who'll be sitting up there tomorrow."}]},
			{"choice": ["Does it matter to us?", "Whoever it is owes us a better year."], "flag": "mid_choice"},
			{"id": "mid_07", "len": 5.0, "see": "Bram, close, the ghost of a laugh.",
				"lines": [{"at": 0.3, "who": "bram", "say": "It shouldn't. It always seems to.", "if": ["mid_choice", 0]},
					{"at": 0.3, "who": "bram", "say": "Write and tell them. See who writes back.", "if": ["mid_choice", 1]}]},
			{"music": "stop"},   # (the fiddle trails off: the festival reel goes with the lanterns)
			{"id": "mid_08", "len": 11.0, "see": "Hundreds of paper lanterns rise over Ashford. Then they stop, every one, hanging in the air as if the night has taken hold of them. The fiddle trails off. One by one, faces turn up."},
			{"id": "mid_09", "len": 5.0, "see": "Corin, looking up, then at Bram.",
				"lines": [{"at": 0.4, "who": "corin", "say": "Bram. Is it meant to do that?"}]},
			{"music": ["sigilfall"]},
			{"id": "mid_10", "len": 8.0, "see": "The sky splits from one horizon to the other. Light pours down in every colour. For a breath the children cheer."},
			{"id": "mid_11", "len": 5.0, "see": "A strike hits the mill and the thatch goes up.",
				"lines": [{"at": 1.6, "who": "nell", "say": "The mill! The mill's on fire!", "hold": 2.4}]},
			{"id": "mid_12", "len": 5.0, "see": "Bram, shouting over the noise, pointing the player at the inn.",
				"lines": [{"at": 0.3, "who": "bram", "say": "Inside! Everyone inside! Sprout, the inn. Now!", "hold": 2.8}]},
			{"id": "mid_13", "len": 9.0, "see": "Everyone runs for their doors. Corin grabs Tilly and runs her up the lane past Tam's hay cart. The player runs for the inn (from behind); strikes land all round, and one knocks them flat.", "player": true},
			{"id": "mid_14", "len": 5.0, "see": "A blast on the far side of the hay cart throws it over, onto Corin. Tilly screams.",
				"lines": [{"at": 1.8, "who": "tilly", "say": "Corin! CORIN!", "hold": 1.8}]},
			{"id": "mid_15", "len": 7.0, "see": "The player gets up off the ground, sees him, and runs back. Bram is already running too. Corin under the cart's edge, his leg pinned.", "player": true,
				"lines": [{"at": 2.8, "who": "corin", "say": "My leg. It's stuck, I can't, I can't get it —"}]},
			{"id": "mid_16", "len": 8.0, "see": "Bram arrives at the cart. He and the player take its top edge, one either side of Corin, and heave; Corin drags himself clear and the cart crashes back down.", "player": true,
				"lines": [{"at": 0.3, "who": "bram", "say": "Other side. On three. One, two —", "hold": 2.8}]},
			{"id": "mid_17", "len": 6.0, "see": "Corin on his feet, limping, trying to make light of it. He isn't all right: his hands are shaking.",
				"lines": [{"at": 0.4, "who": "corin", "say": "I'm all right. I'm all right."}]},
			{"music": "stop"},
			{"stinger": "the_marking"},
			{"id": "mid_18", "len": 10.0, "see": "One light falls differently. White. Slow. Silent. It passes Bram. It passes Corin. It stops at the player.", "player": true},
			{"id": "mid_19", "len": 9.0, "see": "The player's hand held out, and the light settles on it: a card with nothing on it. Every other light in the sky goes out at once. Then a white mark burns itself into the back of the hand.", "player": true},
			{"id": "mid_20", "len": 7.0, "see": "Corin, staring at the card, then down at his own empty hand.",
				"lines": [{"at": 0.4, "who": "corin", "say": "It came to you."}, {"at": 3.6, "who": "corin", "say": "It just came to you."}]},
			{"id": "mid_21", "len": 9.0, "see": "Bram crosses to the player and closes their fingers over the card. Its glow dies between them. His hand is shaking too. He looks the player in the eye.", "player": true,
				"lines": [{"at": 4.0, "who": "bram", "say": "Put that away. Don't show anyone. Not anyone."}]},
		],
	},
	"dawn": {
		"title": "Dawn",
		"steps": [
			{"music": ["dawn_after"]},
			{"caption": "Dawn"},
			{"id": "dawn_01", "len": 9.0, "see": "Dawn over Ashford. Smoke lies over the hills. The mill is a black shell. Children pick fallen Sparks out of the furrows and squabble over them like conkers."},
			{"id": "dawn_02", "len": 8.0, "see": "Hob on the green with a fan of glowing cards in his big hands, showing Bram.",
				"lines": [{"at": 0.5, "who": "hob", "say": "Lost half the barley and the mill roof. Found nine cards in the cabbages. Can't tell if that's a good trade."}]},
			{"id": "dawn_03", "len": 10.0, "see": "A mist comes down the road against the wind. In it walks a grey horse that leaves no prints. Its rider's hood is empty, and it carries a staff topped with a pale lantern."},
			{"id": "dawn_04", "len": 7.0, "see": "The villagers kneel without being told. Bram's hand on the player's shoulder brings them down with the rest (from behind the pair).", "player": true,
				"lines": [{"at": 2.4, "who": "bram", "say": "A Pale Herald. Morrowen's own. Head down. Hand in your pocket."}]},
			{"id": "dawn_05", "len": 4.0, "see": "The Herald stops at the edge of the green. The empty hood.",
				"lines": [{"at": 0.3, "who": "herald", "say": "Hear the Covenant.", "vo": "herald_01"}]},
			{"id": "dawn_06", "len": 16.5, "see": "The pale lantern on the staff brightens as it speaks; Ashford's faces, kneeling, lit by it.",
				"lines": [{"at": 0.3, "who": "herald", "say": "The Age of Solmaris is ending. By the Covenant, the Turning begins. For one year, any Seat in Veyl may be challenged by anyone.", "vo": "herald_02"}]},
			{"id": "dawn_07", "len": 8.5, "see": "The lantern's light shows a knight kneeling in a sun chapel (Ser Aldric Vane, Gary's painting).",
				"lines": [{"at": 0.3, "who": "herald", "say": "Solhaven, for Solmaris: Ser Aldric Vane.", "vo": "herald_03"}]},
			{"id": "dawn_08", "len": 8.0, "see": "Five more faces in the lantern's light, a name written under each, too quick to hold: a scarred warlord, a boy on an ice throne, a grinning captain, a mask in the dark, a blindfolded priestess. The camera stays mostly on Ashford's faces."},
			{"id": "dawn_09", "len": 6.5, "see": "The sixth face. At the name, Bram's hand tightens on the player's shoulder.", "player": true,
				"lines": [{"at": 0.3, "who": "herald", "say": "Glyphmere, for Aldrith: Magister Tobias Crane.", "vo": "herald_09"}]},
			{"id": "dawn_10", "len": 12.0, "see": "The empty hood, and the lantern's light turning towards the kneeling crowd.",
				"lines": [{"at": 0.3, "who": "herald", "say": "And one more. Bound to no god. Holding no Seat. Marked by the Covenant itself.", "vo": "herald_10"}]},
			{"id": "dawn_11", "len": 7.0, "see": "The mark on the player's hand blazes straight through their pocket. Every head in Ashford turns. Last of all, slowly, the empty hood.", "player": true},
			{"name": "Nobody has told the Herald your name. The empty hood speaks it anyway. What does it say?"},
			{"id": "dawn_12", "len": 5.0, "see": "The empty hood, facing the player.",
				"lines": [{"at": 0.2, "who": "herald", "say": "{name}.", "hold": 2.0}, {"at": 2.4, "who": "herald", "say": "The Unsworn.", "vo": "herald_12"}]},
			{"id": "dawn_13", "len": 10.0, "see": "The Herald, the staff raised a little, the lantern's light on the player.",
				"lines": [{"at": 0.3, "who": "herald", "say": "Present your mark at the Sun Court of Solhaven before the new moon, or forfeit it.", "vo": "herald_13"}]},
			{"id": "dawn_14", "len": 9.0, "see": "The Herald rides back into the mist, and the mist goes with it. Nobody speaks. Tilly, uncertain, waves at the place where it was."},
		],
	},
}

var film := ""
var _w: World
var _root: Control
var _video: VideoStreamPlayer
var _stage: OpeningMovie.ShotView
var _voice: AudioStreamPlayer
var _done := false
var _cut := false
var _picks := {}       # flag -> pick, and "name" -> the name given


## Is this film there to play: the whole cut, or a clip or painting for every shot?
static func available(p_film: String) -> bool:
	if "--story-films" in OS.get_cmdline_user_args():
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


## Plays the film over the world, under its movie bars and subtitles
## (CineOverlay), and returns the picks made: {flag: pick, "name": name}.
static func play(w: World, p_film: String) -> Dictionary:
	await Packs.need(p_film)
	var f := StoryFilm.new()
	f.film = p_film
	f._w = w
	w.add_child(f)
	await f.finished
	var picks := f._picks
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
	if ResourceLoader.exists(cut_path(film)):
		await _play_cut(steps)
	else:
		await _play_shots(steps)
	_done = true
	finished.emit()


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


## A line as the game's subtitle, with its voice when it has one.
func _say(ln: Dictionary) -> void:
	var who := String(ln.get("who", ""))
	var text := String(ln.get("say", ""))
	var hold := float(ln.get("hold", -1.0))
	var vo := String(ln.get("vo", ""))
	if vo != "":
		for ext in ["ogg", "wav", "mp3"]:
			var path := "res://assets/audio/vo/%s.%s" % [vo, ext]
			if ResourceLoader.exists(path):
				_voice.stream = load(path)
				_voice.play()
				if hold < 0.0:
					hold = _voice.stream.get_length() + 0.5
				break
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
			if st.has("music") or st.has("stinger"):
				continue   # (the cut has its own music)
			await _between(st, ov)
	while _video.is_playing() and is_inside_tree():
		await get_tree().process_frame
